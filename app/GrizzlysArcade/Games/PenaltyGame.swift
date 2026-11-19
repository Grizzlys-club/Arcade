import SpriteKit

/// Penalty-Duell: swipe the ball past the goalie. 40 seconds, most goals wins.
final class PenaltyGame: MiniScene {

    private final class State {
        var goal: SKSpriteNode!
        var goalie: BearNode!
        var goalieX: CGFloat = 0
        var goalieDir: CGFloat = 1
        var goalieHalf: CGFloat = 20
        var ball: SKSpriteNode!
        var ballGlow: SKSpriteNode!
        var shadow: SKSpriteNode!
        var flying = false
        var resolved = false
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var curve: CGFloat = 0
        var resetTimer: Double = 0
        var cpuTimer: Double = 1.0
        var touchStart: CGPoint?
        var touchTime: Double = 0
        var goalY: CGFloat = 0
        var goalW: CGFloat = 0
        var goalH: CGFloat = 0
        var restY: CGFloat = 0
        var ballR: CGFloat = 9
        var shots = 0
        var hint: SKNode?
        var reaction: Double = 0
        var goalieError: CGFloat = 0
    }

    private var st: [State] = []

    override func setupGame() {
        duration = 40
        for s in seats {
            let o = State()
            st.append(o)
            let w = s.w, h = s.h
            let scale = min(1, w / 300)

            // floor
            let floor = SKSpriteNode(texture: PenaltyGame.floorTexture(w, h, s.color), size: s.size)
            floor.zPosition = -10
            s.field.addChild(floor)

            // goal at the inner edge
            o.goalW = min(w * 0.74, 220)
            o.goalH = max(44, o.goalW * 0.34)
            o.goalY = h / 2 - 40 - o.goalH
            let g = SKSpriteNode(texture: Gfx.goal(o.goalW, o.goalH), size: CGSize(width: o.goalW + 16, height: o.goalH + 12))
            g.position = CGPoint(x: 0, y: o.goalY + o.goalH / 2 - 2)
            g.zPosition = 2
            s.field.addChild(g)
            o.goal = g

            // crease (semicircle in front of goal)
            let crease = SKShapeNode()
            let p = UIBezierPath(arcCenter: .zero, radius: o.goalW * 0.62, startAngle: .pi, endAngle: 2 * .pi, clockwise: true)
            crease.path = p.cgPath
            crease.strokeColor = UIColor(white: 1, alpha: 0.18)
            crease.lineWidth = 2
            crease.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1, alpha: 0.06)
            crease.position = CGPoint(x: 0, y: o.goalY)
            crease.zPosition = 1
            s.field.addChild(crease)

            // goalie bear
            let gh = o.goalH * 0.82
            // opponent keeper in a contrasting skin
            let keeper = BearNode(skin: Skin.find(s.skin.id == "classic" ? "ice" : "classic"), height: gh, faceRight: false)
            keeper.position = CGPoint(x: 0, y: o.goalY - 6)
            keeper.zPosition = 5
            keeper.startBob(amount: 2, duration: 0.25)
            s.field.addChild(keeper)
            o.goalie = keeper
            o.goalieHalf = gh * bearAspect * 0.42

            // penalty spot
            o.restY = -h / 2 + 52 * max(0.8, scale)
            let spot = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 8, height: 8))
            spot.alpha = 0.5
            spot.position = CGPoint(x: 0, y: o.restY - 12)
            spot.zPosition = 1
            s.field.addChild(spot)

            // ball
            o.ballR = 10 * max(0.85, scale)
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: o.ballR * 5, height: o.ballR * 5))
            glow.color = s.color
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.6
            glow.zPosition = 6
            s.field.addChild(glow)
            o.ballGlow = glow
            let sh = SKSpriteNode(texture: Gfx.shadow, size: CGSize(width: o.ballR * 2.4, height: o.ballR))
            sh.zPosition = 6
            s.field.addChild(sh)
            o.shadow = sh
            let b = SKSpriteNode(texture: Gfx.ball(14), size: CGSize(width: o.ballR * 2, height: o.ballR * 2))
            b.zPosition = 8
            s.field.addChild(b)
            o.ball = b
            o.pos = CGPoint(x: 0, y: o.restY)
            placeBall(o)

            // shooter bear behind the ball (player's own bear)
            let shooter = makeBear(s, height: 38 * max(0.85, scale), faceRight: true)
            shooter.position = CGPoint(x: -o.ballR * 3.2, y: o.restY - 26)
            shooter.zPosition = 7
            shooter.alpha = 0.95
            s.field.addChild(shooter)

            // hint
            if !s.isCPU {
                let hint = SKNode()
                let l = label("WISCHEN ↑", size: 18, color: s.color)
                l.position = CGPoint(x: 0, y: o.restY + 46)
                hint.addChild(l)
                hint.zPosition = 50
                hint.run(SKAction.repeatForever(SKAction.sequence([SKAction.moveBy(x: 0, y: 8, duration: 0.4), SKAction.moveBy(x: 0, y: -8, duration: 0.4)])))
                s.field.addChild(hint)
                o.hint = hint
            }
            o.cpuTimer = 1.0 + Double.random(in: 0...0.6)
        }
    }

    private static func floorTexture(_ w: CGFloat, _ h: CGFloat, _ c: UIColor) -> SKTexture {
        return Gfx.texture("pen_floor\(Int(w))x\(Int(h))", size: CGSize(width: w, height: h), scale: 1) { ctx in
            Gfx.gradientColors(UIColor(red: 0.10, green: 0.16, blue: 0.30, alpha: 0.9), UIColor(red: 0.05, green: 0.08, blue: 0.16, alpha: 0.9), in: ctx, size: CGSize(width: w, height: h))
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.07).cgColor)
            ctx.setLineWidth(1)
            var y: CGFloat = 0
            while y < h {
                ctx.move(to: CGPoint(x: 0, y: y))
                ctx.addLine(to: CGPoint(x: w, y: y))
                y += 22
            }
            ctx.strokePath()
        }
    }

    private func placeBall(_ o: State) {
        o.ball.position = o.pos
        o.ballGlow.position = o.pos
        o.shadow.position = CGPoint(x: o.pos.x, y: o.pos.y - o.ballR * 0.9)
    }

    // MARK: shooting

    private func shoot(_ s: Seat, _ o: State, vel: CGVector, curve: CGFloat) {
        guard !o.flying, o.resetTimer <= 0, phase == .playing else { return }
        o.flying = true
        o.resolved = false
        o.vel = vel
        o.curve = curve
        o.shots += 1
        o.reaction = Double.random(in: 0.05...0.18) + (difficulty == 0 ? 0.12 : (difficulty == 1 ? 0.05 : 0))
        o.goalieError = CGFloat.random(in: -1...1) * o.goalW * (difficulty == 0 ? 0.28 : (difficulty == 1 ? 0.18 : 0.1))
        Sfx.shared.play("kick")
        if !s.isCPU { Haptic.tap(.medium) }
        if let hint = o.hint {
            hint.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
            o.hint = nil
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let o = st[seat.index]
        o.touchStart = at
        o.touchTime = elapsed
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let o = st[seat.index]
        guard let start = o.touchStart else { return }
        if hypot(at.x - start.x, at.y - start.y) > 110 {
            release(seat, at: at)
        }
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        release(seat, at: at)
    }

    private func release(_ seat: Seat, at: CGPoint) {
        let o = st[seat.index]
        guard let start = o.touchStart else { return }
        o.touchStart = nil
        let dx = at.x - start.x
        let dy = at.y - start.y
        if dy < 18 { return }
        let t = max(0.04, elapsed - o.touchTime)
        let len = hypot(dx, dy)
        let speed = max(seat.h * 1.6, min(seat.h * 3.6, len / CGFloat(t) * 0.9))
        // aim: project the swipe direction
        let dir = CGVector(dx: dx / len, dy: dy / len)
        shoot(seat, o, vel: CGVector(dx: dir.dx * speed, dy: dir.dy * speed), curve: 0)
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        for s in seats {
            let o = st[s.index]
            updateGoalie(s, o, fdt)

            if o.flying {
                o.vel.dx += o.curve * fdt
                o.pos.x += o.vel.dx * fdt
                o.pos.y += o.vel.dy * fdt
                let total = o.goalY - o.restY
                let prog = max(0, min(1.2, (o.pos.y - o.restY) / total))
                o.ball.setScale(1 - 0.38 * prog)
                o.ballGlow.setScale(1 - 0.38 * prog)
                o.ball.zRotation += fdt * 12
                // ball "lifts" a bit: shadow lags behind
                o.shadow.position = CGPoint(x: o.pos.x, y: o.pos.y - o.ballR * (0.9 + prog * 1.6))
                o.ball.position = o.pos
                o.ballGlow.position = o.pos
                if !o.resolved && (o.pos.y >= o.goalY || abs(o.pos.x) > s.w / 2 + 20) {
                    resolve(s, o)
                }
                if o.resolved && o.vel.dy > 0 && o.pos.y > o.goalY + o.goalH * 0.75 {
                    o.vel = CGVector(dx: o.vel.dx * 0.2, dy: 0)
                }
            }

            if o.resetTimer > 0 {
                o.resetTimer -= dt
                if o.resetTimer <= 0 {
                    o.flying = false
                    o.pos = CGPoint(x: 0, y: o.restY)
                    o.ball.setScale(1)
                    o.ballGlow.setScale(1)
                    o.ball.alpha = 0
                    o.ball.run(SKAction.fadeIn(withDuration: 0.15))
                    placeBall(o)
                }
            }

            if s.isCPU && !o.flying && o.resetTimer <= 0 {
                o.cpuTimer -= dt
                if o.cpuTimer <= 0 {
                    cpuShoot(s, o)
                    o.cpuTimer = 1.25 + Double.random(in: 0...0.6) - s.skill * 0.25
                }
            }
        }
    }

    private func updateGoalie(_ s: Seat, _ o: State, _ dt: CGFloat) {
        let limit = o.goalW / 2 - o.goalieHalf * 0.6
        let diffK: CGFloat = difficulty == 0 ? 0.75 : (difficulty == 1 ? 1.0 : 1.25)
        let speedUp = 1 + CGFloat(elapsed) * 0.025
        if o.flying && !o.resolved {
            o.reaction -= Double(dt)
            if o.reaction <= 0 {
                // predict where the ball crosses the goal line
                let tLeft = max(0.01, (o.goalY - o.pos.y) / max(1, o.vel.dy))
                let px = o.pos.x + o.vel.dx * tLeft + 0.5 * o.curve * tLeft * tLeft + o.goalieError
                let target = max(-limit, min(limit, px))
                let maxSpeed = o.goalW * 1.5 * diffK * speedUp
                let d = target - o.goalieX
                let step = max(-maxSpeed * dt, min(maxSpeed * dt, d))
                o.goalieX += step
            }
        } else {
            let patrol = o.goalW * 0.45 * diffK * speedUp
            o.goalieX += o.goalieDir * patrol * dt
            if o.goalieX > limit { o.goalieX = limit; o.goalieDir = -1 }
            if o.goalieX < -limit { o.goalieX = -limit; o.goalieDir = 1 }
        }
        o.goalie.position.x = o.goalieX
        o.goalie.setFacing(right: o.goalieDir > 0)
    }

    private func resolve(_ s: Seat, _ o: State) {
        o.resolved = true
        let inGoal = abs(o.pos.x) < o.goalW / 2 - o.ballR * 0.5 && o.pos.y >= o.goalY - 2
        let saved = abs(o.pos.x - o.goalieX) < o.goalieHalf + o.ballR * 0.6
        let center = CGPoint(x: o.pos.x, y: o.goalY + 10)
        if inGoal && !saved {
            addScore(s, 1)
            addStat("goals", 1, seat: s)
            s.banner("TOR!", color: s.color, size: 46, duration: 0.5)
            s.burst(at: center, color: s.color, count: 16, speed: 140)
            s.burst(at: center, color: .white, count: 8, speed: 90)
            let shake = SKAction.sequence([SKAction.moveBy(x: 0, y: 5, duration: 0.05), SKAction.moveBy(x: 0, y: -5, duration: 0.08)])
            o.goal.run(SKAction.repeat(shake, count: 3))
            Sfx.shared.play("goal")
            if !s.isCPU { Haptic.good() }
            o.vel = CGVector(dx: o.vel.dx * 0.3, dy: o.vel.dy * 0.35)
        } else if saved && inGoal {
            s.floatText("GEHALTEN", at: CGPoint(x: o.goalieX, y: o.goalY - 30), color: UIColor(white: 1, alpha: 0.9), size: 18)
            o.goalie.squash()
            o.vel = CGVector(dx: CGFloat.random(in: -1...1) * s.w * 0.8, dy: -abs(o.vel.dy) * 0.35)
            Sfx.shared.play("save")
            if !s.isCPU { Haptic.bad() }
        } else {
            let hitPost = abs(abs(o.pos.x) - o.goalW / 2) < o.ballR * 1.6 && o.pos.y >= o.goalY - 4
            s.floatText(hitPost ? "PFOSTEN!" : "DANEBEN", at: CGPoint(x: max(-s.w / 2 + 50, min(s.w / 2 - 50, o.pos.x)), y: o.goalY - 26), color: UIColor(white: 1, alpha: 0.8), size: 17)
            if hitPost {
                o.vel = CGVector(dx: -o.vel.dx * 0.6, dy: -abs(o.vel.dy) * 0.4)
                Sfx.shared.play("hit")
            } else {
                Sfx.shared.play("miss")
            }
        }
        o.ball.run(SKAction.sequence([SKAction.wait(forDuration: 0.35), SKAction.fadeOut(withDuration: 0.2)]))
        o.resetTimer = 0.75
    }

    private func cpuShoot(_ s: Seat, _ o: State) {
        // aim for the corner away from the goalie
        let side: CGFloat = o.goalieX > 0 ? -1 : 1
        let accuracy = CGFloat(s.skill)
        var tx = side * (o.goalW / 2 - o.ballR * 1.5) * (0.5 + 0.45 * accuracy)
        tx += CGFloat.random(in: -1...1) * o.goalW * 0.42 * (1.1 - accuracy)
        let target = CGPoint(x: tx, y: o.goalY + 4)
        let dx = target.x - o.pos.x
        let dy = target.y - o.pos.y
        let len = hypot(dx, dy)
        let speed = s.h * (2.0 + 1.3 * accuracy)
        shoot(s, o, vel: CGVector(dx: dx / len * speed, dy: dy / len * speed), curve: 0)
    }
}
