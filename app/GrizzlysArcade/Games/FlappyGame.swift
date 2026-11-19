import SpriteKit

/// Flatter-Bär: tap to flap through gaps in hockey boards. Score = gates passed.
final class FlappyGame: MiniScene {
    fileprivate final class Gate {
        let node = SKNode()
        var x: CGFloat
        let gapY: CGFloat
        let gap: CGFloat
        var passed = false
        init(x: CGFloat, gapY: CGFloat, gap: CGFloat) {
            self.x = x
            self.gapY = gapY
            self.gap = gap
        }
    }

    fileprivate final class State {
        let seat: Seat
        let rand: Rand
        let bear: BearNode
        let layer = SKNode()
        var y: CGFloat = 0
        var vy: CGFloat = 0
        var gates: [Gate] = []
        var nextSpawn: CGFloat = 70
        var cpuCooldown: Double = 0
        var cpuNoise: CGFloat = 0
        var cpuGate: ObjectIdentifier? = nil
        var hint: SKLabelNode?
        init(seat: Seat, rand: Rand, bear: BearNode) {
            self.seat = seat
            self.rand = rand
            self.bear = bear
        }
    }

    private var states: [State] = []
    private let gravity: CGFloat = -950
    private let flapV: CGFloat = 300
    private let gateW: CGFloat = 26
    private let bearR: CGFloat = 12
    private let bearH: CGFloat = 30

    private func yTop(_ s: Seat) -> CGFloat { return s.h / 2 - 32 }
    private func yBot(_ s: Seat) -> CGFloat { return -s.h / 2 + 10 }
    private func bearX(_ s: Seat) -> CGFloat { return -s.w * 0.25 }

