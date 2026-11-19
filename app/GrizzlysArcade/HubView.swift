import SwiftUI

// MARK: - Hub

struct HubView: View {
    @EnvironmentObject var app: AppState
    @State private var glow = false
    @State private var showWheel = launchArgs.contains("-wheel")
    @AppStorage("ga.welcome.v1") private var welcomeSeen = false

    var body: some View {
        ScrollFit { hubContent }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { glow = true }
            }
            .overlay {
                if showWheel {
                    WheelView(show: $showWheel)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .overlay {
                if !welcomeSeen {
                    WelcomeView(show: Binding(get: { !welcomeSeen }, set: { welcomeSeen = !$0 }))
                        .ignoresSafeArea()
                }
            }
    }

    var hubContent: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: { app.go(.settings) }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                        .overlay(Circle().stroke(Theme.orange.opacity(0.6), lineWidth: 1.5))
                }
                .buttonStyle(PressStyle())
                LevelPill()
                StreakPill()
                Spacer(minLength: 0)
                CoinPill()
            }
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.orange.opacity(glow ? 0.55 : 0.3), .clear], center: .center, startRadius: 10, endRadius: 120))
                    .frame(width: 250, height: 250)
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .shadow(color: Theme.orange.opacity(0.8), radius: glow ? 22 : 10)
                    .scaleEffect(glow ? 1.03 : 0.98)
            }
            .frame(height: 170)
            VStack(spacing: 0) {
                Text("GRIZZLYS")
                    .font(Theme.font(46))
                    .foregroundColor(Theme.orange)
                    .shadow(color: Theme.orange.opacity(0.8), radius: 12)
                Text("ARCADE")
                    .font(Theme.font(20))
                    .foregroundColor(.white)
                    .tracking(12)
            }
            playersCard
            Spacer(minLength: 0)
            featuredCard
            ArcadeButton(title: "TURNIER", icon: "trophy.fill", color: Theme.orange, height: 64) { app.go(.tournamentSetup) }
            HStack(spacing: 12) {
                ArcadeButton(title: "\(GameKind.allCases.count) SPIELE", icon: "gamecontroller.fill", color: Theme.blue, height: 54) { app.go(.picker) }
                ArcadeButton(title: "ZUFALL", icon: "dice.fill", color: Theme.green, height: 54) {
                    let pool = GameKind.allCases.filter { $0.supports(app.playerCount) }
                    if let k = pool.randomElement() { app.startGame(k) }
                }
            }
            HStack(spacing: 10) {
                smallButton("SHOP", "bag.fill", .shop, Theme.pink)
                smallButton("STATS", "chart.bar.fill", .stats, Theme.blue)
                smallButton("ERFOLGE", "rosette", .achievements, Color.yellow)
                Button(action: { Sfx.shared.play("click"); withAnimation { showWheel = true } }) {
                    VStack(spacing: 4) {
                        Image(systemName: "gift.fill").font(.system(size: 20, weight: .bold)).foregroundColor(Theme.green)
                        Text("BONUS").font(Theme.font(11)).foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .neonCard(Theme.green.opacity(0.6), radius: 16, glow: false)
                    .overlay(alignment: .topTrailing) {
                        if app.canSpinWheel {
                            Circle().fill(Color.red).frame(width: 12, height: 12).overlay(Circle().stroke(Color.white, lineWidth: 1.5)).offset(x: -6, y: 6)
                        }
                    }
                }
                .buttonStyle(PressStyle())
            }
            dailyTeaser
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    var featured: GameKind {
        let pool = GameKind.allCases.filter { $0.supports(app.playerCount) }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return pool.isEmpty ? .penalty : pool[day % pool.count]
    }

    var featuredCard: some View {
        let k = featured
        return Button(action: { app.startGame(k) }) {
            HStack(spacing: 12) {
                GamePreview(kind: k, height: 58, corner: 14, badge: false)
                    .frame(width: 92)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SPIEL DES TAGES").font(Theme.font(10)).foregroundColor(Theme.orange).tracking(1)
                    Text(k.title).font(Theme.font(18)).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(k.accent))
            }
            .padding(10)
            .neonCard(k.accent.opacity(0.7), radius: 18, glow: false)
        }
        .buttonStyle(PressStyle())
    }

    var playersCard: some View {
        Button(action: { app.go(.setup) }) {
            HStack(spacing: 6) {
                ForEach(app.activeCards, id: \.self) { c in
                    VStack(spacing: 1) {
                        BearView(skin: app.skin(card: c), height: 38, flip: true)
                        Text(app.name(card: c))
                            .font(Theme.font(10))
                            .foregroundColor(Theme.seat[app.activeCards.firstIndex(of: c) ?? 0])
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                VStack(spacing: 2) {
                    Image(systemName: "person.2.fill").foregroundColor(Theme.orange)
                    Text("ÄNDERN").font(Theme.font(10)).foregroundColor(.white)
                }
                .frame(width: 56)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .neonCard(Theme.orange.opacity(0.7), radius: 18, glow: false)
        }
        .buttonStyle(PressStyle())
    }

    func smallButton(_ title: String, _ icon: String, _ screen: Screen, _ color: Color) -> some View {
        Button(action: { app.go(screen) }) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundColor(color)
                Text(title).font(Theme.font(11)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .neonCard(color.opacity(0.6), radius: 16, glow: false)
        }
        .buttonStyle(PressStyle())
    }

    var dailyTeaser: some View {
        let tasks = Daily.todaysTasks()
        let done = tasks.filter { app.save.daily.claimed.contains($0.id) }.count
        return Button(action: { app.go(.achievements) }) {
            HStack(spacing: 8) {
                Image(systemName: "calendar").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.orange)
                Text("Tagesaufgaben \(done)/\(tasks.count)")
                    .font(Theme.fontMed(13))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                if let next = tasks.first(where: { !app.save.daily.claimed.contains($0.id) }) {
                    Text(next.title).font(Theme.fontMed(12)).foregroundColor(Theme.orange).lineLimit(1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.white.opacity(0.06)))
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Player setup

struct SetupView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 12) {
            TopBar(title: "SPIELER", showCoins: false)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text("Bis zu 4 Spieler an einem Handy. Leg das Handy in die Mitte – jeder spielt von seiner Seite aus.")
                        .font(Theme.fontMed(14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(0..<4, id: \.self) { c in
                            PlayerCard(card: c)
                        }
                    }
                    seatDiagram
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("CPU-STÄRKE").font(Theme.font(13)).foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(Difficulty.names[app.save.difficulty]).font(Theme.font(15)).foregroundColor(Difficulty.colors[app.save.difficulty])
                        }
                        HStack(spacing: 6) {
                            ForEach(0..<5, id: \.self) { i in
                                Button(action: {
                                    Sfx.shared.play("click"); Haptic.tap()
                                    app.update { $0.difficulty = i }
                                }) {
                                    VStack(spacing: 4) {
                                        HStack(spacing: 1.5) {
                                            ForEach(0..<5, id: \.self) { j in
                                                Capsule()
                                                    .fill(j <= i ? Difficulty.colors[i] : Color.white.opacity(0.15))
                                                    .frame(width: 5, height: 8 + CGFloat(j) * 3)
                                            }
                                        }
                                        .frame(height: 22, alignment: .bottom)
                                        Text(["1", "2", "3", "4", "5"][i]).font(Theme.font(12)).foregroundColor(app.save.difficulty == i ? .black : .white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(app.save.difficulty == i ? Difficulty.colors[i] : Color.white.opacity(0.08)))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Difficulty.colors[i].opacity(app.save.difficulty == i ? 0.9 : 0.35), lineWidth: 1))
                                    .shadow(color: app.save.difficulty == i ? Difficulty.colors[i].opacity(0.5) : .clear, radius: 8)
                                }
                                .buttonStyle(PressStyle())
                            }
                        }
                        Text(Difficulty.blurbs[app.save.difficulty])
                            .font(Theme.fontMed(12))
                            .foregroundColor(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .neonCard(Theme.blue.opacity(0.6), radius: 18, glow: false)
                }
                .padding(.bottom, 10)
            }
            ArcadeButton(title: "FERTIG", icon: "checkmark", height: 56) { app.go(.hub) }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    /// Tiny phone showing where everybody sits (own-field games)
    var seatDiagram: some View {
        let cards = app.activeCards
        let n = cards.count
        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: 70, height: 130)
                if n <= 2 {
                    VStack(spacing: 4) {
                        seatBox(1, cards)
                        seatBox(0, cards)
                    }
                    .frame(width: 60, height: 118)
                } else {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) { seatBox(3, cards); seatBox(2, cards) }
                        HStack(spacing: 4) { seatBox(0, cards); seatBox(1, cards) }
                    }
                    .frame(width: 60, height: 118)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("SO SITZT IHR").font(Theme.font(13)).foregroundColor(Theme.orange)
                Text(n <= 2 ? "Einer unten, einer oben (gegenüber)." : "Zwei unten, zwei oben – jeder sein Viertel.")
                    .font(Theme.fontMed(12)).foregroundColor(.white.opacity(0.75))
                Text("Bei Arena-Spielen (Air-Hockey, Sumo …) steuert jeder von seiner Kante: unten, oben, links, rechts.")
                    .font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .neonCard(Theme.orange.opacity(0.5), radius: 18, glow: false)
    }

    @ViewBuilder
    func seatBox(_ seat: Int, _ cards: [Int]) -> some View {
        if seat < cards.count {
            RoundedRectangle(cornerRadius: 5).fill(Theme.seat[seat].opacity(0.8))
                .overlay(Text("\(cards[seat] + 1)").font(Theme.font(12)).foregroundColor(.black))
        } else {
            RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.08))
        }
    }
}

