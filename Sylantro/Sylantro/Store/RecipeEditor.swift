import Foundation
import SwiftData
import SyLibCore

/// Why `RecipeEditor` couldn't change a recipe.
enum RecipeEditorError: Error, Equatable {
    /// No recipe has this id.
    case recipeNotFound(UUID)
    /// The recipe's data couldn't be read, so it is left as it is.
    case recipeUnreadable(UUID)
    /// She has edited the recipe, so a new reading doesn't replace it (RV-7).
    case recipeEdited(UUID)
    /// The pages given aren't the recipe's (M3-4).
    case pagesDontMatch(UUID)
    /// The recipe's only page can't be removed; Delete Recipe removes it all (M3-4).
    case lastPage(UUID)
}

/// The writer for recipes (`02` §5.2, SLT-082, `14` MT-8). M2-3 gives it what capture needs, M3-2
/// the queue's structured reading, M3-3 review's three changes, M3-4 a recipe's pages. `delete`,
/// `markReviewed`, `saveEdits`, `dismissPageTwoWarning`, `reorderPages` and `removePage` save (all
/// but `delete` then write the Files copy); the others don't: their caller saves once.
@MainActor
final class RecipeEditor {
    private let log = AppLogger(category: "RecipeEditor")
    private let context: ModelContext
    /// The copy in Files, changed after each save on this device (MT-15); nil changes none.
    private let mirror: MirrorWriter?
    /// The photo files a deleted recipe's photos are removed from (SLT-157); nil removes none.
    private let photoFiles: PhotoFiles?

    init(context: ModelContext, mirror: MirrorWriter? = nil, photoFiles: PhotoFiles? = nil) {
        self.context = context
        self.mirror = mirror
        self.photoFiles = photoFiles
    }

    /// Inserts a new draft recipe read from `pageIDs`, in order (SC-1). Does not save.
    @discardableResult
    func insertDraft(pageIDs: [UUID], continuesOnUnscannedPage: Bool, now: Date) -> Recipe {
        let recipe = Recipe(
            title: "",
            sourcePageIDs: pageIDs,
            continuesOnUnscannedPage: continuesOnUnscannedPage,
            reviewState: .needsReview,
            createdAt: now,
            updatedAt: now
        )
        let model = RecipeModel()
        model.hydrate(from: recipe)
        context.insert(model)
        log.info(self, "draft \(recipe.id): \(pageIDs.count) pages")
        return recipe
    }

