import Foundation
import Testing
@testable import Sylantro

/// The recipe's JSON (`06` Task M1-1): it round-trips, its keys are sorted, and a file missing a
/// key or carrying one this app doesn't know still reads (SLT-061). Every fixture is made up.
@Suite("Recipe JSON")
struct RecipeJSONTests {
    // MARK: Fixtures

    /// Whole seconds, since `.iso8601` drops fractions.
    static let created = Date(timeIntervalSince1970: 1_795_000_000)
    static let updated = Date(timeIntervalSince1970: 1_795_000_600)
    static let extracted = Date(timeIntervalSince1970: 1_795_000_300)

    static let recipeID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    static let parentID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    static let pageOneID = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!
    static let pageTwoID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
    static let crustGroupID = UUID(uuidString: "55555555-5555-4555-8555-555555555555")!
    static let fillingGroupID = UUID(uuidString: "66666666-6666-4666-8666-666666666666")!
    static let flourID = UUID(uuidString: "77777777-7777-4777-8777-777777777777")!
    static let plumsID = UUID(uuidString: "88888888-8888-4888-8888-888888888888")!
    static let stepOneID = UUID(uuidString: "99999999-9999-4999-8999-999999999999")!
    static let stepTwoID = UUID(uuidString: "AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA")!

    /// A ranged, approximate, optional ingredient with a `sourceBox`; every property set.
    static let flour = Ingredient(
        id: flourID,
        rawText: "about 2 to 3 Tbsp. rye flour, sifted (optional)",
        quantity: Quantity(min: 2, max: 3, isApproximate: true),
        unit: UnitRef(canonical: .tablespoon, raw: "Tbsp."),
        item: "rye flour",
        preparation: "sifted",
        isOptional: true,
        note: "for dusting",
        sourceBox: SourceBox(pageID: pageOneID, x: 0.125, y: 0.25, width: 0.5, height: 0.0625),
        confidence: 0.75,
        isHandwritten: true,
        isUnreadable: true
    )

    static let plums = Ingredient(
        id: plumsID,
        rawText: "1 to 2 lb. purple plums, halved, if ripe",
        quantity: Quantity(min: 1, max: 2, isApproximate: true),
        unit: UnitRef(canonical: .pound, raw: "lb."),
        item: "purple plums",
        preparation: "halved",
        isOptional: true,
        note: "if ripe",
        sourceBox: SourceBox(pageID: pageTwoID, x: 0.25, y: 0.5, width: 0.375, height: 0.03125),
        confidence: 0.5,
        isHandwritten: true,
        isUnreadable: true
    )

    static let full = Recipe(
        id: recipeID,
        schemaVersion: 2,
        title: "Grandma Wren's Plum Tart",
        yield: Yield(
            servings: Quantity(min: 6, max: 8, isApproximate: true),
            amount: Quantity(min: 1, max: 2, isApproximate: true),
            amountUnit: "tarts",
            rawText: "Serves 6 to 8 (makes 1 or 2 tarts)"
        ),
        times: Times(prepMinutes: 20, cookMinutes: 45, totalMinutes: 65, rawText: "Prep 20 min, bake 45 min"),
        ingredientGroups: [
            IngredientGroup(id: crustGroupID, name: "For the crust", ingredients: [flour]),
            IngredientGroup(id: fillingGroupID, name: "For the filling", ingredients: [plums]),
        ],
        steps: [
            Step(
                id: stepOneID,
                index: 1,
                text: "Dust the board with the flour.",
                groupName: "For the crust",
                ingredientIDs: [flourID],
                sourceBox: SourceBox(pageID: pageOneID, x: 0.125, y: 0.625, width: 0.75, height: 0.125),
                isHandwritten: true,
                isUnreadable: true
            ),
            Step(
                id: stepTwoID,
                index: 2,
                text: "Lay the plums cut side up and bake.",
                groupName: "For the filling",
                ingredientIDs: [plumsID],
                sourceBox: SourceBox(pageID: pageTwoID, x: 0.125, y: 0.75, width: 0.75, height: 0.0625),
                isHandwritten: true,
                isUnreadable: true
            ),
        ],
        notes: "Better the next day.",
        tags: ["dessert", "fruit"],
        attribution: Attribution(
            author: "Wren Example",
            publisher: "Made-Up Monthly",
            show: "The Pretend Kitchen",
            episode: "Episode 12",
            sourceURL: "https://example.com/plum-tart",
            printedDate: "June 3",
            issueDate: "Summer 1999",
            copyright: "© 1999 Made-Up Monthly",
            text: "From Aunt May"
        ),
        printedNutrition: "Per serving: 240 calories, 4 g protein",
        equipment: ["9-inch tart pan", "rolling pin"],
        unreadableAreas: [SourceBox(pageID: pageTwoID, x: 0.875, y: 0.125, width: 0.0625, height: 0.25)],
        sourcePageIDs: [pageOneID, pageTwoID],
        continuesOnUnscannedPage: true,
        reviewState: .reviewed,
        extraction: Extraction(
            engine: "testEngine",
            modelID: "made-up-model-1",
            promptVersion: 3,
            overallConfidence: 0.875,
            extractedAt: extracted,
            warnings: ["continues on a page not scanned"]
        ),
        createdAt: created,
        updatedAt: updated,
        parentRecipeID: parentID
    )

    // MARK: Tests

