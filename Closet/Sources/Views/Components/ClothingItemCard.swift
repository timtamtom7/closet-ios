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
                            .fill(Color.closetDivider)
                            .overlay {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.closetSecondaryText)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            }
            .onTapGesture {
                ClosetHaptics.light()
                onTap()
            }
            .accessibilityLabel(item.name)
            .accessibilityHint("Tap to view details")
            .task {
                image = await ImageStorageService.shared.loadImage(path: item.imagePath)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundStyle(Color.closetPrimaryText)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.category.rawValue)
                        .font(ClosetFont.caption2)
                        .foregroundStyle(Color.closetSecondaryText)

                    if item.wearCount > 0 {
                        Text("· \(item.wearCount)x")
                            .font(ClosetFont.caption2)
                            .foregroundStyle(Color.closetAccent)
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                ClosetHaptics.warning()
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete \(item.name)")
        }
    }
}
