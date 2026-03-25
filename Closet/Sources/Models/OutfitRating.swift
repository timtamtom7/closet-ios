import Foundation

struct OutfitRating: Identifiable, Codable, Equatable {
    let id: UUID
    let outfitId: UUID
    let score: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        outfitId: UUID,
        score: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.outfitId = outfitId
        self.score = max(1, min(5, score))
        self.createdAt = createdAt
    }
}
