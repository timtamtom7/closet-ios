import Foundation

actor ColorPaletteAnalysisService {
    static let shared = ColorPaletteAnalysisService()

    private init() {}

    struct PaletteAnalysis {
        let dominantColors: [ColorInfo]
        let neutralColors: [ColorInfo]
        let accentColors: [ColorInfo]
        let warmColors: [ColorInfo]
        let coolColors: [ColorInfo]
        let colorTemperature: TemperatureProfile
        let paletteHarmony: HarmonyType
        let suggestedPalettes: [String]
        let missingColors: [String]

        enum TemperatureProfile: String {
            case warm = "Warm"
            case cool = "Cool"
            case neutral = "Neutral"
            case mixed = "Mixed"
        }

        enum HarmonyType: String {
            case monochromatic = "Monochromatic"
            case analogous = "Analogous"
            case complementary = "Complementary"
            case neutral = "Neutral-Driven"
            case vibrant = "Vibrant"
        }
    }

    struct ColorInfo: Identifiable {
        let id = UUID()
        let hex: String
        let name: String
        let count: Int
        let percentage: Double
        let category: ColorCategory

        enum ColorCategory {
            case neutral
            case warm
            case cool
            case accent
        }
    }

    func analyzePalette(items: [ClothingItem]) -> PaletteAnalysis {
        let allColors = items.flatMap { $0.dominantColors }
        guard !allColors.isEmpty else {
            return emptyPalette
        }

        var colorCounts: [String: Int] = [:]
        for color in allColors {
            colorCounts[color, default: 0] += 1
        }

        let total = Double(allColors.count)

        let colorInfos: [ColorInfo] = colorCounts.map { hex, count in
            let name = colorName(from: hex)
            let category = categorizeColor(hex: hex)
            return ColorInfo(
                hex: hex,
                name: name,
                count: count,
                percentage: Double(count) / total,
                category: category
            )
        }.sorted { $0.count > $1.count }

        let neutralColors = colorInfos.filter { $0.category == .neutral }
        let warmColors = colorInfos.filter { $0.category == .warm }
        let coolColors = colorInfos.filter { $0.category == .cool }
        let accentColors = colorInfos.filter { $0.category == .accent }

        let temperature = computeTemperature(warm: warmColors.count, cool: coolColors.count, neutral: neutralColors.count)
        let harmony = computeHarmony(colors: colorInfos)
        let suggestedPalettes = generateSuggestions(colors: colorInfos, harmony: harmony)
        let missingColors = computeMissingColors(neutrals: neutralColors, accents: accentColors)

        return PaletteAnalysis(
            dominantColors: Array(colorInfos.prefix(5)),
            neutralColors: neutralColors,
            accentColors: accentColors,
            warmColors: warmColors,
            coolColors: coolColors,
            colorTemperature: temperature,
            paletteHarmony: harmony,
            suggestedPalettes: suggestedPalettes,
            missingColors: missingColors
        )
    }

    private func colorName(from hex: String) -> String {
        let hexNorm = hex.uppercased()
        let names: [String: String] = [
            "#000000": "Black",
            "#FFFFFF": "White",
            "#808080": "Gray",
            "#1C1C1E": "Charcoal",
            "#6E6E73": "Slate",
            "#B8A898": "Warm Taupe",
            "#D4C5B5": "Sand",
            "#C45C4A": "Terracotta",
            "#F5F5DC": "Cream",
            "#D3D3D3": "Light Gray",
            "#C0C0C0": "Silver",
            "#8B4513": "Brown",
            "#000080": "Navy",
            "#800020": "Burgundy",
            "#006400": "Forest Green",
            "#4169E1": "Royal Blue",
            "#FF69B4": "Pink",
            "#FFD700": "Gold",
            "#E8E8E6": "Mist",
            "#FAFAF8": "Ivory"
        ]
        return names[hexNorm] ?? hexNorm
    }

    private func categorizeColor(hex: String) -> ColorInfo.ColorCategory {
        let h = hex.uppercased()
        let neutralSet: Set<String> = ["#000000", "#FFFFFF", "#808080", "#1C1C1E", "#6E6E73", "#C0C0C0", "#D3D3D3", "#F5F5DC", "#E8E8E6", "#FAFAF8", "#B8A898", "#D4C5B5"]

        if neutralSet.contains(h) { return .neutral }

        guard let rgb = hexToRGB(h) else { return .accent }

        let warmRanges: [(ClosedRange<Int>, ClosedRange<Int>)] = [
            (0...30, 0...100),
            (0...30, 200...255)
        ]
        for (rRange, gRange) in warmRanges {
            if rRange.contains(rgb.r) && gRange.contains(rgb.g) && rgb.b < 150 {
                return .warm
            }
        }

        let coolRanges: [(ClosedRange<Int>, ClosedRange<Int>)] = [
            (0...100, 0...100),
            (100...200, 100...255)
        ]
        for (rRange, bRange) in coolRanges {
            if rRange.contains(rgb.r) && bRange.contains(rgb.b) && rgb.g < 150 {
                return .cool
            }
        }

        return .accent
    }

    private func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int)? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let value = UInt32(hexSanitized, radix: 16) else { return nil }

        return (
            r: Int((value >> 16) & 0xFF),
            g: Int((value >> 8) & 0xFF),
            b: Int(value & 0xFF)
        )
    }

    private func computeTemperature(warm: Int, cool: Int, neutral: Int) -> PaletteAnalysis.TemperatureProfile {
        if warm > cool + 3 { return .warm }
        if cool > warm + 3 { return .cool }
        if neutral > warm + cool { return .neutral }
        return .mixed
    }

    private func computeHarmony(colors: [ColorInfo]) -> PaletteAnalysis.HarmonyType {
        let total = colors.reduce(0) { $0 + $1.count }
        guard total > 0 else { return .neutral }

        let topPercent = Double(colors.prefix(3).reduce(0) { $0 + $1.count }) / Double(total)
        let neutralPercent = Double(colors.filter { $0.category == .neutral }.reduce(0) { $0 + $1.count }) / Double(total)

        if neutralPercent > 0.7 { return .neutral }
        if topPercent > 0.8 { return .monochromatic }
        if colors.allSatisfy({ $0.category == .warm || $0.category == .accent }) { return .analogous }
        if colors.contains(where: { $0.category == .warm }) && colors.contains(where: { $0.category == .cool }) { return .complementary }
        return .vibrant
    }

    private func generateSuggestions(colors: [ColorInfo], harmony: PaletteAnalysis.HarmonyType) -> [String] {
        var suggestions: [String] = []

        switch harmony {
        case .monochromatic:
            suggestions.append("Your wardrobe has a focused, cohesive palette. Try introducing one complementary accent color.")
        case .analogous:
            suggestions.append("Analogous colors create a harmonious, serene wardrobe. Add a pop of contrast for versatility.")
        case .complementary:
            suggestions.append("You balance warm and cool tones beautifully. Mix these opposites for dynamic outfit combinations.")
        case .neutral:
            suggestions.append("A neutral wardrobe is endlessly combinable. A colorful accessory could add new dimension.")
        case .vibrant:
            suggestions.append("Your wardrobe is full of personality. Lean into bold color-blocked outfits.")
        }

        let neutrals = colors.filter { $0.category == .neutral }
        if neutrals.count < 2 {
            suggestions.append("Consider adding more neutral basics — they help tie colorful pieces together.")
        }

        return suggestions
    }

    private func computeMissingColors(neutrals: [ColorInfo], accents: [ColorInfo]) -> [String] {
        var missing: [String] = []
        let hasBlack = neutrals.contains { $0.hex.uppercased() == "#000000" || $0.hex.uppercased() == "#1C1C1E" }
        let hasWhite = neutrals.contains { $0.hex.uppercased() == "#FFFFFF" || $0.hex.uppercased() == "#FAFAF8" }
        let hasGray = neutrals.contains { $0.hex.uppercased().contains("808080") || $0.hex.uppercased().contains("C0C0C0") }

        if !hasBlack { missing.append("Black") }
        if !hasWhite { missing.append("White") }
        if !hasGray { missing.append("Gray") }
        if accents.count < 2 { missing.append("A bold accent color") }

        return missing
    }

    private var emptyPalette: PaletteAnalysis {
        PaletteAnalysis(
            dominantColors: [],
            neutralColors: [],
            accentColors: [],
            warmColors: [],
            coolColors: [],
            colorTemperature: .neutral,
            paletteHarmony: .neutral,
            suggestedPalettes: ["Add clothing items to discover your color palette."],
            missingColors: []
        )
    }
}
