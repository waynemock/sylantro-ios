import Foundation

/// A recipe's JSON: sorted keys, ISO 8601 dates. Each call makes its own coder, so there is no
/// shared mutable state.
nonisolated enum RecipeJSON {
    static func encode(_ recipe: Recipe) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(recipe)
    }

    static func decode(_ data: Data) throws -> Recipe {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Recipe.self, from: data)
    }
}
