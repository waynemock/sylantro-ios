import Foundation

/// The accuracy spike's exported results (`11` M1-3, SLT-093): sorted-key JSON with ISO 8601
/// dates, like `RecipeJSON`. Behind SLT-093's
/// `AppConfig.AccuracySpike` flag.
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
    /// The parts asked a second time (SLT-147).
    var retried: [String]
    /// The parts asked over the whole page (SLT-147).
    var fallbacks: [String]
    /// The lines in non-Latin letters taken out as unreadable (SLT-150).
    var unreadableLines: Int
    /// How many times structuring was retried after a refusal while in front (SLT-153).
    var rateLimitRetries: Int
    /// The title the header step chose (`11` M1-9).
    var headerTitle: String?
    /// The header answer's title as the model wrote it (`11` M1-14).
    var modelTitle: String?
    /// The header answer's `otherTitles`, as returned (`11` M1-9).
    var otherTitles: [String]
    /// The lines the header step showed the model, each with its text and size (`15` M3-1).
    var headerArea: [HeaderArea.HeaderLine]

    /// One piece of a capture cut by its titles, structured on its own (`15` M3-5s, RV-35).
    nonisolated struct Piece: Codable, Sendable, Equatable {
        var title: String
        var ingredientCount: Int
        var stepCount: Int
        var warnings: [String]
        /// The piece's structuring time, its parts' times added.
        var millis: Int
    }

    /// The titles found by type size (`PageTitles.bigType`), and by the model (`TitleLister`) with
    /// how many it gave that weren't on the page; nil in a result from before M3-5s or when that way
    /// didn't run.
    var titlesBigType: [String]?
    var titlesModel: [String]?
    var titlesModelDropped: Int?
    /// With two or more titles, the capture cut by them and each piece structured on its own.
    var piecesBigType: [Piece]?
    var piecesModel: [Piece]?
}
