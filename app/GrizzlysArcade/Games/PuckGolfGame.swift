import SpriteKit

/// Puck-Golf: drag back from the puck (slingshot) and sink it in as few strokes as possible.
final class PuckGolfGame: MiniScene {

    /// Course in normalised coordinates (0...1 over the play rect)
    fileprivate struct Course {
        let start: CGPoint
        let hole: CGPoint
        let walls: [CGRect]
    }

    private static let courses: [Course] = [
        Course(start: CGPoint(x: 0.5, y: 0.12), hole: CGPoint(x: 0.5, y: 0.85),
               walls: [CGRect(x: 0.3, y: 0.46, width: 0.4, height: 0.05)]),
        Course(start: CGPoint(x: 0.2, y: 0.12), hole: CGPoint(x: 0.8, y: 0.86),
               walls: [CGRect(x: 0.0, y: 0.38, width: 0.62, height: 0.05), CGRect(x: 0.38, y: 0.64, width: 0.62, height: 0.05)]),
        Course(start: CGPoint(x: 0.5, y: 0.1), hole: CGPoint(x: 0.5, y: 0.86),
               walls: [CGRect(x: 0.1, y: 0.42, width: 0.3, height: 0.05), CGRect(x: 0.6, y: 0.42, width: 0.3, height: 0.05), CGRect(x: 0.44, y: 0.66, width: 0.12, height: 0.12)]),
        Course(start: CGPoint(x: 0.8, y: 0.12), hole: CGPoint(x: 0.18, y: 0.82),
               walls: [CGRect(x: 0.35, y: 0.25, width: 0.06, height: 0.45), CGRect(x: 0.0, y: 0.6, width: 0.25, height: 0.05), CGRect(x: 0.6, y: 0.7, width: 0.4, height: 0.05)]),
        Course(start: CGPoint(x: 0.5, y: 0.1), hole: CGPoint(x: 0.5, y: 0.6),
               walls: [CGRect(x: 0.25, y: 0.52, width: 0.05, height: 0.2), CGRect(x: 0.7, y: 0.52, width: 0.05, height: 0.2), CGRect(x: 0.25, y: 0.72, width: 0.5, height: 0.05), CGRect(x: 0.0, y: 0.32, width: 0.4, height: 0.04)]),
        Course(start: CGPoint(x: 0.15, y: 0.1), hole: CGPoint(x: 0.85, y: 0.5),
               walls: [CGRect(x: 0.55, y: 0.0, width: 0.05, height: 0.42), CGRect(x: 0.55, y: 0.58, width: 0.05, height: 0.42), CGRect(x: 0.2, y: 0.55, width: 0.2, height: 0.05)]),
        Course(start: CGPoint(x: 0.5, y: 0.1), hole: CGPoint(x: 0.8, y: 0.85),
               walls: [CGRect(x: 0.2, y: 0.3, width: 0.12, height: 0.12), CGRect(x: 0.62, y: 0.3, width: 0.12, height: 0.12), CGRect(x: 0.42, y: 0.55, width: 0.12, height: 0.12), CGRect(x: 0.6, y: 0.72, width: 0.05, height: 0.28)])
    ]

    fileprivate final class State {
        var play = CGRect.zero
        var courseIndex = 0
        var walls: [CGRect] = []
        var hole = CGPoint.zero
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var strokes = 0
        var dragging = false
        var dragPoint = CGPoint.zero
        var sinking = false
        var moving: Bool { return hypot(vel.dx, vel.dy) > 0 }
        var cpuWait = 1.0
        let courseNode = SKNode()
        let puck = SKSpriteNode()
        let aim = SKNode()
        var aimDots: [SKSpriteNode] = []
        var strokeLabel = SKLabelNode()
        var holeLabel = SKLabelNode()
        var holesDone = 0
    }

    private var st: [State] = []
    private let puckR: CGFloat = 9
    private let holeR: CGFloat = 13

    private static var puckTex: SKTexture {
        return Gfx.texture("golf_puck", size: CGSize(width: 40, height: 40)) { ctx in
            ctx.setFillColor(UIColor(white: 0.06, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 2, y: 2, width: 36, height: 36))
            ctx.setStrokeColor(Theme.uiOrange.cgColor)
            ctx.setLineWidth(4)
            ctx.strokeEllipse(in: CGRect(x: 4, y: 4, width: 32, height: 32))
            ctx.setFillColor(UIColor(white: 1, alpha: 0.35).cgColor)
            ctx.fillEllipse(in: CGRect(x: 11, y: 9, width: 12, height: 7))
        }
    }

