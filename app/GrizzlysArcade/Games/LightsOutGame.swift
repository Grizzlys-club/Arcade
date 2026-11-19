import SpriteKit

/// Lichter aus – same Lights-Out puzzle for every seat. Solve it first for 3/2/1 points.
final class LightsOutGame: MiniScene {

    private final class St {
        var cells: [SKSpriteNode] = []
        var glows: [SKSpriteNode] = []
        var dots: [SKSpriteNode] = []
        var board: [Bool] = []
        var progress = 0
        var locked = true
        var done = false
        var queue: [Int] = []
        var timer: Double = 1.0
        var hint: SKLabelNode!
    }

    private var g = 3
    private var cs: CGFloat = 50
    private var gx0: CGFloat = 0
    private var gy0: CGFloat = 0
    private let total = 3
    private var puzzles: [(board: [Bool], sol: [Int])] = []
    private var solved = [Int](repeating: 0, count: 3)
    private var states: [St] = []
    private var ending = false

    private let on = UIColor(red: 1.0, green: 0.82, blue: 0.2, alpha: 1)
    private let off = UIColor(red: 0.12, green: 0.13, blue: 0.2, alpha: 1)

    override func setupGame() {
        duration = 45
        g = n == 2 ? 4 : 3
        let r = newRand()
        for _ in 0..<total {
            while true {
                var board = [Bool](repeating: false, count: g * g)
                var set = Set<Int>()
                let cnt = g == 3 ? r.int(3, 5) : r.int(5, 7)
                for _ in 0..<cnt {
                    let c = r.int(0, g * g - 1)
                    if set.contains(c) { set.remove(c) } else { set.insert(c) }
                }
                for c in set { LightsOutGame.apply(&board, c, g) }
                if set.count >= 2 && board.contains(true) {
                    puzzles.append((board, set.sorted()))
                    break
                }
            }
        }
        for s in seats {
            let st = St()
            cs = floor(min((s.w - 24) / CGFloat(g), (s.h - 80) / CGFloat(g), 76))
            let gs = cs * CGFloat(g)
            gx0 = -gs / 2
            gy0 = -gs / 2 + 1
            for i in 0..<(g * g) {
                let col = i % g, row = i / g
                let p = CGPoint(x: gx0 + (CGFloat(col) + 0.5) * cs, y: gy0 + (CGFloat(row) + 0.5) * cs)
                let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: cs * 1.7, height: cs * 1.7))
                glow.blendMode = .add
                glow.color = on
                glow.colorBlendFactor = 1
                glow.alpha = 0
                glow.position = p
                glow.zPosition = 1
                s.field.addChild(glow)
                let c = SKSpriteNode(texture: Gfx.pill(cs - 6, cs - 6, fill: .white, border: UIColor(white: 1, alpha: 0.25), corner: 10), size: CGSize(width: cs - 6, height: cs - 6))
                c.color = off
                c.colorBlendFactor = 1
                c.position = p
                c.zPosition = 2
                s.field.addChild(c)
                st.cells.append(c)
                st.glows.append(glow)
            }
            for k in 0..<total {
                let d = SKSpriteNode(texture: Gfx.circle(6, .white), size: CGSize(width: 12, height: 12))
                d.color = UIColor(white: 0.3, alpha: 1)
                d.colorBlendFactor = 1
                d.position = CGPoint(x: CGFloat(k - 1) * 22, y: -s.h / 2 + 18)
                d.zPosition = 3
                s.field.addChild(d)
                st.dots.append(d)
            }
            let hint = label("FELD + NACHBARN UMSCHALTEN", size: min(11, s.w * 0.055), color: UIColor(white: 1, alpha: 0.8))
            hint.position = CGPoint(x: 0, y: -s.h / 2 + 38)
            hint.zPosition = 3
            s.field.addChild(hint)
            st.hint = hint
            loadPuzzle(s, st)
            states.append(st)
        }
    }

    private static func apply(_ b: inout [Bool], _ c: Int, _ g: Int) {
        let col = c % g, row = c / g
        b[c].toggle()
        if col > 0 { b[c - 1].toggle() }
        if col < g - 1 { b[c + 1].toggle() }
        if row > 0 { b[c - g].toggle() }
        if row < g - 1 { b[c + g].toggle() }
    }

    private func loadPuzzle(_ s: Seat, _ st: St) {
        let pz = puzzles[st.progress]
        st.board = pz.board
        for i in 0..<(g * g) { paint(st, i, pop: false) }
        st.queue = pz.sol.shuffled()
        st.timer = 0.6 + (1 - s.skill) * 1.2
    }

    private func paint(_ st: St, _ i: Int, pop: Bool) {
        let lit = st.board[i]
        st.cells[i].color = lit ? on : off
        st.glows[i].alpha = lit ? 0.85 : 0
        if pop {
            st.cells[i].removeAction(forKey: "pop")
            st.cells[i].run(SKAction.sequence([SKAction.scale(to: 0.82, duration: 0.05), SKAction.scale(to: 1, duration: 0.1)]), withKey: "pop")
        }
    }

    override func gameStarted() {
        for st in states { st.locked = false }
        for s in seats {
            states[s.index].hint.run(SKAction.sequence([SKAction.wait(forDuration: 5), SKAction.fadeOut(withDuration: 0.5)]))
        }
    }

    private func tap(_ s: Seat, _ c: Int) {
        let st = states[s.index]
        if st.locked || st.done { return }
        var b = st.board
        LightsOutGame.apply(&b, c, g)
        let col = c % g, row = c / g
        st.board = b
        var idx = [c]
        if col > 0 { idx.append(c - 1) }
        if col < g - 1 { idx.append(c + 1) }
        if row > 0 { idx.append(c - g) }
        if row < g - 1 { idx.append(c + g) }
        for i in idx { paint(st, i, pop: true) }
        if !s.isCPU { Sfx.shared.play("tap"); Haptic.tap() }
        if !st.board.contains(true) { solve(s, st) }
    }

    private func solve(_ s: Seat, _ st: St) {
        let k = st.progress
        let pts = max(1, 3 - solved[k])
        solved[k] += 1
        addScore(s, pts)
        st.dots[k].color = pts == 3 ? on : s.color
        st.locked = true
        s.floatText("+\(pts)", at: CGPoint(x: 0, y: 20), color: .yellow, size: 34)
        s.burst(at: .zero, color: on, count: 22, speed: 160)
        s.flash(on, alpha: 0.25)
        if !s.isCPU { Sfx.shared.play(pts == 3 ? "fanfare" : "coin"); Haptic.good() }
        st.progress += 1
        if st.progress >= total {
            st.done = true
            s.banner("FERTIG!", color: on, size: 38, duration: 1.5)
            return
        }
        s.field.run(SKAction.sequence([SKAction.wait(forDuration: 0.7), SKAction.run { [weak self] in
            guard let self = self else { return }
            self.loadPuzzle(s, st)
            st.locked = false
        }]))
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats where s.isCPU {
            let st = states[s.index]
            if st.locked || st.done { continue }
            st.timer -= dt
            if st.timer <= 0, !st.queue.isEmpty {
                tap(s, st.queue.removeFirst())
                st.timer = 0.3 + (1 - s.skill) * 1.1 + Double.random(in: 0...0.3)
            }
        }
        if !ending && states.allSatisfy({ $0.done }) {
            ending = true
            finishGame()
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let col = Int(floor((at.x - gx0) / cs))
        let row = Int(floor((at.y - gy0) / cs))
        if col < 0 || col >= g || row < 0 || row >= g { return }
        tap(seat, row * g + col)
    }
}
