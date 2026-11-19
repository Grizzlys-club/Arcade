import SpriteKit

/// Zickzack-Bär: the bear runs diagonally up, tap flips the direction. Collect pucks, avoid neon walls.
final class ZigzagGame: MiniScene {

    fileprivate struct Item {
        let node: SKNode
        let wy: CGFloat
        let x: CGFloat
        let block: Bool
        let side: CGFloat      // block: -1 left, +1 right
        let bw: CGFloat        // block width
        var taken = false
    }

    fileprivate final class State {
        let rand: Rand
        var items: [Item] = []
        var nextY: CGFloat = 260
        var wy: CGFloat = 0           // bear distance
        var x: CGFloat = 0
        var dir: CGFloat = 1
        var bear: BearNode!
        var world = SKNode()
        var wallL: SKSpriteNode!
        var wallR: SKSpriteNode!
        var trailT = 0.0
        var cpuAt = -1.0
        var cpuLock = 0.0
        init(rand: Rand) { self.rand = rand }
    }

    private var st: [State] = []
    private var baseY: CGFloat = 0
    private var humansSeen = false
    private var endTimer = -1.0

    private func speed(_ s: Seat) -> CGFloat {
        let k = 1 + 0.8 * CGFloat(min(1, elapsed / 45))
        return s.w * 0.46 * k
    }

    private func limit(_ s: Seat) -> CGFloat { return s.w / 2 - 14 }

