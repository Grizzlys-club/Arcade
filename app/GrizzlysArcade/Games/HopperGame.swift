import SpriteKit

/// Bären-Hüpfer: Doodle-Jump style. Bear bounces automatically, steer toward the finger. Score = height.
final class HopperGame: MiniScene {
    fileprivate enum Kind { case normal, moving, breaking }

    fileprivate final class Plat {
        let node: SKSpriteNode
        var x: CGFloat
        let baseX: CGFloat
        let y: CGFloat
        let kind: Kind
        let amp: CGFloat
        let phase: CGFloat
        var broken = false
        init(node: SKSpriteNode, x: CGFloat, y: CGFloat, kind: Kind, amp: CGFloat, phase: CGFloat) {
            self.node = node
            self.x = x
            self.baseX = x
            self.y = y
            self.kind = kind
            self.amp = amp
            self.phase = phase
        }
    }

    fileprivate final class State {
        let seat: Seat
        let rand: Rand
        let cam = SKNode()
        let bear: BearNode
        var plats: [Plat] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var vx: CGFloat = 0
        var vy: CGFloat = 0
        var camY: CGFloat = 0
        var lastY: CGFloat = 0
        var targetX: CGFloat? = nil
        var landY: CGFloat = 0
        var cpuTimer: Double = 0
        var height = 0
        init(seat: Seat, rand: Rand, bear: BearNode) {
            self.seat = seat
            self.rand = rand
            self.bear = bear
        }
    }

    private var states: [State] = []
    private let gravity: CGFloat = -1150
    private let jumpV: CGFloat = 560
    private let bearH: CGFloat = 30

    private func platW(_ s: Seat) -> CGFloat { return min(64, s.w * 0.3) }

