import SwiftUI

@Environment(\.colorScheme) var colorScheme
import PhotosUI

struct WardrobeView: View {
    @State private var viewModel = WardrobeViewModel()
    @State private var cameraPhotoItem: PhotosPickerItem?
    @State private var columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    categoryFilterBar
                        .padding(.top, 8)

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        errorState(message: error)
                    } else if viewModel.filteredItems.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.filteredItems) { item in
                                    ClothingItemCard(
                                        item: item,
                                        onTap: { viewModel.showItemDetail = item },
                                        onDelete: {
                                            Task { await viewModel.deleteItem(item) }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        }
                    }
                }

                cameraButton
            }
            .background(ClosetDesign.Colors.background(for: colorScheme))
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(viewModel.items.count) pieces")
                        .font(.system(size: 13))
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                }
            }
            .sheet(isPresented: $viewModel.showingAddItem) {
                AddItemSheet(viewModel: viewModel)
            }
            .sheet(item: $viewModel.showItemDetail) { item in
                ItemDetailSheet(item: item, onDelete: {
                    Task {
                        if let detail = viewModel.showItemDetail {
                            await viewModel.deleteItem(detail)
                            viewModel.showItemDetail = nil
                        }
                    }
                })
            }
            .sheet(isPresented: $viewModel.showSubscriptionPrompt) {
                SubscriptionView(context: viewModel.subscriptionContext)
            }
            .photosPicker(
                isPresented: $viewModel.showingImagePicker,
                selection: $viewModel.selectedPhotoItem,
                matching: .images
            )
            .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
                Task {
                    await viewModel.processSelectedPhoto(newValue)
                }
            }
            .onChange(of: cameraPhotoItem) { _, newValue in
                Task {
                    await viewModel.processSelectedPhoto(newValue)
                }
            }
            .task {
                await viewModel.loadItems()
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    category: nil,
                    isSelected: viewModel.selectedCategory == nil,
                    action: { viewModel.selectedCategory = nil }
                )
                ForEach(viewModel.categories) { cat in
                    CategoryChip(
                        category: cat,
                        isSelected: viewModel.selectedCategory == cat,
                        action: { viewModel.selectedCategory = cat }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var emptyState: some View {
        EmptyWardrobeView()
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(ClosetDesign.Colors.error)
            Text("Something went wrong")
                .font(ClosetDesign.Typography.sectionTitle)
                .foregroundStyle(ClosetDesign.Colors.primaryText)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel.loadItems() }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(ClosetDesign.Colors.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.button))
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var cameraButton: some View {
        PhotosPicker(selection: $cameraPhotoItem, matching: .images) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(ClosetDesign.Colors.primaryText)
                .clipShape(Circle())
                .shadow(color: ClosetDesign.Colors.primaryText.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AddItemSheet: View {
    @Bindable var viewModel: WardrobeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if viewModel.processingImage {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing your item...")
                        .font(.system(size: 15))
                        .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ClosetDesign.Colors.background(for: colorScheme))
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        if let image = viewModel.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.image))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                            TextField("Item name", text: $viewModel.itemName)
                                .font(.system(size: 17))
                                .padding(12)
                                .background(ClosetDesign.Colors.background(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.button))
                                .overlay {
                                    RoundedRectangle(cornerRadius: ClosetDesign.Radius.button).stroke(ClosetDesign.Colors.divider, lineWidth: 1)
                                }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                            Picker("Category", selection: Binding(
                                get: { viewModel.detectedCategory ?? .unknown },
                                set: { viewModel.detectedCategory = $0 }
                            )) {
                                ForEach(ClothingCategory.allCases) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        if !viewModel.detectedColors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Detected Colors")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                                HStack(spacing: 8) {
                                    ForEach(viewModel.detectedColors, id: \.self) { color in
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 28, height: 28)
                                            .overlay {
                                                Circle().stroke(ClosetDesign.Colors.divider, lineWidth: 1)
                                            }
                                    }
                                }
                            }
                        }

                        if !viewModel.detectedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                                FlowLayout(spacing: 6) {
                                    ForEach(viewModel.detectedTags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 12))
                                            .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(ClosetDesign.Colors.divider)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .background(ClosetDesign.Colors.background(for: colorScheme))
            }
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.resetCaptureState()
                    dismiss()
                }
                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.saveItem()
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(ClosetDesign.Colors.primaryText)
            }
        }
    }
}

struct ItemDetailSheet: View {
    let item: ClothingItem
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 350)
                            .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.image))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(ClosetDesign.Typography.heading1)
                            .foregroundStyle(ClosetDesign.Colors.primaryText)

                        HStack {
                            Label(item.category.rawValue, systemImage: item.category.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(ClosetDesign.Colors.tertiaryText)

                            Spacer()

                            Text("Worn \(item.wearCount) time\(item.wearCount == 1 ? "" : "s")")
                                .font(.system(size: 14))
                                .foregroundStyle(ClosetDesign.Colors.accent)
                        }
                    }

                    if !item.dominantColors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Colors")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                            HStack(spacing: 8) {
                                ForEach(item.dominantColors, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Circle().stroke(ClosetDesign.Colors.divider, lineWidth: 1)
                                        }
                                }
                            }
                        }
                    }

                    if !item.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 13))
                                    .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(ClosetDesign.Colors.divider)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Delete Item", systemImage: "trash")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(ClosetDesign.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ClosetDesign.Colors.background(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: ClosetDesign.Radius.button))
                            .overlay {
                                RoundedRectangle(cornerRadius: ClosetDesign.Radius.button).stroke(ClosetDesign.Colors.error.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(ClosetDesign.Colors.background(for: colorScheme))
            .navigationTitle("Item Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(ClosetDesign.Colors.primaryText)
                }
            }
            .task {
                image = await ImageStorageService.shared.loadImage(path: item.imagePath)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300 // minimum sensible width
        let result = FlowResult(in: width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

struct EmptyWardrobeView: View {
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ClosetEmptyIllustration(size: 180)
            Text("Your wardrobe is empty")
                .font(ClosetDesign.Typography.sectionTitle)
                .foregroundStyle(ClosetDesign.Colors.primaryText)
            Text("Tap the camera button below to add your first piece")
                .font(.system(size: 15))
                .foregroundStyle(ClosetDesign.Colors.tertiaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}
