import SwiftUI

struct CameraOverlayGuide: View {
    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let centerY = geo.size.height / 2
            let guideWidth = min(geo.size.width * 0.8, 320)
            let guideHeight = guideWidth * 1.3

            ZStack {
                // Semi-transparent overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                // Clear center
                Rectangle()
                    .frame(width: guideWidth, height: guideHeight)
                    .blendMode(.destinationOut)

                // Corner guides
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.8), lineWidth: 3)
                    .frame(width: guideWidth, height: guideHeight)
                    .blendMode(.destinationOut)

                // Corner brackets
                CornerBracket()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .position(x: centerX - guideWidth/2 + 20, y: centerY - guideHeight/2 + 20)

                CornerBracket()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(90))
                    .position(x: centerX + guideWidth/2 - 20, y: centerY - guideHeight/2 + 20)

                CornerBracket()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .position(x: centerX - guideWidth/2 + 20, y: centerY + guideHeight/2 - 20)

                CornerBracket()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(180))
                    .position(x: centerX + guideWidth/2 - 20, y: centerY + guideHeight/2 - 20)

                // Instruction text
                VStack {
                    Spacer()

                    Text("Center the clothing item within the frame")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())

                    Spacer()
                        .frame(height: 100)
                }
            }
            .compositingGroup()
        }
    }
}

struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 8

        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

        return path
    }
}

struct CameraGuideOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let guideWidth = min(geo.size.width * 0.75, 300)
            let guideHeight = guideWidth * 1.2

            ZStack {
                Color.clear

                // Top-left bracket
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 40))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 40, y: 0))
                }
                .stroke(Color.white.opacity(0.9), lineWidth: 3)

                // Top-right bracket
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - 40, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 40))
                }
                .stroke(Color.white.opacity(0.9), lineWidth: 3)

                // Bottom-left bracket
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height - 40))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 40, y: geo.size.height))
                }
                .stroke(Color.white.opacity(0.9), lineWidth: 3)

                // Bottom-right bracket
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - 40, y: geo.size.height))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - 40))
                }
                .stroke(Color.white.opacity(0.9), lineWidth: 3)

                // Center hint lines
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width/2 - guideWidth/2 + 20, y: geo.size.height/2))
                    path.addLine(to: CGPoint(x: geo.size.width/2 + guideWidth/2 - 20, y: geo.size.height/2))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)

                Path { path in
                    path.move(to: CGPoint(x: geo.size.width/2, y: geo.size.height/2 - guideHeight/2 + 20))
                    path.addLine(to: CGPoint(x: geo.size.width/2, y: geo.size.height/2 + guideHeight/2 - 20))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            }
        }
    }
}