    override func setupGame() {
        duration = 60
        for s in seats {
            let bear = makeBear(s, height: bearH, faceRight: true)
            let st = State(seat: s, rand: newRand(), bear: bear)
            s.field.addChild(st.cam)
            st.cam.zPosition = 5
            // start platform
            let y0 = -s.h / 2 + 34
            addPlat(st, x: 0, y: y0, kind: .normal, width: s.w * 0.6)
            st.lastY = y0
            st.landY = y0
            st.x = 0
            st.y = y0
            bear.position = CGPoint(x: 0, y: y0 + 6)
            bear.zPosition = 20
            st.cam.addChild(bear)
            generate(st)
            let hint = label(s.isCPU ? "CPU" : "FINGER ← → ZIEHEN", size: s.w > 300 ? 18 : 12, color: UIColor(white: 1, alpha: 0.85))
            hint.position = CGPoint(x: 0, y: 0)
            hint.zPosition = 40
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.6), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            states.append(st)
        }
    }

    override func gameStarted() {
        for st in states { st.vy = jumpV }
    }

    private func addPlat(_ st: State, x: CGFloat, y: CGFloat, kind: Kind, width: CGFloat? = nil, amp: CGFloat = 0, phase: CGFloat = 0) {
        let s = st.seat
        let pw = width ?? platW(s)
        let fill: UIColor
        let border: UIColor
        switch kind {
        case .normal:
            fill = s.color
            border = UIColor.white
        case .moving:
            fill = UIColor(red: 0.3, green: 0.85, blue: 1, alpha: 1)
            border = UIColor.white
        case .breaking:
            fill = UIColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1)
            border = UIColor(red: 0.8, green: 0.55, blue: 0.3, alpha: 1)
        }
        let node = SKSpriteNode(texture: Gfx.pill(pw, 14, fill: fill, border: border, corner: 7), size: CGSize(width: pw, height: 14))
        node.position = CGPoint(x: x, y: y - 7)
        st.cam.addChild(node)
        if kind == .breaking {
            let crack = label("⚡︎", size: 10, color: UIColor(white: 0, alpha: 0.6))
            crack.zPosition = 1
            node.addChild(crack)
        } else {
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: pw * 1.4, height: 26))
            glow.color = fill
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.35
            glow.zPosition = -1
            node.addChild(glow)
        }
        st.plats.append(Plat(node: node, x: x, y: y, kind: kind, amp: amp, phase: phase))
    }

    private func generate(_ st: State) {
        let s = st.seat
        let pw = platW(s)
        let half = s.w / 2 - pw / 2 - 6
        while st.lastY < st.camY + s.h {
            let hardness = min(1, max(0, st.lastY) / 4000)
            let gap = st.rand.range(42, 62 + 40 * hardness)
            st.lastY += gap
            let x = st.rand.range(-half, half)
            let r = st.rand.double()
            if r < Double(0.18 + 0.2 * hardness) {
                let amp = st.rand.range(20, max(22, half))
                addPlat(st, x: 0, y: st.lastY, kind: .moving, amp: min(amp, half), phase: st.rand.range(0, 6.28))
            } else {
                addPlat(st, x: x, y: st.lastY, kind: .normal)
            }
            if st.rand.chance(Double(0.22 + 0.15 * hardness)) {
                let bx = st.rand.range(-half, half)
                addPlat(st, x: bx, y: st.lastY + gap * 0.5, kind: .breaking)
            }
        }
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        let t = CGFloat(elapsed)
        for st in states {
            let s = st.seat
            guard s.alive else { continue }
            for p in st.plats where p.kind == .moving {
                p.x = p.baseX + sin(t * 1.6 + p.phase) * p.amp
                p.node.position.x = p.x
            }
            if s.isCPU { cpuThink(st, dt) }
            if let tx = st.targetX {
                st.vx = max(-340, min(340, (tx - st.x) * 8))
            } else {
                st.vx *= (1 - min(1, 5 * fdt))
            }
            let prevY = st.y
            st.vy += gravity * fdt
            st.x += st.vx * fdt
            st.y += st.vy * fdt
            let lim = s.w / 2 - 10
            st.x = max(-lim, min(lim, st.x))
            if st.vy < 0 {
                for p in st.plats where !p.broken {
                    let pw = p.node.size.width
                    if prevY >= p.y - 1 && st.y <= p.y && abs(st.x - p.x) < pw / 2 + 8 {
                        if p.kind == .breaking {
                            p.broken = true
                            p.node.run(SKAction.sequence([
                                SKAction.group([SKAction.moveBy(x: 0, y: -120, duration: 0.5), SKAction.fadeOut(withDuration: 0.5), SKAction.rotate(byAngle: 0.8, duration: 0.5)]),
                                SKAction.removeFromParent()
                            ]))
                            if !s.isCPU { Sfx.shared.play("miss") }
                            continue
                        }
                        st.y = p.y
                        st.vy = jumpV
                        st.landY = p.y
                        st.bear.squash()
                        if !s.isCPU { Sfx.shared.play("bounce") }
                        break
                    }
                }
            }
            st.bear.position = CGPoint(x: st.x, y: st.y)
            if abs(st.vx) > 20 { st.bear.setFacing(right: st.vx > 0) }
            // camera
            let follow = st.y - s.h * 0.05
            if follow > st.camY { st.camY = follow }
            st.cam.position.y = -st.camY
            let hgt = Int(max(0, st.camY) / 10)
            if hgt != st.height {
                st.height = hgt
                s.score = hgt
                s.scoreLabel?.text = "\(hgt)"
            }
            generate(st)
            // cleanup
            st.plats.removeAll { p in
                if p.y < st.camY - s.h / 2 - 60 {
                    p.node.removeFromParent()
                    return true
                }
                return false
            }
            if st.y < st.camY - s.h / 2 - 30 {
                fall(st)
            }
        }
        checkEnd()
    }

    private func fall(_ st: State) {
        let s = st.seat
        s.knockOut("ABGESTÜRZT")
        Sfx.shared.play("lose")
        if !s.isCPU { Haptic.bad() }
        s.flash(UIColor.red, alpha: 0.3)
    }

    private func cpuThink(_ st: State, _ dt: Double) {
        st.cpuTimer -= dt
        if st.cpuTimer > 0 { return }
        let s = st.seat
        st.cpuTimer = 0.08 + (1 - s.skill) * 0.25
        let apex = st.y + (st.vy > 0 ? st.vy * st.vy / (2 * -gravity) : 0)
        let allowTrap = Double.random(in: 0...1) < (1 - s.skill) * 0.3
        var best: Plat? = nil
        for p in st.plats where !p.broken && (p.kind != .breaking || allowTrap) {
            if p.y <= apex - 6 && p.y > st.landY + 4 {
                if best == nil || p.y > best!.y { best = p }
            }
        }
        if best == nil {
            for p in st.plats where !p.broken && p.kind != .breaking && p.y < st.y {
                if best == nil || p.y > best!.y { best = p }
            }
        }
        if let b = best {
            let noise = CGFloat.random(in: -1...1) * CGFloat(1 - s.skill) * b.node.size.width * 0.9
            st.targetX = b.x + noise
        }
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
            if a.score > others + 5 { finishGame() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.targetX = at.x
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.targetX = at.x
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        states.first(where: { $0.seat === seat })?.targetX = nil
    }
}
