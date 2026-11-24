import Foundation
import ImageIO
import Observation
import SyLibCore
import UIKit

/// Runs the spike's captures through the reader and the structurer, one at a time, timed
/// (`11` M1-3, SLT-093). Saves nothing. Behind SLT-093's
/// `AppConfig.AccuracySpike` flag.
@MainActor @Observable final class SpikeRunner {
    enum Status: Equatable {
        case waiting
        case reading
        case structuring
        /// Structuring waits until Sylantro is in front again (SLT-144).
        case waitingForApp
        case done
        case failed(String)
    }

    /// One selection of one recipe's photos.
    struct Capture: Identifiable {
        let id = UUID()
        let urls: [URL]
        var status: Status = .waiting
        var result: SpikeCaptureResult?
    }

    private(set) var captures: [Capture] = []
    private(set) var report: SpikeReport?
    private(set) var isRunning = false

    /// The captures that are done or failed; waiting, reading, structuring and waiting-for-the-app
    /// captures are not processed (`11` M1-13).
    var processedCount: Int {
        captures.filter { capture in
            switch capture.status {
            case .done, .failed: true
            case .waiting, .reading, .structuring, .waitingForApp: false
            }
        }.count
    }

    private let log = AppLogger(category: "Spike")
    private let reader = TextReader()
    private let structurer = RecipeStructurer()
    /// Structuring runs only while the scene is active (SLT-144); the view passes its changes in.
    private var isSceneActive = true
    private var modelAvailable = false

    /// Sorted by file name, so `TP-05` comes before `TP-06`.
    func addCapture(_ urls: [URL]) {
        let sorted = urls.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        captures.append(Capture(urls: sorted))
        log.info(self, "capture added: \(sorted.count) page(s)")
    }

    func clear() {
        captures = []
        report = nil
        endTestSetAccess()
        log.info(self, "cleared")
    }

    // MARK: Test set (SLT-154)

    /// Where the test folder's bookmark is kept.
    static let testSetFolderKey = "spikeTestSetFolder"

    /// The test folder, its security-scoped access held until `clear()` or the next load.
    private var testSetFolder: URL?

