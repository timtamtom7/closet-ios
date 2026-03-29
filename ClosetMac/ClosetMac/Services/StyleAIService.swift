import Foundation
import NaturalLanguage
import Observation

// MARK: - Weather Model

struct Weather {
    let temperatureCelsius: Double
    let condition: String
    let location: String

    var temperatureFahrenheit: Double {
        temperatureCelsius * 9 / 5 + 32
    }

    var isCold: Bool { temperatureCelsius < 10 }
    var isHot: Bool { temperatureCelsius > 25 }
    var isRainy: Bool {
        let rainy = condition.lowercased()
        return rainy.contains("rain") || rainy.contains("drizzle") || rainy.contains("shower")
    }

    var description: String {
        "\(Int(temperatureFahrenheit))°F, \(condition)"
    }

    var layeringAdvice: String? {
        if isCold {
            if temperatureCelsius < 5 {
                return "Bundle up — it's \(Int(temperatureFahrenheit))°F. Consider layers, a warm jacket, and accessories like a scarf."
            } else {
                return "Chilly today (\(Int(temperatureFahrenheit))°F). A layer or light jacket should do the trick."
            }
        } else if isHot {
            if temperatureCelsius > 30 {
                return "It's hot — \(Int(temperatureFahrenheit))°F. Go light and breathable. Avoid heavy layers."
            } else {
                return "Warm outside (\(Int(temperatureFahrenheit))°F). Light layers work, but no heavy outerwear needed."
            }
        }
        return nil
    }
}

// MARK: - Outfit Suggestion

struct OutfitSuggestion: Identifiable {
    let id = UUID()
    let items: [ClothingItem]
    let reason: String
    let occasion: String
    let score: Int

    var topItem: ClothingItem? { items.first }
}

// MARK: - Calendar Event

struct CalendarEvent {
    let title: String
    let startDate: Date
    let keywords: [String]

    var inferredOccasion: EventType {
        let text = (title + " " + keywords.joined(separator: " ")).lowercased()
        if text.contains("meeting") || text.contains("interview") || text.contains("presentation") || text.contains("conference") {
            return .work
        } else if text.contains("dinner") || text.contains("date") || text.contains("birthday") || text.contains("celebration") {
            return .date
        } else if text.contains("gym") || text.contains("workout") || text.contains("run") || text.contains("yoga") || text.contains("sport") {
            return .sport
        } else if text.contains("wedding") || text.contains("formal") || text.contains("gala") || text.contains("ceremony") {
            return .formal
        }
        return .casual
    }
}

// MARK: - Style AI Service

@MainActor
@Observable
final class StyleAIService {
    static let shared = StyleAIService()

    private var dataService: ClosetDataService { ClosetDataService.shared }

    // MARK: - Public API

    /// "What should I wear today?"
    func suggestOutfit(for date: Date = Date(), weather: Weather? = nil) -> OutfitSuggestion {
        let events = readTodayCalendarEvents()
        let occasion = inferOccasion(from: events)
        let weatherCondition = weather ?? fetchWeather()

        // Build candidate outfits
        let candidates = generateOutfitCandidates(occasion: occasion, weather: weatherCondition, date: date)

        guard let best = candidates.first else {
            return OutfitSuggestion(
                items: [],
                reason: "No items in your wardrobe yet. Add some pieces to get outfit suggestions!",
                occasion: occasion.rawValue,
                score: 0
            )
        }

        return best
    }

    /// Get multiple outfit suggestions
    func suggestOutfits(count: Int = 5, for date: Date = Date(), weather: Weather? = nil) -> [OutfitSuggestion] {
        let events = readTodayCalendarEvents()
        let occasion = inferOccasion(from: events)
        let weatherCondition = weather ?? fetchWeather()

        var candidates = generateOutfitCandidates(occasion: occasion, weather: weatherCondition, date: date, limit: count)

        // Diversity pass: avoid too many suggestions with the same top item
        var uniqueSuggestions: [OutfitSuggestion] = []
        var usedTopItems: Set<UUID> = []

        for candidate in candidates {
            if uniqueSuggestions.count >= count { break }
            if let top = candidate.topItem, usedTopItems.contains(top.id), uniqueSuggestions.count < candidates.count / 2 {
                continue // skip if we already have too many of the same top
            }
            if let top = candidate.topItem {
                usedTopItems.insert(top.id)
            }
            uniqueSuggestions.append(candidate)
        }

        return uniqueSuggestions
    }

    // MARK: - Private: Outfit Generation

