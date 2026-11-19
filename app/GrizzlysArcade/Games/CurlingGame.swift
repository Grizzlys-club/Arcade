import SpriteKit
import UIKit

/// Eis-Curling: slingshot a stone towards the rings. 5 stones per seat, score = sum of ring points of the stones that stay in the house.
final class CurlingGame: MiniScene {
    override class var layout: SeatLayout { return .turns }
    private var turnWait = 0.0


    // MARK: Types

    private final class Stone {
        let node = SKNode()
        let spin = SKNode()
        var pos = CGPoint.zero
        var vel = CGVector.zero
        var out = false
        var moving: Bool { return vel.dx != 0 || vel.dy != 0 }
    }

    private enum Mode { case ready, sliding, settling, done }

    private final class Pad {
        let seat: Seat
        var stones: [Stone] = []
        var thrown = 0
        var mode: Mode = .ready
        var cur: Stone?
        var timer = 0.0
        var tx: CGFloat = 0
        var ty: CGFloat = 0
        var R: CGFloat = 0
        var r: CGFloat = 12
        var startY: CGFloat = 0
        var dots: [SKSpriteNode] = []
        var ghost: SKSpriteNode?
        var pull: SKSpriteNode?
        var counter: SKLabelNode?
        var hint: SKLabelNode?
        var anchor: CGPoint?
        var touch: UITouch?
        var trailT = 0.0
        var bear: BearNode?
        var lastHit = -1.0
        var idle = 0.0
        var cpuWait = 0.8
        var slideT = 0.0
        var prevTotal = 0
        init(_ s: Seat) { seat = s }
    }

    private var pads: [Pad] = []
    private let mu: CGFloat = 90
    private let maxStones = 5
    private var finishing = false

    // MARK: Setup

    override func setupGame() {
        for s in seats {
            let p = Pad(s)
            pads.append(p)
            build(p)
            spawnStone(p)
        }
        setActiveSeat(0)
    }

