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

    static func area(_ lines: [(String, Double)]) -> [HeaderArea.HeaderLine] {
        lines.map { HeaderArea.HeaderLine(text: $0.0, size: $0.1) }
    }

    @Test("the title starts at the model's first line")
    func titleStartsAtModelsFirstLine() {
        let area = Self.area([("Example Kitchen", 1.0), ("Test Soup", 2.0), ("Recipe by Pat Example", 1.0), ("Serves 2", 1.0)])

        let snapped = HeaderArea.snappedTitle("Example Kitchen\nTest Soup\nRecipe by Pat Example", area: area,
                                              author: "Pat Example", sourceHost: "www.examplekitchen.com")

        #expect(snapped.title == "Test Soup")
        #expect(snapped.snapped)
    }

    @Test("a title's next line joins when it continues")
    func nextLineJoinsWhenItContinues() {
        let area = Self.area([("Test", 1.0), ("soup with beans", 2.0), ("Serves 2", 1.0)])

        let snapped = HeaderArea.snappedTitle("Test", area: area)

        #expect(snapped.title == "Test soup with beans")
        #expect(snapped.snapped)
    }

    @Test("a same-size next line joins, a larger one doesn't")
    func sameSizeLineJoinsLargerDoesNot() {
        let area = Self.area([("Test Soup", 2.0), ("With Beans", 1.8), ("Example blurb text", 2.6)])

        let snapped = HeaderArea.snappedTitle("Test Soup\nWith Beans\nExample blurb text", area: area)

        #expect(snapped.title == "Test Soup With Beans")
        #expect(snapped.snapped)
    }

    @Test("a step is no title")
    func stepIsNoTitle() {
        let area = Self.area([("4. Bake the test soup", 3.0)])

        let snapped = HeaderArea.snappedTitle("4. Bake the test soup", area: area)

        #expect(snapped.title == "")
        #expect(!snapped.snapped)
    }

    // MARK: SP-20's two title fixes (`15` M3-1)

    @Test("a one-word author")
    func oneWordAuthorIsNotASideLine() {
        let area = Self.area([("Example Test Soup", 2.0), ("Serves 2", 1.0)])

        let snapped = HeaderArea.snappedTitle("Example Test Soup", area: area, author: "Example")

        #expect(snapped.title == "Example Test Soup")
        #expect(snapped.snapped)
    }

    @Test("a two-word author")
    func twoWordAuthorIsASideLine() {
        let area = Self.area([("Test Soup", 2.0), ("By Pat Example", 2.0), ("Serves 2", 1.0)])

        let snapped = HeaderArea.snappedTitle("Test Soup\nBy Pat Example", area: area, author: "Pat Example")

        #expect(snapped.title == "Test Soup")
        #expect(snapped.snapped)
    }

    @Test("a step as the largest line")
    func stepAsLargestLineIsNoTitle() {
        let area = Self.area([("Example Kitchen", 1.0), ("1. Preheat the oven", 2.0), ("Serves 2", 1.0)])

        let snapped = HeaderArea.snappedTitle("Made-up Title", area: area)

        #expect(snapped.title == "")
        #expect(!snapped.snapped)
    }

    // MARK: The author's line (`15` M3-2a, RV-25)

    @Test("a title holding the author's name")
    func titleHoldingAuthorsName() {
        let area = Self.area([("Pat Example's Test Soup", 2.0), ("Pat Example makes this for her", 1.0),
                              ("family.", 1.0), ("By Pat Example", 1.0)])

        let snapped = HeaderArea.snappedTitle("Pat Example's Test Soup", area: area, author: "Pat Example")

        #expect(snapped.title == "Pat Example's Test Soup")
        #expect(snapped.snapped)
    }

    @Test("the author's name alone")
    func authorsNameAlone() {
        let area = Self.area([("Test Soup", 2.0), ("Pat Example", 1.0)])

        let snapped = HeaderArea.snappedTitle("Test Soup\nPat Example", area: area, author: "Pat Example")

        #expect(snapped.title == "Test Soup")
        #expect(snapped.snapped)
    }

    // MARK: Titles the rules can fix (`15` M3-3s)

    @Test("the labels path keeps five lines")
    func labelsPathKeepsFiveLines() {
        let lines: [(text: String, height: Double)] = (1...8).map { ("Made-up line \($0)", 0.01) }

        #expect(HeaderArea.lines(lines, stopAt: 1).map(\.text) == lines.prefix(5).map(\.text))
        #expect(HeaderArea.lines(lines, stopAt: 6).map(\.text) == lines.prefix(6).map(\.text))
    }

    @Test("a label line isn't title")
    func labelLineIsNotTitle() {
        let area = Self.area([("Made-up Granola", 2.0), ("Author: Made-up Cook Prep Time: 5 mins", 2.0), ("Serves 4", 1.0)])

        let snapped = HeaderArea.snappedTitle("Made-up Granola\nAuthor: Made-up Cook Prep Time: 5 mins", area: area)

        #expect(snapped.title == "Made-up Granola")
        #expect(snapped.snapped)
    }

    @Test("a breadcrumb and navigation line aren't title")
    func breadcrumbAndNavigationAreNotTitle() {
        let area = Self.area([("Made-up Recipes", 1.0), ("Main Index | Made-up Casseroles | All Pages", 1.0),
                              ("Made-up Bean Dish", 1.0)])

        let snapped = HeaderArea.snappedTitle("Made-up Recipes\nMain Index | Made-up Casseroles | All Pages\nMade-up Bean Dish",
                                              area: area)

        #expect(snapped.title == "Made-up Bean Dish")
    }

    // MARK: Titles stop at the ingredients (`15` M3-3t)

    @Test("quantity lines")
    func quantityLines() {
        for line in ["2 bags made-up berries", "½ c made-up sugar", "1½ c made-up port", "1/2 c made-up oil",
                     "2 * made-up meat", "• made-up salt"] {
            #expect(HeaderArea.startsWithQuantity(line), "\(line)")
        }
        for line in ["5-minute made-up dip", "3-Bean Made-up Chili", "Made-up Sauce", ""] {
            #expect(!HeaderArea.startsWithQuantity(line), "\(line)")
        }
    }

    @Test("the labels path stops at a quantity line")
    func labelsPathStopsAtQuantityLine() {
        let lines: [(text: String, height: Double)] = ["Made-up Sauce", "Made-up Berry Relish", "2 bags made-up berries",
                                                       "1 c made-up sugar", "Made-up line 5", "Made-up line 6"].map { ($0, 0.01) }

        #expect(HeaderArea.lines(lines, stopAt: 1).map(\.text) == lines.prefix(2).map(\.text))
        #expect(HeaderArea.lines(lines, stopAt: 4).map(\.text) == lines.prefix(4).map(\.text))
    }

    @Test("a quantity line isn't title")
    func quantityLineIsNotTitle() {
        let area = Self.area([("Made-up Casserole", 1.0), ("8 large made-up potatoes", 1.0), ("1 stick made-up butter", 1.0)])

        let snapped = HeaderArea.snappedTitle("Made-up Casserole\n8 large made-up potatoes\n1 stick made-up butter", area: area)

        #expect(snapped.title == "Made-up Casserole")
    }
}
