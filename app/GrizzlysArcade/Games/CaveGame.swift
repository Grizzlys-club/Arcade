import SpriteKit

/// Höhlenflug: hold = puck rises, release = falls. Fly through a neon cave. Score = distance.
final class CaveGame: MiniScene {
    fileprivate final class State {
        let seat: Seat
        let bear: BearNode
        let puck = SKNode()
        var tops: [SKSpriteNode] = []
        var bots: [SKSpriteNode] = []
        var capT: [SKSpriteNode] = []
        var capB: [SKSpriteNode] = []
        var y: CGFloat = 0
        var vy: CGFloat = 0
        var dist: CGFloat = 0
        var holding = false
        var noise: CGFloat = 0
        var noiseT: Double = 0
        var trailT: Double = 0
        init(seat: Seat, bear: BearNode) { self.seat = seat; self.bear = bear }
    }

    private var states: [State] = []
    private let colW: CGFloat = 6
    private let r: CGFloat = 8
    private let accel: CGFloat = 820
    private var p1: CGFloat = 0, p2: CGFloat = 0, p3: CGFloat = 0

    private func yLo(_ s: Seat) -> CGFloat { return -s.h / 2 + 8 }
    private func yHi(_ s: Seat) -> CGFloat { return s.h / 2 - 34 }
    private func px(_ s: Seat) -> CGFloat { return -s.w * 0.25 }
    private func gapAt(_ s: Seat, _ d: CGFloat) -> CGFloat {
        let base = min(130, s.h * 0.36)
        return max(base * 0.62, base - d * 0.012) + 12 * sin(d * 0.01 + p3)
    }
    /// gap centre at world distance d
    private func centre(_ s: Seat, _ d: CGFloat) -> CGFloat {
        let g = gapAt(s, d)
        let amp = max(0, (yHi(s) - yLo(s) - g) / 2 - 4)
        let mid = (yHi(s) + yLo(s)) / 2
        let m = min(1, 0.35 + d / 2500)
        return mid + amp * m * (0.6 * sin(d * 0.011 + p1) + 0.4 * sin(d * 0.029 + p2))
    }

