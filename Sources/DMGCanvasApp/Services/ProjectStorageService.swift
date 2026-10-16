import Foundation
import AppKit

public class ProjectStorageService {
    public static let shared = ProjectStorageService()
    
    private init() {}
    
    public func saveProject(_ project: DMGProject, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(project)
        try data.write(to: url, options: .atomic)
    }
    
    public func loadProject(from url: URL) throws -> DMGProject {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(DMGProject.self, from: data)
    }
    
    @MainActor
    public func promptSaveProject(_ project: DMGProject) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Save DMG Canvas Project"
        panel.nameFieldStringValue = "\(project.name.replacingOccurrences(of: " ", with: "_")).dmgproj"
        panel.allowedContentTypes = []
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK {
            return panel.url
        }
        return nil
    }
    
    @MainActor
    public func promptOpenProject() -> DMGProject? {
        let panel = NSOpenPanel()
        panel.title = "Open DMG Canvas Project"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                return try loadProject(from: url)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to open project"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
        return nil
    }
}
