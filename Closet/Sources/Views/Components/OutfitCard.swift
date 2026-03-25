import SwiftUI

struct OutfitCard: View {
    let outfit: Outfit
    let items: [ClothingItem]
    let onSave: () -> Void
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                HStack(spacing: -16) {
                    ForEach(Array(outfit.itemIds.prefix(3).enumerated()), id: \.offset) { index, itemId in
                        if let item = items.first(where: { $0.id == itemId }) {
                            OutfitItemThumbnail(item: item)
                                .zIndex(Double(3 - index))
                                .offset(x: CGFloat(index) * -8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 6) {
                Text(outfit.name)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                HStack(spacing: 8) {
                    Label(outfit.eventType.rawValue, systemImage: outfit.eventType.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    Text("·")
                        .foregroundStyle(Color(hex: "#E8E8E6"))

                    Label(outfit.weather, systemImage: "cloud.sun.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    if let temp = outfit.temperature {
                        Text("·")
                            .foregroundStyle(Color(hex: "#E8E8E6"))
                        Text("\(Int(temp))°C")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
                }
            }

            HStack(spacing: 32) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        offset = -300
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: "#E8E8E6"))
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        offset = 0
                        opacity = 1
                    }
                    onSave()
                } label: {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: "#B8A898"))
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "#1C1C1E").opacity(0.08), radius: 20, x: 0, y: 8)
        .offset(x: offset)
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.width
                }
                .onEnded { value in
                    if value.translation.width < -100 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            offset = -300
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    } else if value.translation.width > 100 {
                        onSave()
                        offset = 0
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            offset = 0
                        }
                    }
                }
        )
    }
}

struct OutfitItemThumbnail: View {
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
        .frame(width: 140, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}
