import Foundation

/// Where a page stands in structuring (SLT-044).
nonisolated enum StructuringState: String, Codable, Sendable, CaseIterable {
    case waiting
    case structured
    case failed

    /// A value this app doesn't know, from a newer one, reads as `.waiting`, so the page is looked
    /// at again, never lost (SLT-067, SLT-044).
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = StructuringState(rawValue: rawValue) ?? .waiting
    }
}
