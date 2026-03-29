import SwiftUI

/// R12: Wish List View — Items I want
struct WishListView: View {
    @ObservedObject var dataService: ClosetDataService
    @StateObject private var sharingService = ClosetSharingService.shared
    @State private var showingAddItem = false
    @State private var showingShareSheet = false
    @State private var selectedPriority: WishListPriority = .all

    enum WishListPriority: String, CaseIterable {
        case all = "All"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }

    var filteredItems: [WishListItem] {
        let items = dataService.wishListItems
        if selectedPriority == .all {
            return items
        }
        return items.filter { $0.priority.rawValue == selectedPriority.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Priority Filter
            priorityFilterBar

            Divider()

            // Content
            if dataService.wishListItems.isEmpty {
                emptyStateView
            } else {
                wishListContent
            }
        }
        .background(Theme.warmBeige)
        .sheet(isPresented: $showingAddItem) {
            AddWishListItemView(dataService: dataService)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareWishListView(sharingService: sharingService, wishListItems: dataService.wishListItems)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Wish List")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            if !dataService.wishListItems.isEmpty {
                Button {
                    showingShareSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.blush)
                }
                .buttonStyle(.plain)
            }

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
    }

    // MARK: - Priority Filter

    private var priorityFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WishListPriority.allCases, id: \.self) { priority in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPriority = priority
                        }
                    } label: {
                        Text(priority.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selectedPriority == priority ? .white : Theme.slate)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedPriority == priority ? Theme.charcoal : Theme.surface)
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "star.circle")
                .font(.system(size: 48))
                .foregroundColor(Theme.sand.opacity(0.6))

            VStack(spacing: 8) {
                Text("Your wish list is empty")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Text("Add items you want — from your closet or the web.\nBirthday coming up? Share your wish list!")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.slate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                showingAddItem = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add First Item")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.blush)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Wish List Content

    private var wishListContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredItems) { item in
                    WishListItemRow(item: item, dataService: dataService)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Wish List Item Row

struct WishListItemRow: View {
    let item: WishListItem
    @ObservedObject var dataService: ClosetDataService
    @State private var showingGotIt = false

    var body: some View {
        HStack(spacing: 12) {
            // Priority Indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: 8) {
                    if let price = item.estimatedPrice {
                        Text(price)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.slate)
                    }

                    if let store = item.storeName {
                        Text("·")
                            .foregroundColor(Theme.slate)
                        Text(store)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.slate)
                            .lineLimit(1)
                    }
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.slate)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Got It Button
            Button {
                moveToCloset()
            } label: {
                Text("Got it!")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.sage)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.sage.opacity(0.15))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Delete
            Button {
                dataService.deleteWishListItem(item)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.slate.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var priorityColor: Color {
        switch item.priority {
        case .high: return Theme.priorityHigh
        case .medium: return Theme.sand
        case .low: return Theme.sage
        }
    }

    private func moveToCloset() {
        let clothingItem = ClothingItem(
            name: item.name,
            category: item.category,
            imagePath: "",
            dominantColors: item.dominantColors,
            tags: item.tags,
            createdAt: Date(),
            wearCount: 0
        )
        dataService.saveClothingItem(clothingItem)
        dataService.deleteWishListItem(item)
    }
}

// MARK: - Add Wish List Item

