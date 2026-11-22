#if DEBUG
import Foundation
import ImageIO
import Observation
import SyLibCore
import UIKit

/// Runs the spike's captures through the reader and the structurer, one at a time, timed
/// (`11` M1-3, SLT-093). Saves nothing. Debug builds only.
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
        log.info(self, "cleared")
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
        for index in captures.indices {
            await read(index)
            if modelAvailable, captures[index].status == .reading {
                await structure(index)
            } else if captures[index].status == .reading {
                captures[index].status = .done
            }
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
            warnings: []
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

    /// Structures one read capture, only while the scene is active. A rate-limit refusal, or an
    /// inactive scene, leaves it waiting for the app instead of failing it (SLT-144).
    private func structure(_ index: Int) async {
        guard var result = captures[index].result else {
            return
        }
        guard isSceneActive else {
            wait(index, &result)
            return
        }
        captures[index].status = .structuring
        log.info(self, "capture \(index): structuring")
        do {
            // The spike has no SourcePages; each page gets an id for this run only.
            let pageIDs = captures[index].urls.map { _ in UUID() }
            let outcome = try await structurer.structure(result.readings, pageIDs: pageIDs)
            result.recipes = outcome.recipes
            result.path = outcome.path
            result.partMillis = outcome.partMillis
            result.usedLineLabels = outcome.usedLineLabels
            result.partErrors = outcome.partErrors
            result.structureMillis = outcome.partMillis.values.reduce(0, +)
            result.warnings = outcome.recipes.flatMap { $0.extraction?.warnings ?? [] }
            captures[index].status = .done
            log.info(self, "capture \(index): done, \(result.recipes.count) recipe(s)")
        } catch where RecipeStructurer.isRateLimit(error) {
            wait(index, &result)
        } catch {
            fail(index, &result, error)
        }
        captures[index].result = result
    }

    /// Structures the waiting captures in order while the scene stays active; reading is not
    /// repeated.
    private func structureWaiting() async {
        for index in captures.indices where captures[index].status == .waitingForApp {
            guard isSceneActive else {
                return
            }
            await structure(index)
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
#endif
