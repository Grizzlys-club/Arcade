import SpriteKit

/// Puck-Zähler – pucks flash up for 1.2 s, then pick the right count. 8 rounds.
final class CountGame: MiniScene {

    private final class CState {
        var pucks: [SKSpriteNode] = []
        var buttons: [SKSpriteNode] = []
        var status: SKLabelNode!
        var big: SKLabelNode!
        var answered = false
        var locked = false
        var cpuAt = 0.0
        var cpuPick = 0
    }

    private enum Step { case intro, show, answer, reveal }

    private let rounds = 8
    private var round = 0
    private var step: Step = .intro
    private var t = 0.0
    private var answerT = 0.0
    private var order = 0
    private var states: [CState] = []
    private var counts: [Int] = []
    private var options: [[Int]] = []
    private var unitPos: [[CGPoint]] = []
    private var areaCenter = CGPoint.zero
    private var areaSize = CGSize.zero
    private var puckR: CGFloat = 12
    private var btnY: CGFloat = 0

    override func setupGame() {
        let s0 = seats[0]
        let w = s0.w, h = s0.h
        puckR = min(14, w * 0.06)
        let y0 = -h / 2 + 76, y1 = h / 2 - 54
        areaCenter = CGPoint(x: 0, y: (y0 + y1) / 2)
        areaSize = CGSize(width: w - 28, height: y1 - y0)
        btnY = -h / 2 + 34

        // same rounds for everyone
        let r = newRand()
        for _ in 0..<rounds {
            let n = r.int(3, 9)
            counts.append(n)
            var cands = r.shuffled([n - 2, n - 1, n + 1, n + 2, n + 3, n - 3].filter { $0 >= 1 })
            var opts = [n]
            while opts.count < 4 && !cands.isEmpty { opts.append(cands.removeFirst()) }
            options.append(opts.sorted())
            var pts: [CGPoint] = []
            let minD = puckR * 2.3
            for _ in 0..<n {
                var best = CGPoint(x: 0.5, y: 0.5)
                var bestD: CGFloat = -1
                for _ in 0..<40 {
                    let c = CGPoint(x: r.range(0, 1), y: r.range(0, 1))
                    var md = CGFloat.greatestFiniteMagnitude
                    for p in pts {
                        md = min(md, hypot((p.x - c.x) * (areaSize.width - 2 * puckR), (p.y - c.y) * (areaSize.height - 2 * puckR)))
                    }
                    if md > bestD { bestD = md; best = c }
                    if md >= minD { break }
                }
                pts.append(best)
            }
            unitPos.append(pts)
        }

        for s in seats {
            let st = CState()
            for _ in 0..<9 {
                let p = SKSpriteNode(texture: Gfx.circle(puckR, UIColor(white: 0.1, alpha: 1)), size: CGSize(width: puckR * 2, height: puckR * 2))
                let ring = SKSpriteNode(texture: Gfx.circle(puckR * 0.78, UIColor(white: 0.1, alpha: 1)), size: CGSize(width: puckR * 1.56, height: puckR * 1.56))
                ring.color = Theme.uiBlue
                ring.colorBlendFactor = 0.35
                ring.zPosition = 1
                p.addChild(ring)
                let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: puckR * 4.2, height: puckR * 4.2))
                g.blendMode = .add
                g.color = Theme.uiBlue
                g.colorBlendFactor = 1
                g.alpha = 0.6
                g.zPosition = -1
                p.addChild(g)
                p.alpha = 0
                p.zPosition = 5
                s.field.addChild(p)
                st.pucks.append(p)
            }
            let bw = (w - 20 - 18) / 4
            for i in 0..<4 {
                let b = MiniScene.button("?", w: bw, h: 44, color: s.color, fontSize: min(22, w * 0.1))
                b.position = CGPoint(x: -w / 2 + 10 + bw / 2 + CGFloat(i) * (bw + 6), y: btnY)
                b.zPosition = 8
                b.alpha = 0
                s.field.addChild(b)
                st.buttons.append(b)
            }
            let status = label("", size: min(13, w * 0.065), color: UIColor(white: 1, alpha: 0.85))
            status.position = CGPoint(x: 0, y: h / 2 - 40)
            status.zPosition = 6
            s.field.addChild(status)
            st.status = status
            let big = label("", size: min(90, w * 0.4), color: .white)
            big.position = areaCenter
            big.zPosition = 12
            big.alpha = 0
            s.field.addChild(big)
            st.big = big
            states.append(st)
        }
    }

    override func gameStarted() {
        startRound()
    }

    private func startRound() {
        step = .intro
        t = 0.8
        order = 0
        let opts = options[round]
        for s in seats {
            let st = states[s.index]
            st.answered = false
            st.locked = false
            st.big.alpha = 0
            for p in st.pucks { p.removeAllActions(); p.alpha = 0 }
            for (i, b) in st.buttons.enumerated() {
                b.removeAllActions()
                b.alpha = 0
                b.color = s.color
                b.setScale(1)
                if let l = b.children.first as? SKLabelNode { l.text = "\(opts[i])" }
            }
            st.status.text = round == 0 ? "ZÄHLE DIE PUCKS!" : "RUNDE \(round + 1)/\(rounds)"
            if s.isCPU {
                st.cpuAt = 0.5 + (1 - s.skill) * 1.7 + Double.random(in: 0..<0.6)
                let correctIdx = opts.firstIndex(of: counts[round]) ?? 0
                var pick = correctIdx
                if Double.random(in: 0..<1) < 0.04 + 0.42 * pow(1 - s.skill, 1.2) {
                    let n = counts[round]
                    let near = [n - 1, n + 1].compactMap { opts.firstIndex(of: $0) }
                    if !near.isEmpty && Double.random(in: 0..<1) < 0.8 {
                        pick = near[Int.random(in: 0..<near.count)]
                    } else {
                        let wrong = (0..<4).filter { $0 != correctIdx }
                        pick = wrong[Int.random(in: 0..<wrong.count)]
                    }
                }
                st.cpuPick = pick
            }
        }
        Sfx.shared.play("tick")
    }

    private func beginShow() {
        step = .show
        t = 1.2
        let n = counts[round]
        let pos = unitPos[round]
        for s in seats {
            let st = states[s.index]
            st.status.text = "SCHAU GENAU!"
            for i in 0..<n {
                let p = st.pucks[i]
                p.position = puckPoint(pos[i])
                p.setScale(0.1)
                p.alpha = 0
                p.run(SKAction.sequence([
                    SKAction.wait(forDuration: Double(i) * 0.04),
                    SKAction.group([SKAction.fadeIn(withDuration: 0.08), SKAction.scale(to: 1.0, duration: 0.14)])
                ]))
            }
        }
        Sfx.shared.play("pop")
    }

    private func puckPoint(_ u: CGPoint) -> CGPoint {
        return CGPoint(x: areaCenter.x + (u.x - 0.5) * (areaSize.width - 2 * puckR),
                       y: areaCenter.y + (u.y - 0.5) * (areaSize.height - 2 * puckR))
    }

    private func beginAnswer() {
        step = .answer
        t = 5.0
        answerT = 0
        for s in seats {
            let st = states[s.index]
            st.status.text = "WIE VIELE?"
            for p in st.pucks { p.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.08)])) }
            for b in st.buttons {
                b.setScale(0.6)
                b.run(SKAction.group([SKAction.fadeAlpha(to: 1, duration: 0.1), SKAction.scale(to: 1, duration: 0.12)]))
            }
        }
        Sfx.shared.play("beep")
    }

    private func beginReveal() {
        step = .reveal
        t = 1.5
        let n = counts[round]
        let opts = options[round]
        let ci = opts.firstIndex(of: n) ?? 0
        let pos = unitPos[round]
        for s in seats {
            let st = states[s.index]
            st.buttons[ci].color = UIColor(red: 0.1, green: 0.8, blue: 0.3, alpha: 1)
            if !st.answered && !st.locked { st.status.text = "ZU LANGSAM" }
            st.big.text = "\(n)"
            st.big.setScale(1.5)
            st.big.alpha = 0
            st.big.run(SKAction.group([SKAction.fadeAlpha(to: 0.9, duration: 0.15), SKAction.scale(to: 1, duration: 0.15)]))
            for i in 0..<n {
                let p = st.pucks[i]
                p.position = puckPoint(pos[i])
                p.removeAllActions()
                p.setScale(1)
                p.run(SKAction.fadeAlpha(to: 0.3, duration: 0.15))
            }
        }
    }

    override func gameUpdate(_ dt: Double) {
        switch step {
        case .intro:
            t -= dt
            if t <= 0 { beginShow() }
        case .show:
            t -= dt
            if t <= 0 { beginAnswer() }
        case .answer:
            t -= dt
            answerT += dt
            for s in seats where s.isCPU {
                let st = states[s.index]
                if !st.answered && !st.locked && answerT >= st.cpuAt { pick(s, st.cpuPick) }
            }
            if t <= 0 || seats.allSatisfy({ states[$0.index].answered || states[$0.index].locked }) { beginReveal() }
        case .reveal:
            t -= dt
            if t <= 0 && phase == .playing {
                round += 1
                if round >= rounds { finishGame() } else { startRound() }
            }
        }
    }

    private func pick(_ s: Seat, _ idx: Int) {
        let st = states[s.index]
        if step != .answer || st.answered || st.locked { return }
        let b = st.buttons[idx]
        if options[round][idx] == counts[round] {
            st.answered = true
            order += 1
            let pts = order == 1 ? 3 : 1
            addScore(s, pts)
            addStat("quiz", 1, seat: s)
            b.color = UIColor(red: 0.1, green: 0.8, blue: 0.3, alpha: 1)
            b.run(SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.07), SKAction.scale(to: 1, duration: 0.1)]))
            st.status.text = order == 1 ? "SCHNELLSTER!" : "RICHTIG!"
            s.floatText("+\(pts)", at: CGPoint(x: b.position.x, y: btnY + 40), color: pts == 3 ? .yellow : .white, size: pts == 3 ? 30 : 24)
            s.burst(at: b.position, color: pts == 3 ? .yellow : s.color, count: pts == 3 ? 16 : 7, speed: 80)
            if !s.isCPU { Sfx.shared.play(pts == 3 ? "coin" : "right"); Haptic.good() }
        } else {
            st.locked = true
            b.color = UIColor(red: 0.85, green: 0.12, blue: 0.18, alpha: 1)
            b.alpha = 0.7
            st.status.text = "FALSCH – GESPERRT"
            s.shake(4)
            if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if step != .answer { return }
        if at.y > btnY + 44 { return }
        let st = states[seat.index]
        var best = 0
        var bd = CGFloat.greatestFiniteMagnitude
        for (i, b) in st.buttons.enumerated() {
            let d = abs(b.position.x - at.x)
            if d < bd { bd = d; best = i }
        }
        pick(seat, best)
    }
}
