import Foundation
import SwiftUI

enum Theme {
    static let warmBeige = Color(hex: "F5F0EB")
    static let charcoal = Color(hex: "2D2D2D")
    static let blush = Color(hex: "E8B4B8")
    static let sage = Color(hex: "9CAF88")
    static let surface = Color(hex: "FAFAFA")
    static let textPrimary = Color(hex: "1A1A1A")
    static let slate = Color(hex: "6E6E73")
    static let mist = Color(hex: "E8E8E6")
    static let sand = Color(hex: "D4C5B5")
    static let ivory = Color(hex: "FAFAF8")
}

enum ClothingCategory: String, CaseIterable, Identifiable, Codable {
    case tops = "Tops"
    case bottoms = "Bottoms"
    case shoes = "Shoes"
    case accessories = "Accessories"
    case outerwear = "Outerwear"
    case all = "All"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tops: return "tshirt"
        case .bottoms: return "figure.stand"
        case .shoes: return "shoe"
        case .accessories: return "sparkles"
        case .outerwear: return "cloud"
        case .all: return "square.grid.2x2"
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case mostWorn = "Most Worn"
    case leastWorn = "Least Worn"

    var id: String { rawValue }
}

enum EventType: String, CaseIterable, Identifiable, Codable {
    case casual = "Casual"
    case work = "Work"
    case date = "Date"
    case sport = "Sport"
    case formal = "Formal"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .casual: return "cup.and.saucer"
        case .work: return "briefcase"
        case .date: return "heart"
        case .sport: return "figure.run"
        case .formal: return "sparkles"
        }
    }
}

enum Mood: String, CaseIterable, Identifiable, Codable {
    case relaxed = "Relaxed"
    case confident = "Confident"
    case active = "Active"
    case playful = "Playful"
    case cozy = "Cozy"

    var emoji: String {
        switch self {
        case .relaxed: return "😌"
        case .confident: return "💪"
        case .active: return "🏃"
        case .playful: return "🎉"
        case .cozy: return "🛋️"
        }
    }

    var id: String { rawValue }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
