import Foundation

/// Reads the quantity and unit at the start of one ingredient line and hands back the rest
/// (`06` Task M1-2). Splitting the rest into item and preparation is the structurer's job. Pure: no
/// state, no locale.
nonisolated enum IngredientLineParser {
    /// Rule 1's whitespace: spaces, tabs and non-breaking spaces.
    private static let whitespace: Set<Character> = [" ", "\t", "\u{00A0}"]

    /// Rule 2, tried in this order, matched case-insensitively.
    private static let approximatePrefixes = ["about ", "approximately ", "approx. ", "approx ", "~"]

    /// Rule 3's unicode fractions: the one table, also read by `TextMatch` and `WrapJoiner`
    /// (`00A` §10).
    static let unicodeFractions: [Character: (numerator: Int, denominator: Int)] = [
        "¼": (1, 4), "½": (1, 2), "¾": (3, 4), "⅓": (1, 3), "⅔": (2, 3), "⅕": (1, 5),
        "⅙": (1, 6), "⅛": (1, 8), "⅜": (3, 8), "⅝": (5, 8), "⅞": (7, 8),
    ]

    /// Rule 3's number words, each followed by a space, in the order tried (`a dozen` before `a`,
    /// SLT-049).
    private static let numberWords: [(word: String, value: Double)] = [
        ("a dozen", 12), ("dozen", 12), ("a", 1), ("an", 1), ("one", 1), ("two", 2), ("three", 3),
        ("four", 4), ("five", 5), ("six", 6), ("seven", 7), ("eight", 8), ("nine", 9), ("ten", 10),
        ("eleven", 11), ("twelve", 12),
    ]

    /// Words that start a line with no quantity, checked before rule 3 (SLT-155).
    private static let vagueAmounts = ["a few ", "a couple of ", "a couple ", "several "]

    /// What follows an amount, after a dash, to make it a size rather than a quantity (SLT-155).
    private static let sizeWords = ["inch", "in."]

    /// Rule 3's range marks; the word `to` is handled separately.
    private static let rangeDashes: Set<Character> = ["-", "\u{2013}", "\u{2014}"]

    static func parse(_ line: String) -> ParsedLine {
        // Rule 1: trim.
        let trimmed = trim(Array(line))
        let unparsed = ParsedLine(quantity: nil, unit: nil, rest: String(trimmed))
        var position = 0

        // Rule 2: an approximate prefix, undone below if no quantity follows.
        var isApproximate = false
        for prefix in approximatePrefixes where hasPrefix(trimmed, at: 0, prefix) {
            isApproximate = true
            position = skipSpaces(trimmed, from: prefix.count)
            break
        }

        // "A few", "a couple (of)" and "several" are no quantity (SLT-155).
        if vagueAmounts.contains(where: { hasPrefix(trimmed, at: position, $0) }) {
            return unparsed
        }

        // Rule 3: an amount, then optionally a range end.
        var zeroDenominator = false
        guard let first = amount(trimmed, at: position, zeroDenominator: &zeroDenominator),
              !zeroDenominator else {
            return unparsed
        }
        // An amount joined to "-inch" or "-in." is a size, so the line has no quantity (SLT-155).
        if isSize(trimmed, at: first.end) {
            return unparsed
        }
        position = first.end
        var maximum: Double?
        if let rangeStart = rangeEndStart(trimmed, from: position) {
            if let second = amount(trimmed, at: rangeStart, zeroDenominator: &zeroDenominator) {
                maximum = second.value
                position = second.end
            }
            if zeroDenominator {
                return unparsed
            }
        }
        let quantity = Quantity(min: first.value, max: maximum, isApproximate: isApproximate)

        // Rule 4: the unit.
        var unit: UnitRef?
        let wordStart = skipSpaces(trimmed, from: position)
        let firstWordEnd = wordEnd(trimmed, from: wordStart)
        if firstWordEnd > wordStart {
            let firstWord = String(trimmed[wordStart..<firstWordEnd])
            // Two words, when exactly one space separates them.
            let secondStart = firstWordEnd + 1
            if secondStart < trimmed.count, trimmed[firstWordEnd] == " ", trimmed[secondStart] != " " {
                let secondWordEnd = wordEnd(trimmed, from: secondStart)
                if secondWordEnd > secondStart {
                    let raw = String(trimmed[wordStart..<secondWordEnd])
                    let key = raw.replacingOccurrences(of: ".", with: "").lowercased()
                    if let canonical = UnitSpellings.twoWord[key] {
                        unit = UnitRef(canonical: canonical, raw: raw)
                        position = secondWordEnd
                    }
                }
            }
            // One word: case-sensitive spellings first, then lowercased without one trailing `.`.
            if unit == nil, let canonical = oneWordUnit(firstWord) {
                unit = UnitRef(canonical: canonical, raw: firstWord)
                position = firstWordEnd
            }
        }

        // Rule 5: "of" directly after a matched unit.
        if unit != nil {
            let ofStart = skipSpaces(trimmed, from: position)
            if hasPrefix(trimmed, at: ofStart, "of ") {
                position = ofStart + 3
            }
        }

        // Rule 6: the rest.
        let rest = trim(Array(trimmed[min(position, trimmed.count)...]))
        return ParsedLine(quantity: quantity, unit: unit, rest: String(rest))
    }

    // MARK: Amounts

    /// The first amount that matches at `start`: a mixed number, a fraction, a unicode fraction, a
    /// decimal, an integer or a number word. A fraction with a zero denominator sets
    /// `zeroDenominator` and matches nothing, so no shorter amount is tried.
    private static func amount(
        _ chars: [Character],
        at start: Int,
        zeroDenominator: inout Bool
    ) -> (value: Double, end: Int)? {
        let integerEnd = digitsEnd(chars, from: start)
        if integerEnd > start {
            let whole = number(chars, start..<integerEnd)
            let afterSpaces = skipSpaces(chars, from: integerEnd)
            // A mixed number: an integer, spaces, then a fraction.
            if afterSpaces > integerEnd,
               let fraction = fraction(chars, at: afterSpaces, zeroDenominator: &zeroDenominator) {
                return (whole + fraction.value, fraction.end)
            }
            if zeroDenominator {
                return nil
            }
            // A mixed number: an integer, then directly or after spaces a unicode fraction.
            if afterSpaces < chars.count, let unicode = unicodeFractions[chars[afterSpaces]] {
                return (whole + Double(unicode.numerator) / Double(unicode.denominator), afterSpaces + 1)
            }
            // A fraction.
            if let fraction = fraction(chars, at: start, zeroDenominator: &zeroDenominator) {
                return fraction
            }
            if zeroDenominator {
                return nil
            }
        }
        // A unicode fraction alone.
        if start < chars.count, let unicode = unicodeFractions[chars[start]] {
            return (Double(unicode.numerator) / Double(unicode.denominator), start + 1)
        }
        // A decimal: digits `.` digits, or `.` digits.
        let pointIndex = integerEnd
        if pointIndex < chars.count, chars[pointIndex] == "." {
            let fractionEnd = digitsEnd(chars, from: pointIndex + 1)
            if fractionEnd > pointIndex + 1 {
                return (number(chars, start..<fractionEnd), fractionEnd)
            }
        }
        // An integer.
        if integerEnd > start {
            return (number(chars, start..<integerEnd), integerEnd)
        }
        // A number word, followed by a space.
        for numberWord in numberWords where hasPrefix(chars, at: start, numberWord.word + " ") {
            return (numberWord.value, start + numberWord.word.count)
        }
        return nil
    }

    /// Integer `/` integer, with `/` or the fraction slash U+2044.
    private static func fraction(
        _ chars: [Character],
        at start: Int,
        zeroDenominator: inout Bool
    ) -> (value: Double, end: Int)? {
        let numeratorEnd = digitsEnd(chars, from: start)
        guard numeratorEnd > start, numeratorEnd < chars.count,
              chars[numeratorEnd] == "/" || chars[numeratorEnd] == "\u{2044}" else {
            return nil
        }
        let denominatorEnd = digitsEnd(chars, from: numeratorEnd + 1)
        guard denominatorEnd > numeratorEnd + 1 else {
            return nil
        }
        let numerator = number(chars, start..<numeratorEnd)
        let denominator = number(chars, (numeratorEnd + 1)..<denominatorEnd)
        guard denominator != 0 else {
            zeroDenominator = true
            return nil
        }
        return (numerator / denominator, denominatorEnd)
    }

    /// A dash (`-`, `–` or `—`), then `inch` or `in.` in any case, then a space or the end.
    private static func isSize(_ chars: [Character], at start: Int) -> Bool {
        guard start < chars.count, rangeDashes.contains(chars[start]) else {
            return false
        }
        return sizeWords.contains { word in
            let end = start + 1 + word.count
            return hasPrefix(chars, at: start + 1, word) && (end == chars.count || chars[end] == " ")
        }
    }

    /// Where a range end's amount starts: optional spaces, then `-`, `–` or `—`, or the word `to`
    /// between spaces, then optional spaces. Nil when there is no range mark.
    private static func rangeEndStart(_ chars: [Character], from start: Int) -> Int? {
        let markStart = skipSpaces(chars, from: start)
        guard markStart < chars.count else {
            return nil
        }
        if rangeDashes.contains(chars[markStart]) {
            return skipSpaces(chars, from: markStart + 1)
        }
        if markStart > start, hasPrefix(chars, at: markStart, "to ") {
            return skipSpaces(chars, from: markStart + 2)
        }
        return nil
    }

    // MARK: Units

    /// The next word: the run of letters and `.` up to a space, a digit, `(`, `,` or the end.
    private static func wordEnd(_ chars: [Character], from start: Int) -> Int {
        var index = start
        while index < chars.count, chars[index].isLetter || chars[index] == "." {
            index += 1
        }
        return index
    }

    private static func oneWordUnit(_ word: String) -> CanonicalUnit? {
        if let canonical = UnitSpellings.caseSensitive[word] {
            return canonical
        }
        var key = word.lowercased()
        if key.hasSuffix(".") {
            key.removeLast()
        }
        return UnitSpellings.oneWord[key]
    }

    // MARK: Characters

    private static func trim(_ chars: [Character]) -> [Character] {
        var lower = 0
        var upper = chars.count
        while lower < upper, whitespace.contains(chars[lower]) {
            lower += 1
        }
        while upper > lower, whitespace.contains(chars[upper - 1]) {
            upper -= 1
        }
        return Array(chars[lower..<upper])
    }

    private static func skipSpaces(_ chars: [Character], from start: Int) -> Int {
        var index = start
        while index < chars.count, chars[index] == " " {
            index += 1
        }
        return index
    }

    private static func isDigit(_ character: Character) -> Bool {
        ("0"..."9").contains(character)
    }

    private static func digitsEnd(_ chars: [Character], from start: Int) -> Int {
        var index = start
        while index < chars.count, isDigit(chars[index]) {
            index += 1
        }
        return index
    }

    /// The value of ASCII digits, with at most one `.`, read without a locale.
    private static func number(_ chars: [Character], _ range: Range<Int>) -> Double {
        Double("0" + String(chars[range])) ?? 0
    }

    /// Whether `prefix` appears at `start`, compared case-insensitively.
    private static func hasPrefix(_ chars: [Character], at start: Int, _ prefix: String) -> Bool {
        let prefixChars = Array(prefix)
        guard start + prefixChars.count <= chars.count else {
            return false
        }
        return String(chars[start..<(start + prefixChars.count)]).lowercased() == prefix
    }
}
