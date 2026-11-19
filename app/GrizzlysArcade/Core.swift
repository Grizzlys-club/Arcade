import SpriteKit
import UIKit

// MARK: - Global scene metrics (portrait)

/// Logical scene width. Height adapts to the device aspect ratio (set by GameHost before a scene is built).
let launchArgs: [String] = {
    #if DEBUG
    return CommandLine.arguments
    #else
    return []
    #endif
}()

let SW: CGFloat = 390
var SH: CGFloat = 844
/// Middle HUD band (timer / pause) for the zones layout
let bandH: CGFloat = 40
/// Keep clear of notch / home indicator
let topInset: CGFloat = 36
let bottomInset: CGFloat = 22
let bearAspect: CGFloat = 918.0 / 777.0

// MARK: - Seeded random (all players get the same sequence = fair)

final class Rand {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    /// 0..<1
    func double() -> Double { return Double(next() >> 11) / Double(1 << 53) }
    func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat { return a + CGFloat(double()) * (b - a) }
    /// inclusive
    func int(_ a: Int, _ b: Int) -> Int { return a + Int(next() % UInt64(b - a + 1)) }
    func chance(_ p: Double) -> Bool { return double() < p }
    func pick<T>(_ arr: [T]) -> T { return arr[int(0, arr.count - 1)] }
    func shuffled<T>(_ arr: [T]) -> [T] {
        var a = arr
        if a.count < 2 { return a }
        for i in stride(from: a.count - 1, to: 0, by: -1) {
            let j = int(0, i)
            a.swapAt(i, j)
        }
        return a
    }
}

// MARK: - Bear

/// The Grizzlys bear cut out of the club logo. Origin of the node = the bear's feet.
final class BearNode: SKNode {
    let visual = SKNode()
    let height: CGFloat
    private var numberLabel: SKLabelNode?

