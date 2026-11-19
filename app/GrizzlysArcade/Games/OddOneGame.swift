import SpriteKit

/// Ausreisser – tap the one shape that differs slightly. 10 rounds.
final class OddOneGame: MiniScene {

    private static let colors: [UIColor] = [
        UIColor(red: 0.2, green: 0.95, blue: 1.0, alpha: 1),
        UIColor(red: 1.0, green: 0.3, blue: 0.75, alpha: 1),
        UIColor(red: 0.6, green: 1.0, blue: 0.25, alpha: 1),
        UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1),
        UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1)
    ]
    private let rounds = 10

    private final class SeatState {
        var rand: Rand!
        var cells: [SKSpriteNode] = []
        var odd = 0
        var lock: Double = 0
        var done = false
        var cpuTimer: Double = 0
        var roundLabel: SKLabelNode!
        var cell: CGFloat = 50
        var cy: CGFloat = 0
        var cols = 3
        var hint: SKLabelNode?
    }

    private var states: [SeatState] = []
    private var round = 0
    private var roundTime: Double = 0
    private var waiting = false

    /// shape textures: 0 circle, 1 square, 2 diamond, 3 triangle
    private static func shapeTexture(_ kind: Int, _ size: CGFloat) -> SKTexture {
        return Gfx.texture("oddone_shape_\(kind)_\(Int(size))", size: CGSize(width: size, height: size)) { ctx in
            let s = size, m = s * 0.08
            ctx.setFillColor(UIColor.white.cgColor)
            switch kind {
            case 0: ctx.fillEllipse(in: CGRect(x: m, y: m, width: s - 2 * m, height: s - 2 * m))
            case 1: ctx.addPath(UIBezierPath(roundedRect: CGRect(x: m, y: m, width: s - 2 * m, height: s - 2 * m), cornerRadius: s * 0.16).cgPath); ctx.fillPath()
            case 2:
                ctx.move(to: CGPoint(x: s / 2, y: m)); ctx.addLine(to: CGPoint(x: s - m, y: s / 2))
                ctx.addLine(to: CGPoint(x: s / 2, y: s - m)); ctx.addLine(to: CGPoint(x: m, y: s / 2)); ctx.fillPath()
            default:
                ctx.move(to: CGPoint(x: s / 2, y: m)); ctx.addLine(to: CGPoint(x: s - m, y: s - m))
                ctx.addLine(to: CGPoint(x: m, y: s - m)); ctx.fillPath()
            }
        }
    }

    override func setupGame() {
        for s in seats {
            let st = SeatState()
            st.rand = newRand()
            st.cols = s.w > 300 ? 4 : 3
            let avail = min(s.w - 24, s.h - 100)
            st.cell = floor(avail / CGFloat(st.cols))
            st.cy = (s.h / 2 - 36 + (-s.h / 2 + 8)) / 2 - 4
            let n = st.cols * st.cols
            let gw = st.cell * CGFloat(st.cols)
            let panel = SKSpriteNode(texture: Gfx.pill(gw + 12, gw + 12, fill: UIColor(white: 0.05, alpha: 0.7), border: UIColor(white: 1, alpha: 0.2), corner: 18), size: CGSize(width: gw + 12, height: gw + 12))
            panel.position = CGPoint(x: 0, y: st.cy)
            panel.zPosition = 1
            s.field.addChild(panel)
            for i in 0..<n {
                let c = SKSpriteNode(texture: OddOneGame.shapeTexture(0, 64), size: CGSize(width: st.cell * 0.78, height: st.cell * 0.78))
                let col = i % st.cols, row = i / st.cols
                c.position = CGPoint(x: (CGFloat(col) - CGFloat(st.cols - 1) / 2) * st.cell, y: st.cy + (CGFloat(row) - CGFloat(st.cols - 1) / 2) * st.cell)
                c.zPosition = 3
                c.colorBlendFactor = 1
                c.alpha = 0.25
                s.field.addChild(c)
                st.cells.append(c)
            }
            st.roundLabel = label("Runde 1/\(rounds)", size: 13, color: UIColor(white: 1, alpha: 0.7))
            st.roundLabel.horizontalAlignmentMode = .left
            st.roundLabel.position = CGPoint(x: -s.w / 2 + 14, y: s.h / 2 - 22)
            st.roundLabel.zPosition = 6
            s.field.addChild(st.roundLabel)
            let hint = label("TIPPE DEN AUSREISSER", size: min(15, s.w * 0.07), color: .white)
            hint.position = CGPoint(x: 0, y: st.cy + gw / 2 + 22)
            hint.zPosition = 7
            s.field.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 3.5), SKAction.fadeOut(withDuration: 0.5)]))
            states.append(st)
        }
    }

    override func gameStarted() { newRound() }

    private func newRound() {
        round += 1
        waiting = false
        roundTime = 0
        timeoutArmed = false
        scheduleTimeout(7.5)
        // identical grid for every seat (same seed per round)
        let seed = Rand(seed: sharedSeed &+ UInt64(round) &* 7919)
        let kind = seed.int(0, 3)
        let colIdx = seed.int(0, OddOneGame.colors.count - 1)
        let diff = max(0.18, 0.55 - CGFloat(round) * 0.04)   // gets subtler
        let sameShapeDiff = seed.chance(0.5)
        for s in seats {
            let st = states[s.index]
            st.done = false
            st.lock = 0
            st.odd = Rand(seed: sharedSeed &+ UInt64(round) &* 104729).int(0, st.cells.count - 1)
            st.roundLabel.text = "Runde \(round)/\(rounds)"
            let base = OddOneGame.colors[colIdx]
            var h: CGFloat = 0, sat: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            base.getHue(&h, saturation: &sat, brightness: &b, alpha: &a)
            let oddCol = UIColor(hue: (h + diff * 0.22 + 1).truncatingRemainder(dividingBy: 1), saturation: sat, brightness: b, alpha: 1)
            for (i, c) in st.cells.enumerated() {
                let isOdd = i == st.odd
                c.removeAllActions()
                let k = (isOdd && sameShapeDiff && round > 3) ? (kind + 1) % 4 : kind
                c.texture = OddOneGame.shapeTexture(k, 64)
                c.color = (isOdd && !(sameShapeDiff && round > 3)) ? oddCol : base
                c.alpha = 1
                c.setScale(0.1)
                c.run(SKAction.sequence([SKAction.wait(forDuration: Double(i) * 0.012), SKAction.scale(to: 1, duration: 0.14)]))
            }
            if s.isCPU {
                st.cpuTimer = 0.9 + (1 - s.skill) * 3.2 + Double.random(in: 0...0.8) + Double(round) * 0.12
            }
        }
    }

    override func gameUpdate(_ dt: Double) {
        guard !waiting else { return }
        roundTime += dt
        for s in seats {
            let st = states[s.index]
            if st.lock > 0 { st.lock -= dt }
            if s.isCPU && !st.done && st.lock <= 0 {
                st.cpuTimer -= dt
                if st.cpuTimer <= 0 {
                    if Double.random(in: 0..<1) < 0.55 + s.skill * 0.4 { tap(s, st.odd) }
                    else {
                        var w = Int.random(in: 0..<st.cells.count)
                        if w == st.odd { w = (w + 1) % st.cells.count }
                        tap(s, w)
                        st.cpuTimer = 0.8 + (1 - s.skill)
                    }
                }
            }
        }
    }

    private func tap(_ s: Seat, _ idx: Int) {
        let st = states[s.index]
        guard !st.done, st.lock <= 0, !waiting else { return }
        let c = st.cells[idx]
        if idx == st.odd {
            let pts = roundTime < 2.5 ? 3 : (roundTime < 5 ? 2 : 1)
            addScore(s, pts)
            addStat("hits", 1, seat: s)
            st.done = true
            s.burst(at: c.position, color: c.color, count: 12, speed: 160)
            s.floatText("+\(pts)", at: CGPoint(x: c.position.x, y: c.position.y + 24), color: pts == 3 ? .yellow : Theme.uiGreen, size: 24)
            c.run(SKAction.sequence([SKAction.scale(to: 1.35, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
            if !s.isCPU { Sfx.shared.play(pts == 3 ? "coin" : "right"); Haptic.good() }
            for (i, o) in st.cells.enumerated() where i != idx { o.run(SKAction.fadeAlpha(to: 0.25, duration: 0.2)) }
            if seats.allSatisfy({ states[$0.index].done }) { endRound() } else { scheduleTimeout(4) }
        } else {
            st.lock = 1.0
            s.shake(4)
            s.flash(.red, alpha: 0.3)
            c.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.15, duration: 0.1), SKAction.fadeAlpha(to: 0.4, duration: 0.9)]))
            if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
        }
    }

    private var timeoutArmed = false
    private func scheduleTimeout(_ secs: Double) {
        guard !timeoutArmed else { return }
        timeoutArmed = true
        let r = round
        run(SKAction.sequence([SKAction.wait(forDuration: secs), SKAction.run { [weak self] in
            guard let self = self, self.round == r, !self.waiting, self.phase == .playing else { return }
            self.endRound()
        }]))
    }

    private func endRound() {
        guard !waiting else { return }
        waiting = true
        timeoutArmed = false
        for s in seats {
            let st = states[s.index]
            if !st.done { st.cells[st.odd].run(SKAction.repeat(SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.12), SKAction.scale(to: 1, duration: 0.12)]), count: 2)) }
        }
        let r = round
        run(SKAction.sequence([SKAction.wait(forDuration: 0.7), SKAction.run { [weak self] in
            guard let self = self, self.phase == .playing, self.round == r else { return }
            if self.round >= self.rounds { self.finishGame() } else { self.newRound() }
        }]))
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        var best = -1
        var bd = st.cell * 0.6
        for (i, c) in st.cells.enumerated() {
            let d = hypot(at.x - c.position.x, at.y - c.position.y)
            if d < bd { bd = d; best = i }
        }
        if best >= 0 { tap(seat, best) }
    }
}
