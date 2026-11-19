import SpriteKit

/// Tauziehen: tap as fast as you can in your half. Whoever pulls the flag to their own edge wins the round. Best of 3.
final class TugWarGame: MiniScene {

    private enum RoundState { case ready, active, over }

    private final class Puller {
        let seat: Seat
        var bear: BearNode!
        var ring: SKSpriteNode!
        var heat: CGFloat = 0
        var wins = 0
        var roundTaps = 0
        var totalPull: CGFloat = 0
        var nextTap: Double = 0
        var phase = Double.random(in: 0..<6.28)
        var restUntil: Double = 0
        var rateJitter = Double.random(in: 0.92...1.08)
        init(seat: Seat) { self.seat = seat }
    }

    private var pullers: [Puller] = []
    private var state: RoundState = .ready
    private var round = 1
    private var f: CGFloat = 0 // -1...1, +1 = bottom seat's edge
    private var fv: CGFloat = 0
    private var readyT: Double = 0
    private var roundT: Double = 0
    private var overT: Double = 0
    private var winnerIdx = 0
    private var R: CGFloat = 340
    private var rope: SKNode!
    private var knots: [SKSpriteNode] = []
    private var flag: SKNode!
    private var flagSprite: SKSpriteNode!
    private var flagGlow: SKSpriteNode!
    private var roundLabel: SKLabelNode!
    private var clock: Double = 0
    private let knotSp: CGFloat = 38
    private let threshold: CGFloat = 0.35
    private let roundLimit: Double = 20

