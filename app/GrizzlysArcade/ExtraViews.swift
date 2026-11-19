import SwiftUI

// MARK: - Shop (skins)

struct ShopView: View {
    @EnvironmentObject var app: AppState
    @State private var message = ""
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 10) {
            TopBar(title: "BÄREN-SHOP")
            Text(message.isEmpty ? "Münzen gibt es nur durchs Spielen: Spiele, Siege, Erfolge und Tagesaufgaben. Kein Echtgeld." : message)
                .font(Theme.fontMed(13))
                .foregroundColor(message.isEmpty ? .white.opacity(0.6) : Theme.orange)
                .multilineTextAlignment(.center)
                .frame(minHeight: 34)
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    let names = ["SKINS", "TITEL", "JUBEL", "BOOSTER"]
                    Chip(text: names[i], on: tab == i, color: Theme.pink) { tab = i }
                }
            }
            ScrollView(showsIndicators: false) {
                if tab == 0 {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Skin.all) { skin in card(skin) }
                    }
                    .padding(.vertical, 4)
                } else {
                    VStack(spacing: 10) {
                        ForEach(items(for: tab)) { item in itemRow(item) }
                        if tab == 3 {
                            Text("Aktiv: \(app.save.coinBoost) Spiele Münz-Booster · \(app.save.xpBoost) Spiele XP-Booster")
                                .font(Theme.fontMed(12)).foregroundColor(.white.opacity(0.55)).padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    func items(for t: Int) -> [ShopItem] {
        switch t {
        case 1: return ShopCatalog.titles
        case 2: return ShopCatalog.cheers
        default: return ShopCatalog.boosts
        }
    }

    func itemRow(_ item: ShopItem) -> some View {
        let owned = app.owns(item) && item.kind != .boost
        let equipped = (item.kind == .title && app.save.titleId == item.id) || (item.kind == .cheer && app.save.cheerId == item.id)
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.pink, Theme.orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: Sym.ok(item.symbol)).font(.system(size: 22, weight: .heavy)).foregroundColor(.white)
            }
            .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(Theme.font(16)).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.7)
                Text(item.detail).font(Theme.fontMed(12)).foregroundColor(.white.opacity(0.6)).lineLimit(2)
            }
            Spacer(minLength: 4)
            Button(action: { act(item, owned: owned) }) {
                Group {
                    if equipped {
                        HStack(spacing: 4) { Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)); Text("AKTIV").font(Theme.font(13)) }
                    } else if owned {
                        Text("WÄHLEN").font(Theme.font(13))
                    } else {
                        HStack(spacing: 5) { Text("\(item.price)").font(Theme.font(14)); CoinGlyph(size: 16) }
                    }
                }
                .foregroundColor(.black)
                .frame(width: 92, height: 38)
                .background(RoundedRectangle(cornerRadius: 11).fill(equipped ? Theme.green : (owned ? Color.white : (app.save.coins >= item.price ? Color.yellow : Color.gray))))
            }
            .buttonStyle(PressStyle())
        }
        .padding(12)
        .neonCard(equipped ? Theme.green.opacity(0.9) : Color.white.opacity(0.18), radius: 18, glow: equipped)
    }

    func act(_ item: ShopItem, owned: Bool) {
        if owned {
            app.equipItem(item)
            message = "\(item.name) ausgewählt."
            Sfx.shared.play("click")
        } else if app.buyItem(item) {
            if item.kind != .boost { app.equipItem(item) }
            message = item.kind == .boost ? "\(item.name) aktiviert!" : "\(item.name) freigeschaltet!"
            Sfx.shared.play("coin")
            Haptic.good()
        } else {
            message = "Es fehlen noch \(item.price - app.save.coins) Münzen. Weiterspielen!"
            Sfx.shared.play("wrong")
            Haptic.bad()
        }
    }

    func card(_ skin: Skin) -> some View {
        let owned = app.save.unlocked.contains(skin.id)
        return VStack(spacing: 6) {
            BearView(skin: skin, height: 78, flip: true)
                .frame(height: 86)
            Text(skin.name).font(Theme.font(15)).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.7)
            Text("Trikot Nr. \(skin.number)").font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.55))
            if owned {
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { c in equipButton(skin, c) }
                }
            } else {
                Button(action: {
                    if app.buy(skin) {
                        message = "\(skin.name) freigeschaltet!"
                        Sfx.shared.play("coin")
                        Haptic.good()
                    } else {
                        message = "Es fehlen noch \(skin.price - app.save.coins) Münzen. Weiterspielen!"
                        Sfx.shared.play("wrong")
                        Haptic.bad()
                    }
                }) {
                    HStack(spacing: 5) { Text("\(skin.price)"); CoinGlyph(size: 18) }
                        .font(Theme.font(15))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(RoundedRectangle(cornerRadius: 10).fill(app.save.coins >= skin.price ? Color.yellow : Color.gray))
                }
                .buttonStyle(PressStyle())
            }
        }
        .padding(10)
        .neonCard(owned ? skin.swiftColor.opacity(0.9) : Color.white.opacity(0.2), radius: 18, glow: owned)
    }

    func equipButton(_ skin: Skin, _ card: Int) -> some View {
        let equipped = app.save.skinIds[card] == skin.id
        let col = Theme.seat[card]
        return Button(action: {
            app.equip(skin, card: card)
            Sfx.shared.play("click")
        }) {
            Text("\(card + 1)")
                .font(Theme.font(13))
                .foregroundColor(equipped ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 8).fill(equipped ? col : Color.white.opacity(0.1)))
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Stats

struct StatsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        let s = app.save
        VStack(spacing: 10) {
            TopBar(title: "STATISTIK")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        tile("gamecontroller.fill", "Spiele", "\(s.gamesPlayed)")
                        tile("medal.fill", "Siege", "\(s.wins)")
                        tile("trophy.fill", "Turniersiege", "\(s.tournamentsWon)")
                        tile("scope", "Tore", "\(s.goals)")
                        tile("brain.head.profile", "Quiz richtig", "\(s.quizCorrect)")
                        tile("hand.raised.fill", "Bälle", "\(s.balls)")
                        tile("target", "Treffer", "\(s.targetsHit)")
                        tile("bolt.fill", "Reaktion", s.bestReaction > 0 ? "\(s.bestReaction)ms" : "–")
                        tile("sparkles", "Spiele entdeckt", "\(s.playedKinds.count)/\(GameKind.allCases.count)")
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("REKORDE").font(Theme.font(15)).foregroundColor(Theme.orange)
                        ForEach(GameKind.allCases) { k in
                            HStack(spacing: 8) {
                                Image(systemName: k.symbol).font(.system(size: 14, weight: .heavy)).foregroundColor(k.accent).frame(width: 22)
                                Text(k.title).font(Theme.fontMed(14)).foregroundColor(.white).lineLimit(1)
                                Spacer()
                                if let b = s.best[k.rawValue] {
                                    Text("\(b) \(k.unit)").font(Theme.font(14)).foregroundColor(Theme.orange)
                                } else {
                                    Text("–").font(Theme.font(14)).foregroundColor(.white.opacity(0.35))
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(14)
                    .neonCard(Theme.orange.opacity(0.5), radius: 18, glow: false)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    func tile(_ icon: String, _ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: Sym.ok(icon)).font(.system(size: 20, weight: .heavy)).foregroundColor(Theme.blue)
            Text(value).font(Theme.font(20)).foregroundColor(.white).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(Theme.fontMed(10)).foregroundColor(.white.opacity(0.6)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .neonCard(Theme.blue.opacity(0.35), radius: 14, glow: false)
    }
}

// MARK: - Achievements and daily tasks

struct AchievementsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 10) {
            TopBar(title: "ERFOLGE")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HEUTE").font(Theme.font(16)).foregroundColor(Theme.orange)
                        ForEach(Daily.todaysTasks()) { t in taskRow(t) }
                        Text("Jeden Tag gibt es neue Aufgaben.")
                            .font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(14)
                    .neonCard(Theme.orange.opacity(0.6), radius: 18, glow: false)
                    Text("\(app.save.achievements.count) / \(Achievement.all.count) ERFOLGE")
                        .font(Theme.font(13)).foregroundColor(.white.opacity(0.6))
                    ForEach(Achievement.all) { a in achievementRow(a) }
                }
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    func taskRow(_ t: DailyTask) -> some View {
        let p = min(t.progress(app.save.daily), t.goal)
        let done = app.save.daily.claimed.contains(t.id)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(t.title).font(Theme.font(14)).foregroundColor(done ? Theme.green : .white)
                Spacer()
                coinReward(done, t.reward).foregroundColor(done ? Theme.green : .yellow)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(done ? Theme.green : Theme.orange)
                        .frame(width: g.size.width * CGFloat(p) / CGFloat(max(1, t.goal)))
                }
            }
            .frame(height: 8)
            Text("\(p) / \(t.goal)").font(Theme.fontMed(10)).foregroundColor(.white.opacity(0.5))
        }
    }

    func achievementRow(_ a: Achievement) -> some View {
        let got = app.save.achievements.contains(a.id)
        return HStack(spacing: 12) {
            Image(systemName: achievementSymbol(a.id)).font(.system(size: 26, weight: .heavy)).foregroundColor(got ? Theme.orange : Color.white.opacity(0.25)).frame(width: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(a.title).font(Theme.font(15)).foregroundColor(got ? .white : .white.opacity(0.55))
                Text(a.detail).font(Theme.fontMed(12)).foregroundColor(.white.opacity(0.5))
            }
            Spacer(minLength: 0)
            coinReward(got, a.reward).foregroundColor(got ? Theme.green : .yellow)
        }
        .padding(12)
        .neonCard(got ? Theme.orange : Color.white.opacity(0.15), radius: 16, glow: got)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var confirmReset = false

    var body: some View {
        VStack(spacing: 12) {
            TopBar(title: "EINSTELLUNGEN", showCoins: false)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    AccountCard()
                    VStack(spacing: 12) {
                        toggleRow("speaker.wave.2.fill", "Soundeffekte", get: { app.save.sound }) { v in app.update { $0.sound = v } }
                        toggleRow("music.note", "Musik", get: { app.save.music }) { v in app.update { $0.music = v } }
                        toggleRow("iphone.radiowaves.left.and.right", "Vibration", get: { app.save.haptics }) { v in app.update { $0.haptics = v } }
                    }
                    .padding(14)
                    .neonCard(Theme.orange.opacity(0.5), radius: 18, glow: false)

                    Button(action: { app.go(.setup) }) {
                        row("person.3.fill", "Spieler, Namen & CPU-Stärke")
                    }.buttonStyle(PressStyle())
                    Button(action: { app.go(.privacy) }) {
                        row("lock.shield.fill", "Datenschutz")
                    }.buttonStyle(PressStyle())

                    VStack(spacing: 6) {
                        Image("logo").resizable().scaledToFit().frame(height: 70)
                        Text("Grizzlys Arcade").font(Theme.font(17)).foregroundColor(.white)
                        Text("Die offizielle Spiele-App von Unihockey am Greifensee Grizzlys.")
                            .font(Theme.fontMed(12)).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") · Keine Werbung · Keine Echtgeld-Käufe · Kein Tracking")
                            .font(Theme.fontMed(11)).foregroundColor(.white.opacity(0.45)).multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .neonCard(Color.white.opacity(0.2), radius: 18, glow: false)

                    Button(action: { confirmReset = true }) {
                        Text("Fortschritt zurücksetzen")
                            .font(Theme.font(14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.55)))
                    }
                    .buttonStyle(PressStyle())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .alert("Fortschritt löschen?", isPresented: $confirmReset) {
            Button("Löschen", role: .destructive) { app.resetAll() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Münzen, Skins, Erfolge, Rekorde und Namen gehen verloren.")
        }
    }

    func toggleRow(_ icon: String, _ title: String, get: @escaping () -> Bool, set: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: get, set: { v in set(v); app.applyPrefs() })) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(Theme.orange).frame(width: 24)
                Text(title).font(Theme.font(16)).foregroundColor(.white)
            }
        }
        .tint(Theme.orange)
    }

    func row(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Theme.orange).frame(width: 24)
            Text(title).font(Theme.font(16)).foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.4))
        }
        .padding(16)
        .neonCard(Theme.orange.opacity(0.4), radius: 18, glow: false)
    }
}

