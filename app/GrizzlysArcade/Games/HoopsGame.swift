import SpriteKit

/// Korbjagd: flick the unihockey ball up at the moving hoop. 30 s, 2 points per basket + streak bonus.
final class HoopsGame: MiniScene {

    fileprivate final class Hoop {
        var hoopY: CGFloat = 0
        var range: CGFloat = 0
        var rimHalf: CGFloat = 30
        var phase: Double = 0
        var x: CGFloat = 0
        var root = SKNode()
        var net = SKSpriteNode()
        var frontRim = SKSpriteNode()
        var ballHome = CGPoint.zero
        var ball: SKSpriteNode? = nil
        var inFlight = false
        var respawnAt: Double = 0
        var streak = 0
        var dragStart: CGPoint? = nil
        var aim = SKSpriteNode()
        var cpuAt: Double = 0
        var streakLabel: SKLabelNode? = nil
        var hint: SKLabelNode? = nil
        var trailTick: CGFloat = 0
    }

    private var hoops: [Hoop] = []
    private let flightTime: Double = 0.62

    // MARK: textures

    private static func ballTex(_ color: UIColor, _ idx: Int) -> SKTexture {
        return Gfx.texture("hoops_ball_\(idx)", size: CGSize(width: 34, height: 34)) { ctx in
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: 1, y: 1, width: 32, height: 32))
            // shading
            ctx.setFillColor(UIColor(white: 1, alpha: 0.28).cgColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 4, width: 14, height: 10))
            // unihockey holes
            ctx.setFillColor(UIColor(white: 0.05, alpha: 0.85).cgColor)
            let c = CGPoint(x: 17, y: 17)
            ctx.fillEllipse(in: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6))
            for i in 0..<6 {
                let a = CGFloat(i) * .pi / 3 + 0.3
                let r: CGFloat = 9.5
                ctx.fillEllipse(in: CGRect(x: c.x + cos(a) * r - 2.2, y: c.y + sin(a) * r - 2.2, width: 4.4, height: 4.4))
            }
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            ctx.setLineWidth(1.3)
            ctx.strokeEllipse(in: CGRect(x: 1, y: 1, width: 32, height: 32))
        }
    }

    private static func boardTex(_ w: CGFloat, _ color: UIColor, _ idx: Int) -> SKTexture {
        let h = w * 0.72
        return Gfx.texture("hoops_board_\(Int(w))_\(idx)", size: CGSize(width: w, height: h)) { ctx in
            let r = CGRect(x: 2, y: 2, width: w - 4, height: h - 4)
            let p = UIBezierPath(roundedRect: r, cornerRadius: 6)
            ctx.addPath(p.cgPath)
            ctx.setFillColor(UIColor(white: 1, alpha: 0.10).cgColor)
            ctx.fillPath()
            ctx.addPath(p.cgPath)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(2.5)
            ctx.strokePath()
            let inner = CGRect(x: w * 0.32, y: h * 0.38, width: w * 0.36, height: h * 0.45)
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.75).cgColor)
            ctx.setLineWidth(1.6)
            ctx.stroke(inner)
        }
    }

    private static func netTex(_ w: CGFloat, _ h: CGFloat) -> SKTexture {
        return Gfx.texture("hoops_net_\(Int(w))", size: CGSize(width: w, height: h)) { ctx in
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            ctx.setLineWidth(1.3)
            let n = 6
            for i in 0...n {
                let tx = w * CGFloat(i) / CGFloat(n)
                let bx = w * 0.2 + w * 0.6 * CGFloat(i) / CGFloat(n)
                ctx.move(to: CGPoint(x: tx, y: 0)); ctx.addLine(to: CGPoint(x: bx, y: h))
                // diagonal
                if i < n {
                    let tx2 = w * CGFloat(i + 1) / CGFloat(n)
                    let bx2 = w * 0.2 + w * 0.6 * CGFloat(i + 1) / CGFloat(n)
                    ctx.move(to: CGPoint(x: tx, y: 0)); ctx.addLine(to: CGPoint(x: bx2, y: h))
                    ctx.move(to: CGPoint(x: tx2, y: 0)); ctx.addLine(to: CGPoint(x: bx, y: h))
                }
            }
            for j in 1...3 {
                let y = h * CGFloat(j) / 4
                let inset = (w * 0.2) * CGFloat(j) / 4
                ctx.move(to: CGPoint(x: inset, y: y)); ctx.addLine(to: CGPoint(x: w - inset, y: y))
            }
            ctx.strokePath()
        }
    }

    private static func rimTex(_ w: CGFloat, _ color: UIColor, _ idx: Int) -> SKTexture {
        return Gfx.texture("hoops_rim_\(Int(w))_\(idx)", size: CGSize(width: w, height: 14)) { ctx in
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: 1, y: 3, width: w - 2, height: 8))
            ctx.setFillColor(UIColor(white: 0.04, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 4, y: 5, width: w - 8, height: 4))
        }
    }

    private static func lineTex() -> SKTexture {
        return Gfx.texture("hoops_aim", size: CGSize(width: 6, height: 64)) { ctx in
            ctx.setFillColor(UIColor.white.cgColor)
            for i in 0..<5 { ctx.fillEllipse(in: CGRect(x: 1.5, y: CGFloat(i) * 13 + 2, width: 3, height: 3)) }
        }
    }

    // MARK: setup

    override func setupGame() {
        duration = 30
        hoops = []
        for s in seats {
            let h = Hoop()
            h.rimHalf = min(34, s.w * 0.115 + 8)
            h.hoopY = s.h / 2 - 78
            h.range = max(10, s.w / 2 - h.rimHalf - 20)
            h.ballHome = CGPoint(x: 0, y: -s.h / 2 + 44)
            h.cpuAt = 1.0 + Double.random(in: 0...0.8)

            // court floor line + glow
            let line = SKSpriteNode(color: s.color.withAlphaComponent(0.35), size: CGSize(width: s.w - 24, height: 2))
            line.position = CGPoint(x: 0, y: -s.h / 2 + 76)
            line.zPosition = 1
            s.field.addChild(line)
            let spot = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 90, height: 90))
            spot.color = s.color
            spot.colorBlendFactor = 1
            spot.blendMode = .add
            spot.alpha = 0.3
            spot.position = h.ballHome
            spot.zPosition = 1
            s.field.addChild(spot)

            // hoop group
            let root = SKNode()
            root.position = CGPoint(x: 0, y: h.hoopY)
            root.zPosition = 10
            s.field.addChild(root)
            h.root = root
            let bw = h.rimHalf * 2 * 1.55
            let board = SKSpriteNode(texture: HoopsGame.boardTex(bw, s.color, s.index), size: CGSize(width: bw, height: bw * 0.72))
            board.position = CGPoint(x: 0, y: bw * 0.36 - 2 + 6)
            board.zPosition = 0
            root.addChild(board)
            let bglow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: bw * 1.7, height: bw * 1.4))
            bglow.color = s.color
            bglow.colorBlendFactor = 1
            bglow.blendMode = .add
            bglow.alpha = 0.3
            bglow.position = CGPoint(x: 0, y: bw * 0.3)
            bglow.zPosition = -1
            root.addChild(bglow)
            let backRim = SKSpriteNode(texture: HoopsGame.rimTex(h.rimHalf * 2, UIColor.orange, 9), size: CGSize(width: h.rimHalf * 2, height: 14))
            backRim.position = CGPoint(x: 0, y: 3)
            backRim.zPosition = 1
            root.addChild(backRim)
            let nh = h.rimHalf * 1.25
            let net = SKSpriteNode(texture: HoopsGame.netTex(h.rimHalf * 2 - 6, nh), size: CGSize(width: h.rimHalf * 2 - 6, height: nh))
            net.anchorPoint = CGPoint(x: 0.5, y: 1)
            net.position = CGPoint(x: 0, y: 0)
            net.zPosition = 3
            root.addChild(net)
            h.net = net
            let front = SKSpriteNode(texture: HoopsGame.rimTex(h.rimHalf * 2, UIColor.orange, 9), size: CGSize(width: h.rimHalf * 2, height: 14))
            front.position = CGPoint(x: 0, y: -2)
            front.zPosition = 4
            root.addChild(front)
            h.frontRim = front

            // aim indicator
            let aim = SKSpriteNode(texture: HoopsGame.lineTex(), size: CGSize(width: 6, height: 64))
            aim.anchorPoint = CGPoint(x: 0.5, y: 0)
            aim.alpha = 0
            aim.zPosition = 8
            s.field.addChild(aim)
            h.aim = aim

            // streak label
            let sl = MiniScene.label("", size: min(18, s.w * 0.09), color: .yellow)
            sl.position = CGPoint(x: 0, y: -s.h / 2 + 100)
            sl.zPosition = 30
            sl.alpha = 0
            s.field.addChild(sl)
            h.streakLabel = sl

            let hint = label(s.isCPU ? "CPU" : "WISCHEN ↑", size: min(20, s.w * 0.1), color: .white)
            hint.position = CGPoint(x: 0, y: 0)
            hint.zPosition = 60
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.4), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            h.hint = hint

            hoops.append(h)
            spawnBall(s, h, animated: false)
        }
    }

    private func spawnBall(_ s: Seat, _ h: Hoop, animated: Bool) {
        let b = SKSpriteNode(texture: HoopsGame.ballTex(s.color, s.index), size: CGSize(width: 34, height: 34))
        b.position = h.ballHome
        b.zPosition = 20
        if animated { b.setScale(0.1); b.run(SKAction.scale(to: 1, duration: 0.18)) }
        let gl = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 64, height: 64))
        gl.color = s.color
        gl.colorBlendFactor = 1
        gl.blendMode = .add
        gl.alpha = 0.4
        gl.zPosition = -1
        b.addChild(gl)
        s.field.addChild(b)
        h.ball = b
        h.inFlight = false
    }

    // MARK: shooting

    private var refLen: CGFloat { return 140 }

    /// Launch towards an aim point (local coords).
    private func launch(_ s: Seat, _ h: Hoop, to target: CGPoint) {
        guard let ball = h.ball, !h.inFlight else { return }
        h.inFlight = true
        h.hint?.removeFromParent()
        h.hint = nil
        let start = ball.position
        var A = target
        A.x = max(-s.w / 2 + 10, min(s.w / 2 - 10, A.x))
        A.y = min(A.y, s.h / 2 - 20)
        Sfx.shared.play("kick")
        if !s.isCPU { Haptic.tap(.light) }
        let T = flightTime
        let arc: CGFloat = 46
        let dist = max(1, h.hoopY - start.y)
        ball.removeAllActions()
        h.trailTick = 0
        ball.run(SKAction.customAction(withDuration: T) { [weak self, weak s] node, t in
            guard let self = self, let s = s else { return }
            let u = CGFloat(t) / CGFloat(T)
            let lin = CGPoint(x: start.x + (A.x - start.x) * u, y: start.y + (A.y - start.y) * u)
            let lift = sin(u * .pi) * arc
            node.position = CGPoint(x: lin.x, y: lin.y + lift)
            // faked perspective: ball shrinks as it flies away
            let depth = max(0, min(1, (lin.y - start.y) / dist))
            node.setScale(1.0 - 0.42 * depth + sin(u * .pi) * 0.18)
            if Int(u * 14) != Int(h.trailTick) {
                h.trailTick = u * 14
                self.trailDot(s, at: node.position, scale: node.xScale)
            }
        })
        ball.run(SKAction.sequence([SKAction.wait(forDuration: T), SKAction.run { [weak self, weak s] in
            guard let self = self, let s = s else { return }
            self.resolve(s, h, at: A)
        }]), withKey: "resolve")
    }

    private func trailDot(_ s: Seat, at p: CGPoint, scale: CGFloat) {
        let d = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 24, height: 24))
        d.color = s.color
        d.colorBlendFactor = 1
        d.blendMode = .add
        d.alpha = 0.7
        d.position = p
        d.setScale(scale)
        d.zPosition = 18
        s.field.addChild(d)
        d.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.3), SKAction.scale(to: 0.2, duration: 0.3)]), SKAction.removeFromParent()]))
    }

    private func resolve(_ s: Seat, _ h: Hoop, at A: CGPoint) {
        guard let ball = h.ball else { return }
        let hx = h.x
        let dx = abs(A.x - hx)
        let dy = abs(A.y - (h.hoopY - 4))
        let tolY = max(26, (h.hoopY - h.ballHome.y) * 0.17)
        let rimPos = CGPoint(x: hx, y: h.hoopY)
        let depthOK = dy < tolY
        if depthOK && dx < h.rimHalf * 0.58 {
            score(s, h, ball: ball, swish: true)
        } else if depthOK && dx < h.rimHalf * 0.95 && Bool.random() {
            score(s, h, ball: ball, swish: false)
        } else if depthOK && dx < h.rimHalf * 1.5 {
            // rim bounce out
            Sfx.shared.play("bounce")
            if !s.isCPU { Haptic.tap(.rigid) }
            s.burst(at: rimPos, color: .orange, count: 6, speed: 70)
            h.root.run(SKAction.sequence([SKAction.moveBy(x: 0, y: -3, duration: 0.04), SKAction.moveBy(x: 0, y: 3, duration: 0.06)]))
            let dir: CGFloat = (A.x > hx) ? 1 : -1
            ball.zPosition = 25
            ball.run(SKAction.group([
                SKAction.moveBy(x: dir * 55, y: -50, duration: 0.5),
                SKAction.rotate(byAngle: dir * -4, duration: 0.5),
                SKAction.sequence([SKAction.wait(forDuration: 0.25), SKAction.fadeOut(withDuration: 0.25)])
            ]))
            miss(s, h, text: "KLONG!")
        } else {
            // air ball: keeps flying and fades
            ball.run(SKAction.group([SKAction.moveBy(x: 0, y: depthOK ? 0 : (A.y > h.hoopY ? 30 : -30), duration: 0.3), SKAction.fadeOut(withDuration: 0.3), SKAction.scale(to: 0.4, duration: 0.3)]))
            Sfx.shared.play("miss")
            miss(s, h, text: A.y < h.hoopY - tolY ? "ZU KURZ" : "DANEBEN")
        }
    }

    private func score(_ s: Seat, _ h: Hoop, ball: SKSpriteNode, swish: Bool) {
        h.streak += 1
        let bonus = h.streak - 1
        let pts = 2 + bonus
        addScore(s, pts)
        addStat("goals", 1, seat: s)
        let rimPos = CGPoint(x: h.x, y: h.hoopY)
        // ball drops through the net (behind the front rim)
        ball.removeAllActions()
        ball.position = CGPoint(x: h.x, y: h.hoopY + 8)
        ball.zPosition = 10.5
        ball.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: -h.rimHalf * 1.3, duration: 0.28), SKAction.scale(to: 0.55, duration: 0.28)]),
            SKAction.moveBy(x: 0, y: -h.rimHalf * 0.9, duration: 0.2),
            SKAction.removeFromParent()
        ]))
        h.net.removeAllActions()
        h.net.run(SKAction.sequence([
            SKAction.group([SKAction.scaleY(to: 1.45, duration: 0.09), SKAction.scaleX(to: 0.88, duration: 0.09)]),
            SKAction.group([SKAction.scaleY(to: 0.85, duration: 0.1), SKAction.scaleX(to: 1.08, duration: 0.1)]),
            SKAction.group([SKAction.scaleY(to: 1.0, duration: 0.12), SKAction.scaleX(to: 1.0, duration: 0.12)])
        ]))
        s.burst(at: rimPos, color: s.color, count: 16, speed: 130)
        s.burst(at: rimPos, color: .yellow, count: 8, speed: 90)
        s.floatText(bonus > 0 ? "+\(pts)  x\(h.streak)" : "+\(pts)", at: CGPoint(x: h.x, y: h.hoopY - 30), color: .yellow, size: min(26, s.w * 0.12))
        if swish {
            s.floatText("SWISH!", at: CGPoint(x: h.x, y: h.hoopY + h.rimHalf * 1.6), color: .white, size: min(24, s.w * 0.11))
            Sfx.shared.play("goal")
        } else {
            s.floatText("REIN!", at: CGPoint(x: h.x, y: h.hoopY + h.rimHalf * 1.6), color: .orange, size: min(22, s.w * 0.1))
            Sfx.shared.play("bounce"); Sfx.shared.play("coin")
        }
        s.flash(s.color, alpha: 0.22, duration: 0.3)
        if h.streak >= 3 { s.shake(4) }
        if !s.isCPU { Haptic.good() }
        if h.streak >= 2, let sl = h.streakLabel {
            sl.text = "SERIE x\(h.streak)"
            sl.removeAllActions()
            sl.alpha = 1
            sl.setScale(1.4)
            sl.run(SKAction.scale(to: 1.0, duration: 0.15))
        }
        h.respawnAt = elapsed + 0.45
        h.ball = nil
    }

    private func miss(_ s: Seat, _ h: Hoop, text: String) {
        h.streak = 0
        h.streakLabel?.run(SKAction.fadeOut(withDuration: 0.2))
        s.floatText(text, at: CGPoint(x: h.x, y: h.hoopY - 30), color: UIColor(red: 1, green: 0.45, blue: 0.4, alpha: 1), size: min(18, s.w * 0.09))
        if !s.isCPU { Haptic.bad() }
        let b = h.ball
        h.ball = nil
        b?.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.removeFromParent()]))
        h.respawnAt = elapsed + 0.4
    }

    // MARK: loop

    override func gameUpdate(_ dt: Double) {
        let p = min(1, elapsed / duration)
        for s in seats {
            let h = hoops[s.index]
            // hoop moves left-right, speed grows
            h.phase += (0.8 + 1.5 * p) * dt
            h.x = h.range * CGFloat(sin(h.phase))
            h.root.position.x = h.x

            if h.ball == nil && elapsed >= h.respawnAt {
                spawnBall(s, h, animated: true)
                h.cpuAt = elapsed + 0.35 + (1 - s.skill) * 0.9 + Double.random(in: 0...0.5)
            }
            if s.isCPU && !h.inFlight && h.ball != nil && elapsed >= h.cpuAt {
                // predict hoop position at arrival
                let futurePhase = h.phase + (0.8 + 1.5 * p) * flightTime
                let hx = h.range * CGFloat(sin(futurePhase))
                let sigma = CGFloat(1 - s.skill)
                let ex = CGFloat.random(in: -1...1) * (sigma * 55 + 3)
                let ey = CGFloat.random(in: -1...1) * (sigma * 38 + 2)
                let aim = CGPoint(x: hx + ex, y: h.hoopY - 4 + ey)
                launch(s, h, to: aim)
            }
        }
    }

    // MARK: touch

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if seat.isCPU { return }
        let h = hoops[seat.index]
        h.dragStart = at
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if seat.isCPU { return }
        let h = hoops[seat.index]
        guard let st = h.dragStart, let ball = h.ball, !h.inFlight else { h.aim.alpha = 0; return }
        let v = CGVector(dx: at.x - st.x, dy: at.y - st.y)
        let len = hypot(v.dx, v.dy)
        if len < 12 { h.aim.alpha = 0; return }
        h.aim.alpha = 0.6
        h.aim.position = CGPoint(x: ball.position.x, y: ball.position.y + 18)
        h.aim.zRotation = atan2(v.dy, v.dx) - .pi / 2
        h.aim.yScale = min(1.6, len / 60)
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if seat.isCPU { return }
        let h = hoops[seat.index]
        h.aim.alpha = 0
        guard let st = h.dragStart else { return }
        h.dragStart = nil
        guard let ball = h.ball, !h.inFlight else { return }
        let v = CGVector(dx: at.x - st.x, dy: at.y - st.y)
        if v.dy < 22 {
            Sfx.shared.play("tap")
            return
        }
        let k = (h.hoopY - ball.position.y) / refLen
        // aim point along the swipe ray, scaled by swipe length
        let target = CGPoint(x: ball.position.x + v.dx * k, y: ball.position.y + v.dy * k)
        launch(seat, h, to: target)
    }
}
