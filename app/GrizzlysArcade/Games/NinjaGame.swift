import SpriteKit

/// Puck-Ninja: slice flying pucks and balls, avoid red cards.
final class NinjaGame: MiniScene {

    fileprivate enum Kind { case puck, ball, gold, card }

    fileprivate final class Item {
        let node: SKSpriteNode
        let kind: Kind
        var pos: CGPoint
        var vel: CGVector
        var spin: CGFloat
        var alive = true
        var cpuPlan: Double? = nil
        var cpuDecided = false
        let r: CGFloat
        init(node: SKSpriteNode, kind: Kind, pos: CGPoint, vel: CGVector, spin: CGFloat, r: CGFloat) {
            self.node = node; self.kind = kind; self.pos = pos; self.vel = vel; self.spin = spin; self.r = r
        }
    }

    fileprivate final class State {
        var rand: Rand
        var nextSpawn = 0.6
        var items: [Item] = []
        var trail: [(CGPoint, Double)] = []
        var trailDots: [SKSpriteNode] = []
        var last: CGPoint? = nil
        var comboCount = 0
        var cpuSwipeT = 0.0
        init(rand: Rand) { self.rand = rand }
    }

    private var st: [State] = []
    private var clock = 0.0

    private static var puckTex: SKTexture {
        return Gfx.texture("ninja_puck", size: CGSize(width: 48, height: 48)) { ctx in
            ctx.setFillColor(UIColor(white: 0.08, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 2, y: 2, width: 44, height: 44))
            ctx.setStrokeColor(UIColor(white: 0.55, alpha: 1).cgColor)
            ctx.setLineWidth(3)
            ctx.strokeEllipse(in: CGRect(x: 5, y: 5, width: 38, height: 38))
            ctx.setFillColor(Theme.uiOrange.cgColor)
            ctx.fillEllipse(in: CGRect(x: 17, y: 17, width: 14, height: 14))
        }
    }

    private static var goldTex: SKTexture {
        return Gfx.texture("ninja_gold", size: CGSize(width: 48, height: 48)) { ctx in
            ctx.setFillColor(UIColor(red: 1, green: 0.8, blue: 0.1, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 2, y: 2, width: 44, height: 44))
            ctx.setStrokeColor(UIColor(red: 1, green: 1, blue: 0.7, alpha: 1).cgColor)
            ctx.setLineWidth(3)
            ctx.strokeEllipse(in: CGRect(x: 5, y: 5, width: 38, height: 38))
            ctx.setFillColor(UIColor(red: 0.7, green: 0.45, blue: 0, alpha: 1).cgColor)
            let c = CGPoint(x: 24, y: 24)
            for i in 0..<10 {
                let rad: CGFloat = i % 2 == 0 ? 12 : 5
                let a = CGFloat(i) * .pi / 5 - .pi / 2
                let p = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
                if i == 0 { ctx.move(to: p) } else { ctx.addLine(to: p) }
            }
            ctx.closePath()
            ctx.fillPath()
        }
    }

    private static var cardTex: SKTexture {
        return Gfx.texture("ninja_card", size: CGSize(width: 36, height: 48)) { ctx in
            let path = UIBezierPath(roundedRect: CGRect(x: 2, y: 2, width: 32, height: 44), cornerRadius: 5)
            ctx.addPath(path.cgPath)
            ctx.setFillColor(UIColor(red: 0.95, green: 0.1, blue: 0.12, alpha: 1).cgColor)
            ctx.fillPath()
            ctx.addPath(path.cgPath)
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(2.5)
            ctx.strokePath()
        }
    }

