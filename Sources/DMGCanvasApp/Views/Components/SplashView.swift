import SwiftUI
import AppKit
import AVFoundation

/// Start-up splash: files, tapes, records and folders stream into the DMGEKI drive while its screen
/// counts "CREATING DISC IMAGE…" up to 100 %, with a mechanical sound. Click to skip.
public struct SplashView: View {
    let onDone: () -> Void
    @State private var start = Date()
    @State private var leaving = false
    @State private var sound: AVAudioPlayer?

    static let total: Double = 2.9
    /// The bar runs from 0 to 100 % over this span.
    static let fillStart: Double = 0.35, fillEnd: Double = 2.25

    public init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }

    public var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(start)
            let u = min(1, max(0, (t - Self.fillStart) / (Self.fillEnd - Self.fillStart)))
            let eased = u < 0.5 ? 2 * u * u : 1 - pow(-2 * u + 2, 2) / 2
            DataStreamDriveScene(progress: eased,
                                 title: u >= 1 ? "DISC IMAGE READY" : "CREATING DISC IMAGE…",
                                 detail: "DISK IMAGE · LAYOUT · BUILD",
                                 time: t)
                .opacity(min(1, t / 0.35))
        }
        .ignoresSafeArea()
        .opacity(leaving ? 0 : 1)
        .scaleEffect(leaving ? 1.04 : 1)
        .animation(.easeIn(duration: 0.45), value: leaving)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear {
            // macOS window restoration may reopen the shared color panel over the splash.
            if NSColorPanel.sharedColorPanelExists {
                NSColorPanel.shared.orderOut(nil)
            }
            start = Date()
            sound = MechanicalSound.splash().player()
            sound?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.total) { finish() }
        }
    }

    private func finish() {
        guard !leaving else { return }
        leaving = true
        sound?.setVolume(0, fadeDuration: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onDone() }
    }
}
