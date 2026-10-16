import SwiftUI
import AppKit

public struct MainView: View {
    @State private var project: DMGProject = DMGProject.defaultProject
    @State private var selectedItemID: UUID? = nil
    @StateObject private var builder = DMGBuilderService()
    @State private var showBuildSuccessAlert: Bool = false
    @State private var showBuildErrorAlert: Bool = false
    @State private var showSplash: Bool = true
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // Left Panel: Assets & Payload Content (Target App at top, then Volume Icon, then Volume & Output)
            AssetsSidebarView(
                project: $project,
                selectedItemID: $selectedItemID
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
            .navigationTitle("")
        } detail: {
            // Center: WYSIWYG Finder Canvas
            FinderCanvasView(
                project: $project,
                selectedItemID: $selectedItemID
            )
            .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
            .background(DMGTheme.canvasDesk)
            // Right: Inspector Panel (native inspector column, so it owns the toolbar's right edge)
            .inspector(isPresented: .constant(true)) {
                InspectorView(
                    project: $project,
                    selectedItemID: $selectedItemID
                )
                .inspectorColumnWidth(min: 330, ideal: 340, max: 400)
                .interactiveDismissDisabled()
                .toolbar {
                    buildToolbarItems
                }
            }
            .navigationTitle("")
        }
        .toolbar {
            toolbarItems
        }
        .toolbar(showSplash ? .hidden : .visible, for: .windowToolbar)
        .overlay {
            // "DMG ready" celebration replaces the plain success alert.
            if showBuildSuccessAlert, let path = builder.finalDMGPath {
                BuildSuccessView(dmgPath: path, onDone: { showBuildSuccessAlert = false })
                    .transition(.opacity)
            }
        }
        .overlay {
            if showSplash {
                SplashView(onDone: { showSplash = false })
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(.dark)
        .background(WindowAccessor())
        .onAppear {
            project.autoCenterIconsVertically()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dmgOpenProject)) { _ in openProject() }
        .onReceive(NotificationCenter.default.publisher(for: .dmgSaveProject)) { _ in saveProject() }
        .alert("Build Failed", isPresented: $showBuildErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(builder.errorMessage ?? "An unknown error occurred during build.")
        }
    }
    
    // MARK: - Toolbar (Apple Human Interface Guidelines Compliant)
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        // Top-Left Branding: Styled DMGEKI Logo Badge (Templates button removed, locked to Standard)
        ToolbarItemGroup(placement: .navigation) {
            DMGEKILogoView(scale: 0.95)
                .padding(.leading, 2)
                .padding(.trailing, 6)
        }
        
        ToolbarItemGroup(placement: .principal) {
            VStack(spacing: 2) {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(DMGTheme.textPrimary)
                Text(project.outputFileName)
                    .font(.caption2)
                    .foregroundColor(DMGTheme.textSecondary)
            }
        }
    }
    
    /// Build DMG at the window's right edge, in the inspector column's part of the toolbar.
    @ToolbarContentBuilder
    private var buildToolbarItems: some ToolbarContent {
        // Open / Save Project live in the menu bar (File menu, ⌘O / ⌘S).
        if #available(macOS 26.0, *) {
            ToolbarSpacer(.flexible)
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            // Primary Action: Build DMG Button with exact DMGEKI logo blue (#27A3F5)
            Button(action: triggerBuild) {
                HStack(spacing: 6) {
                    if builder.isBuilding {
                        ProgressView()
                            .scaleEffect(0.65)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text(builder.isBuilding ? "Building..." : "Build DMG")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: 0x27A3F5))
                )
                .shadow(color: Color(hex: 0x27A3F5).opacity(0.4), radius: 5, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(builder.isBuilding)
            .opacity(builder.isBuilding ? 0.6 : 1.0)
            .keyboardShortcut("b", modifiers: [.command])
            .help("Build Disk Image (⌘B)")
        }
    }
    
    // MARK: - Actions
    
    private func triggerBuild() {
        Task {
            await builder.buildDMG(project: project)
            if builder.errorMessage != nil {
                showBuildErrorAlert = true
            } else if builder.finalDMGPath != nil {
                showBuildSuccessAlert = true
            }
        }
    }
    
    private func saveProject() {
        if let url = ProjectStorageService.shared.promptSaveProject(project) {
            do {
                try ProjectStorageService.shared.saveProject(project, to: url)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to save project"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }
    
    private func openProject() {
        if let loaded = ProjectStorageService.shared.promptOpenProject() {
            var updated = loaded
            updated.autoCenterIconsVertically()
            self.project = updated
            self.selectedItemID = updated.items.first?.id
        }
    }
}

// MARK: - Window Accessor to apply dark appearance and black header tone
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.title = ""
                window.titleVisibility = .hidden
                window.appearance = NSAppearance(named: .darkAqua)
                // Darker black tone (#111113) for window titlebar / header area
                window.backgroundColor = NSColor(red: 0x11 / 255.0, green: 0x11 / 255.0, blue: 0x13 / 255.0, alpha: 1.0)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.title = ""
                window.titleVisibility = .hidden
                window.appearance = NSAppearance(named: .darkAqua)
                window.backgroundColor = NSColor(red: 0x11 / 255.0, green: 0x11 / 255.0, blue: 0x13 / 255.0, alpha: 1.0)
            }
        }
    }
}
