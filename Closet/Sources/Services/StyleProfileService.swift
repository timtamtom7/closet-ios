import Foundation

actor StyleProfileService {
    static let shared = StyleProfileService()

    private init() {}

    func computeProfile(items: [ClothingItem], outfits: [Outfit]) -> StyleProfile {
        var profile = StyleProfile()
        profile.recompute(from: items, outfits: outfits)
        return profile
    }

    func generateInsight(profile: StyleProfile) -> String {
        let insights: [String] = []

        if profile.totalOutfits == 0 {
            return "Log your first outfit to start building your style profile."
        }

        var parts: [String] = []

        let neutralPercent = Int(profile.neutralColorRatio * 100)
        if neutralPercent > 70 {
            parts.append("You're a \(neutralPercent)% neutral dresser — timeless and versatile.")
        } else if neutralPercent > 40 {
            parts.append("Balanced between neutral tones and color pops (\(neutralPercent)% neutral).")
        } else {
            parts.append("Bold and expressive — only \(neutralPercent)% neutral tones.")
        }

        let fittedPercent = Int(profile.fittedRatio * 100)
        if fittedPercent > 65 {
            parts.append("You prefer \(fittedPercent)% fitted, tailored silhouettes.")
        } else if fittedPercent < 35 {
            parts.append("Relaxed and flowy fits dominate your wardrobe (\(fittedPercent)% fitted).")
        } else {
            parts.append("A mix of fitted and relaxed — you keep things interesting.")
        }

        if !profile.dominantCategories.isEmpty {
            let topCat = profile.dominantCategories.prefix(2).map { $0.rawValue }.joined(separator: " and ")
            parts.append("Your collection is strongest in \(topCat).")
        }

        return parts.joined(separator: " ")
    }
}
