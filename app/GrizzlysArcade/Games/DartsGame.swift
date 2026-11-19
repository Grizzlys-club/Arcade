import SpriteKit

/// Bären-Darts: every seat has its own board; a crosshair wobbles in a Lissajous pattern, tap to throw (6 darts).
final class DartsGame: MiniScene {

    private static let dartsPerSeat = 6

    override class var layout: SeatLayout { return .turns }

    fileprivate final class Board {
        var R: CGFloat = 80
        var center = CGPoint.zero
        var thrown = 0
        var phx: Double = 0
        var phy: Double = 0
        var fx: Double = 1.0
        var fy: Double = 1.37
        var cross = SKSpriteNode()
        var crossGlow = SKSpriteNode()
        var pips: [SKSpriteNode] = []
        var lastThrow: Double = 0
        var cpuReady: Double = 0
        var cpuFireAt: Double? = nil
        var done = false
        var doneAt: Double = 0
        var hint: SKLabelNode?
    }

    private var boards: [Board] = []

    // MARK: textures

    private static func boardTex(_ R: CGFloat, _ color: UIColor, _ idx: Int) -> SKTexture {
        let sz = CGSize(width: R * 2 + 12, height: R * 2 + 12)
        return Gfx.texture("darts_board_\(Int(R))_\(idx)", size: sz) { ctx in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            func disc(_ r: CGFloat, _ fill: UIColor) {
                ctx.setFillColor(fill.cgColor)
                ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            }
            disc(R + 3, UIColor(white: 0.03, alpha: 1))
            // alternating wedges in outer + mid ring
            let wedges = 12
            for i in 0..<wedges {
                let a0 = CGFloat(i) / CGFloat(wedges) * 2 * .pi
                let a1 = CGFloat(i + 1) / CGFloat(wedges) * 2 * .pi
                let p = UIBezierPath()
                p.move(to: c)
                p.addArc(withCenter: c, radius: R, startAngle: a0, endAngle: a1, clockwise: true)
                p.close()
                ctx.addPath(p.cgPath)
                ctx.setFillColor((i % 2 == 0 ? color.withAlphaComponent(0.20) : UIColor(white: 0.10, alpha: 1)).cgColor)
                ctx.fillPath()
            }
            // inner disc clears wedges slightly
            disc(R * 0.30, UIColor(white: 0.06, alpha: 1))
            disc(R * 0.30, color.withAlphaComponent(0.30))
            disc(R * 0.12, UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 0.95))
            // neon rings
            ctx.setLineWidth(2.2)
            for (f, a) in [(1.0, 1.0), (0.62, 0.85), (0.30, 0.9), (0.12, 1.0)] as [(CGFloat, CGFloat)] {
                ctx.setStrokeColor((f == 0.12 ? UIColor.white : color).withAlphaComponent(a).cgColor)
                ctx.strokeEllipse(in: CGRect(x: c.x - R * f, y: c.y - R * f, width: R * f * 2, height: R * f * 2))
            }
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.9).cgColor)
            ctx.setLineWidth(1.2)
            ctx.strokeEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: R * 2, height: R * 2))
        }
    }

    private static func crossTex() -> SKTexture {
        let s: CGFloat = 40
        return Gfx.texture("darts_cross", size: CGSize(width: s, height: s)) { ctx in
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: 8, y: 8, width: 24, height: 24))
            ctx.move(to: CGPoint(x: 20, y: 1)); ctx.addLine(to: CGPoint(x: 20, y: 13))
            ctx.move(to: CGPoint(x: 20, y: 27)); ctx.addLine(to: CGPoint(x: 20, y: 39))
            ctx.move(to: CGPoint(x: 1, y: 20)); ctx.addLine(to: CGPoint(x: 13, y: 20))
            ctx.move(to: CGPoint(x: 27, y: 20)); ctx.addLine(to: CGPoint(x: 39, y: 20))
            ctx.strokePath()
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 18.5, y: 18.5, width: 3, height: 3))
        }
    }

    /// Dart with a bear-paw flight. Tip at the bottom centre.
    private static func dartTex(_ color: UIColor, _ idx: Int) -> SKTexture {
        return Gfx.texture("darts_dart_\(idx)", size: CGSize(width: 20, height: 42)) { ctx in
            // barrel
            ctx.setFillColor(UIColor(white: 0.85, alpha: 1).cgColor)
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 8, y: 16)); p.addLine(to: CGPoint(x: 12, y: 16))
            p.addLine(to: CGPoint(x: 10.8, y: 33)); p.addLine(to: CGPoint(x: 10, y: 42)); p.addLine(to: CGPoint(x: 9.2, y: 33))
            p.close()
            ctx.addPath(p.cgPath); ctx.fillPath()
            ctx.setFillColor(UIColor(white: 0.45, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 8.6, y: 22, width: 2.8, height: 3))
            // paw flight
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: 4.5, y: 6.5, width: 11, height: 9.5))
            for (x, y) in [(3.0, 3.8), (7.6, 1.2), (12.4, 1.2), (17.0, 3.8)] as [(CGFloat, CGFloat)] {
                ctx.fillEllipse(in: CGRect(x: x - 2.1, y: y - 2.1, width: 4.2, height: 4.6))
            }
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            ctx.setLineWidth(0.8)
            ctx.strokeEllipse(in: CGRect(x: 4.5, y: 6.5, width: 11, height: 9.5))
        }
    }

    private static func pipTex() -> SKTexture {
        return Gfx.texture("darts_pip", size: CGSize(width: 10, height: 22)) { ctx in
            ctx.setFillColor(UIColor.white.cgColor)
            let p = UIBezierPath()
            p.move(to: CGPoint(x: 3, y: 1)); p.addLine(to: CGPoint(x: 7, y: 1))
            p.addLine(to: CGPoint(x: 7, y: 12)); p.addLine(to: CGPoint(x: 5, y: 21)); p.addLine(to: CGPoint(x: 3, y: 12))
            p.close()
            ctx.addPath(p.cgPath); ctx.fillPath()
        }
    }

    // MARK: setup

    override func setupGame() {
        duration = 0
        let r0 = newRand()
        let px = Double(r0.range(0, 6.28))
        let py = Double(r0.range(0, 6.28))
        boards = []
        for s in seats {
            let b = Board()
            b.R = min(s.w * 0.43, 132, (s.h - 96) / 2)
            b.center = CGPoint(x: 0, y: -4)
            b.phx = px
            b.phy = py
            b.cpuReady = 0.7 + (1 - s.skill) * 0.9 + Double.random(in: 0...0.4)

            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: b.R * 2.9, height: b.R * 2.9))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.35
            glow.position = b.center
            glow.zPosition = 1
            s.field.addChild(glow)

            let board = SKSpriteNode(texture: DartsGame.boardTex(b.R, s.color, s.index), size: CGSize(width: b.R * 2 + 12, height: b.R * 2 + 12))
            board.position = b.center
            board.zPosition = 2
            s.field.addChild(board)

            // ring score labels along the right side
            for (f, t) in [(0.81, "5"), (0.46, "10"), (0.21, "25")] as [(CGFloat, String)] {
                let l = MiniScene.label(t, size: max(8, b.R * 0.11), color: UIColor(white: 1, alpha: 0.55))
                l.position = CGPoint(x: b.center.x + b.R * f, y: b.center.y - 3)
                l.zPosition = 3
                s.field.addChild(l)
            }

            let cg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 46, height: 46))
            cg.blendMode = .add
            cg.alpha = 0.55
            cg.zPosition = 80
            s.field.addChild(cg)
            b.crossGlow = cg
            let cr = SKSpriteNode(texture: DartsGame.crossTex(), size: CGSize(width: 34, height: 34))
            cr.zPosition = 81
            s.field.addChild(cr)
            b.cross = cr

            // remaining-dart pips
            let n = DartsGame.dartsPerSeat
            let gap: CGFloat = min(20, (s.w - 40) / CGFloat(n))
            for i in 0..<n {
                let p = SKSpriteNode(texture: DartsGame.pipTex(), size: CGSize(width: 8, height: 17))
                p.color = s.color
                p.colorBlendFactor = 1
                p.position = CGPoint(x: (CGFloat(i) - CGFloat(n - 1) / 2) * gap, y: -s.h / 2 + 16)
                p.zPosition = 5
                s.field.addChild(p)
                b.pips.append(p)
            }

            let hint = label(s.isCPU ? "CPU" : "TIPP = WERFEN 🎯", size: min(16, s.w * 0.08), color: .white)
            hint.position = CGPoint(x: 0, y: -s.h / 2 + 40)
            hint.zPosition = 60
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.4), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            b.hint = hint

            boards.append(b)
            updateCross(s, b)
        }
        setActiveSeat(0)
    }

    // MARK: crosshair

    private func speedMult(_ b: Board) -> Double { return 1.0 + 0.22 * Double(b.thrown) }

    private func crossPos(_ b: Board) -> CGPoint {
        let a = b.R * 0.8
        return CGPoint(x: b.center.x + a * CGFloat(sin(b.phx)), y: b.center.y + a * CGFloat(sin(b.phy)))
    }

    private func updateCross(_ s: Seat, _ b: Board) {
        let p = crossPos(b)
        b.cross.position = p
        b.crossGlow.position = p
        let col = s.color
        b.crossGlow.color = col
        b.crossGlow.colorBlendFactor = 1
    }

    // MARK: throwing

    private func points(_ b: Board, _ d: CGFloat) -> Int {
        let f = d / b.R
        if f < 0.12 { return 50 }
        if f < 0.30 { return 25 }
        if f < 0.62 { return 10 }
        if f <= 1.0 { return 5 }
        return 0
    }

    private func throwDart(_ s: Seat) {
        let b = boards[s.index]
        if b.done || b.thrown >= DartsGame.dartsPerSeat { return }
        let p = crossPos(b)
        let d = hypot(p.x - b.center.x, p.y - b.center.y)
        let pts = points(b, d)
        b.thrown += 1
        b.lastThrow = elapsed
        b.cpuFireAt = nil
        b.cpuReady = elapsed + 0.55 + (1 - s.skill) * 0.8 + Double.random(in: 0...0.35)
        b.hint?.removeFromParent()
        b.hint = nil
        if b.thrown - 1 < b.pips.count {
            let pip = b.pips[b.thrown - 1]
            pip.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.15), SKAction.scale(to: 0.2, duration: 0.15)])]))
        }

        // dart sprite: drops in from "above" (scale), sticks with a tilt
        let dart = SKSpriteNode(texture: DartsGame.dartTex(s.color, s.index), size: CGSize(width: 17, height: 36))
        dart.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        dart.position = p
        dart.zRotation = CGFloat.random(in: -0.3...0.1)
        dart.zPosition = 20 + CGFloat(b.thrown)
        dart.setScale(2.2)
        dart.alpha = 0.2
        s.field.addChild(dart)
        dart.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.0, duration: 0.08), SKAction.fadeIn(withDuration: 0.06)]),
            SKAction.scale(to: 1.12, duration: 0.04),
            SKAction.scale(to: 1.0, duration: 0.06)
        ]))
        // thud ring
        let ring = SKSpriteNode(texture: Gfx.circle(10, UIColor.clear, ring: UIColor.white), size: CGSize(width: 20, height: 20))
        ring.position = p
        ring.zPosition = 15
        ring.setScale(0.3)
        ring.alpha = 0.9
        s.field.addChild(ring)
        ring.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.6, duration: 0.25), SKAction.fadeOut(withDuration: 0.25)]), SKAction.removeFromParent()]))

        // crosshair recoil
        b.cross.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.05), SKAction.scale(to: 1.0, duration: 0.15)]))

        if pts > 0 {
            addScore(s, pts)
            addStat("hits", 1, seat: s)
        }
        let top = CGPoint(x: p.x, y: p.y + 14)
        switch pts {
        case 50:
            s.floatText("BULLSEYE! +50", at: top, color: .yellow, size: min(26, s.w * 0.11))
            s.burst(at: p, color: .yellow, count: 26, speed: 170)
            s.burst(at: p, color: .white, count: 12, speed: 100)
            s.flash(.yellow, alpha: 0.35)
            s.shake(7)
            Sfx.shared.play("fanfare")
            if !s.isCPU { Haptic.good() }
        case 25:
            s.floatText("+25", at: top, color: s.color, size: 24)
            s.burst(at: p, color: s.color, count: 14, speed: 120)
            Sfx.shared.play("coin")
            if !s.isCPU { Haptic.tap(.medium) }
        case 10:
            s.floatText("+10", at: top, color: .white, size: 21)
            s.burst(at: p, color: s.color, count: 8, speed: 90)
            Sfx.shared.play("hit")
            if !s.isCPU { Haptic.tap(.medium) }
        case 5:
            s.floatText("+5", at: top, color: UIColor(white: 0.9, alpha: 1), size: 19)
            s.burst(at: p, color: s.color, count: 5, speed: 70)
            Sfx.shared.play("stomp")
            if !s.isCPU { Haptic.tap(.light) }
        default:
            s.floatText("DANEBEN", at: top, color: UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1), size: 17)
            Sfx.shared.play("miss")
            if !s.isCPU { Haptic.bad() }
        }

        if b.thrown >= DartsGame.dartsPerSeat {
            b.done = true
            b.doneAt = elapsed
            b.cross.run(SKAction.fadeOut(withDuration: 0.2))
            b.crossGlow.run(SKAction.fadeOut(withDuration: 0.2))
            s.banner("\(s.score)", color: s.color, size: 54, duration: 1.2)
        }
    }

    // MARK: loop

    private func startTurn(_ i: Int) {
        let s = seats[i]
        let b = boards[i]
        b.lastThrow = elapsed
        b.cpuFireAt = nil
        b.cpuReady = elapsed + 0.8 + (1 - s.skill) * 0.9 + Double.random(in: 0...0.4)
        setActiveSeat(i)
    }

    private func nextTurn(after i: Int) -> Int? {
        for k in 1...max(1, seats.count) {
            let j = (i + k) % seats.count
            if !boards[j].done { return j }
        }
        return nil
    }

    override func gameUpdate(_ dt: Double) {
        let s = seats[activeSeatIndex]
        let b = boards[s.index]
        if !b.done {
            let m = speedMult(b)
            b.phx += 1.75 * b.fx * m * dt
            b.phy += 1.75 * b.fy * m * dt
            updateCross(s, b)
            if s.isCPU {
                if b.cpuFireAt == nil && elapsed >= b.cpuReady {
                    let p = crossPos(b)
                    let d = hypot(p.x - b.center.x, p.y - b.center.y)
                    let waited = CGFloat(elapsed - b.cpuReady)
                    let thr = b.R * (0.10 + CGFloat(1 - s.skill) * 0.45) + waited * b.R * 0.35
                    if d < thr {
                        b.cpuFireAt = elapsed + 0.03 + (1 - s.skill) * 0.16 + Double.random(in: 0...0.05)
                    }
                }
                if let t = b.cpuFireAt, elapsed >= t {
                    throwDart(s)
                }
            } else if elapsed - b.lastThrow > 9 {
                // idle human: throw automatically so the match always ends
                throwDart(s)
            }
        } else if elapsed - b.doneAt > 1.1 {
            if let next = nextTurn(after: s.index) { startTurn(next) }
        }
        if boards.allSatisfy({ $0.done }) {
            let last = boards.map { $0.doneAt }.max() ?? elapsed
            if elapsed - last > 0.9 { finishGame() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if seat.isCPU { return }
        let b = boards[seat.index]
        if b.done { return }
        if elapsed - b.lastThrow < 0.18 { return }
        throwDart(seat)
    }
}