    init(skin: Skin, height: CGFloat, faceRight: Bool) {
        self.height = height
        super.init()
        let w = height * bearAspect

        let sh = SKSpriteNode(texture: Gfx.shadow, size: CGSize(width: w * 0.85, height: height * 0.22))
        sh.position = CGPoint(x: 0, y: 2)
        sh.zPosition = -2
        addChild(sh)

        addChild(visual)
        let bodyTex = SKTexture(imageNamed: "bear_body")
        let detailTex = SKTexture(imageNamed: "bear_detail")

        let outline = SKSpriteNode(texture: bodyTex, size: CGSize(width: w * 1.07, height: height * 1.07))
        outline.anchorPoint = CGPoint(x: 0.5, y: 0.03)
        outline.color = skin.isDark ? UIColor.white : UIColor(white: 0.1, alpha: 1)
        outline.colorBlendFactor = 1
        outline.zPosition = 0
        visual.addChild(outline)

        let body = SKSpriteNode(texture: bodyTex, size: CGSize(width: w, height: height))
        body.anchorPoint = CGPoint(x: 0.5, y: 0)
        body.color = skin.color
        body.colorBlendFactor = 1
        body.zPosition = 1
        visual.addChild(body)

        let detail = SKSpriteNode(texture: detailTex, size: CGSize(width: w, height: height))
        detail.anchorPoint = CGPoint(x: 0.5, y: 0)
        detail.zPosition = 2
        visual.addChild(detail)

        let num = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        num.text = "\(skin.number)"
        num.fontSize = height * 0.2
        num.fontColor = skin.isDark ? Theme.uiOrange : UIColor(white: 0.1, alpha: 0.85)
        num.verticalAlignmentMode = .center
        num.position = CGPoint(x: w * 0.2, y: height * 0.55)
        num.zPosition = 3
        visual.addChild(num)
        numberLabel = num

        addAccessory(skin.accessory, w: w, h: height)
        setFacing(right: faceRight)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func addAccessory(_ acc: Accessory, w: CGFloat, h: CGFloat) {
        let hx = -0.12 * w
        switch acc {
        case .none:
            break
        case .crown:
            let path = UIBezierPath()
            let cw = w * 0.2
            let ch = h * 0.13
            path.move(to: CGPoint(x: -cw / 2, y: 0))
            path.addLine(to: CGPoint(x: -cw / 2, y: ch))
            path.addLine(to: CGPoint(x: -cw / 4, y: ch * 0.6))
            path.addLine(to: CGPoint(x: 0, y: ch * 1.1))
            path.addLine(to: CGPoint(x: cw / 4, y: ch * 0.6))
            path.addLine(to: CGPoint(x: cw / 2, y: ch))
            path.addLine(to: CGPoint(x: cw / 2, y: 0))
            path.close()
            let s = SKShapeNode(path: path.cgPath)
            s.fillColor = UIColor(red: 1, green: 0.84, blue: 0.1, alpha: 1)
            s.strokeColor = UIColor(red: 0.6, green: 0.4, blue: 0, alpha: 1)
            s.lineWidth = 2
            s.position = CGPoint(x: hx, y: h * 0.93)
            s.zRotation = 0.15
            s.zPosition = 4
            visual.addChild(s)
        case .headband:
            let s = SKShapeNode(rectOf: CGSize(width: w * 0.26, height: h * 0.05), cornerRadius: 3)
            s.fillColor = UIColor.white
            s.strokeColor = Theme.uiOrange
            s.lineWidth = 2
            s.position = CGPoint(x: hx, y: h * 0.86)
            s.zRotation = -0.12
            s.zPosition = 4
            visual.addChild(s)
        case .helmet:
            let s = SKShapeNode(ellipseOf: CGSize(width: w * 0.27, height: h * 0.16))
            s.fillColor = UIColor(white: 0.95, alpha: 1)
            s.strokeColor = UIColor(white: 0.2, alpha: 1)
            s.lineWidth = 2
            s.position = CGPoint(x: hx, y: h * 0.93)
            s.zRotation = -0.05
            s.zPosition = 4
            visual.addChild(s)
        }
    }

    func setFacing(right: Bool) {
        // the artwork walks to the left
        visual.xScale = right ? -1 : 1
        numberLabel?.xScale = right ? -1 : 1
    }

    var facingRight: Bool { return visual.xScale < 0 }

    func startBob(amount: CGFloat = 3, duration: Double = 0.35) {
        visual.removeAction(forKey: "bob")
        let up = SKAction.moveBy(x: 0, y: amount, duration: duration)
        up.timingMode = .easeInEaseOut
        visual.run(SKAction.repeatForever(SKAction.sequence([up, up.reversed()])), withKey: "bob")
    }

    func stopBob() {
        visual.removeAction(forKey: "bob")
        visual.position = .zero
    }

    func startRun(speed: Double = 0.14) {
        visual.removeAction(forKey: "run")
        let a = SKAction.rotate(toAngle: 0.07, duration: speed)
        let b = SKAction.rotate(toAngle: -0.07, duration: speed)
        let hop = SKAction.sequence([SKAction.moveBy(x: 0, y: 5, duration: speed), SKAction.moveBy(x: 0, y: -5, duration: speed)])
        visual.run(SKAction.repeatForever(SKAction.group([SKAction.sequence([a, b]), SKAction.sequence([hop, hop])])), withKey: "run")
    }

    func stopRun() {
        visual.removeAction(forKey: "run")
        visual.zRotation = 0
        visual.position = .zero
    }

    func squash() {
        visual.run(SKAction.sequence([SKAction.scaleY(to: 0.85, duration: 0.06), SKAction.scaleY(to: 1.0, duration: 0.1)]), withKey: "squash")
    }

    func celebrate() {
        let up = SKAction.moveBy(x: 0, y: 18, duration: 0.16)
        up.timingMode = .easeOut
        run(SKAction.repeat(SKAction.sequence([up, up.reversed()]), count: 4), withKey: "cel")
    }
}

// MARK: - Layout

/// How the portrait screen is divided. Each game picks the layout that suits it.
enum SeatLayout {
    /// Every player gets an own playing field. 2 players: bottom / top half. 3-4: quarters.
    case zones
    /// One shared field in the middle, every player has a control strip on an edge
    /// (bottom, top, left, right). Good for Air-Hockey, Sumo, Hot Puck, Territory ...
    case arena
    /// One full-screen field, the players take turns one after another.
    case turns
}

/// Which screen edge a seat sits at (its "down" direction)
enum SeatEdge {
    case bottom, top, left, right
}

struct SeatSetup {
    var name: String
    var skin: Skin
    var isCPU: Bool
}

// MARK: - Seat

final class Seat {
    let index: Int
    let name: String
    let skin: Skin
    let isCPU: Bool
    let color: UIColor
    /// 0.0 ... 1.0, how well a CPU plays (use it to scale reaction time / accuracy)
    let skill: Double
    let edge: SeatEdge
    /// Size in local coordinates. Local origin = zone centre, +y points AWAY from the player's edge (towards the screen centre),
    /// +x is the player's right. So the player's own edge is at y = -size.height/2.
    let size: CGSize
    /// Zone in scene coordinates (touches inside belong to this seat)
    let zone: CGRect
    let rotation: CGFloat
    /// Rotated container (not clipped): HUD, banners
    let node = SKNode()
    /// Rotated and clipped to the zone: put the game content here
    let field = SKCropNode()
    var score = 0
    var alive = true
    var scoreLabel: SKLabelNode?
    weak var scene: MiniScene?

