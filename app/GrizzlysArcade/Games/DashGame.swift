import SpriteKit

/// Bären-Sprint: 3-lane runner. Dodge obstacles, collect balls.
final class DashGame: MiniScene {

    fileprivate enum Kind { case cone, hurdle, goal, ball }

    fileprivate final class Obj {
        let node: SKSpriteNode
        let kind: Kind
        let lane: Int
        var y: CGFloat
        var alive = true
        init(node: SKSpriteNode, kind: Kind, lane: Int, y: CGFloat) {
            self.node = node; self.kind = kind; self.lane = lane; self.y = y
        }
    }

    fileprivate final class State {
        var rand: Rand
        var lane = 1
        var lives = 3
        var dist: CGFloat = 0
        var balls = 0
        var nextRow: CGFloat = 260
        var objs: [Obj] = []
        var invuln = 0.0
        var bear: BearNode!
        var bearY: CGFloat = 0
        var laneX: [CGFloat] = []
        var stripes: [SKSpriteNode] = []
        var stripeSpan: CGFloat = 0
        var hearts: [SKLabelNode] = []
        var cpuT = 0.0
        init(rand: Rand) { self.rand = rand }
    }

    private var st: [State] = []
    private var runSpeed: CGFloat = 220

    private static var coneTex: SKTexture {
        return Gfx.texture("dash_cone", size: CGSize(width: 40, height: 44)) { ctx in
            ctx.setFillColor(Theme.uiOrange.cgColor)
            ctx.move(to: CGPoint(x: 20, y: 2))
            ctx.addLine(to: CGPoint(x: 34, y: 38))
            ctx.addLine(to: CGPoint(x: 6, y: 38))
            ctx.closePath()
            ctx.fillPath()
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(x: 12, y: 18, width: 16, height: 6))
            ctx.setFillColor(UIColor(white: 0.15, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 2, y: 37, width: 36, height: 6))
        }
    }

    private static var hurdleTex: SKTexture {
        return Gfx.texture("dash_hurdle", size: CGSize(width: 80, height: 26)) { ctx in
            ctx.setFillColor(UIColor(white: 0.9, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 2, y: 4, width: 76, height: 12))
            ctx.setFillColor(UIColor(red: 0.9, green: 0.15, blue: 0.15, alpha: 1).cgColor)
            var x: CGFloat = 2
            while x < 78 {
                ctx.fill(CGRect(x: x, y: 4, width: 8, height: 12))
                x += 16
            }
            ctx.setFillColor(UIColor(white: 0.3, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 6, y: 14, width: 4, height: 10))
            ctx.fill(CGRect(x: 70, y: 14, width: 4, height: 10))
        }
    }

    override func setupGame() {
        duration = 50
        st = seats.map { _ in State(rand: newRand()) }
        for s in seats {
            let g = st[s.index]
            let lw = min(s.w * 0.29, 96)
            g.laneX = [-lw, 0, lw]
            // track
            let track = SKSpriteNode(texture: Gfx.pill(lw * 3 + 12, s.h + 40, fill: UIColor(red: 0.12, green: 0.1, blue: 0.2, alpha: 0.95), border: s.color.withAlphaComponent(0.7), corner: 10), size: CGSize(width: lw * 3 + 12, height: s.h + 40))
            track.zPosition = -6
            s.field.addChild(track)
            let perLane = Int((s.h + 80) / 40) + 1
            g.stripeSpan = CGFloat(perLane) * 40
            for lx in [-lw / 2, lw / 2] {
                for k in 0..<perLane {
                    let y = -s.h / 2 - 20 + CGFloat(k) * 40
                    let st2 = SKSpriteNode(color: UIColor(white: 1, alpha: 0.25), size: CGSize(width: 3, height: 18))
                    st2.position = CGPoint(x: lx, y: y)
                    st2.zPosition = -5
                    s.field.addChild(st2)
                    g.stripes.append(st2)
                }
            }
            g.bearY = -s.h / 2 + 34
            let bh = min(52, s.w * 0.24)
            let bear = makeBear(s, height: bh)
            bear.position = CGPoint(x: 0, y: g.bearY)
            bear.zPosition = 20
            s.field.addChild(bear)
            bear.startRun(speed: 0.11)
            g.bear = bear
            for i in 0..<3 {
                let h = label("❤️", size: 13)
                h.position = CGPoint(x: -s.w / 2 + 18 + CGFloat(i) * 17, y: s.h / 2 - 36)
                h.zPosition = 30
                s.node.addChild(h)
                g.hearts.append(h)
            }
            let hint = label("◀ TIPPEN ▶", size: min(20, s.w * 0.1), color: .white)
            hint.position = CGPoint(x: 0, y: -s.h / 2 + 100)
            hint.zPosition = 40
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.6), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private func spawnRow(_ s: Seat) {
        let g = st[s.index]
        let r = g.rand
        let blocked = r.chance(0.35) ? 2 : 1
        var lanes = r.shuffled([0, 1, 2])
        let blockLanes = Array(lanes.prefix(blocked))
        lanes.removeFirst(blocked)
        let y = s.h / 2 + 30
        for l in blockLanes {
            let roll = r.double()
            let kind: Kind = roll < 0.45 ? .cone : (roll < 0.8 ? .hurdle : .goal)
            let node: SKSpriteNode
            let lw = g.laneX[2]
            switch kind {
            case .cone: node = SKSpriteNode(texture: DashGame.coneTex, size: CGSize(width: min(34, lw * 0.6), height: min(37, lw * 0.65)))
            case .hurdle: node = SKSpriteNode(texture: DashGame.hurdleTex, size: CGSize(width: lw * 0.9, height: lw * 0.3))
            default: node = SKSpriteNode(texture: Gfx.goal(60, 26), size: CGSize(width: lw * 0.9, height: lw * 0.42))
            }
            node.position = CGPoint(x: g.laneX[l], y: y)
            node.zPosition = 10
            s.field.addChild(node)
            g.objs.append(Obj(node: node, kind: kind, lane: l, y: y))
        }
        if r.chance(0.65), let l = lanes.first {
            let b = SKSpriteNode(texture: Gfx.ball(12), size: CGSize(width: 20, height: 20))
            b.position = CGPoint(x: g.laneX[l], y: y)
            b.zPosition = 9
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 44, height: 44))
            glow.blendMode = .add
            glow.alpha = 0.35
            glow.zPosition = -1
            b.addChild(glow)
            s.field.addChild(b)
            g.objs.append(Obj(node: b, kind: .ball, lane: l, y: y))
        }
        let gap = max(150, 240 - g.dist * 0.012) * r.range(0.9, 1.15)
        g.nextRow = g.dist + gap
    }

    private func setLane(_ s: Seat, _ l: Int) {
        let g = st[s.index]
        let nl = max(0, min(2, l))
        if nl == g.lane { return }
        let goingRight = nl > g.lane
        g.lane = nl
        g.bear.removeAction(forKey: "lane")
        g.bear.run(SKAction.moveTo(x: g.laneX[nl], duration: 0.1), withKey: "lane")
        g.bear.setFacing(right: goingRight)
        Sfx.shared.play("tap")
    }

    private func updateScore(_ s: Seat) {
        let g = st[s.index]
        let v = Int(g.dist / 10) + g.balls * 5
        if v != s.score {
            s.score = v
            s.scoreLabel?.text = "\(v)"
        }
    }

    override func gameUpdate(_ dt: Double) {
        let d = CGFloat(dt)
        runSpeed = 220 + CGFloat(elapsed) * 6.5
        for s in seats {
            let g = st[s.index]
            let move = runSpeed * d
            // stripes scroll (also when out, slower)
            let sm = s.alive ? move : move * 0.2
            for stp in g.stripes {
                stp.position.y -= sm
                if stp.position.y < -s.h / 2 - 20 { stp.position.y += g.stripeSpan }
            }
            guard s.alive else { continue }
            g.dist += move
            if g.dist >= g.nextRow { spawnRow(s) }
            if g.invuln > 0 {
                g.invuln -= dt
                g.bear.alpha = (Int(g.invuln * 12) % 2 == 0) ? 0.35 : 1
                if g.invuln <= 0 { g.bear.alpha = 1 }
            }
            for o in g.objs where o.alive {
                o.y -= move
                o.node.position.y = o.y
                if o.lane == g.lane && abs(o.y - (g.bearY + 14)) < 22 {
                    if o.kind == .ball {
                        o.alive = false
                        g.balls += 1
                        addStat("balls", 1, seat: s)
                        s.floatText("+5", at: CGPoint(x: o.node.position.x, y: o.y + 10), color: .yellow, size: 18)
                        o.node.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.8, duration: 0.15), SKAction.fadeOut(withDuration: 0.15)]), SKAction.removeFromParent()]))
                        Sfx.shared.play("coin")
                    } else if g.invuln <= 0 {
                        hit(s, o)
                    }
                }
                if o.y < -s.h / 2 - 40 {
                    o.alive = false
                    o.node.removeFromParent()
                }
            }
            g.objs.removeAll { !$0.alive }
            updateScore(s)
            if s.isCPU && s.alive { cpu(s, dt) }
        }
        if seats.allSatisfy({ !$0.alive }) { finishGame() }
    }

    private func hit(_ s: Seat, _ o: Obj) {
        let g = st[s.index]
        g.lives -= 1
        g.invuln = 1.3
        o.node.run(SKAction.group([SKAction.rotate(byAngle: 2, duration: 0.3), SKAction.moveBy(x: 0, y: 30, duration: 0.3), SKAction.fadeOut(withDuration: 0.3)]))
        o.alive = false
        s.shake(7)
        s.flash(UIColor.red, alpha: 0.3)
        g.bear.squash()
        Sfx.shared.play("stomp")
        if !s.isCPU { Haptic.bad() }
        if g.lives >= 0 && g.lives < g.hearts.count {
            g.hearts[g.lives].run(SKAction.sequence([SKAction.scale(to: 1.6, duration: 0.1), SKAction.fadeAlpha(to: 0.15, duration: 0.2)]))
        }
        if g.lives <= 0 {
            g.bear.stopRun()
            g.bear.alpha = 1
            g.bear.run(SKAction.rotate(toAngle: .pi / 2, duration: 0.3))
            updateScore(s)
            s.knockOut("RAUS")
            Sfx.shared.play("lose")
        }
    }

    private func blocked(_ g: State, lane: Int, within: CGFloat) -> Bool {
        return g.objs.contains { $0.alive && $0.kind != .ball && $0.lane == lane && $0.y > g.bearY - 10 && $0.y - g.bearY < within }
    }

    private func cpu(_ s: Seat, _ dt: Double) {
        let g = st[s.index]
        g.cpuT -= dt
        if g.cpuT > 0 { return }
        g.cpuT = 0.09 + (1 - s.skill) * 0.2
        let look = 110 + CGFloat(s.skill) * 120 + runSpeed * 0.15
        if blocked(g, lane: g.lane, within: look) {
            if Double.random(in: 0..<1) < (1 - s.skill) * 0.25 { return } // slow reaction
            let options = [g.lane - 1, g.lane + 1].filter { $0 >= 0 && $0 <= 2 && !blocked(g, lane: $0, within: look) }
            if let target = options.randomElement() { setLane(s, target) }
            return
        }
        // go for a ball if safe
        if let ball = g.objs.filter({ $0.alive && $0.kind == .ball && $0.y > g.bearY && $0.y - g.bearY < look * 1.2 }).min(by: { $0.y < $1.y }) {
            let step = ball.lane > g.lane ? g.lane + 1 : (ball.lane < g.lane ? g.lane - 1 : g.lane)
            if step != g.lane && !blocked(g, lane: step, within: look) && s.skill > 0.3 { setLane(s, step) }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        setLane(seat, at.x < 0 ? g.lane - 1 : g.lane + 1)
    }
}
