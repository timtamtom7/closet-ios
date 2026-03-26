import Foundation
import SwiftUI

/// R13: Retention tracking for Closet
/// Day 1: first item
/// Day 3: first outfit
/// Day 7: first AI insight
@MainActor
final class RetentionService: ObservableObject {
    static let shared = RetentionService()

    private let installDateKey = "closet_install_date"
    private let day1ItemKey = "day1_item_completed"
    private let day3OutfitKey = "day3_outfit_completed"
    private let day7InsightKey = "day7_insight_completed"
    private let lastActiveKey = "closet_last_active"

    @Published var daysSinceInstall: Int = 0
    @Published var day1Completed: Bool = false
    @Published var day3Completed: Bool = false
    @Published var day7Completed: Bool = false

    var currentMilestone: RetentionMilestone {
        if day7Completed { return .completed }
        else if day3Completed { return .day7 }
        else if day1Completed { return .day3 }
        else { return .day1 }
    }

    enum RetentionMilestone: String {
        case day1 = "Add your first item"
        case day3 = "Create your first outfit"
        case day7 = "Get your first AI insight"
        case completed = "Wardrobe active!"
    }

    init() {
        loadRetentionData()
    }

    func loadRetentionData() {
        if let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        } else {
            UserDefaults.standard.set(Date(), forKey: installDateKey)
            daysSinceInstall = 0
        }

        day1Completed = UserDefaults.standard.bool(forKey: day1ItemKey)
        day3Completed = UserDefaults.standard.bool(forKey: day3OutfitKey)
        day7Completed = UserDefaults.standard.bool(forKey: day7InsightKey)
        UserDefaults.standard.set(Date(), forKey: lastActiveKey)
    }

    func recordItemAdded() {
        guard !day1Completed else { return }
        day1Completed = true
        UserDefaults.standard.set(true, forKey: day1ItemKey)
        trackMilestone(.day1)
    }

    func recordOutfitCreated() {
        guard !day3Completed else { return }
        day3Completed = true
        UserDefaults.standard.set(true, forKey: day3OutfitKey)
        trackMilestone(.day3)
    }

    func recordAIInsightViewed() {
        guard !day7Completed else { return }
        day7Completed = true
        UserDefaults.standard.set(true, forKey: day7InsightKey)
        trackMilestone(.day7)
    }

    private func trackMilestone(_ milestone: RetentionMilestone) {
        print("[Retention] Milestone completed: \(milestone.rawValue)")
    }
}
