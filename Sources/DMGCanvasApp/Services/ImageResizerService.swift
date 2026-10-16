import Foundation
import AppKit

public struct ImageResizerService {
    
    public static let targetWidth: CGFloat = 540
    public static let targetHeight: CGFloat = 350
    
    /// Reads an image from sourcePath and resizes/crops it to strictly 540x350 pt (1080x700 px @2x Retina).
    /// Saves the resized image to a persistent cache directory and returns the new image file path.
    public static func resizeImageTo540x350(from sourcePath: String) -> String? {
        guard FileManager.default.fileExists(atPath: sourcePath),
              let sourceImage = NSImage(contentsOfFile: sourcePath) else {
            return nil
        }
        
        let targetWidthPt: CGFloat = targetWidth
        let targetHeightPt: CGFloat = targetHeight
        let scale: CGFloat = 2.0 // High-DPI 2x Retina
        let pixelWidth = Int(targetWidthPt * scale)
        let pixelHeight = Int(targetHeightPt * scale)
        
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        
        bitmapRep.size = NSSize(width: targetWidthPt, height: targetHeightPt)
        
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current = context
        context?.imageInterpolation = .high
        
        // Compute aspect fill crop rectangle
        let sourceSize = sourceImage.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        
        let scaleX = targetWidthPt / sourceSize.width
        let scaleY = targetHeightPt / sourceSize.height
        let fitScale = max(scaleX, scaleY)
        
        let scaledWidth = sourceSize.width * fitScale
        let scaledHeight = sourceSize.height * fitScale
        let originX = (targetWidthPt - scaledWidth) / 2.0
        let originY = (targetHeightPt - scaledHeight) / 2.0
        
        let drawRect = NSRect(x: originX, y: originY, width: scaledWidth, height: scaledHeight)
        sourceImage.draw(
            in: drawRect,
            from: NSRect(origin: .zero, size: sourceSize),
            operation: .copy,
            fraction: 1.0
        )
        
        NSGraphicsContext.restoreGraphicsState()
        
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        // Write to application cache directory
        let cacheDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("DMGEKI_Resized")
        try? FileManager.default.createDirectory(atPath: cacheDir, withIntermediateDirectories: true)
        
        let sourceName = (sourcePath as NSString).deletingPathExtension.components(separatedBy: "/").last ?? "background"
        let destPath = (cacheDir as NSString).appendingPathComponent("\(sourceName)_540x350.png")
        
        do {
            try pngData.write(to: URL(fileURLWithPath: destPath), options: .atomic)
            return destPath
        } catch {
            return nil
        }
    }
    
    /// Returns the pixel dimensions of an image at path.
    public static func getImageDimensions(from path: String) -> (width: Int, height: Int)? {
        guard let image = ImageCache.shared.image(atPath: path) else {
            return nil
        }
        if let rep = image.representations.first {
            return (width: rep.pixelsWide, height: rep.pixelsHigh)
        }
        return (width: Int(image.size.width), height: Int(image.size.height))
    }
}
