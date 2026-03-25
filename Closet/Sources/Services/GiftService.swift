import Foundation

actor GiftService {
    static let shared = GiftService()

    private init() {}

    struct GiftCode: Codable {
        let code: String
        let itemIds: [UUID]
        let senderName: String
        let message: String?
        let createdAt: Date
        let expiresAt: Date

        var isExpired: Bool {
            Date() > expiresAt
        }
    }

    struct GiftRecipient: Identifiable, Codable {
        let id: UUID
        var name: String
        var email: String?
        var phone: String?
        var sentItems: [UUID]
        var giftCodes: [String]
        let addedAt: Date
    }

    private var recipients: [GiftRecipient] = []
    private let codesFile = "gift_recipients.json"

    func generateGiftCode(for itemIds: [UUID], senderName: String, message: String?, validDays: Int = 30) -> GiftCode {
        let code = generateRandomCode()
        let now = Date()
        let expiresAt = Calendar.current.date(byAdding: .day, value: validDays, to: now)!

        return GiftCode(
            code: code,
            itemIds: itemIds,
            senderName: senderName,
            message: message,
            createdAt: now,
            expiresAt: expiresAt
        )
    }

    private func generateRandomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }

    func saveRecipient(_ recipient: GiftRecipient) async {
        if let index = recipients.firstIndex(where: { $0.id == recipient.id }) {
            recipients[index] = recipient
        } else {
            recipients.append(recipient)
        }
        await persistRecipients()
    }

    func getRecipients() -> [GiftRecipient] {
        return recipients
    }

    func removeRecipient(_ id: UUID) async {
        recipients.removeAll { $0.id == id }
        await persistRecipients()
    }

    private func persistRecipients() async {
        // In a real app, this would save to UserDefaults or a database
        // For now, we keep it in memory
    }

    func loadRecipients() async {
        // Load from persisted storage
    }

    func redeemGiftCode(_ code: String) async -> GiftCode? {
        // In a real app, this would verify against a server
        // For now, return nil
        return nil
    }
}
