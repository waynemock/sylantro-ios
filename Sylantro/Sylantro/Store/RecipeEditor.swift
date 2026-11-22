import Foundation
import SwiftData
import SyLibCore

/// Why `RecipeEditor` couldn't change a recipe.
enum RecipeEditorError: Error, Equatable {
    /// No recipe has this id.
    case recipeNotFound(UUID)
    /// The recipe's data couldn't be read, so it is left as it is.
    case recipeUnreadable(UUID)
}

/// The writer for recipes (`02` §5.2, SLT-082, `14` MT-8). M2-3 gives it only what capture needs;
/// review's edits come in M3. Neither call saves: the caller saves once.
@MainActor
final class RecipeEditor {
    private let log = AppLogger(category: "RecipeEditor")
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
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

    /// Deletes the recipe and saves. Its pages, photos and files stay, as pages without a recipe
    /// (SC-5, SLT-030). Every copy with this id goes, since CloudKit allows duplicates (`02` §5.2).
    func delete(_ recipeID: UUID) throws {
        let models = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID }))
        guard !models.isEmpty else {
            throw RecipeEditorError.recipeNotFound(recipeID)
        }
        for model in models {
            context.delete(model)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            log.error(self, "recipe \(recipeID): not deleted: \(error)")
            throw error
        }
        log.info(self, "recipe \(recipeID) deleted; its pages and photos are kept")
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
}
