import SpriteKit

/// Pfeil-Panik – swipe in the direction of the neon arrow. 30 seconds.
final class ArrowsGame: MiniScene {

    private static let colors: [UIColor] = [
        UIColor(red: 0.2, green: 0.95, blue: 1.0, alpha: 1),
        UIColor(red: 1.0, green: 0.3, blue: 0.75, alpha: 1),
        UIColor(red: 0.6, green: 1.0, blue: 0.25, alpha: 1),
        UIColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 1)
    ]
    /// 0 up, 1 right, 2 down, 3 left (seat-local)
    private static let angles: [CGFloat] = [0, -.pi / 2, .pi, .pi / 2]
    private static let vecs: [CGVector] = [CGVector(dx: 0, dy: 1), CGVector(dx: 1, dy: 0), CGVector(dx: 0, dy: -1), CGVector(dx: -1, dy: 0)]

    private final class SeatState {
        var rand: Rand!
        var dir = 0
        var arrow: SKNode!
        var arrowSize: CGFloat = 100
        var glow: SKSpriteNode!
        var streakLabel: SKLabelNode!
        var streak = 0
        var start: CGPoint?
        var touch: UITouch?
        var cpuTimer: Double = 0
        var hint: SKLabelNode?
    }

    private var states: [SeatState] = []

    private static func arrowTexture(_ size: CGFloat) -> SKTexture {
        return Gfx.texture("arrows_arrow_\(Int(size))", size: CGSize(width: size, height: size)) { ctx in
            let s = size
            ctx.setFillColor(UIColor.white.cgColor)
            let p = CGMutablePath()
            p.move(to: CGPoint(x: s * 0.5, y: s * 0.02))
            p.addLine(to: CGPoint(x: s * 0.96, y: s * 0.5))
            p.addLine(to: CGPoint(x: s * 0.68, y: s * 0.5))
            p.addLine(to: CGPoint(x: s * 0.68, y: s * 0.98))
            p.addLine(to: CGPoint(x: s * 0.32, y: s * 0.98))
            p.addLine(to: CGPoint(x: s * 0.32, y: s * 0.5))
            p.addLine(to: CGPoint(x: s * 0.04, y: s * 0.5))
            p.closeSubpath()
            ctx.addPath(p)
            ctx.fillPath()
        }
    }

    override func setupGame() {
        duration = 30
        for s in seats {
            let st = SeatState()
            st.rand = newRand()
            let sz = min(s.w - 50, (s.h - 100) * 0.9, 190)
            st.arrowSize = sz
            let cy = (s.h / 2 - 40 + (-s.h / 2 + 10)) / 2

            let ring = SKSpriteNode(texture: Gfx.pill(s.w - 24, s.h - 80, fill: UIColor(white: 0.05, alpha: 0.7), border: UIColor(white: 1, alpha: 0.2), corner: 22), size: CGSize(width: s.w - 24, height: s.h - 80))
            ring.position = CGPoint(x: 0, y: cy)
            ring.zPosition = 1
            s.field.addChild(ring)

            let node = SKNode()
            node.position = CGPoint(x: 0, y: cy)
            node.zPosition = 4
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: sz * 1.8, height: sz * 1.8))
            g.blendMode = .add
            g.alpha = 0.8
            node.addChild(g)
            st.glow = g
            let a = SKSpriteNode(texture: ArrowsGame.arrowTexture(sz), size: CGSize(width: sz, height: sz))
            a.name = "a"
            node.addChild(a)
            s.field.addChild(node)
            st.arrow = node

            let sl = label("", size: 14, color: .yellow)
            sl.position = CGPoint(x: 0, y: cy - (s.h - 80) / 2 + 14)
            sl.zPosition = 6
            s.field.addChild(sl)
            st.streakLabel = sl

            let hint = label("WISCHEN ↑ → ↓ ←", size: min(18, s.w * 0.075), color: .white)
            hint.position = CGPoint(x: 0, y: cy + (s.h - 80) / 2 - 20)
            hint.zPosition = 7
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 3.5), SKAction.fadeOut(withDuration: 0.5)]))
            st.hint = hint

            node.alpha = 0.3
            states.append(st)
        }
    }

    override func gameStarted() {
        for s in seats { nextArrow(s) }
    }

    private func nextArrow(_ s: Seat) {
        let st = states[s.index]
        var d = st.rand.int(0, 3)
        if d == st.dir && st.rand.chance(0.4) { d = (d + 1 + st.rand.int(0, 2)) % 4 }
        st.dir = d
        let col = ArrowsGame.colors[st.rand.int(0, 3)]
        st.arrow.alpha = 1
        st.arrow.zRotation = ArrowsGame.angles[d]
        if let a = st.arrow.childNode(withName: "a") as? SKSpriteNode {
            a.color = col
            a.colorBlendFactor = 1
        }
        st.glow.color = col
        st.glow.colorBlendFactor = 1
        st.arrow.setScale(0.8)
        st.arrow.run(SKAction.scale(to: 1, duration: 0.08))
        if s.isCPU { st.cpuTimer = 0.35 + (1 - s.skill) * 0.7 + Double.random(in: 0...0.15) }
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats where s.isCPU {
            let st = states[s.index]
            st.cpuTimer -= dt
            if st.cpuTimer <= 0 {
                let ok = Double.random(in: 0..<1) < 0.62 + s.skill * 0.34
                answer(s, dir: ok ? st.dir : (st.dir + Int.random(in: 1...3)) % 4)
            }
        }
    }

    private func answer(_ s: Seat, dir: Int) {
        let st = states[s.index]
        let off = ArrowsGame.vecs[dir]
        let pos = st.arrow.position
        if dir == st.dir {
            st.streak += 1
            let bonus = st.streak % 8 == 0
            addScore(s, bonus ? 2 : 1)
            addStat("hits", 1, seat: s)
            s.burst(at: pos, color: .white, count: 6, speed: 150)
            s.floatText(bonus ? "+2 SERIE!" : "+1", at: CGPoint(x: pos.x + off.dx * 30, y: pos.y + st.arrowSize * 0.55), color: bonus ? .yellow : Theme.uiGreen, size: bonus ? 24 : 20)
            st.streakLabel.text = st.streak >= 4 ? "🔥 \(st.streak)er Serie" : ""
            if !s.isCPU { Sfx.shared.play(bonus ? "coin" : "tap"); Haptic.tap() }
            nextArrow(s)
        } else {
            st.streak = 0
            st.streakLabel.text = ""
            setScore(s, max(0, s.score - 1))
            s.flash(.red, alpha: 0.35)
            s.shake(6)
            s.floatText("−1", at: CGPoint(x: pos.x, y: pos.y + st.arrowSize * 0.55), color: .red, size: 22)
            st.arrow.run(SKAction.sequence([
                SKAction.moveBy(x: 10, y: 0, duration: 0.03), SKAction.moveBy(x: -20, y: 0, duration: 0.05), SKAction.moveBy(x: 10, y: 0, duration: 0.03)
            ]))
            if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
            if s.isCPU { st.cpuTimer = 0.4 + (1 - s.skill) * 0.4 }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        st.start = at
        st.touch = touch
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        guard st.touch === touch, let a = st.start else { return }
        let dx = at.x - a.x, dy = at.y - a.y
        guard hypot(dx, dy) > 26 else { return }
        st.start = nil
        let d = abs(dx) > abs(dy) ? (dx > 0 ? 1 : 3) : (dy > 0 ? 0 : 2)
        answer(seat, dir: d)
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        if st.touch === touch { st.start = nil; st.touch = nil }
    }
}
