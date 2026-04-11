import SwiftUI

/// Closet Design System
/// Based on Celine lookbooks / The Row aesthetic
enum ClosetDesign {
    
    // MARK: - Colors (Semantic, Dark Mode Aware)
    
    enum Colors {
        static let background = Color("ClosetBackground") // Ivory #FAFAF8
        static let surface = Color("ClosetSurface")     // White #FFFFFF
        
        // Primary text - Charcoal #1C1C1E
        static let primaryText = Color(hex: "#1C1C1E")
        
        // Secondary text - Slate #6E6E73 (darkened for WCAG AA at small sizes)
        static let secondaryText = Color(hex: "#5A5A5E")
        
        // Tertiary text - Slate (darkened from #6E6E73 to #5A5A5E for WCAG AA at body sizes)
        static let tertiaryText = Color(hex: "#5A5A5E")
        
        // Accent - Warm Gold (use sparingly)
        static let accent = Color(hex: "#B8A898")
        static let accentMuted = Color(hex: "#8B7B6B") // darker for small text
        
        // Sand - Accent alt
        static let sand = Color(hex: "#D4C5B5")
        
        // Divider - Mist (darkened from #E8E8E6 to #C8C8C6 for visibility)
        static let divider = Color(hex: "#C8C8C6")
        
        // Error - Terracotta
        static let error = Color(hex: "#C45C4A")
        
        // MARK: - Convenience
        
        static let foreground = primaryText
        static let tint = accent

        // MARK: - Adaptive Colors (Dark Mode Support)

        static func background(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#1C1C1E") : Color(hex: "#FAFAF8")
        }

        static func surface(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#2C2C2E") : Color(hex: "#FFFFFF")
        }

        static func primaryText(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#FFFFFF") : Color(hex: "#1C1C1E")
        }

        static func tertiaryText(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "#8E8E93") : Color(hex: "#5A5A5E")
        }
    }
    
    // MARK: - Typography
    
    enum Typography {
        // Hero headings - New York serif
        static let hero = Font.system(size: 34, weight: .bold, design: .serif)
        static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .serif)
        
        // Body - SF Pro
        static let body = Font.system(size: 17, weight: .regular)
        static let bodyMedium = Font.system(size: 17, weight: .medium)
        
        // Caption/Tag - SF Pro Light, tracked
        static let caption = Font.system(size: 13, weight: .light)
        static let tag = Font.system(size: 11, weight: .medium, design: .default)
        
        // Scale
        static let heading1 = Font.system(size: 28, weight: .semibold, design: .serif)
        static let heading2 = Font.system(size: 20, weight: .semibold, design: .serif)
        static let heading3 = Font.system(size: 17, weight: .semibold)
    }
    
    // MARK: - Spacing (8pt Grid)
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 32
        static let screenMargin: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let card: CGFloat = 12
        static let button: CGFloat = 8
        static let chip: CGFloat = 16
        static let image: CGFloat = 12
        static let avatar: CGFloat = 30
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static let card = (color: Color.black.opacity(0.06), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let elevated = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(4))
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let cardSpring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.75)
        static let cardFast = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
        
        static func card(isReducedMotion: Bool) -> SwiftUI.Animation {
            isReducedMotion ? .linear(duration: 0) : cardSpring
        }
    }
}

// MARK: - View Extension Helpers

extension View {
    /// Adaptive card: surface color in light, dark surface in dark mode
    func closetCard(colorScheme: ColorScheme) -> some View {
        self
            .background(ClosetDesign.Colors.surface(for: colorScheme))
            .cornerRadius(ClosetDesign.Radius.card)
            .shadow(
                color: colorScheme == .dark ? .clear : ClosetDesign.Shadow.card.color,
                radius: colorScheme == .dark ? 0 : ClosetDesign.Shadow.card.radius,
                x: ClosetDesign.Shadow.card.x,
                y: ClosetDesign.Shadow.card.y
            )
    }
    
    /// Adaptive body text color
    func closetBody(colorScheme: ColorScheme) -> some View {
        self
            .font(ClosetDesign.Typography.body)
            .foregroundColor(ClosetDesign.Colors.primaryText(for: colorScheme))
    }
    
    /// Adaptive caption color
    func closetCaption(colorScheme: ColorScheme) -> some View {
        self
            .font(ClosetDesign.Typography.caption)
            .foregroundColor(ClosetDesign.Colors.tertiaryText(for: colorScheme))
    }
}
