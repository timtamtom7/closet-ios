import Foundation

struct StyleProfile: Codable {
    var neutralColorRatio: Double
    var fittedRatio: Double
    var topTags: [String: Int]
    var totalItems: Int
    var totalOutfits: Int
    var mostWornItemIds: [UUID]
    var leastWornItemIds: [UUID]
    var dominantCategories: [ClothingCategory]
    var colorStory: String
    var styleSummary: String

    init(
        neutralColorRatio: Double = 0.5,
        fittedRatio: Double = 0.5,
        topTags: [String: Int] = [:],
        totalItems: Int = 0,
        totalOutfits: Int = 0,
        mostWornItemIds: [UUID] = [],
        leastWornItemIds: [UUID] = [],
        dominantCategories: [ClothingCategory] = [],
        colorStory: String = "",
        styleSummary: String = "Start adding clothes to discover your style."
    ) {
        self.neutralColorRatio = neutralColorRatio
        self.fittedRatio = fittedRatio
        self.topTags = topTags
        self.totalItems = totalItems
        self.totalOutfits = totalOutfits
        self.mostWornItemIds = mostWornItemIds
        self.leastWornItemIds = leastWornItemIds
        self.dominantCategories = dominantCategories
        self.colorStory = colorStory
        self.styleSummary = styleSummary
    }

    mutating func recompute(from items: [ClothingItem], outfits: [Outfit]) {
        totalItems = items.count
        totalOutfits = outfits.count

        let neutralColors: Set<String> = ["#000000", "#FFFFFF", "#808080", "#C0C0C0", "#F5F5DC", "#D3D3D3", "#Fafaf8", "#1C1C1E", "#6E6E73", "#B8A898"]
        let allColors = items.flatMap { $0.dominantColors }
        let neutralCount = allColors.filter { color in
            neutralColors.contains { $0.lowercased() == color.lowercased() }
        }.count
        neutralColorRatio = allColors.isEmpty ? 0.5 : Double(neutralCount) / Double(allColors.count)

        let fittedTags = ["fitted", "slim", "tailored", "structured"]
        let fittedCount = items.filter { item in
            item.tags.contains { fittedTags.contains($0.lowercased()) }
        }.count
        fittedRatio = items.isEmpty ? 0.5 : Double(fittedCount) / Double(items.count)

        var tagCounts: [String: Int] = [:]
        for item in items {
            for tag in item.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        topTags = tagCounts

        var categoryCounts: [ClothingCategory: Int] = [:]
        for item in items {
            categoryCounts[item.category, default: 0] += 1
        }
        dominantCategories = categoryCounts.sorted { $0.value > $1.value }.map { $0.key }

        let neutralPercent = Int(neutralColorRatio * 100)
        if neutralPercent > 70 {
            colorStory = "Your wardrobe leans \(neutralPercent)% neutral — a timeless, versatile palette."
        } else if neutralPercent > 40 {
            colorStory = "Balanced between \(neutralPercent)% neutral tones and colorful accents."
        } else {
            colorStory = "Bold and colorful — only \(neutralPercent)% of your wardrobe is neutral."
        }

        let fittedPercent = Int(fittedRatio * 100)
        let cutDescription = fittedPercent > 60 ? "fitted and tailored" : (fittedPercent > 40 ? "mixing fitted and relaxed" : "relaxed and flowy")

        let outfitCount = outfits.count
        styleSummary = "You gravitate toward \(cutDescription) pieces. \(colorStory) You've logged \(outfitCount) outfit\(outfitCount == 1 ? "" : "s")."
    }
}
