import SwiftUI
import UIKit

// MARK: - Theme (neon dark)

enum Theme {
    static let orange = Color(red: 1.0, green: 0.54, blue: 0.0)
    static let dark = Color(red: 0.05, green: 0.05, blue: 0.09)
    static let panel = Color(red: 0.11, green: 0.11, blue: 0.17)
    static let cream = Color(red: 1.0, green: 0.95, blue: 0.85)
    static let blue = Color(red: 0.25, green: 0.8, blue: 1.0)
    static let green = Color(red: 0.25, green: 1.0, blue: 0.45)
    static let pink = Color(red: 1.0, green: 0.3, blue: 0.7)
    static let uiOrange = UIColor(red: 1.0, green: 0.54, blue: 0.0, alpha: 1)
    static let uiDark = UIColor(red: 0.05, green: 0.05, blue: 0.09, alpha: 1)
    static let uiBlue = UIColor(red: 0.25, green: 0.8, blue: 1.0, alpha: 1)
    static let uiGreen = UIColor(red: 0.25, green: 1.0, blue: 0.45, alpha: 1)
    static let uiPink = UIColor(red: 1.0, green: 0.3, blue: 0.7, alpha: 1)
    static let uiCream = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)

    /// One colour per seat (index 0...3)
    static let seatUI: [UIColor] = [uiOrange, uiBlue, uiGreen, uiPink]
    static let seat: [Color] = [orange, blue, green, pink]

    static func font(_ size: CGFloat) -> Font { Font.custom("AvenirNext-Heavy", size: size) }
    static func fontMed(_ size: CGFloat) -> Font { Font.custom("AvenirNext-DemiBold", size: size) }
}

// MARK: - Skins

enum Accessory: String {
    case none, crown, headband, helmet
}

struct Skin: Identifiable {
    let id: String
    let name: String
    let color: UIColor
    let price: Int
    let accessory: Accessory
    let number: Int

    var swiftColor: Color { Color(uiColor: color) }
    var isDark: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r * 0.3 + g * 0.6 + b * 0.1) < 0.45
    }

    static let classic = Skin(id: "classic", name: "Klassik", color: UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1), price: 0, accessory: .none, number: 17)
    static let all: [Skin] = [
        classic,
        Skin(id: "orange", name: "Grizzly Orange", color: UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1), price: 0, accessory: .headband, number: 10),
        Skin(id: "ice", name: "Eisbär", color: UIColor(red: 0.82, green: 0.94, blue: 1.0, alpha: 1), price: 0, accessory: .headband, number: 7),
        Skin(id: "pink", name: "Pink Power", color: UIColor(red: 1.0, green: 0.31, blue: 0.64, alpha: 1), price: 0, accessory: .headband, number: 21),
        Skin(id: "blue", name: "Zürich Blau", color: UIColor(red: 0.12, green: 0.43, blue: 0.9, alpha: 1), price: 60, accessory: .helmet, number: 8),
        Skin(id: "fire", name: "Feuerbär", color: UIColor(red: 0.9, green: 0.2, blue: 0.17, alpha: 1), price: 80, accessory: .helmet, number: 13),
        Skin(id: "neon", name: "Neon Bär", color: UIColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 1), price: 100, accessory: .none, number: 99),
        Skin(id: "galaxy", name: "Galaxy", color: UIColor(red: 0.48, green: 0.24, blue: 1.0, alpha: 1), price: 120, accessory: .helmet, number: 42),
        Skin(id: "mint", name: "Mint Frost", color: UIColor(red: 0.45, green: 0.95, blue: 0.8, alpha: 1), price: 70, accessory: .helmet, number: 11),
        Skin(id: "candy", name: "Zuckerwatte", color: UIColor(red: 1.0, green: 0.62, blue: 0.85, alpha: 1), price: 90, accessory: .headband, number: 33),
        Skin(id: "sunset", name: "Sonnenuntergang", color: UIColor(red: 1.0, green: 0.42, blue: 0.3, alpha: 1), price: 90, accessory: .headband, number: 5),
        Skin(id: "camo", name: "Tarnbär", color: UIColor(red: 0.3, green: 0.4, blue: 0.2, alpha: 1), price: 100, accessory: .helmet, number: 4),
        Skin(id: "royal", name: "Royal Violett", color: UIColor(red: 0.55, green: 0.2, blue: 0.85, alpha: 1), price: 110, accessory: .crown, number: 3),
        Skin(id: "lava", name: "Lava", color: UIColor(red: 1.0, green: 0.25, blue: 0.0, alpha: 1), price: 130, accessory: .helmet, number: 66),
        Skin(id: "cyber", name: "Cyber Cyan", color: UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1), price: 160, accessory: .helmet, number: 77),
        Skin(id: "diamond", name: "Diamant", color: UIColor(red: 0.75, green: 0.95, blue: 1.0, alpha: 1), price: 300, accessory: .crown, number: 100),
        Skin(id: "gold", name: "Goldbär", color: UIColor(red: 1.0, green: 0.77, blue: 0.0, alpha: 1), price: 150, accessory: .crown, number: 1)
    ]

    static func find(_ id: String) -> Skin {
        for s in all where s.id == id { return s }
        return classic
    }
}

