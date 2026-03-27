import SwiftUI
import UIKit

// MARK: - Theme.swift
// iOS 26 Liquid Glass Design System for Closet
// Design tokens and shared styles

// MARK: - Corner Radius Tokens
enum CornerRadius {
    /// 4pt - micro elements (tags, badges)
    static let micro: CGFloat = 4
    /// 8pt - buttons, chips, small interactive elements
    static let button: CGFloat = 8
    /// 12pt - cards, list items, medium containers
    static let card: CGFloat = 12
    /// 16pt - large cards, sheets, modal containers
    static let large: CGFloat = 16
    /// 20pt - outfit cards, prominent containers
    static let extraLarge: CGFloat = 20
    /// 24pt - full-bleed hero cards
    static let hero: CGFloat = 24
}

// MARK: - Color Palette
extension Color {
    static let closetBackground = Color(hex: "#FAFAF8")
    static let closetSurface = Color(hex: "#FFFFFF")
    static let closetPrimaryText = Color(hex: "#1C1C1E")
    static let closetSecondaryText = Color(hex: "#6E6E73")
    static let closetAccent = Color(hex: "#B8A898")
    static let closetAccentAlt = Color(hex: "#D4C5B5")
    static let closetDivider = Color(hex: "#E8E8E6")
    static let closetError = Color(hex: "#C45C4A")
}

// MARK: - Typography Scale (min 11pt per iOS accessibility)
enum ClosetFont {
    /// 11pt - minimum for any text element
    static let caption2: Font = .system(size: 11, weight: .regular, design: .default)
    /// 13pt - captions, secondary labels
    static let caption: Font = .system(size: 13, weight: .regular, design: .default)
    /// 14pt - body secondary
    static let footnote: Font = .system(size: 14, weight: .regular, design: .default)
    /// 15pt - body text
    static let body: Font = .system(size: 15, weight: .regular, design: .default)
    /// 16pt - body emphasis
    static let bodyMedium: Font = .system(size: 16, weight: .medium, design: .default)
    /// 17pt - body prominent
    static let bodyLarge: Font = .system(size: 17, weight: .regular, design: .default)
    /// 18pt - section headings (serif)
    static let sectionHeading: Font = .system(size: 18, weight: .semibold, design: .serif)
    /// 22pt - section titles
    static let title: Font = .system(size: 22, weight: .bold, design: .serif)
    /// 28pt - large headings
    static let titleLarge: Font = .system(size: 28, weight: .bold, design: .serif)
    /// 34pt - hero text
    static let hero: Font = .system(size: 34, weight: .bold, design: .serif)

    /// Size 12 - for inline metadata (event type, weather, temperature)
    static let metadata: Font = .system(size: 12, weight: .regular, design: .default)
    /// Size 11 - action labels on icon buttons (min compliant)
    static let actionLabel: Font = .system(size: 11, weight: .regular, design: .default)
}

// MARK: - Haptic Feedback
enum ClosetHaptics {
    /// Light impact - for UI interactions (taps, selections)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact - for confirmations (save, like)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact - for significant actions (delete, dismiss)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success notification - for completed save actions
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning notification - for destructive actions
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Selection changed - for picker/tab changes
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Button Styles

/// Primary button with accent fill
struct ClosetPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClosetFont.bodyMedium)
            .foregroundStyle(isEnabled ? Color.white : Color.closetSecondaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(isEnabled ? Color.closetAccent : Color.closetDivider)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Secondary button with outline
struct ClosetSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClosetFont.bodyMedium)
            .foregroundStyle(Color.closetPrimaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(Color.closetDivider, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Icon button for circular actions (like, dismiss, rate)
struct ClosetIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shadow Styles

extension View {
    /// Card shadow - subtle depth
    func closetCardShadow() -> some View {
        self.shadow(color: Color.closetPrimaryText.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    /// Elevated shadow - floating elements
    func closetElevatedShadow() -> some View {
        self.shadow(color: Color.closetPrimaryText.opacity(0.12), radius: 20, x: 0, y: 8)
    }

    /// Soft glow for accent elements
    func closetAccentGlow() -> some View {
        self.shadow(color: Color.closetAccent.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Accessibility Modifiers

extension View {
    /// Standard accessibility label for interactive controls
    func closetAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Accessibility for icon-only buttons
    func closetIconAccessibility(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityRemoveTraits(.isButton)
    }
}
