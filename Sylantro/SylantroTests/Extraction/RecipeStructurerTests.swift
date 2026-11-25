import Foundation
import Testing
@testable import Sylantro

/// The parts' mapping (`11` M1-4 onward): the model's answers for each part become a `Recipe`,
/// with the words from the page and quantities and units from the parser. Every value is made up.
@Suite("Recipe structurer mapping")
struct RecipeStructurerTests {
    static let pageIDs = [
        UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
        UUID(uuidString: "22222222-2222-4222-8222-222222222222")!,
    ]

    @Test("parts assemble with rule fields")
    func partsAssembleWithRuleFields() throws {
        let header = GeneratedHeader(title: "Test Soup", author: nil, publisher: nil, otherTitles: nil)
        let ingredientGroups = RecipeStructurer.ingredientGroups(
            from: GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [Self.item(1, 1)])]),
            lines: ["2 cups water"]
        ).groups
        let steps = GeneratedStepPart(steps: [GeneratedStep(text: "Boil the water.", groupName: nil)])
        let rules = RuleFields(sourceURL: "https://example.com", yieldText: "Serves 2")

        let recipe = RecipeStructurer.assemble(title: "Test Soup", header: header, ingredientGroups: ingredientGroups,
                                               steps: steps, split: SplitPage(), rules: rules, pageIDs: Self.pageIDs,
                                               unreadableAreas: [], warnings: [])

        #expect(recipe.title == "Test Soup")
        let ingredient = try #require(recipe.ingredientGroups.first?.ingredients.first)
        #expect(ingredient.quantity == Quantity(min: 2))
        #expect(ingredient.unit?.canonical == .cup)
        #expect(recipe.yield?.rawText == "Serves 2")
        #expect(recipe.attribution?.sourceURL == "https://example.com")
        #expect(recipe.extraction?.promptVersion == 3)
    }

    // MARK: Lines from the page (M1-5)

    static func item(_ first: Int, _ last: Int) -> GeneratedLineItem {
        GeneratedLineItem(firstLine: first, lastLine: last, item: nil, preparation: nil, note: nil, isOptional: nil)
    }

    @Test("ingredients come from the page's lines")
    func ingredientsComeFromPageLines() throws {
        let lines = ["For the soup", "2 cups water", "1 teaspoon salt, plus more to", "taste"]
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 1, items: [Self.item(2, 2), Self.item(3, 4)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: lines)

        let group = try #require(mapped.groups.first)
        #expect(group.name == "For the soup")
        try #require(group.ingredients.count == 2)
        #expect(group.ingredients[0].rawText == "2 cups water")
        #expect(group.ingredients[0].quantity == Quantity(min: 2))
        #expect(group.ingredients[0].unit?.canonical == .cup)
        #expect(group.ingredients[1].rawText == "1 teaspoon salt, plus more to taste")
        #expect(mapped.warnings.isEmpty)
    }

    @Test("a hyphen at a line end joins the word")
    func hyphenAtLineEndJoins() throws {
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [Self.item(1, 2)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: ["1 1/2 tea-", "spoons salt"])

        let ingredient = try #require(mapped.groups.first?.ingredients.first)
        #expect(ingredient.rawText == "1 1/2 teaspoons salt")
        #expect(ingredient.unit?.canonical == .teaspoon)
    }

    @Test("bad line numbers are skipped")
    func badLineNumbersAreSkipped() {
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [Self.item(5, 5), Self.item(2, 1)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: ["1 cup water", "2 cups flour"])

        #expect(mapped.groups.flatMap(\.ingredients).isEmpty)
        #expect(mapped.warnings.filter { $0 == "ingredient lines out of range" }.count == 2)
        #expect(mapped.warnings.contains("unused ingredient line 1"))
        #expect(mapped.warnings.contains("unused ingredient line 2"))
    }

    @Test("a long group name is not used")
    func longGroupNameIsNotUsed() throws {
        let name = "For the made-up sauce that goes on the noodle"
        #expect(name.count == 45)
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 1, items: [Self.item(2, 2)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: [name, "1 cup water"])

        let group = try #require(mapped.groups.first)
        #expect(group.name == nil)
        #expect(mapped.warnings.contains("group name too long"))
    }

    @Test("the title snaps across three lines")
    func titleSnapsAcrossThreeLines() {
        let area = ["watercress", "salad with beets", "and Feta", "Serves 4"].map { HeaderArea.HeaderLine(text: $0, size: 1.0) }

        let snapped = HeaderArea.snappedTitle("watercress salad with beets and Feta", area: area)

        #expect(snapped.title == "watercress salad with beets and Feta")
        #expect(snapped.snapped)
    }

    @Test("unreadable areas and warnings reach the recipe")
    func unreadableAreasAndWarningsReachRecipe() {
        let box = SourceBox(pageID: Self.pageIDs[0], x: 0.125, y: 0.5, width: 0.5, height: 0.0625)

        let recipe = RecipeStructurer.assemble(title: "", header: nil, ingredientGroups: [], steps: nil, split: SplitPage(),
                                               rules: RuleFields(), pageIDs: Self.pageIDs, unreadableAreas: [box],
                                               warnings: ["unreadable line on page 1"])

        #expect(recipe.unreadableAreas == [box])
        #expect(recipe.extraction?.warnings == ["unreadable line on page 1"])
        #expect(recipe.extraction?.promptVersion == 3)
    }

    // MARK: Run 3's fixes (M1-6)

    @Test("other titles must be lines on the page")
    func otherTitlesMustBeLinesOnThePage() {
        let titles = ["none", "Test Soup", "Side Salad", "Made-up Title", "Side Salad"]
        let lines = ["Test Soup", "1 cup water", "SIDE SALAD", "2 cups lettuce"]

        #expect(RecipeStructurer.otherRecipeTitles(titles, title: "Test Soup", lines: lines) == ["Side Salad"])
        #expect(RecipeStructurer.otherRecipeTitles(nil, title: "Test Soup", lines: lines) == [])
    }

    @Test("'none' fields are nil")
    func noneFieldsAreNil() throws {
        let item = GeneratedLineItem(firstLine: 1, lastLine: 1, item: "none", preparation: "None", note: "n/a", isOptional: nil)
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [item])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: ["1 cup water"])

        let ingredient = try #require(mapped.groups.first?.ingredients.first)
        #expect(ingredient.item == nil)
        #expect(ingredient.preparation == nil)
        #expect(ingredient.note == nil)
    }

    // MARK: Parts only (M1-9)

    @Test("other titles become a warning")
    func otherTitlesBecomeAWarning() {
        #expect(RecipeStructurer.otherRecipesWarning(["Side Salad", "Pie"]) == "may hold other recipes: Side Salad; Pie")
        #expect(RecipeStructurer.otherRecipesWarning([]) == nil)
    }

    // MARK: Title as text, wraps, clean labels (M1-11)

    @Test("labelled lines are cleaned")
    func labelledLinesAreCleaned() {
        let lines = ["Test Soup", "Ingredients", "• 1 cup water", "ps://example.com/r/1"]
        let labels = GeneratedLineLabels(labels: [
            GeneratedLineLabel(line: 1, kind: "header"),
            GeneratedLineLabel(line: 2, kind: "ingredient"),
            GeneratedLineLabel(line: 3, kind: "ingredient"),
            GeneratedLineLabel(line: 4, kind: "ingredient"),
        ])

        let split = RecipeStructurer.labelled(lines, labels: labels, keeping: SplitPage())

        #expect(split.header == ["Test Soup"])
        #expect(split.ingredients == ["1 cup water"])
    }

    // MARK: Group names and lines used once (M1-14)

    static let soupLines = ["For the soup", "1 cup water", "2 cups stock", "For the top", "1 cup cheese"]

    @Test("group names are subheadings only")
    func groupNamesAreSubheadingsOnly() throws {
        let part = GeneratedIngredientLines(groups: [
            GeneratedLineGroup(nameLine: 1, items: [Self.item(2, 2)]),
            GeneratedLineGroup(nameLine: 3, items: [Self.item(3, 3)]),
            GeneratedLineGroup(nameLine: 4, items: [Self.item(5, 5)]),
        ])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: Self.soupLines)

        try #require(mapped.groups.count == 2)
        #expect(mapped.groups[0].name == "For the soup")
        #expect(mapped.groups[0].ingredients.map(\.rawText) == ["1 cup water", "2 cups stock"])
        #expect(mapped.groups[1].name == "For the top")
        #expect(mapped.groups[1].ingredients.map(\.rawText) == ["1 cup cheese"])
    }

    @Test("a line is used once")
    func lineIsUsedOnce() {
        let part = GeneratedIngredientLines(groups: [
            GeneratedLineGroup(nameLine: 0, items: [Self.item(2, 2), Self.item(2, 2), Self.item(3, 3)]),
        ])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: Self.soupLines)

        #expect(mapped.groups.flatMap(\.ingredients).map(\.rawText) == ["1 cup water", "2 cups stock"])
        #expect(mapped.warnings.contains("ingredient line repeated"))
    }

    // MARK: Lines the model skipped (M3-3a, RV-29)

    @Test("a skipped line is put back")
    func skippedLineIsPutBack() throws {
        let lines = ["1 1/2 Tbsp. made-up yeast", "2 cups flour", "1 cup milk"]
        // The name line points at an ingredient line; the items start after it.
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 1, items: [Self.item(2, 2), Self.item(3, 3)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: lines)

        let ingredients = try #require(mapped.groups.first?.ingredients)
        #expect(ingredients.map(\.rawText) == lines)
        #expect(ingredients[0].quantity == Quantity(min: 1.5))
        #expect(ingredients[0].unit?.canonical == .tablespoon)
        #expect(ingredients[0].item == "made-up yeast")
        #expect(mapped.warnings.contains("put back: ingredient 1"))
        #expect(!mapped.warnings.contains("unused ingredient line 1"))
    }

    @Test("a line outside a group stays out")
    func lineOutsideGroupStaysOut() {
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [Self.item(1, 1), Self.item(2, 2)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: ["2 cups flour", "1 cup milk", "1 tsp salt"])

        #expect(mapped.groups.flatMap(\.ingredients).map(\.rawText) == ["2 cups flour", "1 cup milk"])
        #expect(mapped.warnings.contains("unused ingredient line 3"))
        #expect(!mapped.warnings.contains { $0.hasPrefix("put back") })
    }

    @Test("a heading becomes the name")
    func headingBecomesTheName() throws {
        let lines = ["Kolaches:", "1 Tbsp. made-up yeast", "2 cups flour"]
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 2, items: [Self.item(3, 3)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: lines)

        let group = try #require(mapped.groups.first)
        #expect(group.name == "Kolaches")
        #expect(group.ingredients.map(\.rawText) == ["1 Tbsp. made-up yeast", "2 cups flour"])
        #expect(!mapped.warnings.contains { $0.hasPrefix("unused") })
    }

    // MARK: Lines before a group's first one (M3-3e, RV-29)

    @Test("lines before the first are put back")
    func linesBeforeTheFirstArePutBack() throws {
        let lines = ["Dough:", "1 Tbsp. yeast", "1/2 cup water", "1/4 cup butter", "1 cup milk"]
        // The model gives only the last two lines, and no name line.
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [Self.item(4, 4), Self.item(5, 5)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: lines)

        let group = try #require(mapped.groups.first)
        #expect(mapped.groups.count == 1)
        #expect(group.name == "Dough")
        #expect(group.ingredients.map(\.rawText) == ["1 Tbsp. yeast", "1/2 cup water", "1/4 cup butter", "1 cup milk"])
        #expect(mapped.warnings.contains("put back: ingredient 1"))
        #expect(mapped.warnings.contains("put back: ingredient 2"))
        #expect(!mapped.warnings.contains { $0.hasPrefix("unused") })
    }

    @Test("a used line stops the walk")
    func usedLineStopsTheWalk() {
        let lines = ["1 cup flour", "2 cups sugar", "1 made-up egg", "1 cup milk"]
        // The line before the second group's span is the first group's.
        let part = GeneratedIngredientLines(groups: [
            GeneratedLineGroup(nameLine: 0, items: [Self.item(1, 1), Self.item(2, 2)]),
            GeneratedLineGroup(nameLine: 0, items: [Self.item(3, 3), Self.item(4, 4)]),
        ])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: lines)

        #expect(mapped.groups.flatMap(\.ingredients).map(\.rawText) == lines)
        #expect(!mapped.warnings.contains { $0.hasPrefix("put back") })
    }

    // MARK: Groups by the printed headings (M3-3h, RV-38)

    static let headedLines = ["Dough:", "2 cups flour", "1 tsp salt", "Filling:", "1 cup jam", "1 tbsp sugar"]

    @Test("headings regroup")
    func headingsRegroup() {
        // The model gives one unnamed group of the four ingredients.
        let part = GeneratedIngredientLines(groups: [
            GeneratedLineGroup(nameLine: 0, items: [Self.item(2, 2), Self.item(3, 3), Self.item(5, 5), Self.item(6, 6)]),
        ])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: Self.headedLines)

        #expect(mapped.groups.map(\.name) == ["Dough", "Filling"])
        #expect(mapped.groups.map { $0.ingredients.map(\.rawText) } == [["2 cups flour", "1 tsp salt"], ["1 cup jam", "1 tbsp sugar"]])
        #expect(mapped.warnings.isEmpty)
    }

    @Test("a skipped group comes back")
    func skippedGroupComesBack() throws {
        // The model gives only the dough's two.
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [Self.item(2, 2), Self.item(3, 3)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: Self.headedLines)

        try #require(mapped.groups.count == 2)
        #expect(mapped.groups[1].name == "Filling")
        #expect(mapped.groups[1].ingredients.map(\.rawText) == ["1 cup jam", "1 tbsp sugar"])
        #expect(mapped.warnings.contains("put back: ingredient 3"))
        #expect(mapped.warnings.contains("put back: ingredient 4"))
        #expect(!mapped.warnings.contains { $0.hasPrefix("unused") })
    }

    @Test("no headings, no change")
    func noHeadingsNoChange() throws {
        // `soupLines` prints no heading ending with `:`; the model's two named groups stand.
        let part = GeneratedIngredientLines(groups: [
            GeneratedLineGroup(nameLine: 1, items: [Self.item(2, 2), Self.item(3, 3)]),
            GeneratedLineGroup(nameLine: 4, items: [Self.item(5, 5)]),
        ])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: Self.soupLines)

        #expect(mapped.groups.map(\.name) == ["For the soup", "For the top"])
        #expect(mapped.groups.map { $0.ingredients.map(\.rawText) } == [["1 cup water", "2 cups stock"], ["1 cup cheese"]])
    }

    // MARK: The spike's leftovers (M3-1)

    @Test("the fallback's noise")
    func fallbackNoiseIsDropped() {
        let warnings = ["unused ingredient line 2", "ingredient line repeated"]

        #expect(RecipeStructurer.fallbackWarnings(warnings) == ["ingredient line repeated"])
    }
}