    private func generateOutfitCandidates(occasion: EventType, weather: Weather?, date: Date, limit: Int = 5) -> [OutfitSuggestion] {
        let items = dataService.clothingItems
        guard !items.isEmpty else { return [] }

        let tops = items.filter { $0.category == .tops }
        let bottoms = items.filter { $0.category == .bottoms }
        let shoes = items.filter { $0.category == .shoes }
        let outerwear = items.filter { $0.category == .outerwear }

        var scoredCombinations: [(items: [ClothingItem], score: Int, reason: String)] = []

        // Score each top+bottom+shoes combination
        for top in tops.shuffled().prefix(12) {
            for bottom in bottoms.shuffled().prefix(8) {
                for shoe in shoes.shuffled().prefix(6) {
                    var score = 0
                    var reasons: [String] = []

                    // Not worn recently (+10)
                    let daysSinceTop = daysSinceWorn(top.id)
                    let daysSinceBottom = daysSinceWorn(bottom.id)
                    let daysSinceShoe = daysSinceWorn(shoe.id)

                    if daysSinceTop >= 7 {
                        score += 10
                        if daysSinceTop >= 14 { score += 5 }
                    } else if daysSinceTop <= 2 {
                        score -= 8 // worn recently, penalize
                        reasons.append("Worn \(daysSinceTop == 0 ? "today" : "\(daysSinceTop)d ago")")
                    }

                    if daysSinceBottom >= 7 { score += 8 }
                    if daysSinceShoe >= 7 { score += 6 }

                    // Occasion match (+15)
                    if matchesOccasion(top, occasion: occasion) { score += 15; reasons.append("Perfect for \(occasion.rawValue)") }
                    if matchesOccasion(bottom, occasion: occasion) { score += 10 }

                    // Weather appropriateness (+10)
                    if let w = weather {
                        if w.isCold {
                            if top.tags.contains(where: { ["warm", "wool", "sweater", "fleece", "layering"].contains($0.lowercased()) }) { score += 10 }
                            if !outerwear.isEmpty { score += 5 } // can suggest outerwear
                        } else if w.isHot {
                            if top.tags.contains(where: { ["lightweight", "linen", "cotton", "summer", "breathable"].contains($0.lowercased()) }) { score += 10 }
                        }
                        if w.isRainy {
                            if shoe.tags.contains(where: { ["waterproof", "leather", "rain"].contains($0.lowercased()) }) { score += 10 }
                        }
                    }

                    // Neutral palette (matches most style profiles)
                    if dataService.styleProfile.neutralColorRatio > 0.6 {
                        let neutralColors = Set(["black", "white", "gray", "beige", "navy", "cream", "tan", "charcoal"])
                        let isNeutral = top.dominantColors.allSatisfy { neutralColors.contains($0.lowercased()) }
                        if isNeutral { score += 5 }
                    }

                    // Fitted preference
                    if dataService.styleProfile.fittedRatio > 0.5 {
                        if top.tags.contains("fitted") || top.tags.contains("slim") { score += 5 }
                    }

                    let finalReason: String
                    if !reasons.isEmpty {
                        finalReason = reasons.joined(separator: ". ") + "."
                    } else {
                        finalReason = occasionReason(occasion, weather: weather)
                    }

                    var outfitItems = [top, bottom, shoe]
                    if weather?.isCold == true, let outer = outerwear.shuffled().first {
                        outfitItems.insert(outer, at: 0)
                    }

                    scoredCombinations.append((items: outfitItems, score: score, reason: finalReason))
                }
            }
        }

        // Sort by score descending
        scoredCombinations.sort { $0.score > $1.score }

        return scoredCombinations.prefix(limit).map { combo in
            OutfitSuggestion(
                items: combo.items,
                reason: combo.reason,
                occasion: occasion.rawValue,
                score: combo.score
            )
        }
    }

    private func matchesOccasion(_ item: ClothingItem, occasion: EventType) -> Bool {
        let tags = Set(item.tags.map { $0.lowercased() })
        switch occasion {
        case .work:
            return tags.contains("work") || tags.contains("smart-casual") || tags.contains("office") || tags.contains("classic") || tags.contains("professional")
        case .formal:
            return tags.contains("formal") || tags.contains("dressy") || tags.contains("elegant")
        case .date:
            return tags.contains("date") || tags.contains("dressy") || tags.contains("smart")
        case .sport:
            return tags.contains("sport") || tags.contains("athletic") || tags.contains("gym") || tags.contains("active")
        case .casual:
            return tags.contains("casual") || tags.contains("relaxed") || tags.contains("everyday")
        }
    }

