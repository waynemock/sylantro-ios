import Foundation
import Testing
@testable import Sylantro

/// `ReviewFlag` (RV-10, `15` M3-1): each warning becomes a flag that names its field. Every
/// value is made up.
@Suite("Review flags")
struct ReviewFlagTests {
    static func recipe(warnings: [String], ingredients: [String] = [], steps: [String] = [],
                       continues: Bool = false) -> Recipe {
        Recipe(
            ingredientGroups: [IngredientGroup(ingredients: ingredients.map { Ingredient(rawText: $0) })],
            steps: steps.enumerated().map { Step(index: $0.offset, text: $0.element) },
            continuesOnUnscannedPage: continues,
            extraction: Extraction(warnings: warnings)
        )
    }

    @Test("the title")
    func titleFlags() {
        let flags = ReviewFlag.flags(for: Self.recipe(warnings: ["no title", "title from layout"]))

        #expect(flags == [
            ReviewFlag(kind: .noTitle, field: .title),
            ReviewFlag(kind: .titleFromLayout, field: .title),
        ])
    }

    @Test("an ingredient by number")
    func ingredientByNumber() {
        // Ingredient 2 was removed as a step, so number 3 is the second kept ingredient.
        let recipe = Self.recipe(warnings: ["ingredient 2 is a step", "not on page: ingredient 3"],
                                 ingredients: ["1 cup water", "2 made-up eggs", "1 tsp salt"])
        let kept = recipe.ingredientGroups[0].ingredients

        let flags = ReviewFlag.flags(for: recipe)

        #expect(flags == [
            ReviewFlag(kind: .ingredientWasStep, field: .ingredients),
            ReviewFlag(kind: .notOnPage, field: .ingredient(kept[1].id)),
        ])
    }

    @Test("a step by number")
    func stepByNumber() {
        let recipe = Self.recipe(warnings: ["not on page: step 2"], steps: ["Boil the water.", "Add the salt."])

        let flags = ReviewFlag.flags(for: recipe)

        #expect(flags == [ReviewFlag(kind: .notOnPage, field: .step(recipe.steps[1].id))])
    }

    @Test("other recipes")
    func otherRecipes() {
        let flags = ReviewFlag.flags(for: Self.recipe(warnings: ["may hold other recipes: Lemon Bars; Fudge"]))

        #expect(flags == [ReviewFlag(kind: .mayHoldOtherRecipes(["Lemon Bars", "Fudge"]), field: .recipe)])
    }

    @Test("continues")
    func continuesComesFirst() {
        let flags = ReviewFlag.flags(for: Self.recipe(warnings: ["no title"], continues: true))

        #expect(flags == [
            ReviewFlag(kind: .continuesOnUnscannedPage, field: .recipe),
            ReviewFlag(kind: .noTitle, field: .title),
        ])
    }

    @Test("unknown")
    func unknownWarning() {
        let flags = ReviewFlag.flags(for: Self.recipe(warnings: ["a made-up warning"]))

        #expect(flags == [ReviewFlag(kind: .other("a made-up warning"), field: .recipe)])
    }

    @Test("once each")
    func eachFlagOnce() {
        let flags = ReviewFlag.flags(for: Self.recipe(warnings: ["unused ingredient line 3", "unused ingredient line 4"]))

        #expect(flags == [ReviewFlag(kind: .ingredientLinesUnsure, field: .ingredients)])
    }

    @Test("dropped values")
    func droppedValues() {
        let flags = ReviewFlag.flags(for: Self.recipe(warnings: ["not on page: notes", "not on page: author"]))

        #expect(flags == [
            ReviewFlag(kind: .droppedNotOnPage, field: .notes),
            ReviewFlag(kind: .droppedNotOnPage, field: .attribution),
        ])
    }

    // MARK: Review (`15` M3-3)

    @Test("the lines")
    func flagLines() {
        #expect(ReviewFlag.line(for: .noTitle) == "No title found. Add one.")
        #expect(ReviewFlag.line(for: .unreadableLine(page: 2)) == "A line on page 2 couldn't be read.")
        #expect(ReviewFlag.line(for: .mayHoldOtherRecipes(["A", "B"])) == "This page may hold other recipes: A, B.")
        #expect(ReviewFlag.line(for: .other("a made-up warning")) == "Check this.")
    }

    @Test("put back")
    func putBack() {
        let recipe = Self.recipe(warnings: ["put back: ingredient 2"], ingredients: ["2 cups flour", "1 Tbsp. made-up yeast"])

        let flags = ReviewFlag.flags(for: recipe)

        #expect(flags == [ReviewFlag(kind: .putBack, field: .ingredient(recipe.ingredientGroups[0].ingredients[1].id))])
        #expect(ReviewFlag.line(for: .putBack) == "Put back from the page. Check it.")
    }

    @Test("needs review")
    func needsReview() {
        #expect(!Recipe(reviewState: .needsReview).needsReview)
        #expect(Recipe(reviewState: .needsReview, extraction: Extraction()).needsReview)
        #expect(!Recipe(reviewState: .reviewed, extraction: Extraction()).needsReview)
        #expect(!Recipe(reviewState: .edited, extraction: Extraction()).needsReview)
    }
}