// MARK: - Games

enum GameTag: String {
    case hockey = "Unihockey"
    case party = "Party"
}

enum GameKind: String, CaseIterable, Identifiable {
    // Unihockey
    case penalty, goalie, airhockey, puckgolf, ballrain, powershot, hotpuck, sumo, ninja, juggle, quiz, duel, dash
    // Party classics
    case flappy, hopper, stack, simon, reaction, numbers, colors, balance, territory, tapsprint, whack, memory
    // New
    case curling, slalom, pong, bowling, tugwar
    case darts, hoops, hurdles, mathduel, rhythm, billiard
    case arrows, oddone, compare, sorter, dodge, cave, pendulum, count, stoptime, slide, snowball, zigzag, lightsout, reflex

    var id: String { rawValue }

    var tag: GameTag {
        switch self {
        case .penalty, .goalie, .airhockey, .puckgolf, .ballrain, .powershot, .hotpuck, .sumo, .ninja, .juggle, .quiz, .duel, .dash, .curling, .slalom, .pong, .hoops, .billiard, .dodge, .pendulum, .slide:
            return .hockey
        default:
            return .party
        }
    }

    var title: String {
        switch self {
        case .penalty: return "Penalty-Duell"
        case .goalie: return "Torwart-Panik"
        case .airhockey: return "Air-Hockey"
        case .puckgolf: return "Puck-Golf"
        case .ballrain: return "Ballregen"
        case .powershot: return "Power-Schuss"
        case .hotpuck: return "Heisser Puck"
        case .sumo: return "Eis-Sumo"
        case .ninja: return "Puck-Ninja"
        case .juggle: return "Ballhalten"
        case .quiz: return "Unihockey-Quiz"
        case .duel: return "Schläger-Duell"
        case .dash: return "Bären-Sprint"
        case .flappy: return "Flatter-Bär"
        case .hopper: return "Bären-Hüpfer"
        case .stack: return "Bären-Turm"
        case .simon: return "Grizzly Says"
        case .reaction: return "Reaktions-Duell"
        case .numbers: return "Zahlen-Jagd"
        case .colors: return "Farben-Falle"
        case .balance: return "Eis-Balance"
        case .territory: return "Revierkampf"
        case .tapsprint: return "Tap-Sprint"
        case .whack: return "Puck-Jagd"
        case .memory: return "Bären-Memory"
        case .curling: return "Eis-Curling"
        case .slalom: return "Slalom-Dribbling"
        case .pong: return "Puck-Pong"
        case .bowling: return "Bären-Bowling"
        case .tugwar: return "Tauziehen"
        case .darts: return "Bären-Darts"
        case .hoops: return "Korbjagd"
        case .hurdles: return "Hürdenlauf"
        case .mathduel: return "Kopfrechnen"
        case .rhythm: return "Takt-Tipper"
        case .billiard: return "Puck-Billard"
        case .arrows: return "Pfeil-Panik"
        case .oddone: return "Ausreisser"
        case .compare: return "Grösser oder kleiner"
        case .sorter: return "Farb-Sortierer"
        case .dodge: return "Puck-Ausweichen"
        case .cave: return "Höhlenflug"
        case .pendulum: return "Pendel-Wurf"
        case .count: return "Puck-Zähler"
        case .stoptime: return "Zeit-Stopp"
        case .slide: return "Eis-Rutsch"
        case .snowball: return "Schneeballschlacht"
        case .zigzag: return "Zickzack-Bär"
        case .lightsout: return "Lichter aus"
        case .reflex: return "Finger-Blitz"
        }
    }

