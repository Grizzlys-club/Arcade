import SpriteKit

/// Farben-Falle – does the ink colour match the word? JA / NEIN. 30 seconds.
final class ColorsGame: MiniScene {

    private static let words = ["ROT", "BLAU", "GRÜN", "GELB", "ORANGE"]
    private static let inks: [UIColor] = [
        UIColor(red: 1.0, green: 0.2, blue: 0.22, alpha: 1),
        UIColor(red: 0.25, green: 0.5, blue: 1.0, alpha: 1),
        UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1),
        UIColor(red: 1.0, green: 0.92, blue: 0.15, alpha: 1),
        UIColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 1)
    ]

    private struct Item {
        let word: Int
        let ink: Int
        var match: Bool { return word == ink }
    }

    private final class SeatState {
        var rand: Rand!
        var item: Item!
        var word: SKLabelNode!
        var card: SKSpriteNode!
        var yes: SKSpriteNode!
        var no: SKSpriteNode!
        var streakLabel: SKLabelNode!
        var streak = 0
        var lock: Double = 0
        var cpuTimer: Double = 0
    }

    private var states: [SeatState] = []

    override func setupGame() {
        duration = 30
        for s in seats {
            let st = SeatState()
            st.rand = newRand()
            let top = s.h / 2 - 36
            let bottom = -s.h / 2 + 10
            let bh = min(70, (top - bottom) * 0.22)
            let bw = (s.w - 36) / 2
            let by = bottom + bh / 2 + 4

            let q = label("Passt die Farbe?", size: min(17, s.w * 0.08), color: UIColor(white: 1, alpha: 0.8))
            q.position = CGPoint(x: 0, y: top - 14)
            q.zPosition = 5
            s.field.addChild(q)

            let cardTop = top - 32
            let cardBottom = by + bh / 2 + 14
            let ch = cardTop - cardBottom
            let cw = s.w - 28
            let card = SKSpriteNode(texture: Gfx.pill(cw, ch, fill: UIColor(white: 0.06, alpha: 0.9), border: UIColor(white: 1, alpha: 0.25), corner: 20), size: CGSize(width: cw, height: ch))
            card.position = CGPoint(x: 0, y: (cardTop + cardBottom) / 2)
            card.zPosition = 3
            s.field.addChild(card)
            st.card = card

            let word = label("", size: min(54, s.w * 0.17), color: .white)
            word.position = card.position
            word.zPosition = 6
            s.field.addChild(word)
            st.word = word

            let streak = label("", size: 13, color: UIColor.yellow)
            streak.position = CGPoint(x: 0, y: card.position.y - ch / 2 + 16)
            streak.zPosition = 6
            s.field.addChild(streak)
            st.streakLabel = streak

            let yes = MiniScene.button("JA ✓", w: bw, h: bh, color: UIColor(red: 0.1, green: 0.7, blue: 0.3, alpha: 1), fontSize: min(24, bw * 0.22))
            yes.position = CGPoint(x: -bw / 2 - 6, y: by)
            yes.zPosition = 5
            s.field.addChild(yes)
            st.yes = yes
            let no = MiniScene.button("NEIN ✕", w: bw, h: bh, color: UIColor(red: 0.8, green: 0.15, blue: 0.2, alpha: 1), fontSize: min(24, bw * 0.22))
            no.position = CGPoint(x: bw / 2 + 6, y: by)
            no.zPosition = 5
            s.field.addChild(no)
            st.no = no

            states.append(st)
            st.word.text = "BEREIT?"
        }
    }

    override func gameStarted() {
        for s in seats { nextItem(s) }
    }

    private func nextItem(_ s: Seat) {
        let st = states[s.index]
        let r = st.rand!
        let w = r.int(0, 4)
        var ink = w
        if !r.chance(0.5) {
            ink = (w + r.int(1, 4)) % 5
        }
        st.item = Item(word: w, ink: ink)
        st.word.text = ColorsGame.words[w]
        st.word.fontColor = ColorsGame.inks[ink]
        st.word.setScale(0.6)
        st.word.run(SKAction.scale(to: 1.0, duration: 0.1))
        if s.isCPU {
            st.cpuTimer = 0.6 + (1 - s.skill) * 0.9 + Double.random(in: 0...0.3)
        }
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats {
            let st = states[s.index]
            if st.lock > 0 { st.lock -= dt }
            if s.isCPU && st.item != nil && st.lock <= 0 {
                st.cpuTimer -= dt
                if st.cpuTimer <= 0 {
                    let correct = Double.random(in: 0..<1) < 0.7 + s.skill * 0.28
                    answer(s, yes: correct ? st.item.match : !st.item.match)
                }
            }
        }
    }

    private func answer(_ s: Seat, yes: Bool) {
        let st = states[s.index]
        guard let item = st.item, st.lock <= 0 else { return }
        let btn = yes ? st.yes! : st.no!
        btn.run(SKAction.sequence([SKAction.scale(to: 0.92, duration: 0.05), SKAction.scale(to: 1.0, duration: 0.08)]))
        if yes == item.match {
            st.streak += 1
            var pts = 1
            if st.streak % 5 == 0 { pts += 1 }
            addScore(s, pts)
            addStat("hits", 1, seat: s)
            st.card.run(SKAction.sequence([SKAction.colorize(with: UIColor.green, colorBlendFactor: 0.5, duration: 0.05), SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)]))
            s.floatText(pts > 1 ? "+2 SERIE!" : "+1", at: CGPoint(x: 0, y: st.word.position.y + 30), color: pts > 1 ? .yellow : Theme.uiGreen, size: pts > 1 ? 24 : 20)
            st.streakLabel.text = st.streak >= 3 ? "🔥 \(st.streak)er Serie" : ""
            if !s.isCPU { Sfx.shared.play(pts > 1 ? "coin" : "right"); Haptic.tap() }
            nextItem(s)
        } else {
            st.streak = 0
            st.streakLabel.text = ""
            setScore(s, max(0, s.score - 1))
            st.lock = 0.55
            s.flash(UIColor.red, alpha: 0.35)
            s.shake(4)
            s.floatText("−1", at: CGPoint(x: 0, y: st.word.position.y + 30), color: .red, size: 22)
            if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
            run(SKAction.sequence([SKAction.wait(forDuration: 0.45), SKAction.run { [weak self] in
                guard let self = self, self.phase == .playing else { return }
                self.nextItem(s)
            }]))
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        if st.yes.frame.insetBy(dx: -6, dy: -10).contains(at) {
            answer(seat, yes: true)
        } else if st.no.frame.insetBy(dx: -6, dy: -10).contains(at) {
            answer(seat, yes: false)
        }
    }
}
