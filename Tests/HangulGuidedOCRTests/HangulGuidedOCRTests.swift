import CoreGraphics
import XCTest
@testable import HangulGuidedOCR

final class HangulGuidedOCRTests: XCTestCase {
    func testImagePreprocessorAppliesCropRotateUpscaleAndContrast() throws {
        let image = try makeSolidImage(width: 20, height: 10)

        let transformed = try HangulImagePreprocessor.apply(
            [
                .cropNormalized(CGRect(x: 0, y: 0, width: 0.5, height: 1.0)),
                .rotate90Clockwise,
                .upscale(2.0),
                .contrast(1.4),
            ],
            to: image
        )

        XCTAssertEqual(transformed.width, 20)
        XCTAssertEqual(transformed.height, 20)
    }

    func testAutomaticKeepsRawOrderForOrdinaryHorizontalPoster() {
        let observations = [
            HangulTextObservation(text: "행사명", confidence: 1, boundingBox: CGRect(x: 0.62, y: 0.72, width: 0.18, height: 0.08)),
            HangulTextObservation(text: "날짜", confidence: 1, boundingBox: CGRect(x: 0.18, y: 0.72, width: 0.14, height: 0.08)),
            HangulTextObservation(text: "장소", confidence: 1, boundingBox: CGRect(x: 0.22, y: 0.55, width: 0.14, height: 0.08)),
        ]

        let resolved = HangulReadingOrderResolver.resolveWithStrategy(
            observations: observations,
            guide: HangulReadingGuide()
        )

        XCTAssertEqual(resolved.resolvedStrategy, .rawVisionOrder)
        XCTAssertEqual(resolved.text, "행사명 날짜 장소")
    }

    func testAutomaticVerticalStationTermsUseExpectedStationOrder() {
        let observations = [
            HangulTextObservation(text: "동대문역사", confidence: 1, boundingBox: CGRect(x: 0.64, y: 0.1, width: 0.08, height: 0.7)),
            HangulTextObservation(text: "문화공원", confidence: 1, boundingBox: CGRect(x: 0.34, y: 0.1, width: 0.08, height: 0.7)),
        ]

        let resolved = HangulReadingOrderResolver.resolveWithStrategy(
            observations: observations,
            guide: HangulReadingGuide(expectedOrder: ["동대문역사", "문화공원"])
        )

        XCTAssertEqual(resolved.resolvedStrategy, .verticalColumnsLeftToRight)
        XCTAssertEqual(resolved.text, "동대문역사 문화공원")
    }

    func testVerticalStationTermsCanBeReconstructedByExpectedOrder() {
        let observations = [
            HangulTextObservation(text: "동대문역사", confidence: 1, boundingBox: CGRect(x: 0.64, y: 0.1, width: 0.08, height: 0.7)),
            HangulTextObservation(text: "문화공원", confidence: 1, boundingBox: CGRect(x: 0.34, y: 0.1, width: 0.08, height: 0.7)),
        ]

        let result = HangulReadingOrderResolver.resolve(
            observations: observations,
            guide: HangulReadingGuide(
                strategy: .verticalColumnsLeftToRight,
                expectedOrder: ["동대문역사", "문화공원"]
            )
        )

        XCTAssertEqual(result, "동대문역사 문화공원")
    }

    func testVerticalColumnsRightToLeftOrdersTraditionalKoreanColumns() {
        let observations = [
            HangulTextObservation(text: "세로쓰기", confidence: 1, boundingBox: CGRect(x: 0.25, y: 0.1, width: 0.08, height: 0.7)),
            HangulTextObservation(text: "조용히입장", confidence: 1, boundingBox: CGRect(x: 0.65, y: 0.1, width: 0.08, height: 0.7)),
        ]

        let result = HangulReadingOrderResolver.resolve(
            observations: observations,
            guide: HangulReadingGuide(strategy: .verticalColumnsRightToLeft)
        )

        XCTAssertEqual(result, "조용히입장 세로쓰기")
    }

    func testBuildsDeepSoloStylePointProxyFromVisionObservation() {
        let observations = [
            HangulTextObservation(text: "동대문역사", confidence: 0.9, boundingBox: CGRect(x: 0.6, y: 0.1, width: 0.08, height: 0.7)),
        ]

        let proxies = HangulPointProxyBuilder.build(from: observations, sampleCount: 5)

        XCTAssertEqual(proxies.count, 1)
        XCTAssertEqual(proxies[0].orderedPoints.count, 5)
        XCTAssertEqual(proxies[0].boundaryPoints.count, 4)
        XCTAssertEqual(proxies[0].text, "동대문역사")
        XCTAssertEqual(proxies[0].orderedPoints.first?.x, observations[0].boundingBox.midX)
        XCTAssertGreaterThan(proxies[0].orderedPoints.first?.y ?? 0, proxies[0].orderedPoints.last?.y ?? 1)
    }