    var icon: String {
        switch self {
        case .penalty: return "🥅"
        case .goalie: return "🧤"
        case .airhockey: return "🏒"
        case .puckgolf: return "⛳️"
        case .ballrain: return "☔️"
        case .powershot: return "💥"
        case .hotpuck: return "🔥"
        case .sumo: return "🧊"
        case .ninja: return "⚔️"
        case .juggle: return "⚽️"
        case .quiz: return "🧠"
        case .duel: return "✊"
        case .dash: return "🏃"
        case .flappy: return "🐻"
        case .hopper: return "🚀"
        case .stack: return "🧱"
        case .simon: return "🎶"
        case .reaction: return "⚡️"
        case .numbers: return "🔢"
        case .colors: return "🎨"
        case .balance: return "⚖️"
        case .territory: return "🟧"
        case .tapsprint: return "👟"
        case .whack: return "🔨"
        case .memory: return "🃏"
        case .curling: return "🥌"
        case .slalom: return "🚧"
        case .pong: return "🏓"
        case .bowling: return "🎳"
        case .tugwar: return "🪢"
        case .darts: return "🎯"
        case .hoops: return "🏀"
        case .hurdles: return "🏃"
        case .mathduel: return "➕"
        case .rhythm: return "🥁"
        case .billiard: return "🎱"
        case .arrows: return "⬆️"
        case .oddone: return "🔍"
        case .compare: return "⚖️"
        case .sorter: return "🎨"
        case .dodge: return "💨"
        case .cave: return "🦇"
        case .pendulum: return "🎯"
        case .count: return "🔢"
        case .stoptime: return "⏱️"
        case .slide: return "🧊"
        case .snowball: return "❄️"
        case .zigzag: return "⚡"
        case .lightsout: return "💡"
        case .reflex: return "🖐️"
        }
    }

