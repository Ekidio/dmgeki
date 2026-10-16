import SwiftUI
import AppKit

public struct AssetsSidebarView: View {
    @Binding var project: DMGProject
    @Binding var selectedItemID: UUID?
    
    @State private var isTargetAppDropTarget: Bool = false
    
    public init(
        project: Binding<DMGProject>,
        selectedItemID: Binding<UUID?>
    ) {
        self._project = project
        self._selectedItemID = selectedItemID
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Target Application Module (At the very top)
                targetAppSection
                
                Divider()
                    .background(DMGTheme.divider)
                
                // 2. Volume Icon Module (Directly beneath Target Application)
                volumeIconSection
                
                Divider()
                    .background(DMGTheme.divider)
                
                // 3. Volume & Output Settings
                volumeSettingsSection
            }
            .padding(16)
        }
        .background(DMGTheme.sidebar)
    }
    
    // MARK: - 1. Target Application Section (Top Module)
    
    private var targetAppSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "app.badge.checkmark")
                    .foregroundColor(DMGTheme.accent)
                Text("Target Application")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
            }
            
            if let index = project.items.firstIndex(where: { $0.isTargetApp }) {
                let app = project.items[index]
                
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Image(nsImage: app.previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(app.destinationName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(DMGTheme.textPrimary)
                            Text(app.sourcePath.isEmpty ? "Drag & Drop .app here or browse" : app.sourcePath)
                                .font(.system(size: 10))
                                .foregroundColor(DMGTheme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Button("Choose .app...") {
                            chooseTargetApp(at: index)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        Text("X: \(Int(app.positionX)) Y: \(Int(app.positionY))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(DMGTheme.textMuted)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTargetAppDropTarget ? DMGTheme.accent.opacity(0.18) : DMGTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isTargetAppDropTarget ? DMGTheme.accent : DMGTheme.cardBorder, lineWidth: 1)
                )
                .onDrop(of: ["public.file-url"], isTargeted: $isTargetAppDropTarget) { providers in
                    handleDropTargetApp(providers: providers, at: index)
                }
            } else {
                Button(action: addDefaultTargetApp) {
                    Label("Add Target Application", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - 2. Volume Custom Icon (.icns) (Directly beneath Target Application)
    
    private var volumeIconSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "app.dashed")
                    .foregroundColor(DMGTheme.accent)
                Text("Volume Icon")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Volume Icon (.icns)")
                    .font(.caption)
                    .foregroundColor(DMGTheme.textSecondary)
                
                HStack(spacing: 10) {
                    if let iconPath = project.effectiveVolumeIconPath,
                       FileManager.default.fileExists(atPath: iconPath),
                       let icon = ImageCache.shared.image(atPath: iconPath) {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                    } else {
                        Image(systemName: "opticaldiscdrive")
                            .font(.system(size: 24))
                            .foregroundColor(DMGTheme.textMuted)
                    }
                    
                    Button("Choose .icns...") {
                        selectVolumeIcon()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    if project.volumeIconPath != nil {
                        Button("Reset to App Icon") {
                            project.volumeIconPath = nil
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .foregroundColor(DMGTheme.textSecondary)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DMGTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DMGTheme.cardBorder, lineWidth: 1)
                )
                
                if project.volumeIconPath != nil {
                    Text("Custom .icns will be applied as the volume icon.")
                        .font(.caption2)
                        .foregroundColor(DMGTheme.textSecondary)
                } else if project.effectiveVolumeIconPath != nil {
                    Text("Using imported app icon automatically.")
                        .font(.caption2)
                        .foregroundColor(DMGTheme.accent)
                } else {
                    Text("Import an app or choose a custom .icns file.")
                        .font(.caption2)
                        .foregroundColor(DMGTheme.textMuted)
                }
            }
        }
    }
    
    // MARK: - 3. Volume & Output Settings
    
    private var volumeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "opticaldiscdrive")
                    .foregroundColor(DMGTheme.accent)
                Text("Volume & Output")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mounted Volume Name")
                    .font(.caption)
                    .foregroundColor(DMGTheme.textSecondary)
                TextField("e.g. MyApp Installer", text: $project.volumeName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Export DMG File Name")
                    .font(.caption)
                    .foregroundColor(DMGTheme.textSecondary)
                TextField("e.g. MyApp-Installer.dmg", text: $project.outputFileName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Output Directory")
                    .font(.caption)
                    .foregroundColor(DMGTheme.textSecondary)
                HStack(spacing: 8) {
                    TextField("Path", text: $project.outputDirectory)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        selectOutputDirectory()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
    
    // MARK: - Actions & Helpers
    
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            project.outputDirectory = url.path
        }
    }
    
    private func chooseTargetApp(at index: Int) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = []
        if panel.runModal() == .OK, let url = panel.url {
            let appName = url.deletingPathExtension().lastPathComponent
            let fullName = url.lastPathComponent
            
            project.items[index].sourcePath = url.path
            project.items[index].name = fullName
            project.items[index].destinationName = fullName
            project.items[index].positionY = project.window.verticalCenter
            
            // Auto-populate DMG Names from Imported App
            project.name = "\(appName) Installer"
            project.volumeName = "\(appName) Installer"
            let slug = appName.replacingOccurrences(of: " ", with: "-")
            project.outputFileName = "\(slug)-Installer.dmg"
            
            // Auto-center icons vertically (Y = 175 pt) and guarantee /Applications shortcut
            project.autoCenterIconsVertically()
        }
    }
    
    private func selectVolumeIcon() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            project.volumeIconPath = url.path
        }
    }
    
    private func addDefaultTargetApp() {
        project.items.append(
            DMGItem(
                name: "YourApp.app",
                sourcePath: "",
                destinationName: "YourApp.app",
                positionX: 140,
                positionY: project.window.verticalCenter,
                type: .targetApp
            )
        )
        project.autoCenterIconsVertically()
    }
    
    private func handleDropTargetApp(providers: [NSItemProvider], at index: Int) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    let appName = url.deletingPathExtension().lastPathComponent
                    let fullName = url.lastPathComponent
                    
                    self.project.items[index].sourcePath = url.path
                    self.project.items[index].name = fullName
                    self.project.items[index].destinationName = fullName
                    self.project.items[index].positionY = self.project.window.verticalCenter
                    
                    // Auto-populate DMG Names from Imported App
                    self.project.name = "\(appName) Installer"
                    self.project.volumeName = "\(appName) Installer"
                    let slug = appName.replacingOccurrences(of: " ", with: "-")
                    self.project.outputFileName = "\(slug)-Installer.dmg"
                    
                    // Auto-center icons vertically (Y = 175 pt) and guarantee /Applications shortcut
                    self.project.autoCenterIconsVertically()
                }
            }
        }
        return true
    }
}
