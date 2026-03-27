import SwiftUI

struct StyleStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(Color.closetSecondaryText)
                .textCase(.uppercase)
                .tracking(1.2)

            Text(value)
                .font(.system(size: 40, weight: .bold, design: .serif))
                .foregroundStyle(Color.closetPrimaryText)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(Color.closetSecondaryText)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.closetDivider)
                        .frame(height: 4)
                        .clipShape(Capsule())

                    Rectangle()
                        .fill(Color.closetAccent)
                        .frame(width: geo.size.width * animatedProgress, height: 4)
                        .clipShape(Capsule())
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .frame(width: 140, height: 160)
        .background(Color.closetSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .shadow(color: Color.closetPrimaryText.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}
