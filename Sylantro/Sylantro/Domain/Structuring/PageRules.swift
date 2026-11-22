import Foundation

/// Finds the yield, the times, the source URL and "Page n of m" by rule (SLT-143). The model never
/// fills these.
nonisolated enum PageRules {
    private static let urlPrefixes = ["http://", "https://", "www."]
    private static let urlTrailing: Set<Character> = [".", ",", ")"]
    private static let yieldWords = ["serves", "makes", "yield", "yields", "servings"]
    private static let timeWords = ["prep", "cook", "cooking", "total", "active", "inactive", "hands-on"]

    static func find(in lines: [String]) -> RuleFields {
        var fields = RuleFields()
        fields.sourceURL = sourceURL(in: lines)
        if let page = lines.reversed().lazy.compactMap(pageOf).first {
            fields.pageNumber = page.number
            fields.pageCount = page.count
        }
        fields.yieldText = yieldText(in: lines)
        let timeLines = lines.compactMap(timeText)
        fields.timesText = timeLines.isEmpty ? nil : timeLines.joined(separator: "; ")
        return fields
    }

    // MARK: URL

    /// The longest whitespace-separated token that starts with `http://`, `https://` or `www.`,
    /// with trailing `.`, `,` and `)` removed.
    private static func sourceURL(in lines: [String]) -> String? {
        var best: String?
        for line in lines {
            for token in line.split(whereSeparator: \.isWhitespace) {
                guard urlPrefixes.contains(where: { token.hasPrefix($0) }) else {
                    continue
                }
                var url = String(token)
                while let last = url.last, urlTrailing.contains(last) {
                    url.removeLast()
                }
                if url.count > (best?.count ?? 0) {
                    best = url
                }
            }
        }
        return best
    }

    // MARK: Page n of m

    /// `Page <n> of <m>`, case-insensitive, anywhere in the line. Shared with `PageClutter`.
    static func pageOf(_ line: String) -> (number: Int, count: Int)? {
        let chars = Array(line.lowercased())
        var start = 0
        while start + 4 <= chars.count {
            if String(chars[start..<(start + 4)]) == "page",
               let match = numberOfNumber(chars, from: start + 4) {
                return match
            }
            start += 1
        }
        return nil
    }

    /// Spaces, digits, spaces, `of`, spaces, digits.
    private static func numberOfNumber(_ chars: [Character], from start: Int) -> (number: Int, count: Int)? {
        var index = skipSpaces(chars, from: start)
        guard index > start, let number = digits(chars, at: &index) else {
            return nil
        }
        let ofStart = skipSpaces(chars, from: index)
        guard ofStart > index, ofStart + 2 <= chars.count, String(chars[ofStart..<(ofStart + 2)]) == "of" else {
            return nil
        }
        let countStart = skipSpaces(chars, from: ofStart + 2)
        index = countStart
        guard countStart > ofStart + 2, let count = digits(chars, at: &index) else {
            return nil
        }
        return (number, count)
    }

    // MARK: Yield

    /// The first line, or `|`-separated part of a line, that starts with a yield word followed by a
    /// space, `:` or a digit; as written, trimmed.
    private static func yieldText(in lines: [String]) -> String? {
        for line in lines {
            for part in line.split(separator: "|", omittingEmptySubsequences: false) {
                let text = part.trimmingCharacters(in: .whitespaces)
                let lowered = Array(text.lowercased())
                for word in yieldWords where lowered.starts(with: word) {
                    let next = word.count
                    if next < lowered.count, lowered[next] == " " || lowered[next] == ":" || isDigit(lowered[next]) {
                        return text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        return nil
    }

    // MARK: Times

    /// A labelled time line, trimmed (SLT-149). A line holding `|` keeps only its parts that hold a
    /// time, joined with ` | `. Nil when the line holds no time.
    private static func timeText(_ line: String) -> String? {
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let timed = parts.filter(holdsTime)
        return timed.isEmpty ? nil : timed.joined(separator: " | ")
    }

    /// A time word at the line's start or after a character that isn't a letter, followed by
    /// ` time` (then an optional `:`) or by `:`, then optional spaces, then a digit.
    private static func holdsTime(_ line: String) -> Bool {
        let chars = Array(line.lowercased())
        for word in timeWords {
            let wordChars = Array(word)
            var start = 0
            while start + wordChars.count <= chars.count {
                if Array(chars[start..<(start + wordChars.count)]) == wordChars,
                   start == 0 || !chars[start - 1].isLetter {
                    let afterWord = start + wordChars.count
                    let time = Array(" time")
                    if afterWord + time.count <= chars.count,
                       Array(chars[afterWord..<(afterWord + time.count)]) == time,
                       digitFollows(chars, from: afterWord + time.count) {
                        return true
                    }
                    if afterWord < chars.count, chars[afterWord] == ":", digitFollows(chars, from: afterWord) {
                        return true
                    }
                }
                start += 1
            }
        }
        return false
    }

    /// Optional `:`, optional spaces, then a digit.
    private static func digitFollows(_ chars: [Character], from start: Int) -> Bool {
        var index = start
        if index < chars.count, chars[index] == ":" {
            index += 1
        }
        index = skipSpaces(chars, from: index)
        return index < chars.count && isDigit(chars[index])
    }

    // MARK: Characters

    private static func isDigit(_ character: Character) -> Bool {
        ("0"..."9").contains(character)
    }

    private static func skipSpaces(_ chars: [Character], from start: Int) -> Int {
        var index = start
        while index < chars.count, chars[index] == " " || chars[index] == "\t" {
            index += 1
        }
        return index
    }

    private static func digits(_ chars: [Character], at index: inout Int) -> Int? {
        let start = index
        while index < chars.count, isDigit(chars[index]) {
            index += 1
        }
        guard index > start else {
            return nil
        }
        return Int(String(chars[start..<index]))
    }
}