    /// Deletes the recipe and everything that is only its (SLT-157): its pages, their photo records
    /// and sessions left with no page, in one save; then, only once that save succeeds, its photo
    /// files and its folder in Files, in a detached task it returns (nil when there is nothing to
    /// remove and no mirror). A page another recipe lists is kept. Every copy with this id goes,
    /// since CloudKit allows duplicates (`02` §5.2). The view never waits for the task.
    @discardableResult
    func delete(_ recipeID: UUID) throws -> Task<Void, Never>? {
        let models = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID }))
        guard !models.isEmpty else {
            throw RecipeEditorError.recipeNotFound(recipeID)
        }

        // Its pages, those no other recipe lists, with their photos and sessions; and any dish
        // photo of the recipe.
        let pageIDs = Set(models.compactMap { $0.toDomain() }.flatMap(\.sourcePageIDs))
        let records = try recordsOnly(of: recipeID, pageIDs: pageIDs)
        let dishPhotos = try context.fetch(FetchDescriptor<PhotoModel>()).filter { photo in
            photo.recipeID == recipeID && !records.photos.contains { $0 === photo }
        }
        let photos = records.photos + dishPhotos

        for model in models { context.delete(model) }
        for page in records.pages { context.delete(page) }
        for photo in photos { context.delete(photo) }
        for session in records.sessions { context.delete(session) }
        do {
            try context.save()
        } catch {
            // No file is touched when the save fails.
            context.rollback()
            log.error(self, "recipe \(recipeID): not deleted: \(error)")
            throw error
        }
        log.info(self, "recipe \(recipeID) deleted: \(records.pages.count) pages, \(photos.count) photos")
        return removeFilesAfterSave(photos.compactMap(\.fileName), of: recipeID, removingFolder: true)
    }

    // MARK: A recipe's pages (`15` M3-4)

    /// The pages she put in order (RV-15): `pageIDs` must be exactly the recipe's pages, in any
    /// order, on every copy, else `pagesDontMatch` and nothing changes. Saves, and the Files copy's
    /// pages are written again in the new order.
    func reorderPages(_ pageIDs: [UUID], of recipeID: UUID, now: Date) throws {
        let changed = try changedCopies(recipeID) { recipe in
            guard pageIDs.count == recipe.sourcePageIDs.count,
                  pageIDs.map(\.uuidString).sorted() == recipe.sourcePageIDs.map(\.uuidString).sorted() else {
                throw RecipeEditorError.pagesDontMatch(recipeID)
            }
            recipe.sourcePageIDs = pageIDs
            recipe.updatedAt = now
        }
        for (model, recipe) in changed {
            model.hydrate(from: recipe)
        }
        try saveAndMirror(recipeID: recipeID, pagesChanged: true)
        log.info(self, "recipe \(recipeID): pages reordered, \(changed.count) copies")
    }

    /// A page she removed (RV-15, SLT-157): out of the recipe on every copy (its only page throws
    /// `lastPage`, a page not in it `pagesDontMatch`, and nothing changes). When no other recipe
    /// lists it, its page and photo records, and a session left with no page, go in the same save,
    /// and its photo files after it, in a detached task it returns, as `delete` does. Saves, and
    /// the Files copy's pages are written again.
    @discardableResult
    func removePage(_ pageID: UUID, from recipeID: UUID, now: Date) throws -> Task<Void, Never>? {
        let changed = try changedCopies(recipeID) { recipe in
            guard recipe.sourcePageIDs.contains(pageID) else {
                throw RecipeEditorError.pagesDontMatch(recipeID)
            }
            guard recipe.sourcePageIDs.count > 1 else {
                throw RecipeEditorError.lastPage(recipeID)
            }
            recipe.sourcePageIDs.removeAll { $0 == pageID }
            recipe.updatedAt = now
        }
        let records = try recordsOnly(of: recipeID, pageIDs: [pageID])
        for (model, recipe) in changed {
            model.hydrate(from: recipe)
        }
        for page in records.pages { context.delete(page) }
        for photo in records.photos { context.delete(photo) }
        for session in records.sessions { context.delete(session) }
        try saveAndMirror(recipeID: recipeID, pagesChanged: true)
        log.info(self, "recipe \(recipeID): page removed, \(records.pages.count) page copies and \(records.photos.count) photos deleted")
        return removeFilesAfterSave(records.photos.compactMap(\.fileName), of: recipeID, removingFolder: false)
    }

    /// Read Again on a recipe she edited (RV-7): it needs review again, on every copy, so the
    /// queue reads it. Does not save.
    func reopenForReading(_ recipeID: UUID, now: Date) throws {
        let changed = try changedCopies(recipeID) { recipe in
            if recipe.reviewState == .edited {
                recipe.reviewState = .needsReview
            }
        }
        for (model, recipe) in changed {
            model.hydrate(from: recipe)
        }
        log.info(self, "recipe \(recipeID): reopened for reading, \(changed.count) copies")
    }

    /// The records of `pageIDs` that only `recipeID` lists (SLT-047: a page another recipe lists is
    /// kept): every copy of those pages, their photos of any kind, and the sessions they would
    /// leave with no page.
    private func recordsOnly(of recipeID: UUID, pageIDs: Set<UUID>) throws
        -> (pages: [SourcePageModel], photos: [PhotoModel], sessions: [ScanSessionModel]) {
        var pageIDs = pageIDs
        let otherRecipes = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id != recipeID }))
        for other in otherRecipes {
            if let recipe = other.toDomain() {
                pageIDs.subtract(recipe.sourcePageIDs)
            }
        }
        let photos = try context.fetch(FetchDescriptor<PhotoModel>()).filter { photo in
            photo.sourcePageID.map { pageIDs.contains($0) } == true
        }
        let allPages = try context.fetch(FetchDescriptor<SourcePageModel>())
        let pages = allPages.filter { pageIDs.contains($0.id) }
        let remainingSessionIDs = Set(allPages.filter { !pageIDs.contains($0.id) }.compactMap(\.sessionID))
        let sessionIDs = Set(pages.compactMap(\.sessionID)).subtracting(remainingSessionIDs)
        let sessions = try context.fetch(FetchDescriptor<ScanSessionModel>()).filter { sessionIDs.contains($0.id) }
        return (pages, photos, sessions)
    }

    /// After a save that removed photo records: their files, and with `removingFolder` the
    /// recipe's folder in Files, in a detached task (nil when there is nothing to do).
    private func removeFilesAfterSave(_ fileNames: [String], of recipeID: UUID, removingFolder: Bool) -> Task<Void, Never>? {
        let mirror = removingFolder ? mirror : nil
        guard !fileNames.isEmpty || mirror != nil else { return nil }
        let photoFiles = photoFiles
        let log = log
        return Task.detached {
            var removed = 0
            if let photoFiles {
                for fileName in fileNames {
                    do {
                        try photoFiles.remove(fileName)
                        removed += 1
                    } catch {
                        log.error(RecipeEditor.self, "recipe \(recipeID): \(fileName) not removed: \(error)")
                    }
                }
            }
            log.info(RecipeEditor.self, "recipe \(recipeID): \(removed) photo files removed")
            await mirror?.removeRecipe(recipeID: recipeID)
        }
    }

    /// Adds `pageIDs` after the recipe's pages and clears its page-2 warning (Add Page, SLT-046).
    /// Does not save.
    func appendPages(_ pageIDs: [UUID], to recipeID: UUID, now: Date) throws {
        var descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID })
        descriptor.fetchLimit = 1
        guard let model = try context.fetch(descriptor).first else {
            throw RecipeEditorError.recipeNotFound(recipeID)
        }
        guard var recipe = model.toDomain() else {
            throw RecipeEditorError.recipeUnreadable(recipeID)
        }
        recipe.sourcePageIDs.append(contentsOf: pageIDs)
        recipe.continuesOnUnscannedPage = false
        recipe.updatedAt = now
        model.hydrate(from: recipe)
        log.info(self, "recipe \(recipeID): \(pageIDs.count) pages added, \(recipe.sourcePageIDs.count) in all")
    }

    /// Every copy of the recipe becomes `structured` as its reading (`ExtractionPlanner.merged`,
    /// `15` M3-2), its page-2 warning cleared when `lastPageEnds` (M3-2a). Every copy is checked
    /// before any changes, so a throw changes nothing: no copy, a copy that can't be read, or one
    /// she has edited (RV-7). Does not save.
    func applyStructure(_ structured: Recipe, to recipeID: UUID, lastPageEnds: Bool, now: Date) throws {
        let models = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID }))
        guard !models.isEmpty else {
            throw RecipeEditorError.recipeNotFound(recipeID)
        }
        var existing: [(model: RecipeModel, recipe: Recipe)] = []
        for model in models {
            guard let recipe = model.toDomain() else {
                throw RecipeEditorError.recipeUnreadable(recipeID)
            }
            existing.append((model, recipe))
        }
        guard !existing.contains(where: { $0.recipe.reviewState == .edited }) else {
            throw RecipeEditorError.recipeEdited(recipeID)
        }
        for (model, recipe) in existing {
            model.hydrate(from: ExtractionPlanner.merged(structured, into: recipe, lastPageEnds: lastPageEnds, now: now))
        }
        log.info(self, "recipe \(recipeID): structured, \(models.count) copies")
    }

    // MARK: Review (`15` M3-3)

    /// Looks Good (RV-13): reviewed, unless she has edited it, which it stays. Saves.
    func markReviewed(_ recipeID: UUID, now: Date) throws {
        try change(recipeID, "marked reviewed") { recipe in
            if recipe.reviewState != .edited {
                recipe.reviewState = .reviewed
            }
            recipe.updatedAt = now
        }
    }

    /// Done in review's Edit (RV-12, SC-10): her edit applied, the recipe marked edited. Saves.
    func saveEdits(_ edit: ReviewEdit, to recipeID: UUID, now: Date) throws {
        try change(recipeID, "edits saved") { recipe in
            recipe = edit.applied(to: recipe, now: now)
        }
    }

    /// That's All of It (S-53, RV-26): the page-2 warning removed for good. Saves.
    func dismissPageTwoWarning(_ recipeID: UUID, now: Date) throws {
        try change(recipeID, "page-2 warning dismissed") { recipe in
            recipe.continuesOnUnscannedPage = false
            recipe.updatedAt = now
        }
    }

    /// Every copy of the recipe, changed by `body`, after checking every copy can be read (as
    /// `applyStructure`); then saved and its Files copy written.
    private func change(_ recipeID: UUID, _ what: String, _ body: (inout Recipe) throws -> Void) throws {
        let changed = try changedCopies(recipeID, body)
        for (model, recipe) in changed {
            model.hydrate(from: recipe)
        }
        try saveAndMirror(recipeID: recipeID)
        log.info(self, "recipe \(recipeID): \(what), \(changed.count) copies")
    }

    /// Every copy of the recipe with `body` applied, nothing written yet: no copy throws
    /// `recipeNotFound`, a copy that can't be read `recipeUnreadable`, and `body` may throw, so a
    /// throw changes nothing.
    private func changedCopies(_ recipeID: UUID, _ body: (inout Recipe) throws -> Void) throws
        -> [(model: RecipeModel, recipe: Recipe)] {
        let models = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID }))
        guard !models.isEmpty else {
            throw RecipeEditorError.recipeNotFound(recipeID)
        }
        var changed: [(model: RecipeModel, recipe: Recipe)] = []
        for model in models {
            guard var recipe = model.toDomain() else {
                throw RecipeEditorError.recipeUnreadable(recipeID)
            }
            try body(&recipe)
            changed.append((model, recipe))
        }
        return changed
    }

    /// Saves, then writes the recipe's copy in Files as `CaptureRecorder` does after its saves, its
    /// page copies written again when `pagesChanged` (M3-4); a failed save is rolled back, logged
    /// and rethrown.
    private func saveAndMirror(recipeID: UUID, pagesChanged: Bool = false) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            log.error(self, "recipe \(recipeID): not saved: \(error)")
            throw error
        }
        guard let mirror else { return }
        var descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID })
        descriptor.fetchLimit = 1
        guard let recipe = (try? context.fetch(descriptor))?.first?.toDomain() else {
            log.error(self, "recipe \(recipeID): no copy in Files: not readable")
            return
        }
        do {
            guard let snapshot = try MirrorSnapshot.make(for: [recipe], in: context, pagesChanged: pagesChanged).first else { return }
            Task { await mirror.write(snapshot) }
        } catch {
            log.error(self, "recipe \(recipeID): no copy in Files: \(error)")
        }
    }
}
