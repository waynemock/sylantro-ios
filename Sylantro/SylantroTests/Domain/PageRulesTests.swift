import Foundation
import Testing
@testable import Sylantro

/// `PageRules` (`11` M1-4, SLT-143): the URL, "Page n of m", yield and times by rule. Every line
/// is made up.
@Suite("Page rules")
struct PageRulesTests {
    @Test("the longest full URL wins")
    func longestFullURLWins() {
        let fields = PageRules.find(in: ["https://example.com/r/1", "ps://example.com/_/print", "see www.example.com."])
        #expect(fields.sourceURL == "https://example.com/r/1")
    }

    @Test("page n of m")
    func pageNOfM() {
        let fields = PageRules.find(in: ["12/1/24, 9:00 AM", "Page 2 of 3"])
        #expect(fields.pageNumber == 2)
        #expect(fields.pageCount == 3)
    }

    @Test("yield by rule")
    func yieldByRule() {
        let fields = PageRules.find(in: ["PREP TIME: 5 MIN | SERVES 4", "Makes about 2 cups"])
        #expect(fields.yieldText == "SERVES 4")
    }

    @Test("times by rule")
    func timesByRule() {
        let fields = PageRules.find(in: ["Prep Time: 10 mins", "Cook time 20 minutes", "Cook until done."])
        #expect(fields.timesText == "Prep Time: 10 mins; Cook time 20 minutes")
    }

    @Test("times need a label")
    func timesNeedALabel() {
        let fields = PageRules.find(in: ["Prep: 10 min | Serves 4", "Cook 3 to 4 hours on low.", "Cook Time 20 minutes"])
        #expect(fields.timesText == "Prep: 10 min; Cook Time 20 minutes")
    }
}
