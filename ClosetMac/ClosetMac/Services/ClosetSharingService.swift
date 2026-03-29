import Foundation
import AppKit
import CoreImage

/// R12: Closet Sharing Service
/// Handles shared closets with partners and item borrowing
@MainActor
final class ClosetSharingService: ObservableObject {
    static let shared = ClosetSharingService()

    @Published var sharedClosets: [SharedCloset] = []
    @Published var pendingInvitations: [ShareInvitation] = []

    private let fileManager = FileManager.default
    private var sharingDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("Closet", isDirectory: true)
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        return appSupport.appendingPathComponent("sharing", isDirectory: true)
    }

    private var sharingDataURL: URL {
        sharingDirectory.appendingPathComponent("sharing_data.json")
    }

    init() {
        loadSharingData()
    }

    // MARK: - Shared Closet

    func shareWithPartner(email: String) {
        let invitation = ShareInvitation(
            id: UUID(),
            email: email,
            status: .pending,
            createdAt: Date()
        )
        pendingInvitations.append(invitation)
        persistSharingData()
    }

    func acceptInvitation(_ invitation: ShareInvitation) {
        if let index = pendingInvitations.firstIndex(where: { $0.id == invitation.id }) {
            pendingInvitations[index].status = .accepted
        }
        let sharedCloset = SharedCloset(
            id: UUID(),
            partnerName: invitation.email,
            sharedItems: []
        )
        sharedClosets.append(sharedCloset)
        persistSharingData()
    }

    func removePartner(from closet: SharedCloset) {
        sharedClosets.removeAll { $0.id == closet.id }
        persistSharingData()
    }

    func getSharedClosets() -> [SharedCloset] {
        return sharedClosets
    }

    // MARK: - Borrowing

    func borrowItem(itemId: UUID, from partnerName: String, until date: Date) {
        let borrowing = BorrowedItem(
            id: UUID(),
            itemId: itemId,
            borrowerName: "Me",
            lenderName: partnerName,
            borrowedUntil: date,
            borrowedAt: Date()
        )
        persistSharingData()
    }

    func returnItem(borrowingId: UUID) {
        persistSharingData()
    }

    // MARK: - Share Link

    func generateShareLink() -> URL? {
        // In production this would create a CloudKit deep link
        // For now, generates a local placeholder
        return URL(string: "closet://share/\(UUID().uuidString)")
    }

    func generateQRCode(for url: URL) -> Data? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = url.absoluteString.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: 300, height: 300))
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
    }

    // MARK: - Persistence

    private func loadSharingData() {
        guard let data = try? Data(contentsOf: sharingDataURL),
              let saved = try? JSONDecoder().decode(SavedSharingData.self, from: data) else {
            return
        }
        sharedClosets = saved.sharedClosets
        pendingInvitations = saved.pendingInvitations
    }

    private func persistSharingData() {
        let data = SavedSharingData(
            sharedClosets: sharedClosets,
            pendingInvitations: pendingInvitations
        )
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: sharingDataURL)
    }
}

// MARK: - Models

struct SharedCloset: Identifiable, Codable {
    let id: UUID
    var partnerName: String
    var sharedItems: [ClothingItem]
    var createdAt: Date = Date()
}

struct ShareInvitation: Identifiable, Codable {
    let id: UUID
    var email: String
    var status: InvitationStatus
    var createdAt: Date
}

enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct BorrowedItem: Identifiable, Codable {
    let id: UUID
    let itemId: UUID
    let borrowerName: String
    let lenderName: String
    let borrowedUntil: Date
    let borrowedAt: Date
}

struct SavedSharingData: Codable {
    var sharedClosets: [SharedCloset]
    var pendingInvitations: [ShareInvitation]
}
