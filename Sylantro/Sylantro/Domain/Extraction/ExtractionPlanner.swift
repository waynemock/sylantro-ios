import Foundation

/// The extraction queue's rules (`15` M3-2): which recipes this device reads and structures, which
/// comes next, how long it waits after a failure, and how a structured recipe replaces its draft.
nonisolated enum ExtractionPlanner {
    /// Another device waits this long after a page's capture before taking it (RV-3).
    static let otherDeviceWait: TimeInterval = 600
    /// After this many failed attempts the recipe's pages are marked failed (RV-24).
    static let maximumAttempts = 3
    /// A photo not yet on this device is looked for again after this long.
    static let photoWait: TimeInterval = 60

    /// The waits after the first and second failures (RV-24).
    private static let retryDelays: [TimeInterval] = [60, 300]

    /// The wait after the `attempt`th failure: 60 s after the first, 300 s after the second; nil
    /// from the third on, which gives up (RV-24).
    static func retryDelay(afterAttempt attempt: Int) -> TimeInterval? {
        guard attempt >= 1, attempt < maximumAttempts, attempt <= retryDelays.count else {
            return nil
        }
        return retryDelays[attempt - 1]
    }

    /// The jobs to add and the job ids to remove, from the synced store's pages and recipes and
    /// this device's jobs. Pages and recipes count once per id, the first of any duplicates
    /// (`02` §5.2). A recipe is waiting when one of its pages is `.waiting` and it isn't `.edited`
    /// (RV-7); it needs reading when one of its waiting pages has no `ocrText`. A waiting recipe
    /// with no job gets one, `notBefore` its latest waiting capture plus `otherDeviceWait` (RV-3),
    /// when this device can structure or the recipe needs reading (SLT-044). A job whose recipe is
    /// gone, isn't waiting, or (when this device can't structure) doesn't need reading is removed.
    static func plan(pages: [SourcePage], recipes: [Recipe], jobs: [ExtractionJob],
                     canStructure: Bool, now: Date) -> (add: [ExtractionJob], remove: [UUID]) {
        let pagesByID = firstByID(pages, id: \.id)
        let recipesByID = firstByID(recipes, id: \.id)

        /// The recipe's waiting pages, or none when it is edited.
        func waitingPages(of recipe: Recipe) -> [SourcePage] {
            guard recipe.reviewState != .edited else {
                return []
            }
            return recipe.sourcePageIDs.compactMap { pagesByID[$0] }.filter { $0.structuringState == .waiting }
        }

        func wanted(_ waiting: [SourcePage]) -> Bool {
            !waiting.isEmpty && (canStructure || waiting.contains { $0.ocrText == nil })
        }

        var remove: [UUID] = []
        var recipesWithJobs = Set<UUID>()
        for job in jobs {
            recipesWithJobs.insert(job.recipeID)
            if let recipe = recipesByID[job.recipeID], wanted(waitingPages(of: recipe)) {
                continue
            }
            remove.append(job.id)
        }

        var add: [ExtractionJob] = []
        var seen = Set<UUID>()
        // `recipes` in order, so each id's first copy is the one used.
        for recipe in recipes where seen.insert(recipe.id).inserted && !recipesWithJobs.contains(recipe.id) {
            let waiting = waitingPages(of: recipe)
            guard wanted(waiting), let latest = waiting.map(\.capturedAt).max() else {
                continue
            }
            add.append(ExtractionJob(recipeID: recipe.id, scannedHere: false,
                                     notBefore: latest.addingTimeInterval(otherDeviceWait)))
        }
        return (add, remove)
    }

    /// The job to run next: due (`notBefore <= now`), its recipe's `createdAt` the oldest, then
    /// the smaller `id` (compared as `uuidString`); nil when none is due or its recipe is gone.
    static func next(jobs: [ExtractionJob], recipes: [Recipe], now: Date) -> ExtractionJob? {
        let recipesByID = firstByID(recipes, id: \.id)
        let due = jobs.compactMap { job -> (job: ExtractionJob, createdAt: Date)? in
            guard job.notBefore <= now, let recipe = recipesByID[job.recipeID] else {
                return nil
            }
            return (job, recipe.createdAt)
        }
        return due.min { first, second in
            if first.createdAt != second.createdAt {
                return first.createdAt < second.createdAt
            }
            return first.job.id.uuidString < second.job.id.uuidString
        }?.job
    }

    /// `structured` as a reading of `existing`: its id, pages, tags, parent and creation date are
    /// `existing`'s; its page-2 warning is `existing`'s unless `lastPageEnds` (the last page says
    /// "Page n of n", RV-26), which clears it; it needs review, was updated and extracted `now` on
    /// the device, at the current schema version. Everything else is `structured`'s.
    static func merged(_ structured: Recipe, into existing: Recipe, lastPageEnds: Bool, now: Date) -> Recipe {
        var recipe = structured
        recipe.id = existing.id
        recipe.sourcePageIDs = existing.sourcePageIDs
        recipe.continuesOnUnscannedPage = existing.continuesOnUnscannedPage && !lastPageEnds
        recipe.tags = existing.tags
        recipe.parentRecipeID = existing.parentRecipeID
        recipe.createdAt = existing.createdAt
        recipe.reviewState = .needsReview
        recipe.updatedAt = now
        recipe.schemaVersion = Recipe.currentSchemaVersion
        var extraction = structured.extraction ?? Extraction()
        extraction.engine = Extraction.onDeviceEngine
        extraction.extractedAt = now
        recipe.extraction = extraction
        return recipe
    }

    /// Each value by its id, the first of any duplicates.
    private static func firstByID<Value>(_ values: [Value], id: (Value) -> UUID) -> [UUID: Value] {
        var result: [UUID: Value] = [:]
        for value in values where result[id(value)] == nil {
            result[id(value)] = value
        }
        return result
    }
}
