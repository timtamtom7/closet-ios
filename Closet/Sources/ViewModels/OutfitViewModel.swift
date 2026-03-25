import Foundation
import SwiftUI

@Observable
final class OutfitViewModel {
    var outfits: [Outfit] = []
    var suggestedOutfits: [Outfit] = []
    var selectedEventType: EventType = .casual
    var selectedMood: Mood = .relaxed
    var currentWeather: WeatherService.WeatherInfo?
    var isLoading = false
    var errorMessage: String?
    var showOutfitDetail: Outfit?
    var currentSuggestionIndex = 0
    var trendInsights: [OutfitEvolutionService.TrendInsight] = []
    var layeringSuggestions: [String] = []
    var forecasts: [WeatherService.DayForecast] = []
    private var vetoes: [OutfitVeto] = []
    private var ratings: [OutfitRating] = []

    var hasMoreSuggestions: Bool {
        currentSuggestionIndex < suggestedOutfits.count - 1
    }

    var currentSuggestion: Outfit? {
        guard currentSuggestionIndex < suggestedOutfits.count else { return nil }
        return suggestedOutfits[currentSuggestionIndex]
    }

    @MainActor
    func loadOutfits() async {
        isLoading = true
        errorMessage = nil
        do {
            try await DatabaseService.shared.initialize()
            outfits = try await DatabaseService.shared.fetchAllOutfits()
            vetoes = try await DatabaseService.shared.fetchAllVetoes()
            ratings = try await DatabaseService.shared.fetchAllRatings()
            await fetchWeather()
            await fetchForecast()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func fetchWeather() async {
        do {
            currentWeather = try await WeatherService.shared.fetchWeather()
            await loadLayeringSuggestions()
        } catch {
            currentWeather = WeatherService.WeatherInfo(condition: "Clear", temperature: 20, icon: "sun.max.fill")
        }
    }

    @MainActor
    func fetchForecast() async {
        do {
            forecasts = try await WeatherService.shared.fetchForecast(days: 5)
        } catch {
            forecasts = []
        }
    }

    @MainActor
    func loadTrends(items: [ClothingItem]) async {
        trendInsights = await OutfitEvolutionService.shared.generateTrends(
            items: items,
            outfits: outfits,
            vetoes: vetoes,
            ratings: ratings
        )
    }

    @MainActor
    func loadLayeringSuggestions() async {
        guard let temp = currentWeather?.temperature else {
            layeringSuggestions = []
            return
        }
        layeringSuggestions = await OutfitEvolutionService.shared.generateLayeringSuggestions(
            items: [],
            temperature: temp
        )
    }

    @MainActor
    func generateOutfits(from items: [ClothingItem]) async {
        let weatherDesc = currentWeather?.condition ?? "Clear"
        let temp = currentWeather?.temperature

        suggestedOutfits = await OutfitGeneratorService.shared.generateOutfits(
            from: items,
            eventType: selectedEventType,
            mood: selectedMood,
            weather: weatherDesc,
            temperature: temp,
            count: 5
        )
        currentSuggestionIndex = 0
        await loadTrends(items: items)
    }

    @MainActor
    func saveOutfit(_ outfit: Outfit) async {
        do {
            try await DatabaseService.shared.insertOutfit(outfit)
            outfits.insert(outfit, at: 0)
            advanceSuggestion()
        } catch {
            errorMessage = "Failed to save outfit: \(error.localizedDescription)"
        }
    }

    @MainActor
    func vetoOutfit(_ outfit: Outfit, reason: VetoReason) async {
        do {
            let veto = OutfitVeto(outfitId: outfit.id, reason: reason)
            try await DatabaseService.shared.insertVeto(veto)
            vetoes.insert(veto, at: 0)
            advanceSuggestion()
        } catch {
            errorMessage = "Failed to veto outfit: \(error.localizedDescription)"
        }
    }

    @MainActor
    func rateOutfit(_ outfit: Outfit, score: Int) async {
        do {
            let rating = OutfitRating(outfitId: outfit.id, score: score)
            try await DatabaseService.shared.insertRating(rating)
            ratings.insert(rating, at: 0)
            advanceSuggestion()
        } catch {
            errorMessage = "Failed to rate outfit: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteOutfit(_ outfit: Outfit) async {
        do {
            try await DatabaseService.shared.deleteOutfit(id: outfit.id)
            outfits.removeAll { $0.id == outfit.id }
        } catch {
            errorMessage = "Failed to delete outfit: \(error.localizedDescription)"
        }
    }

    func advanceSuggestion() {
        if currentSuggestionIndex < suggestedOutfits.count - 1 {
            currentSuggestionIndex += 1
        }
    }

    func resetSuggestions() {
        suggestedOutfits = []
        currentSuggestionIndex = 0
    }
}
