import Testing
@testable import Sylantro

/// `PageTitles` (`15` RV-35, M3-5s): titles found by their type size, and the pages cut by them.
/// Every line is made up.
@Suite("Page titles")
struct PageTitlesTests {
    /// A page's lines, body lines 10 high and the ones named 16 high.
    static func page(_ texts: [String], big: Set<Int> = []) -> [(text: String, height: Double)] {
        texts.enumerated().map { index, text in (text, big.contains(index) ? 16 : 10) }
    }

    @Test("big lines are titles")
    func bigLinesAreTitles() {
        let page = Self.page(["Made-up Soup", "1 cup water", "Boil the water.", "Made-up Salad", "2 cups lettuce",
                              "Toss it."], big: [0, 3])

        let found = PageTitles.bigType([page])

        #expect(found.map(\.text) == ["Made-up Soup", "Made-up Salad"])
        #expect(found.map(\.firstLine) == [0, 3])
    }

    @Test("a section word isn't")
    func sectionWordIsNot() {
        let page = Self.page(["Ingredients", "1 cup water", "2 cups stock", "Boil the water."], big: [0])

        #expect(PageTitles.bigType([page]).isEmpty)
    }

    @Test("a wrapped title is one")
    func wrappedTitleIsOne() throws {
        let page = Self.page(["Made-up Soup with", "Beans and Greens", "1 cup water", "2 cups stock", "Boil it."],
                             big: [0, 1])

        let found = PageTitles.bigType([page])

        try #require(found.count == 1)
        #expect(found[0].text == "Made-up Soup with Beans and Greens")
        #expect(found[0].firstLine == 0)
        #expect(found[0].lastLine == 1)
    }

    @Test("cut by titles")
    func cutByTitles() {
        let titles: [PageTitles.Found] = [(0, 0, 0, "Made-up Soup"), (0, 10, 10, "Made-up Salad"), (0, 20, 21, "Made-up Bread")]

        let pieces = PageTitles.cut(lineCount: [30], titles: titles)

        #expect(pieces.map { [$0.from.page, $0.from.line, $0.to.page, $0.to.line] } == [
            [0, 0, 0, 9],
            [0, 10, 0, 19],
            [0, 20, 0, 29],
        ])
    }

    @Test("one title, no cut")
    func oneTitleNoCut() {
        #expect(PageTitles.cut(lineCount: [30], titles: [(0, 0, 0, "Made-up Soup")]).isEmpty)
    }
}
