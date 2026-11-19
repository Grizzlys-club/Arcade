import SpriteKit

/// Ballregen: catch falling balls with your bear. White +1, gold +3, yellow card -3. 30 seconds.
final class BallRainGame: MiniScene {

    enum Kind { case white, gold, card }

    private final class Item {
        let node: SKSpriteNode
        let kind: Kind
        var pos: CGPoint
        var speed: CGFloat
        var spin: CGFloat
        var done = false
        init(node: SKSpriteNode, kind: Kind, pos: CGPoint, speed: CGFloat, spin: CGFloat) {
            self.node = node
            self.kind = kind
            self.pos = pos
            self.speed = speed
            self.spin = spin
        }
    }

    private final class State {
        var rand: Rand!
        var bear: BearNode!
        var bearX: CGFloat = 0
        var targetX: CGFloat = 0
        var bearH: CGFloat = 50
        var bearW: CGFloat = 60
        var floorY: CGFloat = 0
        var items: [Item] = []
        var spawnTimer: Double = 0.4
        var cpuRetarget: Double = 0
        var hint: SKNode?
        var combo = 0
    }

    private var st: [State] = []
    private let itemR: CGFloat = 11

    override func setupGame() {
        duration = 30
        for s in seats {
            let o = State()
            o.rand = newRand()
            st.append(o)
            let w = s.w, h = s.h
            let scale = min(1, w / 300)

            let sky = SKSpriteNode(texture: BallRainGame.skyTexture(w, h), size: s.size)
            sky.zPosition = -10
            s.field.addChild(sky)

            o.floorY = -h / 2 + 8
            let ground = SKSpriteNode(texture: Gfx.rect(w, 6, s.color.withAlphaComponent(0.5), corner: 3), size: CGSize(width: w, height: 6))
            ground.position = CGPoint(x: 0, y: o.floorY - 2)
            ground.zPosition = 1
            s.field.addChild(ground)

            o.bearH = min(64, h * 0.17) * max(0.85, scale)
            o.bearW = o.bearH * bearAspect
            let b = makeBear(s, height: o.bearH, faceRight: false)
            b.position = CGPoint(x: 0, y: o.floorY)
            b.zPosition = 5
            s.field.addChild(b)
            o.bear = b
            // catch glow above the bear
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: o.bearW * 1.6, height: o.bearH * 0.9))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.35
            glow.position = CGPoint(x: 0, y: o.bearH * 0.75)
            glow.zPosition = -1
            b.addChild(glow)

