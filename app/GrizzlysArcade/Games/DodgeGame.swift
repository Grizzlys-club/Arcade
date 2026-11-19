import SpriteKit

/// Puck-Ausweichen: drag the bear left/right, dodge falling pucks. 3 lives, score = seconds survived + near misses.
final class DodgeGame: MiniScene {
    fileprivate final class Puck {
        let node: SKNode
        var x: CGFloat
        var y: CGFloat
        let v: CGFloat
        let r: CGFloat
        let noise: CGFloat
        var counted = false
        init(node: SKNode, x: CGFloat, y: CGFloat, v: CGFloat, r: CGFloat, noise: CGFloat) {
            self.node = node; self.x = x; self.y = y; self.v = v; self.r = r; self.noise = noise
        }
    }

    fileprivate final class State {
        let seat: Seat
        let rand: Rand
        let bear: BearNode
        var pucks: [Puck] = []
        var x: CGFloat = 0
        var target: CGFloat = 0
        var lives = 3
        var invuln: Double = 0
        var spawnT: Double = 0.3
        var surv: Double = 0
        var bonus = 0
        var lifeLabel: SKLabelNode?
        init(seat: Seat, rand: Rand, bear: BearNode) { self.seat = seat; self.rand = rand; self.bear = bear }
    }

    private var states: [State] = []
    private let bearH: CGFloat = 32
    private let halfW: CGFloat = 11

    private func feetY(_ s: Seat) -> CGFloat { return -s.h / 2 + 8 }
    private func limit(_ s: Seat) -> CGFloat { return s.w / 2 - 22 }

