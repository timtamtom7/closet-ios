import Foundation

actor MonthlyTrendService {
    static let shared = MonthlyTrendService()

    private init() {}

    struct MonthlyColorTrend: Identifiable {
        let id = UUID()
        let colorName: String
        let hex: String
        let thisMonthCount: Int
        let lastMonthCount: Int
        let thisMonthPercent: Double
        let lastMonthPercent: Double
        let changePercent: Double
        let isIncrease: Bool
        let isNew: Bool
        let isFading: Bool
    }

    struct MonthlyReport {
        let thisMonthItems: [ClothingItem]
        let lastMonthItems: [ClothingItem]
        let thisMonthOutfits: [Outfit]
        let lastMonthOutfits: [Outfit]
        let colorTrends: [MonthlyColorTrend]
        let dominantColorChange: String?
        let temperatureShift: String?
        let styleShifts: [String]
        let aiSuggestion: String
    }

    func generateMonthlyReport(items: [ClothingItem], outfits: [Outfit]) async -> MonthlyReport {
        let calendar = Calendar.current
        let now = Date()

        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? Date()
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? Date()
        let twoMonthsAgoStart = calendar.date(byAdding: .month, value: -2, to: thisMonthStart) ?? Date()

        let thisMonthItems = items.filter { $0.createdAt >= thisMonthStart }
        let lastMonthItems = items.filter { $0.createdAt >= lastMonthStart && $0.createdAt < thisMonthStart }

        let thisMonthOutfits = outfits.filter { $0.createdAt >= thisMonthStart }
        let lastMonthOutfits = outfits.filter { $0.createdAt >= lastMonthStart && $0.createdAt < thisMonthStart }

        let colorTrends = computeColorTrends(thisMonthItems: thisMonthItems, lastMonthItems: lastMonthItems)

        let dominantColorChange = findDominantColorChange(trends: colorTrends)
        let temperatureShift = computeTemperatureShift(thisOutfits: thisMonthOutfits, lastOutfits: lastMonthOutfits)
        let styleShifts = computeStyleShifts(thisOutfits: thisMonthOutfits, lastOutfits: lastMonthOutfits)
        let aiSuggestion = generateAISuggestion(trends: colorTrends, styleShifts: styleShifts, temperatureShift: temperatureShift)

        return MonthlyReport(
            thisMonthItems: thisMonthItems,
            lastMonthItems: lastMonthItems,
            thisMonthOutfits: thisMonthOutfits,
            lastMonthOutfits: lastMonthOutfits,
            colorTrends: colorTrends,
            dominantColorChange: dominantColorChange,
            temperatureShift: temperatureShift,
            styleShifts: styleShifts,
            aiSuggestion: aiSuggestion
        )
    }

    private func computeColorTrends(thisMonthItems: [ClothingItem], lastMonthItems: [ClothingItem]) -> [MonthlyColorTrend] {
        let thisMonthColors = thisMonthItems.flatMap { $0.dominantColors }
        let lastMonthColors = lastMonthItems.flatMap { $0.dominantColors }

        let thisCounts = countColors(thisMonthColors)
        let lastCounts = countColors(lastMonthColors)

        let allColorHexes = Set(thisCounts.keys).union(Set(lastCounts.keys))

        let totalThis = max(thisMonthColors.count, 1)
        let totalLast = max(lastMonthColors.count, 1)

        var trends: [MonthlyColorTrend] = []

        for hex in allColorHexes {
            let thisCount = thisCounts[hex] ?? 0
            let lastCount = lastCounts[hex] ?? 0

            let thisPercent = Double(thisCount) / Double(totalThis)
            let lastPercent = Double(lastCount) / Double(totalLast)

            let isNew = lastCount == 0 && thisCount > 0
            let isFading = lastCount > 0 && thisCount == 0
            let changePercent = lastCount > 0 ? ((Double(thisCount) - Double(lastCount)) / Double(lastCount)) * 100 : (thisCount > 0 ? 100 : 0)
            let isIncrease = thisCount > lastCount

            let colorName = colorName(from: hex)

            trends.append(MonthlyColorTrend(
                colorName: colorName,
                hex: hex,
                thisMonthCount: thisCount,
                lastMonthCount: lastCount,
                thisMonthPercent: thisPercent,
                lastMonthPercent: lastPercent,
                changePercent: abs(changePercent),
                isIncrease: isIncrease,
                isNew: isNew,
                isFading: isFading
            ))
        }

        return trends.sorted { $0.thisMonthPercent > $1.thisMonthPercent }
    }

    private func countColors(_ colors: [String]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for color in colors {
            counts[color, default: 0] += 1
        }
        return counts
    }

    private func colorName(from hex: String) -> String {
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
            "#1166AA": "Sky Blue",
            "#8B0000": "Dark Red",
            "#FFA500": "Orange",
            "#800080": "Purple"
        ]
        return names[hex.uppercased()] ?? hex.uppercased()
    }

    private func findDominantColorChange(trends: [MonthlyColorTrend]) -> String? {
        guard let top = trends.first else { return nil }
        guard top.thisMonthCount > 0 else { return nil }

        if top.isNew {
            return "You discovered \(top.colorName)! It's now \(Int(top.thisMonthPercent * 100))% of your wardrobe this month."
        }

        if top.changePercent > 20 && top.isIncrease {
            return "You've worn \(top.colorName) \(Int(top.changePercent))% more this month — it's your signature hue right now."
        }

        if top.changePercent > 30 && !top.isIncrease {
            return "\(top.colorName) is fading — down \(Int(top.changePercent))% from last month."
        }

        return nil
    }

    private func computeTemperatureShift(thisOutfits: [Outfit], lastOutfits: [Outfit]) -> String? {
        guard !thisOutfits.isEmpty || !lastOutfits.isEmpty else { return nil }

        let thisTemps = thisOutfits.compactMap { $0.temperature }
        let lastTemps = lastOutfits.compactMap { $0.temperature }
        let avgThisTemp = thisTemps.isEmpty ? 0.0 : thisTemps.reduce(0, +) / Double(thisTemps.count)
        let avgLastTemp = lastTemps.isEmpty ? 0.0 : lastTemps.reduce(0, +) / Double(lastTemps.count)

        let tempDiff = avgThisTemp - avgLastTemp
        if abs(tempDiff) > 3 {
            if tempDiff > 0 {
                return "Your outfit weights have been lighter — avg \(Int(avgThisTemp))° vs \(Int(avgLastTemp))° last month."
            } else {
                return "You've been reaching for warmer layers — avg \(Int(avgThisTemp))° vs \(Int(avgLastTemp))° last month."
            }
        }
        return nil
    }

    private func computeStyleShifts(thisOutfits: [Outfit], lastOutfits: [Outfit]) -> [String] {
        var shifts: [String] = []

        let thisEvents = Dictionary(grouping: thisOutfits, by: { $0.eventType })
        let lastEvents = Dictionary(grouping: lastOutfits, by: { $0.eventType })

        for event in EventType.allCases {
            let thisCount = thisEvents[event]?.count ?? 0
            let lastCount = lastEvents[event]?.count ?? 0

            if thisCount > 0 && thisCount > lastCount * 2 {
                shifts.append("More \(event.rawValue.lowercased()) looks this month")
            }
        }

        return shifts
    }

    private func generateAISuggestion(trends: [MonthlyColorTrend], styleShifts: [String], temperatureShift: String?) -> String {
        var suggestions: [String] = []

        guard let topTrend = trends.first(where: { $0.thisMonthCount > 0 && !$0.isNew }) else {
            return "Add more items to discover your monthly style patterns."
        }

        let warmTrend = trends.filter { isWarmColor($0.hex) && $0.isIncrease }
        let coolTrend = trends.filter { isCoolColor($0.hex) && $0.isIncrease }

        if warmTrend.count > coolTrend.count {
            suggestions.append("Your palette is warming up — consider adding cooler tones for balance.")
        } else if coolTrend.count > warmTrend.count {
            suggestions.append("Cool tones are dominating — warmer accents could add variety.")
        }

        if topTrend.thisMonthPercent > 0.5 && trends.filter({ $0.isIncrease }).count < 2 {
            suggestions.append("Your color focus is very narrow this month — try branching out!")
        }

        let newColors = trends.filter { $0.isNew }
        if newColors.count > 2 {
            suggestions.append("Great variety this month — \(newColors.count) new colors introduced!")
        }

        let fadingColors = trends.filter { $0.isFading }
        if !fadingColors.isEmpty {
            let names = fadingColors.prefix(2).map { $0.colorName }.joined(separator: " and ")
            suggestions.append("You seem to be moving away from \(names) — versatile to mix back in.")
        }

        if suggestions.isEmpty {
            suggestions.append("Your style is evolving steadily. Keep experimenting!")
        }

        return suggestions.joined(separator: " ")
    }

    private func isWarmColor(_ hex: String) -> Bool {
        let warmHexes: Set<String> = ["#C45C4A", "#8B4513", "#800020", "#FFA500", "#FFD700", "#FF69B4", "#B8A898", "#D4C5B5"]
        return warmHexes.contains(hex.uppercased())
    }

    private func isCoolColor(_ hex: String) -> Bool {
        let coolHexes: Set<String> = ["#000080", "#1166AA", "#006400", "#4169E1", "#000000", "#FFFFFF", "#808080", "#1C1C1E", "#6E6E73"]
        return coolHexes.contains(hex.uppercased())
    }
}
