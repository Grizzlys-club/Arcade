import SpriteKit

/// Zahlen-Jagd – tap 1…12 in order, fastest finisher wins the round. 3 rounds.
final class NumbersGame: MiniScene {

    private final class SeatState {
        var bubbles: [SKSpriteNode] = []
        var next = 1
        var frozen: Double = 0
        var finished = false
        var cpuTimer: Double = 0
        var hint: SKLabelNode!
        var container = SKNode()
    }

    private let count = 12
    private let rounds = 3
    private var round = 0
    private var states: [SeatState] = []
    private var rand: Rand!
    private var radius: CGFloat = 24
    private var positions: [CGPoint] = []
    private var finishOrder: [Int] = []
    private var roundActive = false
    private var roundTime: Double = 0
    private var pause: Double = 0

    override func setupGame() {
        rand = newRand()
        guard let s0 = seats.first else { return }
        let area = (s0.w - 16) * (s0.h - 60)
        radius = min(30, max(18, sqrt(area / CGFloat(count)) * 0.36))
        for s in seats {
            let st = SeatState()
            st.container.zPosition = 5
            s.field.addChild(st.container)
            let hint = label("TIPPE 1 → 12", size: min(18, s.w * 0.085), color: s.color)
            hint.position = CGPoint(x: 0, y: s.h / 2 - 44)
            hint.zPosition = 10
            s.field.addChild(hint)
            st.hint = hint
            states.append(st)
        }
    }

    override func gameStarted() {
        startRound()
    }

    private func makeLayout() {
        guard let s0 = seats.first else { return }
        let r = radius
        let minX = -s0.w / 2 + r + 8
        let maxX = s0.w / 2 - r - 8
        let minY = -s0.h / 2 + r + 10
        let maxY = s0.h / 2 - 58 - r
        var pts: [CGPoint] = []
        var tries = 0
        var minDist = r * 2.25
        while pts.count < count {
            tries += 1
            if tries > 4000 {
                // relax spacing if the zone is cramped
                minDist *= 0.92
                tries = 0
                pts = []
            }
            let p = CGPoint(x: rand.range(minX, maxX), y: rand.range(minY, maxY))
            if pts.allSatisfy({ hypot($0.x - p.x, $0.y - p.y) >= minDist }) {
                pts.append(p)
            }
        }
        positions = pts
    }

    private func startRound() {
        round += 1
        makeLayout()
        finishOrder = []
        roundActive = true
        roundTime = 0
        for s in seats {
            let st = states[s.index]
            st.container.removeAllChildren()
            st.bubbles = []
            st.next = 1
            st.finished = false
            st.frozen = 0
            st.cpuTimer = 0.8 + Double.random(in: 0...0.3)
            st.hint.text = s.w < 300 ? "RUNDE \(round)/\(rounds)" : "RUNDE \(round)/\(rounds) · TIPPE 1 → \(count)"
            for i in 0..<count {
                let b = SKSpriteNode(texture: Gfx.circle(radius, UIColor(white: 0.12, alpha: 0.95), ring: s.color), size: CGSize(width: radius * 2, height: radius * 2))
                b.position = positions[i]
                b.zPosition = 1
                let l = label("\(i + 1)", size: radius * 0.95, color: .white)
                l.zPosition = 1
                b.addChild(l)
                b.setScale(0)
                b.run(SKAction.sequence([SKAction.wait(forDuration: Double(i) * 0.02), SKAction.scale(to: 1, duration: 0.15)]))
                st.container.addChild(b)
                st.bubbles.append(b)
            }
            highlightNext(s)
        }
    }

    private func highlightNext(_ s: Seat) {
        let st = states[s.index]
        guard st.next <= count else { return }
        let b = st.bubbles[st.next - 1]
        // subtle pulse only for weak hint on round 1
        if round == 1 && st.next == 1 {
            b.run(SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.12, duration: 0.35), SKAction.scale(to: 1.0, duration: 0.35)])), withKey: "pulse")
        }
    }

    override func gameUpdate(_ dt: Double) {
        if !roundActive {
            pause -= dt
            if pause <= 0 && phase == .playing {
                if round >= rounds { finishGame() } else { startRound() }
            }
            return
        }
        roundTime += dt
        for s in seats {
            let st = states[s.index]
            if st.frozen > 0 { st.frozen -= dt }
            if s.isCPU && !st.finished && st.frozen <= 0 {
                st.cpuTimer -= dt
                if st.cpuTimer <= 0 {
                    st.cpuTimer = 0.42 + (1 - s.skill) * 0.6 + Double.random(in: 0...0.25)
                    if Double.random(in: 0..<1) < 0.02 + 0.06 * (1 - s.skill) {
                        // wrong tap
                        var wrong = Int.random(in: 1...count)
                        if wrong == st.next { wrong = wrong % count + 1 }
                        tap(s, number: wrong)
                    } else {
                        tap(s, number: st.next)
                    }
                }
            }
        }
        if roundTime > 22 || seats.allSatisfy({ states[$0.index].finished }) {
            endRound()
        }
    }

    private func tap(_ s: Seat, number: Int) {
        let st = states[s.index]
        if st.finished || st.frozen > 0 || !roundActive { return }
        if number == st.next {
            let b = st.bubbles[number - 1]
            b.removeAction(forKey: "pulse")
            b.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 1.5, duration: 0.12), SKAction.fadeOut(withDuration: 0.12)]), SKAction.removeFromParent()]))
            s.burst(at: b.position, color: s.color, count: 6, speed: 60)
            if !s.isCPU { Sfx.shared.play("pop"); Haptic.tap() }
            st.next += 1
            if st.next > count {
                st.finished = true
                finishOrder.append(s.index)
                let place = finishOrder.count
                let pts = n - place + 1
                addScore(s, pts)
                s.banner(place == 1 ? "ERSTER!" : "\(place). PLATZ", color: place == 1 ? .yellow : s.color, size: 36, duration: 1.0)
                s.floatText("+\(pts)", at: CGPoint(x: 0, y: -40), color: .yellow, size: 28)
                if !s.isCPU { Sfx.shared.play(place == 1 ? "right" : "coin") }
            }
        } else {
            st.frozen = 0.8
            s.flash(UIColor.red, alpha: 0.35)
            s.shake(4)
            if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
            if number >= 1 && number <= count {
                let b = st.bubbles[number - 1]
                if b.parent != nil {
                    b.run(SKAction.sequence([SKAction.moveBy(x: 6, y: 0, duration: 0.04), SKAction.moveBy(x: -12, y: 0, duration: 0.08), SKAction.moveBy(x: 6, y: 0, duration: 0.04)]))
                }
            }
        }
    }

    private func endRound() {
        roundActive = false
        pause = 1.6
        for s in seats where !states[s.index].finished {
            s.floatText("ZEIT UM", at: .zero, color: UIColor(white: 1, alpha: 0.8), size: 24)
        }
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        var bestI = -1
        var bestD = radius * 1.25
        for (i, b) in st.bubbles.enumerated() where b.parent != nil && i + 1 >= st.next {
            let d = hypot(b.position.x - at.x, b.position.y - at.y)
            if d < bestD { bestD = d; bestI = i }
        }
        if bestI >= 0 { tap(seat, number: bestI + 1) }
    }
}
