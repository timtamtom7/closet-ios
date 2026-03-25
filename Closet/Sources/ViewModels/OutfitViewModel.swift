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
            await fetchWeather()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func fetchWeather() async {
        do {
            currentWeather = try await WeatherService.shared.fetchWeather()
        } catch {
            currentWeather = WeatherService.WeatherInfo(condition: "Clear", temperature: 20, icon: "sun.max.fill")
        }
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
