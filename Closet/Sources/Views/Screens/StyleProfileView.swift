import SwiftUI

struct StyleProfileView: View {
    @State private var viewModel = StyleProfileViewModel()
    @State private var wardrobeViewModel = WardrobeViewModel()
    @State private var outfitViewModel = OutfitViewModel()
    @State private var monthlyTrendViewModel = MonthlyTrendViewModel()
    @State private var showMonthlyTrend = false
    @State private var showOutfitTimeline = false
    @State private var showConsultation = false
    @State private var showGift = false
    @State private var showExport = false
    @State private var selectedGiftItem: ClothingItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else {
                        headerSection

                        quickActionsSection

                        statsSection

                        if !viewModel.profile.topTags.isEmpty {
                            tagsSection
                        }

                        summarySection

                        moreOptionsSection
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Style Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showMonthlyTrend) {
                if let report = monthlyTrendViewModel.report {
                    MonthlyTrendView(report: report)
                }
            }
            .sheet(isPresented: $showOutfitTimeline) {
                OutfitTimelineView(outfits: outfitViewModel.outfits, items: wardrobeViewModel.items)
            }
            .sheet(isPresented: $showConsultation) {
                StyleConsultationView()
            }
            .sheet(isPresented: $showGift) {
                GiftView(item: selectedGiftItem) { recipientName, message, itemId in
                    let itemIds = itemId.flatMap { UUID(uuidString: $0) }.map { [$0] } ?? []
                    let code = await GiftService.shared.generateGiftCode(
                        for: itemIds,
                        senderName: "You",
                        message: message.isEmpty ? nil : message
                    )
                    return code.code
                }
            }
            .sheet(isPresented: $showExport) {
                ExportView(
                    items: wardrobeViewModel.items,
                    outfits: outfitViewModel.outfits,
                    styleProfile: viewModel.profile
                )
            }
            .task {
                await wardrobeViewModel.loadItems()
                await outfitViewModel.loadOutfits()
                await viewModel.recomputeProfile(items: wardrobeViewModel.items, outfits: outfitViewModel.outfits)
                await monthlyTrendViewModel.loadReport(items: wardrobeViewModel.items, outfits: outfitViewModel.outfits)
            }
            .onChange(of: wardrobeViewModel.items.count) { _, _ in
                Task {
                    await viewModel.recomputeProfile(items: wardrobeViewModel.items, outfits: outfitViewModel.outfits)
                    await monthlyTrendViewModel.loadReport(items: wardrobeViewModel.items, outfits: outfitViewModel.outfits)
                }
            }
            .onChange(of: outfitViewModel.outfits.count) { _, _ in
                Task {
                    await viewModel.recomputeProfile(items: wardrobeViewModel.items, outfits: outfitViewModel.outfits)
                    await monthlyTrendViewModel.loadReport(items: wardrobeViewModel.items, outfits: outfitViewModel.outfits)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button {
                showMonthlyTrend = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                    Text("Monthly Trends")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(Capsule())
                .shadow(color: Color(hex: "#1C1C1E").opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            Button {
                showOutfitTimeline = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text("Timeline")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(Capsule())
                .shadow(color: Color(hex: "#1C1C1E").opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#B8A898"))

            Text("Your Style Profile")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Updated from \(viewModel.profile.totalItems) items and \(viewModel.profile.totalOutfits) outfits")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
        }
        .padding(.horizontal, 20)
    }

    private var statsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StyleStatCard(
                    title: "Neutral Tones",
                    value: "\(Int(viewModel.profile.neutralColorRatio * 100))%",
                    subtitle: viewModel.profile.neutralColorRatio > 0.6 ? "Classic palette" : "Colorful vibe",
                    progress: viewModel.profile.neutralColorRatio
                )

                StyleStatCard(
                    title: "Fitted Cuts",
                    value: "\(Int(viewModel.profile.fittedRatio * 100))%",
                    subtitle: viewModel.profile.fittedRatio > 0.6 ? "Tailored look" : "Relaxed fit",
                    progress: viewModel.profile.fittedRatio
                )

                StyleStatCard(
                    title: "Items",
                    value: "\(viewModel.profile.totalItems)",
                    subtitle: "in wardrobe",
                    progress: min(Double(viewModel.profile.totalItems) / 50.0, 1.0)
                )

                StyleStatCard(
                    title: "Outfits",
                    value: "\(viewModel.profile.totalOutfits)",
                    subtitle: "logged",
                    progress: min(Double(viewModel.profile.totalOutfits) / 20.0, 1.0)
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Tags")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            FlowLayout(spacing: 8) {
                ForEach(Array(viewModel.profile.topTags.sorted { $0.value > $1.value }.prefix(10)), id: \.key) { tag, count in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#1C1C1E"))
                        Text("\(count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FFFFFF"))
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "#1C1C1E").opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Style Summary")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text(viewModel.insight)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .lineSpacing(4)

            if !viewModel.profile.colorStory.isEmpty {
                Text(viewModel.profile.colorStory)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Color(hex: "#6E6E73"))
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private var moreOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            VStack(spacing: 8) {
                MoreOptionRow(
                    icon: "person.2",
                    title: "Style Consultation",
                    subtitle: "Book a human stylist — coming soon",
                    action: { showConsultation = true }
                )

                MoreOptionRow(
                    icon: "gift",
                    title: "Gift Wardrobe Items",
                    subtitle: "Share items with friends",
                    action: { selectedGiftItem = nil; showGift = true }
                )

                MoreOptionRow(
                    icon: "square.and.arrow.up",
                    title: "Export Wardrobe",
                    subtitle: "Download your data as JSON or CSV",
                    action: { showExport = true }
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

struct MoreOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#B8A898").opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "#B8A898"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#E8E8E6"))
            }
            .padding(12)
            .background(Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
