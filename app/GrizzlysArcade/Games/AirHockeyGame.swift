import SpriteKit

/// Air-Hockey for 2–4 players on one shared rink. Every player defends a goal on his edge.
final class AirHockeyGame: MiniScene {
    override class var layout: SeatLayout { return .arena }
    override class var stripThickness: CGFloat { return 58 }

    private final class Paddle {
        let node = SKNode()
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var target = CGPoint.zero
        var home = CGPoint.zero
        var region = CGRect.zero
        var lives = 3
        var goals = 0
        var outOrder = -1
        var hearts: [SKLabelNode] = []
        var goalNode: SKSpriteNode?
        var wallNode: SKSpriteNode?
        var touch: UITouch?
        var cpuThink: Double = 0
        var cpuAim = CGPoint.zero
    }

    private var paddles: [Paddle] = []
    private let puck = SKNode()
    private var puckPos = CGPoint.zero
    private var puckVel = CGVector.zero
    private var lastTouch: Int = -1
    private var puckLive = false
    private var trailTimer: Double = 0
    private var outCount = 0
    private var rink = CGRect.zero
    private var paddleR: CGFloat = 26
    private let puckR: CGFloat = 13
    private var goalW: CGFloat = 120
    private let maxSpeed: CGFloat = 1050

    // MARK: setup

