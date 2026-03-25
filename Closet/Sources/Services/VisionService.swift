import Foundation
import Vision
#if os(iOS)
import UIKit
#endif

actor VisionService {
    static let shared = VisionService()

    private init() {}

    #if os(iOS)
    func detectClothing(in image: UIImage) async throws -> (category: ClothingCategory, colors: [String], tags: [String]) {
        guard let cgImage = image.cgImage else {
            return (.unknown, [], [])
        }

        let category = try await classifyImage(cgImage: cgImage)
        let colors = extractDominantColors(from: image)
        let tags = generateTags(from: category, colors: colors)

        return (category, colors, tags)
    }
    #else
    func detectClothing(in imagePath: String) async throws -> (category: ClothingCategory, colors: [String], tags: [String]) {
        return (.unknown, [], ["uncategorized"])
    }
    #endif

    #if os(iOS)
    private func classifyImage(cgImage: CGImage) async throws -> ClothingCategory {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: ClothingCategory.unknown)
                    return
                }

                let topResult = results.first?.identifier.lowercased() ?? ""

                let category: ClothingCategory
                if topResult.contains("shirt") || topResult.contains("top") || topResult.contains("blouse") || topResult.contains("t-shirt") || topResult.contains("sweater") || topResult.contains("jacket") {
                    category = .tops
                } else if topResult.contains("pant") || topResult.contains("jean") || topResult.contains("trouser") || topResult.contains("short") || topResult.contains("skirt") || topResult.contains("bottom") {
                    category = .bottoms
                } else if topResult.contains("shoe") || topResult.contains("sneaker") || topResult.contains("boot") || topResult.contains("heel") || topResult.contains("sandal") {
                    category = .shoes
                } else if topResult.contains("dress") || topResult.contains("gown") {
                    category = .dresses
                } else if topResult.contains("coat") || topResult.contains("jacket") || topResult.contains("blazer") || topResult.contains("outerwear") {
                    category = .outerwear
                } else if topResult.contains("hat") || topResult.contains("bag") || topResult.contains("watch") || topResult.contains("jewelry") || topResult.contains("accessory") || topResult.contains("scarf") || topResult.contains("belt") {
                    category = .accessories
                } else {
                    category = .unknown
                }

                continuation.resume(returning: category)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    nonisolated func extractDominantColors(from image: UIImage, colorCount: Int = 5) -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let width = 50
        let height = 50
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return [] }

        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var colorCounts: [String: Int] = [:]

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = Int(pointer[offset])
                let g = Int(pointer[offset + 1])
                let b = Int(pointer[offset + 2])

                let bucket = categorizeRGB(r: r, g: g, b: b)
                colorCounts[bucket, default: 0] += 1
            }
        }

        let sortedColors = colorCounts.sorted { $0.value > $1.value }
        return Array(sortedColors.prefix(colorCount).map { $0.key })
    }
    #endif

    nonisolated private func categorizeRGB(r: Int, g: Int, b: Int) -> String {
        if r < 30 && g < 30 && b < 30 { return "#000000" }
        if r > 225 && g > 225 && b > 225 { return "#FFFFFF" }
        if r > 200 && g > 200 && b > 200 { return "#F5F5DC" }
        if abs(r - g) < 20 && abs(g - b) < 20 && abs(r - b) < 20 { return "#808080" }

        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        if delta < 30 { return "#808080" }

        var hue: Double = 0
        if maxC == r {
            hue = 60.0 * (Double(g - b).truncatingRemainder(dividingBy: 6.0) / Double(delta))
        } else if maxC == g {
            hue = 60.0 * ((Double(b - r) / Double(delta)) + 2.0)
        } else {
            hue = 60.0 * ((Double(r - g) / Double(delta)) + 4.0)
        }

        if hue < 0 { hue += 360.0 }

        if maxC < 100 { return "#1C1C1E" }

        if (hue >= 0 && hue < 30) || hue >= 330 {
            return "#C45C4A"
        } else if hue >= 30 && hue < 90 {
            return "#D4C5B5"
        } else if hue >= 90 && hue < 150 {
            return "#6E6E73"
        } else if hue >= 150 && hue < 210 {
            return "#B8A898"
        } else if hue >= 210 && hue < 270 {
            return "#1C1C1E"
        } else {
            return "#C45C4A"
        }
    }

    #if os(iOS)
    nonisolated private func generateTags(from category: ClothingCategory, colors: [String]) -> [String] {
        var tags: [String] = []

        switch category {
        case .tops:
            tags.append(contentsOf: ["top", "shirt"])
        case .bottoms:
            tags.append(contentsOf: ["bottom", "pant"])
        case .shoes:
            tags.append(contentsOf: ["shoes", "footwear"])
        case .accessories:
            tags.append(contentsOf: ["accessory"])
        case .outerwear:
            tags.append(contentsOf: ["outerwear", "layer"])
        case .dresses:
            tags.append(contentsOf: ["dress", "one-piece"])
        case .unknown:
            tags.append("uncategorized")
        }

        let neutralTags = ["neutral", "classic"]
        let colorfulTags = ["colorful", "bold", "statement"]
        let neutralCount = colors.filter { ["#000000", "#FFFFFF", "#808080", "#F5F5DC", "#1C1C1E"].contains($0) }.count
        if neutralCount > colors.count / 2 {
            tags.append(neutralTags.randomElement()!)
        } else {
            tags.append(colorfulTags.randomElement()!)
        }

        return tags
    }
    #endif
}
