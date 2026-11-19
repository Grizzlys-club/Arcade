import SpriteKit

/// Finger-Blitz – hold the pad, release the moment it lights up. 5 rounds.
final class ReflexGame: MiniScene {

    private final class St {
        var pad: SKSpriteNode!
        var glow: SKSpriteNode!
        var ring: SKSpriteNode!
        var title: SKLabelNode!
        var sub: SKLabelNode!
        var ms: SKLabelNode!
        var dots: [SKSpriteNode] = []
        var holding = false
        var released = false
        var locked = false
        var reactMs = 0
        var cpuReact = 0.0
        var cpuEarly = -1.0
    }

    private enum Step { case prep, waiting, go, result }

    private let rounds = 5
    private var round = 0
    private var states: [St] = []
    private var step: Step = .result
    private var timer = 0.0
    private var goTime = 0.0
    private var order: [Int] = []
    private var rand: Rand!
    private var bestHuman = 0
    private var ending = false

    private let red = UIColor(red: 0.9, green: 0.12, blue: 0.2, alpha: 1)
    private let green = UIColor(red: 0.1, green: 0.9, blue: 0.4, alpha: 1)
    private let idle = UIColor(red: 0.16, green: 0.17, blue: 0.28, alpha: 1)

    override func setupGame() {
        rand = newRand()
        for s in seats {
            let st = St()
            let pw = s.w - 20, ph = s.h - 74
            let py: CGFloat = -4
            let pad = SKSpriteNode(texture: Gfx.pill(pw, ph, fill: .white, border: UIColor(white: 1, alpha: 0.3), corner: 24), size: CGSize(width: pw, height: ph))
            pad.color = idle
            pad.colorBlendFactor = 1
            pad.position = CGPoint(x: 0, y: py)
            pad.zPosition = 2
            s.field.addChild(pad)
            st.pad = pad
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: pw * 1.4, height: ph * 1.25))
            glow.blendMode = .add
            glow.colorBlendFactor = 1
            glow.alpha = 0
            glow.position = pad.position
            glow.zPosition = 1
            s.field.addChild(glow)
            st.glow = glow
            let rd = min(pw, ph) * 0.42
            let ring = SKSpriteNode(texture: Gfx.circle(rd, UIColor(white: 1, alpha: 0.08), ring: UIColor(white: 1, alpha: 0.7)), size: CGSize(width: rd * 2, height: rd * 2))
            ring.position = CGPoint(x: 0, y: py + 10)
            ring.zPosition = 3
            s.field.addChild(ring)
            st.ring = ring
            ring.run(SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.06, duration: 0.6), SKAction.scale(to: 0.96, duration: 0.6)])), withKey: "pulse")
            st.title = label("FINGER DRAUF", size: min(26, s.w * 0.1), color: .white)
            st.title.position = CGPoint(x: 0, y: py + 22)
            st.title.zPosition = 5
            s.field.addChild(st.title)
            st.sub = label("Halten, bei GRÜN loslassen", size: min(12, s.w * 0.06), color: UIColor(white: 1, alpha: 0.8))
            st.sub.position = CGPoint(x: 0, y: py - 8)
            st.sub.zPosition = 5
            s.field.addChild(st.sub)
            st.ms = label("", size: min(30, s.w * 0.14), color: .white)
            st.ms.position = CGPoint(x: 0, y: py - 42)
            st.ms.zPosition = 5
            s.field.addChild(st.ms)
            for k in 0..<rounds {
                let d = SKSpriteNode(texture: Gfx.circle(5, .white), size: CGSize(width: 10, height: 10))
                d.color = UIColor(white: 0.3, alpha: 1)
                d.colorBlendFactor = 1
                d.position = CGPoint(x: CGFloat(k - 2) * 18, y: -s.h / 2 + 12)
                d.zPosition = 3
                s.field.addChild(d)
                st.dots.append(d)
            }
            states.append(st)
        }
    }

    override func gameStarted() { startRound() }

    private func startRound() {
        round += 1
        step = .prep
        timer = round == 1 ? 4.0 : 3.0
        order = []
        for s in seats {
            let st = states[s.index]
            st.released = false
            st.locked = false
            st.reactMs = 0
            st.holding = s.isCPU
            st.ms.text = ""
            st.pad.color = idle
            st.glow.alpha = 0
            st.title.text = s.isCPU ? "BEREIT" : "FINGER DRAUF"
            st.sub.text = s.isCPU ? "" : "Halten, bei GRÜN loslassen"
            st.cpuReact = (0.19 + (1 - s.skill) * 0.3 + Double.random(in: 0...0.06))
            st.cpuEarly = Double.random(in: 0..<1) < 0.05 * (1 - s.skill) ? Double.random(in: 0.3...1.0) : -1
        }
        Sfx.shared.play("tick")
    }

    private func beginWait() {
        step = .waiting
        timer = 1.5 + rand.double() * 2.5
        for s in seats {
            let st = states[s.index]
            if !st.holding {
                lockOut(s, "NICHT GEHALTEN")
            } else {
                st.pad.color = red
                st.glow.color = red
                st.glow.alpha = 0.35
                st.title.text = "WARTEN…"
                st.sub.text = "Noch nicht loslassen!"
            }
        }
    }

    private func lockOut(_ s: Seat, _ why: String) {
        let st = states[s.index]
        if st.locked || st.released { return }
        st.locked = true
        st.pad.color = UIColor(white: 0.18, alpha: 1)
        st.glow.alpha = 0
        st.title.text = why == "" ? "ZU FRÜH!" : why
        st.sub.text = "Gesperrt (0 Punkte)"
        st.dots[round - 1].color = red
        s.shake()
        if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
    }

    override func gameUpdate(_ dt: Double) {
        switch step {
        case .prep:
            timer -= dt
            let humans = seats.filter { !$0.isCPU }
            if humans.allSatisfy({ states[$0.index].holding }) && timer < (round == 1 ? 3.4 : 2.4) || timer <= 0 { beginWait() }
        case .waiting:
            timer -= dt
            for s in seats where s.isCPU {
                let st = states[s.index]
                if st.cpuEarly >= 0 {
                    st.cpuEarly -= dt
                    if st.cpuEarly < 0 { lockOut(s, "") }
                }
            }
            if timer <= 0 { goSignal() }
        case .go:
            let t = elapsed - goTime
            for s in seats where s.isCPU {
                let st = states[s.index]
                if !st.released && !st.locked && t >= st.cpuReact { release(s) }
            }
            if t > 1.6 || seats.allSatisfy({ states[$0.index].released || states[$0.index].locked }) { showResult() }
        case .result:
            timer -= dt
            if timer <= 0 && !ending {
                if round >= rounds {
                    ending = true
                    if bestHuman > 0 { stats["reaction"] = bestHuman }
                    finishGame()
                } else { startRound() }
            }
        }
        if step == .waiting && seats.allSatisfy({ states[$0.index].locked }) { showResult() }
    }

    private func goSignal() {
        step = .go
        goTime = elapsed
        Sfx.shared.play("go")
        for s in seats {
            let st = states[s.index]
            if st.locked { continue }
            st.pad.color = green
            st.glow.color = green
            st.glow.alpha = 0.95
            st.title.text = "LOS!"
            st.sub.text = "LOSLASSEN!"
            st.pad.run(SKAction.sequence([SKAction.scale(to: 1.04, duration: 0.05), SKAction.scale(to: 1, duration: 0.1)]))
            if !s.isCPU { Haptic.tap() }
        }
    }

    private func release(_ s: Seat) {
        let st = states[s.index]
        if st.released || st.locked { return }
        st.released = true
        let ms = Int(((elapsed - goTime) * 1000).rounded())
        st.reactMs = ms
        order.append(s.index)
        let place = order.count
        st.ms.text = "\(ms) ms"
        st.title.text = place == 1 ? "ERSTER!" : "\(place). PLATZ"
        st.sub.text = ms < 250 ? "Blitzschnell!" : (ms < 350 ? "Stark!" : "Geht schneller…")
        st.glow.alpha = 0.4
        s.burst(at: CGPoint(x: 0, y: 0), color: place == 1 ? .yellow : s.color, count: place == 1 ? 20 : 8)
        if !s.isCPU {
            Sfx.shared.play(place == 1 ? "right" : "tap")
            Haptic.good()
            if bestHuman == 0 || ms < bestHuman { bestHuman = ms }
        }
    }

    private func showResult() {
        if step == .result { return }
        step = .result
        timer = 1.7
        let table: [Int] = n == 2 ? [3, 1] : [3, 2, 1]
        for (k, idx) in order.enumerated() {
            let s = seats[idx]
            let pts = k < table.count ? table[k] : 0
            states[idx].dots[round - 1].color = k == 0 ? UIColor.yellow : s.color
            if pts > 0 {
                addScore(s, pts)
                s.floatText("+\(pts)", at: CGPoint(x: 0, y: 50), color: .yellow, size: 30)
            }
        }
        for s in seats {
            let st = states[s.index]
            if !st.released && !st.locked {
                st.title.text = "VERPASST"
                st.sub.text = ""
                st.pad.color = UIColor(white: 0.25, alpha: 1)
                st.glow.alpha = 0
            }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        if step == .prep && !st.holding {
            st.holding = true
            st.pad.color = UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1)
            st.title.text = "GUT – HALTEN"
            st.sub.text = "Warte auf die anderen…"
            Sfx.shared.play("tap"); Haptic.tap()
        }
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        guard st.holding else { return }
        st.holding = false
        switch step {
        case .prep:
            st.pad.color = idle
            st.title.text = "FINGER DRAUF"
            st.sub.text = "Halten, bei GRÜN loslassen"
        case .waiting: lockOut(seat, "")
        case .go: release(seat)
        case .result: break
        }
    }
}
