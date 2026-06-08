import CoreGraphics
import Foundation

public struct HangulOrderedPoint: Sendable, Equatable {
    public var x: CGFloat
    public var y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

public struct HangulPointProxy: Sendable, Equatable {
    public var orderedPoints: [HangulOrderedPoint]
    public var boundaryPoints: [HangulOrderedPoint]
    public var text: String
    public var confidence: Float

    public init(
        orderedPoints: [HangulOrderedPoint],
        boundaryPoints: [HangulOrderedPoint],
        text: String,
        confidence: Float
    ) {
        self.orderedPoints = orderedPoints
        self.boundaryPoints = boundaryPoints
        self.text = text
        self.confidence = confidence
    }
}

public enum HangulPointProxyBuilder {
    public static func build(
        from observations: [HangulTextObservation],
        sampleCount: Int = 25
    ) -> [HangulPointProxy] {
        observations.map { observation in
            HangulPointProxy(
                orderedPoints: orderedPoints(for: observation, sampleCount: sampleCount),
                boundaryPoints: boundaryPoints(for: observation),
                text: observation.text,
                confidence: observation.confidence
            )
        }
    }

    public static func orderedPoints(
        for observation: HangulTextObservation,
        sampleCount: Int = 25
    ) -> [HangulOrderedPoint] {
        let count = max(2, sampleCount)
        let box = observation.boundingBox

        if box.height > box.width * 1.4 {
            return (0..<count).map { index in
                let progress = CGFloat(index) / CGFloat(count - 1)
                return HangulOrderedPoint(
                    x: box.midX,
                    y: box.maxY - box.height * progress
                )
            }
        }

        return (0..<count).map { index in
            let progress = CGFloat(index) / CGFloat(count - 1)
            return HangulOrderedPoint(
                x: box.minX + box.width * progress,
                y: box.midY
            )
        }
    }

    public static func boundaryPoints(
        for observation: HangulTextObservation
    ) -> [HangulOrderedPoint] {
        let box = observation.boundingBox
        return [
            HangulOrderedPoint(x: box.minX, y: box.maxY),
            HangulOrderedPoint(x: box.maxX, y: box.maxY),
            HangulOrderedPoint(x: box.maxX, y: box.minY),
            HangulOrderedPoint(x: box.minX, y: box.minY),
        ]
    }
}
