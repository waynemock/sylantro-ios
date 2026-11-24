import Foundation
import Testing
@testable import Sylantro

/// `ReviewEdit` (`15` M3-3, RV-12): what she types in review's Edit, applied to a recipe. Every
/// value is made up.
@Suite("Review edit")
struct ReviewEditTests {
    static let now = Date(timeIntervalSince1970: 1_795_000_000)
    static let pageID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!

    static func box(_ y: Double) -> SourceBox {
        SourceBox(pageID: pageID, x: 0.125, y: y, width: 0.5, height: 0.0625)
    }

    /// A read recipe: two ingredients in one group, two steps, each with a place on the page.
    static func recipe() -> Recipe {
        Recipe(
            title: "Test Soup",
            ingredientGroups: [IngredientGroup(name: "For the soup", ingredients: [
                Ingredient(rawText: "2 cups flour", preparation: "sifted", sourceBox: box(0.25), confidence: 0.5),
                Ingredient(rawText: "1 tsp salt", sourceBox: box(0.3125)),
            ])],
            steps: [
                Step(index: 0, text: "Mix the flour.", sourceBox: box(0.5)),
                Step(index: 1, text: "Add the salt.", sourceBox: box(0.5625)),
            ],
            sourcePageIDs: [pageID],
            reviewState: .needsReview,
            extraction: Extraction(promptVersion: 3)
        )
    }

    @Test("nothing changed")
    func nothingChanged() {
        let recipe = Self.recipe()

        let applied = ReviewEdit.from(recipe).applied(to: recipe, now: Self.now)

        #expect(applied.ingredientGroups == recipe.ingredientGroups)
        #expect(applied.steps.map(\.id) == recipe.steps.map(\.id))
        #expect(applied.steps.map(\.sourceBox) == recipe.steps.map(\.sourceBox))
        #expect(applied.steps.map(\.text) == recipe.steps.map(\.text))
        #expect(applied.title == "Test Soup")
        #expect(applied.reviewState == .edited)
        #expect(applied.updatedAt == Self.now)
    }

    @Test("a changed line is parsed")
    func changedLineIsParsed() throws {
        let recipe = Self.recipe()
        let original = recipe.ingredientGroups[0].ingredients[0]
        var edit = ReviewEdit.from(recipe)
        edit.groups[0].lines[0].text = "3 tbsp sugar"

        let applied = edit.applied(to: recipe, now: Self.now)

        let changed = try #require(applied.ingredientGroups.first?.ingredients.first)
        #expect(changed.id == original.id)
        #expect(changed.sourceBox == original.sourceBox)
        #expect(changed.rawText == "3 tbsp sugar")
        #expect(changed.quantity == Quantity(min: 3))
        #expect(changed.unit?.canonical == .tablespoon)
        #expect(changed.item == "sugar")
        #expect(changed.preparation == nil)
        #expect(changed.confidence == nil)
    }

    @Test("a new line")
    func newLine() throws {
        let recipe = Self.recipe()
        var edit = ReviewEdit.from(recipe)
        let newID = UUID()
        edit.groups[0].lines.append(ReviewEdit.Line(id: newID, text: "1 egg"))

        let applied = edit.applied(to: recipe, now: Self.now)

        let ingredients = try #require(applied.ingredientGroups.first?.ingredients)
        #expect(ingredients.count == 3)
        #expect(ingredients[2].id == newID)
        #expect(ingredients[2].rawText == "1 egg")
        #expect(ingredients[2].sourceBox == nil)
    }

    @Test("empty lines and groups go")
    func emptyLinesAndGroupsGo() throws {
        var recipe = Self.recipe()
        let salt = recipe.ingredientGroups[0].ingredients[1]
        let flour = recipe.ingredientGroups[0].ingredients[0]
        recipe.ingredientGroups.append(IngredientGroup(name: "For the top", ingredients: [Ingredient(rawText: "1 cup cheese")]))
        recipe.steps[1].ingredientIDs = [salt.id, flour.id]
        var edit = ReviewEdit.from(recipe)
        edit.groups[0].lines[1].text = "  "
        edit.groups[1].lines[0].text = ""

        let applied = edit.applied(to: recipe, now: Self.now)

        #expect(applied.ingredientGroups.count == 1)
        #expect(applied.ingredientGroups[0].ingredients.map(\.id) == [flour.id])
        #expect(applied.steps[1].ingredientIDs == [flour.id])
    }

    @Test("steps renumber")
    func stepsRenumber() {
        var recipe = Self.recipe()
        recipe.steps.append(Step(index: 2, text: "Serve."))
        let ids = recipe.steps.map(\.id)
        var edit = ReviewEdit.from(recipe)
        // The third step moved first, the second deleted.
        edit.steps = [edit.steps[2], edit.steps[0]]

        let applied = edit.applied(to: recipe, now: Self.now)

        #expect(applied.steps.map(\.index) == [1, 2])
        #expect(applied.steps.map(\.id) == [ids[2], ids[0]])
        #expect(applied.steps[1].sourceBox == recipe.steps[0].sourceBox)
    }

    @Test("serves")
    func serves() {
        let recipe = Self.recipe()
        var edit = ReviewEdit.from(recipe)
        edit.yieldText = "Serves 6 to 8"

        let served = edit.applied(to: recipe, now: Self.now)

        #expect(served.yield?.servings == Quantity(min: 6))
        #expect(served.yield?.rawText == "Serves 6 to 8")

        edit.yieldText = ""
        #expect(edit.applied(to: served, now: Self.now).yield == nil)
    }
}
