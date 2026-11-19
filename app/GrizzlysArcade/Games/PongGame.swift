import SpriteKit
import UIKit

/// Puck-Pong: 2-4 players guard one edge of a shared neon court with a paddle. Lose a ball = lose a life.
final class PongGame: MiniScene {
    override class var layout: SeatLayout { return .arena }
    override class var stripThickness: CGFloat { return 66 }

    // MARK: types

    private final class PPaddle {
        var edge: SeatEdge = .bottom
        var nin = CGVector(dx: 0, dy: 1)       // inward normal (scene)
        var horizontal = true                   // goal line runs along x
        var line = CGPoint.zero                 // centre of the goal line
        var latMin: CGFloat = 0
        var latMax: CGFloat = 0
        var u: CGFloat = 0
        var target: CGFloat = 0
        var vel: CGFloat = 0
        var len: CGFloat = 90
        var lives = 3
        var saves = 0
        var outOrder = -1
        var node = SKNode()
        var bar: SKSpriteNode!
        var glow: SKSpriteNode!
        var bear: BearNode!
        var hearts: [SKLabelNode] = []
        var think: Double = 0
        var aimOff: CGFloat = 0
        var wasApproaching = false
        var touch: UITouch?
        var running = false
    }

    private final class PBall {
        let node = SKNode()
        var body: SKSpriteNode!
        var glow: SKSpriteNode!
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var spin: CGFloat = 0
        var speed: CGFloat = 250
        var active = false
        var timer: Double = 0.5
        var last = -1
        var trail: [SKSpriteNode] = []
        var trailAge: [CGFloat] = []
        var trailIdx = 0
        var trailT: Double = 0
    }

    // MARK: state

    private var paddles: [PPaddle] = []
    private var ballList: [PBall] = []
    private var F = CGRect.zero
    private let ballR: CGFloat = 9
    private let padT: CGFloat = 10
    private let padD: CGFloat = 22
    private var edgeNodes: [SeatEdge: SKSpriteNode] = [:]
    private var edgeSeat: [SeatEdge: Int] = [:]
    private var outCount = 0
    private var secondBallDone = false
    private var suddenDeath = false
    private var sdFactor: CGFloat = 1
    private var humanOutTimer: Double = 0
    private var bounceCool: Double = 0
    private let baseSpeed: CGFloat = 250
    private let capSpeed: CGFloat = 620

    private let edges: [SeatEdge] = [.bottom, .top, .left, .right]
    private func ninOf(_ e: SeatEdge) -> CGVector {
        switch e {
        case .bottom: return CGVector(dx: 0, dy: 1)
        case .top: return CGVector(dx: 0, dy: -1)
        case .left: return CGVector(dx: 1, dy: 0)
        case .right: return CGVector(dx: -1, dy: 0)
        }
    }
    private func perp(_ e: SeatEdge, _ p: CGPoint) -> CGFloat {
        switch e {
        case .bottom: return p.y - F.minY
        case .top: return F.maxY - p.y
        case .left: return p.x - F.minX
        case .right: return F.maxX - p.x
        }
    }

    // MARK: setup

