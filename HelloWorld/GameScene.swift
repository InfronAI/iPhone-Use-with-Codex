import SpriteKit
import SwiftUI
import UIKit

struct FlightHUD: Equatable {
    var phase = FlightPhase.ready
    var score = 0
    var best = 0
    var stage = 1
    var lives = 3
    var bombs = 3
    var weapon = 1
    var bossHealth = 0
    var bossMaximum = 0
}

@MainActor
final class GameSession: ObservableObject {
    @Published private(set) var hud = FlightHUD()
    @Published var hapticsEnabled = true
    lazy var scene = GameScene(session: self)
    private let defaults = UserDefaults.standard
    private var best = UserDefaults.standard.integer(forKey: "neonStrike.bestScore")
    private let impact = UIImpactFeedbackGenerator(style: .medium)

    func update(from game: GameEngine) {
        if game.score > best {
            best = game.score
            defaults.set(best, forKey: "neonStrike.bestScore")
        }
        let next = FlightHUD(phase: game.phase, score: game.score, best: best,
            stage: game.stage, lives: game.lives, bombs: game.bombs, weapon: game.weaponLevel,
            bossHealth: game.boss?.health ?? 0, bossMaximum: game.boss?.maximumHealth ?? 0)
        if hud != next {
            hud = next
            UIApplication.shared.isIdleTimerDisabled = game.phase == .playing
        }
    }

    func start() { scene.startGame() }
    func pause() { scene.pauseGame() }
    func resume() { scene.resumeGame() }
    func bomb() { scene.deployBomb() }

    func feedback(_ event: FlightEvent) {
        guard hapticsEnabled else { return }
        switch event {
        case .hit, .bomb, .gameOver: impact.impactOccurred(intensity: 0.9)
        case .collected: impact.impactOccurred(intensity: 0.45)
        default: break
        }
    }
}

@MainActor
final class GameScene: SKScene {
    private weak var session: GameSession?
    private var game = GameEngine()
    private let world = SKNode()
    private let effects = SKNode()
    private let starfield = SKNode()
    private let playerNode = SKNode()
    private var actors: [Int: SKNode] = [:]
    private var stars: [(node: SKShapeNode, speed: CGFloat)] = []
    private var lastUpdate: TimeInterval = 0
    private var animationTime = 0.0
    private weak var activeTouch: UITouch?
    private var lastTouchPosition = CGPoint.zero
    private let cyan = UIColor(red: 0.32, green: 0.95, blue: 1, alpha: 1)
    private let coral = UIColor(red: 1, green: 0.32, blue: 0.42, alpha: 1)
    private var isConfigured = false

    init(session: GameSession) {
        self.session = session
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.018, green: 0.035, blue: 0.075, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("Use init(session:)") }

    override func didMove(to view: SKView) {
        guard !isConfigured else { return }
        isConfigured = true
        addChild(starfield)
        world.zPosition = 5
        addChild(world)
        effects.zPosition = 20
        addChild(effects)
        playerNode.zPosition = 10
        playerNode.addChild(makePlayer())
        world.addChild(playerNode)
        rebuildBackground()
        game.movePlayer(to: FlightPoint(x: Double(size.width / 2), y: 155))
        render()
        session?.update(from: game)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        game.resize(width: Double(size.width), height: Double(size.height))
        if isConfigured { rebuildBackground() }
    }

    func startGame() {
        actors.values.forEach { $0.removeFromParent() }
        actors.removeAll()
        effects.removeAllChildren()
        effects.isPaused = false
        world.isPaused = false
        world.removeAllActions()
        world.position = .zero
        game.start()
        activeTouch = nil
        lastUpdate = 0
        render()
        session?.update(from: game)
    }

    func pauseGame() {
        game.pause()
        activeTouch = nil
        world.isPaused = true
        effects.isPaused = true
        session?.update(from: game)
    }

    func resumeGame() {
        game.resume()
        world.isPaused = false
        effects.isPaused = false
        lastUpdate = 0
        session?.update(from: game)
    }

