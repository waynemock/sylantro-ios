import Foundation
import Testing
@testable import Sylantro

/// `ExtractionPlanner` (`15` M3-2): which recipes get a job, which job runs next, the waits after a
/// failure, and how a structured recipe replaces its draft. Every value is made up.
@Suite("Extraction planner")
struct ExtractionPlannerTests {
    static let now = Date(timeIntervalSince1970: 1_795_000_000)
    static let captured = now.addingTimeInterval(-120)

    static func page(_ state: StructuringState = .waiting, ocrText: String? = nil,
                     capturedAt: Date = captured) -> SourcePage {
        SourcePage(capturedAt: capturedAt, ocrText: ocrText, structuringState: state)
    }

    static func recipe(_ pages: [SourcePage], reviewState: ReviewState = .needsReview,
                       createdAt: Date = captured) -> Recipe {
        Recipe(sourcePageIDs: pages.map(\.id), reviewState: reviewState, createdAt: createdAt, updatedAt: createdAt)
    }

    @Test("a waiting recipe gets a job")
    func waitingRecipeGetsAJob() throws {
        let page = Self.page()
        let recipe = Self.recipe([page])

        let plan = ExtractionPlanner.plan(pages: [page], recipes: [recipe], jobs: [], canStructure: true, now: Self.now)

        try #require(plan.add.count == 1)
        #expect(plan.add[0].recipeID == recipe.id)
        #expect(plan.add[0].scannedHere == false)
        #expect(plan.add[0].attempts == 0)
        #expect(plan.add[0].notBefore == Self.captured.addingTimeInterval(600))
        #expect(plan.remove.isEmpty)
    }

    @Test("one job a recipe")
    func oneJobARecipe() {
        let page = Self.page()
        let recipe = Self.recipe([page])
        let job = ExtractionJob(recipeID: recipe.id)

        let plan = ExtractionPlanner.plan(pages: [page], recipes: [recipe], jobs: [job], canStructure: true, now: Self.now)

        #expect(plan.add.isEmpty)
        #expect(plan.remove.isEmpty)
    }

    @Test("a read recipe's job goes")
    func readRecipesJobGoes() {
        let pages = [Self.page(.structured, ocrText: "Test Soup"), Self.page(.structured, ocrText: "Serves 2")]
        let recipe = Self.recipe(pages)
        let job = ExtractionJob(recipeID: recipe.id)

        let plan = ExtractionPlanner.plan(pages: pages, recipes: [recipe], jobs: [job], canStructure: true, now: Self.now)

        #expect(plan.add.isEmpty)
        #expect(plan.remove == [job.id])
    }

    @Test("a deleted recipe's job goes")
    func deletedRecipesJobGoes() {
        let job = ExtractionJob(recipeID: UUID())

        let plan = ExtractionPlanner.plan(pages: [], recipes: [], jobs: [job], canStructure: true, now: Self.now)

        #expect(plan.add.isEmpty)
        #expect(plan.remove == [job.id])
    }

    @Test("can't structure")
    func cantStructure() {
        let unreadPage = Self.page()
        let unread = Self.recipe([unreadPage])
        let readPage = Self.page(ocrText: "Test Soup")
        let read = Self.recipe([readPage])
        let readJob = ExtractionJob(recipeID: read.id)

        let plan = ExtractionPlanner.plan(pages: [unreadPage, readPage], recipes: [unread, read], jobs: [readJob],
                                          canStructure: false, now: Self.now)

        #expect(plan.add.map(\.recipeID) == [unread.id])
        #expect(plan.remove == [readJob.id])
    }

    @Test("edited recipes wait")
    func editedRecipesWait() {
        let page = Self.page()
        let recipe = Self.recipe([page], reviewState: .edited)

        let plan = ExtractionPlanner.plan(pages: [page], recipes: [recipe], jobs: [], canStructure: true, now: Self.now)

        #expect(plan.add.isEmpty)
    }

    @Test("duplicates count once")
    func duplicatesCountOnce() {
        let page = Self.page()
        let recipe = Self.recipe([page])

        let plan = ExtractionPlanner.plan(pages: [page, page], recipes: [recipe, recipe], jobs: [],
                                          canStructure: true, now: Self.now)

        #expect(plan.add.map(\.recipeID) == [recipe.id])
    }

