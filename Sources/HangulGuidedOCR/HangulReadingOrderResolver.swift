import CoreGraphics
import Foundation

public enum HangulReadingOrderResolver {
    public static func resolveWithStrategy(
        observations: [HangulTextObservation],
        guide: HangulReadingGuide
    ) -> (text: String, resolvedStrategy: HangulReadingStrategy) {
        let resolvedStrategy = guide.strategy == .automatic
            ? inferredStrategy(observations: observations, expectedOrder: guide.expectedOrder)
            : guide.strategy
        let ordered = orderedObservations(observations, strategy: resolvedStrategy)
        let decoded = guide.enablesRepeatedPointCollapse
            ? HangulOrderedSequenceDecoder.deduplicateOverlappingObservations(
                ordered,
                overlapThreshold: guide.duplicateOverlapThreshold
            )
            : ordered
        let orderedText = decodeOrderedText(decoded, enablesRepeatedPointCollapse: guide.enablesRepeatedPointCollapse)

        guard !guide.expectedOrder.isEmpty else {
            return (orderedText, resolvedStrategy)
        }

        let correctedText = HangulLexiconCorrector.reconstruct(
            rawText: orderedText,
            expectedOrder: guide.expectedOrder,
            enablesFuzzyCorrection: guide.enablesFuzzyCorrection
        )
        return (correctedText, resolvedStrategy)
    }

    public static func resolve(
        observations: [HangulTextObservation],
        guide: HangulReadingGuide
    ) -> String {
        resolveWithStrategy(observations: observations, guide: guide).text
    }

    public static func inferredStrategy(
        observations: [HangulTextObservation],
        expectedOrder: [String] = []
    ) -> HangulReadingStrategy {
        guard observations.count > 1 else {
            return .rawVisionOrder
        }

        let tallObservations = observations.filter { observation in
            proxyHeight(observation) > proxyWidth(observation) * 2.0
        }
        let minX = observations.map(centerX).min() ?? 0
        let maxX = observations.map(centerX).max() ?? 0
        let minY = observations.map(centerY).min() ?? 0
        let maxY = observations.map(centerY).max() ?? 0
        let xSpread = maxX - minX
        let ySpread = maxY - minY

        if tallObservations.count >= 2 && xSpread > 0.10 {
            return .verticalColumnsLeftToRight
        }

        let rowCount = groupByRows(observations, rowTolerance: 0.075).count
        let expectedTermCount = max(2, expectedOrder.count)
        if rowCount >= expectedTermCount && ySpread > 0.18 && ySpread > xSpread * 0.75 {
            return .topToBottomRows
        }

        // Raw Vision is usually already strong on ordinary horizontal Korean
        // posters. In auto mode, preserve that order instead of forcing a
        // point-proxy sort that can damage natural paragraph flow.
        return .rawVisionOrder
    }

    public static func orderedObservations(
        _ observations: [HangulTextObservation],
        strategy: HangulReadingStrategy
    ) -> [HangulTextObservation] {
        switch strategy {
        case .automatic:
            return orderedObservations(
                observations,
                strategy: inferredStrategy(observations: observations)
            )
        case .rawVisionOrder:
            return observations
        case .horizontalLines:
            return groupByRows(observations, rowTolerance: 0.055)
                .flatMap { row in row.sorted { centerX($0) < centerX($1) } }
        case .topToBottomRows:
            return groupByRows(observations, rowTolerance: 0.095)
                .flatMap { row in row.sorted { centerX($0) < centerX($1) } }
        case .verticalColumnsLeftToRight:
            return groupByColumns(observations, columnTolerance: 0.075, leftToRight: true)
                .flatMap { column in column.sorted { centerY($0) > centerY($1) } }
        case .verticalColumnsRightToLeft:
            return groupByColumns(observations, columnTolerance: 0.075, leftToRight: false)
                .flatMap { column in column.sorted { centerY($0) > centerY($1) } }
        }
    }

    private static func groupByRows(
        _ observations: [HangulTextObservation],
        rowTolerance: CGFloat
    ) -> [[HangulTextObservation]] {
        var rows: [[HangulTextObservation]] = []
        for observation in observations.sorted(by: { centerY($0) > centerY($1) }) {
            if let index = rows.firstIndex(where: { row in
                abs(meanY(row) - centerY(observation)) <= rowTolerance
            }) {
                rows[index].append(observation)
            } else {
                rows.append([observation])
            }
        }
        return rows.sorted { meanY($0) > meanY($1) }
    }

    private static func groupByColumns(
        _ observations: [HangulTextObservation],
        columnTolerance: CGFloat,
        leftToRight: Bool
    ) -> [[HangulTextObservation]] {
        var columns: [[HangulTextObservation]] = []
        for observation in observations.sorted(by: { centerX($0) < centerX($1) }) {
            if let index = columns.firstIndex(where: { column in
                abs(meanX(column) - centerX(observation)) <= columnTolerance
            }) {
                columns[index].append(observation)
            } else {
                columns.append([observation])
            }
        }

        return columns.sorted {
            leftToRight ? meanX($0) < meanX($1) : meanX($0) > meanX($1)
        }
    }

    private static func meanX(_ observations: [HangulTextObservation]) -> CGFloat {
        observations.map(centerX).reduce(0, +) / CGFloat(max(1, observations.count))
    }

    private static func meanY(_ observations: [HangulTextObservation]) -> CGFloat {
        observations.map(centerY).reduce(0, +) / CGFloat(max(1, observations.count))
    }

    private static func decodeOrderedText(
        _ observations: [HangulTextObservation],
        enablesRepeatedPointCollapse: Bool
    ) -> String {
        let text = observations.map(\.text).joined(separator: " ")
        guard enablesRepeatedPointCollapse else {
            return text
        }
        return HangulOrderedSequenceDecoder.collapseRepeatedPointCharacters(text)
    }

    private static func centerX(_ observation: HangulTextObservation) -> CGFloat {
        let points = HangulPointProxyBuilder.orderedPoints(for: observation, sampleCount: 3)
        return points.map(\.x).reduce(0, +) / CGFloat(points.count)
    }

    private static func centerY(_ observation: HangulTextObservation) -> CGFloat {
        let points = HangulPointProxyBuilder.orderedPoints(for: observation, sampleCount: 3)
        return points.map(\.y).reduce(0, +) / CGFloat(points.count)
    }

    private static func proxyWidth(_ observation: HangulTextObservation) -> CGFloat {
        let points = HangulPointProxyBuilder.boundaryPoints(for: observation)
        let xs = points.map(\.x)
        return (xs.max() ?? 0) - (xs.min() ?? 0)
    }

    private static func proxyHeight(_ observation: HangulTextObservation) -> CGFloat {
        let points = HangulPointProxyBuilder.boundaryPoints(for: observation)
        let ys = points.map(\.y)
        return (ys.max() ?? 0) - (ys.min() ?? 0)
    }
}
