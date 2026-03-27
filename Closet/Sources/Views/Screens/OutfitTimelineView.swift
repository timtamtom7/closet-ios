import SwiftUI

struct OutfitTimelineView: View {
    let outfits: [Outfit]
    let items: [ClothingItem]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMonth: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if groupedOutfits.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedOutfits, id: \.month) { group in
                            MonthGroupView(
                                group: group,
                                items: items,
                                isExpanded: selectedMonth == group.month,
                                onToggle: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedMonth == group.month {
                                            selectedMonth = nil
                                        } else {
                                            selectedMonth = group.month
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Outfit Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
    }

    private var groupedOutfits: [MonthGroup] {
        let calendar = Calendar.current
        var groups: [Date: [Outfit]] = [:]

        for outfit in outfits.sorted(by: { $0.createdAt > $1.createdAt }) {
            let components = calendar.dateComponents([.year, .month], from: outfit.createdAt)
            if let monthStart = calendar.date(from: components) {
                groups[monthStart, default: []].append(outfit)
            }
        }

        return groups.map { month, monthOutfits in
            MonthGroup(month: month, outfits: monthOutfits)
        }.sorted { $0.month > $1.month }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#E8E8E6"))

            Text("No outfit history yet")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Start logging outfits to build your style timeline")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

struct MonthGroup: Identifiable {
    let id = UUID()
    let month: Date
    var outfits: [Outfit]

    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    var outfitCount: Int { outfits.count }
}

struct MonthGroupView: View {
    let group: MonthGroup
    let items: [ClothingItem]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text(monthAbbrev)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isExpanded ? Color(hex: "#B8A898") : Color(hex: "#6E6E73"))
                        Text(yearString)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
                    .frame(width: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.monthString)
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(hex: "#1C1C1E"))

                        Text("\(group.outfitCount) outfit\(group.outfitCount == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(hex: "#FAFAF8"))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(group.outfits) { outfit in
                        TimelineOutfitRow(outfit: outfit, items: items)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .background(Color(hex: "#E8E8E6"))
        }
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: group.month).uppercased()
    }

    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: group.month)
    }
}

struct TimelineOutfitRow: View {
    let outfit: Outfit
    let items: [ClothingItem]
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 12) {
                HStack(spacing: -10) {
                    ForEach(Array(outfit.itemIds.prefix(3).enumerated()), id: \.offset) { index, itemId in
                        if let item = items.first(where: { $0.id == itemId }) {
                            TimelineThumbnail(item: item)
                                .zIndex(Double(3 - index))
                        }
                    }
                }
                .frame(width: 80)

                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: outfit.eventType.icon)
                            .font(.system(size: 11))
                        Text(outfit.eventType.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }

                    Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#E8E8E6"))
            }
            .padding(12)
            .background(Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            TimelineOutfitDetailView(outfit: outfit, items: items)
        }
    }
}

struct TimelineThumbnail: View {
    let item: ClothingItem
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(hex: "#E8E8E6"))
                    .overlay {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .frame(width: 32, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#FFFFFF"), lineWidth: 1.5)
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}

struct TimelineOutfitDetailView: View {
    let outfit: Outfit
    let items: [ClothingItem]
    @Environment(\.dismiss) private var dismiss

    private var outfitItems: [ClothingItem] {
        outfit.itemIds.compactMap { itemId in items.first { $0.id == itemId } }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    outfitImagesSection

                    outfitInfoSection

                    itemsListSection
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle(outfit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
    }

    private var outfitImagesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(outfitItems) { item in
                    VStack(spacing: 8) {
                        TimelineItemImage(item: item)
                            .frame(width: 120, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text(item.name)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var outfitInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(outfit.eventType.rawValue, systemImage: outfit.eventType.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#E8E8E6"))
                    .clipShape(Capsule())

                Spacer()

                Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }

            if let temp = outfit.temperature {
                HStack(spacing: 4) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 12))
                    Text("\(Int(temp))°")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color(hex: "#6E6E73"))
            }
        }
        .padding(.horizontal, 20)
    }

    private var itemsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items in this outfit")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            ForEach(outfitItems) { item in
                HStack(spacing: 12) {
                    TimelineItemImage(item: item)
                        .frame(width: 48, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "#1C1C1E"))

                        Text(item.category.rawValue)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }

                    Spacer()
                }
                .padding(10)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 20)
    }
}

struct TimelineItemImage: View {
    let item: ClothingItem
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(hex: "#E8E8E6"))
                    .overlay {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}
