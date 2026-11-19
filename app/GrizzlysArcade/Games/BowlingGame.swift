import SpriteKit
import UIKit

/// Bären-Bowling: flick the ball up the lane. 10 pins, 5 throws per seat, score = pins down (+5 for a strike).
final class BowlingGame: MiniScene {
    override class var layout: SeatLayout { return .turns }
    private var turnWait = 0.0


    // MARK: Types

    private final class Pin {
        let node = SKNode()
        let visual = SKNode()
        let shadow: SKSpriteNode
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var home = CGPoint.zero
        var fallen = false
        var moving: Bool { return vel.dx != 0 || vel.dy != 0 }
        init(shadow: SKSpriteNode) { self.shadow = shadow }
    }

    private enum Mode { case ready, rolling, settling, done }

    private final class Lane {
        let seat: Seat
        var pins: [Pin] = []
        var ball = SKNode()
        var ballSpin = SKNode()
        var bpos = CGPoint.zero
        var bvel = CGVector.zero
        var spinAcc: CGFloat = 0
        var gutter = false
        var ballDone = false
        var mode: Mode = .ready
        var throwsDone = 0
        var timer = 0.0
        var rollT = 0.0
        var laneW: CGFloat = 200
        var gutW: CGFloat = 14
        var pr: CGFloat = 10
        var br: CGFloat = 14
        var y0: CGFloat = 0
        var backY: CGFloat = 0
        var headY: CGFloat = 0
        var sx: CGFloat = 28
        var counter: SKLabelNode?
        var hint: SKLabelNode?
        var bear: BearNode?
        var touch: UITouch?
        var touchStart = CGPoint.zero
        var samples: [(p: CGPoint, t: Double)] = []
        var idle = 0.0
        var cpuWait = 1.0
        var lastHit = -1.0
        var trailT = 0.0
        init(_ s: Seat) { seat = s }
    }

    private var lanes: [Lane] = []
    private let maxThrows = 5
    private var finishing = false

    // MARK: Setup

    override func setupGame() {
        for s in seats {
            let l = Lane(s)
            lanes.append(l)
            build(l)
            newBall(l)
        }
        setActiveSeat(0)
    }