    private func build(_ p: Pad) {
        let s = p.seat
        let w = s.w, h = s.h
        p.r = w < 250 ? 11 : 13
        p.R = min(w * 0.36, 56)
        p.tx = 0
        p.ty = h / 2 - 32 - p.R
        p.startY = -h / 2 + p.r + 32

        // ice
        let ice = SKSpriteNode(texture: iceTexture(w: w - 6, h: h - 6, ty: p.ty, R: p.R, r: p.r, idx: s.index), size: CGSize(width: w - 6, height: h - 6))
        ice.zPosition = -30
        s.field.addChild(ice)

        // rings
        let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: p.R * 3.0, height: p.R * 3.0))
        glow.color = s.color
        glow.colorBlendFactor = 1
        glow.blendMode = .add
        glow.alpha = 0.5
        glow.position = CGPoint(x: p.tx, y: p.ty)
        glow.zPosition = -29
        s.field.addChild(glow)
        glow.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.28, duration: 1.1), SKAction.fadeAlpha(to: 0.55, duration: 1.1)])))

        let rings = SKSpriteNode(texture: ringTexture(R: p.R, idx: s.index, color: s.color), size: CGSize(width: p.R * 2, height: p.R * 2))
        rings.position = CGPoint(x: p.tx, y: p.ty)
        rings.zPosition = -28
        s.field.addChild(rings)
        let fs: CGFloat = 9
        for (txt, f) in [("1", CGFloat(0.84)), ("2", 0.54), ("3", 0.29)] {
            let l = MiniScene.label(txt, size: fs, color: UIColor(white: 1, alpha: 0.75))
            l.position = CGPoint(x: p.tx + p.R * f, y: p.ty)
            l.zPosition = -27
            s.field.addChild(l)
        }
        let five = MiniScene.label("5", size: 10, color: UIColor(white: 0.1, alpha: 0.8))
        five.position = CGPoint(x: p.tx, y: p.ty)
        five.zPosition = -27
        s.field.addChild(five)

        // counter
        let c = MiniScene.label("STEIN 1/\(maxStones)", size: w < 250 ? 11 : 13, color: s.color)
        c.horizontalAlignmentMode = .left
        c.position = CGPoint(x: -w / 2 + 14, y: h / 2 - 34)
        c.zPosition = 400
        c.alpha = 0.95
        s.node.addChild(c)
        p.counter = c

        // aim helpers
        for i in 0..<14 {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 6, height: 6))
            d.color = .white
            d.colorBlendFactor = 1
            d.blendMode = .add
            d.alpha = 0
            d.zPosition = 20
            s.field.addChild(d)
            p.dots.append(d)
            _ = i
        }
        let g = SKSpriteNode(texture: Gfx.circle(p.r, UIColor(white: 1, alpha: 0.12), ring: .white), size: CGSize(width: p.r * 2, height: p.r * 2))
        g.alpha = 0
        g.zPosition = 19
        s.field.addChild(g)
        p.ghost = g
        let pl = SKSpriteNode(texture: Gfx.rect(4, 4, .white, corner: 2), size: CGSize(width: 4, height: 10))
        pl.anchorPoint = CGPoint(x: 0.5, y: 0)
        pl.color = s.color
        pl.colorBlendFactor = 1
        pl.blendMode = .add
        pl.alpha = 0
        pl.zPosition = 18
        s.field.addChild(pl)
        p.pull = pl

        // hint
        let hl = MiniScene.label("ZIEHEN & LOSLASSEN", size: w < 250 ? 11 : 14, color: .white)
        hl.position = CGPoint(x: 0, y: p.startY + 50)
        hl.zPosition = 60
        s.field.addChild(hl)
        hl.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.4, duration: 0.5), SKAction.fadeAlpha(to: 1, duration: 0.5)])))
        hl.run(SKAction.sequence([SKAction.wait(forDuration: 6), SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]), withKey: "hintOut")
        p.hint = hl

        // bear
        let bear = makeBear(s, height: w < 250 ? 40 : 50, faceRight: true)
        bear.position = CGPoint(x: -w / 2 + (w < 250 ? 24 : 34), y: -h / 2 + 8)
        bear.zPosition = 30
        s.field.addChild(bear)
        bear.startBob(amount: 2, duration: 0.5)
        p.bear = bear
    }

    private func iceTexture(w: CGFloat, h: CGFloat, ty: CGFloat, R: CGFloat, r: CGFloat, idx: Int) -> SKTexture {
        return Gfx.texture("curl_ice_\(Int(w))_\(Int(h))_\(idx)", size: CGSize(width: w, height: h)) { ctx in
            let size = CGSize(width: w, height: h)
            let clip = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 15)
            ctx.addPath(clip.cgPath)
            ctx.clip()
            Gfx.gradientColors(UIColor(red: 0.20, green: 0.36, blue: 0.56, alpha: 1), UIColor(red: 0.07, green: 0.12, blue: 0.24, alpha: 1), in: ctx, size: size)
            let rnd = Rand(seed: 77)
            for _ in 0..<26 {
                let x = rnd.range(0, w)
                let y0 = rnd.range(0, h)
                let len = rnd.range(30, 140)
                ctx.setStrokeColor(UIColor(red: 0.8, green: 0.95, blue: 1, alpha: CGFloat(rnd.range(0.04, 0.16))).cgColor)
                ctx.setLineWidth(rnd.range(0.6, 1.8))
                ctx.move(to: CGPoint(x: x, y: y0))
                ctx.addLine(to: CGPoint(x: x + rnd.range(-6, 6), y: y0 + len))
                ctx.strokePath()
            }
            // soft light around the house
            let space = CGColorSpaceCreateDeviceRGB()
            let cols = [UIColor(white: 1, alpha: 0.16).cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: space, colors: cols, locations: [0, 1]) {
                let c = CGPoint(x: w / 2, y: h / 2 - ty)
                ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: R * 2.2, options: [])
            }
            // centre line + tee line + throw line
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.14).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: w / 2, y: 0)); ctx.addLine(to: CGPoint(x: w / 2, y: h)); ctx.strokePath()
            let ky = h / 2 - ty
            ctx.move(to: CGPoint(x: 0, y: ky)); ctx.addLine(to: CGPoint(x: w, y: ky)); ctx.strokePath()
            ctx.setStrokeColor(UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 0.45).cgColor)
            ctx.setLineWidth(1.5)
            let by = h / 2 - (ty + R + r * 0.5)
            ctx.move(to: CGPoint(x: 0, y: by)); ctx.addLine(to: CGPoint(x: w, y: by)); ctx.strokePath()
            ctx.setStrokeColor(UIColor(white: 1, alpha: 0.3).cgColor)
            let hy = h - 22
            ctx.move(to: CGPoint(x: 12, y: hy)); ctx.addLine(to: CGPoint(x: w - 12, y: hy)); ctx.strokePath()
        }
    }

    private func ringTexture(R: CGFloat, idx: Int, color: UIColor) -> SKTexture {
        return Gfx.texture("curl_rings_\(Int(R))_\(idx)", size: CGSize(width: R * 2, height: R * 2)) { ctx in
            let radii: [CGFloat] = [1.0, 0.68, 0.40, 0.18]
            let cols: [UIColor] = [color.withAlphaComponent(0.5), UIColor(white: 1, alpha: 0.38), color.withAlphaComponent(0.85), UIColor(white: 1, alpha: 0.95)]
            for (i, f) in radii.enumerated() {
                let rr = R * f
                let rect = CGRect(x: R - rr, y: R - rr, width: rr * 2, height: rr * 2)
                ctx.setBlendMode(.clear)
                ctx.fillEllipse(in: rect)
                ctx.setBlendMode(.normal)
                ctx.setFillColor(cols[i].cgColor)
                ctx.fillEllipse(in: rect)
                ctx.setStrokeColor(UIColor(white: 1, alpha: 0.7).cgColor)
                ctx.setLineWidth(1.2)
                ctx.strokeEllipse(in: rect.insetBy(dx: 0.6, dy: 0.6))
            }
        }
    }

    private func stoneTexture(r: CGFloat, idx: Int, color: UIColor) -> SKTexture {
        let d = r * 2
        return Gfx.texture("curl_stone_\(Int(r))_\(idx)", size: CGSize(width: d, height: d), scale: 3) { ctx in
            let rect = CGRect(x: 0.5, y: 0.5, width: d - 1, height: d - 1)
            ctx.saveGState()
            ctx.addEllipse(in: rect)
            ctx.clip()
            Gfx.gradientColors(UIColor(white: 0.72, alpha: 1), UIColor(white: 0.32, alpha: 1), in: ctx, size: CGSize(width: d, height: d))
            ctx.restoreGState()
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(max(2, r * 0.22))
            ctx.strokeEllipse(in: rect.insetBy(dx: r * 0.11, dy: r * 0.11))
            // handle
            let hr = r * 0.5
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: r - hr, y: r - hr, width: hr * 2, height: hr * 2))
            ctx.setFillColor(UIColor(white: 1, alpha: 0.85).cgColor)
            ctx.fill(CGRect(x: r - hr * 0.9, y: r - 1.2, width: hr * 1.8, height: 2.4))
            ctx.setStrokeColor(UIColor(white: 0.1, alpha: 0.8).cgColor)
            ctx.setLineWidth(1)
            ctx.strokeEllipse(in: rect)
        }
    }

    private func spawnStone(_ p: Pad) {
        let st = Stone()
        let s = p.seat
        st.pos = CGPoint(x: 0, y: p.startY)
        st.node.position = st.pos
        st.node.zPosition = 10
        let sh = SKSpriteNode(texture: Gfx.shadow, size: CGSize(width: p.r * 3.2, height: p.r * 1.3))
        sh.position = CGPoint(x: 2, y: -p.r * 0.9)
        sh.zPosition = -2
        st.node.addChild(sh)
        let gl = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: p.r * 3.6, height: p.r * 3.6))
        gl.color = s.color
        gl.colorBlendFactor = 1
        gl.blendMode = .add
        gl.alpha = 0.5
        gl.zPosition = -1
        st.node.addChild(gl)
        let body = SKSpriteNode(texture: stoneTexture(r: p.r, idx: s.index, color: s.color), size: CGSize(width: p.r * 2, height: p.r * 2))
        st.spin.addChild(body)
        st.node.addChild(st.spin)
        let hi = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: p.r * 0.7, height: p.r * 0.7))
        hi.alpha = 0.35
        hi.position = CGPoint(x: -p.r * 0.35, y: p.r * 0.4)
        hi.zPosition = 2
        st.node.addChild(hi)
        st.node.setScale(0.2)
        st.node.run(SKAction.scale(to: 1, duration: 0.2))
        s.field.addChild(st.node)
        p.stones.append(st)
        p.cur = st
        p.mode = .ready
        p.idle = 0
        p.cpuWait = 0.7 + Double.random(in: 0...0.5)
        p.anchor = nil
        p.touch = nil
        updateCounter(p)
    }

    private func updateCounter(_ p: Pad) {
        let num: Int
        switch p.mode {
        case .ready: num = p.thrown + 1
        default: num = p.thrown
        }
        if p.mode == .done {
            p.counter?.text = "FERTIG"
        } else {
            p.counter?.text = "STEIN \(min(maxStones, max(1, num)))/\(maxStones)"
        }
    }

    // MARK: Aim + launch

    private func vmax(_ p: Pad) -> CGFloat {
        let d = p.ty - p.startY
        return sqrt(2 * mu * d) * 1.35
    }

    private func aim(_ p: Pad, from a: CGPoint, to b: CGPoint) -> (dir: CGVector, pow: CGFloat) {
        let pull = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        if pull.dy <= 2 { return (CGVector(dx: 0, dy: 1), 0) }
        let maxPull = min(p.seat.h * 0.28, 100)
        let len = hypot(pull.dx, pull.dy)
        let pw = min(1, len / maxPull)
        var ang = atan2(pull.dx, pull.dy)
        ang = max(-0.8, min(0.8, ang))
        return (CGVector(dx: sin(ang), dy: cos(ang)), pw)
    }

    private func showAim(_ p: Pad, dir: CGVector, pow: CGFloat) {
        guard let st = p.cur else { return }
        let v = vmax(p) * pow
        let L = v * v / (2 * mu)
        let n = p.dots.count
        let step: CGFloat = 15
        for (i, d) in p.dots.enumerated() {
            let dist = step * CGFloat(i + 1)
            if pow < 0.12 || dist > L - 8 {
                d.alpha = 0
            } else {
                d.position = CGPoint(x: st.pos.x + dir.dx * dist, y: st.pos.y + dir.dy * dist)
                d.alpha = 0.9 * (1 - CGFloat(i) / CGFloat(n + 2))
                d.color = p.seat.color
            }
        }
        if let g = p.ghost {
            if pow < 0.12 { g.alpha = 0 } else {
                g.position = CGPoint(x: st.pos.x + dir.dx * L, y: st.pos.y + dir.dy * L)
                g.alpha = 0.9
                let over = g.position.y > p.ty + p.R + p.r * 0.5
                g.color = over ? UIColor.red : UIColor.white
                g.colorBlendFactor = over ? 0.8 : 0
            }
        }
        if let pl = p.pull {
            let len = pow * min(p.seat.h * 0.28, 100) * 0.7
            pl.alpha = pow < 0.05 ? 0 : 0.8
            pl.position = st.pos
            pl.size = CGSize(width: 4, height: len)
            pl.zRotation = -atan2(dir.dx, dir.dy) + .pi
        }
    }

    private func hideAim(_ p: Pad) {
        for d in p.dots { d.alpha = 0 }
        p.ghost?.alpha = 0
        p.pull?.alpha = 0
    }

    private func launch(_ p: Pad, dir: CGVector, speed: CGFloat) {
        guard let st = p.cur, p.mode == .ready else { return }
        st.vel = CGVector(dx: dir.dx * speed, dy: dir.dy * speed)
        p.mode = .sliding
        p.thrown += 1
        p.slideT = 0
        p.prevTotal = total(p)
        p.hint?.removeAction(forKey: "hintOut")
        p.hint?.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
        p.hint = nil
        p.bear?.squash()
        Sfx.shared.play("kick")
        if !p.seat.isCPU { Haptic.tap(.medium) }
        updateCounter(p)
        hideAim(p)
    }

    private func cpuThrow(_ p: Pad) {
        let sk = CGFloat(p.seat.skill)
        let dx = p.tx - 0
        let dy = p.ty - p.startY
        let dist = hypot(dx, dy)
        var ang = atan2(dx, dy)
        ang += CGFloat.random(in: -1...1) * (1 - sk) * 0.16
        let f = 1 + CGFloat.random(in: -1...1) * (1 - sk) * 0.2
        let v = sqrt(2 * mu * dist) * f
        launch(p, dir: CGVector(dx: sin(ang), dy: cos(ang)), speed: v)
    }

    // MARK: Input

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = pads[seat.index]
        if p.mode != .ready || p.anchor != nil { return }
        p.anchor = at
        p.touch = touch
        p.idle = 0
        Haptic.tap(.light)
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = pads[seat.index]
        guard p.mode == .ready, p.touch === touch, let a = p.anchor else { return }
        let r = aim(p, from: a, to: at)
        showAim(p, dir: r.dir, pow: r.pow)
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let p = pads[seat.index]
        guard p.mode == .ready, p.touch === touch, let a = p.anchor else { return }
        p.anchor = nil
        p.touch = nil
        let r = aim(p, from: a, to: at)
        if r.pow < 0.12 {
            hideAim(p)
            if hypot(at.x - a.x, at.y - a.y) > 8 { seat.floatText("ZIEHEN!", at: CGPoint(x: 0, y: p.startY + 30), color: .white, size: 14) }
            return
        }
        launch(p, dir: r.dir, speed: vmax(p) * r.pow)
    }

    // MARK: Update

    private func advanceTurn() {
        for k in 1...max(1, n) {
            let j = (activeSeatIndex + k) % n
            if pads[j].mode != .done {
                pads[j].idle = 0
                pads[j].cpuWait = 0.8 + Double.random(in: 0...0.5)
                setActiveSeat(j)
                return
            }
        }
    }

    override func gameUpdate(_ dt: Double) {
        for p in pads where p.seat.index == activeSeatIndex {
            switch p.mode {
            case .ready:
                p.idle += dt
                if p.seat.isCPU {
                    p.cpuWait -= dt
                    if p.cpuWait <= 0 { cpuThrow(p) }
                } else if p.idle > 14 && p.anchor == nil {
                    // auto throw so the match always ends
                    let sk = CGFloat(0.3)
                    let ang = CGFloat.random(in: -1...1) * (1 - sk) * 0.2
                    let v = sqrt(2 * mu * (p.ty - p.startY)) * CGFloat.random(in: 0.85...1.1)
                    launch(p, dir: CGVector(dx: sin(ang), dy: cos(ang)), speed: v)
                }
            case .sliding:
                p.slideT += dt
                physics(p, dt)
                trail(p, dt)
                if p.stones.allSatisfy({ !$0.moving }) || p.slideT > 9 {
                    for st in p.stones { st.vel = .zero }
                    p.mode = .settling
                    p.timer = 0.45
                }
            case .settling:
                p.timer -= dt
                if p.timer <= 0 { evaluate(p) }
            case .done:
                break
            }
        }
        if !finishing && pads[activeSeatIndex].mode == .done {
            turnWait += dt
            if turnWait > 1.1 { turnWait = 0; advanceTurn() }
        }
        if !finishing && elapsed > 70 * Double(max(1, n)) { finishAll() }
    }

    private func physics(_ p: Pad, _ dt: Double) {
        let sub = 2
        let h = CGFloat(dt) / CGFloat(sub)
        let w = p.seat.w, hh = p.seat.h
        let r = p.r
        let outY = p.ty + p.R + r * 0.5
        for _ in 0..<sub {
            for st in p.stones where !st.out && st.moving {
                var sp = hypot(st.vel.dx, st.vel.dy)
                let nsp = max(0, sp - mu * h)
                if nsp < 7 { st.vel = .zero; continue }
                let k = nsp / sp
                st.vel.dx *= k; st.vel.dy *= k
                sp = nsp
                st.pos.x += st.vel.dx * h
                st.pos.y += st.vel.dy * h
                if st.pos.x < -w / 2 + r + 3 { st.pos.x = -w / 2 + r + 3; st.vel.dx = abs(st.vel.dx) * 0.6; wallFx(p, st) }
                if st.pos.x > w / 2 - r - 3 { st.pos.x = w / 2 - r - 3; st.vel.dx = -abs(st.vel.dx) * 0.6; wallFx(p, st) }
                if st.pos.y < -hh / 2 + r + 3 { st.pos.y = -hh / 2 + r + 3; st.vel.dy = abs(st.vel.dy) * 0.6 }
                if st.pos.y > outY { knockOutStone(p, st) }
            }
            // stone-stone collisions
            let live = p.stones.filter { !$0.out }
            for i in 0..<live.count {
                for j in (i + 1)..<max(i + 1, live.count) {
                    let a = live[i], b = live[j]
                    if !a.moving && !b.moving { continue }
                    var dx = b.pos.x - a.pos.x
                    var dy = b.pos.y - a.pos.y
                    var d = hypot(dx, dy)
                    if d >= 2 * r { continue }
                    if d < 0.001 { dx = 0; dy = 1; d = 1 }
                    let nx = dx / d, ny = dy / d
                    let ov = (2 * r - d) / 2
                    a.pos.x -= nx * ov; a.pos.y -= ny * ov
                    b.pos.x += nx * ov; b.pos.y += ny * ov
                    let vr = (a.vel.dx - b.vel.dx) * nx + (a.vel.dy - b.vel.dy) * ny
                    if vr > 0 {
                        let j2 = vr * 1.85 / 2
                        a.vel.dx -= j2 * nx; a.vel.dy -= j2 * ny
                        b.vel.dx += j2 * nx; b.vel.dy += j2 * ny
                        if vr > 25 { clack(p, at: CGPoint(x: (a.pos.x + b.pos.x) / 2, y: (a.pos.y + b.pos.y) / 2), strength: vr) }
                    }
                }
            }
        }
        for st in p.stones where !st.out {
            st.node.position = st.pos
            if st.moving {
                let sp = hypot(st.vel.dx, st.vel.dy)
                st.spin.zRotation += CGFloat(dt) * (0.8 + sp * 0.004)
            }
        }
    }

    private func wallFx(_ p: Pad, _ st: Stone) {
        if elapsed - p.lastHit > 0.1 {
            p.lastHit = elapsed
            Sfx.shared.play("bounce")
        }
    }

    private func clack(_ p: Pad, at pt: CGPoint, strength: CGFloat) {
        if elapsed - p.lastHit < 0.07 { return }
        p.lastHit = elapsed
        Sfx.shared.play("hit")
        p.seat.burst(at: pt, color: UIColor(red: 0.8, green: 0.95, blue: 1, alpha: 1), count: strength > 80 ? 12 : 6, speed: 70)
        if strength > 70 {
            p.seat.shake(3)
            if !p.seat.isCPU { Haptic.tap(.medium) }
        } else if !p.seat.isCPU {
            Haptic.tap(.light)
        }
    }

    private func knockOutStone(_ p: Pad, _ st: Stone) {
        st.out = true
        st.vel = .zero
        p.seat.floatText("RAUS", at: CGPoint(x: st.pos.x, y: min(st.pos.y, p.seat.h / 2 - 50)), color: UIColor(white: 0.85, alpha: 1), size: 15)
        Sfx.shared.play("miss")
        st.node.run(SKAction.sequence([
            SKAction.group([SKAction.fadeOut(withDuration: 0.3), SKAction.moveBy(x: 0, y: 24, duration: 0.3), SKAction.scale(to: 0.5, duration: 0.3)]),
            SKAction.removeFromParent()
        ]))
    }

    private func trail(_ p: Pad, _ dt: Double) {
        guard let st = p.cur, st.moving else { return }
        p.trailT -= dt
        if p.trailT > 0 { return }
        p.trailT = 0.03
        let sp = hypot(st.vel.dx, st.vel.dy)
        let t = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: p.r * 1.1, height: p.r * 1.1))
        t.color = p.seat.color
        t.colorBlendFactor = 1
        t.blendMode = .add
        t.alpha = min(0.7, sp / 160)
        t.position = st.pos
        t.zPosition = 3
        p.seat.field.addChild(t)
        t.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.45), SKAction.scale(to: 0.3, duration: 0.45)]), SKAction.removeFromParent()]))
        // ice sparkle
        if Int.random(in: 0..<4) == 0 {
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let sparkle = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 3, height: 3))
            sparkle.blendMode = .add
            sparkle.position = CGPoint(x: st.pos.x - st.vel.dx * 0.01, y: st.pos.y - st.vel.dy * 0.01)
            sparkle.zPosition = 4
            p.seat.field.addChild(sparkle)
            sparkle.run(SKAction.sequence([SKAction.group([SKAction.moveBy(x: cos(a) * 14, y: sin(a) * 14, duration: 0.35), SKAction.fadeOut(withDuration: 0.35)]), SKAction.removeFromParent()]))
        }
    }

    // MARK: Scoring

    private func points(_ p: Pad, _ st: Stone) -> Int {
        if st.out { return 0 }
        let d = hypot(st.pos.x - p.tx, st.pos.y - p.ty)
        if d <= p.R * 0.18 + 2 { return 5 }
        if d <= p.R * 0.40 { return 3 }
        if d <= p.R * 0.68 { return 2 }
        if d <= p.R { return 1 }
        return 0
    }

    private func total(_ p: Pad) -> Int {
        return p.stones.reduce(0) { $0 + points(p, $1) }
    }

    private func evaluate(_ p: Pad) {
        let s = p.seat
        let tot = total(p)
        let mine = p.cur.map { points(p, $0) } ?? 0
        let pos = p.cur?.pos ?? .zero
        let wasOut = p.cur?.out ?? false
        if !wasOut {
            if mine == 5 {
                s.banner("VOLLTREFFER!", color: UIColor.yellow, size: 34, duration: 0.7)
                s.flash(UIColor.yellow, alpha: 0.3)
                s.burst(at: CGPoint(x: p.tx, y: p.ty), color: UIColor.yellow, count: 26, speed: 160)
                s.floatText("+5", at: pos, color: UIColor.yellow, size: 28)
                Sfx.shared.play("coin")
                Haptic.good()
                p.bear?.celebrate()
                addStat("hits", 1, seat: s)
            } else if mine > 0 {
                s.floatText("+\(mine)", at: pos, color: s.color, size: 24)
                s.burst(at: pos, color: s.color, count: 10)
                Sfx.shared.play(mine >= 3 ? "right" : "pop")
                if !s.isCPU { Haptic.tap(.light) }
            } else {
                s.floatText("DANEBEN", at: CGPoint(x: pos.x, y: max(pos.y, -s.h / 2 + 60)), color: UIColor(white: 0.8, alpha: 1), size: 14)
                Sfx.shared.play("wrong")
            }
        }
        let bump = tot - p.prevTotal - mine
        if bump < 0 {
            s.floatText("\(bump)", at: CGPoint(x: p.tx, y: p.ty + p.R * 0.5), color: UIColor.red, size: 16)
        }
        setScore(s, tot)
        if p.thrown >= maxStones {
            p.mode = .done
            updateCounter(p)
            p.bear?.stopBob()
            if pads.allSatisfy({ $0.mode == .done }) { finishAll() }
        } else {
            spawnStone(p)
        }
    }

    private func finishAll() {
        if finishing { return }
        finishing = true
        run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.run { [weak self] in
            guard let self = self else { return }
            for p in self.pads { self.setScore(p.seat, self.total(p)) }
            self.finishGame()
        }]))
    }
}
