import SwiftUI

struct WardrobeInsightsView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var styleAI = StyleAIService.shared
    @State private var insightText: String = ""
    @State private var showingUnderutilized = false
    @State private var underutilizedItems: [ClothingItem] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Style Profile Overview
                    profileOverviewCard

                    // Insight Card
                    insightCard

                    // Top Tags
                    if !dataService.styleProfile.topTags.isEmpty {
                        topTagsCard
                    }

                    // Most/Least Worn
                    wornStatsCard

                    // Color Palette
                    if !wardrobeColors.isEmpty {
                        colorPaletteCard
                    }

                    // Underutilized Items
                    underutilizedSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Theme.warmBeige)
        .onAppear {
            refreshInsights()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Wardrobe Insights")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button {
                refreshInsights()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.slate)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Profile Overview

    private var profileOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Style Profile")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.slate)
                Spacer()
                Text("Updated \(formattedDate(dataService.styleProfile.totalOutfits))")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.slate.opacity(0.7))
            }

            HStack(spacing: 16) {
                StatBubble(
                    value: "\(dataService.styleProfile.totalItems)",
                    label: "Items",
                    icon: "tshirt"
                )

                StatBubble(
                    value: "\(dataService.styleProfile.totalOutfits)",
                    label: "Outfits",
                    icon: "square.grid.2x2"
                )

                let avg = averageWearsPerItem
                StatBubble(
                    value: String(format: "%.1f", avg),
                    label: "Avg Wears",
                    icon: "repeat"
                )

                StatBubble(
                    value: "\(Int(dataService.styleProfile.neutralColorRatio * 100))%",
                    label: "Neutral",
                    icon: "circle.lefthalf.filled"
                )
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var averageWearsPerItem: Double {
        let items = dataService.clothingItems
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0) { $0 + $1.wearCount }
        return Double(total) / Double(items.count)
    }

    private var wardrobeColors: [String] {
        var colors: [String: Int] = [:]
        for item in dataService.clothingItems {
            for color in item.dominantColors {
                colors[color, default: 0] += 1
            }
        }
        return colors.sorted { $0.value > $1.value }.prefix(8).map { $0.key }
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.sand)
                Text("AI Style Insight")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.slate)
            }

            if insightText.isEmpty {
                Text("Analyzing your wardrobe...")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.slate)
                    .italic()
            } else {
                Text(insightText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sand.opacity(0.12))
        .cornerRadius(10)
    }

    // MARK: - Top Tags

    private var topTagsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Style Keywords")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            let sortedTags = dataService.styleProfile.topTags.sorted { $0.value > $1.value }.prefix(10)
            FlowLayout(spacing: 6) {
                ForEach(Array(sortedTags), id: \.key) { tag, count in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                        Text("\(count)×")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.slate)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.surface)
                    .cornerRadius(12)
                    .foregroundColor(Theme.textPrimary)
                }
            }
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    // MARK: - Worn Stats

    private var wornStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wear Statistics")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            if let most = dataService.styleProfile.mostWornItem, most.wearCount > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.sand)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Most Worn")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.slate)
                        Text(most.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                    }

                    Spacer()

                    Text("\(most.wearCount)×")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.blush)
                }
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(10)
            }

            if let least = dataService.styleProfile.leastWornItem {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.slate.opacity(0.6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(least.wearCount == 0 ? "Never Worn" : "Least Worn")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.slate)
                        Text(least.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                    }

                    Spacer()

                    Text(least.wearCount == 0 ? "New!" : "\(least.wearCount)×")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(least.wearCount == 0 ? Theme.sage : Theme.slate)
                }
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(10)
            }

            // Monthly Activity Chart
            monthlyActivityChart
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var monthlyActivityChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Month's Outfit Log")
                .font(.system(size: 11))
                .foregroundColor(Theme.slate)

            let entriesByWeek = entriesByWeekOfMonth()
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<4, id: \.self) { week in
                    let count = week < entriesByWeek.count ? entriesByWeek[week] : 0
                    let maxCount = max(entriesByWeek.max() ?? 1, 1)
                    let height = CGFloat(count) / CGFloat(maxCount) * 40 + 4

                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(count > 0 ? Theme.blush : Theme.mist)
                            .frame(width: 28, height: height)

                        Text("W\(week + 1)")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.slate)
                    }
                }
            }
            .frame(height: 60)
        }
    }

    private func entriesByWeekOfMonth() -> [Int] {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        let entriesThisMonth = dataService.wornEntries.filter {
            calendar.component(.month, from: $0.date) == month &&
            calendar.component(.year, from: $0.date) == year
        }

        var weeks = [0, 0, 0, 0]
        for entry in entriesThisMonth {
            let week = calendar.component(.weekOfMonth, from: entry.date) - 1
            if week >= 0 && week < 4 {
                weeks[week] += 1
            }
        }
        return weeks
    }

    // MARK: - Color Palette

    private var colorPaletteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Color Palette")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            HStack(spacing: 8) {
                ForEach(wardrobeColors.prefix(8), id: \.self) { color in
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle().stroke(Theme.mist, lineWidth: 1)
                        )
                }
                Spacer()
            }

            // Color breakdown
            let colorBreakdown = colorBreakdownText
            if !colorBreakdown.isEmpty {
                Text(colorBreakdown)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var colorBreakdownText: String {
        let neutralColors = Set(["black", "white", "gray", "beige", "navy", "cream", "tan", "charcoal"])
        let items = dataService.clothingItems
        guard !items.isEmpty else { return "" }

        var colorItems = 0
        var neutralCount = 0
        for item in items {
            if !item.dominantColors.isEmpty {
                colorItems += 1
                if item.dominantColors.allSatisfy({ neutralColors.contains($0.lowercased()) }) {
                    neutralCount += 1
                }
            }
        }

        guard colorItems > 0 else { return "" }
        let neutralPct = Int(Double(neutralCount) / Double(colorItems) * 100)

        if neutralPct >= 70 {
            return "Predominantly neutral — blacks, whites, and earth tones dominate."
        } else if neutralPct >= 40 {
            return "Mix of neutrals with pops of color throughout."
        } else {
            return "Color-forward wardrobe — you embrace vibrant hues."
        }
    }

    // MARK: - Underutilized Section

    private var underutilizedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Wear More Often")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.slate)

                Spacer()

                Button {
                    withAnimation {
                        showingUnderutilized.toggle()
                    }
                } label: {
                    Text(showingUnderutilized ? "Hide" : "Show all")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.blush)
                }
                .buttonStyle(.plain)
            }

            let items = underutilizedItems
            if items.isEmpty {
                Text("All your items are getting love! 🎉")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.slate)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items.prefix(showingUnderutilized ? items.count : 4)) { item in
                            UnderutilizedItemCard(item: item)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func refreshInsights() {
        underutilizedItems = dataService.clothingItems
            .filter { $0.wearCount <= 1 }
            .sorted { $0.createdAt > $1.createdAt }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            insightText = styleAI.analyzeWardrobeTaste()
        }
    }

    private func formattedDate(_ outfitCount: Int) -> String {
        if outfitCount == 0 { return "never" }
        let entries = dataService.wornEntries
        guard let last = entries.first else { return "never" }
        let days = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "yesterday" }
        return "\(days)d ago"
    }
}

// MARK: - Supporting Views

struct StatBubble: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.blush)

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Theme.slate)
        }
        .frame(maxWidth: .infinity)
    }
}

struct UnderutilizedItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.mist)

                if let image = ClosetDataService.shared.loadImage(named: item.imagePath) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Theme.slate.opacity(0.4))
                }
            }
            .frame(width: 70, height: 70)

            Text(item.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
                .frame(width: 70, alignment: .leading)

            Text(item.wearCount == 0 ? "Never worn" : "\(item.wearCount)× worn")
                .font(.system(size: 9))
                .foregroundColor(item.wearCount == 0 ? Theme.sage : Theme.slate)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            height = y + lineHeight
        }
    }
}
