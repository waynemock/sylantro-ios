import Foundation

/// Whether a capture's last page looks unfinished, so Save asks "Is there another page?" (SLT-046,
/// `14` MT-10, MT-27). Given the bottom lines of the page, top to bottom. A wrong "yes" only asks her
/// a question; a wrong "no" is fixed later with Add Page (SLT-045).
nonisolated enum UnfinishedPageCheck {
    /// The rule that made a page look unfinished, for the log (MT-27).
    enum Reason: Sendable, Equatable {
        /// A footer's "Page n of m", "n of m" or "n/m" with n < m.
        case pageNOfM
        /// The last line that isn't a footer ends mid-sentence.
        case endsMidSentence
        /// A word ending in `*` with no line starting with `*`.
        case footnoteAsterisk
    }

    static func looksUnfinished(_ lines: [String]) -> Bool {
        reason(lines) != nil
    }

    /// The rule that fired, or nil when the page looks finished.
    static func reason(_ lines: [String]) -> Reason? {
        let trimmed = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !trimmed.isEmpty else { return nil }

        // 1. Footer lines are set aside: read for rule 2, ignored by rules 3 and 4.
        let footers = trimmed.filter(isFooter)
        let body = trimmed.filter { !isFooter($0) }

        // 2. "Page n of m", or a footer's "n/m" or "n of m", with n < m, alone or ending the line.
        for footer in footers {
            if let (n, m) = trailingPageNumbers(in: footer), n < m {
                return .pageNOfM
            }
        }

        // 3. The last line that isn't a footer ends mid-sentence.
        if let last = body.last, endsMidSentence(last) {
            return .endsMidSentence
        }

        // 4. A footnote asterisk with no footnote.
        let hasAsteriskWord = body.contains { line in
            line.split(separator: " ").contains { $0.count > 1 && $0.hasSuffix("*") }
        }
        let hasFootnote = body.contains { $0.hasPrefix("*") }
        if hasAsteriskWord && !hasFootnote {
            return .footnoteAsterisk
        }

        // 5. Otherwise, finished.
        return nil
    }

    // MARK: The last page

    /// Whether the lines say this is the last page (`15` M3-2a, RV-26): a line, lowercased and
    /// split on spaces, holding the words `page`, n, `of`, m in a row, n and m whole numbers with
    /// n == m ≥ 1. "5/5" and "5 of 5" without `page` don't count: a date or an ingredient could read
    /// that way.
    static func saysLastPage(_ lines: [String]) -> Bool {
        lines.contains { line in
            let words = line.lowercased().split(separator: " ").map(String.init)
            guard words.count >= 4 else { return false }
            return (0...(words.count - 4)).contains { start in
                guard words[start] == "page", words[start + 2] == "of",
                      let n = wholeNumber(words[start + 1]), let m = wholeNumber(words[start + 3]) else {
                    return false
                }
                return n == m && n >= 1
            }
        }
    }

    /// The value of a word of ASCII digits only, or nil.
    private static func wholeNumber(_ word: String) -> Int? {
        guard !word.isEmpty, word.allSatisfy(\.isASCIIDigit) else { return nil }
        return Int(word)
    }

    // MARK: Footers

    /// A line containing a web address anywhere, a line that is or ends with "Page n of m", "n/m" or
    /// "n of m", only a date or time, or only digits (MT-27 widened the first two).
    static func isFooter(_ line: String) -> Bool {
        containsWebAddress(line) || trailingPageNumbers(in: line) != nil || isOnlyDigits(line) || isDateOrTime(line)
    }

    private static func containsWebAddress(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("http://") || lower.contains("https://") || lower.contains("www.")
    }

    private static func isOnlyDigits(_ line: String) -> Bool {
        !line.isEmpty && line.allSatisfy(\.isASCIIDigit)
    }

    /// Digits with `/`, `:`, `,` and `AM`/`PM` only, with at least one `/` or `:`.
    private static func isDateOrTime(_ line: String) -> Bool {
        var rest = line.uppercased()
        for marker in ["AM", "PM"] {
            rest = rest.replacingOccurrences(of: marker, with: "")
        }
        let allowed: Set<Character> = ["/", ":", ",", " ", "."]
        guard rest.contains(where: \.isASCIIDigit),
              rest.contains("/") || rest.contains(":") else {
            return false
        }
        return rest.allSatisfy { $0.isASCIIDigit || allowed.contains($0) }
    }

    /// n and m from a line that is only "Page n of m" (any case), "n/m" or "n of m".
    static func pageNumbers(in line: String) -> (Int, Int)? {
        var words = line.lowercased().split(separator: " ").map(String.init)
        if words.first == "page" {
            words.removeFirst()
            guard words.count == 3, words[1] == "of" else { return nil }
        }
        if words.count == 3, words[1] == "of", let n = Int(words[0]), let m = Int(words[2]) {
            return (n, m)
        }
        let joined = words.joined()
        let parts = joined.split(separator: "/", omittingEmptySubsequences: false)
        if words.count <= 3, parts.count == 2, let n = Int(parts[0]), let m = Int(parts[1]) {
            return (n, m)
        }
        return nil
    }

    /// n and m from a line that is, or ends after other text with, "Page n of m", "n of m" or
    /// "n/m".
    static func trailingPageNumbers(in line: String) -> (Int, Int)? {
        if let numbers = pageNumbers(in: line) { return numbers }
        let words = line.split(separator: " ")
        for count in [4, 3, 1] where words.count > count {
            if let numbers = pageNumbers(in: words.suffix(count).joined(separator: " ")) {
                return numbers
            }
        }
        return nil
    }

    // MARK: Sentences

    /// Ends with a letter, a comma or a hyphen ("and" and "or" end with a letter). A digit
    /// ("Serves 4", MT-27), a full stop, `!`, `?`, `:`, `)` or a closing quote is a finished line.
    private static func endsMidSentence(_ line: String) -> Bool {
        guard let last = line.last else { return false }
        return last.isLetter || last == "," || last == "-"
    }
}

private extension Character {
    nonisolated var isASCIIDigit: Bool { isASCII && isNumber }
}
