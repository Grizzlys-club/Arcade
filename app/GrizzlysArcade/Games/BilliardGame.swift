import SpriteKit

/// Puck-Billard: shared neon table with 4 corner pockets. Every seat owns a colour and shoots a cue puck
/// from its edge strip with a slingshot (drag back, release). Pocketed pucks score for the last shooter
/// whose cue touched them (+1, own colour +2).
final class BilliardGame: MiniScene {
    override class var layout: SeatLayout { return .arena }
    override class var stripThickness: CGFloat { return 90 }

    private final class Body {
        let node = SKNode()
        var pos = CGPoint.zero
        var vel = CGVector.zero
        let r: CGFloat
        let mass: CGFloat
        let owner: Int        // colour owner (coloured pucks), -1 for cue pucks
        let cueSeat: Int      // seat index for cue pucks, -1 otherwise
        var lastHit = -1
        var alive = true
        var inPlay = true     // cue pucks: false while resting at the edge
        var entered = true
        var stopT: Double = 0
        var trailT: Double = 0
        var isCue: Bool { return cueSeat >= 0 }
        init(r: CGFloat, mass: CGFloat, owner: Int, cueSeat: Int) {
            self.r = r
            self.mass = mass
            self.owner = owner
            self.cueSeat = cueSeat
        }
        var active: Bool { return alive && (!isCue || inPlay) }
    }

    private final class SeatState {
        var cue: Body!
        var rest = CGPoint.zero
        var cool: Double = 0
        var respawn: Double = 0
        var touch: UITouch?
        var dragScene = CGPoint.zero
        var dragging = false
        var cpuThink: Double = 1.0
        var band: SKSpriteNode!
        var handle: SKSpriteNode!
        var dots: [SKSpriteNode] = []
        var readyGlow: SKSpriteNode!
        var wasReady = false
    }

    private var bodies: [Body] = []
    private var states: [SeatState] = []
    private var table = CGRect.zero
    private var pockets: [CGPoint] = []
    private let pocketR: CGFloat = 25
    private var puckR: CGFloat = 12
    private var cueR: CGFloat = 14
    private let maxPull: CGFloat = 42
    private let cooldown: Double = 1.5
    private var soundT: Double = 0
    private var bounceT: Double = 0
    private var colouredLeft = 0
    private var ending = false

    // MARK: setup

