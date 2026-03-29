import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var showingResetAlert = false
    @State private var showingImportPanel = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Style Profile")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.slate)

                    HStack(spacing: 12) {
                        StyleStatCard(
                            title: "Items",
                            value: "\(dataService.styleProfile.totalItems)",
                            subtitle: "in wardrobe"
                        )

                        StyleStatCard(
                            title: "Outfits",
                            value: "\(dataService.styleProfile.totalOutfits)",
                            subtitle: "logged"
                        )

                        StyleStatCard(
                            title: "Neutral",
                            value: "\(Int(dataService.styleProfile.neutralColorRatio * 100))%",
                            subtitle: "color palette"
                        )
                    }
                }
                .padding(.horizontal, 16)

                // Most/Least Worn
                if let mostWorn = dataService.styleProfile.mostWornItem {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Worn Stats")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.slate)

                        HStack(spacing: 12) {
                            WornStatRow(
                                label: "Most Worn",
                                item: mostWorn,
                                icon: "flame.fill",
                                color: Theme.blush
                            )

                            if let leastWorn = dataService.styleProfile.leastWornItem {
                                WornStatRow(
                                    label: "Needs Love",
                                    item: leastWorn,
                                    icon: "heart.fill",
                                    color: Theme.sage
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Divider()
                    .padding(.horizontal, 16)

                // Photo Import
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.slate)

                    Button {
                        showingImportPanel = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Import Photos")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surface)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                Divider()
                    .padding(.horizontal, 16)

                // Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.slate)

                    VStack(spacing: 8) {
                        ForEach(ClothingCategory.allCases.filter { $0 != .all }) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.blush)
                                    .frame(width: 24)

                                Text(category.rawValue)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textPrimary)

                                Spacer()

                                let count = dataService.clothingItems.filter { $0.category == category }.count
                                Text("\(count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.slate)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Theme.surface)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)

                Divider()
                    .padding(.horizontal, 16)

                // Data Management
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.slate)

                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Statistics")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                // About
                VStack(spacing: 4) {
                    Text("Closet")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(Theme.textPrimary)

                    Text("Version 1.0")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.slate)
                }
                .padding(.top, 20)
            }
            .padding(.vertical, 16)
        }
        .alert("Reset All Statistics?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                dataService.resetAllStatistics()
            }
        } message: {
            Text("This will reset all wear counts, delete outfit logs, and remove all outfits. Your clothing items will be kept.")
        }
    }
}

struct StyleStatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.slate)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(Theme.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

struct WornStatRow: View {
    let label: String
    let item: ClothingItem
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.slate)

                Text(item.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text("\(item.wearCount) wears")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.slate)
            }

            Spacer()
        }
        .padding(10)
        .background(Theme.surface)
        .cornerRadius(10)
    }
}
