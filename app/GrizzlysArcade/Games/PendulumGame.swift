import SpriteKit

/// Pendel-Wurf – the ball swings on a rope; tap to release it so it flies along the tangent onto the rings. 6 throws.
final class PendulumGame: MiniScene {

    private final class PState {
        var rope: SKSpriteNode!
        var ball: SKSpriteNode!
        var glow: SKSpriteNode!
        var target = SKNode()
        var targetGlow: SKSpriteNode!
        var counter: SKLabelNode!
        var hint: SKLabelNode?
        var idx = 0
        var mode = 0          // 0 swinging, 1 flying, 2 resting, 3 done
        var phase = 0.0
        var timer = 0.0
        var tapPhase = 0.0
    }

    private let throwsPerSeat = 6
    private let amp = 1.15
    private let omega = 2.8
    private var states: [PState] = []
    private var targetPhis: [Double] = []
    private var pivot = CGPoint.zero
    private var len: CGFloat = 50
    private var ringR: CGFloat = 40
    private var dmax: CGFloat = 250
    private var finishedCalled = false

    private func gauss() -> Double {
        let u1 = max(1e-9, Double.random(in: 0..<1))
        let u2 = Double.random(in: 0..<1)
        return sqrt(-2 * log(u1)) * cos(2 * Double.pi * u2)
    }

    private func ballPos(_ phi: Double) -> CGPoint {
        let th = amp * sin(phi)
        return CGPoint(x: pivot.x + len * CGFloat(sin(th)), y: pivot.y - len * CGFloat(cos(th)))
    }

    /// Where the ball lands when released at swing phase `phi`.
    private func landing(_ phi: Double) -> CGPoint {
        let th = amp * sin(phi)
        let c = cos(phi)
        let sg: Double = c >= 0 ? 1 : -1
        var dx = sg * cos(th)
        var dy = sg * sin(th) + 0.9
        let l = hypot(dx, dy)
        dx /= l; dy /= l
        let f = 0.35 + 0.65 * abs(c)
        let p = ballPos(phi)
        return CGPoint(x: p.x + CGFloat(dx * f) * dmax, y: p.y + CGFloat(dy * f) * dmax)
    }

