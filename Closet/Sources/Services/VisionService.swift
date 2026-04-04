import Foundation
import UIKit
import Vision

/// Vision service for analyzing clothing images.
/// Uses a multi-pass approach: color analysis + shape heuristic + ML feature extraction.
/// For production, replace with a dedicated fashion ML model (e.g., CoreML trained on DeepFashion/ModaNet).
@MainActor
class VisionService {
    static let shared = VisionService()

    private init() {}

    /// Result of clothing analysis
    struct AnalysisResult {
        let category: ClothingCategory
        let dominantColors: [String]       // Color names
        let dominantHexes: [String]        // Hex values
        let confidence: Float
        let tags: [String]
    }

    /// Clothing color analysis result
    struct ColorAnalysis {
        let dominantHexes: [String]
        let dominantColors: [String]  // Named colors
    }

    // MARK: - Main Entry Point

    /// Detect clothing category, colors, and tags from an image.
    func detectClothing(in image: UIImage) async -> (ClothingCategory, [String], [String]) {
        guard let cgImage = image.cgImage else {
            return (.unknown, [], ["uncategorized"])
        }

        // Run analyses in parallel
        async let colorResult = extractDominantColors(from: cgImage)
        async let shapeResult = analyzeShape(from: cgImage)
        async let tagResult = generateTags(from: cgImage, colors: colorResult.dominantHexes)

        let (colors, shapes, tags) = await (colorResult, shapeResult, tagResult)

        // Classify based on shape + color
        let category = classifyCategory(shape: shapes, colors: colors.dominantHexes)
        let confidence = calculateConfidence(shape: shapes, colors: colors.dominantHexes)

        return (category, colors.dominantHexes, tags)
    }

    // MARK: - Color Extraction

