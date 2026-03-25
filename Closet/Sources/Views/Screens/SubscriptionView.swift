import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    let context: SubscriptionContext
    @State private var selectedTier: SubscriptionTier?

    enum SubscriptionContext {
        case itemLimit
        case outfitLimit
        case travelLimit
        case general

        var title: String {
            switch self {
            case .itemLimit: return "Wardrobe Full"
            case .outfitLimit: return "Outfit Limit Reached"
            case .travelLimit: return "Travel Plans Full"
            case .general: return "Unlock Your Wardrobe"
            }
        }

        var message: String {
            switch self {
            case .itemLimit:
                return "You've reached your 20-item limit. Upgrade to Pro for unlimited wardrobe storage."
            case .outfitLimit:
                return "You've reached your 10-outfit limit. Upgrade to Pro for unlimited outfit logging."
            case .travelLimit:
                return "Upgrade to Pro for unlimited travel packing lists."
            case .general:
                return "Get more from your wardrobe with Pro or Stylist plans."
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection

                    tiersSection

                    featuresComparison
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#B8A898").opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "#B8A898"))
            }

            Text(context.title)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text(context.message)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var tiersSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                TierCard(
                    tier: tier,
                    isSelected: selectedTier == tier,
                    onSelect: { selectedTier = tier }
                )
            }
        }
    }

    private var featuresComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Included")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(tier.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#1C1C1E"))

                        Spacer()

                        Text(tier.price)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#B8A898"))
                    }

                    ForEach(tier.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "#B8A898"))

                            Text(feature)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "#6E6E73"))
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct TierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"))
                        .frame(width: 40, height: 40)

                    Image(systemName: tier == .free ? "tag" : (tier == .pro ? "star.fill" : "person.2.fill"))
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? .white : Color(hex: "#6E6E73"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1C1C1E"))

                    Text(tier.price)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"))
            }
            .padding(16)
            .background(isSelected ? Color(hex: "#1C1C1E").opacity(0.05) : Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14).stroke(
                    isSelected ? Color(hex: "#1C1C1E") : Color(hex: "#E8E8E6"),
                    lineWidth: isSelected ? 2 : 1
                )
            }
        }
        .buttonStyle(.plain)
    }
}

struct UpgradePromptView: View {
    let message: String
    let action: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "#B8A898"))

            Text(message)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Not Now") {
                    dismiss()
                }
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#E8E8E6"))
                .clipShape(Capsule())

                Button("Upgrade") {
                    dismiss()
                    action()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#1C1C1E"))
                .clipShape(Capsule())
            }
        }
        .padding(24)
        .background(Color(hex: "#FAFAF8"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "#1C1C1E").opacity(0.1), radius: 20, x: 0, y: 10)
    }
}
