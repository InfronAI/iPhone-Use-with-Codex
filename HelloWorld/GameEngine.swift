import Foundation

enum FlightPhase: Equatable { case ready, playing, paused, gameOver }
enum EnemyKind { case scout, armored, boss }
enum SupplyKind: Int { case weapon, shield, bomb }

struct FlightPoint {
    var x: Double
    var y: Double

    func distance(to other: FlightPoint) -> Double {
        hypot(x - other.x, y - other.y)
    }
}

struct Enemy {
    let id: Int
    let kind: EnemyKind
    var position: FlightPoint
    let originX: Double
    var age = 0.0
    var health: Int
    let maximumHealth: Int
    var fireCooldown: Double
    var radius: Double { kind == .boss ? 48 : kind == .armored ? 23 : 16 }
    var points: Int { kind == .boss ? 2000 : kind == .armored ? 250 : 100 }
}

struct Projectile {
    let id: Int
    var position: FlightPoint
    let velocity: FlightPoint
    let hostile: Bool
    var radius: Double { hostile ? 5 : 4 }
}

struct Supply {
    let id: Int
    let kind: SupplyKind
    var position: FlightPoint
}

enum FlightEvent {
    case explosion(FlightPoint, large: Bool)
    case hit
    case collected(SupplyKind)
    case bomb
    case wave(Int)
    case boss
    case gameOver
}

/// The simulation uses points with the origin at the bottom left, like SpriteKit.
/// Keeping it independent of the renderer lets collision and lifecycle rules be tested.
struct GameEngine {
    var width = 390.0
    var height = 844.0
    private(set) var phase = FlightPhase.ready
    private(set) var score = 0
    private(set) var stage = 1
    private(set) var lives = 3
    private(set) var bombs = 3
    private(set) var weaponLevel = 1
    private(set) var invulnerability = 0.0
    private(set) var player = FlightPoint(x: 195, y: 155)
    private(set) var enemies: [Enemy] = []
    private(set) var projectiles: [Projectile] = []
    private(set) var supplies: [Supply] = []
    private(set) var events: [FlightEvent] = []
    private var randomState: UInt64
    private var nextID = 0
    private var spawnCooldown = 0.8
    private var shotCooldown = 0.0
    private var supplyCooldown = 9.0
    private var stageTime = 0.0
    private var kills = 0
    private var bossSpawned = false

    init(seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        randomState = seed == 0 ? 1 : seed
    }

    var boss: Enemy? { enemies.first { $0.kind == .boss } }

    mutating func resize(width: Double, height: Double) {
        self.width = max(240, width)
        self.height = max(480, height)
        movePlayer(to: player)
    }

    mutating func start() {
        let oldWidth = width
        let oldHeight = height
        self = GameEngine(seed: randomState)
        width = oldWidth
        height = oldHeight
        player = FlightPoint(x: width / 2, y: 155)
        phase = .playing
        invulnerability = 2
        events = [.wave(1)]
    }

    mutating func pause() {
        if phase == .playing { phase = .paused }
    }

    mutating func resume() {
        if phase == .paused { phase = .playing }
    }

    mutating func movePlayer(to position: FlightPoint) {
        player = FlightPoint(x: min(max(position.x, 25), width - 25),
                             y: min(max(position.y, 105), height - 155))
    }

    mutating func drainEvents() -> [FlightEvent] {
        let pending = events
        events.removeAll(keepingCapacity: true)
        return pending
    }

    mutating func useBomb() {
        guard phase == .playing, bombs > 0 else { return }
        bombs -= 1
        projectiles.removeAll { $0.hostile }
        invulnerability = max(invulnerability, 1.2)
        for index in enemies.indices { enemies[index].health -= 60 }
        removeDestroyedEnemies()
        events.append(.bomb)
    }

