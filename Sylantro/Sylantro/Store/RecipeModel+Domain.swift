import Foundation
import SwiftData
import SyLibCore

extension RecipeModel {
    private static let log = AppLogger(category: "Store")

    /// Sets every property from `value`: the whole recipe as `RecipeJSON` (`14` MT-5), and copies
    /// of its title, review state and dates for `@Query` sorting.
    func hydrate(from value: Recipe) {
        id = value.id
        title = value.title
        createdAt = value.createdAt
        updatedAt = value.updatedAt
        reviewStateRaw = value.reviewState.rawValue
        do {
            recipeData = try RecipeJSON.encode(value)
        } catch {
            recipeData = nil
            Self.log.error(self, "recipe \(value.id): not encoded: \(error)")
        }
    }

    /// The recipe decoded from `recipeData`; nil if it is missing or unreadable, logged without
    /// recipe text.
    func toDomain() -> Recipe? {
        guard let recipeData else {
            Self.log.error(self, "recipe \(id): no recipe data")
            return nil
        }
        do {
            return try RecipeJSON.decode(recipeData)
        } catch {
            Self.log.error(self, "recipe \(id): recipe data unreadable (\(recipeData.count) bytes)")
            return nil
        }
    }
}