    @Test("next")
    func nextJob() {
        let older = Self.recipe([], createdAt: Self.now.addingTimeInterval(-3_600))
        let newer = Self.recipe([], createdAt: Self.now.addingTimeInterval(-60))
        let oldest = Self.recipe([], createdAt: Self.now.addingTimeInterval(-7_200))
        let olderJob = ExtractionJob(recipeID: older.id, notBefore: Self.now)
        let newerJob = ExtractionJob(recipeID: newer.id, notBefore: Self.now.addingTimeInterval(-10))
        // The oldest recipe's job isn't due yet, so it is passed over.
        let notDue = ExtractionJob(recipeID: oldest.id, notBefore: Self.now.addingTimeInterval(60))
        let recipes = [older, newer, oldest]

        #expect(ExtractionPlanner.next(jobs: [newerJob, notDue, olderJob], recipes: recipes, now: Self.now) == olderJob)
        #expect(ExtractionPlanner.next(jobs: [notDue], recipes: recipes, now: Self.now) == nil)
    }

    @Test("retry delays")
    func retryDelays() {
        #expect(ExtractionPlanner.retryDelay(afterAttempt: 1) == 60)
        #expect(ExtractionPlanner.retryDelay(afterAttempt: 2) == 300)
        #expect(ExtractionPlanner.retryDelay(afterAttempt: 3) == nil)
        #expect(ExtractionPlanner.maximumAttempts == 3)
    }

    @Test("merged")
    func mergedKeepsTheDraftsFields() {
        let existing = Recipe(
            title: "",
            tags: ["soups"],
            sourcePageIDs: [UUID(), UUID()],
            continuesOnUnscannedPage: true,
            reviewState: .needsReview,
            createdAt: Self.captured,
            updatedAt: Self.captured,
            parentRecipeID: UUID()
        )
        let structured = Recipe(
            schemaVersion: 0,
            title: "Test Soup",
            ingredientGroups: [IngredientGroup(ingredients: [Ingredient(rawText: "2 cups water")])],
            steps: [Step(text: "Boil the water.")],
            notes: "Made up.",
            sourcePageIDs: [UUID()],
            reviewState: .reviewed,
            extraction: Extraction(engine: "other", promptVersion: 3, warnings: ["no title"]),
            createdAt: Self.now,
            updatedAt: Self.now
        )
        let later = Self.now.addingTimeInterval(30)

        let merged = ExtractionPlanner.merged(structured, into: existing, lastPageEnds: false, now: later)

        #expect(merged.id == existing.id)
        #expect(merged.sourcePageIDs == existing.sourcePageIDs)
        #expect(merged.continuesOnUnscannedPage == true)
        #expect(merged.tags == ["soups"])
        #expect(merged.parentRecipeID == existing.parentRecipeID)
        #expect(merged.createdAt == Self.captured)
        #expect(merged.title == "Test Soup")
        #expect(merged.ingredientGroups == structured.ingredientGroups)
        #expect(merged.steps == structured.steps)
        #expect(merged.notes == "Made up.")
        #expect(merged.reviewState == .needsReview)
        #expect(merged.updatedAt == later)
        #expect(merged.schemaVersion == Recipe.currentSchemaVersion)
        #expect(merged.extraction?.engine == Extraction.onDeviceEngine)
        #expect(merged.extraction?.extractedAt == later)
        #expect(merged.extraction?.promptVersion == 3)
        #expect(merged.extraction?.warnings == ["no title"])
    }

    @Test("merged clears the warning")
    func mergedClearsTheWarning() {
        let flagged = Recipe(continuesOnUnscannedPage: true)
        let unflagged = Recipe(continuesOnUnscannedPage: false)
        let structured = Recipe(title: "Test Soup")

        #expect(!ExtractionPlanner.merged(structured, into: flagged, lastPageEnds: true, now: Self.now).continuesOnUnscannedPage)
        #expect(ExtractionPlanner.merged(structured, into: flagged, lastPageEnds: false, now: Self.now).continuesOnUnscannedPage)
        #expect(!ExtractionPlanner.merged(structured, into: unflagged, lastPageEnds: true, now: Self.now).continuesOnUnscannedPage)
        #expect(!ExtractionPlanner.merged(structured, into: unflagged, lastPageEnds: false, now: Self.now).continuesOnUnscannedPage)
    }
}
