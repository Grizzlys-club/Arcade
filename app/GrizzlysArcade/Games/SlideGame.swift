import SpriteKit

/// Eis-Rutsch: swipe, the bear slides on ice until a rock or wall stops it. Reach the goal, avoid holes.
final class SlideGame: MiniScene {

    fileprivate struct Level {
        var n: Int
        var rocks: Set<Int>
        var holes: Set<Int>
        var start: Int
        var goal: Int
    }

    fileprivate enum Outcome { case stop(Int), goal(Int), hole(Int) }

    fileprivate final class State {
        let rand: Rand
        var level: Level
        var levelNo = 0
        var board = SKNode()
        var bear: BearNode!
        var pos = 0
        var moving = false
        var swipeStart: CGPoint? = nil
        var cell: CGFloat = 30
        var origin = CGPoint.zero
        var cpuAt = 0.0
        var path: [Int] = []
        init(rand: Rand, level: Level) { self.rand = rand; self.level = level }
    }

    private var st: [State] = []
    private var gridN = 5
    private static let dirs: [(Int, Int)] = [(0, 1), (0, -1), (-1, 0), (1, 0)]

    // MARK: level logic

    fileprivate static func slide(_ lv: Level, from: Int, dir: Int) -> Outcome {
        let n = lv.n
        var x = from % n, y = from / n
        let d = dirs[dir]
        while true {
            let nx = x + d.0, ny = y + d.1
            if nx < 0 || ny < 0 || nx >= n || ny >= n || lv.rocks.contains(ny * n + nx) { break }
            x = nx; y = ny
            let i = y * n + x
            if i == lv.goal { return .goal(i) }
            if lv.holes.contains(i) { return .hole(i) }
        }
        return .stop(y * n + x)
    }

    /// Shortest list of directions from `from` to the goal (nil = unreachable)
    fileprivate static func solve(_ lv: Level, from: Int) -> [Int]? {
        var prev: [Int: (Int, Int)] = [from: (-1, -1)]
        var queue = [from]
        var qi = 0
        while qi < queue.count {
            let c = queue[qi]; qi += 1
            for d in 0..<4 {
                switch slide(lv, from: c, dir: d) {
                case .hole: continue
                case .goal:
                    var res = [d]
                    var cur = c
                    while let p = prev[cur], p.0 >= 0 { res.append(p.1); cur = p.0 }
                    return res.reversed()
                case .stop(let t):
                    if prev[t] == nil { prev[t] = (c, d); queue.append(t) }
                }
            }
        }
        return nil
    }

    fileprivate static func makeLevel(_ r: Rand, n: Int, no: Int) -> Level {
        let cells = n * n
        let want = min(2 + no / 2, 7)
        var best: Level? = nil
        var bestLen = 0
        for _ in 0..<250 {
            var all = Array(0..<cells)
            all = r.shuffled(all)
            let rockCount = min(n + 1 + no / 3, cells / 3)
            let holeCount = min(2 + no / 3, 5)
            var lv = Level(n: n, rocks: [], holes: [], start: all[0], goal: all[1])
            for i in 0..<rockCount { lv.rocks.insert(all[2 + i]) }
            for i in 0..<holeCount { lv.holes.insert(all[2 + rockCount + i]) }
            if let p = solve(lv, from: lv.start) {
                if p.count >= want { return lv }
                if p.count > bestLen { bestLen = p.count; best = lv }
            }
        }
        if let b = best { return b }
        return Level(n: n, rocks: [], holes: [], start: 0, goal: n - 1)   // trivial: slide right
    }

    // MARK: textures

    private static func tileTex(_ s: CGFloat) -> SKTexture {
        return Gfx.texture("slide_ice_\(Int(s))", size: CGSize(width: s, height: s)) { ctx in
            let r = CGRect(x: 1, y: 1, width: s - 2, height: s - 2)
            ctx.setFillColor(UIColor(red: 0.62, green: 0.85, blue: 1, alpha: 0.28).cgColor)
            ctx.addPath(UIBezierPath(roundedRect: r, cornerRadius: s * 0.15).cgPath)
            ctx.fillPath()
            ctx.setStrokeColor(UIColor(red: 0.7, green: 0.95, blue: 1, alpha: 0.55).cgColor)
            ctx.setLineWidth(1.2)
            ctx.addPath(UIBezierPath(roundedRect: r, cornerRadius: s * 0.15).cgPath)
            ctx.strokePath()
        }
    }

