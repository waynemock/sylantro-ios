import Foundation

/// The record of one original, never edited once saved (SLT-060). Its photos are `Photo`s that
/// point at it; it holds no image data (SLT-053).
nonisolated struct SourcePage: Codable, Sendable, Equatable {
    var id: UUID
    /// `08` NI-5.
    var kind: SourceKind
    /// Its `ScanSession`.
    var sessionID: UUID?
    var capturedAt: Date
    /// Reserved.
    var binderPageLabel: String?
    /// Filled by M3.
    var ocrText: String?
    /// Filled by M3.
    var ocrWords: [OCRWord]
    /// SLT-044.
    var structuringState: StructuringState
    /// A web original's address as fetched (NI-5); text, not `URL`.
    var webAddress: String?
    /// A web original's fetch date.
    var fetchedAt: Date?
    /// The recipe data exactly as fetched (`08` §3.1 A).
    var fetchedRecipeJSON: String?

    init(
        id: UUID = UUID(),
        kind: SourceKind = .scan,
        sessionID: UUID? = nil,
        capturedAt: Date = Date(),
        binderPageLabel: String? = nil,
        ocrText: String? = nil,
        ocrWords: [OCRWord] = [],
        structuringState: StructuringState = .waiting,
        webAddress: String? = nil,
        fetchedAt: Date? = nil,
        fetchedRecipeJSON: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.sessionID = sessionID
        self.capturedAt = capturedAt
        self.binderPageLabel = binderPageLabel
        self.ocrText = ocrText
        self.ocrWords = ocrWords
        self.structuringState = structuringState
        self.webAddress = webAddress
        self.fetchedAt = fetchedAt
        self.fetchedRecipeJSON = fetchedRecipeJSON
    }

    /// Only `id` is required; every other key falls back to its default.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decodeIfPresent(SourceKind.self, forKey: .kind) ?? .scan
        sessionID = try container.decodeIfPresent(UUID.self, forKey: .sessionID)
        capturedAt = try container.decodeIfPresent(Date.self, forKey: .capturedAt) ?? Date()
        binderPageLabel = try container.decodeIfPresent(String.self, forKey: .binderPageLabel)
        ocrText = try container.decodeIfPresent(String.self, forKey: .ocrText)
        ocrWords = try container.decodeIfPresent([OCRWord].self, forKey: .ocrWords) ?? []
        structuringState = try container.decodeIfPresent(StructuringState.self, forKey: .structuringState) ?? .waiting
        webAddress = try container.decodeIfPresent(String.self, forKey: .webAddress)
        fetchedAt = try container.decodeIfPresent(Date.self, forKey: .fetchedAt)
        fetchedRecipeJSON = try container.decodeIfPresent(String.self, forKey: .fetchedRecipeJSON)
    }
}