// MARK: - Privacy (in-app copy of the privacy policy)

struct PrivacyView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 12) {
            TopBar(title: "DATENSCHUTZ", back: .settings, showCoins: false)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    section("Kurz gesagt", "Grizzlys Arcade gibt keine Daten an Server oder Dritte weiter. Es gibt keine Werbung, kein Tracking und keine In-App-Käufe.")
                    section("Anmeldung", "Du meldest dich mit Apple oder E-Mail an. Name und E-Mail-Adresse werden nur lokal auf diesem iPhone gespeichert und nicht an uns oder Dritte übertragen. Bei «Mit Apple anmelden» erhält die App nur die Daten, die du freigibst.")
                    section("Was auf deinem Gerät gespeichert wird", "Konto, Spielernamen, Münzen, freigeschaltete Skins, Rekorde, Erfolge und Einstellungen werden nur lokal auf diesem iPhone gespeichert. Diese Daten verlassen das Gerät nicht und werden nicht an uns oder Dritte übertragen.")
                    section("Internet", "Die App funktioniert komplett offline und baut keine Verbindung zu Servern auf.")
                    section("Kinder", "Die App ist für alle Altersgruppen geeignet. Es gibt keine Links nach aussen, keine Chats und keine Käufe.")
                    section("Löschen", "Unter Einstellungen → Konto löschen werden dein Konto und alle gespeicherten Daten entfernt. Auch durch Löschen der App verschwinden alle Daten.")
                    section("Kontakt", "Unihockey am Greifensee Grizzlys – Fragen zum Datenschutz richtest du an den Verein.")
                }
                .padding(16)
                .neonCard(Theme.orange.opacity(0.4), radius: 18, glow: false)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased()).font(Theme.font(13)).foregroundColor(Theme.orange)
            Text(text).font(Theme.fontMed(15)).foregroundColor(.white.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
        }
    }
}


/// "+20 [coin]" or a check mark when done.
func coinReward(_ done: Bool, _ reward: Int) -> some View {
    HStack(spacing: 4) {
        if done {
            Image(systemName: "checkmark").font(.system(size: 13, weight: .heavy))
        } else {
            Text("+\(reward)").font(Theme.font(13))
            CoinGlyph(size: 15)
        }
    }
}
