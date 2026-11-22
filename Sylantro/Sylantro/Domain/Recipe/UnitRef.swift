import Foundation

/// A unit as written, and the canonical unit it stands for when Sylantro knows it.
nonisolated struct UnitRef: Codable, Sendable, Equatable {
    /// nil is a unit Sylantro doesn't know.
    var canonical: CanonicalUnit?
    /// As written: "Tbsp.".
    var raw: String

    init(
        canonical: CanonicalUnit? = nil,
        raw: String
    ) {
        self.canonical = canonical
        self.raw = raw
    }

    /// `raw` is required. A canonical unit this app doesn't know, from a newer app or a shared
    /// file, reads as nil instead of throwing (SLT-067).
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canonical = try container.decodeIfPresent(String.self, forKey: .canonical).flatMap(CanonicalUnit.init(rawValue:))
        raw = try container.decode(String.self, forKey: .raw)
    }
}
