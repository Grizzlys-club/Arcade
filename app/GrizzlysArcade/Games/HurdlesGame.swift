import SpriteKit

/// Hürdenlauf: the bear runs automatically, tap to jump over neon hurdles.
final class HurdlesGame: MiniScene {
    private final class Runner {
        let seat: Seat
        var dist: CGFloat = 0
        var bonus: CGFloat = 0
        var stumble: Double = 0
        var airT: Double = -1
        var combo = 0
        var cleared = 0
        var next = 0
        var finished = false
        var place = 0
        var bear: BearNode!
        var shadow: SKSpriteNode!
        var hurdles: [SKNode] = []
        var stripes: [SKSpriteNode] = []
        var finishLine: SKSpriteNode!
        var comboLabel: SKLabelNode!
        var cpuErr: Double = 0
        var cpuSkip = false
        var cpuJumped = -1
        var failed: Set<Int> = []
        init(_ s: Seat) { seat = s }
    }

    private var runners: [Runner] = []
    private var hurdleDist: [CGFloat] = []
    private var finishDist: CGFloat = 0
    private var finishedCount = 0
    private var endTimer: Double = -1
    private let airTime = 0.6
    private let numHurdles = 12
    private let stripeGap: CGFloat = 44
    private var cpuRand = Rand(seed: 77)

