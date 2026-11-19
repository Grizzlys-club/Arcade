import SpriteKit

/// Ballhalten: tap the ball to keep it in the air. Longest chain wins, dropping = out.
final class JuggleGame: MiniScene {

    private final class State {
        var ball: SKSpriteNode!
        var glow: SKSpriteNode!
        var shadow: SKSpriteNode!
        var stick: SKSpriteNode!
        var big: SKLabelNode!
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var r: CGFloat = 16
        var chain = 0
        var cooldown: Double = 0
        var falling = false
        var cpuDecided = false
        var cpuTriggerY: CGFloat = 0
        var cpuWillHit = true
        var hint: SKNode?
    }

    private var st: [State] = []
    private var hadHumans = false
    private var fastForward = false

    override func setupGame() {
        duration = 60
        hadHumans = seats.contains { !$0.isCPU }
        for s in seats {
            let o = State()
            st.append(o)
            let w = s.w, h = s.h
            let scale = min(1, w / 300)

            let floor = SKSpriteNode(texture: JuggleGame.floorTexture(w, h), size: s.size)
            floor.zPosition = -10
            s.field.addChild(floor)

            // big chain counter in the background
            let big = label("0", size: min(110, w * 0.45), color: s.color)
            big.alpha = 0.18
            big.position = CGPoint(x: 0, y: h * 0.08)
            big.zPosition = -5
            s.field.addChild(big)
            o.big = big

            // stick lying at the player's edge (decor, follows the last kick)
            let stick = SKSpriteNode(texture: JuggleGame.stickTexture(s.color), size: CGSize(width: 90 * max(0.8, scale), height: 26 * max(0.8, scale)))
            stick.position = CGPoint(x: 0, y: -h / 2 + 18)
            stick.zPosition = 3
            s.field.addChild(stick)
            o.stick = stick

            // ball
            o.r = 17 * max(0.8, scale)
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: o.r * 5, height: o.r * 5))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.55
            glow.zPosition = 5
            s.field.addChild(glow)
            o.glow = glow
            let sh = SKSpriteNode(texture: Gfx.shadow, size: CGSize(width: o.r * 2.4, height: o.r * 0.8))
            sh.zPosition = 2
            s.field.addChild(sh)
            o.shadow = sh
            let b = SKSpriteNode(texture: Gfx.ball(16), size: CGSize(width: o.r * 2, height: o.r * 2))
            b.zPosition = 6
            s.field.addChild(b)
            o.ball = b
            o.pos = CGPoint(x: 0, y: h * 0.12)
            place(s, o)

