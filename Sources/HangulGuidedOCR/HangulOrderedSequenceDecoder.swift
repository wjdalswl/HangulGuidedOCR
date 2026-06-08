import CoreGraphics
import Foundation

public enum HangulOrderedSequenceDecoder {
    public static func collapseRepeatedPointCharacters(_ text: String) -> String {
        let collapsedTokens = text
            .split(whereSeparator: \.isWhitespace)
            .map { collapseRepeatedHangulCharacters(String($0)) }

        var output: [String] = []
        for token in collapsedTokens where !token.isEmpty {
            if token.count == 1,
               isHangulSyllable(token),
               output.last == token {
                continue
            }
            output.append(token)
        }

        return output.joined(separator: " ")
    }

    public static func deduplicateOverlappingObservations(
        _ observations: [HangulTextObservation],
        overlapThreshold: CGFloat = 0.55
    ) -> [HangulTextObservation] {
        guard !observations.isEmpty else {
            return []
        }

        var kept: [HangulTextObservation] = []

        for observation in observations {
            let key = HangulLexiconCorrector.normalize(observation.text)
            guard !key.isEmpty else {
                kept.append(observation)
                continue
            }

            if let existingIndex = kept.firstIndex(where: { existing in
                HangulLexiconCorrector.normalize(existing.text) == key
                    && intersectionOverUnion(existing.boundingBox, observation.boundingBox) >= overlapThreshold
            }) {
                if observation.confidence > kept[existingIndex].confidence {
                    kept[existingIndex] = observation
                }
            } else {
                kept.append(observation)
            }
        }

        return kept
    }

    private static func collapseRepeatedHangulCharacters(_ token: String) -> String {
        var output = ""
        var previousHangul: Character?

        for character in token {
            if isHangulSyllable(character) {
                if previousHangul == character {
                    continue
                }
                previousHangul = character
            } else {
                previousHangul = nil
            }
            output.append(character)
        }

        return output
    }

    private static func isHangulSyllable(_ text: String) -> Bool {
        text.count == 1 && text.first.map(isHangulSyllable) == true
    }

    private static func isHangulSyllable(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 else {
            return false
        }
        return (0xAC00...0xD7A3).contains(Int(scalar.value))
    }

    private static func intersectionOverUnion(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else {
            return 0
        }

        let intersectionArea = intersection.width * intersection.height
        let unionArea = lhs.width * lhs.height + rhs.width * rhs.height - intersectionArea
        guard unionArea > 0 else {
            return 0
        }
        return intersectionArea / unionArea
    }
}
