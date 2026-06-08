import CoreGraphics
import Foundation
import Vision

public final class HangulGuidedOCR {
    public init() {}

    public func recognize(
        _ image: CGImage,
        proposal: HangulSpottingProposal,
        configuration: HangulOCRConfiguration = HangulOCRConfiguration()
    ) throws -> HangulOCRResult {
        var proposalConfiguration = configuration
        proposalConfiguration.imageTransforms = proposal.imageTransforms + configuration.imageTransforms

        if proposalConfiguration.readingGuide.expectedOrder.isEmpty,
           !proposal.expectedOrderTerms.isEmpty {
            proposalConfiguration.readingGuide.expectedOrder = proposal.expectedOrderTerms
        }

        return try recognize(image, configuration: proposalConfiguration)
    }

    public func recognize(
        _ image: CGImage,
        configuration: HangulOCRConfiguration = HangulOCRConfiguration()
    ) throws -> HangulOCRResult {
        let processedImage = try HangulImagePreprocessor.apply(
            configuration.imageTransforms,
            to: image
        )

        var observations: [HangulTextObservation] = []
        var requestError: Error?

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                requestError = error
                return
            }

            let results = request.results as? [VNRecognizedTextObservation] ?? []
            observations = results.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }
                return HangulTextObservation(
                    text: candidate.string,
                    confidence: candidate.confidence,
                    boundingBox: observation.boundingBox
                )
            }
        }

        request.recognitionLevel = configuration.recognitionLevel.visionLevel
        request.recognitionLanguages = configuration.recognitionLanguages
        request.usesLanguageCorrection = configuration.usesLanguageCorrection

        let start = CFAbsoluteTimeGetCurrent()
        let handler = VNImageRequestHandler(cgImage: processedImage, options: [:])
        try handler.perform([request])
        if let requestError {
            throw requestError
        }
        let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000

        let rawText = observations.map(\.text).joined(separator: " ")
        let pointProxies = HangulPointProxyBuilder.build(from: observations)
        let guided = HangulReadingOrderResolver.resolveWithStrategy(
            observations: observations,
            guide: configuration.readingGuide
        )

        return HangulOCRResult(
            rawText: rawText,
            guidedText: guided.text,
            observations: observations,
            pointProxies: pointProxies,
            appliedGuide: configuration.readingGuide,
            resolvedStrategy: guided.resolvedStrategy,
            durationMilliseconds: duration
        )
    }
}
