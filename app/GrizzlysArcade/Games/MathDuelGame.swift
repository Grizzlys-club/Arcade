import SpriteKit

/// Kopfrechnen: same question for all, 4 answer buttons per seat.
final class MathDuelGame: MiniScene {
    private struct Q { var text: String; var answer: Int; var options: [Int] }

    private final class Panel {
        let seat: Seat
        var buttons: [SKSpriteNode] = []
        var labels: [SKLabelNode] = []
        var rects: [CGRect] = []
        var qLabel: SKLabelNode!
        var eqLabel: SKLabelNode!
        var bar: SKSpriteNode!
        var barW: CGFloat = 0
        var progress: SKLabelNode!
        var locked = false
        var done = false
        var cpuTime: Double = 0
        var cpuPick = 0
        init(_ s: Seat) { seat = s }
    }

    private enum State { case intro, ask, reveal }

    private var panels: [Panel] = []
    private var questions: [Q] = []
    private var qi = -1
    private var state: State = .intro
    private var timer: Double = 1.4
    private var qTime: Double = 7
    private var firstDone = false
    private var rnd = Rand(seed: 5)
    private let total = 10

    override func setupGame() {
        let r = newRand()
        for i in 0..<total { questions.append(makeQuestion(i, r)) }
        rnd = Rand(seed: UInt64.random(in: 1...1_000_000))
        for s in seats {
            let p = Panel(s)
            panels.append(p)
            build(p)
            let hint = MiniScene.label("ERSTER = 3 PUNKTE", size: min(20, s.w * 0.1), color: .white)
            hint.position = CGPoint(x: 0, y: s.h * 0.1)
            hint.zPosition = 450
            s.node.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.2), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
        }
    }

    private func makeQuestion(_ i: Int, _ r: Rand) -> Q {
        var text = "", ans = 0
        let kind = i < 3 ? r.int(0, 1) : (i < 6 ? r.int(0, 2) : r.int(1, 2))
        switch kind {
        case 0:
            let hi = i < 3 ? 9 : (i < 6 ? 29 : 49)
            let a = r.int(i < 3 ? 3 : 8, hi), b = r.int(3, i < 3 ? 9 : 19)
            text = "\(a) + \(b)"; ans = a + b
        case 1:
            let a = r.int(i < 3 ? 10 : 18, i < 3 ? 20 : 50), b = r.int(3, i < 3 ? 9 : 17)
            text = "\(a) − \(b)"; ans = a - b
        default:
            let a = r.int(i < 6 ? 3 : 6, i < 6 ? 7 : 12), b = r.int(i < 6 ? 3 : 6, i < 6 ? 9 : 12)
            text = "\(a) × \(b)"; ans = a * b
        }
        var opts = [ans]
        var tries = 0
        while opts.count < 4 && tries < 50 {
            tries += 1
            let d = r.int(1, 10) * (r.chance(0.5) ? 1 : -1)
            let c = ans + (kind == 2 && r.chance(0.5) ? (r.chance(0.5) ? 1 : -1) * r.int(1, 3) * (r.chance(0.5) ? 1 : (r.int(2, 9) > 5 ? 10 : 1)) : d)
            if c >= 0 && !opts.contains(c) { opts.append(c) }
        }
        var k = ans + 11
        while opts.count < 4 { if !opts.contains(k) { opts.append(k) }; k += 1 }
        return Q(text: text, answer: ans, options: r.shuffled(opts))
    }

    private func build(_ p: Panel) {
        let s = p.seat
        let gap: CGFloat = 8
        let bw = (s.w - 24 - gap) / 2
        let bh = min(92, s.h * 0.25)
        let y0 = -s.h / 2 + 12
        for i in 0..<4 {
            let col = i % 2, row = i / 2
            let cx = -((bw + gap) / 2) + CGFloat(col) * (bw + gap)
            let cy = y0 + bh / 2 + CGFloat(row) * (bh + gap)
            let b = SKSpriteNode(texture: Gfx.pill(bw, bh, fill: s.color.withAlphaComponent(0.28), border: s.color, corner: 18), size: CGSize(width: bw, height: bh))
            b.position = CGPoint(x: cx, y: cy)
            b.zPosition = 20
            s.node.addChild(b)
            let l = MiniScene.label("", size: min(42, bw * 0.42), color: .white)
            l.zPosition = 1
            b.addChild(l)
            p.buttons.append(b)
            p.labels.append(l)
            p.rects.append(CGRect(x: cx - bw / 2 - gap / 2, y: cy - bh / 2 - gap / 2, width: bw + gap, height: bh + gap))
            b.alpha = 0
        }
        let qy = y0 + 2 * bh + gap + (s.h / 2 - 50 - (y0 + 2 * bh + gap)) / 2 + 6
        p.qLabel = MiniScene.label("", size: 40, color: .white)
        p.qLabel.position = CGPoint(x: 0, y: qy + 8)
        p.qLabel.zPosition = 30
        s.node.addChild(p.qLabel)
        p.eqLabel = MiniScene.label("= ?", size: min(28, s.w * 0.14), color: s.color)
        p.eqLabel.position = CGPoint(x: 0, y: qy - 30)
        p.eqLabel.zPosition = 30
        s.node.addChild(p.eqLabel)
        p.qLabel.alpha = 0
        p.eqLabel.alpha = 0
        p.barW = s.w - 28
        let back = SKSpriteNode(color: UIColor(white: 1, alpha: 0.15), size: CGSize(width: p.barW, height: 7))
        back.position = CGPoint(x: 0, y: s.h / 2 - 36)
        back.zPosition = 30
        s.node.addChild(back)
        p.bar = SKSpriteNode(color: Theme.uiGreen, size: CGSize(width: p.barW, height: 7))
        p.bar.anchorPoint = CGPoint(x: 0, y: 0.5)
        p.bar.position = CGPoint(x: -p.barW / 2, y: s.h / 2 - 36)
        p.bar.zPosition = 31
        s.node.addChild(p.bar)
        p.progress = MiniScene.label("", size: 12, color: UIColor(white: 1, alpha: 0.6))
        p.progress.position = CGPoint(x: 0, y: s.h / 2 - 50)
        p.progress.zPosition = 30
        s.node.addChild(p.progress)
    }

    override func gameStarted() {
        state = .intro
        timer = 1.2
    }

    private func nextQuestion() {
        qi += 1
        if qi >= total {
            finishGame()
            state = .reveal
            timer = 99
            return
        }
        let q = questions[qi]
        qTime = max(5.5, 7.5 - Double(qi) * 0.2)
        timer = qTime
        firstDone = false
        state = .ask
        Sfx.shared.play("tick")
        for p in panels {
            let s = p.seat
            p.locked = false
            p.done = false
            p.progress.text = "\(qi + 1) / \(total)"
            p.qLabel.text = q.text
            let fit = (s.w - 20) / (CGFloat(q.text.count) * 0.64)
            p.qLabel.fontSize = min(52, fit)
            p.qLabel.removeAllActions()
            p.qLabel.alpha = 1
            p.qLabel.setScale(0.4)
            p.qLabel.run(SKAction.scale(to: 1, duration: 0.18))
            p.eqLabel.alpha = 1
            p.bar.size.width = p.barW
            p.bar.color = Theme.uiGreen
            for i in 0..<4 {
                p.labels[i].text = "\(q.options[i])"
                p.buttons[i].alpha = 1
                p.buttons[i].texture = Gfx.pill(p.buttons[i].size.width, p.buttons[i].size.height, fill: s.color.withAlphaComponent(0.28), border: s.color, corner: 18)
                p.buttons[i].setScale(0.8)
                p.buttons[i].run(SKAction.scale(to: 1, duration: 0.15))
                p.labels[i].fontColor = .white
            }
            if s.isCPU {
                let sk = s.skill
                p.cpuTime = (0.9 + 2.9 * (1 - sk) + Double(qi) * 0.05) * Double(rnd.range(0.7, 1.3))
                let mistake = rnd.chance((1 - sk) * 0.3 + 0.03)
                if mistake {
                    var w = rnd.int(0, 3)
                    while q.options[w] == q.answer { w = (w + 1) % 4 }
                    p.cpuPick = w
                } else {
                    p.cpuPick = q.options.firstIndex(of: q.answer) ?? 0
                }
                if rnd.chance(max(0, (0.5 - sk) * 0.15)) { p.cpuTime = 99 }
            }
        }
    }

    private func color(_ p: Panel, _ i: Int, _ c: UIColor) {
        let b = p.buttons[i]
        b.texture = Gfx.pill(b.size.width, b.size.height, fill: c.withAlphaComponent(0.55), border: c, corner: 18)
    }

    private func answer(_ p: Panel, _ i: Int) {
        if state != .ask || p.locked || p.done { return }
        let q = questions[qi]
        let s = p.seat
        let pos = p.buttons[i].position
        if q.options[i] == q.answer {
            p.done = true
            let pts = firstDone ? 1 : 3
            let first = !firstDone
            firstDone = true
            addScore(s, pts)
            color(p, i, Theme.uiGreen)
            p.buttons[i].run(SKAction.sequence([SKAction.scale(to: 1.12, duration: 0.07), SKAction.scale(to: 1, duration: 0.1)]))
            s.floatText("+\(pts)", at: CGPoint(x: pos.x, y: pos.y + 40), color: first ? UIColor.yellow : Theme.uiGreen, size: 30)
            s.burst(at: pos, color: Theme.uiGreen, count: first ? 18 : 8, speed: 140)
            Sfx.shared.play(first ? "right" : "coin")
            if !s.isCPU { Haptic.good() }
            addStat("quiz", 1, seat: s)
            if first && !s.isCPU { stats["reaction"] = min(stats["reaction"] ?? Int.max, Int((qTime - timer) * 1000)) }
            if first { s.flash(Theme.uiGreen, alpha: 0.25, duration: 0.3) }
        } else {
            p.locked = true
            color(p, i, UIColor.red)
            p.buttons[i].run(SKAction.sequence([SKAction.moveBy(x: 6, y: 0, duration: 0.04), SKAction.moveBy(x: -12, y: 0, duration: 0.06), SKAction.moveBy(x: 6, y: 0, duration: 0.04)]))
            for (j, b) in p.buttons.enumerated() where j != i { b.alpha = 0.4 }
            let lost = s.score > 0
            if lost { addScore(s, -1) }
            s.floatText(lost ? "-1" : "X", at: CGPoint(x: pos.x, y: pos.y + 40), color: UIColor.red, size: 26)
            s.shake(5)
            Sfx.shared.play("wrong")
            if !s.isCPU { Haptic.bad() }
        }
        if p.done { for (j, b) in p.buttons.enumerated() where j != i { b.alpha = 0.45 } }
        if panels.allSatisfy({ $0.done || $0.locked }) { startReveal() }
    }

    private func startReveal() {
        if state != .ask { return }
        state = .reveal
        timer = 1.0
        let q = questions[qi]
        for p in panels {
            if let k = q.options.firstIndex(of: q.answer), !p.done {
                color(p, k, Theme.uiGreen)
                p.buttons[k].alpha = 1
                p.buttons[k].run(SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.1), SKAction.scale(to: 1, duration: 0.1)]))
            }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        guard state == .ask else { return }
        let p = panels[seat.index]
        for (i, r) in p.rects.enumerated() where r.contains(at) {
            answer(p, i)
            return
        }
    }

    override func gameUpdate(_ dt: Double) {
        timer -= dt
        switch state {
        case .intro:
            if timer <= 0 { nextQuestion() }
        case .ask:
            let frac = max(0, timer / qTime)
            for p in panels {
                p.bar.size.width = p.barW * CGFloat(frac)
                p.bar.color = frac < 0.3 ? UIColor.red : (frac < 0.6 ? Theme.uiOrange : Theme.uiGreen)
                if p.seat.isCPU && !p.done && !p.locked && qTime - timer >= p.cpuTime {
                    answer(p, p.cpuPick)
                }
            }
            if state == .ask && timer <= 0 { startReveal() }
        case .reveal:
            if timer <= 0 && qi < total { nextQuestion() }
        }
    }
}
