import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

actor ImageStorageService {
    static let shared = ImageStorageService()

    private let maxDimension: CGFloat = 800
    private let compressionQuality: CGFloat = 0.8

    private init() {}

    #if os(iOS)
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
    #else
    func saveImage(_ image: NSImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
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

    func loadImage(path: String) -> NSImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(path)
        return NSImage(contentsOf: fullPath)
    }
    #endif

    func deleteImage(path: String) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsPath.appendingPathComponent(path)
        try FileManager.default.removeItem(at: fullPath)
    }
}

enum ImageStorageError: Error {
    case compressionFailed
    case saveFailed
}

#if os(macOS)
extension NSImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
#endif
