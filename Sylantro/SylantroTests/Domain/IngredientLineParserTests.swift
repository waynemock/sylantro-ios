import Foundation
import Testing
@testable import Sylantro

/// The ingredient-line parser (`06` Task M1-2): the quantity and unit at the start of a line, and
/// the rest. Every line is made up.
@Suite("The ingredient-line parser")
struct IngredientLineParserTests {
    /// One row of `06` M1-2's table.
    struct Row: Sendable, CustomTestStringConvertible {
        let number: Int
        let line: String
        let quantity: Quantity?
        let unit: UnitRef?
        let rest: String

        var testDescription: String { "#\(number) \(line)" }
    }

    private static func q(_ min: Double, _ max: Double?, _ isApproximate: Bool) -> Quantity {
        Quantity(min: min, max: max, isApproximate: isApproximate)
    }

    private static func u(_ canonical: CanonicalUnit, _ raw: String) -> UnitRef {
        UnitRef(canonical: canonical, raw: raw)
    }

    static let rows: [Row] = [
        Row(number: 1, line: "2 cups flour", quantity: q(2, nil, false), unit: u(.cup, "cups"), rest: "flour"),
        Row(number: 2, line: "1/2 cup sugar", quantity: q(0.5, nil, false), unit: u(.cup, "cup"), rest: "sugar"),
        Row(number: 3, line: "1 1/2 cups milk", quantity: q(1.5, nil, false), unit: u(.cup, "cups"), rest: "milk"),
        Row(number: 4, line: "½ tsp salt", quantity: q(0.5, nil, false), unit: u(.teaspoon, "tsp"), rest: "salt"),
        Row(number: 5, line: "1½ cups water", quantity: q(1.5, nil, false), unit: u(.cup, "cups"), rest: "water"),
        Row(number: 6, line: "1 ½ cups water", quantity: q(1.5, nil, false), unit: u(.cup, "cups"), rest: "water"),
        Row(number: 7, line: "2 to 3 cups flour, sifted", quantity: q(2, 3, false), unit: u(.cup, "cups"), rest: "flour, sifted"),
        Row(number: 8, line: "2-3 Tbsp. butter", quantity: q(2, 3, false), unit: u(.tablespoon, "Tbsp."), rest: "butter"),
        Row(number: 9, line: "1\u{2013}2 tsp vanilla", quantity: q(1, 2, false), unit: u(.teaspoon, "tsp"), rest: "vanilla"),
        Row(number: 10, line: "about 2 cups broth", quantity: q(2, nil, true), unit: u(.cup, "cups"), rest: "broth"),
        Row(number: 11, line: "~1 lb ground beef", quantity: q(1, nil, true), unit: u(.pound, "lb"), rest: "ground beef"),
        Row(number: 12, line: "1 T sugar", quantity: q(1, nil, false), unit: u(.tablespoon, "T"), rest: "sugar"),
        Row(number: 13, line: "1 t salt", quantity: q(1, nil, false), unit: u(.teaspoon, "t"), rest: "salt"),
        Row(number: 14, line: "200g butter", quantity: q(200, nil, false), unit: u(.gram, "g"), rest: "butter"),
        Row(number: 15, line: "8 oz. cream cheese", quantity: q(8, nil, false), unit: u(.ounce, "oz."), rest: "cream cheese"),
        Row(number: 16, line: "4 fl oz milk", quantity: q(4, nil, false), unit: u(.fluidOunce, "fl oz"), rest: "milk"),
        Row(number: 17, line: "1 can (15 oz) black beans", quantity: q(1, nil, false), unit: u(.can, "can"), rest: "(15 oz) black beans"),
        Row(number: 18, line: "3 eggs", quantity: q(3, nil, false), unit: nil, rest: "eggs"),
        Row(number: 19, line: "2 large eggs", quantity: q(2, nil, false), unit: nil, rest: "large eggs"),
        Row(number: 20, line: "a pinch of salt", quantity: q(1, nil, false), unit: u(.pinch, "pinch"), rest: "salt"),
        Row(number: 21, line: "Salt and pepper to taste", quantity: nil, unit: nil, rest: "Salt and pepper to taste"),
        Row(number: 22, line: "1.5 kg potatoes", quantity: q(1.5, nil, false), unit: u(.kilogram, "kg"), rest: "potatoes"),
        Row(number: 23, line: "⅓ cup oil", quantity: q(1.0 / 3.0, nil, false), unit: u(.cup, "cup"), rest: "oil"),
        Row(number: 24, line: "2 cloves garlic, minced", quantity: q(2, nil, false), unit: u(.clove, "cloves"), rest: "garlic, minced"),
        Row(number: 25, line: "  1 cup  rice  ", quantity: q(1, nil, false), unit: u(.cup, "cup"), rest: "rice"),
        Row(number: 26, line: "1/0 cup", quantity: nil, unit: nil, rest: "1/0 cup"),
        Row(number: 27, line: "one onion, diced", quantity: q(1, nil, false), unit: nil, rest: "onion, diced"),
        Row(number: 28, line: "1 garlic clove", quantity: q(1, nil, false), unit: nil, rest: "garlic clove"),
        Row(number: 29, line: "3/4 c. sugar", quantity: q(0.75, nil, false), unit: u(.cup, "c."), rest: "sugar"),
        Row(number: 30, line: "about a dozen eggs", quantity: q(12, nil, true), unit: nil, rest: "eggs"),
        Row(number: 31, line: "Dozen eggs", quantity: q(12, nil, false), unit: nil, rest: "eggs"),
    ]

    @Test("each line parses as the table says", arguments: rows)
    func eachLineParses(_ row: Row) {
        let parsed = IngredientLineParser.parse(row.line)
        #expect(parsed == ParsedLine(quantity: row.quantity, unit: row.unit, rest: row.rest))
    }

    @Test("every canonical unit has a spelling")
    func everyCanonicalUnitHasASpelling() {
        let spelled = Set(UnitSpellings.caseSensitive.values)
            .union(UnitSpellings.twoWord.values)
            .union(UnitSpellings.oneWord.values)
        for unit in CanonicalUnit.allCases {
            #expect(spelled.contains(unit), "\(unit) has no spelling")
        }
    }
}
