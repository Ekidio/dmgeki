import Foundation
import AVFoundation

/// Synthesised machine sounds for the DMGEKI animations: a drive spinning up, a head seeking,
/// blocks snapping into place and a casing latching shut, so the sound tells "a DMG is being
/// assembled from building blocks" instead of playing a melody. Rendered to memory, no assets.
struct MechanicalSound {
    let sr = 44100.0
    private(set) var buf: [Float]
    private var seed: UInt32 = 0x2545F491

    init(duration: Double) {
        buf = [Float](repeating: 0, count: Int(44100.0 * duration))
    }

    private mutating func noise() -> Double {
        seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
        return Double(seed) / Double(UInt32.max) * 2 - 1
    }

    private mutating func add(_ i: Int, _ v: Double) {
        guard i >= 0 && i < buf.count else { return }
        buf[i] += Float(v)
    }

    /// Tiny dry tick: a few milliseconds of high, filtered noise (head step, relay).
    mutating func tick(_ at: Double, _ lvl: Double = 0.25) {
        let s = Int(at * sr), len = Int(0.006 * sr)
        var lp = 0.0
        for i in 0..<len {
            let x = Double(i) / sr
            let n = noise()
            lp += 0.55 * (n - lp)
            add(s + i, lvl * (n - lp) * exp(-x * 900))
        }
    }

    /// Block snapping into place: a short thump with a plastic click on top.
    mutating func snap(_ at: Double, _ lvl: Double = 0.35, pitch: Double = 1.0) {
        let s = Int(at * sr), len = Int(0.09 * sr)
        var ph = 0.0, lp = 0.0
        for i in 0..<len {
            let x = Double(i) / sr
            let f = (190 + 260 * exp(-x * 60)) * pitch
            ph += 2 * .pi * f / sr
            let n = noise()
            lp += 0.35 * (n - lp)
            let body = sin(ph) * exp(-x * 45)
            let click = (n - lp) * exp(-x * 600)
            add(s + i, lvl * (0.8 * body + 0.9 * click))
        }
    }

    /// Heavy casing landing: low thud, short rattle.
    mutating func clunk(_ at: Double, _ lvl: Double = 0.5) {
        let s = Int(at * sr), len = Int(0.22 * sr)
        var ph = 0.0, lp = 0.0
        for i in 0..<len {
            let x = Double(i) / sr
            let f = 62 + 120 * exp(-x * 35)
            ph += 2 * .pi * f / sr
            let n = noise()
            lp += 0.08 * (n - lp)
            let rattle = lp * exp(-x * 28) * (1 + 0.6 * sin(2 * .pi * 38 * x))
            add(s + i, lvl * (sin(ph) * exp(-x * 18) + 1.4 * rattle))
        }
        tick(at + 0.002, lvl * 0.6)
    }

    /// Metallic latch: two quick clicks and a brief ringing spring.
    mutating func latch(_ at: Double, _ lvl: Double = 0.3) {
        tick(at, lvl)
        tick(at + 0.028, lvl * 1.2)
        let s = Int((at + 0.028) * sr), len = Int(0.12 * sr)
        for i in 0..<len {
            let x = Double(i) / sr
            add(s + i, lvl * 0.25 * (sin(2 * .pi * 2830 * x) + 0.6 * sin(2 * .pi * 4170 * x)) * exp(-x * 55))
        }
    }

    /// Motor whir between `from` and `to` Hz (spin-up / servo slide), with a soft buzz.
    mutating func whir(_ at: Double, _ dur: Double, from: Double, to: Double, _ lvl: Double = 0.12) {
        let s = Int(at * sr), len = Int(dur * sr)
        var ph = 0.0, lp = 0.0
        for i in 0..<len {
            let u = Double(i) / Double(len)
            let f = from + (to - from) * (1 - pow(1 - u, 2))
            ph += 2 * .pi * f / sr
            let env = min(1, u / 0.12) * min(1, (1 - u) / 0.2)
            // Rounded saw: motor hum with harmonics.
            let saw = sin(ph) + 0.45 * sin(2 * ph) + 0.22 * sin(3 * ph) + 0.1 * sin(5 * ph)
            let n = noise()
            lp += 0.05 * (n - lp)
            add(s + i, lvl * env * (0.7 * saw + 1.2 * lp))
        }
    }

    /// Rapid head-seek ticks over a span, slightly irregular.
    mutating func seek(_ at: Double, _ dur: Double, rate: Double, _ lvl: Double = 0.16) {
        var t = at
        var k = 0
        while t < at + dur {
            tick(t, lvl * (k % 3 == 0 ? 1.0 : 0.65))
            t += (1 / rate) * (0.7 + 0.6 * abs(noise()))
            k += 1
        }
    }

    /// 16-bit mono WAV in memory, with a gentle soft clip.
    func player(volume: Float = 0.6) -> AVAudioPlayer? {
        var data = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        let n = buf.count
        data.append(contentsOf: Array("RIFF".utf8)); u32(UInt32(36 + n * 2)); data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1); u32(UInt32(sr)); u32(UInt32(sr) * 2); u16(2); u16(16)
        data.append(contentsOf: Array("data".utf8)); u32(UInt32(n * 2))
        for v in buf { u16(UInt16(bitPattern: Int16(tanh(Double(v)) * 30000))) }
        let p = try? AVAudioPlayer(data: data)
        p?.volume = volume
        return p
    }

    // MARK: - The two animations

    /// Start-up splash: disc spins up and is written block by block, casing drops and latches,
    /// "EKI" snaps in, the line slides out.
    static func splash() -> MechanicalSound {
        var m = MechanicalSound(duration: 2.6)
        m.tick(0.02, 0.2)                                       // "DMG" slides in
        m.whir(0.10, 1.0, from: 70, to: 310, 0.10)               // disc spin-up
        m.seek(0.45, 0.62, rate: 38)                             // head writing
        for k in 0..<5 { m.snap(0.95 + Double(k) * 0.07 - 0.02, 0.22, pitch: 1 + Double(k) * 0.12) } // tracks/blocks done
        m.clunk(1.12, 0.55)                                      // casing lands
        m.latch(1.17, 0.3)                                       // and locks
        m.snap(1.30, 0.4, pitch: 1.4)                            // "EKI" pops
        m.whir(1.36, 0.5, from: 220, to: 520, 0.05)              // line slides out
        m.tick(1.62, 0.18); m.tick(1.66, 0.12)                   // subtitle
        return m
    }

    /// "DMG ready": casing lands, blocks are written, latch, check mark snaps in.
    static func buildSuccess() -> MechanicalSound {
        var m = MechanicalSound(duration: 2.0)
        m.clunk(0.30, 0.5)                                       // casing lands
        m.whir(0.33, 0.6, from: 160, to: 300, 0.08)              // write motor
        m.seek(0.35, 0.5, rate: 34)                              // head writing
        for k in 0..<6 { m.snap(0.38 + Double(k) * 0.085, 0.2, pitch: 1 + Double(k) * 0.08) } // blocks assembling
        m.latch(0.93, 0.32)                                      // file sealed
        m.snap(0.95, 0.45, pitch: 1.5)                           // check mark
        m.snap(1.05, 0.25, pitch: 2.0)
        return m
    }
}
