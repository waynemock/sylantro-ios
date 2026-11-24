import Foundation

/// The one text normalization the structuring rules use (`11` M1-4), so a value and the page text
/// compare the same way.
nonisolated enum TextMatch {
    /// Unicode fractions (`IngredientLineParser`'s table) as ` n/d`; a word broken by a hyphen at a
    /// line end joined; lowercased; every run of characters other than letters, digits, `/` and `.`
    /// as one space; trimmed.
    static func normalize(_ text: String) -> String {
        var expanded: [Character] = []
        for character in text {
            if let fraction = IngredientLineParser.unicodeFractions[character] {
                expanded.append(contentsOf: " \(fraction.numerator)/\(fraction.denominator)")
            } else {
                expanded.append(character)
            }
        }

        // `-`, a newline, then a letter: the hyphen and the newline are removed.
        var joined = ""
        var index = 0
        while index < expanded.count {
            if expanded[index] == "-", index + 2 < expanded.count,
               expanded[index + 1].isNewline, expanded[index + 2].isLetter {
                index += 2
                continue
            }
            joined.append(expanded[index])
            index += 1
        }

        var result = ""
        var pendingSpace = false
        for character in joined.lowercased() {
            if character.isLetter || ("0"..."9").contains(character) || character == "/" || character == "." {
                if pendingSpace, !result.isEmpty {
                    result.append(" ")
                }
                pendingSpace = false
                result.append(character)
            } else {
                pendingSpace = true
            }
        }
        return result
    }

    /// The model's ways of writing "no value" (SLT-152), compared trimmed and lowercased.
    private static let emptyAnswers: Set<String> = [
        "", "none", "n/a", "na", "null", "nil", "-", "empty", "not specified", "not applicable",
    ]

    /// Whether a model answer is no value: nil, empty, or "none" and the like (SLT-152).
    static func isEmptyAnswer(_ text: String?) -> Bool {
        guard let text else {
            return true
        }
        return emptyAnswers.contains(text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }

    /// Whether `value`, normalized, appears in `text`, normalized. An empty normalized value is
    /// never contained.
    static func contains(_ value: String, in text: String) -> Bool {
        let normalizedValue = normalize(value)
        guard !normalizedValue.isEmpty else {
            return false
        }
        return normalize(text).contains(normalizedValue)
    }
}
