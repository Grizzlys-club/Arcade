import SpriteKit

/// Grizzly Says – memorise the sequence of glowing pads and repeat it on your own pads.
final class SimonGame: MiniScene {

    private static let padColors: [UIColor] = [
        UIColor(red: 1.0, green: 0.25, blue: 0.3, alpha: 1),
        UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1),
        UIColor(red: 0.2, green: 0.95, blue: 0.45, alpha: 1),
        UIColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 1)
    ]
    private static let padIcons = ["🏒", "🥅", "🏆", "🧤"]
    private static let padSounds = ["beep", "pop", "kick", "bounce"]

    private final class Pad {
        let node: SKSpriteNode
        let glow: SKSpriteNode
        let rect: CGRect
        init(node: SKSpriteNode, glow: SKSpriteNode, rect: CGRect) {
            self.node = node
            self.glow = glow
            self.rect = rect
        }
    }

    private final class SeatState {
        var pads: [Pad] = []
        var progress = 0
        var done = false
        var cpuTimer: Double = 0
        var status: SKLabelNode?
    }

    private enum Step { case pause, showing, input }

    private var states: [SeatState] = []
    private var sequence: [Int] = []
    private var rand: Rand!
    private var step: Step = .pause
    private var timer: Double = 0
    private var showIndex = 0
    private var showLit = false
    private var inputLeft: Double = 0
    private var hasHumans = false
    private var round = 0

    override func setupGame() {
        rand = newRand()
        hasHumans = seats.contains { !$0.isCPU }
        for s in seats {
            let st = SeatState()
            let usableTop = s.h / 2 - 40
            let usableBottom = -s.h / 2 + 16
            let gap: CGFloat = 10
            let side = min((s.w - 30 - gap) / 2, (usableTop - usableBottom - 40 - gap) / 2)
            let cy = (usableTop + usableBottom) / 2 - 12
            for i in 0..<4 {
                let col = CGFloat(i % 2)
                let row = CGFloat(i / 2)
                let x = (col - 0.5) * (side + gap)
                let y = cy + (0.5 - row) * (side + gap)
                let c = SimonGame.padColors[i]
                let tex = Gfx.pill(side, side, fill: c.withAlphaComponent(0.9), border: UIColor(white: 1, alpha: 0.7), corner: side * 0.22)
                let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: side * 1.9, height: side * 1.9))
                glow.color = c
                glow.colorBlendFactor = 1
                glow.blendMode = .add
                glow.alpha = 0
                glow.position = CGPoint(x: x, y: y)
                glow.zPosition = 4
                s.field.addChild(glow)
                let node = SKSpriteNode(texture: tex, size: CGSize(width: side, height: side))
                node.position = CGPoint(x: x, y: y)
                node.alpha = 0.35
                node.zPosition = 5
                s.field.addChild(node)
                let icon = SKLabelNode(text: SimonGame.padIcons[i])
                icon.fontSize = side * 0.42
                icon.verticalAlignmentMode = .center
                icon.zPosition = 1
                node.addChild(icon)
                st.pads.append(Pad(node: node, glow: glow, rect: CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side)))
            }
            let status = label("MERKEN!", size: min(22, s.w * 0.1), color: .white)
            status.position = CGPoint(x: 0, y: usableTop - 4)
            status.zPosition = 10
            s.field.addChild(status)
            st.status = status
            states.append(st)
        }
    }

    override func gameStarted() {
        nextRound()
    }

    private func nextRound() {
        round += 1
        sequence.append(rand.int(0, 3))
        step = .pause
        timer = 0.7
        showIndex = 0
        showLit = false
        for s in seats where s.alive {
            let st = states[s.index]
            st.progress = 0
            st.done = false
            st.status?.text = "MERKEN! (\(sequence.count))"
            st.status?.fontColor = .white
        }
    }

    private var showInterval: Double { return max(0.28, 0.6 - 0.025 * Double(sequence.count)) }

    override func gameUpdate(_ dt: Double) {
        switch step {
        case .pause:
            timer -= dt
            if timer <= 0 {
                step = .showing
                timer = 0
                showIndex = 0
                showLit = false
            }
        case .showing:
            timer -= dt
            if timer <= 0 {
                if showLit {
                    // turn off
                    for s in seats where s.alive { setLit(s, sequence[showIndex], false) }
                    showLit = false
                    showIndex += 1
                    timer = showInterval * 0.45
                    if showIndex >= sequence.count {
                        beginInput()
                    }
                } else {
                    let p = sequence[showIndex]
                    for s in seats where s.alive { setLit(s, p, true) }
                    Sfx.shared.play(SimonGame.padSounds[p])
                    showLit = true
                    timer = showInterval
                }
            }
        case .input:
            inputLeft -= dt
            for s in seats where s.alive && s.isCPU {
                let st = states[s.index]
                if st.done { continue }
                st.cpuTimer -= dt
                if st.cpuTimer <= 0 {
                    st.cpuTimer = 0.32 + (1 - s.skill) * 0.4 + Double.random(in: 0...0.2)
                    let len = Double(sequence.count)
                    let mistake = max(0, (len - (3 + s.skill * 9)) * 0.07) + 0.015 * (1 - s.skill)
                    var pad = sequence[st.progress]
                    if Double.random(in: 0..<1) < mistake {
                        pad = (pad + Int.random(in: 1...3)) % 4
                    }
                    press(s, pad)
                }
            }
            if inputLeft <= 0 {
                for s in seats where s.alive && !states[s.index].done {
                    fail(s, text: "ZU LANGSAM")
                }
                endRound()
            }
        }
        if elapsed > 80 && step != .input {
            finishGame()
        }
    }

    private func beginInput() {
        step = .input
        inputLeft = 2.5 + Double(sequence.count) * 0.9
        for s in seats where s.alive {
            let st = states[s.index]
            st.status?.text = "DU BIST DRAN!"
            st.status?.fontColor = s.color
            st.cpuTimer = 0.5 + Double.random(in: 0...0.3)
        }
    }

    private func setLit(_ s: Seat, _ p: Int, _ on: Bool) {
        let pad = states[s.index].pads[p]
        pad.node.removeAction(forKey: "lit")
        pad.glow.removeAction(forKey: "lit")
        if on {
            pad.node.alpha = 1
            pad.node.run(SKAction.scale(to: 1.07, duration: 0.06), withKey: "lit")
            pad.glow.alpha = 0.85
        } else {
            pad.node.run(SKAction.group([SKAction.fadeAlpha(to: 0.35, duration: 0.12), SKAction.scale(to: 1.0, duration: 0.12)]), withKey: "lit")
            pad.glow.run(SKAction.fadeOut(withDuration: 0.12), withKey: "lit")
        }
    }

    private func blink(_ s: Seat, _ p: Int) {
        setLit(s, p, true)
        let pad = states[s.index].pads[p]
        pad.node.run(SKAction.sequence([SKAction.wait(forDuration: 0.16), SKAction.run { [weak self] in self?.setLit(s, p, false) }]), withKey: "blink")
    }

    private func press(_ s: Seat, _ p: Int) {
        guard step == .input, s.alive else { return }
        let st = states[s.index]
        if st.done { return }
        blink(s, p)
        if sequence[st.progress] == p {
            if !s.isCPU { Sfx.shared.play(SimonGame.padSounds[p]); Haptic.tap() }
            st.progress += 1
            if st.progress >= sequence.count {
                st.done = true
                setScore(s, sequence.count)
                st.status?.text = "✓ SUPER!"
                st.status?.fontColor = Theme.uiGreen
                s.burst(at: CGPoint(x: 0, y: 0), color: s.color, count: 12)
                if seats.filter({ $0.alive && !states[$0.index].done }).isEmpty {
                    endRound()
                }
            }
        } else {
            fail(s, text: "FALSCH!")
            if seats.filter({ $0.alive && !states[$0.index].done }).isEmpty {
                endRound()
            }
        }
    }

    private func fail(_ s: Seat, text: String) {
        let st = states[s.index]
        st.done = true
        st.status?.text = text
        st.status?.fontColor = UIColor.red
        s.flash(UIColor.red, alpha: 0.4)
        s.shake()
        if !s.isCPU { Sfx.shared.play("wrong"); Haptic.bad() }
        s.knockOut("RAUS")
    }

    private func endRound() {
        if step != .input { return }
        step = .pause
        let alive = aliveSeats.count
        if alive <= 1 && n > 1 || alive == 0 || (hasHumans && !humansAlive) || elapsed > 80 {
            finishGame()
            return
        }
        Sfx.shared.play("right")
        run(SKAction.sequence([SKAction.wait(forDuration: 0.6), SKAction.run { [weak self] in self?.nextRound() }]))
        timer = 100 // wait for nextRound
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        for (i, pad) in st.pads.enumerated() where pad.rect.insetBy(dx: -4, dy: -4).contains(at) {
            press(seat, i)
            return
        }
    }
}
