import SwiftUI

// MARK: - Levels & XP

enum Level {
    /// XP needed to go from `level` to `level + 1`
    static func need(_ level: Int) -> Int { return 80 + 30 * level }

    static func info(_ xp: Int) -> (level: Int, into: Int, need: Int) {
        var lvl = 1
        var left = xp
        while left >= need(lvl) { left -= need(lvl); lvl += 1 }
        return (lvl, left, need(lvl))
    }

    static func rankName(_ level: Int) -> String {
        switch level {
        case 1...2: return "Rookie"
        case 3...5: return "Nachwuchs"
        case 6...9: return "Stammspieler"
        case 10...14: return "Topscorer"
        case 15...19: return "Captain"
        case 20...29: return "Eis-Profi"
        default: return "Grizzly-Legende"
        }
    }
}

// MARK: - Shop catalog (titles, cheers, boosts)

enum ShopKind { case title, cheer, boost }

struct ShopItem: Identifiable {
    let id: String
    let kind: ShopKind
    let name: String
    let detail: String
    let price: Int
    let symbol: String
}

enum ShopCatalog {
    static let titles: [ShopItem] = [
        ShopItem(id: "rookie", kind: .title, name: "Rookie", detail: "Jeder fängt mal an", price: 0, symbol: "leaf.fill"),
        ShopItem(id: "nachwuchs", kind: .title, name: "Nachwuchs-Bär", detail: "Auf dem Weg nach oben", price: 40, symbol: "arrow.up.right"),
        ShopItem(id: "stuermer", kind: .title, name: "Sturmbär", detail: "Immer vorne dabei", price: 70, symbol: "bolt.fill"),
        ShopItem(id: "eishexer", kind: .title, name: "Eishexer", detail: "Das Eis gehorcht dir", price: 90, symbol: "snowflake"),
        ShopItem(id: "puckzauberer", kind: .title, name: "Puck-Zauberer", detail: "Der Puck klebt an der Kelle", price: 120, symbol: "sparkles"),
        ShopItem(id: "captain", kind: .title, name: "Captain", detail: "Führt das Team an", price: 180, symbol: "star.circle.fill"),
        ShopItem(id: "legende", kind: .title, name: "Grizzly-Legende", detail: "Alle kennen deinen Namen", price: 300, symbol: "crown.fill")
    ]

    static let cheers: [ShopItem] = [
        ShopItem(id: "classic", kind: .cheer, name: "Klassik", detail: "Orange und Weiss", price: 0, symbol: "party.popper.fill"),
        ShopItem(id: "neon", kind: .cheer, name: "Neon-Regen", detail: "Grelle Leuchtfarben", price: 50, symbol: "sparkle"),
        ShopItem(id: "gold", kind: .cheer, name: "Goldregen", detail: "Nur das Beste", price: 90, symbol: "star.fill"),
        ShopItem(id: "ice", kind: .cheer, name: "Eiskristalle", detail: "Kühl und klar", price: 90, symbol: "snowflake"),
        ShopItem(id: "fire", kind: .cheer, name: "Feuerwerk", detail: "Heiss, heisser, Sieger", price: 130, symbol: "flame.fill"),
        ShopItem(id: "rainbow", kind: .cheer, name: "Regenbogen", detail: "Alle Farben", price: 200, symbol: "rainbow")
    ]

    static let boosts: [ShopItem] = [
        ShopItem(id: "coin2", kind: .boost, name: "Münz-Booster", detail: "Doppelte Münzen für 10 Spiele", price: 80, symbol: "bitcoinsign.circle.fill"),
        ShopItem(id: "xp2", kind: .boost, name: "XP-Booster", detail: "Doppelte XP für 10 Spiele", price: 60, symbol: "chart.line.uptrend.xyaxis")
    ]

    static func title(_ id: String) -> ShopItem { return titles.first { $0.id == id } ?? titles[0] }