    private static var holeTex: SKTexture {
        return Gfx.texture("golf_hole", size: CGSize(width: 60, height: 60)) { ctx in
            ctx.setFillColor(UIColor(white: 0, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 6, width: 48, height: 48))
            ctx.setStrokeColor(UIColor(red: 0.3, green: 1, blue: 0.5, alpha: 1).cgColor)
            ctx.setLineWidth(4)
            ctx.strokeEllipse(in: CGRect(x: 4, y: 4, width: 52, height: 52))
        }
    }

    override func setupGame() {
        duration = 60
        st = []
        for s in seats {
            let g = State()
            g.play = CGRect(x: -s.w / 2 + 10, y: -s.h / 2 + 10, width: s.w - 20, height: s.h - 50)
            // floor
            let floor = SKSpriteNode(texture: Gfx.pill(g.play.width + 8, g.play.height + 8, fill: UIColor(red: 0.08, green: 0.22, blue: 0.16, alpha: 0.9), border: UIColor(red: 0.3, green: 1, blue: 0.5, alpha: 0.8), corner: 14), size: CGSize(width: g.play.width + 8, height: g.play.height + 8))
            floor.position = CGPoint(x: g.play.midX, y: g.play.midY)
            floor.zPosition = -5
            s.field.addChild(floor)
            // floor stripes
            var y = g.play.minY + 30
            while y < g.play.maxY {
                let line = SKSpriteNode(color: UIColor(white: 1, alpha: 0.04), size: CGSize(width: g.play.width, height: 14))
                line.position = CGPoint(x: g.play.midX, y: y)
                line.zPosition = -4
                s.field.addChild(line)
                y += 44
            }
            g.courseNode.zPosition = 1
            s.field.addChild(g.courseNode)
            g.puck.texture = PuckGolfGame.puckTex
            g.puck.size = CGSize(width: puckR * 2 + 2, height: puckR * 2 + 2)
            g.puck.zPosition = 10
            s.field.addChild(g.puck)
            g.aim.zPosition = 9
            s.field.addChild(g.aim)
            for i in 0..<9 {
                let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 7, height: 7))
                d.color = s.color
                d.colorBlendFactor = 1
                d.alpha = 1 - CGFloat(i) * 0.09
                g.aim.addChild(d)
                g.aimDots.append(d)
            }
            g.aim.isHidden = true
            g.strokeLabel = label("SCHLÄGE 0", size: 12, color: UIColor(white: 1, alpha: 0.75))
            g.strokeLabel.horizontalAlignmentMode = .left
            g.strokeLabel.position = CGPoint(x: -s.w / 2 + 14, y: s.h / 2 - 34)
            g.strokeLabel.zPosition = 20
            s.node.addChild(g.strokeLabel)
            g.holeLabel = label("LOCH 1", size: 12, color: UIColor(red: 0.3, green: 1, blue: 0.5, alpha: 1))
            g.holeLabel.horizontalAlignmentMode = .right
            g.holeLabel.position = CGPoint(x: s.w / 2 - 14, y: s.h / 2 - 34)
            g.holeLabel.zPosition = 20
            s.node.addChild(g.holeLabel)
            st.append(g)
            loadCourse(s, 0)
            let hint = label("ZIEHEN & LOSLASSEN", size: min(16, s.w * 0.075), color: .white)
            hint.position = CGPoint(x: 0, y: -s.h / 2 + 70)
            hint.zPosition = 30
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 5.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private func p(_ g: State, _ u: CGPoint) -> CGPoint {
        return CGPoint(x: g.play.minX + u.x * g.play.width, y: g.play.minY + u.y * g.play.height)
    }

