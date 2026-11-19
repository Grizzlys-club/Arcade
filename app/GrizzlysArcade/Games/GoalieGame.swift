import SpriteKit

/// Torwart-Panik: drag the keeper and stop the shots. 3 goals conceded = out.
final class GoalieGame: MiniScene {

    private final class Shot {
        let node: SKSpriteNode
        let glow: SKSpriteNode
        var pos: CGPoint
        var vel: CGVector
        var curve: CGFloat
        var done = false
        var cpuNoise: CGFloat = 0
        init(node: SKSpriteNode, glow: SKSpriteNode, pos: CGPoint, vel: CGVector, curve: CGFloat) {
            self.node = node
            self.glow = glow
            self.pos = pos
            self.vel = vel
            self.curve = curve
        }
    }

    private final class State {
        var rand: Rand!
        var keeper: BearNode!
        var keeperX: CGFloat = 0
        var targetX: CGFloat = 0
        var keeperHalf: CGFloat = 20
        var keeperH: CGFloat = 40
        var shooter: BearNode!
        var goal: SKSpriteNode!
        var goalW: CGFloat = 0
        var goalH: CGFloat = 0
        var lineY: CGFloat = 0
        var shots: [Shot] = []
        var spawnTimer: Double = 1.0
        var shotCount = 0
        var lives = 3
        var lifeNodes: [SKSpriteNode] = []
        var ballR: CGFloat = 9
        var hint: SKNode?
        var nextShotX: CGFloat = 0
    }

    private var st: [State] = []
    private var hadHumans = false

    override func setupGame() {
        duration = 75
        hadHumans = seats.contains { !$0.isCPU }
        for s in seats {
            let o = State()
            o.rand = newRand()
            st.append(o)
            let w = s.w, h = s.h
            let scale = min(1, w / 300)

            let floor = SKSpriteNode(texture: GoalieGame.floorTexture(w, h), size: s.size)
            floor.zPosition = -10
            s.field.addChild(floor)

            // goal at the player's edge, opening upwards
            o.goalW = min(w * 0.82, 240)
            o.goalH = max(40, o.goalW * 0.26)
            let g = SKSpriteNode(texture: Gfx.goal(o.goalW, o.goalH), size: CGSize(width: o.goalW + 16, height: o.goalH + 12))
            g.zRotation = .pi
            g.position = CGPoint(x: 0, y: -h / 2 + o.goalH / 2 + 4)
            g.zPosition = 2
            s.field.addChild(g)
            o.goal = g
            o.lineY = -h / 2 + o.goalH + 6

            let crease = SKShapeNode()
            let p = UIBezierPath(arcCenter: .zero, radius: o.goalW * 0.6, startAngle: 0, endAngle: .pi, clockwise: true)
            crease.path = p.cgPath
            crease.strokeColor = s.color.withAlphaComponent(0.35)
            crease.lineWidth = 2
            crease.fillColor = s.color.withAlphaComponent(0.06)
            crease.position = CGPoint(x: 0, y: o.lineY)
            crease.zPosition = 1
            s.field.addChild(crease)

            // keeper = the player's bear
            o.keeperH = 50 * max(0.8, scale)
            let k = makeBear(s, height: o.keeperH, faceRight: false)
            k.position = CGPoint(x: 0, y: o.lineY - o.keeperH * 0.35)
            k.zPosition = 6
            s.field.addChild(k)
            o.keeper = k
            o.keeperHalf = o.keeperH * bearAspect * 0.5
            // glove glow under the keeper
            let glove = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: o.keeperHalf * 3, height: o.keeperH))
            glove.color = s.color
            glove.colorBlendFactor = 1
            glove.blendMode = .add
            glove.alpha = 0.35
            glove.position = CGPoint(x: 0, y: o.keeperH * 0.5)
            glove.zPosition = -1
            k.addChild(glove)

            // shooter at the inner edge (opponent)
            let sh = BearNode(skin: Skin.find(s.skin.id == "fire" ? "blue" : "fire"), height: 38 * max(0.85, scale), faceRight: false)
            sh.position = CGPoint(x: 0, y: h / 2 - 40 - 38 * max(0.85, scale))
            sh.zPosition = 5
            sh.alpha = 0.9
            s.field.addChild(sh)
            o.shooter = sh

            o.ballR = 9 * max(0.85, scale)

            // lives (balls in the top-left corner)
            for i in 0..<3 {
                let l = SKSpriteNode(texture: Gfx.circle(8, s.color, ring: .white), size: CGSize(width: 13, height: 13))
                l.position = CGPoint(x: -w / 2 + 20 + CGFloat(i) * 17, y: h / 2 - 36)
                l.zPosition = 400
                s.node.addChild(l)
                o.lifeNodes.append(l)
            }