    override func setupGame() {
        duration = 45
        humansSeen = seats.contains { !$0.isCPU }
        st = []
        for s in seats {
            let g = State(rand: newRand())
            baseY = -s.h / 2 + 90
            s.field.addChild(g.world)
            // neon side walls (fixed on screen, glowing)
            for side in [-1, 1] as [CGFloat] {
                let w = SKSpriteNode(texture: Gfx.rect(5, s.h, s.color, corner: 2), size: CGSize(width: 5, height: s.h))
                w.position = CGPoint(x: side * (s.w / 2 - 4), y: 0)
                w.zPosition = 20
                let gl = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 40, height: s.h * 1.2))
                gl.color = s.color; gl.colorBlendFactor = 1; gl.blendMode = .add; gl.alpha = 0.55
                w.addChild(gl)
                s.field.addChild(w)
            }
            let bh = min(46, s.w * 0.2)
            g.bear = makeBear(s, height: bh, faceRight: true)
            g.bear.zPosition = 30
            g.bear.startBob(amount: 2, duration: 0.2)
            g.bear.position = CGPoint(x: 0, y: baseY)
            s.field.addChild(g.bear)
            st.append(g)
            let hint = label("TIPPEN = WENDEN ⚡", size: min(17, s.w * 0.08), color: .white)
            hint.position = CGPoint(x: 0, y: 0)
            hint.zPosition = 60
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.4), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
        for s in seats { fill(s) }
    }

    /// generate content up to the visible top (same sequence for all seats)
    private func fill(_ s: Seat) {
        let g = st[s.index]
        let hw = limit(s) - 8
        while g.nextY < g.wy + s.h + 120 {
            let y = g.nextY
            let r = g.rand
            if r.chance(0.42) {
                let side: CGFloat = r.chance(0.5) ? -1 : 1
                let bw = r.range(0.2, 0.42) * s.w
                let n = SKSpriteNode(texture: Gfx.rect(bw, 12, Theme.uiPink, corner: 5), size: CGSize(width: bw, height: 12))
                let gl = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: bw + 26, height: 44))
                gl.color = Theme.uiPink; gl.colorBlendFactor = 1; gl.blendMode = .add; gl.alpha = 0.6
                n.addChild(gl)
                n.zPosition = 10
                g.world.addChild(n)
                n.position = CGPoint(x: side * (s.w / 2 - bw / 2 - 2), y: y)
                g.items.append(Item(node: n, wy: y, x: 0, block: true, side: side, bw: bw))
            } else {
                let count = r.chance(0.35) ? 2 : 1
                for k in 0..<count {
                    let x = r.range(-hw, hw)
                    let n = SKSpriteNode(texture: Gfx.ball(9), size: CGSize(width: 20, height: 20))
                    n.color = .darkGray; n.colorBlendFactor = 0.7
                    let gl = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 40, height: 40))
                    gl.color = Theme.uiOrange; gl.colorBlendFactor = 1; gl.blendMode = .add; gl.alpha = 0.7
                    gl.zPosition = -1
                    n.addChild(gl)
                    n.zPosition = 10
                    n.position = CGPoint(x: x, y: y + CGFloat(k) * 34)
                    g.world.addChild(n)
                    g.items.append(Item(node: n, wy: y + CGFloat(k) * 34, x: x, block: false, side: 0, bw: 0))
                }
            }
            g.nextY += r.range(80, 125)
        }
    }

    private func flip(_ s: Seat) {
        let g = st[s.index]
        g.dir = -g.dir
        g.bear.setFacing(right: g.dir > 0)
        g.bear.squash()
        Sfx.shared.play("tap")
        if !s.isCPU { Haptic.tap(.light) }
    }

    private func crash(_ s: Seat) {
        let g = st[s.index]
        let p = g.bear.position
        s.burst(at: p, color: Theme.uiPink, count: 20, speed: 140)
        s.flash(UIColor.red, alpha: 0.4)
        s.shake(9)
        Sfx.shared.play("lose")
        if !s.isCPU { Haptic.bad() }
        g.bear.stopBob()
        g.bear.run(SKAction.group([SKAction.rotate(byAngle: 3, duration: 0.4), SKAction.fadeAlpha(to: 0.3, duration: 0.4)]))
        s.knockOut("CRASH")
    }

    override func gameUpdate(_ dt: Double) {
        let fdt = CGFloat(dt)
        var alive = 0
        for s in seats {
            let g = st[s.index]
            if !s.alive { continue }
            alive += 1
            let v = speed(s)
            // CPU brain
            if s.isCPU {
                if g.cpuAt < 0 && elapsed > g.cpuLock {
                    var danger = false
                    let marginT = 0.05 + (1 - s.skill) * 0.3
                    let ahead = g.dir * (g.x + g.dir * v * CGFloat(marginT) + 0)
                    if ahead >= limit(s) - 4 { danger = true }
                    for it in g.items where it.block && !it.taken && it.wy > g.wy - 12 && it.wy < g.wy + 150 {
                        let edge = it.side * (s.w / 2 - it.bw - 4)
                        let after = g.x + g.dir * (it.wy - g.wy + v * CGFloat(marginT))
                        if it.side == g.dir && after * it.side > edge * it.side - 6 { danger = true }
                    }
                    if danger { g.cpuAt = elapsed + Double.random(in: 0...(1 - s.skill) * 0.18) }
                }
                if g.cpuAt >= 0 && elapsed >= g.cpuAt {
                    g.cpuAt = -1
                    g.cpuLock = elapsed + 0.3
                    flip(s)
                }
            }
            g.x += g.dir * v * fdt
            g.wy += v * fdt
            g.bear.position = CGPoint(x: g.x, y: baseY)
            g.bear.zRotation = -g.dir * 0.22
            g.world.position.y = baseY - g.wy
            // trail
            g.trailT -= dt
            if g.trailT <= 0 {
                g.trailT = 0.05
                let tr = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: 22, height: 22))
                tr.color = s.color; tr.colorBlendFactor = 1; tr.blendMode = .add; tr.alpha = 0.6
                tr.position = CGPoint(x: g.x, y: g.wy + 4)
                tr.zPosition = 5
                g.world.addChild(tr)
                tr.run(SKAction.sequence([SKAction.group([SKAction.fadeOut(withDuration: 0.4), SKAction.scale(to: 0.2, duration: 0.4)]), SKAction.removeFromParent()]))
            }
            // collisions
            let by = g.wy + 14
            var crashed = abs(g.x) >= limit(s)
            for i in 0..<g.items.count where !g.items[i].taken {
                let it = g.items[i]
                if it.wy < g.wy - 60 { it.node.removeFromParent(); g.items[i].taken = true; continue }
                if it.block {
                    if abs(it.wy - by) < 15 && it.side * g.x > it.side * (it.side * (s.w / 2 - it.bw - 2)) - 4 { crashed = true }
                } else if hypot(it.x - g.x, it.wy - by) < 24 {
                    g.items[i].taken = true
                    it.node.removeFromParent()
                    addScore(s, 1)
                    addStat("balls", 1, seat: s)
                    let p = CGPoint(x: it.x, y: baseY + (it.wy - g.wy))
                    s.floatText("+1", at: p, color: Theme.uiOrange)
                    s.burst(at: p, color: Theme.uiOrange, count: 8, speed: 70)
                    Sfx.shared.play("coin")
                    if !s.isCPU { Haptic.tap(.light) }
                }
            }
            if g.items.count > 60 { g.items.removeAll { $0.taken } }
            fill(s)
            if crashed { crash(s); alive -= 1 }
        }
        if endTimer < 0 {
            let humanAlive = seats.contains { !$0.isCPU && $0.alive }
            if alive == 0 || (humansSeen && !humanAlive) { endTimer = 1.0 }
        } else {
            endTimer -= dt
            if endTimer <= 0 { finishGame() }
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        flip(seat)
    }
}
