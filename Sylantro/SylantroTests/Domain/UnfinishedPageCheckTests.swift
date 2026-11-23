import Testing
@testable import Sylantro

/// Save's page-2 question (`14` Task M2-4, MT-10, SLT-046): which bottom lines look unfinished.
/// Every line is made up.
@Suite("Unfinished page")
struct UnfinishedPageCheckTests {
    @Test("page 1 of 2 asks")
    func pageOneOfTwoAsks() {
        #expect(UnfinishedPageCheck.looksUnfinished(["Bake until golden.", "Page 1 of 2"]))
    }

    @Test("the last page doesn't ask")
    func lastPageDoesNotAsk() {
        #expect(!UnfinishedPageCheck.looksUnfinished(["Serve warm.", "Page 2 of 2"]))
    }

    @Test("a sentence cut off asks")
    func sentenceCutOffAsks() {
        #expect(UnfinishedPageCheck.looksUnfinished(["Stir in the flour and"]))
        #expect(UnfinishedPageCheck.looksUnfinished(["Add the milk,"]))
    }

    @Test("a finished step doesn't ask")
    func finishedStepDoesNotAsk() {
        #expect(!UnfinishedPageCheck.looksUnfinished(["Serve warm."]))
    }

    @Test("web footers are set aside")
    func webFootersAreSetAside() {
        let footers = ["Serve warm.", "https://www.example.com/recipes/soup", "11/20/26, 3:45 PM"]
        #expect(!UnfinishedPageCheck.looksUnfinished(footers + ["1/1"]))
        #expect(UnfinishedPageCheck.looksUnfinished(footers + ["1/2"]))
    }

    @Test("a footnote asterisk with no footnote asks")
    func footnoteAsteriskWithNoFootnoteAsks() {
        let lines = ["2 cups oats*", "Bake 20 minutes."]
        #expect(UnfinishedPageCheck.looksUnfinished(lines))
        #expect(!UnfinishedPageCheck.looksUnfinished(lines + ["* Use gluten-free oats."]))
    }

    @Test("no lines don't ask")
    func noLinesDoNotAsk() {
        #expect(!UnfinishedPageCheck.looksUnfinished([]))
    }

    @Test("a web address with a page number is a footer")
    func webAddressWithPageNumberIsFooter() {
        #expect(UnfinishedPageCheck.reason(["Serve warm.", "https://www.example.com/recipes/soup 1/1"]) == nil)
        #expect(UnfinishedPageCheck.reason(["Serve warm.", "https://www.example.com/recipes/soup 1/2"]) == .pageNOfM)
    }

    @Test("a line ending in a number doesn't ask")
    func lineEndingInNumberDoesNotAsk() {
        #expect(UnfinishedPageCheck.reason(["Serves 4"]) == nil)
        #expect(UnfinishedPageCheck.reason(["Calories 250"]) == nil)
    }

    @Test("the reason is the rule that fired")
    func reasonIsTheRuleThatFired() {
        #expect(UnfinishedPageCheck.reason(["Stir in the flour and"]) == .endsMidSentence)
        #expect(UnfinishedPageCheck.reason(["Bake until golden.", "Page 1 of 2"]) == .pageNOfM)
        #expect(UnfinishedPageCheck.reason(["2 cups oats*", "Bake 20 minutes."]) == .footnoteAsterisk)
    }
}
