import Foundation

/// Lines that belong to no section of a recipe (SLT-149): a web address line, "Page n of m", or a
/// printed date, as a browser prints them at a page's top and foot.
nonisolated enum PageClutter {
    /// Also a line with a web address anywhere in it, as a misread footer gives it (`15` M3-3m).
    static func isClutter(_ line: String) -> Bool {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstToken = text.split(whereSeparator: \.isWhitespace).first {
            let token = firstToken.lowercased()
            if token.contains("://") || token.hasPrefix("www.") {
                return true
            }
        }
        if PageRules.pageOf(text) != nil {
            return true
        }
        if text.split(separator: " ").contains(where: { isWebAddressWord(String($0)) }) {
            return true
        }
        return startsWithDate(text)
    }

    /// A word, its trailing punctuation ignored, that is `www`, starts with `www.`, contains
    /// `.com/`, or ends with `.com`, `.org` or `.net` (M3-3m).
    private static func isWebAddressWord(_ word: String) -> Bool {
        var word = word.lowercased()
        while let last = word.unicodeScalars.last, CharacterSet.punctuationCharacters.contains(last) {
            word.removeLast()
        }
        return word == "www" || word.hasPrefix("www.") || word.contains(".com/")
            || word.hasSuffix(".com") || word.hasSuffix(".org") || word.hasSuffix(".net")
    }

    /// 1 or 2 digits, `/`, 1 or 2 digits, `/`, 2 or 4 digits.
    private static func startsWithDate(_ text: String) -> Bool {
        let chars = Array(text)
        var index = 0

        func digitRun() -> Int {
            let start = index
            while index < chars.count, ("0"..."9").contains(chars[index]) {
                index += 1
            }
            return index - start
        }

        guard (1...2).contains(digitRun()), index < chars.count, chars[index] == "/" else {
            return false
        }
        index += 1
        guard (1...2).contains(digitRun()), index < chars.count, chars[index] == "/" else {
            return false
        }
        index += 1
        let year = digitRun()
        return year == 2 || year == 4
    }
}
