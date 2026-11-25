import Foundation

/// How far the queue is through reading one recipe (`13` SC-23, `15` M3-3f), by the steps it
/// knows: each page read, then each of the three parts structured. The model reports nothing
/// within a call, so the bar moves by these steps.
nonisolated struct ReadingProgress: Sendable, Equatable {
    /// The parts that count, as the structurer names them; `lineLabels` and the fallbacks don't.
    static let parts = ["header", "ingredients", "steps"]

    /// The pages with no reading when the job started; pages already read (RV-4) aren't counted.
    let pagesToRead: Int
    private(set) var pagesRead = 0
    private(set) var partsDone: Set<String> = []

    init(pagesToRead: Int) {
        self.pagesToRead = max(pagesToRead, 0)
    }

    /// One more page read, never past `pagesToRead`.
    mutating func pageRead() {
        pagesRead = min(pagesRead + 1, pagesToRead)
    }

    /// A part structured; a part not in `parts` changes nothing, and a part counts once.
    mutating func partDone(_ part: String) {
        if Self.parts.contains(part) {
            partsDone.insert(part)
        }
    }

    /// (pages read + parts done) ÷ (pages to read + 3), from 0 to 1.
    var fraction: Double {
        let total = pagesToRead + Self.parts.count
        return min(max(Double(pagesRead + partsDone.count) / Double(total), 0), 1)
    }
}
