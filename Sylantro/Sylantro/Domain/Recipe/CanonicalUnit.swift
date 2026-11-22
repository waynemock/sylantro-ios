import Foundation

/// The units Sylantro knows. No conversion factors: those belong to the nutrition task (`03` §6).
nonisolated enum CanonicalUnit: String, Codable, Sendable, CaseIterable {
    case teaspoon
    case tablespoon
    case cup
    case fluidOunce
    case pint
    case quart
    case gallon
    case milliliter
    case liter
    case ounce
    case pound
    case gram
    case kilogram
    case pinch
    case dash
    case clove
    case can
    case package
    case stick
    case slice
}
