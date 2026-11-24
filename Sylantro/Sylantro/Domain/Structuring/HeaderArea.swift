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

    /// `lines` is the first page's lines in reading order, with each box's height. `stopAt` is the
    /// index of the first line labelled `ingredient` or `step`, when labels ran.
    static func lines(_ lines: [(text: String, height: Double)], stopAt: Int?) -> [HeaderLine] {
        // 1. The end: the first labelled ingredient or step, else the first heading, else the page.
        let end = stopAt ?? lines.firstIndex { PageSplitter.heading($0.text) != nil } ?? lines.count
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
    /// `("", false)`. The answer's lines, less side lines (the site's name or the author's), give
    /// the start: the first area line equal to the first of them, else the first run of 2 or 3
    /// lines matching it. The title takes in the following area lines, up to 3 in all, while each
    /// isn't a side line and either starts lowercase or is the model's next line at 0.8 to 1.25
    /// times the start's size. A title starting with a step number is no title. An answer with no
    /// line left, or none found, gives the largest line (the first of equal ones), with `snapped`
    /// false; an empty area gives `""`, and so does a largest line starting with a step number.
    static func snappedTitle(_ text: String, area: [HeaderLine], author: String? = nil,
                             sourceHost: String? = nil) -> (title: String, snapped: Bool) {
        // 1. Empty.
        guard !TextMatch.isEmptyAnswer(text) else {
            return ("", false)
        }

        // 2. The model's lines, less side lines.
        let modelLines = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !isSideLine($0, author: author, sourceHost: sourceHost) }
            .map(TextMatch.normalize)

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
            guard !isSideLine(line.text, author: author, sourceHost: sourceHost) else {
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

    /// A line that is the site's name (its letters and digits, at least 4, found in the host
    /// without dots) or holds the author's name. A one-word author name is ignored (`15` M3-1).
    private static func isSideLine(_ line: String, author: String?, sourceHost: String?) -> Bool {
        if let sourceHost {
            let letters = String(line.lowercased().filter { $0.isLetter || ("0"..."9").contains($0) })
            if letters.count >= minimumSiteNameLength, sourceHost.replacingOccurrences(of: ".", with: "").contains(letters) {
                return true
            }
        }
        if !TextMatch.isEmptyAnswer(author), let author {
            let name = TextMatch.normalize(author)
            if name.contains(" "), TextMatch.normalize(line).contains(name) {
                return true
            }
        }
        return false
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
