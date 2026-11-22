import Foundation

/// The one text normalization the structuring rules use (`11` M1-4), so a value and the page text
/// compare the same way.
nonisolated enum TextMatch {
    /// `06` M1-2's unicode fractions, as ` n/d`. The same table as `IngredientLineParser`'s, which
    /// is private to that file.
    private static let unicodeFractions: [Character: String] = [
        "¼": " 1/4", "½": " 1/2", "¾": " 3/4", "⅓": " 1/3", "⅔": " 2/3", "⅕": " 1/5",
        "⅙": " 1/6", "⅛": " 1/8", "⅜": " 3/8", "⅝": " 5/8", "⅞": " 7/8",
    ]

    /// Unicode fractions as ` n/d`; a word broken by a hyphen at a line end joined; lowercased;
    /// every run of characters other than letters, digits, `/` and `.` as one space; trimmed.
    static func normalize(_ text: String) -> String {
        var expanded: [Character] = []
        for character in text {
            if let fraction = unicodeFractions[character] {
                expanded.append(contentsOf: fraction)
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
