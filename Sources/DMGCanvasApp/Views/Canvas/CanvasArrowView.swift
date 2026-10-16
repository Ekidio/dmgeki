import SwiftUI

public struct CanvasArrowView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let style: DMGArrowStyle
    
    public init(startPoint: CGPoint, endPoint: CGPoint, style: DMGArrowStyle = .curved) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.style = style
    }
    
    public var body: some View {
        if style != .none {
            ZStack {
                switch style {
                case .curved:
                    CurvedArrowShape(start: startPoint, end: endPoint)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    ArrowHead(end: endPoint, angle: calculateAngle())
                        .fill(Color.cyan)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                case .straight:
                    Path { path in
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    .stroke(
                        Color.primary.opacity(0.5),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4])
                    )
                    
                    ArrowHead(end: endPoint, angle: calculateStraightAngle())
                        .fill(Color.primary.opacity(0.7))
                    
                case .gradient:
                    CurvedArrowShape(start: startPoint, end: endPoint)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple, Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .shadow(color: Color.cyan.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    ArrowHead(end: endPoint, angle: calculateAngle())
                        .fill(Color.cyan)
                        .shadow(color: Color.cyan.opacity(0.8), radius: 6, x: 0, y: 0)
                    
                case .minimal:
                    Path { path in
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    .stroke(
                        Color.secondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    
                    ArrowHead(end: endPoint, angle: calculateStraightAngle(), size: 8)
                        .fill(Color.secondary.opacity(0.6))
                    
                case .none:
                    EmptyView()
                }
            }
        }
    }
    
    private func calculateStraightAngle() -> Double {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        return atan2(dy, dx)
    }
    
    private func calculateAngle() -> Double {
        let midX = (startPoint.x + endPoint.x) / 2
        let midY = min(startPoint.y, endPoint.y) - 40
        let dx = endPoint.x - midX
        let dy = endPoint.y - midY
        return atan2(dy, dx)
    }
}

fileprivate struct CurvedArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        
        // Arc upwards slightly for a natural drag-to-install curve
        let midX = (start.x + end.x) / 2
        let controlY = min(start.y, end.y) - 35
        let controlPoint = CGPoint(x: midX, y: controlY)
        
        path.addQuadCurve(to: end, control: controlPoint)
        return path
    }
}

fileprivate struct ArrowHead: Shape {
    let end: CGPoint
    let angle: Double
    var size: CGFloat = 12
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let p1 = CGPoint(
            x: end.x - size * cos(angle - .pi / 6),
            y: end.y - size * sin(angle - .pi / 6)
        )
        let p2 = CGPoint(
            x: end.x - size * cos(angle + .pi / 6),
            y: end.y - size * sin(angle + .pi / 6)
        )
        
        path.move(to: end)
        path.addLine(to: p1)
        path.addLine(to: CGPoint(x: end.x - (size * 0.7) * cos(angle), y: end.y - (size * 0.7) * sin(angle)))
        path.addLine(to: p2)
        path.closeSubpath()
        
        return path
    }
}
