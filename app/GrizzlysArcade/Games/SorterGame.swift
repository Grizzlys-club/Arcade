import SpriteKit

/// Farb-Sortierer: balls fall one by one; tap left half = orange basket, right half = blue basket.
final class SorterGame: MiniScene {
    fileprivate final class State {
        let seat: Seat
        let rand: Rand
        let bear: BearNode
        var baskets: [SKSpriteNode] = []
        var ball: SKNode?
        var color = 0
        var y: CGFloat = 0
        var age: Double = 0
        var wait: Double = 0.2
        var cpuDelay: Double = 0
        var cpuSide = 0
        var streak = 0
        init(seat: Seat, rand: Rand, bear: BearNode) { self.seat = seat; self.rand = rand; self.bear = bear }
    }

    private var states: [State] = []
    private let cols: [UIColor] = [Theme.uiOrange, UIColor(red: 0.2, green: 0.55, blue: 1, alpha: 1)]
    private let ballR: CGFloat = 14

    private func yStart(_ s: Seat) -> CGFloat { return s.h / 2 - 44 }
    private func yMouth(_ s: Seat) -> CGFloat { return -s.h / 2 + 66 }
    private func basketX(_ s: Seat, _ side: Int) -> CGFloat { return (side == 0 ? -1 : 1) * s.w * 0.27 }

    override func setupGame() {
        duration = 30
        for s in seats {
            let bear = makeBear(s, height: 36, faceRight: false)
            let st = State(seat: s, rand: newRand(), bear: bear)
            // centre divider
            let div = SKSpriteNode(color: UIColor(white: 1, alpha: 0.12), size: CGSize(width: 2, height: s.h - 60))
            div.position = CGPoint(x: 0, y: -4)
            div.zPosition = 1
            s.field.addChild(div)
            for side in 0..<2 {
                let bw = s.w * 0.36
                let b = SKSpriteNode(texture: Gfx.pill(bw, 40, fill: cols[side].withAlphaComponent(0.35), border: cols[side], corner: 10, gloss: false), size: CGSize(width: bw, height: 40))
                b.position = CGPoint(x: basketX(s, side), y: -s.h / 2 + 32)
                b.zPosition = 3
                let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: bw * 1.6, height: 70))
                g.color = cols[side]; g.colorBlendFactor = 1; g.blendMode = .add; g.alpha = 0.5
                g.zPosition = -1
                b.addChild(g)
                s.field.addChild(b)
                st.baskets.append(b)
                let arrow = label(side == 0 ? "◀" : "▶", size: 14, color: UIColor(white: 1, alpha: 0.8))
                arrow.position = CGPoint(x: 0, y: 0)
                arrow.zPosition = 1
                b.addChild(arrow)
            }
            bear.position = CGPoint(x: 0, y: -s.h / 2 + 8)
            bear.zPosition = 4
            s.field.addChild(bear)
            bear.startBob(amount: 3, duration: 0.3)
            let hint = label(s.isCPU ? "CPU" : "◀ ORANGE · BLAU ▶", size: s.w > 300 ? 17 : 12, color: UIColor(white: 1, alpha: 0.85))
            hint.position = CGPoint(x: 0, y: 0)
            hint.zPosition = 30
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 3.2 + 1.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            states.append(st)
        }
    }

    private var fallSpeed: CGFloat { return (120 + CGFloat(elapsed) * 8) * (seats.first.map { $0.h / 370 } ?? 1) }

    private func spawn(_ st: State) {
        let s = st.seat
        st.color = st.rand.chance(0.5) ? 1 : 0
        let n = SKNode()
        let tex = Gfx.circle(ballR, cols[st.color], ring: UIColor(white: 1, alpha: 0.9))
        n.addChild(SKSpriteNode(texture: tex, size: CGSize(width: ballR * 2, height: ballR * 2)))
        let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: ballR * 5, height: ballR * 5))
        g.color = cols[st.color]; g.colorBlendFactor = 1; g.blendMode = .add; g.alpha = 0.8
        g.zPosition = -1
        n.addChild(g)
        n.zPosition = 10
        st.y = yStart(s)
        n.position = CGPoint(x: 0, y: st.y)
        s.field.addChild(n)
        st.ball = n
        st.age = 0
        let fall = Double((yStart(s) - yMouth(s)) / fallSpeed)
        st.cpuDelay = (0.18 + (1 - s.skill) * 0.55 + Double.random(in: 0...0.12)) * min(1, fall / 0.9)
        st.cpuSide = Double.random(in: 0...1) < (1 - s.skill) * 0.28 ? 1 - st.color : st.color
    }

    private func decide(_ st: State, side: Int) {
        guard let ball = st.ball, st.seat.alive, phase == .playing else { return }
        let s = st.seat
        st.ball = nil
        st.wait = 0.15
        let ok = side == st.color
        let tgt = CGPoint(x: basketX(s, side), y: yMouth(s) - 8)
        ball.run(SKAction.sequence([SKAction.group([SKAction.move(to: tgt, duration: 0.1), SKAction.scale(to: 0.6, duration: 0.1)]), SKAction.removeFromParent()]))
        let b = st.baskets[side]
        b.run(SKAction.sequence([SKAction.scale(to: 1.12, duration: 0.05), SKAction.scale(to: 1, duration: 0.1)]))
        if ok {
            st.streak += 1
            addScore(s, 1)
            addStat("balls", 1, seat: s)
            s.floatText("+1", at: CGPoint(x: tgt.x, y: tgt.y + 30), color: cols[side], size: 20)
            s.burst(at: tgt, color: cols[side], count: 8, speed: 90)
            st.bear.squash()
            if st.streak % 5 == 0 { st.bear.celebrate(); s.floatText("\(st.streak)er SERIE!", at: CGPoint(x: 0, y: 20), color: .yellow, size: 16) }
            if !s.isCPU { Sfx.shared.play("pop"); Haptic.tap() }
        } else {
            st.streak = 0
            addScore(s, -1)
            s.floatText("-1", at: CGPoint(x: tgt.x, y: tgt.y + 30), color: .red, size: 22)
            s.flash(.red, alpha: 0.25, duration: 0.25)
            s.shake(3)
            if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
        }
    }

    private func miss(_ st: State) {
        guard let ball = st.ball else { return }
        let s = st.seat
        st.ball = nil
        st.wait = 0.25
        st.streak = 0
        ball.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))
        addScore(s, -1)
        s.floatText("ZU LANGSAM", at: CGPoint(x: 0, y: yMouth(s) + 20), color: .red, size: 14)
        if !s.isCPU { Sfx.shared.play("miss"); Haptic.bad() }
    }

    override func gameUpdate(_ dt: Double) {
        for st in states {
            if let ball = st.ball {
                st.age += dt
                st.y -= fallSpeed * CGFloat(dt)
                ball.position.y = st.y
                if st.seat.isCPU && st.age >= st.cpuDelay { decide(st, side: st.cpuSide) }
                else if st.y <= yMouth(st.seat) { miss(st) }
            } else {
                st.wait -= dt
                if st.wait <= 0 { spawn(st) }
            }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if let st = states.first(where: { $0.seat === seat }) { decide(st, side: at.x < 0 ? 0 : 1) }
    }
}
