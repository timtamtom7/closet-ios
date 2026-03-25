import SwiftUI

struct TravelPackingView: View {
    @State private var viewModel = TravelPackingViewModel()
    @State private var wardrobeViewModel = WardrobeViewModel()
    @State private var showNewTrip = false
    @State private var showPackingList = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection

                    if !viewModel.recentPackingLists.isEmpty {
                        recentListsSection
                    }

                    quickStartSection
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Travel Packing")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showNewTrip) {
                NewTripSheet(
                    wardrobeViewModel: wardrobeViewModel,
                    onGenerate: { context in
                        Task {
                            let list = await viewModel.generatePackingList(
                                for: wardrobeViewModel.items,
                                context: context
                            )
                            viewModel.recentPackingLists.insert(list, at: 0)
                            showPackingList = true
                        }
                    }
                )
            }
            .sheet(isPresented: $showPackingList) {
                if let list = viewModel.currentPackingList {
                    PackingListDetailView(
                        packingList: list,
                        items: wardrobeViewModel.items
                    )
                }
            }
            .task {
                await wardrobeViewModel.loadItems()
                viewModel.loadSavedLists()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#B8A898"))

            Text("Pack Smart")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Text("Generate personalized packing lists based on weather and activities")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
    }

    private var recentListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Lists")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 20)

            ForEach(viewModel.recentPackingLists.prefix(3)) { list in
                PackingListRow(list: list) {
                    viewModel.currentPackingList = list
                    showPackingList = true
                }
            }
        }
    }

    private var quickStartSection: some View {
        VStack(spacing: 16) {
            Button {
                showNewTrip = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: "#B8A898"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("New Trip")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: "#1C1C1E"))
                        Text("Create a packing list for your upcoming trip")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#E8E8E6"))
                }
                .padding(20)
                .background(Color(hex: "#FFFFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
    }
}

struct PackingListRow: View {
    let list: TravelPackingService.PackingList
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(list.tripTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1C1C1E"))

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(dateRange)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color(hex: "#6E6E73"))

                    HStack(spacing: 4) {
                        Image(systemName: "cloud.sun")
                            .font(.system(size: 11))
                        Text(list.weatherSummary)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color(hex: "#6E6E73"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(list.tripNights)")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: "#B8A898"))
                    Text("nights")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
            .padding(16)
            .background(Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: list.startDate)) - \(formatter.string(from: list.endDate))"
    }
}

struct NewTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wardrobeViewModel: WardrobeViewModel
    let onGenerate: (TravelPackingService.TripContext) -> Void

    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var selectedActivities: Set<TravelPackingService.TripContext.TripActivity> = [.casual]
    @State private var weatherForecast: WeatherService.DayForecast?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Destination")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                        TextField("e.g. Paris, Tokyo, Beach Resort", text: $destination)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Color(hex: "#FFFFFF"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dates")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#6E6E73"))
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(Color(hex: "#B8A898"))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("End")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#6E6E73"))
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(Color(hex: "#B8A898"))
                            }
                        }
                        .padding(14)
                        .background(Color(hex: "#FFFFFF"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activities")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(TravelPackingService.TripContext.TripActivity.allCases) { activity in
                                ActivityChip(
                                    activity: activity,
                                    isSelected: selectedActivities.contains(activity)
                                ) {
                                    if selectedActivities.contains(activity) {
                                        selectedActivities.remove(activity)
                                    } else {
                                        selectedActivities.insert(activity)
                                    }
                                }
                            }
                        }
                    }

                    if let forecast = weatherForecast {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weather Preview")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "#6E6E73"))

                            HStack(spacing: 12) {
                                Image(systemName: forecast.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color(hex: "#B8A898"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(Int(forecast.avgTemp))° average")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color(hex: "#1C1C1E"))
                                    Text(forecast.condition)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(hex: "#6E6E73"))
                                }

                                Spacer()
                            }
                            .padding(14)
                            .background(Color(hex: "#FFFFFF"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Generate") {
                        let context = TravelPackingService.TripContext(
                            destination: destination,
                            startDate: startDate,
                            endDate: endDate,
                            activities: Array(selectedActivities),
                            weather: weatherForecast
                        )
                        onGenerate(context)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .disabled(destination.isEmpty)
                    .opacity(destination.isEmpty ? 0.5 : 1)
                }
            }
            .onChange(of: destination) { _, _ in
                Task {
                    weatherForecast = try? await WeatherService.shared.fetchForecast(days: 5).first
                }
            }
        }
    }
}

struct ActivityChip: View {
    let activity: TravelPackingService.TripContext.TripActivity
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: activity.icon)
                    .font(.system(size: 14))
                Text(activity.rawValue)
                    .font(.system(size: 13))
            }
            .foregroundStyle(isSelected ? .white : Color(hex: "#1C1C1E"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "#1C1C1E") : Color(hex: "#FFFFFF"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct PackingListDetailView: View {
    let packingList: TravelPackingService.PackingList
    let items: [ClothingItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    tripHeader

                    ForEach(packingList.categories) { category in
                        PackingCategorySection(
                            categoryPacking: category,
                            items: items
                        )
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Packing List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#6E6E73"))
                }
            }
        }
    }

    private var tripHeader: some View {
        VStack(spacing: 8) {
            Text(packingList.tripTitle)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text(dateRange)
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color(hex: "#6E6E73"))

                HStack(spacing: 4) {
                    Image(systemName: "cloud.sun")
                        .font(.system(size: 13))
                    Text(packingList.weatherSummary)
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color(hex: "#6E6E73"))
            }

            Text("\(packingList.tripNights) nights")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "#B8A898"))
        }
        .padding(.horizontal, 20)
    }

    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: packingList.startDate)) - \(formatter.string(from: packingList.endDate))"
    }
}

struct PackingCategorySection: View {
    let categoryPacking: TravelPackingService.PackingList.CategoryPacking
    let items: [ClothingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryPacking.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#B8A898"))

                Text(categoryPacking.category.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: "#1C1C1E"))

                Spacer()

                Text("\(categoryPacking.totalCount) items")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#6E6E73"))
            }

            Text(categoryPacking.notes)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#6E6E73"))

            if !categoryPacking.itemIds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categoryPacking.itemIds, id: \.self) { itemId in
                            if let item = items.first(where: { $0.id == itemId }) {
                                PackingItemThumbnail(item: item)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

struct PackingItemThumbnail: View {
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
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                    }
            }
        }
        .frame(width: 56, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
        }
        .task {
            image = await ImageStorageService.shared.loadImage(path: item.imagePath)
        }
    }
}
