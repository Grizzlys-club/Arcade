import SpriteKit

/// Power-Schuss: stop the marker in the green zone. 8 shots, accuracy = points.
final class PowerShotGame: MiniScene {
    override class var layout: SeatLayout { return .turns }
    private var turnWait = 0.0


    private static let totalShots = 8

    private final class State {
        var rand: Rand!
        var meterW: CGFloat = 0
        var meterY: CGFloat = 0
        var meter: SKSpriteNode!
        var green: SKSpriteNode!
        var perfect: SKSpriteNode!
        var marker: SKSpriteNode!
        var m: CGFloat = 0
        var dir: CGFloat = 1
        var speed: CGFloat = 0.8
        var center: CGFloat = 0.5
        var width: CGFloat = 0.2
        var shot = 0
        var locked = false
        var done = false
        var waitTimer: Double = 0
        var cpuTarget: CGFloat = 0.5
        var cpuArmed: Double = 0
        var idle: Double = 0
        var shotLabel: SKLabelNode!
        var ball: SKSpriteNode!
        var ballRest = CGPoint.zero
        var goal: SKSpriteNode!
        var goalW: CGFloat = 0
        var goalH: CGFloat = 0
        var goalY: CGFloat = 0
        var keeper: BearNode!
        var hint: SKNode?
        var dots: [SKSpriteNode] = []
    }

    private var st: [State] = []

    override func setupGame() {
        duration = 0
        for s in seats {
            let o = State()
            o.rand = newRand()
            st.append(o)
            let w = s.w, h = s.h
            let scale = min(1, w / 300)

            let floor = SKSpriteNode(texture: PowerShotGame.floorTexture(w, h), size: s.size)
            floor.zPosition = -10
            s.field.addChild(floor)

            // goal + keeper
            o.goalW = min(w * 0.7, 210)
            o.goalH = max(44, o.goalW * 0.36)
            o.goalY = h / 2 - 42 - o.goalH
            let g = SKSpriteNode(texture: Gfx.goal(o.goalW, o.goalH), size: CGSize(width: o.goalW + 16, height: o.goalH + 12))
            g.position = CGPoint(x: 0, y: o.goalY + o.goalH / 2 - 2)
            g.zPosition = 2
            s.field.addChild(g)
            o.goal = g
            let k = BearNode(skin: Skin.find(s.skin.id == "galaxy" ? "classic" : "galaxy"), height: o.goalH * 0.75, faceRight: false)
            k.position = CGPoint(x: 0, y: o.goalY - 4)
            k.zPosition = 4
            k.startBob(amount: 2, duration: 0.3)
            s.field.addChild(k)
            o.keeper = k

            // meter near the player's edge
            o.meterW = w - 44
            o.meterY = -h / 2 + 44
            let back = SKSpriteNode(texture: Gfx.pill(o.meterW + 8, 30, fill: UIColor(white: 0, alpha: 0.6), border: UIColor(white: 1, alpha: 0.4), corner: 15), size: CGSize(width: o.meterW + 8, height: 30))
            back.position = CGPoint(x: 0, y: o.meterY)
            back.zPosition = 10
            s.field.addChild(back)
            let bar = SKSpriteNode(texture: PowerShotGame.barTexture(o.meterW), size: CGSize(width: o.meterW, height: 20))
            bar.position = CGPoint(x: 0, y: o.meterY)
            bar.zPosition = 11
            s.field.addChild(bar)
            o.meter = bar
            let green = SKSpriteNode(color: UIColor(red: 0.2, green: 1, blue: 0.35, alpha: 0.9), size: CGSize(width: 10, height: 20))
            green.zPosition = 12
            green.position.y = o.meterY
            s.field.addChild(green)
            o.green = green
            let perfect = SKSpriteNode(color: UIColor.white, size: CGSize(width: 3, height: 20))
            perfect.zPosition = 13
            perfect.position.y = o.meterY
            perfect.alpha = 0.9
            s.field.addChild(perfect)
            o.perfect = perfect
            let marker = SKSpriteNode(texture: Gfx.pill(8, 36, fill: .white, border: s.color, corner: 4), size: CGSize(width: 8, height: 36))
            marker.zPosition = 14
            marker.position.y = o.meterY
            s.field.addChild(marker)
            o.marker = marker
            let mg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 34, height: 50))
            mg.color = s.color
            mg.colorBlendFactor = 1
            mg.blendMode = .add
            mg.alpha = 0.7
            mg.zPosition = -1
            marker.addChild(mg)

