import SpriteKit

/// Tap-Sprint: alternate left / right taps to sprint to the finish line.
final class TapSprintGame: MiniScene {

    fileprivate final class State {
        var dist: CGFloat = 0          // metres
        var vel: CGFloat = 0           // m/s
        var lastSide = 0               // -1 left, 1 right, 0 none
        var stumble = 0.0
        var finishedPlace = -1
        var startY: CGFloat = 0
        var finishY: CGFloat = 0
        var bear: BearNode!
        var leftBtn = SKSpriteNode()
        var rightBtn = SKSpriteNode()
        var markers: [SKSpriteNode] = []
        var barBottom: CGFloat = 0
        var barTop: CGFloat = 0
        var meterLabel = SKLabelNode()
        var cpuT = 0.0
        var running = false
    }

    private var st: [State] = []
    private let raceLength: CGFloat = 60
    private var finishOrder: [Int] = []
    private let placePoints = [100, 80, 60, 40]

    private static var finishTex: SKTexture {
        return Gfx.texture("sprint_finish", size: CGSize(width: 120, height: 12)) { ctx in
            for i in 0..<20 {
                for j in 0..<2 {
                    ctx.setFillColor(((i + j) % 2 == 0 ? UIColor.white : UIColor.black).cgColor)
                    ctx.fill(CGRect(x: CGFloat(i) * 6, y: CGFloat(j) * 6, width: 6, height: 6))
                }
            }
        }
    }

    override func setupGame() {
        duration = 25
        st = []
        finishOrder = []
        for s in seats {
            let g = State()
            let btnH: CGFloat = min(70, s.h * 0.18)
            let btnY = -s.h / 2 + 10 + btnH / 2
            g.startY = btnY + btnH / 2 + 34
            g.finishY = s.h / 2 - 52
            let trackW = min(s.w * 0.5, 130)
            let trackX: CGFloat = -min(14, s.w * 0.06)
            // track
            let trackH = g.finishY - g.startY + 40
            let track = SKSpriteNode(texture: Gfx.pill(trackW, trackH, fill: UIColor(red: 0.55, green: 0.18, blue: 0.12, alpha: 0.85), border: s.color.withAlphaComponent(0.8), corner: 8), size: CGSize(width: trackW, height: trackH))
            track.position = CGPoint(x: trackX, y: (g.finishY + g.startY) / 2)
            track.zPosition = -5
            s.field.addChild(track)
            // distance marks every 10 m
            for m in stride(from: 10, to: Int(raceLength), by: 10) {
                let y = g.startY + CGFloat(m) / raceLength * (g.finishY - g.startY)
                let line = SKSpriteNode(color: UIColor(white: 1, alpha: 0.35), size: CGSize(width: trackW - 8, height: 2))
                line.position = CGPoint(x: trackX, y: y)
                line.zPosition = -4
                s.field.addChild(line)
                let l = label("\(m)", size: 10, color: UIColor(white: 1, alpha: 0.5))
                l.horizontalAlignmentMode = .left
                l.position = CGPoint(x: trackX + trackW / 2 + 4, y: y)
                s.field.addChild(l)
            }
            let fin = SKSpriteNode(texture: TapSprintGame.finishTex, size: CGSize(width: trackW - 4, height: 10))
            fin.position = CGPoint(x: trackX, y: g.finishY)
            fin.zPosition = -3
            s.field.addChild(fin)
            let start = SKSpriteNode(color: .white, size: CGSize(width: trackW - 4, height: 3))
            start.position = CGPoint(x: trackX, y: g.startY)
            start.zPosition = -3
            s.field.addChild(start)
            // bear
            let bh = min(48, s.w * 0.22)
            let bear = makeBear(s, height: bh)
            bear.position = CGPoint(x: trackX, y: g.startY - 6)
            bear.zPosition = 10
            s.field.addChild(bear)
            bear.startBob(amount: 2, duration: 0.4)
            g.bear = bear
            // buttons
            let bw = s.w / 2 - 16
            let lb = MiniScene.button("◀ L", w: bw, h: btnH, color: s.color, fontSize: min(24, btnH * 0.38))
            lb.position = CGPoint(x: -s.w / 4, y: btnY)
            lb.zPosition = 20
            s.field.addChild(lb)
            let rb = MiniScene.button("R ▶", w: bw, h: btnH, color: s.color, fontSize: min(24, btnH * 0.38))
            rb.position = CGPoint(x: s.w / 4, y: btnY)
            rb.zPosition = 20
            s.field.addChild(rb)
            g.leftBtn = lb
            g.rightBtn = rb
            // progress bar of all runners on the right side
            g.barBottom = g.startY
            g.barTop = g.finishY
            let barX = s.w / 2 - 12
            let bar = SKSpriteNode(color: UIColor(white: 1, alpha: 0.15), size: CGSize(width: 4, height: g.barTop - g.barBottom))
            bar.position = CGPoint(x: barX, y: (g.barTop + g.barBottom) / 2)
            s.field.addChild(bar)
            for o in seats {
                let mk = SKSpriteNode(texture: Gfx.circle(6, o.color, ring: o.index == s.index ? UIColor.white : nil), size: CGSize(width: o.index == s.index ? 13 : 10, height: o.index == s.index ? 13 : 10))
                mk.position = CGPoint(x: barX, y: g.barBottom)
                mk.zPosition = o.index == s.index ? 6 : 5
                s.field.addChild(mk)
                g.markers.append(mk)
            }
            g.meterLabel = label("0 m", size: 12, color: UIColor(white: 1, alpha: 0.75))
            g.meterLabel.horizontalAlignmentMode = .left
            g.meterLabel.position = CGPoint(x: -s.w / 2 + 14, y: s.h / 2 - 34)
            g.meterLabel.zPosition = 30
            s.node.addChild(g.meterLabel)
            st.append(g)
            let hint = label("ABWECHSELND TIPPEN!", size: min(15, s.w * 0.072), color: .white)
            hint.position = CGPoint(x: 0, y: g.startY + 50)
            hint.zPosition = 40
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.6), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private func press(_ s: Seat, side: Int) {
        let g = st[s.index]
        if g.finishedPlace >= 0 { return }
        let btn: SKSpriteNode = side < 0 ? g.leftBtn : g.rightBtn
        btn.removeAction(forKey: "press")
        btn.run(SKAction.sequence([SKAction.scale(to: 0.9, duration: 0.04), SKAction.scale(to: 1, duration: 0.07)]), withKey: "press")
        if g.stumble > 0 { return }
        if side == g.lastSide {
            // same side twice: stumble
            g.vel *= 0.3
            g.stumble = 0.35
            g.bear.squash()
            s.floatText("STOLPERT!", at: CGPoint(x: g.bear.position.x, y: g.bear.position.y + 50), color: UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1), size: 15)
            Sfx.shared.play("wrong")
            if !s.isCPU { Haptic.bad() }
            g.lastSide = 0
            return
        }
        g.lastSide = side
        g.vel = min(11, g.vel + 1.0)
        if !s.isCPU { Haptic.tap() }
        Sfx.shared.play("tap")
    }

