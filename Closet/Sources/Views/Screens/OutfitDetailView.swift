import SwiftUI

struct OutfitDetailView: View {
    let outfit: Outfit
    let items: [ClothingItem]
    let onDelete: () -> Void
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Outfit image grid
                    VStack(spacing: -12) {
                        HStack(spacing: -12) {
                            ForEach(Array(outfit.itemIds.prefix(3).enumerated()), id: \.offset) { index, itemId in
                                if let item = items.first(where: { $0.id == itemId }) {
                                    OutfitDetailThumbnail(item: item)
                                        .zIndex(Double(3 - index))
                                        .offset(x: CGFloat(index) * -8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 20)

                    // Outfit info
                    VStack(spacing: 12) {
                        Text(outfit.name)
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(Color(hex: "#1C1C1E"))

                        HStack(spacing: 16) {
                            Label(outfit.eventType.rawValue, systemImage: outfit.eventType.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#6E6E73"))

                            Label(outfit.mood.rawValue, systemImage: "face.smiling")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "#6E6E73"))

                            if let temp = outfit.temperature {
                                Label("\(Int(temp))°", systemImage: "thermometer")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#6E6E73"))
                            }
                        }

                        Text("Saved on \(outfit.createdAt.formatted(date: .long, time: .shortened))")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
                    .padding(.horizontal, 20)

                    // Items list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Items in this outfit")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(hex: "#1C1C1E"))

                        ForEach(outfit.itemIds, id: \.self) { itemId in
                            if let item = items.first(where: { $0.id == itemId }) {
                                HStack(spacing: 12) {
                                    if let image = AsyncImageView(item: item).asImage() {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 56, height: 72)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "#E8E8E6"))
                                            .frame(width: 56, height: 72)
                                            .overlay {
                                                Image(systemName: item.category.icon)
                                                    .foregroundStyle(Color(hex: "#6E6E73"))
                                            }
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color(hex: "#1C1C1E"))

                                        Text(item.category.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color(hex: "#6E6E73"))
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            onShare()
                            dismiss()
                        } label: {
                            Label("Share Outfit Card", systemImage: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#1C1C1E"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                                }
                        }

                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Delete Outfit", systemImage: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "#C45C4A"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#FAFAF8"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#C45C4A").opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#1C1C1E"))
                }
            }
        }
    }
}

struct OutfitDetailThumbnail: View {
    let item: ClothingItem
    @State private var image: UIImage?

    var body: some View {
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
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .frame(width: 140, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}

extension View {
    @MainActor
    func asImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        let targetSize = controller.view.intrinsicContentSize
        guard targetSize.width > 0 && targetSize.height > 0 else { return nil }
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