    func deployBomb() {
        game.useBomb()
        handleEvents()
        render()
        session?.update(from: game)
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = lastUpdate == 0 ? 0 : min(0.05, max(0, currentTime - lastUpdate))
        lastUpdate = currentTime
        animationTime += delta
        for star in stars {
            star.node.position.y -= star.speed * delta
            if star.node.position.y < -10 { star.node.position.y = size.height + 10 }
        }
        game.advance(delta)
        handleEvents()
        render()
        session?.update(from: game)
    }

    private func render() {
        playerNode.position = game.phase == .ready
            ? CGPoint(x: size.width / 2, y: 82)
            : CGPoint(x: game.player.x, y: game.player.y)
        playerNode.isHidden = game.phase == .gameOver
        playerNode.setScale(1)
        playerNode.alpha = game.invulnerability > 0 && Int(animationTime * 12) % 2 == 0 ? 0.4 : 1
        playerNode.childNode(withName: "ship/shield")?.isHidden = game.invulnerability <= 0
        var living = Set<Int>()
        for enemy in game.enemies {
            living.insert(enemy.id)
            let node = actor(enemy.id) { self.makeEnemy(enemy.kind) }
            node.position = CGPoint(x: enemy.position.x, y: enemy.position.y)
            node.zRotation = enemy.kind == .boss ? 0 : sin(enemy.age * 2.3) * -0.12
        }
        for shot in game.projectiles {
            living.insert(shot.id)
            let node = actor(shot.id) { self.makeProjectile(hostile: shot.hostile) }
            node.position = CGPoint(x: shot.position.x, y: shot.position.y)
            node.zRotation = atan2(-shot.velocity.x, shot.velocity.y)
        }
        for supply in game.supplies {
            living.insert(supply.id)
            let node = actor(supply.id) { self.makeSupply(supply.kind) }
            node.position = CGPoint(x: supply.position.x, y: supply.position.y)
        }
        let stale = actors.keys.filter { !living.contains($0) }
        for id in stale { actors.removeValue(forKey: id)?.removeFromParent() }
    }

    private func actor(_ id: Int, create: () -> SKNode) -> SKNode {
        if let node = actors[id] { return node }
        let node = create()
        actors[id] = node
        world.addChild(node)
        return node
    }

