import SwiftUI
import AppKit
import AVFoundation

/// Start-up splash in the EKIDIO style (as STEMEKI, CHORDEKI): "DMG" slides in, a disc spins in
/// and is burned track by track, then a blue drive casing drops over it and "EKI" is cut out of it.
public struct SplashView: View {
    let onDone: () -> Void
    @State private var start = Date()
    @State private var leaving = false
    @State private var jingle: AVAudioPlayer?

    static let total: Double = 2.6
    /// DMGEKI blue (#27A3F5) and its family of shades, light to deep.
    static let blue = Color(red: 39 / 255, green: 163 / 255, blue: 245 / 255)
    private let colors = [
        Color(red: 0.42, green: 0.78, blue: 1.0),
        Color(red: 0.15, green: 0.64, blue: 0.96),
        Color(red: 0.10, green: 0.50, blue: 0.92),
        Color(red: 0.12, green: 0.36, blue: 0.85),
    ]

    public init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }

    public var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(start)
            Canvas { ctx, size in draw(ctx, size, t) }
        }
        .background(background)
        .opacity(leaving ? 0 : 1)
        .scaleEffect(leaving ? 1.04 : 1)
        .animation(.easeIn(duration: 0.5), value: leaving)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear {
            // macOS window restoration may reopen the shared color panel over the splash.
            if NSColorPanel.sharedColorPanelExists {
                NSColorPanel.shared.orderOut(nil)
            }
            start = Date()
            jingle = MechanicalSound.splash().player()
            jingle?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.total) { finish() }
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.043, green: 0.043, blue: 0.05)
            RadialGradient(colors: [Self.blue.opacity(0.24), colors[3].opacity(0.08), .clear],
                           center: .init(x: 0.5, y: 0.47), startRadius: 0, endRadius: 520)
        }
        .ignoresSafeArea()
    }

    private func finish() {
        guard !leaving else { return }
        leaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone() }
    }

    // MARK: Drawing

    private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
    private func easeOut(_ x: Double) -> Double { 1 - pow(1 - clamp(x), 3) }
    private func overshoot(_ x: Double) -> Double {
        let c = clamp(x), s = 1.9
        return 1 + (s + 1) * pow(c - 1, 3) + s * pow(c - 1, 2)
    }

    func draw(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double) {
        let cx = size.width / 2, cy = size.height / 2 - 20
        let unit = min(size.width / 900, size.height / 640) * 1.0
        let skew = CGAffineTransform(a: 1, b: 0, c: -0.25, d: 1, tx: 0, ty: 0)

        // "DMG" slides in from the left; the logo is centred as a whole.
        let sIn = easeOut(t / 0.6)
        var word = ctx
        word.opacity = sIn
        word.translateBy(x: cx + 2 * unit - (1 - sIn) * 80, y: cy)
        word.draw(Text("DMG").font(.system(size: 120 * unit, weight: .black).italic()).foregroundColor(.white),
                  at: .zero, anchor: .trailing)

        // The EKI badge is a drive being built: a disc spins in and gets "burned" track by track,
        // then the drive casing drops over it and locks, and "EKI" is cut out of the casing.
        let bw = 300 * unit, bh = 150 * unit
        let bx = cx + 30 * unit - bh / 2 * 0.25, by = cy - bh / 2
        let bcx = bx + bh / 2 * 0.25 + bw / 2, bcy = by + bh / 2
        let close = overshoot((t - 0.95) / 0.32)         // casing drop, with a little bounce
        let landed = clamp((t - 1.12) / 0.08)
        ctx.drawLayer { ctx in
            // White offset shadow once the casing is locked.
            if landed > 0 {
                var sh = ctx
                sh.opacity = landed
                sh.translateBy(x: bx + 12 * unit + bh / 2 * 0.25, y: by + 12 * unit)
                sh.concatenate(skew)
                sh.fill(Path(CGRect(x: 0, y: 0, width: bw, height: bh)), with: .color(.white))
            }

            // 1. The disc rolls in from the right, spinning, and is written track by track.
            let dIn = easeOut((t - 0.1) / 0.55)
            let discAlpha = dIn * (1 - landed)
            if discAlpha > 0 {
                let r = bh * 0.62 * (1 - 0.25 * clamp((t - 0.95) / 0.2))
                let spin = Angle.radians(-(t * 9) - Double(1 - dIn) * 6)
                var d = ctx
                d.opacity = discAlpha
                d.translateBy(x: bcx + (1 - dIn) * 340 * unit, y: bcy)
                d.rotate(by: spin)
                let disc = Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
                d.fill(disc, with: .radialGradient(Gradient(colors: [Color(white: 0.92), Color(white: 0.62), colors[0].opacity(0.9)]),
                                                   center: .zero, startRadius: r * 0.2, endRadius: r))
                // Spinning sheen.
                for k in 0..<2 {
                    var w = Path()
                    w.move(to: .zero)
                    w.addArc(center: .zero, radius: r, startAngle: .degrees(Double(k) * 180 - 18),
                             endAngle: .degrees(Double(k) * 180 + 18), clockwise: false)
                    w.closeSubpath()
                    d.fill(w, with: .color(.white.opacity(0.35)))
                }
                // Burned tracks: each ring fills its arc a moment after the previous one.
                for k in 0..<5 {
                    let tr = r * (0.42 + 0.11 * CGFloat(k))
                    let wp = clamp((t - 0.45 - Double(k) * 0.07) / 0.5)
                    var ring = Path()
                    ring.addArc(center: .zero, radius: tr, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                    d.stroke(ring, with: .color(.black.opacity(0.08)), lineWidth: 5 * unit)
                    guard wp > 0 else { continue }
                    var arc = Path()
                    arc.addArc(center: .zero, radius: tr, startAngle: .degrees(0), endAngle: .degrees(360 * wp), clockwise: false)
                    d.stroke(arc, with: .color(Self.blue), lineWidth: 5 * unit)
                    if wp < 1 {
                        let a = 2 * Double.pi * wp
                        let head = CGRect(x: tr * CGFloat(cos(a)) - 4 * unit, y: tr * CGFloat(sin(a)) - 4 * unit,
                                          width: 8 * unit, height: 8 * unit)
                        d.fill(Path(ellipseIn: head), with: .color(.white))
                    }
                }
                // Centre hole: the background shows through.
                var hole = d
                hole.blendMode = .destinationOut
                hole.fill(Path(ellipseIn: CGRect(x: -r * 0.16, y: -r * 0.16, width: r * 0.32, height: r * 0.32)), with: .color(.white))
                d.stroke(Path(ellipseIn: CGRect(x: -r * 0.3, y: -r * 0.3, width: r * 0.6, height: r * 0.6)),
                         with: .color(.white.opacity(0.5)), lineWidth: 1.5 * unit)
            }

            // 2. The drive casing drops over the disc and locks.
            if t > 0.95 {
                var c = ctx
                c.opacity = clamp((t - 0.95) / 0.1)
                c.translateBy(x: bx + bh / 2 * 0.25, y: by - (1 - close) * bh * 1.5)
                c.concatenate(skew)
                let rect = CGRect(x: 0, y: 0, width: bw, height: bh)
                c.fill(Path(rect), with: .linearGradient(Gradient(colors: [colors[0], colors[1], colors[2], colors[3]]),
                                                         startPoint: .zero, endPoint: CGPoint(x: 0, y: bh)))
                // Top seam, vents, the disc slot and the activity LED.
                c.fill(Path(CGRect(x: 0, y: bh * 0.16, width: bw, height: 1.5 * unit)), with: .color(.black.opacity(0.18)))
                for k in 0..<5 {
                    c.fill(Path(CGRect(x: bw - 70 * unit + CGFloat(k) * 10 * unit, y: bh * 0.05, width: 4 * unit, height: bh * 0.07)),
                           with: .color(.black.opacity(0.22)))
                }
                c.fill(Path(roundedRect: CGRect(x: bw * 0.06, y: bh * 0.84, width: bw * 0.56, height: 4 * unit), cornerRadius: 2 * unit),
                       with: .color(.black.opacity(0.35)))
                let busy = t < 1.9 ? (Int(t * 12) % 2 == 0) : true
                c.fill(Path(ellipseIn: CGRect(x: bw - 26 * unit, y: bh * 0.83, width: 8 * unit, height: 8 * unit)),
                       with: .color(busy ? .white : .black.opacity(0.3)))
                let flash = max(0, 1 - abs(t - 1.17) / 0.12)
                if flash > 0 { c.fill(Path(rect), with: .color(.white.opacity(0.55 * flash))) }
            }

            // "EKI" pops in, cut out of the casing.
            let ePop = overshoot((t - 1.25) / 0.4)
            if t > 1.25 {
                var e = ctx
                e.blendMode = .destinationOut
                e.translateBy(x: bx + bw / 2 + 10 * unit, y: by + bh / 2 + 2 * unit)
                e.scaleBy(x: ePop, y: ePop)
                e.draw(Text("EKI").font(.system(size: 116 * unit, weight: .black).italic()).foregroundColor(.white),
                       at: .zero, anchor: .center)
            }
        }

        // A blue line grows, then the subtitle.
        let lg = easeOut((t - 1.35) / 0.6)
        if lg > 0 {
            let lw = 620 * unit * lg, ly = cy + bh / 2 + 46 * unit
            let rect = CGRect(x: cx - lw / 2, y: ly, width: lw, height: 4 * unit)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 2),
                     with: .linearGradient(Gradient(colors: [.clear] + colors + [.clear]),
                                           startPoint: CGPoint(x: rect.minX, y: ly), endPoint: CGPoint(x: rect.maxX, y: ly)))
        }
        let sub = easeOut((t - 1.6) / 0.5)
        if sub > 0 {
            var s = ctx
            s.opacity = sub
            s.draw(Text("D I S K   I M A G E   ·   L A Y O U T   ·   B U I L D")
                    .font(.system(size: 15 * unit, weight: .bold, design: .monospaced)).foregroundColor(Color(white: 0.85)),
                   at: CGPoint(x: cx, y: cy + bh / 2 + 82 * unit + (1 - sub) * 8))
        }
        // Brand and version at the bottom.
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        var v = ctx
        v.opacity = easeOut((t - 1.0) / 0.6)
        v.draw(Text(ver.isEmpty ? "EKIDIO SOUND" : "V\(ver) · EKIDIO SOUND")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.4)),
               at: CGPoint(x: size.width / 2, y: size.height - 26))
    }
}
