import SwiftUI
import AppKit

public struct ScriptExportSheetView: View {
    let script: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var copied: Bool = false
    
    public init(script: String) {
        self.script = script
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Export Standalone CI/CD Build Script", systemImage: "terminal.fill")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
            
            Divider()
            
            // Script Preview
            ScrollView {
                Text(script)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .textSelection(.enabled)
            }
            .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            // Bottom Bar
            HStack {
                Text("Run this script directly in terminal or add it to GitHub Actions / Xcode Cloud.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: copyToClipboard) {
                    Label(copied ? "Copied!" : "Copy to Clipboard", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                Button(action: saveScriptToFile) {
                    Label("Save build_dmg.sh...", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 680, height: 480)
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(script, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
    
    private func saveScriptToFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "build_dmg.sh"
        panel.title = "Save Build Script"
        if panel.runModal() == .OK, let url = panel.url {
            try? script.write(to: url, atomically: true, encoding: .utf8)
            // Make executable chmod +x
            _ = try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            dismiss()
        }
    }
}
