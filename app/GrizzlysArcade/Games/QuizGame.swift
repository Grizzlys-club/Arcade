import SpriteKit

// MARK: - Fragen vom Verein prüfen lassen
// Each entry: question, then 4 answers – the FIRST answer is the correct one (answers get shuffled in the game).
let QuizPool: [(q: String, a: [String])] = [
    ("Wie viele Feldspieler hat ein Team im Grossfeld gleichzeitig auf dem Feld (ohne Torhüter)?", ["5", "4", "6", "3"]),
    ("Wie viele Feldspieler stehen im Kleinfeld pro Team auf dem Feld (ohne Torhüter)?", ["3", "2", "4", "5"]),
    ("Wie viele Drittel hat ein Unihockeyspiel?", ["3", "2", "4", "5"]),
    ("Wie lange dauert ein Drittel im Grossfeld bei den Aktiven (Elite)?", ["20 Minuten", "15 Minuten", "25 Minuten", "30 Minuten"]),
    ("Wie viele Löcher hat ein offizieller Unihockeyball?", ["26", "18", "32", "40"]),
    ("Welchen Durchmesser hat ein offizieller Unihockeyball?", ["72 mm", "52 mm", "62 mm", "82 mm"]),
    ("Wie schwer ist ein offizieller Unihockeyball ungefähr?", ["23 Gramm", "13 Gramm", "43 Gramm", "63 Gramm"]),
    ("Aus welchem Material ist der Unihockeyball?", ["Kunststoff", "Gummi", "Leder", "Holz"]),
    ("Was hat der Torhüter im Unihockey NICHT?", ["Einen Stock", "Eine Maske", "Handschuhe", "Ein Trikot"]),
    ("Wie gross ist ein Grossfeld?", ["40 x 20 m", "30 x 15 m", "60 x 30 m", "20 x 10 m"]),
    ("Wie hoch ist die Bande beim Unihockey?", ["50 cm", "30 cm", "80 cm", "1 m"]),
    ("Wie gross ist ein Grossfeld-Tor (Breite x Höhe)?", ["160 x 115 cm", "183 x 122 cm", "120 x 90 cm", "300 x 200 cm"]),
    ("Was ist im Unihockey für Feldspieler verboten?", ["Den Ball mit dem Kopf spielen", "Einen Pass spielen", "Aufs Tor schiessen", "Die Linie wechseln"]),
    ("Darf ein Feldspieler den Ball mit der Hand spielen?", ["Nein", "Ja, immer", "Nur im Angriff", "Nur beim Bully"]),
    ("Wie heisst Unihockey auf Englisch?", ["Floorball", "Fieldball", "Streetball", "Icehockey"]),
    ("Welches Land hat bei den Männern die meisten WM-Titel gewonnen?", ["Schweden", "Finnland", "Schweiz", "Tschechien"]),
    ("Wie heisst der internationale Unihockey-Verband?", ["IFF", "FIFA", "IIHF", "UEFA"]),
    ("Wie heisst der Schweizer Unihockey-Verband?", ["Swiss Unihockey", "Swiss Floorball League", "Unihockey Helvetia", "Schweizer Stockverband"]),
    ("Wie lange dauert eine kleine Strafe?", ["2 Minuten", "1 Minute", "5 Minuten", "10 Minuten"]),
    ("Wie lange dauert eine grosse Strafe?", ["5 Minuten", "3 Minuten", "4 Minuten", "8 Minuten"]),
    ("Bis zu welcher Höhe darf man den Stock beim Schlagen schwingen?", ["Hüfthöhe", "Kniehöhe", "Schulterhöhe", "Kopfhöhe"]),
    ("In welchem Land entstand das moderne Unihockey in den 1970er-Jahren?", ["Schweden", "Kanada", "USA", "Schweiz"]),
    ("In welchem Jahr wurde der internationale Verband IFF gegründet?", ["1986", "1966", "1996", "2006"]),
    ("Wie heisst die Spielfortsetzung nach einem Foul?", ["Freischlag", "Einwurf", "Eckball", "Abstoss"]),
    ("Wie heisst das Anspiel in der Mitte im Unihockey?", ["Bully", "Kick-off", "Tip-off", "Break"]),
    ("Wie wird das Spiel nach einem Tor fortgesetzt?", ["Mit einem Bully am Mittelpunkt", "Mit einem Freischlag", "Mit einem Abwurf des Torhüters", "Mit einem Penalty"]),
    ("Wie viele Schiedsrichter leiten ein Grossfeldspiel normalerweise?", ["2", "1", "3", "4"]),
    ("Wann gibt es einen Penalty?", ["Wenn eine klare Torchance durch ein Foul verhindert wird", "Nach jedem Foul", "Wenn der Ball aus dem Feld fliegt", "Nach jedem Tor"]),
    ("Wie viele Timeouts hat ein Team pro Spiel?", ["1", "2", "3", "Keines"]),
    ("Wie lange dauert ein Timeout?", ["30 Sekunden", "10 Sekunden", "1 Minute", "2 Minuten"]),
    ("Dürfen Feldspieler den kleinen Torraum betreten?", ["Nein", "Ja, jederzeit", "Nur der Captain", "Nur in der Verlängerung"]),
    ("Was ist ein Hattrick?", ["Drei Tore vom selben Spieler in einem Spiel", "Drei Fouls hintereinander", "Ein Tor in drei Sekunden", "Drei Pässe ohne Bodenkontakt"]),
    ("Sind harte Körperchecks wie im Eishockey erlaubt?", ["Nein", "Ja", "Nur an der Bande", "Nur im Schlussdrittel"]),
    ("Wie viele Punkte gibt in der Schweizer Meisterschaft ein Sieg in der regulären Spielzeit?", ["3", "2", "1", "4"]),
    ("Mit welcher Seite der Schaufel darf man den Ball spielen?", ["Mit beiden Seiten", "Nur mit der Vorderseite", "Nur mit der Rückseite", "Nur mit der Spitze"]),
    ("Wie heisst die höchste Schweizer Liga der Männer?", ["Unihockey Prime League", "Super League", "National League", "Champions League"]),
    ("Wie heisst das Spielgerät des Feldspielers?", ["Stock", "Schläger-Brett", "Paddel", "Keule"]),
    ("Was muss ein Spieler nach einer Strafe tun?", ["Auf die Strafbank", "In die Garderobe", "Ins Tor", "Auf die Tribüne"]),
    ("Wie viele Spieler pro Team sind im Grossfeld gleichzeitig auf dem Feld (mit Torhüter)?", ["6", "5", "7", "11"]),
    ("Darf man während des Spiels die Spieler wechseln?", ["Ja, jederzeit in der Wechselzone", "Nur in der Drittelspause", "Nur nach einem Tor", "Nein, nie"]),
    ("Wo darf der Torhüter den Ball mit der Hand spielen?", ["Nur im Torhüterraum", "Auf dem ganzen Feld", "In der eigenen Hälfte", "Nirgends"]),
    ("Wann wurden die Schweizer Frauen Unihockey-Weltmeisterinnen?", ["2005", "1995", "2015", "Noch nie"]),
    ("Womit ist das Spielfeld im Unihockey umgeben?", ["Mit einer Bande", "Mit einem Netz", "Mit einer Mauer", "Mit nichts"])
]