struct PlayerCard: View {
    @EnvironmentObject var app: AppState
    let card: Int
    @State private var name = ""

    var body: some View {
        let mode = app.save.slots[card]
        let seatIndex = app.activeCards.firstIndex(of: card)
        let color = seatIndex.map { Theme.seat[$0] } ?? Color.gray
        VStack(spacing: 8) {
            Button(action: cycleSkin) {
                ZStack(alignment: .bottomTrailing) {
                    BearView(skin: app.skin(card: card), height: 66, flip: true)
                        .opacity(mode == .off ? 0.3 : 1)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Circle().fill(color))
                }
            }
            .buttonStyle(PressStyle())
            if mode == .human {
                TextField("Spieler \(card + 1)", text: $name, onCommit: saveName)
                    .font(Theme.font(15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.35)))
                    .submitLabel(.done)
                    .onChange(of: name) { v in
                        if v.count > 10 { name = String(v.prefix(10)) }
                        saveName()
                    }
            } else {
                Text(mode == .cpu ? AppState.cpuNames[card] + " (CPU)" : "—")
                    .font(Theme.font(14))
                    .foregroundColor(.white.opacity(mode == .off ? 0.4 : 0.85))
                    .frame(height: 32)
            }
            HStack(spacing: 4) {
                modeButton("person.fill", .human, mode)
                modeButton("cpu", .cpu, mode)
                modeButton("xmark", .off, mode)
            }
        }
        .padding(12)
        .neonCard(color, radius: 18, glow: mode != .off)
        .onAppear { name = app.save.names[card] }
    }

    func modeButton(_ t: String, _ m: SlotMode, _ cur: SlotMode) -> some View {
        Button(action: {
            Sfx.shared.play("click")
            app.setSlot(card, m)
        }) {
            Image(systemName: Sym.ok(t))
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 9).fill(cur == m ? Theme.orange.opacity(0.85) : Color.white.opacity(0.08)))
        }
        .buttonStyle(PressStyle())
    }

    func cycleSkin() {
        let owned = Skin.all.filter { app.save.unlocked.contains($0.id) }
        guard !owned.isEmpty else { return }
        let cur = owned.firstIndex(where: { $0.id == app.save.skinIds[card] }) ?? -1
        let next = owned[(cur + 1) % owned.count]
        app.equip(next, card: card)
        Sfx.shared.play("pop")
        Haptic.tap()
    }

    func saveName() {
        let v = String(name.prefix(10))
        app.update { $0.names[card] = v }
    }
}

