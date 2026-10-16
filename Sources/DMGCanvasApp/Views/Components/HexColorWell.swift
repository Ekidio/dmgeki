import SwiftUI
import AppKit

/// AppKit color well bound directly to a hex string.
///
/// Replaces SwiftUI `ColorPicker`, whose `Color` <-> hex round-trip (with color-space
/// conversion) made the binding fire endlessly while the color panel / eyedropper was
/// active. That flooded the main thread while the system eyedropper held the cursor,
/// freezing the mouse until reboot. Here updates are coalesced to one per run-loop pass
/// and only committed when the hex value actually changes.
public struct HexColorWell: NSViewRepresentable {
    @Binding var hex: String

    public init(hex: Binding<String>) {
        self._hex = hex
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(hex: $hex)
    }

    public func makeNSView(context: Context) -> NSColorWell {
        let well = NSColorWell(frame: NSRect(x: 0, y: 0, width: 44, height: 24))
        if #available(macOS 13.0, *) {
            well.colorWellStyle = .minimal
        }
        well.color = Self.nsColor(from: hex)
        well.target = context.coordinator
        well.action = #selector(Coordinator.colorChanged(_:))
        NSColorPanel.shared.showsAlpha = false
        return well
    }

    public func updateNSView(_ well: NSColorWell, context: Context) {
        context.coordinator.hex = $hex
        // Only push the model value into the well when it really differs,
        // otherwise setting `color` would re-trigger the panel.
        if Self.hexString(from: well.color) != hex.uppercased() {
            well.color = Self.nsColor(from: hex)
        }
    }

    public static func dismantleNSView(_ well: NSColorWell, coordinator: Coordinator) {
        well.deactivate()
        well.target = nil
    }

    public final class Coordinator: NSObject {
        var hex: Binding<String>
        private var pendingHex: String?

        init(hex: Binding<String>) {
            self.hex = hex
        }

        @objc func colorChanged(_ sender: NSColorWell) {
            let newHex = HexColorWell.hexString(from: sender.color)
            let alreadyScheduled = pendingHex != nil
            pendingHex = newHex
            guard !alreadyScheduled else { return }
            // Coalesce bursts of panel/eyedropper updates into a single model write.
            DispatchQueue.main.async { [weak self] in
                guard let self, let value = self.pendingHex else { return }
                self.pendingHex = nil
                if self.hex.wrappedValue.uppercased() != value {
                    self.hex.wrappedValue = value
                }
            }
        }
    }

    // MARK: - Hex helpers

    static func hexString(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(round(min(max(rgb.redComponent, 0), 1) * 255.0))
        let g = Int(round(min(max(rgb.greenComponent, 0), 1) * 255.0))
        let b = Int(round(min(max(rgb.blueComponent, 0), 1) * 255.0))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    static func nsColor(from hex: String) -> NSColor {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") { clean.removeFirst() }
        guard clean.count == 6, let value = UInt64(clean, radix: 16) else { return .black }
        return NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