    /// Short rules shown on the intro card (keep to about two sentences)
    var rules: String {
        switch self {
        case .penalty: return "Wische den Ball ins Tor. Der Torwart wird immer schneller. Wer in 40 Sekunden die meisten Tore schiesst, gewinnt."
        case .goalie: return "Schüsse fliegen aufs Tor. Ziehe deinen Torwart und halte so viele wie möglich. Drei Fehler und du bist raus."
        case .airhockey: return "Schiebe deinen Schläger und schiesse den Puck ins gegnerische Tor. Jedes Gegentor kostet ein Leben, du hast drei."
        case .puckgolf: return "Wische den Puck ins Loch, mit so wenigen Schlägen wie möglich. Wer in 60 Sekunden die meisten Löcher schafft, gewinnt."
        case .ballrain: return "Fange mit deinem Bären die Bälle: weiss gibt 1, golden 3. Gelbe Karten kosten 3 Punkte. 30 Sekunden."
        case .powershot: return "Tippe genau dann, wenn der Balken im grünen Bereich ist. Je genauer der Schuss, desto mehr Punkte. 8 Schüsse."
        case .hotpuck: return "Der heisse Puck brennt! Tippe ihn mehrmals schnell an, um ihn weiterzugeben. Wer ihn beim Knall hält, verliert ein Leben."
        case .sumo: return "Schiebe deinen Bären mit dem Finger und stosse die anderen vom schrumpfenden Eis. Der letzte Bär gewinnt."
        case .ninja: return "Wische durch die fliegenden Pucks und Bälle. Rote Karten darfst du nicht berühren. 30 Sekunden."
        case .juggle: return "Tippe den Ball, damit er in der Luft bleibt. Je länger die Serie, desto schneller wird er. Wer ihn fallen lässt, ist raus."
        case .quiz: return "Sechs Fragen zu Unihockey. Wer richtig und schnell antwortet, bekommt mehr Punkte. Falsch gibt keine."
        case .duel: return "Wähle Schläger, Ball oder Handschuh. Schläger schlägt Ball, Ball schlägt Handschuh, Handschuh schlägt Schläger."
        case .dash: return "Dein Bär rennt automatisch. Tippe links oder rechts um die Spur zu wechseln, weiche Hindernissen aus und sammle Bälle."
        case .flappy: return "Tippe, um den Bären flattern zu lassen. Fliege durch die Lücken und berühre keine Bande. Wer abstürzt, ist raus."
        case .hopper: return "Dein Bär hüpft von selbst. Ziehe nach links und rechts, lande auf den Plattformen und steige so hoch du kannst."
        case .stack: return "Der Block schwebt hin und her. Tippe zum Fallenlassen und stapele den Turm so hoch wie möglich. Daneben gibt weniger Platz."
        case .simon: return "Merke dir die Reihenfolge der leuchtenden Felder und tippe sie nach. Ein Fehler und du bist raus. Wer am längsten dabei bleibt, gewinnt."
        case .reaction: return "Warte bis das Feld grün wird und tippe dann sofort. Zu früh getippt ist gesperrt. 5 Runden, wer zuerst reagiert, bekommt den Punkt."
        case .numbers: return "Tippe die Zahlen in der richtigen Reihenfolge, so schnell du kannst. Wer zuerst fertig ist, holt die meisten Punkte. 3 Runden."
        case .colors: return "Passt die Farbe des Wortes zum Wort? Tippe Ja oder Nein. Richtig gibt 1 Punkt, falsch nimmt 1. 30 Sekunden."
        case .balance: return "Halte die Kugel auf dem Balken, indem du links oder rechts kippst. Wer am längsten balanciert, gewinnt."
        case .territory: return "Tippe auf Felder, um sie in deiner Farbe zu färben. Du darfst auch fremde Felder übernehmen. Wer am Ende die meisten hat, gewinnt."
        case .tapsprint: return "Tippe abwechselnd links und rechts, um zu rennen. Zweimal dieselbe Seite bremst dich. Wer zuerst im Ziel ist, gewinnt."
        case .whack: return "Pucks tauchen aus den Löchern auf. Tippe sie schnell. Schiedsrichter-Karten nicht berühren. 30 Sekunden."
        case .memory: return "Finde die Bärenpaare. Alle spielen dasselbe Feld gleichzeitig. Wer zuerst alle Paare hat, gewinnt."
        case .curling: return "Ziehe zurück und lass los: Dein Stein gleitet übers Eis. Lande möglichst nahe in der Mitte der Zielscheibe. 5 Steine pro Spieler."
        case .slalom: return "Führe den Puck mit dem Finger durch die Pylonen, ohne eine umzuwerfen. Jedes saubere Tor gibt Punkte, die Zeit läuft. 45 Sekunden."
        case .pong: return "Verteidige dein Tor mit dem Schläger an deiner Kante und lenke den Ball zu den anderen. Wer ein Tor kassiert, verliert ein Leben."
        case .bowling: return "Wische den Ball kräftig auf die Pins. Je mehr umfallen, desto mehr Punkte. Ein Strike gibt Bonus. 5 Würfe."
        case .tugwar: return "Tippe so schnell du kannst! Wer das Seil über die Mittellinie auf seine Seite zieht, gewinnt die Runde. Beste von 3."
        case .darts: return "Zielkreuz wackelt: tippe zum Werfen. Je näher am Zentrum, desto mehr Punkte. 6 Pfeile pro Spieler."
        case .hoops: return "Wische den Ball nach oben in den Korb. Treffer in Serie geben Bonus, der Korb bewegt sich. 30 Sekunden."
        case .hurdles: return "Dein Bär rennt automatisch. Tippe im richtigen Moment, um über die Hürden zu springen. Wer stolpert, verliert Tempo."
        case .mathduel: return "Rechne so schnell du kannst und tippe die richtige Lösung. Wer zuerst richtig antwortet, holt den Punkt. 10 Aufgaben."
        case .rhythm: return "Tippe die fallenden Noten genau im Takt in deiner Spur. Perfekte Treffer geben die meisten Punkte. 40 Sekunden."
        case .billiard: return "Schiesse deinen Puck an und lass die anderen Pucks in die Ecklöcher fallen. Wer die meisten versenkt, gewinnt."
        case .arrows: return "Wische so schnell du kannst in die Richtung des angezeigten Pfeils. Falsche Richtung kostet einen Punkt. 30 Sekunden."
        case .oddone: return "Ein Feld unterscheidet sich von den anderen. Tippe es als Erster an. Je schneller, desto mehr Punkte. 10 Runden."
        case .compare: return "Zwei Zahlen erscheinen. Tippe die grössere an, bevor die Zeit abläuft. Falsch oder zu langsam gibt Abzug. 30 Sekunden."
        case .sorter: return "Bälle fallen von oben. Wische sie nach links oder rechts in den Korb mit der gleichen Farbe. 30 Sekunden."
        case .dodge: return "Pucks regnen von oben. Ziehe deinen Bären nach links und rechts und weiche aus. Wer am längsten überlebt, gewinnt."
        case .cave: return "Halte den Finger gedrückt, um zu steigen, und lass los, um zu sinken. Fliege durch die Höhle, ohne die Wände zu berühren."
        case .pendulum: return "Der Ball schwingt am Seil hin und her. Tippe im richtigen Moment, um ihn ins Ziel zu werfen. 6 Würfe."
        case .count: return "Pucks blitzen kurz auf. Wie viele waren es? Tippe die richtige Zahl. Wer richtig und schnell ist, gewinnt. 8 Runden."
        case .stoptime: return "Die Uhr läuft kurz sichtbar, dann wird sie unsichtbar. Tippe, wenn du glaubst, dass genau die Zielzeit erreicht ist. 5 Runden."
        case .slide: return "Wische deinen Bären übers Eis: Er rutscht, bis er an eine Wand stösst. Erreiche das Tor, ohne in ein Loch zu fallen."
        case .snowball: return "Ziele per Wischen auf die auftauchenden Ziele und wirf Schneebälle. Bären-Freunde darfst du nicht treffen. 30 Sekunden."
        case .zigzag: return "Dein Bär läuft automatisch. Tippe, um die Richtung zu wechseln, sammle Pucks und weiche den Wänden aus."
        case .lightsout: return "Tippe auf ein Feld: Es schaltet sich und seine Nachbarn um. Schalte alle Lichter aus, bevor die anderen es schaffen. Gleiches Rätsel für alle."
        case .reflex: return "Halte den Finger auf dem Feld. Sobald es leuchtet, lass los. Zu früh losgelassen ist gesperrt. 5 Runden."
        }
    }

