import SpriteKit

/// Slalom-Dribbling: steer the bear-puck through rows of neon cones. Drag left/right, hit a cone = slow + combo lost.
final class SlalomGame: MiniScene {

    private final class Row {
        let node = SKNode()
        let k: Int
        var gx: CGFloat = 0
        var gl: CGFloat = 0
        var gr: CGFloat = 0
        var y: CGFloat = 0
        var done = false
        var hit = false
        var err: CGFloat = 0
        var cones: [SKSpriteNode] = []
        var beam: SKSpriteNode!
        init(k: Int) { self.k = k }
    }

    private final class Lane {
        let seat: Seat
        let content = SKNode()
        var rows: [Row] = []
        var lines: [SKSpriteNode] = []
        let puck = SKNode()
        var glow: SKSpriteNode!
        var bear: BearNode!
        var px: CGFloat = 0
        var tx: CGFloat = 0
        var grab: CGFloat = 0
        var scroll: CGFloat = 0
        var slow: CGFloat = 1
        var combo = 0
        var nextSpawn = 0
        var trailT: Double = 0
        var cpuDelay: Double = 0
        var comboLabel: SKLabelNode!
        var lastVx: CGFloat = 0
        init(seat: Seat) { self.seat = seat }
    }

    private var lanes: [Lane] = []
    private var gateF: [CGFloat] = []
    private var sc: CGFloat = 1
    private var pr: CGFloat = 15
    private var coneD: CGFloat = 26
    private var gapW: CGFloat = 72
    private var rowSp: CGFloat = 130
    private var fieldW: CGFloat = 370
    private var puckY: CGFloat = 0

    override func setupGame() {
        duration = 45
        let s0 = seats[0]
        sc = s0.w > 300 ? 1.0 : 0.62
        pr = 15 * sc
        coneD = 26 * sc
        gapW = pr * 2 * 2.5
        rowSp = max(110, s0.h * 0.34)
        fieldW = s0.w - 16
        puckY = -s0.h / 2 + 74
        // shared course
        let r = newRand()
        var sign: CGFloat = r.chance(0.5) ? 1 : -1
        for _ in 0..<220 {
            gateF.append(sign * r.range(0.4, 1.0))
            sign = -sign
        }
        for s in seats { buildLane(s) }
    }

    private func coneTexture() -> SKTexture {
        let key = "slalom_cone_\(Int(coneD))"
        let d = coneD * 1.7
        return Gfx.texture(key, size: CGSize(width: d, height: d)) { ctx in
            let c = CGPoint(x: d / 2, y: d / 2)
            let space = CGColorSpaceCreateDeviceRGB()
            let halo = [UIColor(red: 1, green: 0.5, blue: 0.1, alpha: 0.55).cgColor, UIColor(red: 1, green: 0.5, blue: 0.1, alpha: 0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: halo, locations: [0, 1]) {
                ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: d / 2, options: [])
            }
            let r = self.coneD / 2
            ctx.setFillColor(UIColor(red: 1, green: 0.45, blue: 0.05, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * 0.72, y: c.y - r * 0.72, width: r * 1.44, height: r * 1.44))
            ctx.setFillColor(UIColor(red: 1, green: 0.4, blue: 0.0, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * 0.42, y: c.y - r * 0.42, width: r * 0.84, height: r * 0.84))
            ctx.setFillColor(UIColor(red: 0.6, green: 0.15, blue: 0, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * 0.16, y: c.y - r * 0.16, width: r * 0.32, height: r * 0.32))
        }
    }

