import SwiftUI

struct MonthlyTrendView: View {
    let report: MonthlyTrendService.MonthlyReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection

                    if !report.colorTrends.isEmpty {
                        colorTrendSection
                    }

                    if let dominantChange = report.dominantColorChange {
                        dominantColorHighlight(change: dominantChange)
                    }

                    if !report.styleShifts.isEmpty {
                        styleShiftsSection
                    }

                    aiSuggestionSection

                    monthlyStatsSection
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Monthly Trends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            Text("Your Month in Style")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text(monthYearString())
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
        }
        .padding(.horizontal, 20)
    }

    private var colorTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Color Evolution")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                Spacer()
            }

            Text("How your color choices shifted this month")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#6E6E73"))

            ForEach(report.colorTrends.prefix(5)) { trend in
                ColorTrendRow(trend: trend)
            }
        }
        .padding(.horizontal, 20)
    }

    private func dominantColorHighlight(change: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Spotlight")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                Spacer()
            }

            Text(change)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FFFFFF"), Color(hex: "#FAFAF8")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private var styleShiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Style Shifts")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                Spacer()
            }

            ForEach(report.styleShifts, id: \.self) { shift in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#B8A898"))
                        .padding(.top, 2)

                    Text(shift)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private var aiSuggestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("AI Suggestion")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            Text(report.aiSuggestion)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private var monthlyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "number")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("This Month")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                Spacer()
            }

            HStack(spacing: 20) {
                MonthlyStatPill(
                    value: "\(report.thisMonthItems.count)",
                    label: "items added",
                    icon: "tshirt"
                )

                MonthlyStatPill(
                    value: "\(report.thisMonthOutfits.count)",
                    label: "outfits logged",
                    icon: "sparkles"
                )

                MonthlyStatPill(
                    value: "\(report.colorTrends.filter { $0.isNew }.count)",
                    label: "new colors",
                    icon: "paintpalette"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private var gradientColors: [Color] {
        let activeTrends = report.colorTrends.prefix(3)
        return activeTrends.map { Color(hex: $0.hex) }
    }

    private func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

struct ColorTrendRow: View {
    let trend: MonthlyTrendService.MonthlyColorTrend

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: trend.hex))
                .frame(width: 36, height: 36)
                .overlay {
                    Circle()
                        .stroke(Color(hex: "#E8E8E6"), lineWidth: 1.5)
                }
                .shadow(color: Color(hex: trend.hex).opacity(0.3), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(trend.colorName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                HStack(spacing: 4) {
                    Text("\(Int(trend.thisMonthPercent * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1C1C1E"))

                    Text("this month")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    if trend.lastMonthCount > 0 {
                        Text("· \(Int(trend.lastMonthPercent * 100))% last month")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    } else if trend.isNew {
                        Text("· new this month!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#B8A898"))
                    }
                }
            }

            Spacer()

            if trend.thisMonthCount > 0 {
                changeIndicator
            }
        }
        .padding(12)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var changeIndicator: some View {
        HStack(spacing: 2) {
            if trend.isIncrease {
                Image(systemName: "arrow.up")
                    .font(.system(size: 11, weight: .bold))
                Text("\(Int(trend.changePercent))%")
                    .font(.system(size: 12, weight: .semibold))
            } else if trend.isFading {
                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .bold))
                Text("\(Int(trend.changePercent))%")
                    .font(.system(size: 12, weight: .semibold))
            } else {
                Image(systemName: "equal")
                    .font(.system(size: 11))
                Text("—")
                    .font(.system(size: 12))
            }
        }
        .foregroundStyle(trend.isIncrease ? Color(hex: "#1166AA") : (trend.isFading ? Color(hex: "#C45C4A") : Color(hex: "#6E6E73")))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (trend.isIncrease ? Color(hex: "#1166AA") : (trend.isFading ? Color(hex: "#C45C4A") : Color(hex: "#6E6E73")))
                .opacity(0.1)
        )
        .clipShape(Capsule())
    }
}

struct MonthlyStatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#6E6E73"))
        }
        .frame(maxWidth: .infinity)
    }
}

import SwiftUI

@Observable
final class MonthlyTrendViewModel {
    var report: MonthlyTrendService.MonthlyReport?
    var isLoading = false

    @MainActor
    func loadReport(items: [ClothingItem], outfits: [Outfit]) async {
        isLoading = true
        report = await MonthlyTrendService.shared.generateMonthlyReport(items: items, outfits: outfits)
        isLoading = false
    }
}
