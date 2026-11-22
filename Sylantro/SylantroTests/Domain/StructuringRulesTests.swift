import Foundation
import Testing
@testable import Sylantro

/// `ScriptCheck` (SLT-150) and `HeaderArea` (SLT-148), `11` M1-5. Every line is made up.
@Suite("Structuring rules")
struct StructuringRulesTests {
    @Test("non-Latin letters are caught")
    func nonLatinLettersAreCaught() {
        #expect(ScriptCheck.isLatin("2 T paprika"))
        #expect(ScriptCheck.isLatin("1½ cups crème fraîche"))
        // Cyrillic Т and р.
        #expect(!ScriptCheck.isLatin("2 \u{0422} \u{0440}\u{0430}\u{0440}\u{0438}\u{043A}\u{0430}"))
    }

    @Test("the header area stops at the first heading")
    func headerAreaStopsAtFirstHeading() {
        let lines: [(text: String, height: Double)] = [
            ("Example Recipes", 0.01), ("Page 1 of 1", 0.01), ("Test Soup", 0.02),
            ("Serves 2", 0.01), ("Ingredients", 0.012), ("1 cup water", 0.01),
        ]
        let area = HeaderArea.lines(lines, stopAt: nil)
        #expect(area == [
            HeaderArea.HeaderLine(text: "Example Recipes", size: 1.0),
            HeaderArea.HeaderLine(text: "Test Soup", size: 2.0),
            HeaderArea.HeaderLine(text: "Serves 2", size: 1.0),
        ])
    }

    @Test("a 'none' answer is empty")
    func noneAnswerIsEmpty() {
        #expect(TextMatch.isEmptyAnswer(nil))
        #expect(TextMatch.isEmptyAnswer(""))
        #expect(TextMatch.isEmptyAnswer("none"))
        #expect(TextMatch.isEmptyAnswer(" None "))
        #expect(TextMatch.isEmptyAnswer("N/A"))
        #expect(!TextMatch.isEmptyAnswer("nonfat milk"))
        #expect(!TextMatch.isEmptyAnswer("1 cup water"))
    }

    @Test("wrapped lines are joined by rule")
    func wrappedLinesAreJoined() {
        let lines = ["1 cup grape juice, such as", "Concord", "1 cup flour,", "sifted", "• 1 egg",
                     "3 tea-", "spoons salt", "(about 2 cups)"]
        #expect(WrapJoiner.join(lines) == ["1 cup grape juice, such as Concord", "1 cup flour, sifted", "• 1 egg",
                                           "3 teaspoons salt (about 2 cups)"])
    }

    @Test("a new ingredient is never joined")
    func newIngredientIsNeverJoined() {
        let lines = ["2 cups water,", "1 cup flour", "½ cup sugar"]
        #expect(WrapJoiner.join(lines) == lines)
    }

    @Test("the title snaps to the page's lines")
    func titleSnapsToPageLines() {
        let area = [("Example Kitchen", 1.0), ("Test", 2.0), ("Soup", 2.0), ("Serves 2", 1.0)]
            .map { HeaderArea.HeaderLine(text: $0.0, size: $0.1) }

        let match = HeaderArea.snappedTitle("test soup", area: area)
        #expect(match.title == "Test Soup")
        #expect(match.snapped)

        let unmatched = HeaderArea.snappedTitle("Made-up Title", area: area)
        #expect(unmatched.title == "Test")
        #expect(!unmatched.snapped)

        let none = HeaderArea.snappedTitle("none", area: area)
        #expect(none.title == "")
        #expect(!none.snapped)
    }

    @Test("a smaller line is trimmed from the title")
    func smallerLineIsTrimmedFromTitle() {
        let area = [("Example Kitchen", 1.0), ("Test Soup", 2.0), ("Serves 2", 1.0)]
            .map { HeaderArea.HeaderLine(text: $0.0, size: $0.1) }

        let snapped = HeaderArea.snappedTitle("example kitchen test soup", area: area)

        #expect(snapped.title == "Test Soup")
        #expect(snapped.snapped)
    }
}
