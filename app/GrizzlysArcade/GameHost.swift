import SwiftUI
import SpriteKit

final class HostModel: ObservableObject {
    enum Phase { case intro, playing, paused, result }
    @Published var phase: Phase = .intro
    @Published var scene: MiniScene? = nil
    @Published var result = GameResult()
    @Published var reward = RewardInfo()
}

struct GameHost: View {
    @EnvironmentObject var app: AppState
    @StateObject private var model = HostModel()
    @State private var viewSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                if let s = model.scene {
                    SKContainer(scene: s).ignoresSafeArea()
                }
                switch model.phase {
                case .intro: introCard
                case .paused: pauseCard
                case .result: resultCard
                case .playing: EmptyView()
                }
            }
            .onAppear {
                viewSize = geo.size
                if app.autoplay {
                    app.autoKick = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { app.autoKick = true }
                }
            }
            .onChange(of: app.autoKick) { v in
                if v && model.phase == .intro { startPlaying() }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: scene creation

    func makeScene(_ k: GameKind) -> MiniScene {
        let full = UIScreen.main.bounds.size
        let aspect = full.height / max(1, full.width)
        SH = max(640, min(920, SW * aspect))
        let s = GameRegistry.make(k)
        s.size = CGSize(width: SW, height: SH)
        s.scaleMode = .aspectFit
        s.configure(players: app.seatSetups(), difficulty: app.save.difficulty)
        let m = model
        let a = app
        s.onFinish = { r in
            DispatchQueue.main.async {
                let info = a.record(r, kind: k)
                m.result = r
                m.reward = info
                m.scene?.isPaused = true
                m.phase = .result
                Sfx.shared.play("win")
                if a.autoplay {
                    print("GA_RESULT \(k.rawValue) scores=\(r.scores) stats=\(r.stats)")
                    if a.tournament != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { a.afterTournamentGame() }
                    }
                }
            }
        }
        s.onPause = {
            DispatchQueue.main.async {
                if m.phase == .playing {
                    m.scene?.userPaused = true
                    m.scene?.isPaused = true
                    m.phase = .paused
                }
            }
        }
        return s
    }

    func startPlaying() {
        model.scene = makeScene(app.current)
        model.phase = .playing
        if !app.save.seenIntro.contains(app.current.rawValue) && !app.autoplay {
            app.update { $0.seenIntro.append(app.current.rawValue) }
        }
    }

    func resume() {
        model.scene?.userPaused = false
        model.scene?.isPaused = false
        model.phase = .playing
    }

    func leave() {
        model.scene?.isPaused = true
        model.scene = nil
        if app.tournament != nil {
            app.tournament = nil
            app.go(.hub)
        } else {
            app.go(.picker)
        }
    }

    // MARK: overlays

    var introCard: some View {
        let kind = app.current
        return ZStack {
            ArcadeBackground()
            VStack(spacing: 0) {
                // top bar: always reachable
                HStack {
                    Button(action: { leave() }) {
                        HStack(spacing: 8) {
                            Image(systemName: app.tournament != nil ? "xmark" : "chevron.left")
                                .font(.system(size: 16, weight: .heavy))
                            Text(app.tournament != nil ? "ABBRECHEN" : "ZURÜCK")
                                .font(Theme.font(14))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 42)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                        .overlay(Capsule().stroke(Theme.orange.opacity(0.7), lineWidth: 1.5))
                    }
                    .buttonStyle(PressStyle())
                    Spacer()
                    if let t = app.tournament {
                        Text(t.isFinal ? "FINALE · DOPPELT" : "RUNDE \(t.played + 1)/\(t.rounds)")
                            .font(Theme.font(13))
                            .foregroundColor(t.isFinal ? .yellow : Theme.orange)
                            .tracking(1)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, safeAreaTop() + 6)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ZStack(alignment: .bottom) {
                            GamePreview(kind: kind, height: 190, corner: 26, badge: false)
                            VStack(spacing: 2) {
                                GlyphTile(kind: kind, size: 46)
                                Text(kind.title.uppercased())
                                    .font(Theme.font(28))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.8), radius: 6)
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                            }
                            .padding(.bottom, 10)
                        }
                        Text(kind.tag.rawValue.uppercased() + " · ca. \(kind.seconds) SEK · \(kind.minPlayers)–\(kind.maxPlayers) SPIELER")
                            .font(Theme.font(11))
                            .foregroundColor(kind.accent)
                            .tracking(1.5)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill").foregroundColor(.yellow)
                                Text("SO GEHT'S").font(Theme.font(13)).foregroundColor(.white.opacity(0.7))
                            }
                            Text(kind.rules)
                                .font(Theme.fontMed(17))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(layoutHint(kind))
                                .font(Theme.fontMed(13))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .neonCard(kind.accent)
                        playersRow
                        Color.clear.frame(height: 6)
                    }
                    .padding(.horizontal, 22)
                }

                // pinned start button – always visible
                VStack(spacing: 0) {
                    ArcadeButton(title: "LOS GEHT'S", icon: "play.fill", color: Theme.orange, height: 60) { startPlaying() }
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, safeAreaBottom() + 8)
                .background(
                    LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                )
            }
        }
    }

    func layoutHint(_ k: GameKind) -> String {
        let n = app.playerCount
        if GameRegistry.layout(k) == .turns {
            return "Ihr spielt der Reihe nach auf dem ganzen Bildschirm. Gib das Handy weiter, wenn du fertig bist."
        }
        let isArena = GameRegistry.layout(k) == .arena
        if isArena {
            return n >= 3 ? "Gemeinsames Spielfeld: Jeder steuert von seiner Handy-Kante aus (unten, oben, links, rechts)." : "Gemeinsames Spielfeld: einer unten, einer oben."
        }
        return n >= 3 ? "Jeder hat sein eigenes Viertel des Bildschirms." : "Jeder hat seine eigene Bildschirmhälfte: einer unten, einer oben."
    }

    var playersRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<app.playerCount, id: \.self) { i in
                VStack(spacing: 2) {
                    BearView(skin: app.seatSkin(i), height: 42, flip: true)
                    Text(app.seatName(i)).font(Theme.font(11)).foregroundColor(Theme.seat[i]).lineLimit(1)
                    if app.seatIsCPU(i) { Text("CPU").font(Theme.font(9)).foregroundColor(.white.opacity(0.5)) }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    var pauseCard: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                pauseBody
                ScrollView(showsIndicators: false) { pauseBody.padding(.vertical, 40) }
            }
        }
    }

    var pauseBody: some View {
        ZStack {
            VStack(spacing: 14) {
                Text("PAUSE").font(Theme.font(40)).foregroundColor(.white)
                Text(app.current.rules)
                    .font(Theme.fontMed(14))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                ArcadeButton(title: "WEITER", icon: "play.fill", height: 54) { resume() }
                ArcadeButton(title: "NEU STARTEN", color: Color.white.opacity(0.9), height: 48) { startPlaying() }
                ArcadeButton(title: app.tournament != nil ? "TURNIER ABBRECHEN" : "ZUR SPIELWAHL", color: Color.red.opacity(0.85), textColor: .white, height: 48) { leave() }
            }
            .padding(22)
            .neonCard(Theme.orange)
            .padding(.horizontal, 28)
        }
    }

    var resultCard: some View {
        let kind = app.current
        let r = model.result
        let info = model.reward
        let ranks = info.ranks.isEmpty ? Ranking.ranks(r.scores) : info.ranks
        let order = r.scores.indices.sorted { ranks[$0] < ranks[$1] }
        let winners = order.filter { ranks[$0] == 0 }
        let title: String
        if winners.count > 1 {
            title = "Unentschieden!"
        } else if let w = winners.first {
            title = "\(app.seatName(w)) gewinnt!"
        } else {
            title = "Fertig"
        }
        return ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            if winners.contains(where: { !app.seatIsCPU($0) }) { Confetti().ignoresSafeArea() }
            VStack(spacing: 0) {
                if app.playerCount == 2 {
                    compactResult(kind: kind, r: r, info: info, ranks: ranks, order: order, title: title)
                        .rotationEffect(.degrees(180))
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                    Rectangle().fill(kind.accent.opacity(0.7)).frame(height: 2).shadow(color: kind.accent, radius: 6)
                }
                ScrollFit {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    GlyphTile(kind: kind, size: 28)
                    Text(kind.title.uppercased())
                        .font(Theme.font(14))
                        .foregroundColor(kind.accent)
                        .tracking(1)
                }
                if let w = winners.first {
                    ZStack(alignment: .top) {
                        BearView(skin: app.seatSkin(w), height: 100, flip: true)
                            .padding(.top, 22)
                        Image(systemName: Sym.ok("crown.fill", "star.fill")).font(.system(size: 30, weight: .heavy)).foregroundColor(Color(red: 1, green: 0.82, blue: 0.2)).shadow(color: .yellow.opacity(0.7), radius: 8)
                    }
                }
                Text(title.uppercased())
                    .font(Theme.font(28))
                    .foregroundColor(Theme.orange)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                VStack(spacing: 8) {
                    ForEach(order, id: \.self) { i in
                        HStack(spacing: 10) {
                            MedalGlyph(rank: ranks[i], size: 28)
                                .frame(width: 34)
                            Circle().fill(Theme.seat[i % 4]).frame(width: 10, height: 10)
                            Text(app.seatName(i)).font(Theme.font(17)).foregroundColor(.white).lineLimit(1)
                            Spacer()
                            Text("\(r.scores[i])").font(Theme.font(22)).foregroundColor(.white)
                            Text(kind.unit).font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.5))
                            if !info.pts.isEmpty && i < info.pts.count {
                                Text("+\(info.pts[i])")
                                    .font(Theme.font(14))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.yellow))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.seat[i % 4].opacity(ranks[i] == 0 ? 0.22 : 0.08)))
                    }
                }
                HStack(spacing: 12) {
                    if info.coins > 0 { HStack(spacing: 4) { Text("+\(info.coins)").font(Theme.font(16)).foregroundColor(.yellow); CoinGlyph(size: 18) } }
                    if info.xp > 0 { Text("+\(info.xp) XP").font(Theme.font(15)).foregroundColor(Theme.blue) }
                    if info.newBest { Text("NEUER REKORD!").font(Theme.font(14)).foregroundColor(Theme.pink) }
                }
                ForEach(info.messages, id: \.self) { m in
                    Text(m).font(Theme.fontMed(13)).foregroundColor(.white.opacity(0.85))
                }
                if let t = app.tournament {
                    ArcadeButton(title: t.finished ? "ZUR SIEGEREHRUNG" : "WEITER ZUM STAND", height: 56) {
                        model.scene = nil
                        app.afterTournamentGame()
                    }
                } else {
                    HStack(spacing: 10) {
                        ArcadeButton(title: "NOCHMAL", icon: "arrow.counterclockwise", height: 52) { startPlaying() }
                        ArcadeButton(title: "SPIELE", color: Color.white.opacity(0.9), height: 52) {
                            model.scene = nil
                            app.go(.picker)
                        }
                    }
                }
            }
            .padding(20)
            .neonCard(kind.accent)
            .padding(.horizontal, 18)
                }
            }
        }
    }

    /// Short copy of the result for the player sitting on the other side (shown rotated by 180°)
    func compactResult(kind: GameKind, r: GameResult, info: RewardInfo, ranks: [Int], order: [Int], title: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                GlyphTile(kind: kind, size: 26)
                Text(kind.title.uppercased()).font(Theme.font(13)).foregroundColor(kind.accent).tracking(1)
            }
            Text(title.uppercased())
                .font(Theme.font(26))
                .foregroundColor(Theme.orange)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            ForEach(order, id: \.self) { i in
                HStack(spacing: 10) {
                    MedalGlyph(rank: ranks[i], size: 26)
                    Circle().fill(Theme.seat[i % 4]).frame(width: 10, height: 10)
                    Text(app.seatName(i)).font(Theme.font(16)).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Text("\(r.scores[i])").font(Theme.font(20)).foregroundColor(.white)
                    Text(kind.unit).font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.seat[i % 4].opacity(ranks[i] == 0 ? 0.22 : 0.08)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}
