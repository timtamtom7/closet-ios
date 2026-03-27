import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        #if os(iOS)
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadContentView
            } else {
                iPhoneContentView
            }
        }
        #else
        macOSContentView
        #endif
    }

    #if os(iOS)
    private var iPhoneContentView: some View {
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

            ColorPaletteView()
                .tabItem {
                    Label("Palette", systemImage: "paintpalette")
                }
                .tag(2)

            TravelPackingView()
                .tabItem {
                    Label("Travel", systemImage: "airplane")
                }
                .tag(3)

            StyleProfileView()
                .tabItem {
                    Label("Style", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .tint(Color(hex: "#1C1C1E"))
        .onChange(of: selectedTab) { _, _ in
            ClosetHaptics.selection()
        }
    }

    private var iPadContentView: some View {
        iPadDashboardView()
    }
    #endif

    #if os(macOS)
    private var macOSContentView: some View {
        iPadDashboardView()
    }
    #endif
}