    var accent: Color {
        switch self {
        case .penalty: return Color(red: 1.0, green: 0.35, blue: 0.3)
        case .goalie: return Color(red: 0.2, green: 0.9, blue: 0.6)
        case .airhockey: return Color(red: 0.3, green: 0.75, blue: 1.0)
        case .puckgolf: return Color(red: 0.4, green: 0.9, blue: 0.3)
        case .ballrain: return Color(red: 0.4, green: 0.65, blue: 1.0)
        case .powershot: return Color(red: 1.0, green: 0.8, blue: 0.1)
        case .hotpuck: return Color(red: 1.0, green: 0.45, blue: 0.1)
        case .sumo: return Color(red: 0.5, green: 0.9, blue: 1.0)
        case .ninja: return Color(red: 0.9, green: 0.3, blue: 0.9)
        case .juggle: return Color(red: 0.95, green: 0.95, blue: 0.4)
        case .quiz: return Color(red: 0.65, green: 0.4, blue: 1.0)
        case .duel: return Color(red: 1.0, green: 0.5, blue: 0.6)
        case .dash: return Color(red: 1.0, green: 0.7, blue: 0.1)
        case .flappy: return Color(red: 0.3, green: 0.85, blue: 0.9)
        case .hopper: return Color(red: 0.6, green: 0.5, blue: 1.0)
        case .stack: return Color(red: 1.0, green: 0.6, blue: 0.3)
        case .simon: return Color(red: 0.3, green: 1.0, blue: 0.7)
        case .reaction: return Color(red: 0.3, green: 1.0, blue: 0.4)
        case .numbers: return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .colors: return Color(red: 1.0, green: 0.4, blue: 0.8)
        case .balance: return Color(red: 0.7, green: 0.9, blue: 1.0)
        case .territory: return Color(red: 1.0, green: 0.54, blue: 0.0)
        case .tapsprint: return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .whack: return Color(red: 0.9, green: 0.8, blue: 0.3)
        case .memory: return Color(red: 0.8, green: 0.5, blue: 1.0)
        case .curling: return Color(red: 0.35, green: 0.8, blue: 1.0)
        case .slalom: return Color(red: 1.0, green: 0.55, blue: 0.2)
        case .pong: return Color(red: 0.55, green: 1.0, blue: 0.55)
        case .bowling: return Color(red: 0.95, green: 0.35, blue: 0.55)
        case .tugwar: return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .darts: return Color(red: 1.0, green: 0.3, blue: 0.35)
        case .hoops: return Color(red: 1.0, green: 0.55, blue: 0.1)
        case .hurdles: return Color(red: 0.3, green: 0.85, blue: 1.0)
        case .mathduel: return Color(red: 0.6, green: 0.7, blue: 1.0)
        case .rhythm: return Color(red: 0.9, green: 0.35, blue: 1.0)
        case .billiard: return Color(red: 0.2, green: 0.9, blue: 0.7)
        case .arrows: return Color(red: 0.35, green: 0.9, blue: 1.0)
        case .oddone: return Color(red: 1.0, green: 0.75, blue: 0.3)
        case .compare: return Color(red: 0.55, green: 0.8, blue: 1.0)
        case .sorter: return Color(red: 1.0, green: 0.45, blue: 0.75)
        case .dodge: return Color(red: 0.9, green: 0.5, blue: 0.3)
        case .cave: return Color(red: 0.5, green: 0.4, blue: 0.9)
        case .pendulum: return Color(red: 0.3, green: 1.0, blue: 0.6)
        case .count: return Color(red: 0.95, green: 0.85, blue: 0.35)
        case .stoptime: return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .slide: return Color(red: 0.6, green: 0.9, blue: 1.0)
        case .snowball: return Color(red: 0.7, green: 0.95, blue: 1.0)
        case .zigzag: return Color(red: 0.3, green: 0.95, blue: 0.5)
        case .lightsout: return Color(red: 1.0, green: 0.9, blue: 0.3)
        case .reflex: return Color(red: 0.4, green: 1.0, blue: 0.7)
        }
    }