    override func setupGame() {
        let s0 = seats[0]
        let w = s0.w, h = s0.h
        len = min(64, w * 0.27)
        ringR = min(44, w * 0.2)
        dmax = h * 0.7
        pivot = CGPoint(x: 0, y: -h / 2 + len + 18)

        // identical targets for every seat (as swing phases, converted per seat geometry)
        let r = newRand()
        for _ in 0..<throwsPerSeat {
            var chosen = 0.9
            for _ in 0..<80 {
                let phi = Double(r.range(0, 2 * .pi))
                let p = landing(phi)
                if p.y > pivot.y + 70 && p.y < h / 2 - 44 && abs(p.x) < w / 2 - ringR - 6 {
                    chosen = phi
                    break
                }
            }
            targetPhis.append(chosen)
        }

        for s in seats {
            let st = PState()
            // faint arc guide
            for i in 0...14 {
                let phi = -Double.pi / 2 + Double.pi * Double(i) / 14
                let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 4, height: 4))
                d.position = ballPos(phi)
                d.color = s.color
                d.colorBlendFactor = 1
                d.alpha = 0.3
                d.zPosition = 1
                s.field.addChild(d)
            }
            // target rings
            st.target.zPosition = 2
            for (k, f) in [1.0, 0.6, 0.28].enumerated() {
                let ring = SKSpriteNode(texture: Gfx.circle(ringR, .white), size: CGSize(width: ringR * 2 * CGFloat(f), height: ringR * 2 * CGFloat(f)))
                ring.color = k == 2 ? Theme.uiOrange : s.color
                ring.colorBlendFactor = 1
                ring.alpha = k == 2 ? 0.95 : (k == 0 ? 0.28 : 0.5)
                ring.zPosition = CGFloat(k)
                st.target.addChild(ring)
            }
            let tg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: ringR * 3.4, height: ringR * 3.4))
            tg.blendMode = .add
            tg.color = s.color
            tg.colorBlendFactor = 1
            tg.alpha = 0.6
            tg.zPosition = -1
            st.target.addChild(tg)
            st.targetGlow = tg
            st.target.alpha = 0
            s.field.addChild(st.target)

            // rope + pivot + ball
            let rope = SKSpriteNode(color: UIColor(white: 1, alpha: 0.85), size: CGSize(width: 2.5, height: len))
            rope.anchorPoint = CGPoint(x: 0.5, y: 1)
            rope.position = pivot
            rope.zPosition = 4
            s.field.addChild(rope)
            st.rope = rope
            let pv = SKSpriteNode(texture: Gfx.circle(5, .white), size: CGSize(width: 10, height: 10))
            pv.position = pivot
            pv.color = s.color
            pv.colorBlendFactor = 1
            pv.zPosition = 5
            s.field.addChild(pv)
            let br = max(9, min(13, w * 0.05))
            let ball = SKSpriteNode(texture: Gfx.ball(br), size: CGSize(width: br * 2, height: br * 2))
            ball.position = ballPos(0)
            ball.zPosition = 20
            s.field.addChild(ball)
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: br * 5, height: br * 5))
            g.blendMode = .add
            g.color = Theme.uiOrange
            g.colorBlendFactor = 1
            g.alpha = 0.7
            g.zPosition = -1
            ball.addChild(g)
            st.ball = ball
            st.glow = g

            let bear = makeBear(s, height: 38, faceRight: true)
            bear.position = CGPoint(x: -w / 2 + 34, y: -h / 2 + 4)
            bear.zPosition = 3
            bear.alpha = 0.85
            s.field.addChild(bear)

            let cnt = label("WURF 1/\(throwsPerSeat)", size: 11, color: UIColor(white: 1, alpha: 0.6))
            cnt.horizontalAlignmentMode = .right
            cnt.position = CGPoint(x: w / 2 - 12, y: -h / 2 + 12)
            cnt.zPosition = 6
            s.field.addChild(cnt)
            st.counter = cnt

            let hint = label(s.isCPU ? "" : "TIPPEN = WERFEN", size: min(15, w * 0.075), color: .white)
            hint.position = CGPoint(x: 0, y: pivot.y + 38)
            hint.zPosition = 30
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4), SKAction.fadeOut(withDuration: 0.5)]))
            st.hint = hint
            states.append(st)
        }
    }

    override func gameStarted() {
        for s in seats { startThrow(s) }
    }

    private func startThrow(_ s: Seat) {
        let st = states[s.index]
        st.mode = 0
        st.phase = 0
        st.timer = 0
        st.ball.removeAllActions()
        st.ball.setScale(1)
        st.ball.alpha = 1
        st.ball.position = ballPos(0)
        st.rope.alpha = 1
        st.rope.zRotation = 0
        st.counter.text = "WURF \(st.idx + 1)/\(throwsPerSeat)"
        st.target.position = landing(targetPhis[st.idx])
        st.target.setScale(0.2)
        st.target.alpha = 0
        st.target.run(SKAction.group([SKAction.fadeIn(withDuration: 0.15), SKAction.sequence([SKAction.scale(to: 1.15, duration: 0.18), SKAction.scale(to: 1.0, duration: 0.1)])]))
        if s.isCPU {
            let err = gauss() * (1 - s.skill) * 0.3
            st.tapPhase = max(0.05, targetPhis[st.idx] + err)
        }
    }

    override func gameUpdate(_ dt: Double) {
        var allDone = true
        for s in seats {
            let st = states[s.index]
            switch st.mode {
            case 0:
                allDone = false
                st.phase += omega * dt
                st.timer += dt
                let th = amp * sin(st.phase)
                st.rope.zRotation = CGFloat(th)
                st.ball.position = ballPos(st.phase)
                if s.isCPU {
                    if st.phase >= st.tapPhase { release(s) }
                } else if st.timer > 5 {
                    release(s)
                }
            case 1:
                allDone = false
            case 2:
                allDone = false
                st.timer -= dt
                if st.timer <= 0 {
                    st.idx += 1
                    if st.idx >= throwsPerSeat {
                        st.mode = 3
                        st.ball.run(SKAction.fadeOut(withDuration: 0.3))
                        st.target.run(SKAction.fadeOut(withDuration: 0.3))
                        st.counter.text = "FERTIG"
                    } else {
                        startThrow(s)
                    }
                }
            default:
                break
            }
        }
        if allDone && !finishedCalled {
            finishedCalled = true
            finishGame()
        }
    }

    private func release(_ s: Seat) {
        let st = states[s.index]
        if st.mode != 0 { return }
        st.mode = 1
        let land = landing(st.phase)
        st.hint?.removeAllActions()
        st.hint?.alpha = 0
        st.rope.run(SKAction.fadeAlpha(to: 0.2, duration: 0.15))
        Sfx.shared.play("kick")
        if !s.isCPU { Haptic.tap(.medium) }
        let move = SKAction.move(to: land, duration: 0.5)
        move.timingMode = .easeOut
        let arc = SKAction.sequence([SKAction.scale(to: 1.6, duration: 0.25), SKAction.scale(to: 1.0, duration: 0.25)])
        st.ball.run(SKAction.group([move, arc]))
        // trail
        let color = s.color
        let trail = SKAction.repeat(SKAction.sequence([
            SKAction.run { [weak st, weak s] in
                guard let st = st, let s = s else { return }
                let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 8, height: 8))
                d.color = color
                d.colorBlendFactor = 1
                d.blendMode = .add
                d.position = st.ball.position
                d.zPosition = 15
                s.field.addChild(d)
                d.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.3), SKAction.scale(to: 0.2, duration: 0.3)]), SKAction.removeFromParent()]))
            },
            SKAction.wait(forDuration: 0.05)
        ]), count: 10)
        st.ball.run(trail)
        run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.run { [weak self] in self?.landed(s, at: land) }]))
    }

    private func landed(_ s: Seat, at p: CGPoint) {
        let st = states[s.index]
        if st.mode != 1 || phase != .playing { return }
        let d = hypot(p.x - st.target.position.x, p.y - st.target.position.y)
        let pts: Int = d < ringR * 0.28 ? 5 : (d < ringR * 0.6 ? 3 : (d < ringR ? 1 : 0))
        st.mode = 2
        st.timer = 0.9
        if pts > 0 {
            addScore(s, pts)
            addStat("hits", 1, seat: s)
            s.floatText("+\(pts)", at: CGPoint(x: p.x, y: p.y + 24), color: pts == 5 ? .yellow : .white, size: pts == 5 ? 34 : 26)
            s.burst(at: p, color: pts == 5 ? .yellow : s.color, count: pts == 5 ? 22 : 10)
            st.targetGlow.run(SKAction.sequence([SKAction.fadeAlpha(to: 1, duration: 0.05), SKAction.fadeAlpha(to: 0.6, duration: 0.3)]))
            st.target.run(SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.07), SKAction.scale(to: 1.0, duration: 0.12)]))
            if !s.isCPU { Sfx.shared.play(pts == 5 ? "goal" : "right"); Haptic.good() }
            if pts == 5 { s.banner("VOLLTREFFER!", color: .yellow, size: 28, duration: 0.5) }
        } else {
            s.floatText("DANEBEN", at: CGPoint(x: p.x, y: p.y + 24), color: UIColor(white: 1, alpha: 0.8), size: 18)
            s.burst(at: p, color: UIColor(white: 0.7, alpha: 1), count: 5, speed: 50)
            if !s.isCPU { Sfx.shared.play("miss"); Haptic.bad() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        release(seat)
    }
}