            if !s.isCPU {
                let hint = SKNode()
                let l = label("← ZIEHEN →", size: 17, color: s.color)
                l.position = CGPoint(x: 0, y: o.lineY + 34)
                hint.addChild(l)
                hint.zPosition = 50
                s.field.addChild(hint)
                o.hint = hint
            }
            o.nextShotX = o.rand.range(-w * 0.3, w * 0.3)
        }
    }

    private static func floorTexture(_ w: CGFloat, _ h: CGFloat) -> SKTexture {
        return Gfx.texture("goalie_floor\(Int(w))x\(Int(h))", size: CGSize(width: w, height: h), scale: 1) { ctx in
            Gfx.gradientColors(UIColor(red: 0.05, green: 0.12, blue: 0.12, alpha: 0.9), UIColor(red: 0.08, green: 0.2, blue: 0.18, alpha: 0.9), in: ctx, size: CGSize(width: w, height: h))
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.06).cgColor)
            ctx.setLineWidth(1)
            var x: CGFloat = 0
            while x < w {
                ctx.move(to: CGPoint(x: x, y: 0))
                ctx.addLine(to: CGPoint(x: x, y: h))
                x += 24
            }
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

    private var fastForward = false

    override func gameUpdate(_ dtIn: Double) {
        // when all humans are out, let the CPUs finish quickly
        if hadHumans && !humansAlive && !fastForward {
            fastForward = true
            bannerAll("⏩", color: .white, size: 40, duration: 0.6)
        }
        let dt = fastForward ? dtIn * 3 : dtIn
        let fdt = CGFloat(dt)
        for s in seats {
            let o = st[s.index]
            if !s.alive {
                for shot in o.shots where !shot.done { shot.done = true; shot.node.removeFromParent(); shot.glow.removeFromParent() }
                continue
            }
            // spawn shots (same schedule for everybody)
            o.spawnTimer -= dt
            if o.spawnTimer <= 0 {
                spawn(s, o)
                o.spawnTimer = max(0.5, 1.55 - elapsed * 0.017) * Double(o.rand.range(0.85, 1.15))
            }
            // shooter walks to the next shot position
            let sx = o.shooter.position.x
            o.shooter.position.x = sx + (o.nextShotX - sx) * min(1, fdt * 6)

            // keeper movement
            if s.isCPU { cpuTarget(s, o) }
            let limit = s.w / 2 - o.keeperHalf * 0.7
            let tgt = max(-limit, min(limit, o.targetX))
            let maxSpeed: CGFloat = s.isCPU ? s.w * (0.9 + CGFloat(s.skill) * 1.6) : s.w * 6
            let d = tgt - o.keeperX
            if s.isCPU {
                o.keeperX += max(-maxSpeed * fdt, min(maxSpeed * fdt, d))
            } else {
                o.keeperX += d * min(1, fdt * 24)
            }
            o.keeper.position.x = o.keeperX
            if abs(d) > 2 { o.keeper.setFacing(right: d > 0) }

            // shots
            for shot in o.shots where !shot.done {
                shot.vel.dx += shot.curve * fdt
                shot.pos.x += shot.vel.dx * fdt
                shot.pos.y += shot.vel.dy * fdt
                // bounce on side walls
                if shot.pos.x < -s.w / 2 + o.ballR { shot.pos.x = -s.w / 2 + o.ballR; shot.vel.dx = abs(shot.vel.dx); shot.curve = 0 }
                if shot.pos.x > s.w / 2 - o.ballR { shot.pos.x = s.w / 2 - o.ballR; shot.vel.dx = -abs(shot.vel.dx); shot.curve = 0 }
                shot.node.position = shot.pos
                shot.glow.position = shot.pos
                shot.node.zRotation += fdt * 10
                let progress = (s.h / 2 - shot.pos.y) / s.h
                shot.node.setScale(0.75 + 0.4 * max(0, min(1, progress)))

                // save?
                let saveTop = o.lineY + o.keeperH * 0.55
                if shot.pos.y <= saveTop && shot.pos.y > o.lineY - o.keeperH * 0.4 && abs(shot.pos.x - o.keeperX) < o.keeperHalf + o.ballR {
                    save(s, o, shot)
                    continue
                }
                if shot.pos.y <= o.lineY - 6 {
                    if abs(shot.pos.x) < o.goalW / 2 - 4 {
                        conceded(s, o, shot)
                    } else {
                        shot.done = true
                        shot.node.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
                        shot.glow.removeFromParent()
                        s.floatText("VORBEI", at: CGPoint(x: shot.pos.x * 0.7, y: o.lineY + 20), color: UIColor(white: 1, alpha: 0.6), size: 14)
                    }
                }
            }
            o.shots.removeAll { $0.done }
        }
        checkEnd()
    }

    private func spawn(_ s: Seat, _ o: State) {
        let r = o.rand!
        o.shotCount += 1
        let start = CGPoint(x: o.nextShotX, y: o.shooter.position.y + 14)
        let tx = r.range(-o.goalW * 0.46, o.goalW * 0.46)
        let curved = r.chance(min(0.6, 0.15 + elapsed * 0.008))
        let curve: CGFloat = curved ? r.range(-1, 1) * s.w * 1.6 : 0
        let speed = s.h * (0.95 + CGFloat(min(70, elapsed)) * 0.03) * r.range(0.9, 1.2)
        let dy = o.lineY - start.y
        let T = abs(dy) / speed
        let vx = (tx - start.x - 0.5 * curve * T * T) / T
        let node = SKSpriteNode(texture: Gfx.ball(14), size: CGSize(width: o.ballR * 2, height: o.ballR * 2))
        node.position = start
        node.zPosition = 8
        let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: o.ballR * 4.5, height: o.ballR * 4.5))
        glow.color = curved ? UIColor(red: 1, green: 0.4, blue: 0.9, alpha: 1) : UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
        glow.colorBlendFactor = 1
        glow.blendMode = .add
        glow.alpha = 0.7
        glow.position = start
        glow.zPosition = 7
        s.field.addChild(glow)
        s.field.addChild(node)
        let shot = Shot(node: node, glow: glow, pos: start, vel: CGVector(dx: vx, dy: -speed), curve: curve)
        shot.cpuNoise = CGFloat.random(in: -1...1) * o.goalW * 0.5 * CGFloat(1.05 - s.skill)
        o.shots.append(shot)
        o.shooter.squash()
        o.nextShotX = r.range(-s.w * 0.32, s.w * 0.32)
        if s === aliveSeats.first { Sfx.shared.play("kick") }
    }

    private func cpuTarget(_ s: Seat, _ o: State) {
        // react to the lowest incoming shot
        guard let shot = o.shots.filter({ !$0.done }).min(by: { $0.pos.y < $1.pos.y }) else {
            o.targetX = o.keeperX * 0.95
            return
        }
        // only start reacting once the ball is in the reaction window
        let window = s.h * CGFloat(0.55 + s.skill * 0.4)
        if shot.pos.y - o.lineY > window { return }
        let tLeft = max(0.01, (shot.pos.y - o.lineY) / max(1, -shot.vel.dy))
        let px = shot.pos.x + shot.vel.dx * tLeft + 0.5 * shot.curve * tLeft * tLeft
        o.targetX = px + shot.cpuNoise
    }

    private func save(_ s: Seat, _ o: State, _ shot: Shot) {
        shot.done = true
        addScore(s, 1)
        addStat("balls", 1, seat: s)
        o.keeper.squash()
        s.burst(at: shot.pos, color: s.color, count: 10, speed: 100)
        s.floatText("+1", at: CGPoint(x: shot.pos.x, y: shot.pos.y + 20), color: s.color, size: 20)
        Sfx.shared.play("save")
        if !s.isCPU { Haptic.tap(.medium) }
        shot.glow.removeFromParent()
        let away = CGVector(dx: CGFloat.random(in: -1...1) * s.w * 0.6, dy: s.h * 0.5)
        shot.node.run(SKAction.sequence([
            SKAction.group([SKAction.move(by: away, duration: 0.45), SKAction.fadeOut(withDuration: 0.45), SKAction.scale(to: 0.4, duration: 0.45)]),
            SKAction.removeFromParent()
        ]))
    }

    private func conceded(_ s: Seat, _ o: State, _ shot: Shot) {
        shot.done = true
        shot.glow.removeFromParent()
        shot.node.run(SKAction.sequence([SKAction.moveBy(x: 0, y: -10, duration: 0.1), SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
        o.lives -= 1
        if o.lives >= 0 && o.lives < o.lifeNodes.count {
            let l = o.lifeNodes[o.lives]
            l.run(SKAction.group([SKAction.scale(to: 1.8, duration: 0.2), SKAction.fadeAlpha(to: 0.15, duration: 0.2)]))
        }
        s.flash(UIColor.red, alpha: 0.35)
        s.shake(6)
        s.floatText("TOR!", at: CGPoint(x: shot.pos.x, y: o.lineY + 24), color: UIColor.red, size: 22)
        o.goal.run(SKAction.sequence([SKAction.moveBy(x: 0, y: -4, duration: 0.05), SKAction.moveBy(x: 0, y: 4, duration: 0.08)]))
        Sfx.shared.play("wrong")
        if !s.isCPU { Haptic.bad() }
        if o.lives <= 0 {
            s.knockOut("RAUS")
            Sfx.shared.play("lose")
        }
    }

    private func checkEnd() {
        if phase != .playing { return }
        let alive = aliveSeats
        if alive.isEmpty { finishGame(); return }
        if alive.count == 1 && n > 1 {
            let a = alive[0]
            let others = seats.filter { $0 !== a }.map { $0.score }.max() ?? 0
            if a.score > others { finishGame() }
        }
    }
}
