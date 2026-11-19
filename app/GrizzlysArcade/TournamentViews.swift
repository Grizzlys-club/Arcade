import SwiftUI

// MARK: - Tournament setup

struct TournamentSetupView: View {
    @EnvironmentObject var app: AppState
    @State private var rounds = 5

    var body: some View {
        VStack(spacing: 14) {
            TopBar(title: "TURNIER")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Image(systemName: Sym.ok("trophy.fill")).font(.system(size: 64, weight: .heavy)).foregroundColor(Color(red: 1, green: 0.82, blue: 0.2)).shadow(color: .yellow.opacity(0.7), radius: 18)
                    Text("Jede Runde lost die Glücksmaschine ein zufälliges Spiel aus. Wer am Ende die meisten Punkte hat, steht ganz oben auf dem Podest.")
                        .font(Theme.fontMed(15))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WIE VIELE RUNDEN?").font(Theme.font(13)).foregroundColor(.white.opacity(0.7))
                        HStack(spacing: 8) {
                            ForEach([3, 5, 7, 10, 15], id: \.self) { r in
                                Chip(text: "\(r)", on: rounds == r) { rounds = r }
                            }
                        }
                        Text("ca. \(rounds * 1 + rounds / 2)–\(rounds * 2) Minuten")
                            .font(Theme.fontMed(12)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(14)
                    .neonCard(Theme.orange.opacity(0.6), radius: 18, glow: false)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PUNKTE PRO SPIEL").font(Theme.font(13)).foregroundColor(.white.opacity(0.7))
                        Text(pointsText).font(Theme.fontMed(14)).foregroundColor(.white)
                        Text("Das Finale zählt doppelt!").font(Theme.font(13)).foregroundColor(.yellow)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .neonCard(Theme.blue.opacity(0.6), radius: 18, glow: false)
                    Button(action: { app.go(.setup) }) {
                        HStack {
                            ForEach(0..<app.playerCount, id: \.self) { i in
                                VStack(spacing: 1) {
                                    BearView(skin: app.seatSkin(i), height: 36, flip: true)
                                    Text(app.seatName(i)).font(Theme.font(10)).foregroundColor(Theme.seat[i]).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            Image(systemName: "pencil.circle.fill").font(.system(size: 22)).foregroundColor(Theme.orange)
                        }
                        .padding(12)
                        .neonCard(Color.white.opacity(0.3), radius: 18, glow: false)
                    }
                    .buttonStyle(PressStyle())
                }
            }
            ArcadeButton(title: "TURNIER STARTEN", icon: "sparkles", height: 62) { app.startTournament(rounds: rounds) }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .onAppear { rounds = app.save.rounds }
    }

    var pointsText: String {
        switch app.playerCount {
        case 2: return "Sieg 3 · Niederlage 0 · Unentschieden je 1"
        case 3: return "1. Platz 4 · 2. Platz 2 · 3. Platz 0"
        default: return "1. Platz 5 · 2. Platz 3 · 3. Platz 1 · 4. Platz 0"
        }
    }
}

// MARK: - Standings + slot machine

struct TournamentView: View {
    @EnvironmentObject var app: AppState
    @State private var reelKind: GameKind = .penalty
    @State private var spinning = true
    @State private var landed = false
    @State private var bounce = false

    var body: some View {
        let t = app.tournament ?? Tournament(rounds: 1, points: [0, 0], wins: [0, 0])
        ScrollFit {
        VStack(spacing: 14) {
            HStack {
                Button(action: {
                    app.tournament = nil
                    app.go(.hub)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.red.opacity(0.5)))
                }
                .buttonStyle(PressStyle())
                Spacer()
                VStack(spacing: 0) {
                    Text("TURNIER").font(Theme.font(13)).foregroundColor(Theme.orange).tracking(3)
                    Text(t.isFinal ? "FINALE" : "RUNDE \(t.played + 1) / \(t.rounds)").font(Theme.font(24)).foregroundColor(.white)
                }
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            roundDots(t)
            standings(t)
            Spacer(minLength: 0)
            reel(t)
            Spacer(minLength: 0)
            if landed {
                ArcadeButton(title: "SPIELEN", icon: "play.fill", height: 62) { app.playTournamentGame() }
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("Die Glücksmaschine lost aus …")
                    .font(Theme.fontMed(15))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: 62)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
        }
        .onAppear { spin(to: t.next ?? .penalty) }
    }

    func roundDots(_ t: Tournament) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<t.rounds, id: \.self) { i in
                let done = i < t.log.count
                ZStack {
                    Circle()
                        .fill(done ? t.log[i].kind.accent : (i == t.played ? Theme.orange.opacity(0.35) : Color.white.opacity(0.08)))
                    if done {
                        Image(systemName: t.log[i].kind.symbol).font(.system(size: t.rounds > 10 ? 8 : 11, weight: .heavy)).foregroundColor(.white)
                    } else if i == t.rounds - 1 {
                        Text("★").font(.system(size: 10)).foregroundColor(.yellow)
                    }
                }
                .frame(width: t.rounds > 10 ? 18 : 24, height: t.rounds > 10 ? 18 : 24)
            }
        }
    }

