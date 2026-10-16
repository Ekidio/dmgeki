import SwiftUI
import AppKit

public struct CanvasItemView: View {
    @Binding var item: DMGItem
    let isSelected: Bool
    let windowSettings: DMGWindowSettings
    let snapToGrid: Bool
    let gridSpacing: Double
    let snapToGuides: Bool
    let otherItems: [DMGItem]
    let canvasWidth: Double
    let canvasHeight: Double
    let onSelect: () -> Void
    let onDraggingStateChanged: (Bool, CGPoint?, [CGPoint]) -> Void // isDragging, currentPos, activeGuides
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    public init(
        item: Binding<DMGItem>,
        isSelected: Bool,
        windowSettings: DMGWindowSettings,
        snapToGrid: Bool,
        gridSpacing: Double,
        snapToGuides: Bool,
        otherItems: [DMGItem],
        canvasWidth: Double,
        canvasHeight: Double,
        onSelect: @escaping () -> Void,
        onDraggingStateChanged: @escaping (Bool, CGPoint?, [CGPoint]) -> Void
    ) {
        self._item = item
        self.isSelected = isSelected
        self.windowSettings = windowSettings
        self.snapToGrid = snapToGrid
        self.gridSpacing = gridSpacing
        self.snapToGuides = snapToGuides
        self.otherItems = otherItems
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.onSelect = onSelect
        self.onDraggingStateChanged = onDraggingStateChanged
    }
    
    public var body: some View {
        let currentX = item.positionX + dragOffset.width
        let currentY = item.positionY + dragOffset.height
        
        VStack(spacing: 4) {
            if !windowSettings.labelOnBottom {
                HStack(spacing: 8) {
                    iconView
                    labelView
                }
            } else {
                iconView
                labelView
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : (isDragging ? Color.primary.opacity(0.06) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .overlay(alignment: .top) {
            if isDragging {
                Text("X: \(Int(currentX)), Y: \(Int(currentY))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 2)
                    .offset(y: -24)
            }
        }
        .position(x: currentX, y: currentY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        onSelect()
                    }
                    
                    var newX = item.positionX + value.translation.width
                    var newY = item.positionY + value.translation.height
                    
                    var activeGuides: [CGPoint] = []
                    let snapThreshold: Double = 8.0
                    
                    // Snap to window center
                    let centerX = canvasWidth / 2
                    let centerY = canvasHeight / 2
                    if snapToGuides {
                        if abs(newX - centerX) < snapThreshold {
                            newX = centerX
                            activeGuides.append(CGPoint(x: centerX, y: -1)) // Vertical line
                        }
                        if abs(newY - centerY) < snapThreshold {
                            newY = centerY
                            activeGuides.append(CGPoint(x: -1, y: centerY)) // Horizontal line
                        }
                        
                        // Snap to alignment with other items
                        for other in otherItems where other.id != item.id {
                            if abs(newX - other.positionX) < snapThreshold {
                                newX = other.positionX
                                activeGuides.append(CGPoint(x: other.positionX, y: -1))
                            }
                            if abs(newY - other.positionY) < snapThreshold {
                                newY = other.positionY
                                activeGuides.append(CGPoint(x: -1, y: other.positionY))
                            }
                        }
                    }
                    
                    // Snap to grid
                    if snapToGrid && gridSpacing > 0 {
                        let remX = newX.truncatingRemainder(dividingBy: gridSpacing)
                        if abs(remX) < snapThreshold {
                            newX = round(newX / gridSpacing) * gridSpacing
                        }
                        let remY = newY.truncatingRemainder(dividingBy: gridSpacing)
                        if abs(remY) < snapThreshold {
                            newY = round(newY / gridSpacing) * gridSpacing
                        }
                    }
                    
                    // Clamp to canvas bounds with padding
                    let halfIcon = windowSettings.iconSize / 2
                    newX = max(halfIcon, min(canvasWidth - halfIcon, newX))
                    newY = max(halfIcon, min(canvasHeight - halfIcon, newY))
                    
                    dragOffset = CGSize(width: newX - item.positionX, height: newY - item.positionY)
                    onDraggingStateChanged(true, CGPoint(x: newX, y: newY), activeGuides)
                }
                .onEnded { value in
                    item.positionX = round(item.positionX + dragOffset.width)
                    item.positionY = round(item.positionY + dragOffset.height)
                    dragOffset = .zero
                    isDragging = false
                    onDraggingStateChanged(false, nil, [])
                }
        )
        .onTapGesture {
            onSelect()
        }
    }
    
    private var iconView: some View {
        Image(nsImage: item.previewImage)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: CGFloat(windowSettings.iconSize), height: CGFloat(windowSettings.iconSize))
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
    }
    
    private var labelColor: Color {
        Color(hexString: windowSettings.labelColorHex, defaultColor: .black)
    }
    
    private var labelShadowColor: Color {
        let ns = NSColor(labelColor)
        guard let rgb = ns.usingColorSpace(.sRGB) else {
            return Color.white.opacity(0.85)
        }
        let lum = 0.299 * rgb.redComponent + 0.587 * rgb.greenComponent + 0.114 * rgb.blueComponent
        return lum > 0.5 ? Color.black.opacity(0.85) : Color.white.opacity(0.85)
    }
    
    private var labelView: some View {
        Text(item.destinationName)
            .font(.system(size: CGFloat(windowSettings.textSize), weight: .medium))
            .foregroundColor(labelColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: CGFloat(windowSettings.iconSize * 1.5))
            .shadow(color: labelShadowColor, radius: 0.8, x: 0, y: 0.5)
    }
}
