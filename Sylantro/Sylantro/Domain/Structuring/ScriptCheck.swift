import Foundation

/// Whether a read line is in Latin letters (SLT-150). Handwriting read as Cyrillic or Greek
/// look-alikes is unreadable, not text.
nonisolated enum ScriptCheck {
    /// Basic Latin to Latin Extended-B, combining marks, and Latin Extended Additional.
    private static let latinRanges: [ClosedRange<UInt32>] = [0x0000...0x024F, 0x0300...0x036F, 0x1E00...0x1EFF]

    /// True when every letter's unicode scalars are all Latin. A line with no letters is Latin.
    static func isLatin(_ line: String) -> Bool {
        line.allSatisfy { character in
            !character.isLetter || character.unicodeScalars.allSatisfy { scalar in
                latinRanges.contains { $0.contains(scalar.value) }
            }
        }
    }
}
