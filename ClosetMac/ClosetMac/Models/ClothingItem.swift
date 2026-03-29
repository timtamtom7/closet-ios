import Foundation

struct ClothingItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: ClothingCategory
    var imagePath: String
    var dominantColors: [String]
    var tags: [String]
    var createdAt: Date
    var wearCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        imagePath: String,
        dominantColors: [String] = [],
        tags: [String] = [],
        createdAt: Date = Date(),
        wearCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.imagePath = imagePath
        self.dominantColors = dominantColors
        self.tags = tags
        self.createdAt = createdAt
        self.wearCount = wearCount
    }
}

struct Outfit: Identifiable, Codable {
    var id: UUID
    var name: String
    var itemIds: [UUID]
    var eventType: EventType
    var mood: Mood
    var weather: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        itemIds: [UUID],
        eventType: EventType = .casual,
        mood: Mood = .relaxed,
        weather: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.itemIds = itemIds
        self.eventType = eventType
        self.mood = mood
        self.weather = weather
        self.createdAt = createdAt
    }
}

struct WornEntry: Identifiable, Codable {
    var id: UUID
    var outfitId: UUID?
    var itemIds: [UUID]
    var date: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        outfitId: UUID? = nil,
        itemIds: [UUID],
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.outfitId = outfitId
        self.itemIds = itemIds
        self.date = date
        self.notes = notes
    }
}

struct StyleProfile {
    var neutralColorRatio: Double = 0.0
    var fittedRatio: Double = 0.0
    var topTags: [String: Int] = [:]
    var totalItems: Int = 0
    var totalOutfits: Int = 0
    var mostWornItem: ClothingItem?
    var leastWornItem: ClothingItem?
}

struct WishListItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: ClothingCategory
    var estimatedPrice: String?
    var storeName: String?
    var priority: WishListPriority
    var notes: String?
    var dominantColors: [String]
    var tags: [String]
    var createdAt: Date

    enum WishListPriority: String, CaseIterable, Codable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        estimatedPrice: String? = nil,
        storeName: String? = nil,
        priority: WishListPriority = .medium,
        notes: String? = nil,
        dominantColors: [String] = [],
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.estimatedPrice = estimatedPrice
        self.storeName = storeName
        self.priority = priority
        self.notes = notes
        self.dominantColors = dominantColors
        self.tags = tags
        self.createdAt = createdAt
    }
}
