import SpriteKit

/// Puck-Jagd: whack the pucks popping out of the holes, avoid the referee cards.
final class WhackGame: MiniScene {

    fileprivate enum Kind { case puck, gold, card }

    fileprivate struct Event {
        let time: Double
        let hole: Int
        let kind: Kind
        let up: Double
    }

    fileprivate final class Mole {
        let node: SKSpriteNode
        let kind: Kind
        let hole: Int
        let until: Double
        var alive = true
        var cpuAt: Double? = nil
        init(node: SKSpriteNode, kind: Kind, hole: Int, until: Double) {
            self.node = node; self.kind = kind; self.hole = hole; self.until = until
        }
    }

    fileprivate final class State {
        var holes: [CGPoint] = []
        var cell = CGSize.zero
        var moles: [Int: Mole] = [:]
        var nextEvent = 0
    }

    private var st: [State] = []
    private var events: [Event] = []
    private var cols = 3
    private var rows = 4

    private static var holeTex: SKTexture {
        return Gfx.texture("whack_hole", size: CGSize(width: 90, height: 40)) { ctx in
            ctx.setFillColor(UIColor(white: 0, alpha: 0.9).cgColor)
            ctx.fillEllipse(in: CGRect(x: 3, y: 4, width: 84, height: 32))
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.18).cgColor)
            ctx.setLineWidth(3)
            ctx.strokeEllipse(in: CGRect(x: 3, y: 4, width: 84, height: 32))
        }
    }

    private static func moleTex(_ kind: Kind) -> SKTexture {
        switch kind {
        case .puck:
            return Gfx.texture("whack_puck", size: CGSize(width: 70, height: 54)) { ctx in
                // puck seen from the side, with eyes
                ctx.setFillColor(UIColor(white: 0.1, alpha: 1).cgColor)
                ctx.fill(CGRect(x: 4, y: 14, width: 62, height: 26))
                ctx.fillEllipse(in: CGRect(x: 4, y: 30, width: 62, height: 20))
                ctx.setFillColor(UIColor(white: 0.22, alpha: 1).cgColor)
                ctx.fillEllipse(in: CGRect(x: 4, y: 4, width: 62, height: 20))
                ctx.setFillColor(Theme.uiOrange.cgColor)
                ctx.fill(CGRect(x: 4, y: 26, width: 62, height: 4))
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fillEllipse(in: CGRect(x: 20, y: 31, width: 11, height: 11))
                ctx.fillEllipse(in: CGRect(x: 39, y: 31, width: 11, height: 11))
                ctx.setFillColor(UIColor.black.cgColor)
                ctx.fillEllipse(in: CGRect(x: 24, y: 35, width: 5, height: 5))
                ctx.fillEllipse(in: CGRect(x: 43, y: 35, width: 5, height: 5))
            }
        case .gold:
            return Gfx.texture("whack_gold", size: CGSize(width: 70, height: 54)) { ctx in
                ctx.setFillColor(UIColor(red: 0.85, green: 0.6, blue: 0.0, alpha: 1).cgColor)
                ctx.fill(CGRect(x: 4, y: 14, width: 62, height: 26))
                ctx.fillEllipse(in: CGRect(x: 4, y: 30, width: 62, height: 20))
                ctx.setFillColor(UIColor(red: 1, green: 0.85, blue: 0.2, alpha: 1).cgColor)
                ctx.fillEllipse(in: CGRect(x: 4, y: 4, width: 62, height: 20))
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fillEllipse(in: CGRect(x: 20, y: 31, width: 11, height: 11))
                ctx.fillEllipse(in: CGRect(x: 39, y: 31, width: 11, height: 11))
                ctx.setFillColor(UIColor.black.cgColor)
                ctx.fillEllipse(in: CGRect(x: 24, y: 35, width: 5, height: 5))
                ctx.fillEllipse(in: CGRect(x: 43, y: 35, width: 5, height: 5))
            }
        case .card:
            return Gfx.texture("whack_card", size: CGSize(width: 70, height: 54)) { ctx in
                // referee hand holding a card
                let path = UIBezierPath(roundedRect: CGRect(x: 18, y: 2, width: 34, height: 48), cornerRadius: 5)
                ctx.addPath(path.cgPath)
                ctx.setFillColor(UIColor(red: 1, green: 0.85, blue: 0.1, alpha: 1).cgColor)
                ctx.fillPath()
                ctx.addPath(path.cgPath)
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.setLineWidth(3)
                ctx.strokePath()
                ctx.setFillColor(UIColor.black.cgColor)
                ctx.fill(CGRect(x: 24, y: 30, width: 22, height: 4))
            }
        }
    }

    override func setupGame() {
        duration = 30
        let wide = (seats.first?.w ?? 200) > 260
        cols = wide ? 4 : 3
        rows = wide ? 3 : 4
        // shared event list (same for every seat)
        let r = newRand()
        events = []
        var t = 0.4
        while t < duration - 0.6 {
            let p = t / duration
            let roll = r.double()
            let kind: Kind = roll < 0.1 ? .gold : (roll < 0.25 ? .card : .puck)
            let up = (1.2 - 0.55 * p) * (kind == .gold ? 0.75 : 1)
            events.append(Event(time: t, hole: r.int(0, cols * rows - 1), kind: kind, up: up))
            if r.chance(0.25 + 0.3 * p) {
                events.append(Event(time: t + 0.05, hole: r.int(0, cols * rows - 1), kind: r.chance(0.3) ? .card : .puck, up: up))
            }
            t += (0.75 - 0.42 * p) * Double(r.range(0.8, 1.2))
        }
        st = []
        for s in seats {
            let g = State()
            let top = s.h / 2 - 40
            let bottom = -s.h / 2 + 16
            g.cell = CGSize(width: s.w / CGFloat(cols), height: (top - bottom) / CGFloat(rows))
            for row in 0..<rows {
                for c in 0..<cols {
                    let x = -s.w / 2 + g.cell.width * (CGFloat(c) + 0.5)
                    let y = bottom + g.cell.height * (CGFloat(row) + 0.3)
                    g.holes.append(CGPoint(x: x, y: y))
                    let hw = min(g.cell.width * 0.82, 84)
                    let hole = SKSpriteNode(texture: WhackGame.holeTex, size: CGSize(width: hw, height: hw * 0.42))
                    hole.position = CGPoint(x: x, y: y)
                    hole.zPosition = 1
                    s.field.addChild(hole)
                }
            }
            st.append(g)
            let hint = label("TIPP DIE PUCKS! 🔨", size: min(18, s.w * 0.085), color: .white)
            hint.position = CGPoint(x: 0, y: 0)
            hint.zPosition = 60
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.4), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private func pop(_ s: Seat, _ e: Event) {
        let g = st[s.index]
        if let old = g.moles[e.hole] {
            old.alive = false
            old.node.removeFromParent()
        }
        let hw = min(g.cell.width * 0.72, 70)
        let node = SKSpriteNode(texture: WhackGame.moleTex(e.kind), size: CGSize(width: hw, height: hw * 54 / 70))
        node.anchorPoint = CGPoint(x: 0.5, y: 0.15)
        let base = g.holes[e.hole]
        node.position = base
        node.zPosition = 2
        node.yScale = 0.1
        s.field.addChild(node)
        node.run(SKAction.scaleY(to: 1, duration: 0.09))
        if e.kind == .gold {
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: hw * 1.6, height: hw * 1.6))
            glow.color = .yellow
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.5
            glow.position = CGPoint(x: 0, y: hw * 0.3)
            glow.zPosition = -1
            node.addChild(glow)
        }
        let m = Mole(node: node, kind: e.kind, hole: e.hole, until: elapsed + e.up)
        if s.isCPU {
            let react = 0.22 + (1 - s.skill) * 0.55 + Double.random(in: 0...0.2)
            let p: Double = e.kind == .card ? (1 - s.skill) * 0.25 : 0.45 + 0.5 * s.skill
            if Double.random(in: 0..<1) < p && react < e.up { m.cpuAt = elapsed + react }
        }
        g.moles[e.hole] = m
    }

    private func hide(_ m: Mole) {
        m.alive = false
        m.node.run(SKAction.sequence([SKAction.scaleY(to: 0.05, duration: 0.08), SKAction.removeFromParent()]))
    }

    private func whack(_ s: Seat, _ m: Mole) {
        guard m.alive else { return }
        m.alive = false
        let g = st[s.index]
        g.moles[m.hole] = nil
        let p = CGPoint(x: g.holes[m.hole].x, y: g.holes[m.hole].y + m.node.size.height * 0.4)
        switch m.kind {
        case .puck:
            addScore(s, 1)
            addStat("hits", 1, seat: s)
            s.floatText("+1", at: p, color: .white)
            Sfx.shared.play("hit")
            if !s.isCPU { Haptic.tap(.medium) }
        case .gold:
            addScore(s, 3)
            addStat("hits", 1, seat: s)
            s.floatText("+3", at: p, color: .yellow, size: 26)
            Sfx.shared.play("coin")
            if !s.isCPU { Haptic.good() }
        case .card:
            setScore(s, max(0, s.score - 2))
            s.floatText("-2", at: p, color: UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1), size: 26)
            s.flash(UIColor.red, alpha: 0.4)
            s.shake(6)
            Sfx.shared.play("whistle")
            if !s.isCPU { Haptic.bad() }
        }
        s.burst(at: p, color: m.kind == .card ? .red : (m.kind == .gold ? .yellow : s.color), count: 10, speed: 80)
        // stick swing
        let stick = SKSpriteNode(color: .white, size: CGSize(width: 6, height: min(60, g.cell.height * 0.8)))
        stick.anchorPoint = CGPoint(x: 0.5, y: 0)
        stick.position = CGPoint(x: p.x + 18, y: p.y - 6)
        stick.zRotation = -0.9
        stick.zPosition = 40
        let blade = SKSpriteNode(color: s.color, size: CGSize(width: 18, height: 8))
        blade.position = CGPoint(x: -6, y: stick.size.height)
        stick.addChild(blade)
        s.field.addChild(stick)
        stick.run(SKAction.sequence([SKAction.rotate(toAngle: 0.5, duration: 0.07), SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))
        m.node.run(SKAction.sequence([SKAction.scaleY(to: 0.35, duration: 0.05), SKAction.scaleX(to: 1.3, duration: 0.05), SKAction.fadeOut(withDuration: 0.12), SKAction.removeFromParent()]))
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats {
            let g = st[s.index]
            while g.nextEvent < events.count && events[g.nextEvent].time <= elapsed {
                pop(s, events[g.nextEvent])
                g.nextEvent += 1
            }
            for (hole, m) in g.moles {
                if !m.alive { g.moles[hole] = nil; continue }
                if let t = m.cpuAt, elapsed >= t {
                    m.cpuAt = nil
                    whack(s, m)
                    continue
                }
                if elapsed >= m.until {
                    hide(m)
                    g.moles[hole] = nil
                }
            }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        var best: Mole? = nil
        var bd = CGFloat.greatestFiniteMagnitude
        for (_, m) in g.moles where m.alive {
            let c = CGPoint(x: g.holes[m.hole].x, y: g.holes[m.hole].y + m.node.size.height * 0.4)
            let d = hypot(at.x - c.x, at.y - c.y)
            if d < max(g.cell.width, g.cell.height) * 0.55 && d < bd { bd = d; best = m }
        }
        if let m = best {
            whack(seat, m)
        } else {
            Sfx.shared.play("tap")
        }
    }
}
