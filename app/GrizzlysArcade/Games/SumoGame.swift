import SpriteKit

/// Eis-Sumo: push the other bears off a shrinking ice disc. Joystick control from your edge.
final class SumoGame: MiniScene {
    override class var layout: SeatLayout { return .arena }
    override class var stripThickness: CGFloat { return 78 }

    private final class Fighter {
        let node = SKNode()
        var bear: BearNode!
        var ring: SKSpriteNode!
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var input = CGVector.zero // -1...1
        var touch: UITouch?
        var touchStart = CGPoint.zero
        var stick: SKNode!
        var knob: SKSpriteNode!
        var outOrder = -1
        var lastHitBy = -1
        var lastHitTime: Double = -10
        var cpuThink: Double = 0
        var dashCool: Double = 0
    }

    private var fighters: [Fighter] = []
    private var center = CGPoint.zero
    private var r0: CGFloat = 150
    private var radius: CGFloat = 150
    private var disc: SKSpriteNode!
    private var discRing: SKShapeNode!
    private let bodyR: CGFloat = 22
    private var outCount = 0

    override func setupGame() {
        duration = 45
        center = CGPoint(x: arena.midX, y: arena.midY)
        r0 = min(arena.width, arena.height) / 2 - 12
        radius = r0

        // water
        let waterTex = Gfx.texture("sumo_water_\(Int(arena.width))x\(Int(arena.height))", size: arena.size, scale: 1) { ctx in
            Gfx.gradientColors(UIColor(red: 0.02, green: 0.12, blue: 0.25, alpha: 1), UIColor(red: 0.01, green: 0.05, blue: 0.14, alpha: 1), in: ctx, size: self.arena.size)
            ctx.setStrokeColor(UIColor(red: 0.3, green: 0.7, blue: 1, alpha: 0.12).cgColor)
            ctx.setLineWidth(2)
            var y: CGFloat = 8
            while y < self.arena.height {
                var x: CGFloat = CGFloat(Int(y) % 40)
                while x < self.arena.width {
                    ctx.move(to: CGPoint(x: x, y: y))
                    ctx.addQuadCurve(to: CGPoint(x: x + 20, y: y), control: CGPoint(x: x + 10, y: y - 5))
                    x += 44
                }
                y += 22
            }
            ctx.strokePath()
        }
        let water = SKSpriteNode(texture: waterTex, size: arena.size)
        water.position = center
        water.zPosition = -30
        world.addChild(water)
        water.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.8, duration: 1.4), SKAction.fadeAlpha(to: 1, duration: 1.4)])))

        let d = r0 * 2
        let iceTex = Gfx.texture("sumo_ice_\(Int(d))", size: CGSize(width: d, height: d), scale: 2) { ctx in
            let rect = CGRect(x: 2, y: 2, width: d - 4, height: d - 4)
            ctx.saveGState()
            ctx.addEllipse(in: rect)
            ctx.clip()
            let space = CGColorSpaceCreateDeviceRGB()
            let cols = [UIColor(red: 0.92, green: 0.98, blue: 1, alpha: 1).cgColor, UIColor(red: 0.62, green: 0.84, blue: 0.97, alpha: 1).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: cols, locations: [0, 1]) {
                ctx.drawRadialGradient(g, startCenter: CGPoint(x: d * 0.4, y: d * 0.4), startRadius: 0, endCenter: CGPoint(x: d / 2, y: d / 2), endRadius: d / 2, options: [.drawsAfterEndLocation])
            }
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.6).cgColor)
            ctx.setLineWidth(1.2)
            for i in 0..<14 {
                let a = CGFloat(i) * 0.9
                ctx.move(to: CGPoint(x: d / 2 + cos(a) * d * 0.1, y: d / 2 + sin(a) * d * 0.1))
                ctx.addLine(to: CGPoint(x: d / 2 + cos(a + 0.3) * d * 0.45, y: d / 2 + sin(a + 0.3) * d * 0.45))
            }
            ctx.strokePath()
            ctx.setStrokeColor(UIColor(red: 1, green: 0.54, blue: 0, alpha: 0.5).cgColor)
            ctx.setLineWidth(4)
            ctx.strokeEllipse(in: CGRect(x: d * 0.35, y: d * 0.35, width: d * 0.3, height: d * 0.3))
            ctx.restoreGState()
        }
        disc = SKSpriteNode(texture: iceTex, size: CGSize(width: d, height: d))
        disc.position = center
        disc.zPosition = -20
        world.addChild(disc)
        let logo = SKSpriteNode(imageNamed: "logo")
        logo.size = CGSize(width: d * 0.28, height: d * 0.28)
        logo.alpha = 0.35
        disc.addChild(logo)

        discRing = SKShapeNode(circleOfRadius: r0)
        discRing.strokeColor = UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 0.9)
        discRing.lineWidth = 3
        discRing.glowWidth = 8
        discRing.position = center
        discRing.zPosition = -19
        world.addChild(discRing)

        for s in seats {
            let f = Fighter()
            let dir = s.dirToScene(CGVector(dx: 0, dy: -1))
            f.pos = CGPoint(x: center.x + dir.dx * r0 * 0.55, y: center.y + dir.dy * r0 * 0.55)
            let ring = SKSpriteNode(texture: Gfx.circle(bodyR, s.color.withAlphaComponent(0.35), ring: s.color), size: CGSize(width: bodyR * 2, height: bodyR * 2))
            f.ring = ring
            f.node.addChild(ring)
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: bodyR * 4, height: bodyR * 4))
            g.color = s.color
            g.colorBlendFactor = 1
            g.blendMode = .add
            g.alpha = 0.5
            g.zPosition = -1
            f.node.addChild(g)
            let bear = makeBear(s, height: 40, faceRight: f.pos.x < center.x)
            bear.position = CGPoint(x: 0, y: -bodyR * 0.55)
            bear.zPosition = 2
            f.node.addChild(bear)
            f.bear = bear
            f.node.position = f.pos
            f.node.zPosition = 30
            world.addChild(f.node)

            // joystick visual in the strip
            let stick = SKNode()
            let base = SKSpriteNode(texture: Gfx.circle(30, UIColor(white: 1, alpha: 0.08), ring: s.color.withAlphaComponent(0.7)), size: CGSize(width: 60, height: 60))
            stick.addChild(base)
            let knob = SKSpriteNode(texture: Gfx.circle(14, s.color, ring: .white), size: CGSize(width: 28, height: 28))
            knob.zPosition = 1
            stick.addChild(knob)
            stick.position = CGPoint(x: 0, y: -4)
            stick.zPosition = 420
            stick.alpha = s.isCPU ? 0.35 : 0.9
            s.node.addChild(stick)
            f.stick = stick
            f.knob = knob
            if !s.isCPU {
                let hint = MiniScene.label("ZIEHEN = SCHIEBEN", size: 10, color: UIColor(white: 1, alpha: 0.6))
                hint.position = CGPoint(x: 0, y: -s.h / 2 + 10)
                hint.zPosition = 420
                s.node.addChild(hint)
                hint.run(SKAction.sequence([SKAction.wait(forDuration: 8), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
            }
            fighters.append(f)
        }
    }

    // MARK: touches (joystick: start point -> current point, local coords)

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let f = fighters[seat.index]
        f.touch = touch
        f.touchStart = at
        f.input = .zero
        f.stick.position = CGPoint(x: max(-seat.w / 2 + 30, min(seat.w / 2 - 30, at.x)), y: max(-seat.h / 2 + 30, min(seat.h / 2 + 60, at.y)))
        f.knob.position = .zero
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let f = fighters[seat.index]
        guard f.touch === touch else { return }
        var vx = at.x - f.touchStart.x
        var vy = at.y - f.touchStart.y
        let l = hypot(vx, vy)
        let maxL: CGFloat = 50
        if l > maxL { vx = vx / l * maxL; vy = vy / l * maxL }
        f.knob.position = CGPoint(x: vx * 0.6, y: vy * 0.6)
        let v = seat.dirToScene(CGVector(dx: vx / maxL, dy: vy / maxL))
        f.input = v
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let f = fighters[seat.index]
        guard f.touch === touch else { return }
        f.touch = nil
        f.input = .zero
        f.knob.run(SKAction.move(to: .zero, duration: 0.1))
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        // shrink the ice
        let t = min(1, elapsed / (duration * 0.85))
        radius = r0 * CGFloat(1 - 0.55 * t)
        disc.setScale(radius / r0)
        discRing.setScale(radius / r0)

        for s in seats where s.alive {
            let f = fighters[s.index]
            if s.isCPU { cpu(s, f, dt) }
            f.dashCool -= dt
            let accel: CGFloat = 620
            f.vel.dx += f.input.dx * accel * fdt
            f.vel.dy += f.input.dy * accel * fdt
            let fr = pow(0.35, fdt)
            f.vel.dx *= fr
            f.vel.dy *= fr
            let sp = hypot(f.vel.dx, f.vel.dy)
            let maxS: CGFloat = 340
            if sp > maxS { f.vel.dx = f.vel.dx / sp * maxS; f.vel.dy = f.vel.dy / sp * maxS }
            f.pos.x += f.vel.dx * fdt
            f.pos.y += f.vel.dy * fdt
            if abs(f.vel.dx) > 8 { f.bear.setFacing(right: f.vel.dx > 0) }
        }
        // collisions
        let alive = seats.filter { $0.alive }
        for i in 0..<alive.count {
            for j in (i + 1)..<max(i + 1, alive.count) {
                collide(alive[i], alive[j])
            }
        }
        for s in seats where s.alive {
            let f = fighters[s.index]
            f.node.position = f.pos
            let d = hypot(f.pos.x - center.x, f.pos.y - center.y)
            if d > radius + bodyR * 0.2 {
                fall(s, f)
            }
        }
        if aliveSeats.count <= 1 {
            finishGame(scores: finalScores())
        }
    }

    private func collide(_ a: Seat, _ b: Seat) {
        let fa = fighters[a.index], fb = fighters[b.index]
        let dx = fb.pos.x - fa.pos.x, dy = fb.pos.y - fa.pos.y
        let d = hypot(dx, dy)
        let minD = bodyR * 2
        guard d < minD, d > 0.001 else { return }
        let nx = dx / d, ny = dy / d
        let push = (minD - d) / 2
        fa.pos.x -= nx * push; fa.pos.y -= ny * push
        fb.pos.x += nx * push; fb.pos.y += ny * push
        let rv = (fb.vel.dx - fa.vel.dx) * nx + (fb.vel.dy - fa.vel.dy) * ny
        if rv < 0 {
            let e: CGFloat = 1.35 // bouncy for fun knock-backs
            let j = -(1 + e) * rv / 2
            fa.vel.dx -= j * nx; fa.vel.dy -= j * ny
            fb.vel.dx += j * nx; fb.vel.dy += j * ny
            if -rv > 120 {
                Sfx.shared.play("hit")
                if !a.isCPU || !b.isCPU { Haptic.tap(.medium) }
                let mid = CGPoint(x: (fa.pos.x + fb.pos.x) / 2, y: (fa.pos.y + fb.pos.y) / 2)
                spark(mid)
                fa.bear.squash()
                fb.bear.squash()
            } else {
                Sfx.shared.play("bounce")
            }
            fa.lastHitBy = b.index; fa.lastHitTime = elapsed
            fb.lastHitBy = a.index; fb.lastHitTime = elapsed
        }
    }

    private func spark(_ p: CGPoint) {
        for _ in 0..<8 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 6, height: 6))
            d.color = .white
            d.colorBlendFactor = 1
            d.blendMode = .add
            d.position = p
            d.zPosition = 40
            world.addChild(d)
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: 20...60)
            d.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: cos(a) * r, y: sin(a) * r, duration: 0.3), SKAction.fadeOut(withDuration: 0.3)]), SKAction.removeFromParent()]))
        }
    }

    private func fall(_ s: Seat, _ f: Fighter) {
        f.outOrder = outCount
        outCount += 1
        s.knockOut("PLATSCH!")
        Sfx.shared.play("miss")
        if !s.isCPU { Haptic.bad() }
        f.node.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 0.2, duration: 0.5), SKAction.fadeOut(withDuration: 0.5), SKAction.rotate(byAngle: 3, duration: 0.5)]),
            SKAction.removeFromParent()
        ]))
        // splash ring
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 1)
        ring.lineWidth = 3
        ring.position = f.pos
        ring.zPosition = 25
        world.addChild(ring)
        ring.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 5, duration: 0.6), SKAction.fadeOut(withDuration: 0.6)]), SKAction.removeFromParent()]))
        for _ in 0..<14 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 7, height: 7))
            d.color = UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 1)
            d.colorBlendFactor = 1
            d.position = f.pos
            d.zPosition = 26
            world.addChild(d)
            let a = CGFloat.random(in: 0..<(2 * .pi))
            d.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: cos(a) * 50, y: sin(a) * 50 + 30, duration: 0.5), SKAction.fadeOut(withDuration: 0.5)]), SKAction.removeFromParent()]))
        }
        // knock-out credit
        if f.lastHitBy >= 0 && elapsed - f.lastHitTime < 2.5 && seats[f.lastHitBy].alive {
            let k = seats[f.lastHitBy]
            addScore(k, 1)
            addStat("hits", 1, seat: k)
            k.banner("K.O.!", color: .yellow, size: 30, duration: 0.6)
        }
        bannerAll("\(s.name.uppercased()) RAUS", color: s.color, size: 26, duration: 0.6)
    }

    private func finalScores() -> [Int] {
        return seats.map { s in
            let f = fighters[s.index]
            if f.outOrder >= 0 { return f.outOrder * 100 + s.score }
            let d = hypot(f.pos.x - center.x, f.pos.y - center.y)
            return n * 100 + Int(max(0, 99 - d / max(1, r0) * 99))
        }
    }

    override func timeUp() {
        finishGame(scores: finalScores())
    }

    // MARK: CPU

    private func cpu(_ s: Seat, _ f: Fighter, _ dt: Double) {
        f.cpuThink -= dt
        if f.cpuThink > 0 { return }
        f.cpuThink = 0.08 + (1 - s.skill) * 0.25
        // pick nearest opponent
        var target: Fighter?
        var bd = CGFloat.greatestFiniteMagnitude
        for o in seats where o.alive && o.index != s.index {
            let fo = fighters[o.index]
            let d = hypot(fo.pos.x - f.pos.x, fo.pos.y - f.pos.y)
            if d < bd { bd = d; target = fo }
        }
        var ax: CGFloat = 0, ay: CGFloat = 0
        if let t = target {
            // aim at a point slightly on the centre side of the target -> push it outwards
            let ox = t.pos.x - center.x, oy = t.pos.y - center.y
            let ol = max(1, hypot(ox, oy))
            let aim = CGPoint(x: t.pos.x - ox / ol * 8, y: t.pos.y - oy / ol * 8)
            ax = aim.x - f.pos.x
            ay = aim.y - f.pos.y
            let l = max(1, hypot(ax, ay))
            ax /= l; ay /= l
        }
        // edge avoidance
        let cx = center.x - f.pos.x, cy = center.y - f.pos.y
        let cd = hypot(cx, cy)
        let danger = cd / max(1, radius)
        if danger > 0.62 {
            let w = CGFloat(0.5 + s.skill) * (danger - 0.55) * 4
            ax += cx / max(1, cd) * w
            ay += cy / max(1, cd) * w
        }
        let l = max(0.001, hypot(ax, ay))
        let strength = CGFloat(0.55 + 0.45 * s.skill)
        let noise = CGFloat(1 - s.skill) * 0.5
        f.input = CGVector(dx: ax / l * strength + CGFloat.random(in: -noise...noise), dy: ay / l * strength + CGFloat.random(in: -noise...noise))
        f.knob.position = CGPoint(x: 0, y: 0)
    }
}
