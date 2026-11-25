import Foundation

/// A named run of ingredients: "For the sauce", "For the crust".
nonisolated struct IngredientGroup: Codable, Sendable, Equatable {
    var id: UUID
    /// nil is an unnamed group.
    var name: String?
    /// Where the name is on the page (`15` RV-34, M3-3d); nil when not placed.
    var nameBox: SourceBox?
    var ingredients: [Ingredient]

    init(
        id: UUID = UUID(),
        name: String? = nil,
        nameBox: SourceBox? = nil,
        ingredients: [Ingredient] = []
    ) {
        self.id = id
        self.name = name
        self.nameBox = nameBox
        self.ingredients = ingredients
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name)
        nameBox = try container.decodeIfPresent(SourceBox.self, forKey: .nameBox)
        ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients) ?? []
    }
}
