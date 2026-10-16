import Foundation

public struct DMGWindowSettings: Codable, Equatable {
    public static let standardWidth: Double = 540
    public static let standardHeight: Double = 350
    
    /// DMG Window width is strictly locked to 540 pt
    public var width: Double {
        get { Self.standardWidth }
        set { }
    }
    
    /// DMG Window height is strictly locked to 350 pt
    public var height: Double {
        get { Self.standardHeight }
        set { }
    }
    
    /// Exact vertical center for items in the locked 540x350 window: 175.0 pt
    public var verticalCenter: Double {
        Self.standardHeight / 2.0
    }
    
    public var spawnPositionX: Double
    public var spawnPositionY: Double
    public var centerOnScreen: Bool
    public var title: String
    
    // Icon & Label styling
    public var iconSize: Double
    public var textSize: Double
    public var labelOnBottom: Bool
    public var labelColorHex: String
    
    // Finder chrome settings
    public var showToolbar: Bool
    public var showPathbar: Bool
    public var showStatusbar: Bool
    public var showSidebar: Bool
    
    enum CodingKeys: String, CodingKey {
        case width, height, spawnPositionX, spawnPositionY, centerOnScreen, title
        case iconSize, textSize, labelOnBottom, labelColorHex
        case showToolbar, showPathbar, showStatusbar, showSidebar
    }
    
    public init(
        width: Double = standardWidth,
        height: Double = standardHeight,
        spawnPositionX: Double = 240,
        spawnPositionY: Double = 160,
        centerOnScreen: Bool = true,
        title: String = "",
        iconSize: Double = 112,
        textSize: Double = 12,
        labelOnBottom: Bool = true,
        labelColorHex: String = "#000000",
        showToolbar: Bool = false,
        showPathbar: Bool = false,
        showStatusbar: Bool = false,
        showSidebar: Bool = false
    ) {
        self.spawnPositionX = spawnPositionX
        self.spawnPositionY = spawnPositionY
        self.centerOnScreen = centerOnScreen
        self.title = title
        self.iconSize = iconSize
        self.textSize = textSize
        self.labelOnBottom = labelOnBottom
        self.labelColorHex = labelColorHex
        self.showToolbar = showToolbar
        self.showPathbar = showPathbar
        self.showStatusbar = showStatusbar
        self.showSidebar = showSidebar
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.spawnPositionX = try container.decodeIfPresent(Double.self, forKey: .spawnPositionX) ?? 240
        self.spawnPositionY = try container.decodeIfPresent(Double.self, forKey: .spawnPositionY) ?? 160
        self.centerOnScreen = try container.decodeIfPresent(Bool.self, forKey: .centerOnScreen) ?? true
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.iconSize = try container.decodeIfPresent(Double.self, forKey: .iconSize) ?? 112
        self.textSize = try container.decodeIfPresent(Double.self, forKey: .textSize) ?? 12
        self.labelOnBottom = try container.decodeIfPresent(Bool.self, forKey: .labelOnBottom) ?? true
        self.labelColorHex = try container.decodeIfPresent(String.self, forKey: .labelColorHex) ?? "#000000"
        self.showToolbar = try container.decodeIfPresent(Bool.self, forKey: .showToolbar) ?? false
        self.showPathbar = try container.decodeIfPresent(Bool.self, forKey: .showPathbar) ?? false
        self.showStatusbar = try container.decodeIfPresent(Bool.self, forKey: .showStatusbar) ?? false
        self.showSidebar = try container.decodeIfPresent(Bool.self, forKey: .showSidebar) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.standardWidth, forKey: .width)
        try container.encode(Self.standardHeight, forKey: .height)
        try container.encode(spawnPositionX, forKey: .spawnPositionX)
        try container.encode(spawnPositionY, forKey: .spawnPositionY)
        try container.encode(centerOnScreen, forKey: .centerOnScreen)
        try container.encode(title, forKey: .title)
        try container.encode(iconSize, forKey: .iconSize)
        try container.encode(textSize, forKey: .textSize)
        try container.encode(labelOnBottom, forKey: .labelOnBottom)
        try container.encode(labelColorHex, forKey: .labelColorHex)
        try container.encode(showToolbar, forKey: .showToolbar)
        try container.encode(showPathbar, forKey: .showPathbar)
        try container.encode(showStatusbar, forKey: .showStatusbar)
        try container.encode(showSidebar, forKey: .showSidebar)
    }
}