// MARK: - Game picker

struct PickerView: View {
    @EnvironmentObject var app: AppState
    @State private var filter: GameTag? = nil

    var body: some View {
        let n = app.playerCount
        let list = GameKind.allCases.filter { filter == nil || $0.tag == filter }
        VStack(spacing: 12) {
            TopBar(title: "SPIELE")
            HStack(spacing: 8) {
                Chip(text: "ALLE \(GameKind.allCases.count)", on: filter == nil) { filter = nil }
                Chip(text: "UNIHOCKEY", on: filter == .hockey, color: Theme.blue) { filter = .hockey }
                Chip(text: "PARTY", on: filter == .party, color: Theme.pink) { filter = .party }
            }
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(list) { k in
                        card(k, enabled: k.supports(n))
                    }
                }
                .padding(.vertical, 6)
            }
            Text("\(n) Spieler · \(app.humanCount) Mensch\(app.humanCount == 1 ? "" : "en")")
                .font(Theme.fontMed(12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    func card(_ k: GameKind, enabled: Bool) -> some View {
        Button(action: { if enabled { app.startGame(k) } }) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    GamePreview(kind: k, height: 104, corner: 18)
                    if !app.save.playedKinds.contains(k.rawValue) {
                        Text("NEU")
                            .font(Theme.font(10))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.yellow))
                            .padding(6)
                    }
                }
                Text(k.title)
                    .font(Theme.font(15))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 4) {
                    Text(GameRegistry.layout(k) == .arena ? "ARENA" : k.tag.rawValue.uppercased())
                        .font(Theme.font(9))
                        .foregroundColor(k.accent)
                    Spacer()
                    if let b = app.save.best[k.rawValue] {
                        HStack(spacing: 3) { Image(systemName: "medal.fill").font(.system(size: 9)); Text("\(b)").font(Theme.fontMed(11)) }.foregroundColor(.white.opacity(0.75))
                    } else {
                        Text("\(k.seconds)s").font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(10)
            .neonCard(k.accent.opacity(0.7), radius: 20, glow: false)
            .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(PressStyle())
    }
}


enum Difficulty {
    static let names = ["EINSTEIGER", "LEICHT", "MITTEL", "SCHWER", "EXTREM"]
    static let colors: [Color] = [Color(red: 0.4, green: 0.95, blue: 0.6), Theme.green, Theme.orange, Color(red: 1, green: 0.4, blue: 0.3), Theme.pink]
    static let blurbs = [
        "Die CPU patzt oft und lässt dir viel Raum. Perfekt zum Üben.",
        "Du hast gute Siegchancen, die CPU macht noch regelmässig Fehler.",
        "Ein faires Duell: Wer konzentriert spielt, gewinnt.",
        "Eine echte Herausforderung. Die CPU reagiert schnell und patzt selten.",
        "Fast unmöglich, aber machbar: Die CPU spielt am Limit. Nur für Profis."
    ]
}
