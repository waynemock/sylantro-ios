import Foundation

/// How a recipe was read, so a newer extractor can re-run only recipes an older one made.
nonisolated struct Extraction: Codable, Sendable, Equatable {
    static let onDeviceEngine = "onDevice"

    /// A string, so a future engine's value survives.
    var engine: String
    var modelID: String?
    var promptVersion: Int?
    var overallConfidence: Double?
    var extractedAt: Date?
    var warnings: [String]

    init(
        engine: String = Extraction.onDeviceEngine,
        modelID: String? = nil,
        promptVersion: Int? = nil,
        overallConfidence: Double? = nil,
        extractedAt: Date? = nil,
        warnings: [String] = []
    ) {
        self.engine = engine
        self.modelID = modelID
        self.promptVersion = promptVersion
        self.overallConfidence = overallConfidence
        self.extractedAt = extractedAt
        self.warnings = warnings
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        engine = try container.decodeIfPresent(String.self, forKey: .engine) ?? Extraction.onDeviceEngine
        modelID = try container.decodeIfPresent(String.self, forKey: .modelID)
        promptVersion = try container.decodeIfPresent(Int.self, forKey: .promptVersion)
        overallConfidence = try container.decodeIfPresent(Double.self, forKey: .overallConfidence)
        extractedAt = try container.decodeIfPresent(Date.self, forKey: .extractedAt)
        warnings = try container.decodeIfPresent([String].self, forKey: .warnings) ?? []
    }
}