            if !s.isCPU {
                let hint = SKNode()
                let l = label("← FINGER ZIEHEN →", size: 15, color: s.color)
                l.position = CGPoint(x: 0, y: o.floorY + o.bearH + 30)
                hint.addChild(l)
                hint.zPosition = 50
                s.field.addChild(hint)
                o.hint = hint
            }
        }
    }

    private static func skyTexture(_ w: CGFloat, _ h: CGFloat) -> SKTexture {
        return Gfx.texture("rain_sky\(Int(w))x\(Int(h))", size: CGSize(width: w, height: h), scale: 1) { ctx in
            Gfx.gradientColors(UIColor(red: 0.04, green: 0.06, blue: 0.18, alpha: 0.9), UIColor(red: 0.1, green: 0.14, blue: 0.3, alpha: 0.85), in: ctx, size: CGSize(width: w, height: h))
            ctx.setFillColor(UIColor(white: 1, alpha: 0.5).cgColor)
            var seed: UInt32 = UInt32(w * 7 + h)
            for _ in 0..<40 {
                seed = seed &* 1664525 &+ 1013904223
                let x = CGFloat(seed % UInt32(max(1, w)))
                seed = seed &* 1664525 &+ 1013904223
                let y = CGFloat(seed % UInt32(max(1, h * 0.7)))
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: 1.6, height: 1.6))
            }
        }
    }

    private static var cardTexture: SKTexture {
        return Gfx.texture("rain_card", size: CGSize(width: 18, height: 25)) { ctx in
            let path = UIBezierPath(roundedRect: CGRect(x: 1, y: 1, width: 16, height: 23), cornerRadius: 3)
            ctx.addPath(path.cgPath)
            ctx.setFillColor(UIColor(red: 1, green: 0.85, blue: 0.05, alpha: 1).cgColor)
            ctx.fillPath()
            ctx.addPath(path.cgPath)
            ctx.setStrokeColor(UIColor(red: 0.5, green: 0.35, blue: 0, alpha: 1).cgColor)
            ctx.setLineWidth(1.5)
            ctx.strokePath()
        }
    }

    // MARK: input

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let o = st[seat.index]
        o.targetX = at.x
        if let h = o.hint {
            h.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
            o.hint = nil
        }
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        st[seat.index].targetX = at.x
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        for s in seats {
            let o = st[s.index]
            o.spawnTimer -= dt
            if o.spawnTimer <= 0 {
                spawn(s, o)
                o.spawnTimer = max(0.26, 0.62 - elapsed * 0.012)
            }

            if s.isCPU { cpu(s, o, dt) }
            let limit = s.w / 2 - o.bearW * 0.4
            let tgt = max(-limit, min(limit, o.targetX))
            let d = tgt - o.bearX
            if s.isCPU {
                let maxSpeed = s.w * (0.8 + CGFloat(s.skill) * 1.5)
                o.bearX += max(-maxSpeed * fdt, min(maxSpeed * fdt, d))
            } else {
                o.bearX += d * min(1, fdt * 20)
            }
            o.bear.position.x = o.bearX
            if abs(d) > 3 {
                o.bear.setFacing(right: d > 0)
                o.bear.zRotation = max(-0.15, min(0.15, -d * 0.004))
            } else {
                o.bear.zRotation *= 0.8
            }

            let catchTop = o.floorY + o.bearH * 0.95
            let catchBottom = o.floorY + o.bearH * 0.25
            for it in o.items where !it.done {
                it.pos.y -= it.speed * fdt
                it.node.position = it.pos
                it.node.zRotation += it.spin * fdt
                if it.pos.y <= catchTop && it.pos.y >= catchBottom && abs(it.pos.x - o.bearX) < o.bearW * 0.5 + itemR * 0.5 {
                    caught(s, o, it)
                } else if it.pos.y < o.floorY - itemR {
                    it.done = true
                    it.node.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))
                    if it.kind != .card { o.combo = 0 }
                }
            }
            o.items.removeAll { $0.done }
        }
    }

    private func spawn(_ s: Seat, _ o: State) {
        let r = o.rand!
        let x = r.range(-s.w / 2 + 16, s.w / 2 - 16)
        let roll = r.double()
        let kind: Kind = roll < 0.13 ? .gold : (roll < 0.33 ? .card : .white)
        let speed = s.h * (0.42 + CGFloat(elapsed) * 0.018 + r.range(0, 0.18)) * (kind == .gold ? 1.2 : 1)
        let spin = r.range(-4, 4)
        let node: SKSpriteNode
        switch kind {
        case .white:
            node = SKSpriteNode(texture: Gfx.ball(14), size: CGSize(width: itemR * 2, height: itemR * 2))
        case .gold:
            node = SKSpriteNode(texture: Gfx.ball(14), size: CGSize(width: itemR * 2.2, height: itemR * 2.2))
            node.color = UIColor(red: 1, green: 0.8, blue: 0.1, alpha: 1)
            node.colorBlendFactor = 0.75
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: itemR * 5, height: itemR * 5))
            g.color = UIColor.yellow
            g.colorBlendFactor = 1
            g.blendMode = .add
            g.alpha = 0.7
            g.zPosition = -1
            node.addChild(g)
        case .card:
            node = SKSpriteNode(texture: BallRainGame.cardTexture, size: CGSize(width: 18, height: 25))
        }
        let pos = CGPoint(x: x, y: s.h / 2 - 34)
        node.position = pos
        node.zPosition = 8
        node.alpha = 0
        node.run(SKAction.fadeIn(withDuration: 0.15))
        s.field.addChild(node)
        o.items.append(Item(node: node, kind: kind, pos: pos, speed: speed, spin: spin))
    }

    private func caught(_ s: Seat, _ o: State, _ it: Item) {
        it.done = true
        it.node.removeAllActions()
        it.node.removeFromParent()
        let p = CGPoint(x: it.pos.x, y: it.pos.y + 10)
        switch it.kind {
        case .white:
            addScore(s, 1)
            addStat("balls", 1, seat: s)
            o.combo += 1
            s.floatText("+1", at: p, color: s.color, size: 18)
            s.burst(at: p, color: .white, count: 5, speed: 60)
            Sfx.shared.play("pop")
            if !s.isCPU { Haptic.tap() }
        case .gold:
            addScore(s, 3)
            addStat("balls", 1, seat: s)
            o.combo += 1
            s.floatText("+3", at: p, color: UIColor.yellow, size: 24)
            s.burst(at: p, color: UIColor.yellow, count: 14, speed: 100)
            Sfx.shared.play("coin")
            if !s.isCPU { Haptic.good() }
        case .card:
            setScore(s, max(0, s.score - 3))
            o.combo = 0
            s.floatText("-3", at: p, color: UIColor.red, size: 24)
            s.flash(UIColor(red: 1, green: 0.85, blue: 0, alpha: 1), alpha: 0.3)
            s.shake(4)
            Sfx.shared.play("wrong")
            if !s.isCPU { Haptic.bad() }
        }
        o.bear.squash()
        if o.combo > 0 && o.combo % 10 == 0 {
            s.banner("\(o.combo)ER SERIE!", color: s.color, size: 28, duration: 0.5)
        }
    }

    private func cpu(_ s: Seat, _ o: State, _ dt: Double) {
        o.cpuRetarget -= dt
        if o.cpuRetarget > 0 { return }
        o.cpuRetarget = 0.08 + (1 - s.skill) * 0.25
        let catchY = o.floorY + o.bearH * 0.6
        let maxSpeed = s.w * (0.8 + CGFloat(s.skill) * 1.5)
        var best: Item? = nil
        var bestValue: CGFloat = -1
        for it in o.items where !it.done && it.kind != .card && it.pos.y > catchY {
            let t = (it.pos.y - catchY) / it.speed
            let dist = abs(it.pos.x - o.bearX)
            if dist > maxSpeed * t + o.bearW * 0.4 { continue }
            let value = CGFloat(it.kind == .gold ? 3 : 1) / (t + 0.3)
            if value > bestValue { bestValue = value; best = it }
        }
        var tx = best?.pos.x ?? o.bearX * 0.9
        // dodge cards that are about to land on the bear
        for it in o.items where !it.done && it.kind == .card && it.pos.y > catchY {
            let t = (it.pos.y - catchY) / it.speed
            if t < 0.45 && abs(it.pos.x - tx) < o.bearW * 0.6 && Double.random(in: 0...1) < s.skill + 0.2 {
                tx = it.pos.x + (it.pos.x > o.bearX ? -1 : 1) * o.bearW * 0.9
            }
        }
        o.targetX = tx + CGFloat.random(in: -1...1) * o.bearW * 0.3 * CGFloat(1 - s.skill)
    }
}
