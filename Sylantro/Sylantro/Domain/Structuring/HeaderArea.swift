import Foundation

/// The title's candidate lines at the top of the first page, each with its text size against the
/// page's usual text (SLT-148).
nonisolated enum HeaderArea {
    /// One candidate line. `size` is its height over the page's median line height, to one decimal.
    nonisolated struct HeaderLine: Codable, Equatable, Sendable {
        var text: String
        var size: Double
    }

    /// At most this many lines are taken from the top.
    private static let maximumLines = 25
    /// When the area would be empty, this many lines are taken instead.
    private static let fallbackLines = 10
    /// On the labels path the area runs at least this many lines (SP-21, `15` M3-3s).
    private static let minimumLabelledLines = 5

    /// `lines` is the first page's lines in reading order, with each box's height. `stopAt` is the
    /// index of the first line labelled `ingredient` or `step`, when labels ran; the area then runs
    /// to the later of it and the 5th line (SP-21, `15` M3-3s), the lines added after `stopAt`
    /// stopping before the first quantity line (`15` M3-3t).
    static func lines(_ lines: [(text: String, height: Double)], stopAt: Int?) -> [HeaderLine] {
        // 1. The end: the first labelled ingredient or step, but not before the 5th line unless a
        // quantity line comes first (lines before `stopAt` are always kept); else the first
        // heading, else the page.
        let end = stopAt.map { stopAt in
            let firstQuantity = lines.prefix(minimumLabelledLines).firstIndex { startsWithQuantity($0.text) }
            return max(stopAt, min(minimumLabelledLines, firstQuantity ?? minimumLabelledLines))
        } ?? lines.firstIndex { PageSplitter.heading($0.text) != nil } ?? lines.count
        var taken = Array(lines.prefix(min(max(end, 0), maximumLines)))
        // 2. Nothing before the end: the first lines instead.
        if taken.isEmpty {
            taken = Array(lines.prefix(fallbackLines))
        }
        // 3. Clutter, non-Latin and heading lines are dropped.
        taken.removeAll {
            PageClutter.isClutter($0.text) || !ScriptCheck.isLatin($0.text) || PageSplitter.heading($0.text) != nil
        }
        // 4. Sizes against the median height of the whole page.
        let median = medianHeight(lines.map(\.height))
        return taken.map { line in
            guard let median, median > 0 else {
                return HeaderLine(text: line.text, size: 1.0)
            }
            return HeaderLine(text: line.text, size: (line.height / median * 10).rounded() / 10)
        }
    }

    /// The size band, against the title's first line, in which the model's next line joins it.
    private static let sameSizeRange = 0.8...1.25
    /// A title takes in at most this many area lines.
    private static let maximumTitleLines = 3
    /// A site-name line needs at least this many letters and digits to match the host.
    private static let minimumSiteNameLength = 4

    /// The host of a printed URL: lowercased, any scheme and `://` removed, up to the first `/`.
    /// Nil for nil or empty.
    static func host(of url: String?) -> String? {
        guard var text = url?.lowercased(), !text.isEmpty else {
            return nil
        }
        if let scheme = text.range(of: "://") {
            text = String(text[scheme.upperBound...])
        }
        return String(text.prefix { $0 != "/" })
    }

    /// The model's title snapped to the page (SLT-148), in order: an empty answer is no title,
    /// `("", false)`. The answer's lines, less side lines (the site's name, or the author's line:
    /// the name alone, or `by` and the name), give
    /// the start: the first area line equal to the first of them, else the first run of 2 or 3
    /// lines matching it. The title takes in the following area lines, up to 3 in all, while each
    /// isn't a side line and either starts lowercase or is the model's next line at 0.8 to 1.25
    /// times the start's size, and isn't a quantity line (`15` M3-3t). A title starting with a step
    /// number is no title. Navigation lines
    /// (` | ` twice or more) and the breadcrumb line just before one are never title: the model's
    /// lines equal to one are dropped with the side lines, and the title never takes one in
    /// (`15` M3-3s). An answer with no
    /// line left, or none found, gives the largest line (the first of equal ones), with `snapped`
    /// false; an empty area gives `""`, and so does a largest line starting with a step number.
    static func snappedTitle(_ text: String, area: [HeaderLine], author: String? = nil,
                             sourceHost: String? = nil) -> (title: String, snapped: Bool) {
        // 1. Empty.
        guard !TextMatch.isEmptyAnswer(text) else {
            return ("", false)
        }

        // 2. The model's lines, less side lines and the area's navigation and breadcrumb lines.
        let barred = barredLines(in: area)
        let barredTexts = Set(barred.map { TextMatch.normalize(area[$0].text) })
        // A label line is a side line, but not as the model's first line: a title that is itself
        // one is unchanged.
        let modelLines = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .enumerated()
            .filter { !isSideLine($0.element, author: author, sourceHost: sourceHost, labels: $0.offset > 0) }
            .map { TextMatch.normalize($0.element) }
            .filter { !barredTexts.contains($0) }

        // 3. The start: one area line, else a run of 2 or 3.
        guard let firstModelLine = modelLines.first, let start = startRun(of: firstModelLine, in: area) else {
            // The largest line, unless it is a step.
            let largest = largestLine(area)
            return (startsWithStepNumber(largest) ? "" : largest, false)
        }

        // 4. The next lines.
        var titleLines = Array(area[start])
        var nextModelLine = 1
        let startSize = area[start.lowerBound].size
        var index = start.upperBound
        while titleLines.count < maximumTitleLines, index < area.count {
            let line = area[index]
            guard !isSideLine(line.text, author: author, sourceHost: sourceHost), !barred.contains(index),
                  !startsWithQuantity(line.text) else {
                break
            }
            let normalized = TextMatch.normalize(line.text)
            let isModelsNext = nextModelLine < modelLines.count && normalized == modelLines[nextModelLine]
            let continues = line.text.first?.isLowercase ?? false
            let sameSize = startSize == 0 || sameSizeRange.contains(line.size / startSize)
            guard continues || (isModelsNext && sameSize) else {
                break
            }
            titleLines.append(line)
            if isModelsNext {
                nextModelLine += 1
            }
            index += 1
        }

        // 5. A step is no title.
        let title = titleLines.map(\.text).joined(separator: " ")
        if startsWithStepNumber(title) {
            return ("", false)
        }

        // 6. The lines as read.
        return (title, true)
    }

    /// The area range the title starts at: the first line equal to `modelLine`, else the first
    /// run of 2 or 3 lines whose joined text normalizes to it.
    private static func startRun(of modelLine: String, in area: [HeaderLine]) -> Range<Int>? {
        if let index = area.firstIndex(where: { TextMatch.normalize($0.text) == modelLine }) {
            return index..<(index + 1)
        }
        for start in area.indices {
            for count in 2...3 where start + count <= area.count {
                if TextMatch.normalize(area[start..<(start + count)].map(\.text).joined(separator: " ")) == modelLine {
                    return start..<(start + count)
                }
            }
        }
        return nil
    }

    /// The normalized starts of a label line (`15` M3-3s, moved from M3-5): each followed by a
    /// space (a printed `:` normalizes to one) and more text.
    private static let labelStarts = [
        "author", "by", "prep time", "cook time", "total time", "active time", "yield", "serves", "servings", "makes",
    ]

    /// The indexes of the area's navigation lines (holding ` | ` two or more times) and of the line
    /// just before each, its breadcrumb (`15` M3-3s).
    private static func barredLines(in area: [HeaderLine]) -> Set<Int> {
        var barred = Set<Int>()
        for (index, line) in area.enumerated() where line.text.components(separatedBy: " | ").count >= 3 {
            barred.insert(index)
            if index > 0 {
                barred.insert(index - 1)
            }
        }
        return barred
    }

    /// A line that is the site's name (its letters and digits, at least 4, found in the host
    /// without dots) or the author's line: the name alone, or `by` and the name, compared
    /// normalized (`15` M3-2a, RV-25). A title that merely holds the name isn't one. Also a label
    /// line, such as "Author: … Prep Time: …" (`15` M3-3s), unless `labels` is false.
    private static func isSideLine(_ line: String, author: String?, sourceHost: String?, labels: Bool = true) -> Bool {
        let normalized = TextMatch.normalize(line)
        if labels, labelStarts.contains(where: { normalized.hasPrefix($0 + " ") && normalized.count > $0.count + 1 }) {
            return true
        }
        if let sourceHost {
            let letters = String(line.lowercased().filter { $0.isLetter || ("0"..."9").contains($0) })
            if letters.count >= minimumSiteNameLength, sourceHost.replacingOccurrences(of: ".", with: "").contains(letters) {
                return true
            }
        }
        if !TextMatch.isEmptyAnswer(author), let author {
            let name = TextMatch.normalize(author)
            let normalizedLine = TextMatch.normalize(line)
            if !name.isEmpty, normalizedLine == name || (" " + normalizedLine + " ").contains(" by " + name + " ") {
                return true
            }
        }
        return false
    }

    /// Whether the text, trimmed, starts with a bullet (as `PageSplitter.removingBullet` finds one),
    /// or with a quantity and a space: digits, a fraction such as `1/2`, a fraction character, or
    /// digits joined to one (`1½`) (`15` M3-3t). "5-minute …" and "3-Bean …" aren't.
    nonisolated static func startsWithQuantity(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if PageSplitter.removingBullet(trimmed) != trimmed {
            return true
        }
        let characters = Array(trimmed)
        var index = 0
        while index < characters.count, ("0"..."9").contains(characters[index]) {
            index += 1
        }
        let digits = index
        if digits > 0, index + 1 < characters.count, characters[index] == "/", ("0"..."9").contains(characters[index + 1]) {
            index += 1
            while index < characters.count, ("0"..."9").contains(characters[index]) {
                index += 1
            }
        } else if index < characters.count, IngredientLineParser.unicodeFractions[characters[index]] != nil {
            index += 1
        } else if digits == 0 {
            return false
        }
        return index < characters.count && characters[index] == " "
    }

    /// One or more digits, then `.` or `)`, then a space.
    private static func startsWithStepNumber(_ text: String) -> Bool {
        let digits = text.prefix { ("0"..."9").contains($0) }
        let rest = text.dropFirst(digits.count)
        guard !digits.isEmpty, let mark = rest.first, mark == "." || mark == ")" else {
            return false
        }
        return rest.dropFirst().first == " "
    }

    /// The largest line (the first of equal ones), or `""` for an empty area.
    private static func largestLine(_ area: [HeaderLine]) -> String {
        var largest: HeaderLine?
        for line in area where line.size > (largest?.size ?? -.infinity) {
            largest = line
        }
        return largest?.text ?? ""
    }

    /// The median of the heights, or nil when none is above 0.
    private static func medianHeight(_ heights: [Double]) -> Double? {
        guard heights.contains(where: { $0 > 0 }) else {
            return nil
        }
        let sorted = heights.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
