import Foundation

struct Outfit: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var itemIds: [UUID]
    var eventType: EventType
    var mood: Mood
    var weather: String
    var temperature: Double?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        itemIds: [UUID],
        eventType: EventType,
        mood: Mood,
        weather: String,
        temperature: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.itemIds = itemIds
        self.eventType = eventType
        self.mood = mood
        self.weather = weather
        self.temperature = temperature
        self.createdAt = createdAt
    }

    var itemCount: Int {
        itemIds.count
    }
}
