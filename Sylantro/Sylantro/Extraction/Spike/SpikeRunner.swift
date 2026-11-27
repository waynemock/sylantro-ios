import BackgroundTasks
import Foundation
import ImageIO
import Observation
import os
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
        logPermittedIdentifiersOnce()
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

    /// Every capture read, then structured. With `backgroundTask` (Run All in Background (Test),
    /// `15` M3-3l), structuring is tried with the scene inactive too, and the task's progress and
    /// subtitle follow the captures. `notStarted` is why the background task didn't start, for
    /// the report; nil for a plain run.
    func runAll(in backgroundTask: BGContinuedProcessingTask? = nil, notStarted: String? = nil) async {
        guard !isRunning else {
            return
        }
        isRunning = true
        modelAvailable = RecipeStructurer.isAvailable
        backgroundTaskOutcome = notStarted
        self.backgroundTask = backgroundTask
        isBackgroundTest = backgroundTask != nil
        if backgroundTask == nil {
            backgroundTaskStartedAt = nil
            backgroundTaskEndedAt = nil
        }
        log.info(self, "run started: \(captures.count) capture(s), model available \(modelAvailable), background test \(isBackgroundTest)")
        for index in captures.indices {
            captures[index].status = .waiting
            captures[index].result = nil
        }
        // Ten units a capture: up to 9 for its steps, the tenth when it is done or failed (M3-3p).
        backgroundTask?.progress.totalUnitCount = Int64(captures.count * Self.unitsPerCapture)
        backgroundTask?.progress.completedUnitCount = 0
        // A cancelled run (Close, `11` M1-7) stops before the next read or structuring. The
        // task's expiry doesn't cancel it (M3-3p).
        for index in captures.indices {
            guard !Task.isCancelled, captures.indices.contains(index) else {
                break
            }
            currentCapture = index
            startSteps(capture: index)
            updateSubtitle(capture: index, waiting: false)
            await read(index)
            guard !Task.isCancelled, captures.indices.contains(index) else {
                break
            }
            if modelAvailable, captures[index].status == .reading {
                await structure(index)
            } else if captures[index].status == .reading {
                captures[index].status = .done
            }
            // The captures done or failed, as the screen's bar counts them (M3-3o); the next
            // capture's steps start from 0 (M3-3p).
            stepsInCurrent = 0
            updateProgress()
            // The file can be exported at any point, failed captures included (`11` M1-9).
            finishReport()
        }
        if Task.isCancelled {
            endBackgroundTest()
            finishReport()
            isRunning = false
            log.info(self, "run cancelled")
            return
        }
        // The scene may have come back while the run was still going.
        await structureWaiting()
        endBackgroundTest()
        finishReport()
        isRunning = false
        log.info(self, "run finished")
    }

    // MARK: Background test (`15` M3-3l)

    /// The continued-processing task's identifier, both registered and requested, under the
    /// wildcard `com.syzygysoftwerksllc.Sylantro.spike.*` that `Info.plist` permits (Apple's
    /// notation for these tasks, `15` M3-3m and M3-3n: only the permitted identifier is a wildcard).
    static let backgroundTaskIdentifier = "com.syzygysoftwerksllc.Sylantro.spike.run"
    private static let backgroundTaskTitle = "Spike run"
    /// Registered once per launch: a second registration of the identifier ends the app.
    private static var isLaunchHandlerRegistered = false
    /// The run waiting for its submitted task to launch.
    private static var pendingLaunch: CheckedContinuation<BGContinuedProcessingTask?, Never>?

    /// Structuring is tried whether or not the scene is active.
    private var isBackgroundTest = false
    private var backgroundTask: BGContinuedProcessingTask?
    /// The report's `backgroundTask`.
    private var backgroundTaskOutcome: String?
    /// The capture being read or structured, for an expiry.
    private var currentCapture = 0
    private var didExpire = false
    /// The task's launch and end, for the report (M3-3p).
    private var backgroundTaskStartedAt: Date?
    private var backgroundTaskEndedAt: Date?
    /// The capture whose steps are counted, and how many are done (M3-3p).
    private var stepCaptureID: UUID?
    private var stepsInCurrent = 0
    /// A capture's units in the task's progress: up to 9 for its steps, 10 when it is processed.
    private nonisolated static let unitsPerCapture = 10
    /// The installed app's permitted identifiers are logged once, when the spike screen opens.
    private var hasLoggedPermittedIdentifiers = false

    /// Run All in Background (Test): submits a continued-processing task that fails rather than
    /// queues, and runs `runAll` in background-test mode inside it. If the submit throws, the run
    /// goes ahead as Run All, the report saying why. Close cancels it as it cancels Run All.
    func runAllInBackground() async {
        guard !isRunning else {
            return
        }
        // A submit with no handler registered ends the app, so there is no submit without one (M3-3n).
        guard Self.registerLaunchHandlerIfNeeded() else {
            log.error(self, "background task registration rejected: \(Self.backgroundTaskIdentifier)")
            await runAll(notStarted: "not started: registration rejected")
            return
        }
        let request = BGContinuedProcessingTaskRequest(identifier: Self.backgroundTaskIdentifier,
                                                       title: Self.backgroundTaskTitle, subtitle: "Starting")
        request.strategy = .fail
        var submitError: String?
        // The handler runs on the main queue, so it can't run before the continuation is kept.
        let task: BGContinuedProcessingTask? = await withCheckedContinuation { continuation in
            Self.pendingLaunch = continuation
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                Self.pendingLaunch = nil
                submitError = String(describing: error)
                continuation.resume(returning: nil)
            }
        }
        guard let task else {
            let reason = submitError ?? "no continued-processing task launched"
            log.error(self, "background task not started: \(reason)")
            await runAll(notStarted: "not started: \(reason)")
            return
        }
        log.info(self, "background task started")
        didExpire = false
        backgroundTaskStartedAt = Date()
        backgroundTaskEndedAt = nil
        // Strongly held until the system clears the handler, after it runs or on completion.
        task.expirationHandler = { @Sendable in
            Task { @MainActor in self.expireBackgroundTask(task) }
        }
        let run = Task { await self.runAll(in: task) }
        await withTaskCancellationHandler {
            await run.value
        } onCancel: {
            run.cancel()
        }
        // An expired task was completed when it expired; its outcome stays (M3-3p).
        if !didExpire {
            let succeeded = !run.isCancelled
            let waiting = captures.filter { $0.status == .waitingForApp }.count
            backgroundTaskOutcome = !succeeded ? "cancelled"
                : waiting == 0 ? "completed" : "completed, \(waiting) waiting for the app"
            task.setTaskCompleted(success: succeeded)
            endBackgroundTask()
        }
        finishReport()
        log.info(self, "background task ended: \(backgroundTaskOutcome ?? "")")
    }

    /// Records the task's end and logs how long it lasted (M3-3p).
    private func endBackgroundTask() {
        let end = Date()
        backgroundTaskEndedAt = end
        if let start = backgroundTaskStartedAt {
            log.info(self, "background task lasted \(Int(end.timeIntervalSince(start))) s")
        }
    }

    /// The launch handler, registered on the main queue the first time it is needed (a
    /// continued-processing registration may come after launch). False when the system rejects
    /// the registration (the identifier not permitted by the installed app's `Info.plist`).
    private static func registerLaunchHandlerIfNeeded() -> Bool {
        guard !isLaunchHandlerRegistered else {
            return true
        }
        isLaunchHandlerRegistered = BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier,
                                                                   using: .main) { task in
            MainActor.assumeIsolated {
                launched(task as? BGContinuedProcessingTask)
            }
        }
        return isLaunchHandlerRegistered
    }

    /// Logs the installed app's `BGTaskSchedulerPermittedIdentifiers`, identifiers only, the first
    /// time the spike screen is in front (M3-3n).
    private func logPermittedIdentifiersOnce() {
        guard !hasLoggedPermittedIdentifiers else {
            return
        }
        hasLoggedPermittedIdentifiers = true
        if let identifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String],
           !identifiers.isEmpty {
            log.info(self, "background task permitted identifiers: \(identifiers.joined(separator: ", "))")
        } else {
            log.info(self, "background task permitted identifiers: none")
        }
    }

    /// Hands the launched task to the run waiting for it; a task nobody waits for ends at once.
    private static func launched(_ task: BGContinuedProcessingTask?) {
        guard let continuation = pendingLaunch else {
            task?.setTaskCompleted(success: false)
            return
        }
        pendingLaunch = nil
        continuation.resume(returning: task)
    }

    /// The task expired (M3-3p): it is completed at once, the capture it stopped at recorded, and
    /// the runner stops touching it. The run isn't cancelled: background-test mode ends, and the
    /// rest goes on as Run All, structuring only while the scene is active (SLT-144).
    private func expireBackgroundTask(_ task: BGContinuedProcessingTask) {
        guard !didExpire, backgroundTask === task else {
            return
        }
        didExpire = true
        backgroundTaskOutcome = "expired at capture \(currentCapture + 1)"
        task.setTaskCompleted(success: false)
        endBackgroundTask()
        endBackgroundTest()
        log.info(self, "background task expired at capture \(currentCapture + 1), run goes on in the app")
        finishReport()
    }

    private func endBackgroundTest() {
        isBackgroundTest = false
        backgroundTask = nil
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
        // Whether the scene was inactive at any point of the reading (M3-3l).
        var readInBackground = !isSceneActive
        do {
            var lastImage: CGImage?
            for url in urls {
                let image = try Self.loadImage(url)
                let start = ContinuousClock.now
                let reading = try await reader.read(image)
                result.readMillis.append(Self.millis(since: start))
                result.readings.append(reading)
                readInBackground = readInBackground || !isSceneActive
                lastImage = image
                stepDone("read")
            }
            if let lastImage {
                let start = ContinuousClock.now
                let bottom = try await reader.readBottom(lastImage)
                result.bottomReadMillis = Self.millis(since: start)
                result.bottomText = bottom.text
                readInBackground = readInBackground || !isSceneActive
                stepDone("read")
            }
        } catch {
            fail(index, &result, error)
        }
        result.readWhileInBackground = readInBackground
        captures[index].result = result
    }

    /// Structures one read capture, only while the scene is active, or in any scene in the
    /// background test (M3-3l). A rate-limit refusal while the scene is active is retried after a
    /// short wait, up to three times (SLT-153); in the background test, one while it isn't is
    /// retried after `backgroundRetryDelay`'s longer waits (M3-3o). Each wait follows the scene at
    /// the refusal, the count carrying on. After that, or with the scene inactive outside the
    /// test, the capture waits for the app instead of failing (SLT-144). Each attempt is recorded,
    /// with the parts that got through and the wait after it.
    private func structure(_ index: Int) async {
        guard var result = captures[index].result else {
            return
        }
        let captureID = captures[index].id
        guard isSceneActive || isBackgroundTest else {
            wait(index, &result)
            return
        }
        captures[index].status = .structuring
        log.info(self, "capture \(index): structuring")
        var refusals = 0
        while true {
            let attemptAt = Date()
            let attemptStart = ContinuousClock.now
            let attemptSceneActive = isSceneActive
            // The background test skips the title comparison (M3-3p), decided as the attempt starts.
            let comparesTitles = !isBackgroundTest
            // The part names `onPartDone` gives during this attempt (M3-3o), from any thread.
            let partsDone = OSAllocatedUnfairLock(initialState: [String]())
            func recordAttempt(_ outcome: String, retryAfter delay: Duration? = nil) {
                result.structureAttempts = (result.structureAttempts ?? []) + [SpikeCaptureResult.Attempt(
                    sceneActive: attemptSceneActive, outcome: outcome, millis: Self.millis(since: attemptStart), at: attemptAt,
                    partsDone: partsDone.withLock { $0 }, retryAfterSeconds: delay.map { Int($0.components.seconds) }
                )]
            }
            do {
                // The spike has no SourcePages; each page gets an id for this run only.
                let pageIDs = captures[index].urls.map { _ in UUID() }
                let outcome = try await structurer.structure(result.readings, pageIDs: pageIDs) { part in
                    partsDone.withLock { $0.append(part) }
                    Task { @MainActor in self.stepDone(Self.stepName(part), capture: captureID) }
                }
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
                // RV-35: each way of finding the page's titles, and the pieces they cut it into; not
                // in the background test, so a capture makes only the structurer's calls (M3-3p).
                if comparesTitles {
                    await findTitles(&result, pageIDs: pageIDs)
                }
                guard isCapture(captureID, at: index) else {
                    return
                }
                recordAttempt("done")
                captures[index].status = .done
                log.info(self, "capture \(index): done, \(result.recipes.count) recipe(s)")
            } catch where RecipeStructurer.isRateLimit(error) {
                guard isCapture(captureID, at: index) else {
                    return
                }
                refusals += 1
                // The wait follows the scene now (M3-3o): in front, SLT-153's; behind it, the
                // background test's longer ones; otherwise none.
                let sceneActive = isSceneActive
                let delay = sceneActive ? Self.retryDelay(afterRefusal: refusals)
                    : isBackgroundTest ? Self.backgroundRetryDelay(afterRefusal: refusals) : nil
                recordAttempt("refused", retryAfter: delay)
                if let delay {
                    // Still `.structuring`: wait, then structure again from the start.
                    log.info(self, "capture \(index): refused, scene active \(sceneActive), retrying in \(delay.components.seconds) s")
                    updateSubtitle(capture: index, waiting: true)
                    try? await Task.sleep(for: delay)
                    guard isCapture(captureID, at: index) else {
                        return
                    }
                    // A cancelled wait ends without retrying; outside the test, so does a scene
                    // that left meanwhile.
                    if isSceneActive || isBackgroundTest, !Task.isCancelled {
                        result.rateLimitRetries += 1
                        updateSubtitle(capture: index, waiting: false)
                        continue
                    }
                } else {
                    log.info(self, "capture \(index): refused, scene active \(sceneActive)")
                }
                wait(index, &result)
            } catch {
                guard isCapture(captureID, at: index) else {
                    return
                }
                recordAttempt("failed: \(String(describing: error))")
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

    // MARK: Titles on a page (`15` M3-5s, RV-35)

    /// Both ways of finding a capture's recipe titles, side by side: by type size
    /// (`PageTitles.bigType`) and by the model (`TitleLister`). With two or more titles, the capture
    /// is cut by them (`PageTitles.cut`) and each piece structured on its own. A failure here is
    /// recorded in `partErrors` and doesn't fail the capture.
    private func findTitles(_ result: inout SpikeCaptureResult, pageIDs: [UUID]) async {
        // The structurer's readable lines, page by page (SLT-150).
        let pages = result.readings.map { $0.lines.filter { ScriptCheck.isLatin($0.text) } }

        let bigType = PageTitles.bigType(pages.map { $0.map { (text: $0.text, height: $0.box.height) } })
        result.titlesBigType = bigType.map(\.text)
        result.piecesBigType = await pieces(bigType, pages: pages, pageIDs: pageIDs, way: "bigType",
                                            errors: &result.partErrors)

        do {
            let answer = try await TitleLister.titles(numberedLines: pages.flatMap { $0.map(\.text) })
            stepDone("titles")
            result.titlesModel = answer.titles
            result.titlesModelDropped = answer.dropped
            result.piecesModel = await pieces(Self.positions(of: answer.titles, in: pages), pages: pages,
                                              pageIDs: pageIDs, way: "model", errors: &result.partErrors)
        } catch {
            result.partErrors["titles model"] = String(describing: error)
        }
        log.info(self, "titles: \(result.titlesBigType?.count ?? 0) by type size, \(result.titlesModel?.count ?? 0) by the model")
    }

    /// The capture cut by `titles` and each piece structured on its own, from its own lines only
    /// (the other lines left out, each page kept so the page IDs line up); nil with fewer than two
    /// titles. A piece that fails is left out and recorded in `errors`.
    private func pieces(_ titles: [PageTitles.Found], pages: [[PageReading.ReadLine]], pageIDs: [UUID],
                        way: String, errors: inout [String: String]) async -> [SpikeCaptureResult.Piece]? {
        let cuts = PageTitles.cut(lineCount: pages.map(\.count), titles: titles)
        guard !cuts.isEmpty else { return nil }
        var pieces: [SpikeCaptureResult.Piece] = []
        for (offset, cut) in cuts.enumerated() {
            let readings = pages.enumerated().map { pageIndex, lines in
                PageReading(lines: lines.enumerated().filter { lineIndex, _ in
                    Self.isInside((pageIndex, lineIndex), from: cut.from, to: cut.to)
                }.map(\.element))
            }
            do {
                let outcome = try await structurer.structure(readings, pageIDs: pageIDs)
                let recipe = outcome.recipes.first
                pieces.append(SpikeCaptureResult.Piece(
                    title: titles[offset].text,
                    ingredientCount: recipe?.ingredientGroups.flatMap(\.ingredients).count ?? 0,
                    stepCount: recipe?.steps.count ?? 0,
                    warnings: recipe?.extraction?.warnings ?? [],
                    millis: outcome.partMillis.values.reduce(0, +)
                ))
            } catch {
                errors["pieces \(way) \(offset + 1)"] = String(describing: error)
            }
            stepDone("pieces")
        }
        return pieces
    }

    /// Where the model's titles are: the first line, or two adjacent lines on one page, that each
    /// equals (normalized), in reading order; a title already placed, or not found, is left out.
    private static func positions(of titles: [String], in pages: [[PageReading.ReadLine]]) -> [PageTitles.Found] {
        var found: [PageTitles.Found] = []
        for title in titles {
            let target = TextMatch.normalize(title)
            search: for (pageIndex, lines) in pages.enumerated() {
                for lineIndex in lines.indices {
                    let one = TextMatch.normalize(lines[lineIndex].text)
                    let two = lineIndex + 1 < lines.count
                        ? TextMatch.normalize(lines[lineIndex].text + " " + lines[lineIndex + 1].text) : nil
                    let lastLine: Int? = one == target ? lineIndex : (two == target ? lineIndex + 1 : nil)
                    if let lastLine {
                        if !found.contains(where: { $0.page == pageIndex && $0.firstLine == lineIndex }) {
                            found.append((pageIndex, lineIndex, lastLine, title))
                        }
                        break search
                    }
                }
            }
        }
        return found.sorted { ($0.page, $0.firstLine) < ($1.page, $1.firstLine) }
    }

    /// Whether `position` is from `from` to `to`, both included, in page then line order.
    private static func isInside(_ position: (page: Int, line: Int), from: (page: Int, line: Int),
                                 to: (page: Int, line: Int)) -> Bool {
        !(position < from) && !(to < position)
    }

    /// The outcome's part times, part errors, retries, fallbacks, line-label use, header title,
    /// model title, other titles, header area and answers as line numbers (M3-3m), which a failed
    /// capture keeps too.
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
        result.stepRanges = outcome.stepRanges
        result.ingredientItems = outcome.ingredientItems
        result.sectionLineCounts = outcome.sectionLineCounts
    }

    /// The wait before structuring again after the `count`th refusal in a row while in front:
    /// 30 seconds for the first three, then nil (SLT-153).
    nonisolated static func retryDelay(afterRefusal count: Int) -> Duration? {
        (1...3).contains(count) ? .seconds(30) : nil
    }

    /// The background test's wait after the `count`th refusal in a row with the scene inactive
    /// (M3-3o): 30, 60, 120, 240, 300 and 300 seconds, then nil.
    nonisolated static func backgroundRetryDelay(afterRefusal count: Int) -> Duration? {
        let seconds = [30, 60, 120, 240, 300, 300]
        return (1...seconds.count).contains(count) ? .seconds(seconds[count - 1]) : nil
    }

    /// The task's completed units (M3-3p): 10 for each processed capture (done or failed, never
    /// waiting for the app), and the current capture's steps, at most 9.
    nonisolated static func completedUnits(processed: Int, stepsInCurrent: Int) -> Int64 {
        Int64(processed * unitsPerCapture + min(stepsInCurrent, unitsPerCapture - 1))
    }

    /// A step's name in the subtitle: the part's name, a fallback under its part's (M3-3p).
    nonisolated static func stepName(_ part: String) -> String {
        let name = part.hasSuffix(" fallback") ? String(part.dropLast(" fallback".count)) : part
        return name == "lineLabels" ? "line labels" : name
    }

    /// The capture at `index` starts its steps from 0 (M3-3p).
    private func startSteps(capture index: Int) {
        stepCaptureID = captures[index].id
        stepsInCurrent = 0
    }

    /// One step of the current capture (or of `captureID`, if it is still the current one) is
    /// done (M3-3p): its unit is added, and the subtitle names it. Nothing outside the
    /// background test.
    private func stepDone(_ step: String, capture captureID: UUID? = nil) {
        guard captureID == nil || captureID == stepCaptureID else {
            return
        }
        stepsInCurrent += 1
        guard let backgroundTask, let index = captures.firstIndex(where: { $0.id == stepCaptureID }) else {
            return
        }
        updateProgress()
        backgroundTask.updateTitle(Self.backgroundTaskTitle,
                                   subtitle: "Capture \(index + 1) of \(captures.count), \(step)")
    }

    /// The task's progress as it stands (M3-3p).
    private func updateProgress() {
        backgroundTask?.progress.completedUnitCount = Self.completedUnits(processed: processedCount,
                                                                          stepsInCurrent: stepsInCurrent)
    }

    /// The background task's subtitle for a capture: "Capture n of m", with ", waiting" during a
    /// refusal's wait (M3-3o). Nothing outside the background test.
    private func updateSubtitle(capture index: Int, waiting: Bool) {
        backgroundTask?.updateTitle(Self.backgroundTaskTitle,
                                    subtitle: "Capture \(index + 1) of \(captures.count)" + (waiting ? ", waiting" : ""))
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
            currentCapture = index
            startSteps(capture: index)
            await structure(index)
            // While the background task runs, its progress follows (M3-3o, M3-3p).
            stepsInCurrent = 0
            updateProgress()
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
            captures: captures.compactMap(\.result),
            backgroundTask: backgroundTaskOutcome,
            backgroundTaskStartedAt: backgroundTaskStartedAt,
            backgroundTaskEndedAt: backgroundTaskEndedAt
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
