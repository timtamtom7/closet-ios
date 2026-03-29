import SwiftUI

struct OutfitBuilderView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var selectedItems: Set<UUID> = []
    @State private var outfitName = ""
    @State private var selectedEvent: EventType = .casual
    @State private var selectedMood: Mood = .relaxed
    @State private var showingSaveAlert = false
    @State private var savedOutfit = false

    private var outfitItems: [ClothingItem] {
        dataService.clothingItems.filter { selectedItems.contains($0.id) }
    }

    private var groupedItems: [ClothingCategory: [ClothingItem]] {
        Dictionary(grouping: dataService.clothingItems) { $0.category }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Outfit Builder")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Event & Mood
            HStack(spacing: 12) {
                // Event Type
                Menu {
                    ForEach(EventType.allCases) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            Label(event.rawValue, systemImage: event.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedEvent.icon)
                        Text(selectedEvent.rawValue)
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.surface)
                    .cornerRadius(8)
                    .foregroundColor(Theme.charcoal)
                }
                .menuStyle(.borderlessButton)

                // Mood
                Menu {
                    ForEach(Mood.allCases) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            Text("\(mood.emoji) \(mood.rawValue)")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedMood.emoji)
                        Text(selectedMood.rawValue)
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.surface)
                    .cornerRadius(8)
                    .foregroundColor(Theme.charcoal)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Selected Items (Outfit Canvas)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Selected Items")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.slate)

                            Spacer()

                            Text("\(selectedItems.count) items")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.slate)
                        }

                        if outfitItems.isEmpty {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.surface)
                                    .frame(height: 120)

                                VStack(spacing: 8) {
                                    Image(systemName: "tshirt")
                                        .font(.system(size: 28))
                                        .foregroundColor(Theme.slate.opacity(0.4))
                                    Text("Tap items to add")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.slate)
                                }
                            }
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(outfitItems) { item in
                                        OutfitItemThumbnail(item: item, isSelected: true) {
                                            selectedItems.remove(item.id)
                                        }
                                    }
                                }
                            }
                            .frame(height: 100)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Outfit Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Outfit Name")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.slate)
                        TextField("e.g. Weekend Casual", text: $outfitName)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Theme.surface)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)

                    // Available Items by Category
                    ForEach(ClothingCategory.allCases.filter { $0 != .all }) { category in
                        if let items = groupedItems[category], !items.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.slate)
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(items) { item in
                                            OutfitItemThumbnail(
                                                item: item,
                                                isSelected: selectedItems.contains(item.id)
                                            ) {
                                                if selectedItems.contains(item.id) {
                                                    selectedItems.remove(item.id)
                                                } else {
                                                    selectedItems.insert(item.id)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            Divider()

            // Save Button
            VStack(spacing: 8) {
                Button {
                    if !selectedItems.isEmpty {
                        saveOutfit()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Save Outfit")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedItems.isEmpty ? Theme.slate : Theme.sage)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(selectedItems.isEmpty)

                if savedOutfit {
                    Text("Outfit saved!")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.sage)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .animation(.easeInOut, value: savedOutfit)
        }
    }

    private func saveOutfit() {
        let name = outfitName.isEmpty ? "Outfit \(dataService.outfits.count + 1)" : outfitName

        let outfit = Outfit(
            name: name,
            itemIds: Array(selectedItems),
            eventType: selectedEvent,
            mood: selectedMood
        )

        dataService.saveOutfit(outfit)

        // Log as worn entry too
        let entry = WornEntry(
            outfitId: outfit.id,
            itemIds: Array(selectedItems)
        )
        dataService.logWornEntry(entry)

        // Reset
        selectedItems.removeAll()
        outfitName = ""
        savedOutfit = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedOutfit = false
        }
    }
}

struct OutfitItemThumbnail: View {
    let item: ClothingItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.surface)
                        .frame(width: 70, height: 70)

                    if let image = ClosetDataService.shared.loadImage(named: item.imagePath) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Theme.slate.opacity(0.5))
                    }

                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.blush, lineWidth: 3)
                            .frame(width: 70, height: 70)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.blush)
                            .offset(x: 25, y: -25)
                    }
                }

                Text(item.name)
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}