    private func build(_ l: Lane) {
        let s = l.seat
        let w = s.w, h = s.h
        let narrow = w < 250
        l.laneW = narrow ? w * 0.82 : 250
        l.gutW = max(8, min(16, (w - l.laneW) / 2 - 1))
        l.pr = narrow ? 8.5 : 10.5
        l.br = l.pr * 1.45
        l.sx = l.pr * 2.7
        let dy = l.sx * 0.87
        l.backY = h / 2 - 46
        l.headY = l.backY - 3 * dy
        l.y0 = -h / 2 + l.br + 36

        // pin homes: head pin first, then rows of 2, 3, 4 (4 at the back)
        var homes: [CGPoint] = []
        for row in 0..<4 {
            let cnt = row + 1
            let y = l.headY + CGFloat(row) * dy
            for k in 0..<cnt {
                let x = (CGFloat(k) - CGFloat(cnt - 1) / 2) * l.sx
                homes.append(CGPoint(x: x, y: y))
            }
        }

        let tw = w - 6, th = h - 6
        let lane = SKSpriteNode(texture: laneTexture(w: tw, h: th, laneW: l.laneW, gut: l.gutW, homes: homes, pr: l.pr, idx: s.index, color: s.color), size: CGSize(width: tw, height: th))
        lane.zPosition = -30
        s.field.addChild(lane)

        for hp in homes {
            let sh = SKSpriteNode(texture: Gfx.shadow, size: CGSize(width: l.pr * 3.2, height: l.pr * 1.3))
            sh.position = CGPoint(x: 1.5, y: -2)
            sh.zPosition = -1
            let pin = Pin(shadow: sh)
            pin.home = hp
            pin.pos = hp
            pin.node.position = hp
            pin.node.zPosition = 20 - hp.y * 0.01
            pin.node.addChild(sh)
            let sp = SKSpriteNode(texture: pinTexture(pr: l.pr), size: CGSize(width: l.pr * 1.9, height: l.pr * 4.6))
            sp.anchorPoint = CGPoint(x: 0.5, y: 0.1)
            pin.visual.addChild(sp)
            pin.node.addChild(pin.visual)
            s.field.addChild(pin.node)
            l.pins.append(pin)
        }

        // counter on a dark pill
        let pillW: CGFloat = narrow ? 76 : 92
        let pill = SKSpriteNode(texture: Gfx.pill(pillW, 18, fill: UIColor(white: 0, alpha: 0.6), border: s.color.withAlphaComponent(0.6), corner: 9, gloss: false), size: CGSize(width: pillW, height: 18))
        pill.position = CGPoint(x: -w / 2 + 12 + pillW / 2, y: h / 2 - 36)
        pill.zPosition = 399
        s.node.addChild(pill)
        let c = MiniScene.label("WURF 1/\(maxThrows)", size: narrow ? 11 : 13, color: .white)
        c.position = pill.position
        c.zPosition = 400
        s.node.addChild(c)
        l.counter = c

        // hint
        let hl = MiniScene.label("NACH OBEN WISCHEN", size: narrow ? 11 : 14, color: .white)
        hl.position = CGPoint(x: 0, y: l.y0 + 62)
        hl.zPosition = 60
        let hbg = SKSpriteNode(texture: Gfx.pill(narrow ? 142 : 176, 22, fill: UIColor(white: 0, alpha: 0.55), corner: 11, gloss: false), size: CGSize(width: narrow ? 142 : 176, height: 22))
        hbg.zPosition = -1
        hl.addChild(hbg)
        s.field.addChild(hl)
        hl.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.45, duration: 0.5), SKAction.fadeAlpha(to: 1, duration: 0.5)])))
        hl.run(SKAction.sequence([SKAction.wait(forDuration: 6), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]), withKey: "hintOut")
        l.hint = hl

        // bear
        let bear = makeBear(s, height: narrow ? 38 : 50, faceRight: true)
        bear.position = CGPoint(x: -w / 2 + (narrow ? 20 : 34), y: -h / 2 + 8)
        bear.zPosition = 30
        s.field.addChild(bear)
        bear.startBob(amount: 2, duration: 0.5)
        l.bear = bear
    }

    private func laneTexture(w: CGFloat, h: CGFloat, laneW: CGFloat, gut: CGFloat, homes: [CGPoint], pr: CGFloat, idx: Int, color: UIColor) -> SKTexture {
        return Gfx.texture("bowl_lane_\(Int(w))_\(Int(h))_\(idx)", size: CGSize(width: w, height: h)) { ctx in
            let size = CGSize(width: w, height: h)
            let clip = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 15)
            ctx.addPath(clip.cgPath)
            ctx.clip()
            ctx.setFillColor(UIColor(red: 0.05, green: 0.04, blue: 0.1, alpha: 1).cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            let lx = (w - laneW) / 2
            // wood
            ctx.saveGState()
            ctx.clip(to: CGRect(x: lx, y: 0, width: laneW, height: h))
            Gfx.gradientColors(UIColor(red: 0.50, green: 0.30, blue: 0.14, alpha: 1), UIColor(red: 0.80, green: 0.55, blue: 0.30, alpha: 1), in: ctx, size: size)
            let rnd = Rand(seed: 31)
            let boards = 11
            for b in 0...boards {
                let x = lx + laneW * CGFloat(b) / CGFloat(boards)
                ctx.setStrokeColor(UIColor(white: 0, alpha: 0.18).cgColor)
                ctx.setLineWidth(0.8)
                ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: h)); ctx.strokePath()
                if b < boards {
                    ctx.setFillColor(UIColor(white: rnd.double() > 0.5 ? 1 : 0, alpha: CGFloat(rnd.range(0.02, 0.07))).cgColor)
                    ctx.fill(CGRect(x: x, y: 0, width: laneW / CGFloat(boards), height: h))
                }
            }
            // pin deck shade
            let deckTop = 0.0
            let deckBottom = h / 2 - (homes.map { $0.y }.min() ?? 0) + pr * 3
            ctx.setFillColor(UIColor(white: 1, alpha: 0.06).cgColor)
            ctx.fill(CGRect(x: lx, y: deckTop, width: laneW, height: deckBottom))
            // arrows
            ctx.setFillColor(UIColor(white: 0.15, alpha: 0.35).cgColor)
            let ay = h * 0.62
            for k in -2...2 {
                let ax = w / 2 + CGFloat(k) * laneW * 0.16
                let off = CGFloat(abs(k)) * 9
                ctx.move(to: CGPoint(x: ax, y: ay - 12 + off))
                ctx.addLine(to: CGPoint(x: ax - 5, y: ay + 6 + off))
                ctx.addLine(to: CGPoint(x: ax + 5, y: ay + 6 + off))
                ctx.closePath()
                ctx.fillPath()
            }
            // pin spots
            ctx.setFillColor(UIColor(white: 1, alpha: 0.3).cgColor)
            for hp in homes {
                let r: CGFloat = pr * 0.45
                ctx.fillEllipse(in: CGRect(x: w / 2 + hp.x - r, y: h / 2 - hp.y - r * 0.6, width: r * 2, height: r * 1.2))
            }
            // foul line
            ctx.setFillColor(UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.7).cgColor)
            ctx.fill(CGRect(x: lx, y: h - 26, width: laneW, height: 2))
            ctx.restoreGState()
            // gutters
            let gcols = [UIColor(white: 0.04, alpha: 1), UIColor(white: 0.16, alpha: 1)]
            for gx in [lx - gut, lx + laneW] {
                ctx.setFillColor(gcols[0].cgColor)
                ctx.fill(CGRect(x: gx, y: 0, width: gut, height: h))
                ctx.setFillColor(gcols[1].cgColor)
                ctx.fill(CGRect(x: gx + gut * 0.35, y: 0, width: gut * 0.3, height: h))
            }
            // neon edges
            ctx.setStrokeColor(color.withAlphaComponent(0.9).cgColor)
            ctx.setLineWidth(2)
            for ex in [lx, lx + laneW] {
                ctx.move(to: CGPoint(x: ex, y: 0)); ctx.addLine(to: CGPoint(x: ex, y: h)); ctx.strokePath()
            }
        }
    }

    private func pinTexture(pr: CGFloat) -> SKTexture {
        let W = pr * 1.9, H = pr * 4.6
        return Gfx.texture("bowl_pin_\(Int(pr * 10))", size: CGSize(width: W, height: H), scale: 3) { ctx in
            // y=0 is top of image. Base near bottom (anchor 0.1 => base at H*0.9)
            let cx = W / 2
            let baseY = H * 0.9
            let bodyR = W * 0.46
            let white = UIColor(white: 0.97, alpha: 1)
            // body: lower belly ellipse
            let belly = CGRect(x: cx - bodyR, y: baseY - bodyR * 2.6, width: bodyR * 2, height: bodyR * 2.6)
            // neck
            let neckW = W * 0.34
            let neck = CGRect(x: cx - neckW / 2, y: H * 0.18, width: neckW, height: baseY - bodyR * 1.4 - H * 0.18)
            // head
            let headR = W * 0.27
            let head = CGRect(x: cx - headR, y: H * 0.03, width: headR * 2, height: headR * 2)
            ctx.setFillColor(white.cgColor)
            ctx.fillEllipse(in: belly)
            ctx.fill(neck)
            ctx.fillEllipse(in: head)
            // shading
            ctx.saveGState()
            ctx.addEllipse(in: belly)
            ctx.addRect(neck)
            ctx.addEllipse(in: head)
            ctx.clip()
            ctx.setFillColor(UIColor(white: 0.55, alpha: 0.45).cgColor)
            ctx.fill(CGRect(x: cx + bodyR * 0.25, y: 0, width: W, height: H))
            ctx.setFillColor(UIColor(white: 1, alpha: 0.5).cgColor)
            ctx.fill(CGRect(x: cx - bodyR * 0.65, y: 0, width: bodyR * 0.2, height: H))
            // red stripes
            ctx.setFillColor(UIColor(red: 0.9, green: 0.1, blue: 0.15, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 0, y: H * 0.34, width: W, height: H * 0.045))
            ctx.fill(CGRect(x: 0, y: H * 0.41, width: W, height: H * 0.03))
            ctx.restoreGState()
            ctx.setStrokeColor(UIColor(white: 0.25, alpha: 0.6).cgColor)
            ctx.setLineWidth(0.6)
            ctx.strokeEllipse(in: belly)
            ctx.strokeEllipse(in: head)
        }
    }

    private func ballTexture(br: CGFloat, idx: Int, color: UIColor) -> SKTexture {
        let d = br * 2
        return Gfx.texture("bowl_ball_\(Int(br))_\(idx)", size: CGSize(width: d, height: d), scale: 3) { ctx in
            ctx.saveGState()
            ctx.addEllipse(in: CGRect(x: 0.5, y: 0.5, width: d - 1, height: d - 1))
            ctx.clip()
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let space = CGColorSpaceCreateDeviceRGB()
            let light = UIColor(red: min(1, r * 1.0 + 0.35), green: min(1, g + 0.35), blue: min(1, b + 0.35), alpha: 1)
            let dark = UIColor(red: r * 0.25, green: g * 0.25, blue: b * 0.25, alpha: 1)
            let cols = [light.cgColor, color.cgColor, dark.cgColor] as CFArray
            if let gr = CGGradient(colorsSpace: space, colors: cols, locations: [0, 0.45, 1]) {
                let c = CGPoint(x: br * 0.7, y: br * 0.7)
                ctx.drawRadialGradient(gr, startCenter: c, startRadius: 0, endCenter: CGPoint(x: br, y: br), endRadius: br * 1.15, options: [.drawsAfterEndLocation])
            }
            ctx.restoreGState()
            ctx.setStrokeColor(UIColor(white: 0, alpha: 0.6).cgColor)
            ctx.setLineWidth(1)
            ctx.strokeEllipse(in: CGRect(x: 0.5, y: 0.5, width: d - 1, height: d - 1))
        }
    }

    // MARK: Ball

    private func newBall(_ l: Lane) {
        let s = l.seat
        l.ball = SKNode()
        l.ballSpin = SKNode()
        l.bpos = CGPoint(x: 0, y: l.y0)
        l.bvel = .zero
        l.spinAcc = 0
        l.gutter = false
        l.ballDone = false
        l.mode = .ready
        l.idle = 0
        l.cpuWait = 0.8 + Double.random(in: 0...0.5)
        l.touch = nil
        l.samples = []
        let b = l.ball
        b.position = l.bpos
        b.zPosition = 40
        let sh = SKSpriteNode(texture: Gfx.shadow, size: CGSize(width: l.br * 3, height: l.br * 1.2))
        sh.position = CGPoint(x: 2, y: -l.br * 0.8)
        sh.zPosition = -2
        b.addChild(sh)
        let gl = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: l.br * 3.6, height: l.br * 3.6))
        gl.color = s.color
        gl.colorBlendFactor = 1
        gl.blendMode = .add
        gl.alpha = 0.45
        gl.zPosition = -1
        b.addChild(gl)
        let body = SKSpriteNode(texture: ballTexture(br: l.br, idx: s.index, color: s.color), size: CGSize(width: l.br * 2, height: l.br * 2))
        b.addChild(body)
        // finger holes rotate with the roll
        for (dx, dy) in [(-0.25, 0.3), (0.12, 0.38), (-0.02, 0.1)] as [(CGFloat, CGFloat)] {
            let hole = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: l.br * 0.28, height: l.br * 0.28))
            hole.color = UIColor(white: 0.05, alpha: 1)
            hole.colorBlendFactor = 1
            hole.alpha = 0.85
            hole.position = CGPoint(x: dx * l.br, y: dy * l.br)
            l.ballSpin.addChild(hole)
        }
        l.ballSpin.zPosition = 1
        b.addChild(l.ballSpin)
        let hi = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: l.br * 0.5, height: l.br * 0.5))
        hi.alpha = 0.55
        hi.position = CGPoint(x: -l.br * 0.35, y: l.br * 0.4)
        hi.zPosition = 2
        b.addChild(hi)
        b.setScale(0.2)
        b.run(SKAction.scale(to: 1, duration: 0.2))
        s.field.addChild(b)
        updateCounter(l)
    }

    private func updateCounter(_ l: Lane) {
        if l.mode == .done {
            l.counter?.text = "FERTIG"
        } else {
            let n = l.mode == .ready ? l.throwsDone + 1 : l.throwsDone
            l.counter?.text = "WURF \(min(maxThrows, max(1, n)))/\(maxThrows)"
        }
    }

    private func resetPins(_ l: Lane) {
        for (i, p) in l.pins.enumerated() {
            p.pos = p.home
            p.vel = .zero
            p.fallen = false
            p.node.position = p.home
            p.node.zPosition = 20 - p.home.y * 0.01
            p.visual.removeAllActions()
            p.visual.zRotation = 0
            p.visual.alpha = 1
            p.shadow.alpha = 1
            p.node.setScale(0.1)
            p.node.run(SKAction.sequence([SKAction.wait(forDuration: Double(i) * 0.025), SKAction.scale(to: 1.15, duration: 0.12), SKAction.scale(to: 1.0, duration: 0.08)]))
        }
    }

    private func pinsDown(_ l: Lane) -> Int { return l.pins.filter { $0.fallen }.count }

    // MARK: Launch

    private func launch(_ l: Lane, dir: CGVector, speed: CGFloat, spin: CGFloat) {
        guard l.mode == .ready else { return }
        l.bvel = CGVector(dx: dir.dx * speed, dy: dir.dy * speed)
        l.spinAcc = spin
        l.mode = .rolling
        l.rollT = 0
        l.throwsDone += 1
        l.hint?.removeAction(forKey: "hintOut")
        l.hint?.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
        l.hint = nil
        l.bear?.squash()
        Sfx.shared.play("kick")
        if !l.seat.isCPU { Haptic.tap(.medium) }
        updateCounter(l)
    }

    private func cpuThrow(_ l: Lane) {
        let sk = CGFloat(l.seat.skill)
        let sx0 = CGFloat.random(in: -1...1) * l.laneW * 0.18
        l.bpos.x = sx0
        l.ball.position = l.bpos
        let side: CGFloat = Bool.random() ? 1 : -1
        let tx = side * l.sx * 0.28
        let ty = l.headY
        var ang = atan2(tx - sx0, ty - l.bpos.y)
        ang += CGFloat.random(in: -1...1) * (1 - sk) * 0.17
        let sp = CGFloat.random(in: 360...470)
        launch(l, dir: CGVector(dx: sin(ang), dy: cos(ang)), speed: sp, spin: 0)
    }

    // MARK: Input

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let l = lanes[seat.index]
        guard l.mode == .ready, l.touch == nil else { return }
        l.touch = touch
        l.touchStart = at
        l.samples = [(at, elapsed)]
        l.idle = 0
        Haptic.tap(.light)
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let l = lanes[seat.index]
        guard l.mode == .ready, l.touch === touch else { return }
        l.samples.append((at, elapsed))
        if l.samples.count > 40 { l.samples.removeFirst() }
        let lim = l.laneW / 2 - l.br
        let x = max(-lim, min(lim, (at.x - l.touchStart.x) * 0.9))
        let y = l.y0 + max(0, min(70, at.y - l.touchStart.y))
        l.bpos = CGPoint(x: x, y: y)
        l.ball.position = l.bpos
        l.ballSpin.zRotation = (at.y - l.touchStart.y) * 0.03
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let l = lanes[seat.index]
        guard l.mode == .ready, l.touch === touch else { return }
        l.touch = nil
        l.samples.append((at, elapsed))
        let now = elapsed
        let recent = l.samples.filter { now - $0.t < 0.14 }
        func reject() {
            l.bpos = CGPoint(x: 0, y: l.y0)
            l.ball.run(SKAction.move(to: l.bpos, duration: 0.15))
            seat.floatText("SCHWUNG!", at: CGPoint(x: 0, y: l.y0 + 40), color: .white, size: 14)
        }
        guard recent.count >= 2, let f = recent.first, let e = recent.last else { reject(); return }
        let dt = max(0.02, e.t - f.t)
        let vx = (e.p.x - f.p.x) / CGFloat(dt)
        let vy = (e.p.y - f.p.y) / CGFloat(dt)
        let sp = hypot(vx, vy)
        if sp < 250 || vy < 120 { reject(); return }
        var ang = atan2(vx, vy)
        ang = max(-0.5, min(0.5, ang))
        let speed = max(300, min(540, sp * 0.4))
        // curve: change of direction over the swipe
        var spin: CGFloat = 0
        let pts = l.samples.filter { now - $0.t < 0.3 }
        if pts.count >= 5 {
            let mid = pts[pts.count / 2]
            let a1 = atan2(mid.p.x - pts[0].p.x, max(1, mid.p.y - pts[0].p.y))
            let a2 = atan2(e.p.x - mid.p.x, max(1, e.p.y - mid.p.y))
            let diff = a2 - a1
            if abs(diff) > 0.1 { spin = max(-120, min(120, diff * 240)) }
        }
        launch(l, dir: CGVector(dx: sin(ang), dy: cos(ang)), speed: speed, spin: spin)
    }

    // MARK: Update

    private func advanceTurn() {
        for k in 1...max(1, n) {
            let j = (activeSeatIndex + k) % n
            if lanes[j].mode != .done {
                lanes[j].idle = 0
                lanes[j].cpuWait = 0.8 + Double.random(in: 0...0.5)
                setActiveSeat(j)
                return
            }
        }
    }

    override func gameUpdate(_ dt: Double) {
        for l in lanes where l.seat.index == activeSeatIndex {
            switch l.mode {
            case .ready:
                l.idle += dt
                if l.seat.isCPU {
                    l.cpuWait -= dt
                    if l.cpuWait <= 0 { cpuThrow(l) }
                } else if l.idle > 14 && l.touch == nil {
                    let ang = CGFloat.random(in: -0.12...0.12)
                    launch(l, dir: CGVector(dx: sin(ang), dy: cos(ang)), speed: 400, spin: 0)
                }
            case .rolling:
                l.rollT += dt
                step(l, dt)
                if l.ballDone && !l.pins.contains(where: { $0.moving }) || l.rollT > 6 {
                    for p in l.pins { p.vel = .zero }
                    if !l.ballDone { removeBall(l) }
                    l.mode = .settling
                    l.timer = 0.9
                    evaluate(l)
                }
            case .settling:
                l.timer -= dt
                if l.timer <= 0 { next(l) }
            case .done:
                break
            }
        }
        if !finishing && lanes[activeSeatIndex].mode == .done {
            turnWait += dt
            if turnWait > 1.1 { turnWait = 0; advanceTurn() }
        }
        if !finishing && elapsed > 70 * Double(max(1, n)) { finishAll() }
    }

    private func step(_ l: Lane, _ dt: Double) {
        let sub = 3
        let h = CGFloat(dt) / CGFloat(sub)
        let pr = l.pr, br = l.br
        let halfLane = l.laneW / 2
        for _ in 0..<sub {
            // ball
            if !l.ballDone {
                if !l.gutter {
                    l.bvel.dx += l.spinAcc * h
                }
                l.bpos.x += l.bvel.dx * h
                l.bpos.y += l.bvel.dy * h
                if l.gutter {
                    let target = (l.bpos.x < 0 ? -1 : 1) * (halfLane + l.gutW / 2)
                    l.bpos.x += (target - l.bpos.x) * min(1, 12 * h)
                } else if abs(l.bpos.x) > halfLane - br * 0.35 && l.bpos.y < l.headY - 25 {
                    l.gutter = true
                    l.bvel.dx = 0
                    l.spinAcc = 0
                    l.seat.floatText("RINNE!", at: CGPoint(x: l.bpos.x * 0.5, y: l.bpos.y + 40), color: UIColor(white: 0.85, alpha: 1), size: 16)
                    Sfx.shared.play("miss")
                    l.ball.run(SKAction.scale(to: 0.85, duration: 0.2))
                }
                if !l.gutter {
                    // wall clamp on the pin deck
                    let lim = halfLane - br * 0.5
                    if l.bpos.x > lim { l.bpos.x = lim; l.bvel.dx = -abs(l.bvel.dx) * 0.5 }
                    if l.bpos.x < -lim { l.bpos.x = -lim; l.bvel.dx = abs(l.bvel.dx) * 0.5 }
                }
                // ball vs pins
                if !l.gutter {
                    for p in l.pins {
                        let dx = p.pos.x - l.bpos.x
                        let dy = p.pos.y - l.bpos.y
                        var d = hypot(dx, dy)
                        let minD = pr + br * 0.9
                        if d >= minD { continue }
                        var nx = dx / max(d, 0.001), ny = dy / max(d, 0.001)
                        if d < 0.001 { nx = 0; ny = 1; d = 0.001 }
                        let ov = minD - d
                        p.pos.x += nx * ov * 0.8
                        p.pos.y += ny * ov * 0.8
                        l.bpos.x -= nx * ov * 0.2
                        l.bpos.y -= ny * ov * 0.2
                        let vr = (l.bvel.dx - p.vel.dx) * nx + (l.bvel.dy - p.vel.dy) * ny
                        if vr > 0 {
                            let mb: CGFloat = 6, mp: CGFloat = 1
                            let j = (1 + 0.7) * vr / (1 / mb + 1 / mp)
                            l.bvel.dx -= j / mb * nx
                            l.bvel.dy -= j / mb * ny
                            p.vel.dx += j / mp * nx
                            p.vel.dy += j / mp * ny
                            topple(l, p, strength: vr)
                        }
                    }
                }
                // ball visual
                let sp = hypot(l.bvel.dx, l.bvel.dy)
                l.ballSpin.zRotation += h * sp * 0.05
                if l.bpos.y > l.backY + pr * 2 + 6 || (sp < 25 && l.bpos.y > l.headY - 10) || l.bpos.y < -l.seat.h / 2 {
                    removeBall(l)
                }
            }
            // pins
            let lim = halfLane - pr
            for p in l.pins where p.moving {
                let sp = hypot(p.vel.dx, p.vel.dy)
                let nsp = sp * CGFloat(exp(-3.6 * Double(h)))
                if nsp < 9 { p.vel = .zero; continue }
                let k = nsp / sp
                p.vel.dx *= k; p.vel.dy *= k
                p.pos.x += p.vel.dx * h
                p.pos.y += p.vel.dy * h
                if p.pos.x > lim { p.pos.x = lim; p.vel.dx = -abs(p.vel.dx) * 0.5 }
                if p.pos.x < -lim { p.pos.x = -lim; p.vel.dx = abs(p.vel.dx) * 0.5 }
                if p.pos.y > l.backY + pr + 12 { p.pos.y = l.backY + pr + 12; p.vel.dy = -abs(p.vel.dy) * 0.5 }
                if p.pos.y < -l.seat.h / 2 + pr { p.pos.y = -l.seat.h / 2 + pr; p.vel.dy = abs(p.vel.dy) * 0.5 }
            }
            // pin vs pin
            for i in 0..<l.pins.count {
                for j in (i + 1)..<max(i + 1, l.pins.count) {
                    let a = l.pins[i], b = l.pins[j]
                    if !a.moving && !b.moving { continue }
                    var dx = b.pos.x - a.pos.x
                    var dy = b.pos.y - a.pos.y
                    var d = hypot(dx, dy)
                    if d >= 2 * pr { continue }
                    if d < 0.001 { dx = 0; dy = 1; d = 1 }
                    let nx = dx / d, ny = dy / d
                    let ov = (2 * pr - d) / 2
                    a.pos.x -= nx * ov; a.pos.y -= ny * ov
                    b.pos.x += nx * ov; b.pos.y += ny * ov
                    let vr = (a.vel.dx - b.vel.dx) * nx + (a.vel.dy - b.vel.dy) * ny
                    if vr > 0 {
                        let j2 = vr * 1.7 / 2
                        a.vel.dx -= j2 * nx; a.vel.dy -= j2 * ny
                        b.vel.dx += j2 * nx; b.vel.dy += j2 * ny
                        if vr > 8 { topple(l, a, strength: vr); topple(l, b, strength: vr) }
                    }
                }
            }
        }
        // sync nodes
        l.ball.position = l.bpos
        for p in l.pins {
            p.node.position = p.pos
            if p.fallen { p.node.zPosition = 15 } else { p.node.zPosition = 20 - p.pos.y * 0.01 }
        }
        // ball trail
        if !l.ballDone {
            l.trailT -= dt
            if l.trailT <= 0 {
                l.trailT = 0.03
                let t = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: br * 1.1, height: br * 1.1))
                t.color = l.seat.color
                t.colorBlendFactor = 1
                t.blendMode = .add
                t.alpha = 0.5
                t.position = l.bpos
                t.zPosition = 5
                l.seat.field.addChild(t)
                t.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.35), SKAction.scale(to: 0.3, duration: 0.35)]), SKAction.removeFromParent()]))
            }
        }
    }

    private func topple(_ l: Lane, _ p: Pin, strength: CGFloat) {
        if p.fallen { return }
        p.fallen = true
        let dirx = p.vel.dx, diry = p.vel.dy
        var ang = atan2(-dirx, diry)
        if hypot(dirx, diry) < 1 { ang = 1.4 }
        p.visual.run(SKAction.sequence([
            SKAction.rotate(toAngle: ang, duration: 0.22, shortestUnitArc: true),
            SKAction.fadeAlpha(to: 0.6, duration: 0.5)
        ]))
        p.shadow.run(SKAction.fadeAlpha(to: 0.3, duration: 0.3))
        if elapsed - l.lastHit > 0.045 {
            l.lastHit = elapsed
            Sfx.shared.play("hit")
        }
        l.seat.burst(at: p.pos, color: UIColor(white: 1, alpha: 1), count: 4, speed: 60)
        if strength > 150 && !l.seat.isCPU { Haptic.tap(.light) }
        if strength > 250 { l.seat.shake(2.5) }
    }

    private func removeBall(_ l: Lane) {
        if l.ballDone { return }
        l.ballDone = true
        l.ball.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.25), SKAction.scale(to: 0.6, duration: 0.25)]), SKAction.removeFromParent()]))
    }

    // MARK: Scoring

    private func evaluate(_ l: Lane) {
        let s = l.seat
        let n = pinsDown(l)
        var gain = n
        let strike = n == l.pins.count
        if strike { gain += 5 }
        if gain > 0 { addScore(s, gain) }
        addStat("hits", n, seat: s)
        let cx: CGFloat = 0
        let cy = l.headY + 30
        if strike {
            s.banner("STRIKE!", color: UIColor.yellow, size: 42, duration: 0.7)
            s.flash(UIColor.yellow, alpha: 0.3)
            s.burst(at: CGPoint(x: cx, y: cy), color: UIColor.yellow, count: 30, speed: 180)
            s.burst(at: CGPoint(x: cx, y: cy), color: s.color, count: 20, speed: 130)
            s.floatText("+\(gain)", at: CGPoint(x: cx, y: cy - 30), color: UIColor.yellow, size: 30)
            Sfx.shared.play("fanfare")
            Haptic.good()
            l.bear?.celebrate()
            addStat("goals", 1, seat: s)
        } else if n > 0 {
            s.floatText("+\(n)", at: CGPoint(x: cx, y: cy - 20), color: s.color, size: 26)
            Sfx.shared.play(n >= 7 ? "right" : "pop")
            if n >= 7 { s.burst(at: CGPoint(x: cx, y: cy), color: s.color, count: 14, speed: 110) }
        } else {
            s.floatText(l.gutter ? "RINNE" : "DANEBEN", at: CGPoint(x: cx, y: cy - 20), color: UIColor(white: 0.85, alpha: 1), size: 16)
            Sfx.shared.play("wrong")
        }
    }

    private func next(_ l: Lane) {
        if l.throwsDone >= maxThrows {
            l.mode = .done
            updateCounter(l)
            l.bear?.stopBob()
            if lanes.allSatisfy({ $0.mode == .done }) { finishAll() }
        } else {
            resetPins(l)
            newBall(l)
        }
    }

    private func finishAll() {
        if finishing { return }
        finishing = true
        run(SKAction.sequence([SKAction.wait(forDuration: 0.4), SKAction.run { [weak self] in self?.finishGame() }]))
    }
}