            // ball + shooter
            o.ballRest = CGPoint(x: 0, y: o.meterY + 50 * max(0.85, scale))
            let ball = SKSpriteNode(texture: Gfx.ball(14), size: CGSize(width: 20 * max(0.85, scale), height: 20 * max(0.85, scale)))
            ball.position = o.ballRest
            ball.zPosition = 8
            s.field.addChild(ball)
            o.ball = ball
            let shooter = makeBear(s, height: 40 * max(0.85, scale), faceRight: true)
            shooter.position = CGPoint(x: -26 * max(0.85, scale), y: o.ballRest.y - 18)
            shooter.zPosition = 7
            s.field.addChild(shooter)

            // shot counter + dots
            let sl = label("SCHUSS 1/\(PowerShotGame.totalShots)", size: 13, color: UIColor(white: 1, alpha: 0.7))
            sl.horizontalAlignmentMode = .left
            sl.position = CGPoint(x: -w / 2 + 14, y: h / 2 - 34)
            sl.zPosition = 400
            s.node.addChild(sl)
            o.shotLabel = sl
            let dotSize: CGFloat = min(12, (w - 40) / CGFloat(PowerShotGame.totalShots) - 4)
            for i in 0..<PowerShotGame.totalShots {
                let d = SKSpriteNode(texture: Gfx.circle(8, UIColor(white: 1, alpha: 0.15)), size: CGSize(width: dotSize, height: dotSize))
                let total = CGFloat(PowerShotGame.totalShots) * (dotSize + 4)
                d.position = CGPoint(x: -total / 2 + (dotSize + 4) * (CGFloat(i) + 0.5), y: o.meterY + 24)
                d.zPosition = 10
                s.field.addChild(d)
                o.dots.append(d)
            }

