import SwiftUI
import PhotosUI

struct WardrobeView: View {
    @State private var viewModel = WardrobeViewModel()
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
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(viewModel.items.count) pieces")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#6E6E73"))
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
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tshirt")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#E8E8E6"))
            Text("Your wardrobe is empty")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "#1C1C1E"))
            Text("Tap the camera button to add your first piece")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var cameraButton: some View {
        PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color(hex: "#1C1C1E"))
                .clipShape(Circle())
                .shadow(color: Color(hex: "#1C1C1E").opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

struct AddItemSheet: View {
    @Bindable var viewModel: WardrobeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
                        TextField("Item name", text: $viewModel.itemName)
                            .font(.system(size: 17))
                            .padding(12)
                            .background(Color(hex: "#FAFAF8"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#6E6E73"))
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
                                .foregroundStyle(Color(hex: "#6E6E73"))
                            HStack(spacing: 8) {
                                ForEach(viewModel.detectedColors, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 28, height: 28)
                                        .overlay {
                                            Circle().stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
                                        }
                                }
                            }
                        }
                    }

                    if !viewModel.detectedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(hex: "#6E6E73"))
                            FlowLayout(spacing: 6) {
                                ForEach(viewModel.detectedTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "#6E6E73"))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#E8E8E6"))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetCaptureState()
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "#6E6E73"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveItem()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                }
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
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color(hex: "#1C1C1E"))

                        HStack {
                            Label(item.category.rawValue, systemImage: item.category.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#6E6E73"))

                            Spacer()

                            Text("Worn \(item.wearCount) time\(item.wearCount == 1 ? "" : "s")")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#B8A898"))
                        }
                    }

                    if !item.dominantColors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Colors")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(hex: "#6E6E73"))
                            HStack(spacing: 8) {
                                ForEach(item.dominantColors, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Circle().stroke(Color(hex: "#E8E8E6"), lineWidth: 1)
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
                                    .foregroundStyle(Color(hex: "#6E6E73"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#E8E8E6"))
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
                            .foregroundStyle(Color(hex: "#C45C4A"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#FAFAF8"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#C45C4A").opacity(0.3), lineWidth: 1)
                            }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color(hex: "#FAFAF8"))
            .navigationTitle("Item Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "#1C1C1E"))
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
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
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