    @Test("a recipe survives a round trip")
    func roundTrip() throws {
        let decoded = try RecipeJSON.decode(RecipeJSON.encode(Self.full))
        #expect(decoded == Self.full)
    }

    @Test("keys are sorted and the schema version is written")
    func sortedKeysAndSchemaVersion() throws {
        // `full` sets a non-default schema version; this one is the current version.
        var recipe = Self.full
        recipe.schemaVersion = Recipe.currentSchemaVersion
        let json = try #require(String(data: RecipeJSON.encode(recipe), encoding: .utf8))
        #expect(json.contains("\"schemaVersion\" : 1"))
        let attribution = try #require(json.range(of: "\"attribution\""))
        let createdAt = try #require(json.range(of: "\"createdAt\""))
        let title = try #require(json.range(of: "\"title\""))
        #expect(attribution.lowerBound < createdAt.lowerBound)
        #expect(createdAt.lowerBound < title.lowerBound)
    }

    @Test("an older recipe reads")
    func olderRecipeReads() throws {
        // `full` has no title box, as every recipe before M3-3a (RV-31).
        let data = try RecipeJSON.encode(Self.full)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(!json.contains("titleBox"))

        let decoded = try RecipeJSON.decode(data)

        #expect(decoded.titleBox == nil)
        #expect(decoded == Self.full)
    }

    @Test("older recipes read")
    func olderRecipesReadWithoutFieldBoxes() throws {
        // A recipe from before M3-3d (RV-34): no `fieldBoxes`, and groups with no `nameBox`.
        var object = try #require(try JSONSerialization.jsonObject(with: RecipeJSON.encode(Self.full)) as? [String: Any])
        object.removeValue(forKey: "fieldBoxes")
        let groups = try #require(object["ingredientGroups"] as? [[String: Any]])
        object["ingredientGroups"] = groups.map { group in group.filter { $0.key != "nameBox" } }
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(!(String(data: data, encoding: .utf8) ?? "").contains("fieldBoxes"))

        let decoded = try RecipeJSON.decode(data)

        #expect(decoded.fieldBoxes.isEmpty)
        #expect(decoded.ingredientGroups.allSatisfy { $0.nameBox == nil })
        #expect(decoded == Self.full)
    }

    @Test("a file with only an id reads with every default")
    func onlyAnIDReadsWithDefaults() throws {
        let json = #"{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F"}"#
        let recipe = try RecipeJSON.decode(Data(json.utf8))
        #expect(recipe.id == UUID(uuidString: "8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F"))
        #expect(recipe.schemaVersion == 1)
        #expect(recipe.title == "")
        #expect(recipe.yield == nil)
        #expect(recipe.times == nil)
        #expect(recipe.ingredientGroups.isEmpty)
        #expect(recipe.steps.isEmpty)
        #expect(recipe.notes == nil)
        #expect(recipe.tags.isEmpty)
        #expect(recipe.attribution == nil)
        #expect(recipe.printedNutrition == nil)
        #expect(recipe.equipment.isEmpty)
        #expect(recipe.unreadableAreas.isEmpty)
        #expect(recipe.sourcePageIDs.isEmpty)
        #expect(recipe.reviewState == .needsReview)
        #expect(recipe.extraction == nil)
        #expect(recipe.parentRecipeID == nil)
    }

    @Test("a file without an id is refused")
    func noIDIsRefused() {
        let json = #"{"title":"Soup"}"#
        #expect(throws: (any Error).self) {
            try RecipeJSON.decode(Data(json.utf8))
        }
    }

    @Test("an unknown key is ignored")
    func unknownKeyIsIgnored() throws {
        let data = try RecipeJSON.encode(Self.full)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["futureField"] = true
        let withFutureField = try JSONSerialization.data(withJSONObject: object)
        #expect(try RecipeJSON.decode(withFutureField) == Self.full)
    }

    @Test("an unknown review state reads as needs review")
    func unknownReviewStateIsNeedsReview() throws {
        let json = #"{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F","reviewState":"archived"}"#
        let recipe = try RecipeJSON.decode(Data(json.utf8))
        #expect(recipe.reviewState == .needsReview)
    }

    @Test("an unknown engine survives")
    func unknownEngineSurvives() throws {
        let recipe = Recipe(id: Self.recipeID, extraction: Extraction(engine: "futureEngine"))
        let decoded = try RecipeJSON.decode(RecipeJSON.encode(recipe))
        #expect(decoded.extraction?.engine == "futureEngine")
    }

    @Test("an unknown unit spelling has no canonical unit")
    func unknownUnitHasNoCanonical() throws {
        let handful = Ingredient(id: Self.flourID, rawText: "a handful of herbs", unit: UnitRef(raw: "handful"))
        let recipe = Recipe(id: Self.recipeID, ingredientGroups: [IngredientGroup(id: Self.crustGroupID, ingredients: [handful])])
        let decoded = try RecipeJSON.decode(RecipeJSON.encode(recipe))
        let unit = try #require(decoded.ingredientGroups.first?.ingredients.first?.unit)
        #expect(unit.raw == "handful")
        #expect(unit.canonical == nil)
    }

    @Test("an unknown canonical unit reads as none")
    func unknownCanonicalUnitReadsAsNone() throws {
        let json = #"{"canonical":"bushel","raw":"bu"}"#
        let unit = try JSONDecoder().decode(UnitRef.self, from: Data(json.utf8))
        #expect(unit.canonical == nil)
        #expect(unit.raw == "bu")
    }
}
