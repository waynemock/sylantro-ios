import Foundation

/// The title's candidate lines at the top of the first page, each with its text size against the
/// page's usual text (SLT-148).
nonisolated enum HeaderArea {
    /// One candidate line. `size` is its height over the page's median line height, to one decimal.
    nonisolated struct HeaderLine: Equatable, Sendable {
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

    /// A run's first or last line smaller than this share of its largest line is trimmed (a
    /// site name beside the title, SLT-148).
    private static let titleTrimShare = 0.85

    /// The model's title snapped to the page (SLT-148). An empty answer is no title: `("", false)`.
    /// Otherwise the first run of 1 to 3 consecutive area lines whose joined text normalizes to
    /// `text` is the title, as read, with `snapped` true; a run of 2 or 3 first drops its first
    /// lines, then its last, while they are smaller than 0.85 of the run's largest, keeping at
    /// least one. A non-empty answer that matches nothing gives the largest line (the first of
    /// equal ones), with `snapped` false; an empty area gives `""`.
    static func snappedTitle(_ text: String, area: [HeaderLine]) -> (title: String, snapped: Bool) {
        guard !TextMatch.isEmptyAnswer(text) else {
            return ("", false)
        }
        let wanted = TextMatch.normalize(text)
        for start in area.indices {
            for count in 1...3 where start + count <= area.count {
                var run = Array(area[start..<(start + count)])
                guard TextMatch.normalize(run.map(\.text).joined(separator: " ")) == wanted else {
                    continue
                }
                let threshold = (run.map(\.size).max() ?? 0) * titleTrimShare
                while run.count > 1, let first = run.first, first.size < threshold {
                    run.removeFirst()
                }
                while run.count > 1, let last = run.last, last.size < threshold {
                    run.removeLast()
                }
                return (run.map(\.text).joined(separator: " "), true)
            }
        }
        var largest: HeaderLine?
        for line in area where line.size > (largest?.size ?? -.infinity) {
            largest = line
        }
        return (largest?.text ?? "", false)
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
