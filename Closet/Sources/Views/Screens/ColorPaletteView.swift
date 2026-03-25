import SwiftUI

struct ColorPaletteView: View {
    @State private var viewModel = ColorPaletteViewModel()
    @State private var wardrobeViewModel = WardrobeViewModel()
    @State private var selectedColor: ColorPaletteAnalysisService.ColorInfo?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else {
                        paletteHeader

                        if !viewModel.analysis.dominantColors.isEmpty {
                            dominantColorsSection
                            paletteBreakdownSection
                            harmonySection
                            if !viewModel.analysis.suggestedPalettes.isEmpty {
                                suggestionsSection
                            }
                            if !viewModel.analysis.missingColors.isEmpty {
                                missingColorsSection
                            }
                        } else {
                            emptyState
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Color Palette")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedColor) { color in
                ColorDetailSheet(color: color)
            }
            .task {
                await wardrobeViewModel.loadItems()
                await viewModel.analyzePalette(items: wardrobeViewModel.items)
            }
            .onChange(of: wardrobeViewModel.items.count) { _, _ in
                Task {
                    await viewModel.analyzePalette(items: wardrobeViewModel.items)
                }
            }
        }
    }

    private var paletteHeader: some View {
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

                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            Text("Your Color Story")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("\(viewModel.analysis.dominantColors.count) colors across \(wardrobeViewModel.items.count) items")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
        }
        .padding(.horizontal, 20)
    }

    private var dominantColorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintpalette")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Dominant Colors")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            Text("\(Int(viewModel.analysis.dominantColors.first?.percentage ?? 0 * 100))% \(viewModel.analysis.dominantColors.first?.name ?? "") — your signature hue")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#6E6E73"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.analysis.dominantColors) { color in
                        ColorSwatchCard(color: color) {
                            selectedColor = color
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var paletteBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Palette Breakdown")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            VStack(spacing: 10) {
                PaletteBreakdownRow(
                    label: "Neutral",
                    colors: viewModel.analysis.neutralColors,
                    temperature: .neutral
                )
                PaletteBreakdownRow(
                    label: "Warm",
                    colors: viewModel.analysis.warmColors,
                    temperature: .warm
                )
                PaletteBreakdownRow(
                    label: "Cool",
                    colors: viewModel.analysis.coolColors,
                    temperature: .cool
                )
                PaletteBreakdownRow(
                    label: "Accent",
                    colors: viewModel.analysis.accentColors,
                    temperature: .accent
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private var harmonySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Palette Profile")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            HStack(spacing: 16) {
                PaletteProfileCard(
                    title: "Temperature",
                    value: viewModel.analysis.colorTemperature.rawValue,
                    icon: temperatureIcon,
                    color: temperatureColor
                )

                PaletteProfileCard(
                    title: "Harmony",
                    value: viewModel.analysis.paletteHarmony.rawValue,
                    icon: "circle.hexagongrid",
                    color: Color(hex: "#B8A898")
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Style Suggestions")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            ForEach(viewModel.analysis.suggestedPalettes, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#B8A898"))
                        .padding(.top, 1)

                    Text(suggestion)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                        .lineSpacing(2)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var missingColorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))
                Text("Consider Adding")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
            }

            Text("These versatile colors would expand your outfit combinations")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#6E6E73"))

            FlowLayout(spacing: 8) {
                ForEach(viewModel.analysis.missingColors, id: \.self) { color in
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text(color)
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FFFFFF"))
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "#1C1C1E").opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ClosetEmptyIllustration(size: 160)

            Text("No colors to analyze yet")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Add clothing items to discover your wardrobe's color story")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
    }

    private var gradientColors: [Color] {
        let top = viewModel.analysis.dominantColors.prefix(3)
        return top.map { Color(hex: $0.hex) }
    }

    private var temperatureIcon: String {
        switch viewModel.analysis.colorTemperature {
        case .warm: return "sun.max.fill"
        case .cool: return "snowflake"
        case .neutral: return "circle.lefthalf.filled"
        case .mixed: return "circle.hexagongrid"
        }
    }

    private var temperatureColor: Color {
        switch viewModel.analysis.colorTemperature {
        case .warm: return Color(hex: "#C45C4A")
        case .cool: return Color(hex: "#1166AA")
        case .neutral: return Color(hex: "#808080")
        case .mixed: return Color(hex: "#B8A898")
        }
    }
}

struct ColorSwatchCard: View {
    let color: ColorPaletteAnalysisService.ColorInfo
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: color.hex))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Circle()
                            .stroke(Color(hex: "#E8E8E6"), lineWidth: 2)
                    }
                    .shadow(color: Color(hex: color.hex).opacity(0.3), radius: 6, x: 0, y: 3)

                Text(color.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .lineLimit(1)

                Text("\(Int(color.percentage * 100))%")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

struct PaletteBreakdownRow: View {
    let label: String
    let colors: [ColorPaletteAnalysisService.ColorInfo]
    let temperature: ColorPaletteAnalysisService.ColorInfo.ColorCategory

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .frame(width: 60, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(colors.prefix(5)) { color in
                    Circle()
                        .fill(Color(hex: color.hex))
                        .frame(width: 20, height: 20)
                        .overlay {
                            Circle()
                                .stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                        }
                }

                if colors.count > 5 {
                    Text("+\(colors.count - 5)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }

                if colors.isEmpty {
                    Text("—")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#E8E8E6"))
                }
            }

            Spacer()

            if !colors.isEmpty {
                Text("\(Int(colors.reduce(0) { $0 + $1.percentage } * 100))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }
        }
        .padding(12)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PaletteProfileCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#6E6E73"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ColorDetailSheet: View {
    let color: ColorPaletteAnalysisService.ColorInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Circle()
                    .fill(Color(hex: color.hex))
                    .frame(width: 120, height: 120)
                    .shadow(color: Color(hex: color.hex).opacity(0.4), radius: 16, x: 0, y: 8)

                VStack(spacing: 8) {
                    Text(color.name)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: "#1C1C1E"))

                    Text(color.hex)
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: "#6E6E73"))

                    Text("\(color.count) item\(color.count == 1 ? "" : "s") in your wardrobe")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }

                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Color Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
    }
}


