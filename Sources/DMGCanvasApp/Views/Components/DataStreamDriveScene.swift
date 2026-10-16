import SwiftUI

/// The DMGEKI "creating disc image" scene: files, folders, tapes, reels, records and waveforms on the
/// left dissolve into streams of light that flow into the slot of a drive on the right, whose screen
/// shows the progress and the DMG EKI logo. Used by the start-up splash and while a DMG is building.
struct DataStreamDriveScene: View {
    /// 0…1, shown on the drive's screen.
    var progress: Double
    /// Screen headline, e.g. "CREATING DISC IMAGE…".
    var title: String = "CREATING DISC IMAGE…"
    /// Optional small line under the bar (the current build stage).
    var detail: String = ""
    /// Seconds since the scene appeared, drives the motion (pass the TimelineView time).
    var time: Double

    static let cyan = Color(red: 0.36, green: 0.82, blue: 1.0)
    static let blue = Color(red: 39 / 255, green: 163 / 255, blue: 245 / 255)

    var body: some View {
        Canvas { ctx, size in draw(ctx, size) }
            .background(
                ZStack {
                    Color(red: 0.035, green: 0.04, blue: 0.05)
                    RadialGradient(colors: [Self.blue.opacity(0.18), .clear],
                                   center: .init(x: 0.68, y: 0.5), startRadius: 0, endRadius: 620)
                }
            )
    }

    // MARK: - Layout

    private struct Tile {
        enum Kind { case folder, document, waveform, record, reel, cassette }
        var kind: Kind
        var x: Double, y: Double, w: Double, h: Double, phase: Double
        var label: String
    }

