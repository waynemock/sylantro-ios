import Foundation

/// One image file's record (`05` §4): its metadata and file name, never its bytes (SLT-053).
nonisolated struct Photo: Codable, Sendable, Equatable {
    var id: UUID
    /// A raw string, so a future kind survives a round trip (`05` §4).
    var kindRaw: String
    /// A page photo's page.
    var sourcePageID: UUID?
    /// A dish photo's recipe.
    var recipeID: UUID?
    /// Dish photo order; 0 is the cover.
    var sortIndex: Int
    var pixelWidth: Int?
    var pixelHeight: Int?
    var takenAt: Date
    /// `PhotoEncoding.fileName(for: id)`; never the bytes (SLT-053).
    var fileName: String?

    /// The kind, or nil for one this app doesn't know. Not encoded.
    var kind: PhotoKind? { PhotoKind(rawValue: kindRaw) }

    init(
        id: UUID = UUID(),
        kindRaw: String = PhotoKind.pageOriginal.rawValue,
        sourcePageID: UUID? = nil,
        recipeID: UUID? = nil,
        sortIndex: Int = 0,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        takenAt: Date = Date(),
        fileName: String? = nil
    ) {
        self.id = id
        self.kindRaw = kindRaw
        self.sourcePageID = sourcePageID
        self.recipeID = recipeID
        self.sortIndex = sortIndex
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.takenAt = takenAt
        self.fileName = fileName
    }

    /// Only `id` is required; every other key falls back to its default.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kindRaw = try container.decodeIfPresent(String.self, forKey: .kindRaw) ?? PhotoKind.pageOriginal.rawValue
        sourcePageID = try container.decodeIfPresent(UUID.self, forKey: .sourcePageID)
        recipeID = try container.decodeIfPresent(UUID.self, forKey: .recipeID)
        sortIndex = try container.decodeIfPresent(Int.self, forKey: .sortIndex) ?? 0
        pixelWidth = try container.decodeIfPresent(Int.self, forKey: .pixelWidth)
        pixelHeight = try container.decodeIfPresent(Int.self, forKey: .pixelHeight)
        takenAt = try container.decodeIfPresent(Date.self, forKey: .takenAt) ?? Date()
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
    }
}
