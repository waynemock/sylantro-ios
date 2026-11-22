import Foundation
import Testing
@testable import Sylantro

/// The spike runner's timed retry (SLT-153) and its test-set groups (SLT-154), `11` M1-6. Every
/// file name is made up.
@Suite("Spike runner")
struct SpikeRunnerTests {
    @Test("rate-limit retries are timed and limited")
    func rateLimitRetriesAreTimedAndLimited() {
        #expect(SpikeRunner.retryDelay(afterRefusal: 1) == .seconds(30))
        #expect(SpikeRunner.retryDelay(afterRefusal: 2) == .seconds(30))
        #expect(SpikeRunner.retryDelay(afterRefusal: 3) == .seconds(30))
        #expect(SpikeRunner.retryDelay(afterRefusal: 4) == nil)
    }

    @Test("the test set groups by page ID")
    func testSetGroupsByPageID() {
        let names = ["TP-06.jpeg", "TP-05.jpeg", "TP-01.jpeg", "TP-07.JPG", "notes.txt", "TP-01 copy.jpeg", "TP-17.jpeg"]
        #expect(TestSetGroups.captures(fileNames: names) == [["TP-01.jpeg"], ["TP-05.jpeg", "TP-06.jpeg"], ["TP-07.JPG"], ["TP-17.jpeg"]])
    }
}
