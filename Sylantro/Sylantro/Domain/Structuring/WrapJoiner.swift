import Foundation

/// Joins ingredient lines that wrap onto the next line, by rule, before the model numbers them
/// (SLT-146).
nonisolated enum WrapJoiner {
    /// A line ending with one of these words, as a whole word, continues on the next.
    private static let continuingWords: Set<String> = ["and", "or", "as", "plus", "of", "with", "to", "for", "into", "in"]

    /// The lines trimmed, with each continuation joined to the line before it. A line starting
    /// with a digit, a unicode fraction or a bullet always starts a new line.
    static func join(_ lines: [String]) -> [String] {
        var joined: [String] = []
        for line in lines.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
            guard let previous = joined.last, !startsIngredient(line), continues(line, after: previous) else {
                joined.append(line)
                continue
            }
            joined[joined.count - 1] = joining(previous, line)
        }
        return joined
    }

    /// A line that starts an ingredient: a digit, a unicode fraction (a key of
    /// `IngredientLineParser`'s table), or a bullet and a space.
    static func startsIngredient(_ line: String) -> Bool {
        guard let first = line.first else {
            return false
        }
        return ("0"..."9").contains(first) || IngredientLineParser.unicodeFractions.keys.contains(first)
            || PageSplitter.removingBullet(line) != line
    }

    /// This line starts with a lowercase letter or `(`, or the line before ends with `,`, `-` or a
    /// continuing word.
    private static func continues(_ line: String, after previous: String) -> Bool {
        if let first = line.first, first.isLowercase || first == "(" {
            return true
        }
        if previous.hasSuffix(",") || previous.hasSuffix("-") {
            return true
        }
        guard let lastWord = previous.split(whereSeparator: \.isWhitespace).last else {
            return false
        }
        return continuingWords.contains(lastWord.lowercased())
    }

    /// One space between, except that a `-` before a lowercase letter is removed with no space.
    private static func joining(_ previous: String, _ line: String) -> String {
        if previous.hasSuffix("-"), let first = line.first, first.isLowercase {
            return String(previous.dropLast()) + line
        }
        return previous + " " + line
    }
}
