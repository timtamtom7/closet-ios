import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
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
                    Label("Outfits", systemImage: "rectangle.stack")
                }
                .tag(1)

            StyleProfileView()
                .tabItem {
                    Label("Style", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .tint(ClosetDesign.Colors.primaryText(for: colorScheme))
        .preferredColorScheme(nil) // Follow system setting
    }
}

#Preview {
    ContentView()
}