    private func buildLane(_ s: Seat) {
        let lane = Lane(seat: s)
        s.field.addChild(lane.content)
        // side rails
        for sx in [-1.0, 1.0] {
            let rail = SKSpriteNode(texture: Gfx.rect(3, s.h, s.color), size: CGSize(width: 3, height: s.h))
            rail.position = CGPoint(x: CGFloat(sx) * fieldW / 2, y: 0)
            rail.alpha = 0.55
            rail.zPosition = 1
            lane.content.addChild(rail)
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 26, height: s.h * 1.1))
            g.color = s.color
            g.colorBlendFactor = 1
            g.blendMode = .add
            g.alpha = 0.35
            g.position = rail.position
            g.zPosition = 1
            lane.content.addChild(g)
        }
        // scrolling grid lines
        let n = Int(s.h / 44) + 2
        for _ in 0..<n {
            let l = SKSpriteNode(texture: Gfx.rect(fieldW, 2, .white), size: CGSize(width: fieldW, height: 2))
            l.alpha = 0.07
            l.zPosition = 0
            lane.content.addChild(l)
            lane.lines.append(l)
        }
        // puck + bear
        let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: pr * 5, height: pr * 5))
        glow.color = s.color
        glow.colorBlendFactor = 1
        glow.blendMode = .add
        glow.alpha = 0.8
        lane.glow = glow
        lane.puck.addChild(glow)
        let disc = SKSpriteNode(texture: Gfx.circle(pr, UIColor(white: 0.08, alpha: 1), ring: s.color), size: CGSize(width: pr * 2, height: pr * 2))
        disc.zPosition = 1
        lane.puck.addChild(disc)
        let bear = makeBear(s, height: 40 * sc, faceRight: s.index % 2 == 0)
        bear.position = CGPoint(x: 0, y: -pr * 0.35)
        bear.zPosition = 3
        lane.puck.addChild(bear)
        lane.bear = bear
        lane.puck.position = CGPoint(x: 0, y: puckY)
        lane.puck.zPosition = 30
        lane.content.addChild(lane.puck)

        let cl = MiniScene.label("", size: 13 * max(sc, 0.85), color: UIColor(red: 0.4, green: 1, blue: 0.9, alpha: 1))
        cl.horizontalAlignmentMode = .left
        cl.position = CGPoint(x: -s.w / 2 + 14, y: -s.h / 2 + 14)
        cl.zPosition = 400
        s.node.addChild(cl)
        lane.comboLabel = cl

        if !s.isCPU {
            let hint = MiniScene.label("← WISCHEN →", size: 15 * max(sc, 0.85), color: .white)
            hint.position = CGPoint(x: 0, y: -s.h / 2 + 22)
            hint.zPosition = 420
            s.node.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.5), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
        }
        lanes.append(lane)
        // pre-spawn visible rows
        updateRowsPositions(lane)
        spawnRows(lane)
    }

    private func spawnRows(_ lane: Lane) {
        let top = lane.seat.h / 2 + 60
        while true {
            let y = puckY + 170 + CGFloat(lane.nextSpawn) * rowSp - lane.scroll
            if y > top { break }
            makeRow(lane, k: lane.nextSpawn)
            lane.nextSpawn += 1
        }
    }

    private func makeRow(_ lane: Lane, k: Int) {
        let row = Row(k: k)
        let maxG = fieldW / 2 - gapW / 2 - coneD * 1.3
        row.gx = gateF[k % gateF.count] * maxG
        row.gl = row.gx - gapW / 2
        row.gr = row.gx + gapW / 2
        let tex = coneTexture()
        let sp = coneD * 1.02
        var x = row.gl - coneD / 2
        while x > -fieldW / 2 + coneD * 0.4 {
            row.cones.append(addCone(row, tex, x))
            x -= sp
        }
        x = row.gr + coneD / 2
        while x < fieldW / 2 - coneD * 0.4 {
            row.cones.append(addCone(row, tex, x))
            x += sp
        }
        let beam = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: gapW * 1.5, height: coneD * 2.2))
        beam.color = UIColor(red: 0.3, green: 1, blue: 0.6, alpha: 1)
        beam.colorBlendFactor = 1
        beam.blendMode = .add
        beam.alpha = 0.4
        beam.position = CGPoint(x: row.gx, y: 0)
        beam.zPosition = 2
        row.node.addChild(beam)
        row.beam = beam
        let sk = max(0.1, lane.seat.skill)
        let std = (1 - sk) * gapW * 0.45
        let e = CGFloat(Double.random(in: -1...1) + Double.random(in: -1...1)) * 0.5 * std * 1.6
        let lim = gapW * 0.5 * 1.15
        row.err = max(-lim, min(lim, e))
        row.y = puckY + 170 + CGFloat(k) * rowSp - lane.scroll
        row.node.position = CGPoint(x: 0, y: row.y)
        row.node.zPosition = 10
        lane.content.addChild(row.node)
        lane.rows.append(row)
    }

    private func addCone(_ row: Row, _ tex: SKTexture, _ x: CGFloat) -> SKSpriteNode {
        let c = SKSpriteNode(texture: tex, size: CGSize(width: coneD * 1.7, height: coneD * 1.7))
        c.position = CGPoint(x: x, y: 0)
        row.node.addChild(c)
        return c
    }

    private func updateRowsPositions(_ lane: Lane) {
        let h = lane.seat.h
        for (i, l) in lane.lines.enumerated() {
            let span = CGFloat(lane.lines.count) * 44
            var y = CGFloat(i) * 44 - lane.scroll
            y = y.truncatingRemainder(dividingBy: span)
            if y < 0 { y += span }
            l.position = CGPoint(x: 0, y: y - h / 2 - 22)
        }
    }

    override func gameStarted() {
        for l in lanes { l.bear.startBob(amount: 2, duration: 0.25) }
    }

    // MARK: input

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let l = lanes[seat.index]
        l.grab = l.px - at.x
        l.tx = l.px
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let l = lanes[seat.index]
        l.tx = at.x + l.grab
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        let cdt = CGFloat(dt)
        let maxX = fieldW / 2 - pr - 2
        for l in lanes {
            let s = l.seat
            // speed
            let ramp = CGFloat(min(1.0, elapsed / 40.0))
            let base = (150 + 175 * ramp) * (sc > 0.9 ? 1 : 0.9)
            l.slow = min(1, l.slow + cdt * 0.6)
            let v = base * l.slow
            l.scroll += v * cdt

            // steering
            if s.isCPU {
                let next = l.rows.first(where: { !$0.done })
                var target: CGFloat = 0
                if let r = next { target = r.gx + r.err }
                if l.cpuDelay > 0 {
                    l.cpuDelay -= dt
                } else {
                    l.tx = target
                }
                let maxv = (260 + 560 * CGFloat(s.skill)) * sc
                let d = l.tx - l.px
                l.px += max(-maxv * cdt, min(maxv * cdt, d))
            } else {
                l.px += (l.tx - l.px) * min(1, cdt * 22)
            }
            l.px = max(-maxX, min(maxX, l.px))
            let vx = (l.px - l.lastVx) / max(cdt, 0.001)
            l.lastVx = l.px
            l.puck.position = CGPoint(x: l.px, y: puckY)
            l.bear.zRotation += (max(-0.35, min(0.35, -vx * 0.0006)) - l.bear.zRotation) * min(1, cdt * 12)
            l.glow.alpha = 0.55 + 0.3 * l.slow

            // trail
            l.trailT -= dt
            if l.trailT <= 0 {
                l.trailT = 0.045
                let t = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: pr * 1.1, height: pr * 1.1))
                t.color = s.color
                t.colorBlendFactor = 1
                t.blendMode = .add
                t.alpha = 0.7
                t.position = CGPoint(x: l.px, y: puckY - pr * 0.6)
                t.zPosition = 25
                l.content.addChild(t)
                t.run(SKAction.sequence([
                    SKAction.group([SKAction.moveBy(x: 0, y: -50 * l.slow, duration: 0.35), SKAction.fadeOut(withDuration: 0.35), SKAction.scale(to: 0.2, duration: 0.35)]),
                    SKAction.removeFromParent()
                ]))
            }

            // rows
            updateRowsPositions(l)
            for r in l.rows {
                r.y = puckY + 170 + CGFloat(r.k) * rowSp - l.scroll
                r.node.position.y = r.y
                if r.done { continue }
                let dy = r.y - puckY
                let reach = coneD / 2 + pr * 0.7
                if abs(dy) < reach, !r.hit {
                    if l.px - pr * 0.8 < r.gl || l.px + pr * 0.8 > r.gr {
                        r.hit = true
                        hitCone(l, r)
                    }
                }
                if dy < -reach {
                    r.done = true
                    if !r.hit { passGate(l, r) }
                    l.cpuDelay = (1 - s.skill) * 0.22
                }
            }
            while let f = l.rows.first, f.y < -s.h / 2 - 50 {
                f.node.removeFromParent()
                l.rows.removeFirst()
            }
            spawnRows(l)
        }
    }

    private func hitCone(_ l: Lane, _ r: Row) {
        let s = l.seat
        r.done = true
        l.combo = 0
        l.comboLabel.text = ""
        l.slow = 0.25
        // fly nearest cone away
        var best: SKSpriteNode?
        var bd = CGFloat.greatestFiniteMagnitude
        for c in r.cones where c.alpha > 0.5 {
            let d = abs(c.position.x - l.px)
            if d < bd { bd = d; best = c }
        }
        if let c = best {
            let dir: CGFloat = c.position.x < l.px ? -1 : 1
            c.run(SKAction.group([
                SKAction.moveBy(x: dir * 60, y: 90, duration: 0.5),
                SKAction.rotate(byAngle: dir * 6, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]))
        }
        r.beam.alpha = 0.05
        s.shake(4)
        s.flash(.red, alpha: 0.25, duration: 0.3)
        s.burst(at: CGPoint(x: l.px, y: puckY + pr), color: UIColor(red: 1, green: 0.5, blue: 0.1, alpha: 1), count: 12, speed: 110)
        s.floatText("AUA", at: CGPoint(x: l.px, y: puckY + 40 * sc), color: UIColor(red: 1, green: 0.35, blue: 0.3, alpha: 1), size: 18)
        l.bear.squash()
        l.puck.run(SKAction.sequence([SKAction.moveBy(x: 0, y: -8, duration: 0.05), SKAction.moveBy(x: 0, y: 8, duration: 0.12)]))
        if !s.isCPU {
            Sfx.shared.play("hit")
            Haptic.bad()
        }
    }

    private func passGate(_ l: Lane, _ r: Row) {
        let s = l.seat
        l.combo += 1
        let pts = 1 + (l.combo >= 3 ? min(l.combo - 1, 12) / 3 : 0)
        addScore(s, pts)
        r.beam.removeAllActions()
        r.beam.alpha = 1
        r.beam.run(SKAction.fadeAlpha(to: 0.12, duration: 0.5))
        s.floatText("+\(pts)", at: CGPoint(x: l.px, y: puckY + 36 * sc), color: UIColor(red: 0.4, green: 1, blue: 0.6, alpha: 1), size: pts > 1 ? 22 : 18)
        s.burst(at: CGPoint(x: r.gx, y: puckY), color: UIColor(red: 0.4, green: 1, blue: 0.7, alpha: 1), count: 6, speed: 70)
        if l.combo >= 3 {
            l.comboLabel.text = "KOMBO x\(l.combo)"
            l.comboLabel.removeAllActions()
            l.comboLabel.run(SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.06), SKAction.scale(to: 1, duration: 0.1)]))
        }
        if l.combo > 0 && l.combo % 5 == 0 {
            s.floatText("KOMBO x\(l.combo)!", at: CGPoint(x: 0, y: puckY + 90 * sc), color: UIColor(red: 1, green: 0.9, blue: 0.2, alpha: 1), size: 22)
            s.burst(at: CGPoint(x: l.px, y: puckY + 20), color: UIColor(red: 1, green: 0.9, blue: 0.2, alpha: 1), count: 18, speed: 150)
            l.bear.celebrate()
            if !s.isCPU { Sfx.shared.play("right"); Haptic.good() }
        } else if !s.isCPU {
            Sfx.shared.play("coin")
            Haptic.tap()
        }
    }
}