/// Unihockey-Quiz: 6 questions, everyone answers in their own zone. Correct = 3 + speed bonus (up to 3).
final class QuizGame: MiniScene {
    fileprivate final class SeatUI {
        let seat: Seat
        let root = SKNode()
        var buttons: [(node: SKSpriteNode, center: CGPoint, size: CGSize, answer: Int)] = []
        var timerBar: SKSpriteNode?
        var timerW: CGFloat = 0
        var answered: Int? = nil
        var answerTime: Double = 0
        var cpuAt: Double = 0
        var cpuCorrect = false
        init(seat: Seat) { self.seat = seat }
    }

    private let questionCount = 6
    private let timePerQ: Double = 10
    private var picked: [Int] = []
    private var orders: [[Int]] = []
    private var qIndex = -1
    private var qTime: Double = 0
    private var revealing = false
    private var uis: [SeatUI] = []

    override func setupGame() {
        duration = 0
        let r = newRand()
        picked = Array(r.shuffled(Array(0..<QuizPool.count)).prefix(questionCount))
        orders = picked.map { _ in r.shuffled([0, 1, 2, 3]) }
        for s in seats {
            let ui = SeatUI(seat: s)
            ui.root.zPosition = 5
            s.field.addChild(ui.root)
            uis.append(ui)
            let logo = SKSpriteNode(imageNamed: "logo")
            let d = min(s.w, s.h) * 0.5
            logo.size = CGSize(width: d, height: d)
            logo.alpha = 0.06
            logo.zPosition = 0
            s.field.addChild(logo)
            let wait = label("🧠 Gleich geht's los…", size: s.w > 300 ? 20 : 14, color: UIColor(white: 1, alpha: 0.8))
            ui.root.addChild(wait)
        }
    }

