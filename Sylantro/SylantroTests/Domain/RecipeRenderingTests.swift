import Foundation
import Testing
@testable import Sylantro

/// A recipe's plain copy (`14` Task M2-5, MT-18): `recipe.md` for a recipe not yet read, and its
/// folder's name. `en_US` and UTC; every recipe is made up.
@Suite("Recipe rendering")
struct RecipeRenderingTests {
    static let locale = Locale(identifier: "en_US")
    static let utc = TimeZone(identifier: "UTC")!
    static let id = UUID(uuidString: "8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F")!

    /// A two-page draft created 22 Nov 2026 (UTC).
    static func draft(continuesOnUnscannedPage: Bool) -> Recipe {
        var components = DateComponents(year: 2026, month: 11, day: 22, hour: 15)
        components.timeZone = utc
        let created = Calendar(identifier: .gregorian).date(from: components)!
        return Recipe(id: id, sourcePageIDs: [UUID(), UUID()], continuesOnUnscannedPage: continuesOnUnscannedPage,
                      createdAt: created, updatedAt: created)
    }

    static let pageFileNames = ["page-1.heic", "page-2.heic"]

    @Test("a new recipe's markdown")
    func newRecipeMarkdown() {
        let markdown = RecipeRendering.markdown(Self.draft(continuesOnUnscannedPage: false),
                                                pageFileNames: Self.pageFileNames,
                                                locale: Self.locale, timeZone: Self.utc)
        #expect(markdown == """
        # New recipe

        Scanned Nov 22, 2026 · 2 pages

        Waiting to be read

        ![](pages/page-1.heic)

        ![](pages/page-2.heic)

        """)
    }

    @Test("the page-2 warning is in the markdown")
    func pageTwoWarningMarkdown() {
        let markdown = RecipeRendering.markdown(Self.draft(continuesOnUnscannedPage: true),
                                                pageFileNames: Self.pageFileNames,
                                                locale: Self.locale, timeZone: Self.utc)
        #expect(markdown == """
        # New recipe

        Scanned Nov 22, 2026 · 2 pages

        Waiting to be read

        Continues on a page not scanned

        ![](pages/page-1.heic)

        ![](pages/page-2.heic)

        """)
    }

    // MARK: A read recipe (`15` M3-3, `13` §4.5)

    @Test("a read recipe's sections")
    func readRecipeSections() {
        var recipe = Self.draft(continuesOnUnscannedPage: false)
        recipe.title = "Test Soup"
        recipe.yield = Yield(rawText: "Serves 4")
        recipe.times = Times(prepMinutes: 15, cookMinutes: 75)
        recipe.ingredientGroups = [IngredientGroup(name: "For the soup", ingredients: [
            Ingredient(rawText: "2 cups water"), Ingredient(rawText: "1 tsp salt"),
        ])]
        recipe.steps = [Step(index: 0, text: "Boil the water."), Step(index: 1, text: "Add the salt.")]
        recipe.notes = "Made up."
        recipe.equipment = ["Pot"]
        recipe.printedNutrition = "Calories 100"
        recipe.attribution = Attribution(author: "Pat Example", publisher: "Example Kitchen",
                                         sourceURL: "https://example.com/soup")
        recipe.extraction = Extraction(promptVersion: 3, warnings: ["no title"])

        let markdown = RecipeRendering.markdown(recipe, pageFileNames: Self.pageFileNames,
                                                locale: Self.locale, timeZone: Self.utc)

        #expect(markdown == """
        # Test Soup

        Scanned Nov 22, 2026 · 2 pages

        Serves 4

        Prep 15 min · Cook 1 hr 15 min

        ## Ingredients

        ### For the soup

        - 2 cups water
        - 1 tsp salt

        ## Steps

        1. Boil the water.
        2. Add the salt.

        ## Notes

        Made up.

        ## Equipment

        - Pot

        ## Nutrition

        Calories 100

        ## Source

        Pat Example
        Example Kitchen
        https://example.com/soup

        ![](pages/page-1.heic)

        ![](pages/page-2.heic)

        """)
    }

    @Test("an unread recipe is unchanged")
    func unreadRecipeIsUnchanged() {
        // Fields filled but no extraction: M2's markdown, nothing more.
        var recipe = Self.draft(continuesOnUnscannedPage: false)
        recipe.steps = [Step(text: "Boil the water.")]

        let markdown = RecipeRendering.markdown(recipe, pageFileNames: Self.pageFileNames,
                                                locale: Self.locale, timeZone: Self.utc)

        #expect(markdown == """
        # New recipe

        Scanned Nov 22, 2026 · 2 pages

        Waiting to be read

        ![](pages/page-1.heic)

        ![](pages/page-2.heic)

        """)
    }

    @Test("folder names")
    func folderNames() {
        #expect(RecipeRendering.folderName(title: "", id: Self.id) == "new-recipe-8d5e1b3c")
        #expect(RecipeRendering.folderName(title: "Grandma's Apple Pie!", id: Self.id) == "grandmas-apple-pie-8d5e1b3c")
        #expect(RecipeRendering.folderName(title: "Crème Brûlée", id: Self.id) == "creme-brulee-8d5e1b3c")
    }
}
