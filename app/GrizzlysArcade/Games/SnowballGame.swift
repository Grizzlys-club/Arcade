import SpriteKit

/// Schneeballschlacht: throw snowballs at the snowmen, never hit a friend bear.
final class SnowballGame: MiniScene {

    fileprivate struct Spawn {
        let time: Double
        let x: CGFloat      // -1...1
        let y: CGFloat      // 0...1
        let friend: Bool
        let life: Double
        let vx: CGFloat
    }

    fileprivate final class Target {
        let node: SKNode
        let friend: Bool
        let until: Double
        var vx: CGFloat
        var alive = true
        var radius: CGFloat
        init(node: SKNode, friend: Bool, until: Double, vx: CGFloat, radius: CGFloat) {
            self.node = node; self.friend = friend; self.until = until; self.vx = vx; self.radius = radius
        }
    }

    fileprivate final class Ball {
        let node: SKSpriteNode
        let from: CGPoint
        let to: CGPoint
        let t0: Double
        let dur: Double
        let arc: CGFloat
        init(node: SKSpriteNode, from: CGPoint, to: CGPoint, t0: Double, dur: Double, arc: CGFloat) {
            self.node = node; self.from = from; self.to = to; self.t0 = t0; self.dur = dur; self.arc = arc
        }
    }

    fileprivate final class State {
        var targets: [Target] = []
        var balls: [Ball] = []
        var next = 0
        var cooldown = 0.0
        var aim: SKSpriteNode!
        var aiming = false
        var cpuShots: [(at: Double, aim: CGPoint)] = []
        var cpuPlan: [(Target, Double)] = []
    }

    private var st: [State] = []
    private var spawns: [Spawn] = []
    private var tsize: CGFloat = 38

    private static func snowmanTex() -> SKTexture {
        return Gfx.texture("snowball_man", size: CGSize(width: 48, height: 64)) { ctx in
            ctx.setFillColor(UIColor(white: 0.97, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 2, width: 36, height: 34))
            ctx.fillEllipse(in: CGRect(x: 12, y: 28, width: 24, height: 24))
            ctx.setStrokeColor(UIColor(red: 0.5, green: 0.75, blue: 1, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: 6, y: 2, width: 36, height: 34))
            ctx.strokeEllipse(in: CGRect(x: 12, y: 28, width: 24, height: 24))
            ctx.setFillColor(UIColor(red: 0.12, green: 0.12, blue: 0.2, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 14, y: 50, width: 20, height: 4))
            ctx.fill(CGRect(x: 18, y: 53, width: 12, height: 10))
            ctx.fillEllipse(in: CGRect(x: 18, y: 41, width: 4, height: 4))
            ctx.fillEllipse(in: CGRect(x: 27, y: 41, width: 4, height: 4))
            ctx.setFillColor(UIColor.orange.cgColor)
            ctx.fill(CGRect(x: 22, y: 36, width: 12, height: 4))
            ctx.setFillColor(UIColor(red: 0.12, green: 0.12, blue: 0.2, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 21, y: 22, width: 5, height: 5))
            ctx.fillEllipse(in: CGRect(x: 21, y: 12, width: 5, height: 5))
        }
    }

