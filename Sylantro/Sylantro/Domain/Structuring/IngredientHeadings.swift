import Foundation

/// The group headings printed in an ingredient section ("Dough:", "For the sauce:"), found by rule
/// so the groups follow the page (`15` RV-38, M3-3h).
nonisolated enum IngredientHeadings {
    /// A heading's text before its `:` is this many characters long.
    static let length = 2...60

    /// The numbers (from 1) of `lines` that are group headings: trimmed, ending with `:`, 2 to 60
    /// characters before the `:`, at least half of them letters, not starting like an ingredient
    /// (`WrapJoiner.startsIngredient`), and not a section heading (`PageSplitter.heading`).
    static func lines(_ lines: [String]) -> [Int] {
        lines.enumerated().compactMap { offset, line in
            isHeading(line) ? offset + 1 : nil
        }
    }

    private static func isHeading(_ line: String) -> Bool {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasSuffix(":") else { return false }
        let name = text.dropLast()
        guard length.contains(name.count),
              name.filter(\.isLetter).count * 2 >= name.count,
              !WrapJoiner.startsIngredient(text),
              PageSplitter.heading(text) == nil else {
            return false
        }
        return true
    }
}
