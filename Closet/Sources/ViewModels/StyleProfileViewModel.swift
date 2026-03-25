import Foundation
import SwiftUI

@Observable
final class StyleProfileViewModel {
    var profile: StyleProfile = StyleProfile()
    var insight: String = "Start adding clothes to discover your style."
    var isLoading = false

    @MainActor
    func recomputeProfile(items: [ClothingItem], outfits: [Outfit]) async {
        isLoading = true
        profile = await StyleProfileService.shared.computeProfile(items: items, outfits: outfits)
        insight = await StyleProfileService.shared.generateInsight(profile: profile)
        isLoading = false
    }
}
