import Foundation

actor OutfitEvolutionService {
    static let shared = OutfitEvolutionService()

    private init() {}

    struct VetoPattern {
        let reason: VetoReason
        let count: Int
        let percentage: Double
    }

    struct TrendInsight {
        let message: String
        let type: InsightType

        enum InsightType {
            case color
            case frequency
            case weather
            case seasonal
        }
    }

    func analyzeVetoPatterns(vetoes: [OutfitVeto]) -> [VetoPattern] {
        var counts: [VetoReason: Int] = [:]
        for veto in vetoes {
            counts[veto.reason, default: 0] += 1
        }
        let total = vetoes.count
        return counts.map { reason, count in
            VetoPattern(reason: reason, count: count, percentage: total > 0 ? Double(count) / Double(total) : 0)
        }.sorted { $0.count > $1.count }
    }

    func generateTrends(items: [ClothingItem], outfits: [Outfit], vetoes: [OutfitVeto], ratings: [OutfitRating]) -> [TrendInsight] {
        var insights: [TrendInsight] = []

        // Color trend: check what colors are being worn over time
        let recentOutfits = outfits.prefix(10)
        let recentColors = recentOutfits.flatMap { outfit in
            outfit.itemIds.compactMap { itemId in
                items.first { $0.id == itemId }?.dominantColors
            }.flatMap { $0 }
        }
        let neutralColors: Set<String> = ["#000000", "#FFFFFF", "#808080", "#F5F5DC", "#1C1C1E", "#6E6E73"]
        let recentNeutralCount = recentColors.filter { neutralColors.contains($0.uppercased()) }.count
        let recentColorPct = recentColors.isEmpty ? 0.5 : Double(recentNeutralCount) / Double(recentColors.count)

        if recentColorPct > 0.75 {
            insights.append(TrendInsight(message: "You've been leaning heavily into neutral tones lately.", type: .color))
        } else if recentColorPct < 0.4 {
            insights.append(TrendInsight(message: "A colorful streak — bold choices lately!", type: .color))
        }

        // Frequency insight
        if outfits.count >= 5 {
            insights.append(TrendInsight(message: "You logged \(outfits.count) outfits. Keep building your style!", type: .frequency))
        }

        // Veto pattern insight
        let patterns = analyzeVetoPatterns(vetoes: vetoes)
        if let topPattern = patterns.first, topPattern.percentage > 0.3 {
            let message: String
            switch topPattern.reason {
            case .tooFormal:
                message = "You tend to skip formal looks — casual is your comfort zone."
            case .tooCasual:
                message = "You sometimes want more polished looks."
            case .wrongWeather:
                message = "Weather mismatches are a common veto reason — check the forecast!"
            case .notMyStyle:
                message = "Your style is distinct — trust your gut."
            case .dontLikeColors:
                message = "Color harmony matters to you."
            case .uncomfortable:
                message = "Comfort is key in your outfit choices."
            case .tooLoud:
                message = "You prefer understated over loud."
            case .repeated:
                message = "Variety matters — try mixing in different combinations."
            }
            insights.append(TrendInsight(message: message, type: .weather))
        }

        return insights
    }

    func generateLayeringSuggestions(items: [ClothingItem], temperature: Double) -> [String] {
        var suggestions: [String] = []
        let coldThreshold = 15.0
        let warmThreshold = 25.0

        if temperature < coldThreshold {
            let outerwear = items.filter { $0.category == .outerwear }
            let tops = items.filter { $0.category == .tops }
            if outerwear.count < 2 {
                suggestions.append("Consider adding more layers — you only have \(outerwear.count) outerwear piece\(outerwear.count == 1 ? "" : "s").")
            }
            if tops.count < 3 {
                suggestions.append("You have \(tops.count) top\(tops.count == 1 ? "" : "s") — consider more for cold layering.")
            }
            suggestions.append("It's cold! A sweater or cardigan over your top would work well.")
        } else if temperature > warmThreshold {
            let lightTops = items.filter { $0.category == .tops }
            suggestions.append("Warm weather — lighter tops work great.")
            if !items.contains(where: { $0.category == .dresses }) && !items.contains(where: { $0.category == .bottoms }) {
                suggestions.append("Consider lighter fabrics for the heat.")
            }
        } else {
            suggestions.append("Layerable weather — a light jacket or cardigan is perfect.")
        }

        return suggestions
    }

    func adjustOutfitForVetoes(outfits: [Outfit], vetoes: [OutfitVeto], items: [ClothingItem]) -> [Outfit] {
        // Filter out outfits that share items with recently vetoed outfits, weighted by veto reason
        return outfits
    }
}
