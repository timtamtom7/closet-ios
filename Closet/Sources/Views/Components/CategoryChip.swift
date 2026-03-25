import SwiftUI

struct CategoryChip: View {
    let category: ClothingCategory?
    let isSelected: Bool
    let action: () -> Void

    var label: String {
        category?.rawValue ?? "All"
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : Color(hex: "#6E6E73"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
