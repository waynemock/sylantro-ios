import Foundation

/// The structured reading of one recipe (SLT-060). Its JSON is what the store's data and
/// `recipe.json` hold (SLT-061); a file missing a key still reads, with that key's default.
nonisolated struct Recipe: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 1

    var id: UUID
    var schemaVersion: Int
    var title: String
    /// Where the title is on the page (`15` RV-31, M3-3a), as ingredients and steps carry theirs;
    /// nil when not placed, as in every recipe read before M3-3a.
    var titleBox: SourceBox?
    /// Where the other lines are on the page (`15` RV-34, M3-3d), by `FieldBoxKey`: the yield,
    /// times, notes, nutrition, each equipment item and each source line. Empty for a recipe read
    /// before M3-3d.
    var fieldBoxes: [String: SourceBox]
    var yield: Yield?
    var times: Times?
    var ingredientGroups: [IngredientGroup]
    var steps: [Step]
    var notes: String?
    var tags: [String]
    /// Where it came from, in parts (SLT-062).
    var attribution: Attribution?
    /// Nutrition facts as printed on the page, raw text (SLT-063).
    var printedNutrition: String?
    /// A printed Equipment list, one item each (SLT-064).
    var equipment: [String]
    /// Handwriting that can't be read and has no place in the recipe (SLT-066).
    var unreadableAreas: [SourceBox]
    /// The `SourcePage`s it was read from (SLT-060).
    var sourcePageIDs: [UUID]
    /// Set when she answers Save Without It at "Is there another page?" (SLT-046); cleared by Add Page.
    var continuesOnUnscannedPage: Bool
    var reviewState: ReviewState
    var extraction: Extraction?
    var createdAt: Date
    var updatedAt: Date
    /// A variant's original.
    var parentRecipeID: UUID?

    init(
        id: UUID = UUID(),
        schemaVersion: Int = Recipe.currentSchemaVersion,
        title: String = "",
        titleBox: SourceBox? = nil,
        fieldBoxes: [String: SourceBox] = [:],
        yield: Yield? = nil,
        times: Times? = nil,
        ingredientGroups: [IngredientGroup] = [],
        steps: [Step] = [],
        notes: String? = nil,
        tags: [String] = [],
        attribution: Attribution? = nil,
        printedNutrition: String? = nil,
        equipment: [String] = [],
        unreadableAreas: [SourceBox] = [],
        sourcePageIDs: [UUID] = [],
        continuesOnUnscannedPage: Bool = false,
        reviewState: ReviewState = .needsReview,
        extraction: Extraction? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        parentRecipeID: UUID? = nil
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.title = title
        self.titleBox = titleBox
        self.fieldBoxes = fieldBoxes
        self.yield = yield
        self.times = times
        self.ingredientGroups = ingredientGroups
        self.steps = steps
        self.notes = notes
        self.tags = tags
        self.attribution = attribution
        self.printedNutrition = printedNutrition
        self.equipment = equipment
        self.unreadableAreas = unreadableAreas
        self.sourcePageIDs = sourcePageIDs
        self.continuesOnUnscannedPage = continuesOnUnscannedPage
        self.reviewState = reviewState
        self.extraction = extraction
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.parentRecipeID = parentRecipeID
    }

    /// Only `id` is required; every other key falls back to its default.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Recipe.currentSchemaVersion
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        titleBox = try container.decodeIfPresent(SourceBox.self, forKey: .titleBox)
        fieldBoxes = try container.decodeIfPresent([String: SourceBox].self, forKey: .fieldBoxes) ?? [:]
        yield = try container.decodeIfPresent(Yield.self, forKey: .yield)
        times = try container.decodeIfPresent(Times.self, forKey: .times)
        ingredientGroups = try container.decodeIfPresent([IngredientGroup].self, forKey: .ingredientGroups) ?? []
        steps = try container.decodeIfPresent([Step].self, forKey: .steps) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        attribution = try container.decodeIfPresent(Attribution.self, forKey: .attribution)
        printedNutrition = try container.decodeIfPresent(String.self, forKey: .printedNutrition)
        equipment = try container.decodeIfPresent([String].self, forKey: .equipment) ?? []
        unreadableAreas = try container.decodeIfPresent([SourceBox].self, forKey: .unreadableAreas) ?? []
        sourcePageIDs = try container.decodeIfPresent([UUID].self, forKey: .sourcePageIDs) ?? []
        continuesOnUnscannedPage = try container.decodeIfPresent(Bool.self, forKey: .continuesOnUnscannedPage) ?? false
        reviewState = try container.decodeIfPresent(ReviewState.self, forKey: .reviewState) ?? .needsReview
        extraction = try container.decodeIfPresent(Extraction.self, forKey: .extraction)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        parentRecipeID = try container.decodeIfPresent(UUID.self, forKey: .parentRecipeID)
    }
}

extension Recipe {
    /// `fieldBoxes`' keys (`15` M3-3d): equipment items and source lines are numbered from 0, in
    /// the order the screen shows them (`equipment`, and `RecipeRendering.sourceLines`).
    nonisolated enum FieldBoxKey {
        static let yield = "yield"
        static let times = "times"
        static let notes = "notes"
        static let nutrition = "nutrition"

        static func equipment(_ index: Int) -> String {
            "equipment.\(index)"
        }

        static func source(_ index: Int) -> String {
            "source.\(index)"
        }
    }
}
