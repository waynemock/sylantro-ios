import Foundation

/// The titles of the recipes on a capture's pages, found by their type size, and the cut of the
/// pages into one piece per title (`15` RV-14, RV-35, M3-5s). Spike only for now. Pages and lines
/// are numbered from 0, as their arrays are.
nonisolated enum PageTitles {
    /// A title: its page, its first and last lines there, and its text (a wrapped title's lines
    /// joined with a space).
    typealias Found = (page: Int, firstLine: Int, lastLine: Int, text: String)

    /// A line at least this many times the page's median line height is big.
    static let bigRatio = 1.4
    /// A big line's text is this many characters long.
    static let titleLength = 3...80

    /// The section words a big line isn't, normalized (`TextMatch`), with their singulars.
    private static let sectionWords: Set<String> = [
        "ingredients", "ingredient", "directions", "direction", "instructions", "instruction",
        "method", "steps", "step", "preparation", "notes", "note", "equipment", "nutrition",
    ]

    /// The big-type titles of `pages` (each line's text and box height), in reading order. On each
    /// page a line is big when it is at least `bigRatio` times the median height of that page's
    /// lines, its text has 3 to 80 characters, at least half of them letters, and it isn't a
    /// section word (or "for the …"). Big lines next to each other on one page are one title.
    static func bigType(_ pages: [[(text: String, height: Double)]]) -> [Found] {
        var found: [Found] = []
        for (pageIndex, lines) in pages.enumerated() {
            guard let median = medianHeight(lines.map(\.height)), median > 0 else { continue }
            var current: Found?
            for (lineIndex, line) in lines.enumerated() {
                if line.height >= bigRatio * median && isTitleText(line.text) {
                    let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let open = current, open.lastLine == lineIndex - 1 {
                        current = (pageIndex, open.firstLine, lineIndex, open.text + " " + text)
                    } else {
                        if let open = current { found.append(open) }
                        current = (pageIndex, lineIndex, lineIndex, text)
                    }
                } else if let open = current {
                    found.append(open)
                    current = nil
                }
            }
            if let open = current { found.append(open) }
        }
        return found
    }

    /// The pieces the titles cut the pages into, `lineCount` being each page's number of lines:
    /// with two or more titles, from each title's first line to the line before the next title's
    /// (the last one to the end of the last page); with fewer, none. Lines before the first title
    /// belong to no piece.
    static func cut(lineCount: [Int], titles: [Found]) -> [(from: (page: Int, line: Int), to: (page: Int, line: Int))] {
        guard titles.count >= 2, let lastPage = lineCount.indices.last(where: { lineCount[$0] > 0 }) else {
            return []
        }
        let end = (page: lastPage, line: lineCount[lastPage] - 1)
        return titles.indices.compactMap { index in
            let from = (page: titles[index].page, line: titles[index].firstLine)
            let to = index + 1 < titles.count
                ? lineBefore((titles[index + 1].page, titles[index + 1].firstLine), lineCount: lineCount)
                : end
            guard let to else { return nil }
            return (from, to)
        }
    }

    /// The line before `position`: the one above it, else the last line of the nearest page before
    /// with any; nil when there is none.
    private static func lineBefore(_ position: (page: Int, line: Int), lineCount: [Int]) -> (page: Int, line: Int)? {
        if position.line > 0 {
            return (position.page, position.line - 1)
        }
        var page = position.page - 1
        while page >= 0 {
            if lineCount[page] > 0 {
                return (page, lineCount[page] - 1)
            }
            page -= 1
        }
        return nil
    }

    /// 3 to 80 characters, at least half letters, and not a section word or "for the …".
    private static func isTitleText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard titleLength.contains(trimmed.count),
              trimmed.filter(\.isLetter).count * 2 >= trimmed.count else {
            return false
        }
        let normalized = TextMatch.normalize(trimmed)
        return !sectionWords.contains(normalized) && !normalized.hasPrefix("for the ")
    }

    /// The median of the heights, or nil for none.
    private static func medianHeight(_ heights: [Double]) -> Double? {
        guard !heights.isEmpty else { return nil }
        let sorted = heights.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
