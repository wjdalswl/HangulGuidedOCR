import CoreGraphics
import Foundation
import Vision

public enum HangulRecognitionLevel: Sendable {
    case fast
    case accurate

    var visionLevel: VNRequestTextRecognitionLevel {
        switch self {
        case .fast:
            return .fast
        case .accurate:
            return .accurate
        }
    }
}

public enum HangulReadingStrategy: Sendable, Equatable {
    case automatic
    case rawVisionOrder
    case horizontalLines
    case verticalColumnsLeftToRight
    case verticalColumnsRightToLeft
    case topToBottomRows
}

public enum HangulImageTransform: Sendable, Equatable {
    case cropNormalized(CGRect)
    case rotate90Clockwise
    case rotate90CounterClockwise
    case upscale(CGFloat)
    case contrast(Double)
}

public struct HangulReadingGuide: Sendable, Equatable {
    public var strategy: HangulReadingStrategy
    public var expectedOrder: [String]
    public var enablesFuzzyCorrection: Bool
    public var enablesRepeatedPointCollapse: Bool
    public var duplicateOverlapThreshold: CGFloat

    public init(
        strategy: HangulReadingStrategy = .automatic,
        expectedOrder: [String] = [],
        enablesFuzzyCorrection: Bool = true,
        enablesRepeatedPointCollapse: Bool = true,
        duplicateOverlapThreshold: CGFloat = 0.55
    ) {
        self.strategy = strategy
        self.expectedOrder = expectedOrder
        self.enablesFuzzyCorrection = enablesFuzzyCorrection
        self.enablesRepeatedPointCollapse = enablesRepeatedPointCollapse
        self.duplicateOverlapThreshold = duplicateOverlapThreshold
    }
}

public struct HangulOCRConfiguration: Sendable, Equatable {
    public var recognitionLevel: HangulRecognitionLevel
    public var recognitionLanguages: [String]
    public var usesLanguageCorrection: Bool
    public var imageTransforms: [HangulImageTransform]
    public var readingGuide: HangulReadingGuide

    public init(
        recognitionLevel: HangulRecognitionLevel = .accurate,
        recognitionLanguages: [String] = ["ko-KR", "en-US"],
        usesLanguageCorrection: Bool = true,
        imageTransforms: [HangulImageTransform] = [],
        readingGuide: HangulReadingGuide = HangulReadingGuide()
    ) {
        self.recognitionLevel = recognitionLevel
        self.recognitionLanguages = recognitionLanguages
        self.usesLanguageCorrection = usesLanguageCorrection
        self.imageTransforms = imageTransforms
        self.readingGuide = readingGuide
    }
}

public struct HangulTextObservation: Sendable, Equatable {
    public var text: String
    public var confidence: Float
    public var boundingBox: CGRect

    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

public struct HangulOCRResult: Sendable, Equatable {
    public var rawText: String
    public var guidedText: String
    public var observations: [HangulTextObservation]
    public var pointProxies: [HangulPointProxy]
    public var appliedGuide: HangulReadingGuide
    public var resolvedStrategy: HangulReadingStrategy
    public var durationMilliseconds: Double

    public init(
        rawText: String,
        guidedText: String,
        observations: [HangulTextObservation],
        pointProxies: [HangulPointProxy] = [],
        appliedGuide: HangulReadingGuide,
        resolvedStrategy: HangulReadingStrategy? = nil,
        durationMilliseconds: Double
    ) {
        self.rawText = rawText
        self.guidedText = guidedText
        self.observations = observations
        self.pointProxies = pointProxies
        self.appliedGuide = appliedGuide
        self.resolvedStrategy = resolvedStrategy ?? appliedGuide.strategy
        self.durationMilliseconds = durationMilliseconds
    }
}

public enum HangulGuidedOCRError: Error, Equatable {
    case preprocessingFailed
}