    private static func rockTex(_ s: CGFloat) -> SKTexture {
        return Gfx.texture("slide_rock_\(Int(s))", size: CGSize(width: s, height: s)) { ctx in
            let r = CGRect(x: s * 0.08, y: s * 0.08, width: s * 0.84, height: s * 0.84)
            ctx.setFillColor(UIColor(white: 0.32, alpha: 1).cgColor)
            ctx.fillEllipse(in: r)
            ctx.setFillColor(UIColor(white: 0.5, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: s * 0.18, y: s * 0.42, width: s * 0.4, height: s * 0.4))
            ctx.setStrokeColor(UIColor(white: 0.15, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: r)
        }
    }

    private static func holeTex(_ s: CGFloat) -> SKTexture {
        return Gfx.texture("slide_hole_\(Int(s))", size: CGSize(width: s, height: s)) { ctx in
            let r = CGRect(x: s * 0.12, y: s * 0.12, width: s * 0.76, height: s * 0.76)
            ctx.setFillColor(UIColor(red: 0.02, green: 0.04, blue: 0.12, alpha: 1).cgColor)
            ctx.fillEllipse(in: r)
            ctx.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 1, alpha: 0.9).cgColor)
            ctx.setLineWidth(2.5)
            ctx.strokeEllipse(in: r)
        }
    }

    // MARK: setup

    override func setupGame() {
        duration = 40
        let wide = (seats.first?.w ?? 200) > 260
        gridN = wide ? 6 : 5
        st = []
        for s in seats {
            let g = State(rand: newRand(), level: Level(n: gridN, rocks: [], holes: [], start: 0, goal: 1))
            g.cell = floor(min((s.w - 14) / CGFloat(gridN), (s.h - 78) / CGFloat(gridN)))
            let bw = g.cell * CGFloat(gridN)
            g.origin = CGPoint(x: -bw / 2, y: -s.h / 2 + 30)
            st.append(g)
            newLevel(s, animate: false)
            let hint = label("WISCHEN ❄️", size: min(18, s.w * 0.085), color: .white)
            hint.position = CGPoint(x: 0, y: -s.h / 2 + 14)
            hint.zPosition = 60
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.4), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        }
    }

    private func center(_ g: State, _ i: Int) -> CGPoint {
        let n = g.level.n
        return CGPoint(x: g.origin.x + g.cell * (CGFloat(i % n) + 0.5), y: g.origin.y + g.cell * (CGFloat(i / n) + 0.5))
    }

    private func feet(_ g: State, _ i: Int) -> CGPoint {
        let c = center(g, i)
        return CGPoint(x: c.x, y: c.y - g.cell * 0.38)
    }

    private func newLevel(_ s: Seat, animate: Bool) {
        let g = st[s.index]
        g.board.removeFromParent()
        g.board = SKNode()
        s.field.addChild(g.board)
        g.level = SlideGame.makeLevel(g.rand, n: gridN, no: g.levelNo)
        g.levelNo += 1
        let lv = g.level
        let c = g.cell
        for i in 0..<(lv.n * lv.n) {
            let t = SKSpriteNode(texture: SlideGame.tileTex(c), size: CGSize(width: c, height: c))
            t.position = center(g, i)
            g.board.addChild(t)
            if lv.rocks.contains(i) {
                let r = SKSpriteNode(texture: SlideGame.rockTex(c), size: CGSize(width: c, height: c))
                r.position = center(g, i); r.zPosition = 2
                g.board.addChild(r)
            } else if lv.holes.contains(i) {
                let h = SKSpriteNode(texture: SlideGame.holeTex(c), size: CGSize(width: c, height: c))
                h.position = center(g, i); h.zPosition = 1
                g.board.addChild(h)
            }
        }
        // goal puck with glow
        let gl = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: c * 1.8, height: c * 1.8))
        gl.color = Theme.uiOrange; gl.colorBlendFactor = 1; gl.blendMode = .add; gl.alpha = 0.7
        gl.position = center(g, lv.goal); gl.zPosition = 1
        gl.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.3, duration: 0.5), SKAction.fadeAlpha(to: 0.8, duration: 0.5)])))
        g.board.addChild(gl)
        let puck = SKSpriteNode(texture: Gfx.star(c * 0.36, Theme.uiOrange), size: CGSize(width: c * 0.72, height: c * 0.72))
        puck.position = center(g, lv.goal); puck.zPosition = 2
        puck.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 3)))
        g.board.addChild(puck)

        g.bear = makeBear(s, height: c * 0.82, faceRight: true)
        g.bear.zPosition = 10
        g.board.addChild(g.bear)
        place(s, to: lv.start)
        if animate {
            g.board.alpha = 0
            g.board.run(SKAction.fadeIn(withDuration: 0.25))
        }
        planCPU(s)
    }

    private func place(_ s: Seat, to i: Int) {
        let g = st[s.index]
        g.pos = i
        g.bear.removeAllActions()
        g.bear.setScale(1)
        g.bear.alpha = 1
        g.bear.position = feet(g, i)
        g.moving = false
    }

    private func planCPU(_ s: Seat) {
        guard s.isCPU else { return }
        let g = st[s.index]
        g.path = SlideGame.solve(g.level, from: g.pos) ?? []
        g.cpuAt = elapsed + 0.5 + (1 - s.skill) * 1.3 + Double.random(in: 0...0.4)
    }

    // MARK: moving

    private func move(_ s: Seat, dir: Int) {
        let g = st[s.index]
        if g.moving || !s.alive { return }
        let out = SlideGame.slide(g.level, from: g.pos, dir: dir)
        let target: Int
        switch out { case .stop(let t), .goal(let t), .hole(let t): target = t }
        if target == g.pos {
            g.bear.squash()
            Sfx.shared.play("tap")
            if !s.isCPU { Haptic.tap(.light) }
            return
        }
        let d = SlideGame.dirs[dir]
        if d.0 != 0 { g.bear.setFacing(right: d.0 > 0) }
        let dist = abs(target % g.level.n - g.pos % g.level.n) + abs(target / g.level.n - g.pos / g.level.n)
        let dur = 0.06 + 0.055 * Double(dist)
        g.moving = true
        g.pos = target
        Sfx.shared.play("jump")
        // ice trail
        let trail = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: g.cell * 1.2, height: g.cell * 1.2))
        trail.color = Theme.uiBlue; trail.colorBlendFactor = 1; trail.blendMode = .add; trail.alpha = 0.5
        trail.position = g.bear.position; trail.zPosition = 5
        g.board.addChild(trail)
        trail.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
        let mv = SKAction.move(to: feet(g, target), duration: dur)
        mv.timingMode = .easeOut
        g.bear.run(mv) { [weak self] in
            guard let self = self else { return }
            self.arrived(s, out)
        }
    }

    private func arrived(_ s: Seat, _ out: Outcome) {
        let g = st[s.index]
        g.moving = false
        let p = s.field.convert(center(g, g.pos), from: g.board)
        switch out {
        case .goal:
            addScore(s, 1)
            addStat("goals", 1, seat: s)
            s.floatText("+1", at: p, color: Theme.uiOrange, size: 26)
            s.burst(at: p, color: Theme.uiOrange, count: 16, speed: 110)
            Sfx.shared.play("coin")
            if !s.isCPU { Haptic.good() }
            g.moving = true
            g.bear.celebrate()
            g.bear.run(SKAction.wait(forDuration: 0.55)) { [weak self] in
                self?.newLevel(s, animate: true)
            }
        case .hole:
            s.burst(at: p, color: Theme.uiBlue, count: 10, speed: 70)
            s.flash(UIColor.blue, alpha: 0.25)
            Sfx.shared.play("miss")
            if !s.isCPU { Haptic.bad() }
            g.moving = true
            g.bear.run(SKAction.group([SKAction.scale(to: 0.05, duration: 0.3), SKAction.rotate(byAngle: 4, duration: 0.3)])) { [weak self] in
                self?.resetBear(s)
            }
        case .stop:
            g.bear.squash()
            Sfx.shared.play("tap")
            if !s.isCPU { Haptic.tap(.light) }
            if SlideGame.solve(g.level, from: g.pos) == nil {
                // stuck: back to the start
                s.floatText("NEU", at: p, color: .white, size: 18)
                g.moving = true
                g.bear.run(SKAction.sequence([SKAction.wait(forDuration: 0.35), SKAction.fadeOut(withDuration: 0.12)])) { [weak self] in
                    self?.resetBear(s)
                }
            } else {
                planCPU(s)
            }
        }
    }

    private func resetBear(_ s: Seat) {
        let g = st[s.index]
        place(s, to: g.level.start)
        g.bear.alpha = 0
        g.bear.run(SKAction.fadeIn(withDuration: 0.2))
        planCPU(s)
    }

    // MARK: loop & input

    override func gameUpdate(_ dt: Double) {
        for s in seats where s.isCPU {
            let g = st[s.index]
            if g.moving || elapsed < g.cpuAt || g.path.isEmpty { continue }
            var d = g.path.removeFirst()
            if Double.random(in: 0..<1) < (1 - s.skill) * 0.12 { d = Int.random(in: 0..<4) }   // slip
            move(s, dir: d)
            g.cpuAt = elapsed + 0.25 + (1 - s.skill) * 0.7 + Double.random(in: 0...0.2)
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        st[seat.index].swipeStart = at
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let g = st[seat.index]
        guard let a = g.swipeStart else { return }
        let dx = at.x - a.x, dy = at.y - a.y
        if hypot(dx, dy) < 18 { return }
        g.swipeStart = nil
        let dir = abs(dx) > abs(dy) ? (dx > 0 ? 3 : 2) : (dy > 0 ? 0 : 1)
        move(seat, dir: dir)
    }

    override func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {
        st[seat.index].swipeStart = nil
    }
}
