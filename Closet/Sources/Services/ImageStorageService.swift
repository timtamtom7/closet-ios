import Foundation
import UIKit

actor ImageStorageService {
    static let shared = ImageStorageService()

    private let maxDimension: CGFloat = 800
    private let compressionQuality: CGFloat = 0.8

    private init() {}

    func saveImage(_ image: UIImage) throws -> String {
        let resized = resizeImage(image, maxDimension: maxDimension)
        guard let data = resized.jpegData(compressionQuality: compressionQuality) else {
            throw ImageStorageError.compressionFailed
        }

        let filename = "\(UUID().uuidString).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDir = documentsPath.appendingPathComponent("ClothingImages", isDirectory: true)

        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let filePath = imagesDir.appendingPathComponent(filename)
        try data.write(to: filePath)

        return "ClothingImages/\(filename)"
    }

    func loadImage(path: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(path)
        return UIImage(contentsOfFile: fullPath.path)
    }

    func deleteImage(path: String) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(path)
        try FileManager.default.removeItem(at: fullPath)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1 { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum ImageStorageError: Error {
    case compressionFailed
    case saveFailed
}
