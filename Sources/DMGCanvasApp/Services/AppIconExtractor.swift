import Foundation
import AppKit

public struct AppIconExtractor {
    
    /// Finds or extracts the native .icns icon file from a macOS application (.app) bundle
    public static func findAppIconICNS(from appPath: String) -> String? {
        guard !appPath.isEmpty, FileManager.default.fileExists(atPath: appPath) else {
            return nil
        }
        
        let fileManager = FileManager.default
        let isDirectory = (try? appPath.asURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        
        // 1. Direct .icns file
        if appPath.hasSuffix(".icns") {
            return appPath
        }
        
        // 2. If it's a .app bundle, check Contents/Info.plist
        if appPath.hasSuffix(".app") || isDirectory {
            let plistPath = (appPath as NSString).appendingPathComponent("Contents/Info.plist")
            if fileManager.fileExists(atPath: plistPath),
               let infoDict = NSDictionary(contentsOfFile: plistPath) {
                // Check CFBundleIconFile or CFBundleIconName
                if let iconFileName = (infoDict["CFBundleIconFile"] as? String) ?? (infoDict["CFBundleIconName"] as? String) {
                    var candidate = iconFileName
                    if !candidate.hasSuffix(".icns") {
                        candidate += ".icns"
                    }
                    let resPath = (appPath as NSString).appendingPathComponent("Contents/Resources/\(candidate)")
                    if fileManager.fileExists(atPath: resPath) {
                        return resPath
                    }
                }
            }
            
            // 3. Fallback: Search Contents/Resources for any .icns file
            let resourcesDir = (appPath as NSString).appendingPathComponent("Contents/Resources")
            if let files = try? fileManager.contentsOfDirectory(atPath: resourcesDir) {
                // Prioritize files named AppIcon.icns or icon.icns
                if let appIcon = files.first(where: { $0.lowercased() == "appicon.icns" }) {
                    return (resourcesDir as NSString).appendingPathComponent(appIcon)
                }
                if let anyIcns = files.first(where: { $0.hasSuffix(".icns") }) {
                    return (resourcesDir as NSString).appendingPathComponent(anyIcns)
                }
            }
        }
        
        // 4. Fallback: Generate an .icns from NSWorkspace icon
        let icon = NSWorkspace.shared.icon(forFile: appPath)
        return exportIconToTemporaryICNS(icon: icon, identifier: (appPath as NSString).lastPathComponent)
    }
    
    /// Exports an NSImage to a cached temporary .icns file
    private static func exportIconToTemporaryICNS(icon: NSImage, identifier: String) -> String? {
        let tempDir = NSTemporaryDirectory() + "dmgeki_extracted_icons"
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        
        let sanitized = identifier.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: " ", with: "_")
        let targetPath = (tempDir as NSString).appendingPathComponent("\(sanitized).icns")
        
        if FileManager.default.fileExists(atPath: targetPath) {
            return targetPath
        }
        
        guard let tiffData = icon.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        // Create iconset directory to build multi-resolution .icns via iconutil
        let iconsetPath = (tempDir as NSString).appendingPathComponent("\(sanitized).iconset")
        try? FileManager.default.removeItem(atPath: iconsetPath)
        try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: iconsetPath) }
        
        let sizes: [(name: String, px: Int)] = [
            ("icon_16x16.png", 16),
            ("icon_16x16@2x.png", 32),
            ("icon_32x32.png", 32),
            ("icon_32x32@2x.png", 64),
            ("icon_128x128.png", 128),
            ("icon_128x128@2x.png", 256),
            ("icon_256x256.png", 256),
            ("icon_256x256@2x.png", 512),
            ("icon_512x512.png", 512),
            ("icon_512x512@2x.png", 1024)
        ]
        
        for item in sizes {
            let itemUrl = URL(fileURLWithPath: (iconsetPath as NSString).appendingPathComponent(item.name))
            if let resizedData = resizeImageToPNGData(rep: rep, size: item.px) {
                try? resizedData.write(to: itemUrl)
            }
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetPath, "-o", targetPath]
        try? process.run()
        process.waitUntilExit()
        
        if FileManager.default.fileExists(atPath: targetPath) {
            return targetPath
        }
        
        return nil
    }
    
    private static func resizeImageToPNGData(rep: NSBitmapImageRep, size: Int) -> Data? {
        let cgSize = CGSize(width: size, height: size)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: size,
                height: size,
                bitsPerComponent: 8,
                bytesPerRow: size * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              let cgImage = rep.cgImage else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: cgSize))
        
        guard let outputCGImage = context.makeImage() else { return nil }
        let newRep = NSBitmapImageRep(cgImage: outputCGImage)
        return newRep.representation(using: .png, properties: [:])
    }
}

private extension String {
    var asURL: URL {
        URL(fileURLWithPath: self)
    }
}
