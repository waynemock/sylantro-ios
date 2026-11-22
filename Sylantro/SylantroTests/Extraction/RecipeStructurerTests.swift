import Foundation
import Testing
@testable import Sylantro

/// `RecipeStructurer.makeRecipe` (`11` M1-3): the model's reading becomes a `Recipe`, with
/// quantities and units from the parser. Every value is made up.
@Suite("Recipe structurer mapping")
struct RecipeStructurerTests {
    static let pageIDs = [
        UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
        UUID(uuidString: "22222222-2222-4222-8222-222222222222")!,
    ]

    static func generated(
        title: String = "Test Soup",
        yieldText: String? = nil,
        lines: [String] = [],
        steps: [String] = [],
        notes: String? = nil,
        author: String? = nil,
        publisher: String? = nil
    ) -> GeneratedRecipe {
        GeneratedRecipe(
            title: title,
            yieldText: yieldText,
            timesText: nil,
            ingredientGroups: [
                GeneratedGroup(name: nil, lines: lines.map {
                    GeneratedIngredient(rawText: $0, item: nil, preparation: nil, note: nil, isOptional: false)
                }),
            ],
            steps: steps.map { GeneratedStep(text: $0, groupName: nil) },
            notes: notes,
            author: author,
            publisher: publisher,
            sourceURL: nil,
            equipment: [],
            printedNutrition: nil
        )
    }

    @Test("a generated recipe maps to a recipe")
    func generatedRecipeMaps() throws {
        let generated = Self.generated(
            lines: ["2 cups water", "1 T salt"],
            steps: ["Boil the water.", "Add the salt."],
            publisher: "Example Kitchen"
        )
        let recipe = RecipeStructurer.makeRecipe(from: generated, pageIDs: Self.pageIDs)

        #expect(recipe.title == "Test Soup")
        let ingredients = try #require(recipe.ingredientGroups.first?.ingredients)
        try #require(ingredients.count == 2)
        #expect(ingredients[0].quantity == Quantity(min: 2))
        #expect(ingredients[0].unit?.canonical == .cup)
        #expect(ingredients[0].rawText == "2 cups water")
        #expect(ingredients[1].quantity == Quantity(min: 1))
        #expect(ingredients[1].unit?.canonical == .tablespoon)
        #expect(ingredients[1].unit?.raw == "T")
        #expect(recipe.steps.map(\.index) == [0, 1])
        #expect(recipe.attribution?.publisher == "Example Kitchen")
        #expect(recipe.reviewState == .needsReview)
        #expect(recipe.sourcePageIDs == Self.pageIDs)
    }

    @Test("empty strings become nil")
    func emptyStringsBecomeNil() {
        let generated = Self.generated(yieldText: "", notes: "", author: "")
        let recipe = RecipeStructurer.makeRecipe(from: generated, pageIDs: Self.pageIDs)

        #expect(recipe.yield == nil)
        #expect(recipe.notes == nil)
        #expect(recipe.attribution == nil)
    }

    @Test("a line the parser can't read keeps its words")
    func unreadableLineKeepsItsWords() throws {
        let generated = Self.generated(lines: ["Salt to taste"])
        let recipe = RecipeStructurer.makeRecipe(from: generated, pageIDs: Self.pageIDs)

        let ingredient = try #require(recipe.ingredientGroups.first?.ingredients.first)
        #expect(ingredient.quantity == nil)
        #expect(ingredient.unit == nil)
        #expect(ingredient.rawText == "Salt to taste")
    }

    @Test("parts assemble with rule fields")
    func partsAssembleWithRuleFields() throws {
        let header = GeneratedHeader(title: "Test Soup", author: nil, publisher: nil, otherTitles: [])
        let ingredients = GeneratedIngredientPart(groups: [
            GeneratedGroup(name: nil, lines: [
                GeneratedIngredient(rawText: "2 cups water", item: nil, preparation: nil, note: nil, isOptional: false),
            ]),
        ])
        let steps = GeneratedStepPart(steps: [GeneratedStep(text: "Boil the water.", groupName: nil)])
        let rules = RuleFields(sourceURL: "https://example.com", yieldText: "Serves 2")

        let recipe = RecipeStructurer.assemble(header: header, ingredients: ingredients, steps: steps,
                                               split: SplitPage(), rules: rules, pageIDs: Self.pageIDs)

        #expect(recipe.title == "Test Soup")
        let ingredient = try #require(recipe.ingredientGroups.first?.ingredients.first)
        #expect(ingredient.quantity == Quantity(min: 2))
        #expect(ingredient.unit?.canonical == .cup)
        #expect(recipe.yield?.rawText == "Serves 2")
        #expect(recipe.attribution?.sourceURL == "https://example.com")
        #expect(recipe.extraction?.promptVersion == 2)
    }
}
