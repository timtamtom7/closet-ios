import Foundation
import SwiftUI
import PhotosUI

@Observable
final class WardrobeViewModel {
    var items: [ClothingItem] = []
    var selectedCategory: ClothingCategory? = nil
    var isLoading = false
    var errorMessage: String?
    var showingImagePicker = false
    var showingCamera = false
    var showingAddItem = false
    var processingImage = false
    var selectedPhotoItem: PhotosPickerItem?
    var capturedImage: UIImage?
    var detectedCategory: ClothingCategory?
    var detectedColors: [String] = []
    var detectedTags: [String] = []
    var itemName: String = ""
    var showItemDetail: ClothingItem?
    var showDeleteConfirmation = false
    var itemToDelete: ClothingItem?
    var showSubscriptionPrompt = false
    var subscriptionContext: SubscriptionView.SubscriptionContext = .general

    var filteredItems: [ClothingItem] {
        guard let cat = selectedCategory else { return items }
        return items.filter { $0.category == cat }
    }

    var categories: [ClothingCategory] {
        ClothingCategory.allCases.filter { $0 != .unknown }
    }

    @MainActor
    func loadItems() async {
        isLoading = true
        errorMessage = nil
        do {
            try await DatabaseService.shared.initialize()
            items = try await DatabaseService.shared.fetchAllClothingItems()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func processSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        processingImage = true
        detectedCategory = nil
        detectedColors = []
        detectedTags = []
        itemName = ""

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                capturedImage = image
                let result = try await VisionService.shared.detectClothing(in: image)
                detectedCategory = result.category
                detectedColors = result.colors
                detectedTags = result.tags
                itemName = result.category.rawValue
                showingAddItem = true
            }
        } catch {
            errorMessage = "Failed to process image: \(error.localizedDescription)"
        }
        processingImage = false
    }

    @MainActor
    func saveItem() async {
        guard let image = capturedImage else { return }

        // Check subscription limits
        let (allowed, reason) = await SubscriptionService.shared.canAddItem(currentCount: items.count)
        if !allowed {
            subscriptionContext = .itemLimit
            showSubscriptionPrompt = true
            return
        }

        do {
            let imagePath = try await ImageStorageService.shared.saveImage(image)
            let category = detectedCategory ?? .unknown
            let item = ClothingItem(
                name: itemName.isEmpty ? category.rawValue : itemName,
                category: category,
                imagePath: imagePath,
                dominantColors: detectedColors,
                tags: detectedTags
            )
            try await DatabaseService.shared.insertClothingItem(item)
            items.insert(item, at: 0)
            resetCaptureState()
        } catch {
            errorMessage = "Failed to save item: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteItem(_ item: ClothingItem) async {
        do {
            try await ImageStorageService.shared.deleteImage(path: item.imagePath)
            try await DatabaseService.shared.deleteClothingItem(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    func resetCaptureState() {
        capturedImage = nil
        detectedCategory = nil
        detectedColors = []
        detectedTags = []
        itemName = ""
        showingAddItem = false
        selectedPhotoItem = nil
    }
}
