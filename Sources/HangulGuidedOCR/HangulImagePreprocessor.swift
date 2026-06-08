import CoreGraphics
import CoreImage
import Foundation
import ImageIO

enum HangulImagePreprocessor {
    static func apply(_ transforms: [HangulImageTransform], to image: CGImage) throws -> CGImage {
        guard !transforms.isEmpty else {
            return image
        }

        let context = CIContext(options: nil)
        var ciImage = CIImage(cgImage: image)

        for transform in transforms {
            switch transform {
            case .cropNormalized(let normalizedRect):
                let extent = ciImage.extent
                let crop = CGRect(
                    x: extent.minX + normalizedRect.minX * extent.width,
                    y: extent.minY + normalizedRect.minY * extent.height,
                    width: normalizedRect.width * extent.width,
                    height: normalizedRect.height * extent.height
                )
                ciImage = ciImage.cropped(to: crop)

            case .rotate90Clockwise:
                ciImage = ciImage.oriented(.right)

            case .rotate90CounterClockwise:
                ciImage = ciImage.oriented(.left)

            case .upscale(let scale):
                ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

            case .contrast(let value):
                let filter = CIFilter(name: "CIColorControls")
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                filter?.setValue(value, forKey: kCIInputContrastKey)
                ciImage = filter?.outputImage ?? ciImage
            }
        }

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw HangulGuidedOCRError.preprocessingFailed
        }
        return cgImage
    }
}
