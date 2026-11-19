import SpriteKit

/// Reaktions-Duell – wait for green, then tap as fast as possible. 5 rounds.
final class ReactionGame: MiniScene {

    private final class SeatState {
        var panel: SKSpriteNode!
        var glow: SKSpriteNode!
        var title: SKLabelNode!
        var sub: SKLabelNode!
        var ms: SKLabelNode!
        var cross: SKLabelNode!
        var tapped = false
        var locked = false
        var reactMs = 0
        var cpuReact: Double = 0
        var cpuEarly: Double = -1
    }

    private enum Step { case waiting, go, result }

    private let rounds = 5
    private var round = 0
    private var states: [SeatState] = []
    private var step: Step = .result
    private var timer: Double = 0
    private var goTime: Double = 0
    private var order: [Int] = []
    private var rand: Rand!
    private var bestHuman = 0
    private var roundLabels: [SKLabelNode] = []

    private let red = UIColor(red: 0.85, green: 0.12, blue: 0.18, alpha: 1)
    private let green = UIColor(red: 0.1, green: 0.85, blue: 0.35, alpha: 1)

    override func setupGame() {
        rand = newRand()
        for s in seats {
            let st = SeatState()
            let pw = s.w - 20
            let ph = s.h - 56
            let py: CGFloat = -14
            let panel = SKSpriteNode(texture: Gfx.pill(pw, ph, fill: .white, border: nil, corner: 22), size: CGSize(width: pw, height: ph))
            panel.color = UIColor(white: 0.25, alpha: 1)
            panel.colorBlendFactor = 1
            panel.position = CGPoint(x: 0, y: py)
            panel.zPosition = 2
            s.field.addChild(panel)
            st.panel = panel
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: pw * 1.4, height: ph * 1.2))
            glow.blendMode = .add
            glow.alpha = 0
            glow.colorBlendFactor = 1
            glow.position = panel.position
            glow.zPosition = 1
            s.field.addChild(glow)
            st.glow = glow

            let fs = min(40, s.w * 0.16)
            let title = label("BEREIT?", size: fs, color: .white)
            title.position = CGPoint(x: 0, y: py + 20)
            title.zPosition = 5
            s.field.addChild(title)
            st.title = title
            let sub = label("Tippe, wenn es grün wird", size: min(14, s.w * 0.065), color: UIColor(white: 1, alpha: 0.8))
            sub.position = CGPoint(x: 0, y: py - 16)
            sub.zPosition = 5
            s.field.addChild(sub)
            st.sub = sub
            let ms = label("", size: min(30, s.w * 0.13), color: .white)
            ms.position = CGPoint(x: 0, y: py - 56)
            ms.zPosition = 5
            s.field.addChild(ms)
            st.ms = ms
            let cross = label("✕", size: min(120, s.w * 0.5), color: UIColor(white: 1, alpha: 0.9))
            cross.position = CGPoint(x: 0, y: py)
            cross.zPosition = 6
            cross.alpha = 0
            s.field.addChild(cross)
            st.cross = cross

            let bear = makeBear(s, height: min(60, s.h * 0.16), faceRight: true)
            bear.position = CGPoint(x: -pw / 2 + bear.height * 0.75, y: py - ph / 2 + 8)
            bear.zPosition = 4
            bear.alpha = 0.9
            s.field.addChild(bear)

