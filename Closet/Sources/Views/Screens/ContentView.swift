import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadContentView
            } else {
                iPhoneContentView
            }
        }
    }

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
    }

    private var iPadContentView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List {
                NavigationLink(destination: WardrobeView()) {
                    Label("Wardrobe", systemImage: "tshirt")
                }
                NavigationLink(destination: OutfitView()) {
                    Label("Outfits", systemImage: "sparkles")
                }
                NavigationLink(destination: ColorPaletteView()) {
                    Label("Palette", systemImage: "paintpalette")
                }
                NavigationLink(destination: TravelPackingView()) {
                    Label("Travel", systemImage: "airplane")
                }
                NavigationLink(destination: StyleProfileView()) {
                    Label("Style", systemImage: "person.crop.circle")
                }
            }
            .navigationTitle("Closet")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
        } detail: {
            NavigationStack {
                ZStack {
                    Color(hex: "#F5F5F7").ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 72))
                            .foregroundColor(Color(hex: "#1C1C1E").opacity(0.1))
                        Text("Select a view from the sidebar")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Closet")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .tint(Color(hex: "#1C1C1E"))
    }
}
