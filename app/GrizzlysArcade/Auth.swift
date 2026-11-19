import SwiftUI

// MARK: - Account (stored locally on the device only)

struct Account: Codable {
    var provider: String   // "apple" | "email"
    var id: String
    var name: String
    var email: String

    var providerLabel: String { "iCloud" }
}

extension AppState {
    static let accountKey = "ga.account.v1"

    static func loadAccount() -> Account? {
        guard let d = UserDefaults.standard.data(forKey: accountKey) else { return nil }
        return try? JSONDecoder().decode(Account.self, from: d)
    }

    func signIn(_ a: Account) {
        if let d = try? JSONEncoder().encode(a) {
            UserDefaults.standard.set(d, forKey: AppState.accountKey)
        }
        let first = a.name.trimmingCharacters(in: .whitespaces)
        update { s in
            if !first.isEmpty && (s.names[0] == "Spieler 1" || s.names[0].isEmpty) {
                s.names[0] = String(first.prefix(10))
            }
        }
        if let d = NSUbiquitousKeyValueStore.default.data(forKey: "ga.save.v1"),
           let restored = try? JSONDecoder().decode(SaveData.self, from: d), restored.xp > save.xp {
            save = restored
            persist()
        }
        withAnimation(.easeInOut(duration: 0.3)) { account = a }
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: AppState.accountKey)
        withAnimation(.easeInOut(duration: 0.3)) {
            account = nil
            screen = .hub
        }
    }

    /// Deletes the account and all progress stored on this device
    func deleteAccount() {
        resetAll()
        signOut()
    }

    var needsLogin: Bool { return false }
}

// MARK: - Login screen

struct LoginView: View {
    @EnvironmentObject var app: AppState
    @State private var showEmail = false
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var glow = false

    var body: some View {
        ZStack {
            ArcadeBackground()
            Color.black.opacity(0.35).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer(minLength: 20)
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Theme.orange.opacity(glow ? 0.55 : 0.3), .clear], center: .center, startRadius: 10, endRadius: 130))
                            .frame(width: 270, height: 270)
                        Image("logo").resizable().scaledToFit().frame(height: 170)
                            .shadow(color: Theme.orange.opacity(0.8), radius: glow ? 22 : 10)
                    }
                    .frame(height: 190)
                    VStack(spacing: 2) {
                        Text("GRIZZLYS").font(Theme.font(44)).foregroundColor(Theme.orange).shadow(color: Theme.orange.opacity(0.8), radius: 12)
                        Text("ARCADE").font(Theme.font(20)).foregroundColor(.white).tracking(12)
                    }
                    Text("Verbinde dich mit iCloud, damit dein Fortschritt gespeichert bleibt.")
                        .font(Theme.fontMed(16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)

                    field("person.fill", "Dein Name (optional)", text: $name, keyboard: .default)

                    Button(action: { connectICloud() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "icloud.fill").font(.system(size: 20, weight: .heavy))
                            Text("MIT ICLOUD VERBINDEN").font(Theme.font(18))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.orange))
                    }
                    .buttonStyle(PressStyle())

                    if !message.isEmpty {
                        Text(message)
                            .font(Theme.fontMed(13))
                            .foregroundColor(Theme.orange)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("Dein Fortschritt wird in deinem privaten iCloud-Speicher gesichert. Details unter Einstellungen → Datenschutz.")
                        .font(Theme.fontMed(11))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, safeAreaTop() * 0.4)
                .padding(.bottom, safeAreaBottom())
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    func field(_ icon: String, _ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Theme.orange).frame(width: 22)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(true)
                .font(Theme.fontMed(17))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.4)))
    }

    func connectICloud() {
        let n = name.trimmingCharacters(in: .whitespaces)
        var id = "local"
        if let t = FileManager.default.ubiquityIdentityToken { id = "icloud-\(t.hash)" }
        else { message = "iCloud ist auf diesem Gerät nicht angemeldet. Dein Fortschritt bleibt vorerst nur hier gespeichert." }
        Haptic.good()
        app.signIn(Account(provider: "icloud", id: id, name: n.isEmpty ? "Bär" : n, email: ""))
    }
}

// MARK: - Account card (settings)

struct AccountCard: View {
    @EnvironmentObject var app: AppState
    @State private var confirmDelete = false

    var body: some View {
        if let a = app.account {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [Theme.orange, Color(red: 1, green: 0.35, blue: 0.1)], startPoint: .top, endPoint: .bottom))
                        Text(String(a.name.prefix(1)).uppercased()).font(Theme.font(22)).foregroundColor(.black)
                    }
                    .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.name).font(Theme.font(18)).foregroundColor(.white).lineLimit(1)
                        Text(a.email.isEmpty ? "Angemeldet mit \(a.providerLabel)" : a.email)
                            .font(Theme.fontMed(12)).foregroundColor(.white.opacity(0.6)).lineLimit(1)
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    Button(action: { app.signOut() }) {
                        Text("Abmelden").font(Theme.font(14)).foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    }
                    .buttonStyle(PressStyle())
                    Button(action: { confirmDelete = true }) {
                        Text("Konto löschen").font(Theme.font(14)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.6)))
                    }
                    .buttonStyle(PressStyle())
                }
            }
            .padding(14)
            .neonCard(Theme.orange.opacity(0.5), radius: 18, glow: false)
            .alert("Konto löschen?", isPresented: $confirmDelete) {
                Button("Konto löschen", role: .destructive) { app.deleteAccount() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Dein Konto sowie Münzen, Skins, Rekorde und alle Daten auf diesem Gerät werden gelöscht.")
            }
        }
    }
}
