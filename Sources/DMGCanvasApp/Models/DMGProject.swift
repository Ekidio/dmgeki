import Foundation

public enum DMGArrowStyle: String, CaseIterable, Identifiable, Codable {
    case curved = "Curved"
    case straight = "Straight"
    case gradient = "Glow Gradient"
    case minimal = "Minimal Line"
    case none = "None"
    
    public var id: String { rawValue }
}

public enum DMGBackgroundPreset: String, CaseIterable, Identifiable, Codable {
    case modernGradient = "Modern Gradient"
    case darkMinimal = "Dark Minimal"
    case lightMinimal = "Light Minimal"
    case oceanBlue = "Ocean Blue"
    case customImage = "Custom Image"
    
    public var id: String { rawValue }
}

public enum DMGImageScalingMode: String, CaseIterable, Identifiable, Codable {
    case fill = "Fill"
    case fit = "Fit"
    case stretch = "Stretch"
    
    public var id: String { rawValue }
}

public struct DMGProject: Identifiable, Codable, Equatable {
    public var id: UUID
    public var version: String
    public var name: String
    public var volumeName: String
    public var outputFileName: String
    public var outputDirectory: String
    
    // Window settings (Strictly 540x350)
    public var window: DMGWindowSettings
    
    // Items
    public var items: [DMGItem]
    
    // Background and Volume Assets
    public var backgroundImagePath: String?
    public var backgroundRetinaImagePath: String?
    public var backgroundPreset: DMGBackgroundPreset
    public var backgroundImageScale: Double
    public var backgroundImageScalingMode: DMGImageScalingMode
    public var backgroundOverlayColorHex: String
    public var backgroundOverlayOpacity: Double
    public var includeArrowInBackground: Bool
    public var showWatermark: Bool
    public var watermarkText: String
    public var volumeIconPath: String?
    
    // Build and Compression (Hardcoded to UDZO)
    public var format: DMGCompressionFormat
    public var compressionLevel: Int
    
    // Canvas WYSIWYG Guides
    public var showGrid: Bool
    public var gridSpacing: Double
    public var snapToGrid: Bool
    public var snapToGuides: Bool
    public var showArrow: Bool
    public var arrowStyle: DMGArrowStyle
    
    public init(
        id: UUID = UUID(),
        version: String = "1.0",
        name: String = "App Installer",
        volumeName: String = "App Installer",
        outputFileName: String = "App-Installer.dmg",
        outputDirectory: String = ("~/Desktop" as NSString).expandingTildeInPath,
        window: DMGWindowSettings = DMGWindowSettings(),
        items: [DMGItem] = [],
        backgroundImagePath: String? = nil,
        backgroundRetinaImagePath: String? = nil,
        backgroundPreset: DMGBackgroundPreset = .lightMinimal,
        backgroundImageScale: Double = 1.0,
        backgroundImageScalingMode: DMGImageScalingMode = .fill,
        backgroundOverlayColorHex: String = "#000000",
        backgroundOverlayOpacity: Double = 0.0,
        includeArrowInBackground: Bool = true,
        showWatermark: Bool = true,
        watermarkText: String = "Drag to Applications to Install",
        volumeIconPath: String? = nil,
        format: DMGCompressionFormat = .udzo,
        compressionLevel: Int = 9,
        showGrid: Bool = false,
        gridSpacing: Double = 20,
        snapToGrid: Bool = true,
        snapToGuides: Bool = true,
        showArrow: Bool = true,
        arrowStyle: DMGArrowStyle = .curved
    ) {
        self.id = id
        self.version = version
        self.name = name
        self.volumeName = volumeName
        self.outputFileName = outputFileName
        self.outputDirectory = outputDirectory
        self.window = window
        self.items = items
        self.backgroundImagePath = backgroundImagePath
        self.backgroundRetinaImagePath = backgroundRetinaImagePath
        self.backgroundPreset = backgroundPreset
        self.backgroundImageScale = backgroundImageScale
        self.backgroundImageScalingMode = backgroundImageScalingMode
        self.backgroundOverlayColorHex = backgroundOverlayColorHex
        self.backgroundOverlayOpacity = backgroundOverlayOpacity
        self.includeArrowInBackground = includeArrowInBackground
        self.showWatermark = showWatermark
        self.watermarkText = watermarkText
        self.volumeIconPath = volumeIconPath
        self.format = .udzo
        self.compressionLevel = 9
        self.showGrid = showGrid
        self.gridSpacing = gridSpacing
        self.snapToGrid = snapToGrid
        self.snapToGuides = snapToGuides
        self.showArrow = showArrow
        self.arrowStyle = arrowStyle
    }
    
