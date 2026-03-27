import Foundation
#if os(iOS)
import UIKit
import SwiftUI

actor ShareService {
    static let shared = ShareService()

    private init() {}

    @MainActor
    func shareOutfitCard(
        outfit: Outfit,
        items: [ClothingItem],
        weather: WeatherService.WeatherInfo?
    ) async -> UIImage? {
        let view = OutfitShareCardView(outfit: outfit, items: items, weather: weather)
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(x: 0, y: 0, width: 400, height: 500)

        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    @MainActor
    func shareWeeklyLookbook(outfits: [Outfit], items: [ClothingItem]) async -> UIImage? {
        let view = WeeklyLookbookView(outfits: outfits, items: items)
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(x: 0, y: 0, width: 400, height: 700)

        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct OutfitShareCardView: View {
    let outfit: Outfit
    let items: [ClothingItem]
    let weather: WeatherService.WeatherInfo?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: -12) {
                ForEach(Array(outfit.itemIds.prefix(3).enumerated()), id: \.offset) { index, itemId in
                    if let item = items.first(where: { $0.id == itemId }) {
                        AsyncImageView(item: item)
                            .frame(width: 120, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .zIndex(Double(3 - index))
                            .offset(x: CGFloat(index) * -8)
                    }
                }
            }
            .padding(.top, 24)

            VStack(spacing: 6) {
                Text(outfit.name)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                HStack(spacing: 8) {
                    Label(outfit.eventType.rawValue, systemImage: outfit.eventType.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    if let weather = weather {
                        Text("·")
                            .foregroundStyle(Color(hex: "#E8E8E6"))
                        Label(weather.description, systemImage: weather.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
                }

                Text(generateCaption())
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Color(hex: "#B8A898"))
                    .padding(.top, 4)
            }

            Spacer()

            Text("Curated with Closet")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .frame(width: 400, height: 500)
        .background(Color(hex: "#FAFAF8"))
    }

    private func generateCaption() -> String {
        let captions = [
            "Effortlessly elegant in neutrals.",
            "Understated and refined.",
            "A study in effortless style.",
            "Chic and completely you.",
            "The art of looking effortless."
        ]
        return captions.randomElement() ?? "Styled with Closet."
    }
}

struct WeeklyLookbookView: View {
    let outfits: [Outfit]
    let items: [ClothingItem]

    var body: some View {
        VStack(spacing: 16) {
            Text("This Week's Looks")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .padding(.top, 24)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(outfits.prefix(7).enumerated()), id: \.offset) { index, outfit in
                    VStack(spacing: 4) {
                        HStack(spacing: -8) {
                            ForEach(Array(outfit.itemIds.prefix(2).enumerated()), id: \.offset) { _, itemId in
                                if let item = items.first(where: { $0.id == itemId }) {
                                    AsyncImageView(item: item)
                                        .frame(width: 50, height: 65)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }

                        Text(dayName(for: index))
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Text("Curated with Closet")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .padding(.bottom, 16)
        }
        .frame(width: 400, height: 700)
        .background(Color(hex: "#FAFAF8"))
    }

    private func dayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[safe: index] ?? "Day"
    }
}

struct AsyncImageView: View {
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
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}
#endif

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
