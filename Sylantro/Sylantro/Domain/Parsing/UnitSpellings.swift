import Foundation

/// The one table of unit spellings the ingredient-line parser knows (`00A` §10). `twoWord` and
/// `oneWord` keys are lowercase with no periods; `caseSensitive` is checked as written (SLT-048).
nonisolated enum UnitSpellings {
    static let caseSensitive: [String: CanonicalUnit] = ["T": .tablespoon, "t": .teaspoon]

    static let twoWord: [String: CanonicalUnit] = [
        "fl oz": .fluidOunce,
        "fluid ounce": .fluidOunce,
        "fluid ounces": .fluidOunce,
    ]

    static let oneWord: [String: CanonicalUnit] = [
        "tsp": .teaspoon, "tsps": .teaspoon, "teaspoon": .teaspoon, "teaspoons": .teaspoon,
        "tbsp": .tablespoon, "tbsps": .tablespoon, "tbs": .tablespoon, "tbl": .tablespoon,
        "tablespoon": .tablespoon, "tablespoons": .tablespoon,
        "c": .cup, "cup": .cup, "cups": .cup,
        "floz": .fluidOunce,
        "pt": .pint, "pint": .pint, "pints": .pint,
        "qt": .quart, "quart": .quart, "quarts": .quart,
        "gal": .gallon, "gallon": .gallon, "gallons": .gallon,
        "ml": .milliliter, "milliliter": .milliliter, "milliliters": .milliliter,
        "millilitre": .milliliter, "millilitres": .milliliter,
        "l": .liter, "liter": .liter, "liters": .liter, "litre": .liter, "litres": .liter,
        "oz": .ounce, "ounce": .ounce, "ounces": .ounce,
        "lb": .pound, "lbs": .pound, "pound": .pound, "pounds": .pound,
        "g": .gram, "gr": .gram, "gram": .gram, "grams": .gram,
        "kg": .kilogram, "kilogram": .kilogram, "kilograms": .kilogram,
        "pinch": .pinch, "pinches": .pinch,
        "dash": .dash, "dashes": .dash,
        "clove": .clove, "cloves": .clove,
        "can": .can, "cans": .can,
        "pkg": .package, "package": .package, "packages": .package,
        "stick": .stick, "sticks": .stick,
        "slice": .slice, "slices": .slice,
    ]
}
