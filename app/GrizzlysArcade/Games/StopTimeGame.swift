import SpriteKit

/// Zeit-Stopp – the clock is visible for 1 s only, then tap when you think the target time is reached. 5 rounds.
final class StopTimeGame: MiniScene {

    private final class TState {
        var panel: SKSpriteNode!
        var glow: SKSpriteNode!
        var target: SKLabelNode!
        var clock: SKLabelNode!
        var sub: SKLabelNode!
        var err: SKLabelNode!
        var round: SKLabelNode!
        var button: SKSpriteNode!
        var tapped = false
        var stopT = 0.0
        var cpuT = 0.0
    }

    private enum Step { case intro, run, reveal }

    private let rounds = 5
    private var round = 0
    private var step: Step = .intro
    private var t = 0.0          // run time / countdown timer
    private var targets: [Double] = []
    private var states: [TState] = []

    private func gauss() -> Double {
        let u1 = max(1e-9, Double.random(in: 0..<1))
        let u2 = Double.random(in: 0..<1)
        return sqrt(-2 * log(u1)) * cos(2 * Double.pi * u2)
    }

    override func setupGame() {
        let r = newRand()
        targets = Array(r.shuffled([2.0, 3.0, 4.0, 5.0, 6.0, 7.0]).prefix(rounds))
        for s in seats {
            let st = TState()
            let w = s.w, h = s.h
            let pw = w - 20, ph = h - 56
            let py: CGFloat = -14
            let panel = SKSpriteNode(texture: Gfx.pill(pw, ph, fill: UIColor(white: 0.08, alpha: 0.9), border: s.color.withAlphaComponent(0.5), corner: 22, gloss: false), size: CGSize(width: pw, height: ph))
            panel.position = CGPoint(x: 0, y: py)
            panel.zPosition = 1
            s.field.addChild(panel)
            st.panel = panel
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: pw * 1.3, height: ph * 0.7))
            glow.blendMode = .add
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.alpha = 0.25
            glow.position = CGPoint(x: 0, y: py + 10)
            glow.zPosition = 2
            s.field.addChild(glow)
            st.glow = glow

            let cap = label("ZIELZEIT", size: min(12, w * 0.06), color: UIColor(white: 1, alpha: 0.6))
            cap.position = CGPoint(x: 0, y: py + ph / 2 - 24)
            cap.zPosition = 5
            s.field.addChild(cap)
            let tg = label("", size: min(44, w * 0.2), color: Theme.uiOrange)
            tg.position = CGPoint(x: 0, y: py + ph / 2 - 58)
            tg.zPosition = 5
            s.field.addChild(tg)
            st.target = tg
            let clock = label("0.00", size: min(64, w * 0.3), color: .white)
            clock.position = CGPoint(x: 0, y: py + 8)
            clock.zPosition = 5
            s.field.addChild(clock)
            st.clock = clock
            let err = label("", size: min(22, w * 0.11), color: .white)
            err.position = CGPoint(x: 0, y: py - 38)
            err.zPosition = 5
            s.field.addChild(err)
            st.err = err
            let sub = label("", size: min(13, w * 0.065), color: UIColor(white: 1, alpha: 0.8))
            sub.position = CGPoint(x: 0, y: py - 62)
            sub.zPosition = 5
            s.field.addChild(sub)
            st.sub = sub
            let rl = label("RUNDE 1/\(rounds)", size: 11, color: UIColor(white: 1, alpha: 0.5))
            rl.position = CGPoint(x: 0, y: py + ph / 2 - 8)
            rl.zPosition = 5
            s.field.addChild(rl)
            st.round = rl

