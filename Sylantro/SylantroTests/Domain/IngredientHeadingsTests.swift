import Testing
@testable import Sylantro

/// `IngredientHeadings` (`15` RV-38, M3-3h): which lines of an ingredient section are group
/// headings. Every line is made up.
@Suite("Ingredient headings")
struct IngredientHeadingsTests {
    @Test("what a heading is")
    func whatAHeadingIs() {
        let long = String(repeating: "a", count: 69) + ":"
        #expect(long.count == 70)
        let lines = ["For the sauce:", "Plum/Apricot Filling:", "Ingredients:", "1 cup flour:", "Note", long]

        #expect(IngredientHeadings.lines(lines) == [1, 2])
    }
}
