import Foundation

/// Whether a capture's last page looks unfinished, so Save asks "Is there a page 2?" (SLT-046,
/// `14` MT-10). Given the bottom lines of the page, top to bottom. A wrong "yes" only asks her a
/// question; a wrong "no" is fixed later with Add Page (SLT-045).
nonisolated enum UnfinishedPageCheck {
    static func looksUnfinished(_ lines: [String]) -> Bool {
        let trimmed = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !trimmed.isEmpty else { return false }

        // 1. Footer lines are set aside: read for rule 2, ignored by rules 3 and 4.
        let footers = trimmed.filter(isFooter)
        let body = trimmed.filter { !isFooter($0) }

        // 2. "Page n of m", or a footer's "n/m" or "n of m", with n < m.
        for footer in footers {
            if let (n, m) = pageNumbers(in: footer), n < m {
                return true
            }
        }

        // 3. The last line that isn't a footer ends mid-sentence.
        if let last = body.last, endsMidSentence(last) {
            return true
        }

        // 4. A footnote asterisk with no footnote.
        let hasAsteriskWord = body.contains { line in
            line.split(separator: " ").contains { $0.count > 1 && $0.hasSuffix("*") }
        }
        let hasFootnote = body.contains { $0.hasPrefix("*") }
        if hasAsteriskWord && !hasFootnote {
            return true
        }

        // 5. Otherwise, false.
        return false
    }

    // MARK: Footers

    /// Only a web address, a date or time, "Page n of m", "n/m" or "n of m", or only digits.
    static func isFooter(_ line: String) -> Bool {
        isWebAddress(line) || pageNumbers(in: line) != nil || isOnlyDigits(line) || isDateOrTime(line)
    }

    private static func isWebAddress(_ line: String) -> Bool {
        let lower = line.lowercased()
        let startsLikeAddress = lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("www.")
        return startsLikeAddress && !line.contains(" ")
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

    // MARK: Sentences

    /// Ends with a letter, a digit, a comma or a hyphen ("and" and "or" end with a letter). A
    /// full stop, `!`, `?`, `:`, `)` or a closing quote is a finished line.
    private static func endsMidSentence(_ line: String) -> Bool {
        guard let last = line.last else { return false }
        return last.isLetter || last.isNumber || last == "," || last == "-"
    }
}

private extension Character {
    nonisolated var isASCIIDigit: Bool { isASCII && isNumber }
}
