import Foundation

@main
struct GameEngineChecks {
    static func run(_ game: inout GameEngine, seconds: Double) {
        for _ in 0..<Int(seconds * 120) {
            game.advance(1.0 / 120)
            _ = game.drainEvents()
        }
    }

    static func main() {
        var game = GameEngine(seed: 42)
        game.advance(2)
        precondition(game.projectiles.isEmpty && game.phase == .ready)
        game.useBomb()
        precondition(game.bombs == 3, "Cannot spend bombs before starting")
        game.resize(width: 375, height: 812)
        game.start()
        precondition(game.player.x == 187.5 && game.lives == 3)
        game.movePlayer(to: FlightPoint(x: -100, y: 2000))
        precondition(game.player.x == 25 && game.player.y == 657, "Movement must stay inside the playfield")
        game.movePlayer(to: FlightPoint(x: 180, y: 155))
        run(&game, seconds: 1.2)
        precondition(!game.projectiles.isEmpty && !game.enemies.isEmpty, "Automatic firing and enemy spawns")
        game.pause()
        let pausedShots = game.projectiles.map(\.position.y)
        let pausedEnemies = game.enemies.map(\.position.y)
        game.advance(10)
        game.useBomb()
        precondition(game.projectiles.map(\.position.y) == pausedShots && game.enemies.map(\.position.y) == pausedEnemies)
        precondition(game.bombs == 3 && game.phase == .paused)
        game.resume()
        let expectedPoints = game.enemies.reduce(0) { $0 + $1.points }
        let oldScore = game.score
        game.useBomb()
        precondition(game.score == oldScore + expectedPoints && game.enemies.isEmpty, "Bomb kills must award score once")
        precondition(game.projectiles.allSatisfy { !$0.hostile })
        game.useBomb()
        game.useBomb()
        game.useBomb()
        precondition(game.bombs == 0, "Bomb inventory cannot go below zero")
        game.pause()
        game.start()
        precondition(game.phase == .playing && game.score == 0 && game.stage == 1 && game.bombs == 3)
        precondition(game.enemies.isEmpty && game.projectiles.isEmpty && game.supplies.isEmpty)

        // A stationary player must eventually take damage and reach game over.
        var mortal = GameEngine(seed: 12)
        mortal.start()
        var damageCount = 0
        var previousLives = 3
        for _ in 0..<120 * 180 {
            mortal.advance(1.0 / 120)
            if mortal.lives < previousLives {
                damageCount += 1
                previousLives = mortal.lives
                precondition(mortal.invulnerability > 1.9, "Damage grants a recovery window")
            }
            _ = mortal.drainEvents()
            if mortal.phase == .gameOver { break }
        }
        precondition(mortal.phase == .gameOver && mortal.lives == 0 && damageCount == 3)
        let finalScore = mortal.score
        mortal.advance(5)
        precondition(mortal.score == finalScore, "Game over must freeze simulation")

        // Fly along the upper boundary, above enemy fire, to verify stage progression.
        var campaign = GameEngine(seed: 7)
        campaign.start()
        campaign.movePlayer(to: FlightPoint(x: 25, y: 2000))
        for _ in 0..<120 * 45 {
            let candidates = stride(from: 25.0, through: campaign.width - 25, by: 15).map {
                FlightPoint(x: $0, y: campaign.height - 155)
            }
            let threats = campaign.enemies.map(\.position) + campaign.projectiles.filter(\.hostile).map(\.position)
            let safest = candidates.max { a, b in
                (threats.map { $0.distance(to: a) }.min() ?? 1000) <
                (threats.map { $0.distance(to: b) }.min() ?? 1000)
            }!
            campaign.movePlayer(to: safest)
            campaign.advance(1.0 / 120)
            _ = campaign.drainEvents()
        }
        precondition(campaign.phase == .playing && campaign.stage == 3 && campaign.boss != nil,
                     "Every third sector must spawn a boss")
        let bossHP = campaign.boss!.health
        campaign.useBomb()
        precondition(campaign.boss!.health == bossHP - 60, "Boss takes bounded bomb damage")
        campaign.useBomb()
        campaign.useBomb()
        precondition(campaign.boss == nil && campaign.stage == 4, "Boss defeat advances campaign")

        // Pursue visible supplies without bypassing the collection path.
        var collector = GameEngine(seed: 5)
        collector.start()
        collector.movePlayer(to: FlightPoint(x: 25, y: 2000))
        for _ in 0..<120 * 28 {
            if let supply = collector.supplies.first {
                collector.movePlayer(to: supply.position)
                if collector.invulnerability <= 0 && collector.bombs > 0 { collector.useBomb() }
            } else {
                let threats = collector.enemies.map(\.position)
                let candidates = stride(from: 25.0, through: collector.width - 25, by: 15).map {
                    FlightPoint(x: $0, y: collector.height - 155)
                }
                let safest = candidates.max { a, b in
                    (threats.map { $0.distance(to: a) }.min() ?? 1000) <
                    (threats.map { $0.distance(to: b) }.min() ?? 1000)
                }!
                collector.movePlayer(to: safest)
            }
            collector.advance(1.0 / 120)
            _ = collector.drainEvents()
            if collector.weaponLevel == 3 { break }
        }
        precondition(collector.weaponLevel == 3, "Collecting P supplies upgrades the weapon")

        var smooth = GameEngine(seed: 99)
        var coarse = GameEngine(seed: 99)
        smooth.start(); coarse.start()
        for _ in 0..<240 { smooth.advance(1.0 / 120) }
        for _ in 0..<60 { coarse.advance(1.0 / 30) }
        precondition(smooth.score == coarse.score && smooth.enemies.count == coarse.enemies.count)
        for (a, b) in zip(smooth.enemies, coarse.enemies) {
            precondition(a.position.distance(to: b.position) < 0.001, "Frame splitting must preserve motion")
        }
        print("PASS: lifecycle, movement bounds, automatic combat, bomb scoring and inventory, damage immunity, game over, boss progression, power-ups, frame-rate independence")
    }
}
