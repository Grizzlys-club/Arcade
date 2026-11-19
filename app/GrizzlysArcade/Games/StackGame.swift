import SpriteKit

/// Bären-Turm: classic stacker. Tap to drop the sliding block; overhang is cut off. Score = height (+1 per perfect drop).
final class StackGame: MiniScene {
    fileprivate final class State {
        let seat: Seat
        let tower = SKNode()
        var tops: [(x: CGFloat, w: CGFloat)] = []
        var moving: SKNode? = nil
        var mx: CGFloat = 0
        var mw: CGFloat = 0
        var dir: CGFloat = 1
        var level = 0
        var cpuError: CGFloat = 0
        var cpuDelay: Double = 0
        var combo = 0
        init(seat: Seat) { self.seat = seat }
    }

    private var states: [State] = []

    private func blockH(_ s: Seat) -> CGFloat { return s.w > 300 ? 24 : 20 }
    private func baseY(_ s: Seat) -> CGFloat { return -s.h / 2 + 30 }

    override func setupGame() {
        duration = 60
        for s in seats {
            let st = State(seat: s)
            st.tower.zPosition = 5
            s.field.addChild(st.tower)
            let bw = min(s.w * 0.62, 170)
            // ground
            let ground = SKSpriteNode(color: UIColor(white: 1, alpha: 0.15), size: CGSize(width: s.w, height: 3))
            ground.position = CGPoint(x: 0, y: baseY(s) - blockH(s) / 2 - 2)
            st.tower.addChild(ground)
            let bear = makeBear(s, height: 34, faceRight: true)
            bear.position = CGPoint(x: -s.w / 2 + 26, y: baseY(s) - blockH(s) / 2)
            bear.zPosition = 3
            st.tower.addChild(bear)
            bear.startBob(amount: 2, duration: 0.5)
            st.tower.addChild(makeBlock(s, w: bw, level: 0, x: 0))
            st.tops = [(x: 0, w: bw)]
            let hint = label(s.isCPU ? "CPU" : "TIPPEN = FALLEN LASSEN", size: s.w > 300 ? 17 : 12, color: UIColor(white: 1, alpha: 0.85))
            hint.position = CGPoint(x: 0, y: s.h * 0.15)
            hint.zPosition = 40
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.6), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            states.append(st)
        }
    }

    override func gameStarted() {
        for st in states { spawn(st) }
    }

    private func makeBlock(_ s: Seat, w: CGFloat, level: Int, x: CGFloat) -> SKNode {
        let bh = blockH(s)
        let node = SKSpriteNode(color: s.color, size: CGSize(width: w, height: bh - 2))
        node.position = CGPoint(x: x, y: baseY(s) + CGFloat(level) * bh)
        let dark = SKSpriteNode(color: UIColor(white: 0, alpha: 0.25), size: CGSize(width: w, height: 4))
        dark.position = CGPoint(x: 0, y: -(bh - 2) / 2 + 2)
        dark.zPosition = 1
        node.addChild(dark)
        let stripe = SKSpriteNode(color: UIColor(white: 1, alpha: 0.85), size: CGSize(width: w, height: 3))
        stripe.zPosition = 1
        node.addChild(stripe)
        let hi = SKSpriteNode(color: UIColor(white: 1, alpha: 0.35), size: CGSize(width: w, height: 2))
        hi.position = CGPoint(x: 0, y: (bh - 2) / 2 - 1)
        hi.zPosition = 1
        node.addChild(hi)
        return node
    }

    private func blockSpeed(_ st: State) -> CGFloat {
        let s = st.seat
        return min(300, 95 + CGFloat(st.level) * 7) * (0.55 + 0.45 * s.w / 390)
    }

    private func range(_ st: State) -> CGFloat {
        let s = st.seat
        return max(10, s.w / 2 - st.mw / 2 + st.mw * 0.3)
    }

    private func spawn(_ st: State) {
        let s = st.seat
        guard s.alive, let top = st.tops.last else { return }
        st.level += 1
        st.mw = top.w
        st.dir = st.level % 2 == 0 ? 1 : -1
        st.mx = -st.dir * range(st)
        let b = makeBlock(s, w: st.mw, level: st.level, x: st.mx)
        st.tower.addChild(b)
        st.moving = b
        if s.isCPU {
            st.cpuError = CGFloat.random(in: -1...1) * (CGFloat(1 - s.skill) * 28 + 3)
            st.cpuDelay = 0.35
        }
        // camera
        let topY = baseY(s) + CGFloat(st.level) * blockH(s)
        let want = max(0, topY - s.h * 0.12)
        st.tower.removeAction(forKey: "cam")
        let a = SKAction.moveTo(y: -want, duration: 0.25)
        a.timingMode = .easeOut
        st.tower.run(a, withKey: "cam")
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        for st in states {
            let s = st.seat
            guard s.alive, let m = st.moving else { continue }
            let r = range(st)
            st.mx += st.dir * blockSpeed(st) * fdt
            if st.mx > r { st.mx = r; st.dir = -1 }
            if st.mx < -r { st.mx = -r; st.dir = 1 }
            m.position.x = st.mx
            if s.isCPU, let top = st.tops.last {
                st.cpuDelay -= dt
                let target = max(-r, min(r, top.x + st.cpuError))
                if (st.cpuDelay <= 0 && abs(st.mx - target) <= blockSpeed(st) * fdt * 1.2) || st.cpuDelay < -5 {
                    drop(st)
                }
            }
        }
        checkEnd()
    }

    private func drop(_ st: State) {
        let s = st.seat
        guard s.alive, let m = st.moving, let top = st.tops.last else { return }
        st.moving = nil
        let dx = st.mx - top.x
        let overlap = st.mw - abs(dx)
        let y = m.position.y
        m.removeFromParent()
        if overlap <= 0 {
            // missed completely
            let miss = makeBlock(s, w: st.mw, level: st.level, x: st.mx)
            st.tower.addChild(miss)
            miss.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: st.dir * 40, y: -s.h, duration: 0.9), SKAction.rotate(byAngle: st.dir * -2, duration: 0.9)]), SKAction.removeFromParent()]))
            st.level -= 1
            s.knockOut("DANEBEN")
            Sfx.shared.play("lose")
            if !s.isCPU { Haptic.bad() }
            return
        }
        if abs(dx) <= 4 {
            // perfect
            st.combo += 1
            let b = makeBlock(s, w: st.mw, level: st.level, x: top.x)
            st.tower.addChild(b)
            st.tops.append((x: top.x, w: st.mw))
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: st.mw * 1.6, height: 50))
            glow.color = UIColor.white
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.position = CGPoint(x: top.x, y: y)
            glow.zPosition = 6
            st.tower.addChild(glow)
            glow.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.5, duration: 0.35), SKAction.fadeOut(withDuration: 0.35)]), SKAction.removeFromParent()]))
            addScore(s, 2)
            s.floatText(st.combo > 1 ? "PERFEKT x\(st.combo)" : "PERFEKT!", at: CGPoint(x: 0, y: 0), color: UIColor.yellow, size: 18)
            if !s.isCPU {
                Sfx.shared.play("coin")
                Haptic.good()
            }
        } else {
            st.combo = 0
            let nx = top.x + dx / 2
            let b = makeBlock(s, w: overlap, level: st.level, x: nx)
            st.tower.addChild(b)
            st.tops.append((x: nx, w: overlap))
            let cutW = abs(dx)
            let cutX = dx > 0 ? nx + overlap / 2 + cutW / 2 : nx - overlap / 2 - cutW / 2
            let cut = makeBlock(s, w: cutW, level: st.level, x: cutX)
            cut.alpha = 0.8
            st.tower.addChild(cut)
            let sign: CGFloat = dx > 0 ? 1 : -1
            cut.run(SKAction.sequence([
                SKAction.group([SKAction.moveBy(x: sign * 30, y: -s.h * 0.8, duration: 0.8), SKAction.rotate(byAngle: sign * -1.5, duration: 0.8), SKAction.fadeOut(withDuration: 0.8)]),
                SKAction.removeFromParent()
            ]))
            addScore(s, 1)
            if !s.isCPU { Sfx.shared.play("stomp") }
        }
        spawn(st)
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
        if let st = states.first(where: { $0.seat === seat }) { drop(st) }
    }
}
