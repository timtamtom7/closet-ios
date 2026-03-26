import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "Free"
    case pro = "Pro"
    case stylist = "Stylist"

    var displayName: String { rawValue }

    var maxItems: Int? { nil } // nil = unlimited
    var maxOutfits: Int? { nil }
    var maxTravelPlans: Int? { nil }

    var hasUnlimitedItems: Bool { maxItems == nil }
    var hasUnlimitedOutfits: Bool { maxOutfits == nil }

    var features: [String] {
        switch self {
        case .free:
            return [
                "20 wardrobe items",
                "10 saved outfits",
                "Color palette analysis",
                "Basic style profile"
            ]
        case .pro:
            return [
                "Unlimited wardrobe items",
                "Unlimited outfits",
                "AI outfit generation",
                "Color trend analysis",
                "Monthly style insights",
                "Travel packing lists",
                "Export wardrobe data"
            ]
        case .stylist:
            return [
                "Everything in Pro",
                "Personal stylist consultation",
                "Custom lookbooks",
                "Shopping guidance",
                "Priority support"
            ]
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$9.99/mo"
        case .stylist: return "$24.99/mo"
        }
    }
}

actor SubscriptionService {
    static let shared = SubscriptionService()

    static let freeItemLimit = 20
    static let freeOutfitLimit = 10

    private init() {}

    @MainActor
    private var _currentTier: SubscriptionTier = .free

    @MainActor
    var currentTier: SubscriptionTier {
        get { _currentTier }
        set { _currentTier = newValue }
    }

    @MainActor
    func loadSubscription() async {
        let defaults = UserDefaults.standard
        if let tierRaw = defaults.string(forKey: "subscriptionTier"),
           let tier = SubscriptionTier(rawValue: tierRaw) {
            _currentTier = tier
        } else {
            _currentTier = .free
        }
    }

    @MainActor
    func setTier(_ tier: SubscriptionTier) async {
        _currentTier = tier
        let defaults = UserDefaults.standard
        defaults.set(tier.rawValue, forKey: "subscriptionTier")
    }

    @MainActor
    func canAddItem(currentCount: Int) -> (allowed: Bool, reason: String?) {
        switch _currentTier {
        case .free:
            if currentCount >= Self.freeItemLimit {
                return (false, "Upgrade to Pro for unlimited wardrobe items")
            }
        case .pro, .stylist:
            break
        }
        return (true, nil)
    }

    @MainActor
    func canAddOutfit(currentCount: Int) -> (allowed: Bool, reason: String?) {
        switch _currentTier {
        case .free:
            if currentCount >= Self.freeOutfitLimit {
                return (false, "Upgrade to Pro for unlimited outfits")
            }
        case .pro, .stylist:
            break
        }
        return (true, nil)
    }

    @MainActor
    func remainingItems(currentCount: Int) -> Int {
        switch _currentTier {
        case .free:
            return max(0, Self.freeItemLimit - currentCount)
        case .pro, .stylist:
            return Int.max
        }
    }

    @MainActor
    func remainingOutfits(currentCount: Int) -> Int {
        switch _currentTier {
        case .free:
            return max(0, Self.freeOutfitLimit - currentCount)
        case .pro, .stylist:
            return Int.max
        }
    }
}