    override func setupGame() {
        _ = Gfx.glow
        duration = 75
        rink = arena.insetBy(dx: 6, dy: 6)
        paddleR = n >= 3 ? 23 : 27
        goalW = min(rink.width, rink.height) * (n >= 3 ? 0.42 : 0.4)

        // ice
        let iceTex = Gfx.texture("airhockey_ice_\(Int(rink.width))x\(Int(rink.height))", size: rink.size, scale: 1.5) { ctx in
            let s = self.rink.size
            Gfx.gradientColors(UIColor(red: 0.08, green: 0.16, blue: 0.3, alpha: 1), UIColor(red: 0.05, green: 0.09, blue: 0.2, alpha: 1), in: ctx, size: s)
            ctx.setStrokeColor(UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 0.22).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: s.width / 2 - 48, y: s.height / 2 - 48, width: 96, height: 96))
            ctx.move(to: CGPoint(x: 0, y: s.height / 2))
            ctx.addLine(to: CGPoint(x: s.width, y: s.height / 2))
            ctx.strokePath()
            // tiny air holes
            ctx.setFillColor(UIColor(white: 1, alpha: 0.06).cgColor)
            var y: CGFloat = 10
            while y < s.height {
                var x: CGFloat = 10
                while x < s.width {
                    ctx.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                    x += 18
                }
                y += 18
            }
        }
        let ice = SKSpriteNode(texture: iceTex, size: rink.size)
        ice.position = CGPoint(x: rink.midX, y: rink.midY)
        ice.zPosition = -20
        world.addChild(ice)
        let logo = SKSpriteNode(imageNamed: "logo")
        let d = min(rink.width, rink.height) * 0.55
        logo.size = CGSize(width: d, height: d)
        logo.position = CGPoint(x: rink.midX, y: rink.midY)
        logo.alpha = 0.1
        logo.zPosition = -19
        world.addChild(logo)

        // boards
        let board = SKShapeNode(rect: rink, cornerRadius: 14)
        board.strokeColor = UIColor(red: 0.5, green: 0.9, blue: 1, alpha: 0.9)
        board.lineWidth = 4
        board.glowWidth = 6
        board.fillColor = .clear
        board.zPosition = -10
        world.addChild(board)

        for s in seats {
            let p = Paddle()
            let dir = s.dirToScene(CGVector(dx: 0, dy: 1)) // into the rink
            let gc = goalCenter(s)
            let depth: CGFloat
            switch s.edge {
            case .bottom, .top: depth = rink.height * (n >= 3 ? 0.33 : 0.46)
            case .left, .right: depth = rink.width * 0.4
            }
            p.home = CGPoint(x: gc.x + dir.dx * (paddleR + 34), y: gc.y + dir.dy * (paddleR + 34))
            p.pos = p.home
            p.target = p.home
            switch s.edge {
            case .bottom: p.region = CGRect(x: rink.minX + paddleR, y: rink.minY + paddleR, width: rink.width - 2 * paddleR, height: depth - paddleR)
            case .top: p.region = CGRect(x: rink.minX + paddleR, y: rink.maxY - depth, width: rink.width - 2 * paddleR, height: depth - paddleR)
            case .left: p.region = CGRect(x: rink.minX + paddleR, y: rink.minY + paddleR, width: depth - paddleR, height: rink.height - 2 * paddleR)
            case .right: p.region = CGRect(x: rink.maxX - depth, y: rink.minY + paddleR, width: depth - paddleR, height: rink.height - 2 * paddleR)
            }
            // region hint
            let zone = SKShapeNode(rect: p.region.insetBy(dx: -paddleR, dy: -paddleR), cornerRadius: 12)
            zone.fillColor = s.color.withAlphaComponent(0.05)
            zone.strokeColor = s.color.withAlphaComponent(0.18)
            zone.lineWidth = 1
            zone.zPosition = -15
            world.addChild(zone)

            // paddle
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: paddleR * 4, height: paddleR * 4))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.55
            p.node.addChild(glow)
            let body = SKSpriteNode(texture: Gfx.circle(paddleR, s.color.withAlphaComponent(0.95), ring: .white), size: CGSize(width: paddleR * 2, height: paddleR * 2))
            p.node.addChild(body)
            let knob = SKSpriteNode(texture: Gfx.circle(paddleR * 0.45, UIColor(white: 1, alpha: 0.85), ring: s.color), size: CGSize(width: paddleR * 0.9, height: paddleR * 0.9))
            knob.zPosition = 1
            p.node.addChild(knob)
            p.node.position = p.pos
            p.node.zPosition = 30
            world.addChild(p.node)

            // goal
            let horizontal = s.edge == .bottom || s.edge == .top
            let gsize = horizontal ? CGSize(width: goalW, height: 10) : CGSize(width: 10, height: goalW)
            let g = SKSpriteNode(texture: Gfx.pill(gsize.width, gsize.height, fill: s.color, border: .white, corner: 5), size: gsize)
            g.position = gc
            g.zPosition = -5
            world.addChild(g)
            let gg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: gsize.width * 1.4, height: gsize.height * 6 + 30))
            gg.color = s.color
            gg.colorBlendFactor = 1
            gg.blendMode = .add
            gg.alpha = 0.45
            g.addChild(gg)
            p.goalNode = g

            // hearts in the strip
            for i in 0..<3 {
                let h = MiniScene.label("♥", size: 20, color: s.color)
                h.position = CGPoint(x: -s.w / 2 + 22 + CGFloat(i) * 22, y: -6)
                h.zPosition = 410
                s.node.addChild(h)
                p.hearts.append(h)
            }
            let hint = MiniScene.label(s.isCPU ? "" : "SCHLÄGER ZIEHEN", size: 11, color: UIColor(white: 1, alpha: 0.55))
            hint.position = CGPoint(x: 30, y: -8)
            hint.zPosition = 410
            s.node.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 7), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
            paddles.append(p)
        }

        // puck
        let pg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: puckR * 5, height: puckR * 5))
        pg.color = Theme.uiOrange
        pg.colorBlendFactor = 1
        pg.blendMode = .add
        pg.alpha = 0.6
        puck.addChild(pg)
        let pb = SKSpriteNode(texture: Gfx.circle(puckR, UIColor(white: 0.08, alpha: 1), ring: Theme.uiOrange), size: CGSize(width: puckR * 2, height: puckR * 2))
        puck.addChild(pb)
        puck.zPosition = 25
        world.addChild(puck)
        resetPuck(towards: nil, delay: 0)
    }

    override func gameStarted() {
        launchPuck(towards: nil)
    }

    private func goalCenter(_ s: Seat) -> CGPoint {
        switch s.edge {
        case .bottom: return CGPoint(x: rink.midX, y: rink.minY)
        case .top: return CGPoint(x: rink.midX, y: rink.maxY)
        case .left: return CGPoint(x: rink.minX, y: rink.midY)
        case .right: return CGPoint(x: rink.maxX, y: rink.midY)
        }
    }

    private func resetPuck(towards seat: Seat?, delay: Double) {
        puckLive = false
        puckPos = CGPoint(x: rink.midX, y: rink.midY)
        puckVel = .zero
        puck.position = puckPos
        puck.setScale(0.1)
        puck.run(SKAction.scale(to: 1, duration: 0.3))
        if delay > 0 {
            run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.run { [weak self] in
                guard let self = self, self.phase == .playing else { return }
                self.launchPuck(towards: seat)
            }]))
        }
    }

    private func launchPuck(towards seat: Seat?) {
        let alive = seats.filter { $0.alive }
        guard let t = seat ?? alive.randomElement() else { return }
        let gc = goalCenter(t)
        var dx = gc.x - puckPos.x
        var dy = gc.y - puckPos.y
        let l = max(1, hypot(dx, dy))
        dx /= l; dy /= l
        let a = CGFloat.random(in: -0.35...0.35)
        let sp: CGFloat = 230
        puckVel = CGVector(dx: (dx * cos(a) - dy * sin(a)) * sp, dy: (dx * sin(a) + dy * cos(a)) * sp)
        puckLive = true
        lastTouch = -1
        Sfx.shared.play("whistle")
    }

    // MARK: touches

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = paddles[seat.index]
        p.touch = touch
        p.target = clamp(seat.toScene(at), p.region)
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = paddles[seat.index]
        if p.touch == nil { p.touch = touch }
        if p.touch === touch { p.target = clamp(seat.toScene(at), p.region) }
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = paddles[seat.index]
        if p.touch === touch { p.touch = nil }
    }

    private func clamp(_ pt: CGPoint, _ r: CGRect) -> CGPoint {
        return CGPoint(x: max(r.minX, min(r.maxX, pt.x)), y: max(r.minY, min(r.maxY, pt.y)))
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        for s in seats where s.alive {
            let p = paddles[s.index]
            if s.isCPU { cpu(s, p, dt) }
            // follow target fast (human) / limited (cpu)
            let maxV: CGFloat = s.isCPU ? CGFloat(140 + 400 * s.skill) : 2400
            var dx = p.target.x - p.pos.x
            var dy = p.target.y - p.pos.y
            let dist = hypot(dx, dy)
            let step = min(dist, maxV * fdt)
            if dist > 0.01 { dx = dx / dist * step; dy = dy / dist * step } else { dx = 0; dy = 0 }
            p.vel = CGVector(dx: dx / max(fdt, 0.001), dy: dy / max(fdt, 0.001))
            p.pos = CGPoint(x: p.pos.x + dx, y: p.pos.y + dy)
            p.node.position = p.pos
        }
        guard puckLive else { return }

        // sub-steps for stable collisions
        let steps = 3
        let sdt = fdt / CGFloat(steps)
        for _ in 0..<steps {
            puckPos.x += puckVel.dx * sdt
            puckPos.y += puckVel.dy * sdt
            for s in seats where s.alive { collide(s, paddles[s.index]) }
            if walls() { return }
        }
        let fr = pow(0.62, fdt)
        puckVel = CGVector(dx: puckVel.dx * fr, dy: puckVel.dy * fr)
        var sp = hypot(puckVel.dx, puckVel.dy)
        if sp > maxSpeed {
            puckVel = CGVector(dx: puckVel.dx / sp * maxSpeed, dy: puckVel.dy / sp * maxSpeed)
            sp = maxSpeed
        }
        if sp < 60 {
            // keep the game moving: slight drift towards the centre
            puckVel.dx += (rink.midX - puckPos.x) * 0.4 * fdt
            puckVel.dy += (rink.midY - puckPos.y) * 0.4 * fdt
        }
        puck.position = puckPos
        trailTimer -= dt
        if sp > 380 && trailTimer <= 0 {
            trailTimer = 0.05
            let t = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: puckR * 2.6, height: puckR * 2.6))
            t.color = Theme.uiOrange
            t.colorBlendFactor = 1
            t.blendMode = .add
            t.alpha = 0.4
            t.position = puckPos
            t.zPosition = 20
            world.addChild(t)
            t.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.25), SKAction.scale(to: 0.3, duration: 0.25)]), SKAction.removeFromParent()]))
        }
    }

    private func collide(_ s: Seat, _ p: Paddle) {
        let dx = puckPos.x - p.pos.x
        let dy = puckPos.y - p.pos.y
        let d = hypot(dx, dy)
        let minD = paddleR + puckR
        if d < minD && d > 0.001 {
            let nx = dx / d, ny = dy / d
            puckPos = CGPoint(x: p.pos.x + nx * minD, y: p.pos.y + ny * minD)
            let rvx = puckVel.dx - p.vel.dx
            let rvy = puckVel.dy - p.vel.dy
            let dot = rvx * nx + rvy * ny
            if dot < 0 {
                let e: CGFloat = 0.9
                puckVel.dx -= (1 + e) * dot * nx
                puckVel.dy -= (1 + e) * dot * ny
                // a bit of extra kick from the paddle movement
                puckVel.dx += p.vel.dx * 0.25
                puckVel.dy += p.vel.dy * 0.25
                let sp = hypot(puckVel.dx, puckVel.dy)
                if sp > 500 {
                    Sfx.shared.play("hit")
                    if !s.isCPU { Haptic.tap(.medium) }
                } else {
                    Sfx.shared.play("tap")
                }
                lastTouch = s.index
                p.node.run(SKAction.sequence([SKAction.scale(to: 1.15, duration: 0.05), SKAction.scale(to: 1, duration: 0.08)]))
            }
        }
    }

    /// returns true if a goal happened
    private func walls() -> Bool {
        let half = goalW / 2
        // bottom / top
        if puckPos.y - puckR < rink.minY {
            if let s = seatAt(.bottom), s.alive, abs(puckPos.x - rink.midX) < half - puckR * 0.3 {
                if puckPos.y < rink.minY - puckR { goal(on: s); return true }
            } else {
                puckPos.y = rink.minY + puckR
                puckVel.dy = abs(puckVel.dy) * 0.92
                boardHit()
            }
        }
        if puckPos.y + puckR > rink.maxY {
            if let s = seatAt(.top), s.alive, abs(puckPos.x - rink.midX) < half - puckR * 0.3 {
                if puckPos.y > rink.maxY + puckR { goal(on: s); return true }
            } else {
                puckPos.y = rink.maxY - puckR
                puckVel.dy = -abs(puckVel.dy) * 0.92
                boardHit()
            }
        }
        if puckPos.x - puckR < rink.minX {
            if let s = seatAt(.left), s.alive, abs(puckPos.y - rink.midY) < half - puckR * 0.3 {
                if puckPos.x < rink.minX - puckR { goal(on: s); return true }
            } else {
                puckPos.x = rink.minX + puckR
                puckVel.dx = abs(puckVel.dx) * 0.92
                boardHit()
            }
        }
        if puckPos.x + puckR > rink.maxX {
            if let s = seatAt(.right), s.alive, abs(puckPos.y - rink.midY) < half - puckR * 0.3 {
                if puckPos.x > rink.maxX + puckR { goal(on: s); return true }
            } else {
                puckPos.x = rink.maxX - puckR
                puckVel.dx = -abs(puckVel.dx) * 0.92
                boardHit()
            }
        }
        return false
    }

    private func boardHit() {
        if hypot(puckVel.dx, puckVel.dy) > 300 { Sfx.shared.play("bounce") }
    }

    private func seatAt(_ e: SeatEdge) -> Seat? {
        return seats.first { $0.edge == e }
    }

    private func goal(on s: Seat) {
        let p = paddles[s.index]
        puckLive = false
        puck.position = puckPos
        p.lives -= 1
        if p.lives >= 0 && p.lives < p.hearts.count {
            let h = p.hearts[p.lives]
            h.run(SKAction.group([SKAction.scale(to: 1.8, duration: 0.2), SKAction.fadeAlpha(to: 0.15, duration: 0.2)]))
        }
        if lastTouch >= 0 && lastTouch != s.index {
            let sc = seats[lastTouch]
            paddles[lastTouch].goals += 1
            addScore(sc, 1)
            addStat("goals", 1, seat: sc)
            sc.banner("TOR!", color: .yellow, size: 30, duration: 0.6)
        }
        Sfx.shared.play("goal")
        Haptic.bad()
        let gc = goalCenter(s)
        burst(at: gc, color: s.color)
        flashAll(s.color, alpha: 0.25)
        world.run(SKAction.sequence([SKAction.moveBy(x: 6, y: 0, duration: 0.03), SKAction.moveBy(x: -12, y: 0, duration: 0.05), SKAction.moveBy(x: 6, y: 0, duration: 0.03)]))
        s.flash(s.color)
        if p.lives <= 0 {
            p.outOrder = outCount
            outCount += 1
            s.knockOut("RAUS")
            p.node.run(SKAction.fadeAlpha(to: 0.15, duration: 0.3))
            // goal becomes a wall
            if let g = p.goalNode {
                g.run(SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.3))
                g.alpha = 0.6
            }
            Sfx.shared.play("lose")
        }
        if aliveSeats.count <= 1 {
            finishGame(scores: finalScores())
            return
        }
        resetPuck(towards: s.alive ? s : nil, delay: 1.1)
    }

    private func burst(at p: CGPoint, color: UIColor) {
        for _ in 0..<18 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 8, height: 8))
            d.color = color
            d.colorBlendFactor = 1
            d.blendMode = .add
            d.position = p
            d.zPosition = 40
            world.addChild(d)
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: 40...150)
            d.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: cos(a) * r, y: sin(a) * r, duration: 0.5), SKAction.fadeOut(withDuration: 0.5)]), SKAction.removeFromParent()]))
        }
    }

    private func finalScores() -> [Int] {
        return seats.map { s in
            let p = paddles[s.index]
            let survival = p.outOrder >= 0 ? p.outOrder : n
            return max(0, p.lives) * 1000 + survival * 100 + p.goals
        }
    }

    override func timeUp() {
        finishGame(scores: finalScores())
    }

    // MARK: CPU

    private func cpu(_ s: Seat, _ p: Paddle, _ dt: Double) {
        p.cpuThink -= dt
        if p.cpuThink > 0 { p.target = clamp(p.cpuAim, p.region); return }
        p.cpuThink = 0.08 + (1 - s.skill) * 0.32
        let gc = goalCenter(s)
        let inward = s.dirToScene(CGVector(dx: 0, dy: 1))
        // puck heading towards my goal?
        let toGoal = CGVector(dx: gc.x - puckPos.x, dy: gc.y - puckPos.y)
        let approaching = puckVel.dx * toGoal.dx + puckVel.dy * toGoal.dy > 0
        let inRegion = p.region.insetBy(dx: -paddleR * 1.5, dy: -paddleR * 1.5).contains(puckPos)
        let err = CGFloat(1 - s.skill) * 48
        if puckLive && inRegion {
            // attack: get behind the puck (goal side) and push through it
            let dx = puckPos.x - gc.x, dy = puckPos.y - gc.y
            let l = max(1, hypot(dx, dy))
            let behind = CGPoint(x: puckPos.x - dx / l * (paddleR * 0.6), y: puckPos.y - dy / l * (paddleR * 0.6))
            let paddleBehind = (p.pos.x - gc.x) * dx + (p.pos.y - gc.y) * dy < (l - 6) * l
            p.cpuAim = paddleBehind ? CGPoint(x: puckPos.x + dx / l * 30, y: puckPos.y + dy / l * 30) : behind
        } else if puckLive && approaching {
            // defend: stand between puck and goal
            let t: CGFloat = 0.35
            p.cpuAim = CGPoint(x: gc.x + (puckPos.x - gc.x) * t + inward.dx * 40, y: gc.y + (puckPos.y - gc.y) * t + inward.dy * 40)
        } else {
            // home, shadow the puck sideways
            let lateral = CGVector(dx: inward.dy, dy: -inward.dx)
            let off = (puckPos.x - gc.x) * lateral.dx + (puckPos.y - gc.y) * lateral.dy
            let o = max(-goalW * 0.4, min(goalW * 0.4, off * 0.5))
            p.cpuAim = CGPoint(x: p.home.x + lateral.dx * o, y: p.home.y + lateral.dy * o)
        }
        p.cpuAim.x += CGFloat.random(in: -err...err)
        p.cpuAim.y += CGFloat.random(in: -err...err)
        p.target = clamp(p.cpuAim, p.region)
    }
}
