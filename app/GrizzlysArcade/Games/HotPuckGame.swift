import SpriteKit

/// Heisser Puck: hot potato. Tap your strip N times to pass the burning puck on before it explodes.
final class HotPuckGame: MiniScene {
    override class var layout: SeatLayout { return .arena }
    override class var stripThickness: CGFloat { return 104 }

    private final class Holder {
        var lives = 3
        var hearts: [SKLabelNode] = []
        var button: SKSpriteNode!
        var counter: SKLabelNode!
        var baseText = ""
        var outOrder = -1
        var cpuTimer: Double = 0
    }

    private var holders: [Holder] = []
    private let puck = SKNode()
    private var puckGlow: SKSpriteNode!
    private var puckCore: SKSpriteNode!
    private var flame: SKSpriteNode!
    private var holder = -1
    private var need = 3
    private var flying = false
    private var fuse: Double = 8
    private var roundTime: Double = 0
    private var tickTimer: Double = 0
    private var roundActive = false
    private var outCount = 0
    private var passes = 0

    override func setupGame() {
        duration = 75

        // table in the arena
        let tTex = Gfx.texture("hotpuck_table_\(Int(arena.width))x\(Int(arena.height))", size: arena.size, scale: 1) { ctx in
            let s = self.arena.size
            Gfx.gradientColors(UIColor(red: 0.14, green: 0.05, blue: 0.05, alpha: 1), UIColor(red: 0.05, green: 0.02, blue: 0.04, alpha: 1), in: ctx, size: s)
            ctx.setStrokeColor(UIColor(red: 1, green: 0.4, blue: 0.1, alpha: 0.16).cgColor)
            ctx.setLineWidth(2)
            for i in 1..<6 {
                let r = CGFloat(i) * min(s.width, s.height) * 0.09
                ctx.strokeEllipse(in: CGRect(x: s.width / 2 - r, y: s.height / 2 - r, width: r * 2, height: r * 2))
            }
        }
        let table = SKSpriteNode(texture: tTex, size: arena.size)
        table.position = CGPoint(x: arena.midX, y: arena.midY)
        table.zPosition = -20
        world.addChild(table)
        let logo = SKSpriteNode(imageNamed: "logo")
        let d = min(arena.width, arena.height) * 0.5
        logo.size = CGSize(width: d, height: d)
        logo.position = CGPoint(x: arena.midX, y: arena.midY)
        logo.alpha = 0.12
        logo.zPosition = -19
        world.addChild(logo)

        for s in seats {
            let h = Holder()
            let bw = min(s.w - 40, 220)
            let btn = MiniScene.button(s.isCPU ? "CPU" : "TIPPEN!", w: bw, h: min(54, s.h - 44), color: s.color.withAlphaComponent(0.5), fontSize: 18)
            btn.position = CGPoint(x: 0, y: -8)
            btn.zPosition = 410
            s.node.addChild(btn)
            h.button = btn
            h.counter = btn.children.compactMap { $0 as? SKLabelNode }.first ?? MiniScene.label("", size: 18)
            h.baseText = s.isCPU ? "CPU" : "TIPPEN!"
            for i in 0..<3 {
                let heart = MiniScene.label("♥", size: 16, color: UIColor(red: 1, green: 0.25, blue: 0.3, alpha: 1))
                heart.position = CGPoint(x: -s.w / 2 + 18 + CGFloat(i) * 17, y: -s.h / 2 + 12)
                heart.zPosition = 412
                s.node.addChild(heart)
                h.hearts.append(heart)
            }
            setScore(s, 3)
            holders.append(h)
        }

        // the puck
        puckGlow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 90, height: 90))
        puckGlow.color = UIColor(red: 1, green: 0.45, blue: 0.05, alpha: 1)
        puckGlow.colorBlendFactor = 1
        puckGlow.blendMode = .add
        puck.addChild(puckGlow)
        flame = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 50, height: 70))
        flame.color = UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
        flame.colorBlendFactor = 1
        flame.blendMode = .add
        flame.alpha = 0.6
        flame.position = CGPoint(x: 0, y: 14)
        puck.addChild(flame)
        puckCore = SKSpriteNode(texture: Gfx.circle(18, UIColor(white: 0.08, alpha: 1), ring: UIColor(red: 1, green: 0.5, blue: 0.1, alpha: 1)), size: CGSize(width: 36, height: 36))
        puckCore.zPosition = 1
        puck.addChild(puckCore)
        let fire = MiniScene.label("🔥", size: 18)
        fire.zPosition = 2
        puck.addChild(fire)
        puck.position = CGPoint(x: arena.midX, y: arena.midY)
        puck.zPosition = 50
        world.addChild(puck)
        puck.run(SKAction.repeatForever(SKAction.sequence([SKAction.rotate(byAngle: 0.15, duration: 0.05), SKAction.rotate(byAngle: -0.15, duration: 0.05)])))
    }

    override func gameStarted() {
        newRound(first: true)
    }

    private func holdPoint(_ s: Seat) -> CGPoint {
        return s.toScene(CGPoint(x: 0, y: s.h / 2 + 46))
    }

    private func newRound(first: Bool) {
        let alive = aliveSeats
        guard alive.count > 1, let start = alive.randomElement() else { return }
        fuse = Double.random(in: 5...11)
        roundTime = 0
        roundActive = true
        tickTimer = 0
        puck.alpha = 1
        puck.setScale(0.1)
        puck.position = CGPoint(x: arena.midX, y: arena.midY)
        puck.run(SKAction.scale(to: 1, duration: 0.25))
        give(to: start, from: nil)
    }

    private func give(to s: Seat, from: Seat?) {
        flying = true
        holder = s.index
        need = Int.random(in: 3...6)
        for h in holders { h.counter.text = h.baseText }
        let target = holdPoint(s)
        let move = SKAction.move(to: target, duration: from == nil ? 0.35 : 0.22)
        move.timingMode = .easeOut
        puck.run(SKAction.sequence([move, SKAction.run { [weak self] in
            guard let self = self else { return }
            self.flying = false
            self.updateHolderUI()
        }]), withKey: "fly")
        updateHolderUI()
    }

    private func updateHolderUI() {
        for s in seats {
            let h = holders[s.index]
            let isHolder = s.index == holder && s.alive
            h.button.removeAction(forKey: "pulse")
            if isHolder {
                h.button.alpha = 1
                h.button.colorBlendFactor = 0
                h.counter.text = "\(h.baseText) \(need)×"
                h.button.run(SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.06, duration: 0.15), SKAction.scale(to: 1.0, duration: 0.15)])), withKey: "pulse")
            } else {
                h.button.alpha = s.alive ? 0.45 : 0.15
                h.button.setScale(1)
                h.counter.text = h.baseText
            }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        tap(seat)
    }

    private func tap(_ s: Seat) {
        guard roundActive, !flying, s.index == holder, s.alive else { return }
        need -= 1
        Sfx.shared.play("tap")
        if !s.isCPU { Haptic.tap() }
        let h = holders[s.index]
        h.counter.text = "\(h.baseText) \(max(0, need))×"
        h.button.run(SKAction.sequence([SKAction.scale(to: 0.9, duration: 0.04), SKAction.scale(to: 1.0, duration: 0.06)]))
        puckCore.run(SKAction.sequence([SKAction.scale(to: 1.25, duration: 0.04), SKAction.scale(to: 1.0, duration: 0.06)]))
        if need <= 0 {
            let others = aliveSeats.filter { $0.index != s.index }
            if let t = others.randomElement() {
                passes += 1
                Sfx.shared.play("kick")
                give(to: t, from: s)
            }
        }
    }

    override func gameUpdate(_ dt: Double) {
        guard roundActive else { return }
        roundTime += dt
        // visuals heat up
        let heat = CGFloat(min(1, roundTime / 9))
        puckGlow.setScale(1 + heat * 1.2 + CGFloat(sin(roundTime * 18)) * 0.08 * (1 + heat))
        puckGlow.alpha = 0.6 + heat * 0.4
        flame.setScale(1 + heat)
        tickTimer -= dt
        if tickTimer <= 0 {
            tickTimer = max(0.12, 0.6 - roundTime * 0.055)
            Sfx.shared.play("tick")
        }
        // CPU
        for s in seats where s.isCPU && s.alive && s.index == holder && !flying {
            let h = holders[s.index]
            h.cpuTimer -= dt
            if h.cpuTimer <= 0 {
                h.cpuTimer = (0.36 - 0.22 * s.skill) * Double.random(in: 0.75...1.3)
                tap(s)
            }
        }
        if roundTime >= fuse && !flying {
            explode()
        }
    }

    private func explode() {
        roundActive = false
        guard holder >= 0 && holder < seats.count else { return }
        let s = seats[holder]
        let h = holders[s.index]
        h.lives -= 1
        if h.lives >= 0 && h.lives < h.hearts.count {
            h.hearts[h.lives].run(SKAction.group([SKAction.scale(to: 2, duration: 0.2), SKAction.fadeAlpha(to: 0.1, duration: 0.2)]))
        }
        setScore(s, max(0, h.lives))
        Sfx.shared.play("stomp")
        Sfx.shared.play("lose")
        if !s.isCPU { Haptic.bad() }
        flashAll(UIColor(red: 1, green: 0.5, blue: 0.1, alpha: 1), alpha: 0.5)
        world.run(SKAction.sequence([SKAction.moveBy(x: 8, y: 4, duration: 0.03), SKAction.moveBy(x: -14, y: -6, duration: 0.05), SKAction.moveBy(x: 6, y: 2, duration: 0.04)]))
        let p = puck.position
        for i in 0..<28 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 10, height: 10))
            d.color = i % 2 == 0 ? UIColor(red: 1, green: 0.6, blue: 0.1, alpha: 1) : UIColor.yellow
            d.colorBlendFactor = 1
            d.blendMode = .add
            d.position = p
            d.zPosition = 60
            world.addChild(d)
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: 60...190)
            d.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: cos(a) * r, y: sin(a) * r, duration: 0.6), SKAction.fadeOut(withDuration: 0.6), SKAction.scale(to: 0.3, duration: 0.6)]), SKAction.removeFromParent()]))
        }
        let boom = MiniScene.label("💥", size: 70)
        boom.position = p
        boom.zPosition = 70
        world.addChild(boom)
        boom.run(SKAction.sequence([SKAction.scale(to: 1.6, duration: 0.3), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
        puck.alpha = 0
        s.flash(UIColor.orange, alpha: 0.6)
        s.banner("BUMM!", color: .orange, size: 30, duration: 0.6)
        if h.lives <= 0 {
            h.outOrder = outCount
            outCount += 1
            s.knockOut("RAUS")
        }
        holder = -1
        updateHolderUI()
        if aliveSeats.count <= 1 {
            finishGame(scores: finalScores())
            return
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 1.6), SKAction.run { [weak self] in
            guard let self = self, self.phase == .playing else { return }
            self.newRound(first: false)
        }]))
    }

    private func finalScores() -> [Int] {
        return seats.map { s in
            let h = holders[s.index]
            let survival = h.outOrder >= 0 ? h.outOrder : n
            return max(0, h.lives) * 100 + survival * 10
        }
    }

    override func timeUp() {
        finishGame(scores: finalScores())
    }
}
