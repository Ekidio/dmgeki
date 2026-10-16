import Foundation
import AppKit
import UniformTypeIdentifiers

public enum DMGItemType: String, CaseIterable, Identifiable, Codable {
    case targetApp = "Target App Bundle"
    case applicationsSymlink = "Applications Symlink"
    case file = "File"
    case folder = "Folder"
    case symlink = "Symlink"
    
    public var id: String { rawValue }
    
    public var systemIconName: String {
        switch self {
        case .targetApp:
            return "app.badge.checkmark"
        case .applicationsSymlink:
            return "folder.badge.gearshape"
        case .file:
            return "doc.fill"
        case .folder:
            return "folder.fill"
        case .symlink:
            return "link"
        }
    }
}

public struct DMGItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var sourcePath: String
    public var destinationName: String
    public var positionX: Double
    public var positionY: Double
    public var type: DMGItemType
    public var customIconPath: String?
    public var isHidden: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        sourcePath: String = "",
        destinationName: String = "",
        positionX: Double = 140,
        positionY: Double = 180,
        type: DMGItemType = .file,
        customIconPath: String? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sourcePath = sourcePath
        self.destinationName = destinationName.isEmpty ? name : destinationName
        self.positionX = positionX
        self.positionY = positionY
        self.type = type
        self.customIconPath = customIconPath
        self.isHidden = isHidden
    }
    
    public var isTargetApp: Bool {
        type == .targetApp
    }
    
    public var isApplicationsSymlink: Bool {
        type == .applicationsSymlink
    }
    
    /// Returns best available NSImage for previewing this item
    public var previewImage: NSImage {
        if let customIcon = customIconPath, !customIcon.isEmpty, FileManager.default.fileExists(atPath: customIcon) {
            if let img = ImageCache.shared.image(atPath: customIcon) {
                return img
            }
        }
        
        switch type {
        case .targetApp:
            if !sourcePath.isEmpty && FileManager.default.fileExists(atPath: sourcePath) {
                let img = ImageCache.shared.workspaceIcon(forFile: sourcePath)
                return img
            }
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                return appIcon
            }
            return NSWorkspace.shared.icon(for: .applicationBundle)
            
        case .applicationsSymlink:
            let appsPath = "/Applications"
            if FileManager.default.fileExists(atPath: appsPath) {
                return ImageCache.shared.workspaceIcon(forFile: appsPath)
            }
            return NSWorkspace.shared.icon(for: .folder)
            
        case .folder:
            if !sourcePath.isEmpty && FileManager.default.fileExists(atPath: sourcePath) {
                return ImageCache.shared.workspaceIcon(forFile: sourcePath)
            }
            return NSWorkspace.shared.icon(for: .folder)
            
        case .file, .symlink:
            if !sourcePath.isEmpty && FileManager.default.fileExists(atPath: sourcePath) {
                return ImageCache.shared.workspaceIcon(forFile: sourcePath)
            }
            let ext = (name as NSString).pathExtension
            if let utType = UTType(filenameExtension: ext) {
                return NSWorkspace.shared.icon(for: utType)
            }
            return NSWorkspace.shared.icon(for: .item)
        }
    }
}
