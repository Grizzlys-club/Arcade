import SwiftUI

enum Screen {
    case hub, setup, picker, tournamentSetup, tournament, playing, podium, shop, stats, achievements, settings, privacy
}

struct TourEntry {
    var kind: GameKind
    var scores: [Int]
    var pts: [Int]
}

struct Tournament {
    var rounds: Int
    var played = 0
    var points: [Int]
    var wins: [Int]
    var log: [TourEntry] = []
    var bag: [GameKind] = []
    var next: GameKind? = nil

    var finished: Bool { return played >= rounds }
    var isFinal: Bool { return played == rounds - 1 }

    /// seat indices, best first
    var order: [Int] {
        return points.indices.sorted { a, b in
            if points[a] != points[b] { return points[a] > points[b] }
            if wins[a] != wins[b] { return wins[a] > wins[b] }
            return a < b
        }
    }
    /// 0-based place per seat (ties share)
    var places: [Int] {
        return points.indices.map { i in points.indices.filter { points[$0] > points[i] || (points[$0] == points[i] && wins[$0] > wins[i]) }.count }
    }
}

struct RewardInfo {
    var coins = 0
    var ranks: [Int] = []
    var pts: [Int] = []
    var messages: [String] = []
    var newBest = false
    var xp = 0
    var level = 0
}

final class AppState: ObservableObject {
    @Published var screen: Screen = .hub
    @Published var save: SaveData
    @Published var account: Account? = AppState.loadAccount()
    let skipLogin = launchArgs.contains { ["-game", "-tournament", "-screen", "-intro", "-wheel", "-skiplogin"].contains($0) }
    @Published var current: GameKind = .penalty
    @Published var tournament: Tournament? = nil
    @Published var toast: String? = nil
    /// Set by launch arguments for automated tests (all seats CPU)
    var autoplay = false
    @Published var autoKick = false
    var autoplayCount = 2

    private let key = "grizzlys.save.v2"
    static let cpuNames = ["Brummi", "Tatze", "Honig", "Pelzi"]

    init() {
        if let d = UserDefaults.standard.data(forKey: "grizzlys.save.v2"),
           let s = try? JSONDecoder().decode(SaveData.self, from: d) {
            save = s
        } else {
            save = SaveData()
        }
        applyPrefs()
        rollDaily()
        readLaunchArgs()
    }

    private func readLaunchArgs() {
        let args = launchArgs
        func value(_ k: String) -> String? {
            if let i = args.firstIndex(of: k), i + 1 < args.count { return args[i + 1] }
            return nil
        }
        if let p = value("-players"), let n = Int(p) { autoplayCount = max(2, min(4, n)) }
        if let d = value("-difficulty"), let n = Int(d) { save.difficulty = max(0, min(4, n)) }
        if let g = value("-game"), let k = GameKind(rawValue: g) {
            autoplay = true
            current = k
            screen = .playing
        } else if let r = value("-tournament"), let rounds = Int(r) {
            autoplay = true
            startTournament(rounds: rounds)
        } else if let g = value("-intro"), let k = GameKind(rawValue: g) {
            current = k
            screen = .playing
        } else if let sc = value("-screen") {
            let map: [String: Screen] = ["setup": .setup, "picker": .picker, "shop": .shop, "stats": .stats, "achievements": .achievements, "settings": .settings, "tsetup": .tournamentSetup, "privacy": .privacy]
            if let s = map[sc] { screen = s }
        }
    }

    // MARK: persistence