    override func setupGame() {
        duration = 45
        for s in seats {
            let bear = makeBear(s, height: bearH, faceRight: false)
            let st = State(seat: s, rand: newRand(), bear: bear)
            let floor = SKSpriteNode(color: s.color.withAlphaComponent(0.7), size: CGSize(width: s.w, height: 3))
            floor.position = CGPoint(x: 0, y: feetY(s) - 2)
            floor.zPosition = 2
            s.field.addChild(floor)
            let fg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: s.w * 1.2, height: 30))
            fg.color = s.color; fg.colorBlendFactor = 1; fg.blendMode = .add; fg.alpha = 0.4
            fg.position = floor.position
            s.field.addChild(fg)
            bear.position = CGPoint(x: 0, y: feetY(s))
            bear.zPosition = 20
            s.field.addChild(bear)
            bear.startRun(speed: 0.1)
            let ll = label("●●●", size: 13, color: s.color)
            ll.horizontalAlignmentMode = .left
            ll.position = CGPoint(x: -s.w / 2 + 14, y: s.h / 2 - 34)
            ll.zPosition = 400
            s.node.addChild(ll)
            st.lifeLabel = ll
            let hint = label(s.isCPU ? "CPU" : "↔ ZIEHEN", size: s.w > 300 ? 18 : 13, color: UIColor(white: 1, alpha: 0.85))
            hint.position = CGPoint(x: 0, y: 0)
            hint.zPosition = 30
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 3.2 + 1.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            states.append(st)
        }
    }

    private func spawn(_ st: State) {
        let s = st.seat
        let frac = CGFloat(st.rand.double())
        let sp = 150 + CGFloat(elapsed) * 4.5 + st.rand.range(0, 50)
        let r: CGFloat = st.rand.range(8, 11)
        let node = SKNode()
        let body = SKSpriteNode(texture: Gfx.circle(r, UIColor(white: 0.08, alpha: 1), ring: Theme.uiOrange), size: CGSize(width: r * 2, height: r * 2))
        node.addChild(body)
        let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: r * 4.5, height: r * 4.5))
        g.color = Theme.uiOrange; g.colorBlendFactor = 1; g.blendMode = .add; g.alpha = 0.7
        g.zPosition = -1
        node.addChild(g)
        node.zPosition = 10
        let x = (frac * 2 - 1) * (s.w / 2 - r)
        let p = Puck(node: node, x: x, y: s.h / 2 + r, v: sp * s.h / 370, r: r, noise: CGFloat.random(in: -1...1))
        node.position = CGPoint(x: p.x, y: p.y)
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: 6, duration: 1)))
        s.field.addChild(node)
        st.pucks.append(p)
    }

    private func hit(_ st: State) {
        let s = st.seat
        st.lives -= 1
        st.invuln = 1.3
        st.lifeLabel?.text = String(repeating: "●", count: max(0, st.lives))
        s.burst(at: CGPoint(x: st.x, y: feetY(s) + 16), color: .red, count: 12)
        s.shake(5)
        s.flash(.red, alpha: 0.3)
        st.bear.squash()
        if !s.isCPU { Sfx.shared.play("hit"); Haptic.bad() }
        if st.lives <= 0 {
            s.knockOut("RAUS")
            st.bear.stopRun()
            for p in st.pucks { p.node.removeFromParent() }
            st.pucks = []
        }
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        for st in states where st.seat.alive {
            let s = st.seat
            st.surv += dt
            st.invuln -= dt
            st.bear.visual.alpha = st.invuln > 0 ? (Int(st.invuln * 12) % 2 == 0 ? 0.35 : 1) : 1
            st.spawnT -= dt
            if st.spawnT <= 0 {
                let dens = max(0.2, 0.62 - elapsed * 0.01) * pow(390.0 / Double(s.w), 0.5)
                st.spawnT += dens
                spawn(st)
                if st.rand.chance(min(0.4, elapsed * 0.01)) { spawn(st) }
            }
            if s.isCPU { cpuThink(st, dt) }
            let maxStep: CGFloat = 900 * fdt
            st.x += max(-maxStep, min(maxStep, st.target - st.x))
            st.x = max(-limit(s), min(limit(s), st.x))
            st.bear.position.x = st.x
            let cy = feetY(s) + bearH * 0.45
            var i = 0
            while i < st.pucks.count {
                let p = st.pucks[i]
                let prev = p.y
                p.y -= p.v * fdt
                p.node.position.y = p.y
                var removed = false
                let dx = abs(p.x - st.x)
                if st.invuln <= 0 && dx < halfW + p.r * 0.8 && abs(p.y - cy) < bearH * 0.45 + p.r * 0.8 {
                    p.node.removeFromParent()
                    st.pucks.remove(at: i)
                    removed = true
                    hit(st)
                    if !s.alive { break }
                } else if !p.counted && prev > cy && p.y <= cy {
                    p.counted = true
                    if dx < halfW + p.r + 12 {
                        st.bonus += 2
                        s.floatText("KNAPP! +2", at: CGPoint(x: st.x, y: cy + 26), color: .yellow, size: 14)
                        if !s.isCPU { Sfx.shared.play("coin") }
                    }
                }
                if !removed {
                    if p.y < -s.h / 2 - 20 { p.node.removeFromParent(); st.pucks.remove(at: i); removed = true }
                }
                if !removed { i += 1 }
            }
            let sc = Int(st.surv) + st.bonus
            if sc != s.score { setScore(s, sc) }
        }
        if phase == .playing { checkEnd() }
    }

    private func cpuThink(_ st: State, _ dt: Double) {
        let s = st.seat
        let look = 0.45 + 0.55 * s.skill
        let cy = feetY(s) + bearH * 0.45
        let reach = CGFloat(280 + 220 * s.skill) // px/s the CPU can move
        var best = st.x
        var bestCost = CGFloat.greatestFiniteMagnitude
        let steps = 15
        for k in 0..<steps {
            let cx = -limit(s) + (2 * limit(s)) * CGFloat(k) / CGFloat(steps - 1)
            var cost = abs(cx - st.x) * 0.004
            for p in st.pucks {
                let t = (p.y - cy) / p.v
                if t < -0.1 || t > CGFloat(look) { continue }
                let px = p.x + p.noise * CGFloat(1 - s.skill) * 28
                let need = halfW + p.r + 8
                // can we be at cx by the time the puck arrives?
                let dxMove = abs(cx - st.x)
                if abs(px - cx) < need { cost += 3 / (max(t, 0) + 0.15) }
                // crossing path: staying at current x until puck passes
                if dxMove > reach * max(t, 0.02) && abs(px - st.x) < need { cost += 6 }
            }
            if cost < bestCost - 0.001 { bestCost = cost; best = cx }
        }
        st.target = best
        // limit speed of the CPU towards its target
        let step = reach * CGFloat(dt)
        st.target = st.x + max(-step, min(step, best - st.x))
    }

    private func checkEnd() {
        let alive = aliveSeats
        if alive.isEmpty { finishGame(); return }
        if alive.count == 1 && n > 1 {
            let a = alive[0]
            let others = seats.filter { $0 !== a }.map { $0.score }.max() ?? 0
            if a.score > others + 2 { finishGame() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.target = at.x
    }
    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.target = at.x
    }
}
