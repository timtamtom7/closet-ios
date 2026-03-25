import Foundation

enum ClothingCategory: String, CaseIterable, Codable, Identifiable {
    case tops = "Tops"
    case bottoms = "Bottoms"
    case shoes = "Shoes"
    case accessories = "Accessories"
    case outerwear = "Outerwear"
    case dresses = "Dresses"
    case unknown = "Unknown"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tops: return "tshirt"
        case .bottoms: return "figure.stand"
        case .shoes: return "shoe"
        case .accessories: return "watch"
        case .outerwear: return "cloud.sun"
        case .dresses: return "figure.dress.line.vertical.figure"
        case .unknown: return "questionmark.circle"
        }
    }
}

enum EventType: String, CaseIterable, Codable, Identifiable {
    case casual = "Casual"
    case work = "Work"
    case date = "Date Night"
    case sport = "Sport"
    case formal = "Formal"
    case travel = "Travel"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .casual: return "cup.and.saucer"
        case .work: return "briefcase"
        case .date: return "heart"
        case .sport: return "figure.run"
        case .formal: return "sparkles"
        case .travel: return "airplane"
        }
    }

    var formality: Int {
        switch self {
        case .casual: return 1
        case .travel: return 2
        case .work: return 3
        case .date: return 4
        case .sport: return 2
        case .formal: return 5
        }
    }
}

enum Mood: String, CaseIterable, Codable, Identifiable {
    case relaxed = "😌 Relaxed"
    case warm = "🏽 Warm"
    case powerful = "💪 Powerful"
    case playful = "🎉 Playful"
    case cozy = "🛋️ Cozy"
    case bold = "🔥 Bold"

    var id: String { rawValue }

    var emoji: String {
        rawValue.components(separatedBy: " ").first ?? "😌"
    }

    var acceptsColor: Bool {
        switch self {
        case .playful, .bold: return true
        default: return false
        }
    }
}
