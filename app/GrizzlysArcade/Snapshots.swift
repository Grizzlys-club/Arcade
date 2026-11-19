import SpriteKit
import UIKit

enum SnapshotRunner {
    static var active: Bool { launchArgs.contains("-snapshots") }

    static var smoke: Bool { launchArgs.contains("-smoke") }

    /// Crash test: every game with every supported player count, ~15 s of simulated play each.
    static func runSmoke() {
        var jobs: [(GameKind, Int)] = []
        for k in GameKind.allCases { for n in 1...4 where n == 1 || k.supports(n) { jobs.append((k, n)) } }
        var i = 0
        func next() {
            if i >= jobs.count { print("SMOKE_DONE \(jobs.count)"); return }
            let (k, n) = jobs[i]; i += 1
            print("SMOKE_START \(k.rawValue) \(n)")
            SH = 844
            let scene = GameRegistry.make(k)
            scene.size = CGSize(width: SW, height: SH)
            scene.scaleMode = .aspectFit
            scene.useCountdown = false
            let ids = ["orange", "classic", "ice", "pink"]
            var setups: [SeatSetup] = []
            for p in 0..<n { setups.append(SeatSetup(name: "P\(p + 1)", skin: Skin.find(ids[p]), isCPU: true)) }
            scene.configure(players: setups, difficulty: 2)
            let view = SKView(frame: CGRect(x: 0, y: 0, width: SW, height: SH))
            view.presentScene(scene)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                var t = CACurrentMediaTime()
                for _ in 0..<900 { t += 1.0 / 60; scene.update(t) }
                print("SMOKE_OK \(k.rawValue) \(n)")
                scene.removeAllChildren()
                view.presentScene(nil)
                next()
            }
        }
        next()
    }

    static func run() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("snaps")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let kinds = GameKind.allCases
        var idx = 0
        func next() {
            if idx >= kinds.count { print("SNAP_DONE"); return }
            let k = kinds[idx]; idx += 1
            SH = 844
            let scene = GameRegistry.make(k)
            scene.size = CGSize(width: SW, height: SH)
            scene.scaleMode = .aspectFit
            scene.useCountdown = false
            var setups: [SeatSetup] = []
            let ids = ["orange", "classic", "ice", "pink"]
            for i in 0..<2 { setups.append(SeatSetup(name: "Grizzly \(i + 1)", skin: Skin.find(ids[i]), isCPU: true)) }
            scene.configure(players: setups, difficulty: 2)
            let view = SKView(frame: CGRect(x: 0, y: 0, width: SW, height: SH))
            view.presentScene(scene)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                var t = CACurrentMediaTime()
                for _ in 0..<220 { t += 1.0 / 60; scene.update(t) }
                if let tex = view.texture(from: scene) {
                    let img = UIImage(cgImage: tex.cgImage())
                    if let d = img.pngData() { try? d.write(to: dir.appendingPathComponent("\(k.rawValue).png")) }
                }
                print("SNAP \(k.rawValue)")
                scene.removeAllChildren()
                view.presentScene(nil)
                next()
            }
        }
        next()
    }
}
