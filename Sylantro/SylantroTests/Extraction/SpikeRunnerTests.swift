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

    @Test("the header area in the report")
    func headerAreaIsInTheReport() throws {
        let result = SpikeCaptureResult(
            fileNames: ["TP-01.jpeg"], readings: [], readMillis: [], bottomReadMillis: nil, bottomText: nil,
            structureMillis: nil, recipes: [], error: nil, path: nil, partMillis: [:], usedLineLabels: false,
            partErrors: [:], waits: 0, warnings: [], retried: [], fallbacks: [], unreadableLines: 0,
            rateLimitRetries: 0, headerTitle: nil, modelTitle: nil, otherTitles: [],
            headerArea: [HeaderArea.HeaderLine(text: "Test Soup", size: 2.0)]
        )
        let report = SpikeReport(runAt: Date(timeIntervalSince1970: 0), deviceModel: "iPhone0,0", systemVersion: "26.5",
                                 modelAvailable: false, captures: [result])

        let json = try #require(try JSONSerialization.jsonObject(with: report.encoded()) as? [String: Any])
        let captures = try #require(json["captures"] as? [[String: Any]])
        let area = try #require(captures.first?["headerArea"] as? [[String: Any]])
        try #require(area.count == 1)
        #expect(area[0]["text"] as? String == "Test Soup")
        #expect(area[0]["size"] as? Double == 2.0)
    }

    @Test("older results read")
    func olderResultsRead() throws {
        // A result from before M3-5s: none of the title fields.
        let result = SpikeCaptureResult(
            fileNames: ["TP-01.jpeg"], readings: [], readMillis: [], bottomReadMillis: nil, bottomText: nil,
            structureMillis: nil, recipes: [], error: nil, path: nil, partMillis: [:], usedLineLabels: false,
            partErrors: [:], waits: 0, warnings: [], retried: [], fallbacks: [], unreadableLines: 0,
            rateLimitRetries: 0, headerTitle: nil, modelTitle: nil, otherTitles: [], headerArea: []
        )
        let data = try JSONEncoder().encode(result)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(!json.contains("titlesBigType") && !json.contains("piecesModel"))

        let decoded = try JSONDecoder().decode(SpikeCaptureResult.self, from: data)

        #expect(decoded.titlesBigType == nil)
        #expect(decoded.titlesModel == nil)
        #expect(decoded.titlesModelDropped == nil)
        #expect(decoded.piecesBigType == nil)
        #expect(decoded.piecesModel == nil)
    }
}
