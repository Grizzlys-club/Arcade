import SpriteKit

/// Bären-Memory – find the pairs. Everyone plays the same layout at the same time.
final class MemoryGame: MiniScene {

    private static let icons = ["🐻", "🏒", "🥅", "🏆", "🧤", "LOGO"]

    private final class Card {
        let node: SKSpriteNode
        let front: SKNode
        let back: SKNode
        let pair: Int
        var open = false
        var matched = false
        init(node: SKSpriteNode, front: SKNode, back: SKNode, pair: Int) {
            self.node = node
            self.front = front
            self.back = back
            self.pair = pair
        }
    }

    private final class SeatState {
        var cards: [Card] = []
        var first: Int? = nil
        var pendingSecond: Int? = nil
        var busy: Double = 0
        var pairs = 0
        var finished = false
        var cpuTimer: Double = 0
        var memory: [Int: Int] = [:]   // card index -> pair (cards the CPU has seen)
    }

    private var states: [SeatState] = []
    private var finishOrder: [Int] = []
    private var cardSize = CGSize(width: 50, height: 60)

    override func setupGame() {
        duration = 60
        let r = newRand()
        let layout = r.shuffled([0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5])
        guard let s0 = seats.first else { return }
        let wide = s0.w > s0.h * 0.8
        let cols = wide ? 4 : 3
        let rows = 12 / cols
        let gap: CGFloat = 8
        let top = s0.h / 2 - 36
        let bottom = -s0.h / 2 + 12
        let maxW = (s0.w - 24 - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let maxH = (top - bottom - gap * CGFloat(rows - 1)) / CGFloat(rows)
        var cw = maxW
        var ch = cw * 1.25
        if ch > maxH { ch = maxH; cw = ch / 1.25 }
        cardSize = CGSize(width: cw, height: ch)
        let gridW = cw * CGFloat(cols) + gap * CGFloat(cols - 1)
        let gridH = ch * CGFloat(rows) + gap * CGFloat(rows - 1)
        let cy = (top + bottom) / 2
        for s in seats {
            let st = SeatState()
            for i in 0..<12 {
                let col = CGFloat(i % cols)
                let row = CGFloat(i / cols)
                let x = -gridW / 2 + cw / 2 + col * (cw + gap)
                let y = cy + gridH / 2 - ch / 2 - row * (ch + gap)
                let node = SKSpriteNode(texture: Gfx.pill(cw, ch, fill: UIColor(white: 1, alpha: 0.001), border: nil, corner: 10), size: cardSize)
                node.position = CGPoint(x: x, y: y)
                node.zPosition = 5
                s.field.addChild(node)

                let back = SKNode()
                let bs = SKSpriteNode(texture: Gfx.pill(cw, ch, fill: s.color.withAlphaComponent(0.55), border: UIColor(white: 1, alpha: 0.5), corner: 10), size: cardSize)
                back.addChild(bs)
                let logo = SKSpriteNode(imageNamed: "logo")
                let ls = min(cw, ch) * 0.62
                logo.size = CGSize(width: ls, height: ls)
                logo.alpha = 0.55
                logo.zPosition = 1
                back.addChild(logo)
                node.addChild(back)

                let front = SKNode()
                let fs = SKSpriteNode(texture: Gfx.pill(cw, ch, fill: UIColor(white: 0.95, alpha: 1), border: s.color, corner: 10), size: cardSize)
                front.addChild(fs)
                let pair = layout[i]
                let icon = MemoryGame.icons[pair]
                if icon == "LOGO" {
                    let l = SKSpriteNode(imageNamed: "logo")
                    l.size = CGSize(width: ls * 1.1, height: ls * 1.1)
                    l.zPosition = 1
                    front.addChild(l)
                } else {
                    let l = SKLabelNode(text: icon)
                    l.fontSize = min(cw, ch) * 0.55
                    l.verticalAlignmentMode = .center
                    l.zPosition = 1
                    front.addChild(l)
                }
                front.isHidden = true
                node.addChild(front)
                st.cards.append(Card(node: node, front: front, back: back, pair: pair))
            }
            states.append(st)
        }
    }

    override func gameStarted() {
        for s in seats where s.isCPU {
            states[s.index].cpuTimer = 0.8 + Double.random(in: 0...0.4)
        }
    }

    private func flip(_ card: Card, open: Bool) {
        card.open = open
        card.node.removeAction(forKey: "flip")
        card.node.run(SKAction.sequence([
            SKAction.scaleX(to: 0, duration: 0.09),
            SKAction.run {
                card.front.isHidden = !open
                card.back.isHidden = open
            },
            SKAction.scaleX(to: 1, duration: 0.09)
        ]), withKey: "flip")
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats {
            let st = states[s.index]
            if st.busy > 0 {
                st.busy -= dt
                if st.busy <= 0 { closeMismatch(s) }
                continue
            }
            if s.isCPU && !st.finished {
                st.cpuTimer -= dt
                if st.cpuTimer <= 0 {
                    st.cpuTimer = 0.55 + (1 - s.skill) * 0.6 + Double.random(in: 0...0.25)
                    cpuMove(s)
                }
            }
        }
        if seats.allSatisfy({ states[$0.index].finished }) && phase == .playing {
            finishGame()
        }
    }

    private func cpuMove(_ s: Seat) {
        let st = states[s.index]
        let hidden = st.cards.indices.filter { !st.cards[$0].matched && !st.cards[$0].open }
        if hidden.isEmpty { return }
        let remember = 0.45 + s.skill * 0.5
        if let f = st.first {
            let pair = st.cards[f].pair
            if let known = st.memory.first(where: { $0.value == pair && $0.key != f && hidden.contains($0.key) })?.key,
               Double.random(in: 0..<1) < remember {
                pick(s, known)
            } else {
                let unknown = hidden.filter { st.memory[$0] == nil }
                pick(s, (unknown.isEmpty ? hidden : unknown).randomElement()!)
            }
        } else {
            // known pair?
            var pairPick: Int? = nil
            for (i, p) in st.memory where hidden.contains(i) {
                if st.memory.contains(where: { $0.key != i && $0.value == p && hidden.contains($0.key) }) {
                    pairPick = i
                    break
                }
            }
            if let pp = pairPick, Double.random(in: 0..<1) < remember {
                pick(s, pp)
            } else {
                let unknown = hidden.filter { st.memory[$0] == nil }
                pick(s, (unknown.isEmpty ? hidden : unknown).randomElement()!)
            }
        }
    }

    private func pick(_ s: Seat, _ i: Int) {
        let st = states[s.index]
        if st.finished || st.busy > 0 { return }
        let card = st.cards[i]
        if card.open || card.matched { return }
        flip(card, open: true)
        st.memory[i] = card.pair
        if !s.isCPU { Sfx.shared.play("tap"); Haptic.tap() }
        if let f = st.first {
            let other = st.cards[f]
            st.first = nil
            if other.pair == card.pair {
                other.matched = true
                card.matched = true
                st.memory[f] = nil
                st.memory[i] = nil
                st.pairs += 1
                addScore(s, 10)
                addStat("hits", 1, seat: s)
                for c in [other, card] {
                    c.node.run(SKAction.sequence([SKAction.wait(forDuration: 0.18), SKAction.scale(to: 1.15, duration: 0.08), SKAction.scale(to: 1.0, duration: 0.1), SKAction.fadeAlpha(to: 0.55, duration: 0.2)]))
                    s.burst(at: c.node.position, color: s.color, count: 8, speed: 70)
                }
                if !s.isCPU { Sfx.shared.play("right"); Haptic.good() }
                if st.pairs >= 6 {
                    st.finished = true
                    finishOrder.append(s.index)
                    let place = finishOrder.count
                    let bonus = [30, 20, 10, 0][min(3, place - 1)]
                    addScore(s, bonus)
                    s.banner(place == 1 ? "ERSTER!" : "\(place). PLATZ", color: place == 1 ? .yellow : s.color, size: 36, duration: 1.2)
                    if bonus > 0 { s.floatText("+\(bonus) BONUS", at: CGPoint(x: 0, y: -50), color: .yellow, size: 22) }
                    if !s.isCPU { Sfx.shared.play("fanfare") }
                }
            } else {
                st.busy = 0.75
                st.first = f
                st.pendingSecond = i
            }
        } else {
            st.first = i
        }
    }

    private func closeMismatch(_ s: Seat) {
        let st = states[s.index]
        if let f = st.first, let p = st.pendingSecond {
            flip(st.cards[f], open: false)
            flip(st.cards[p], open: false)
            if !s.isCPU { Sfx.shared.play("miss") }
        }
        st.first = nil
        st.pendingSecond = nil
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        for (i, c) in st.cards.enumerated() where c.node.frame.insetBy(dx: -3, dy: -3).contains(at) {
            pick(seat, i)
            return
        }
    }
}
