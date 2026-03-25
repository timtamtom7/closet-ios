import SwiftUI

struct OutfitView: View {
    @State private var outfitViewModel = OutfitViewModel()
    @State private var wardrobeViewModel = WardrobeViewModel()
    @State private var showWhyNotSheet = false
    @State private var showScoreSheet = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    weatherSection

                    if !outfitViewModel.trendInsights.isEmpty {
                        TrendInsightsView(insights: outfitViewModel.trendInsights)
                            .padding(.horizontal, 20)
                    }

                    if !outfitViewModel.layeringSuggestions.isEmpty {
                        TemperatureLayeringView(
                            suggestions: outfitViewModel.layeringSuggestions,
                            temperature: outfitViewModel.currentWeather?.temperature ?? 20
                        )
                        .padding(.horizontal, 20)
                    }

                    if !outfitViewModel.forecasts.isEmpty {
                        SeasonTransitionView(forecasts: outfitViewModel.forecasts, items: wardrobeViewModel.items)
                            .padding(.horizontal, 20)
                    }

                    generatorSection

                    if outfitViewModel.outfits.isEmpty && !outfitViewModel.isLoading {
                        outfitEmptyState
                    } else if !outfitViewModel.outfits.isEmpty {
                        outfitLogSection
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Outfits")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if outfitViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.top, 8)
                }
            }
            .sheet(isPresented: $showWhyNotSheet) {
                if let outfit = outfitViewModel.currentSuggestion {
                    WhyNotSheet(outfit: outfit) { reason in
                        Task {
                            await outfitViewModel.vetoOutfit(outfit, reason: reason)
                        }
                    }
                }
            }
            .sheet(isPresented: $showScoreSheet) {
                if let outfit = outfitViewModel.currentSuggestion {
                    OutfitScoreSheet(outfit: outfit) { score in
                        Task {
                            await outfitViewModel.rateOutfit(outfit, score: score)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
            .task {
                await outfitViewModel.loadOutfits()
                await wardrobeViewModel.loadItems()
            }
            .onChange(of: outfitViewModel.outfits.count) { _, _ in
                Task {
                    await outfitViewModel.loadTrends(items: wardrobeViewModel.items)
                }
            }
        }
    }

    private var weatherSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Weather")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "#6E6E73"))
                WeatherBadge(weather: outfitViewModel.currentWeather)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var outfitEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#E8E8E6"))
            Text("No outfits saved yet")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))
            if wardrobeViewModel.items.count < 3 {
                Text("Add at least 3 clothing items to start generating outfits")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#6E6E73"))
                    .multilineTextAlignment(.center)
            } else {
                Text("Generate your first outfit above")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#6E6E73"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
    }

    private var generatorSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Generate Outfits")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                Text("Set your context and let the AI curate looks for you")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Event")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                        Picker("Event", selection: $outfitViewModel.selectedEventType) {
                            ForEach(EventType.allCases) { evt in
                                Label(evt.rawValue, systemImage: evt.icon).tag(evt)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color(hex: "#1C1C1E"))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mood")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                        Picker("Mood", selection: $outfitViewModel.selectedMood) {
                            ForEach(Mood.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color(hex: "#1C1C1E"))
                    }
                }
                .padding(16)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task {
                        await outfitViewModel.generateOutfits(from: wardrobeViewModel.items)
                    }
                } label: {
                    Label("Generate Looks", systemImage: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#1C1C1E"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(wardrobeViewModel.items.count < 3)
                .opacity(wardrobeViewModel.items.count < 3 ? 0.5 : 1)
            }
            .padding(.horizontal, 20)

            if !outfitViewModel.suggestedOutfits.isEmpty {
                suggestionCarousel
            }
        }
    }

    private var suggestionCarousel: some View {
        VStack(spacing: 16) {
            Text("Swipe right to save, left to pass")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#6E6E73"))

            if let current = outfitViewModel.currentSuggestion {
                OutfitCard(
                    outfit: current,
                    items: wardrobeViewModel.items,
                    onSave: {
                        Task {
                            await outfitViewModel.saveOutfit(current)
                        }
                    },
                    onDismiss: {
                        outfitViewModel.advanceSuggestion()
                    },
                    onWhyNot: {
                        showWhyNotSheet = true
                    },
                    onRate: {
                        showScoreSheet = true
                    }
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: "#B8A898"))
                    Text("You've seen all suggestions!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
                    Text("Save more clothes to generate new looks")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }

            if outfitViewModel.hasMoreSuggestions {
                HStack(spacing: 4) {
                    ForEach(0..<outfitViewModel.suggestedOutfits.count, id: \.self) { index in
                        Circle()
                            .fill(index == outfitViewModel.currentSuggestionIndex ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    private var outfitLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Outfit Log")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                Spacer()
                Text("\(outfitViewModel.outfits.count) saved")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }
            .padding(.horizontal, 20)

            ForEach(outfitViewModel.outfits.prefix(5)) { outfit in
                OutfitLogRow(
                    outfit: outfit,
                    items: wardrobeViewModel.items,
                    onDelete: {
                        Task { await outfitViewModel.deleteOutfit(outfit) }
                    }
                )
            }
        }
    }
}

struct OutfitLogRow: View {
    let outfit: Outfit
    let items: [ClothingItem]
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: -10) {
                ForEach(Array(outfit.itemIds.prefix(3).enumerated()), id: \.offset) { index, itemId in
                    if let item = items.first(where: { $0.id == itemId }) {
                        OutfitThumbnailSmall(item: item)
                            .zIndex(Double(3 - index))
                    }
                }
            }
            .frame(width: 90)

            VStack(alignment: .leading, spacing: 4) {
                Text(outfit.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(outfit.eventType.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                    Text("·")
                        .foregroundStyle(Color(hex: "#E8E8E6"))
                    Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.horizontal, 20)
    }
}

struct OutfitThumbnailSmall: View {
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
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .frame(width: 36, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#FFFFFF"), lineWidth: 1.5)
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}
