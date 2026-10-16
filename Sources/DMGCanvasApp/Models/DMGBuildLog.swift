import Foundation
import SwiftUI

public enum DMGLogLevel: String, Codable {
    case info
    case command
    case appleScript
    case warning
    case success
    case error
    
    public var prefix: String {
        switch self {
        case .info: return "ℹ️ [INFO]"
        case .command: return "⚡️ [EXEC]"
        case .appleScript: return "📜 [APPLESCRIPT]"
        case .warning: return "⚠️ [WARN]"
        case .success: return "✅ [SUCCESS]"
        case .error: return "❌ [ERROR]"
        }
    }
    
    public var color: Color {
        switch self {
        case .info: return Color.blue
        case .command: return Color.purple
        case .appleScript: return Color.cyan
        case .warning: return Color.orange
        case .success: return Color.green
        case .error: return Color.red
        }
    }
}

public struct DMGBuildLog: Identifiable, Codable {
    public var id: UUID
    public var timestamp: Date
    public var level: DMGLogLevel
    public var message: String
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), level: DMGLogLevel = .info, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}
