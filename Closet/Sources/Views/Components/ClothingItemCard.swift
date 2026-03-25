import SwiftUI

struct ClothingItemCard: View {
    let item: ClothingItem
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(hex: "#E8E8E6"))
                            .overlay {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color(hex: "#6E6E73"))
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onTapGesture { onTap() }
            .task {
                image = await ImageStorageService.shared.loadImage(path: item.imagePath)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.category.rawValue)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    if item.wearCount > 0 {
                        Text("· \(item.wearCount)x")
                            .font(.system(size: 11, weight: .regular, design: .default))
                            .foregroundStyle(Color(hex: "#B8A898"))
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
