import SwiftUI

struct ClosetOverviewView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var selectedCategory: ClothingCategory = .all
    @State private var selectedSort: SortOption = .recent
    @State private var showingAddItem = false
    @State private var searchText = ""

    private var filteredItems: [ClothingItem] {
        var items = dataService.clothingItems

        // Filter by category
        if selectedCategory != .all {
            items = items.filter { $0.category == selectedCategory }
        }

        // Filter by search
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Sort
        switch selectedSort {
        case .recent:
            items.sort { $0.createdAt > $1.createdAt }
        case .mostWorn:
            items.sort { $0.wearCount > $1.wearCount }
        case .leastWorn:
            items.sort { $0.wearCount < $1.wearCount }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Wardrobe")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.blush)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.slate)
                    .font(.system(size: 12))
                TextField("Search items...", text: $searchText)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Theme.surface)
            .cornerRadius(8)
            .padding(.horizontal, 16)

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ClothingCategory.allCases) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)

            // Sort
            HStack {
                Text("\(filteredItems.count) items")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate)

                Spacer()

                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if selectedSort == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedSort.rawValue)
                            .font(.system(size: 11))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(Theme.slate)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(filteredItems) { item in
                        ClothingItemCard(item: item, dataService: dataService)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(dataService: dataService, isPresented: $showingAddItem)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Theme.charcoal : Theme.mist)
            .foregroundColor(isSelected ? .white : Theme.slate)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct ClothingItemCard: View {
    let item: ClothingItem
    @ObservedObject var dataService: ClosetDataService
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Image
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.surface)

                    if let image = dataService.loadImage(named: item.imagePath) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 28))
                            .foregroundColor(Theme.slate.opacity(0.5))
                    }
                }
                .frame(height: 100)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    HStack {
                        Text(item.category.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.slate)

                        Spacer()

                        Text("\(item.wearCount)×")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.blush)
                    }
                }
            }
            .padding(10)
            .background(Theme.surface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            ItemDetailSheet(item: item, dataService: dataService, isPresented: $showingDetail)
        }
    }
}

struct ItemDetailSheet: View {
    let item: ClothingItem
    @ObservedObject var dataService: ClosetDataService
    @Binding var isPresented: Bool
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
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

            // Image
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surface)

                if let image = dataService.loadImage(named: item.imagePath) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                } else {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 48))
                        .foregroundColor(Theme.slate.opacity(0.5))
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 16)

            // Info
            VStack(spacing: 12) {
                Text(item.name)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 16) {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.slate)

                    Label("\(item.wearCount) wears", systemImage: "repeat")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.blush)
                }

                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.sand.opacity(0.3))
                                    .foregroundColor(Theme.charcoal)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                if !item.dominantColors.isEmpty {
                    HStack(spacing: 6) {
                        Text("Colors:")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.slate)

                        ForEach(item.dominantColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle().stroke(Theme.mist, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Delete
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Item", systemImage: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 420)
        .background(Theme.warmBeige)
        .alert("Delete Item?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataService.deleteClothingItem(item)
                isPresented = false
            }
        } message: {
            Text("This will permanently remove \(item.name) from your wardrobe.")
        }
    }
}

struct AddItemSheet: View {
    @ObservedObject var dataService: ClosetDataService
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var category: ClothingCategory = .tops
    @State private var tagsText = ""
    @State private var selectedImage: NSImage?

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Add Item")
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

            // Image Picker
            Button {
                pickImage()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.surface)

                    if let image = selectedImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.slate.opacity(0.5))
                            Text("Add Photo")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.slate)
                        }
                    }
                }
                .frame(height: 140)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)

            // Fields
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.slate)
                    TextField("e.g. White Cotton Tee", text: $name)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Theme.surface)
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.slate)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([ClothingCategory.tops, .bottoms, .shoes, .accessories, .outerwear]) { cat in
                                CategoryChip(
                                    title: cat.rawValue,
                                    icon: cat.icon,
                                    isSelected: category == cat
                                ) {
                                    category = cat
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tags (comma separated)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.slate)
                    TextField("e.g. casual, summer", text: $tagsText)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Theme.surface)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Save Button
            Button {
                saveItem()
            } label: {
                Text("Add to Wardrobe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(name.isEmpty ? Theme.slate : Theme.blush)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(name.isEmpty)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 480)
        .background(Theme.warmBeige)
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            self.selectedImage = NSImage(contentsOf: url)
        }
    }

    private func saveItem() {
        var imagePath = ""
        if let image = selectedImage {
            imagePath = dataService.saveImage(image) ?? ""
        }

        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        let item = ClothingItem(
            name: name,
            category: category,
            imagePath: imagePath,
            dominantColors: [],
            tags: tags
        )

        dataService.saveClothingItem(item)
        isPresented = false
    }
}