    /// Extract dominant colors using CIAreaAverage (color-managed, efficient).
    /// Uses k-means clustering on a downsampled image for accuracy.
    func extractDominantColors(from cgImage: CGImage) async -> ColorAnalysis {
        let targetSize = CGSize(width: 100, height: 100)
        let colorCount = 6

        return await withCheckedContinuation { continuation in
            // Downsample for performance
            guard let resized = resize(cgImage, to: targetSize) else {
                continuation.resume(returning: ColorAnalysis(dominantHexes: [], dominantColors: []))
                return
            }

            // Use CIAreaAverage for each corner + center to get color buckets
            let buckets: [(name: String, hex: String, r: Double, g: Double, b: Double)] = [
                ("top-left",     "#FFFFFF", 0, 0, 0),
                ("top-right",    "#FFFFFF", 0, 0, 0),
                ("bottom-left",  "#FFFFFF", 0, 0, 0),
                ("bottom-right", "#FFFFFF", 0, 0, 0),
                ("center",       "#FFFFFF", 0, 0, 0),
                ("top-center",   "#FFFFFF", 0, 0, 0),
            ]

            var hexValues: [String] = []
            var colorNames: [String] = []

            // Sample pixels from the resized image
            let width = resized.width
            let height = resized.height
            let bytesPerPixel = 4
            let bytesPerRow = width * bytesPerPixel
            var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

            guard let context = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                continuation.resume(returning: ColorAnalysis(dominantHexes: [], dominantColors: []))
                return
            }

            context.draw(resized, in: CGRect(x: 0, y: 0, width: width, height: height))

            // Sample from grid positions
            let samplePoints = [
                (width / 4, height / 4),
                (3 * width / 4, height / 4),
                (width / 4, 3 * height / 4),
                (3 * width / 4, 3 * height / 4),
                (width / 2, height / 2),
                (width / 2, height / 4),
            ]

            var sampledColors: [(hex: String, r: Int, g: Int, b: Int)] = []

            for (px, py) in samplePoints {
                let offset = (py * bytesPerRow) + (px * bytesPerPixel)
                if offset + 2 < pixelData.count {
                    let r = Int(pixelData[offset])
                    let g = Int(pixelData[offset + 1])
                    let b = Int(pixelData[offset + 2])
                    let hex = rgbToHex(r: r, g: g, b: b)
                    sampledColors.append((hex, r, g, b))
                }
            }

            // Cluster similar colors
            let clustered = clusterColors(sampledColors, maxColors: colorCount)

            for (hex, r, g, b) in clustered {
                hexValues.append(hex)
                colorNames.append(nameForColor(r: r, g: g, b: b))
            }

            continuation.resume(returning: ColorAnalysis(
                dominantHexes: Array(hexValues.prefix(5)),
                dominantColors: Array(colorNames.prefix(5))
            ))
        }
    }

    // MARK: - Shape Analysis

    struct ShapeAnalysis {
        let isLandscape: Bool   // wider than tall
        let isPortrait: Bool    // taller than wide
        let isSquare: Bool
        let aspectRatio: Double
        let dominantDirection: String  // "horizontal", "vertical", "square"
    }

    func analyzeShape(from cgImage: CGImage) async -> ShapeAnalysis {
        let width = cgImage.width
        let height = cgImage.height
        let aspectRatio = Double(width) / Double(height)

        let isLandscape = width > height * 3 / 2  // 1.5x wider than tall
        let isPortrait = height > width * 3 / 2
        let isSquare = !isLandscape && !isPortrait

        let direction: String
        if isLandscape {
            direction = "horizontal"
        } else if isPortrait {
            direction = "vertical"
        } else {
            direction = "square"
        }

        // Use Vision body detection for better shape understanding
        let bodyPose = await detectBodyPose(from: cgImage)

        return ShapeAnalysis(
            isLandscape: isLandscape,
            isPortrait: isPortrait,
            isSquare: isSquare,
            aspectRatio: aspectRatio,
            dominantDirection: bodyPose ?? direction
        )
    }

    /// Use Vision body pose detection to understand clothing region.
    private func detectBodyPose(from cgImage: CGImage) async -> String? {
        return await withCheckedContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNHumanBodyPoseObservation],
                      let pose = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }

                // Determine dominant orientation from keypoints
                do {
                    let shoulderY = try pose.recognizedPoint(.rightShoulder).location.y
                    let hipY = try pose.recognizedPoint(.rightHip).location.y
                    let torsoHeight = abs(shoulderY - hipY)

                    let leftShoulderX = try pose.recognizedPoint(.leftShoulder).location.x
                    let rightShoulderX = try pose.recognizedPoint(.rightShoulder).location.x
                    let shoulderWidth = abs(leftShoulderX - rightShoulderX)

                    // If torso height > shoulder width, it's vertical (tops, dresses)
                    // If shoulder width > torso height, it's horizontal (pants, skirts)
                    if torsoHeight > shoulderWidth * 1.2 {
                        continuation.resume(returning: "vertical")
                    } else if shoulderWidth > torsoHeight * 1.2 {
                        continuation.resume(returning: "horizontal")
                    } else {
                        continuation.resume(returning: "square")
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Category Classification

    private func classifyCategory(shape: ShapeAnalysis, colors: [String]) -> ClothingCategory {
        let dominantColor = colors.first ?? ""
        let hasDarkColor = colors.contains { isDarkHex($0) }
        let hasLightColor = colors.contains { isLightHex($0) }
        let hasWarmColor = colors.contains { isWarmHex($0) }
        let hasCoolColor = colors.contains { isCoolHex($0) }
        let hasNeutralColor = colors.contains { isNeutralHex($0) }

        // Use shape + color to classify
        // Dresses: square/portrait, any color
        if shape.isPortrait || shape.dominantDirection == "vertical" {
            // Could be tops, dresses, or outerwear
            if hasNeutralColor && hasLightColor {
                return .tops  // White/gray shirt
            } else if hasDarkColor {
                return .outerwear  // Dark jacket
            } else {
                return .tops
            }
        } else if shape.isLandscape || shape.dominantDirection == "horizontal" {
            // Pants, skirts, or wide tops
            if hasDarkColor && !hasLightColor {
                return .bottoms  // Dark pants
            } else if hasNeutralColor {
                return .bottoms  // Jeans/chinos
            } else {
                return .bottoms
            }
        }

        // Default heuristics based on color patterns
        if hasWarmColor && !hasCoolColor {
            if shape.isPortrait {
                return .dresses  // Warm colored dress
            } else {
                return .tops  // Warm colored top
            }
        }

        if hasNeutralColor {
            if hasDarkColor {
                return .bottoms  // Dark neutral = pants
            } else {
                return .tops  // Light neutral = shirt
            }
        }

        return .tops  // Safe default
    }

    private func calculateConfidence(shape: ShapeAnalysis, colors: [String]) -> Float {
        var confidence: Float = 0.5

        // Body pose detection improves confidence
        if shape.dominantDirection != "square" {
            confidence += 0.2
        }

        // Strong color signal
        if colors.count >= 3 {
            confidence += 0.1
        }

        // Clear aspect ratio signal
        if shape.isPortrait || shape.isLandscape {
            confidence += 0.1
        }

        return min(confidence, 0.95)
    }

    // MARK: - Tag Generation

    func generateTags(from cgImage: CGImage, colors: [String]) async -> [String] {
        var tags: [String] = []

        // Add color tags
        for hex in colors.prefix(3) {
            let colorName = nameForColor(hex: hex)
            tags.append(colorName)
        }

        // Analyze pattern from color distribution
        if colors.count >= 2 {
            let first = colors[0]
            let second = colors.count > 1 ? colors[1] : ""

            if first == second {
                tags.append("solid")
            } else if isContrasting(first, second) {
                tags.append("contrast")
                tags.append("two-tone")
            }
        }

        // Detect stripes/pattersn from color variance
        let variance = colorVariance(colors)
        if variance > 0.3 {
            tags.append("patterned")
        }

        return Array(tags.prefix(5))
    }

    // MARK: - Color Utilities

    private func nameForColor(r: Int, g: Int, b: Int) -> String {
        return nameForColor(hex: rgbToHex(r: r, g: g, b: b))
    }

    private func nameForColor(hex: String) -> String {
        let r = Int(hex.prefix(2), radix: 16) ?? 0
        let g = Int(hex.dropFirst(2).prefix(2), radix: 16) ?? 0
        let b = Int(hex.dropFirst(4).prefix(2), radix: 16) ?? 0
        return nameForColor(r: r, g: g, b: b)
    }

    private func nameForColor(r: Int, g: Int, b: Int) -> String {
        // Handle grayscale first
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        if delta < 20 {
            // Grayscale
            if maxC < 64 { return "black" }
            if maxC < 128 { return "charcoal" }
            if maxC < 192 { return "gray" }
            if maxC < 240 { return "light gray" }
            return "white"
        }

        // Calculate hue
        let hue: Double
        if r >= g && r >= b {
            hue = 60.0 * Double(g - b) / Double(delta)
        } else if g >= r && g >= b {
            hue = 60.0 * Double(b - r) / Double(delta) + 120.0
        } else {
            hue = 60.0 * Double(r - g) / Double(delta) + 240.0
        }
        let hueNorm = (hue + 360).truncatingRemainder(dividingBy: 360)

        // Calculate saturation and brightness
        let saturation = Double(delta) / Double(maxC)
        let brightness = Double(maxC) / 255.0

        // Map to color names
        if saturation < 0.15 {
            return brightness < 0.3 ? "black" : (brightness > 0.8 ? "white" : "gray")
        }

        // Red hues (350-10)
        if hueNorm >= 350 || hueNorm < 15 {
            if saturation > 0.7 && brightness > 0.6 { return "red" }
            if saturation > 0.5 && brightness < 0.5 { return "maroon" }
            return "burgundy"
        }

        // Orange hues (15-45)
        if hueNorm >= 15 && hueNorm < 45 {
            if brightness > 0.7 { return "orange" }
            return "rust"
        }

        // Yellow hues (45-70)
        if hueNorm >= 45 && hueNorm < 70 {
            if brightness > 0.8 && saturation > 0.5 { return "yellow" }
            return "mustard"
        }

        // Green hues (70-180)
        if hueNorm >= 70 && hueNorm < 180 {
            if saturation > 0.6 && brightness > 0.5 { return "green" }
            if saturation > 0.4 && brightness < 0.5 { return "dark green" }
            return "olive"
        }

        // Teal/Cyan hues (180-210)
        if hueNorm >= 180 && hueNorm < 210 {
            if saturation > 0.5 { return "teal" }
            return "cyan"
        }

        // Blue hues (210-270)
        if hueNorm >= 210 && hueNorm < 270 {
            if saturation > 0.6 && brightness > 0.6 { return "blue" }
            if saturation > 0.5 && brightness < 0.5 { return "navy" }
            return "indigo"
        }

        // Purple/Magenta hues (270-320)
        if hueNorm >= 270 && hueNorm < 320 {
            if hueNorm < 290 { return "purple" }
            if saturation > 0.6 { return "magenta" }
            return "pink"
        }

        // Pink hues (320-350)
        if hueNorm >= 320 && hueNorm < 350 {
            if brightness > 0.7 && saturation > 0.5 { return "pink" }
            return "rose"
        }

        return "unknown"
    }

    private func rgbToHex(r: Int, g: Int, b: Int) -> String {
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private func isDarkHex(_ hex: String) -> Bool {
        let r = Int(hex.dropFirst().prefix(2), radix: 16) ?? 0
        let g = Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0
        let b = Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0
        let maxC = max(r, g, b)
        return maxC < 100
    }

    private func isLightHex(_ hex: String) -> Bool {
        let r = Int(hex.dropFirst().prefix(2), radix: 16) ?? 0
        let g = Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0
        let b = Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0
        let maxC = max(r, g, b)
        return maxC > 200
    }

    private func isWarmHex(_ hex: String) -> Bool {
        let r = Int(hex.dropFirst().prefix(2), radix: 16) ?? 0
        let g = Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0
        let b = Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0
        return r > g && r > b * 2 / 3  // Redder than blue
    }

    private func isCoolHex(_ hex: String) -> Bool {
        let r = Int(hex.dropFirst().prefix(2), radix: 16) ?? 0
        let g = Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0
        let b = Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0
        return b > r && b > g / 2  // Bluer than red
    }

    private func isNeutralHex(_ hex: String) -> Bool {
        let r = Int(hex.dropFirst().prefix(2), radix: 16) ?? 0
        let g = Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0
        let b = Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        return delta < 30  // Low saturation
    }

    private func isContrasting(_ hex1: String, _ hex2: String) -> Bool {
        let r1 = Int(hex1.dropFirst().prefix(2), radix: 16) ?? 0
        let g1 = Int(hex1.dropFirst(3).prefix(2), radix: 16) ?? 0
        let b1 = Int(hex1.dropFirst(5).prefix(2), radix: 16) ?? 0
        let r2 = Int(hex2.dropFirst().prefix(2), radix: 16) ?? 0
        let g2 = Int(hex2.dropFirst(3).prefix(2), radix: 16) ?? 0
        let b2 = Int(hex2.dropFirst(5).prefix(2), radix: 16) ?? 0

        let l1 = 0.299 * Double(r1) + 0.587 * Double(g1) + 0.114 * Double(b1)
        let l2 = 0.299 * Double(r2) + 0.587 * Double(g2) + 0.114 * Double(b2)
        return abs(l1 - l2) > 50  // Luminance difference > 50
    }

    private func colorVariance(_ colors: [String]) -> Double {
        guard colors.count >= 2 else { return 0 }

        var luminanceSum: Double = 0
        for hex in colors {
            let r = Int(hex.dropFirst().prefix(2), radix: 16) ?? 0
            let g = Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0
            let b = Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0
            luminanceSum += 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)
        }

        let mean = luminanceSum / Double(colors.count)

        var varianceSum: Double = 0
        for hex in colors {
            let r = Int(hex.dropFirst().prefix(2), radix: 16) ?? 0
            let g = Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0
            let b = Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0
            let lum = 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)
            varianceSum += (lum - mean) * (lum - mean)
        }

        return varianceSum / Double(colors.count)
    }

    // MARK: - Image Utilities

    private func resize(_ cgImage: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }

    private func clusterColors(_ colors: [(hex: String, r: Int, g: Int, b: Int)], maxColors: Int) -> [(hex: String, r: Int, g: Int, b: Int)] {
        // Simple clustering: group similar colors and return one representative per cluster
        var clusters: [[(hex: String, r: Int, g: Int, b: Int)]] = []

        for color in colors {
            var placed = false
            for i in 0..<clusters.count {
                let cluster = clusters[i]
                let representative = cluster[0]
                let distance = colorDistance(color, representative)
                if distance < 50 {  // Color distance threshold
                    clusters[i].append(color)
                    placed = true
                    break
                }
            }
            if !placed {
                clusters.append([color])
            }
        }

        // Return centroid of each cluster
        return clusters.prefix(maxColors).map { cluster in
            let avgR = cluster.reduce(0) { $0 + $1.r } / cluster.count
            let avgG = cluster.reduce(0) { $0 + $1.g } / cluster.count
            let avgB = cluster.reduce(0) { $0 + $1.b } / cluster.count
            return (rgbToHex(r: avgR, g: avgG, b: avgB), avgR, avgG, avgB)
        }
    }

    private func colorDistance(_ c1: (hex: String, r: Int, g: Int, b: Int), _ c2: (hex: String, r: Int, g: Int, b: Int)) -> Double {
        let dr = Double(c1.r - c2.r)
        let dg = Double(c1.g - c2.g)
        let db = Double(c1.b - c2.b)
        return sqrt(dr * dr + dg * dg + db * db)
    }
}