    override func gameStarted() {
        nextQuestion()
    }

    private func nextQuestion() {
        qIndex += 1
        if qIndex >= picked.count {
            finishGame()
            return
        }
        qTime = 0
        revealing = false
        let q = QuizPool[picked[qIndex]]
        let order = orders[qIndex]
        for ui in uis {
            build(ui, q: q, order: order)
            let s = ui.seat
            ui.answered = nil
            if s.isCPU {
                ui.cpuAt = Double.random(in: 1.2...6.5) * (1.25 - s.skill * 0.6)
                ui.cpuCorrect = Double.random(in: 0...1) < 0.3 + 0.6 * s.skill
            }
        }
        Sfx.shared.play("tick")
    }

    private func build(_ ui: SeatUI, q: (q: String, a: [String]), order: [Int]) {
        let s = ui.seat
        ui.root.removeAllChildren()
        ui.buttons = []
        let wide = s.w > 300
        let top = s.h / 2 - 32
        let counter = label("FRAGE \(qIndex + 1)/\(picked.count)", size: wide ? 12 : 10, color: s.color)
        counter.position = CGPoint(x: 0, y: top - 6)
        ui.root.addChild(counter)
        let ql = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        ql.text = q.q
        ql.fontSize = wide ? 18 : 13
        ql.fontColor = .white
        ql.numberOfLines = 0
        ql.preferredMaxLayoutWidth = s.w - 24
        ql.lineBreakMode = .byWordWrapping
        ql.horizontalAlignmentMode = .center
        ql.verticalAlignmentMode = .top
        ql.position = CGPoint(x: 0, y: top - 18)
        ui.root.addChild(ql)

        // answers
        let bottom = -s.h / 2 + 12
        let gap: CGFloat = 6
        var rects: [(CGPoint, CGSize)] = []
        if wide {
            let bw = (s.w - 24 - gap) / 2
            let bh: CGFloat = min(58, (s.h * 0.42 - gap) / 2)
            for i in 0..<4 {
                let col = CGFloat(i % 2)
                let row = CGFloat(1 - i / 2)
                let cx = -s.w / 2 + 12 + bw / 2 + col * (bw + gap)
                let cy = bottom + bh / 2 + row * (bh + gap)
                rects.append((CGPoint(x: cx, y: cy), CGSize(width: bw, height: bh)))
            }
        } else {
            let bw = s.w - 16
            let bh: CGFloat = max(30, min(44, (s.h * 0.5 - 3 * gap) / 4))
            for i in 0..<4 {
                let cy = bottom + bh / 2 + CGFloat(3 - i) * (bh + gap)
                rects.append((CGPoint(x: 0, y: cy), CGSize(width: bw, height: bh)))
            }
        }
        let answersTop = (rects.map { $0.0.y + $0.1.height / 2 }.max() ?? 0)
        for i in 0..<4 {
            let (c, sz) = rects[i]
            let ans = order[i]
            let b = SKSpriteNode(texture: Gfx.pill(sz.width, sz.height, fill: UIColor(white: 1, alpha: 0.1), border: s.color.withAlphaComponent(0.7), corner: 12), size: sz)
            b.position = c
            ui.root.addChild(b)
            let l = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            l.text = q.a[ans]
            l.fontSize = wide ? 15 : 12
            l.fontColor = .white
            l.numberOfLines = 2
            l.preferredMaxLayoutWidth = sz.width - 14
            l.lineBreakMode = .byWordWrapping
            l.horizontalAlignmentMode = .center
            l.verticalAlignmentMode = .center
            l.zPosition = 1
            b.addChild(l)
            ui.buttons.append((node: b, center: c, size: sz, answer: ans))
        }
        // timer bar between question and answers
        let tw = s.w - 40
        let back = SKSpriteNode(color: UIColor(white: 1, alpha: 0.12), size: CGSize(width: tw, height: 5))
        back.position = CGPoint(x: 0, y: answersTop + 10)
        ui.root.addChild(back)
        let bar = SKSpriteNode(color: s.color, size: CGSize(width: tw, height: 5))
        bar.anchorPoint = CGPoint(x: 0, y: 0.5)
        bar.position = CGPoint(x: -tw / 2, y: answersTop + 10)
        bar.zPosition = 1
        ui.root.addChild(bar)
        ui.timerBar = bar
        ui.timerW = tw
        // shrink question font if it would run into the timer
        let room = (top - 18) - (answersTop + 18)
        var fs = ql.fontSize
        while ql.frame.height > room && fs > 9 {
            fs -= 1
            ql.fontSize = fs
        }
    }

