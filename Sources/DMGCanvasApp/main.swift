import SwiftUI
import AppKit

@main
struct DMGCanvasApp: App {
    init() {
        // Apply DMGEKI branding icon to macOS dock and application
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        } else if let fallback = NSImage(contentsOfFile: "Resources/AppIcon.icns") {
            NSApplication.shared.applicationIconImage = fallback
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1100, idealWidth: 1280, minHeight: 700, idealHeight: 820)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    // Handled inside app or via notification
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button {
                    NotificationCenter.default.post(name: .dmgOpenProject, object: nil)
                } label: {
                    Label("Open Project…", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandGroup(replacing: .saveItem) {
                Button {
                    NotificationCenter.default.post(name: .dmgSaveProject, object: nil)
                } label: {
                    Label("Save Project…", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    /// Menu bar → MainView: open a .dmgproj configuration.
    static let dmgOpenProject = Notification.Name("DMGEKI.openProject")
    /// Menu bar → MainView: save the current .dmgproj configuration.
    static let dmgSaveProject = Notification.Name("DMGEKI.saveProject")
}