    init(index: Int, setup: SeatSetup, skill: Double, edge: SeatEdge, zone: CGRect) {
        self.index = index
        self.name = setup.name
        self.skin = setup.skin
        self.isCPU = setup.isCPU
        self.color = Theme.seatUI[index % 4]
        self.skill = skill
        self.edge = edge
        self.zone = zone
        switch edge {
        case .bottom:
            rotation = 0
            size = zone.size
        case .top:
            rotation = .pi
            size = zone.size
        case .left:
            rotation = -.pi / 2
            size = CGSize(width: zone.height, height: zone.width)
        case .right:
            rotation = .pi / 2
            size = CGSize(width: zone.height, height: zone.width)
        }
        node.position = CGPoint(x: zone.midX, y: zone.midY)
        node.zRotation = rotation
        let mask = SKSpriteNode(color: .white, size: size)
        field.maskNode = mask
        node.addChild(field)
    }

    var w: CGFloat { return size.width }
    var h: CGFloat { return size.height }
    var center: CGPoint { return CGPoint(x: zone.midX, y: zone.midY) }

    /// Scene point -> local point
    func local(_ p: CGPoint) -> CGPoint {
        let dx = p.x - zone.midX
        let dy = p.y - zone.midY
        let c = cos(-rotation)
        let s = sin(-rotation)
        return CGPoint(x: dx * c - dy * s, y: dx * s + dy * c)
    }

    /// Local point -> scene point
    func toScene(_ l: CGPoint) -> CGPoint {
        let c = cos(rotation)
        let s = sin(rotation)
        return CGPoint(x: zone.midX + l.x * c - l.y * s, y: zone.midY + l.x * s + l.y * c)
    }

    /// Local direction -> scene direction
    func dirToScene(_ v: CGVector) -> CGVector {
        let c = cos(rotation)
        let s = sin(rotation)
        return CGVector(dx: v.dx * c - v.dy * s, dy: v.dx * s + v.dy * c)
    }

    func contains(local p: CGPoint) -> Bool {
        return abs(p.x) <= w / 2 && abs(p.y) <= h / 2
    }

    // MARK: effects in local coordinates

