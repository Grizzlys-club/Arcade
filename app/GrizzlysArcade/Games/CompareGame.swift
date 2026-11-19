import SpriteKit

/// Grösser oder kleiner – tap the larger value before the bar runs out. 30 seconds.
final class CompareGame: MiniScene {

    private final class SeatState {
        var rand: Rand!
        var count = 0
        var vals = (0, 0)
        var btns: [SKSpriteNode] = []
        var labels: [SKLabelNode] = []
        var bar: SKSpriteNode!
        var barW: CGFloat = 100
        var timeLeft: Double = 3
        var timeMax: Double = 3
        var streak = 0
        var lock: Double = 0
        var cpuTimer: Double = 0
        var streakLabel: SKLabelNode!
        var active = false
    }

    private var states: [SeatState] = []
    private static let cols: [UIColor] = [UIColor(red: 0.1, green: 0.6, blue: 0.95, alpha: 1), UIColor(red: 0.85, green: 0.2, blue: 0.7, alpha: 1)]

    override func setupGame() {
        duration = 30
        for s in seats {
            let st = SeatState()
            st.rand = newRand()
            let top = s.h / 2 - 40
            let bottom = -s.h / 2 + 12
            let barH: CGFloat = 10
            st.barW = s.w - 28
            let bg = SKSpriteNode(color: UIColor(white: 1, alpha: 0.12), size: CGSize(width: st.barW, height: barH))
            bg.position = CGPoint(x: 0, y: top - 8)
            bg.zPosition = 2
            s.field.addChild(bg)
            let bar = SKSpriteNode(color: Theme.uiGreen, size: CGSize(width: st.barW, height: barH))
            bar.anchorPoint = CGPoint(x: 0, y: 0.5)
            bar.position = CGPoint(x: -st.barW / 2, y: top - 8)
            bar.zPosition = 3
            s.field.addChild(bar)
            st.bar = bar

            let areaTop = top - 28, areaBot = bottom + 22
            let vertical = s.w < 300          // quarters: stack buttons vertically? keep side by side only in halves
            let bw = vertical ? s.w - 28 : (s.w - 40) / 2
            let bh = vertical ? (areaTop - areaBot - 10) / 2 : min(areaTop - areaBot, bw * 1.1)
            for i in 0..<2 {
                let b = MiniScene.button("", w: bw, h: bh, color: CompareGame.cols[i], fontSize: 20)
                if vertical { b.position = CGPoint(x: 0, y: areaTop - bh / 2 - CGFloat(i) * (bh + 10)) }
                else { b.position = CGPoint(x: (i == 0 ? -1 : 1) * (bw / 2 + 6), y: (areaTop + areaBot) / 2) }
                b.zPosition = 4
                s.field.addChild(b)
                let l = label("", size: min(44, bw * 0.3, bh * 0.5), color: .white)
                l.verticalAlignmentMode = .center
                l.position = b.position
                l.zPosition = 6
                s.field.addChild(l)
                st.btns.append(b)
                st.labels.append(l)
            }
            let sl = label("", size: 13, color: .yellow)
            sl.position = CGPoint(x: 0, y: bottom + 8)
            sl.zPosition = 6
            s.field.addChild(sl)
            st.streakLabel = sl

            let hint = label("TIPPE DIE GRÖSSERE ZAHL", size: min(15, s.w * 0.07), color: .white)
            hint.position = CGPoint(x: 0, y: (areaTop + areaBot) / 2 + (vertical ? 0 : bh / 2 + 6))
            hint.zPosition = 8
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 3.4), SKAction.fadeOut(withDuration: 0.5)]))
            if !vertical { hint.position.y = areaTop - 4 }
            s.field.addChild(hint)
            states.append(st)
        }
    }

    override func gameStarted() { for s in seats { nextQuestion(s) } }

    /// text for a value; harder levels use expressions
    private func text(for v: Int, expr: Bool, _ r: Rand) -> String {
        guard expr else { return "\(v)" }
        let divs = (2...9).filter { v % $0 == 0 && v / $0 >= 2 }
        if !divs.isEmpty && r.chance(0.6) { let d = r.pick(divs); return "\(d)×\(v / d)" }
        let x = r.int(1, max(1, v - 1))
        return "\(x)+\(v - x)"
    }

    private func nextQuestion(_ s: Seat) {
        let st = states[s.index]
        let r = st.rand!
        let lvl = st.count
        let maxV = min(20 + lvl * 6, 99)
        let gap = max(1, 9 - lvl)
        let a = r.int(10, maxV)
        var b = a + (r.chance(0.5) ? 1 : -1) * r.int(1, gap + (lvl < 3 ? 6 : 0))
        if b == a { b = a + 1 }
        let exprChance = lvl < 5 ? 0.0 : min(0.8, 0.3 + Double(lvl - 5) * 0.08)
        let ea = r.chance(exprChance), eb = r.chance(exprChance)
        let swap = r.chance(0.5)
        let pair = swap ? (b, a) : (a, b)
        st.vals = pair
        let ta = text(for: pair.0, expr: ea, r), tb = text(for: pair.1, expr: eb, r)
        st.labels[0].text = ta
        st.labels[1].text = tb
        for i in 0..<2 {
            st.btns[i].setScale(0.85)
            st.btns[i].run(SKAction.scale(to: 1, duration: 0.1))
            st.labels[i].setScale(0.85)
            st.labels[i].run(SKAction.scale(to: 1, duration: 0.1))
        }
        st.timeMax = max(1.5, 3.4 - Double(lvl) * 0.1)
        st.timeLeft = st.timeMax
        st.active = true
        if s.isCPU { st.cpuTimer = 0.6 + (1 - s.skill) * 1.3 + Double(lvl) * 0.03 + Double.random(in: 0...0.3) }
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats {
            let st = states[s.index]
            guard st.active else { continue }
            if st.lock > 0 { st.lock -= dt; continue }
            st.timeLeft -= dt
            let f = max(0, CGFloat(st.timeLeft / st.timeMax))
            st.bar.size.width = st.barW * f
            st.bar.color = f > 0.5 ? Theme.uiGreen : (f > 0.25 ? .yellow : .red)
            if st.timeLeft <= 0 { miss(s, timeout: true); continue }
            if s.isCPU {
                st.cpuTimer -= dt
                if st.cpuTimer <= 0 {
                    let right = st.vals.0 > st.vals.1 ? 0 : 1
                    let ok = Double.random(in: 0..<1) < 0.6 + s.skill * 0.36
                    choose(s, ok ? right : 1 - right)
                }
            }
        }
    }

    private func miss(_ s: Seat, timeout: Bool) {
        let st = states[s.index]
        st.streak = 0
        st.streakLabel.text = ""
        st.active = false
        st.count += 1
        setScore(s, max(0, s.score - 1))
        s.shake(4)
        s.flash(.red, alpha: 0.35)
        s.floatText(timeout ? "ZU LANGSAM −1" : "−1", at: CGPoint(x: 0, y: 0), color: .red, size: 22)
        if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
        let right = st.vals.0 > st.vals.1 ? 0 : 1
        st.btns[right].run(SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.1), SKAction.scale(to: 1, duration: 0.1)]))
        run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.run { [weak self] in
            guard let self = self, self.phase == .playing else { return }
            self.nextQuestion(s)
        }]))
        st.lock = 0.5
    }

    private func choose(_ s: Seat, _ i: Int) {
        let st = states[s.index]
        guard st.active, st.lock <= 0 else { return }
        let right = st.vals.0 > st.vals.1 ? 0 : 1
        if i == right {
            st.streak += 1
            let pts = st.streak > 0 && st.streak % 4 == 0 ? 2 : 1
            addScore(s, pts)
            addStat("hits", 1, seat: s)
            st.count += 1
            st.active = false
            s.burst(at: st.btns[i].position, color: .white, count: 8, speed: 140)
            s.floatText(pts > 1 ? "+2 SERIE!" : "+1", at: CGPoint(x: st.btns[i].position.x, y: st.btns[i].position.y + 36), color: pts > 1 ? .yellow : Theme.uiGreen, size: pts > 1 ? 24 : 20)
            st.streakLabel.text = st.streak >= 3 ? "🔥 \(st.streak)er Serie" : ""
            if !s.isCPU { Sfx.shared.play(pts > 1 ? "coin" : "right"); Haptic.tap() }
            nextQuestion(s)
        } else {
            miss(s, timeout: false)
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        for i in 0..<2 where st.btns[i].frame.insetBy(dx: -4, dy: -6).contains(at) { choose(seat, i); return }
    }
}