    func standings(_ t: Tournament) -> some View {
        let maxP = max(1, t.points.max() ?? 1)
        let places = t.places
        return VStack(spacing: 8) {
            ForEach(t.order, id: \.self) { i in
                HStack(spacing: 10) {
                    Text(["1", "2", "3", "4"][min(3, places[i])])
                        .font(Theme.font(18))
                        .foregroundColor(places[i] == 0 ? .yellow : .white.opacity(0.7))
                        .frame(width: 20)
                    BearView(skin: app.seatSkin(i), height: 34, flip: true)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(app.seatName(i)).font(Theme.font(15)).foregroundColor(.white).lineLimit(1)
                            if t.wins[i] > 0 {
                                Text("\(t.wins[i])× Sieg").font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.6))
                            }
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule().fill(Theme.seat[i % 4])
                                    .frame(width: max(8, g.size.width * CGFloat(t.points[i]) / CGFloat(maxP)))
                                    .shadow(color: Theme.seat[i % 4].opacity(0.7), radius: 6)
                            }
                        }
                        .frame(height: 10)
                    }
                    Text("\(t.points[i])").font(Theme.font(26)).foregroundColor(.white).frame(width: 46, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.seat[i % 4].opacity(places[i] == 0 && t.played > 0 ? 0.18 : 0.06)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: t.points)
    }

    func reel(_ t: Tournament) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [reelKind.accent.opacity(0.9), reelKind.accent.opacity(0.35)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: reelKind.accent.opacity(landed ? 0.9 : 0.4), radius: landed ? 30 : 12)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 3)
                VStack(spacing: 6) {
                    Image(systemName: reelKind.symbol).font(.system(size: 60, weight: .heavy)).foregroundColor(.white).shadow(color: .black.opacity(0.4), radius: 4)
                    Text(reelKind.title.uppercased())
                        .font(Theme.font(22))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if landed {
                        Text(reelKind.tag.rawValue.uppercased() + " · ca. \(reelKind.seconds)s")
                            .font(Theme.font(11))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(2)
                    }
                }
                .padding(.horizontal, 16)
                .blur(radius: spinning ? 1.2 : 0)
            }
            .frame(width: 240, height: 190)
            .scaleEffect(bounce ? 1.08 : 1)
            HStack(spacing: 6) {
                ForEach(0..<9, id: \.self) { i in
                    Circle().fill(spinning && (i % 2 == 0) == bounce ? Color.yellow : Color.yellow.opacity(0.25)).frame(width: 7, height: 7)
                }
            }
        }
    }

    func spin(to target: GameKind) {
        landed = false
        spinning = true
        let pool = GameKind.allCases.filter { $0.supports(app.playerCount) }
        var time = 0.0
        let steps = 24
        for s in 0..<steps {
            let delay = 0.05 + pow(Double(s) / Double(steps), 2.4) * 0.38
            time += delay
            let last = s == steps - 1
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                if last {
                    reelKind = target
                    spinning = false
                    Sfx.shared.play("fanfare")
                    Haptic.good()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { bounce = true; landed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.spring()) { bounce = false }
                    }
                    if app.autoplay {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { app.playTournamentGame() }
                    }
                } else {
                    var k = pool.randomElement() ?? target
                    if k == reelKind { k = pool.randomElement() ?? target }
                    reelKind = k
                    bounce.toggle()
                    Sfx.shared.play("tick")
                    Haptic.tap(.soft)
                }
            }
        }
    }
}

// MARK: - Podium

struct PodiumView: View {
    @EnvironmentObject var app: AppState
    @State private var appear = false

