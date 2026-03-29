import SwiftUI

struct MenuBarView: View {
    @StateObject private var dataService = ClosetDataService.shared
    @State private var selectedTab: MenuTab = .overview
    @State private var showingOutfitBuilder = false
    @State private var showingLogEntry = false

    enum MenuTab: String, CaseIterable {
        case overview = "Wardrobe"
        case outfits = "Outfits"
        case style = "Style"
        case wishList = "Wish List"
        case log = "Log"
        case settings = "Settings"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(MenuTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: iconFor(tab))
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? Theme.charcoal : Theme.slate)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? Theme.warmBeige : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Theme.surface)

            Divider()

            // Content
            ScrollView {
                switch selectedTab {
                case .overview:
                    ClosetOverviewView(dataService: dataService)
                case .outfits:
                    OutfitBuilderView(dataService: dataService)
                case .style:
                    StyleView(dataService: dataService)
                case .wishList:
                    WishListView(dataService: dataService)
                case .log:
                    WornLogView(dataService: dataService)
                case .settings:
                    SettingsView(dataService: dataService)
                }
            }
        }
        .frame(width: 360, height: 480)
        .background(Theme.warmBeige)
    }

    private func iconFor(_ tab: MenuTab) -> String {
        switch tab {
        case .overview: return "tshirt"
        case .outfits: return "square.grid.2x2"
        case .style: return "wand.and.stars"
        case .wishList: return "star"
        case .log: return "calendar"
        case .settings: return "gearshape"
        }
    }
}