    func persist() {
        if autoplay { return }
        if let d = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(d, forKey: key)
            if account != nil && d.count < 500_000 {
                NSUbiquitousKeyValueStore.default.set(d, forKey: "ga.save.v1")
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }

    func update(_ f: (inout SaveData) -> Void) {
        var s = save
        f(&s)
        save = s
        persist()
    }

    func applyPrefs() {
        Sfx.shared.enabled = save.sound
        Sfx.shared.musicEnabled = save.music
        Haptic.enabled = save.haptics
        Cheer.id = save.cheerId
    }

    func rollDaily() {
        let today = Daily.todayKey()
        if save.daily.date != today {
            update { $0.daily = DailyState(date: today) }
        }
        updateStreak(today)
    }

    // MARK: streak, wheel, items

    private func dayKey(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    func updateStreak(_ today: String) {
        if autoplay || save.lastLogin == today { return }
        let yesterday = dayKey(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        update { s in
            s.streak = (s.lastLogin == yesterday) ? s.streak + 1 : 1
            s.lastLogin = today
        }
    }

    var canSpinWheel: Bool { return save.lastWheel != Daily.todayKey() }
    var streakBonus: Int { return min(max(save.streak, 1), 7) * 5 }

    func claimWheel(prizeIndex: Int) {
        let p = Wheel.prizes[prizeIndex]
        update { $0.lastWheel = Daily.todayKey() }
        switch p.kind {
        case .coins: addCoins(p.amount)
        case .xp: addXP(p.amount)
        case .boost: update { $0.coinBoost += p.amount }
        }
        addCoins(streakBonus)
    }

    /// Adds XP and returns messages for level ups (with coin reward)
    @discardableResult
    func addXP(_ n: Int) -> [String] {
        let before = Level.info(save.xp).level
        update { $0.xp += n }
        let after = Level.info(save.xp).level
        var out: [String] = []
        if after > before {
            for l in (before + 1)...after {
                addCoins(20 + l * 5)
                out.append("Level \(l): \(Level.rankName(l)) +\(20 + l * 5) Münzen")
            }
            showToast(out.last ?? "")
        }
        return out
    }

    func buyItem(_ item: ShopItem) -> Bool {
        if item.kind != .boost && (save.items.contains(item.id) || item.price == 0) { return true }
        if save.coins < item.price { return false }
        update { s in
            s.coins -= item.price
            switch item.kind {
            case .boost:
                if item.id == "coin2" { s.coinBoost += 10 } else { s.xpBoost += 10 }
            default:
                s.items.append(item.id)
            }
        }
        return true
    }

    func owns(_ item: ShopItem) -> Bool { return item.price == 0 || save.items.contains(item.id) }

    func equipItem(_ item: ShopItem) {
        update { s in
            if item.kind == .title { s.titleId = item.id }
            if item.kind == .cheer { s.cheerId = item.id }
        }
        Cheer.id = save.cheerId
    }

    // MARK: players

    /// Card indices (0...3) that take part, in seat order
    var activeCards: [Int] {
        if autoplay { return Array(0..<autoplayCount) }
        return (0..<4).filter { save.slots[$0] != .off }
    }

    var playerCount: Int { return activeCards.count }
    var humanCount: Int { return activeCards.filter { !isCPU(card: $0) }.count }

    func isCPU(card: Int) -> Bool {
        if autoplay { return true }
        return save.slots[card] == .cpu
    }

    func name(card: Int) -> String {
        if isCPU(card: card) { return AppState.cpuNames[card] }
        let n = save.names[card].trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "Spieler \(card + 1)" : n
    }

    func skin(card: Int) -> Skin { return Skin.find(save.skinIds[card]) }

    /// Seat setups for a new match, in seat order
    func seatSetups() -> [SeatSetup] {
        return activeCards.map { SeatSetup(name: name(card: $0), skin: skin(card: $0), isCPU: isCPU(card: $0)) }
    }

    /// name / color for seat index i
    func seatName(_ i: Int) -> String {
        let c = activeCards
        return i < c.count ? name(card: c[i]) : "?"
    }

    func seatSkin(_ i: Int) -> Skin {
        let c = activeCards
        return i < c.count ? skin(card: c[i]) : Skin.classic
    }

    func seatIsCPU(_ i: Int) -> Bool {
        let c = activeCards
        return i < c.count ? isCPU(card: c[i]) : true
    }

    func setSlot(_ card: Int, _ mode: SlotMode) {
        var slots = save.slots
        slots[card] = mode
        if slots.filter({ $0 != .off }).count < 2 { return }
        update { $0.slots = slots }
    }

    func showToast(_ s: String) {
        toast = s
        Sfx.shared.play("coin")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            if self?.toast == s { self?.toast = nil }
        }
    }

    func addCoins(_ n: Int) {
        update { $0.coins += n; $0.totalCoins += n }
    }

    // MARK: navigation

    func go(_ s: Screen) {
        Sfx.shared.play("click")
        Haptic.tap()
        withAnimation(.easeInOut(duration: 0.25)) { screen = s }
    }

    func startGame(_ k: GameKind) {
        tournament = nil
        current = k
        go(.playing)
    }

    func startTournament(rounds: Int) {
        let n = playerCount
        var t = Tournament(rounds: rounds, points: Array(repeating: 0, count: n), wins: Array(repeating: 0, count: n))
        t.next = drawGame(&t)
        tournament = t
        if !autoplay { update { $0.rounds = rounds } }
        screen = .tournament
    }

    private func drawGame(_ t: inout Tournament) -> GameKind {
        let n = playerCount
        if t.bag.isEmpty {
            let last = t.log.last?.kind
            t.bag = GameKind.allCases.filter { $0.supports(n) && $0 != last }.shuffled()
        }
        return t.bag.removeFirst()
    }

    func playTournamentGame() {
        guard let t = tournament, let k = t.next, !t.finished else { return }
        current = k
        go(.playing)
    }

    func afterTournamentGame() {
        guard var t = tournament else { go(.picker); return }
        if t.finished {
            finishTournament()
            return
        }
        t.next = drawGame(&t)
        tournament = t
        go(.tournament)
    }

    func finishTournament() {
        guard let t = tournament else { return }
        let places = t.places
        let humanWon = places.indices.contains { places[$0] == 0 && !seatIsCPU($0) }
        if humanCount > 0 && !autoplay {
            update { s in
                s.tournamentsPlayed += 1
                if humanWon { s.tournamentsWon += 1 }
            }
            addCoins(humanWon ? 30 + 5 * t.rounds : 10)
            _ = checkAchievements()
        }
        go(.podium)
    }

    // MARK: results

    func record(_ r: GameResult, kind: GameKind) -> RewardInfo {
        var info = RewardInfo()
        rollDaily()
        let ranks = Ranking.ranks(r.scores)
        info.ranks = ranks
        let humanSeats = r.scores.indices.filter { !seatIsCPU($0) }
        let humanWon = humanSeats.contains { ranks[$0] == 0 } && r.scores.count > 1
        let bestHuman = humanSeats.map { r.scores[$0] }.max() ?? 0
        var isBest = false
        if !humanSeats.isEmpty && !autoplay {
            update { s in
                s.gamesPlayed += 1
                if humanWon { s.wins += 1 }
                s.goals += r.stats["goals"] ?? 0
                s.balls += r.stats["balls"] ?? 0
                s.quizCorrect += r.stats["quiz"] ?? 0
                s.targetsHit += r.stats["hits"] ?? 0
                let rt = r.stats["reaction"] ?? 0
                if rt > 0 && (s.bestReaction == 0 || rt < s.bestReaction) { s.bestReaction = rt }
                let old = s.best[kind.rawValue] ?? 0
                if bestHuman > old {
                    s.best[kind.rawValue] = bestHuman
                    isBest = old > 0
                }
                if !s.playedKinds.contains(kind.rawValue) { s.playedKinds.append(kind.rawValue) }
                s.daily.games += 1
                if humanWon { s.daily.wins += 1 }
                s.daily.goals += r.stats["goals"] ?? 0
                s.daily.balls += r.stats["balls"] ?? 0
                s.daily.quiz += r.stats["quiz"] ?? 0
                if !s.daily.kinds.contains(kind.rawValue) { s.daily.kinds.append(kind.rawValue) }
            }
            var coins = 4 + (humanWon ? 6 : 0)
            if save.coinBoost > 0 {
                coins *= 2
                update { $0.coinBoost -= 1 }
            }
            addCoins(coins)
            info.coins = coins
            var xp = 14 + (humanWon ? 18 : 0) + (tournament != nil ? 6 : 0)
            if save.xpBoost > 0 {
                xp *= 2
                update { $0.xpBoost -= 1 }
            }
            info.xp = xp
            info.messages.append(contentsOf: addXP(xp))
        }
        info.newBest = isBest

        if var t = tournament {
            var pts = Ranking.points(r.scores)
            if t.isFinal { pts = pts.map { $0 * 2 } }
            for i in pts.indices where i < t.points.count {
                t.points[i] += pts[i]
                if ranks[i] == 0 { t.wins[i] += 1 }
            }
            t.log.append(TourEntry(kind: kind, scores: r.scores, pts: pts))
            t.played += 1
            tournament = t
            info.pts = pts
        }

        if !autoplay {
            info.messages.append(contentsOf: checkAchievements())
            info.messages.append(contentsOf: checkDaily())
        }
        return info
    }

    func checkAchievements() -> [String] {
        var out: [String] = []
        for a in Achievement.all {
            if !save.achievements.contains(a.id) && a.check(save) {
                update { $0.achievements.append(a.id) }
                addCoins(a.reward)
                out.append("Erfolg: \(a.title) +\(a.reward)")
            }
        }
        if let first = out.first { showToast(first) }
        return out
    }

    func checkDaily() -> [String] {
        var out: [String] = []
        for t in Daily.todaysTasks() {
            if t.progress(save.daily) >= t.goal && !save.daily.claimed.contains(t.id) {
                update { $0.daily.claimed.append(t.id) }
                addCoins(t.reward)
                out.append("Tagesaufgabe: \(t.title) +\(t.reward)")
            }
        }
        return out
    }

    // MARK: shop

    func buy(_ skin: Skin) -> Bool {
        if save.unlocked.contains(skin.id) { return true }
        if save.coins < skin.price { return false }
        update { s in
            s.coins -= skin.price
            s.unlocked.append(skin.id)
        }
        _ = checkAchievements()
        return true
    }

    func equip(_ skin: Skin, card: Int) {
        update { $0.skinIds[card] = skin.id }
    }

    func resetAll() {
        save = SaveData()
        persist()
        applyPrefs()
        rollDaily()
    }
}
