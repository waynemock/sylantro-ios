import Testing
@testable import Sylantro

/// `ReadingProgress` (`13` SC-23, `15` M3-3f): the bar moves by each page read, then each of the
/// three parts structured.
@Suite("Reading progress")
struct ReadingProgressTests {
    @Test("pages then parts")
    func pagesThenParts() {
        var progress = ReadingProgress(pagesToRead: 2)
        #expect(progress.fraction == 0)

        progress.pageRead()
        #expect(progress.fraction == 0.2)
        progress.pageRead()
        #expect(progress.fraction == 0.4)

        progress.partDone("header")
        progress.partDone("ingredients")
        progress.partDone("steps")
        #expect(progress.fraction == 1.0)
    }

    @Test("other parts don't count")
    func otherPartsDontCount() {
        var progress = ReadingProgress(pagesToRead: 1)
        progress.partDone("lineLabels")
        progress.partDone("ingredients fallback")
        #expect(progress.fraction == 0)

        progress.partDone("header")
        let once = progress.fraction
        progress.partDone("header")
        #expect(progress.fraction == once)
        #expect(once == 0.25)
    }

    @Test("nothing to read")
    func nothingToRead() {
        var progress = ReadingProgress(pagesToRead: 0)
        #expect(progress.fraction == 0)

        progress.partDone("header")
        #expect(progress.fraction == 1.0 / 3)
        progress.partDone("ingredients")
        #expect(progress.fraction == 2.0 / 3)
        progress.partDone("steps")
        #expect(progress.fraction == 1)
    }
}
