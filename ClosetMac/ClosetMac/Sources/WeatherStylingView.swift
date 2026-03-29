import SwiftUI

struct WeatherStylingView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var styleAI = StyleAIService.shared
    @State private var weather: Weather?
    @State private var isLoadingWeather = true
    @State private var weatherError: String?
    @State private var currentSuggestion: OutfitSuggestion?
    @State private var allSuggestions: [OutfitSuggestion] = []
    @State private var currentIndex = 0
    @State private var savedMessage = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Weather Card
                    weatherCard

                    // Layering Advice
                    if let w = weather, let advice = w.layeringAdvice {
                        layeringAdviceCard(advice: advice)
                    }

                    // Current Suggestion
                    if let suggestion = currentSuggestion {
                        suggestionCard(suggestion)
                    }

                    // Suggestion Navigation
                    if !allSuggestions.isEmpty {
                        suggestionNavigation
                    }

                    // Saved Feedback
                    if savedMessage {
                        savedFeedbackView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Theme.warmBeige)
        .task {
            await loadWeather()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Weather & Style")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button {
                Task { await loadWeather() }
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

    // MARK: - Weather Card

    private var weatherCard: some View {
        VStack(spacing: 12) {
            if isLoadingWeather {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Fetching weather...")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.slate)
                }
                .frame(height: 80)
            } else if let error = weatherError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(Theme.slate)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.slate)
                }
                .frame(height: 80)
            } else if let w = weather {
                HStack(spacing: 16) {
                    // Weather Icon
                    weatherIcon(for: w.condition)
                        .font(.system(size: 36))
                        .foregroundColor(Theme.blush)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Forecast")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.slate)

                        Text("\(Int(w.temperatureFahrenheit))°F / \(Int(w.temperatureCelsius))°C")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundColor(Theme.textPrimary)

                        Text(w.condition)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.slate)
                    }

                    Spacer()
                }
                .padding(16)

                // Temperature bar visualization
                temperatureBar(w)
            }
        }
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func temperatureBar(_ w: Weather) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            // Map -10°C..35°C to 0..1
            let temp = w.temperatureCelsius
            let normalized = (temp + 10) / 45.0
            let clamped = min(max(normalized, 0), 1)

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.mist)
                    .frame(height: 6)

                // Gradient fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "89CFF0"), Color(hex: "F4A460"), Color(hex: "C45C4A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * clamped, height: 6)

                // Tonight marker (assume 8°C drop)
                let tonightTemp = temp - 8
                let tonightNormalized = (tonightTemp + 10) / 45.0
                let tonightClamped = min(max(tonightNormalized, 0), 1)

                Circle()
                    .fill(Theme.slate)
                    .frame(width: 8, height: 8)
                    .offset(x: width * tonightClamped - 4, y: -1)
                    .opacity(temp < 25 ? 1 : 0)

                Text("Tonight: \(Int(tonightTemp))°C")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.slate)
                    .offset(x: width * tonightClamped - 20, y: -14)
                    .opacity(temp < 25 ? 1 : 0)
            }
        }
        .frame(height: 24)
    }

    private func weatherIcon(for condition: String) -> some View {
        let lower = condition.lowercased()
        if lower.contains("sun") || lower.contains("clear") {
            return Image(systemName: "sun.max.fill")
        } else if lower.contains("cloud") && lower.contains("part") {
            return Image(systemName: "cloud.sun.fill")
        } else if lower.contains("cloud") {
            return Image(systemName: "cloud.fill")
        } else if lower.contains("rain") || lower.contains("drizzle") || lower.contains("shower") {
            return Image(systemName: "cloud.rain.fill")
        } else if lower.contains("snow") {
            return Image(systemName: "cloud.snow.fill")
        } else if lower.contains("thunder") || lower.contains("storm") {
            return Image(systemName: "cloud.bolt.fill")
        } else if lower.contains("fog") || lower.contains("mist") {
            return Image(systemName: "cloud.fog.fill")
        }
        return Image(systemName: "cloud.fill")
    }

    // MARK: - Layering Advice

    private func layeringAdviceCard(advice: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(Theme.sand)

            Text(advice)
                .font(.system(size: 12))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Theme.sand.opacity(0.15))
        .cornerRadius(10)
    }

    // MARK: - Suggestion Card

    private func suggestionCard(_ suggestion: OutfitSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Suggestion")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.slate)

                Spacer()

                if let w = weather {
                    WeatherBadgeMini(temperature: w.temperatureFahrenheit, condition: w.condition)
                }
            }

            // Outfit Items Preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -10) {
                    ForEach(Array(suggestion.items.enumerated()), id: \.element.id) { index, item in
                        OutfitSuggestionThumbnail(item: item, index: index, total: suggestion.items.count)
                    }
                }
                .padding(.leading, 4)
            }
            .frame(height: 100)

            // Reason
            Text(suggestion.reason)
                .font(.system(size: 12))
                .foregroundColor(Theme.slate)
                .italic()

            // Action Buttons
            HStack(spacing: 12) {
                Button {
                    saveSuggestion(suggestion)
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Love it")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.blush)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button {
                    nextSuggestion()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Skip")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.slate)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.surface)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var suggestionNavigation: some View {
        HStack(spacing: 8) {
            ForEach(0..<allSuggestions.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Theme.charcoal : Theme.mist)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 4)
    }

    private var savedFeedbackView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.sage)
            Text("Saved to your outfit log!")
                .font(.system(size: 12))
                .foregroundColor(Theme.sage)
        }
        .padding(.vertical, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Actions

    private func loadWeather() async {
        isLoadingWeather = true
        weatherError = nil

        let w = styleAI.fetchWeather()
        self.weather = w

        if w != nil {
            let suggestions = styleAI.suggestOutfits(count: 5, weather: w)
            self.allSuggestions = suggestions
            self.currentSuggestion = suggestions.first
            self.currentIndex = 0
        } else {
            weatherError = "Couldn't fetch weather. Check your connection."
            let suggestions = styleAI.suggestOutfits(count: 5)
            self.allSuggestions = suggestions
            self.currentSuggestion = suggestions.first
        }

        isLoadingWeather = false
    }

    private func nextSuggestion() {
        guard !allSuggestions.isEmpty else { return }
        currentIndex = (currentIndex + 1) % allSuggestions.count
        currentSuggestion = allSuggestions[currentIndex]
    }

    private func saveSuggestion(_ suggestion: OutfitSuggestion) {
        let outfitName = "Suggested — \(suggestion.occasion)"
        let outfit = Outfit(
            name: outfitName,
            itemIds: suggestion.items.map { $0.id },
            eventType: EventType(rawValue: suggestion.occasion) ?? .casual,
            mood: .relaxed,
            weather: weather?.description
        )
        dataService.saveOutfit(outfit)

        let entry = WornEntry(
            outfitId: outfit.id,
            itemIds: suggestion.items.map { $0.id }
        )
        dataService.logWornEntry(entry)

        withAnimation {
            savedMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                savedMessage = false
            }
        }

        nextSuggestion()
    }
}

// MARK: - Supporting Views

struct OutfitSuggestionThumbnail: View {
    let item: ClothingItem
    let index: Int
    let total: Int

    var body: some View {
        ZStack {
            if let image = ClosetDataService.shared.loadImage(named: item.imagePath) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 90)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.mist)
                    .frame(width: 80, height: 90)

                Image(systemName: item.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.slate.opacity(0.5))
            }
        }
        .frame(width: 80, height: 90)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .offset(x: CGFloat(index) * -12)
        .zIndex(Double(total - index))
    }
}

struct WeatherBadgeMini: View {
    let temperature: Double
    let condition: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 10))
            Text("\(Int(temperature))°F")
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.mist)
        .cornerRadius(12)
        .foregroundColor(Theme.textPrimary)
    }
}
