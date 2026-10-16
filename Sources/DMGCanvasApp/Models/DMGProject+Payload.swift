import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - Importing files & folders into the DMG payload

extension DMGProject {

    /// Extra payload items: everything except the target app and the /Applications shortcut.
    public var extraItems: [DMGItem] {
        items.filter { !$0.isTargetApp && !$0.isApplicationsSymlink }
    }

    /// Imports dropped / chosen URLs. A `.app` becomes the target application while none is set;
    /// everything else is added as an extra file or folder. `at` places the first item at that
    /// point of the canvas (the rest follow to its right). Returns the last added item's id.
    @discardableResult
    public mutating func importPayload(_ urls: [URL], at point: CGPoint? = nil) -> UUID? {
        var lastID: UUID?
        var dropPoint = point
        for url in urls {
            let isApp = url.pathExtension.lowercased() == "app"
            if isApp, let index = items.firstIndex(where: { $0.isTargetApp }), items[index].sourcePath.isEmpty {
                importTargetApp(url)
                lastID = items[index].id
                continue
            }
            if isApp, !items.contains(where: { $0.isTargetApp }) {
                items.append(DMGItem(name: url.lastPathComponent, positionX: 140, positionY: window.verticalCenter, type: .targetApp))
                importTargetApp(url)
                lastID = items.first(where: { $0.isTargetApp })?.id
                continue
            }
            // Skip what is already in the DMG.
            if items.contains(where: { $0.sourcePath == url.path }) { continue }

            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            let slot = dropPoint ?? nextFreeSlot()
            let item = DMGItem(
                name: url.lastPathComponent,
                sourcePath: url.path,
                destinationName: uniqueDestinationName(url.lastPathComponent),
                positionX: clampX(slot.x),
                positionY: clampY(slot.y),
                type: isDir.boolValue ? .folder : .file
            )
            items.append(item)
            lastID = item.id
            if let p = dropPoint { dropPoint = CGPoint(x: p.x + window.iconSize + 16, y: p.y) }
        }
        return lastID
    }

    /// Sets the target application from a URL and names the DMG after it.
    public mutating func importTargetApp(_ url: URL) {
        guard let index = items.firstIndex(where: { $0.isTargetApp }) else { return }
        let appName = url.deletingPathExtension().lastPathComponent
        let fullName = url.lastPathComponent
        items[index].sourcePath = url.path
        items[index].name = fullName
        items[index].destinationName = fullName
        items[index].positionY = window.verticalCenter

        name = "\(appName) Installer"
        volumeName = "\(appName) Installer"
        outputFileName = "\(appName.replacingOccurrences(of: " ", with: "-"))-Installer.dmg"

        autoCenterIconsVertically()
    }

    public mutating func removeItem(_ id: UUID) {
        items.removeAll { $0.id == id && !$0.isTargetApp && !$0.isApplicationsSymlink }
    }

    // MARK: Placement helpers

    /// Extras go in a row above the app → Applications line, left to right; then a second pass, nudged.
    private func nextFreeSlot() -> CGPoint {
        let half = window.iconSize / 2
        let top = half + 10
        let step = window.iconSize + 18
        let columns = max(1, Int((window.width - 2 * 20) / step))
        let rowWidth = Double(columns - 1) * step
        let startX = (window.width - rowWidth) / 2
        for pass in 0..<4 {
            for c in 0..<columns {
                let p = CGPoint(x: startX + Double(c) * step + Double(pass) * 14, y: top + Double(pass) * 14)
                let taken = items.contains { abs($0.positionX - p.x) < half && abs($0.positionY - p.y) < half }
                if !taken { return p }
            }
        }
        return CGPoint(x: window.width / 2, y: top)
    }

    private func clampX(_ x: Double) -> Double { min(max(x, 30), window.width - 30) }
    private func clampY(_ y: Double) -> Double { min(max(y, 30), window.height - 30) }

    /// Finder names must be unique in the volume root: "Readme.pdf" → "Readme 2.pdf".
    private func uniqueDestinationName(_ name: String) -> String {
        let taken = Set(items.map { $0.destinationName.lowercased() })
        guard taken.contains(name.lowercased()) else { return name }
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var n = 2
        while true {
            let candidate = ext.isEmpty ? "\(base) \(n)" : "\(base) \(n).\(ext)"
            if !taken.contains(candidate.lowercased()) { return candidate }
            n += 1
        }
    }
}

// MARK: - Loading file URLs from drag & drop

enum FileURLDrop {
    static let types: [UTType] = [.fileURL]

    /// Collects every file URL from the providers, then calls back on the main queue.
    static func load(_ providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else { return false }
        let group = DispatchGroup()
        var urls = [Int: URL]()
        let lock = NSLock()
        for (i, provider) in fileProviders.enumerated() {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                var url: URL?
                if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
                else if let u = item as? URL { url = u }
                if let url { lock.lock(); urls[i] = url; lock.unlock() }
            }
        }
        group.notify(queue: .main) {
            completion(urls.keys.sorted().compactMap { urls[$0] })
        }
        return true
    }
}
