import SwiftUI

struct StyleStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double

    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                .textCase(.uppercase)
                .tracking(1.2)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(ClosetDesign.Colors.primaryText)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(ClosetDesign.Colors.tertiaryText)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ClosetDesign.Colors.divider)
                        .frame(height: 4)
                        .clipShape(Capsule())

                    Rectangle()
                        .fill(ClosetDesign.Colors.accent)
                        .frame(width: geo.size.width * animatedProgress, height: 4)
                        .clipShape(Capsule())
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .frame(width: 140, height: 160)
        .background(ClosetDesign.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.card))
        .shadow(color: ClosetDesign.Colors.primaryText.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75)) {
                animatedProgress = progress
            }
        }
    }
}
