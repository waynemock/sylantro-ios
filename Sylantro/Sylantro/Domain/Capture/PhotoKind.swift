import Foundation

/// What a `Photo` is of (`05` §4). Not decoded directly: `Photo` keeps the raw string, so a future
/// kind survives a round trip.
nonisolated enum PhotoKind: String, Codable, Sendable, CaseIterable {
    case pageOriginal
    case pageCropped
    case dish
}
