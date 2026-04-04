import SwiftUI

@Environment(\.colorScheme) var colorScheme

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
                            .fill(ClosetDesign.Colors.divider)
                            .overlay {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.image))
            }
            .onTapGesture { onTap() }
            .task {
                image = await ImageStorageService.shared.loadImage(path: item.imagePath)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(ClosetDesign.Typography.bodyMedium)
                    .foregroundStyle(ClosetDesign.Colors.primaryText)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.category.rawValue)
                        .font(ClosetDesign.Typography.tag)
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)

                    if item.wearCount > 0 {
                        Text("· \(item.wearCount)x")
                            .font(ClosetDesign.Typography.tag)
                            .foregroundStyle(ClosetDesign.Colors.accent)
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
