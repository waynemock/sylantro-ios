import Foundation

/// Where a recipe stands in review; drives the review inbox.
nonisolated enum ReviewState: String, Codable, Sendable, CaseIterable {
    case needsReview
    case reviewed
    case edited

    /// A value this app doesn't know, from a newer one, reads as `.needsReview`.
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ReviewState(rawValue: rawValue) ?? .needsReview
    }
}