    private func loadCourse(_ s: Seat, _ idx: Int) {
        let g = st[s.index]
        g.courseIndex = idx
        let c = PuckGolfGame.courses[idx % PuckGolfGame.courses.count]
        g.courseNode.removeAllChildren()
        g.walls = c.walls.map { r in
            CGRect(x: g.play.minX + r.minX * g.play.width, y: g.play.minY + r.minY * g.play.height, width: max(10, r.width * g.play.width), height: max(10, r.height * g.play.height))
        }
        for r in g.walls {
            let wn = SKSpriteNode(texture: Gfx.pill(r.width, r.height, fill: UIColor(red: 0.18, green: 0.18, blue: 0.3, alpha: 1), border: s.color.withAlphaComponent(0.9), corner: 4), size: r.size)
            wn.position = CGPoint(x: r.midX, y: r.midY)
            g.courseNode.addChild(wn)
        }
        g.hole = p(g, c.hole)
        let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 70, height: 70))
        glow.color = UIColor(red: 0.3, green: 1, blue: 0.5, alpha: 1)
        glow.colorBlendFactor = 1
        glow.blendMode = .add
        glow.alpha = 0.5
        glow.position = g.hole
        g.courseNode.addChild(glow)
        glow.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.25, duration: 0.6), SKAction.fadeAlpha(to: 0.55, duration: 0.6)])))
        let hole = SKSpriteNode(texture: PuckGolfGame.holeTex, size: CGSize(width: holeR * 2 + 4, height: holeR * 2 + 4))
        hole.position = g.hole
        g.courseNode.addChild(hole)
        // flag
        let pole = SKSpriteNode(color: .white, size: CGSize(width: 2, height: 26))
        pole.anchorPoint = CGPoint(x: 0.5, y: 0)
        pole.position = CGPoint(x: g.hole.x + 2, y: g.hole.y)
        g.courseNode.addChild(pole)
        let flag = SKSpriteNode(color: s.color, size: CGSize(width: 14, height: 9))
        flag.anchorPoint = CGPoint(x: 0, y: 0.5)
        flag.position = CGPoint(x: g.hole.x + 3, y: g.hole.y + 21)
        g.courseNode.addChild(flag)
        flag.run(SKAction.repeatForever(SKAction.sequence([SKAction.scaleX(to: 0.7, duration: 0.3), SKAction.scaleX(to: 1, duration: 0.3)])))
        g.pos = p(g, c.start)
        g.vel = .zero
        g.strokes = 0
        g.sinking = false
        g.dragging = false
        g.aim.isHidden = true
        g.cpuWait = 0.9 + (1 - s.skill) * 0.8
        g.puck.position = g.pos
        g.puck.setScale(0.1)
        g.puck.alpha = 1
        g.puck.run(SKAction.scale(to: 1, duration: 0.25))
        g.strokeLabel.text = "SCHLÄGE 0"
        g.holeLabel.text = "LOCH \(g.holesDone + 1)"
    }

    // MARK: physics (shared by real play and CPU simulation)

    /// Returns true when the puck dropped into the hole.
    private func step(_ pos: inout CGPoint, _ vel: inout CGVector, dt: CGFloat, g: State) -> Bool {
        // hole attraction / sinking
        let dx = g.hole.x - pos.x
        let dy = g.hole.y - pos.y
        let d = hypot(dx, dy)
        let speed = hypot(vel.dx, vel.dy)
        if d < holeR && speed < 330 { return true }
        if d < holeR * 2.2 && d > 0.1 {
            let pull: CGFloat = 900 * (1 - d / (holeR * 2.2))
            vel.dx += dx / d * pull * dt
            vel.dy += dy / d * pull * dt
        }
        // friction
        let k = max(0, 1 - 1.25 * dt)
        vel.dx *= k
        vel.dy *= k
        let sp = hypot(vel.dx, vel.dy)
        if sp < 14 { vel = .zero; return false }
        if sp > 0 {
            // constant rolling resistance
            let dec = min(sp, 40 * dt)
            vel.dx -= vel.dx / sp * dec
            vel.dy -= vel.dy / sp * dec
        }
        pos.x += vel.dx * dt
        pos.y += vel.dy * dt
        // borders
        let b = g.play
        if pos.x < b.minX + puckR { pos.x = b.minX + puckR; vel.dx = abs(vel.dx) * 0.8 }
        if pos.x > b.maxX - puckR { pos.x = b.maxX - puckR; vel.dx = -abs(vel.dx) * 0.8 }
        if pos.y < b.minY + puckR { pos.y = b.minY + puckR; vel.dy = abs(vel.dy) * 0.8 }
        if pos.y > b.maxY - puckR { pos.y = b.maxY - puckR; vel.dy = -abs(vel.dy) * 0.8 }
        // walls
        for r in g.walls {
            let cx = max(r.minX, min(pos.x, r.maxX))
            let cy = max(r.minY, min(pos.y, r.maxY))
            let ex = pos.x - cx
            let ey = pos.y - cy
            let dist = hypot(ex, ey)
            if dist < puckR {
                var nx: CGFloat = 0
                var ny: CGFloat = 0
                if dist > 0.001 {
                    nx = ex / dist
                    ny = ey / dist
                } else {
                    // centre inside the rect: push out along smallest axis
                    let l = pos.x - r.minX, rr = r.maxX - pos.x, bb = pos.y - r.minY, t = r.maxY - pos.y
                    let m = min(l, rr, bb, t)
                    if m == l { nx = -1 } else if m == rr { nx = 1 } else if m == bb { ny = -1 } else { ny = 1 }
                }
                pos.x = cx + nx * puckR
                pos.y = cy + ny * puckR
                let vn = vel.dx * nx + vel.dy * ny
                if vn < 0 {
                    vel.dx -= 1.8 * vn * nx
                    vel.dy -= 1.8 * vn * ny
                }
            }
        }
        return false
    }

    private func simulate(_ g: State, from: CGPoint, vel v0: CGVector) -> (CGFloat, Bool) {
        var pos = from
        var vel = v0
        var best = CGFloat.greatestFiniteMagnitude
        for _ in 0..<300 {
            if step(&pos, &vel, dt: 1.0 / 60.0, g: g) { return (0, true) }
            best = min(best, hypot(pos.x - g.hole.x, pos.y - g.hole.y) * 0.3 + 0)
            if vel == .zero { break }
        }
        return (hypot(pos.x - g.hole.x, pos.y - g.hole.y) + best * 0.2, false)
    }

    // MARK: shooting

    private func shoot(_ s: Seat, _ v: CGVector) {
        let g = st[s.index]
        g.vel = v
        g.strokes += 1
        g.strokeLabel.text = "SCHLÄGE \(g.strokes)"
        Sfx.shared.play("kick")
        if !s.isCPU { Haptic.tap() }
        g.puck.run(SKAction.sequence([SKAction.scale(to: 1.25, duration: 0.05), SKAction.scale(to: 1, duration: 0.1)]))
    }

    private func sink(_ s: Seat) {
        let g = st[s.index]
        g.sinking = true
        g.vel = .zero
        let pts = max(1, 6 - g.strokes)
        addScore(s, pts)
        addStat("goals", 1, seat: s)
        g.holesDone += 1
        g.puck.run(SKAction.group([SKAction.move(to: g.hole, duration: 0.15), SKAction.scale(to: 0.2, duration: 0.25), SKAction.fadeOut(withDuration: 0.25)]))
        s.burst(at: g.hole, color: UIColor(red: 0.3, green: 1, blue: 0.5, alpha: 1), count: 16, speed: 110)
        s.floatText(g.strokes == 1 ? "HOLE IN ONE! +\(pts)" : "+\(pts)", at: CGPoint(x: g.hole.x, y: g.hole.y + 20), color: g.strokes == 1 ? .yellow : UIColor(red: 0.3, green: 1, blue: 0.5, alpha: 1), size: g.strokes == 1 ? 18 : 24)
        Sfx.shared.play(g.strokes == 1 ? "fanfare" : "goal")
        if !s.isCPU { Haptic.good() }
        run(SKAction.sequence([SKAction.wait(forDuration: 0.9), SKAction.run { [weak self] in
            guard let self = self, self.phase == .playing else { return }
            self.loadCourse(s, g.courseIndex + 1)
        }]))
    }

    private func skipHole(_ s: Seat) {
        let g = st[s.index]
        g.sinking = true
        s.floatText("ZU VIELE SCHLÄGE", at: g.pos, color: UIColor(white: 1, alpha: 0.8), size: 14)
        Sfx.shared.play("miss")
        run(SKAction.sequence([SKAction.wait(forDuration: 0.8), SKAction.run { [weak self] in
            guard let self = self, self.phase == .playing else { return }
            self.loadCourse(s, g.courseIndex + 1)
        }]))
    }

    // MARK: loop

    override func gameUpdate(_ dt: Double) {
        let d = CGFloat(dt)
        for s in seats {
            let g = st[s.index]
            if g.sinking { continue }
            if g.moving {
                var sunk = false
                for _ in 0..<2 {
                    if step(&g.pos, &g.vel, dt: d / 2, g: g) { sunk = true; break }
                }
                g.puck.position = g.pos
                g.puck.zRotation += hypot(g.vel.dx, g.vel.dy) * d * 0.02
                if sunk { sink(s); continue }
                if !g.moving && g.strokes >= 8 { skipHole(s) }
            } else if s.isCPU {
                g.cpuWait -= dt
                if g.cpuWait <= 0 {
                    cpuShot(s)
                }
            }
        }
    }

    private func cpuShot(_ s: Seat) {
        let g = st[s.index]
        var bestV = CGVector(dx: 0, dy: 300)
        var bestScore = CGFloat.greatestFiniteMagnitude
        let base = atan2(g.hole.y - g.pos.y, g.hole.x - g.pos.x)
        for i in 0..<28 {
            let a = base + CGFloat(i) / 28 * 2 * .pi
            for pw in [CGFloat(330), 520, 720, 900] {
                let v = CGVector(dx: cos(a) * pw, dy: sin(a) * pw)
                let (score, sunk) = simulate(g, from: g.pos, vel: v)
                let sc = sunk ? -pw * 0.01 : score
                if sc < bestScore { bestScore = sc; bestV = v }
            }
        }
        // human-like error
        let err = CGFloat((1 - s.skill) * 0.32)
        let a = atan2(bestV.dy, bestV.dx) + CGFloat.random(in: -err...err)
        let pw = hypot(bestV.dx, bestV.dy) * CGFloat.random(in: (1 - err * 0.6)...(1 + err * 0.6))
        let v = CGVector(dx: cos(a) * pw, dy: sin(a) * pw)
        // show the aim briefly
        showAim(g, CGVector(dx: -v.dx / 7.5, dy: -v.dy / 7.5))
        g.aim.run(SKAction.sequence([SKAction.wait(forDuration: 0.25), SKAction.hide()]))
        run(SKAction.sequence([SKAction.wait(forDuration: 0.25), SKAction.run { [weak self] in
            guard let self = self, self.phase == .playing, !g.sinking else { return }
            self.shoot(s, v)
        }]))
        g.cpuWait = 99
        run(SKAction.sequence([SKAction.wait(forDuration: 0.3), SKAction.run { g.cpuWait = 0.8 + (1 - s.skill) * 0.9 }]))
    }

    private func showAim(_ g: State, _ pull: CGVector) {
        g.aim.isHidden = false
        let len = hypot(pull.dx, pull.dy)
        if len < 1 { g.aim.isHidden = true; return }
        let dir = CGVector(dx: -pull.dx / len, dy: -pull.dy / len)
        for (i, dot) in g.aimDots.enumerated() {
            let t = CGFloat(i + 1) / CGFloat(g.aimDots.count)
            let dd = len * 1.6 * t
            dot.position = CGPoint(x: g.pos.x + dir.dx * dd, y: g.pos.y + dir.dy * dd)
            dot.setScale(1 + len / 110 * 0.5)
        }
    }

    private func pullVector(_ g: State, _ at: CGPoint) -> CGVector {
        var v = CGVector(dx: at.x - g.pos.x, dy: at.y - g.pos.y)
        let l = hypot(v.dx, v.dy)
        let maxL: CGFloat = 115
        if l > maxL { v.dx *= maxL / l; v.dy *= maxL / l }
        return v
    }

    // MARK: touches

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        if g.sinking || g.moving { return }
        g.dragging = true
        g.dragPoint = at
        showAim(g, pullVector(g, at))
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        guard g.dragging else { return }
        g.dragPoint = at
        showAim(g, pullVector(g, at))
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        guard g.dragging else { return }
        g.dragging = false
        g.aim.isHidden = true
        if g.sinking || g.moving { return }
        let v = pullVector(g, at)
        if hypot(v.dx, v.dy) < 12 { return }
        shoot(seat, CGVector(dx: -v.dx * 7.8, dy: -v.dy * 7.8))
    }
}
