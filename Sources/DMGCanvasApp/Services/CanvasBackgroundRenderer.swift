import Foundation
import SwiftUI
import AppKit

public struct CanvasBackgroundRenderer {
    
    /// Renders high-DPI Retina background image assets (.tiff and .png) for the DMG installer window.
    @MainActor
    public static func renderBackground(for project: DMGProject, outputDirectory: String) throws -> (tiffPath: String, pngPath: String) {
        let width = CGFloat(project.window.width)
        let height = CGFloat(project.window.height)
        
        let contentView = CanvasBackgroundContentView(project: project)
            .frame(width: width, height: height)
        
        // 1x Standard Renderer
        let renderer1x = ImageRenderer(content: contentView)
        renderer1x.scale = 1.0
        guard let nsImage1x = renderer1x.nsImage else {
            throw NSError(
                domain: "CanvasBackgroundRenderer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to render 1x background image."]
            )
        }
        
        // 2x Retina Renderer
        let renderer2x = ImageRenderer(content: contentView)
        renderer2x.scale = 2.0
        guard let nsImage2x = renderer2x.nsImage else {
            throw NSError(
                domain: "CanvasBackgroundRenderer",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to render 2x Retina background image."]
            )
        }
        
        let tempUUID = UUID().uuidString.prefix(8)
        let tmpDir = (outputDirectory as NSString).appendingPathComponent(".tmp_bg_\(tempUUID)")
        try FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(atPath: tmpDir)
        }
        
        let path1x = (tmpDir as NSString).appendingPathComponent("bg_1x.tiff")
        let path2x = (tmpDir as NSString).appendingPathComponent("bg_2x.tiff")
        let outTiff = (outputDirectory as NSString).appendingPathComponent("background.tiff")
        let outPng = (outputDirectory as NSString).appendingPathComponent("background.png")
        
        // 1. Write 1x TIFF
        if let tiffData1x = nsImage1x.tiffRepresentation {
            try tiffData1x.write(to: URL(fileURLWithPath: path1x))
        }
        
        // 2. Write 2x TIFF and PNG
        if let tiffData2x = nsImage2x.tiffRepresentation {
            try tiffData2x.write(to: URL(fileURLWithPath: path2x))
            
            if let rep = NSBitmapImageRep(data: tiffData2x),
               let pngData = rep.representation(using: .png, properties: [:]) {
                try pngData.write(to: URL(fileURLWithPath: outPng))
            }
        }
        
        // 3. Combine 1x and 2x into high-DPI multi-resolution TIFF via tiffutil
        let tiffProcess = Process()
        tiffProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tiffutil")
        tiffProcess.arguments = ["-cathidpicheck", path1x, path2x, "-out", outTiff]
        try? tiffProcess.run()
        tiffProcess.waitUntilExit()
        
        // Fallback if tiffutil could not run
        if !FileManager.default.fileExists(atPath: outTiff) {
            if let fallbackTiff = nsImage2x.tiffRepresentation {
                try fallbackTiff.write(to: URL(fileURLWithPath: outTiff))
            }
        }
        
        return (tiffPath: outTiff, pngPath: outPng)
    }
}