    private func rebuildBackground() {
        starfield.removeAllChildren()
        stars.removeAll()
        let grid = CGMutablePath()
        stride(from: CGFloat(0), through: size.width, by: 44).forEach {
            grid.move(to: CGPoint(x: $0, y: 0)); grid.addLine(to: CGPoint(x: $0, y: size.height))
        }
        stride(from: CGFloat(0), through: size.height, by: 44).forEach {
            grid.move(to: CGPoint(x: 0, y: $0)); grid.addLine(to: CGPoint(x: size.width, y: $0))
        }
        let gridNode = SKShapeNode(path: grid)
        gridNode.strokeColor = cyan.withAlphaComponent(0.045)
        gridNode.lineWidth = 0.5
        starfield.addChild(gridNode)
        for index in 0..<85 {
            let depth = CGFloat(index % 3 + 1)
            let star = SKShapeNode(circleOfRadius: depth == 3 ? 1.25 : 0.65)
            star.fillColor = (index % 7 == 0 ? cyan : .white).withAlphaComponent(0.15 + depth * 0.18)
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat((index * 137 + 29) % 997) / 997 * size.width,
                                    y: CGFloat((index * 233 + 71) % 991) / 991 * size.height)
            starfield.addChild(star)
            stars.append((star, depth * 20))
        }
        for x in [size.width * 0.12, size.width * 0.88] {
            let line = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
            line.position = CGPoint(x: x, y: size.height / 2)
            line.fillColor = cyan.withAlphaComponent(0.07)
            line.strokeColor = .clear
            starfield.addChild(line)
        }
    }

    private func polygon(_ points: [CGPoint], fill: UIColor, stroke: UIColor, width: CGFloat = 1.4) -> SKShapeNode {
        let path = CGMutablePath()
        if let first = points.first { path.move(to: first) }
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = width
        return node
    }

    private func makePlayer() -> SKNode {
        let node = SKNode()
        node.name = "ship"
        let wing = polygon([CGPoint(x: 0, y: 34), CGPoint(x: 10, y: 4), CGPoint(x: 30, y: -16),
                            CGPoint(x: 28, y: -24), CGPoint(x: 10, y: -17), CGPoint(x: 0, y: -24),
                            CGPoint(x: -10, y: -17), CGPoint(x: -28, y: -24), CGPoint(x: -30, y: -16),
                            CGPoint(x: -10, y: 4)],
                           fill: UIColor(red: 0.09, green: 0.22, blue: 0.32, alpha: 1), stroke: cyan)
        wing.glowWidth = 2
        node.addChild(wing)
        node.addChild(polygon([CGPoint(x: 0, y: 30), CGPoint(x: 8, y: -12), CGPoint(x: 0, y: -19), CGPoint(x: -8, y: -12)],
                              fill: UIColor(red: 0.75, green: 0.91, blue: 0.96, alpha: 1), stroke: .white))
        node.addChild(polygon([CGPoint(x: 0, y: 17), CGPoint(x: 4, y: 0), CGPoint(x: 0, y: -7), CGPoint(x: -4, y: 0)],
                              fill: cyan, stroke: cyan))
        for x in [-15.0, 15.0] {
            let exhaust = polygon([CGPoint(x: -4, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 0, y: -27)],
                                  fill: cyan.withAlphaComponent(0.7), stroke: cyan.withAlphaComponent(0.2))
            exhaust.position = CGPoint(x: x, y: -20)
            exhaust.glowWidth = 5
            exhaust.zPosition = -1
            exhaust.run(.repeatForever(.sequence([.scaleY(to: 0.55, duration: 0.09), .scaleY(to: 1, duration: 0.12)])))
            node.addChild(exhaust)
        }
        let shield = SKShapeNode(circleOfRadius: 39)
        shield.name = "shield"
        shield.strokeColor = cyan.withAlphaComponent(0.7)
        shield.fillColor = cyan.withAlphaComponent(0.04)
        shield.glowWidth = 4
        shield.lineWidth = 1.2
        node.addChild(shield)
        return node
    }

    private func makeEnemy(_ kind: EnemyKind) -> SKNode {
        let node = SKNode()
        let tint: UIColor = kind == .scout ? coral : UIColor(red: 0.77, green: 0.48, blue: 1, alpha: 1)
        let hull = polygon([CGPoint(x: 0, y: -25), CGPoint(x: 9, y: -7), CGPoint(x: 23, y: 6),
                            CGPoint(x: 19, y: 20), CGPoint(x: 8, y: 11), CGPoint(x: 0, y: 18),
                            CGPoint(x: -8, y: 11), CGPoint(x: -19, y: 20), CGPoint(x: -23, y: 6), CGPoint(x: -9, y: -7)],
                           fill: tint.withAlphaComponent(0.2), stroke: tint)
        hull.glowWidth = 1.4
        node.addChild(hull)
        let core = SKShapeNode(rectOf: CGSize(width: 5, height: 18), cornerRadius: 2)
        core.fillColor = tint
        core.strokeColor = .white.withAlphaComponent(0.7)
        core.glowWidth = 3
        node.addChild(core)
        if kind == .boss {
            node.setScale(2.3)
            for x in [-25.0, 25.0] {
                let cannon = SKShapeNode(rectOf: CGSize(width: 9, height: 28), cornerRadius: 2)
                cannon.position = CGPoint(x: x, y: -3)
                cannon.fillColor = UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1)
                cannon.strokeColor = tint
                node.addChild(cannon)
            }
        } else if kind == .armored { node.setScale(1.3) }
        return node
    }

    private func makeProjectile(hostile: Bool) -> SKNode {
        let node = hostile ? SKShapeNode(circleOfRadius: 4.5) : SKShapeNode(rectOf: CGSize(width: 3, height: 18), cornerRadius: 1.5)
        let tint = hostile ? UIColor(red: 1, green: 0.62, blue: 0.29, alpha: 1) : cyan
        node.fillColor = hostile ? tint : .white
        node.strokeColor = tint
        node.glowWidth = hostile ? 3 : 4
        node.zPosition = 2
        return node
    }

    private func makeSupply(_ kind: SupplyKind) -> SKNode {
        let node = SKNode()
        let color: UIColor = kind == .weapon ? cyan : kind == .shield ? .systemGreen : .systemOrange
        let border = SKShapeNode(rectOf: CGSize(width: 25, height: 25), cornerRadius: 6)
        border.fillColor = UIColor(red: 0.04, green: 0.1, blue: 0.14, alpha: 1)
        border.strokeColor = color
        border.glowWidth = 4
        node.addChild(border)
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = kind == .weapon ? "P" : kind == .shield ? "+" : "B"
        label.fontSize = 16
        label.fontColor = color
        label.verticalAlignmentMode = .center
        node.addChild(label)
        node.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.45), .scale(to: 1, duration: 0.45)])))
        return node
    }

    private func handleEvents() {
        for event in game.drainEvents() {
            session?.feedback(event)
            switch event {
            case let .explosion(position, large): explode(at: position, large: large)
            case .hit:
                flash(color: coral, alpha: 0.17)
                world.run(.sequence([.moveBy(x: 4, y: 0, duration: 0.04), .moveBy(x: -8, y: 0, duration: 0.04), .move(to: .zero, duration: 0.06)]))
            case .bomb: flash(color: cyan, alpha: 0.6)
            case let .wave(stage): banner("SECTOR  " + String(format: "%02d", stage), color: cyan)
            case .boss: banner("WARNING  /  BOSS", color: coral)
            case let .collected(kind):
                banner(kind == .weapon ? "火力升级" : kind == .shield ? "护盾恢复" : "炸弹补给", color: cyan)
            case .gameOver: break
            }
        }
    }

    private func explode(at point: FlightPoint, large: Bool) {
        let position = CGPoint(x: point.x, y: point.y)
        let ring = SKShapeNode(circleOfRadius: 8)
        ring.position = position
        ring.strokeColor = large ? cyan : .systemOrange
        ring.lineWidth = 2
        ring.glowWidth = 4
        effects.addChild(ring)
        ring.run(.sequence([.group([.scale(to: large ? 9 : 4, duration: 0.4), .fadeOut(withDuration: 0.4)]), .removeFromParent()]))
        for index in 0..<(large ? 18 : 10) {
            let spark = SKShapeNode(rectOf: CGSize(width: 2, height: 6))
            spark.fillColor = index % 3 == 0 ? cyan : .systemOrange
            spark.strokeColor = .clear
            spark.position = position
            let angle = Double(index) * 2.399
            let distance = Double(large ? 65 : 30) + Double(index % 5) * 8
            spark.zRotation = angle
            effects.addChild(spark)
            spark.run(.sequence([.group([.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.45), .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
        }
    }

    private func flash(color: UIColor, alpha: CGFloat) {
        let node = SKSpriteNode(color: color, size: size)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.alpha = alpha
        effects.addChild(node)
        node.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
    }

    private func banner(_ text: String, color: UIColor) {
        effects.childNode(withName: "banner")?.removeFromParent()
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.name = "banner"
        label.text = text
        label.fontSize = 18
        label.fontColor = color
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.64)
        effects.addChild(label)
        label.run(.sequence([.wait(forDuration: 1.4), .group([.fadeOut(withDuration: 0.5), .moveBy(x: 0, y: 15, duration: 0.5)]), .removeFromParent()]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard game.phase == .playing, activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        lastTouchPosition = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard game.phase == .playing, let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        game.movePlayer(to: FlightPoint(x: game.player.x + Double(point.x - lastTouchPosition.x) * 1.15,
                                       y: game.player.y + Double(point.y - lastTouchPosition.y) * 1.15))
        lastTouchPosition = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) { activeTouch = nil }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
