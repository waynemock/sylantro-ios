import Foundation
import CoreGraphics
import Observation
import SwiftData
import SyLibCore

/// Reads and structures waiting recipes behind her, one at a time, oldest first, only while
/// Sylantro is open (`02` §4, `15` M3-2, SLT-041, SLT-144, RV-5). Its jobs live in the device-only
/// store (RV-2, RV-23) and are rebuilt from the synced pages' marks by `ExtractionPlanner`. It only
/// reads the synced store; every write to it goes through `CaptureRecorder` (SLT-082).
@MainActor @Observable final class ExtractionQueue {
    /// How often the jobs are planned again while the scene is active.
    private static let planningInterval: Duration = .seconds(600)

    @ObservationIgnored private let log = AppLogger(category: "Extraction")
    /// The synced store, read only.
    @ObservationIgnored private let syncedContext: ModelContext
    /// The device-only store's container and context: its jobs, the one thing the queue writes
    /// itself. Nil only when not even an in-memory store opened; then the queue does nothing.
    @ObservationIgnored private let jobContainer: ModelContainer?
    @ObservationIgnored private let context: ModelContext?
    @ObservationIgnored private let captureRecorder: CaptureRecorder
    @ObservationIgnored private let photoFiles: PhotoFiles
    @ObservationIgnored private let reader = TextReader()
    @ObservationIgnored private let structurer = RecipeStructurer()

    /// The recipe whose job is running, from its start to its end, for "Reading…" (S-45,
    /// `15` M3-3); nil otherwise.
    private(set) var currentRecipeID: UUID?
    /// How far that job is, 0 to 1, by pages read and parts structured (SC-23, `15` M3-3f); nil
    /// with no job, or while one waits.
    private(set) var progress: Double?
    /// The steps behind `progress`.
    @ObservationIgnored private var reading: ReadingProgress?

    private var isActive = false
    private var isRunning = false
    /// A refusal outlasted its retries: nothing runs until the scene is active again (SLT-144).
    private var isWaitingForApp = false
    @ObservationIgnored private var planningTask: Task<Void, Never>?
    @ObservationIgnored private var wakeTask: Task<Void, Never>?

    private init(syncedContext: ModelContext, jobContainer: ModelContainer?, captureRecorder: CaptureRecorder,
                 photoFiles: PhotoFiles) {
        self.syncedContext = syncedContext
        self.jobContainer = jobContainer
        self.context = jobContainer?.mainContext
        self.captureRecorder = captureRecorder
        self.photoFiles = photoFiles
    }

    /// The queue on the device-only store, `"SylantroLocal"` (RV-23). A store that won't open is
    /// logged and an in-memory one used for this launch; the file is never deleted, moved or
    /// replaced (`00B` §2), and the jobs are rebuilt from the synced marks either way.
    static func live(syncedContext: ModelContext, captureRecorder: CaptureRecorder,
                     photoFiles: PhotoFiles) -> ExtractionQueue {
        let log = AppLogger(category: "Extraction")
        let schema = Schema([ExtractionJobModel.self])
        var container: ModelContainer?
        do {
            let configuration = ModelConfiguration("SylantroLocal", schema: schema, cloudKitDatabase: .none)
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            log.error(ExtractionQueue.self, "device-only store not opened; jobs kept in memory this launch: \(error)")
            do {
                let configuration = ModelConfiguration("SylantroLocal", schema: schema, isStoredInMemoryOnly: true,
                                                       cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                log.error(ExtractionQueue.self, "no job store this launch; nothing is read or structured: \(error)")
            }
        }
        return ExtractionQueue(syncedContext: syncedContext, jobContainer: container,
                               captureRecorder: captureRecorder, photoFiles: photoFiles)
    }

    /// A capture or added page saved here (RV-3): its job is due now, `scannedHere` true; an
    /// existing job is made due now, its attempts kept.
    func enqueue(recipeID: UUID) {
        guard let context else { return }
        let now = Date()
        do {
            let models = try context.fetch(FetchDescriptor<ExtractionJobModel>(predicate: #Predicate { $0.recipeID == recipeID }))
            if models.isEmpty {
                let model = ExtractionJobModel()
                model.hydrate(from: ExtractionJob(recipeID: recipeID, scannedHere: true, notBefore: now))
                context.insert(model)
            } else {
                for model in models {
                    guard var job = model.toDomain() else { continue }
                    job.scannedHere = true
                    job.notBefore = now
                    model.hydrate(from: job)
                }
            }
            try context.save()
            log.info(self, "recipe \(recipeID): queued, scanned here")
        } catch {
            log.error(self, "recipe \(recipeID): not queued: \(error)")
        }
        run()
    }

    /// The scene's activity, from `RootView`. Work runs only while active (SLT-144); each time it
    /// becomes active the jobs are planned, and again every 600 s while it stays active.
    func setSceneActive(_ isActive: Bool) {
        self.isActive = isActive
        log.info(self, "scene \(isActive ? "active" : "not active")")
        guard isActive else {
            planningTask?.cancel()
            planningTask = nil
            wakeTask?.cancel()
            wakeTask = nil
            return
        }
        isWaitingForApp = false
        planAndRun()
        if planningTask == nil {
            planningTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: Self.planningInterval)
                    guard !Task.isCancelled, let self, self.isActive else { return }
                    self.planAndRun()
                }
            }
        }
    }