    override func setupGame() {
        duration = 0
        useCountdown = true
        R = min(340, (bandY - bottomInset) - 36)
        if seats.count < 2 { return }
        if seats.count > 2 { for i in 2..<seats.count { seats[i].knockOut("—") } }
        for i in 0..<2 { pullers.append(Puller(seat: seats[i])) }

        // rope in scene space
        rope = SKNode()
        rope.position = CGPoint(x: SW / 2, y: bandY)
        rope.zPosition = 5
        world.addChild(rope)
        let len = R * 2 + 60
        let ropeTex = Gfx.texture("tugwar_rope", size: CGSize(width: 10, height: 64), scale: 2) { ctx in
            ctx.setFillColor(UIColor(red: 0.78, green: 0.6, blue: 0.34, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 64))
            ctx.setStrokeColor(UIColor(red: 0.45, green: 0.3, blue: 0.14, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            var y: CGFloat = -4
            while y < 68 {
                ctx.move(to: CGPoint(x: 0, y: y + 8))
                ctx.addLine(to: CGPoint(x: 10, y: y))
                y += 8
            }
            ctx.strokePath()
        }
        let ropeSprite = SKSpriteNode(texture: ropeTex, size: CGSize(width: 9, height: len))
        rope.addChild(ropeSprite)
        let ropeGlow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 34, height: len))
        ropeGlow.color = UIColor(red: 1, green: 0.8, blue: 0.4, alpha: 1)
        ropeGlow.colorBlendFactor = 1
        ropeGlow.blendMode = .add
        ropeGlow.alpha = 0.25
        ropeGlow.zPosition = -1
        rope.addChild(ropeGlow)
        let nk = Int(len / knotSp) + 2
        for _ in 0..<nk {
            let k = SKSpriteNode(texture: Gfx.circle(5, UIColor(red: 0.5, green: 0.33, blue: 0.15, alpha: 1)), size: CGSize(width: 12, height: 12))
            k.zPosition = 1
            rope.addChild(k)
            knots.append(k)
        }

        // win lines
        for i in 0..<2 {
            let s = seats[i]
            let y = bandY + (i == 0 ? -R : R)
            let line = SKSpriteNode(texture: Gfx.rect(SW - 30, 3, s.color), size: CGSize(width: SW - 30, height: 3))
            line.position = CGPoint(x: SW / 2, y: y)
            line.alpha = 0.8
            line.zPosition = 4
            world.addChild(line)
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: SW, height: 50))
            g.color = s.color
            g.colorBlendFactor = 1
            g.blendMode = .add
            g.alpha = 0.45
            g.position = line.position
            g.zPosition = 4
            world.addChild(g)
            g.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.25, duration: 0.7), SKAction.fadeAlpha(to: 0.5, duration: 0.7)])))
        }
        // centre mark
        let mid = SKSpriteNode(texture: Gfx.rect(60, 2, UIColor(white: 1, alpha: 0.5)), size: CGSize(width: 60, height: 2))
        mid.position = CGPoint(x: SW / 2, y: bandY)
        mid.zPosition = 4
        mid.alpha = 0.5
        world.addChild(mid)

        // flag
        flag = SKNode()
        flag.zPosition = 40
        flag.position = CGPoint(x: SW / 2, y: bandY)
        world.addChild(flag)
        let ftex = Gfx.texture("tugwar_flag", size: CGSize(width: 76, height: 26), scale: 2) { ctx in
            let path = UIBezierPath(roundedRect: CGRect(x: 2, y: 2, width: 72, height: 22), cornerRadius: 6)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            ctx.setStrokeColor(UIColor(white: 0.15, alpha: 1).cgColor)
            ctx.setLineWidth(3)
            ctx.addPath(path.cgPath)
            ctx.strokePath()
            ctx.setFillColor(UIColor(white: 0.15, alpha: 0.9).cgColor)
            var x: CGFloat = 10
            while x < 66 { ctx.fill(CGRect(x: x, y: 6, width: 7, height: 14)); x += 14 }
        }
        flagSprite = SKSpriteNode(texture: ftex, size: CGSize(width: 76, height: 26))
        flagSprite.color = .white
        flagSprite.colorBlendFactor = 0
        flagSprite.zPosition = 2
        flag.addChild(flagSprite)
        flagGlow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 120, height: 70))
        flagGlow.blendMode = .add
        flagGlow.color = .white
        flagGlow.colorBlendFactor = 1
        flagGlow.alpha = 0.6
        flag.addChild(flagGlow)

        // bears + tap rings
        for p in pullers {
            let s = p.seat
            let bh: CGFloat = min(88, s.h * 0.24)
            let bear = makeBear(s, height: bh, faceRight: true)
            let bw = bh * bearAspect
            bear.position = CGPoint(x: -bw * 0.34, y: -s.h / 2 + 34)
            bear.zPosition = 20
            s.node.addChild(bear)
            p.bear = bear
            bear.startBob(amount: 2, duration: 0.3)

            let ring = SKSpriteNode(texture: Gfx.circle(34, s.color.withAlphaComponent(0.18), ring: s.color), size: CGSize(width: 68, height: 68))
            ring.position = CGPoint(x: 92, y: -s.h / 2 + 70)
            ring.zPosition = 15
            s.node.addChild(ring)
            p.ring = ring
            let rg = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 130, height: 130))
            rg.color = s.color
            rg.colorBlendFactor = 1
            rg.blendMode = .add
            rg.alpha = 0.4
            ring.addChild(rg)
            let t = MiniScene.label("TAP", size: 20, color: .white)
            t.zPosition = 1
            ring.addChild(t)

            if !s.isCPU {
                let hint = MiniScene.label("SCHNELL TIPPEN!", size: 16, color: .white)
                hint.position = CGPoint(x: 0, y: -s.h / 2 + 140)
                hint.zPosition = 420
                s.node.addChild(hint)
                hint.run(SKAction.sequence([SKAction.wait(forDuration: 5), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
            }
        }

        roundLabel = MiniScene.label("RUNDE 1/3", size: 13, color: Theme.uiOrange)
        roundLabel.position = CGPoint(x: SW - 62, y: bandY)
        hud.addChild(roundLabel)
        updateKnots()
    }

    private func sgn(_ i: Int) -> CGFloat { return i == 0 ? 1 : -1 }

    override func gameStarted() {
        if pullers.count < 2 { finishGame(); return }
        beginRound(first: true)
    }

    private func beginRound(first: Bool) {
        f = 0
        fv = 0
        roundT = 0
        for p in pullers {
            p.heat = 0
            p.roundTaps = 0
            p.nextTap = clock + 0.4
            p.restUntil = 0
            p.rateJitter = Double.random(in: 0.92...1.08)
        }
        state = .ready
        readyT = first ? 0.5 : 1.5
        roundLabel.text = "RUNDE \(round)/3"
        if !first || true {
            bannerAll("RUNDE \(round)", color: .white, size: 40, duration: 0.9)
        }
    }

    // MARK: input

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        guard seat.index < 2, state == .active else { return }
        tap(pullers[seat.index], human: true)
    }

    private func tap(_ p: Puller, human: Bool) {
        p.heat += 1
        p.roundTaps += 1
        let s = p.seat
        // bear pull animation
        p.bear.removeAction(forKey: "pull")
        p.bear.run(SKAction.sequence([
            SKAction.group([SKAction.rotate(toAngle: 0.16, duration: 0.05), SKAction.moveBy(x: -5, y: 0, duration: 0.05)]),
            SKAction.group([SKAction.rotate(toAngle: 0.0, duration: 0.1), SKAction.moveBy(x: 5, y: 0, duration: 0.1)])
        ]), withKey: "pull")
        p.bear.squash()
        p.ring.removeAction(forKey: "pulse")
        p.ring.setScale(1.0)
        p.ring.run(SKAction.sequence([SKAction.scale(to: 1.22, duration: 0.04), SKAction.scale(to: 1.0, duration: 0.08)]), withKey: "pulse")
        // dust at the feet
        let bw = p.bear.height * bearAspect
        let feet = CGPoint(x: p.bear.position.x - bw * 0.25, y: p.bear.position.y + 2)
        for _ in 0..<2 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: CGFloat.random(in: 7...12), height: CGFloat.random(in: 7...12)))
            d.color = UIColor(red: 0.85, green: 0.78, blue: 0.62, alpha: 1)
            d.colorBlendFactor = 1
            d.alpha = 0.6
            d.position = CGPoint(x: feet.x + CGFloat.random(in: -8...8), y: feet.y)
            d.zPosition = 18
            s.node.addChild(d)
            d.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -34 ... -8), y: CGFloat.random(in: 6...22), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 2.0, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        if human {
            Sfx.shared.play("tap")
            Haptic.tap()
        }
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        if pullers.count < 2 { return }
        clock += dt
        let cdt = CGFloat(dt)
        switch state {
        case .ready:
            readyT -= dt
            if readyT <= 0 {
                state = .active
                roundT = 0
                for p in pullers { p.nextTap = clock + Double.random(in: 0.05...0.25) }
                bannerAll("ZIEH!", color: Theme.uiOrange, size: 46, duration: 0.4)
                Sfx.shared.play("go")
            }
        case .active:
            roundT += dt
            // CPU
            for p in pullers where p.seat.isCPU {
                if clock >= p.nextTap {
                    if clock < p.restUntil { p.nextTap = p.restUntil; continue }
                    tap(p, human: false)
                    let sk = p.seat.skill
                    let wob = 1 + 0.22 * sin(clock * 2.3 + p.phase) + 0.1 * sin(clock * 5.1 + p.phase * 2)
                    let rate = (3.0 + 4.6 * sk) * p.rateJitter * wob
                    var iv = 1.0 / max(1.5, rate) * Double.random(in: 0.8...1.2)
                    if Double.random(in: 0...1) < 0.05 * (1.2 - sk) {
                        iv += Double.random(in: 0.25...0.5)
                    }
                    p.nextTap = clock + iv
                }
            }
            // heat decay + pull
            let decay = CGFloat(exp(-dt / 0.5))
            for p in pullers { p.heat *= decay }
            let diff = pullers[0].heat - pullers[1].heat
            var target: CGFloat = 0
            if abs(diff) > threshold {
                target = (abs(diff) - threshold) * 0.22 * (diff > 0 ? 1 : -1)
            }
            fv += (target - fv) * min(1, cdt * 6)
            f += fv * cdt
            let moved = abs(fv * cdt)
            if fv > 0 { pullers[0].totalPull += moved } else { pullers[1].totalPull += moved }
            f = max(-1, min(1, f))
            updateKnots()
            if f >= 1 { endRound(winner: 0) }
            else if f <= -1 { endRound(winner: 1) }
            else if roundT >= roundLimit {
                if abs(f) > 0.02 { endRound(winner: f > 0 ? 0 : 1) }
                else {
                    let a = pullers[0].roundTaps, b = pullers[1].roundTaps
                    endRound(winner: a == b ? Int.random(in: 0...1) : (a > b ? 0 : 1))
                }
            }
        case .over:
            overT -= dt
            if overT <= 0 {
                if pullers[0].wins >= 2 || pullers[1].wins >= 2 || round >= 3 {
                    state = .ready
                    readyT = 999
                    finishAll()
                } else {
                    round += 1
                    beginRound(first: false)
                }
            }
        }
    }

    private func updateKnots() {
        flag.position = CGPoint(x: SW / 2, y: bandY - f * R)
        let a = abs(f)
        let lead = f >= 0 ? pullers[0].seat.color : pullers[1].seat.color
        flagGlow.color = a > 0.05 ? lead : .white
        flagGlow.alpha = 0.45 + 0.4 * a
        flagGlow.size = CGSize(width: 120 + 40 * a, height: 70 + 20 * a)
        flagSprite.color = lead
        flagSprite.colorBlendFactor = 0.35 * a
        let len = R * 2 + 60
        let span = CGFloat(knots.count) * knotSp
        for (i, k) in knots.enumerated() {
            var y = CGFloat(i) * knotSp - f * R
            y = y.truncatingRemainder(dividingBy: span)
            if y < 0 { y += span }
            k.position = CGPoint(x: 0, y: y - len / 2 - (span - len) / 2)
        }
    }

    private func endRound(winner: Int) {
        state = .over
        overT = 2.2
        winnerIdx = winner
        let w = pullers[winner]
        let l = pullers[1 - winner]
        w.wins += 1
        setScore(w.seat, w.wins)
        // shake
        for p in pullers { p.seat.shake(9) }
        var acts: [SKAction] = []
        for _ in 0..<6 {
            acts.append(SKAction.move(to: CGPoint(x: CGFloat.random(in: -7...7), y: CGFloat.random(in: -7...7)), duration: 0.035))
        }
        acts.append(SKAction.move(to: .zero, duration: 0.035))
        world.run(SKAction.sequence(acts), withKey: "wshake")
        flashAll(w.seat.color, alpha: 0.3)
        w.seat.banner("RUNDE GEWONNEN!", color: UIColor.yellow, size: 30, duration: 1.2)
        l.seat.banner("VERLOREN", color: UIColor(white: 1, alpha: 0.8), size: 30, duration: 1.2)
        w.seat.burst(at: CGPoint(x: 0, y: -w.seat.h / 2 + 120), color: w.seat.color, count: 24, speed: 190)
        w.bear.celebrate()
        // loser topples back
        l.bear.run(SKAction.group([SKAction.rotate(toAngle: 0.5, duration: 0.2), SKAction.moveBy(x: -12, y: 0, duration: 0.2)]))
        l.bear.run(SKAction.sequence([SKAction.wait(forDuration: 1.6), SKAction.group([SKAction.rotate(toAngle: 0, duration: 0.3), SKAction.moveBy(x: 12, y: 0, duration: 0.3)])]))
        // dust cloud at the flag
        for _ in 0..<14 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 12, height: 12))
            d.color = UIColor(red: 0.85, green: 0.78, blue: 0.62, alpha: 1)
            d.colorBlendFactor = 1
            d.alpha = 0.7
            d.position = flag.position
            d.zPosition = 45
            world.addChild(d)
            let a = CGFloat.random(in: 0..<(2 * CGFloat.pi))
            let dist = CGFloat.random(in: 30...90)
            d.run(SKAction.sequence([
                SKAction.group([SKAction.moveBy(x: cos(a) * dist, y: sin(a) * dist, duration: 0.6), SKAction.fadeOut(withDuration: 0.6), SKAction.scale(to: 2.5, duration: 0.6)]),
                SKAction.removeFromParent()
            ]))
        }
        for p in pullers where !p.seat.isCPU {
            if p === w { Sfx.shared.play("win"); Haptic.good() } else { Sfx.shared.play("lose"); Haptic.bad() }
        }
        if pullers.allSatisfy({ $0.seat.isCPU }) { Sfx.shared.play("horn") }
    }

    private func finishAll() {
        let a = pullers[0], b = pullers[1]
        var s0 = a.wins * 10, s1 = b.wins * 10
        if s0 == s1 { if a.totalPull >= b.totalPull { s0 += 1 } else { s1 += 1 } }
        finishGame(scores: [s0, s1])
    }
}
