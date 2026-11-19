import SpriteKit

/// Eis-Balance: tilt the beam (finger left / right) to keep the ball on it. Gusts get stronger. Score = seconds * 10.
final class BalanceGame: MiniScene {
    fileprivate final class State {
        let seat: Seat
        let rand: Rand
        let beam = SKNode()
        let ball: SKSpriteNode
        let wind: SKLabelNode
        var s: CGFloat = 0
        var v: CGFloat = 0
        var theta: CGFloat = 0
        var target: CGFloat = 0
        var touchX: [UITouch: CGFloat] = [:]
        var gustTimer: Double = 1.5
        var gustLeft: Double = 0
        var gust: CGFloat = 0
        var alive: Double = 0
        var cpuTimer: Double = 0
        init(seat: Seat, rand: Rand, ball: SKSpriteNode, wind: SKLabelNode) {
            self.seat = seat
            self.rand = rand
            self.ball = ball
            self.wind = wind
        }
    }

    private var states: [State] = []
    private let maxTilt: CGFloat = 0.38
    private let G: CGFloat = 420
    private let ballR: CGFloat = 11
    private let beamT: CGFloat = 10

    private func beamL(_ s: Seat) -> CGFloat { return s.w * 0.8 }
    private func pivot(_ s: Seat) -> CGPoint { return CGPoint(x: 0, y: -s.h * 0.1) }

