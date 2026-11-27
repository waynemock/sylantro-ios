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
        let steps = [Step(index: 0, text: "Boil the water.")]
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
        #expect(recipe.extraction?.promptVersion == 4)
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
        #expect(recipe.extraction?.promptVersion == 4)
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
        // M3-3q: both come after the printed heading "Dough:" with a quantity, so neither is flagged.
        #expect(!mapped.warnings.contains { $0.hasPrefix("put back") })
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
        // M3-3q: both have quantities under a printed heading, so neither is flagged.
        #expect(!mapped.warnings.contains { $0.hasPrefix("put back") })
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

    // MARK: Steps by lines (M3-3j)

    static func steps(_ ranges: (Int, Int)...) -> GeneratedStepLines {
        GeneratedStepLines(steps: ranges.map { GeneratedStepRange(firstLine: $0.0, lastLine: $0.1) })
    }

    @Test("steps by lines")
    func stepsByLines() {
        let lines = ["Whisk the made-up batter", "until smooth, then rest it.", "Heat the pan over",
                     "medium heat and pour in", "a ladle of batter."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 2), (3, 5)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Whisk the made-up batter until smooth, then rest it.",
                                             "Heat the pan over medium heat and pour in a ladle of batter."])
        #expect(mapped.steps.map(\.index) == [0, 1])
        #expect(mapped.warnings.isEmpty)
    }

    @Test("a hyphen at a line's end")
    func stepHyphenJoins() {
        let mapped = RecipeStructurer.steps(from: Self.steps((1, 2)), lines: ["Fry the made-up cakes until golden-", "brown."])

        #expect(mapped.steps.map(\.text) == ["Fry the made-up cakes until golden-brown."])
    }

    @Test("a skipped step line")
    func skippedStepLine() {
        let lines = ["Stir in the made-up sauce", "and simmer gently.", "Serve it warm.", "Cool it a little."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 1), (4, 4)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Stir in the made-up sauce and simmer gently.", "Serve it warm.", "Cool it a little."])
        #expect(mapped.warnings == ["put back: step 2"])
    }

    @Test("a printed number starts a step")
    func printedNumberStartsStep() {
        let mapped = RecipeStructurer.steps(from: Self.steps((1, 2)), lines: ["1. Mix the flour.", "2. Add the eggs."])

        #expect(mapped.steps.map(\.text) == ["Mix the flour.", "Add the eggs."])
        #expect(mapped.warnings.isEmpty)
    }

    @Test("a step heading")
    func stepHeading() {
        let lines = ["For the filling:", "Mix the made-up fruit.", "Fill the shell."]

        let mapped = RecipeStructurer.steps(from: Self.steps((2, 2), (3, 3)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Mix the made-up fruit.", "Fill the shell."])
        #expect(mapped.steps.map(\.groupName) == ["For the filling", "For the filling"])
    }

    @Test("bad step ranges")
    func badStepRanges() {
        let lines = ["Mix the made-up dough.", "Bake it."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 2), (2, 3), (2, 2)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Mix the made-up dough. Bake it."])
        #expect(mapped.warnings == ["step lines out of range", "step lines out of range"])
    }

    // MARK: Steps split where the page splits them (M3-3k)

    @Test("a range that continues a sentence")
    func rangeContinuesSentence() {
        let lines = ["Simmer the made-up sauce for 10", "minutes. Serve it hot."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 1), (2, 2)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Simmer the made-up sauce for 10 minutes. Serve it hot."])
    }

    @Test("a numbered page")
    func numberedPage() {
        let lines = ["1. Mix the made-up flour.", "Add the eggs.", "2. Bake it."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 1), (2, 2), (3, 3)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Mix the made-up flour. Add the eggs.", "Bake it."])
    }

    @Test("step markers")
    func stepMarkers() {
        let lines = ["Step 1", "Heat the made-up oven.", "Step 2", "Mix the dough.", "4.", "Bake it well."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 6)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Heat the made-up oven.", "Mix the dough.", "Bake it well."])
    }

    @Test("a heading with no colon")
    func headingWithNoColon() {
        let lines = ["Campfire Method", "Warm the made-up tortilla.", "Add the sauce."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 1), (2, 2), (3, 3)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Warm the made-up tortilla.", "Add the sauce."])
        #expect(mapped.steps.map(\.groupName) == ["Campfire Method", "Campfire Method"])
    }

    @Test("a fragment")
    func fragmentIsLeftOut() {
        let mapped = RecipeStructurer.steps(from: Self.steps((1, 1), (2, 2)), lines: [": 10 min", "Stir the made-up soup."])

        #expect(mapped.steps.map(\.text) == ["Stir the made-up soup."])
    }

    @Test("put back only between steps")
    func putBackOnlyBetweenSteps() {
        let lines = ["Made-up Notes Here.", "Mix the batter.", "Rest the batter.", "Bake the batter.", "Related Recipes Below."]

        let mapped = RecipeStructurer.steps(from: Self.steps((2, 2), (4, 4)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Mix the batter.", "Rest the batter.", "Bake the batter."])
        #expect(mapped.warnings == ["put back: step 2"])
    }

    @Test("a step line labelled an ingredient")
    func stepLineLabelledIngredient() {
        // M3-3m: the middle line no longer starts with a quantity and a unit ("2 cups …"), which
        // Part 3 keeps with the ingredients.
        let lines = ["Mix the made-up oats and", "all of the nuts until", "coated. Bake it."]
        func labels(_ middle: String) -> GeneratedLineLabels {
            GeneratedLineLabels(labels: [GeneratedLineLabel(line: 1, kind: "step"), GeneratedLineLabel(line: 2, kind: middle),
                                         GeneratedLineLabel(line: 3, kind: "step")])
        }

        let asIngredient = RecipeStructurer.labelled(lines, labels: labels("ingredient"), keeping: SplitPage())
        let asNote = RecipeStructurer.labelled(lines, labels: labels("note"), keeping: SplitPage())

        #expect(asIngredient.steps == lines)
        #expect(asIngredient.ingredients.isEmpty)
        #expect(asNote.steps == lines)
        #expect(asNote.notes.isEmpty)
    }

    // MARK: Steps under printed labels and headings (M3-3m)

    static let labelledStepLines = ["Step 1", "Mix it:", "Stir the made-up flour.", "Add the water.", "Step 2", "Bake it:",
                                    "Bake the made-up bread."]

    @Test("a range over a label and a heading")
    func rangeOverLabelAndHeading() {
        let mapped = RecipeStructurer.steps(from: Self.steps((1, 4), (5, 7)), lines: Self.labelledStepLines)

        #expect(mapped.steps.map(\.text) == ["Stir the made-up flour. Add the water.", "Bake the made-up bread."])
        #expect(mapped.steps.map(\.groupName) == ["Mix it", "Bake it"])
        #expect(mapped.warnings.isEmpty)
    }

    @Test("a first step after a label is put back")
    func firstStepAfterLabelIsPutBack() {
        let mapped = RecipeStructurer.steps(from: Self.steps((5, 7)), lines: Self.labelledStepLines)

        #expect(mapped.steps.count == 2)
        #expect(mapped.warnings == ["put back: step 1"])
    }

    @Test("a heading on a numbered page")
    func headingOnNumberedPage() {
        let lines = ["1. Mix the made-up dough.", "2. Bake it.", "Campfire Method", "1.", "Warm the made-up tortilla."]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 1), (2, 2), (3, 3), (5, 5)), lines: lines)

        #expect(mapped.steps.count == 3)
        #expect(mapped.steps.last?.groupName == "Campfire Method")
    }

    @Test("where the method ends")
    func methodEnds() {
        let lines = ["Simmer the made-up cider for 10", "minutes. Serve it hot.", "Related Pages", "Made-up Cider Recipe"]

        let mapped = RecipeStructurer.steps(from: Self.steps((1, 4)), lines: lines)

        #expect(mapped.steps.map(\.text) == ["Simmer the made-up cider for 10 minutes. Serve it hot."])
    }

    @Test("a run of step lines labelled ingredients")
    func runOfStepLinesLabelledIngredients() {
        let labels = GeneratedLineLabels(labels: [
            GeneratedLineLabel(line: 1, kind: "step"), GeneratedLineLabel(line: 2, kind: "ingredient"),
            GeneratedLineLabel(line: 3, kind: "ingredient"), GeneratedLineLabel(line: 4, kind: "step"),
        ])
        let lines = ["Whisk the made-up", "butter, sugar, honey,", "spice and salt in a", "medium bowl."]
        var withQuantity = lines
        withQuantity[1] = "1/2 cup made-up sugar,"

        let moved = RecipeStructurer.labelled(lines, labels: labels, keeping: SplitPage())
        let kept = RecipeStructurer.labelled(withQuantity, labels: labels, keeping: SplitPage())

        #expect(moved.steps == lines)
        #expect(moved.ingredients.isEmpty)
        #expect(kept.ingredients == ["1/2 cup made-up sugar,", "spice and salt in a"])
        // M3-3s: with the run kept as ingredients, "Whisk the made-up" is a step before the first
        // ingredient with a step after the last, so it is left unlabelled, as a title line would be.
        #expect(kept.steps == ["medium bowl."])
    }

    // MARK: Each ingredient's name from its own line (M3-3q)

    @Test("an item name from the next line")
    func itemNameFromNextLine() throws {
        let lines = ["1 cup made-up flour, sifted", "2 tablespoons made-up sugar"]
        let first = GeneratedLineItem(firstLine: 1, lastLine: 1, item: "made-up sugar", preparation: "melted", note: nil, isOptional: nil)
        let second = GeneratedLineItem(firstLine: 2, lastLine: 2, item: "made-up sugar", preparation: nil, note: nil, isOptional: nil)

        let mapped = RecipeStructurer.ingredientGroups(from: GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [first, second])]),
                                                       lines: lines)

        let ingredients = try #require(mapped.groups.first?.ingredients)
        try #require(ingredients.count == 2)
        #expect(ingredients[0].item == "made-up flour, sifted")
        #expect(ingredients[0].preparation == nil)
        #expect(ingredients[1].item == "made-up sugar")
        #expect(mapped.warnings.isEmpty)
    }

    @Test("an item name with its quantity")
    func itemNameWithQuantity() throws {
        let item = GeneratedLineItem(firstLine: 1, lastLine: 1, item: "1/4 cup made-up butter", preparation: nil, note: nil, isOptional: nil)

        let mapped = RecipeStructurer.ingredientGroups(from: GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [item])]),
                                                       lines: ["1/4 cup made-up butter"])

        #expect(mapped.groups.first?.ingredients.first?.item == "made-up butter")
    }

    @Test("lines put back under headings unflagged")
    func putBackUnderHeadingsUnflagged() throws {
        let lines = ["Made-up dough:", "1 cup made-up flour", "Made-up filling:", "2 tablespoons made-up jam", "- made-up sprinkles"]
        let part = GeneratedIngredientLines(groups: [GeneratedLineGroup(nameLine: 0, items: [Self.item(2, 2)])])

        let mapped = RecipeStructurer.ingredientGroups(from: part, lines: lines)

        try #require(mapped.groups.count == 2)
        #expect(mapped.groups[1].name == "Made-up filling")
        #expect(mapped.groups[1].ingredients.map(\.rawText) == ["2 tablespoons made-up jam", "- made-up sprinkles"])
        #expect(mapped.warnings == ["put back: ingredient 3"])
    }

    // MARK: A title line labelled a step (M3-3s)

    @Test("a title line labelled a step")
    func titleLineLabelledStep() {
        func labels(_ kinds: [String]) -> GeneratedLineLabels {
            GeneratedLineLabels(labels: kinds.enumerated().map { GeneratedLineLabel(line: $0.offset + 1, kind: $0.element) })
        }

        let titled = RecipeStructurer.labelled(["Made-up Hummus", "1 can made-up chickpeas", "Puree the made-up chickpeas."],
                                               labels: labels(["step", "ingredient", "step"]), keeping: SplitPage())
        let stepsFirst = RecipeStructurer.labelled(["Mix the made-up batter.", "2 cups made-up flour"],
                                                   labels: labels(["step", "ingredient"]), keeping: SplitPage())

        #expect(!titled.steps.contains("Made-up Hummus"))
        #expect(titled.steps == ["Puree the made-up chickpeas."])
        #expect(stepsFirst.steps == ["Mix the made-up batter."])
    }
}
