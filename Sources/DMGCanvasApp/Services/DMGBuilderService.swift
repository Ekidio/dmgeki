import Foundation
import AppKit

public class DMGBuilderService: ObservableObject {
    @Published public var isBuilding: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var currentStage: String = ""
    @Published public var logs: [DMGBuildLog] = []
    @Published public var finalDMGPath: String? = nil
    @Published public var errorMessage: String? = nil
    
    private var activeProcess: Process?
    private var cancellationRequested: Bool = false
    
    public init() {}
    
    public func clearLogs() {
        logs.removeAll()
        progress = 0.0
        currentStage = ""
        finalDMGPath = nil
        errorMessage = nil
    }
    
    public func log(_ message: String, level: DMGLogLevel = .info) {
        DispatchQueue.main.async {
            let entry = DMGBuildLog(level: level, message: message)
            self.logs.append(entry)
        }
    }
    
    public func cancelBuild() {
        cancellationRequested = true
        activeProcess?.terminate()
        log("Build cancellation requested by user.", level: .warning)
    }
    
    @MainActor
    public func buildDMG(project: DMGProject) async {
        isBuilding = true
        cancellationRequested = false
        progress = 0.0
        currentStage = "Validating..."
        finalDMGPath = nil
        errorMessage = nil
        clearLogs()
        
        log("🚀 Starting DMG Build Pipeline for '\(project.name)'", level: .info)
        
        do {
            try await runBuildPipeline(project: project)
            
            self.progress = 1.0
            self.currentStage = "Build Complete!"
            self.isBuilding = false
            self.log("🎉 DMG Build Successfully Finished!", level: .success)
            if let path = self.finalDMGPath {
                self.log("📦 Output saved to: \(path)", level: .success)
            }
        } catch {
            self.isBuilding = false
            self.errorMessage = error.localizedDescription
            self.log("❌ Build failed: \(error.localizedDescription)", level: .error)
        }
    }
    
    private func updateStage(_ stage: String, progress: Double) {
        DispatchQueue.main.async {
            self.currentStage = stage
            self.progress = progress
        }
        log(stage, level: .info)
    }
    
