import Foundation

/// A recipe's times, parsed where possible, the raw text always kept.
nonisolated struct Times: Codable, Sendable, Equatable {
    var prepMinutes: Int?
    var cookMinutes: Int?
    var totalMinutes: Int?
    var rawText: String?

    init(
        prepMinutes: Int? = nil,
        cookMinutes: Int? = nil,
        totalMinutes: Int? = nil,
        rawText: String? = nil
    ) {
        self.prepMinutes = prepMinutes
        self.cookMinutes = cookMinutes
        self.totalMinutes = totalMinutes
        self.rawText = rawText
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prepMinutes = try container.decodeIfPresent(Int.self, forKey: .prepMinutes)
        cookMinutes = try container.decodeIfPresent(Int.self, forKey: .cookMinutes)
        totalMinutes = try container.decodeIfPresent(Int.self, forKey: .totalMinutes)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText)
    }
}