    override func setupGame() {
        duration = 75
        F = arena.insetBy(dx: 3, dy: 3)

        // court
        let tex = Gfx.texture("pong_court_\(Int(F.width))x\(Int(F.height))", size: F.size, scale: 1.5) { ctx in
            let s = self.F.size
            Gfx.gradientColors(UIColor(red: 0.04, green: 0.09, blue: 0.1, alpha: 1), UIColor(red: 0.02, green: 0.04, blue: 0.07, alpha: 1), in: ctx, size: s)
            ctx.setStrokeColor(UIColor(red: 0.4, green: 1, blue: 0.6, alpha: 0.07).cgColor)
            ctx.setLineWidth(1)
            var x: CGFloat = 0
            while x <= s.width { ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: s.height)); x += 32 }
            var y: CGFloat = 0
            while y <= s.height { ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: s.width, y: y)); y += 32 }
            ctx.strokePath()
            ctx.setStrokeColor(UIColor(red: 0.5, green: 1, blue: 0.7, alpha: 0.28).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: s.width / 2 - 50, y: s.height / 2 - 50, width: 100, height: 100))
            ctx.setLineDash(phase: 0, lengths: [8, 8])
            ctx.move(to: CGPoint(x: 0, y: s.height / 2))
            ctx.addLine(to: CGPoint(x: s.width, y: s.height / 2))
            ctx.move(to: CGPoint(x: s.width / 2, y: 0))
            ctx.addLine(to: CGPoint(x: s.width / 2, y: s.height))
            ctx.strokePath()
        }
        let court = SKSpriteNode(texture: tex, size: F.size)
        court.position = CGPoint(x: F.midX, y: F.midY)
        court.zPosition = -20
        world.addChild(court)
        let logo = SKSpriteNode(imageNamed: "logo")
        let ld = min(F.width, F.height) * 0.5
        logo.size = CGSize(width: ld, height: ld)
        logo.position = CGPoint(x: F.midX, y: F.midY)
        logo.alpha = 0.08
        logo.zPosition = -19
        world.addChild(logo)

        // edge lines (goal or wall)
        for s in seats { edgeSeat[s.edge] = s.index }
        for e in edges {
            let horiz = (e == .bottom || e == .top)
            let sz = horiz ? CGSize(width: F.width, height: 5) : CGSize(width: 5, height: F.height)
            let col: UIColor = edgeSeat[e].map { seats[$0].color } ?? UIColor(white: 0.85, alpha: 1)
            let node = SKSpriteNode(texture: Gfx.pill(sz.width, sz.height, fill: col, border: nil, corner: 2.5, gloss: false), size: sz)
            switch e {
            case .bottom: node.position = CGPoint(x: F.midX, y: F.minY)
            case .top: node.position = CGPoint(x: F.midX, y: F.maxY)
            case .left: node.position = CGPoint(x: F.minX, y: F.midY)
            case .right: node.position = CGPoint(x: F.maxX, y: F.midY)
            }
            node.zPosition = -8
            node.alpha = edgeSeat[e] == nil ? 0.6 : 1
            world.addChild(node)
            let gl = SKSpriteNode(texture: Gfx.glow, size: horiz ? CGSize(width: sz.width * 1.05, height: 46) : CGSize(width: 46, height: sz.height * 1.05))
            gl.color = col
            gl.colorBlendFactor = 1
            gl.blendMode = .add
            gl.alpha = edgeSeat[e] == nil ? 0.25 : 0.5
            gl.name = "glow"
            node.addChild(gl)
            edgeNodes[e] = node
        }

        // paddles
        for s in seats {
            let p = PPaddle()
            p.edge = s.edge
            p.nin = ninOf(s.edge)
            p.horizontal = (s.edge == .bottom || s.edge == .top)
            switch s.edge {
            case .bottom: p.line = CGPoint(x: F.midX, y: F.minY)
            case .top: p.line = CGPoint(x: F.midX, y: F.maxY)
            case .left: p.line = CGPoint(x: F.minX, y: F.midY)
            case .right: p.line = CGPoint(x: F.maxX, y: F.midY)
            }
            p.latMin = p.horizontal ? F.minX : F.minY
            p.latMax = p.horizontal ? F.maxX : F.maxY
            let edgeLen = p.latMax - p.latMin
            p.len = p.horizontal ? min(104, edgeLen * 0.28) : min(92, edgeLen * 0.15)
            p.u = (p.latMin + p.latMax) / 2
            p.target = p.u

            let node = p.node
            node.zRotation = s.rotation
            let handle = SKSpriteNode(color: UIColor(white: 0.9, alpha: 1), size: CGSize(width: 5, height: padD + 12 - padT / 2))
            handle.position = CGPoint(x: 0, y: -(padD + 12 + padT / 2) / 2 + 0)
            handle.zPosition = -1
            node.addChild(handle)
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: p.len + 40, height: padT + 40))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.6
            node.addChild(glow)
            p.glow = glow
            let bar = SKSpriteNode(texture: Gfx.pill(p.len, padT, fill: s.color, border: .white, corner: 5, gloss: false), size: CGSize(width: p.len, height: padT))
            bar.zPosition = 1
            node.addChild(bar)
            p.bar = bar
            node.zPosition = 30
            world.addChild(node)

            let bearH: CGFloat = p.horizontal ? 36 : 28
            let bear = makeBear(s, height: bearH, faceRight: s.index % 2 == 0)
            bear.zRotation = s.rotation
            bear.zPosition = 28
            world.addChild(bear)
            p.bear = bear
            // feet position computed in place()
            for i in 0..<3 {
                let h = MiniScene.label("♥", size: 17, color: s.color)
                h.position = CGPoint(x: -s.w / 2 + 20 + CGFloat(i) * 19, y: -s.h / 2 + 13)
                h.zPosition = 410
                s.node.addChild(h)
                p.hearts.append(h)
            }
            if !s.isCPU {
                let hint = MiniScene.label("← WISCHEN →", size: 12, color: UIColor(white: 1, alpha: 0.7))
                hint.position = CGPoint(x: 38, y: -s.h / 2 + 13)
                hint.zPosition = 410
                s.node.addChild(hint)
                hint.run(SKAction.sequence([SKAction.wait(forDuration: 6), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
            }
            paddles.append(p)
            place(p)
        }

        // balls
        for _ in 0..<2 { ballList.append(makeBall()) }
        ballList[0].timer = 0.3
        ballList[1].timer = 9999
    }

    private func makeBall() -> PBall {
        let b = PBall()
        let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: ballR * 5, height: ballR * 5))
        g.color = .white
        g.colorBlendFactor = 1
        g.blendMode = .add
        g.alpha = 0.7
        b.node.addChild(g)
        b.glow = g
        let body = SKSpriteNode(texture: Gfx.circle(ballR, UIColor(white: 0.97, alpha: 1), ring: Theme.uiOrange), size: CGSize(width: ballR * 2, height: ballR * 2))
        body.zPosition = 1
        b.node.addChild(body)
        b.body = body
        b.node.zPosition = 25
        b.node.isHidden = true
        world.addChild(b.node)
        for _ in 0..<14 {
            let t = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: ballR * 2.6, height: ballR * 2.6))
            t.color = .white
            t.colorBlendFactor = 1
            t.blendMode = .add
            t.alpha = 0
            t.zPosition = 20
            world.addChild(t)
            b.trail.append(t)
            b.trailAge.append(9)
        }
        return b
    }

    private func place(_ p: PPaddle) {
        let pt: CGPoint
        if p.horizontal {
            pt = CGPoint(x: p.u, y: p.line.y + p.nin.dy * padD)
        } else {
            pt = CGPoint(x: p.line.x + p.nin.dx * padD, y: p.u)
        }
        p.node.position = pt
        let bh = p.bear.height
        if p.horizontal {
            p.bear.position = CGPoint(x: p.u, y: p.line.y - p.nin.dy * (bh + 5))
        } else {
            p.bear.position = CGPoint(x: p.line.x - p.nin.dx * (bh + 5), y: p.u)
        }
    }

    // MARK: touches

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = paddles[seat.index]
        p.touch = touch
        setTarget(seat, p, at)
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = paddles[seat.index]
        if p.touch == nil { p.touch = touch }
        if p.touch === touch { setTarget(seat, p, at) }
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = paddles[seat.index]
        if p.touch === touch { p.touch = nil }
    }

    private func setTarget(_ seat: Seat, _ p: PPaddle, _ at: CGPoint) {
        let sp = seat.toScene(at)
        p.target = clampU(p, p.horizontal ? sp.x : sp.y)
    }

    private func clampU(_ p: PPaddle, _ u: CGFloat) -> CGFloat {
        let half = p.len * p.bar.xScale / 2 + 6
        return max(p.latMin + half, min(p.latMax - half, u))
    }

    // MARK: update

    override func gameStarted() {
        ballList[0].timer = 0.2
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        bounceCool -= dt

        if !secondBallDone && elapsed >= 20 {
            secondBallDone = true
            ballList[1].timer = 0.4
            bannerAll("ZWEITER BALL!", color: UIColor(red: 0.55, green: 1, blue: 0.55, alpha: 1), size: 30, duration: 0.7)
            Sfx.shared.play("whistle")
        }
        if !suddenDeath && elapsed >= 42 {
            suddenDeath = true
            bannerAll("SUDDEN DEATH", color: UIColor(red: 1, green: 0.35, blue: 0.3, alpha: 1), size: 32, duration: 0.9)
            flashAll(UIColor.red, alpha: 0.18)
            Sfx.shared.play("horn")
        }
        let sdMul: CGFloat = suddenDeath ? 1 + CGFloat(elapsed - 42) * 0.035 : 1
        sdFactor = suddenDeath ? max(0.7, 1 - CGFloat(elapsed - 42) * 0.012) : 1

        // paddles
        for s in seats where s.alive {
            let p = paddles[s.index]
            if s.isCPU { cpuThink(s, p, dt) }
            p.bar.xScale += (sdFactor - p.bar.xScale) * min(1, fdt * 3)
            p.glow.xScale = p.bar.xScale
            let maxV: CGFloat = s.isCPU ? CGFloat(120 + 420 * s.skill) : 2800
            let d = p.target - p.u
            let step = max(-maxV * fdt, min(maxV * fdt, d))
            p.u = clampU(p, p.u + step)
            p.vel = step / max(fdt, 0.001)
            place(p)
            let moving = abs(p.vel) > 60
            if moving && !p.running { p.running = true; p.bear.startRun(speed: 0.12) }
            if !moving && p.running { p.running = false; p.bear.stopRun() }
        }

        // balls
        for b in ballList {
            if !b.active {
                b.timer -= dt
                if b.timer <= 0 && !finished && aliveSeats.count > 1 { spawn(b) }
                updateTrail(b, fdt, dt)
                continue
            }
            let steps = 3
            let sdt = fdt / CGFloat(steps)
            for _ in 0..<steps {
                b.pos.x += b.vel.dx * sdt
                b.pos.y += b.vel.dy * sdt
                for s in seats where s.alive { collide(b, s, paddles[s.index]) }
                if walls(b) { break }
            }
            if !b.active { updateTrail(b, fdt, dt); continue }
            // spin curve
            if abs(b.spin) > 0.01 {
                let a = b.spin * fdt
                let c = cos(a), sn = sin(a)
                b.vel = CGVector(dx: b.vel.dx * c - b.vel.dy * sn, dy: b.vel.dx * sn + b.vel.dy * c)
                b.spin *= pow(0.45, fdt)
            }
            // keep target speed
            let cur = max(1, hypot(b.vel.dx, b.vel.dy))
            let want = min(b.speed, capSpeed) * sdMul
            let k = want / cur
            b.vel = CGVector(dx: b.vel.dx * k, dy: b.vel.dy * k)
            b.node.position = b.pos
            updateTrail(b, fdt, dt)
        }

        if let _ = seats.first(where: { !$0.isCPU }), !humansAlive, !finished {
            humanOutTimer += dt
            if humanOutTimer > 3.5 { finishGame(scores: finalScores()) }
        }
    }

    private func updateTrail(_ b: PBall, _ fdt: CGFloat, _ dt: Double) {
        for i in 0..<b.trail.count {
            b.trailAge[i] += fdt
            let a = max(0, 1 - b.trailAge[i] / 0.32)
            b.trail[i].alpha = a * 0.5
            b.trail[i].setScale(0.4 + a * 0.7)
        }
        if b.active {
            b.trailT -= dt
            if b.trailT <= 0 {
                b.trailT = 0.018
                let t = b.trail[b.trailIdx]
                t.position = b.pos
                t.color = b.last >= 0 ? seats[b.last].color : UIColor.white
                b.trailAge[b.trailIdx] = 0
                b.trailIdx = (b.trailIdx + 1) % b.trail.count
            }
        }
    }

    private func spawn(_ b: PBall) {
        let alive = aliveSeats
        guard !alive.isEmpty else { return }
        let target = alive[Int.random(in: 0..<alive.count)]
        let nin = paddles[target.index].nin
        let a = CGFloat.random(in: -0.6...0.6)
        // fly towards the target's goal, i.e. against its inward normal
        let dx = -nin.dx, dy = -nin.dy
        b.pos = CGPoint(x: F.midX + CGFloat.random(in: -20...20), y: F.midY + CGFloat.random(in: -20...20))
        b.speed = baseSpeed
        b.vel = CGVector(dx: (dx * cos(a) - dy * sin(a)) * baseSpeed, dy: (dx * sin(a) + dy * cos(a)) * baseSpeed)
        b.spin = 0
        b.last = -1
        b.active = true
        b.node.position = b.pos
        b.node.isHidden = false
        b.node.setScale(0.1)
        b.node.run(SKAction.scale(to: 1, duration: 0.25))
        b.glow.color = .white
        b.body.color = .white
        for i in 0..<b.trail.count { b.trailAge[i] = 9 }
        Sfx.shared.play("tick")
    }

    // MARK: collision

    private func collide(_ b: PBall, _ s: Seat, _ p: PPaddle) {
        let lat = p.horizontal ? b.pos.x : b.pos.y
        let dLat = lat - p.u
        let perpD = perp(p.edge, b.pos)
        let half = p.len * p.bar.xScale / 2
        let pLo = padD - padT / 2, pHi = padD + padT / 2
        let cl = max(-half, min(half, dLat))
        let cp = max(pLo, min(pHi, perpD))
        let dist = hypot(dLat - cl, perpD - cp)
        if dist >= ballR { return }
        // velocity in (perp, lat)
        let latAxis = p.horizontal ? CGVector(dx: 1, dy: 0) : CGVector(dx: 0, dy: 1)
        let vp = b.vel.dx * p.nin.dx + b.vel.dy * p.nin.dy
        let vl = b.vel.dx * latAxis.dx + b.vel.dy * latAxis.dy
        if abs(dLat) > half && perpD < pHi {
            // hit the end cap: bounce sideways
            let sgn: CGFloat = dLat > 0 ? 1 : -1
            if vl * sgn < 0 {
                let nl = -vl
                b.vel = CGVector(dx: p.nin.dx * vp + latAxis.dx * nl, dy: p.nin.dy * vp + latAxis.dy * nl)
                let newLat = p.u + sgn * (half + ballR)
                if p.horizontal { b.pos.x = newLat } else { b.pos.y = newLat }
            }
            return
        }
        if vp >= 0 { return }
        // front hit: angle from hit offset + paddle movement
        let off = max(-1, min(1, dLat / max(half, 1)))
        var ang = off * 0.8 + max(-0.35, min(0.35, p.vel / 2600))
        ang = max(-1.05, min(1.05, ang))
        b.speed = min(capSpeed, b.speed + 17)
        let sp = max(b.speed, hypot(b.vel.dx, b.vel.dy))
        let nvp = sp * cos(ang), nvl = sp * sin(ang)
        b.vel = CGVector(dx: p.nin.dx * nvp + latAxis.dx * nvl, dy: p.nin.dy * nvp + latAxis.dy * nvl)
        b.spin = max(-3, min(3, p.vel * 0.0045))
        // push out of the paddle
        let np = pHi + ballR + 0.5
        switch p.edge {
        case .bottom: b.pos.y = F.minY + np
        case .top: b.pos.y = F.maxY - np
        case .left: b.pos.x = F.minX + np
        case .right: b.pos.x = F.maxX - np
        }
        b.last = s.index
        p.saves += 1
        addScore(s, 1)
        addStat("hits", 1, seat: s)
        b.glow.color = s.color
        b.body.color = s.color
        b.body.colorBlendFactor = 0.35
        b.node.removeAction(forKey: "pop")
        b.node.run(SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.05), SKAction.scale(to: 1, duration: 0.09)]), withKey: "pop")
        p.node.removeAction(forKey: "hit")
        p.node.run(SKAction.sequence([SKAction.scale(to: 1.12, duration: 0.04), SKAction.scale(to: 1, duration: 0.08)]), withKey: "hit")
        p.bear.squash()
        sparks(at: b.pos, color: s.color, count: 6, speed: 90)
        Sfx.shared.play(sp > 430 ? "hit" : "tap")
        if !s.isCPU { Haptic.tap(.medium) }
    }

    private func walls(_ b: PBall) -> Bool {
        for e in edges {
            let d = perp(e, b.pos)
            if let si = edgeSeat[e], seats[si].alive {
                if d < -ballR * 0.5 {
                    lose(b, seats[si])
                    return true
                }
            } else if d < ballR {
                let nin = ninOf(e)
                switch e {
                case .bottom: b.pos.y = F.minY + ballR
                case .top: b.pos.y = F.maxY - ballR
                case .left: b.pos.x = F.minX + ballR
                case .right: b.pos.x = F.maxX - ballR
                }
                let vp = b.vel.dx * nin.dx + b.vel.dy * nin.dy
                if vp < 0 {
                    b.vel = CGVector(dx: b.vel.dx - 2 * vp * nin.dx, dy: b.vel.dy - 2 * vp * nin.dy)
                    b.spin *= 0.6
                    wallFlash(e)
                    if bounceCool <= 0 { bounceCool = 0.06; Sfx.shared.play("bounce") }
                    sparks(at: b.pos, color: UIColor(white: 0.9, alpha: 1), count: 3, speed: 60)
                }
            }
        }
        return false
    }

    private func wallFlash(_ e: SeatEdge) {
        guard let n = edgeNodes[e], let g = n.childNode(withName: "glow") else { return }
        g.removeAction(forKey: "f")
        g.run(SKAction.sequence([SKAction.fadeAlpha(to: 1, duration: 0.03), SKAction.fadeAlpha(to: edgeSeat[e] != nil && !(seats[edgeSeat[e]!].alive) ? 0.4 : 0.28, duration: 0.2)]), withKey: "f")
    }

    private func lose(_ b: PBall, _ s: Seat) {
        let p = paddles[s.index]
        b.active = false
        b.node.isHidden = true
        b.timer = 1.4
        p.lives -= 1
        if p.lives >= 0 && p.lives < p.hearts.count {
            let h = p.hearts[p.lives]
            h.run(SKAction.group([SKAction.scale(to: 2.0, duration: 0.2), SKAction.fadeAlpha(to: 0.15, duration: 0.2)]))
        }
        let red = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
        if p.lives > 0 { s.banner("LEBEN WEG", color: red, size: 26, duration: 0.5) }
        Sfx.shared.play("miss")
        Haptic.bad()
        var gp = b.pos
        switch p.edge {
        case .bottom: gp.y = F.minY
        case .top: gp.y = F.maxY
        case .left: gp.x = F.minX
        case .right: gp.x = F.maxX
        }
        sparks(at: gp, color: s.color, count: 22, speed: 160)
        flashAll(s.color, alpha: 0.18)
        s.flash(red, alpha: 0.5)
        world.removeAction(forKey: "shake")
        world.position = .zero
        let amt: CGFloat = 7
        world.run(SKAction.sequence([
            SKAction.moveBy(x: amt, y: amt, duration: 0.03), SKAction.moveBy(x: -2 * amt, y: -amt, duration: 0.05),
            SKAction.moveBy(x: amt, y: -amt * 0.5, duration: 0.04), SKAction.move(to: .zero, duration: 0.03)
        ]), withKey: "shake")
        if let g = edgeNodes[p.edge]?.childNode(withName: "glow") {
            g.run(SKAction.sequence([SKAction.fadeAlpha(to: 1, duration: 0.05), SKAction.fadeAlpha(to: 0.5, duration: 0.5)]))
        }
        if p.lives <= 0 {
            p.outOrder = outCount
            outCount += 1
            s.knockOut("RAUS")
            p.node.run(SKAction.fadeAlpha(to: 0, duration: 0.3))
            p.bear.run(SKAction.fadeAlpha(to: 0.3, duration: 0.3))
            if p.running { p.bear.stopRun(); p.running = false }
            if let en = edgeNodes[p.edge] {
                en.run(SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.3))
                en.alpha = 0.7
                if let g = en.childNode(withName: "glow") as? SKSpriteNode {
                    g.color = .white
                    g.alpha = 0.3
                }
            }
            Sfx.shared.play("lose")
            if aliveSeats.count <= 1 {
                for ob in ballList { ob.active = false; ob.node.isHidden = true }
                finishGame(scores: finalScores())
            }
        }
    }

    private func sparks(at p: CGPoint, color: UIColor, count: Int, speed: CGFloat) {
        for _ in 0..<count {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 6, height: 6))
            d.color = color
            d.colorBlendFactor = 1
            d.blendMode = .add
            d.position = p
            d.zPosition = 40
            world.addChild(d)
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let r = CGFloat.random(in: 0.3...1) * speed
            d.run(SKAction.sequence([
                SKAction.group([SKAction.moveBy(x: cos(a) * r, y: sin(a) * r, duration: 0.45), SKAction.fadeOut(withDuration: 0.45), SKAction.scale(to: 0.2, duration: 0.45)]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: scoring

    private func finalScores() -> [Int] {
        return seats.map { s in
            let p = paddles[s.index]
            let sv = min(99, p.saves)
            if p.outOrder >= 0 { return p.outOrder * 100 + sv }
            return 10000 + max(0, p.lives) * 1000 + sv
        }
    }

    override func timeUp() {
        finishGame(scores: finalScores())
    }

    // MARK: CPU

    private func fold(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        let w = max(1, b - a)
        var t = (x - a).truncatingRemainder(dividingBy: 2 * w)
        if t < 0 { t += 2 * w }
        if t > w { t = 2 * w - t }
        return a + t
    }

    private func cpuThink(_ s: Seat, _ p: PPaddle, _ dt: Double) {
        p.think -= dt
        if p.think > 0 { return }
        p.think = 0.07 + (1 - s.skill) * 0.26
        var bestT: CGFloat = .greatestFiniteMagnitude
        var best: PBall?
        var nearest: PBall?
        var nd: CGFloat = .greatestFiniteMagnitude
        for b in ballList where b.active {
            let d = perp(p.edge, b.pos)
            if d < nd { nd = d; nearest = b }
            let vn = -(b.vel.dx * p.nin.dx + b.vel.dy * p.nin.dy)
            if vn > 30 {
                let t = max(0, d - padD) / vn
                if t < bestT { bestT = t; best = b }
            }
        }
        let mid = (p.latMin + p.latMax) / 2
        let half = p.len / 2
        if let b = best {
            if !p.wasApproaching {
                p.aimOff = CGFloat.random(in: -0.45...0.45) * CGFloat(0.3 + 0.7 * s.skill)
            }
            p.wasApproaching = true
            let l0 = p.horizontal ? b.pos.x : b.pos.y
            let vl = p.horizontal ? b.vel.dx : b.vel.dy
            var x = fold(l0 + vl * bestT, p.latMin + ballR, p.latMax - ballR)
            let err = CGFloat(1 - s.skill) * (22 + bestT * 60)
            x += CGFloat.random(in: -err...err)
            x -= p.aimOff * half
            p.target = clampU(p, x)
        } else {
            p.wasApproaching = false
            if let b = nearest {
                let l0 = p.horizontal ? b.pos.x : b.pos.y
                p.target = clampU(p, mid * 0.4 + l0 * 0.6)
            } else {
                p.target = clampU(p, mid)
            }
        }
    }
}
