import Foundation
import EventKit

final class CalendarService: @unchecked Sendable {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private var _isAuthorized = false

    private init() {}

    struct CalendarEvent: Identifiable {
        let id: UUID
        let title: String
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        var suggestedEventType: EventType

        init(title: String, startDate: Date, endDate: Date, isAllDay: Bool, suggestedEventType: EventType) {
            self.id = UUID()
            self.title = title
            self.startDate = startDate
            self.endDate = endDate
            self.isAllDay = isAllDay
            self.suggestedEventType = suggestedEventType
        }

        init(from ekEvent: EKEvent) {
            self.id = UUID()
            self.title = ekEvent.title ?? "Untitled Event"
            self.startDate = ekEvent.startDate
            self.endDate = ekEvent.endDate
            self.isAllDay = ekEvent.isAllDay
            self.suggestedEventType = CalendarService.suggestEventType(from: ekEvent)
        }
    }

    static func suggestEventType(from event: EKEvent) -> EventType {
        let title = (event.title ?? "").lowercased()
        let notes = (event.notes ?? "").lowercased()
        let text = title + " " + notes

        if text.contains("dinner") || text.contains("date") || text.contains("anniversary") || text.contains("birthday") {
            return .date
        } else if text.contains("meeting") || text.contains("presentation") || text.contains("interview") || text.contains("conference") {
            return .work
        } else if text.contains("gym") || text.contains("workout") || text.contains("run") || text.contains("sport") {
            return .sport
        } else if text.contains("wedding") || text.contains("gala") || text.contains("formal") || text.contains("ceremony") {
            return .formal
        } else if text.contains("travel") || text.contains("flight") || text.contains("trip") {
            return .travel
        }
        return .casual
    }

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let status = EKEventStore.authorizationStatus(for: .event)
                switch status {
                case .fullAccess:
                    _isAuthorized = true
                    return true
                case .notDetermined:
                    let granted = try await eventStore.requestFullAccessToEvents()
                    _isAuthorized = granted
                    return granted
                default:
                    return false
                }
            } else {
                let status = EKEventStore.authorizationStatus(for: .event)
                switch status {
                case .authorized:
                    _isAuthorized = true
                    return true
                case .notDetermined:
                    let granted = try await eventStore.requestAccess(to: .event)
                    _isAuthorized = granted
                    return granted
                default:
                    return false
                }
            }
        } catch {
            return false
        }
    }

    func fetchTodayEvents() async -> [CalendarEvent] {
        if !_isAuthorized {
            let granted = await requestAccess()
            if !granted { return [] }
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)

        return events.map { CalendarEvent(from: $0) }
    }

    func fetchUpcomingEvents(days: Int = 7) async -> [CalendarEvent] {
        if !_isAuthorized {
            let granted = await requestAccess()
            if !granted { return [] }
        }

        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: days, to: startDate)!

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        return events.map { CalendarEvent(from: $0) }
    }
}