    @MainActor
    private func runBuildPipeline(project: DMGProject) async throws {
        // Stage 1: Validation
        updateStage("Validating configuration...", progress: 0.05)
        guard !project.volumeName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "DMGBuilder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Volume name cannot be empty."])
        }
        guard !project.outputFileName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "DMGBuilder", code: 2, userInfo: [NSLocalizedDescriptionKey: "Output DMG filename cannot be empty."])
        }
        
        let outputDirectory = (project.outputDirectory as NSString).expandingTildeInPath
        if !FileManager.default.fileExists(atPath: outputDirectory) {
            try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)
        }
        
        let finalPath = (outputDirectory as NSString).appendingPathComponent(project.outputFileName)
        
        // Stage 2: Staging directory setup
        updateStage("Setting up staging environment...", progress: 0.12)
        let tempUUID = UUID().uuidString.prefix(8)
        let stagingDir = NSTemporaryDirectory() + "dmg_staging_\(tempUUID)"
        let tempDMGPath = NSTemporaryDirectory() + "dmg_temp_\(tempUUID).dmg"
        let volumeMountPath = "/Volumes/\(project.volumeName)"
        
        // Defer cleanup
        defer {
            try? FileManager.default.removeItem(atPath: stagingDir)
            if FileManager.default.fileExists(atPath: tempDMGPath) {
                try? FileManager.default.removeItem(atPath: tempDMGPath)
            }
        }
        
        try FileManager.default.createDirectory(atPath: stagingDir, withIntermediateDirectories: true)
        log("Staging directory: \(stagingDir)", level: .info)
        
        // Stage 3: Copying items & background
        updateStage("Staging payload items...", progress: 0.20)
        
        // Copy / Link items
        for item in project.items {
            if cancellationRequested { throw CancellationError() }
            
            if item.isApplicationsSymlink {
                let dest = (stagingDir as NSString).appendingPathComponent(item.destinationName)
                log("Creating symlink to /Applications -> \(item.destinationName)", level: .command)
                try FileManager.default.createSymbolicLink(atPath: dest, withDestinationPath: "/Applications")
            } else if !item.sourcePath.isEmpty {
                if FileManager.default.fileExists(atPath: item.sourcePath) {
                    let dest = (stagingDir as NSString).appendingPathComponent(item.destinationName)
                    log("Copying item: \(item.name) -> \(item.destinationName)", level: .command)
                    try FileManager.default.copyItem(atPath: item.sourcePath, toPath: dest)
                } else {
                    log("Warning: Source file '\(item.sourcePath)' not found on disk. Skipping copy.", level: .warning)
                }
            }
        }
        
        // Staging background image (Always generated as high-DPI background.png)
        updateStage("Generating & staging high-DPI background image...", progress: 0.30)
        let bgDir = (stagingDir as NSString).appendingPathComponent(".background")
        try FileManager.default.createDirectory(atPath: bgDir, withIntermediateDirectories: true)
        
        do {
            let rendered = try CanvasBackgroundRenderer.renderBackground(for: project, outputDirectory: bgDir)
            log("Generated background image: \(rendered.pngPath)", level: .success)
        } catch {
            log("Warning: Failed to render background image: \(error.localizedDescription)", level: .warning)
            // Fallback: If custom image exists on disk, copy directly
            if let customPath = project.backgroundImagePath, FileManager.default.fileExists(atPath: customPath) {
                let fallbackPng = (bgDir as NSString).appendingPathComponent("background.png")
                try? FileManager.default.copyItem(atPath: customPath, toPath: fallbackPng)
            }
        }
        
        // Staging volume icon (uses custom .icns if chosen, otherwise imported app icon)
        if let iconPath = project.effectiveVolumeIconPath, FileManager.default.fileExists(atPath: iconPath) {
            updateStage("Processing volume icon...", progress: 0.35)
            let iconTarget = (stagingDir as NSString).appendingPathComponent(".VolumeIcon.icns")
            try? FileManager.default.removeItem(atPath: iconTarget)
            try FileManager.default.copyItem(atPath: iconPath, toPath: iconTarget)
            log("Added volume icon .VolumeIcon.icns from: \(iconPath)", level: .info)
        }
        
        // Stage 4: Calculating volume size
        updateStage("Calculating required disk volume size...", progress: 0.40)
        let stagingSizeMB = calculateDirectorySizeMB(path: stagingDir)
        let diskSizeMB = max(100, stagingSizeMB + 60) // Extra padding for filesystem overhead and .DS_Store
        log("Staging size: \(stagingSizeMB) MB, Allocated volume size: \(diskSizeMB) MB", level: .info)
        
        // Stage 5: Create temporary read-write DMG
        updateStage("Creating temporary read-write DMG...", progress: 0.48)
        _ = try await executeCommand("/usr/bin/hdiutil", arguments: [
            "create",
            "-size", "\(diskSizeMB)m",
            "-fs", "HFS+",
            "-volname", project.volumeName,
            "-ov",
            tempDMGPath
        ])
        
        // Stage 6: Attach temporary DMG
        updateStage("Mounting temporary disk image...", progress: 0.55)
        _ = try await executeCommand("/usr/bin/hdiutil", arguments: [
            "attach",
            "-readwrite",
            "-noverify",
            "-noautoopen",
            tempDMGPath
        ])
        
        // Ensure volume is detached on failure/exit
        defer {
            _ = runCommandSynchronous("/usr/bin/hdiutil", arguments: ["detach", volumeMountPath, "-force"])
        }
        
        // Stage 7: Copy payload into mounted volume
        updateStage("Populating mounted volume...", progress: 0.62)
        _ = try await executeCommand("/bin/cp", arguments: [
            "-R",
            "\(stagingDir)/.",
            "\(volumeMountPath)/"
        ])
        
        // Explicitly ensure .background directory and background.png exist directly on mounted volume root
        let mountedBgDir = (volumeMountPath as NSString).appendingPathComponent(".background")
        try? FileManager.default.createDirectory(atPath: mountedBgDir, withIntermediateDirectories: true)
        let stagedBgPng = (bgDir as NSString).appendingPathComponent("background.png")
        let mountedBgPng = (mountedBgDir as NSString).appendingPathComponent("background.png")
        if FileManager.default.fileExists(atPath: stagedBgPng) {
            try? FileManager.default.removeItem(atPath: mountedBgPng)
            try? FileManager.default.copyItem(atPath: stagedBgPng, toPath: mountedBgPng)
            log("Verified .background/background.png on mounted volume root", level: .success)
        }
        let stagedBgTiff = (bgDir as NSString).appendingPathComponent("background.tiff")
        let mountedBgTiff = (mountedBgDir as NSString).appendingPathComponent("background.tiff")
        if FileManager.default.fileExists(atPath: stagedBgTiff) {
            try? FileManager.default.removeItem(atPath: mountedBgTiff)
            try? FileManager.default.copyItem(atPath: stagedBgTiff, toPath: mountedBgTiff)
        }
        
        // Ensure volume icon is explicitly in place and attributes set
        if let iconPath = project.effectiveVolumeIconPath, FileManager.default.fileExists(atPath: iconPath) {
            let volumeIconDest = (volumeMountPath as NSString).appendingPathComponent(".VolumeIcon.icns")
            if !FileManager.default.fileExists(atPath: volumeIconDest) {
                try? FileManager.default.copyItem(atPath: iconPath, toPath: volumeIconDest)
            }
            
            // Set file creator type to icnC
            _ = try? await executeCommand("/usr/bin/SetFile", arguments: ["-c", "icnC", volumeIconDest])
            // Set invisible attribute on .VolumeIcon.icns
            _ = try? await executeCommand("/usr/bin/SetFile", arguments: ["-a", "V", volumeIconDest])
            // Set custom icon bit on the volume root
            _ = try? await executeCommand("/usr/bin/SetFile", arguments: ["-a", "C", volumeMountPath])
            log("Configured volume icon .VolumeIcon.icns and enabled volume custom icon bit on \(project.volumeName)", level: .success)
        }
        
        // Stage 8: Apply Finder Layout Styling via AppleScript
        updateStage("Applying Finder window styling & background image...", progress: 0.70)
        let appleScript = AppleScriptGenerator.generateScript(
            for: project,
            volumeName: project.volumeName,
            backgroundFileName: "background.png"
        )
        
        log("Executing AppleScript via osascript...", level: .command)
        try await executeAppleScript(appleScript)
        
        // Flush filesystem cache and allow Finder to persist .DS_Store
        _ = try? await executeCommand("/bin/sync", arguments: [])
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s delay
        
        // Stage 9: Detach temporary volume cleanly so .DS_Store persists
        updateStage("Unmounting disk volume...", progress: 0.80)
        _ = try await executeCommand("/usr/bin/hdiutil", arguments: [
            "detach",
            volumeMountPath,
            "-force"
        ])
        
        // Wait for unmount to complete
        var unmountAttempts = 0
        while FileManager.default.fileExists(atPath: volumeMountPath) && unmountAttempts < 6 {
            try await Task.sleep(nanoseconds: 500_000_000)
            unmountAttempts += 1
        }
        
        // Stage 10: Convert to final compressed DMG (Enforced UDZO zlib)
        updateStage("Converting to final compressed format (UDZO)...", progress: 0.88)
        if FileManager.default.fileExists(atPath: finalPath) {
            try FileManager.default.removeItem(atPath: finalPath)
        }
        
        let convertArgs = [
            "convert",
            tempDMGPath,
            "-format", "UDZO",
            "-imagekey", "zlib-level=9",
            "-o", finalPath
        ]
        
        _ = try await executeCommand("/usr/bin/hdiutil", arguments: convertArgs)
        
        // Set volume icon on the final DMG file itself in Finder
        if let iconPath = project.effectiveVolumeIconPath, FileManager.default.fileExists(atPath: iconPath) {
            if let iconImage = NSImage(contentsOfFile: iconPath) {
                let success = NSWorkspace.shared.setIcon(iconImage, forFile: finalPath, options: [])
                if success {
                    log("Set volume icon on built DMG file in Finder", level: .success)
                }
            }
            _ = try? await executeCommand("/usr/bin/SetFile", arguments: ["-a", "C", finalPath])
        }
        
        self.finalDMGPath = finalPath
    }
    
    // MARK: - Process Execution Helpers
    
    @discardableResult
    private func executeCommand(_ launchPath: String, arguments: [String]) async throws -> String {
        log("$ \(launchPath) \(arguments.joined(separator: " "))", level: .command)
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launchPath)
            process.arguments = arguments
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            self.activeProcess = process
            
            do {
                try process.run()
                
                stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                        let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                        for line in lines where !line.isEmpty {
                            self.log(line, level: .info)
                        }
                    }
                }
                
                stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                        let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                        for line in lines where !line.isEmpty {
                            self.log(line, level: .warning)
                        }
                    }
                }
                
                process.terminationHandler = { proc in
                    stdoutPipe.fileHandleForReading.readabilityHandler = nil
                    stderrPipe.fileHandleForReading.readabilityHandler = nil
                    
                    if proc.terminationStatus == 0 {
                        continuation.resume(returning: "")
                    } else {
                        let err = NSError(
                            domain: "DMGBuilder",
                            code: Int(proc.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "Command failed with exit code \(proc.terminationStatus)"]
                        )
                        continuation.resume(throwing: err)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func executeAppleScript(_ scriptText: String) async throws {
        let tempScriptPath = NSTemporaryDirectory() + "finder_setup_\(UUID().uuidString.prefix(6)).applescript"
        try scriptText.write(toFile: tempScriptPath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tempScriptPath) }
        
        do {
            _ = try await executeCommand("/usr/bin/osascript", arguments: [tempScriptPath])
            log("Finder window styling & background picture configured successfully.", level: .success)
        } catch {
            log("AppleScript execution note: \(error.localizedDescription)", level: .warning)
        }
    }
    
    private func runCommandSynchronous(_ launchPath: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
    
    private func calculateDirectorySizeMB(path: String) -> Int {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return 50 }
        var totalBytes: Int64 = 0
        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? Int64 {
                totalBytes += size
            }
        }
        return Int(totalBytes / (1024 * 1024))
    }
}
