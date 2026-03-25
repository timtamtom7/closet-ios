import Foundation

@Observable
final class TravelPackingViewModel {
    var recentPackingLists: [TravelPackingService.PackingList] = []
    var currentPackingList: TravelPackingService.PackingList?
    var isLoading = false

    private let saveKey = "savedPackingLists"

    func loadSavedLists() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let lists = try? JSONDecoder().decode([SavedList].self, from: data) {
            recentPackingLists = lists.map { $0.toPackingList() }
        }
    }

    func saveLists() {
        let savedLists = recentPackingLists.prefix(10).map { SavedList(from: $0) }
        if let data = try? JSONEncoder().encode(savedLists) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    @MainActor
    func generatePackingList(
        for items: [ClothingItem],
        context: TravelPackingService.TripContext
    ) async -> TravelPackingService.PackingList {
        isLoading = true
        let list = await TravelPackingService.shared.generatePackingList(for: items, context: context)
        isLoading = false
        return list
    }
}

private struct SavedList: Codable {
    let id: UUID
    let tripTitle: String
    let destination: String
    let startDate: Date
    let endDate: Date
    let weatherSummary: String
    let tripNights: Int
    let createdAt: Date

    init(from list: TravelPackingService.PackingList) {
        self.id = list.id
        self.tripTitle = list.tripTitle
        self.destination = list.destination
        self.startDate = list.startDate
        self.endDate = list.endDate
        self.weatherSummary = list.weatherSummary
        self.tripNights = list.tripNights
        self.createdAt = list.createdAt
    }

    func toPackingList() -> TravelPackingService.PackingList {
        TravelPackingService.PackingList(
            tripTitle: tripTitle,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            weatherSummary: weatherSummary,
            categories: [],
            tripNights: tripNights,
            createdAt: createdAt
        )
    }
}
