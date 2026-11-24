import Foundation
import Testing
@testable import Sylantro

/// `RecipeValidator` (`11` M1-4, SLT-142): every value the model returned is looked for on the
/// page. Every line is made up.
@Suite("Recipe validator")
struct RecipeValidatorTests {
    @Test("a value not on the page is dropped")
    func valueNotOnPageIsDropped() {
        let recipe = Recipe(title: "Test Soup", equipment: ["Pot", "Wok"])
        let checked = RecipeValidator.check(recipe, pageText: "Test Soup\nUse a pot.", clutterFreeText: "Test Soup\nUse a pot.")
        #expect(checked.title == "Test Soup")
        #expect(checked.equipment == ["Pot"])
        #expect(checked.extraction?.warnings.contains("not on page: equipment") == true)
    }

    @Test("fractions and line-end hyphens still match")
    func fractionsAndHyphensMatch() {
        let recipe = Recipe(ingredientGroups: [IngredientGroup(ingredients: [Ingredient(rawText: "1½ teaspoons salt")])])
        let checked = RecipeValidator.check(recipe, pageText: "1 1/2 tea-\nspoons salt", clutterFreeText: "1 1/2 tea-\nspoons salt")
        #expect(checked.extraction?.warnings ?? [] == [])
        #expect(checked.ingredientGroups[0].ingredients.count == 1)
    }

    @Test("a step copied into the ingredients is removed")
    func copiedStepIsRemoved() {
        let sentence = "Stir the made-up soup slowly over a low heat until it is thick enough."
        #expect(sentence.count == 70)
        let recipe = Recipe(
            ingredientGroups: [IngredientGroup(ingredients: [Ingredient(rawText: sentence)])],
            steps: [Step(index: 0, text: sentence)]
        )
        let checked = RecipeValidator.check(recipe, pageText: sentence, clutterFreeText: sentence)
        #expect(checked.ingredientGroups[0].ingredients.isEmpty)
        #expect(checked.extraction?.warnings.contains("ingredient 1 is a step") == true)
    }

    @Test("the title isn't checked")
    func titleIsNotChecked() {
        let recipe = Recipe(title: "Made-up Title")
        let checked = RecipeValidator.check(recipe, pageText: "Test Soup\nUse a pot.", clutterFreeText: "Test Soup\nUse a pot.")
        #expect(checked.title == "Made-up Title")
        let warnings = checked.extraction?.warnings ?? []
        #expect(!warnings.contains("not on page: title"))
    }

    @Test("a value across a page break is found")
    func valueAcrossPageBreakIsFound() {
        // The step ends one page and goes on the next, with the first page's footer between.
        let recipe = Recipe(steps: [Step(text: "Bloom the made-up yeast in warm water.")])
        let pageText = "Bloom the made-up yeast in\nwww.example.com/soup Page 1 of 2\nwarm water."

        let withoutClutter = RecipeValidator.check(recipe, pageText: pageText,
                                                   clutterFreeText: "Bloom the made-up yeast in\nwarm water.")
        let withClutter = RecipeValidator.check(recipe, pageText: pageText, clutterFreeText: pageText)

        let foundWarnings = withoutClutter.extraction?.warnings ?? []
        let missedWarnings = withClutter.extraction?.warnings ?? []
        #expect(!foundWarnings.contains("not on page: step 1"))
        #expect(missedWarnings.contains("not on page: step 1"))
    }
}
