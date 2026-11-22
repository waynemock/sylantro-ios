import Foundation

/// What kind of original a `SourcePage` records (`08` NI-5).
nonisolated enum SourceKind: String, Codable, Sendable, CaseIterable {
    case scan
    case screenshot
    case web

    /// A value this app doesn't know, from a newer one, reads as `.scan` (SLT-067).
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SourceKind(rawValue: rawValue) ?? .scan
    }
}
