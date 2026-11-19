import SpriteKit

/// Schläger-Duell: rock-paper-scissors for 2–4 players. Schläger > Ball > Handschuh > Schläger.
final class DuelGame: MiniScene {
    private let icons = ["🏒", "⚪️", "🧤"]
    private let names = ["SCHLÄGER", "BALL", "HANDSCHUH"]
    private let totalRounds = 7
    private let chooseTime: Double = 3.0
    private let revealTime: Double = 2.4

    private enum Step { case choose, reveal, done }
    private var step: Step = .done
    private var stepTime: Double = 0
    private var round = 0
    private var picks: [Int] = []
    private var cpuPickAt: [Double] = []
    private var lastPicks: [Int] = []
    private var buttons: [[SKSpriteNode]] = []
    private var timerLabels: [SKLabelNode] = []
    private var roundLabels: [SKLabelNode] = []
    private var revealNodes: [SKNode] = []
    private var cpuBias: [[Double]] = []

    override func setupGame() {
        picks = Array(repeating: -1, count: n)
        lastPicks = picks
        cpuPickAt = Array(repeating: 1, count: n)
        cpuBias = seats.map { _ in [Double.random(in: 0.8...1.4), Double.random(in: 0.8...1.4), Double.random(in: 0.8...1.4)] }
        for s in seats {
            var row: [SKSpriteNode] = []
            let wide = s.w > 250
            let top: CGFloat = 40
            let area = CGRect(x: -s.w / 2 + 12, y: -s.h / 2 + 12, width: s.w - 24, height: s.h - top - 60)
            for k in 0..<3 {
                let bw: CGFloat, bh: CGFloat
                let pos: CGPoint
                if wide {
                    bw = (area.width - 20) / 3
                    bh = min(140, area.height * 0.7)
                    pos = CGPoint(x: area.minX + bw / 2 + CGFloat(k) * (bw + 10), y: area.minY + area.height / 2)
                } else {
                    bw = area.width
                    bh = min(84, (area.height - 20) / 3)
                    pos = CGPoint(x: area.midX, y: area.maxY - bh / 2 - CGFloat(k) * (bh + 10))
                }
                let b = SKSpriteNode(texture: Gfx.pill(bw, bh, fill: s.color.withAlphaComponent(0.22), border: s.color.withAlphaComponent(0.8), corner: 16), size: CGSize(width: bw, height: bh))
                b.position = pos
                b.zPosition = 10
                let icon = MiniScene.label(icons[k], size: min(bh * 0.45, 46))
                icon.position = CGPoint(x: 0, y: wide ? bh * 0.1 : 0)
                if !wide { icon.position = CGPoint(x: -bw / 2 + bh * 0.45, y: 0) }
                icon.zPosition = 1
                b.addChild(icon)
                let t = MiniScene.label(names[k], size: min(15, bw * 0.12), color: .white)
                t.position = wide ? CGPoint(x: 0, y: -bh * 0.3) : CGPoint(x: bh * 0.3, y: 0)
                t.zPosition = 1
                b.addChild(t)
                s.field.addChild(b)
                row.append(b)
            }
            buttons.append(row)
            let tl = MiniScene.label("", size: 26, color: .white)
            tl.position = CGPoint(x: 0, y: s.h / 2 - 54)
            tl.zPosition = 20
            s.field.addChild(tl)
            timerLabels.append(tl)
            let rl = MiniScene.label("", size: 12, color: UIColor(white: 1, alpha: 0.6))
            rl.position = CGPoint(x: 0, y: s.h / 2 - 32)
            rl.horizontalAlignmentMode = .center
            rl.zPosition = 20
            s.node.addChild(rl)
            roundLabels.append(rl)
            let rn = SKNode()
            rn.zPosition = 60
            s.node.addChild(rn)
            revealNodes.append(rn)
        }
    }

    override func gameStarted() {
        startRound()
    }

    private func startRound() {
        round += 1
        step = .choose
        stepTime = 0
        picks = Array(repeating: -1, count: n)
        for s in seats {
            roundLabels[s.index].text = "RUNDE \(round)/\(totalRounds)"
            revealNodes[s.index].removeAllChildren()
            for b in buttons[s.index] {
                b.alpha = 1
                b.setScale(1)
                b.colorBlendFactor = 0
            }
            cpuPickAt[s.index] = Double.random(in: 0.5...2.6)
        }
        Sfx.shared.play("beep")
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        guard step == .choose else { return }
        for (k, b) in buttons[seat.index].enumerated() {
            let f = b.frame
            if f.insetBy(dx: -4, dy: -4).contains(at) {
                choose(seat, k)
                return
            }
        }
    }

    private func choose(_ s: Seat, _ k: Int) {
        picks[s.index] = k
        if !s.isCPU {
            Sfx.shared.play("click")
            Haptic.tap()
            for (j, b) in buttons[s.index].enumerated() {
                b.alpha = j == k ? 1 : 0.35
                b.setScale(j == k ? 1.06 : 0.94)
            }
        } else {
            // CPU picks stay hidden – just dim the buttons
            for b in buttons[s.index] { b.alpha = 0.35 }
        }
    }