    func floatText(_ text: String, at p: CGPoint, color: UIColor = .white, size: CGFloat = 22) {
        let l = MiniScene.label(text, size: size, color: color)
        l.position = p
        l.zPosition = 300
        node.addChild(l)
        l.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: 40, duration: 0.7), SKAction.sequence([SKAction.wait(forDuration: 0.35), SKAction.fadeOut(withDuration: 0.35)])]),
            SKAction.removeFromParent()
        ]))
    }

    func burst(at p: CGPoint, color: UIColor, count: Int = 10, speed: CGFloat = 120) {
        for _ in 0..<count {
            let s = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 7, height: 7))
            s.color = color
            s.colorBlendFactor = 1
            s.blendMode = .add
            s.position = p
            s.zPosition = 250
            field.addChild(s)
            let a = CGFloat.random(in: 0..<(2 * CGFloat.pi))
            let d = CGFloat.random(in: 0.4...1.0) * speed
            s.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(a) * d, y: sin(a) * d, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.2, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    /// Big text in the middle of this seat, readable for this player
    func banner(_ text: String, color: UIColor? = nil, size: CGFloat = 44, duration: Double = 0.8) {
        let l = MiniScene.label(text, size: min(size, w * 0.16 + 14), color: color ?? self.color)
        l.zPosition = 700
        l.setScale(0.3)
        node.addChild(l)
        l.run(SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.wait(forDuration: duration),
            SKAction.group([SKAction.fadeOut(withDuration: 0.2), SKAction.scale(to: 1.3, duration: 0.2)]),
            SKAction.removeFromParent()
        ]))
    }

    func flash(_ color: UIColor, alpha: CGFloat = 0.45, duration: Double = 0.35) {
        let f = SKSpriteNode(color: color, size: size)
        f.alpha = alpha
        f.zPosition = 600
        node.addChild(f)
        f.run(SKAction.sequence([SKAction.fadeOut(withDuration: duration), SKAction.removeFromParent()]))
    }

    func shake(_ amt: CGFloat = 5) {
        field.removeAction(forKey: "shake")
        field.position = .zero
        var acts: [SKAction] = []
        for _ in 0..<5 {
            acts.append(SKAction.move(to: CGPoint(x: CGFloat.random(in: -amt...amt), y: CGFloat.random(in: -amt...amt)), duration: 0.03))
        }
        acts.append(SKAction.move(to: .zero, duration: 0.03))
        field.run(SKAction.sequence(acts), withKey: "shake")
    }

    /// Mark the seat as out (dims the zone, shows OUT)
    func knockOut(_ text: String = "RAUS") {
        if !alive { return }
        alive = false
        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.55), size: size)
        dim.zPosition = 500
        node.addChild(dim)
        let l = MiniScene.label(text, size: min(40, w * 0.18), color: UIColor(white: 1, alpha: 0.9))
        l.zPosition = 501
        node.addChild(l)
    }
}

// MARK: - Mini game base scene

/// Base class of every mini game.
/// Lifecycle: configure (by host) -> setupGame() -> countdown -> gameStarted() -> gameUpdate(dt) ... -> finishGame()
class MiniScene: SKScene {
    /// Override in a game to choose the screen layout
    class var layout: SeatLayout { return .zones }
    /// Thickness of the edge strips in the arena layout (top/bottom; sides use 0.8x)
    class var stripThickness: CGFloat { return 96 }

    var seats: [Seat] = []
    var n: Int { return seats.count }
    var difficulty = 1
    /// 0 = no time limit. Set in setupGame().
    var duration: Double = 0
    var elapsed: Double = 0
    var stats: [String: Int] = [:]
    /// Same seed for every seat in this match: let r = newRand()
    let sharedSeed = UInt64.random(in: 1...UInt64.max >> 1)
    var onFinish: ((GameResult) -> Void)?
    var onPause: (() -> Void)?

    enum Phase { case countdown, playing, over }
    var phase: Phase = .countdown
    var userPaused = false
    /// Turns layout: index of the seat that is playing right now
    var activeSeatIndex = 0
    private var turnLabels: [SKLabelNode] = []
    var useCountdown = true
    var finished = false
    /// Arena layout: the shared field in scene coordinates (zones layout: whole screen)
    var arena = CGRect.zero
    /// Zones layout: y of the middle HUD band
    var bandY: CGFloat = SH / 2

    let world = SKNode()
    let hud = SKNode()
    private var timeBar: SKSpriteNode?
    private var timeBarWidth: CGFloat = 0
    private var touchOwner: [UITouch: Int] = [:]
    private var countdownTime = 3.2
    private var lastCount = 99
    private var lastUpdate: TimeInterval = 0
    private var built = false

