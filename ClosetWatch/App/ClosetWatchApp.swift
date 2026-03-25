import SwiftUI
import WatchKit

@main
struct ClosetWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayOutfitView()
                .tag(0)

            RecentOutfitsView()
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - Today Outfit

struct TodayOutfitView: View {
    @State private var todayOutfit: OutfitRecord?
    @State private var showingLogSheet = false
    @State private var selectedCategory: ClothingCategory = .tops

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let outfit = todayOutfit {
                        // Today's outfit
                        outfitSummaryView(outfit)
                    } else {
                        emptyStateView
                    }

                    // Category quick-log
                    categoryGrid
                }
                .padding()
            }
            .navigationTitle("Closet")
            .sheet(isPresented: $showingLogSheet) {
                LogOutfitSheet(category: $selectedCategory, onSave: {
                    loadTodayOutfit()
                })
            }
            .onAppear {
                loadTodayOutfit()
            }
        }
    }

    private func loadTodayOutfit() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "todayOutfit"),
           let outfit = try? JSONDecoder().decode(OutfitRecord.self, from: data) {
            todayOutfit = outfit
        }
    }

    private func outfitSummaryView(_ outfit: OutfitRecord) -> some View {
        VStack(spacing: 8) {
            Text("Today's Outfit")
                .font(.caption2)
                .foregroundColor(.secondary)

            ForEach(outfit.items, id: \.self) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundColor(.orange)
                    Text(item.category.rawValue)
                        .font(.caption)
                }
            }

            if let notes = outfit.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Button {
                showingLogSheet = true
            } label: {
                Label("Update", systemImage: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tshirt")
                .font(.title2)
                .foregroundColor(.orange.opacity(0.5))

            Text("No outfit logged today")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                showingLogSheet = true
            } label: {
                Label("Log Outfit", systemImage: "plus")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(ClothingCategory.allCases.filter { $0 != .unknown }, id: \.self) { category in
                Button {
                    selectedCategory = category
                    showingLogSheet = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: category.icon)
                            .font(.title3)
                        Text(category.rawValue)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Recent Outfits

struct RecentOutfitsView: View {
    @State private var recentOutfits: [OutfitRecord] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                if recentOutfits.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.orange.opacity(0.5))
                        Text("No recent outfits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(recentOutfits.prefix(5), id: \.date) { outfit in
                            outfitRow(outfit)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Recent")
            .onAppear {
                loadRecentOutfits()
            }
        }
    }

    private func loadRecentOutfits() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "recentOutfits"),
           let outfits = try? JSONDecoder().decode([OutfitRecord].self, from: data) {
            recentOutfits = outfits
        }
    }

    private func outfitRow(_ outfit: OutfitRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(outfit.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .fontWeight(.medium)

                Text(outfit.items.map { $0.category.rawValue }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Log Outfit Sheet

struct LogOutfitSheet: View {
    @Binding var category: ClothingCategory
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategories: Set<ClothingCategory> = []
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("What are you wearing?")
                        .font(.headline)
                        .foregroundColor(.orange)

                    // Category selection
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(ClothingCategory.allCases.filter { $0 != .unknown }, id: \.self) { cat in
                            Button {
                                if selectedCategories.contains(cat) {
                                    selectedCategories.remove(cat)
                                } else {
                                    selectedCategories.insert(cat)
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: cat.icon)
                                        .font(.title3)
                                    Text(cat.rawValue)
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    selectedCategories.contains(cat)
                                        ? Color.orange
                                        : Color.orange.opacity(0.1)
                                )
                                .foregroundColor(
                                    selectedCategories.contains(cat)
                                        ? .white
                                        : .orange
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Notes
                    TextField("Notes (optional)", text: $notes)
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
            }
            .navigationTitle("Log Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveOutfit()
                        dismiss()
                    }
                    .disabled(selectedCategories.isEmpty)
                }
            }
        }
    }

    private func saveOutfit() {
        let items = selectedCategories.map { ClothingItemRecord(category: $0) }
        let record = OutfitRecord(date: Date(), items: items, notes: notes.isEmpty ? nil : notes)

        let defaults = UserDefaults.standard

        // Save as today's outfit
        if let data = try? JSONEncoder().encode(record) {
            defaults.set(data, forKey: "todayOutfit")
        }

        // Add to recent outfits
        var recent: [OutfitRecord] = []
        if let data = defaults.data(forKey: "recentOutfits"),
           let existing = try? JSONDecoder().decode([OutfitRecord].self, from: data) {
            recent = existing
        }
        recent.insert(record, at: 0)
        if recent.count > 20 { recent = Array(recent.prefix(20)) }
        if let data = try? JSONEncoder().encode(recent) {
            defaults.set(data, forKey: "recentOutfits")
        }

        // Also save to shared app group
        if let sharedDefaults = UserDefaults(suiteName: "group.com.closet.stylist") {
            if let data = try? JSONEncoder().encode(record) {
                sharedDefaults.set(data, forKey: "watchTodayOutfit")
            }
        }

        WKInterfaceDevice.current().play(.success)
        onSave()
    }
}

// MARK: - Shared Models

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

struct ClothingItemRecord: Codable, Hashable {
    let category: ClothingCategory
}

struct OutfitRecord: Codable {
    let date: Date
    let items: [ClothingItemRecord]
    let notes: String?
}
