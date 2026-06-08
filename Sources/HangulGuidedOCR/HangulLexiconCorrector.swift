import Foundation

public enum HangulLexiconCorrector {
    public static func reconstruct(
        rawText: String,
        expectedOrder: [String],
        enablesFuzzyCorrection: Bool
    ) -> String {
        let normalizedRaw = normalize(rawText)
        let rawTokens = tokenize(rawText)
        var reconstructed: [String] = []

        for expected in expectedOrder {
            let normalizedExpected = normalize(expected)
            if normalizedRaw.contains(normalizedExpected) {
                reconstructed.append(expected)
                continue
            }

            if enablesFuzzyCorrection,
               rawTokens.contains(where: { isFuzzyMatch($0, normalizedExpected) }) {
                reconstructed.append(expected)
            }
        }

        return reconstructed.isEmpty ? rawText : reconstructed.joined(separator: " ")
    }

    public static func normalize(_ text: String) -> String {
        let normalized = text.precomposedStringWithCanonicalMapping.lowercased()
        return normalized.replacingOccurrences(
            of: #"[^0-9a-z가-힣]+"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func tokenize(_ text: String) -> [String] {
        text.precomposedStringWithCanonicalMapping
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map(normalize)
            .filter { !$0.isEmpty }
    }

    private static func isFuzzyMatch(_ token: String, _ expected: String) -> Bool {
        guard !token.isEmpty, !expected.isEmpty else {
            return false
        }
        let distance = editDistance(Array(token), Array(expected))
        let threshold = max(1, expected.count / 3)
        return distance <= threshold
    }

    private static func editDistance<T: Equatable>(_ lhs: [T], _ rhs: [T]) -> Int {
        var previous = Array(0...rhs.count)
        for (i, left) in lhs.enumerated() {
            var current = [i + 1]
            for (j, right) in rhs.enumerated() {
                let cost = left == right ? 0 : 1
                current.append(
                    min(
                        previous[j + 1] + 1,
                        current[j] + 1,
                        previous[j] + cost
                    )
                )
            }
            previous = current
        }
        return previous[rhs.count]
    }
}
