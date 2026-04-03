import SwiftUI
import UIKit

struct OutfitCard: View {
    let outfit: Outfit
    let items: [ClothingItem]
    let onSave: () -> Void
    let onDismiss: () -> Void
    let onWhyNot: (() -> Void)?
    let onRate: (() -> Void)?

    init(
        outfit: Outfit,
        items: [ClothingItem],
        onSave: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onWhyNot: (() -> Void)? = nil,
        onRate: (() -> Void)? = nil
    ) {
        self.outfit = outfit
        self.items = items
        self.onSave = onSave
        self.onDismiss = onDismiss
        self.onWhyNot = onWhyNot
        self.onRate = onRate
    }

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var cardOpacity: Double = 1
    @State private var callbacks = OutfitCardCallbacks()
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        cardContent
            .padding(20)
            .background(ClosetDesign.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.card))
            .shadow(color: ClosetDesign.Colors.primaryText.opacity(0.08), radius: 20, x: 0, y: 8)
            .offset(x: offset)
            .opacity(opacity * cardOpacity)
            .rotationEffect(.degrees(rotation))
            .onAppear { callbacks.onSave = onSave; callbacks.onDismiss = onDismiss }
            .cardAccessibility(outfit: outfit, callbacks: callbacks)
            .gesture(dragGesture)
    }

    private var cardContent: some View {
        VStack(spacing: 16) {
            thumbnailStack
            outfitInfo
            actionButtons
        }
    }

    private var thumbnailStack: some View {
        ZStack {
            HStack(spacing: -16) {
                ForEach(Array(outfit.itemIds.prefix(3).enumerated()), id: \.offset) { index, itemId in
                    if let item = items.first(where: { $0.id == itemId }) {
                        OutfitItemThumbnail(item: item)
                            .zIndex(Double(3 - index))
                            .offset(x: -8 * CGFloat(index))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.image))
    }

    private var outfitInfo: some View {
        VStack(spacing: 6) {
            Text(outfit.name)
                .font(ClosetDesign.Typography.bodyMedium)
                .foregroundStyle(ClosetDesign.Colors.primaryText)

            HStack(spacing: 8) {
                Label(outfit.eventType.rawValue, systemImage: outfit.eventType.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)

                Text("·")
                    .foregroundStyle(ClosetDesign.Colors.divider)

                Label(outfit.weather, systemImage: "cloud.sun.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)

                if let temp = outfit.temperature {
                    Text("·")
                        .foregroundStyle(ClosetDesign.Colors.divider)
                    Text("\(Int(temp))°C")
                        .font(.system(size: 12))
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if onWhyNot != nil || onRate != nil {
            fullActionButtons
        } else {
            simpleActionButtons
        }
    }

    private var fullActionButtons: some View {
        HStack(spacing: 24) {
            whyNotButton
            dismissButton
            rateButton
            saveButton
        }
    }

    private var simpleActionButtons: some View {
        HStack(spacing: 32) {
            Button {
                performDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(ClosetDesign.Colors.divider)
            }

            Button {
                performSave()
            } label: {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(ClosetDesign.Colors.accent)
            }
        }
    }

    private var whyNotButton: some View {
        Button {
            let selection = UISelectionFeedbackGenerator()
            selection.selectionChanged()
            onWhyNot?()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "hand.thumbsdown.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                Text("Why not?")
                    .font(.system(size: 11))
                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
            }
        }
    }

    private var dismissButton: some View {
        Button {
            performDismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(ClosetDesign.Colors.divider)
        }
    }

    @ViewBuilder
    private var rateButton: some View {
        if let onRate = onRate {
            Button {
                let selection = UISelectionFeedbackGenerator()
                selection.selectionChanged()
                onRate()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(ClosetDesign.Colors.accent)
                    Text("Rate")
                        .font(.system(size: 11))
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            performSave()
        } label: {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(ClosetDesign.Colors.accent)
        }
    }

    private func performDismiss() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
            offset = -300
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }

    private func performSave() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
            offset = 0
            opacity = 1
        }
        onSave()
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
                rotation = Double(value.translation.width / 20)
                cardOpacity = 1.0 - abs(value.translation.width) / 400
            }
            .onEnded { value in
                if value.translation.width < -100 {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                        offset = -300
                        opacity = 0
                        rotation = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                } else if value.translation.width > 100 {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    offset = 0
                    rotation = 0
                    cardOpacity = 1
                    onSave()
                } else {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                        offset = 0
                        rotation = 0
                        cardOpacity = 1
                    }
                }
            }
    }
}

struct OutfitItemThumbnail: View {
    let item: ClothingItem
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(hex: "#E8E8E6"))
                    .overlay {
                        Image(systemName: item.category.icon)
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .frame(width: 140, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}

// MARK: - Accessibility Modifier

final class OutfitCardCallbacks: @unchecked Sendable {
    var onSave: (() -> Void)?
    var onDismiss: (() -> Void)?
}

private struct CardAccessibility: ViewModifier {
    let outfit: Outfit
    let callbacks: OutfitCardCallbacks

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(outfit.name), \(outfit.eventType.rawValue)")
            .accessibilityHint("Swipe left to dismiss, right to save.")
            .accessibilityAction(named: "Save") { [weak callbacks] in
                callbacks?.onSave?()
            }
            .accessibilityAction(named: "Dismiss") { [weak callbacks] in
                callbacks?.onDismiss?()
            }
    }
}

extension View {
    func cardAccessibility(outfit: Outfit, callbacks: OutfitCardCallbacks) -> some View {
        modifier(CardAccessibility(outfit: outfit, callbacks: callbacks))
    }
}