    override func setupGame() {
        duration = 30
        st = seats.map { _ in State(rand: newRand()) }
        for s in seats {
            let g = st[s.index]
            // dojo floor lines
            for i in 0..<5 {
                let line = SKSpriteNode(color: s.color.withAlphaComponent(0.06), size: CGSize(width: s.w, height: 2))
                line.position = CGPoint(x: 0, y: -s.h / 2 + CGFloat(i + 1) * s.h / 6)
                line.zPosition = -5
                s.field.addChild(line)
            }
            for i in 0..<14 {
                let d = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 22, height: 22))
                d.color = s.color
                d.colorBlendFactor = 0.6
                d.blendMode = .add
                d.zPosition = 50
                d.alpha = 0
                d.setScale(1 - CGFloat(i) * 0.05)
                s.field.addChild(d)
                g.trailDots.append(d)
            }
            let hint = label("WISCHEN! ⚔️", size: min(20, s.w * 0.09), color: .white)
            hint.position = CGPoint(x: 0, y: 0)
            hint.zPosition = 60
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            let warn = label("Rote Karten meiden!", size: min(13, s.w * 0.065), color: UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1))
            warn.position = CGPoint(x: 0, y: -26)
            warn.zPosition = 60
            s.field.addChild(warn)
            warn.run(SKAction.sequence([SKAction.wait(forDuration: 4.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private func gravity(_ s: Seat) -> CGFloat { return s.h * 1.55 }

    private func spawn(_ s: Seat) {
        let g = st[s.index]
        let r = g.rand
        let count = r.chance(0.3) ? (r.chance(0.4) ? 3 : 2) : 1
        for _ in 0..<count {
            let roll = r.double()
            let kind: Kind
            if roll < 0.14 { kind = .card } else if roll < 0.24 { kind = .gold } else if roll < 0.6 { kind = .puck } else { kind = .ball }
            let x = r.range(-0.36, 0.36) * s.w
            let apex = r.range(0.55, 0.88) * s.h
            let gr = gravity(s)
            let vy = sqrt(2 * gr * apex)
            let vx = (-x * 0.9 + r.range(-0.15, 0.15) * s.w) / 1.8
            let rad: CGFloat = min(22, s.w * 0.1)
            let node: SKSpriteNode
            switch kind {
            case .puck: node = SKSpriteNode(texture: NinjaGame.puckTex, size: CGSize(width: rad * 2, height: rad * 2))
            case .ball: node = SKSpriteNode(texture: Gfx.ball(20), size: CGSize(width: rad * 1.8, height: rad * 1.8))
            case .gold: node = SKSpriteNode(texture: NinjaGame.goldTex, size: CGSize(width: rad * 2, height: rad * 2))
            case .card: node = SKSpriteNode(texture: NinjaGame.cardTex, size: CGSize(width: rad * 1.4, height: rad * 1.9))
            }
            node.zPosition = 10
            let pos = CGPoint(x: x, y: -s.h / 2 - rad)
            node.position = pos
            s.field.addChild(node)
            if kind == .gold || kind == .card {
                let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: rad * 3.6, height: rad * 3.6))
                glow.color = kind == .gold ? UIColor.yellow : UIColor.red
                glow.colorBlendFactor = 1
                glow.blendMode = .add
                glow.alpha = 0.55
                glow.zPosition = -1
                node.addChild(glow)
            }
            let it = Item(node: node, kind: kind, pos: pos, vel: CGVector(dx: vx, dy: vy), spin: r.range(-5, 5), r: rad)
            g.items.append(it)
        }
        Sfx.shared.play("jump")
        let t = clock
        g.nextSpawn = t + max(0.45, 1.05 - t * 0.02) * Double(r.range(0.8, 1.2))
    }

    private func slice(_ s: Seat, _ it: Item, dir: CGVector) {
        guard it.alive else { return }
        it.alive = false
        let g = st[s.index]
        switch it.kind {
        case .card:
            setScore(s, max(0, s.score - 5))
            s.flash(UIColor.red, alpha: 0.5)
            s.shake(8)
            s.floatText("-5", at: it.pos, color: UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1), size: 28)
            Sfx.shared.play("wrong")
            if !s.isCPU { Haptic.bad() }
            g.comboCount = 0
        case .gold:
            addScore(s, 3)
            addStat("hits", 1, seat: s)
            s.floatText("+3", at: it.pos, color: .yellow, size: 26)
            Sfx.shared.play("coin")
            if !s.isCPU { Haptic.good() }
            g.comboCount += 1
        default:
            addScore(s, 1)
            addStat("hits", 1, seat: s)
            s.floatText("+1", at: it.pos, color: .white, size: 20)
            Sfx.shared.play("hit")
            if !s.isCPU { Haptic.tap() }
            g.comboCount += 1
        }
        s.burst(at: it.pos, color: it.kind == .card ? .red : (it.kind == .gold ? .yellow : s.color), count: 12, speed: 100)
        // two halves flying apart
        let len = max(0.001, hypot(dir.dx, dir.dy))
        let nx = -dir.dy / len
        let ny = dir.dx / len
        for side in [-1.0, 1.0] as [CGFloat] {
            let half = SKSpriteNode(texture: it.node.texture, size: it.node.size)
            half.position = it.pos
            half.zPosition = 9
            half.xScale = 0.55
            half.zRotation = atan2(dir.dy, dir.dx)
            half.alpha = 0.9
            s.field.addChild(half)
            half.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: nx * side * 40, y: ny * side * 40 - 60, duration: 0.5),
                    SKAction.rotate(byAngle: side * 3, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        it.node.removeFromParent()
        // slash line
        let slash = SKSpriteNode(color: .white, size: CGSize(width: it.r * 3.4, height: 3))
        slash.position = it.pos
        slash.zRotation = atan2(dir.dy, dir.dx)
        slash.zPosition = 60
        slash.blendMode = .add
        s.field.addChild(slash)
        slash.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.25), SKAction.scaleX(to: 1.6, duration: 0.25)]), SKAction.removeFromParent()]))
    }

    private func endSwipe(_ s: Seat) {
        let g = st[s.index]
        if g.comboCount >= 3 {
            let bonus = g.comboCount - 2
            addScore(s, bonus)
            s.banner("COMBO x\(g.comboCount)  +\(bonus)", color: UIColor.yellow, size: 26, duration: 0.5)
            Sfx.shared.play("fanfare")
        }
        g.comboCount = 0
        g.last = nil
    }

    private func swipe(_ s: Seat, from a: CGPoint, to b: CGPoint) {
        let g = st[s.index]
        let dir = CGVector(dx: b.x - a.x, dy: b.y - a.y)
        let segLen2 = dir.dx * dir.dx + dir.dy * dir.dy
        for it in g.items where it.alive {
            var t: CGFloat = 0
            if segLen2 > 0.0001 {
                t = ((it.pos.x - a.x) * dir.dx + (it.pos.y - a.y) * dir.dy) / segLen2
                t = max(0, min(1, t))
            }
            let cx = a.x + dir.dx * t
            let cy = a.y + dir.dy * t
            if hypot(it.pos.x - cx, it.pos.y - cy) < it.r + 6 {
                slice(s, it, dir: dir)
            }
        }
        g.trail.append((b, clock))
    }

    // MARK: loop

    override func gameUpdate(_ dt: Double) {
        clock = elapsed
        let d = CGFloat(dt)
        for s in seats {
            let g = st[s.index]
            if clock >= g.nextSpawn && duration - elapsed > 1.2 { spawn(s) }
            let gr = gravity(s)
            for it in g.items where it.alive {
                it.vel.dy -= gr * d
                it.pos.x += it.vel.dx * d
                it.pos.y += it.vel.dy * d
                it.node.position = it.pos
                it.node.zRotation += it.spin * d
                if it.pos.y < -s.h / 2 - 40 && it.vel.dy < 0 {
                    it.alive = false
                    it.node.removeFromParent()
                }
                if s.isCPU { cpuThink(s, it) }
            }
            g.items.removeAll { !$0.alive }
            // trail
            g.trail.removeAll { clock - $0.1 > 0.18 }
            for (i, dot) in g.trailDots.enumerated() {
                let idx = g.trail.count - 1 - i
                if idx >= 0 {
                    dot.position = g.trail[idx].0
                    dot.alpha = CGFloat(max(0, 1 - (clock - g.trail[idx].1) / 0.18))
                } else {
                    dot.alpha = 0
                }
            }
            if s.isCPU && g.cpuSwipeT > 0 {
                g.cpuSwipeT -= dt
                if g.cpuSwipeT <= 0 { endSwipe(s) }
            }
        }
    }

    private func cpuThink(_ s: Seat, _ it: Item) {
        if !it.cpuDecided && it.vel.dy < it.r * 6 {
            it.cpuDecided = true
            let p: Double
            if it.kind == .card { p = (1 - s.skill) * 0.18 } else { p = 0.4 + 0.55 * s.skill }
            if Double.random(in: 0..<1) < p {
                it.cpuPlan = elapsed + Double.random(in: 0.05...(0.15 + (1 - s.skill) * 0.35))
            }
        }
        if let t = it.cpuPlan, elapsed >= t, it.alive {
            it.cpuPlan = nil
            let ang = CGFloat.random(in: 0..<(2 * .pi))
            let a = CGPoint(x: it.pos.x - cos(ang) * 40, y: it.pos.y - sin(ang) * 40)
            let b = CGPoint(x: it.pos.x + cos(ang) * 40, y: it.pos.y + sin(ang) * 40)
            let g = st[s.index]
            g.trail.append((a, clock))
            swipe(s, from: a, to: b)
            g.cpuSwipeT = 0.3
        }
    }

    // MARK: touches

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        g.last = at
        g.comboCount = 0
        g.trail.append((at, clock))
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        guard let last = g.last else { return }
        if hypot(at.x - last.x, at.y - last.y) < 2 { return }
        swipe(seat, from: last, to: at)
        g.last = at
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        endSwipe(seat)
    }
}
