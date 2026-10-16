import SwiftUI
import AppKit

@main
struct DMGCanvasApp: App {
    @StateObject private var updater = Updater.shared
    
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
                // Wide enough for sidebar (260) + canvas (500) + inspector (330) + dividers; a narrower
                // window makes the split view loop on its constraints and crash at launch.
                .frame(minWidth: 1180, idealWidth: 1380, minHeight: 700, idealHeight: 860)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1380, height: 860)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheckForUpdates)
            }
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
