import SwiftUI

struct CategoryChip: View {
    let category: ClothingCategory?
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        category?.rawValue ?? "All"
    }

    var body: some View {
        Button(action: {
            ClosetHaptics.selection()
            action()
        }) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color.closetSecondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.closetPrimaryText : Color.closetDivider)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
