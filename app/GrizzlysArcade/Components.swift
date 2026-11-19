import SwiftUI
import SpriteKit

// MARK: - Styles

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Glowing neon card background
struct NeonCard: ViewModifier {
    var color: Color = Theme.orange
    var radius: CGFloat = 20
    var glow: Bool = true
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.panel, Theme.panel.opacity(0.75)], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(color.opacity(0.85), lineWidth: 1.5)
            )
            .shadow(color: glow ? color.opacity(0.35) : .clear, radius: 10)
    }
}

extension View {
    func neonCard(_ color: Color = Theme.orange, radius: CGFloat = 20, glow: Bool = true) -> some View {
        modifier(NeonCard(color: color, radius: radius, glow: glow))
    }
}

struct ArcadeButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = Theme.orange
    var textColor: Color = Color.black
    var height: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptic.tap()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    if Sym.has(icon) {
                        Image(systemName: icon).font(.system(size: height * 0.34, weight: .heavy))
                    } else {
                        Text(icon).font(.system(size: height * 0.42))
                    }
                }
                Text(title).font(Theme.font(height * 0.36)).tracking(1)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: height * 0.32, style: .continuous)
                    .fill(LinearGradient(colors: [color, color.opacity(0.78)], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: height * 0.32, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.55), radius: 12)
        }
        .buttonStyle(PressStyle())
    }
}

struct ArcadeBackground: View {
    @State private var spin = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.08, green: 0.06, blue: 0.16), Color(red: 0.02, green: 0.02, blue: 0.05)], startPoint: .top, endPoint: .bottom)
            GeometryReader { g in
                Path { p in
                    var x: CGFloat = 0
                    while x < g.size.width {
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: g.size.height))
                        x += 32
                    }
                    var y: CGFloat = 0
                    while y < g.size.height {
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: g.size.width, y: y))
                        y += 32
                    }
                }
                .stroke(Theme.orange.opacity(0.05), lineWidth: 1)
                Circle()
                    .fill(RadialGradient(colors: [Theme.orange.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: g.size.width * 0.7))
                    .frame(width: g.size.width * 1.4, height: g.size.width * 1.4)
                    .position(x: g.size.width * 0.5, y: g.size.height * 0.18)
                Circle()
                    .fill(RadialGradient(colors: [Theme.blue.opacity(0.14), .clear], center: .center, startRadius: 0, endRadius: g.size.width * 0.6))
                    .frame(width: g.size.width * 1.2, height: g.size.width * 1.2)
                    .position(x: g.size.width * 0.9, y: g.size.height * 0.85)
            }
            GeometryReader { g in
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: g.size.width * 1.3, height: g.size.width * 1.3)
                    .opacity(0.04)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 120).repeatForever(autoreverses: false), value: spin)
                    .position(x: g.size.width / 2, y: g.size.height / 2)
                    .onAppear { spin = true }
            }
        }
        .clipped()
        .ignoresSafeArea()
    }
}

struct CoinPill: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        HStack(spacing: 6) {
            CoinGlyph(size: 20)
            Text("\(app.save.coins)").font(Theme.font(17)).foregroundColor(Color.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.5)))
        .overlay(Capsule().stroke(Color.yellow.opacity(0.8), lineWidth: 1.5))
    }
}

struct TopBar: View {
    @EnvironmentObject var app: AppState
    let title: String
    var back: Screen = .hub
    var showCoins = true

    var body: some View {
        HStack(spacing: 10) {
            Button(action: { app.go(back) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                    .overlay(Circle().stroke(Theme.orange.opacity(0.7), lineWidth: 1.5))
            }
            .buttonStyle(PressStyle())
            Text(title).font(Theme.font(24)).foregroundColor(Color.white).lineLimit(1).minimumScaleFactor(0.6)
            Spacer()
            if showCoins { CoinPill() }
        }
    }
}

struct ToastView: View {
    let text: String
    var body: some View {
        VStack {
            Text(text)
                .font(Theme.font(15))
                .foregroundColor(Color.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Theme.orange))
                .overlay(Capsule().stroke(Color.white, lineWidth: 2))
                .shadow(color: Theme.orange.opacity(0.6), radius: 10)
            Spacer()
        }
        .padding(.top, 50)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
        .allowsHitTesting(false)
    }
}

