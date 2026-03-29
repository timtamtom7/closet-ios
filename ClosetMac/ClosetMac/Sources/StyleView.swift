import SwiftUI

/// R11: Style tab — combines Weather-Aware Styling + Wardrobe Insights
struct StyleView: View {
    @ObservedObject var dataService: ClosetDataService
    @State private var selectedSubTab: StyleSubTab = .weather

    enum StyleSubTab: String, CaseIterable {
        case weather = "Weather"
        case insights = "Insights"
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
            }
            .tabViewStyle(.automatic)
        }
    }
}