    override func setupGame() {
        duration = 30
        let r = newRand()
        spawns = []
        var t = 0.5
        while t < duration - 1 {
            let p = t / duration
            let friend = r.chance(0.28)
            spawns.append(Spawn(time: t, x: r.range(-1, 1), y: r.range(0, 1), friend: friend,
                                life: Double(1.9 - 0.7 * p) * Double(r.range(0.85, 1.15)),
                                vx: r.range(-1, 1) * (20 + 50 * CGFloat(p))))
            t += Double(0.62 - 0.27 * p) * Double(r.range(0.8, 1.2))
        }
        tsize = min(50, (seats.first?.w ?? 200) * 0.2)
        st = []
        for s in seats {
            let g = State()
            let aim = SKSpriteNode(texture: Gfx.circle(14, UIColor.clear, ring: s.color), size: CGSize(width: 28, height: 28))
            aim.zPosition = 80
            aim.alpha = 0
            s.field.addChild(aim)
            g.aim = aim
            // snow bank at the player's edge
            let bank = SKSpriteNode(texture: Gfx.pill(s.w, 26, fill: UIColor(white: 1, alpha: 0.18), border: UIColor(white: 1, alpha: 0.4), corner: 12, gloss: false), size: CGSize(width: s.w, height: 26))
            bank.position = CGPoint(x: 0, y: -s.h / 2 + 8)
            bank.zPosition = 3
            s.field.addChild(bank)
            st.append(g)
            let hint = label("ZIEHEN & LOSLASSEN ❄️", size: min(16, s.w * 0.075), color: .white)
            hint.position = CGPoint(x: 0, y: -s.h / 2 + 60)
            hint.zPosition = 60
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.4), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private func origin(_ s: Seat) -> CGPoint { return CGPoint(x: 0, y: -s.h / 2 + 26) }

    private func spawn(_ s: Seat, _ e: Spawn) {
        let g = st[s.index]
        let node = SKNode()
        var rad = tsize * 0.55
        if e.friend {
            let b = makeBear(s, height: tsize * 0.95, faceRight: e.vx > 0)
            b.position = CGPoint(x: 0, y: -tsize * 0.45)
            b.startRun()
            node.addChild(b)
            let heart = label("♥", size: tsize * 0.4, color: Theme.uiPink)
            heart.position = CGPoint(x: 0, y: tsize * 0.62)
            node.addChild(heart)
            rad = tsize * 0.5
        } else {
            let m = SKSpriteNode(texture: SnowballGame.snowmanTex(), size: CGSize(width: tsize * 0.8, height: tsize * 0.8 * 64 / 48))
            node.addChild(m)
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: tsize * 1.5, height: tsize * 1.5))
            glow.color = Theme.uiBlue; glow.colorBlendFactor = 1; glow.blendMode = .add; glow.alpha = 0.35
            glow.zPosition = -1
            node.addChild(glow)
        }
        let top = s.h / 2 - 50
        let bottom = -s.h / 2 + 110
        let hw = s.w / 2 - tsize * 0.6
        node.position = CGPoint(x: e.x * hw, y: bottom + e.y * (top - bottom))
        node.zPosition = 10
        node.setScale(0.05)
        node.run(SKAction.scale(to: 1, duration: 0.15))
        s.field.addChild(node)
        let tg = Target(node: node, friend: e.friend, until: elapsed + e.life, vx: e.vx, radius: rad)
        g.targets.append(tg)
        if s.isCPU {
            var p = e.friend ? (1 - s.skill) * 0.08 : 0.3 + 0.65 * s.skill
            p = min(p, 0.95)
            if Double.random(in: 0..<1) < p {
                let react = 0.3 + (1 - s.skill) * 0.7 + Double.random(in: 0...0.25)
                if react < e.life { g.cpuPlan.append((tg, elapsed + react)) }
            }
        }
    }

    private func throwBall(_ s: Seat, to target: CGPoint) {
        let g = st[s.index]
        if elapsed < g.cooldown { return }
        g.cooldown = elapsed + 0.22
        let from = origin(s)
        var to = target
        to.y = max(to.y, from.y + 30)
        let ball = SKSpriteNode(texture: Gfx.ball(8), size: CGSize(width: 16, height: 16))
        ball.color = .white; ball.colorBlendFactor = 0.8
        ball.position = from
        ball.zPosition = 50
        s.field.addChild(ball)
        let dist = hypot(to.x - from.x, to.y - from.y)
        g.balls.append(Ball(node: ball, from: from, to: to, t0: elapsed, dur: 0.3 + Double(dist) / 700, arc: 40 + dist * 0.18))
        Sfx.shared.play("kick")
        if !s.isCPU { Haptic.tap(.light) }
    }

    private func land(_ s: Seat, _ b: Ball) {
        let g = st[s.index]
        b.node.removeFromParent()
        var hit: Target? = nil
        var bd = CGFloat.greatestFiniteMagnitude
        for t in g.targets where t.alive {
            let d = hypot(t.node.position.x - b.to.x, t.node.position.y - b.to.y)
            if d < t.radius + 8 && d < bd { bd = d; hit = t }
        }
        guard let t = hit else {
            s.burst(at: b.to, color: UIColor(white: 1, alpha: 1), count: 5, speed: 40)
            Sfx.shared.play("tap")
            return
        }
        t.alive = false
        let p = t.node.position
        if t.friend {
            setScore(s, max(0, s.score - 2))
            s.floatText("-2", at: p, color: UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1), size: 26)
            s.flash(UIColor.red, alpha: 0.35)
            s.shake(6)
            s.burst(at: p, color: Theme.uiPink, count: 10, speed: 80)
            Sfx.shared.play("wrong")
            if !s.isCPU { Haptic.bad() }
        } else {
            addScore(s, 1)
            addStat("hits", 1, seat: s)
            s.floatText("+1", at: p, color: .white)
            s.burst(at: p, color: UIColor(white: 1, alpha: 1), count: 14, speed: 100)
            s.burst(at: p, color: Theme.uiBlue, count: 6, speed: 70)
            Sfx.shared.play("hit")
            if !s.isCPU { Haptic.tap(.medium) }
        }
        t.node.run(SKAction.sequence([SKAction.group([SKAction.scaleX(to: 1.4, duration: 0.08), SKAction.scaleY(to: 0.3, duration: 0.08)]), SKAction.fadeOut(withDuration: 0.1), SKAction.removeFromParent()]))
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats {
            let g = st[s.index]
            while g.next < spawns.count && spawns[g.next].time <= elapsed {
                spawn(s, spawns[g.next]); g.next += 1
            }
            let hw = s.w / 2 - tsize * 0.5
            for t in g.targets where t.alive {
                t.node.position.x += t.vx * CGFloat(dt)
                if abs(t.node.position.x) > hw { t.vx = -t.vx; t.node.position.x = max(-hw, min(hw, t.node.position.x)) }
                if elapsed >= t.until {
                    t.alive = false
                    t.node.run(SKAction.sequence([SKAction.scale(to: 0.05, duration: 0.12), SKAction.removeFromParent()]))
                }
            }
            g.targets.removeAll { !$0.alive }
            // balls in flight
            var done: [Ball] = []
            for b in g.balls {
                let k = CGFloat(min(1, (elapsed - b.t0) / b.dur))
                b.node.position = CGPoint(x: b.from.x + (b.to.x - b.from.x) * k,
                                          y: b.from.y + (b.to.y - b.from.y) * k + sin(k * .pi) * b.arc)
                b.node.setScale(1.5 - 0.95 * k)
                if k >= 1 { done.append(b) }
            }
            for b in done { land(s, b) }
            g.balls.removeAll { x in done.contains { $0 === x } }
            // CPU
            if s.isCPU {
                var rest: [(Target, Double)] = []
                for (t, at) in g.cpuPlan {
                    if !t.alive { continue }
                    if elapsed >= at && elapsed < g.cooldown { rest.append((t, at)) }
                    else if elapsed >= at {
                        let flight = 0.3 + Double(hypot(t.node.position.x, t.node.position.y - origin(s).y)) / 700
                        let err = (1 - s.skill) * 38
                        let aim = CGPoint(x: t.node.position.x + t.vx * CGFloat(flight) + CGFloat.random(in: -err...err),
                                          y: t.node.position.y + CGFloat.random(in: -err...err) * 0.6)
                        throwBall(s, to: aim)
                    } else { rest.append((t, at)) }
                }
                g.cpuPlan = rest
            }
        }
    }

    // MARK: input

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        g.aiming = true
        g.aim.position = at
        g.aim.alpha = 0.9
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        g.aim.position = at
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        g.aim.alpha = 0
        g.aiming = false
        throwBall(seat, to: at)
    }
}
