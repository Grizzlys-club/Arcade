import SwiftUI

@main
struct GrizzlysArcadeApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .preferredColorScheme(.dark)
                .onAppear { if SnapshotRunner.active { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { SnapshotRunner.run() } }; if SnapshotRunner.smoke { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { SnapshotRunner.runSmoke() } } }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            ArcadeBackground()
            if app.needsLogin {
                LoginView().transition(.opacity)
            } else {
            Group {
                switch app.screen {
                case .hub: HubView()
                case .setup: SetupView()
                case .picker: PickerView()
                case .tournamentSetup: TournamentSetupView()
                case .tournament: TournamentView()
                case .playing: GameHost()
                case .podium: PodiumView()
                case .shop: ShopView()
                case .stats: StatsView()
                case .achievements: AchievementsView()
                case .settings: SettingsView()
                case .privacy: PrivacyView()
                }
            }
            .transition(.opacity)
            }
            if let t = app.toast {
                ToastView(text: t)
            }
        }
        .onAppear { Sfx.shared.music(app.screen == .playing ? "game" : "menu") }
        .onChange(of: app.screen) { s in Sfx.shared.music(s == .playing ? "game" : "menu") }
    }
}
