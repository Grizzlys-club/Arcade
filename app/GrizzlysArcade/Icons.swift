import SwiftUI
import UIKit

// MARK: - Vector icons (SF Symbols + drawn glyphs) – no emojis in the UI

enum Sym {
    static func has(_ n: String) -> Bool { UIImage(systemName: n) != nil }
    static func ok(_ n: String, _ fallback: String = "star.fill") -> String { has(n) ? n : fallback }
}

extension GameKind {
    var symbol: String {
        let n: String
        switch self {
        case .penalty: n = "figure.hockey"
        case .goalie: n = "hand.raised.fill"
        case .airhockey: n = "circle.circle.fill"
        case .puckgolf: n = "flag.fill"
        case .ballrain: n = "cloud.rain.fill"
        case .powershot: n = "bolt.fill"
        case .hotpuck: n = "flame.fill"
        case .sumo: n = "snowflake"
        case .ninja: n = "wind"
        case .juggle: n = "soccerball"
        case .quiz: n = "brain.head.profile"
        case .duel: n = "scissors"
        case .dash: n = "figure.run"
        case .flappy: n = "paperplane.fill"
        case .hopper: n = "arrow.up.circle.fill"
        case .stack: n = "square.stack.3d.up.fill"
        case .simon: n = "music.note"
        case .reaction: n = "timer"
        case .numbers: n = "number"
        case .colors: n = "paintpalette.fill"
        case .balance: n = "scalemass.fill"
        case .territory: n = "square.grid.3x3.fill"
        case .tapsprint: n = "hare.fill"
        case .whack: n = "hammer.fill"
        case .memory: n = "rectangle.on.rectangle.fill"
        case .curling: n = "circle.hexagongrid.fill"
        case .slalom: n = "triangle.fill"
        case .pong: n = "arrow.left.and.right.circle.fill"
        case .bowling: n = "circle.grid.3x3.fill"
        case .tugwar: n = "arrow.left.arrow.right"
        case .darts: n = "target"
        case .hoops: n = "basketball.fill"
        case .hurdles: n = "figure.run.circle.fill"
        case .mathduel: n = "plus.forwardslash.minus"
        case .rhythm: n = "waveform"
        case .billiard: n = "circle.circle"
        case .arrows: n = "arrow.up.arrow.down"
        case .oddone: n = "magnifyingglass"
        case .compare: n = "greaterthan.circle.fill"
        case .sorter: n = "arrow.left.arrow.right.circle.fill"
        case .dodge: n = "wind"
        case .cave: n = "mountain.2.fill"
        case .pendulum: n = "metronome.fill"
        case .count: n = "eye.fill"
        case .stoptime: n = "stopwatch.fill"
        case .slide: n = "snowflake.circle.fill"
        case .snowball: n = "smallcircle.filled.circle.fill"
        case .zigzag: n = "bolt.horizontal.fill"
        case .lightsout: n = "lightbulb.fill"
        case .reflex: n = "hand.tap.fill"
        }
        return Sym.ok(n)
    }
}

/// Rounded gradient tile with a white symbol – replaces the old emoji icons.
struct GlyphTile: View {
    let kind: GameKind
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(LinearGradient(colors: [kind.accent, kind.accent.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: max(1, size * 0.03))
            Image(systemName: kind.symbol)
                .font(.system(size: size * 0.5, weight: .heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: kind.accent.opacity(0.55), radius: size * 0.2)
    }
}

/// Plain symbol with weight.
struct SymbolIcon: View {
    let name: String
    var size: CGFloat = 18
    var color: Color = .white
    var body: some View {
        Image(systemName: Sym.ok(name))
            .font(.system(size: size, weight: .heavy))
            .foregroundColor(color)
    }
}

/// Drawn gold coin (no emoji).
struct CoinGlyph: View {
    var size: CGFloat = 20
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(red: 1, green: 0.88, blue: 0.3), Color(red: 0.95, green: 0.6, blue: 0.05)], startPoint: .top, endPoint: .bottom))
            Circle().stroke(Color(red: 0.7, green: 0.4, blue: 0.0).opacity(0.8), lineWidth: max(1, size * 0.08)).padding(size * 0.1)
            Text("G").font(Theme.font(size * 0.5)).foregroundColor(Color(red: 0.6, green: 0.32, blue: 0.0))
        }
        .frame(width: size, height: size)
        .shadow(color: Color.yellow.opacity(0.5), radius: size * 0.25)
    }
}

/// Numbered medal for ranks.
struct MedalGlyph: View {
    let rank: Int   // 0 = gold
    var size: CGFloat = 26
    var body: some View {
        let c: [Color] = [Color(red: 1, green: 0.8, blue: 0.15), Color(white: 0.8), Color(red: 0.8, green: 0.5, blue: 0.25), Color(white: 0.35)]
        let col = c[min(3, max(0, rank))]
        ZStack {
            Circle().fill(LinearGradient(colors: [col.opacity(1), col.opacity(0.6)], startPoint: .top, endPoint: .bottom))
            Circle().stroke(Color.white.opacity(0.6), lineWidth: max(1, size * 0.06))
            Text("\(rank + 1)").font(Theme.font(size * 0.52)).foregroundColor(rank == 3 ? .white : .black.opacity(0.8))
        }
        .frame(width: size, height: size)
    }
}

func achievementSymbol(_ id: String) -> String {
    switch id {
    case "firstwin": return Sym.ok("medal.fill")
    case "goals10": return Sym.ok("scope")
    case "goals50": return Sym.ok("flame.fill")
    case "tour1": return Sym.ok("trophy.fill")
    case "tour3": return Sym.ok("crown.fill", "star.circle.fill")
    case "quiz20": return Sym.ok("brain.head.profile")
    case "balls50": return Sym.ok("hand.raised.fill")
    case "hits50": return Sym.ok("target")
    case "react": return Sym.ok("bolt.fill")
    case "play25": return Sym.ok("gamecontroller.fill")
    case "kinds12": return Sym.ok("sparkles")
    case "kinds25": return Sym.ok("rosette")
    case "skins6": return Sym.ok("tshirt.fill")
    case "rich": return Sym.ok("banknote.fill", "creditcard.fill")
    default: return Sym.ok("star.fill")
    }
}