    static func palette(_ id: String) -> [Color] {
        switch id {
        case "neon": return [Color(red: 0.2, green: 1, blue: 0.5), Color(red: 1, green: 0.2, blue: 0.8), Color(red: 0.2, green: 0.9, blue: 1), .yellow]
        case "gold": return [Color(red: 1, green: 0.85, blue: 0.3), Color(red: 1, green: 0.7, blue: 0.1), .white, Color(red: 0.95, green: 0.6, blue: 0.0)]
        case "ice": return [Color(red: 0.7, green: 0.95, blue: 1), .white, Color(red: 0.4, green: 0.8, blue: 1), Color(red: 0.85, green: 0.9, blue: 1)]
        case "fire": return [Color(red: 1, green: 0.3, blue: 0.1), Color(red: 1, green: 0.6, blue: 0.0), .yellow, Color(red: 0.9, green: 0.1, blue: 0.1)]
        case "rainbow": return [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        default: return [Theme.orange, .white, .yellow, Color(red: 1, green: 0.4, blue: 0.2), Theme.blue]
        }
    }
}

/// Global so that Confetti (shown from several places) can pick up the equipped cheer.
enum Cheer {
    static var id = "classic"
}

// MARK: - Level pill / streak

struct LevelPill: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        let i = Level.info(app.save.xp)
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Theme.orange, Color(red: 1, green: 0.35, blue: 0.1)], startPoint: .top, endPoint: .bottom))
                Text("\(i.level)").font(Theme.font(15)).foregroundColor(.black)
            }
            .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(Level.rankName(i.level).uppercased()).font(Theme.font(10)).foregroundColor(.white).tracking(0.6)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15)).frame(width: 74, height: 5)
                    Capsule().fill(Theme.orange).frame(width: 74 * CGFloat(i.into) / CGFloat(max(1, i.need)), height: 5)
                }
            }
        }
        .padding(.leading, 5)
        .padding(.trailing, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.45)))
        .overlay(Capsule().stroke(Theme.orange.opacity(0.5), lineWidth: 1.5))
    }
}

struct StreakPill: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill").font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.orange)
            Text("\(app.save.streak)").font(Theme.font(14)).foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.45)))
        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Lucky wheel (daily bonus)

struct WheelPrize {
    enum Kind { case coins, xp, boost }
    let label: String
    let sub: String
    let kind: Kind
    let amount: Int
    let color: Color
    let weight: Int
}

enum Wheel {
    static let prizes: [WheelPrize] = [
        WheelPrize(label: "10", sub: "Münzen", kind: .coins, amount: 10, color: Color(red: 0.25, green: 0.75, blue: 1), weight: 22),
        WheelPrize(label: "40", sub: "XP", kind: .xp, amount: 40, color: Color(red: 0.7, green: 0.4, blue: 1), weight: 14),
        WheelPrize(label: "25", sub: "Münzen", kind: .coins, amount: 25, color: Color(red: 0.2, green: 0.9, blue: 0.5), weight: 18),
        WheelPrize(label: "x2", sub: "Booster", kind: .boost, amount: 5, color: Color(red: 1, green: 0.5, blue: 0.2), weight: 8),
        WheelPrize(label: "15", sub: "Münzen", kind: .coins, amount: 15, color: Color(red: 1, green: 0.35, blue: 0.6), weight: 20),
        WheelPrize(label: "80", sub: "XP", kind: .xp, amount: 80, color: Color(red: 0.5, green: 0.55, blue: 1), weight: 8),
        WheelPrize(label: "50", sub: "Münzen", kind: .coins, amount: 50, color: Color(red: 1, green: 0.8, blue: 0.1), weight: 8),
        WheelPrize(label: "100", sub: "Münzen", kind: .coins, amount: 100, color: Color(red: 1, green: 0.25, blue: 0.25), weight: 2)
    ]

    static func roll() -> Int {
        let total = prizes.reduce(0) { $0 + $1.weight }
        var r = Int.random(in: 0..<total)
        for (i, p) in prizes.enumerated() {
            if r < p.weight { return i }
            r -= p.weight
        }
        return 0
    }
}