    /// What the number in the result means
    var unit: String {
        switch self {
        case .penalty, .puckgolf: return "Tore"
        case .goalie: return "Paraden"
        case .airhockey: return "Punkte"
        case .snowball, .arrows, .oddone, .compare, .sorter, .dodge, .cave, .pendulum, .count, .stoptime, .slide, .zigzag, .lightsout, .reflex, .curling, .slalom, .pong, .bowling, .tugwar, .darts, .hoops, .hurdles, .mathduel, .rhythm, .billiard, .quiz, .duel, .reaction, .numbers, .powershot, .whack, .ninja, .colors, .ballrain, .territory: return "Punkte"
        case .juggle: return "Serie"
        case .hopper, .stack: return "Höhe"
        case .flappy: return "Tore"
        case .dash, .tapsprint, .sumo, .balance, .hotpuck, .simon, .memory: return "Punkte"
        }
    }

    /// Approximate play time in seconds (shown in the picker)
    var seconds: Int {
        switch self {
        case .penalty: return 40
        case .goalie: return 60
        case .airhockey: return 75
        case .puckgolf: return 60
        case .ballrain: return 30
        case .powershot: return 40
        case .hotpuck: return 60
        case .sumo: return 45
        case .ninja: return 30
        case .juggle: return 45
        case .quiz: return 60
        case .duel: return 45
        case .dash: return 45
        case .flappy: return 45
        case .hopper: return 45
        case .stack: return 40
        case .simon: return 50
        case .reaction: return 40
        case .numbers: return 45
        case .colors: return 30
        case .balance: return 40
        case .territory: return 25
        case .tapsprint: return 20
        case .whack: return 30
        case .memory: return 50
        case .curling: return 60
        case .slalom: return 45
        case .pong: return 75
        case .bowling: return 50
        case .tugwar: return 25
        case .darts: return 50
        case .hoops: return 30
        case .hurdles: return 40
        case .mathduel: return 45
        case .rhythm: return 40
        case .billiard: return 60
        case .arrows: return 30
        case .oddone: return 45
        case .compare: return 30
        case .sorter: return 30
        case .dodge: return 45
        case .cave: return 45
        case .pendulum: return 45
        case .count: return 45
        case .stoptime: return 50
        case .slide: return 50
        case .snowball: return 30
        case .zigzag: return 45
        case .lightsout: return 50
        case .reflex: return 40
        }
    }

    var minPlayers: Int { return 2 }
    var maxPlayers: Int { return self == .tugwar ? 2 : 4 }

    func supports(_ n: Int) -> Bool { return n >= minPlayers && n <= maxPlayers }
}

/// Result a game hands back. scores are per seat (higher = better).
struct GameResult {
    var scores: [Int] = []
    var stats: [String: Int] = [:]
}

enum Ranking {
    /// Competition ranking, 0 = best, ties share a rank.
    static func ranks(_ scores: [Int]) -> [Int] {
        return scores.map { s in scores.filter { $0 > s }.count }
    }

    /// Tournament points per seat for one game.
    static func points(_ scores: [Int]) -> [Int] {
        let n = scores.count
        let table: [Int]
        switch n {
        case 2: table = [3, 0]
        case 3: table = [4, 2, 0]
        default: table = [5, 3, 1, 0]
        }
        let r = ranks(scores)
        return r.enumerated().map { (i, rank) in
            let tied = r.filter { $0 == rank }.count
            var sum = 0
            for k in 0..<tied { sum += table[min(rank + k, table.count - 1)] }
            _ = i
            return sum / tied
        }
    }
}

// MARK: - Save data

struct DailyState: Codable {
    var date = ""
    var games = 0
    var wins = 0
    var goals = 0
    var balls = 0
    var quiz = 0
    var kinds: [String] = []
    var claimed: [String] = []
}

enum SlotMode: String, Codable {
    case human, cpu, off
}

struct SaveData: Codable {
    var coins = 0
    var totalCoins = 0
    var unlocked: [String] = ["classic", "orange", "ice", "pink"]
    var skinIds: [String] = ["orange", "classic", "ice", "pink"]
    var names: [String] = ["Spieler 1", "Spieler 2", "Spieler 3", "Spieler 4"]
    var slots: [SlotMode] = [.human, .cpu, .off, .off]
    var difficulty = 2
    var rounds = 5
    var sound = true
    var music = true
    var haptics = true
    var best: [String: Int] = [:]
    var gamesPlayed = 0
    var wins = 0
    var tournamentsPlayed = 0
    var tournamentsWon = 0
    var goals = 0
    var quizCorrect = 0
    var balls = 0
    var targetsHit = 0
    var bestReaction = 0
    var achievements: [String] = []
    var seenIntro: [String] = []
    var playedKinds: [String] = []
    var daily = DailyState()
    var xp = 0
    var streak = 0
    var lastLogin = ""
    var lastWheel = ""
    var items: [String] = []
    var titleId = "rookie"
    var cheerId = "classic"
    var coinBoost = 0
    var xpBoost = 0

