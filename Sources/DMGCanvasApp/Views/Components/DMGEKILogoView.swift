import SwiftUI
import AppKit

public struct DMGEKILogoView: View {
    public var scale: CGFloat = 1.0
    
    public init(scale: CGFloat = 1.0) {
        self.scale = scale
    }
    
    public var body: some View {
        HStack(spacing: 5 * scale) {
            // "DMG" in white/primary bold italic typography
            Text("DMG")
                .font(.system(size: 15 * scale, weight: .black, design: .default).italic())
                .foregroundColor(.primary)
                .tracking(-0.6 * scale)
                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            
            // "EKI" in skewed #27A3F5 blue badge with inner grid lines
            ZStack {
                // Background #27A3F5
                RoundedRectangle(cornerRadius: 3.5 * scale)
                    .fill(Color(red: 39.0 / 255.0, green: 163.0 / 255.0, blue: 245.0 / 255.0))
                
                // Inner 4x4 grid overlay
                EKIGridOverlay()
                    .opacity(0.35)
                    .clipShape(RoundedRectangle(cornerRadius: 3.5 * scale))
                
                // "EKI" bold italic text
                Text("EKI")
                    .font(.system(size: 13.5 * scale, weight: .black, design: .default).italic())
                    .foregroundColor(.white)
                    .tracking(-0.2 * scale)
                    .padding(.horizontal, 7 * scale)
                    .padding(.vertical, 2.5 * scale)
            }
            .fixedSize()
            .transformEffect(CGAffineTransform(1, 0, -0.2125, 1, 0, 0))
            .shadow(color: Color(red: 39.0 / 255.0, green: 163.0 / 255.0, blue: 245.0 / 255.0).opacity(0.5), radius: 6 * scale, x: 0, y: 0)
        }
        .padding(.horizontal, 2)
    }
}

private struct EKIGridOverlay: View {
    var body: some View {
        Canvas { context, size in
            let cols = 4
            let rows = 4
            let stepX = size.width / CGFloat(cols)
            let stepY = size.height / CGFloat(rows)
            
            // Vertical lines
            for i in 1..<cols {
                var p = Path()
                let x = stepX * CGFloat(i)
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(p, with: .color(.black), lineWidth: 1.2)
            }
            
            // Horizontal lines
            for j in 1..<rows {
                var p = Path()
                let y = stepY * CGFloat(j)
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(.black), lineWidth: 1.2)
            }
        }
    }
}
