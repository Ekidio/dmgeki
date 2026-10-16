import SwiftUI
import AppKit

public struct AssetsSidebarView: View {
    @Binding var project: DMGProject
    @Binding var selectedItemID: UUID?
    
    @State private var isPayloadDropTarget: Bool = false
    
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
                
                // 2. Extra files & folders shipped in the DMG
                payloadSection
                
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
        // One drop target for the whole sidebar. Drop targets inside the scroll content are placed without the
        // scroll view's top inset (≈60 pt too high) and swallow clicks meant for the buttons above them.
        .onDrop(of: FileURLDrop.types, isTargeted: $isPayloadDropTarget) { providers in
            FileURLDrop.load(providers) { urls in
                selectedItemID = project.importPayload(urls) ?? selectedItemID
            }
        }
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
                        .fill(isPayloadDropTarget && app.sourcePath.isEmpty ? DMGTheme.accent.opacity(0.18) : DMGTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isPayloadDropTarget && app.sourcePath.isEmpty ? DMGTheme.accent : DMGTheme.cardBorder, lineWidth: 1)
                )
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
            project.importTargetApp(url)
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
    
    // MARK: - Files & Folders
    
    private var payloadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(DMGTheme.accent)
                Text("Files & Folders")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
                Spacer()
                Text("\(project.extraItems.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(DMGTheme.textMuted)
            }
            
            ForEach(project.extraItems) { item in
                payloadRow(item)
            }
            
            // Add button above the drop zone (kept outside it, so nothing in the drop target can swallow its clicks)
            Button {
                chooseFilesOrFolders()
            } label: {
                Label("Add Files or Folders...", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            
            // Drop zone
            VStack(spacing: 6) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 20))
                    .foregroundColor(isPayloadDropTarget ? DMGTheme.accent : DMGTheme.textMuted)
                Text("Drag & drop files or folders here")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DMGTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPayloadDropTarget ? DMGTheme.accent.opacity(0.15) : Color.clear)
                    .allowsHitTesting(false)
            )
            // Decoration only: keep the dashed frame out of hit testing.
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isPayloadDropTarget ? DMGTheme.accent : DMGTheme.cardBorder,
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .allowsHitTesting(false)
            )
            
            Text("Shipped in the DMG next to your app. You can also drop them straight onto the canvas.")
                .font(.caption2)
                .foregroundColor(DMGTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func payloadRow(_ item: DMGItem) -> some View {
        let isSelected = selectedItemID == item.id
        let missing = !FileManager.default.fileExists(atPath: item.sourcePath)
        return HStack(spacing: 10) {
            Image(nsImage: item.previewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.destinationName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DMGTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(missing ? "Missing: \(item.sourcePath)" : item.sourcePath)
                    .font(.system(size: 10))
                    .foregroundColor(missing ? .orange : DMGTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 4)
            Button {
                if selectedItemID == item.id { selectedItemID = nil }
                project.removeItem(item.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DMGTheme.textMuted)
            }
            .buttonStyle(.plain)
            .help("Remove from DMG")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected ? DMGTheme.accent.opacity(0.16) : DMGTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isSelected ? DMGTheme.accent : DMGTheme.cardBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { selectedItemID = item.id }
    }
    
    private func chooseFilesOrFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.treatsFilePackagesAsDirectories = false
        panel.prompt = "Add"
        panel.message = "Choose files or folders to include in the DMG"
        if panel.runModal() == .OK {
            selectedItemID = project.importPayload(panel.urls) ?? selectedItemID
        }
    }
}
