import Foundation
import AppKit

/// In-memory image cache keyed by file path + modification date.
/// SwiftUI view bodies re-evaluate on every project change (e.g. each color-panel /
/// eyedropper update), so decoding images from disk inside `body` blocks the main thread.
public final class ImageCache {
    public static let shared = ImageCache()

    private let cache = NSCache<NSString, NSImage>()
    private let iconCache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 64
        iconCache.countLimit = 64
    }

    private func key(for path: String) -> NSString? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
        return "\(path)|\(mtime)|\(size)" as NSString
    }

    /// Returns the image at `path`, decoding it from disk only when not cached.
    public func image(atPath path: String) -> NSImage? {
        guard !path.isEmpty, let key = key(for: path) else { return nil }
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    /// Cached `NSWorkspace` file icon.
    public func workspaceIcon(forFile path: String) -> NSImage {
        let key = (self.key(for: path) ?? path as NSString)
        if let cached = iconCache.object(forKey: key) { return cached }
        let icon = NSWorkspace.shared.icon(forFile: path)
        iconCache.setObject(icon, forKey: key)
        return icon
    }
}