/// Small coloured chip
struct Chip: View {
    let text: String
    var on: Bool
    var color: Color = Theme.orange
    let action: () -> Void
    var body: some View {
        Button(action: { Sfx.shared.play("click"); Haptic.tap(); action() }) {
            Text(text)
                .font(Theme.font(14))
                .foregroundColor(on ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(on ? color : Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(on ? Color.white.opacity(0.6) : color.opacity(0.4), lineWidth: 1))
                .shadow(color: on ? color.opacity(0.5) : .clear, radius: 8)
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Bear in SwiftUI

struct BearView: View {
    let skin: Skin
    var height: CGFloat = 100
    var flip: Bool = false

    var body: some View {
        let w = height * bearAspect
        ZStack {
            Image("bear_body")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(skin.isDark ? Color.white : Color(white: 0.1))
                .scaleEffect(1.07)
            Image("bear_body")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(skin.swiftColor)
            Image("bear_detail")
                .resizable()
            if skin.accessory == .crown {
                Image(systemName: Sym.ok("crown.fill", "star.fill"))
                    .foregroundColor(Color(red: 1, green: 0.82, blue: 0.2))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .font(.system(size: height * 0.28))
                    .offset(x: -w * 0.13, y: -height * 0.5)
            }
            if skin.accessory == .helmet {
                Image(systemName: Sym.ok("shield.fill"))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .font(.system(size: height * 0.24))
                    .offset(x: -w * 0.13, y: -height * 0.46)
            }
            Text("\(skin.number)")
                .font(Theme.font(height * 0.2))
                .foregroundColor(skin.isDark ? Theme.orange : Color(white: 0.1).opacity(0.85))
                .offset(x: w * 0.2 * (flip ? -1 : 1), y: height * 0.05)
        }
        .frame(width: w, height: height)
        .scaleEffect(x: flip ? -1 : 1, y: 1)
    }
}

// MARK: - SpriteKit container

struct SKContainer: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let v = SKView()
        v.isMultipleTouchEnabled = true
        v.preferredFramesPerSecond = 60
        v.backgroundColor = UIColor.black
        v.presentScene(scene)
        return v
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
    }
}

// MARK: - Confetti

struct Confetti: View {
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let colors: [Color] = ShopCatalog.palette(Cheer.id)
                for i in 0..<70 {
                    let seed = Double(i)
                    let x = (sin(seed * 12.9898) * 0.5 + 0.5) * Double(size.width) + sin(t * 2 + seed) * 14
                    let speed = 70 + (cos(seed * 78.233) * 0.5 + 0.5) * 120
                    let y = (t * speed + seed * 53).truncatingRemainder(dividingBy: Double(size.height) + 20) - 10
                    let rect = Path(CGRect(x: -4, y: -2, width: 8, height: 4))
                    ctx.drawLayer { layer in
                        layer.translateBy(x: CGFloat(x), y: CGFloat(y))
                        layer.rotate(by: Angle.radians(t * 3 + seed))
                        layer.fill(rect, with: .color(colors[i % colors.count]))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Game preview (screenshot of the real game, fallback gradient + emoji)

func safeAreaTop() -> CGFloat {
    let w = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    return max(20, w?.safeAreaInsets.top ?? 44)
}

func safeAreaBottom() -> CGFloat {
    let w = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    return max(10, w?.safeAreaInsets.bottom ?? 20)
}

struct GamePreview: View {
    let kind: GameKind
    var height: CGFloat = 90
    var corner: CGFloat = 18
    var badge: Bool = true

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        ZStack(alignment: .bottomLeading) {
            if let ui = UIImage(named: "prev_\(kind.rawValue)") {
                Color.black.overlay(
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                )
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
            } else {
                LinearGradient(colors: [kind.accent, kind.accent.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: kind.symbol).font(.system(size: height * 0.42, weight: .heavy)).foregroundColor(.white.opacity(0.9)).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if badge {
                GlyphTile(kind: kind, size: max(26, height * 0.3))
                    .padding(7)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(shape)
        .overlay(shape.stroke(kind.accent.opacity(0.9), lineWidth: 2))
        .shadow(color: kind.accent.opacity(0.35), radius: 10)
    }
}


// MARK: - Scroll container that fills the screen but scrolls when content is taller

struct ScrollFit<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ c: () -> Content) { content = c() }
    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                content.frame(minHeight: geo.size.height)
            }
        }
    }
}