            let bw = pw - 40
            let btn = MiniScene.button("STOPP", w: bw, h: 46, color: s.color, fontSize: min(22, w * 0.1))
            btn.position = CGPoint(x: 0, y: py - ph / 2 + 36)
            btn.zPosition = 6
            s.field.addChild(btn)
            st.button = btn
            states.append(st)
        }
    }

    override func gameStarted() { startRound() }

    private func startRound() {
        step = .intro
        t = 1.4
        let target = targets[round]
        for s in seats {
            let st = states[s.index]
            st.tapped = false
            st.stopT = 0
            st.target.text = String(format: "%.2f s", target)
            st.target.setScale(1.6)
            st.target.run(SKAction.scale(to: 1, duration: 0.2))
            st.clock.text = "0.00"
            st.clock.fontColor = UIColor(white: 1, alpha: 0.45)
            st.clock.alpha = 1
            st.err.text = ""
            st.sub.text = "GLEICH GEHT'S LOS …"
            st.round.text = "RUNDE \(round + 1)/\(rounds)"
            st.button.alpha = 0.35
            st.glow.color = s.color
            st.glow.alpha = 0.25
            if s.isCPU {
                st.cpuT = max(0.4, target + gauss() * (0.04 + 0.3 * (1 - s.skill)))
            }
        }
        Sfx.shared.play("tick")
    }

    private func beginRun() {
        step = .run
        t = 0
        for s in seats {
            let st = states[s.index]
            st.clock.fontColor = .white
            st.sub.text = round == 0 ? "TIPPEN BEI ZIELZEIT" : "UHR VERSCHWINDET …"
            st.button.alpha = 1
        }
        Sfx.shared.play("go")
    }

    override func gameUpdate(_ dt: Double) {
        switch step {
        case .intro:
            t -= dt
            if t <= 0 { beginRun() }
        case .run:
            t += dt
            let target = targets[round]
            for s in seats {
                let st = states[s.index]
                if st.tapped { continue }
                if t < 1.0 {
                    st.clock.text = String(format: "%.2f", t)
                } else if st.clock.text != "?.??" {
                    st.clock.text = "?.??"
                    st.clock.fontColor = UIColor(white: 1, alpha: 0.5)
                    st.clock.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.2, duration: 0.2), SKAction.fadeAlpha(to: 0.8, duration: 0.2)]))
                    st.sub.text = "UHR VERSTECKT"
                }
                if s.isCPU && t >= st.cpuT { stop(s) }
            }
            if seats.allSatisfy({ states[$0.index].tapped }) || t > target + 2.5 { beginReveal() }
        case .reveal:
            t -= dt
            if t <= 0 && phase == .playing {
                round += 1
                if round >= rounds { finishGame() } else { startRound() }
            }
        }
    }

    private func stop(_ s: Seat) {
        let st = states[s.index]
        if step != .run || st.tapped { return }
        st.tapped = true
        st.stopT = t
        let target = targets[round]
        let e = t - target
        let ae = abs(e)
        let pts = ae < 0.1 ? 5 : (ae < 0.25 ? 3 : (ae < 0.5 ? 1 : 0))
        let col: UIColor = ae < 0.1 ? Theme.uiGreen : (ae < 0.25 ? .yellow : (ae < 0.5 ? Theme.uiOrange : UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)))
        st.clock.removeAllActions()
        st.clock.alpha = 1
        st.clock.text = String(format: "%.2f", t)
        st.clock.fontColor = col
        st.clock.setScale(1.3)
        st.clock.run(SKAction.scale(to: 1, duration: 0.2))
        st.err.text = String(format: "%@%.2f s", e >= 0 ? "+" : "−", ae)
        st.err.fontColor = col
        st.sub.text = pts == 5 ? "PERFEKT!" : (pts > 0 ? "GESTOPPT" : "ZU WEIT DANEBEN")
        st.button.alpha = 0.25
        st.glow.color = col
        st.glow.alpha = 0.6
        if pts > 0 {
            addScore(s, pts)
            addStat("hits", 1, seat: s)
            s.floatText("+\(pts)", at: CGPoint(x: 0, y: 40), color: col, size: pts == 5 ? 34 : 26)
            s.burst(at: CGPoint(x: 0, y: -6), color: col, count: pts == 5 ? 24 : 10)
        }
        if !s.isCPU {
            Sfx.shared.play(pts >= 3 ? "right" : (pts > 0 ? "tap" : "miss"))
            if pts > 0 { Haptic.good() } else { Haptic.bad() }
        }
    }

    private func beginReveal() {
        if step == .reveal { return }
        step = .reveal
        t = 1.6
        for s in seats {
            let st = states[s.index]
            if !st.tapped {
                st.clock.text = String(format: "%.2f", targets[round])
                st.clock.fontColor = UIColor(white: 1, alpha: 0.5)
                st.sub.text = "ZU SPÄT"
                st.err.text = ""
                st.button.alpha = 0.15
            }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        stop(seat)
    }
}
