import SwiftUI
import AppKit

public struct InspectorView: View {
    @Binding var project: DMGProject
    @Binding var selectedItemID: UUID?
    
    @State private var autoResizeFeedbackMessage: String? = nil
    
    public init(project: Binding<DMGProject>, selectedItemID: Binding<UUID?>) {
        self._project = project
        self._selectedItemID = selectedItemID
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Inspector Header
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(DMGTheme.accent)
                Text("Appearance & Styling")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DMGTheme.barBackground)
            
            Divider()
                .background(DMGTheme.divider)
            
            // Inspector Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Background Style (Consolidated with full image management)
                    backgroundStyleSection
                    
                    Divider()
                        .background(DMGTheme.divider)
                    
                    // 2. Icon & Label Sizing
                    iconSizingSection
                    
                    Divider()
                        .background(DMGTheme.divider)
                    
                    // 3. Drag Indicator Arrow
                    dragArrowSection
                    
                    Divider()
                        .background(DMGTheme.divider)
                    
                    // 4. Grid & Snapping
                    gridSnappingSection
                }
                .padding(16)
            }
        }
        .background(DMGTheme.sidebar)
    }
    
    // MARK: - 1. Background Style Section
    
    private var backgroundStyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "photo.artframe")
                    .foregroundColor(DMGTheme.accent)
                Text("Background Style")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
            }
            
            Picker("Theme", selection: $project.backgroundPreset) {
                ForEach(DMGBackgroundPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.menu)
            
            // Thumbnail preview card
            HStack(spacing: 12) {
                ZStack {
                    CanvasBackgroundContentView(project: project)
                        .frame(width: CGFloat(project.window.width), height: CGFloat(project.window.height))
                        .scaleEffect(56.0 / max(1.0, CGFloat(project.window.width)))
                        .frame(width: 56, height: 36)
                        .clipped()
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(DMGTheme.border, lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    if let bgPath = project.backgroundImagePath, !bgPath.isEmpty {
                        let fileName = (bgPath as NSString).lastPathComponent
                        Text(fileName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DMGTheme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        if let dims = ImageResizerService.getImageDimensions(from: bgPath) {
                            Text("\(dims.width) × \(dims.height) px (Retina)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(DMGTheme.textSecondary)
                        }
                    } else {
                        Text(project.backgroundPreset.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(DMGTheme.textPrimary)
                        Text("540 × 350 pt (Locked)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(DMGTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .background(DMGTheme.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DMGTheme.cardBorder, lineWidth: 1)
            )
            
            // Custom Background Image Controls
            if project.backgroundImagePath != nil || project.backgroundPreset == .customImage {
                VStack(alignment: .leading, spacing: 10) {
                    // Action Buttons Row: Replace, Delete, Auto (540x350)
                    HStack(spacing: 6) {
                        // Replace / Change Image Button
                        Button(action: selectBackgroundImage) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Replace...")
                            }
                            .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Replace background with another image file")
                        
                        // Delete / Clear Image Button
                        Button(action: deleteBackgroundImage) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(DMGTheme.danger)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Delete custom background image and restore default gradient")
                        
                        Spacer()
                        
                        // Auto (540x350) Button
                        Button(action: autoResizeImage) {
                            HStack(spacing: 3) {
                                Image(systemName: "wand.and.stars")
                                Text("Auto (540×350)")
                            }
                            .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DMGTheme.accent)
                        .controlSize(.small)
                        .help("Automatically crop & resize image strictly to 540x350 pt @2x")
                    }
                    
                    if let feedback = autoResizeFeedbackMessage {
                        Text(feedback)
                            .font(.caption2)
                            .foregroundColor(DMGTheme.success)
                    }
                    
                    // Scaling Mode Picker
                    HStack {
                        Text("Scaling Mode")
                            .font(.caption)
                            .foregroundColor(DMGTheme.textSecondary)
                        Spacer()
                        Picker("", selection: $project.backgroundImageScalingMode) {
                            ForEach(DMGImageScalingMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 160)
                    }
                    
                    // Scale Slider
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Scale")
                                .font(.caption)
                                .foregroundColor(DMGTheme.textSecondary)
                            Spacer()
                            Text("\(Int(project.backgroundImageScale * 100))%")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(DMGTheme.textSecondary)
                        }
                        
                        HStack(spacing: 8) {
                            Slider(value: $project.backgroundImageScale, in: 0.5...2.0, step: 0.05)
                            Button("100%") {
                                project.backgroundImageScale = 1.0
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 9))
                            .controlSize(.mini)
                        }
                    }
                    
                    // Export Rendered Image
                    Button("Export Rendered Background...") {
                        exportRenderedBackground()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.system(size: 11))
                }
                .padding(10)
                .background(DMGTheme.surface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DMGTheme.cardBorder, lineWidth: 1)
                )
            } else {
                HStack(spacing: 8) {
                    Button("Choose Custom Image...") {
                        selectBackgroundImage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Export Background...") {
                        exportRenderedBackground()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Color Overlay Tint Layer
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "square.fill.on.square.fill")
                        .foregroundColor(DMGTheme.accent)
                        .font(.system(size: 11))
                    Text("Background Color Overlay")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DMGTheme.textPrimary)
                    Spacer()
                    HexColorWell(hex: $project.backgroundOverlayColorHex)
                        .frame(width: 44, height: 24)
                }
                
                // Opacity Slider
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Overlay Opacity")
                            .font(.caption)
                            .foregroundColor(DMGTheme.textSecondary)
                        Spacer()
                        Text("\(Int(round(project.backgroundOverlayOpacity * 100)))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(DMGTheme.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Slider(value: $project.backgroundOverlayOpacity, in: 0.0...1.0, step: 0.05)
                        
                        Button("Off") {
                            project.backgroundOverlayOpacity = 0.0
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 9))
                        .controlSize(.mini)
                    }
                }
                
                // Quick Presets
                HStack(spacing: 5) {
                    ForEach([
                        ("#000000", "Dark 40%", 0.40),
                        ("#000000", "Dark 70%", 0.70),
                        ("#FFFFFF", "Light 35%", 0.35),
                        ("#27A3F5", "Blue 25%", 0.25)
                    ], id: \.1) { hex, label, opacity in
                        Button(action: {
                            project.backgroundOverlayColorHex = hex
                            project.backgroundOverlayOpacity = opacity
                        }) {
                            Text(label)
                                .font(.system(size: 9))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }
            }
            .padding(10)
            .background(DMGTheme.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DMGTheme.cardBorder, lineWidth: 1)
            )
            
            // Watermark Hint
            Toggle("Show Watermark Hint", isOn: $project.showWatermark)
                .foregroundColor(DMGTheme.textPrimary)
            
            if project.showWatermark {
                TextField("Watermark Text", text: $project.watermarkText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - 2. Icon & Label Sizing Section
    
    private var iconSizingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "textformat.size")
                    .foregroundColor(DMGTheme.accent)
                Text("Icon & Label Sizing")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Icon Size")
                        .foregroundColor(DMGTheme.textPrimary)
                    Spacer()
                    Text("\(Int(project.window.iconSize)) × \(Int(project.window.iconSize)) pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(DMGTheme.textSecondary)
                }
                Slider(value: $project.window.iconSize, in: 64...256, step: 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Label Font Size")
                        .foregroundColor(DMGTheme.textPrimary)
                    Spacer()
                    Text("\(Int(project.window.textSize)) pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(DMGTheme.textSecondary)
                }
                Slider(value: $project.window.textSize, in: 10...18, step: 1)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Label Position")
                    .font(.caption)
                    .foregroundColor(DMGTheme.textSecondary)
                Picker("Label Position", selection: $project.window.labelOnBottom) {
                    Text("Bottom").tag(true)
                    Text("Right").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            // Icon Font Color
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Icon Font Color")
                        .foregroundColor(DMGTheme.textPrimary)
                    Spacer()
                    HexColorWell(hex: $project.window.labelColorHex)
                        .frame(width: 44, height: 24)
                }
                
                // Quick preset color swatches
                HStack(spacing: 5) {
                    ForEach([
                        ("#000000", "Black"),
                        ("#FFFFFF", "White"),
                        ("#2C2C2E", "Dark"),
                        ("#8E8E93", "Gray"),
                        ("#27A3F5", "Blue"),
                        ("#FF9500", "Orange")
                    ], id: \.0) { hex, name in
                        Button(action: {
                            project.window.labelColorHex = hex
                        }) {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color(hexString: hex, defaultColor: .black))
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 0.5))
                                Text(name)
                                    .font(.system(size: 9))
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(project.window.labelColorHex.uppercased() == hex.uppercased() ? DMGTheme.accent : nil)
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Drag Indicator Arrow Section
    
    private var dragArrowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right")
                    .foregroundColor(DMGTheme.accent)
                Text("Drag Indicator Arrow")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
            }
            
            Toggle("Show Drag Arrow", isOn: $project.showArrow)
                .foregroundColor(DMGTheme.textPrimary)
            
            if project.showArrow {
                Picker("Arrow Style", selection: $project.arrowStyle) {
                    ForEach(DMGArrowStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    // MARK: - 4. Grid & Snapping Section
    
    private var gridSnappingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "grid")
                    .foregroundColor(DMGTheme.accent)
                Text("Grid & Snapping")
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
            }
            
            Toggle("Show Grid Overlay", isOn: $project.showGrid)
                .foregroundColor(DMGTheme.textPrimary)
            Toggle("Snap to Grid", isOn: $project.snapToGrid)
                .foregroundColor(DMGTheme.textPrimary)
            
            if project.showGrid || project.snapToGrid {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Grid Spacing")
                            .foregroundColor(DMGTheme.textPrimary)
                        Spacer()
                        Text("\(Int(project.gridSpacing)) pt")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(DMGTheme.textSecondary)
                    }
                    Slider(value: $project.gridSpacing, in: 10...40, step: 5)
                }
            }
            
            Toggle("Snap to Alignment Guides", isOn: $project.snapToGuides)
                .foregroundColor(DMGTheme.textPrimary)
        }
    }
    
    // MARK: - Actions & Helpers
    
    private func selectBackgroundImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url {
            project.backgroundImagePath = url.path
            project.backgroundPreset = .customImage
            project.backgroundImageScale = 1.0
            project.backgroundImageScalingMode = .fill
            autoResizeFeedbackMessage = nil
        }
    }
    
    private func deleteBackgroundImage() {
        project.backgroundImagePath = nil
        project.backgroundPreset = .modernGradient
        project.backgroundImageScale = 1.0
        project.backgroundImageScalingMode = .fill
        autoResizeFeedbackMessage = nil
    }
    
    private func autoResizeImage() {
        guard let currentPath = project.backgroundImagePath else { return }
        if let resizedPath = ImageResizerService.resizeImageTo540x350(from: currentPath) {
            project.backgroundImagePath = resizedPath
            project.backgroundImageScale = 1.0
            project.backgroundImageScalingMode = .fill
            autoResizeFeedbackMessage = "✓ Automatically sized to 540 × 350 pt"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                autoResizeFeedbackMessage = nil
            }
        }
    }
    
    private func exportRenderedBackground() {
        let panel = NSSavePanel()
        panel.title = "Export Rendered Background Image"
        panel.nameFieldStringValue = "\(project.name.replacingOccurrences(of: " ", with: "-"))-background.png"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            let tempDir = NSTemporaryDirectory() + "export_bg_\(UUID().uuidString.prefix(6))"
            try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(atPath: tempDir) }
            
            if let rendered = try? CanvasBackgroundRenderer.renderBackground(for: project, outputDirectory: tempDir),
               let data = try? Data(contentsOf: URL(fileURLWithPath: rendered.pngPath)) {
                try? data.write(to: url)
            }
        }
    }
}
