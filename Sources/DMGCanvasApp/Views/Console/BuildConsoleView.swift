import SwiftUI
import AppKit

public struct BuildConsoleView: View {
    @ObservedObject var builder: DMGBuilderService
    @Binding var isExpanded: Bool
    
    public init(
        builder: DMGBuilderService,
        isExpanded: Binding<Bool>
    ) {
        self.builder = builder
        self._isExpanded = isExpanded
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    if builder.isBuilding {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 14, height: 14)
                    } else if builder.progress == 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DMGTheme.success)
                    } else if builder.errorMessage != nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DMGTheme.danger)
                    } else {
                        Image(systemName: "terminal.fill")
                            .foregroundColor(DMGTheme.accent)
                    }
                    
                    Text(builder.currentStage.isEmpty ? "Build Console" : builder.currentStage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DMGTheme.textPrimary)
                        .lineLimit(1)
                }
                
                if builder.isBuilding {
                    ProgressView(value: builder.progress)
                        .tint(DMGTheme.accent)
                        .frame(width: 140)
                }
                
                Spacer()
                
                // Actions
                if let finalPath = builder.finalDMGPath {
                    Button(action: { revealInFinder(path: finalPath) }) {
                        Label("Show in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DMGTheme.success)
                    .controlSize(.small)
                    
                    Button(action: { testMountDMG(path: finalPath) }) {
                        Label("Test Mount", systemImage: "opticaldiscdrive")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                if builder.isBuilding {
                    Button("Cancel") {
                        builder.cancelBuild()
                    }
                    .buttonStyle(.bordered)
                    .tint(DMGTheme.danger)
                    .controlSize(.small)
                } else if !builder.logs.isEmpty {
                    Button("Clear") {
                        builder.clearLogs()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(DMGTheme.textSecondary)
                    .font(.caption)
                }
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundColor(DMGTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DMGTheme.barBackground)
            
            // Console Terminal Body
            if isExpanded {
                Divider()
                    .background(DMGTheme.divider)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if builder.logs.isEmpty {
                                Text("Click 'Build DMG' to start compilation, packaging, and Finder styling...")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(DMGTheme.textMuted)
                                    .padding(12)
                            } else {
                                ForEach(builder.logs) { log in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(log.formattedTime)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(DMGTheme.textMuted)
                                        
                                        Text(log.message)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(log.level.color)
                                            .textSelection(.enabled)
                                    }
                                    .id(log.id)
                                }
                            }
                        }
                        .padding(12)
                    }
                    .frame(height: 160)
                    .background(Color(hex: 0x121214))
                    .onChange(of: builder.logs.count) { _ in
                        if let lastLog = builder.logs.last {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            Divider()
                .background(DMGTheme.divider)
        }
    }
    
    private func revealInFinder(path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
    }
    
    private func testMountDMG(path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
