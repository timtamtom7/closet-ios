import SwiftUI

/// R14: Vision Pro spatial wardrobe
/// Spatial display of wardrobe items
struct SpatialWardrobeView: View {
    @State private var selectedCategory: SpatialCategory = .tops
    @State private var selectedItem: SpatialWardrobeItem?

    enum SpatialCategory: String, CaseIterable {
        case tops = "Tops"
        case bottoms = "Bottoms"
        case dresses = "Dresses"
        case outerwear = "Outerwear"
        case shoes = "Shoes"
        case accessories = "Accessories"

        var icon: String {
            switch self {
            case .tops: return "tshirt.fill"
            case .bottoms: return "figure.walk"
            case .dresses: return "figure.dress.line.vertical.figure"
            case .outerwear: return "cloud.snow.fill"
            case .shoes: return "shoe.fill"
            case .accessories: return "watch.analog"
            }
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "1A1A1A").ignoresSafeArea()

            VStack(spacing: 24) {
                categorySelector

                if let items = mockItems(for: selectedCategory), !items.isEmpty {
                    spatialGrid(items)
                } else {
                    emptyState
                }
            }
        }
    }

    private var categorySelector: some View {
        HStack(spacing: 16) {
            ForEach(SpatialCategory.allCases, id: \.self) { category in
                Button {
                    withAnimation {
                        selectedCategory = category
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .font(.title2)
                        Text(category.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(selectedCategory == category ? .white : .gray)
                    .padding()
                    .background(selectedCategory == category ? Color.white.opacity(0.2) : Color.clear)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func spatialGrid(_ items: [SpatialWardrobeItem]) -> some View {
        let columns = [GridItem(.adaptive(minimum: 140))]

        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    SpatialWardrobeCard(item: item, isSelected: selectedItem?.id == item.id)
                        .onTapGesture {
                            withAnimation {
                                selectedItem = item
                            }
                        }
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hanger")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No items in this category")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }

    private func mockItems(for category: SpatialCategory) -> [SpatialWardrobeItem]? {
        switch category {
        case .tops:
            return [
                SpatialWardrobeItem(id: UUID(), name: "White T-Shirt", category: "tops", color: "White"),
                SpatialWardrobeItem(id: UUID(), name: "Navy Blazer", category: "tops", color: "Navy"),
                SpatialWardrobeItem(id: UUID(), name: "Gray Sweater", category: "tops", color: "Gray")
            ]
        case .bottoms:
            return [
                SpatialWardrobeItem(id: UUID(), name: "Dark Jeans", category: "bottoms", color: "Dark Blue"),
                SpatialWardrobeItem(id: UUID(), name: "Black Pants", category: "bottoms", color: "Black")
            ]
        case .dresses:
            return [
                SpatialWardrobeItem(id: UUID(), name: "Little Black Dress", category: "dresses", color: "Black")
            ]
        case .outerwear:
            return [
                SpatialWardrobeItem(id: UUID(), name: "Trench Coat", category: "outerwear", color: "Beige")
            ]
        case .shoes:
            return [
                SpatialWardrobeItem(id: UUID(), name: "White Sneakers", category: "shoes", color: "White"),
                SpatialWardrobeItem(id: UUID(), name: "Brown Boots", category: "shoes", color: "Brown")
            ]
        case .accessories:
            return [
                SpatialWardrobeItem(id: UUID(), name: "Leather Watch", category: "accessories", color: "Brown")
            ]
        }
    }
}

struct SpatialWardrobeItem: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let color: String
}

struct SpatialWardrobeCard: View {
    let item: SpatialWardrobeItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(itemGradient)
                .frame(height: 120)
                .overlay {
                    VStack {
                        Image(systemName: "tshirt.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

            Text(item.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(item.color)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(16)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 2)
            }
        }
    }

    private var itemGradient: LinearGradient {
        let color = itemColor(item.color)
        return LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func itemColor(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "white": return Color(hex: "E5E5E5")
        case "navy", "dark blue": return Color(hex: "1A1A2E")
        case "gray": return Color(hex: "6E6E73")
        case "black": return Color(hex: "2C2C2C")
        case "beige": return Color(hex: "D4C5B5")
        case "brown": return Color(hex: "8B4513")
        default: return Color(hex: "6E6E73")
        }
    }
}
