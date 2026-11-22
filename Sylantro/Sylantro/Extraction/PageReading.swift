import Foundation

/// What `TextReader` read from one page: its lines, top to bottom as Vision orders them, and the
/// lines' text joined with `\n`.
nonisolated struct PageReading: Codable, Sendable, Equatable {
    /// One recognized line: its top candidate's string and confidence, and where it is.
    nonisolated struct ReadLine: Codable, Sendable, Equatable {
        /// A box normalized 0 to 1, origin top left, as `SourceBox`'s.
        nonisolated struct CGRectCodable: Codable, Sendable, Equatable {
            var x: Double
            var y: Double
            var width: Double
            var height: Double
        }

        var text: String
        var confidence: Double
        var box: CGRectCodable
    }

    var lines: [ReadLine]
    var text: String
    var meanConfidence: Double?
    var minConfidence: Double?

    /// A reading of `lines`, with the text and confidences derived from them.
    init(lines: [ReadLine]) {
        self.lines = lines
        text = lines.map(\.text).joined(separator: "\n")
        let confidences = lines.map(\.confidence)
        meanConfidence = confidences.isEmpty ? nil : confidences.reduce(0, +) / Double(confidences.count)
        minConfidence = confidences.min()
    }
}
