import SwiftUI
import AVFoundation

/// Shown while a DMG is building: the data-stream drive scene with the builder's real progress and stage.
/// When the build finishes, MainView swaps it for the "DMG Ready" card.
struct BuildProgressView: View {
    @ObservedObject var builder: DMGBuilderService
    @State private var start = Date()
    @State private var sound: AVAudioPlayer?

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.animation) { tl in
                DataStreamDriveScene(progress: builder.progress,
                                     title: "CREATING DISC IMAGE…",
                                     detail: shortStage,
                                     time: tl.date.timeIntervalSince(start))
            }
            .ignoresSafeArea()

            Button {
                builder.cancelBuild()
            } label: {
                Text("Cancel")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(white: 0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .padding(.bottom, 28)
        }
        .onAppear {
            start = Date()
            sound = MechanicalSound.buildStart().player()
            sound?.play()
        }
    }

    /// "Converting to final compressed format (UDZO)..." → "CONVERTING TO FINAL COMPRESSED FORMAT"
    private var shortStage: String {
        var s = builder.currentStage
        if let paren = s.firstIndex(of: "(") { s = String(s[..<paren]) }
        s = s.replacingOccurrences(of: "...", with: "").trimmingCharacters(in: .whitespaces)
        if s.count > 38 { s = String(s.prefix(37)) + "…" }
        return s.uppercased()
    }
}
