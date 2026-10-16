import SwiftUI
import AppKit

public struct CanvasBackgroundContentView: View {
    public let project: DMGProject
    
    public init(project: DMGProject) {
        self.project = project
    }
    
    public var body: some View {
        ZStack {
            // Base Background Layer
            baseBackgroundView
            
            // Color overlay tint layer
            if project.backgroundOverlayOpacity > 0.001 {
                Color(hexString: project.backgroundOverlayColorHex, defaultColor: .black)
                    .opacity(project.backgroundOverlayOpacity)
                    .frame(width: CGFloat(project.window.width), height: CGFloat(project.window.height))
                    .allowsHitTesting(false)
            }
            
            // Subtle watermark / instruction label
            if project.showWatermark && !project.watermarkText.isEmpty {
                watermarkView
            }
            
            // Drag-and-drop indicator arrow baked into the background for Finder presentation
            if project.showArrow {
                if let appItem = project.items.first(where: { $0.isTargetApp }),
                   let appsShortcut = project.items.first(where: { $0.isApplicationsSymlink }) {
                    let start = CGPoint(
                        x: appItem.positionX + (project.window.iconSize * 0.42),
                        y: appItem.positionY
                    )
                    let end = CGPoint(
                        x: appsShortcut.positionX - (project.window.iconSize * 0.42),
                        y: appsShortcut.positionY
                    )
                    CanvasArrowView(startPoint: start, endPoint: end, style: project.arrowStyle)
                } else if project.items.count >= 2 {
                    let start = CGPoint(
                        x: project.items[0].positionX + (project.window.iconSize * 0.42),
                        y: project.items[0].positionY
                    )
                    let end = CGPoint(
                        x: project.items[1].positionX - (project.window.iconSize * 0.42),
                        y: project.items[1].positionY
                    )
                    CanvasArrowView(startPoint: start, endPoint: end, style: project.arrowStyle)
                }
            }
        }
        .frame(width: CGFloat(project.window.width), height: CGFloat(project.window.height))
        .clipped()
    }
    
    // MARK: - Base Background
    
    @ViewBuilder
    private var baseBackgroundView: some View {
        if let bgPath = project.backgroundImagePath, !bgPath.isEmpty,
           let nsImage = ImageCache.shared.image(atPath: bgPath) {
            Group {
                switch project.backgroundImageScalingMode {
                case .fill:
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .fit:
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .stretch:
                    Image(nsImage: nsImage)
                        .resizable()
                }
            }
            .scaleEffect(CGFloat(project.backgroundImageScale))
            .frame(width: CGFloat(project.window.width), height: CGFloat(project.window.height))
            .clipped()
        } else {
            presetGradientView
        }
    }
    
    @ViewBuilder
    private var presetGradientView: some View {
        switch project.backgroundPreset {
        case .modernGradient:
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.94, blue: 0.96),
                    Color(red: 0.86, green: 0.88, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .darkMinimal:
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.18, blue: 0.22),
                    Color(red: 0.09, green: 0.10, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .lightMinimal:
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.91, green: 0.92, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .oceanBlue:
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.16, blue: 0.28),
                    Color(red: 0.04, green: 0.08, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .customImage:
            // Fallback if custom image was deleted or not set
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.94, blue: 0.96),
                    Color(red: 0.86, green: 0.88, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Watermark
    
    private var watermarkView: some View {
        // Watermark follows the "Icon Font Color" so it matches the icon labels.
        let labelColor = Color(hexString: project.window.labelColorHex, defaultColor: .black)
        let textColor: Color = labelColor
        let iconColor: Color = labelColor.opacity(0.85)
        
        return VStack(spacing: 5) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(iconColor)
            
            Text(project.watermarkText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(labelColor.opacity(0.10))
                )
        }
        .position(
            x: CGFloat(project.window.width) / 2.0,
            y: CGFloat(project.window.height) - 44.0
        )
    }
}
