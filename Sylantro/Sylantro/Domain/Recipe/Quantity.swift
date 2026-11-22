import Foundation

/// A number as read: a single value, or a range from `min` to `max`, perhaps "about".
nonisolated struct Quantity: Codable, Sendable, Equatable {
    var min: Double
    /// nil is a single value.
    var max: Double?
    var isApproximate: Bool

    init(
        min: Double,
        max: Double? = nil,
        isApproximate: Bool = false
    ) {
        self.min = min
        self.max = max
        self.isApproximate = isApproximate
    }

    /// `min` is required.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        min = try container.decode(Double.self, forKey: .min)
        max = try container.decodeIfPresent(Double.self, forKey: .max)
        isApproximate = try container.decodeIfPresent(Bool.self, forKey: .isApproximate) ?? false
    }
}