struct WheelWedge: Shape {
    var from: Double
    var to: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = rect.width / 2
        p.move(to: c)
        var a = from
        while a <= to + 0.01 {
            let rad = a * .pi / 180
            p.addLine(to: CGPoint(x: c.x + CGFloat(cos(rad)) * r, y: c.y + CGFloat(sin(rad)) * r))
            a += 2
        }
        p.closeSubpath()
        return p
    }
}

struct WheelView: View {
    @EnvironmentObject var app: AppState
    @Binding var show: Bool
    @State private var rotation: Double = 0
    @State private var spinning = false
    @State private var won: Int? = nil

    var body: some View {
        let canSpin = app.canSpinWheel
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            ScrollFit {
            VStack(spacing: 16) {
                HStack {
                    Text("GLÜCKSRAD").font(Theme.font(28)).foregroundColor(Theme.orange)
                    Spacer()
                    Button(action: { if !spinning { withAnimation { show = false } } }) {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .heavy)).foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PressStyle())
                }
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundColor(Theme.orange)
                    Text("Tages-Streak: \(app.save.streak)").font(Theme.fontMed(15)).foregroundColor(.white)
                    Text("· Bonus +\(app.streakBonus) Münzen").font(Theme.fontMed(13)).foregroundColor(.white.opacity(0.6))
                }
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    wheel.rotationEffect(.degrees(rotation))
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                        .shadow(color: Theme.orange, radius: 8)
                        .offset(y: -14)
                }
                .frame(width: 300, height: 300)
                if let w = won {
                    let p = Wheel.prizes[w]
                    VStack(spacing: 4) {
                        Text("DU GEWINNST").font(Theme.font(12)).foregroundColor(.white.opacity(0.6)).tracking(2)
                        Text("\(p.label) \(p.sub)").font(Theme.font(28)).foregroundColor(p.color)
                    }
                    .transition(.scale)
                }
                Spacer(minLength: 0)
                if won != nil {
                    ArcadeButton(title: "SUPER!", icon: "checkmark", height: 58) { withAnimation { show = false } }
                } else {
                    ArcadeButton(title: canSpin ? "DREHEN" : "MORGEN WIEDER", icon: canSpin ? "arrow.triangle.2.circlepath" : "clock", color: canSpin ? Theme.orange : Color.gray, height: 58) {
                        if canSpin && !spinning { spin() }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, safeAreaTop() + 8)
            .padding(.bottom, safeAreaBottom() + 10)
            }
        }
    }

    var wheel: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let center = -90.0 + Double(i) * 45
                WheelWedge(from: center - 22.5, to: center + 22.5)
                    .fill(Wheel.prizes[i].color.opacity(0.9))
                WheelWedge(from: center - 22.5, to: center + 22.5)
                    .stroke(Color.black.opacity(0.5), lineWidth: 2)
                VStack(spacing: 0) {
                    Text(Wheel.prizes[i].label).font(Theme.font(24)).foregroundColor(.black)
                    Text(Wheel.prizes[i].sub.uppercased()).font(Theme.font(8)).foregroundColor(.black.opacity(0.7))
                }
                .rotationEffect(.degrees(center + 90))
                .offset(x: CGFloat(cos(center * .pi / 180)) * 100, y: CGFloat(sin(center * .pi / 180)) * 100)
            }
            Circle().fill(Color.black).frame(width: 52, height: 52)
            Circle().stroke(Theme.orange, lineWidth: 4).frame(width: 52, height: 52)
            Image("logo").resizable().scaledToFit().frame(width: 34)
        }
        .frame(width: 280, height: 280)
        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 5))
        .shadow(color: Theme.orange.opacity(0.6), radius: 24)
    }

    func spin() {
        spinning = true
        let idx = Wheel.roll()
        let land = Double((360 - idx * 45) % 360) + Double.random(in: -14...14)
        Sfx.shared.play("tick")
        Haptic.tap()
        withAnimation(.timingCurve(0.12, 0.7, 0.1, 1, duration: 4.2)) {
            rotation += 360 * 6 + land - rotation.truncatingRemainder(dividingBy: 360)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            spinning = false
            app.claimWheel(prizeIndex: idx)
            Sfx.shared.play("win")
            Haptic.good()
            withAnimation(.spring()) { won = idx }
        }
    }
}