    func testBuildsPreOCRSpottingProposalFromOrderedPoints() {
        let proposal = HangulSpottingProposal.fromNormalizedRect(
            CGRect(x: 0.42, y: 0.25, width: 0.18, height: 0.50),
            direction: .verticalTopToBottom,
            expectedText: "광복절",
            sampleCount: 5,
            normalizationPadding: 0.03,
            rotation: .clockwise90
        )

        XCTAssertEqual(proposal.orderedPoints.count, 5)
        XCTAssertEqual(proposal.boundaryPoints.count, 4)
        XCTAssertEqual(proposal.expectedOrderTerms, ["광복절"])
        XCTAssertEqual(proposal.imageTransforms.count, 2)
        XCTAssertGreaterThan(proposal.orderedPoints.first?.y ?? 0, proposal.orderedPoints.last?.y ?? 1)

        let crop = proposal.normalizedBoundingRect()
        XCTAssertEqual(crop.minX, 0.39, accuracy: 0.0001)
        XCTAssertEqual(crop.minY, 0.22, accuracy: 0.0001)
        XCTAssertEqual(crop.width, 0.24, accuracy: 0.0001)
        XCTAssertEqual(crop.height, 0.56, accuracy: 0.0001)
    }

    func testCollapsesRepeatedPointCharactersLikeCTCDecoding() {
        let observations = [
            HangulTextObservation(text: "광광광복절", confidence: 0.7, boundingBox: CGRect(x: 0.45, y: 0.35, width: 0.10, height: 0.45)),
        ]

        let resolved = HangulReadingOrderResolver.resolveWithStrategy(
            observations: observations,
            guide: HangulReadingGuide(strategy: .rawVisionOrder)
        )

        XCTAssertEqual(resolved.text, "광복절")
    }

    func testSuppressesOverlappingDuplicatePointPredictions() {
        let observations = [
            HangulTextObservation(text: "광", confidence: 0.3, boundingBox: CGRect(x: 0.45, y: 0.66, width: 0.10, height: 0.10)),
            HangulTextObservation(text: "광", confidence: 0.9, boundingBox: CGRect(x: 0.455, y: 0.665, width: 0.10, height: 0.10)),
            HangulTextObservation(text: "복", confidence: 0.8, boundingBox: CGRect(x: 0.45, y: 0.50, width: 0.10, height: 0.10)),
            HangulTextObservation(text: "절", confidence: 0.8, boundingBox: CGRect(x: 0.45, y: 0.34, width: 0.10, height: 0.10)),
        ]

        let resolved = HangulReadingOrderResolver.resolveWithStrategy(
            observations: observations,
            guide: HangulReadingGuide(strategy: .topToBottomRows)
        )

        XCTAssertEqual(resolved.text, "광 복 절")
    }

    func testAutomaticTypographyWallFuzzyCorrection() {
        let observations = [
            HangulTextObservation(text: "예는", confidence: 0.5, boundingBox: CGRect(x: 0.45, y: 0.80, width: 0.12, height: 0.08)),
            HangulTextObservation(text: "그림을", confidence: 0.8, boundingBox: CGRect(x: 0.45, y: 0.62, width: 0.16, height: 0.08)),
            HangulTextObservation(text: "그리고", confidence: 0.8, boundingBox: CGRect(x: 0.45, y: 0.44, width: 0.16, height: 0.08)),
            HangulTextObservation(text: "싶다", confidence: 0.8, boundingBox: CGRect(x: 0.45, y: 0.26, width: 0.12, height: 0.08)),
        ]

        let resolved = HangulReadingOrderResolver.resolveWithStrategy(
            observations: observations,
            guide: HangulReadingGuide(expectedOrder: ["예쁜", "그림을", "그리고", "싶다"])
        )

        XCTAssertEqual(resolved.resolvedStrategy, .topToBottomRows)
        XCTAssertEqual(resolved.text, "예쁜 그림을 그리고 싶다")
    }

    func testTypographyWallFuzzyCorrection() {
        let observations = [
            HangulTextObservation(text: "예는", confidence: 0.5, boundingBox: CGRect(x: 0.05, y: 0.8, width: 0.1, height: 0.1)),
            HangulTextObservation(text: "그림을", confidence: 0.8, boundingBox: CGRect(x: 0.2, y: 0.8, width: 0.2, height: 0.1)),
            HangulTextObservation(text: "그리고", confidence: 0.8, boundingBox: CGRect(x: 0.45, y: 0.8, width: 0.2, height: 0.1)),
            HangulTextObservation(text: "싶다", confidence: 0.8, boundingBox: CGRect(x: 0.7, y: 0.8, width: 0.1, height: 0.1)),
        ]

        let result = HangulReadingOrderResolver.resolve(
            observations: observations,
            guide: HangulReadingGuide(
                strategy: .topToBottomRows,
                expectedOrder: ["예쁜", "그림을", "그리고", "싶다"]
            )
        )

        XCTAssertEqual(result, "예쁜 그림을 그리고 싶다")
    }

    private func makeSolidImage(width: Int, height: Int) throws -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw XCTSkip("Could not create CGContext for image preprocessing test.")
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else {
            throw XCTSkip("Could not create CGImage for image preprocessing test.")
        }
        return image
    }
}
