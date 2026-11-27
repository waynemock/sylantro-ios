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
        #expect(decoded.readWhileInBackground == nil)
        #expect(decoded.structureAttempts == nil)
    }

    @Test("background fields round trip")
    func backgroundFieldsRoundTrip() throws {
        var result = SpikeCaptureResult(
            fileNames: ["TP-01.jpeg"], readings: [], readMillis: [], bottomReadMillis: nil, bottomText: nil,
            structureMillis: nil, recipes: [], error: nil, path: nil, partMillis: [:], usedLineLabels: false,
            partErrors: [:], waits: 0, warnings: [], retried: [], fallbacks: [], unreadableLines: 0,
            rateLimitRetries: 0, headerTitle: nil, modelTitle: nil, otherTitles: [], headerArea: []
        )
        result.readWhileInBackground = true
        result.structureAttempts = [
            SpikeCaptureResult.Attempt(sceneActive: true, outcome: "refused", millis: 1_200,
                                       at: Date(timeIntervalSince1970: 1_000)),
            SpikeCaptureResult.Attempt(sceneActive: false, outcome: "done", millis: 8_400,
                                       at: Date(timeIntervalSince1970: 1_060)),
        ]
        let report = SpikeReport(runAt: Date(timeIntervalSince1970: 0), deviceModel: "iPhone0,0", systemVersion: "26.5",
                                 modelAvailable: true, captures: [result], backgroundTask: "expired at capture 3")

        let decoded = try SpikeReport.decoded(from: report.encoded())

        #expect(decoded.backgroundTask == "expired at capture 3")
        let capture = try #require(decoded.captures.first)
        #expect(capture.readWhileInBackground == true)
        #expect(capture.structureAttempts == result.structureAttempts)
    }

    @Test("a run of five pages is one capture")
    func runOfFivePagesIsOneCapture() {
        let run = ["TP-26.heic", "TP-27.heic", "TP-28.heic", "TP-29.heic", "TP-30.heic"]

        #expect(TestSetGroups.captures(fileNames: ["TP-30.heic", "TP-25.jpeg"] + run.dropLast()) == [["TP-25.jpeg"], run])
        #expect(TestSetGroups.captures(fileNames: run.filter { $0 != "TP-28.heic" })
                == [["TP-26.heic"], ["TP-27.heic"], ["TP-29.heic"], ["TP-30.heic"]])
    }

    @Test("step and ingredient answers recorded")
    func answersRecorded() throws {
        var result = SpikeCaptureResult(
            fileNames: ["TP-01.jpeg"], readings: [], readMillis: [], bottomReadMillis: nil, bottomText: nil,
            structureMillis: nil, recipes: [], error: nil, path: nil, partMillis: [:], usedLineLabels: false,
            partErrors: [:], waits: 0, warnings: [], retried: [], fallbacks: [], unreadableLines: 0,
            rateLimitRetries: 0, headerTitle: nil, modelTitle: nil, otherTitles: [], headerArea: []
        )
        result.stepRanges = [[1, 4], [5, 7]]
        result.ingredientItems = [[0, 0, -1], [0, 1, 1], [0, 2, 3], [1, 4, -1], [1, 5, 5]]
        result.sectionLineCounts = ["ingredients": 5, "steps": 7]

        let decoded = try JSONDecoder().decode(SpikeCaptureResult.self, from: JSONEncoder().encode(result))

        #expect(decoded.stepRanges == result.stepRanges)
        #expect(decoded.ingredientItems == result.ingredientItems)
        #expect(decoded.sectionLineCounts == result.sectionLineCounts)
    }

    // MARK: Waiting out the rate limit in the background (M3-3o)

    @Test("background retries are timed and limited")
    func backgroundRetriesAreTimedAndLimited() {
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 0) == nil)
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 1) == .seconds(30))
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 2) == .seconds(60))
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 3) == .seconds(120))
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 4) == .seconds(240))
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 5) == .seconds(300))
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 6) == .seconds(300))
        #expect(SpikeRunner.backgroundRetryDelay(afterRefusal: 7) == nil)
    }

    @Test("attempt parts and waits round trip")
    func attemptPartsAndWaitsRoundTrip() throws {
        let attempt = SpikeCaptureResult.Attempt(sceneActive: false, outcome: "refused", millis: 900,
                                                 at: Date(timeIntervalSince1970: 2_000),
                                                 partsDone: ["line labels", "ingredients"], retryAfterSeconds: 60)

        let decoded = try JSONDecoder().decode(SpikeCaptureResult.Attempt.self, from: JSONEncoder().encode(attempt))

        #expect(decoded == attempt)
        #expect(decoded.partsDone == ["line labels", "ingredients"])
        #expect(decoded.retryAfterSeconds == 60)
    }

    // MARK: Background progress at each step (M3-3p)

    @Test("background progress by steps")
    func backgroundProgressBySteps() {
        #expect(SpikeRunner.completedUnits(processed: 0, stepsInCurrent: 0) == 0)
        #expect(SpikeRunner.completedUnits(processed: 0, stepsInCurrent: 3) == 3)
        #expect(SpikeRunner.completedUnits(processed: 2, stepsInCurrent: 4) == 24)
        #expect(SpikeRunner.completedUnits(processed: 2, stepsInCurrent: 15) == 29)
    }

    @Test("background task times round trip")
    func backgroundTaskTimesRoundTrip() throws {
        let report = SpikeReport(runAt: Date(timeIntervalSince1970: 0), deviceModel: "iPhone0,0", systemVersion: "26.5",
                                 modelAvailable: true, captures: [], backgroundTask: "expired at capture 3",
                                 backgroundTaskStartedAt: Date(timeIntervalSince1970: 3_000),
                                 backgroundTaskEndedAt: Date(timeIntervalSince1970: 3_420))

        let decoded = try SpikeReport.decoded(from: report.encoded())

        #expect(decoded.backgroundTask == "expired at capture 3")
        #expect(decoded.backgroundTaskStartedAt == report.backgroundTaskStartedAt)
        #expect(decoded.backgroundTaskEndedAt == report.backgroundTaskEndedAt)
    }
}