    // MARK: Planning

    private func planAndRun() {
        plan()
        run()
    }

    /// Adds and removes jobs by `ExtractionPlanner.plan`, from every page and recipe in the synced
    /// store.
    private func plan() {
        guard let context else { return }
        do {
            let pages = try syncedContext.fetch(FetchDescriptor<SourcePageModel>()).compactMap { $0.toDomain() }
            let recipes = try syncedContext.fetch(FetchDescriptor<RecipeModel>()).compactMap { $0.toDomain() }
            let models = try context.fetch(FetchDescriptor<ExtractionJobModel>())
            let jobs = models.compactMap { $0.toDomain() }
            let changes = ExtractionPlanner.plan(pages: pages, recipes: recipes, jobs: jobs,
                                                 canStructure: RecipeStructurer.isAvailable, now: Date())
            let removed = Set(changes.remove)
            for model in models where removed.contains(model.id) {
                context.delete(model)
            }
            for job in changes.add {
                let model = ExtractionJobModel()
                model.hydrate(from: job)
                context.insert(model)
            }
            try context.save()
            log.info(self, "planned: \(changes.add.count) added, \(changes.remove.count) removed, \(jobs.count - changes.remove.count + changes.add.count) jobs")
        } catch {
            log.error(self, "jobs not planned: \(error)")
        }
    }

    // MARK: Running

    /// Runs due jobs one at a time while active; with none due, waits for the earliest
    /// `notBefore` (or the next planning or `enqueue`).
    private func run() {
        guard isActive, !isWaitingForApp, !isRunning, context != nil else { return }
        wakeTask?.cancel()
        wakeTask = nil
        isRunning = true
        Task {
            while isActive, !isWaitingForApp {
                let jobs = currentJobs()
                let recipes = ((try? syncedContext.fetch(FetchDescriptor<RecipeModel>())) ?? []).compactMap { $0.toDomain() }
                guard let job = ExtractionPlanner.next(jobs: jobs, recipes: recipes, now: Date()) else {
                    break
                }
                await runJob(job)
            }
            isRunning = false
            if isActive, !isWaitingForApp {
                scheduleWake()
            }
        }
    }