    private func finishRunner(_ s: Seat) {
        let g = st[s.index]
        g.finishedPlace = finishOrder.count
        finishOrder.append(s.index)
        let pts = placePoints[min(g.finishedPlace, placePoints.count - 1)]
        setScore(s, pts)
        g.bear.stopRun()
        g.bear.stopBob()
        g.bear.celebrate()
        s.banner(g.finishedPlace == 0 ? "1. PLATZ!" : "\(g.finishedPlace + 1). PLATZ", color: g.finishedPlace == 0 ? .yellow : .white, size: 32, duration: 1.2)
        s.burst(at: CGPoint(x: g.bear.position.x, y: g.finishY), color: .yellow, count: 18, speed: 120)
        Sfx.shared.play(g.finishedPlace == 0 ? "fanfare" : "whistle")
        if !s.isCPU { Haptic.good() }
    }

    override func gameUpdate(_ dt: Double) {
        let d = CGFloat(dt)
        for s in seats {
            let g = st[s.index]
            if g.finishedPlace >= 0 { continue }
            if s.isCPU { cpu(s, dt) }
            if g.stumble > 0 { g.stumble -= dt }
            // decay
            g.vel *= max(0, 1 - 1.2 * d)
            if g.vel < 0.05 { g.vel = 0 }
            g.dist = min(raceLength, g.dist + g.vel * d)
            let y = g.startY + g.dist / raceLength * (g.finishY - g.startY)
            g.bear.position.y = y - 6
            if g.vel > 0.8 && !g.running {
                g.running = true
                g.bear.stopBob()
                g.bear.startRun(speed: 0.12)
            } else if g.vel <= 0.8 && g.running {
                g.running = false
                g.bear.stopRun()
                g.bear.startBob(amount: 2, duration: 0.4)
            }
            g.meterLabel.text = "\(Int(g.dist)) m"
            if g.dist >= raceLength { finishRunner(s) }
        }
        // progress markers
        for s in seats {
            let g = st[s.index]
            for o in seats {
                let og = st[o.index]
                g.markers[o.index].position.y = g.barBottom + og.dist / raceLength * (g.barTop - g.barBottom)
            }
        }
        if finishOrder.count >= seats.count { endRace() }
    }

    private func cpu(_ s: Seat, _ dt: Double) {
        let g = st[s.index]
        g.cpuT -= dt
        if g.cpuT > 0 { return }
        let rate = 3.0 + s.skill * 4.5
        g.cpuT = 1.0 / rate * Double.random(in: 0.8...1.2)
        var side = g.lastSide == 0 ? 1 : -g.lastSide
        if g.lastSide != 0 && Double.random(in: 0..<1) < (1 - s.skill) * 0.07 { side = g.lastSide } // mistake
        press(s, side: side)
    }

    private func endRace() {
        if finished { return }
        var scores: [Int] = []
        for s in seats {
            let g = st[s.index]
            if g.finishedPlace >= 0 {
                scores.append(placePoints[min(g.finishedPlace, placePoints.count - 1)])
            } else {
                scores.append(Int(g.dist / raceLength * 39))
            }
        }
        for (i, s) in seats.enumerated() { setScore(s, scores[i]) }
        finishGame(scores: scores)
    }

    override func timeUp() { endRace() }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        press(seat, side: at.x < 0 ? -1 : 1)
    }
}
