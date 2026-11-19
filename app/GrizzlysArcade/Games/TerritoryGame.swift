import SpriteKit

/// Revierkampf: one shared 5x7 grid, mirrored into every zone. Tap to claim, enemy cells need 2 taps.
final class TerritoryGame: MiniScene {
    private let cols = 5
    private let rows = 7
    private var owner: [Int] = []
    private var cracked: [Bool] = []
    /// tiles[seat][cell]
    private var tiles: [[SKSpriteNode]] = []
    private var crackMarks: [[SKLabelNode]] = []
    private var cellSize: [CGFloat] = []
    private var gridOrigin: [CGPoint] = []
    private var cpuTimers: [Double] = []

    override func setupGame() {
        duration = 25
        owner = Array(repeating: -1, count: cols * rows)
        cracked = Array(repeating: false, count: cols * rows)
        cpuTimers = seats.map { _ in Double.random(in: 0.2...0.6) }
        for s in seats {
            let top: CGFloat = 34
            let usableH = s.h - top - 16
            let cs = floor(min((s.w - 16) / CGFloat(cols), usableH / CGFloat(rows)))
            cellSize.append(cs)
            let gw = cs * CGFloat(cols)
            let gh = cs * CGFloat(rows)
            let origin = CGPoint(x: -gw / 2, y: -s.h / 2 + 8 + (usableH - gh) / 2)
            gridOrigin.append(origin)
            var row: [SKSpriteNode] = []
            var marks: [SKLabelNode] = []
            let tileTex = Gfx.pill(cs - 4, cs - 4, fill: UIColor(white: 1, alpha: 1), corner: min(10, cs * 0.22))
            for i in 0..<(cols * rows) {
                let c = i % cols, r = i / cols
                let t = SKSpriteNode(texture: tileTex, size: CGSize(width: cs - 4, height: cs - 4))
                t.position = CGPoint(x: origin.x + (CGFloat(c) + 0.5) * cs, y: origin.y + (CGFloat(r) + 0.5) * cs)
                t.color = UIColor(white: 0.25, alpha: 1)
                t.colorBlendFactor = 1
                t.alpha = 0.55
                t.zPosition = 5
                s.field.addChild(t)
                row.append(t)
                let m = MiniScene.label("✕", size: cs * 0.5, color: UIColor(white: 1, alpha: 0.9))
                m.position = t.position
                m.zPosition = 6
                m.isHidden = true
                s.field.addChild(m)
                marks.append(m)
            }
            tiles.append(row)
            crackMarks.append(marks)
            if !s.isCPU {
                let hint = MiniScene.label("FELDER ANTIPPEN!", size: min(18, s.w * 0.08), color: s.color)
                hint.position = CGPoint(x: 0, y: 0)
                hint.zPosition = 50
                s.node.addChild(hint)
                hint.run(SKAction.sequence([SKAction.wait(forDuration: 4.5), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
            }
        }
    }

    private func cellAt(_ s: Seat, _ p: CGPoint) -> Int? {
        let cs = cellSize[s.index]
        let o = gridOrigin[s.index]
        let c = Int(floor((p.x - o.x) / cs))
        let r = Int(floor((p.y - o.y) / cs))
        if c < 0 || c >= cols || r < 0 || r >= rows { return nil }
        return r * cols + c
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        if let i = cellAt(seat, at) { act(seat, i) }
    }

    override func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {
        // swiping over free cells claims them too (fun & fast)
        if let i = cellAt(seat, at), owner[i] == -1 { act(seat, i) }
    }

    private func act(_ s: Seat, _ i: Int) {
        let o = owner[i]
        if o == s.index {
            if cracked[i] {
                cracked[i] = false
                Sfx.shared.play("pop")
                refresh(i)
            }
            return
        }
        if o == -1 {
            owner[i] = s.index
            cracked[i] = false
            Sfx.shared.play("tap")
            if !s.isCPU { Haptic.tap() }
        } else if !cracked[i] {
            cracked[i] = true
            Sfx.shared.play("hit")
        } else {
            owner[i] = s.index
            cracked[i] = false
            Sfx.shared.play("pop")
            if !s.isCPU { Haptic.tap(.medium) }
            addStat("hits", 1, seat: s)
        }
        refresh(i)
        recount()
    }

    private func refresh(_ i: Int) {
        let o = owner[i]
        for s in seats {
            let t = tiles[s.index][i]
            t.removeAction(forKey: "pop")
            if o >= 0 {
                t.color = seats[o].color
                t.alpha = 1
            } else {
                t.color = UIColor(white: 0.25, alpha: 1)
                t.alpha = 0.55
            }
            t.setScale(0.7)
            t.run(SKAction.scale(to: 1, duration: 0.12), withKey: "pop")
            crackMarks[s.index][i].isHidden = !cracked[i]
        }
    }

    private func recount() {
        var counts = Array(repeating: 0, count: n)
        for o in owner where o >= 0 { counts[o] += 1 }
        for s in seats where s.score != counts[s.index] { setScore(s, counts[s.index]) }
    }

    override func gameUpdate(_ dt: Double) {
        for s in seats where s.isCPU {
            cpuTimers[s.index] -= dt
            if cpuTimers[s.index] > 0 { continue }
            cpuTimers[s.index] = (0.55 - 0.35 * s.skill) * Double.random(in: 0.7...1.3)
            // preference: repair own cracked > free > cracked enemy > enemy
            var candidates = owner.indices.filter { owner[$0] == s.index && cracked[$0] }
            if candidates.isEmpty || Double.random(in: 0...1) > s.skill { candidates = owner.indices.filter { owner[$0] == -1 } }
            if candidates.isEmpty { candidates = owner.indices.filter { owner[$0] >= 0 && owner[$0] != s.index && cracked[$0] } }
            if candidates.isEmpty { candidates = owner.indices.filter { owner[$0] >= 0 && owner[$0] != s.index } }
            if let i = candidates.randomElement() { act(s, i) }
        }
    }
}
