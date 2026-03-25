import Foundation

actor TravelPackingService {
    static let shared = TravelPackingService()

    private init() {}

    struct PackingList: Identifiable {
        let id = UUID()
        let tripTitle: String
        let destination: String
        let startDate: Date
        let endDate: Date
        let weatherSummary: String
        let categories: [CategoryPacking]
        let tripNights: Int
        let createdAt: Date

        struct CategoryPacking: Identifiable {
            let id = UUID()
            let category: ClothingCategory
            let itemIds: [UUID]
            let packedCount: Int
            let totalCount: Int
            let notes: String
        }
    }

    struct TripContext {
        let destination: String
        let startDate: Date
        let endDate: Date
        let activities: [TripActivity]
        let weather: WeatherService.DayForecast?

        enum TripActivity: String, CaseIterable, Codable, Identifiable {
            case beach = "Beach"
            case business = "Business"
            case hiking = "Hiking"
            case sightseeing = "Sightseeing"
            case formal = "Formal Dinner"
            case casual = "Casual"
            case winter = "Winter Sports"

            var id: String { rawValue }

            var icon: String {
                switch self {
                case .beach: return "sun.and.horizon"
                case .business: return "briefcase"
                case .hiking: return "figure.hiking"
                case .sightseeing: return "camera.macro"
                case .formal: return "sparkles"
                case .casual: return "cup.and.saucer"
                case .winter: return "snowflake"
                }
            }
        }
    }

    func generatePackingList(
        for items: [ClothingItem],
        context: TripContext
    ) -> PackingList {
        let nights = Calendar.current.dateComponents([.day], from: context.startDate, to: context.endDate).day ?? 1
        let avgTemp = context.weather?.avgTemp ?? 20
        let needsOuterwear = avgTemp < 18
        let needsLightLayers = avgTemp >= 18 && avgTemp <= 24
        let isHot = avgTemp > 25

        let requiredCategories: [ClothingCategory] = [.tops, .bottoms, .shoes]

        var categoryPackings: [PackingList.CategoryPacking] = []

        for cat in requiredCategories {
            let catItems = items.filter { $0.category == cat }
            let (packed, notes) = packingLogic(
                category: cat,
                nights: nights,
                activities: context.activities,
                weather: context.weather,
                items: catItems
            )
            categoryPackings.append(PackingList.CategoryPacking(
                category: cat,
                itemIds: packed.map { $0.id },
                packedCount: 0,
                totalCount: packed.count,
                notes: notes
            ))
        }

        if needsOuterwear || context.activities.contains(.hiking) {
            let outerwearItems = items.filter { $0.category == .outerwear }
            let packed = Array(outerwearItems.prefix(2))
            let notes = needsOuterwear ? "Cold destination — bring 1-2 warm layers" : "Activity-appropriate outerwear"
            categoryPackings.append(PackingList.CategoryPacking(
                category: .outerwear,
                itemIds: packed.map { $0.id },
                packedCount: 0,
                totalCount: packed.count,
                notes: notes
            ))
        }

        if context.activities.contains(.beach) {
            let tops = items.filter { $0.category == .tops }
            let packed = Array(tops.prefix(2))
            categoryPackings.append(PackingList.CategoryPacking(
                category: .tops,
                itemIds: packed.map { $0.id },
                packedCount: 0,
                totalCount: packed.count,
                notes: "Beach cover-up / swim shirt"
            ))
        }

        if context.activities.contains(.formal) || context.activities.contains(.business) {
            let packed = items.filter { $0.category == .tops || $0.category == .bottoms || $0.category == .outerwear }
            let formalCount = min(2, packed.count)
            categoryPackings.append(PackingList.CategoryPacking(
                category: .dresses,
                itemIds: Array(packed.prefix(formalCount).map { $0.id }),
                packedCount: 0,
                totalCount: formalCount,
                notes: "Formal/business attire — pack wrinkle-resistant pieces"
            ))
        }

        if !items.filter({ $0.category == .accessories }).isEmpty {
            categoryPackings.append(PackingList.CategoryPacking(
                category: .accessories,
                itemIds: [],
                packedCount: 0,
                totalCount: 0,
                notes: "Essentials: watch, sunglasses, belt"
            ))
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateRange = "\(dateFormatter.string(from: context.startDate)) - \(dateFormatter.string(from: context.endDate))"

        let tempDesc: String
        if let temp = context.weather?.avgTemp {
            tempDesc = "\(Int(temp))°C average"
        } else {
            tempDesc = "Weather TBD"
        }

        return PackingList(
            tripTitle: "\(context.destination) Trip",
            destination: context.destination,
            startDate: context.startDate,
            endDate: context.endDate,
            weatherSummary: tempDesc,
            categories: categoryPackings,
            tripNights: max(nights, 1),
            createdAt: Date()
        )
    }

    private func packingLogic(
        category: ClothingCategory,
        nights: Int,
        activities: [TripContext.TripActivity],
        weather: WeatherService.DayForecast?,
        items: [ClothingItem]
    ) -> ([ClothingItem], String) {
        let count: Int
        let notes: String

        switch category {
        case .tops:
            if isBusinessTrip(activities) {
                count = min(nights + 2, items.count)
                notes = "\(nights) days + 2 backups. Mix-and-match-friendly tops."
            } else if nights <= 3 {
                count = min(nights + 1, items.count)
                notes = "\(nights)-night trip: \(count) tops recommended."
            } else {
                count = min(Int(Double(nights) * 0.7), items.count)
                notes = "One outfit per day, minus laundry day."
            }

        case .bottoms:
            if nights <= 3 {
                count = min(nights, items.count)
            } else {
                count = min(Int(Double(nights) / 2) + 1, items.count)
            }
            notes = count == nights ? "One per day" : "Pack \(count) — rewear with different tops."

        case .shoes:
            let shoeTypes: [ClothingCategory: String] = [
                .shoes: activities.contains(.hiking) ? "Walking shoes + hiking boots" : "Comfortable walking shoes"
            ]
            count = min(2, items.count)
            notes = shoeTypes[category] ?? "Comfortable pair"

        default:
            count = min(2, items.count)
            notes = "Based on your activities."
        }

        return (Array(items.prefix(count)), notes)
    }

    private func isBusinessTrip(_ activities: [TripContext.TripActivity]) -> Bool {
        activities.contains(.business) || activities.contains(.formal)
    }
}