    private func occasionReason(_ occasion: EventType, weather: Weather?) -> String {
        var parts: [String] = []
        switch occasion {
        case .work: parts.append("You have work today — smart casual works well")
        case .formal: parts.append("Looking for something a bit more formal")
        case .date: parts.append("Special occasion — dress to impress")
        case .sport: parts.append("Active day ahead — go comfortable")
        case .casual: parts.append("Casual day — keep it relaxed")
        }
        if let w = weather, let advice = w.layeringAdvice {
            parts.append(advice)
        }
        return parts.joined(separator: ". ")
    }

    // MARK: - Days Since Worn

    private func daysSinceWorn(_ itemId: UUID) -> Int {
        let entries = dataService.wornEntries
        guard let lastEntry = entries.first(where: { $0.itemIds.contains(itemId) }) else {
            return 999 // never worn
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastEntry.date, to: Date())
        return components.day ?? 999
    }

    // MARK: - Calendar

    private func readTodayCalendarEvents() -> [CalendarEvent] {
        // Note: Full EventKit integration requires macOS entitlements and user permission.
        // Placeholder returns empty unless explicitly granted. The algorithm still works
        // without calendar events — it defaults to casual suggestions.
        return []
    }

    private func inferOccasion(from events: [CalendarEvent]) -> EventType {
        guard let mostImportant = events.first else { return .casual }
        return mostImportant.inferredOccasion
    }

    // MARK: - Weather

    func fetchWeather(location: String = "Vancouver") -> Weather? {
        guard let url = URL(string: "https://wttr.in/\(location)?format=j1") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let semaphore = DispatchSemaphore(value: 0)
        var result: Weather?

        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { semaphore.signal() }
            guard let data = data, error == nil else { return }

            struct WttrResponse: Decodable {
                let current_condition: [WttrCondition]
            }
            struct WttrCondition: Decodable {
                let temp_C: [String]
                let weatherDesc: [WttrDesc]
            }
            struct WttrDesc: Decodable {
                let value: String
            }

            guard let response = try? JSONDecoder().decode(WttrResponse.self, from: data),
                  let condition = response.current_condition.first,
                  let tempStr = condition.temp_C.first,
                  let temp = Double(tempStr),
                  let desc = condition.weatherDesc.first else { return }

            result = Weather(temperatureCelsius: temp, condition: desc.value, location: location)
        }.resume()

        _ = semaphore.wait(timeout: .now() + 6)
        return result
    }

    // MARK: - Natural Language: Season / Trend Analysis

    func analyzeWardrobeTaste() -> String {
        let items = dataService.clothingItems
        let profile = dataService.styleProfile

        var insights: [String] = []

        // Color analysis
        let neutralColors = Set(["black", "white", "gray", "beige", "navy", "cream", "tan", "charcoal"])
        let neutralItems = items.filter { item in
            item.dominantColors.contains { neutralColors.contains($0.lowercased()) }
        }
        let neutralPct = items.isEmpty ? 0 : Int(Double(neutralItems.count) / Double(items.count) * 100)

        if neutralPct >= 70 {
            insights.append("You lean heavily into neutral tones — \(neutralPct)% of your wardrobe is black, white, gray, or beige.")
        } else if neutralPct >= 40 {
            insights.append("A balanced mix — \(neutralPct)% neutral tones with room for color.")
        } else {
            insights.append("You're not afraid of color — only \(neutralPct)% of your wardrobe is strictly neutral.")
        }

        // Seasonal
        let winterTags = Set(["winter", "wool", "warm", "layering", "cozy"])
        let summerTags = Set(["summer", "lightweight", "linen", "cotton", "breathable", "summer"])
        let winterItems = items.filter { $0.tags.contains { winterTags.contains($0.lowercased()) } }
        let summerItems = items.filter { $0.tags.contains { summerTags.contains($0.lowercased()) } }

        let month = Calendar.current.component(.month, from: Date())
        if month >= 11 || month <= 3 {
            if !winterItems.isEmpty {
                insights.append("Winter-ready: \(winterItems.count) warm pieces waiting to be worn.")
            }
        } else {
            if !summerItems.isEmpty {
                insights.append("Summer-forward: \(summerItems.count) light pieces for warmer days.")
            }
        }

        // Top tags
        let sortedTags = profile.topTags.sorted { $0.value > $1.value }
        if let topTag = sortedTags.first {
            insights.append("Your signature style keyword: \"\(topTag.key)\" (appears \(topTag.value)× across your wardrobe).")
        }

        // Most/least worn
        if let most = profile.mostWornItem, most.wearCount > 0 {
            insights.append("Your most-worn piece: \(most.name) (\(most.wearCount)× this season).")
        }
        if let least = profile.leastWornItem, least.wearCount == 0 {
            insights.append("That \(least.name) hasn't been worn yet — time for a comeback?")
        }

        return insights.joined(separator: "\n")
    }
}
