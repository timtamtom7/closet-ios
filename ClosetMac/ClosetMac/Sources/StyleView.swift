import SwiftUI

/// R11: Style tab — combines Weather-Aware Styling + Wardrobe Insights
struct StyleView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var selectedSubTab: StyleSubTab = .weather

    enum StyleSubTab: String, CaseIterable {
        case weather = "Weather"
        case insights = "Insights"
        case share = "Share"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sub-tab bar
            HStack(spacing: 0) {
                ForEach(StyleSubTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSubTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedSubTab == tab ? Theme.textPrimary : Theme.slate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedSubTab == tab ? Theme.warmBeige : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .background(Theme.surface)

            Divider()

            // Content
            TabView(selection: $selectedSubTab) {
                WeatherStylingView(dataService: dataService)
                    .tag(StyleSubTab.weather)

                WardrobeInsightsView(dataService: dataService)
                    .tag(StyleSubTab.insights)

                StyleProfileShareView(dataService: dataService)
                    .tag(StyleSubTab.share)
            }
            .tabViewStyle(.automatic)
        }
    }
}

/// R12: Style Profile Sharing View
struct StyleProfileShareView: View {
    @ObservedObject var dataService: ClosetDataService
    @StateObject private var sharingService = ClosetSharingService.shared
    @State private var showingInviteSheet = false
    @State private var inviteEmail = ""
    @State private var copiedMessage = false

    var styleDescription: String {
        let profile = dataService.styleProfile
        var parts: [String] = []

        if profile.neutralColorRatio > 0.6 {
            parts.append("Neutral Tones")
        } else if profile.neutralColorRatio > 0.3 {
            parts.append("Mixed Palette")
        } else {
            parts.append("Colorful")
        }

        if profile.fittedRatio > 0.5 {
            parts.append("Fitted")
        } else if profile.fittedRatio > 0.2 {
            parts.append("Balanced Fit")
        } else {
            parts.append("Relaxed")
        }

        if let topTag = profile.topTags.sorted(by: { $0.value > $1.value }).first {
            parts.append(topTag.key.capitalized)
        }

        return parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // My Style Profile Card
                myStyleCard

                // Share Options
                shareOptionsSection

                // Partner's Style (if shared closet exists)
                if !sharingService.sharedClosets.isEmpty {
                    partnerStyleSection
                }

                // Invite Partner
                inviteSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $showingInviteSheet) {
            invitePartnerSheet
        }
    }

    // MARK: - My Style Card

    private var myStyleCard: some View {
        VStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.blush.opacity(0.2))
                    .frame(width: 64, height: 64)

                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.blush)
            }

            // Style Label
            VStack(spacing: 4) {
                Text("My Style Profile")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.slate)

                Text(styleDescription)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Quick Stats
            HStack(spacing: 0) {
                miniStat(value: "\(dataService.styleProfile.totalItems)", label: "Items")
                Spacer()
                miniStat(value: "\(dataService.styleProfile.totalOutfits)", label: "Outfits")
                Spacer()
                let topCat = dataService.clothingItems.isEmpty ? "—" : topCategory
                miniStat(value: topCat, label: "Top Cat")
            }
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private var topCategory: String {
        let counts = Dictionary(grouping: dataService.clothingItems, by: { $0.category })
            .mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key.rawValue ?? "—"
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.slate)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Share Options

    private var shareOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share My Style")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            VStack(spacing: 8) {
                shareOptionRow(icon: "gift", title: "Gift Ideas", subtitle: "Share with partner for gift inspiration") {
                    shareForGifts()
                }

                shareOptionRow(icon: "square.and.arrow.up", title: "Export Card", subtitle: "Shareable style stats image") {
                    shareStyleCard()
                }

                shareOptionRow(icon: "link", title: "Copy Share Link", subtitle: "Share your style profile link") {
                    copyShareLink()
                }
            }
        }
    }

    private func shareOptionRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.blush)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.slate)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate.opacity(0.5))
            }
            .padding(12)
            .background(Theme.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Partner Style

    private var partnerStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Partner's Style")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            ForEach(sharingService.sharedClosets) { closet in
                partnerStyleCard(closet)
            }
        }
    }

    private func partnerStyleCard(_ closet: SharedCloset) -> some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Theme.sage.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(String(closet.partnerName.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.sage)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(closet.partnerName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)

                    Text("\(closet.sharedItems.count) shared items")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.slate)
                }

                Spacer()

                Button {
                    sharingService.removePartner(from: closet)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.slate.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            if !closet.sharedItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -8) {
                        ForEach(closet.sharedItems.prefix(5)) { item in
                            sharedItemThumbnail(item)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }

    private func sharedItemThumbnail(_ item: ClothingItem) -> some View {
        ZStack {
            if let image = ClosetDataService.shared.loadImage(named: item.imagePath) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.mist)
                    .frame(width: 60, height: 60)

                Image(systemName: item.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.slate.opacity(0.5))
            }
        }
        .frame(width: 60, height: 60)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    // MARK: - Invite

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invite Partner")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.slate)

            Button {
                showingInviteSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Partner")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.blush)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Invite Sheet

    private var invitePartnerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    showingInviteSheet = false
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.slate)

                Spacer()

                Text("Invite Partner")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Button("Send") {
                    sharingService.shareWithPartner(email: inviteEmail)
                    showingInviteSheet = false
                    inviteEmail = ""
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.blush)
                .disabled(inviteEmail.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.surface)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // QR Code
                    if let url = sharingService.generateShareLink(),
                       let qrData = sharingService.generateQRCode(for: url) {
                        VStack(spacing: 10) {
                            Image(nsImage: NSImage(data: qrData)!)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 140, height: 140)
                                .cornerRadius(8)

                            Text("Scan to connect")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.slate)
                        }
                        .padding(.vertical, 8)
                    }

                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or share via email")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.slate)

                        TextField("partner@email.com", text: $inviteEmail)
                            .font(.system(size: 14))
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Theme.surface)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(width: 320, height: 380)
        .background(Theme.warmBeige)
    }

    // MARK: - Actions

    private func shareForGifts() {
        let text = """
        🎁 My Style Profile

        \(styleDescription)

        Items: \(dataService.styleProfile.totalItems)
        Outfits logged: \(dataService.styleProfile.totalOutfits)

        Top category: \(topCategory)

        Shared from Closet
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func shareStyleCard() {
        let text = "My Style: \(styleDescription) · \(dataService.styleProfile.totalItems) items · Shared from Closet"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func copyShareLink() {
        if let url = sharingService.generateShareLink() {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
        }
    }
}