struct AddWishListItemView: View {
    @ObservedObject var dataService: ClosetDataService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ClothingCategory = .tops
    @State private var estimatedPrice = ""
    @State private var storeName = ""
    @State private var notes = ""
    @State private var priority: WishListItem.WishListPriority = .medium

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.slate)

                Spacer()

                Text("Add to Wish List")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button("Save") {
                    saveItem()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.blush)
                .disabled(name.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Name
                    FormField(label: "Item Name", text: $name, placeholder: "e.g., Navy Cashmere Sweater")

                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.slate)

                        Picker("", selection: $category) {
                            ForEach(ClothingCategory.allCases.filter { $0 != .all }, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Price & Store
                    HStack(spacing: 12) {
                        FormField(label: "Est. Price", text: $estimatedPrice, placeholder: "$150", axis: .vertical)
                        FormField(label: "Store", text: $storeName, placeholder: "e.g., Everlane", axis: .vertical)
                    }

                    // Priority
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.slate)

                        HStack(spacing: 8) {
                            ForEach(WishListItem.WishListPriority.allCases, id: \.self) { p in
                                Button {
                                    priority = p
                                } label: {
                                    Text(p.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(priority == p ? .white : Theme.slate)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(priority == p ? Theme.charcoal : Theme.surface)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Notes
                    FormField(label: "Notes", text: $notes, placeholder: "Size, color preferences, link...", axis: .vertical)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 360, height: 480)
        .background(Theme.warmBeige)
    }

    private func saveItem() {
        let price = estimatedPrice.isEmpty ? nil : estimatedPrice
        let item = WishListItem(
            name: name,
            category: category,
            estimatedPrice: price,
            storeName: storeName.isEmpty ? nil : storeName,
            priority: priority,
            notes: notes.isEmpty ? nil : notes
        )
        dataService.addWishListItem(item)
        dismiss()
    }
}

// MARK: - Share Wish List

struct ShareWishListView: View {
    @ObservedObject var sharingService: ClosetSharingService
    let wishListItems: [WishListItem]
    @Environment(\.dismiss) private var dismiss

    @State private var shareVia: ShareDestination = .messages

    enum ShareDestination: String, CaseIterable {
        case messages = "Messages"
        case mail = "Mail"
        case copyLink = "Copy Link"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.slate)

                Spacer()

                Text("Share Wish List")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.blush)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Preview Card
                    wishListPreviewCard

                    // Share Destinations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share via")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.slate)

                        ForEach(ShareDestination.allCases, id: \.self) { dest in
                            Button {
                                shareVia(dest)
                            } label: {
                                HStack {
                                    Image(systemName: iconFor(dest))
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.blush)
                                        .frame(width: 24)

                                    Text(dest.rawValue)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textPrimary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.slate.opacity(0.5))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Theme.surface)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Generate QR
                    if let url = sharingService.generateShareLink() {
                        qrCodeSection(url: url)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 360, height: 520)
        .background(Theme.warmBeige)
    }

    private var wishListPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My Wish List")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(Theme.textPrimary)

            ForEach(wishListItems.prefix(3)) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.sand)
                        .frame(width: 6, height: 6)

                    Text(item.name)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    if let price = item.estimatedPrice {
                        Text(price)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.slate)
                    }
                }
            }

            if wishListItems.count > 3 {
                Text("+\(wishListItems.count - 3) more items")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func qrCodeSection(url: URL) -> some View {
        VStack(spacing: 10) {
            Text("Or scan to view")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            if let qrData = sharingService.generateQRCode(for: url),
               let nsImage = NSImage(data: qrData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }

    private func iconFor(_ dest: ShareDestination) -> String {
        switch dest {
        case .messages: return "message.fill"
        case .mail: return "envelope.fill"
        case .copyLink: return "link"
        }
    }

    private func shareVia(_ dest: ShareDestination) {
        let text = formatWishListText()
        switch dest {
        case .messages:
            shareText(text)
        case .mail:
            shareText(text)
        case .copyLink:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    private func formatWishListText() -> String {
        var text = "🎁 My Wish List\n\n"
        for item in wishListItems {
            var line = "• \(item.name)"
            if let price = item.estimatedPrice {
                line += " — \(price)"
            }
            if let store = item.storeName {
                line += " (\(store))"
            }
            line += "\n"
            text += line
        }
        text += "\nShared from Closet"
        return text
    }

    private func shareText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Form Field

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            if axis == .vertical {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Theme.surface)
                    .cornerRadius(8)
            } else {
                HStack(spacing: 0) {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Theme.surface)
                .cornerRadius(8)
            }
        }
    }
}