    override func setupGame() {
        duration = 60
        table = arena.insetBy(dx: 6, dy: 6)
        puckR = n >= 3 ? 11 : 12
        cueR = puckR + 2.5

        // felt
        let feltTex = Gfx.texture("billiard_felt_\(Int(table.width))x\(Int(table.height))", size: table.size, scale: 1.5) { ctx in
            let s = self.table.size
            Gfx.gradientColors(UIColor(red: 0.04, green: 0.17, blue: 0.2, alpha: 1), UIColor(red: 0.02, green: 0.09, blue: 0.14, alpha: 1), in: ctx, size: s)
            ctx.setStrokeColor(UIColor(red: 0.2, green: 1, blue: 0.8, alpha: 0.07).cgColor)
            ctx.setLineWidth(1)
            var x: CGFloat = 0
            while x < s.width {
                ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: s.height)); ctx.strokePath()
                x += 26
            }
            var y: CGFloat = 0
            while y < s.height {
                ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: s.width, y: y)); ctx.strokePath()
                y += 26
            }
            ctx.setStrokeColor(UIColor(red: 0.3, green: 1, blue: 0.9, alpha: 0.18).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: 0, y: s.height / 2)); ctx.addLine(to: CGPoint(x: s.width, y: s.height / 2)); ctx.strokePath()
            ctx.strokeEllipse(in: CGRect(x: s.width / 2 - 40, y: s.height / 2 - 40, width: 80, height: 80))
        }
        let felt = SKSpriteNode(texture: feltTex, size: table.size)
        felt.position = CGPoint(x: table.midX, y: table.midY)
        felt.zPosition = -20
        world.addChild(felt)
        let logo = SKSpriteNode(imageNamed: "logo")
        let d = min(table.width, table.height) * 0.5
        logo.size = CGSize(width: d, height: d)
        logo.position = CGPoint(x: table.midX, y: table.midY)
        logo.alpha = 0.08
        logo.zPosition = -19
        world.addChild(logo)

        let rail = SKShapeNode(rect: table, cornerRadius: 14)
        rail.strokeColor = UIColor(red: 0.3, green: 1, blue: 0.9, alpha: 0.9)
        rail.lineWidth = 4
        rail.glowWidth = 6
        rail.fillColor = .clear
        rail.zPosition = -10
        world.addChild(rail)

        // pockets
        let pin: CGFloat = 5
        pockets = [
            CGPoint(x: table.minX + pin, y: table.minY + pin),
            CGPoint(x: table.maxX - pin, y: table.minY + pin),
            CGPoint(x: table.minX + pin, y: table.maxY - pin),
            CGPoint(x: table.maxX - pin, y: table.maxY - pin)
        ]
        for p in pockets {
            let hole = SKSpriteNode(texture: Gfx.circle(pocketR, UIColor(red: 0.0, green: 0.02, blue: 0.04, alpha: 1), ring: UIColor(red: 1, green: 0.3, blue: 0.85, alpha: 1)), size: CGSize(width: pocketR * 2, height: pocketR * 2))
            hole.position = p
            hole.zPosition = -8
            world.addChild(hole)
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: pocketR * 4.2, height: pocketR * 4.2))
            g.color = UIColor(red: 1, green: 0.3, blue: 0.85, alpha: 1)
            g.colorBlendFactor = 1
            g.blendMode = .add
            g.alpha = 0.55
            g.position = p
            g.zPosition = -9
            world.addChild(g)
            g.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.3, duration: 0.9), SKAction.fadeAlpha(to: 0.6, duration: 0.9)])))
        }

        // coloured pucks in a rack
        let total = n == 2 ? 10 : (n == 3 ? 9 : 8)
        var colours: [Int] = []
        for i in 0..<total { colours.append(i % n) }
        colours.shuffle()
        let sp = puckR * 2 + 1.5
        var pts: [CGPoint] = []
        let rows = 6
        for row in -rows...rows {
            for col in -rows...rows {
                let x = CGFloat(col) * sp + (row % 2 != 0 ? sp / 2 : 0)
                let y = CGFloat(row) * sp * 0.866
                pts.append(CGPoint(x: x, y: y))
            }
        }
        pts.sort { hypot($0.x, $0.y) < hypot($1.x, $1.y) }
        for i in 0..<total {
            let seat = seats[colours[i]]
            let b = Body(r: puckR, mass: 1, owner: seat.index, cueSeat: -1)
            b.pos = CGPoint(x: table.midX + pts[i].x, y: table.midY + pts[i].y)
            buildPuckNode(b, color: seat.color, ringColor: UIColor(white: 1, alpha: 0.9), glowAlpha: 0.5)
            b.node.position = b.pos
            b.node.zPosition = 22
            world.addChild(b.node)
            bodies.append(b)
        }
        colouredLeft = total

        // cue pucks + aim visuals
        for s in seats {
            let st = SeatState()
            let localRest = CGPoint(x: s.w > 300 ? 0 : 24, y: s.h / 2 - 32)
            st.rest = s.toScene(localRest)
            let cue = Body(r: cueR, mass: 1.25, owner: -1, cueSeat: s.index)
            cue.inPlay = false
            cue.entered = false
            cue.pos = st.rest
            buildPuckNode(cue, color: UIColor(white: 0.95, alpha: 1), ringColor: s.color, glowAlpha: 0.7, glowColor: s.color)
            cue.node.position = st.rest
            cue.node.zPosition = 30
            world.addChild(cue.node)
            st.cue = cue
            bodies.append(cue)

            let rg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: cueR * 5, height: cueR * 5))
            rg.color = s.color
            rg.colorBlendFactor = 1
            rg.blendMode = .add
            rg.alpha = 0
            rg.position = st.rest
            rg.zPosition = 28
            world.addChild(rg)
            st.readyGlow = rg

            let band = SKSpriteNode(color: s.color, size: CGSize(width: 4, height: 1))
            band.alpha = 0
            band.zPosition = 29
            world.addChild(band)
            st.band = band
            let handle = SKSpriteNode(texture: Gfx.circle(9, s.color.withAlphaComponent(0.5), ring: .white), size: CGSize(width: 18, height: 18))
            handle.alpha = 0
            handle.zPosition = 29
            world.addChild(handle)
            st.handle = handle
            for _ in 0..<10 {
                let dot = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 6, height: 6))
                dot.color = s.color
                dot.colorBlendFactor = 1
                dot.blendMode = .add
                dot.alpha = 0
                dot.zPosition = 27
                world.addChild(dot)
                st.dots.append(dot)
            }
            st.cpuThink = 1.2 + Double.random(in: 0...1.2) + (1 - s.skill) * 1.2
            states.append(st)

            if !s.isCPU {
                let hint = MiniScene.label("ZIEHEN & LOSLASSEN", size: 11, color: UIColor(white: 1, alpha: 0.6))
                hint.position = CGPoint(x: 0, y: -s.h / 2 + 12)
                hint.zPosition = 410
                s.node.addChild(hint)
                hint.run(SKAction.sequence([SKAction.wait(forDuration: 8), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
            }
        }
    }

    private func buildPuckNode(_ b: Body, color: UIColor, ringColor: UIColor, glowAlpha: CGFloat, glowColor: UIColor? = nil) {
        let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: b.r * 4.2, height: b.r * 4.2))
        g.color = glowColor ?? color
        g.colorBlendFactor = 1
        g.blendMode = .add
        g.alpha = glowAlpha
        g.zPosition = -1
        b.node.addChild(g)
        let body = SKSpriteNode(texture: Gfx.circle(b.r, color, ring: ringColor), size: CGSize(width: b.r * 2, height: b.r * 2))
        b.node.addChild(body)
        let hi = SKSpriteNode(texture: Gfx.circle(b.r * 0.45, UIColor(white: 1, alpha: 0.35), ring: nil), size: CGSize(width: b.r * 0.9, height: b.r * 0.9))
        hi.position = CGPoint(x: -b.r * 0.25, y: b.r * 0.25)
        hi.zPosition = 1
        b.node.addChild(hi)
    }

    // MARK: input

    private func isReady(_ st: SeatState) -> Bool {
        return !st.cue.inPlay && st.cool <= 0 && st.respawn <= 0
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        if st.touch != nil || !isReady(st) { return }
        st.touch = touch
        st.dragging = true
        st.dragScene = seat.toScene(at)
        updateAim(seat, st)
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        guard st.touch === touch else { return }
        st.dragScene = seat.toScene(at)
        updateAim(seat, st)
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        guard st.touch === touch else { return }
        st.dragScene = seat.toScene(at)
        st.touch = nil
        st.dragging = false
        let (dir, frac, valid) = pullInfo(seat, st)
        hideAim(st)
        if valid, isReady(st) {
            fire(seat, st, dir: dir, speed: 260 + frac * 640)
        }
    }

    /// direction (scene), power fraction 0...1, valid
    private func pullInfo(_ seat: Seat, _ st: SeatState) -> (CGVector, CGFloat, Bool) {
        let dx = st.rest.x - st.dragScene.x
        let dy = st.rest.y - st.dragScene.y
        let len = hypot(dx, dy)
        if len < 1 { return (CGVector(dx: 0, dy: 0), 0, false) }
        let dir = CGVector(dx: dx / len, dy: dy / len)
        let inward = seat.dirToScene(CGVector(dx: 0, dy: 1))
        let fwd = dir.dx * inward.dx + dir.dy * inward.dy
        let frac = min(1, len / maxPull)
        return (dir, frac, len >= 10 && fwd > 0.2)
    }

    private func updateAim(_ seat: Seat, _ st: SeatState) {
        let (dir, frac, valid) = pullInfo(seat, st)
        let dx = st.dragScene.x - st.rest.x
        let dy = st.dragScene.y - st.rest.y
        let len = hypot(dx, dy)
        let hl = min(len, maxPull)
        let hp = len > 0.5 ? CGPoint(x: st.rest.x + dx / len * hl, y: st.rest.y + dy / len * hl) : st.rest
        st.handle.position = hp
        st.handle.alpha = 0.9
        st.band.position = CGPoint(x: (hp.x + st.rest.x) / 2, y: (hp.y + st.rest.y) / 2)
        st.band.size = CGSize(width: 4, height: max(1, hl))
        st.band.zRotation = atan2(hp.y - st.rest.y, hp.x - st.rest.x) - .pi / 2
        st.band.alpha = valid ? 0.8 : 0.25
        let count = valid ? 3 + Int(frac * 7) : 0
        for (i, dot) in st.dots.enumerated() {
            if i < count {
                let dd = cueR + 14 + CGFloat(i) * 24
                dot.position = CGPoint(x: st.rest.x + dir.dx * dd, y: st.rest.y + dir.dy * dd)
                dot.alpha = 0.85 - CGFloat(i) * 0.07
            } else {
                dot.alpha = 0
            }
        }
    }

    private func hideAim(_ st: SeatState) {
        st.handle.alpha = 0
        st.band.alpha = 0
        for d in st.dots { d.alpha = 0 }
    }

    private func fire(_ seat: Seat, _ st: SeatState, dir: CGVector, speed: CGFloat) {
        let c = st.cue!
        c.pos = st.rest
        c.vel = CGVector(dx: dir.dx * speed, dy: dir.dy * speed)
        c.inPlay = true
        c.entered = false
        c.stopT = 0
        c.node.removeAllActions()
        c.node.setScale(1)
        c.node.alpha = 1
        c.node.position = c.pos
        st.cool = cooldown
        st.readyGlow.alpha = 0
        Sfx.shared.play(speed > 650 ? "kick" : "tap")
        if !seat.isCPU { Haptic.tap(speed > 650 ? .heavy : .medium) }
        let sq = SKAction.sequence([SKAction.scale(to: 1.25, duration: 0.05), SKAction.scale(to: 1, duration: 0.1)])
        c.node.run(sq)
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        soundT -= dt
        bounceT -= dt
        let fdt = CGFloat(dt)

        // seats: cooldown / respawn / CPU
        for s in seats {
            let st = states[s.index]
            if st.cool > 0 { st.cool -= dt }
            if st.respawn > 0 {
                st.respawn -= dt
                if st.respawn <= 0 { respawnCue(st) }
            }
            if !st.cue.inPlay {
                let ready = isReady(st)
                let cn = st.cue.node
                if st.respawn <= 0 { cn.alpha = ready ? 1 : 0.35 }
                if ready && !st.wasReady {
                    st.readyGlow.removeAllActions()
                    st.readyGlow.alpha = 0.8
                    st.readyGlow.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.25, duration: 0.6), SKAction.fadeAlpha(to: 0.65, duration: 0.6)])), withKey: "pulse")
                    if s.isCPU { st.cpuThink = 0.35 + (1 - s.skill) * 1.6 + Double.random(in: 0...0.7) }
                }
                if !ready && st.wasReady { st.readyGlow.removeAllActions(); st.readyGlow.alpha = 0 }
                st.wasReady = ready
                if s.isCPU && ready {
                    st.cpuThink -= dt
                    if st.cpuThink <= 0 { cpuShoot(s, st) }
                }
            } else {
                st.wasReady = false
            }
        }

        // physics
        let steps = 3
        let sdt = fdt / CGFloat(steps)
        for _ in 0..<steps {
            for b in bodies where b.active {
                b.pos.x += b.vel.dx * sdt
                b.pos.y += b.vel.dy * sdt
            }
            for b in bodies where b.active { walls(b) }
            for b in bodies where b.active && b.entered { checkPockets(b) }
            collisions()
        }
        let fr = pow(0.33, fdt)
        for b in bodies where b.active {
            var vx = b.vel.dx * fr
            var vy = b.vel.dy * fr
            let sp = hypot(vx, vy)
            if sp > 0 {
                let ns = max(0, sp - 22 * fdt)
                vx = vx / sp * ns
                vy = vy / sp * ns
                if ns < 12 { vx = 0; vy = 0 }
            }
            b.vel = CGVector(dx: vx, dy: vy)
            b.node.position = b.pos
            let speed = hypot(vx, vy)
            if speed > 260 {
                b.trailT -= dt
                if b.trailT <= 0 {
                    b.trailT = 0.028
                    spawnTrail(b)
                }
            }
            if b.isCue && b.inPlay {
                if speed == 0 {
                    b.stopT += dt
                    if b.stopT > 0.4 { retireCue(b) }
                } else {
                    b.stopT = 0
                }
            }
        }

        if colouredLeft <= 0 && !ending {
            ending = true
            bannerAll("ALLE VERSENKT!", color: UIColor.yellow, size: 34, duration: 0.7)
            finishGame()
        }
    }

    private func spawnTrail(_ b: Body) {
        let t = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: b.r * 2.8, height: b.r * 2.8))
        if b.isCue {
            t.color = seats[b.cueSeat].color
        } else {
            t.color = seats[b.owner].color
        }
        t.colorBlendFactor = 1
        t.blendMode = .add
        t.alpha = 0.45
        t.position = b.pos
        t.zPosition = 15
        world.addChild(t)
        t.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.3), SKAction.scale(to: 0.3, duration: 0.3)]), SKAction.removeFromParent()]))
    }

    private func walls(_ b: Body) {
        let minX = table.minX + b.r, maxX = table.maxX - b.r
        let minY = table.minY + b.r, maxY = table.maxY - b.r
        if !b.entered {
            if b.isCue {
                if b.pos.x >= minX && b.pos.x <= maxX && b.pos.y >= minY && b.pos.y <= maxY {
                    b.entered = true
                    return
                }
                // keep the shot inside the strip lane until it reaches the table
                let e = seats[b.cueSeat].edge
                if e == .bottom || e == .top {
                    if b.pos.x < minX { b.pos.x = minX; b.vel.dx = abs(b.vel.dx) }
                    if b.pos.x > maxX { b.pos.x = maxX; b.vel.dx = -abs(b.vel.dx) }
                } else {
                    if b.pos.y < minY { b.pos.y = minY; b.vel.dy = abs(b.vel.dy) }
                    if b.pos.y > maxY { b.pos.y = maxY; b.vel.dy = -abs(b.vel.dy) }
                }
            }
            return
        }
        var hit = false
        if b.pos.x < minX { b.pos.x = minX; b.vel.dx = abs(b.vel.dx) * 0.9; hit = true }
        if b.pos.x > maxX { b.pos.x = maxX; b.vel.dx = -abs(b.vel.dx) * 0.9; hit = true }
        if b.pos.y < minY { b.pos.y = minY; b.vel.dy = abs(b.vel.dy) * 0.9; hit = true }
        if b.pos.y > maxY { b.pos.y = maxY; b.vel.dy = -abs(b.vel.dy) * 0.9; hit = true }
        if hit && bounceT <= 0 && hypot(b.vel.dx, b.vel.dy) > 200 {
            bounceT = 0.06
            Sfx.shared.play("bounce")
        }
    }

    private func collisions() {
        let c = bodies.count
        if c < 2 { return }
        for i in 0..<(c - 1) {
            let a = bodies[i]
            if !a.active { continue }
            for j in (i + 1)..<c {
                let b = bodies[j]
                if !b.active { continue }
                let dx = b.pos.x - a.pos.x
                let dy = b.pos.y - a.pos.y
                let minD = a.r + b.r
                if abs(dx) > minD || abs(dy) > minD { continue }
                let d2 = dx * dx + dy * dy
                if d2 >= minD * minD || d2 < 0.0001 { continue }
                let d = sqrt(d2)
                let nx = dx / d, ny = dy / d
                let tm = a.mass + b.mass
                let overlap = minD - d
                a.pos.x -= nx * overlap * (b.mass / tm)
                a.pos.y -= ny * overlap * (b.mass / tm)
                b.pos.x += nx * overlap * (a.mass / tm)
                b.pos.y += ny * overlap * (a.mass / tm)
                let rv = (b.vel.dx - a.vel.dx) * nx + (b.vel.dy - a.vel.dy) * ny
                if rv >= 0 { continue }
                let e: CGFloat = 0.94
                let jimp = -(1 + e) * rv / (1 / a.mass + 1 / b.mass)
                let spA = hypot(a.vel.dx, a.vel.dy)
                let spB = hypot(b.vel.dx, b.vel.dy)
                a.vel.dx -= jimp * nx / a.mass
                a.vel.dy -= jimp * ny / a.mass
                b.vel.dx += jimp * nx / b.mass
                b.vel.dy += jimp * ny / b.mass
                // credit
                if a.isCue && !b.isCue { b.lastHit = a.cueSeat }
                else if b.isCue && !a.isCue { a.lastHit = b.cueSeat }
                else if !a.isCue && !b.isCue {
                    if spA >= spB && a.lastHit >= 0 { b.lastHit = a.lastHit }
                    else if spB > spA && b.lastHit >= 0 { a.lastHit = b.lastHit }
                }
                if -rv > 90 && soundT <= 0 {
                    soundT = 0.05
                    Sfx.shared.play(-rv > 400 ? "hit" : "tap")
                    let p = CGPoint(x: a.pos.x + nx * a.r, y: a.pos.y + ny * a.r)
                    if -rv > 300 { spark(at: p) }
                }
            }
        }
    }

    private func spark(at p: CGPoint) {
        for _ in 0..<4 {
            let s = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 5, height: 5))
            s.color = .white
            s.colorBlendFactor = 1
            s.blendMode = .add
            s.position = p
            s.zPosition = 40
            world.addChild(s)
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: 15...40)
            s.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: cos(a) * r, y: sin(a) * r, duration: 0.25), SKAction.fadeOut(withDuration: 0.25)]), SKAction.removeFromParent()]))
        }
    }

    // MARK: pockets

    private func checkPockets(_ b: Body) {
        for p in pockets {
            if hypot(b.pos.x - p.x, b.pos.y - p.y) < pocketR - 1 {
                pocketed(b, at: p)
                return
            }
        }
    }

    private func pocketed(_ b: Body, at p: CGPoint) {
        let color: UIColor = b.isCue ? seats[b.cueSeat].color : seats[b.owner].color
        pocketBurst(at: p, color: color)
        Sfx.shared.play("pop")
        world.run(SKAction.sequence([SKAction.moveBy(x: 3, y: 0, duration: 0.025), SKAction.moveBy(x: -6, y: 0, duration: 0.04), SKAction.moveBy(x: 3, y: 0, duration: 0.025)]))
        if b.isCue {
            b.vel = .zero
            b.inPlay = false
            b.node.run(SKAction.sequence([SKAction.group([SKAction.move(to: p, duration: 0.12), SKAction.scale(to: 0.1, duration: 0.12)]), SKAction.fadeOut(withDuration: 0.01)]))
            let st = states[b.cueSeat]
            st.respawn = 0.5
            st.cool = max(st.cool, 0.6)
            return
        }
        b.alive = false
        colouredLeft -= 1
        b.vel = .zero
        b.node.run(SKAction.sequence([SKAction.group([SKAction.move(to: p, duration: 0.12), SKAction.scale(to: 0.1, duration: 0.12)]), SKAction.removeFromParent()]))
        if b.lastHit >= 0 {
            let s = seats[b.lastHit]
            let own = b.owner == b.lastHit
            let pts = own ? 2 : 1
            addScore(s, pts)
            addStat("balls", 1, seat: s)
            var lp = s.local(p)
            let lim = s.w / 2 - 70
            lp.x = max(-lim, min(lim, lp.x))
            lp.y = max(-s.h / 2 + 20, min(s.h / 2 + 400, lp.y))
            s.floatText("VERSENKT +\(pts)", at: lp, color: own ? UIColor.yellow : s.color, size: s.w < 250 ? 15 : 19)
            if !s.isCPU { own ? Haptic.good() : Haptic.tap(.medium) }
            Sfx.shared.play(own ? "coin" : "right")
        } else {
            Sfx.shared.play("miss")
        }
    }

    private func pocketBurst(at p: CGPoint, color: UIColor) {
        let ring = SKSpriteNode(texture: Gfx.circle(pocketR, UIColor.clear, ring: color), size: CGSize(width: pocketR * 2, height: pocketR * 2))
        ring.position = p
        ring.zPosition = 38
        ring.blendMode = .add
        world.addChild(ring)
        ring.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 2.4, duration: 0.35), SKAction.fadeOut(withDuration: 0.35)]), SKAction.removeFromParent()]))
        for _ in 0..<16 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 8, height: 8))
            d.color = color
            d.colorBlendFactor = 1
            d.blendMode = .add
            d.position = p
            d.zPosition = 40
            world.addChild(d)
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: 30...110)
            d.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: cos(a) * r, y: sin(a) * r, duration: 0.5), SKAction.fadeOut(withDuration: 0.5), SKAction.scale(to: 0.2, duration: 0.5)]), SKAction.removeFromParent()]))
        }
    }

    // MARK: cue lifecycle

    private func retireCue(_ b: Body) {
        let st = states[b.cueSeat]
        b.inPlay = false
        b.vel = .zero
        b.node.run(SKAction.fadeOut(withDuration: 0.2))
        st.respawn = 0.2
    }

    private func respawnCue(_ st: SeatState) {
        let c = st.cue!
        c.inPlay = false
        c.entered = false
        c.vel = .zero
        c.pos = st.rest
        c.node.removeAllActions()
        c.node.position = st.rest
        c.node.alpha = 0.35
        c.node.setScale(0.1)
        c.node.run(SKAction.scale(to: 1, duration: 0.2))
    }

    // MARK: CPU

    private func cpuShoot(_ s: Seat, _ st: SeatState) {
        let c = st.rest
        let targets = bodies.filter { !$0.isCue && $0.alive }
        if targets.isEmpty { st.cpuThink = 1; return }
        let inward = s.dirToScene(CGVector(dx: 0, dy: 1))
        var cands: [(score: CGFloat, aim: CGPoint, dist: CGFloat)] = []
        for p in targets {
            for k in pockets {
                let vx = k.x - p.pos.x, vy = k.y - p.pos.y
                let len = max(1, hypot(vx, vy))
                let ux = vx / len, uy = vy / len
                let g = CGPoint(x: p.pos.x - ux * (p.r + cueR), y: p.pos.y - uy * (p.r + cueR))
                if !table.insetBy(dx: cueR, dy: cueR).contains(g) { continue }
                let tx = g.x - c.x, ty = g.y - c.y
                let d1 = max(1, hypot(tx, ty))
                let dx = tx / d1, dy = ty / d1
                if dx * inward.dx + dy * inward.dy < 0.25 { continue }
                let cut = dx * ux + dy * uy
                if cut < 0.35 { continue }
                var blocked = false
                for o in targets where o !== p {
                    // distance of o from the segment c -> g
                    let ox = o.pos.x - c.x, oy = o.pos.y - c.y
                    let t = max(0, min(d1, ox * dx + oy * dy))
                    let px = c.x + dx * t, py = c.y + dy * t
                    if hypot(o.pos.x - px, o.pos.y - py) < o.r + cueR + 1 { blocked = true; break }
                }
                var sc = cut * 100 - (d1 + len) * 0.06
                if p.owner == s.index { sc += 30 }
                if blocked { sc -= 70 }
                cands.append((sc, g, d1 + len))
            }
        }
        var aim: CGPoint
        var dist: CGFloat
        if cands.isEmpty {
            let p = targets.min { hypot($0.pos.x - c.x, $0.pos.y - c.y) < hypot($1.pos.x - c.x, $1.pos.y - c.y) }!
            aim = p.pos
            dist = hypot(p.pos.x - c.x, p.pos.y - c.y) + 200
        } else {
            cands.sort { $0.score > $1.score }
            let pickTop = Double.random(in: 0..<1) < 0.35 + s.skill * 0.6
            let idx = pickTop ? 0 : Int.random(in: 0..<min(3, cands.count))
            aim = cands[idx].aim
            dist = cands[idx].dist
        }
        let ang = atan2(aim.y - c.y, aim.x - c.x)
        let err = CGFloat(Double.random(in: -1...1) * (1 - s.skill) * 0.24 + Double.random(in: -0.012...0.012))
        let a2 = ang + err
        var dir = CGVector(dx: cos(a2), dy: sin(a2))
        // always point into the table
        if dir.dx * inward.dx + dir.dy * inward.dy < 0.2 { dir = inward }
        var speed = dist * 1.25 + 220
        speed *= CGFloat(1 + Double.random(in: -1...1) * (1 - s.skill) * 0.25)
        speed = max(300, min(900, speed))
        fire(s, st, dir: dir, speed: speed)
        st.cpuThink = 1
    }

    override func timeUp() {
        finishGame()
    }
}