    override func setupGame() {
        duration = 40
        let r = newRand()
        var d: CGFloat = 260
        for _ in 0..<numHurdles {
            hurdleDist.append(d)
            d += r.range(175, 235)
        }
        finishDist = d + 40
        cpuRand = Rand(seed: UInt64.random(in: 1...1_000_000))
        let colors = [Theme.uiPink, Theme.uiBlue, Theme.uiGreen, Theme.uiOrange]
        for s in seats {
            let ru = Runner(s)
            runners.append(ru)
            buildTrack(ru, colors: colors)
            let hint = MiniScene.label("TIPPEN = SPRUNG", size: min(22, s.w * 0.11), color: .white)
            hint.position = CGPoint(x: 0, y: s.h * 0.12)
            hint.zPosition = 450
            s.node.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.2), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            hint.run(SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.4), SKAction.scale(to: 0.95, duration: 0.4)])))
        }
    }

    private func bearY(_ s: Seat) -> CGFloat { return -s.h / 2 + s.h * 0.24 }

    private func buildTrack(_ ru: Runner, colors: [UIColor]) {
        let s = ru.seat
        let tw = s.w * 0.88
        let track = SKSpriteNode(color: UIColor(white: 1, alpha: 0.05), size: CGSize(width: tw, height: s.h))
        track.zPosition = -30
        s.field.addChild(track)
        for sx: CGFloat in [-1, 1] {
            let edge = SKSpriteNode(color: s.color, size: CGSize(width: 3, height: s.h))
            edge.position = CGPoint(x: sx * tw / 2, y: 0)
            edge.zPosition = -29
            s.field.addChild(edge)
            let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 26, height: s.h))
            g.color = s.color
            g.colorBlendFactor = 1
            g.alpha = 0.35
            g.blendMode = .add
            g.position = edge.position
            g.zPosition = -29
            s.field.addChild(g)
        }
        let count = Int(s.h / stripeGap) + 3
        for _ in 0..<count {
            let st = SKSpriteNode(color: UIColor(white: 1, alpha: 0.07), size: CGSize(width: tw - 6, height: 3))
            st.zPosition = -28
            s.field.addChild(st)
            ru.stripes.append(st)
        }
        // lane dashes (static dots on centre lines scroll with stripes)
        // finish line
        let fw = tw - 6
        let fk = "hurdles_finish\(Int(fw))"
        let tex = Gfx.texture(fk, size: CGSize(width: fw, height: 20)) { ctx in
            let sq: CGFloat = 10
            var xi = 0
            var x: CGFloat = 0
            while x < fw {
                for row in 0..<2 {
                    ctx.setFillColor(((xi + row) % 2 == 0 ? UIColor.white : UIColor(white: 0.1, alpha: 1)).cgColor)
                    ctx.fill(CGRect(x: x, y: CGFloat(row) * sq, width: sq, height: sq))
                }
                x += sq
                xi += 1
            }
        }
        ru.finishLine = SKSpriteNode(texture: tex, size: CGSize(width: fw, height: 20))
        ru.finishLine.zPosition = -20
        s.field.addChild(ru.finishLine)
        // hurdles
        let hw = tw * 0.78
        for (i, _) in hurdleDist.enumerated() {
            let c = colors[i % colors.count]
            let n = SKNode()
            let bar = SKSpriteNode(texture: Gfx.rect(hw, 7, c, corner: 3), size: CGSize(width: hw, height: 7))
            bar.position = CGPoint(x: 0, y: 12)
            bar.zPosition = 1
            n.addChild(bar)
            for sx: CGFloat in [-1, 1] {
                let post = SKSpriteNode(texture: Gfx.rect(5, 15, UIColor(white: 0.85, alpha: 1), corner: 2), size: CGSize(width: 5, height: 15))
                post.position = CGPoint(x: sx * hw * 0.46, y: 6)
                n.addChild(post)
            }
            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: hw * 1.3, height: 44))
            glow.color = c
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.6
            glow.position = CGPoint(x: 0, y: 12)
            n.addChild(glow)
            n.zPosition = 5
            n.isHidden = true
            s.field.addChild(n)
            ru.hurdles.append(n)
        }
        ru.shadow = SKSpriteNode(texture: Gfx.shadow, size: CGSize(width: 56, height: 20))
        ru.shadow.zPosition = 4
        ru.shadow.position = CGPoint(x: 0, y: bearY(s) - 2)
        s.field.addChild(ru.shadow)
        let bh = min(58, s.w * 0.3)
        ru.bear = makeBear(s, height: bh, faceRight: false)
        ru.bear.position = CGPoint(x: 0, y: bearY(s))
        ru.bear.zPosition = 6
        s.field.addChild(ru.bear)
        let cl = MiniScene.label("", size: min(18, s.w * 0.09), color: UIColor.yellow)
        cl.position = CGPoint(x: -s.w / 2 + 14, y: s.h / 2 - 36)
        cl.horizontalAlignmentMode = .left
        cl.zPosition = 400
        s.node.addChild(cl)
        ru.comboLabel = cl
        layoutRunner(ru)
    }

    override func gameStarted() {
        for ru in runners { ru.bear.startRun(speed: 0.12) }
    }

    private func layoutRunner(_ ru: Runner) {
        let s = ru.seat
        let by = bearY(s)
        let top = s.h / 2 + 30
        for (i, hd) in hurdleDist.enumerated() {
            let y = by + (hd - ru.dist)
            let node = ru.hurdles[i]
            if ru.failed.contains(i) { continue }
            let vis = y < top && y > -s.h / 2 - 30
            node.isHidden = !vis
            node.position = CGPoint(x: 0, y: y)
        }
        let fy = by + (finishDist - ru.dist)
        ru.finishLine.position = CGPoint(x: 0, y: fy)
        ru.finishLine.isHidden = fy > top || fy < -s.h / 2 - 20
        let off = ru.dist.truncatingRemainder(dividingBy: stripeGap)
        for (k, st) in ru.stripes.enumerated() {
            st.position = CGPoint(x: 0, y: -s.h / 2 + CGFloat(k) * stripeGap - off)
        }
    }

    private func speed(_ ru: Runner) -> CGFloat {
        if ru.finished { return 0 }
        let slow: CGFloat = ru.stumble > 0 ? (0.35 + 0.65 * CGFloat(1 - min(1, ru.stumble / 0.9))) : 1
        return (135 + ru.bonus) * slow
    }

    private func jump(_ ru: Runner) {
        if ru.finished || ru.airT >= 0 { return }
        ru.airT = 0
        Sfx.shared.play("jump")
        if !ru.seat.isCPU { Haptic.tap(.light) }
        ru.bear.visual.run(SKAction.sequence([SKAction.scaleY(to: 1.15, duration: 0.08), SKAction.scaleY(to: 1.0, duration: 0.15)]), withKey: "stretch")
        ru.seat.burst(at: CGPoint(x: 0, y: bearY(ru.seat)), color: UIColor(white: 1, alpha: 0.8), count: 5, speed: 50)
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        jump(runners[seat.index])
    }

    private func jumpHeight(_ ru: Runner) -> CGFloat {
        if ru.airT < 0 { return 0 }
        let p = CGFloat(ru.airT / airTime)
        return 4 * 46 * p * (1 - p)
    }

    override func gameUpdate(_ dt: Double) {
        for ru in runners {
            let s = ru.seat
            // CPU
            if s.isCPU && !ru.finished && ru.next < hurdleDist.count && ru.airT < 0 {
                let remain = hurdleDist[ru.next] - ru.dist
                if ru.cpuJumped != ru.next {
                    let sp = max(60, speed(ru))
                    if remain <= sp * CGFloat(airTime / 2 + ru.cpuErr) {
                        ru.cpuJumped = ru.next
                        if !ru.cpuSkip { jump(ru) }
                    }
                }
            }
            if ru.stumble > 0 { ru.stumble = max(0, ru.stumble - dt) }
            let v = speed(ru)
            ru.dist += v * CGFloat(dt)
            if ru.airT >= 0 {
                ru.airT += dt
                if ru.airT >= airTime {
                    ru.airT = -1
                    ru.bear.squash()
                    s.burst(at: CGPoint(x: 0, y: bearY(s)), color: UIColor(white: 1, alpha: 0.7), count: 6, speed: 60)
                }
            }
            let hgt = jumpHeight(ru)
            ru.bear.position = CGPoint(x: 0, y: bearY(s) + hgt)
            let sc = 1 - hgt / 120
            ru.shadow.setScale(max(0.5, sc))
            ru.shadow.alpha = max(0.4, sc)
            // hurdle crossing
            while ru.next < hurdleDist.count && ru.dist >= hurdleDist[ru.next] && !ru.finished {
                let i = ru.next
                ru.next += 1
                let ok = jumpHeight(ru) > 14
                let hy = bearY(s)
                if ok {
                    ru.cleared += 1
                    ru.combo += 1
                    ru.bonus = min(100, ru.bonus + 12)
                    addScore(s, 1)
                    addStat("hits", 1, seat: s)
                    s.floatText(ru.combo > 1 ? "+1  x\(ru.combo)" : "+1", at: CGPoint(x: 0, y: hy + 70), color: Theme.uiGreen, size: 20)
                    s.burst(at: CGPoint(x: 0, y: hy), color: Theme.uiGreen, count: 8, speed: 90)
                    Sfx.shared.play("coin")
                    if !s.isCPU { Haptic.tap(.medium) }
                    let n = ru.hurdles[i]
                    n.run(SKAction.sequence([SKAction.scale(to: 1.15, duration: 0.08), SKAction.scale(to: 1, duration: 0.12)]))
                } else {
                    ru.combo = 0
                    ru.bonus = 0
                    ru.stumble = 0.9
                    ru.failed.insert(i)
                    s.shake(5)
                    s.flash(.red, alpha: 0.25, duration: 0.3)
                    s.floatText("AUTSCH", at: CGPoint(x: 0, y: hy + 70), color: UIColor.red, size: 20)
                    s.burst(at: CGPoint(x: 0, y: hy), color: Theme.uiPink, count: 12, speed: 120)
                    Sfx.shared.play("hit")
                    if !s.isCPU { Haptic.bad() }
                    ru.bear.run(SKAction.sequence([SKAction.rotate(byAngle: 0.35, duration: 0.07), SKAction.rotate(byAngle: -0.35, duration: 0.15)]))
                    let n = ru.hurdles[i]
                    n.isHidden = false
                    n.run(SKAction.sequence([
                        SKAction.group([SKAction.rotate(byAngle: 1.2, duration: 0.4), SKAction.moveBy(x: 30, y: 40, duration: 0.4), SKAction.fadeOut(withDuration: 0.4)]),
                        SKAction.hide()
                    ]))
                }
                ru.comboLabel.text = ru.combo >= 2 ? "SERIE \(ru.combo)" : ""
                if ru.next < hurdleDist.count {
                    let q = 1 - s.skill
                    ru.cpuErr = Double(cpuRand.range(-1, 1)) * (0.02 + q * 0.26)
                    ru.cpuSkip = cpuRand.chance(q * 0.18)
                }
            }
            if ru.next == 0 && ru.cpuErr == 0 && s.isCPU {
                let q = 1 - s.skill
                ru.cpuErr = Double(cpuRand.range(-1, 1)) * (0.02 + q * 0.26)
            }
            layoutRunner(ru)
            if !ru.finished && ru.dist >= finishDist { finish(ru) }
        }
        if endTimer >= 0 {
            endTimer -= dt
            if endTimer <= 0 { finishGame() }
        }
    }

    private func finish(_ ru: Runner) {
        ru.finished = true
        ru.place = finishedCount + 1
        finishedCount += 1
        let bonus = ru.place == 1 ? 5 : (ru.place == 2 ? 3 : (ru.place == 3 ? 1 : 0))
        let s = ru.seat
        addScore(s, bonus)
        ru.bear.stopRun()
        ru.bear.celebrate()
        ru.comboLabel.text = ""
        s.banner("PLATZ \(ru.place)", color: ru.place == 1 ? UIColor.yellow : s.color, size: 34, duration: 1.4)
        if bonus > 0 { s.floatText("+\(bonus)", at: CGPoint(x: 0, y: bearY(s) + 90), color: UIColor.yellow, size: 26) }
        s.burst(at: CGPoint(x: 0, y: bearY(s) + 30), color: UIColor.yellow, count: 22, speed: 160)
        Sfx.shared.play(ru.place == 1 ? "fanfare" : "whistle")
        if !s.isCPU { Haptic.good() }
        if finishedCount >= seats.count { endTimer = 1.2 }
    }
}