    /// Split frames so fast bullets cannot jump through narrow collision circles.
    /// Discard long suspension gaps instead of advancing a whole battle on resume.
    mutating func advance(_ elapsed: Double) {
        guard phase == .playing, elapsed.isFinite, elapsed > 0 else { return }
        var remaining = min(elapsed, 0.1)
        while remaining > 0.000_001, phase == .playing {
            let delta = min(remaining, 1.0 / 120.0)
            step(delta)
            remaining -= delta
        }
    }

    private mutating func step(_ delta: Double) {
        invulnerability = max(0, invulnerability - delta)
        stageTime += delta
        shotCooldown -= delta
        spawnCooldown -= delta
        supplyCooldown -= delta

        if shotCooldown <= 0 {
            firePlayerWeapon()
            shotCooldown += weaponLevel == 3 ? 0.13 : 0.17
        }

        if stage % 3 == 0 {
            if !bossSpawned {
                spawnEnemy(.boss)
                bossSpawned = true
                events.append(.boss)
            }
        } else if stageTime >= 22 {
            advanceStage()
        } else if spawnCooldown <= 0 {
            spawnEnemy(random() > 0.72 ? .armored : .scout)
            spawnCooldown = max(0.38, 1.0 - Double(stage) * 0.055)
        }

        if supplyCooldown <= 0 {
            dropSupply(at: FlightPoint(x: 45 + random() * (width - 90), y: height - 110))
            supplyCooldown = 12
        }

        for index in enemies.indices {
            enemies[index].age += delta
            let age = enemies[index].age
            if enemies[index].kind == .boss {
                enemies[index].position.y = max(height - 205, enemies[index].position.y - 85 * delta)
                enemies[index].position.x = width / 2 + sin(age * 0.8) * (width * 0.28)
            } else {
                let speed = enemies[index].kind == .armored ? 65.0 : 110.0
                enemies[index].position.y -= (speed + Double(min(stage, 20)) * 6) * delta
                enemies[index].position.x = min(width - 25, max(25, enemies[index].originX + sin(age * 2.3) * 24))
            }
            enemies[index].fireCooldown -= delta
            if enemies[index].fireCooldown <= 0, enemies[index].position.y < height - 115,
               enemies[index].position.y > player.y + 35 {
                fireEnemyWeapon(enemies[index])
                enemies[index].fireCooldown = enemies[index].kind == .boss ? 0.85 : max(1.1, 2.8 - Double(stage) * 0.08)
            }
        }

        for index in projectiles.indices {
            projectiles[index].position.x += projectiles[index].velocity.x * delta
            projectiles[index].position.y += projectiles[index].velocity.y * delta
        }
        for index in supplies.indices { supplies[index].position.y -= 80 * delta }
        resolveCollisions()
        enemies.removeAll { $0.position.y < -60 }
        projectiles.removeAll { $0.position.y < -30 || $0.position.y > height + 40 || $0.position.x < -30 || $0.position.x > width + 30 }
        supplies.removeAll { $0.position.y < -30 }
    }

    private mutating func firePlayerWeapon() {
        let offsets: [Double] = weaponLevel == 1 ? [0] : [-11, 11]
        for offset in offsets {
            projectiles.append(Projectile(id: identifier(),
                position: FlightPoint(x: player.x + offset, y: player.y + 27),
                velocity: FlightPoint(x: 0, y: 760), hostile: false))
        }
        if weaponLevel == 3 {
            for direction in [-1.0, 1.0] {
                projectiles.append(Projectile(id: identifier(),
                    position: FlightPoint(x: player.x + direction * 19, y: player.y + 12),
                    velocity: FlightPoint(x: direction * 150, y: 700), hostile: false))
            }
        }
    }

    private mutating func fireEnemyWeapon(_ enemy: Enemy) {
        let direction = atan2(player.y - enemy.position.y, player.x - enemy.position.x)
        let angles: [Double] = enemy.kind == .boss ? [-0.48, -0.24, 0, 0.24, 0.48] : [0]
        let speed = 175.0 + Double(min(stage, 15)) * 7
        for offset in angles {
            projectiles.append(Projectile(id: identifier(),
                position: FlightPoint(x: enemy.position.x, y: enemy.position.y - 20),
                velocity: FlightPoint(x: cos(direction + offset) * speed,
                                      y: sin(direction + offset) * speed), hostile: true))
        }
    }