    init() {}

    /// Tolerant decoding: missing keys keep their default (safe for app updates)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SaveData()
        coins = (try? c.decodeIfPresent(type(of: d.coins), forKey: .coins)) ?? d.coins
        totalCoins = (try? c.decodeIfPresent(type(of: d.totalCoins), forKey: .totalCoins)) ?? d.totalCoins
        unlocked = (try? c.decodeIfPresent(type(of: d.unlocked), forKey: .unlocked)) ?? d.unlocked
        skinIds = (try? c.decodeIfPresent(type(of: d.skinIds), forKey: .skinIds)) ?? d.skinIds
        names = (try? c.decodeIfPresent(type(of: d.names), forKey: .names)) ?? d.names
        slots = (try? c.decodeIfPresent(type(of: d.slots), forKey: .slots)) ?? d.slots
        difficulty = (try? c.decodeIfPresent(type(of: d.difficulty), forKey: .difficulty)) ?? d.difficulty
        rounds = (try? c.decodeIfPresent(type(of: d.rounds), forKey: .rounds)) ?? d.rounds
        sound = (try? c.decodeIfPresent(type(of: d.sound), forKey: .sound)) ?? d.sound
        music = (try? c.decodeIfPresent(type(of: d.music), forKey: .music)) ?? d.music
        haptics = (try? c.decodeIfPresent(type(of: d.haptics), forKey: .haptics)) ?? d.haptics
        best = (try? c.decodeIfPresent(type(of: d.best), forKey: .best)) ?? d.best
        gamesPlayed = (try? c.decodeIfPresent(type(of: d.gamesPlayed), forKey: .gamesPlayed)) ?? d.gamesPlayed
        wins = (try? c.decodeIfPresent(type(of: d.wins), forKey: .wins)) ?? d.wins
        tournamentsPlayed = (try? c.decodeIfPresent(type(of: d.tournamentsPlayed), forKey: .tournamentsPlayed)) ?? d.tournamentsPlayed
        tournamentsWon = (try? c.decodeIfPresent(type(of: d.tournamentsWon), forKey: .tournamentsWon)) ?? d.tournamentsWon
        goals = (try? c.decodeIfPresent(type(of: d.goals), forKey: .goals)) ?? d.goals
        quizCorrect = (try? c.decodeIfPresent(type(of: d.quizCorrect), forKey: .quizCorrect)) ?? d.quizCorrect
        balls = (try? c.decodeIfPresent(type(of: d.balls), forKey: .balls)) ?? d.balls
        targetsHit = (try? c.decodeIfPresent(type(of: d.targetsHit), forKey: .targetsHit)) ?? d.targetsHit
        bestReaction = (try? c.decodeIfPresent(type(of: d.bestReaction), forKey: .bestReaction)) ?? d.bestReaction
        achievements = (try? c.decodeIfPresent(type(of: d.achievements), forKey: .achievements)) ?? d.achievements
        seenIntro = (try? c.decodeIfPresent(type(of: d.seenIntro), forKey: .seenIntro)) ?? d.seenIntro
        playedKinds = (try? c.decodeIfPresent(type(of: d.playedKinds), forKey: .playedKinds)) ?? d.playedKinds
        daily = (try? c.decodeIfPresent(type(of: d.daily), forKey: .daily)) ?? d.daily
        xp = (try? c.decodeIfPresent(type(of: d.xp), forKey: .xp)) ?? d.xp
        streak = (try? c.decodeIfPresent(type(of: d.streak), forKey: .streak)) ?? d.streak
        lastLogin = (try? c.decodeIfPresent(type(of: d.lastLogin), forKey: .lastLogin)) ?? d.lastLogin
        lastWheel = (try? c.decodeIfPresent(type(of: d.lastWheel), forKey: .lastWheel)) ?? d.lastWheel
        items = (try? c.decodeIfPresent(type(of: d.items), forKey: .items)) ?? d.items
        titleId = (try? c.decodeIfPresent(type(of: d.titleId), forKey: .titleId)) ?? d.titleId
        cheerId = (try? c.decodeIfPresent(type(of: d.cheerId), forKey: .cheerId)) ?? d.cheerId
        coinBoost = (try? c.decodeIfPresent(type(of: d.coinBoost), forKey: .coinBoost)) ?? d.coinBoost
        xpBoost = (try? c.decodeIfPresent(type(of: d.xpBoost), forKey: .xpBoost)) ?? d.xpBoost
        while names.count < 4 { names.append("Spieler \(names.count + 1)") }
        while skinIds.count < 4 { skinIds.append("classic") }
        while slots.count < 4 { slots.append(.off) }
        if slots.filter({ $0 != .off }).count < 2 { slots = d.slots }
    }
}

