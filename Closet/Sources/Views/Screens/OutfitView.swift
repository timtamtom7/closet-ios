import SwiftUI
import UIKit

struct OutfitView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var outfitViewModel = OutfitViewModel()
    @Environment(WardrobeViewModel.self) private var wardrobeViewModel
    @State private var showWhyNotSheet = false
    @State private var showScoreSheet = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var todayEvents: [CalendarService.CalendarEvent] = []
    @State private var calendarAuthorized = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    calendarSection

                    weatherSection

                    if !outfitViewModel.trendInsights.isEmpty {
                        TrendInsightsView(insights: outfitViewModel.trendInsights)
                            .padding(.horizontal, 20)
                    }

                    if !outfitViewModel.layeringSuggestions.isEmpty {
                        TemperatureLayeringView(
                            suggestions: outfitViewModel.layeringSuggestions,
                            temperature: Double(outfitViewModel.currentWeather?.temperature ?? 20)
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
            .background(ClosetDesign.Colors.background(for: colorScheme))
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
            .sheet(isPresented: $outfitViewModel.showSubscriptionPrompt) {
                SubscriptionView(context: outfitViewModel.subscriptionContext)
            }
            .task {
                await outfitViewModel.loadOutfits()
                await wardrobeViewModel.loadItems()
                calendarAuthorized = await CalendarService.shared.requestAccess()
                if calendarAuthorized {
                    todayEvents = await CalendarService.shared.fetchTodayEvents()
                    if let firstEvent = todayEvents.first {
                        outfitViewModel.selectedEventType = firstEvent.suggestedEventType
                    }
                }
            }
            .onChange(of: outfitViewModel.outfits.count) { _, _ in
                Task {
                    await outfitViewModel.loadTrends(items: wardrobeViewModel.items)
                }
            }
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(ClosetDesign.Colors.accent)
                Text("Today's Calendar")
                    .font(ClosetDesign.Typography.heading3)
                    .foregroundStyle(ClosetDesign.Colors.primaryText)
                Spacer()
            }

            if !todayEvents.isEmpty {
                ForEach(todayEvents.prefix(3)) { event in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ClosetDesign.Colors.primaryText)
                                .lineLimit(1)
                            Text(timeRange(from: event))
                                .font(.system(size: 12))
                                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                        }

                        Spacer()

                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                                outfitViewModel.selectedEventType = event.suggestedEventType
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: event.suggestedEventType.icon)
                                    .font(.system(size: 12))
                                Text(event.suggestedEventType.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(
                                outfitViewModel.selectedEventType == event.suggestedEventType
                                ? .white
                                : ClosetDesign.Colors.primaryText
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                outfitViewModel.selectedEventType == event.suggestedEventType
                                ? ClosetDesign.Colors.primaryText
                                : ClosetDesign.Colors.surface(for: colorScheme)
                            )
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(ClosetDesign.Colors.divider, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Set event type to \(event.suggestedEventType.rawValue)")
                    }
                    .padding(12)
                    .background(ClosetDesign.Colors.background(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.button))
                }
            } else if calendarAuthorized {
                Text("No events scheduled for today")
                    .font(.system(size: 13))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 12))
                    Text("Calendar access not granted")
                        .font(.system(size: 13))
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(ClosetDesign.Typography.caption)
                }
                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
            }
        }
        .padding(16)
        .background(ClosetDesign.Colors.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.card))
        .padding(.horizontal, 20)
    }

    private func timeRange(from event: CalendarService.CalendarEvent) -> String {
        if event.isAllDay { return "All Day" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }

    private var weatherSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Weather")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
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
                .foregroundStyle(ClosetDesign.Colors.divider)
            Text("No outfits saved yet")
                .font(ClosetDesign.Typography.sectionTitle)
                .foregroundStyle(ClosetDesign.Colors.primaryText)
            if wardrobeViewModel.items.count < 3 {
                Text("Add at least 3 clothing items to start generating outfits")
                    .font(.system(size: 14))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            } else {
                Text("Generate your first outfit above")
                    .font(.system(size: 14))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
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
                    .font(ClosetDesign.Typography.sectionTitle)
                    .foregroundStyle(ClosetDesign.Colors.primaryText)
                Text("Set your context and let the AI curate looks for you")
                    .font(.system(size: 14))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Event")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                        Picker("Event", selection: $outfitViewModel.selectedEventType) {
                            ForEach(EventType.allCases) { evt in
                                Label(evt.rawValue, systemImage: evt.icon).tag(evt)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(ClosetDesign.Colors.primaryText)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mood")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                        Picker("Mood", selection: $outfitViewModel.selectedMood) {
                            ForEach(Mood.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(ClosetDesign.Colors.primaryText)
                    }
                }
                .padding(16)
                .background(ClosetDesign.Colors.surface(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.card))

                Button {
                    let tap = UIImpactFeedbackGenerator(style: .light)
                    tap.impactOccurred()
                    Task {
                        await outfitViewModel.generateOutfits(from: wardrobeViewModel.items)
                    }
                } label: {
                    Label("Generate Looks", systemImage: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ClosetDesign.Colors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.button))
                }
                .buttonStyle(ScaleButtonStyle())
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
                .foregroundStyle(ClosetDesign.Colors.tertiaryText)

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
                        .foregroundStyle(ClosetDesign.Colors.accent)
                    Text("You've seen all suggestions!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ClosetDesign.Colors.primaryText)
                    Text("Save more clothes to generate new looks")
                        .font(.system(size: 13))
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }

            if outfitViewModel.hasMoreSuggestions {
                HStack(spacing: 4) {
                    ForEach(0..<outfitViewModel.suggestedOutfits.count, id: \.self) { index in
                        Circle()
                            .fill(index == outfitViewModel.currentSuggestionIndex ? ClosetDesign.Colors.primaryText : ClosetDesign.Colors.divider)
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
                    .font(ClosetDesign.Typography.sectionTitle)
                    .foregroundStyle(ClosetDesign.Colors.primaryText)
                Spacer()
                Text("\(outfitViewModel.outfits.count) saved")
                    .font(.system(size: 13))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
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
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity
                ))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75), value: outfitViewModel.outfits.count)
    }
}

struct OutfitLogRow: View {
    @Environment(\.colorScheme) var colorScheme
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
                    .foregroundStyle(ClosetDesign.Colors.primaryText)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(outfit.eventType.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                    Text("·")
                        .foregroundStyle(ClosetDesign.Colors.divider)
                    Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(ClosetDesign.Colors.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.card))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.horizontal, 20)
    }
}

struct OutfitThumbnailSmall: View {
    @Environment(\.colorScheme) var colorScheme
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
                    .fill(ClosetDesign.Colors.divider)
                    .overlay {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                    }
            }
        }
        .frame(width: 36, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6).stroke(ClosetDesign.Colors.surface(for: colorScheme), lineWidth: 1.5)
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}