    private mutating func spawnEnemy(_ kind: EnemyKind) {
        let x = kind == .boss ? width / 2 : 35 + random() * (width - 70)
        let hp = kind == .boss ? 100 + stage * 12 : kind == .armored ? 7 : 2
        enemies.append(Enemy(id: identifier(), kind: kind,
            position: FlightPoint(x: x, y: height + 45), originX: x,
            health: hp, maximumHealth: hp, fireCooldown: 1.1 + random()))
    }

    private mutating func resolveCollisions() {
        var removedProjectiles = Set<Int>()
        for projectile in projectiles {
            if projectile.hostile {
                if projectile.position.distance(to: player) < 11 + projectile.radius {
                    removedProjectiles.insert(projectile.id)
                    damagePlayer()
                }
            } else if let index = enemies.firstIndex(where: {
                $0.health > 0 && $0.position.distance(to: projectile.position) < $0.radius + projectile.radius
            }) {
                enemies[index].health -= 1
                removedProjectiles.insert(projectile.id)
            }
        }
        projectiles.removeAll { removedProjectiles.contains($0.id) }
        removeDestroyedEnemies()
        guard phase == .playing else { return }

        for index in enemies.indices where enemies[index].position.distance(to: player) < enemies[index].radius + 11 {
            damagePlayer()
            if enemies[index].kind != .boss {
                events.append(.explosion(enemies[index].position, large: false))
                enemies[index].health = 0
            }
        }
        enemies.removeAll { $0.health <= 0 }
        guard phase == .playing else { return }
        let collected = supplies.filter { $0.position.distance(to: player) < 36 }
        for supply in collected { collect(supply.kind) }
        let collectedIDs = Set(collected.map(\.id))
        supplies.removeAll { collectedIDs.contains($0.id) }
    }

    private mutating func damagePlayer() {
        guard invulnerability <= 0, phase == .playing else { return }
        lives -= 1
        invulnerability = 2
        weaponLevel = max(1, weaponLevel - 1)
        events.append(.hit)
        if lives <= 0 {
            phase = .gameOver
            events.append(.explosion(player, large: true))
            events.append(.gameOver)
        }
    }

    private mutating func collect(_ kind: SupplyKind) {
        switch kind {
        case .weapon: weaponLevel = min(3, weaponLevel + 1)
        case .shield: lives = min(3, lives + 1)
        case .bomb: bombs = min(3, bombs + 1)
        }
        score += 50
        events.append(.collected(kind))
    }

    private mutating func removeDestroyedEnemies() {
        let destroyed = enemies.filter { $0.health <= 0 }
        enemies.removeAll { $0.health <= 0 }
        for enemy in destroyed {
            score += enemy.points
            kills += 1
            events.append(.explosion(enemy.position, large: enemy.kind != .scout))
            if kills % 7 == 0 { dropSupply(at: enemy.position) }
            if enemy.kind == .boss {
                projectiles.removeAll { $0.hostile }
                dropSupply(at: enemy.position)
                advanceStage()
            }
        }
    }

    private mutating func dropSupply(at position: FlightPoint) {
        let kind: SupplyKind = weaponLevel < 3 ? .weapon : (random() < 0.55 ? .shield : .bomb)
        supplies.append(Supply(id: identifier(), kind: kind, position: position))
    }

    private mutating func advanceStage() {
        stage += 1
        stageTime = 0
        bossSpawned = false
        spawnCooldown = 1
        events.append(.wave(stage))
    }

    private mutating func identifier() -> Int {
        nextID += 1
        return nextID
    }

    private mutating func random() -> Double {
        randomState = randomState &* 6364136223846793005 &+ 1442695040888963407
        return Double(randomState >> 11) / Double(UInt64(1) << 53)
    }
}
