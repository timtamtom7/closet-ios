import SwiftUI

struct WornLogView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var selectedMonth: Date = Date()
    @State private var showingLogEntry = false
    @State private var viewMode: ViewMode = .calendar

    enum ViewMode: String, CaseIterable {
        case calendar = "Calendar"
        case list = "List"
    }

    private var calendarEntries: [Date: [WornEntry]] {
        Dictionary(grouping: dataService.wornEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
    }

    private var weeklyEntries: [WornEntry] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dataService.wornEntries.filter { $0.date >= weekAgo }
    }

    private var monthlyStats: (wears: Int, outfits: Int, topItem: ClothingItem?) {
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedMonth)) ?? Date()
        let monthEntries = dataService.wornEntries.filter { $0.date >= monthStart }

        var itemCounts: [UUID: Int] = [:]
        for entry in monthEntries {
            for itemId in entry.itemIds {
                itemCounts[itemId, default: 0] += 1
            }
        }

        let topItemId = itemCounts.max(by: { $0.value < $1.value })?.key
        let topItem = topItemId.flatMap { id in dataService.clothingItems.first(where: { $0.id == id }) }

        return (monthEntries.count, Set(monthEntries.compactMap { $0.outfitId }).count, topItem)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Worn Log")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Picker("", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Stats Bar
            HStack(spacing: 16) {
                StatPill(title: "This Month", value: "\(monthlyStats.wears)", subtitle: "wears")
                StatPill(title: "Outfits", value: "\(monthlyStats.outfits)", subtitle: "logged")
                if let topItem = monthlyStats.topItem {
                    StatPill(title: "Top Pick", value: topItem.name, subtitle: "\(topItem.wearCount)x worn")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            if viewMode == .calendar {
                // Calendar View
                VStack(spacing: 12) {
                    // Month Navigation
                    HStack {
                        Button {
                            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? Date()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.charcoal)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text(monthYearString)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)

                        Spacer()

                        Button {
                            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? Date()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.charcoal)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    // Calendar Grid
                    CalendarGridView(
                        month: selectedMonth,
                        entries: calendarEntries,
                        clothingItems: dataService.clothingItems,
                        onSelectDate: { date in
                            // Show entries for that date
                        }
                    )
                }
                .padding(.vertical, 12)
            } else {
                // List View
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(weeklyEntries) { entry in
                            WornEntryRow(entry: entry, clothingItems: dataService.clothingItems)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }

            Spacer()

            // Log Today's Outfit Button
            Button {
                showingLogEntry = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Today's Outfit")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.blush)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showingLogEntry) {
            LogEntrySheet(dataService: dataService, isPresented: $showingLogEntry)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Theme.slate)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(subtitle)
                .font(.system(size: 8))
                .foregroundColor(Theme.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.surface)
        .cornerRadius(8)
    }
}

struct CalendarGridView: View {
    let month: Date
    let entries: [Date: [WornEntry]]
    let clothingItems: [ClothingItem]
    let onSelectDate: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    private var daysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: month),
              let monthStart = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start)?.start else {
            return []
        }

        var days: [Date?] = []
        let firstWeekday = Calendar.current.component(.weekday, from: monthInterval.start)

        // Add empty cells for days before the first day of month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Add days of month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    var body: some View {
        VStack(spacing: 4) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.slate)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            hasEntry: entries[Calendar.current.startOfDay(for: date)] != nil,
                            entryCount: entries[Calendar.current.startOfDay(for: date)]?.count ?? 0,
                            isToday: Calendar.current.isDateInToday(date)
                        )
                        .onTapGesture {
                            onSelectDate(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let hasEntry: Bool
    let entryCount: Int
    let isToday: Bool

    var body: some View {
        ZStack {
            if isToday {
                Circle()
                    .fill(Theme.blush.opacity(0.2))
            }

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? Theme.blush : Theme.textPrimary)

            if hasEntry {
                Circle()
                    .fill(Theme.sage)
                    .frame(width: 6, height: 6)
                    .offset(y: 10)
            }
        }
        .frame(height: 32)
    }
}

struct WornEntryRow: View {
    let entry: WornEntry
    let clothingItems: [ClothingItem]

    private var items: [ClothingItem] {
        clothingItems.filter { entry.itemIds.contains($0.id) }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(spacing: 2) {
                Text(dayString)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(monthString)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.slate)
            }
            .frame(width: 40)

            // Item thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -8) {
                    ForEach(items.prefix(5)) { item in
                        ZStack {
                            Circle()
                                .fill(Theme.surface)
                                .frame(width: 36, height: 36)

                            if let image = ClosetDataService.shared.loadImage(named: item.imagePath) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.slate)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(Theme.warmBeige, lineWidth: 2)
                        )
                    }

                    if items.count > 5 {
                        Circle()
                            .fill(Theme.mist)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text("+\(items.count - 5)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Theme.slate)
                            )
                    }
                }
            }

            Spacer()

            if let outfitId = entry.outfitId,
               let outfit = ClosetDataService.shared.outfits.first(where: { $0.id == outfitId }) {
                Text(outfit.eventType.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.slate)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.surface)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: entry.date)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: entry.date)
    }
}

struct LogEntrySheet: View {
    @ObservedObject var dataService: ClosetDataService
    @Binding var isPresented: Bool
    @State private var selectedItemIds: Set<UUID> = []
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Log Today's Outfit")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.slate)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)

            // Quick Select from Recent
            if !dataService.clothingItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select items worn today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.slate)

                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(dataService.clothingItems.prefix(12)) { item in
                                QuickSelectItem(
                                    item: item,
                                    isSelected: selectedItemIds.contains(item.id)
                                ) {
                                    if selectedItemIds.contains(item.id) {
                                        selectedItemIds.remove(item.id)
                                    } else {
                                        selectedItemIds.insert(item.id)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            // Save Button
            Button {
                let entry = WornEntry(
                    itemIds: Array(selectedItemIds),
                    notes: notes.isEmpty ? nil : notes
                )
                dataService.logWornEntry(entry)
                isPresented = false
            } label: {
                Text("Log Outfit")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedItemIds.isEmpty ? Theme.slate : Theme.blush)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(selectedItemIds.isEmpty)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 420)
        .background(Theme.warmBeige)
    }
}

struct QuickSelectItem: View {
    let item: ClothingItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 36, height: 36)

                    if let image = ClosetDataService.shared.loadImage(named: item.imagePath) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.slate)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    Text(item.category.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.slate)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.blush)
                }
            }
            .padding(8)
            .background(isSelected ? Theme.blush.opacity(0.1) : Theme.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
