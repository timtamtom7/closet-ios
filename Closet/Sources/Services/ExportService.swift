import Foundation

actor ExportService {
    static let shared = ExportService()

    private init() {}

    enum ExportFormat {
        case json
        case csv
        case pdf
    }

    struct WardrobeExport: Codable {
        let exportDate: Date
        let totalItems: Int
        let totalOutfits: Int
        let items: [ClothingItemExport]
        let outfits: [OutfitExport]
        let colorPalette: [String: Int]
        let styleProfile: StyleProfileExport?
    }

    struct ClothingItemExport: Codable {
        let id: String
        let name: String
        let category: String
        let colors: [String]
        let tags: [String]
        let wearCount: Int
        let createdAt: Date
    }

    struct OutfitExport: Codable {
        let id: String
        let name: String
        let itemIds: [String]
        let eventType: String
        let mood: String
        let weather: String?
        let temperature: Double?
        let createdAt: Date
        let rating: Int?
    }

    struct StyleProfileExport: Codable {
        let neutralColorRatio: Double
        let fittedRatio: Double
        let topTags: [String: Int]
        let dominantCategories: [String]
        let colorStory: String
        let styleSummary: String
    }

    func exportWardrobe(
        items: [ClothingItem],
        outfits: [Outfit],
        styleProfile: StyleProfile?,
        format: ExportFormat
    ) async throws -> Data {
        let wardrobeExport = buildExport(items: items, outfits: outfits, styleProfile: styleProfile)

        switch format {
        case .json:
            return try encodeJSON(wardrobeExport)
        case .csv:
            return encodeCSV(items: items, outfits: outfits)
        case .pdf:
            return try encodeJSON(wardrobeExport)
        }
    }

    private func buildExport(items: [ClothingItem], outfits: [Outfit], styleProfile: StyleProfile?) -> WardrobeExport {
        let itemExports = items.map { item in
            ClothingItemExport(
                id: item.id.uuidString,
                name: item.name,
                category: item.category.rawValue,
                colors: item.dominantColors,
                tags: item.tags,
                wearCount: item.wearCount,
                createdAt: item.createdAt
            )
        }

        let outfitExports = outfits.map { outfit in
            OutfitExport(
                id: outfit.id.uuidString,
                name: outfit.name,
                itemIds: outfit.itemIds.map { $0.uuidString },
                eventType: outfit.eventType.rawValue,
                mood: outfit.mood.rawValue,
                weather: outfit.weather,
                temperature: outfit.temperature,
                createdAt: outfit.createdAt,
                rating: nil
            )
        }

        var colorCounts: [String: Int] = [:]
        for item in items {
            for color in item.dominantColors {
                colorCounts[color, default: 0] += 1
            }
        }

        let profileExport: StyleProfileExport?
        if let profile = styleProfile {
            profileExport = StyleProfileExport(
                neutralColorRatio: profile.neutralColorRatio,
                fittedRatio: profile.fittedRatio,
                topTags: profile.topTags,
                dominantCategories: profile.dominantCategories.map { $0.rawValue },
                colorStory: profile.colorStory,
                styleSummary: profile.styleSummary
            )
        } else {
            profileExport = nil
        }

        return WardrobeExport(
            exportDate: Date(),
            totalItems: items.count,
            totalOutfits: outfits.count,
            items: itemExports,
            outfits: outfitExports,
            colorPalette: colorCounts,
            styleProfile: profileExport
        )
    }

    private func encodeJSON(_ export: WardrobeExport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    private func encodeCSV(items: [ClothingItem], outfits: [Outfit]) -> Data {
        var csv = "Type,ID,Name,Category,Colors,Tags,Created\n"

        for item in items {
            let row = [
                "Item",
                item.id.uuidString,
                escapeCSV(item.name),
                item.category.rawValue,
                item.dominantColors.joined(separator: "; "),
                item.tags.joined(separator: "; "),
                item.createdAt.formatted(date: .numeric, time: .omitted)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        for outfit in outfits {
            let row = [
                "Outfit",
                outfit.id.uuidString,
                escapeCSV(outfit.name),
                outfit.eventType.rawValue,
                outfit.mood.rawValue,
                outfit.itemIds.map { $0.uuidString }.joined(separator: ";"),
                outfit.createdAt.formatted(date: .numeric, time: .omitted)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        return csv.data(using: .utf8) ?? Data()
    }

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }

    func getExportFileName(format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        let ext: String
        switch format {
        case .json: ext = "json"
        case .csv: ext = "csv"
        case .pdf: ext = "json"
        }

        return "Closet_Export_\(dateStr).\(ext)"
    }
}
