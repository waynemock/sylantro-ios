import Foundation

/// One sitting of scanning: the pages captured between tapping "Let's cook." and leaving the camera.
nonisolated struct ScanSession: Codable, Sendable, Equatable {
    var id: UUID
    var startedAt: Date
    /// Reserved; no screen sets it in M2.
    var binderSection: String?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        binderSection: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.binderSection = binderSection
    }

    /// Only `id` is required; every other key falls back to its default.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        binderSection = try container.decodeIfPresent(String.self, forKey: .binderSection)
    }
}
