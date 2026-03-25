import Foundation

@Observable
final class ColorPaletteViewModel {
    var analysis: ColorPaletteAnalysisService.PaletteAnalysis = ColorPaletteAnalysisService.PaletteAnalysis(
        dominantColors: [],
        neutralColors: [],
        accentColors: [],
        warmColors: [],
        coolColors: [],
        colorTemperature: .neutral,
        paletteHarmony: .neutral,
        suggestedPalettes: [],
        missingColors: []
    )
    var isLoading = false

    @MainActor
    func analyzePalette(items: [ClothingItem]) async {
        isLoading = true
        analysis = await ColorPaletteAnalysisService.shared.analyzePalette(items: items)
        isLoading = false
    }
}
