import Foundation

actor OutfitGeneratorService {
    static let shared = OutfitGeneratorService()

    private init() {}

    func generateOutfits(
        from items: [ClothingItem],
        eventType: EventType,
        mood: Mood,
        weather: String,
        temperature: Double?,
        count: Int = 5
    ) -> [Outfit] {
        guard items.count >= 3 else { return [] }

        let tops = items.filter { $0.category == .tops || $0.category == .dresses }
        let bottoms = items.filter { $0.category == .bottoms }
        let shoes = items.filter { $0.category == .shoes }
        let accessories = items.filter { $0.category == .accessories }
        let outerwear = items.filter { $0.category == .outerwear }

        var outfits: [Outfit] = []

        let outfitCount = min(count, max(tops.count * bottoms.count * shoes.count, 1))

        for i in 0..<outfitCount {
            var selectedItems: [ClothingItem] = []

            if let top = tops.randomElement(), !selectedItems.contains(top) {
                selectedItems.append(top)
            }
            if let bottom = bottoms.randomElement(), !selectedItems.contains(bottom) {
                selectedItems.append(bottom)
            }
            if let shoe = shoes.randomElement(), !selectedItems.contains(shoe) {
                selectedItems.append(shoe)
            }

            if mood.acceptsColor && Bool.random() {
                if let acc = accessories.randomElement(), !selectedItems.contains(acc) {
                    selectedItems.append(acc)
                }
            }

            if temperature != nil && temperature! < 15 && !outerwear.isEmpty {
                if let layer = outerwear.randomElement(), !selectedItems.contains(layer) {
                    selectedItems.append(layer)
                }
            }

            guard selectedItems.count >= 3 else { continue }

            let name = generateOutfitName(eventType: eventType, mood: mood, items: selectedItems)
            let outfit = Outfit(
                id: UUID(),
                name: name,
                itemIds: selectedItems.map { $0.id },
                eventType: eventType,
                mood: mood,
                weather: weather,
                temperature: temperature,
                createdAt: Date()
            )
            outfits.append(outfit)
        }

        return outfits
    }

    private func generateOutfitName(eventType: EventType, mood: Mood, items: [ClothingItem]) -> String {
        let prefixes = [
            "Effortless", "Polished", "Relaxed", "Chic", "Timeless",
            "Fresh", "Classic", "Modern", "Elevated", "Easy"
        ]

        let categoryWords: [ClothingCategory: [String]] = [
            .tops: ["Shirt", "Top", "Blouse", "Sweater"],
            .bottoms: ["Pant", "Jean", "Skirt", "Short"],
            .shoes: ["Step", "Look", "Fit", "Style"],
            .accessories: ["Touch", "Accent", "Detail"],
            .outerwear: ["Layer", "Coat", "Jacket"],
            .dresses: ["Dress", "Look", "Ensemble"],
            .unknown: ["Look", "Fit", "Style"]
        ]

        let prefix = prefixes.randomElement() ?? "Classic"
        let firstTop = items.first { $0.category == .tops || $0.category == .dresses }
        let suffix = categoryWords[firstTop?.category ?? .unknown]?.randomElement() ?? "Look"

        return "\(prefix) \(suffix)"
    }
}