struct DailyTask: Identifiable {
    let id: String
    let title: String
    let goal: Int
    let reward: Int
    let progress: (DailyState) -> Int
}

enum Daily {
    static let pool: [DailyTask] = [
        DailyTask(id: "games3", title: "Spiele 3 Spiele", goal: 3, reward: 15, progress: { $0.games }),
        DailyTask(id: "games6", title: "Spiele 6 Spiele", goal: 6, reward: 30, progress: { $0.games }),
        DailyTask(id: "wins2", title: "Gewinne 2 Spiele", goal: 2, reward: 20, progress: { $0.wins }),
        DailyTask(id: "goals5", title: "Schiesse 5 Tore", goal: 5, reward: 20, progress: { $0.goals }),
        DailyTask(id: "balls15", title: "Fange 15 Bälle", goal: 15, reward: 20, progress: { $0.balls }),
        DailyTask(id: "quiz5", title: "5 Quizfragen richtig", goal: 5, reward: 20, progress: { $0.quiz }),
        DailyTask(id: "kinds3", title: "3 verschiedene Spiele", goal: 3, reward: 25, progress: { $0.kinds.count })
    ]

    static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    static func todaysTasks() -> [DailyTask] {
        let cal = Calendar.current
        let day = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        var out: [DailyTask] = []
        var i = day % pool.count
        while out.count < 3 {
            let t = pool[i % pool.count]
            if !out.contains(where: { $0.id == t.id }) { out.append(t) }
            i += 2
        }
        return out
    }
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let reward: Int
    let check: (SaveData) -> Bool

    static let all: [Achievement] = [
        Achievement(id: "firstwin", title: "Erster Sieg", detail: "Gewinne ein Spiel", icon: "🥇", reward: 10, check: { $0.wins >= 1 }),
        Achievement(id: "goals10", title: "Torjäger", detail: "Schiesse 10 Tore", icon: "🥅", reward: 20, check: { $0.goals >= 10 }),
        Achievement(id: "goals50", title: "Torfabrik", detail: "Schiesse 50 Tore", icon: "🔥", reward: 50, check: { $0.goals >= 50 }),
        Achievement(id: "tour1", title: "Turniersieger", detail: "Gewinne ein Turnier", icon: "🏆", reward: 50, check: { $0.tournamentsWon >= 1 }),
        Achievement(id: "tour3", title: "Pokalsammler", detail: "Gewinne 3 Turniere", icon: "👑", reward: 100, check: { $0.tournamentsWon >= 3 }),
        Achievement(id: "quiz20", title: "Quiz Profi", detail: "20 Quizfragen richtig", icon: "🧠", reward: 30, check: { $0.quizCorrect >= 20 }),
        Achievement(id: "balls50", title: "Fangkünstler", detail: "Fange 50 Bälle", icon: "🧤", reward: 30, check: { $0.balls >= 50 }),
        Achievement(id: "hits50", title: "Scharfschütze", detail: "Triff 50 Ziele", icon: "🎯", reward: 30, check: { $0.targetsHit >= 50 }),
        Achievement(id: "react", title: "Blitzreaktion", detail: "Reagiere schneller als 250 ms", icon: "⚡️", reward: 40, check: { $0.bestReaction > 0 && $0.bestReaction < 250 }),
        Achievement(id: "play25", title: "Dauerbrenner", detail: "Spiele 25 Spiele", icon: "🎮", reward: 40, check: { $0.gamesPlayed >= 25 }),
        Achievement(id: "kinds12", title: "Allrounder", detail: "Spiele 12 verschiedene Spiele", icon: "🌟", reward: 60, check: { $0.playedKinds.count >= 12 }),
        Achievement(id: "kinds25", title: "Arcade-Meister", detail: "Spiele alle 50 Spiele", icon: "🎖️", reward: 150, check: { $0.playedKinds.count >= GameKind.allCases.count }),
        Achievement(id: "skins6", title: "Modefan", detail: "Besitze 6 Skins", icon: "👕", reward: 30, check: { $0.unlocked.count >= 6 }),
        Achievement(id: "rich", title: "Münzbär", detail: "Sammle insgesamt 500 Münzen", icon: "💰", reward: 50, check: { $0.totalCoins >= 500 })
    ]
}
