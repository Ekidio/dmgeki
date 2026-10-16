import SwiftUI
import AppKit
import AVFoundation

/// "DMG ready" celebration in the EKIDIO style (matches the start-up splash): the blue drive casing
/// drops in, its write stripe fills, a check mark is cut out of it and blue sparks burst outwards.
/// Then the file name, size and the actions fade in.
public struct BuildSuccessView: View {
    let dmgPath: String
    let onDone: () -> Void

    @State private var start = Date()
    @State private var showInfo = false
    @State private var leaving = false
    @State private var sound: AVAudioPlayer?

    private static let blue = Color(red: 39 / 255, green: 163 / 255, blue: 245 / 255)
    private let colors = [
        Color(red: 0.42, green: 0.78, blue: 1.0),
        Color(red: 0.15, green: 0.64, blue: 0.96),
        Color(red: 0.10, green: 0.50, blue: 0.92),
        Color(red: 0.12, green: 0.36, blue: 0.85),
    ]

    public init(dmgPath: String, onDone: @escaping () -> Void) {
        self.dmgPath = dmgPath
        self.onDone = onDone
    }

    private var fileName: String { (dmgPath as NSString).lastPathComponent }
    private var folder: String { (dmgPath as NSString).deletingLastPathComponent }
    private var fileSize: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: dmgPath),
              let size = attrs[.size] as? NSNumber else { return "" }
        return ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
    }

    public var body: some View {
        ZStack {
            // Backdrop
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color(red: 0.043, green: 0.043, blue: 0.05).opacity(0.9)
                RadialGradient(colors: [Self.blue.opacity(0.28), .clear],
                               center: .init(x: 0.5, y: 0.4), startRadius: 0, endRadius: 520)
            }
            .ignoresSafeArea()
            .onTapGesture { close() }

            VStack(spacing: 0) {
                TimelineView(.animation) { tl in
                    let t = tl.date.timeIntervalSince(start)
                    Canvas { ctx, size in draw(ctx, size, t) }
                }
                .frame(width: 560, height: 300)
                .allowsHitTesting(false)

                VStack(spacing: 10) {
                    Text("D M G   R E A D Y")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Self.blue)

                    Text(fileName)
                        .font(.system(size: 26, weight: .black).italic())
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text([fileSize, folder].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(white: 0.55))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 10) {
                        Button(action: showInFinder) {
                            Label("Show in Finder", systemImage: "folder")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Self.blue))
                                .shadow(color: Self.blue.opacity(0.5), radius: 8)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)

                        Button(action: openDMG) {
                            Label("Open DMG", systemImage: "externaldrive")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.10)))
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button(action: close) {
                            Text("Done")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(white: 0.75))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.cancelAction)
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: 520)
                .opacity(showInfo ? 1 : 0)
                .offset(y: showInfo ? 0 : 14)
            }
        }
        .opacity(leaving ? 0 : 1)
        .scaleEffect(leaving ? 1.03 : 1)
        .animation(.easeIn(duration: 0.35), value: leaving)
        .onAppear {
            start = Date()
            sound = MechanicalSound.buildSuccess().player()
            sound?.play()
            withAnimation(.easeOut(duration: 0.5).delay(1.25)) { showInfo = true }
        }
    }

    // MARK: Actions

    private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: dmgPath)])
        close()
    }

    private func openDMG() {
        NSWorkspace.shared.open(URL(fileURLWithPath: dmgPath))
        close()
    }

    private func close() {
        guard !leaving else { return }
        leaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDone() }
    }

    // MARK: Drawing

    private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
    private func easeOut(_ x: Double) -> Double { 1 - pow(1 - clamp(x), 3) }
    private func overshoot(_ x: Double) -> Double {
        let c = clamp(x), s = 1.9
        return 1 + (s + 1) * pow(c - 1, 3) + s * pow(c - 1, 2)
    }

    func draw(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double) {
        let unit: CGFloat = 0.95
        let skew = CGAffineTransform(a: 1, b: 0, c: -0.25, d: 1, tx: 0, ty: 0)
        let bw = 300 * unit, bh = 150 * unit
        let cx = size.width / 2, cy = size.height / 2 + 6
        let bx = cx - bw / 2, by = cy - bh / 2

        // Glow pulse behind the drive once it is complete.
        let glow = clamp((t - 0.9) / 0.3) * (0.75 + 0.25 * sin(t * 3))
        if glow > 0 {
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 230, y: cy - 150, width: 460, height: 300)),
                     with: .radialGradient(Gradient(colors: [Self.blue.opacity(0.35 * glow), .clear]),
                                           center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: 230))
        }

        // Sparks burst out of the drive when the check lands.
        let bt = t - 0.95
        if bt > 0 && bt < 1.4 {
            let p = easeOut(bt / 1.1)
            for k in 0..<28 {
                let a = Double(k) / 28 * 2 * .pi + Double(k % 3) * 0.17
                let dist = (140 + Double((k * 37) % 70)) * p
                let x = cx + CGFloat(cos(a) * dist * 1.45), y = cy + CGFloat(sin(a) * dist * 0.95)
                let r = CGFloat(k % 4 == 0 ? 4.5 : 3) * CGFloat(1 - p * 0.6)
                var s = ctx
                s.opacity = 1 - clamp((bt - 0.3) / 1.0)
                let c: Color = k % 5 == 0 ? .white : colors[k % 4]
                s.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)), with: .color(c))
            }
        }

        let drop = overshoot(t / 0.4)
        let landed = clamp((t - 0.3) / 0.1)
        ctx.drawLayer { ctx in
            // White offset shadow.
            if landed > 0 {
                var sh = ctx
                sh.opacity = landed
                sh.translateBy(x: bx + 12 * unit, y: by + 12 * unit)
                sh.concatenate(skew)
                sh.fill(Path(CGRect(x: 0, y: 0, width: bw, height: bh)), with: .color(.white))
            }

            // The drive casing drops in.
            var c = ctx
            c.opacity = clamp(t / 0.12)
            c.translateBy(x: bx, y: by - (1 - drop) * bh * 1.4)
            c.concatenate(skew)
            let rect = CGRect(x: 0, y: 0, width: bw, height: bh)
            c.fill(Path(rect), with: .linearGradient(Gradient(colors: colors),
                                                     startPoint: .zero, endPoint: CGPoint(x: 0, y: bh)))
            c.fill(Path(CGRect(x: 0, y: bh * 0.16, width: bw, height: 1.5 * unit)), with: .color(.black.opacity(0.18)))
            for k in 0..<5 {
                c.fill(Path(CGRect(x: bw - 70 * unit + CGFloat(k) * 10 * unit, y: bh * 0.05, width: 4 * unit, height: bh * 0.07)),
                       with: .color(.black.opacity(0.22)))
            }
            // Write stripe fills along the slot, then the LED settles to steady white.
            let slot = CGRect(x: bw * 0.06, y: bh * 0.84, width: bw * 0.56, height: 4 * unit)
            c.fill(Path(roundedRect: slot, cornerRadius: 2 * unit), with: .color(.black.opacity(0.35)))
            let wp = easeOut((t - 0.35) / 0.5)
            if wp > 0 {
                c.fill(Path(roundedRect: CGRect(x: slot.minX, y: slot.minY, width: slot.width * wp, height: slot.height),
                            cornerRadius: 2 * unit), with: .color(.white.opacity(0.9)))
            }
            let busy = t < 0.9 ? (Int(t * 14) % 2 == 0) : true
            c.fill(Path(ellipseIn: CGRect(x: bw - 26 * unit, y: bh * 0.83, width: 8 * unit, height: 8 * unit)),
                   with: .color(busy ? .white : .black.opacity(0.3)))
            let flash = max(0, 1 - abs(t - 0.95) / 0.12)
            if flash > 0 { c.fill(Path(rect), with: .color(.white.opacity(0.5 * flash))) }

            // The check mark is cut out of the casing, drawn stroke by stroke.
            let cp = easeOut((t - 0.85) / 0.35)
            if cp > 0 {
                var check = Path()
                check.move(to: CGPoint(x: cx - 46 * unit, y: cy + 2 * unit))
                check.addLine(to: CGPoint(x: cx - 12 * unit, y: cy + 34 * unit))
                check.addLine(to: CGPoint(x: cx + 52 * unit, y: cy - 36 * unit))
                var e = ctx
                e.blendMode = .destinationOut
                let pop = overshoot((t - 0.85) / 0.45)
                e.translateBy(x: cx, y: cy)
                e.scaleBy(x: pop, y: pop)
                e.translateBy(x: -cx, y: -cy)
                e.stroke(check.trimmedPath(from: 0, to: cp),
                         with: .color(.white),
                         style: StrokeStyle(lineWidth: 26 * unit, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
