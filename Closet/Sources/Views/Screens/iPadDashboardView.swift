import SwiftUI

struct iPadDashboardView: View {
    @State private var wardrobeViewModel = WardrobeViewModel()
    @State private var outfitViewModel = OutfitViewModel()
    @State private var selectedSidebarItem: SidebarItem? = .wardrobe
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    enum SidebarItem: String, CaseIterable, Identifiable {
        case wardrobe = "Wardrobe"
        case outfits = "Outfits"
        case palette = "Palette"
        case travel = "Travel"
        case style = "Style"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .wardrobe: return "tshirt"
            case .outfits: return "sparkles"
            case .palette: return "paintpalette"
            case .travel: return "airplane"
            case .style: return "person.crop.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
        } detail: {
            HStack(spacing: 0) {
                detailContent
                    .frame(maxWidth: .infinity)
                trailingPanel
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await wardrobeViewModel.loadItems()
            await outfitViewModel.loadOutfits()
        }
    }

    private var sidebarContent: some View {
        List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
            NavigationLink(value: item) {
                Label(item.rawValue, systemImage: item.icon)
            }
        }
        .navigationTitle("Closet")
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedSidebarItem {
        case .wardrobe:
            NavigationStack {
                WardrobeGridView(wardrobeViewModel: wardrobeViewModel)
            }
        case .outfits:
            NavigationStack {
                OutfitLogListView(outfitViewModel: outfitViewModel, wardrobeViewModel: wardrobeViewModel)
            }
        case .palette:
            NavigationStack {
                ColorPaletteView()
            }
        case .travel:
            NavigationStack {
                TravelPackingView()
            }
        case .style:
            NavigationStack {
                StyleProfileView()
            }
        case .none:
            ZStack {
                Color(hex: "#FAFAF8").ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 72))
                        .foregroundColor(Color(hex: "#1C1C1E").opacity(0.1))
                    Text("Select a view from the sidebar")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var trailingPanel: some View {
        VStack(spacing: 0) {
            // Quick Stats Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(wardrobeViewModel.items.count)")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    Text("items")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#6E6E73"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(outfitViewModel.outfits.count)")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    Text("outfits")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#6E6E73"))
                }
            }
            .padding()
            .background(Color(hex: "#FFFFFF"))

            Divider()

            // Today's outfit
            if let todayOutfit = outfitViewModel.outfits.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Outfit")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#6E6E73"))

                    HStack(spacing: -8) {
                        ForEach(Array(todayOutfit.itemIds.prefix(3).enumerated()), id: \.offset) { index, itemId in
                            if let item = wardrobeViewModel.items.first(where: { $0.id == itemId }) {
                                TrailingItemThumbnail(item: item)
                                    .zIndex(Double(3 - index))
                            }
                        }
                    }

                    Text(todayOutfit.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .lineLimit(1)

                    Text(todayOutfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#6E6E73"))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#FAFAF8"))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#E8E8E6"))
                    Text("No outfits yet")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6E6E73"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(hex: "#FAFAF8"))
            }

            Spacer()

            // Weather
            if let weather = outfitViewModel.currentWeather {
                HStack(spacing: 8) {
                    Image(systemName: weather.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#B8A898"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(weather.temperature))°")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#1C1C1E"))
                        Text(weather.condition)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#6E6E73"))
                    }
                    Spacer()
                }
                .padding()
                .background(Color(hex: "#FFFFFF"))
            }
        }
        .frame(width: 220)
    }
}

// MARK: - iPad Wardrobe Grid

struct WardrobeGridView: View {
    var wardrobeViewModel: WardrobeViewModel
    @State private var selectedCategory: ClothingCategory?
    @State private var showCamera = false

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)
    ]

    var filteredItems: [ClothingItem] {
        guard let category = selectedCategory else {
            return wardrobeViewModel.items
        }
        return wardrobeViewModel.items.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(
                            category: nil,
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )

                        ForEach(ClothingCategory.allCases.filter { $0 != .unknown }, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredItems) { item in
                        ClothingItemCard(
                            item: item,
                            onTap: {},
                            onDelete: {
                                Task { await wardrobeViewModel.deleteItem(item) }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "#FAFAF8"))
        .navigationTitle("Wardrobe")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCamera = true
                } label: {
                    Image(systemName: "camera.fill")
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            Text("Camera")
        }
    }
}

// MARK: - iPad Outfit Log List

struct OutfitLogListView: View {
    var outfitViewModel: OutfitViewModel
    var wardrobeViewModel: WardrobeViewModel

    var body: some View {
        ScrollView {
            if outfitViewModel.outfits.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "#E8E8E6"))
                    Text("No outfits saved yet")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    Text("Generate and save outfits to see them here")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6E6E73"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(outfitViewModel.outfits) { outfit in
                        OutfitLogRow(outfit: outfit, items: wardrobeViewModel.items, onDelete: {
                            Task { await outfitViewModel.deleteOutfit(outfit) }
                        })
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .background(Color(hex: "#FAFAF8"))
        .navigationTitle("Outfits")
    }
}

// MARK: - Supporting Views

struct TrailingItemThumbnail: View {
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
        .frame(width: 40, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#FFFFFF"), lineWidth: 2)
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}