    /// A loose wall of media on the left, deterministic so it does not jump between frames.
    private static let tiles: [Tile] = {
        var out: [Tile] = []
        let kinds: [Tile.Kind] = [.reel, .waveform, .cassette, .folder, .record, .document, .waveform, .reel, .folder, .cassette, .record, .waveform]
        let labels = ["AUDIO", "RECORDINGS", "PROJECT", "STEMS", "MASTER", "VIDEO", "DOCS", "ASSETS"]
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double(seed >> 33) / Double(1 << 31) }
        var k = 0
        for col in 0..<4 {
            for row in 0..<5 {
                // Mixed wall: every row and column gets a different kind.
                let kind = kinds[(col * 5 + row * 7 + (col * row) % 3) % kinds.count]
                let w: Double, h: Double
                switch kind {
                case .reel, .record: w = 120; h = 120
                case .cassette: w = 140; h = 90
                case .folder: w = 150; h = 105
                case .document: w = 95; h = 120
                case .waveform: w = 160; h = 80
                }
                let x = 20 + Double(col) * 125 + rnd() * 30 - Double(col) * 6
                let y = 10 + Double(row) * 150 + rnd() * 40 + (col % 2 == 0 ? 0 : 60)
                out.append(Tile(kind: kind, x: x, y: y, w: w * (0.85 + rnd() * 0.25), h: h * (0.85 + rnd() * 0.25),
                                phase: rnd() * 6.28, label: labels[k % labels.count]))
                k += 1
            }
        }
        return out
    }()

    // MARK: - Drawing

    private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }

    func draw(_ ctx: GraphicsContext, _ size: CGSize) {
        // Design space 1376 × 768, scaled to fit and centred.
        let s = min(size.width / 1376, size.height / 768)
        var c = ctx
        c.translateBy(x: (size.width - 1376 * s) / 2, y: (size.height - 768 * s) / 2)
        c.scaleBy(x: s, y: s)

        drawRings(c)

        let slot = CGPoint(x: 858, y: 384)
        drawStreams(c, to: slot)
        for (i, tile) in Self.tiles.enumerated() { drawTile(c, tile, index: i) }
        drawParticles(c, to: slot)
        drawDevice(c, slot: slot)
    }

    private func drawRings(_ c: GraphicsContext) {
        let center = CGPoint(x: 1060, y: 384)
        for i in 0..<5 {
            let r = 160.0 + Double(i) * 120
            c.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)),
                     with: .color(Self.cyan.opacity(0.07)), lineWidth: 1)
        }
        // A slow sweep.
        let a = time * 0.6
        var sweep = Path()
        sweep.move(to: center)
        sweep.addLine(to: CGPoint(x: center.x + cos(a) * 700, y: center.y + sin(a) * 700))
        c.stroke(sweep, with: .color(Self.cyan.opacity(0.05)), lineWidth: 1)
    }

    /// Point on the cubic stream curve from a tile to the slot.
    private func streamPoint(from p0: CGPoint, to p3: CGPoint, spread: Double, _ u: Double) -> CGPoint {
        let p1 = CGPoint(x: p0.x + 200, y: p0.y)
        let p2 = CGPoint(x: p3.x - 220, y: p3.y + spread)
        let v = 1 - u
        let x = v * v * v * p0.x + 3 * v * v * u * p1.x + 3 * v * u * u * p2.x + u * u * u * p3.x
        let y = v * v * v * p0.y + 3 * v * v * u * p1.y + 3 * v * u * u * p2.y + u * u * u * p3.y
        return CGPoint(x: x, y: y)
    }

    private func streamStart(_ i: Int) -> CGPoint {
        let tile = Self.tiles[i]
        return CGPoint(x: tile.x + tile.w, y: tile.y + tile.h / 2)
    }

    private func drawStreams(_ c: GraphicsContext, to slot: CGPoint) {
        for i in Self.tiles.indices where Self.tiles[i].x > 250 {
            let p0 = streamStart(i)
            let spread = (p0.y - slot.y) * 0.18
            let end = CGPoint(x: slot.x, y: slot.y + (p0.y - slot.y) * 0.08)
            var path = Path()
            path.move(to: p0)
            for k in 1...40 { path.addLine(to: streamPoint(from: p0, to: end, spread: spread, Double(k) / 40)) }
            let shimmer = 0.10 + 0.08 * sin(time * 2 + Double(i))
            c.stroke(path, with: .linearGradient(Gradient(colors: [Self.cyan.opacity(0), Self.cyan.opacity(shimmer), Self.cyan.opacity(shimmer * 2.2)]),
                                                 startPoint: p0, endPoint: end), lineWidth: 1.2)
        }
    }

    private func drawParticles(_ c: GraphicsContext, to slot: CGPoint) {
        let starts = Self.tiles.indices.filter { Self.tiles[$0].x > 250 }
        for (n, i) in starts.enumerated() {
            let p0 = streamStart(i)
            let spread = (p0.y - slot.y) * 0.18
            let end = CGPoint(x: slot.x, y: slot.y + (p0.y - slot.y) * 0.08)
            for k in 0..<6 {
                let speed = 0.28 + Double((n * 3 + k) % 5) * 0.05
                let u = (time * speed + Double(k) / 6 + Double(n) * 0.13).truncatingRemainder(dividingBy: 1)
                let p = streamPoint(from: p0, to: end, spread: spread + Double(k - 3) * 6, u)
                let r = 1.4 + 1.6 * u
                let a = min(1, u * 3) * (u > 0.94 ? (1 - u) / 0.06 : 1)
                c.fill(Path(ellipseIn: CGRect(x: p.x - r * 3, y: p.y - r * 3, width: r * 6, height: r * 6)),
                       with: .color(Self.cyan.opacity(0.10 * a)))
                c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                       with: .color(.white.opacity(0.9 * a)))
            }
        }
        // Binary drizzle along the main stream.
        for k in 0..<18 {
            let u = (time * 0.18 + Double(k) / 18).truncatingRemainder(dividingBy: 1)
            let p = streamPoint(from: CGPoint(x: 520, y: 300 + Double(k % 6) * 40), to: slot, spread: 0, u)
            var t = c
            t.opacity = 0.25 * sin(u * .pi)
            t.draw(Text(k % 3 == 0 ? "1011" : (k % 3 == 1 ? "0110" : "1101"))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Self.cyan), at: p)
        }
    }

    // MARK: Tiles

    private func drawTile(_ c: GraphicsContext, _ tile: Tile, index: Int) {
        var c = c
        let bob = sin(time * 0.8 + tile.phase) * 3
        c.translateBy(x: tile.x, y: tile.y + bob)
        // Further right = brighter, a hint of depth.
        c.opacity = 0.55 + 0.45 * min(1, tile.x / 420)
        let rect = CGRect(x: 0, y: 0, width: tile.w, height: tile.h)
        let grey = Color(white: 0.30), dark = Color(white: 0.14), light = Color(white: 0.75)
        switch tile.kind {
        case .folder:
            let tab = Path(roundedRect: CGRect(x: 0, y: 0, width: tile.w * 0.42, height: tile.h * 0.3), cornerRadius: 5)
            c.fill(tab, with: .color(Color(white: 0.24)))
            let body = Path(roundedRect: CGRect(x: 0, y: tile.h * 0.15, width: tile.w, height: tile.h * 0.85), cornerRadius: 6)
            c.fill(body, with: .linearGradient(Gradient(colors: [Color(white: 0.34), Color(white: 0.2)]),
                                               startPoint: .zero, endPoint: CGPoint(x: 0, y: tile.h)))
            c.stroke(body, with: .color(.white.opacity(0.12)), lineWidth: 1)
            c.draw(Text(tile.label).font(.system(size: 13, weight: .semibold)).foregroundColor(light),
                   at: CGPoint(x: tile.w / 2, y: tile.h * 0.6))
        case .document:
            let body = Path(roundedRect: rect, cornerRadius: 4)
            c.fill(body, with: .color(Color(white: 0.82)))
            for l in 0..<6 {
                c.fill(Path(CGRect(x: 10, y: 18 + Double(l) * 14, width: tile.w * (l % 2 == 0 ? 0.7 : 0.55), height: 3)),
                       with: .color(Color(white: 0.55)))
            }
        case .waveform:
            let body = Path(roundedRect: rect, cornerRadius: 6)
            c.fill(body, with: .color(Color(red: 0.08, green: 0.12, blue: 0.17)))
            c.stroke(body, with: .color(Self.cyan.opacity(0.35)), lineWidth: 1)
            var wave = Path()
            let n = 40
            for k in 0..<n {
                let u = Double(k) / Double(n - 1)
                let amp = (0.2 + 0.8 * abs(sin(u * 9 + tile.phase + time * 1.5))) * tile.h * 0.32
                let x = 8 + u * (tile.w - 16)
                wave.addRect(CGRect(x: x, y: tile.h / 2 - amp, width: 1.6, height: amp * 2))
            }
            c.fill(wave, with: .color(Self.cyan.opacity(0.85)))
        case .record:
            let r = min(tile.w, tile.h) / 2
            let ctr = CGPoint(x: tile.w / 2, y: tile.h / 2)
            c.fill(Path(ellipseIn: CGRect(x: ctr.x - r, y: ctr.y - r, width: 2 * r, height: 2 * r)), with: .color(Color(white: 0.06)))
            for g in 1..<6 {
                let gr = r * (0.4 + Double(g) * 0.1)
                c.stroke(Path(ellipseIn: CGRect(x: ctr.x - gr, y: ctr.y - gr, width: 2 * gr, height: 2 * gr)),
                         with: .color(.white.opacity(0.06)), lineWidth: 1)
            }
            c.fill(Path(ellipseIn: CGRect(x: ctr.x - r * 0.3, y: ctr.y - r * 0.3, width: r * 0.6, height: r * 0.6)), with: .color(light))
            c.fill(Path(ellipseIn: CGRect(x: ctr.x - 3, y: ctr.y - 3, width: 6, height: 6)), with: .color(dark))
        case .reel:
            let r = min(tile.w, tile.h) / 2
            var rc = c
            rc.translateBy(x: tile.w / 2, y: tile.h / 2)
            rc.rotate(by: .radians(time * 0.9 + tile.phase))
            rc.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r)), with: .color(Color(white: 0.78)))
            rc.stroke(Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r)), with: .color(Color(white: 0.45)), lineWidth: 3)
            for h in 0..<3 {
                let a = Double(h) * 2 * .pi / 3
                let hc = CGPoint(x: cos(a) * r * 0.5, y: sin(a) * r * 0.5)
                rc.fill(Path(ellipseIn: CGRect(x: hc.x - r * 0.22, y: hc.y - r * 0.22, width: r * 0.44, height: r * 0.44)), with: .color(grey))
            }
            rc.fill(Path(ellipseIn: CGRect(x: -r * 0.16, y: -r * 0.16, width: r * 0.32, height: r * 0.32)), with: .color(dark))
        case .cassette:
            let body = Path(roundedRect: rect, cornerRadius: 6)
            c.fill(body, with: .color(Color(white: 0.22)))
            c.stroke(body, with: .color(.white.opacity(0.15)), lineWidth: 1)
            c.fill(Path(roundedRect: CGRect(x: 8, y: 8, width: tile.w - 16, height: tile.h * 0.55), cornerRadius: 3), with: .color(Color(white: 0.85)))
            for side in [0.33, 0.67] {
                let ctr = CGPoint(x: tile.w * side, y: tile.h * 0.36)
                c.fill(Path(ellipseIn: CGRect(x: ctr.x - 10, y: ctr.y - 10, width: 20, height: 20)), with: .color(dark))
            }
        }
    }

    // MARK: Device

    private func drawDevice(_ c: GraphicsContext, slot: CGPoint) {
        let body = CGRect(x: 840, y: 120, width: 460, height: 530)
        let shape = Path(roundedRect: body, cornerRadius: 44)

        // Glow where the streams enter.
        c.fill(Path(ellipseIn: CGRect(x: slot.x - 90, y: slot.y - 160, width: 180, height: 320)),
               with: .radialGradient(Gradient(colors: [Self.cyan.opacity(0.35), .clear]), center: slot, startRadius: 0, endRadius: 140))

        c.fill(shape, with: .linearGradient(Gradient(colors: [Color(white: 0.42), Color(white: 0.22), Color(white: 0.12)]),
                                            startPoint: CGPoint(x: body.minX, y: body.minY), endPoint: CGPoint(x: body.maxX, y: body.maxY)))
        c.stroke(shape, with: .color(.white.opacity(0.35)), lineWidth: 2)
        let inner = Path(roundedRect: body.insetBy(dx: 22, dy: 22), cornerRadius: 30)
        c.fill(inner, with: .color(Color(white: 0.08)))
        c.stroke(inner, with: .color(.white.opacity(0.10)), lineWidth: 1)

        // Screws.
        for p in [CGPoint(x: body.minX + 40, y: body.minY + 40), CGPoint(x: body.maxX - 40, y: body.minY + 40),
                  CGPoint(x: body.minX + 40, y: body.maxY - 40), CGPoint(x: body.maxX - 40, y: body.maxY - 40)] {
            c.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14)), with: .color(Color(white: 0.35)))
            c.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)), with: .color(Color(white: 0.15)))
        }

        // The slot on the left edge, glowing.
        let slotRect = CGRect(x: body.minX + 6, y: slot.y - 110, width: 16, height: 220)
        c.fill(Path(roundedRect: slotRect, cornerRadius: 8), with: .color(Color(white: 0.03)))
        let pulse = 0.6 + 0.4 * sin(time * 6)
        c.fill(Path(roundedRect: slotRect.insetBy(dx: 4, dy: 20), cornerRadius: 4),
               with: .color(Self.cyan.opacity(0.55 * pulse)))

        // Screen.
        let screen = CGRect(x: body.minX + 70, y: body.minY + 70, width: body.width - 120, height: body.height - 140)
        let scr = Path(roundedRect: screen, cornerRadius: 14)
        c.fill(scr, with: .linearGradient(Gradient(colors: [Color(red: 0.03, green: 0.08, blue: 0.13), Color(red: 0.02, green: 0.04, blue: 0.07)]),
                                          startPoint: CGPoint(x: 0, y: screen.minY), endPoint: CGPoint(x: 0, y: screen.maxY)))
        c.stroke(scr, with: .color(Self.cyan.opacity(0.55)), lineWidth: 2)
        // Faint HUD lines.
        for k in 0..<6 {
            let y = screen.minY + 20 + Double(k) * 3
            c.fill(Path(CGRect(x: screen.minX + 16, y: y, width: 40 - Double(k) * 5, height: 1)), with: .color(Self.cyan.opacity(0.35)))
        }

        // Title + progress.
        c.draw(Text(title).font(.system(size: 22, weight: .bold, design: .monospaced)).foregroundColor(Self.cyan),
               at: CGPoint(x: screen.midX, y: screen.minY + 58))
        let bar = CGRect(x: screen.minX + 26, y: screen.minY + 84, width: screen.width - 52, height: 26)
        c.stroke(Path(roundedRect: bar, cornerRadius: 4), with: .color(Self.cyan.opacity(0.7)), lineWidth: 1.5)
        let p = clamp(progress)
        if p > 0 {
            let fill = CGRect(x: bar.minX + 3, y: bar.minY + 3, width: (bar.width - 6) * p, height: bar.height - 6)
            c.fill(Path(roundedRect: fill, cornerRadius: 2),
                   with: .linearGradient(Gradient(colors: [Self.blue, Self.cyan]), startPoint: CGPoint(x: fill.minX, y: 0), endPoint: CGPoint(x: fill.maxX, y: 0)))
        }
        c.draw(Text("\(Int((p * 100).rounded()))%").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.white),
               at: CGPoint(x: bar.midX, y: bar.midY))
        if !detail.isEmpty {
            c.draw(Text(detail).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(Self.cyan.opacity(0.7)),
                   at: CGPoint(x: screen.midX, y: bar.maxY + 18))
        }

        // DMG EKI logo: white italic "DMG" and a glowing blue grid badge with "EKI".
        let logoY = screen.minY + 230
        c.draw(Text("DMG").font(.system(size: 56, weight: .black).italic()).foregroundColor(.white),
               at: CGPoint(x: screen.midX + 4, y: logoY), anchor: .trailing)
        let badge = CGRect(x: screen.midX + 12, y: logoY - 36, width: 136, height: 72)
        let skew = CGAffineTransform(a: 1, b: 0, c: -0.2, d: 1, tx: 0, ty: 0)
        var b = c
        b.translateBy(x: badge.minX + 8, y: badge.minY)
        b.concatenate(skew)
        let local = CGRect(x: 0, y: 0, width: badge.width, height: badge.height)
        b.fill(Path(roundedRect: local.insetBy(dx: -10, dy: -10), cornerRadius: 18),
               with: .color(Self.blue.opacity(0.18 + 0.08 * sin(time * 3))))
        let cols = 4, rows = 2
        let cw = local.width / Double(cols), rh = local.height / Double(rows)
        for col in 0..<cols {
            for row in 0..<rows {
                let lit = 0.75 + 0.25 * sin(time * 4 + Double(col + row * 2))
                b.fill(Path(roundedRect: CGRect(x: Double(col) * cw + 3, y: Double(row) * rh + 3, width: cw - 6, height: rh - 6), cornerRadius: 6),
                       with: .color(Self.blue.opacity(lit)))
            }
        }
        b.stroke(Path(roundedRect: local, cornerRadius: 10), with: .color(Self.cyan.opacity(0.9)), lineWidth: 2)
        b.draw(Text("EKI").font(.system(size: 46, weight: .black).italic()).foregroundColor(.white),
               at: CGPoint(x: local.midX, y: local.midY))

        // Bottom status row.
        c.fill(Path(CGRect(x: screen.minX + 20, y: screen.maxY - 40, width: screen.width - 40, height: 1)), with: .color(Self.cyan.opacity(0.3)))
        for k in 0..<12 {
            let on = (Int(time * 8) + k) % 5 != 0
            c.fill(Path(CGRect(x: screen.minX + 24 + Double(k) * 9, y: screen.maxY - 28, width: 5, height: 8)),
                   with: .color(Self.cyan.opacity(on ? 0.6 : 0.15)))
        }
    }
}
