import SwiftUI

struct CategoryChip: View {
    let category: ClothingCategory?
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var label: String {
        category?.rawValue ?? "All"
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : ClosetDesign.Colors.tertiaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ClosetDesign.Colors.primaryText : ClosetDesign.Colors.divider)
                .clipShape(Capsule())
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
