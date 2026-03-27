import SwiftUI

struct WhyNotSheet: View {
    let outfit: Outfit
    let onVeto: (VetoReason) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Why not this outfit?")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.closetPrimaryText)
                        .padding(.top, 8)

                    Text("Help the AI learn your preferences")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.closetSecondaryText)

                    VStack(spacing: 10) {
                        ForEach(VetoReason.allCases) { reason in
                            Button {
                                ClosetHaptics.light()
                                onVeto(reason)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: reason.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.closetAccent)
                                        .frame(width: 28)

                                    Text(reason.rawValue)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.closetPrimaryText)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.closetDivider)
                                }
                                .padding(16)
                                .background(Color.closetSurface)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Skip for reason: \(reason.rawValue)")
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.closetBackground)
            .navigationTitle("Skip Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        ClosetHaptics.light()
                        dismiss()
                    }
                    .foregroundStyle(Color.closetSecondaryText)
                }
            }
        }
    }
}

struct OutfitScoreSheet: View {
    let outfit: Outfit
    let onRate: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedScore: Int?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Rate this outfit")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.closetPrimaryText)
                    .padding(.top, 16)

                Text("How much do you love this look?")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.closetSecondaryText)

                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { score in
                        Button {
                            ClosetHaptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedScore = score
                            }
                        } label: {
                            Image(systemName: (selectedScore ?? 0) >= score ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle((selectedScore ?? 0) >= score ? Color.closetAccent : Color.closetDivider)
                                .scaleEffect(selectedScore == score ? 1.2 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(score) star\(score == 1 ? "" : "s")")
                    }
                }
                .padding(.vertical, 8)

                if let score = selectedScore {
                    Text(scoreLabel(for: score))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.closetSecondaryText)
                        .transition(.opacity)
                }

                Spacer()

                Button {
                    if let score = selectedScore {
                        ClosetHaptics.success()
                        onRate(score)
                        dismiss()
                    }
                } label: {
                    Text("Save Rating")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedScore != nil ? Color.closetPrimaryText : Color.closetDivider)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                }
                .disabled(selectedScore == nil)
                .accessibilityLabel("Save rating")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .background(Color.closetBackground)
            .navigationTitle("Rate Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        ClosetHaptics.light()
                        dismiss()
                    }
                    .foregroundStyle(Color.closetSecondaryText)
                }
            }
        }
    }

    private func scoreLabel(for score: Int) -> String {
        switch score {
        case 1: return "Not for me"
        case 2: return "Could work"
        case 3: return "Pretty good"
        case 4: return "Really like it"
        case 5: return "Love it!"
        default: return ""
        }
    }
}

struct TrendInsightsView: View {
    let insights: [OutfitEvolutionService.TrendInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.closetAccent)
                Text("Style Insights")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.closetPrimaryText)
            }

            ForEach(insights, id: \.message) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color.closetAccent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text(insight.message)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.closetSecondaryText)
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.closetSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

struct TemperatureLayeringView: View {
    let suggestions: [String]
    let temperature: Double

    private var temperatureColor: Color {
        if temperature < 10 { return Color(hex: "#1166AA") }
        if temperature < 15 { return Color.closetSecondaryText }
        if temperature < 25 { return Color.closetAccent }
        return Color.closetError
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: temperature < 15 ? "thermometer.snowflake" : (temperature > 25 ? "thermometer.sun" : "thermometer.medium"))
                    .font(.system(size: 16))
                    .foregroundStyle(temperatureColor)

                Text("Layering Tips")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.closetPrimaryText)
            }

            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.closetAccent)
                        .padding(.top, 1)

                    Text(suggestion)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.closetSecondaryText)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.closetSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

struct SeasonTransitionView: View {
    let forecasts: [WeatherService.DayForecast]
    let items: [ClothingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.closetAccent)
                Text("Upcoming Weather")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.closetPrimaryText)
            }

            if forecasts.isEmpty {
                Text("No forecast available")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.closetSecondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(forecasts) { day in
                            VStack(spacing: 6) {
                                Text(dayName(from: day.date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.closetSecondaryText)

                                Image(systemName: day.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.closetAccent)

                                Text("\(Int(day.avgTemp))°")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.closetPrimaryText)
                            }
                            .frame(width: 60)
                            .padding(.vertical, 12)
                            .background(Color.closetBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                        }
                    }
                }

                if let coldDay = forecasts.first(where: { $0.avgTemp < 12 }) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.closetError)

                        Text("Cold snap ahead (\(Int(coldDay.avgTemp))° on \(dayName(from: coldDay.date))). Pull forward your warmest pieces.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.closetSecondaryText)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.closetSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private func dayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