    override func gameUpdate(_ dt: Double) {
        if qIndex < 0 || qIndex >= picked.count || revealing { return }
        qTime += dt
        let left = max(0, timePerQ - qTime)
        for ui in uis {
            if ui.answered == nil {
                ui.timerBar?.size.width = ui.timerW * CGFloat(left / timePerQ)
            }
            if ui.seat.isCPU && ui.answered == nil && qTime >= ui.cpuAt {
                let correct = 0
                var choice = correct
                if !ui.cpuCorrect {
                    choice = Int.random(in: 1...3)
                }
                answer(ui, choice)
            }
        }
        if left <= 0 || uis.allSatisfy({ $0.answered != nil }) {
            reveal()
        }
    }

    private func answer(_ ui: SeatUI, _ ans: Int) {
        if ui.answered != nil || revealing { return }
        ui.answered = ans
        ui.answerTime = qTime
        for b in ui.buttons {
            if b.answer == ans {
                b.node.texture = Gfx.pill(b.size.width, b.size.height, fill: ui.seat.color.withAlphaComponent(0.55), border: UIColor.white, corner: 12)
                b.node.run(SKAction.sequence([SKAction.scale(to: 1.06, duration: 0.07), SKAction.scale(to: 1.0, duration: 0.1)]))
            } else {
                b.node.alpha = 0.5
            }
        }
        if !ui.seat.isCPU {
            Sfx.shared.play("tap")
            Haptic.tap()
        }
    }

    private func reveal() {
        revealing = true
        var anyHumanRight = false
        for ui in uis {
            let s = ui.seat
            for b in ui.buttons {
                if b.answer == 0 {
                    b.node.alpha = 1
                    b.node.texture = Gfx.pill(b.size.width, b.size.height, fill: UIColor(red: 0.15, green: 0.75, blue: 0.3, alpha: 0.9), border: UIColor.white, corner: 12)
                } else if b.answer == ui.answered {
                    b.node.texture = Gfx.pill(b.size.width, b.size.height, fill: UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 0.85), border: UIColor.white, corner: 12)
                }
            }
            if ui.answered == 0 {
                let bonus = Int((3 * max(0, timePerQ - ui.answerTime) / timePerQ).rounded())
                let pts = 3 + bonus
                addScore(s, pts)
                s.floatText("RICHTIG +\(pts)", at: CGPoint(x: 0, y: 0), color: UIColor.green, size: s.w > 300 ? 24 : 16)
                addStat("quiz", 1, seat: s)
                if !s.isCPU { anyHumanRight = true }
            } else if ui.answered == nil {
                s.floatText("ZU LANGSAM", at: CGPoint(x: 0, y: 0), color: UIColor.orange, size: s.w > 300 ? 22 : 15)
            } else {
                s.floatText("FALSCH", at: CGPoint(x: 0, y: 0), color: UIColor.red, size: s.w > 300 ? 22 : 15)
            }
        }
        Sfx.shared.play(anyHumanRight ? "right" : "wrong")
        run(SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.run { [weak self] in self?.nextQuestion() }]))
    }

    override func began(_ seat: Seat, at: CGPoint, touch: UITouch) {
        guard let ui = uis.first(where: { $0.seat === seat }), ui.answered == nil, !revealing, qIndex >= 0 else { return }
        for b in ui.buttons {
            if abs(at.x - b.center.x) <= b.size.width / 2 && abs(at.y - b.center.y) <= b.size.height / 2 {
                answer(ui, b.answer)
                return
            }
        }
    }
}
