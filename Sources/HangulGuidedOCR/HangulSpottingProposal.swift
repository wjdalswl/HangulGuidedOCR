import CoreGraphics
import Foundation

public enum HangulSpottingDirection: Sendable, Equatable {
    case horizontalLeftToRight
    case verticalTopToBottom
}

public enum HangulSpottingRotation: Sendable, Equatable {
    case none
    case clockwise90
    case counterClockwise90
}

public struct HangulSpottingProposal: Sendable, Equatable {
    public var orderedPoints: [HangulOrderedPoint]
    public var boundaryPoints: [HangulOrderedPoint]
    public var expectedText: String?
    public var confidence: Float
    public var normalizationPadding: CGFloat
    public var rotation: HangulSpottingRotation

    public init(
        orderedPoints: [HangulOrderedPoint],
        boundaryPoints: [HangulOrderedPoint],
        expectedText: String? = nil,
        confidence: Float = 1,
        normalizationPadding: CGFloat = 0.02,
        rotation: HangulSpottingRotation = .none
    ) {
        self.orderedPoints = orderedPoints
        self.boundaryPoints = boundaryPoints
        self.expectedText = expectedText
        self.confidence = confidence
        self.normalizationPadding = normalizationPadding
        self.rotation = rotation
    }

    public static func fromNormalizedRect(
        _ rect: CGRect,
        direction: HangulSpottingDirection,
        expectedText: String? = nil,
        confidence: Float = 1,
        sampleCount: Int = 25,
        normalizationPadding: CGFloat = 0.02,
        rotation: HangulSpottingRotation = .none
    ) -> HangulSpottingProposal {
        let count = max(2, sampleCount)
        let orderedPoints: [HangulOrderedPoint]

        switch direction {
        case .horizontalLeftToRight:
            orderedPoints = (0..<count).map { index in
                let progress = CGFloat(index) / CGFloat(count - 1)
                return HangulOrderedPoint(
                    x: rect.minX + rect.width * progress,
                    y: rect.midY
                )
            }

        case .verticalTopToBottom:
            orderedPoints = (0..<count).map { index in
                let progress = CGFloat(index) / CGFloat(count - 1)
                return HangulOrderedPoint(
                    x: rect.midX,
                    y: rect.maxY - rect.height * progress
                )
            }
        }

        return HangulSpottingProposal(
            orderedPoints: orderedPoints,
            boundaryPoints: [
                HangulOrderedPoint(x: rect.minX, y: rect.maxY),
                HangulOrderedPoint(x: rect.maxX, y: rect.maxY),
                HangulOrderedPoint(x: rect.maxX, y: rect.minY),
                HangulOrderedPoint(x: rect.minX, y: rect.minY),
            ],
            expectedText: expectedText,
            confidence: confidence,
            normalizationPadding: normalizationPadding,
            rotation: rotation
        )
    }

    public func normalizedBoundingRect(padding overridePadding: CGFloat? = nil) -> CGRect {
        let points = boundaryPoints.isEmpty ? orderedPoints : boundaryPoints
        guard let first = points.first else {
            return .zero
        }

        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y

        for point in points.dropFirst() {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        let padding = max(0, overridePadding ?? normalizationPadding)
        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(1, maxX + padding)
        maxY = min(1, maxY + padding)

        return CGRect(
            x: minX,
            y: minY,
            width: max(0, maxX - minX),
            height: max(0, maxY - minY)
        )
    }

    public var imageTransforms: [HangulImageTransform] {
        var transforms: [HangulImageTransform] = [
            .cropNormalized(normalizedBoundingRect())
        ]

        switch rotation {
        case .none:
            break
        case .clockwise90:
            transforms.append(.rotate90Clockwise)
        case .counterClockwise90:
            transforms.append(.rotate90CounterClockwise)
        }

        return transforms
    }

    public var expectedOrderTerms: [String] {
        guard let expectedText else {
            return []
        }
        return [expectedText]
    }
}
