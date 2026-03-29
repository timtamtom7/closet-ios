import Foundation
import AppKit

@MainActor
class ClosetDataService: ObservableObject {
    static let shared = ClosetDataService()

    @Published var clothingItems: [ClothingItem] = []
    @Published var outfits: [Outfit] = []
    @Published var wornEntries: [WornEntry] = []
    @Published var styleProfile: StyleProfile = StyleProfile()

    private let fileManager = FileManager.default
    private var imagesDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("Closet", isDirectory: true)
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        return appSupport
    }

    init() {
        loadData()
    }

    func loadData() {
        clothingItems = loadClothingItems()
        outfits = loadOutfits()
        wornEntries = loadWornEntries()
        updateStyleProfile()
    }

    func saveClothingItem(_ item: ClothingItem) {
        if let index = clothingItems.firstIndex(where: { $0.id == item.id }) {
            clothingItems[index] = item
        } else {
            clothingItems.insert(item, at: 0)
        }
        persistClothingItems()
        updateStyleProfile()
    }

    func deleteClothingItem(_ item: ClothingItem) {
        clothingItems.removeAll { $0.id == item.id }
        persistClothingItems()
        updateStyleProfile()
    }

    func saveOutfit(_ outfit: Outfit) {
        if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfits[index] = outfit
        } else {
            outfits.insert(outfit, at: 0)
        }
        persistOutfits()
    }

    func deleteOutfit(_ outfit: Outfit) {
        outfits.removeAll { $0.id == outfit.id }
        persistOutfits()
    }

    func logWornEntry(_ entry: WornEntry) {
        wornEntries.insert(entry, at: 0)
        for itemId in entry.itemIds {
            if let index = clothingItems.firstIndex(where: { $0.id == itemId }) {
                clothingItems[index].wearCount += 1
            }
        }
        persistWornEntries()
        persistClothingItems()
        updateStyleProfile()
    }

    func saveImage(_ image: NSImage) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return nil
        }

        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)

        do {
            try jpegData.write(to: fileURL)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    func loadImage(named filename: String) -> NSImage? {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        return NSImage(contentsOf: fileURL)
    }

    func imageURL(for filename: String) -> URL {
        return imagesDirectory.appendingPathComponent(filename)
    }

    func deleteImage(named filename: String) {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }

    func resetAllStatistics() {
        for index in clothingItems.indices {
            clothingItems[index].wearCount = 0
        }
        wornEntries.removeAll()
        outfits.removeAll()
        persistClothingItems()
        persistOutfits()
        persistWornEntries()
        updateStyleProfile()
    }

    private func updateStyleProfile() {
        var profile = StyleProfile()
        profile.totalItems = clothingItems.count
        profile.totalOutfits = outfits.count

        let neutralColors = Set(["black", "white", "gray", "beige", "navy", "cream", "tan", "charcoal"])
        let neutralItems = clothingItems.filter { item in
            item.dominantColors.contains { color in
                neutralColors.contains(color.lowercased())
            }
        }
        profile.neutralColorRatio = clothingItems.isEmpty ? 0 : Double(neutralItems.count) / Double(clothingItems.count)

        let fittedItems = clothingItems.filter { $0.tags.contains("fitted") || $0.tags.contains("slim") }
        profile.fittedRatio = clothingItems.isEmpty ? 0 : Double(fittedItems.count) / Double(clothingItems.count)

        var tagCounts: [String: Int] = [:]
        for item in clothingItems {
            for tag in item.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        profile.topTags = tagCounts

        profile.mostWornItem = clothingItems.max(by: { $0.wearCount < $1.wearCount })
        profile.leastWornItem = clothingItems.min(by: { $0.wearCount < $1.wearCount })

        styleProfile = profile
    }

    // MARK: - Persistence

    private var clothingItemsURL: URL {
        imagesDirectory.appendingPathComponent("clothing_items.json")
    }

    private var outfitsURL: URL {
        imagesDirectory.appendingPathComponent("outfits.json")
    }

    private var wornEntriesURL: URL {
        imagesDirectory.appendingPathComponent("worn_entries.json")
    }

    private func loadClothingItems() -> [ClothingItem] {
        guard let data = try? Data(contentsOf: clothingItemsURL),
              let items = try? JSONDecoder().decode([ClothingItem].self, from: data) else {
            return sampleItems()
        }
        return items
    }

    private func loadOutfits() -> [Outfit] {
        guard let data = try? Data(contentsOf: outfitsURL),
              let items = try? JSONDecoder().decode([Outfit].self, from: data) else {
            return []
        }
        return items
    }

    private func loadWornEntries() -> [WornEntry] {
        guard let data = try? Data(contentsOf: wornEntriesURL),
              let items = try? JSONDecoder().decode([WornEntry].self, from: data) else {
            return []
        }
        return items
    }

    private func persistClothingItems() {
        guard let data = try? JSONEncoder().encode(clothingItems) else { return }
        try? data.write(to: clothingItemsURL)
    }

    private func persistOutfits() {
        guard let data = try? JSONEncoder().encode(outfits) else { return }
        try? data.write(to: outfitsURL)
    }

    private func persistWornEntries() {
        guard let data = try? JSONEncoder().encode(wornEntries) else { return }
        try? data.write(to: wornEntriesURL)
    }

    private func sampleItems() -> [ClothingItem] {
        return [
            ClothingItem(name: "White Cotton Tee", category: .tops, imagePath: "", dominantColors: ["white"], tags: ["casual", "summer"], wearCount: 12),
            ClothingItem(name: "Navy Chinos", category: .bottoms, imagePath: "", dominantColors: ["navy"], tags: ["smart-casual"], wearCount: 8),
            ClothingItem(name: "Brown Leather Shoes", category: .shoes, imagePath: "", dominantColors: ["brown"], tags: ["classic"], wearCount: 6),
            ClothingItem(name: "Gray Wool Sweater", category: .tops, imagePath: "", dominantColors: ["gray"], tags: ["winter", "cozy"], wearCount: 4),
            ClothingItem(name: "Blue Denim Jacket", category: .outerwear, imagePath: "", dominantColors: ["blue"], tags: ["casual", "layering"], wearCount: 3),
            ClothingItem(name: "Black Belt", category: .accessories, imagePath: "", dominantColors: ["black"], tags: ["essential"], wearCount: 15),
            ClothingItem(name: "Striped Oxford Shirt", category: .tops, imagePath: "", dominantColors: ["white", "blue"], tags: ["work", "classic"], wearCount: 7),
            ClothingItem(name: "Khaki Shorts", category: .bottoms, imagePath: "", dominantColors: ["beige"], tags: ["summer", "casual"], wearCount: 5)
        ]
    }
}