    // MARK: - Backward-compatible Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0"
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "App Installer"
        self.volumeName = try container.decodeIfPresent(String.self, forKey: .volumeName) ?? "App Installer"
        self.outputFileName = try container.decodeIfPresent(String.self, forKey: .outputFileName) ?? "App-Installer.dmg"
        self.outputDirectory = try container.decodeIfPresent(String.self, forKey: .outputDirectory) ?? ("~/Desktop" as NSString).expandingTildeInPath
        self.window = try container.decodeIfPresent(DMGWindowSettings.self, forKey: .window) ?? DMGWindowSettings()
        self.items = try container.decodeIfPresent([DMGItem].self, forKey: .items) ?? []
        self.backgroundImagePath = try container.decodeIfPresent(String.self, forKey: .backgroundImagePath)
        self.backgroundRetinaImagePath = try container.decodeIfPresent(String.self, forKey: .backgroundRetinaImagePath)
        self.backgroundPreset = try container.decodeIfPresent(DMGBackgroundPreset.self, forKey: .backgroundPreset) ?? .lightMinimal
        self.backgroundImageScale = try container.decodeIfPresent(Double.self, forKey: .backgroundImageScale) ?? 1.0
        self.backgroundImageScalingMode = try container.decodeIfPresent(DMGImageScalingMode.self, forKey: .backgroundImageScalingMode) ?? .fill
        self.backgroundOverlayColorHex = try container.decodeIfPresent(String.self, forKey: .backgroundOverlayColorHex) ?? "#000000"
        self.backgroundOverlayOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOverlayOpacity) ?? 0.0
        self.includeArrowInBackground = try container.decodeIfPresent(Bool.self, forKey: .includeArrowInBackground) ?? true
        self.showWatermark = try container.decodeIfPresent(Bool.self, forKey: .showWatermark) ?? true
        self.watermarkText = try container.decodeIfPresent(String.self, forKey: .watermarkText) ?? "Drag to Applications to Install"
        self.volumeIconPath = try container.decodeIfPresent(String.self, forKey: .volumeIconPath)
        // Compression is always enforced as UDZO (zlib)
        self.format = .udzo
        self.compressionLevel = 9
        self.showGrid = try container.decodeIfPresent(Bool.self, forKey: .showGrid) ?? false
        self.gridSpacing = try container.decodeIfPresent(Double.self, forKey: .gridSpacing) ?? 20
        self.snapToGrid = try container.decodeIfPresent(Bool.self, forKey: .snapToGrid) ?? true
        self.snapToGuides = try container.decodeIfPresent(Bool.self, forKey: .snapToGuides) ?? true
        self.showArrow = try container.decodeIfPresent(Bool.self, forKey: .showArrow) ?? true
        self.arrowStyle = try container.decodeIfPresent(DMGArrowStyle.self, forKey: .arrowStyle) ?? .curved
        
        // Guarantee /Applications shortcut is always present
        if !self.items.contains(where: { $0.isApplicationsSymlink }) {
            self.items.append(
                DMGItem(
                    name: "Applications",
                    sourcePath: "/Applications",
                    destinationName: "Applications",
                    positionX: 400,
                    positionY: 175,
                    type: .applicationsSymlink
                )
            )
        }
    }
    
    // MARK: - Factory Templates (All standardized to 540x350 and centered vertically at Y = 175)
    
    public static var defaultProject: DMGProject {
        var project = DMGProject(
            name: "Standard Installer",
            volumeName: "App Installer",
            outputFileName: "App-Installer.dmg",
            backgroundPreset: .lightMinimal
        )
        project.includeArrowInBackground = false
        project.items = [
            DMGItem(
                name: "YourApp.app",
                sourcePath: "",
                destinationName: "YourApp.app",
                positionX: 140,
                positionY: 175,
                type: .targetApp
            ),
            DMGItem(
                name: "Applications",
                sourcePath: "/Applications",
                destinationName: "Applications",
                positionX: 400,
                positionY: 175,
                type: .applicationsSymlink
            )
        ]
        return project
    }
    
    public static var minimalProject: DMGProject {
        var project = DMGProject(
            name: "Minimal Drop Installer",
            volumeName: "App Installer",
            outputFileName: "App-Installer.dmg",
            backgroundPreset: .darkMinimal
        )
        project.includeArrowInBackground = true
        project.items = [
            DMGItem(
                name: "Application.app",
                sourcePath: "",
                destinationName: "Application.app",
                positionX: 140,
                positionY: 175,
                type: .targetApp
            ),
            DMGItem(
                name: "Applications",
                sourcePath: "/Applications",
                destinationName: "Applications",
                positionX: 400,
                positionY: 175,
                type: .applicationsSymlink
            )
        ]
        project.arrowStyle = .minimal
        return project
    }
    
    public static var developerSuiteProject: DMGProject {
        var project = DMGProject(
            name: "Dark Studio Installer",
            volumeName: "Studio Installer",
            outputFileName: "Studio-Installer.dmg",
            backgroundPreset: .darkMinimal
        )
        project.includeArrowInBackground = true
        project.items = [
            DMGItem(
                name: "Studio.app",
                sourcePath: "",
                destinationName: "Studio.app",
                positionX: 140,
                positionY: 175,
                type: .targetApp
            ),
            DMGItem(
                name: "Applications",
                sourcePath: "/Applications",
                destinationName: "Applications",
                positionX: 400,
                positionY: 175,
                type: .applicationsSymlink
            )
        ]
        project.showArrow = true
        project.arrowStyle = .gradient
        return project
    }
    
    // MARK: - Auto-Center Icons Vertically (Strictly Y = 175.0 pt)
    
    public mutating func autoCenterIconsVertically() {
        if !items.contains(where: { $0.isApplicationsSymlink }) {
            items.append(
                DMGItem(
                    name: "Applications",
                    sourcePath: "/Applications",
                    destinationName: "Applications",
                    positionX: 400,
                    positionY: window.verticalCenter,
                    type: .applicationsSymlink
                )
            )
        }
        let centerY = window.verticalCenter
        for i in 0..<items.count {
            items[i].positionY = centerY
        }
    }
    
    // MARK: - Effective Volume Icon Resolution
    
    /// Returns custom .icns if chosen; otherwise falls back automatically to the imported application's .icns
    public var effectiveVolumeIconPath: String? {
        if let customPath = volumeIconPath, !customPath.isEmpty, FileManager.default.fileExists(atPath: customPath) {
            return customPath
        }
        if let targetApp = items.first(where: { $0.isTargetApp }), !targetApp.sourcePath.isEmpty {
            return AppIconExtractor.findAppIconICNS(from: targetApp.sourcePath)
        }
        return nil
    }
}