    override func setupGame() {
        duration = 60
        for s in seats {
            let L = beamL(s)
            let p = pivot(s)
            // stand
            let stand = SKSpriteNode(texture: Gfx.texture("balance_stand", size: CGSize(width: 40, height: 60)) { ctx in
                ctx.setFillColor(UIColor(white: 0.85, alpha: 1).cgColor)
                ctx.move(to: CGPoint(x: 20, y: 0))
                ctx.addLine(to: CGPoint(x: 40, y: 60))
                ctx.addLine(to: CGPoint(x: 0, y: 60))
                ctx.closePath()
                ctx.fillPath()
            }, size: CGSize(width: 34, height: 52))
            stand.anchorPoint = CGPoint(x: 0.5, y: 1)
            stand.position = p
            stand.zPosition = 2
            s.field.addChild(stand)
            // ice floor
            let floor = SKSpriteNode(color: UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 0.18), size: CGSize(width: s.w, height: 6))
            floor.position = CGPoint(x: 0, y: p.y - 54)
            s.field.addChild(floor)
            // beam = a hockey stick
            let st = State(seat: s, rand: newRand(), ball: SKSpriteNode(texture: Gfx.ball(ballR), size: CGSize(width: ballR * 2, height: ballR * 2)), wind: label("", size: s.w > 300 ? 22 : 16, color: UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 1)))
            st.beam.position = p
            st.beam.zPosition = 5
            Self.beamNode(L, s.color, into: st.beam)
            s.field.addChild(st.beam)
            st.ball.zPosition = 8
            s.field.addChild(st.ball)
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 50, height: 50))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.5
            glow.zPosition = -1
            st.ball.addChild(glow)
            st.wind.position = CGPoint(x: 0, y: s.h * 0.22)
            st.wind.zPosition = 20
            s.field.addChild(st.wind)
            // left / right touch hints
            for (sign, txt) in [(CGFloat(-1), "◀︎"), (CGFloat(1), "▶︎")] {
                let l = label(txt, size: 28, color: s.color.withAlphaComponent(0.35))
                l.position = CGPoint(x: sign * s.w * 0.36, y: -s.h * 0.36)
                s.field.addChild(l)
            }
            let hint = label(s.isCPU ? "CPU" : "LINKS / RECHTS HALTEN", size: s.w > 300 ? 17 : 12, color: UIColor(white: 1, alpha: 0.85))
            hint.position = CGPoint(x: 0, y: s.h * 0.12)
            hint.zPosition = 40
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.6), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            states.append(st)
            place(st)
        }
    }

    @discardableResult
    private static func beamNode(_ L: CGFloat, _ color: UIColor, into parent: SKNode) -> SKNode {
        let shaft = SKSpriteNode(color: UIColor(white: 0.95, alpha: 1), size: CGSize(width: L, height: 10))
        parent.addChild(shaft)
        let tape = SKSpriteNode(color: color, size: CGSize(width: L * 0.18, height: 10))
        tape.position = CGPoint(x: -L / 2 + L * 0.09, y: 0)
        tape.zPosition = 1
        parent.addChild(tape)
        let blade = SKSpriteNode(color: color, size: CGSize(width: 10, height: 22))
        blade.position = CGPoint(x: L / 2 - 5, y: -6)
        blade.zPosition = 1
        parent.addChild(blade)
        let mid = SKSpriteNode(color: Theme.uiOrange, size: CGSize(width: 4, height: 12))
        mid.zPosition = 2
        parent.addChild(mid)
        return parent
    }

    private func place(_ st: State) {
        let p = pivot(st.seat)
        let c = cos(st.theta)
        let sn = sin(st.theta)
        let off = ballR + beamT / 2
        st.ball.position = CGPoint(x: p.x + c * st.s - sn * off, y: p.y + sn * st.s + c * off)
        st.ball.zRotation = -st.s / ballR
        st.beam.zRotation = st.theta
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        let t = CGFloat(elapsed)
        for st in states {
            let s = st.seat
            guard s.alive else { continue }
            // gusts (same sequence for everyone)
            st.gustTimer -= dt
            if st.gustTimer <= 0 {
                st.gustTimer = Double(st.rand.range(1.3, 2.6))
                st.gustLeft = 0.8
                st.gust = st.rand.range(-1, 1) * (45 + t * 4.5)
                st.wind.text = st.gust < 0 ? "💨 ◀︎◀︎" : "▶︎▶︎ 💨"
                st.wind.alpha = 1
                st.wind.run(SKAction.sequence([SKAction.wait(forDuration: 0.6), SKAction.fadeOut(withDuration: 0.3)]))
            }
            var g: CGFloat = 0
            if st.gustLeft > 0 {
                st.gustLeft -= dt
                g = st.gust
            }
            if s.isCPU {
                cpuThink(st, dt, gust: g)
            } else if let x = st.touchX.values.first {
                st.target = max(-1, min(1, -x / (s.w * 0.35))) * maxTilt
            } else {
                st.target = 0
            }
            let step = 2.0 * fdt
            st.theta += max(-step, min(step, st.target - st.theta))
            let c = 0.6 + t * 0.05
            let a = -G * sin(st.theta) + c * st.s + g
            st.v += a * fdt
            st.v *= (1 - 0.3 * fdt)
            st.s += st.v * fdt
            place(st)
            if abs(st.s) > beamL(s) / 2 + 2 {
                drop(st)
                continue
            }
            st.alive += dt
            let sc = Int(st.alive * 10)
            if sc != s.score {
                s.score = sc
                s.scoreLabel?.text = "\(sc)"
            }
        }
        checkEnd()
    }

    private func cpuThink(_ st: State, _ dt: Double, gust: CGFloat) {
        st.cpuTimer -= dt
        if st.cpuTimer > 0 { return }
        let s = st.seat
        st.cpuTimer = 0.06 + (1 - s.skill) * 0.25
        let c = 0.6 + CGFloat(elapsed) * 0.05
        let kp: CGFloat = 3
        let kd: CGFloat = 2.5
        var sn = (c * st.s + kp * st.s + kd * st.v + gust * CGFloat(s.skill)) / G
        sn += CGFloat.random(in: -1...1) * CGFloat(1 - s.skill) * 0.12
        sn = max(-0.99, min(0.99, sn))
        st.target = max(-maxTilt, min(maxTilt, asin(sn)))
    }

    private func drop(_ st: State) {
        let s = st.seat
        let dir: CGFloat = st.s > 0 ? 1 : -1
        st.ball.run(SKAction.group([SKAction.moveBy(x: dir * 30, y: -s.h * 0.6, duration: 0.7), SKAction.fadeOut(withDuration: 0.7)]))
        s.knockOut("RUNTER")
        Sfx.shared.play("miss")
        if !s.isCPU { Haptic.bad() }
    }

    private func checkEnd() {
        if phase != .playing { return }
        let alive = aliveSeats
        if alive.isEmpty {
            finishGame()
            return
        }
        if alive.count == 1 && n > 1 {
            let a = alive[0]
            let others = seats.filter { $0 !== a }.map { $0.score }.max() ?? 0
            if a.score > others { finishGame() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.touchX[touch] = at.x
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.touchX[touch] = at.x
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.touchX[touch] = nil
    }
}
