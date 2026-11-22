import Foundation

/// What a recipe makes: "Serves 4 to 6", "Makes 24 cookies", or both.
nonisolated struct Yield: Codable, Sendable, Equatable {
    /// "Serves 4 to 6" is min 4, max 6.
    var servings: Quantity?
    /// "Makes 24": 24.
    var amount: Quantity?
    /// "cookies".
    var amountUnit: String?
    /// As printed.
    var rawText: String?

    init(
        servings: Quantity? = nil,
        amount: Quantity? = nil,
        amountUnit: String? = nil,
        rawText: String? = nil
    ) {
        self.servings = servings
        self.amount = amount
        self.amountUnit = amountUnit
        self.rawText = rawText
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        servings = try container.decodeIfPresent(Quantity.self, forKey: .servings)
        amount = try container.decodeIfPresent(Quantity.self, forKey: .amount)
        amountUnit = try container.decodeIfPresent(String.self, forKey: .amountUnit)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText)
    }
}
