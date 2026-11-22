#if DEBUG
import Foundation

/// The accuracy spike's exported results (`11` M1-3, SLT-093): sorted-key JSON with ISO 8601
/// dates, like `RecipeJSON`. Debug builds only.
nonisolated struct SpikeReport: Codable, Sendable {
    var runAt: Date
    /// The hardware identifier, such as `iPhone18,1`.
    var deviceModel: String
    var systemVersion: String
    var modelAvailable: Bool
    var captures: [SpikeCaptureResult]

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

/// One capture's readings, timings and recipes.
nonisolated struct SpikeCaptureResult: Codable, Sendable {
    /// In order.
    var fileNames: [String]
    var readings: [PageReading]
    /// One per page.
    var readMillis: [Int]
    /// The last page's `readBottom`.
    var bottomReadMillis: Int?
    var bottomText: String?
    var structureMillis: Int?
    var recipes: [Recipe]
    /// The error's `String(describing:)`.
    var error: String?
    /// `parts` or `oneShot`; nil until structured.
    var path: String?
    /// Each model call's time, keyed by part.
    var partMillis: [String: Int]
    var usedLineLabels: Bool
    /// A part that threw, keyed by part.
    var partErrors: [String: String]
    /// How many times it waited for the app (SLT-144).
    var waits: Int
    /// Every recipe's `extraction.warnings`.
    var warnings: [String]
}
#endif
