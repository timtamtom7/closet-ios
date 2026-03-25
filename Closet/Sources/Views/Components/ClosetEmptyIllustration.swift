import SwiftUI

/// An elegant ivory editorial illustration for Closet's empty states.
struct ClosetEmptyIllustration: View {
    let size: CGFloat

    // Ivory editorial palette
    private let ivory = Color(hex: "F5F0EB")
    private let warmGray = Color(hex: "6E6E73")
    private let charcoal = Color(hex: "1C1C1E")
    private let softTaupe = Color(hex: "C7B8A8")
    private let blush = Color(hex: "E8D5CF")

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let scale = size / 300

            // Soft ivory glow
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - 90 * scale,
                    y: center.y - 90 * scale,
                    width: 180 * scale,
                    height: 180 * scale
                )),
                with: .radialGradient(
                    Gradient(colors: [softTaupe.opacity(0.15), Color.clear]),
                    center: center,
                    startRadius: 0,
                    endRadius: 90 * scale
                )
            )

            // Elegant wardrobe outline
            let wardrobeX = center.x
            let wardrobeY = center.y + 20 * scale
            let wardrobeW: CGFloat = 120 * scale
            let wardrobeH: CGFloat = 160 * scale

            // Wardrobe body (rectangle with rounded corners)
            let wardrobeRect = CGRect(
                x: wardrobeX - wardrobeW / 2,
                y: wardrobeY - wardrobeH / 2,
                width: wardrobeW,
                height: wardrobeH
            )
            let wardrobePath = Path(roundedRect: wardrobeRect, cornerRadius: 8 * scale)
            context.stroke(wardrobePath, with: .color(softTaupe.opacity(0.4)), lineWidth: 1.5 * scale)

            // Wardrobe inner frame (door divider)
            let doorX = wardrobeX
            var doorPath = Path()
            doorPath.move(to: CGPoint(x: doorX, y: wardrobeY - wardrobeH / 2))
            doorPath.addLine(to: CGPoint(x: doorX, y: wardrobeY + wardrobeH / 2))
            context.stroke(doorPath, with: .color(softTaupe.opacity(0.3)), lineWidth: 1 * scale)

            // Hanging rod
            var rodPath = Path()
            rodPath.move(to: CGPoint(x: wardrobeX - wardrobeW / 2 + 10 * scale, y: wardrobeY - wardrobeH / 4))
            rodPath.addLine(to: CGPoint(x: wardrobeX + wardrobeW / 2 - 10 * scale, y: wardrobeY - wardrobeH / 4))
            context.stroke(rodPath, with: .color(softTaupe.opacity(0.35)), lineWidth: 1.5 * scale)

            // Hangers (simplified triangular shapes)
            let hangerY = wardrobeY - wardrobeH / 4 - 5 * scale
            let hangerSpacing = 28 * scale
            for i in -1...1 {
                let hx = wardrobeX + CGFloat(i) * hangerSpacing
                var hangerPath = Path()
                hangerPath.move(to: CGPoint(x: hx - 8 * scale, y: hangerY + 15 * scale))
                hangerPath.addLine(to: CGPoint(x: hx, y: hangerY))
                hangerPath.addLine(to: CGPoint(x: hx + 8 * scale, y: hangerY + 15 * scale))
                context.stroke(hangerPath, with: .color(softTaupe.opacity(0.3)), lineWidth: 1 * scale)
            }

            // Clothing items (simplified t-shirt shape)
            let shirtY = wardrobeY + wardrobeH / 6
            let shirtScale = 14 * scale
            for i in -1...1 {
                let sx = wardrobeX + CGFloat(i) * 32 * scale
                drawTShirt(context: context, center: CGPoint(x: sx, y: shirtY), scale: shirtScale, color: blush.opacity(0.5))
            }

            // Small decorative elements
            let dots: [(CGPoint, CGFloat)] = [
                (CGPoint(x: 50 * scale, y: 60 * scale), 3 * scale),
                (CGPoint(x: 250 * scale, y: 80 * scale), 2 * scale),
                (CGPoint(x: 40 * scale, y: 240 * scale), 2 * scale),
                (CGPoint(x: 260 * scale, y: 220 * scale), 3 * scale),
            ]
            for (pos, radius) in dots {
                var dotPath = Path()
                dotPath.addEllipse(in: CGRect(
                    x: pos.x - radius,
                    y: pos.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(dotPath, with: .color(softTaupe.opacity(0.2)))
            }

            // Elegant curved line (decorative)
            var curvePath = Path()
            curvePath.move(to: CGPoint(x: 60 * scale, y: 140 * scale))
            curvePath.addQuadCurve(
                to: CGPoint(x: 240 * scale, y: 140 * scale),
                control: CGPoint(x: 150 * scale, y: 120 * scale)
            )
            context.stroke(curvePath, with: .color(softTaupe.opacity(0.15)), lineWidth: 1 * scale)
        }
        .frame(width: size, height: size)
    }

    private func drawTShirt(context: GraphicsContext, center: CGPoint, scale: CGFloat, color: Color) {
        var path = Path()

        // T-shirt shape using bezier curves
        path.move(to: CGPoint(x: center.x - scale * 1.2, y: center.y - scale * 0.3))
        // Left sleeve
        path.addLine(to: CGPoint(x: center.x - scale * 1.8, y: center.y + scale * 0.2))
        path.addLine(to: CGPoint(x: center.x - scale * 1.4, y: center.y + scale * 0.4))
        // Left body
        path.addLine(to: CGPoint(x: center.x - scale * 0.8, y: center.y + scale * 0.5))
        // Bottom
        path.addLine(to: CGPoint(x: center.x + scale * 0.8, y: center.y + scale * 0.5))
        // Right body
        path.addLine(to: CGPoint(x: center.x + scale * 1.4, y: center.y + scale * 0.4))
        // Right sleeve
        path.addLine(to: CGPoint(x: center.x + scale * 1.8, y: center.y + scale * 0.2))
        path.addLine(to: CGPoint(x: center.x + scale * 1.2, y: center.y - scale * 0.3))
        // Neck
        path.addQuadCurve(
            to: CGPoint(x: center.x - scale * 0.4, y: center.y - scale * 0.3),
            control: CGPoint(x: center.x, y: center.y - scale * 0.8)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - scale * 1.2, y: center.y - scale * 0.3),
            control: CGPoint(x: center.x - scale * 0.6, y: center.y - scale * 0.6)
        )
        path.closeSubpath()

        context.fill(path, with: .color(color))
    }
}



#Preview {
    ZStack {
        Color(hex: "FAF8F5").ignoresSafeArea()
        ClosetEmptyIllustration(size: 200)
    }
}