    /// A wake at the earliest `notBefore` still to come, if any.
    private func scheduleWake() {
        let now = Date()
        guard let earliest = currentJobs().map(\.notBefore).filter({ $0 > now }).min() else { return }
        let delay = earliest.timeIntervalSince(now)
        log.info(self, "next job due in \(Int(delay.rounded())) s")
        wakeTask?.cancel()
        wakeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.run()
        }
    }

    /// Where a page's photo stands for reading.
    private enum PagePhoto {
        case image(CGImage)
        /// No record or file on this device yet.
        case notHere
        /// The file is here and can't be read.
        case unreadable
    }

    /// Failures of a job that aren't the reader's, structurer's or a writer's own errors.
    private enum JobError: Error {
        case photoUnreadable(UUID)
        case noRecipe
    }

    /// One job: read the recipe's unread pages, then structure it and save it (`15` M3-2 part 5).
    private func runJob(_ job: ExtractionJob) async {
        let recipeID = job.recipeID
        log.info(self, "recipe \(recipeID): job started, \(job.attempts) failed attempts so far")
        currentRecipeID = recipeID
        defer {
            currentRecipeID = nil
            setReading(nil)
        }
        guard let recipe = fetchRecipe(recipeID), recipe.reviewState != .edited,
              pages(recipe.sourcePageIDs).values.contains(where: { $0.structuringState == .waiting }) else {
            log.info(self, "recipe \(recipeID): gone, edited or not waiting; job removed")
            removeJob(job.id)
            return
        }
        // The bar starts at 0; pages already read (RV-4) aren't counted.
        let unread = pages(recipe.sourcePageIDs).values.filter { $0.ocrText == nil }.count
        setReading(ReadingProgress(pagesToRead: unread))

        do {
            // Read each unread page, in order.
            for pageID in recipe.sourcePageIDs {
                guard let page = pages([pageID])[pageID], page.ocrText == nil else { continue }
                switch await photo(of: pageID) {
                case .notHere:
                    var waiting = currentJob(job.id) ?? job
                    waiting.notBefore = Date().addingTimeInterval(ExtractionPlanner.photoWait)
                    updateJob(waiting)
                    log.info(self, "recipe \(recipeID): page \(pageID) photo not here yet; waits \(Int(ExtractionPlanner.photoWait)) s")
                    return
                case .unreadable:
                    throw JobError.photoUnreadable(pageID)
                case .image(let image):
                    let start = ContinuousClock.now
                    let reading = try await reader.read(image)
                    let words = reading.lines.map { line in
                        OCRWord(text: line.text,
                                box: SourceBox(pageID: pageID, x: line.box.x, y: line.box.y,
                                               width: line.box.width, height: line.box.height),
                                confidence: line.confidence)
                    }
                    try captureRecorder.recordReading(pageID: pageID, text: reading.text, words: words)
                    advanceReading { $0.pageRead() }
                    log.info(self, "recipe \(recipeID): page \(pageID) read in \(Self.millis(since: start)) ms, \(words.count) lines")
                }
            }

            // A device that can't structure stops here; the pages stay waiting (SLT-044).
            guard RecipeStructurer.isAvailable else {
                log.info(self, "recipe \(recipeID): read; can't structure here, left waiting; job removed")
                removeJob(job.id)
                return
            }

            // Structure, retrying a refusal while in front (SLT-153, as `SpikeRunner.structure`).
            let read = pages(recipe.sourcePageIDs)
            let readings = recipe.sourcePageIDs.map { PageReading(words: read[$0]?.ocrWords ?? []) }
            var refusals = 0
            while true {
                do {
                    let start = ContinuousClock.now
                    let outcome = try await structurer.structure(readings, pageIDs: recipe.sourcePageIDs) { part in
                        // Back on the main actor; the queue lives as long as the app.
                        Task { @MainActor in self.partDone(part, recipeID: recipeID) }
                    }
                    guard let structured = outcome.recipes.first else {
                        throw JobError.noRecipe
                    }
                    log.info(self, "recipe \(recipeID): structured in \(Self.millis(since: start)) ms, \(structured.extraction?.warnings.count ?? 0) warnings")
                    // "Page n of n" on the last page clears the page-2 warning (RV-26).
                    let lastPageEnds = UnfinishedPageCheck.saysLastPage(readings.last?.lines.map(\.text) ?? [])
                    let warning = !recipe.continuesOnUnscannedPage ? "none" : (lastPageEnds ? "cleared" : "kept")
                    log.info(self, "recipe \(recipeID): last page says it ends: \(lastPageEnds); page-2 warning \(warning)")
                    let saved = try captureRecorder.finishStructuring(structured, recipeID: recipeID,
                                                                      lastPageEnds: lastPageEnds, now: Date())
                    log.info(self, "recipe \(recipeID): \(saved ? "saved" : "not saved, another device was first"); job removed")
                    removeJob(job.id)
                    return
                } catch where RecipeStructurer.isRateLimit(error) {
                    refusals += 1
                    // A job that waits shows no bar (M3-3f).
                    let pagesToRead = reading?.pagesToRead ?? 0
                    setReading(nil)
                    if isActive, let delay = Self.rateLimitDelay(afterRefusal: refusals) {
                        log.info(self, "recipe \(recipeID): refused (\(refusals)); waits 30 s")
                        try? await Task.sleep(for: delay)
                        if isActive, !Task.isCancelled {
                            // Structuring again: the pages are read, the parts start over.
                            var again = ReadingProgress(pagesToRead: pagesToRead)
                            for _ in 0..<pagesToRead { again.pageRead() }
                            setReading(again)
                            continue
                        }
                    }
                    log.info(self, "recipe \(recipeID): refused; waits until Sylantro is in front again")
                    isWaitingForApp = true
                    return
                }
            }
        } catch {
            fail(job, pageIDs: recipe.sourcePageIDs, error: error)
        }
    }

    // MARK: Progress (`15` M3-3f)

    private func setReading(_ value: ReadingProgress?) {
        reading = value
        progress = value?.fraction
    }

    private func advanceReading(_ step: (inout ReadingProgress) -> Void) {
        guard var value = reading else { return }
        step(&value)
        setReading(value)
    }

    /// A part the structurer finished, for the job still running on this recipe; a late one after
    /// the job ended, or while it waits, changes nothing.
    private func partDone(_ part: String, recipeID: UUID) {
        guard currentRecipeID == recipeID else { return }
        advanceReading { $0.partDone(part) }
    }

    /// A failed read, structuring or save: one more attempt counted, and either a wait by
    /// `retryDelay` or, after the last, the pages marked failed and the job removed (RV-24).
    private func fail(_ job: ExtractionJob, pageIDs: [UUID], error: any Error) {
        var failed = currentJob(job.id) ?? job
        failed.attempts += 1
        failed.lastError = String(describing: error)
        log.error(self, "recipe \(failed.recipeID): attempt \(failed.attempts) failed (\(type(of: error)))")
        log.debug(self, "recipe \(failed.recipeID): \(String(describing: error))")
        if let delay = ExtractionPlanner.retryDelay(afterAttempt: failed.attempts) {
            failed.notBefore = Date().addingTimeInterval(delay)
            updateJob(failed)
            log.info(self, "recipe \(failed.recipeID): tried again in \(Int(delay)) s")
            return
        }
        do {
            try captureRecorder.markFailed(pageIDs: pageIDs)
        } catch {
            log.error(self, "recipe \(failed.recipeID): pages not marked failed: \(error)")
        }
        removeJob(failed.id)
        log.info(self, "recipe \(failed.recipeID): gave up after \(failed.attempts) attempts; pages marked failed")
    }

    // MARK: Reading the stores

    /// The page's photo: its cropped one, else its original (`15` M3-2), at full size, loaded off
    /// the main actor.
    private func photo(of pageID: UUID) async -> PagePhoto {
        let photos = ((try? syncedContext.fetch(FetchDescriptor<PhotoModel>())) ?? []).filter { $0.sourcePageID == pageID }
        let photo = photos.first { $0.kindRaw == PhotoKind.pageCropped.rawValue }
            ?? photos.first { $0.kindRaw == PhotoKind.pageOriginal.rawValue }
        guard let fileName = photo?.fileName, photoFiles.availability(of: fileName) == .available else {
            return .notHere
        }
        let files = photoFiles
        guard let image = await Task.detached(operation: { files.fullImage(of: fileName) }).value else {
            return .unreadable
        }
        return .image(image)
    }

    /// The recipe's first copy.
    private func fetchRecipe(_ recipeID: UUID) -> Recipe? {
        var descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID })
        descriptor.fetchLimit = 1
        return (try? syncedContext.fetch(descriptor))?.first?.toDomain()
    }

    /// The pages with these ids, the first copy of each.
    private func pages(_ pageIDs: [UUID]) -> [UUID: SourcePage] {
        let wanted = Set(pageIDs)
        var result: [UUID: SourcePage] = [:]
        let models = (try? syncedContext.fetch(FetchDescriptor<SourcePageModel>())) ?? []
        for model in models where wanted.contains(model.id) && result[model.id] == nil {
            result[model.id] = model.toDomain()
        }
        return result
    }

    // MARK: The jobs

    private func currentJobs() -> [ExtractionJob] {
        ((try? context?.fetch(FetchDescriptor<ExtractionJobModel>())) ?? []).compactMap { $0.toDomain() }
    }

    private func currentJob(_ id: UUID) -> ExtractionJob? {
        jobModels(id).first?.toDomain()
    }

    private func jobModels(_ id: UUID) -> [ExtractionJobModel] {
        (try? context?.fetch(FetchDescriptor<ExtractionJobModel>(predicate: #Predicate { $0.id == id }))) ?? []
    }

    /// Writes the job back; a job removed meanwhile (by planning) stays removed.
    private func updateJob(_ job: ExtractionJob) {
        guard let context else { return }
        for model in jobModels(job.id) {
            model.hydrate(from: job)
        }
        do {
            try context.save()
        } catch {
            log.error(self, "recipe \(job.recipeID): job not updated: \(error)")
        }
    }

    private func removeJob(_ id: UUID) {
        guard let context else { return }
        for model in jobModels(id) {
            context.delete(model)
        }
        do {
            try context.save()
        } catch {
            log.error(self, "job \(id) not removed: \(error)")
        }
    }

    // MARK: Helpers

    /// As `SpikeRunner.retryDelay(afterRefusal:)`: 30 s for the first three refusals in a row, then
    /// nil (SLT-153).
    private static func rateLimitDelay(afterRefusal count: Int) -> Duration? {
        (1...3).contains(count) ? .seconds(30) : nil
    }

    private static func millis(since start: ContinuousClock.Instant) -> Int {
        let (seconds, attoseconds) = (ContinuousClock.now - start).components
        return Int(seconds * 1000 + attoseconds / 1_000_000_000_000_000)
    }
}