    private func cpuChoice(_ s: Seat) -> Int {
        // smart: counter what the others picked most last round (with probability by skill)
        if round > 1 && Double.random(in: 0...1) < s.skill * 0.6 {
            var counts = [0, 0, 0]
            for (i, p) in lastPicks.enumerated() where i != s.index && p >= 0 { counts[p] += 1 }
            if let mostPicked = counts.indices.max(by: { counts[$0] < counts[$1] }), counts[mostPicked] > 0 {
                // the choice that beats mostPicked: x beats y if y == (x+1)%3 -> x = (y+2)%3
                return (mostPicked + 2) % 3
            }
        }
        let w = cpuBias[s.index]
        let r = Double.random(in: 0..<(w[0] + w[1] + w[2]))
        if r < w[0] { return 0 }
        if r < w[0] + w[1] { return 1 }
        return 2
    }

    private func beats(_ a: Int, _ b: Int) -> Bool {
        if a < 0 { return false }
        if b < 0 { return true }
        return b == (a + 1) % 3
    }

    override func gameUpdate(_ dt: Double) {
        stepTime += dt
        switch step {
        case .choose:
            for s in seats where s.isCPU && picks[s.index] < 0 && stepTime >= cpuPickAt[s.index] {
                choose(s, cpuChoice(s))
            }
            let left = max(0, chooseTime - stepTime)
            let txt = "\(Int(ceil(left)))"
            for l in timerLabels where l.text != txt {
                l.text = txt
                l.setScale(1.3)
                l.run(SKAction.scale(to: 1, duration: 0.15))
            }
            let allPicked = !picks.contains(-1)
            if stepTime >= chooseTime || (allPicked && stepTime > 1.0) { reveal() }
        case .reveal:
            if stepTime >= revealTime {
                if round >= totalRounds {
                    step = .done
                    finishGame()
                } else {
                    startRound()
                }
            }
        case .done:
            break
        }
    }

    private func reveal() {
        step = .reveal
        stepTime = 0
        for l in timerLabels { l.text = "" }
        var gained = Array(repeating: 0, count: n)
        for i in 0..<n {
            for j in 0..<n where i != j {
                if beats(picks[i], picks[j]) { gained[i] += 1 }
            }
        }
        Sfx.shared.play("whistle")
        for s in seats {
            for b in buttons[s.index] { b.alpha = 0.12 }
            let rn = revealNodes[s.index]
            rn.removeAllChildren()
            // cards of all players
            let cw = min(80, (s.w - 20) / CGFloat(n) - 6)
            let total = CGFloat(n) * (cw + 6) - 6
            for (k, o) in seats.enumerated() {
                let card = SKSpriteNode(texture: Gfx.pill(cw, cw * 1.25, fill: o.color.withAlphaComponent(0.85), border: .white, corner: 12), size: CGSize(width: cw, height: cw * 1.25))
                card.position = CGPoint(x: -total / 2 + cw / 2 + CGFloat(k) * (cw + 6), y: 10)
                let icon = MiniScene.label(picks[k] >= 0 ? icons[picks[k]] : "❓", size: cw * 0.45)
                icon.position = CGPoint(x: 0, y: cw * 0.08)
                card.addChild(icon)
                let nm = MiniScene.label(o.index == s.index ? "DU" : String(o.name.prefix(6)).uppercased(), size: min(11, cw * 0.15), color: .black)
                nm.position = CGPoint(x: 0, y: -cw * 0.42)
                card.addChild(nm)
                card.xScale = 0.01
                rn.addChild(card)
                card.run(SKAction.sequence([SKAction.wait(forDuration: Double(k) * 0.08), SKAction.scaleX(to: 1, duration: 0.18)]))
                if o.index == s.index {
                    let ring = SKSpriteNode(texture: Gfx.pill(cw + 8, cw * 1.25 + 8, fill: .clear, border: .yellow, corner: 14), size: CGSize(width: cw + 8, height: cw * 1.25 + 8))
                    ring.position = card.position
                    ring.zPosition = -1
                    rn.addChild(ring)
                }
            }
            let g = gained[s.index]
            let res = MiniScene.label(g > 0 ? "+\(g)" : (picks[s.index] < 0 ? "ZU LANGSAM" : "0"), size: g > 0 ? 34 : 20, color: g > 0 ? .yellow : UIColor(white: 1, alpha: 0.7))
            res.position = CGPoint(x: 0, y: -cw * 0.8 - 14)
            res.setScale(0.2)
            rn.addChild(res)
            res.run(SKAction.sequence([SKAction.wait(forDuration: 0.4), SKAction.scale(to: 1, duration: 0.15)]))
            if g > 0 {
                addScore(s, g)
                if !s.isCPU { Haptic.good() }
            }
        }
        if gained.contains(where: { $0 > 0 }) { Sfx.shared.play("right") } else { Sfx.shared.play("miss") }
        lastPicks = picks
    }
}
