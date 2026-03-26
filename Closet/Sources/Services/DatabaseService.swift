import Foundation
import SQLite

actor DatabaseService {
    static let shared = DatabaseService()

    private var db: Connection?
    private let dbPath: String

    // Tables
    private let clothingItems = Table("clothing_items")
    private let outfits = Table("outfits")
    private let outfitVetoes = Table("outfit_vetoes")
    private let outfitRatings = Table("outfit_ratings")

    // ClothingItem columns
    private let id = SQLite.Expression<String>("id")
    private let name = SQLite.Expression<String>("name")
    private let category = SQLite.Expression<String>("category")
    private let imagePath = SQLite.Expression<String>("image_path")
    private let dominantColors = SQLite.Expression<String>("dominant_colors")
    private let tags = SQLite.Expression<String>("tags")
    private let createdAt = SQLite.Expression<Double>("created_at")
    private let wearCount = SQLite.Expression<Int>("wear_count")

    // Outfit columns
    private let itemIds = SQLite.Expression<String>("item_ids")
    private let eventType = SQLite.Expression<String>("event_type")
    private let mood = SQLite.Expression<String>("mood")
    private let weather = SQLite.Expression<String>("weather")
    private let temperature = SQLite.Expression<Double?>("temperature")
    private let outfitName = SQLite.Expression<String>("outfit_name")

    // Veto columns
    private let outfitId = SQLite.Expression<String>("outfit_id")
    private let vetoReason = SQLite.Expression<String>("veto_reason")

    // Rating columns
    private let score = SQLite.Expression<Int>("score")

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        dbPath = documentsPath.appendingPathComponent("closet.sqlite3").path
    }

    func initialize() throws {
        db = try Connection(dbPath)
        try createTables()
    }

    private func createTables() throws {
        try db?.run(clothingItems.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(category)
            t.column(imagePath)
            t.column(dominantColors)
            t.column(tags)
            t.column(createdAt)
            t.column(wearCount, defaultValue: 0)
        })

        try db?.run(outfits.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(outfitName)
            t.column(itemIds)
            t.column(eventType)
            t.column(mood)
            t.column(weather)
            t.column(temperature)
            t.column(createdAt)
        })

        try db?.run(outfitVetoes.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(outfitId)
            t.column(vetoReason)
            t.column(createdAt)
        })

        try db?.run(outfitRatings.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(outfitId)
            t.column(score)
            t.column(createdAt)
        })
    }

    // MARK: - ClothingItem CRUD

    func insertClothingItem(_ item: ClothingItem) throws {
        let colorsJSON = try JSONEncoder().encode(item.dominantColors)
        let tagsJSON = try JSONEncoder().encode(item.tags)
        try db?.run(clothingItems.insert(
            id <- item.id.uuidString,
            name <- item.name,
            category <- item.category.rawValue,
            imagePath <- item.imagePath,
            dominantColors <- String(data: colorsJSON, encoding: .utf8) ?? "[]",
            tags <- String(data: tagsJSON, encoding: .utf8) ?? "[]",
            createdAt <- item.createdAt.timeIntervalSince1970,
            wearCount <- item.wearCount
        ))
    }

    func fetchAllClothingItems() throws -> [ClothingItem] {
        guard let db = db else { return [] }
        var items: [ClothingItem] = []
        for row in try db.prepare(clothingItems.order(createdAt.desc)) {
            let colors: [String] = (try? JSONDecoder().decode([String].self, from: Data(row[dominantColors].utf8))) ?? []
            let itemTags: [String] = (try? JSONDecoder().decode([String].self, from: Data(row[tags].utf8))) ?? []
            let cat = ClothingCategory(rawValue: row[category]) ?? .unknown
            let item = ClothingItem(
                id: UUID(uuidString: row[id]) ?? UUID(),
                name: row[name],
                category: cat,
                imagePath: row[imagePath],
                dominantColors: colors,
                tags: itemTags,
                createdAt: Date(timeIntervalSince1970: row[createdAt]),
                wearCount: row[wearCount]
            )
            items.append(item)
        }
        return items
    }

    func deleteClothingItem(id itemId: UUID) throws {
        let item = clothingItems.filter(id == itemId.uuidString)
        try db?.run(item.delete())
    }

    func incrementWearCount(id itemId: UUID) throws {
        let item = clothingItems.filter(id == itemId.uuidString)
        try db?.run(item.update(wearCount++))
    }

    // MARK: - Outfit CRUD

    func insertOutfit(_ outfit: Outfit) throws {
        let idsJSON = try JSONEncoder().encode(outfit.itemIds.map { $0.uuidString })
        try db?.run(outfits.insert(
            id <- outfit.id.uuidString,
            outfitName <- outfit.name,
            itemIds <- String(data: idsJSON, encoding: .utf8) ?? "[]",
            eventType <- outfit.eventType.rawValue,
            mood <- outfit.mood.rawValue,
            weather <- outfit.weather,
            temperature <- outfit.temperature,
            createdAt <- outfit.createdAt.timeIntervalSince1970
        ))

        for itemId in outfit.itemIds {
            try incrementWearCount(id: itemId)
        }
    }

    func fetchAllOutfits() throws -> [Outfit] {
        guard let db = db else { return [] }
        var results: [Outfit] = []
        for row in try db.prepare(outfits.order(createdAt.desc)) {
            let rawIds: [String] = (try? JSONDecoder().decode([String].self, from: Data(row[itemIds].utf8))) ?? []
            let uuidIds = rawIds.compactMap { UUID(uuidString: $0) }
            let evt = EventType(rawValue: row[eventType]) ?? .casual
            let m = Mood(rawValue: row[mood]) ?? .relaxed
            let o = Outfit(
                id: UUID(uuidString: row[id]) ?? UUID(),
                name: row[outfitName],
                itemIds: uuidIds,
                eventType: evt,
                mood: m,
                weather: row[weather],
                temperature: row[temperature],
                createdAt: Date(timeIntervalSince1970: row[createdAt])
            )
            results.append(o)
        }
        return results
    }

    func deleteOutfit(id outfitId: UUID) throws {
        let outfit = outfits.filter(id == outfitId.uuidString)
        try db?.run(outfit.delete())
    }

    // MARK: - OutfitVeto CRUD

    func insertVeto(_ veto: OutfitVeto) throws {
        try db?.run(outfitVetoes.insert(
            id <- veto.id.uuidString,
            outfitId <- veto.outfitId.uuidString,
            vetoReason <- veto.reason.rawValue,
            createdAt <- veto.createdAt.timeIntervalSince1970
        ))
    }

    func fetchAllVetoes() throws -> [OutfitVeto] {
        guard let db = db else { return [] }
        var results: [OutfitVeto] = []
        for row in try db.prepare(outfitVetoes.order(createdAt.desc)) {
            let reason = VetoReason(rawValue: row[vetoReason]) ?? .notMyStyle
            let veto = OutfitVeto(
                id: UUID(uuidString: row[id]) ?? UUID(),
                outfitId: UUID(uuidString: row[outfitId]) ?? UUID(),
                reason: reason,
                createdAt: Date(timeIntervalSince1970: row[createdAt])
            )
            results.append(veto)
        }
        return results
    }

    func vetoCount(forReason reason: VetoReason) throws -> Int {
        guard let db = db else { return 0 }
        return try db.scalar(outfitVetoes.filter(vetoReason == reason.rawValue).count)
    }

    // MARK: - OutfitRating CRUD

    func insertRating(_ rating: OutfitRating) throws {
        try db?.run(outfitRatings.insert(
            id <- rating.id.uuidString,
            outfitId <- rating.outfitId.uuidString,
            score <- rating.score,
            createdAt <- rating.createdAt.timeIntervalSince1970
        ))
    }

    func fetchAllRatings() throws -> [OutfitRating] {
        guard let db = db else { return [] }
        var results: [OutfitRating] = []
        for row in try db.prepare(outfitRatings.order(createdAt.desc)) {
            let rating = OutfitRating(
                id: UUID(uuidString: row[id]) ?? UUID(),
                outfitId: UUID(uuidString: row[outfitId]) ?? UUID(),
                score: row[score],
                createdAt: Date(timeIntervalSince1970: row[createdAt])
            )
            results.append(rating)
        }
        return results
    }

    func averageRating() throws -> Double {
        guard let db = db else { return 0 }
        let count = try db.scalar(outfitRatings.count)
        guard count > 0 else { return 0 }
        let total = try db.scalar(outfitRatings.select(score.sum)) ?? 0
        return Double(total) / Double(count)
    }
}
