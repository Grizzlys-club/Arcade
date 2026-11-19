import SpriteKit

/// Takt-Tipper: neon notes fall down the lanes of every zone, tap the lane when a note crosses the hit line.
/// Same pre-generated pattern for all seats (newRand). PERFECT 3 / GOOD 1, combo multiplier up to x3.
final class RhythmGame: MiniScene {
    private struct NoteDef {
        let t: Double
        let lane: Int
    }

    private final class Note {
        let def: NoteDef
        let node: SKSpriteNode
        var done = false
        var missed = false
        var cpuAt: Double?
        init(def: NoteDef, node: SKSpriteNode) {
            self.def = def
            self.node = node
        }
    }

    private final class SeatState {
        var notes: [Note] = []
        var nextIdx = 0
        var combo = 0
        var laneW: CGFloat = 50
        var laneX: [CGFloat] = []
        var hitY: CGFloat = 0
        var topY: CGFloat = 0
        var speed: CGFloat = 150
        var receptors: [SKSpriteNode] = []
        var recGlow: [SKSpriteNode] = []
        var hitLine: SKSpriteNode?
        var comboLabel: SKLabelNode?
        var bear: BearNode?
        var noteTex: [SKTexture] = []
    }

    private let laneColors: [UIColor] = [
        UIColor(red: 0.2, green: 0.85, blue: 1.0, alpha: 1),
        UIColor(red: 1.0, green: 0.3, blue: 0.75, alpha: 1),
        UIColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1),
        UIColor(red: 0.35, green: 1.0, blue: 0.5, alpha: 1)
    ]
    private var pattern: [NoteDef] = []
    private var states: [SeatState] = []
    private var lanes = 3
    private let fallTime: Double = 1.4
    private let beatLen: Double = 0.5
    private var lastBeat = -1
    private let perfectWin = 0.075
    private let goodWin = 0.16
    private let catchWin = 0.28

    // MARK: setup

    override func setupGame() {
        duration = 40
        lanes = n <= 2 ? 4 : 3

        // pattern: 120 BPM, eighth-note grid
        let r = newRand()
        var t = 1.9
        var last = -1
        let step = beatLen / 2
        var k = 0
        while t < 37.8 {
            let prog = t / 38
            let onBeat = k % 2 == 0
            let p = (onBeat ? 0.64 : 0.27) * (0.65 + 0.5 * prog)
            if r.chance(p) {
                var lane = r.int(0, lanes - 1)
                if lane == last { lane = (lane + r.int(1, lanes - 1)) % lanes }
                pattern.append(NoteDef(t: t, lane: lane))
                last = lane
                if prog > 0.45 && r.chance(0.12) {
                    let l2 = (lane + r.int(1, lanes - 1)) % lanes
                    pattern.append(NoteDef(t: t, lane: l2))
                }
            }
            t += step
            k += 1
        }

        for s in seats {
            let st = SeatState()
            buildSeat(s, st)
            states.append(st)
        }
    }

    private func buildSeat(_ s: Seat, _ st: SeatState) {
        let innerW = s.w - 12
        let laneW = innerW / CGFloat(lanes)
        st.laneW = laneW
        st.hitY = -s.h / 2 + 64
        st.topY = s.h / 2 - 62
        st.speed = (st.topY - st.hitY) / CGFloat(fallTime)
        let laneH = st.topY - st.hitY + 70
        let recR = min(laneW * 0.4, 22)

        for i in 0..<lanes {
            let c = laneColors[i % laneColors.count]
            let x = -innerW / 2 + laneW * (CGFloat(i) + 0.5)
            st.laneX.append(x)
            let bg = SKSpriteNode(texture: Gfx.rect(laneW - 4, laneH, c.withAlphaComponent(0.09), corner: 8), size: CGSize(width: laneW - 4, height: laneH))
            bg.position = CGPoint(x: x, y: st.hitY - 28 + laneH / 2)
            bg.zPosition = 1
            s.field.addChild(bg)
            let edge = SKSpriteNode(color: c.withAlphaComponent(0.25), size: CGSize(width: 1.5, height: laneH))
            edge.position = CGPoint(x: x - laneW / 2 + 1, y: bg.position.y)
            edge.zPosition = 2
            s.field.addChild(edge)

            let glow = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: recR * 4.2, height: recR * 4.2))
            glow.color = c
            glow.colorBlendFactor = 1
            glow.blendMode = .add
            glow.alpha = 0.0
            glow.position = CGPoint(x: x, y: st.hitY)
            glow.zPosition = 4
            s.field.addChild(glow)
            st.recGlow.append(glow)

            let rec = SKSpriteNode(texture: Gfx.circle(recR, c.withAlphaComponent(0.2), ring: c), size: CGSize(width: recR * 2, height: recR * 2))
            rec.position = CGPoint(x: x, y: st.hitY)
            rec.zPosition = 5
            s.field.addChild(rec)
            st.receptors.append(rec)

            st.noteTex.append(Gfx.pill(laneW - 12, 20, fill: c, border: .white, corner: 10))
        }
        let line = SKSpriteNode(color: UIColor(white: 1, alpha: 0.35), size: CGSize(width: innerW, height: 2))
        line.position = CGPoint(x: 0, y: st.hitY)
        line.zPosition = 3
        s.field.addChild(line)
        st.hitLine = line

        let bear = makeBear(s, height: 32, faceRight: false)
        bear.position = CGPoint(x: 0, y: -s.h / 2 + 6)
        bear.zPosition = 6
        s.field.addChild(bear)
        bear.startBob(amount: 2, duration: 0.25)
        st.bear = bear

        let combo = MiniScene.label("", size: s.w < 250 ? 15 : 18, color: .white)
        combo.position = CGPoint(x: 0, y: s.h / 2 - 38)
        combo.zPosition = 410
        s.node.addChild(combo)
        st.comboLabel = combo

        if !s.isCPU {
            let hint = MiniScene.label("TIPPE IM TAKT", size: 13, color: UIColor(white: 1, alpha: 0.75))
            hint.position = CGPoint(x: 0, y: st.hitY + 60)
            hint.zPosition = 410
            s.node.addChild(hint)
            hint.run(SKAction.sequence([SKAction.wait(forDuration: 6), SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
        }
    }

    // MARK: input

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        let st = states[seat.index]
        let lane = laneIndex(st, x: at.x, seat: seat)
        press(lane: lane, seat: seat, st: st)
        tapJudge(seat, st, lane: lane)
    }

    private func laneIndex(_ st: SeatState, x: CGFloat, seat: Seat) -> Int {
        var best = 0
        var bd = CGFloat.greatestFiniteMagnitude
        for (i, lx) in st.laneX.enumerated() {
            let d = abs(lx - x)
            if d < bd { bd = d; best = i }
        }
        return best
    }

    private func press(lane: Int, seat: Seat, st: SeatState) {
        guard lane < st.receptors.count else { return }
        let rec = st.receptors[lane]
        rec.removeAction(forKey: "p")
        rec.run(SKAction.sequence([SKAction.scale(to: 1.25, duration: 0.04), SKAction.scale(to: 1.0, duration: 0.1)]), withKey: "p")
        let g = st.recGlow[lane]
        g.removeAction(forKey: "g")
        g.alpha = 0.7
        g.run(SKAction.fadeOut(withDuration: 0.25), withKey: "g")
    }

    private func tapJudge(_ seat: Seat, _ st: SeatState, lane: Int) {
        var best: Note?
        var bd = 99.0
        for nt in st.notes where !nt.done && !nt.missed && nt.def.lane == lane {
            let d = abs(nt.def.t - elapsed)
            if d < catchWin && d < bd { bd = d; best = nt }
        }
        if let nt = best {
            resolve(seat, st, nt, err: nt.def.t - elapsed)
        } else {
            // tapping the void breaks the combo
            if st.combo > 0 { breakCombo(seat, st) }
            Sfx.shared.play("tap")
        }
    }

    // MARK: judging

    private func resolve(_ s: Seat, _ st: SeatState, _ nt: Note, err: Double) {
        let a = abs(err)
        let x = st.laneX[nt.def.lane]
        if a > goodWin {
            // too early / too late: miss
            nt.missed = true
            markMiss(s, st, nt)
            return
        }
        let perfect = a <= perfectWin
        let mult = min(3, 1 + st.combo / 10)
        let pts = (perfect ? 3 : 1) * mult
        st.combo += 1
        let newMult = min(3, 1 + st.combo / 10)
        addScore(s, pts)
        addStat("hits", 1, seat: s)
        nt.done = true
        let c = laneColors[nt.def.lane % laneColors.count]
        nt.node.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.6, duration: 0.12), SKAction.fadeOut(withDuration: 0.12)]),
            SKAction.removeFromParent()
        ]))
        s.burst(at: CGPoint(x: x, y: st.hitY), color: perfect ? UIColor.yellow : c, count: perfect ? 12 : 6, speed: perfect ? 90 : 60)
        s.floatText(perfect ? "PERFEKT" : "GUT", at: CGPoint(x: x, y: st.hitY + 34), color: perfect ? UIColor.yellow : .white, size: s.w < 250 ? 12 : 15)
        if perfect {
            Sfx.shared.play("coin")
            if !s.isCPU { Haptic.tap(.medium) }
            st.bear?.squash()
        } else {
            Sfx.shared.play("tap")
            if !s.isCPU { Haptic.tap(.light) }
        }
        if newMult > mult {
            s.banner("x\(newMult)", color: UIColor.yellow, size: 34, duration: 0.4)
        }
        updateCombo(s, st)
    }

    private func markMiss(_ s: Seat, _ st: SeatState, _ nt: Note) {
        nt.node.removeAllActions()
        nt.node.colorBlendFactor = 0.8
        nt.node.color = UIColor(red: 0.35, green: 0.05, blue: 0.1, alpha: 1)
        nt.node.alpha = 0.55
        breakCombo(s, st)
        s.floatText("MISS", at: CGPoint(x: st.laneX[nt.def.lane], y: st.hitY + 30), color: UIColor(red: 1, green: 0.35, blue: 0.35, alpha: 1), size: s.w < 250 ? 11 : 14)
        Sfx.shared.play("miss")
    }

    private func breakCombo(_ s: Seat, _ st: SeatState) {
        let had = st.combo
        st.combo = 0
        updateCombo(s, st)
        if had >= 5 {
            s.flash(UIColor.red, alpha: 0.18, duration: 0.25)
            if !s.isCPU { Haptic.bad() }
        }
    }

    private func updateCombo(_ s: Seat, _ st: SeatState) {
        guard let l = st.comboLabel else { return }
        if st.combo >= 2 {
            let m = min(3, 1 + st.combo / 10)
            l.text = "\(st.combo) COMBO  x\(m)"
            l.fontColor = m == 3 ? UIColor.yellow : (m == 2 ? Theme.uiOrange : UIColor.white)
            l.removeAction(forKey: "pop")
            l.setScale(1.0)
            l.run(SKAction.sequence([SKAction.scale(to: 1.2, duration: 0.05), SKAction.scale(to: 1.0, duration: 0.08)]), withKey: "pop")
        } else {
            l.text = ""
        }
    }

    // MARK: update

    override func gameUpdate(_ dt: Double) {
        // beat
        let beat = Int(elapsed / beatLen)
        if beat != lastBeat {
            lastBeat = beat
            Sfx.shared.play("tick")
            for st in states {
                if let l = st.hitLine {
                    l.removeAction(forKey: "beat")
                    l.alpha = 1
                    l.run(SKAction.fadeAlpha(to: 0.55, duration: 0.25), withKey: "beat")
                    l.run(SKAction.sequence([SKAction.scaleY(to: 2.5, duration: 0.04), SKAction.scaleY(to: 1, duration: 0.2)]), withKey: "beatS")
                }
            }
        }

        for s in seats {
            let st = states[s.index]
            // spawn
            while st.nextIdx < pattern.count && pattern[st.nextIdx].t - fallTime <= elapsed {
                let def = pattern[st.nextIdx]
                st.nextIdx += 1
                let node = SKSpriteNode(texture: st.noteTex[def.lane], size: CGSize(width: st.laneW - 12, height: 20))
                node.position = CGPoint(x: st.laneX[def.lane], y: st.topY)
                node.zPosition = 8
                node.alpha = 0
                let g = SKSpriteNode(texture: Gfx.glow, size: CGSize(width: st.laneW + 10, height: 56))
                g.color = laneColors[def.lane % laneColors.count]
                g.colorBlendFactor = 1
                g.blendMode = .add
                g.alpha = 0.6
                g.zPosition = -1
                node.addChild(g)
                s.field.addChild(node)
                let nt = Note(def: def, node: node)
                if s.isCPU {
                    let missChance = (1 - s.skill) * 0.45 + 0.03
                    if Double.random(in: 0..<1) >= missChance {
                        let spread = 0.02 + (1 - s.skill) * 0.15
                        let e = (Double.random(in: -1...1) + Double.random(in: -1...1)) * 0.5 * spread
                        nt.cpuAt = def.t + e
                    }
                }
                st.notes.append(nt)
            }
            // move / miss / cleanup
            var i = st.notes.count - 1
            while i >= 0 {
                let nt = st.notes[i]
                if nt.done {
                    st.notes.remove(at: i)
                    i -= 1
                    continue
                }
                let dtn = nt.def.t - elapsed
                nt.node.position.y = st.hitY + CGFloat(dtn) * st.speed
                if !nt.missed {
                    nt.node.alpha = min(1, CGFloat((fallTime - dtn) / 0.25))
                }
                if s.isCPU, let at = nt.cpuAt, !nt.missed, elapsed >= at {
                    nt.cpuAt = nil
                    press(lane: nt.def.lane, seat: s, st: st)
                    resolve(s, st, nt, err: nt.def.t - elapsed)
                    if nt.done { st.notes.remove(at: i); i -= 1; continue }
                }
                if !nt.missed && -dtn > goodWin {
                    nt.missed = true
                    markMiss(s, st, nt)
                }
                if -dtn > 0.7 {
                    nt.node.removeFromParent()
                    st.notes.remove(at: i)
                }
                i -= 1
            }
        }
    }
}