    required override init(size: CGSize) {
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: setup by host

    func configure(players: [SeatSetup], difficulty: Int) {
        self.difficulty = difficulty
        let lay = type(of: self).layout
        let count = max(1, min(4, players.count))
        var placed: [(SeatEdge, CGRect)] = []
        let usableBottom = bottomInset
        let usableTop = SH - topInset
        switch lay {
        case .zones:
            let hh = (usableTop - usableBottom - bandH) / 2
            let midBottom = usableBottom
            let topY = usableBottom + hh + bandH
            bandY = usableBottom + hh + bandH / 2
            if count <= 2 {
                placed.append((.bottom, CGRect(x: 0, y: midBottom, width: SW, height: hh)))
                placed.append((.top, CGRect(x: 0, y: topY, width: SW, height: hh)))
            } else {
                let w = SW / 2 - 2
                placed.append((.bottom, CGRect(x: 0, y: midBottom, width: w, height: hh)))
                placed.append((.bottom, CGRect(x: SW / 2 + 2, y: midBottom, width: w, height: hh)))
                placed.append((.top, CGRect(x: SW / 2 + 2, y: topY, width: w, height: hh)))
                placed.append((.top, CGRect(x: 0, y: topY, width: w, height: hh)))
            }
            arena = CGRect(x: 0, y: 0, width: SW, height: SH)
        case .turns:
            let full = CGRect(x: 0, y: usableBottom + 30, width: SW, height: usableTop - usableBottom - 30)
            for _ in 0..<count { placed.append((.bottom, full)) }
            arena = full
            bandY = usableBottom + 15
        case .arena:
            let t = type(of: self).stripThickness
            let ts = t * 0.8
            let sides = count >= 3
            let x0: CGFloat = sides ? ts : 0
            let x1: CGFloat = sides ? SW - ts : SW
            placed.append((.bottom, CGRect(x: x0, y: usableBottom, width: x1 - x0, height: t)))
            placed.append((.top, CGRect(x: x0, y: usableTop - t, width: x1 - x0, height: t)))
            placed.append((.left, CGRect(x: 0, y: usableBottom + t, width: ts, height: usableTop - usableBottom - 2 * t)))
            placed.append((.right, CGRect(x: SW - ts, y: usableBottom + t, width: ts, height: usableTop - usableBottom - 2 * t)))
            arena = CGRect(x: x0, y: usableBottom + t, width: x1 - x0, height: usableTop - usableBottom - 2 * t)
        }
        let levels: [Double] = [0.04, 0.14, 0.26, 0.42, 0.64]
        let base: Double = levels[max(0, min(levels.count - 1, difficulty))]
        let jitter: Double = difficulty >= 4 ? 0.0 : 0.06
        seats = []
        for i in 0..<count {
            let skill = max(0.1, min(1.0, base + Double.random(in: -jitter...jitter)))
            let s = Seat(index: i, setup: players[i], skill: skill, edge: placed[i].0, zone: placed[i].1)
            s.scene = self
            seats.append(s)
        }
    }

    // MARK: overridable

    func setupGame() {}
    func gameStarted() {}
    func gameUpdate(_ dt: Double) {}
    /// Default: end the game with the current seat scores
    func timeUp() { finishGame() }
    /// Touch callbacks: `at` is in the seat's LOCAL coordinates. Use seat.toScene(at) for scene coordinates.
    func began(_ seat: Seat, at: CGPoint, touch: UITouch) {}
    func moved(_ seat: Seat, at: CGPoint, touch: UITouch) {}
    func ended(_ seat: Seat, at: CGPoint, touch: UITouch) {}

    // MARK: lifecycle

    override func didMove(to view: SKView) {
        if built { return }
        built = true
        view.isMultipleTouchEnabled = true
        anchorPoint = .zero
        backgroundColor = Theme.uiDark
        addChild(world)
        addChild(hud)
        hud.zPosition = 1000
        buildBackground()
        for s in seats {
            s.node.zPosition = 10
            world.addChild(s.node)
            buildSeatChrome(s)
        }
        setupGame()
        buildHUD()
        if !useCountdown {
            phase = .playing
            gameStarted()
        }
    }

    private func buildBackground() {
        let bg = SKSpriteNode(texture: Gfx.backdrop("game\(Int(SH))", top: UIColor(red: 0.07, green: 0.06, blue: 0.14, alpha: 1), bottom: UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1), accent: Theme.uiOrange), size: CGSize(width: SW, height: SH))
        bg.anchorPoint = .zero
        bg.zPosition = -100
        world.addChild(bg)
        // empty quarter for 3 players: show the club logo
        if type(of: self).layout == .zones && seats.count == 3 {
            let hh = (SH - topInset - bottomInset - bandH) / 2
            let logo = SKSpriteNode(imageNamed: "logo")
            let d = min(SW / 2, hh) * 0.7
            logo.size = CGSize(width: d, height: d)
            logo.position = CGPoint(x: SW / 4, y: bandY + bandH / 2 + hh / 2)
            logo.alpha = 0.55
            logo.zRotation = .pi
            logo.zPosition = -50
            world.addChild(logo)
            logo.run(SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.05, duration: 1.2), SKAction.scale(to: 0.95, duration: 1.2)])))
        }
    }

    private func buildSeatChrome(_ s: Seat) {
        // tinted panel with neon border
        let panel = SKSpriteNode(texture: Gfx.pill(s.w, s.h, fill: s.color.withAlphaComponent(0.07), border: s.color.withAlphaComponent(0.55), corner: 18, gloss: false), size: s.size)
        panel.zPosition = -40
        s.node.addChild(panel)
        // name + score, near the inner edge (readable for this player)
        let fs: CGFloat = s.h < 120 ? 12 : 14
        let name = MiniScene.label(s.name.uppercased() + (s.isCPU ? " · CPU" : ""), size: fs, color: s.color)
        name.horizontalAlignmentMode = .left
        name.position = CGPoint(x: -s.w / 2 + 14, y: s.h / 2 - 14)
        name.zPosition = 400
        name.alpha = 0.9
        s.node.addChild(name)
        let sc = MiniScene.label("0", size: fs + 8, color: .white)
        sc.horizontalAlignmentMode = .right
        sc.position = CGPoint(x: s.w / 2 - 14, y: s.h / 2 - 16)
        sc.zPosition = 400
        s.node.addChild(sc)
        s.scoreLabel = sc
    }

    private func buildHUD() {
        let lay = type(of: self).layout
        // pause button (centre of the screen for zones, top-left corner of arena)
        let pausePos: CGPoint
        if lay == .zones {
            pausePos = CGPoint(x: 24, y: bandY)
        } else if lay == .turns {
            pausePos = CGPoint(x: SW / 2, y: SH - topInset - 20)
        } else if n >= 3 {
            pausePos = CGPoint(x: arena.minX / 2, y: (arena.minY + bottomInset) / 2)
        } else {
            pausePos = CGPoint(x: 22, y: arena.midY)
        }
        let pause = SKSpriteNode(texture: Gfx.circle(16, UIColor(white: 0, alpha: 0.6), ring: Theme.uiOrange), size: CGSize(width: 32, height: 32))
        pause.position = pausePos
        pause.name = "pause"
        pause.zPosition = 20
        pause.alpha = 0.85
        hud.addChild(pause)
        let pl = MiniScene.label("II", size: 13, color: Theme.uiOrange)
        pl.position = pausePos
        pl.zPosition = 21
        pl.alpha = pause.alpha
        hud.addChild(pl)
        if lay == .turns && n > 1 {
            let step = SW / CGFloat(n)
            for s in seats {
                let l = MiniScene.label("", size: 13, color: s.color)
                l.position = CGPoint(x: step * (CGFloat(s.index) + 0.5), y: bottomInset + 15)
                l.zPosition = 30
                hud.addChild(l)
                turnLabels.append(l)
            }
            refreshTurnBoard()
        }
        if duration > 0 {
            let w: CGFloat = lay == .zones ? SW - 70 : arena.width - 40
            let y: CGFloat = lay == .zones ? bandY : arena.maxY - 8
            let x0: CGFloat = lay == .zones ? 50 : arena.minX + 20
            let back = SKSpriteNode(texture: Gfx.pill(w, 8, fill: UIColor(white: 1, alpha: 0.12), corner: 4), size: CGSize(width: w, height: 8))
            back.anchorPoint = CGPoint(x: 0, y: 0.5)
            back.position = CGPoint(x: x0, y: y)
            hud.addChild(back)
            let bar = SKSpriteNode(color: Theme.uiOrange, size: CGSize(width: w, height: 6))
            bar.anchorPoint = CGPoint(x: 0, y: 0.5)
            bar.position = CGPoint(x: x0, y: y)
            bar.zPosition = 1
            hud.addChild(bar)
            timeBar = bar
            timeBarWidth = w
            if lay == .arena {
                // second bar at the bottom so all players see it
                back.position.y = arena.minY + 8
                bar.position.y = arena.minY + 8
            }
        }
    }

    // MARK: turns layout

    /// Turns layout: shows only this seat's field and hands it the touches.
    func setActiveSeat(_ i: Int) {
        if seats.isEmpty { return }
        activeSeatIndex = max(0, min(seats.count - 1, i))
        for s in seats { s.node.isHidden = s.index != activeSeatIndex }
        refreshTurnBoard()
        if seats.count > 1 && phase == .playing {
            let s = seats[activeSeatIndex]
            s.banner(s.name.uppercased() + " IST DRAN", color: s.color, size: 26, duration: 0.9)
        }
    }

    func refreshTurnBoard() {
        for (i, l) in turnLabels.enumerated() where i < seats.count {
            let s = seats[i]
            l.text = String(s.name.prefix(7)).uppercased() + " " + String(s.score)
            l.alpha = i == activeSeatIndex ? 1.0 : 0.5
        }
    }

    // MARK: helpers

    static func label(_ text: String, size: CGFloat, color: UIColor = .white, bold: Bool = true) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: bold ? "AvenirNext-Heavy" : "AvenirNext-DemiBold")
        l.text = text
        l.fontSize = size
        l.fontColor = color
        l.horizontalAlignmentMode = .center
        l.verticalAlignmentMode = .center
        return l
    }

    func label(_ text: String, size: CGFloat, color: UIColor = .white) -> SKLabelNode {
        return MiniScene.label(text, size: size, color: color)
    }

    /// Rounded neon button node (sprite + label). Name it to hit-test.
    static func button(_ text: String, w: CGFloat, h: CGFloat, color: UIColor, textColor: UIColor = .white, fontSize: CGFloat = 18) -> SKSpriteNode {
        let b = SKSpriteNode(texture: Gfx.pill(w, h, fill: color.withAlphaComponent(0.85), border: UIColor(white: 1, alpha: 0.6), corner: min(16, h / 2)), size: CGSize(width: w, height: h))
        let l = MiniScene.label(text, size: fontSize, color: textColor)
        l.zPosition = 1
        b.addChild(l)
        return b
    }

    func newRand() -> Rand { return Rand(seed: sharedSeed) }

    func makeBear(_ seat: Seat, height: CGFloat, faceRight: Bool = false) -> BearNode {
        return BearNode(skin: seat.skin, height: height, faceRight: faceRight)
    }

    private var activeBursts = 0

    /// Little firework of sparks (cheap: max 10 sprites, auto removed)
    func burst(at p: CGPoint, color: UIColor, count: Int = 10, power: CGFloat = 46) {
        if activeBursts > 5 { return }
        activeBursts += 1
        for i in 0..<count {
            let d = SKSpriteNode(texture: Gfx.dot, size: CGSize(width: 6, height: 6))
            d.color = i % 3 == 0 ? .white : color
            d.colorBlendFactor = 1
            d.blendMode = .add
            d.position = p
            d.zPosition = 450
            addChild(d)
            let a = CGFloat(i) / CGFloat(count) * 2 * .pi + CGFloat.random(in: -0.3...0.3)
            let dist = power * CGFloat.random(in: 0.6...1.2)
            d.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(a) * dist, y: sin(a) * dist, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.2, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 0.45), SKAction.run { [weak self] in self?.activeBursts -= 1 }]))
    }

    func setScore(_ seat: Seat, _ v: Int) {
        let gained = v > seat.score
        seat.score = v
        if type(of: self).layout == .turns { refreshTurnBoard() }
        if gained, let l = seat.scoreLabel, let par = l.parent {
            burst(at: par.convert(l.position, to: self), color: seat.color)
        }
        if let l = seat.scoreLabel {
            l.text = "\(v)"
            l.removeAllActions()
            l.run(SKAction.sequence([SKAction.scale(to: 1.35, duration: 0.07), SKAction.scale(to: 1.0, duration: 0.1)]))
        }
    }

    func addScore(_ seat: Seat, _ v: Int) {
        setScore(seat, seat.score + v)
    }

    func addStat(_ key: String, _ v: Int = 1, seat: Seat? = nil) {
        if let s = seat, s.isCPU { return }
        stats[key, default: 0] += v
    }

    var aliveSeats: [Seat] { return seats.filter { $0.alive } }
    var humansAlive: Bool { return seats.contains { $0.alive && !$0.isCPU } }

    func flashAll(_ color: UIColor, alpha: CGFloat = 0.4) {
        let f = SKSpriteNode(color: color, size: CGSize(width: SW, height: SH))
        f.anchorPoint = .zero
        f.alpha = alpha
        f.zPosition = 800
        hud.addChild(f)
        f.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.35), SKAction.removeFromParent()]))
    }

    /// Text shown to every seat (rotated for each player)
    func bannerAll(_ text: String, color: UIColor = Theme.uiOrange, size: CGFloat = 44, duration: Double = 0.8) {
        if type(of: self).layout == .arena {
            // arena: one big upright label plus a rotated one for the top player
            for (i, rot) in [CGFloat(0), .pi].enumerated() {
                if i == 1 && n < 2 { break }
                let l = MiniScene.label(text, size: size, color: color)
                l.position = CGPoint(x: arena.midX, y: arena.midY + (i == 0 ? -40 : 40))
                l.zRotation = rot
                l.zPosition = 700
                l.setScale(0.3)
                hud.addChild(l)
                l.run(SKAction.sequence([SKAction.scale(to: 1.0, duration: 0.15), SKAction.wait(forDuration: duration), SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
            }
        } else {
            for s in seats { s.banner(text, color: color, size: size, duration: duration) }
        }
    }

    // MARK: flow

    /// End the game. Scores default to the seat scores (higher = better).
    func finishGame(scores: [Int]? = nil, delay: Double = 1.0) {
        if finished { return }
        finished = true
        phase = .over
        let r = GameResult(scores: scores ?? seats.map { $0.score }, stats: stats)
        let best = r.scores.max() ?? 0
        for (i, s) in seats.enumerated() where r.scores[i] == best {
            s.banner("SIEG!", color: UIColor.yellow, size: 40, duration: 1.0)
        }
        Sfx.shared.play("horn")
        run(SKAction.sequence([
            SKAction.wait(forDuration: delay + 0.6),
            SKAction.run { [weak self] in self?.onFinish?(r) }
        ]))
    }

    override func update(_ currentTime: TimeInterval) {
        var dt = currentTime - lastUpdate
        lastUpdate = currentTime
        if dt <= 0 || dt > 0.05 { dt = 1.0 / 60.0 }
        if userPaused || !built { return }
        switch phase {
        case .countdown:
            countdownTime -= dt
            let c = Int(ceil(countdownTime))
            if c != lastCount {
                lastCount = c
                if c >= 1 && c <= 3 {
                    bannerAll("\(c)", color: .white, size: 70, duration: 0.5)
                    Sfx.shared.play("beep")
                }
            }
            if countdownTime <= 0 {
                bannerAll("LOS!", color: Theme.uiOrange, size: 60, duration: 0.4)
                Sfx.shared.play("go")
                phase = .playing
                gameStarted()
            }
        case .playing:
            elapsed += dt
            gameUpdate(dt)
            if duration > 0 && phase == .playing {
                let left = max(0, duration - elapsed)
                timeBar?.size.width = timeBarWidth * CGFloat(left / duration)
                if left < 5 { timeBar?.color = UIColor.red }
                if left <= 0 { timeUp() }
            }
        case .over:
            break
        }
    }

    // MARK: touches

    func seatFor(_ p: CGPoint) -> Seat? {
        if seats.isEmpty { return nil }
        if type(of: self).layout == .turns { return seats[min(activeSeatIndex, seats.count - 1)] }
        for s in seats where s.zone.contains(p) { return s }
        // outside all zones (arena / band): nearest seat zone
        var best = seats[0]
        var bd = CGFloat.greatestFiniteMagnitude
        for s in seats {
            let cx = max(s.zone.minX, min(p.x, s.zone.maxX))
            let cy = max(s.zone.minY, min(p.y, s.zone.maxY))
            let d = hypot(p.x - cx, p.y - cy)
            if d < bd { bd = d; best = s }
        }
        return best
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let pt = t.location(in: self)
            if let node = hud.childNode(withName: "pause"), hypot(pt.x - node.position.x, pt.y - node.position.y) < 26 {
                onPause?()
                continue
            }
            guard let s = seatFor(pt), !s.isCPU else { continue }
            touchOwner[t] = s.index
            if phase == .playing && s.alive { began(s, at: s.local(pt), touch: t) }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            guard let i = touchOwner[t] else { continue }
            let s = seats[i]
            if phase == .playing && s.alive { moved(s, at: s.local(t.location(in: self)), touch: t) }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            guard let i = touchOwner[t] else { continue }
            let s = seats[i]
            if phase == .playing && s.alive { ended(s, at: s.local(t.location(in: self)), touch: t) }
            touchOwner[t] = nil
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
