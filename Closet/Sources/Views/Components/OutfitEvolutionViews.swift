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
                        .foregroundStyle(Color(hex: "#1C1C1E"))
                        .padding(.top, 8)

                    Text("Help the AI learn your preferences")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    VStack(spacing: 10) {
                        ForEach(VetoReason.allCases) { reason in
                            Button {
                                onVeto(reason)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: reason.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color(hex: "#B8A898"))
                                        .frame(width: 28)

                                    Text(reason.rawValue)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color(hex: "#1C1C1E"))

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "#E8E8E6"))
                                }
                                .padding(16)
                                .background(Color(hex: "#FFFFFF"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Skip Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
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
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .padding(.top, 16)

                Text("How much do you love this look?")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#6E6E73"))

                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { score in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedScore = score
                            }
                        } label: {
                            Image(systemName: (selectedScore ?? 0) >= score ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle((selectedScore ?? 0) >= score ? Color(hex: "#B8A898") : Color(hex: "#E8E8E6"))
                                .scaleEffect(selectedScore == score ? 1.2 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)

                if let score = selectedScore {
                    Text(scoreLabel(for: score))
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                        .transition(.opacity)
                }

                Spacer()

                Button {
                    if let score = selectedScore {
                        onRate(score)
                        dismiss()
                    }
                } label: {
                    Text("Save Rating")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedScore != nil ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(selectedScore == nil)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Rate Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
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

import SwiftUI

struct TrendInsightsView: View {
    let insights: [OutfitEvolutionService.TrendInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Style Insights")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            ForEach(insights, id: \.message) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color(hex: "#B8A898"))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text(insight.message)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TemperatureLayeringView: View {
    let suggestions: [String]
    let temperature: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: temperature < 15 ? "thermometer.snowflake" : (temperature > 25 ? "thermometer.sun" : "thermometer.medium"))
                    .font(.system(size: 16))
                    .foregroundStyle(temperatureColor)

                Text("Layering Tips")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#B8A898"))
                        .padding(.top, 1)

                    Text(suggestion)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var temperatureColor: Color {
        if temperature < 10 { return Color(hex: "#1166AA") }
        if temperature < 15 { return Color(hex: "#6E6E73") }
        if temperature < 25 { return Color(hex: "#B8A898") }
        return Color(hex: "#C45C4A")
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
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Upcoming Weather")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            if forecasts.isEmpty {
                Text("No forecast available")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(forecasts) { day in
                            VStack(spacing: 6) {
                                Text(dayName(from: day.date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: "#6E6E73"))

                                Image(systemName: day.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: "#B8A898"))

                                Text("\(Int(day.avgTemp))°")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#1C1C1E"))
                            }
                            .frame(width: 60)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#FAFAF8"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                if let coldDay = forecasts.first(where: { $0.avgTemp < 12 }) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "#C45C4A"))

                        Text("Cold snap ahead (\(Int(coldDay.avgTemp))° on \(dayName(from: coldDay.date))). Pull forward your warmest pieces.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