    var body: some View {
        let t = app.tournament ?? Tournament(rounds: 1, points: [0, 0], wins: [0, 0])
        let order = t.order
        let places = t.places
        ZStack {
            Confetti().ignoresSafeArea()
            ScrollFit {
            VStack(spacing: 12) {
                Text("SIEGEREHRUNG")
                    .font(Theme.font(14)).foregroundColor(Theme.orange).tracking(4)
                    .padding(.top, 12)
                Text(places.filter { $0 == 0 }.count > 1 ? "GETEILTER SIEG!" : "\(app.seatName(order[0]).uppercased()) GEWINNT!")
                    .font(Theme.font(30))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 8) {
                    if order.count > 1 { podiumColumn(order[1], place: places[order[1]], t: t) }
                    podiumColumn(order[0], place: places[order[0]], t: t)
                    if order.count > 2 { podiumColumn(order[2], place: places[order[2]], t: t) }
                }
                if order.count > 3 {
                    HStack {
                        Text("4.").font(Theme.font(16)).foregroundColor(.white.opacity(0.6))
                        BearView(skin: app.seatSkin(order[3]), height: 30, flip: true)
                        Text(app.seatName(order[3])).font(Theme.font(15)).foregroundColor(.white)
                        Spacer()
                        Text("\(t.points[order[3]]) Pkt").font(Theme.font(15)).foregroundColor(.white.opacity(0.7))
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                }
                roundLog(t)
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    ArcadeButton(title: "NOCHMAL", icon: "arrow.counterclockwise", height: 54) { app.startTournament(rounds: t.rounds) }
                    ArcadeButton(title: "MENÜ", color: Color.white.opacity(0.9), height: 54) {
                        app.tournament = nil
                        app.go(.hub)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            }
        }
        .onAppear {
            Sfx.shared.play("fanfare")
            Haptic.good()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { appear = true }
        }
    }

    func podiumColumn(_ seat: Int, place: Int, t: Tournament) -> some View {
        let heights: [CGFloat] = [150, 110, 80, 60]
        let colors: [Color] = [Color(red: 1, green: 0.8, blue: 0.15), Color(white: 0.78), Color(red: 0.8, green: 0.5, blue: 0.25), Color.gray]
        let h = heights[min(3, place)]
        return VStack(spacing: 4) {
            if place == 0 {
                Image(systemName: Sym.ok("trophy.fill"))
                    .font(.system(size: 50, weight: .heavy))
                    .foregroundColor(Color(red: 1, green: 0.82, blue: 0.2))
                    .shadow(color: .yellow.opacity(0.9), radius: 16)
                    .offset(y: appear ? 0 : -60)
                    .opacity(appear ? 1 : 0)
            }
            BearView(skin: app.seatSkin(seat), height: place == 0 ? 92 : 70, flip: true)
                .scaleEffect(appear ? 1 : 0.2)
            Text(app.seatName(seat)).font(Theme.font(14)).foregroundColor(Theme.seat[seat % 4]).lineLimit(1)
            Text("\(t.points[seat]) Pkt").font(Theme.fontMed(12)).foregroundColor(.white)
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [colors[min(3, place)], colors[min(3, place)].opacity(0.6)], startPoint: .top, endPoint: .bottom))
                VStack(spacing: 2) {
                    Text("\(place + 1)").font(Theme.font(42)).foregroundColor(.black.opacity(0.65))
                    Image("logo").resizable().scaledToFit().frame(width: 30).opacity(0.7)
                }
            }
            .frame(height: appear ? h : 10)
        }
        .frame(maxWidth: .infinity)
    }

    func roundLog(_ t: Tournament) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<t.log.count, id: \.self) { i in
                    let e = t.log[i]
                    let best = e.scores.max() ?? 0
                    let w = e.scores.firstIndex(of: best) ?? 0
                    VStack(spacing: 2) {
                        Image(systemName: e.kind.symbol).font(.system(size: 17, weight: .heavy)).foregroundColor(e.kind.accent)
                        Circle().fill(Theme.seat[w % 4]).frame(width: 8, height: 8)
                    }
                    .frame(width: 42, height: 52)
                    .background(RoundedRectangle(cornerRadius: 10).fill(e.kind.accent.opacity(0.25)))
                }
            }
        }
        .frame(height: 56)
    }
}
