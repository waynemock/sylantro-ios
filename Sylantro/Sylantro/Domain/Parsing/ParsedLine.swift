import Foundation

/// What `IngredientLineParser` reads from the start of one ingredient line: the quantity, the unit,
/// and everything after them.
nonisolated struct ParsedLine: Equatable, Sendable {
    var quantity: Quantity?
    var unit: UnitRef?
    var rest: String
}
