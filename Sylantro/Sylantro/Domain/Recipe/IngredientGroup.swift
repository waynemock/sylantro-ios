import Foundation

/// A named run of ingredients: "For the sauce", "For the crust".
nonisolated struct IngredientGroup: Codable, Sendable, Equatable {
    var id: UUID
    /// nil is an unnamed group.
    var name: String?
    var ingredients: [Ingredient]

    init(
        id: UUID = UUID(),
        name: String? = nil,
        ingredients: [Ingredient] = []
    ) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name)
        ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients) ?? []
    }
}
