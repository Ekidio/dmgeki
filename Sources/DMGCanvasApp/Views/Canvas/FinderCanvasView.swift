import SwiftUI
import AppKit

public struct FinderCanvasView: View {
    @Binding var project: DMGProject
    @Binding var selectedItemID: UUID?
    
    @State private var zoomScale: Double = 1.0
    @State private var activeGuides: [CGPoint] = []
    @State private var isDraggingAnyItem: Bool = false
    
    public init(project: Binding<DMGProject>, selectedItemID: Binding<UUID?>) {
        self._project = project
        self._selectedItemID = selectedItemID
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar: Fixed 540x350 Indicator, Quick Tools & Zoom
            canvasControlBar
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(DMGTheme.barBackground)
            
            Divider()
                .background(DMGTheme.divider)
            
            // Interactive Scrollable / Scalable Canvas Area
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack {
                        // Canvas desk background (#121214)
                        DMGTheme.canvasDesk
                            .frame(
                                width: max(geo.size.width, CGFloat(project.window.width * zoomScale) + 120),
                                height: max(geo.size.height, CGFloat(project.window.height * zoomScale) + 120)
                            )
                        
                        // Simulated Finder Window (Strictly 540x350)
                        finderWindowView
                            .scaleEffect(zoomScale)
                            .shadow(color: Color.black.opacity(0.55), radius: 28, x: 0, y: 14)
                    }
                    .frame(
                        minWidth: geo.size.width,
                        minHeight: geo.size.height,
                        alignment: .center
                    )
                }
            }
        }
        .onAppear {
            project.autoCenterIconsVertically()
        }
    }
    
    // MARK: - Finder Window Simulated View
    
    private var finderWindowView: some View {
        VStack(spacing: 0) {
            // Finder Window Titlebar
            finderTitleBar
            
            // Optional Finder Toolbar
            if project.window.showToolbar {
                finderToolbar
            }
            
            // Main Window Content (WYSIWYG Canvas: 540 × 350 pt)
            ZStack(alignment: .topLeading) {
                // Background Layer: Image or styled canvas (matching final DMG output)
                CanvasBackgroundContentView(project: project)
                
                // Grid Overlay
                if project.showGrid {
                    gridOverlay
                }
                
                // Alignment Snap Guides (Cyan lines when dragging)
                if !activeGuides.isEmpty {
                    snapGuidesOverlay
                }
                
                // Content Items (Draggable Icons)
                ForEach($project.items) { $item in
                    CanvasItemView(
                        item: $item,
                        isSelected: selectedItemID == item.id,
                        windowSettings: project.window,
                        snapToGrid: project.snapToGrid,
                        gridSpacing: project.gridSpacing,
                        snapToGuides: project.snapToGuides,
                        otherItems: project.items,
                        canvasWidth: project.window.width,
                        canvasHeight: project.window.height,
                        onSelect: {
                            selectedItemID = item.id
                        },
                        onDraggingStateChanged: { dragging, pos, guides in
                            isDraggingAnyItem = dragging
                            activeGuides = guides
                        }
                    )
                }
            }
            .frame(width: CGFloat(project.window.width), height: CGFloat(project.window.height))
            .clipped()
            
            // Optional Status / Path Bar
            if project.window.showStatusbar {
                finderStatusBar
            }
        }
        .frame(width: CGFloat(project.window.width))
        .background(DMGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DMGTheme.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Title Bar
    
    private var finderTitleBar: some View {
        HStack(spacing: 8) {
            // Traffic Light Buttons
            HStack(spacing: 7) {
                Circle().fill(Color(red: 1.0, green: 0.38, blue: 0.35)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 0.16, green: 0.79, blue: 0.28)).frame(width: 12, height: 12)
            }
            .padding(.leading, 12)
            
            Spacer()
            
            // Window Icon and Title
            HStack(spacing: 6) {
                if let iconPath = project.effectiveVolumeIconPath, !iconPath.isEmpty,
                   let icon = ImageCache.shared.image(atPath: iconPath) {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "opticaldiscdrive.fill")
                        .foregroundColor(DMGTheme.accent)
                        .font(.system(size: 13))
                }
                
                Text(project.window.title.isEmpty ? project.volumeName : project.window.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DMGTheme.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right spacer to keep title visually centered
            Color.clear.frame(width: 54, height: 12)
        }
        .frame(height: 38)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x2e2e32), Color(hex: 0x242426)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Divider()
                .background(DMGTheme.divider)
        }
    }
    
    // MARK: - Finder Toolbar Simulation
    
    private var finderToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left").font(.system(size: 11, weight: .semibold))
                    .padding(5)
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                    .padding(5)
            }
            .foregroundColor(DMGTheme.textSecondary)
            .background(DMGTheme.surfaceElevated)
            .cornerRadius(6)
            
            // View Mode Segment
            HStack(spacing: 2) {
                Image(systemName: "square.grid.2x2.fill").font(.system(size: 11))
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(DMGTheme.accent.opacity(0.25))
                    .cornerRadius(4)
                Image(systemName: "list.bullet").font(.system(size: 11))
                    .padding(.horizontal, 6).padding(.vertical, 4)
                Image(systemName: "sidebar.left").font(.system(size: 11))
                    .padding(.horizontal, 6).padding(.vertical, 4)
            }
            .foregroundColor(DMGTheme.textSecondary)
            .background(DMGTheme.surfaceElevated)
            .cornerRadius(6)
            
            Spacer()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DMGTheme.textMuted)
                    .font(.system(size: 11))
                Text("Search")
                    .font(.system(size: 11))
                    .foregroundColor(DMGTheme.textMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DMGTheme.surfaceElevated)
            .cornerRadius(6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: 0x222224))
        .overlay(alignment: .bottom) {
            Divider()
                .background(DMGTheme.divider)
        }
    }
    
    // MARK: - Grid Overlay
    
    private var gridOverlay: some View {
        Canvas { context, size in
            let spacing = max(10, project.gridSpacing)
            
            // Vertical lines
            var x: CGFloat = 0
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 1)
                x += spacing
            }
            
            // Horizontal lines
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 1)
                y += spacing
            }
        }
    }
    
    // MARK: - Snap Guides Overlay
    
    private var snapGuidesOverlay: some View {
        Canvas { context, size in
            for guide in activeGuides {
                var path = Path()
                if guide.y == -1 {
                    // Vertical guideline
                    path.move(to: CGPoint(x: guide.x, y: 0))
                    path.addLine(to: CGPoint(x: guide.x, y: size.height))
                } else if guide.x == -1 {
                    // Horizontal guideline
                    path.move(to: CGPoint(x: 0, y: guide.y))
                    path.addLine(to: CGPoint(x: size.width, y: guide.y))
                }
                context.stroke(
                    path,
                    with: .color(Color.cyan),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 2])
                )
            }
        }
    }
    

    
    // MARK: - Status Bar Simulation
    
    private var finderStatusBar: some View {
        HStack {
            Text("\(project.items.count) items")
                .font(.system(size: 10))
                .foregroundColor(DMGTheme.textSecondary)
            Spacer()
            Text("450 MB available")
                .font(.system(size: 10))
                .foregroundColor(DMGTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(hex: 0x222224))
        .overlay(alignment: .top) {
            Divider()
                .background(DMGTheme.divider)
        }
    }
    
    // MARK: - Top Control Bar (Clean HIG layout, no truncating text)
    
    private var canvasControlBar: some View {
        HStack(spacing: 12) {
            // Grid, Snap, Guides, Alignment Controls (Compact, non-truncating icon buttons)
            HStack(spacing: 6) {
                Toggle(isOn: $project.showGrid) {
                    Image(systemName: "grid")
                        .font(.system(size: 12))
                }
                .toggleStyle(.button)
                .help("Toggle Grid Overlay")
                
                Toggle(isOn: $project.snapToGrid) {
                    Image(systemName: "rectangle.split.3x3")
                        .font(.system(size: 12))
                }
                .toggleStyle(.button)
                .help("Snap to Grid")
                
                Toggle(isOn: $project.snapToGuides) {
                    Image(systemName: "ruler")
                        .font(.system(size: 12))
                }
                .toggleStyle(.button)
                .help("Snap to Alignment Guides")
                
                Button(action: {
                    project.autoCenterIconsVertically()
                }) {
                    Image(systemName: "align.vertical.center")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .help("Auto-Center Icons Vertically (Y: 175 pt)")
            }
            
            Spacer()
            
            // Zoom Controls
            HStack(spacing: 6) {
                Button(action: { zoomScale = max(0.5, zoomScale - 0.1) }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(DMGTheme.textSecondary)
                .help("Zoom Out")
                
                Text("\(Int(zoomScale * 100))%")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(DMGTheme.textPrimary)
                    .frame(width: 38)
                
                Button(action: { zoomScale = min(2.0, zoomScale + 0.1) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(DMGTheme.textSecondary)
                .help("Zoom In")
                
                Button("100%") {
                    zoomScale = 1.0
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .font(.system(size: 10))
                .help("Reset Zoom to 100%")
            }
        }
    }
}
