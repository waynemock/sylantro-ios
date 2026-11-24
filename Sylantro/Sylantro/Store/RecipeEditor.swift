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
}

/// The writer for recipes (`02` §5.2, SLT-082, `14` MT-8). M2-3 gives it what capture needs, M3-2
/// the queue's structured reading; review's edits come later in M3. Only `delete` saves: for the
/// rest, the caller saves once.
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

        // Its pages: every copy's, minus any another recipe lists (SLT-047, for M3).
        var pageIDs = Set(models.compactMap { $0.toDomain() }.flatMap(\.sourcePageIDs))
        let otherRecipes = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id != recipeID }))
        for other in otherRecipes {
            if let recipe = other.toDomain() {
                pageIDs.subtract(recipe.sourcePageIDs)
            }
        }

        // Its photos: those of its pages, of both kinds, and any dish photo of the recipe.
        let photos = try context.fetch(FetchDescriptor<PhotoModel>()).filter { photo in
            photo.sourcePageID.map { pageIDs.contains($0) } == true || photo.recipeID == recipeID
        }
        let fileNames = photos.compactMap(\.fileName)

        // Its sessions: those of its pages that no remaining page points to.
        let allPages = try context.fetch(FetchDescriptor<SourcePageModel>())
        let pages = allPages.filter { pageIDs.contains($0.id) }
        let remainingSessionIDs = Set(allPages.filter { !pageIDs.contains($0.id) }.compactMap(\.sessionID))
        let sessionIDs = Set(pages.compactMap(\.sessionID)).subtracting(remainingSessionIDs)
        let sessions = try context.fetch(FetchDescriptor<ScanSessionModel>()).filter { sessionIDs.contains($0.id) }

        for model in models { context.delete(model) }
        for page in pages { context.delete(page) }
        for photo in photos { context.delete(photo) }
        for session in sessions { context.delete(session) }
        do {
            try context.save()
        } catch {
            // No file is touched when the save fails.
            context.rollback()
            log.error(self, "recipe \(recipeID): not deleted: \(error)")
            throw error
        }
        log.info(self, "recipe \(recipeID) deleted: \(pages.count) pages, \(photos.count) photos")

        guard !fileNames.isEmpty || mirror != nil else { return nil }
        let photoFiles = photoFiles
        let mirror = mirror
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
}