            if !s.isCPU {
                let hint = SKNode()
                let l = label("BALL ANTIPPEN!", size: 16, color: s.color)
                l.position = CGPoint(x: 0, y: -h * 0.18)
                hint.addChild(l)
                hint.zPosition = 50
                hint.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.4, duration: 0.4), SKAction.fadeAlpha(to: 1, duration: 0.4)])))
                s.field.addChild(hint)
                o.hint = hint
            }
        }
    }

    private static func floorTexture(_ w: CGFloat, _ h: CGFloat) -> SKTexture {
        return Gfx.texture("juggle_floor\(Int(w))x\(Int(h))", size: CGSize(width: w, height: h), scale: 1) { ctx in
            Gfx.gradientColors(UIColor(red: 0.12, green: 0.08, blue: 0.2, alpha: 0.85), UIColor(red: 0.04, green: 0.03, blue: 0.08, alpha: 0.9), in: ctx, size: CGSize(width: w, height: h))
            ctx.setFillColor(UIColor(white: 1, alpha: 0.05).cgColor)
            ctx.fill(CGRect(x: 0, y: h - 34, width: w, height: 34))
        }
    }

    private static func stickTexture(_ c: UIColor) -> SKTexture {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Gfx.texture("juggle_stick\(Int(r * 255))_\(Int(g * 255))_\(Int(b * 255))", size: CGSize(width: 90, height: 26)) { ctx in
            // shaft
            ctx.setStrokeColor(UIColor(white: 0.92, alpha: 1).cgColor)
            ctx.setLineWidth(5)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: 4, y: 6))
            ctx.addLine(to: CGPoint(x: 66, y: 16))
            ctx.strokePath()
            // blade
            ctx.setFillColor(c.cgColor)
            let blade = UIBezierPath(roundedRect: CGRect(x: 62, y: 10, width: 26, height: 12), cornerRadius: 5)
            ctx.addPath(blade.cgPath)
            ctx.fillPath()
            // grip
            ctx.setStrokeColor(UIColor(white: 0.15, alpha: 1).cgColor)
            ctx.setLineWidth(6)
            ctx.move(to: CGPoint(x: 4, y: 6))
            ctx.addLine(to: CGPoint(x: 20, y: 8.6))
            ctx.strokePath()
        }
    }

    private func place(_ s: Seat, _ o: State) {
        o.ball.position = o.pos
        o.glow.position = o.pos
        let floorY = -s.h / 2 + 10
        let height = max(0, o.pos.y - floorY)
        o.shadow.position = CGPoint(x: o.pos.x, y: floorY)
        let k = max(0.3, 1 - height / s.h)
        o.shadow.setScale(k)
        o.shadow.alpha = k
    }

    private func gravity(_ s: Seat, _ o: State) -> CGFloat {
        return s.h * 2.2 * (1 + CGFloat(o.chain) * 0.035)
    }

    override func gameStarted() {
        for s in seats {
            st[s.index].falling = true
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let o = st[seat.index]
        let d = hypot(at.x - o.pos.x, at.y - o.pos.y)
        if d < o.r * 2.2 + 26 {
            kick(seat, o, offset: (o.pos.x - at.x) / (o.r * 2.2 + 26))
        }
    }

    private func kick(_ s: Seat, _ o: State, offset: CGFloat) {
        if o.cooldown > 0 || o.vel.dy > 0 || !o.falling || !s.alive || phase != .playing { return }
        o.cooldown = 0.14
        o.chain += 1
        setScore(s, o.chain)
        let g = gravity(s, o)
        // apex at about 60% of the zone height above the current point (but stay below the HUD)
        let maxY = s.h / 2 - 40 - o.r
        let apex = min(maxY, o.pos.y + s.h * 0.55)
        let rise = max(s.h * 0.2, apex - o.pos.y)
        o.vel.dy = sqrt(2 * g * rise)
        o.vel.dx = max(-1, min(1, offset)) * s.w * 0.9 + CGFloat.random(in: -20...20)
        o.cpuDecided = false
        o.ball.run(SKAction.sequence([SKAction.scale(to: 1.25, duration: 0.05), SKAction.scale(to: 1.0, duration: 0.1)]))
        o.big.text = "\(o.chain)"
        o.big.removeAllActions()
        o.big.run(SKAction.sequence([SKAction.scale(to: 1.15, duration: 0.06), SKAction.scale(to: 1.0, duration: 0.12)]))
        let stickMove = SKAction.moveTo(x: max(-s.w / 2 + 45, min(s.w / 2 - 45, o.pos.x)), duration: 0.12)
        o.stick.run(stickMove)
        s.burst(at: CGPoint(x: o.pos.x, y: o.pos.y - o.r), color: s.color, count: 6, speed: 70)
        if o.chain % 10 == 0 {
            s.floatText("\(o.chain)!", at: CGPoint(x: o.pos.x, y: o.pos.y + 30), color: UIColor.yellow, size: 24)
            Sfx.shared.play("coin")
        } else {
            Sfx.shared.play("bounce")
        }
        if !s.isCPU { Haptic.tap(.medium) }
        if let h = o.hint {
            h.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
            o.hint = nil
        }
    }

    override func gameUpdate(_ dtIn: Double) {
        if hadHumans && !humansAlive && !fastForward && aliveSeats.count > 0 {
            fastForward = true
            bannerAll("⏩", color: .white, size: 40, duration: 0.6)
        }
        let dt = fastForward ? dtIn * 3 : dtIn
        let fdt = CGFloat(dt)
        for s in seats where s.alive {
            let o = st[s.index]
            if !o.falling { continue }
            o.cooldown -= dt
            let g = gravity(s, o)
            o.vel.dy -= g * fdt
            o.pos.x += o.vel.dx * fdt
            o.pos.y += o.vel.dy * fdt
            o.vel.dx *= (1 - 0.4 * fdt)
            // walls
            let wx = s.w / 2 - o.r
            if o.pos.x < -wx { o.pos.x = -wx; o.vel.dx = abs(o.vel.dx) * 0.8; Sfx.shared.play("tick") }
            if o.pos.x > wx { o.pos.x = wx; o.vel.dx = -abs(o.vel.dx) * 0.8; Sfx.shared.play("tick") }
            // ceiling (below HUD strip)
            let top = s.h / 2 - 34 - o.r
            if o.pos.y > top { o.pos.y = top; o.vel.dy = -abs(o.vel.dy) * 0.5 }
            o.ball.zRotation -= o.vel.dx * fdt * 0.05
            place(s, o)

            if s.isCPU { cpu(s, o) }

            if o.pos.y < -s.h / 2 - o.r {
                drop(s, o)
            }
        }
        checkEnd()
    }

    private func cpu(_ s: Seat, _ o: State) {
        if o.vel.dy >= 0 { return }
        if !o.cpuDecided {
            o.cpuDecided = true
            o.cpuTriggerY = -s.h / 2 + s.h * CGFloat.random(in: 0.18...0.32)
            let p = min(0.99, 0.66 + s.skill * 0.3) - Double(o.chain) * 0.004 * (1.1 - s.skill)
            o.cpuWillHit = Double.random(in: 0...1) < max(0.5, p)
        }
        if o.cpuWillHit && o.pos.y <= o.cpuTriggerY {
            // aim back to the middle a bit
            let offset = -o.pos.x / (s.w * 0.6) + CGFloat.random(in: -0.25...0.25)
            kick(s, o, offset: offset)
        }
    }

    private func drop(_ s: Seat, _ o: State) {
        o.falling = false
        o.ball.removeAllActions()
        o.ball.alpha = 0
        o.glow.alpha = 0
        o.shadow.alpha = 0
        s.flash(UIColor.red, alpha: 0.3)
        s.shake(5)
        Sfx.shared.play("miss")
        if !s.isCPU { Haptic.bad() }
        s.knockOut("RAUS · \(o.chain)")
    }

    private func checkEnd() {
        if phase != .playing { return }
        let alive = aliveSeats
        if alive.isEmpty { finishGame(); return }
        if alive.count == 1 && n > 1 {
            let a = alive[0]
            let others = seats.filter { $0 !== a }.map { $0.score }.max() ?? 0
            if a.score > others { finishGame() }
        }
    }
}