            if !s.isCPU {
                let hint = SKNode()
                let l = label("TIPPEN IM GRÜNEN!", size: 15, color: UIColor(red: 0.3, green: 1, blue: 0.45, alpha: 1))
                l.position = CGPoint(x: 0, y: o.ballRest.y + 40)
                hint.addChild(l)
                hint.zPosition = 50
                hint.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.4, duration: 0.4), SKAction.fadeAlpha(to: 1, duration: 0.4)])))
                s.field.addChild(hint)
                o.hint = hint
            }
            newShot(s, o)
        }
        setActiveSeat(0)
    }

    private static func floorTexture(_ w: CGFloat, _ h: CGFloat) -> SKTexture {
        return Gfx.texture("power_floor\(Int(w))x\(Int(h))", size: CGSize(width: w, height: h), scale: 1) { ctx in
            Gfx.gradientColors(UIColor(red: 0.16, green: 0.12, blue: 0.04, alpha: 0.85), UIColor(red: 0.06, green: 0.05, blue: 0.08, alpha: 0.9), in: ctx, size: CGSize(width: w, height: h))
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.08).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: w * 0.2, y: h * 0.38, width: w * 0.6, height: w * 0.6))
        }
    }

    private static func barTexture(_ w: CGFloat) -> SKTexture {
        return Gfx.texture("power_bar\(Int(w))", size: CGSize(width: w, height: 20)) { ctx in
            let space = CGColorSpaceCreateDeviceRGB()
            let cols = [UIColor(red: 0.9, green: 0.15, blue: 0.2, alpha: 1).cgColor,
                        UIColor(red: 1, green: 0.75, blue: 0.1, alpha: 1).cgColor,
                        UIColor(red: 0.9, green: 0.15, blue: 0.2, alpha: 1).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: cols, locations: [0, 0.5, 1]) {
                let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: w, height: 20), cornerRadius: 10)
                ctx.addPath(path.cgPath)
                ctx.clip()
                ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: w, y: 0), options: [])
            }
        }
    }

    private func newShot(_ s: Seat, _ o: State) {
        let r = o.rand!
        o.locked = false
        o.width = max(0.07, 0.22 - CGFloat(o.shot) * 0.019)
        o.center = r.range(0.15 + o.width / 2, 0.85 - o.width / 2)
        o.speed = 0.75 + CGFloat(o.shot) * 0.13
        o.m = r.range(0, 1)
        o.dir = r.chance(0.5) ? 1 : -1
        o.green.size.width = o.width * o.meterW
        o.green.position.x = -o.meterW / 2 + o.center * o.meterW
        o.perfect.position.x = o.green.position.x
        o.shotLabel.text = "SCHUSS \(min(PowerShotGame.totalShots, o.shot + 1))/\(PowerShotGame.totalShots)"
        o.ball.removeAllActions()
        o.ball.position = o.ballRest
        o.ball.setScale(1)
        o.ball.alpha = 1
        o.keeper.position.x = 0
        // CPU plans its tap
        let err = CGFloat.random(in: -1...1) * (1.05 - CGFloat(s.skill)) * 0.2 + CGFloat.random(in: -0.015...0.015)
        o.cpuTarget = max(0.01, min(0.99, o.center + err))
        o.cpuArmed = Double.random(in: 0.5...1.1)
        o.idle = 0
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let o = st[seat.index]
        tap(seat, o)
    }

    private func tap(_ s: Seat, _ o: State) {
        if o.locked || o.done || phase != .playing { return }
        o.locked = true
        if let h = o.hint {
            h.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
            o.hint = nil
        }
        let d = abs(o.m - o.center)
        let half = o.width / 2
        var pts: Int
        if d <= half {
            pts = 10 - Int((d / half) * 3.99)
        } else {
            pts = max(0, 6 - Int((d - half) * 22))
        }
        pts = max(0, min(10, pts))
        addScore(s, pts)
        if pts >= 7 { addStat("goals", 1, seat: s) }
        o.marker.run(SKAction.sequence([SKAction.scaleY(to: 1.4, duration: 0.06), SKAction.scaleY(to: 1, duration: 0.1)]))
        let dotColor: UIColor = pts >= 10 ? UIColor.yellow : (pts >= 7 ? UIColor(red: 0.3, green: 1, blue: 0.4, alpha: 1) : (pts >= 4 ? UIColor.orange : UIColor.red))
        if o.shot < o.dots.count {
            o.dots[o.shot].texture = Gfx.circle(8, dotColor)
            o.dots[o.shot].run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.08), SKAction.scale(to: 1, duration: 0.12)]))
        }
        animateShot(s, o, pts: pts)
        o.shot += 1
        o.waitTimer = 1.25
        Sfx.shared.play("kick")
        if !s.isCPU { Haptic.tap(.heavy) }
    }

    private func animateShot(_ s: Seat, _ o: State, pts: Int) {
        let side: CGFloat = Bool.random() ? 1 : -1
        var target: CGPoint
        var text: String
        var color = s.color
        var after: SKAction = SKAction.fadeOut(withDuration: 0.2)
        var keeperX: CGFloat = 0
        if pts >= 10 {
            target = CGPoint(x: side * (o.goalW / 2 - 12), y: o.goalY + o.goalH - 12)
            text = "TRAUMTOR! +\(pts)"
            color = UIColor.yellow
            keeperX = -side * o.goalW * 0.25
        } else if pts >= 7 {
            target = CGPoint(x: side * o.goalW * 0.3, y: o.goalY + o.goalH * 0.35)
            text = "TOR! +\(pts)"
            keeperX = -side * o.goalW * 0.2
        } else if pts >= 4 {
            target = CGPoint(x: side * o.goalW / 2, y: o.goalY + o.goalH * 0.5)
            text = "PFOSTEN +\(pts)"
            color = UIColor.orange
            keeperX = side * o.goalW * 0.1
            after = SKAction.sequence([SKAction.move(by: CGVector(dx: -side * 40, dy: -50), duration: 0.3), SKAction.fadeOut(withDuration: 0.15)])
        } else {
            target = CGPoint(x: side * (o.goalW / 2 + 40), y: o.goalY + o.goalH + 30)
            text = pts > 0 ? "DANEBEN +\(pts)" : "DANEBEN"
            color = UIColor(white: 0.8, alpha: 1)
            keeperX = 0
        }
        let fly = SKAction.move(to: target, duration: 0.32)
        fly.timingMode = .easeOut
        o.ball.run(SKAction.sequence([
            SKAction.group([fly, SKAction.scale(to: 0.65, duration: 0.32), SKAction.rotate(byAngle: 8, duration: 0.32)]),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                s.floatText(text, at: CGPoint(x: 0, y: o.goalY - 26), color: color, size: 18)
                if pts >= 7 {
                    s.burst(at: target, color: color, count: pts >= 10 ? 22 : 12, speed: 120)
                    o.goal.run(SKAction.sequence([SKAction.moveBy(x: 0, y: 4, duration: 0.05), SKAction.moveBy(x: 0, y: -4, duration: 0.08)]))
                    Sfx.shared.play(pts >= 10 ? "goal" : "right")
                    if pts >= 10 { s.shake(4) }
                } else if pts >= 4 {
                    Sfx.shared.play("hit")
                } else {
                    Sfx.shared.play("miss")
                }
                _ = self
            },
            after
        ]))
        let km = SKAction.moveTo(x: keeperX, duration: 0.25)
        km.timingMode = .easeOut
        o.keeper.run(km)
    }

    private func advanceTurn() {
        for k in 1...max(1, n) {
            let j = (activeSeatIndex + k) % n
            if !st[j].done {
                st[j].idle = 0
                st[j].cpuArmed = 0.6
                setActiveSeat(j)
                return
            }
        }
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        for s in seats where s.index == activeSeatIndex {
            let o = st[s.index]
            if o.done { continue }
            if o.locked {
                o.waitTimer -= dt
                if o.waitTimer <= 0 {
                    if o.shot >= PowerShotGame.totalShots {
                        o.done = true
                        o.marker.alpha = 0.3
                        s.banner("FERTIG", color: s.color, size: 34, duration: 1.0)
                    } else {
                        newShot(s, o)
                    }
                }
                continue
            }
            let prev = o.m
            o.m += o.dir * o.speed * fdt
            if o.m > 1 { o.m = 2 - o.m; o.dir = -1 }
            if o.m < 0 { o.m = -o.m; o.dir = 1 }
            o.marker.position.x = -o.meterW / 2 + o.m * o.meterW
            o.idle += dt
            if !s.isCPU && o.idle > 7 {
                // nobody tapped: the shot goes off by itself
                tap(s, o)
                continue
            }
            if s.isCPU {
                o.cpuArmed -= dt
                if o.cpuArmed <= 0 {
                    let crossed = (prev - o.cpuTarget) * (o.m - o.cpuTarget) <= 0 && abs(prev - o.m) < 0.5
                    if crossed || o.cpuArmed < -4 { tap(s, o) }
                }
            }
        }
        if phase == .playing && st[activeSeatIndex].done && !st.allSatisfy({ $0.done }) {
            turnWait += dt
            if turnWait > 1.1 { turnWait = 0; advanceTurn() }
        }
        if phase == .playing && st.allSatisfy({ $0.done }) {
            finishGame()
        }
    }
}