            let rl = label("RUNDE 1/\(rounds)", size: 11, color: UIColor(white: 1, alpha: 0.6))
            rl.horizontalAlignmentMode = .right
            rl.position = CGPoint(x: pw / 2 - 12, y: py - ph / 2 + 14)
            rl.zPosition = 5
            s.field.addChild(rl)
            roundLabels.append(rl)
            states.append(st)
        }
    }

    override func gameStarted() {
        startRound()
    }

    private func startRound() {
        round += 1
        step = .waiting
        order = []
        timer = 1.4 + rand.double() * 2.8
        for s in seats {
            let st = states[s.index]
            st.tapped = false
            st.locked = false
            st.reactMs = 0
            st.panel.color = red
            st.glow.color = red
            st.glow.alpha = 0.35
            st.title.text = "WARTEN…"
            st.sub.text = "Noch nicht tippen!"
            st.ms.text = ""
            st.cross.alpha = 0
            roundLabels[s.index].text = "RUNDE \(round)/\(rounds)"
            if s.isCPU {
                st.cpuReact = (180 + (1 - s.skill) * 270 + Double.random(in: 0...60)) / 1000
                // rare false start for weak CPUs
                if Double.random(in: 0..<1) < 0.06 * (1 - s.skill) {
                    st.cpuEarly = Double.random(in: 0.3...max(0.4, timer - 0.1))
                } else {
                    st.cpuEarly = -1
                }
            }
        }
        Sfx.shared.play("tick")
    }

    override func gameUpdate(_ dt: Double) {
        switch step {
        case .waiting:
            timer -= dt
            for s in seats where s.isCPU {
                let st = states[s.index]
                if st.cpuEarly >= 0 {
                    st.cpuEarly -= dt
                    if st.cpuEarly < 0 { falseStart(s) }
                }
            }
            if timer <= 0 { goSignal() }
        case .go:
            let t = elapsed - goTime
            for s in seats where s.isCPU {
                let st = states[s.index]
                if !st.tapped && !st.locked && t >= st.cpuReact { hit(s) }
            }
            if t > 1.6 || seats.allSatisfy({ states[$0.index].tapped || states[$0.index].locked }) {
                showResult()
            }
        case .result:
            timer -= dt
            if timer <= 0 && phase == .playing {
                if round >= rounds {
                    if bestHuman > 0 { stats["reaction"] = bestHuman }
                    finishGame()
                } else {
                    startRound()
                }
            }
        }
    }

    private func goSignal() {
        step = .go
        goTime = elapsed
        Sfx.shared.play("go")
        for s in seats {
            let st = states[s.index]
            if st.locked { continue }
            st.panel.color = green
            st.glow.color = green
            st.glow.alpha = 0.9
            st.title.text = "JETZT!"
            st.sub.text = "TIPPEN!"
            st.panel.run(SKAction.sequence([SKAction.scale(to: 1.04, duration: 0.05), SKAction.scale(to: 1.0, duration: 0.1)]))
        }
    }

    private func falseStart(_ s: Seat) {
        let st = states[s.index]
        if st.locked || st.tapped { return }
        st.locked = true
        st.panel.color = UIColor(white: 0.2, alpha: 1)
        st.glow.alpha = 0
        st.title.text = "ZU FRÜH!"
        st.sub.text = "Gesperrt für diese Runde"
        st.cross.alpha = 1
        st.cross.fontColor = red
        st.cross.setScale(1.4)
        st.cross.run(SKAction.scale(to: 1.0, duration: 0.15))
        s.shake()
        if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
        if seats.allSatisfy({ states[$0.index].locked }) {
            showResult()
        }
    }

    private func hit(_ s: Seat) {
        let st = states[s.index]
        if st.tapped || st.locked { return }
        st.tapped = true
        let ms = Int(((elapsed - goTime) * 1000).rounded())
        st.reactMs = ms
        order.append(s.index)
        let place = order.count
        st.ms.text = "\(ms) ms"
        st.title.text = place == 1 ? "ERSTER!" : "\(place). PLATZ"
        st.sub.text = ms < 250 ? "Blitzschnell!" : (ms < 350 ? "Stark!" : "Geht schneller…")
        s.burst(at: CGPoint(x: 0, y: -14), color: place == 1 ? UIColor.yellow : s.color, count: place == 1 ? 18 : 8)
        if !s.isCPU {
            Sfx.shared.play(place == 1 ? "right" : "tap")
            Haptic.good()
            if bestHuman == 0 || ms < bestHuman { bestHuman = ms }
        }
    }

    private func showResult() {
        if step == .result { return }
        step = .result
        timer = 1.6
        let table: [Int] = n == 2 ? [3, 1] : [3, 2, 1, 0]
        for (k, idx) in order.enumerated() {
            let s = seats[idx]
            let pts = k < table.count ? table[k] : 0
            if pts > 0 {
                addScore(s, pts)
                s.floatText("+\(pts)", at: CGPoint(x: 0, y: 40), color: .yellow, size: 30)
            }
        }
        for s in seats {
            let st = states[s.index]
            if !st.tapped && !st.locked {
                st.title.text = "VERPASST"
                st.sub.text = ""
                st.panel.color = UIColor(white: 0.25, alpha: 1)
                st.glow.alpha = 0
            }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        switch step {
        case .waiting: falseStart(seat)
        case .go: hit(seat)
        case .result: break
        }
    }
}
