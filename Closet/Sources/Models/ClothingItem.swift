import Foundation

struct ClothingItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
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

    var imageURL: URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsPath?.appendingPathComponent(imagePath)
    }
}