    /// One capture per page-ID group of the folder's photos (`TestSetGroups`), replacing the
    /// captures; the folder is remembered as a bookmark.
    func loadTestSet(folder: URL) {
        endTestSetAccess()
        if folder.startAccessingSecurityScopedResource() {
            testSetFolder = folder
        }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            let byName = Dictionary(files.map { ($0.lastPathComponent, $0) }, uniquingKeysWith: { first, _ in first })
            captures = []
            report = nil
            for group in TestSetGroups.captures(fileNames: Array(byName.keys)) {
                addCapture(group.compactMap { byName[$0] })
            }
            log.info(self, "test set loaded: \(captures.count) capture(s)")
        } catch {
            log.error(self, "test set not loaded: \(error.localizedDescription)")
            return
        }
        do {
            UserDefaults.standard.set(try folder.bookmarkData(), forKey: Self.testSetFolderKey)
        } catch {
            log.error(self, "test set folder not remembered: \(error.localizedDescription)")
        }
    }

    /// Loads the remembered test folder. False when there is none or it can't be resolved.
    func loadSavedTestSet() -> Bool {
        guard let bookmark = UserDefaults.standard.data(forKey: Self.testSetFolderKey) else {
            return false
        }
        var isStale = false
        guard let folder = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
            log.info(self, "saved test set not resolved")
            return false
        }
        // `loadTestSet` saves the bookmark again, which renews a stale one.
        if isStale {
            log.info(self, "saved test set bookmark is stale; saving it again")
        }
        loadTestSet(folder: folder)
        return true
    }

    private func endTestSetAccess() {
        testSetFolder?.stopAccessingSecurityScopedResource()
        testSetFolder = nil
    }

    func sceneBecameActive() {
        isSceneActive = true
        log.info(self, "scene active")
        guard !isRunning, captures.contains(where: { $0.status == .waitingForApp }) else {
            return
        }
        Task {
            isRunning = true
            await structureWaiting()
            finishReport()
            isRunning = false
        }
    }

    func sceneLeftActive() {
        isSceneActive = false
        log.info(self, "scene not active")
    }

    func runAll() async {
        guard !isRunning else {
            return
        }
        isRunning = true
        modelAvailable = RecipeStructurer.isAvailable
        log.info(self, "run started: \(captures.count) capture(s), model available \(modelAvailable)")
        for index in captures.indices {
            captures[index].status = .waiting
            captures[index].result = nil
        }
        // A cancelled run (Close, `11` M1-7) stops before the next read or structuring.
        for index in captures.indices {
            guard !Task.isCancelled, captures.indices.contains(index) else {
                break
            }
            await read(index)
            guard !Task.isCancelled, captures.indices.contains(index) else {
                break
            }
            if modelAvailable, captures[index].status == .reading {
                await structure(index)
            } else if captures[index].status == .reading {
                captures[index].status = .done
            }
            // The file can be exported at any point, failed captures included (`11` M1-9).
            finishReport()
        }
        if Task.isCancelled {
            finishReport()
            isRunning = false
            log.info(self, "run cancelled")
            return
        }
        // The scene may have come back while the run was still going.
        await structureWaiting()
        finishReport()
        isRunning = false
        log.info(self, "run finished")
    }

    /// Every page's `read`, timed, then the last page's `readBottom`. Leaves the status at
    /// `.reading`, or `.failed`.
    private func read(_ index: Int) async {
        let urls = captures[index].urls
        var result = SpikeCaptureResult(
            fileNames: urls.map(\.lastPathComponent),
            readings: [],
            readMillis: [],
            bottomReadMillis: nil,
            bottomText: nil,
            structureMillis: nil,
            recipes: [],
            error: nil,
            path: nil,
            partMillis: [:],
            usedLineLabels: false,
            partErrors: [:],
            waits: 0,
            warnings: [],
            retried: [],
            fallbacks: [],
            unreadableLines: 0,
            rateLimitRetries: 0,
            headerTitle: nil,
            modelTitle: nil,
            otherTitles: [],
            headerArea: []
        )
        captures[index].status = .reading
        log.info(self, "capture \(index): reading")
        do {
            var lastImage: CGImage?
            for url in urls {
                let image = try Self.loadImage(url)
                let start = ContinuousClock.now
                let reading = try await reader.read(image)
                result.readMillis.append(Self.millis(since: start))
                result.readings.append(reading)
                lastImage = image
            }
            if let lastImage {
                let start = ContinuousClock.now
                let bottom = try await reader.readBottom(lastImage)
                result.bottomReadMillis = Self.millis(since: start)
                result.bottomText = bottom.text
            }
        } catch {
            fail(index, &result, error)
        }
        captures[index].result = result
    }

    /// Structures one read capture, only while the scene is active. A rate-limit refusal while
    /// the scene is active is retried after a short wait, up to three times (SLT-153); after that,
    /// or with the scene inactive, the capture waits for the app instead of failing (SLT-144).
    private func structure(_ index: Int) async {
        guard var result = captures[index].result else {
            return
        }
        let captureID = captures[index].id
        guard isSceneActive else {
            wait(index, &result)
            return
        }
        captures[index].status = .structuring
        log.info(self, "capture \(index): structuring")
        var refusals = 0
        while true {
            do {
                // The spike has no SourcePages; each page gets an id for this run only.
                let pageIDs = captures[index].urls.map { _ in UUID() }
                let outcome = try await structurer.structure(result.readings, pageIDs: pageIDs)
                guard isCapture(captureID, at: index) else {
                    return
                }
                Self.copyDiagnostics(outcome, into: &result)
                result.recipes = outcome.recipes
                result.path = outcome.path
                result.structureMillis = outcome.partMillis.values.reduce(0, +)
                result.warnings = outcome.recipes.flatMap { $0.extraction?.warnings ?? [] }
                // The lines the structurer took out as unreadable: those that aren't Latin.
                result.unreadableLines = result.readings.reduce(0) { count, reading in
                    count + reading.lines.filter { !ScriptCheck.isLatin($0.text) }.count
                }
                captures[index].status = .done
                log.info(self, "capture \(index): done, \(result.recipes.count) recipe(s)")
            } catch where RecipeStructurer.isRateLimit(error) {
                guard isCapture(captureID, at: index) else {
                    return
                }
                refusals += 1
                if isSceneActive, let delay = Self.retryDelay(afterRefusal: refusals) {
                    // Still `.structuring`: wait, then structure again from the start.
                    log.info(self, "capture \(index): refused, retrying after a wait")
                    try? await Task.sleep(for: delay)
                    guard isCapture(captureID, at: index) else {
                        return
                    }
                    // A cancelled wait ends without retrying.
                    if isSceneActive, !Task.isCancelled {
                        result.rateLimitRetries += 1
                        continue
                    }
                }
                wait(index, &result)
            } catch {
                guard isCapture(captureID, at: index) else {
                    return
                }
                // Keep what the structurer learned before it failed (`11` M1-9).
                if let failed = error as? StructuringFailed {
                    Self.copyDiagnostics(failed.outcome, into: &result)
                }
                fail(index, &result, error)
            }
            break
        }
        captures[index].result = result
    }

    /// The outcome's part times, part errors, retries, fallbacks, line-label use, header title,
    /// model title, other titles and header area, which a failed capture keeps too.
    private static func copyDiagnostics(_ outcome: StructuringOutcome, into result: inout SpikeCaptureResult) {
        result.partMillis = outcome.partMillis
        result.partErrors = outcome.partErrors
        result.retried = outcome.retried
        result.fallbacks = outcome.fallbacks
        result.usedLineLabels = outcome.usedLineLabels
        result.headerTitle = outcome.headerTitle
        result.modelTitle = outcome.modelTitle
        result.otherTitles = outcome.otherTitles
        result.headerArea = outcome.headerArea
    }

    /// The wait before structuring again after the `count`th refusal in a row while in front:
    /// 30 seconds for the first three, then nil (SLT-153).
    nonisolated static func retryDelay(afterRefusal count: Int) -> Duration? {
        (1...3).contains(count) ? .seconds(30) : nil
    }

    /// Whether the capture at `index` is still `id`: Clear or Load Test Set may have replaced the
    /// captures during a wait.
    private func isCapture(_ id: UUID, at index: Int) -> Bool {
        captures.indices.contains(index) && captures[index].id == id
    }

    /// Structures the waiting captures in order while the scene stays active; reading is not
    /// repeated.
    private func structureWaiting() async {
        for index in captures.indices where captures[index].status == .waitingForApp {
            guard isSceneActive else {
                return
            }
            await structure(index)
            finishReport()
        }
    }

    private func wait(_ index: Int, _ result: inout SpikeCaptureResult) {
        result.waits += 1
        captures[index].result = result
        captures[index].status = .waitingForApp
        log.info(self, "capture \(index): waiting for the app")
    }

    private func fail(_ index: Int, _ result: inout SpikeCaptureResult, _ error: any Error) {
        let description = String(describing: error)
        result.error = description
        captures[index].status = .failed(description)
        log.error(self, "capture \(index): failed")
    }

    /// The report of every capture as it stands.
    private func finishReport() {
        report = SpikeReport(
            runAt: Date(),
            deviceModel: Self.hardwareIdentifier(),
            systemVersion: UIDevice.current.systemVersion,
            modelAvailable: modelAvailable,
            captures: captures.compactMap(\.result)
        )
    }

    // MARK: Helpers

    /// Loads an image from a security-scoped URL, upright per its orientation.
    private static func loadImage(_ url: URL) throws -> CGImage {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize(of: url) ?? 8192,
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: url])
        }
        return image
    }

    /// The image's longer side, so the upright copy keeps its full size.
    private static func maxPixelSize(of url: URL) -> Int? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return max(width, height)
    }

    private static func millis(since start: ContinuousClock.Instant) -> Int {
        let elapsed = ContinuousClock.now - start
        let (seconds, attoseconds) = elapsed.components
        return Int(seconds * 1000 + attoseconds / 1_000_000_000_000_000)
    }

    /// The hardware identifier, such as `iPhone18,1`.
    private static func hardwareIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
