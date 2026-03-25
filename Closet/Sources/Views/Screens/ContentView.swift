import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt")
                }
                .tag(0)

            OutfitView()
                .tabItem {
                    Label("Outfits", systemImage: "sparkles")
                }
                .tag(1)

            StyleProfileView()
                .tabItem {
                    Label("Style", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .tint(Color(hex: "#1C1C1E"))
    }
}