    override func setupGame() {
        duration = 60
        for s in seats {
            let bear = makeBear(s, height: bearH, faceRight: true)
            let st = State(seat: s, rand: newRand(), bear: bear)
            s.field.addChild(st.layer)
            st.layer.zPosition = 5
            // floor and ceiling lines
            for yy in [yBot(s), yTop(s)] {
                let line = SKSpriteNode(color: s.color.withAlphaComponent(0.6), size: CGSize(width: s.w, height: 3))
                line.position = CGPoint(x: 0, y: yy)
                line.zPosition = 2
                s.field.addChild(line)
                let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: s.w * 1.2, height: 26))
                glow.color = s.color
                glow.colorBlendFactor = 1
                glow.alpha = 0.35
                glow.blendMode = .add
                glow.position = line.position
                glow.zPosition = 1
                s.field.addChild(glow)
            }
            // drifting background dots (parallax)
            for i in 0..<10 {
                let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 4, height: 4))
                d.alpha = 0.25
                d.position = CGPoint(x: CGFloat(i) * s.w / 10 - s.w / 2, y: CGFloat.random(in: yBot(s)...yTop(s)))
                d.zPosition = 0
                s.field.addChild(d)
                let dur = Double.random(in: 4...8)
                d.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: -s.w - 20, y: 0, duration: dur),
                    SKAction.moveBy(x: s.w + 20, y: 0, duration: 0)
                ])))
            }
            st.y = 0
            bear.position = CGPoint(x: bearX(s), y: st.y - bearH / 2)
            bear.zPosition = 20
            s.field.addChild(bear)
            bear.startBob(amount: 4, duration: 0.3)
            let hint = label(s.isCPU ? "CPU" : "TIPPEN = FLATTERN", size: s.w > 300 ? 18 : 13, color: UIColor(white: 1, alpha: 0.8))
            hint.position = CGPoint(x: 0, y: -s.h * 0.25)
            hint.zPosition = 30
            s.field.addChild(hint)
            st.hint = hint
            states.append(st)
        }
    }

    override func gameStarted() {
        for st in states {
            st.bear.stopBob()
            st.vy = flapV * 0.6
            st.hint?.run(SKAction.sequence([SKAction.wait(forDuration: 1.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private var scrollSpeed: CGFloat {
        let w = seats.first?.w ?? 390
        return (95 + CGFloat(elapsed) * 2.0) * (0.72 + 0.28 * w / 390)
    }

    private func spacing(_ s: Seat) -> CGFloat {
        return max(135, s.w * 0.55)
    }

    private func spawnGate(_ st: State) {
        let s = st.seat
        let gap = max(92, 138 - CGFloat(elapsed) * 0.75)
        let lo = yBot(s) + gap / 2 + 16
        let hi = yTop(s) - gap / 2 - 16
        let gy = st.rand.range(lo, max(lo, hi))
        let g = Gate(x: s.w / 2 + gateW, gapY: gy, gap: gap)
        // bottom board
        let botH = (gy - gap / 2) - yBot(s)
        let topH = yTop(s) - (gy + gap / 2)
        for (hgt, cy, capY) in [(botH, yBot(s) + botH / 2, gy - gap / 2), (topH, yTop(s) - topH / 2, gy + gap / 2)] {
            if hgt <= 0 { continue }
            let board = SKSpriteNode(color: UIColor(white: 0.93, alpha: 1), size: CGSize(width: gateW, height: hgt))
            board.position = CGPoint(x: 0, y: cy)
            g.node.addChild(board)
            let stripe = SKSpriteNode(color: Theme.uiOrange.withAlphaComponent(0.9), size: CGSize(width: 5, height: hgt))
            stripe.position = CGPoint(x: 0, y: cy)
            stripe.zPosition = 1
            g.node.addChild(stripe)
            let cap = SKSpriteNode(color: s.color, size: CGSize(width: gateW + 8, height: 8))
            cap.position = CGPoint(x: 0, y: capY)
            cap.zPosition = 2
            g.node.addChild(cap)
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: gateW + 40, height: 30))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.6
            glow.position = CGPoint(x: 0, y: capY)
            glow.zPosition = 3
            g.node.addChild(glow)
        }
        g.node.position = CGPoint(x: g.x, y: 0)
        st.layer.addChild(g.node)
        st.gates.append(g)
    }

    private func flap(_ st: State) {
        guard st.seat.alive, phase == .playing else { return }
        st.vy = flapV
        st.bear.squash()
        if !st.seat.isCPU {
            Sfx.shared.play("jump")
            Haptic.tap()
        }
    }

    private func crash(_ st: State) {
        let s = st.seat
        if !s.alive { return }
        s.knockOut("ABSTURZ")
        s.shake(6)
        s.burst(at: CGPoint(x: bearX(s), y: st.y), color: s.color, count: 14)
        Sfx.shared.play("hit")
        if !s.isCPU { Haptic.bad() }
        st.bear.run(SKAction.group([
            SKAction.moveBy(x: 0, y: -s.h, duration: 0.8),
            SKAction.rotate(byAngle: -3, duration: 0.8)
        ]))
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        let dist = scrollSpeed * fdt
        for st in states {
            let s = st.seat
            // gates keep scrolling even after a crash (looks alive), but no spawning
            for g in st.gates {
                g.x -= dist
                g.node.position.x = g.x
            }
            while let f = st.gates.first, f.x < -s.w / 2 - gateW * 2 {
                f.node.removeFromParent()
                st.gates.removeFirst()
            }
            guard s.alive else { continue }
            st.nextSpawn -= dist
            if st.nextSpawn <= 0 {
                st.nextSpawn += spacing(s)
                spawnGate(st)
            }
            if s.isCPU { cpuThink(st, dt) }
            st.vy += gravity * fdt
            st.y += st.vy * fdt
            if st.y + bearR > yTop(s) {
                st.y = yTop(s) - bearR
                st.vy = min(0, st.vy)
            }
            st.bear.position = CGPoint(x: bearX(s), y: st.y - bearH / 2)
            st.bear.zRotation = max(-0.6, min(0.45, st.vy / 650))
            if st.y - bearR < yBot(s) {
                crash(st)
                continue
            }
            let bx = bearX(s)
            for g in st.gates {
                if abs(g.x - bx) < gateW / 2 + bearR - 2 {
                    if st.y - bearR + 3 < g.gapY - g.gap / 2 || st.y + bearR - 3 > g.gapY + g.gap / 2 {
                        crash(st)
                        break
                    }
                }
                if !g.passed && g.x + gateW / 2 < bx - bearR {
                    g.passed = true
                    addScore(s, 1)
                    s.floatText("+1", at: CGPoint(x: bx, y: st.y + 24), color: s.color, size: 18)
                    if !s.isCPU { Sfx.shared.play("pop") }
                }
            }
        }
        checkEnd()
    }

    private func cpuThink(_ st: State, _ dt: Double) {
        st.cpuCooldown -= dt
        let s = st.seat
        let bx = bearX(s)
        let next = st.gates.first { $0.x + gateW / 2 > bx - bearR }
        var target: CGFloat
        if let g = next {
            let id = ObjectIdentifier(g)
            if st.cpuGate != id {
                st.cpuGate = id
                st.cpuNoise = CGFloat.random(in: -1...1) * CGFloat(1 - s.skill) * g.gap * 0.55
            }
            // aim at the lower part of the gap so the flap overshoot stays inside
            target = g.gapY - g.gap / 2 + bearR + 12 + st.cpuNoise * 0.3
        } else {
            target = 0
        }
        let predicted = st.y + st.vy * 0.1 + 0.5 * gravity * 0.01
        if predicted < target && st.cpuCooldown <= 0 {
            if Double.random(in: 0...1) < (1 - s.skill) * 0.012 {
                st.cpuCooldown = 0.3
                return
            }
            st.cpuCooldown = 0.12 + (1 - s.skill) * 0.08
            flap(st)
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
            if a.score > others { finishGame() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if let st = states.first(where: { $0.seat === seat }) { flap(st) }
    }
}
