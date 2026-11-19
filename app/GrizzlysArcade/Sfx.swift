import AVFoundation
import UIKit

struct Note {
    var f0: Double
    var f1: Double
    var dur: Double
    var vol: Double
    var wave: Int   // 0 sine, 1 square, 2 noise
}

final class Sfx {
    static let shared = Sfx()
    var enabled = true {
        didSet { if !enabled { musicPlayer?.stop() } else if let m = currentMusic { currentMusic = nil; music(m) } }
    }
    var musicEnabled = true {
        didSet { if !musicEnabled { musicPlayer?.stop() } else if let m = currentMusic { currentMusic = nil; music(m) } }
    }
    private var musicPlayer: AVAudioPlayer?
    private var currentMusic: String?
    private var musicCache: [String: Data] = [:]
    private var datas: [String: Data] = [:]
    private var pools: [String: [AVAudioPlayer]] = [:]

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        build()
        warmUp()
    }

    /// Creates the audio players ahead of time so the first hit never stutters.
    private func warmUp() {
        for name in ["tap", "hit", "click", "bounce", "goal", "pop", "kick", "beep"] {
            guard let d = datas[name] else { continue }
            var pool: [AVAudioPlayer] = []
            for _ in 0..<2 {
                if let p = try? AVAudioPlayer(data: d) { p.volume = 0.8; p.prepareToPlay(); pool.append(p) }
            }
            pools[name] = pool
        }
    }

    private func n(_ f0: Double, _ f1: Double, _ dur: Double, _ vol: Double = 0.6, _ wave: Int = 0) -> Note {
        return Note(f0: f0, f1: f1, dur: dur, vol: vol, wave: wave)
    }

    private func build() {
        datas["click"] = makeWav([n(700, 900, 0.05, 0.4)])
        datas["tap"] = makeWav([n(880, 880, 0.04, 0.4)])
        datas["beep"] = makeWav([n(660, 660, 0.14, 0.5)])
        datas["go"] = makeWav([n(990, 990, 0.35, 0.5, 1)])
        datas["tick"] = makeWav([n(600, 600, 0.03, 0.3)])
        datas["jump"] = makeWav([n(300, 750, 0.13, 0.4)])
        datas["pop"] = makeWav([n(700, 1300, 0.06, 0.5)])
        datas["kick"] = makeWav([n(0, 0, 0.04, 0.7, 2), n(220, 80, 0.12, 0.8)])
        datas["hit"] = makeWav([n(0, 0, 0.06, 0.7, 2), n(150, 50, 0.14, 0.8)])
        datas["bounce"] = makeWav([n(350, 250, 0.05, 0.4)])
        datas["save"] = makeWav([n(0, 0, 0.05, 0.6, 2), n(300, 200, 0.12, 0.6)])
        datas["goal"] = makeWav([n(523, 523, 0.09, 0.5, 1), n(659, 659, 0.09, 0.5, 1), n(784, 784, 0.09, 0.5, 1), n(1046, 1046, 0.3, 0.5, 1)])
        datas["horn"] = makeWav([n(220, 220, 0.5, 0.5, 1), n(330, 330, 0.01, 0.0, 0)])
        datas["miss"] = makeWav([n(400, 120, 0.35, 0.5)])
        datas["wrong"] = makeWav([n(160, 140, 0.28, 0.5, 1)])
        datas["right"] = makeWav([n(660, 660, 0.08, 0.5), n(990, 990, 0.18, 0.5)])
        datas["coin"] = makeWav([n(1200, 1500, 0.07, 0.4), n(1800, 1800, 0.14, 0.4)])
        datas["whistle"] = makeWav([n(2700, 2700, 0.07, 0.4), n(3000, 3000, 0.07, 0.4), n(2700, 2700, 0.07, 0.4), n(3000, 3000, 0.07, 0.4), n(2700, 2700, 0.1, 0.4), n(3000, 3000, 0.12, 0.4)])
        datas["win"] = makeWav([n(523, 523, 0.11, 0.5, 1), n(523, 523, 0.11, 0.5, 1), n(523, 523, 0.11, 0.5, 1), n(784, 784, 0.4, 0.5, 1)])
        datas["lose"] = makeWav([n(392, 392, 0.18, 0.5), n(330, 330, 0.18, 0.5), n(262, 262, 0.4, 0.5)])
        datas["fanfare"] = makeWav([n(523, 523, 0.12, 0.5, 1), n(659, 659, 0.12, 0.5, 1), n(784, 784, 0.12, 0.5, 1), n(1046, 1046, 0.2, 0.5, 1), n(784, 784, 0.1, 0.5, 1), n(1046, 1046, 0.5, 0.5, 1)])
        datas["stomp"] = makeWav([n(0, 0, 0.05, 0.5, 2), n(90, 40, 0.1, 0.8)])
    }

    private func makeWav(_ notes: [Note]) -> Data {
        let rate = 22050.0
        var samples: [Int16] = []
        for note in notes {
            let count = max(1, Int(rate * note.dur))
            var phase = 0.0
            for i in 0..<count {
                let t = Double(i) / Double(count)
                let f = note.f0 + (note.f1 - note.f0) * t
                phase += 2.0 * Double.pi * f / rate
                var v: Double
                if note.wave == 1 {
                    v = sin(phase) >= 0 ? 0.6 : -0.6
                } else if note.wave == 2 {
                    v = Double.random(in: -1.0...1.0)
                } else {
                    v = sin(phase)
                }
                let attack = min(1.0, Double(i) / (rate * 0.004))
                let env = attack * pow(1.0 - t, 1.4)
                var s = v * note.vol * env
                if s > 1 { s = 1 }
                if s < -1 { s = -1 }
                samples.append(Int16(s * 30000.0))
            }
        }
        var data = Data()
        func append32(_ x: UInt32) { var v = x.littleEndian; data.append(Data(bytes: &v, count: 4)) }
        func append16(_ x: UInt16) { var v = x.littleEndian; data.append(Data(bytes: &v, count: 2)) }
        let dataSize = UInt32(samples.count * 2)
        data.append("RIFF".data(using: .ascii)!)
        append32(36 + dataSize)
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        append32(16)
        append16(1)
        append16(1)
        append32(UInt32(rate))
        append32(UInt32(rate) * 2)
        append16(2)
        append16(16)
        data.append("data".data(using: .ascii)!)
        append32(dataSize)
        for s in samples {
            var v = s.littleEndian
            data.append(Data(bytes: &v, count: 2))
        }
        return data
    }

    func play(_ name: String) {
        if !enabled { return }
        guard let d = datas[name] else { return }
        var pool = pools[name] ?? []
        for p in pool where !p.isPlaying {
            p.currentTime = 0
            p.play()
            return
        }
        if pool.count < 4, let p = try? AVAudioPlayer(data: d) {
            p.volume = 0.8
            p.prepareToPlay()
            p.play()
            pool.append(p)
            pools[name] = pool
        }
    }

    // MARK: - Music (generated chiptune loops)

    /// "menu", "game" or nil to stop
    func music(_ name: String?) {
        if name == currentMusic && (musicPlayer?.isPlaying ?? false) { return }
        currentMusic = name
        musicPlayer?.stop()
        musicPlayer = nil
        guard let name = name, enabled, musicEnabled else { return }
        if let d = musicCache[name] {
            startMusic(d, name: name)
            return
        }
        DispatchQueue.global(qos: .utility).async {
            let d = Sfx.makeSong(name)
            DispatchQueue.main.async {
                self.musicCache[name] = d
                if self.currentMusic == name { self.startMusic(d, name: name) }
            }
        }
    }

    private func startMusic(_ d: Data, name: String) {
        guard enabled, musicEnabled, let p = try? AVAudioPlayer(data: d) else { return }
        p.numberOfLoops = -1
        p.volume = name == "menu" ? 0.35 : 0.22
        p.prepareToPlay()
        p.play()
        musicPlayer = p
    }

    private static func makeSong(_ name: String) -> Data {
        let rate = 22050.0
        let game = name == "game"
        let bpm = game ? 138.0 : 112.0
        let beat = 60.0 / bpm
        let bars = 8
        let total = Int(rate * beat * 4 * Double(bars))
        var buf = [Float](repeating: 0, count: total)
        func midi(_ m: Int) -> Double { return 440.0 * pow(2.0, Double(m - 69) / 12.0) }
        func tone(_ start: Double, _ dur: Double, _ f0: Double, _ f1: Double, _ vol: Double, _ wave: Int, _ decay: Double) {
            let s0 = Int(start * rate)
            let n = Int(dur * rate)
            var phase = 0.0
            var seed: UInt32 = UInt32(s0 & 0xffff) &+ 12345
            for i in 0..<n {
                let idx = s0 + i
                if idx >= total { break }
                let t = Double(i) / Double(n)
                let f = f0 + (f1 - f0) * t
                phase += 2 * Double.pi * f / rate
                var v: Double
                switch wave {
                case 1: v = sin(phase) >= 0 ? 0.5 : -0.5
                case 2:
                    seed = seed &* 1103515245 &+ 12345
                    v = Double(Int32(bitPattern: seed)) / Double(Int32.max)
                case 3: v = 2 * abs(2 * (phase / (2 * Double.pi) - floor(phase / (2 * Double.pi) + 0.5))) - 1
                default: v = sin(phase)
                }
                let attack = min(1.0, Double(i) / (rate * 0.005))
                let env = attack * pow(1 - t, decay)
                buf[idx] += Float(v * vol * env)
            }
        }
        // chord roots (midi) and minor/major flags: Am F C G  /  Em C G D
        let roots = game ? [52, 48, 55, 50] : [57, 53, 48, 55]
        let minor = game ? [true, false, false, false] : [true, false, false, false]
        let lead: [Int] = game ? [0, 7, 12, 7, 3, 7, 12, 15] : [0, 4, 7, 12, 7, 4, 7, 11]
        for bar in 0..<bars {
            let c = (bar / 2) % 4
            let root = roots[c]
            let third = minor[c] ? 3 : 4
            let chord = [0, third, 7, 12]
            let t0 = Double(bar) * 4 * beat
            for b in 0..<4 {
                let bt = t0 + Double(b) * beat
                // kick + bass
                tone(bt, 0.16, 140, 45, 0.55, 0, 2.5)
                tone(bt, beat * 0.45, midi(root - 24), midi(root - 24), 0.28, 3, 1.2)
                tone(bt + beat / 2, beat * 0.4, midi(root - 12), midi(root - 12), 0.18, 3, 1.4)
                // hats
                tone(bt + beat / 2, 0.04, 0, 0, 0.09, 2, 3)
                if game { tone(bt + beat * 0.25, 0.03, 0, 0, 0.05, 2, 3); tone(bt + beat * 0.75, 0.03, 0, 0, 0.05, 2, 3) }
                // snare on 2 and 4
                if b % 2 == 1 { tone(bt, 0.12, 0, 0, 0.16, 2, 2) }
                // arpeggio (16ths)
                for k in 0..<4 {
                    let note = root + 12 + chord[(b * 4 + k) % 4]
                    tone(bt + Double(k) * beat / 4, beat / 4 * 0.9, midi(note), midi(note), 0.055, 1, 1.6)
                }
            }
            // lead melody on the second bar of each chord
            if bar % 2 == 1 {
                for (i, iv) in lead.enumerated() {
                    let st = t0 + Double(i) * beat / 2
                    let m = root + 12 + (minor[c] ? iv : (iv == 3 ? 4 : (iv == 15 ? 16 : iv)))
                    tone(st, beat / 2 * 0.95, midi(m), midi(m), 0.07, 0, 0.8)
                }
            }
        }
        var peak: Float = 0.001
        for v in buf { peak = max(peak, abs(v)) }
        let gain = 0.9 / peak
        var data = Data()
        func append32(_ x: UInt32) { var v = x.littleEndian; data.append(Data(bytes: &v, count: 4)) }
        func append16(_ x: UInt16) { var v = x.littleEndian; data.append(Data(bytes: &v, count: 2)) }
        let dataSize = UInt32(total * 2)
        data.append("RIFF".data(using: .ascii)!)
        append32(36 + dataSize)
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        append32(16)
        append16(1)
        append16(1)
        append32(UInt32(rate))
        append32(UInt32(rate) * 2)
        append16(2)
        append16(16)
        data.append("data".data(using: .ascii)!)
        append32(dataSize)
        var pcm = [Int16](repeating: 0, count: total)
        for i in 0..<total { pcm[i] = Int16(max(-1, min(1, buf[i] * gain)) * 30000) }
        pcm.withUnsafeBufferPointer { p in data.append(Data(buffer: p)) }
        return data
    }
}

enum Haptic {
    static var enabled = true
    private static var impact: [Int: UIImpactFeedbackGenerator] = [:]
    private static let notify = UINotificationFeedbackGenerator()

    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if !enabled { return }
        let g: UIImpactFeedbackGenerator
        if let c = impact[style.rawValue] { g = c } else { g = UIImpactFeedbackGenerator(style: style); impact[style.rawValue] = g }
        g.impactOccurred()
        g.prepare()
    }

    static func good() {
        if !enabled { return }
        notify.notificationOccurred(.success)
        notify.prepare()
    }

    static func bad() {
        if !enabled { return }
        notify.notificationOccurred(.error)
        notify.prepare()
    }
}
