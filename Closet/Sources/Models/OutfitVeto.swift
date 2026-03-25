import Foundation

struct OutfitVeto: Identifiable, Codable, Equatable {
    let id: UUID
    let outfitId: UUID
    let reason: VetoReason
    let createdAt: Date

    init(
        id: UUID = UUID(),
        outfitId: UUID,
        reason: VetoReason,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.outfitId = outfitId
        self.reason = reason
        self.createdAt = createdAt
    }
}

enum VetoReason: String, CaseIterable, Codable, Identifiable {
    case tooFormal = "Too formal"
    case tooCasual = "Too casual"
    case wrongWeather = "Wrong for weather"
    case notMyStyle = "Not my style"
    case dontLikeColors = "Don't like the colors"
    case uncomfortable = "Looks uncomfortable"
    case tooLoud = "Too loud/bold"
    case repeated = "Too similar to recent looks"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tooFormal: return "figure.formalwear"
        case .tooCasual: return "figure.casual"
        case .wrongWeather: return "cloud.sun"
        case .notMyStyle: return "hand.thumbsdown"
        case .dontLikeColors: return "paintpalette"
        case .uncomfortable: return "figure.stand"
        case .tooLoud: return "speaker.wave.3"
        case .repeated: return "arrow.triangle.2.circlepath"
        }
    }
}