    override func setupGame() {
        duration = 45
        let rr = newRand()
        p1 = rr.range(0, 6); p2 = rr.range(0, 6); p3 = rr.range(0, 6)
        for s in seats {
            let bear = makeBear(s, height: 26, faceRight: true)
            let st = State(seat: s, bear: bear)
            let count = Int(s.w / colW) + 3
            let top = s.h / 2, bottom = -s.h / 2
            for i in 0..<count {
                let x = -s.w / 2 + CGFloat(i) * colW
                let t = SKSpriteNode(color: UIColor(red: 0.1, green: 0.07, blue: 0.2, alpha: 1), size: CGSize(width: colW + 0.5, height: 10))
                t.anchorPoint = CGPoint(x: 0.5, y: 0); t.position = CGPoint(x: x, y: top - 10); t.zPosition = 3
                let b = SKSpriteNode(color: UIColor(red: 0.1, green: 0.07, blue: 0.2, alpha: 1), size: CGSize(width: colW + 0.5, height: 10))
                b.anchorPoint = CGPoint(x: 0.5, y: 1); b.position = CGPoint(x: x, y: bottom + 10); b.zPosition = 3
                let ct = SKSpriteNode(color: s.color, size: CGSize(width: colW + 0.5, height: 4))
                ct.position = CGPoint(x: x, y: 0); ct.zPosition = 4
                let cb = SKSpriteNode(color: s.color, size: CGSize(width: colW + 0.5, height: 4))
                cb.position = CGPoint(x: x, y: 0); cb.zPosition = 4
                for n in [t, b, ct, cb] { s.field.addChild(n) }
                st.tops.append(t); st.bots.append(b); st.capT.append(ct); st.capB.append(cb)
            }
            // puck with glow + bear on top
            let body = SKSpriteNode(texture: Gfx.circle(r, UIColor(white: 0.1, alpha: 1), ring: Theme.uiOrange), size: CGSize(width: r * 2, height: r * 2))
            st.puck.addChild(body)
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: r * 5, height: r * 5))
            g.color = Theme.uiOrange; g.colorBlendFactor = 1; g.blendMode = .add; g.alpha = 0.8; g.zPosition = -1
            st.puck.addChild(g)
            bear.position = CGPoint(x: 0, y: r - 2)
            bear.zPosition = 1
            st.puck.addChild(bear)
            st.puck.zPosition = 20
            st.puck.position = CGPoint(x: px(s), y: 0)
            s.field.addChild(st.puck)
            let hint = label(s.isCPU ? "CPU" : "HALTEN = HOCH", size: s.w > 300 ? 18 : 13, color: UIColor(white: 1, alpha: 0.9))
            hint.position = CGPoint(x: 0, y: -s.h * 0.3)
            hint.zPosition = 30
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 3.2 + 1.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            st.y = centre(s, px(s))
            states.append(st)
            layoutCols(st)
        }
    }

    private func layoutCols(_ st: State) {
        let s = st.seat
        for i in 0..<st.tops.count {
            let x = st.tops[i].position.x
            let d = st.dist + x + s.w / 2
            let c = centre(s, d), g = gapAt(s, d)
            let topEdge = c + g / 2, botEdge = c - g / 2
            st.tops[i].size.height = max(1, s.h / 2 - topEdge)
            st.tops[i].position.y = topEdge
            st.bots[i].size.height = max(1, botEdge + s.h / 2)
            st.bots[i].position.y = botEdge
            st.capT[i].position.y = topEdge - 1
            st.capB[i].position.y = botEdge + 1
        }
    }

    private func crash(_ st: State) {
        let s = st.seat
        if !s.alive { return }
        s.knockOut("CRASH")
        s.shake(7)
        s.burst(at: CGPoint(x: px(s), y: st.y), color: s.color, count: 16, speed: 140)
        s.flash(.red, alpha: 0.3)
        if !s.isCPU { Sfx.shared.play("hit"); Haptic.bad() }
        st.puck.run(SKAction.fadeOut(withDuration: 0.2))
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        for st in states where st.seat.alive {
            let s = st.seat
            let speed = (105 + CGFloat(elapsed) * 2.2) * (0.75 + 0.25 * s.w / 390)
            st.dist += speed * fdt
            if s.isCPU { cpuThink(st, dt, speed) }
            st.vy += (st.holding ? accel : -accel) * fdt
            st.vy = max(-300, min(300, st.vy))
            st.y += st.vy * fdt
            st.puck.position.y = st.y
            st.puck.zRotation = max(-0.5, min(0.5, st.vy / 500)) * -0.6
            layoutCols(st)
            st.trailT -= dt
            if st.trailT <= 0 {
                st.trailT = 0.04
                let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 6, height: 6))
                d.color = st.holding ? Theme.uiOrange : s.color; d.colorBlendFactor = 1; d.blendMode = .add
                d.position = CGPoint(x: px(s) - 6, y: st.y); d.zPosition = 10
                s.field.addChild(d)
                d.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: -30, y: 0, duration: 0.35), SKAction.fadeOut(withDuration: 0.35)]), SKAction.removeFromParent()]))
            }
            // collision at three sample columns
            var dead = false
            for dx in [-r + 2, 0, r - 2] {
                let d = st.dist + px(s) + s.w / 2 + dx
                let c = centre(s, d), g = gapAt(s, d)
                if st.y + r - 2 > c + g / 2 || st.y - r + 2 < c - g / 2 { dead = true }
            }
            if dead { crash(st); continue }
            let sc = Int(st.dist / 10)
            if sc != s.score { s.score = sc; s.scoreLabel?.text = "\(sc)" }
        }
        checkEnd()
    }

    private func cpuThink(_ st: State, _ dt: Double, _ speed: CGFloat) {
        let s = st.seat
        st.noiseT -= dt
        if st.noiseT <= 0 {
            st.noiseT = 0.5
            st.noise = CGFloat.random(in: -1...1) * CGFloat(1 - s.skill) * gapAt(s, st.dist) * 0.3
        }
        let lookX = 20 + CGFloat(s.skill) * 20
        let d = st.dist + px(s) + s.w / 2 + lookX
        let target = centre(s, d) + st.noise
        let predicted = st.y + st.vy * 0.11
        let hold = predicted < target
        if Double.random(in: 0...1) < (1 - s.skill) * 0.01 { st.holding = !st.holding } else { st.holding = hold }
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

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if let st = states.first(where: { $0.seat === seat }) {
            st.holding = true
            if !seat.isCPU { Sfx.shared.play("tap") }
        }
    }
    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.holding = false
    }
}
