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
        let checked = RecipeValidator.check(recipe, pageText: "Test Soup\nUse a pot.")
        #expect(checked.title == "Test Soup")
        #expect(checked.equipment == ["Pot"])
        #expect(checked.extraction?.warnings.contains("not on page: equipment") == true)
    }

    @Test("fractions and line-end hyphens still match")
    func fractionsAndHyphensMatch() {
        let recipe = Recipe(ingredientGroups: [IngredientGroup(ingredients: [Ingredient(rawText: "1½ teaspoons salt")])])
        let checked = RecipeValidator.check(recipe, pageText: "1 1/2 tea-\nspoons salt")
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
        let checked = RecipeValidator.check(recipe, pageText: sentence)
        #expect(checked.ingredientGroups[0].ingredients.isEmpty)
        #expect(checked.extraction?.warnings.contains("ingredient 1 is a step") == true)
    }
}
