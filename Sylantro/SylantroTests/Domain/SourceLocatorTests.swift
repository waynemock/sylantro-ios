import Foundation
import Testing
@testable import Sylantro

/// `SourceLocator` (`15` M3-1): each ingredient and step gets the box of the page lines it was
/// read from. Every line is made up; the boxes use binary fractions so unions compare exactly.
@Suite("Source locator")
struct SourceLocatorTests {
    static let page1 = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    static let page2 = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!

    /// Lines one under another, each 0.0625 tall, starting at `y` 0.125.
    static func lines(_ texts: [String], page: UUID = page1, x: Double = 0.125, width: Double = 0.5) -> [SourceLocator.Line] {
        texts.enumerated().map { index, text in
            SourceLocator.Line(text: text, box: SourceBox(pageID: page, x: x, y: 0.125 + Double(index) * 0.0625,
                                                         width: width, height: 0.0625))
        }
    }

    static func recipe(ingredients: [String] = [], steps: [String] = []) -> Recipe {
        Recipe(
            ingredientGroups: [IngredientGroup(ingredients: ingredients.map { Ingredient(rawText: $0) })],
            steps: steps.enumerated().map { Step(index: $0.offset, text: $0.element) }
        )
    }

    static func ingredients(_ recipe: Recipe) -> [Ingredient] {
        recipe.ingredientGroups.flatMap(\.ingredients)
    }

    @Test("a one-line ingredient")
    func oneLineIngredient() {
        let lines = Self.lines(["Test Soup", "2 cups water", "1 tsp salt"])

        let located = SourceLocator.locate(Self.recipe(ingredients: ["2 cups water"]), lines: lines)

        #expect(Self.ingredients(located).first?.sourceBox == lines[1].box)
    }

    @Test("a wrapped ingredient")
    func wrappedIngredient() {
        var lines = Self.lines(["Test Soup", "1 teaspoon salt, plus more to", "taste"])
        // The wrap is shorter and further right, so the union differs from either line.
        lines[2].box.x = 0.25
        lines[2].box.width = 0.125

        let located = SourceLocator.locate(Self.recipe(ingredients: ["1 teaspoon salt, plus more to taste"]), lines: lines)

        #expect(Self.ingredients(located).first?.sourceBox
            == SourceBox(pageID: Self.page1, x: 0.125, y: 0.1875, width: 0.5, height: 0.125))
    }

    @Test("the same line twice")
    func sameLineTwice() {
        let lines = Self.lines(["For the dough", "1 tsp salt", "For the filling", "1 tsp salt"])

        let located = SourceLocator.locate(Self.recipe(ingredients: ["1 tsp salt", "1 tsp salt"]), lines: lines)

        let ingredients = Self.ingredients(located)
        #expect(ingredients.map(\.sourceBox) == [lines[1].box, lines[3].box])
    }

    @Test("a step over three lines")
    func stepOverThreeLines() {
        let lines = Self.lines(["2. Stir the made-up soup", "slowly over a low heat", "until it is warm.", "3. Serve."])
        let step = "Stir the made-up soup slowly over a low heat until it is warm."

        let located = SourceLocator.locate(Self.recipe(steps: [step]), lines: lines)

        // Pass 1 finds no run equal to the step: the step number makes every run longer.
        #expect(located.steps.first?.sourceBox
            == SourceBox(pageID: Self.page1, x: 0.125, y: 0.125, width: 0.5, height: 0.1875))
    }

    @Test("not found")
    func notFound() {
        let lines = Self.lines(["2 cups water", "1 tsp salt"])

        let located = SourceLocator.locate(Self.recipe(ingredients: ["3 made-up eggs", "1 tsp salt"]), lines: lines)

        let ingredients = Self.ingredients(located)
        #expect(ingredients[0].sourceBox == nil)
        #expect(ingredients[1].sourceBox == lines[1].box)
    }

    @Test("never across pages")
    func neverAcrossPages() {
        let lines = Self.lines(["Test Soup", "1 cup grated made-up"]) + Self.lines(["cheese", "Serves 2"], page: Self.page2)

        let located = SourceLocator.locate(Self.recipe(ingredients: ["1 cup grated made-up cheese"]), lines: lines)

        #expect(Self.ingredients(located).first?.sourceBox == nil)
    }

    // MARK: Across a page break, and the title (`15` M3-3a, RV-30, RV-31)

    /// A page's read lines, one under another as `lines(_:)` places them.
    static func readLines(_ texts: [String]) -> [PageReading.ReadLine] {
        texts.enumerated().map { index, text in
            PageReading.ReadLine(text: text, confidence: 1,
                                 box: .init(x: 0.125, y: 0.125 + Double(index) * 0.0625, width: 0.5, height: 0.0625))
        }
    }

    @Test("a step across pages")
    func stepAcrossPages() {
        // Page 1 ends with the step's first lines and a footer; page 2 starts with its last line.
        let pageOne = Self.readLines(["1. Bloom the made-up yeast in", "warm water and", "www.example.com/soup Page 1 of 2"])
        let pageTwo = Self.readLines(["let it stand 5 minutes.", "2. Mix."])
        let lines = RecipeStructurer.locatorLines([pageOne, pageTwo], pageIDs: [Self.page1, Self.page2])
        let step = "Bloom the made-up yeast in warm water and let it stand 5 minutes."

        let located = SourceLocator.locate(Self.recipe(steps: [step]), lines: lines)

        // Page 1's two lines only: no footer, nothing from page 2.
        #expect(located.steps.first?.sourceBox
            == SourceBox(pageID: Self.page1, x: 0.125, y: 0.125, width: 0.5, height: 0.125))
    }

    @Test("one page first")
    func onePageFirst() {
        // A run across the break would match first in line order; the one-page run wins.
        let lines = Self.lines(["Stir.", "Mix the flour"]) + Self.lines(["and the water.", "Mix the flour and the water."], page: Self.page2)

        let located = SourceLocator.locate(Self.recipe(steps: ["Mix the flour and the water."]), lines: lines)

        #expect(located.steps.first?.sourceBox == lines[3].box)
    }

    @Test("the title is placed")
    func titleIsPlaced() {
        let lines = Self.lines(["Test Soup", "1 cup water", "Simmer the Test Soup gently."])
        var recipe = Self.recipe(ingredients: ["1 cup water"])
        recipe.title = "Test Soup"
        #expect(SourceLocator.locate(recipe, lines: lines).titleBox == lines[0].box)

        // Found only inside a step's line: no box.
        recipe.title = "Simmer the Test Soup"
        #expect(SourceLocator.locate(recipe, lines: lines).titleBox == nil)
    }
}
