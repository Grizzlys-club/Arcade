import SwiftUI

/// First-launch tour (3 pages). Stored with @AppStorage so it only shows once.
struct WelcomeView: View {
    @Binding var show: Bool
    @State private var page = 0

    var body: some View {
        ZStack {
            ArcadeBackground()
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                TabView(selection: $page) {
                    pageOne.tag(0)
                    pageTwo.tag(1)
                    pageThree.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                ArcadeButton(title: page < 2 ? "WEITER" : "LOS GEHT'S", icon: page < 2 ? nil : "bolt.fill", height: 58) {
                    if page < 2 {
                        withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) { show = false }
                    }
                }
                Button(action: { withAnimation { show = false } }) {
                    Text("Überspringen").font(Theme.fontMed(14)).foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, safeAreaTop() + 10)
            .padding(.bottom, safeAreaBottom() + 10)
        }
        .transition(.opacity)
    }

    func slide(_ hero: AnyView, _ title: String, _ text: String) -> some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            hero
            Text(title)
                .font(Theme.font(30))
                .foregroundColor(Theme.orange)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            Text(text)
                .font(Theme.fontMed(17))
                .foregroundColor(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 6)
    }

    var pageOne: some View {
        slide(AnyView(
            Image("logo").resizable().scaledToFit().frame(height: 170)
                .shadow(color: Theme.orange.opacity(0.8), radius: 20)
        ), "WILLKOMMEN BEI DEN GRIZZLYS", "Die Arcade vom Unihockey-Club am Greifensee: schnelle Minispiele für dich und deine Kollegen.")
    }

    var pageTwo: some View {
        slide(AnyView(
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.seat[i].opacity(0.85))
                        .frame(width: 52, height: 90)
                        .overlay(Text("\(i + 1)").font(Theme.font(26)).foregroundColor(.black))
                        .shadow(color: Theme.seat[i].opacity(0.6), radius: 10)
                }
            }
        ), "BIS ZU 4 AN EINEM HANDY", "Leg das Handy in die Mitte. Jeder spielt von seiner Seite aus: zu zweit gegenüber, zu viert in den Ecken. Einzelspieler üben gegen CPU-Bären.")
    }

    var pageThree: some View {
        slide(AnyView(
            HStack(spacing: 14) {
                Image(systemName: Sym.ok("trophy.fill")).font(.system(size: 56, weight: .heavy)).foregroundColor(Color(red: 1, green: 0.82, blue: 0.2))
                CoinGlyph(size: 58)
                BearView(skin: Skin.find("orange"), height: 70, flip: true)
            }
        ), "TURNIER, MÜNZEN, SKINS", "Spiele ein Turnier mit Zufallsspielen und kämpfe um den Pokal. Sammle Münzen und schalte neue Bären-Skins frei.")
    }
}
