import Foundation

/// One recipe this device means to read and structure (`15` M3-2). Kept only in the device-only
/// store, never in a file, so it isn't `Codable`.
nonisolated struct ExtractionJob: Sendable, Equatable {
    var id: UUID
    /// One job per recipe on a device.
    var recipeID: UUID
    /// True when this device saved the capture or the added page (RV-3).
    var scannedHere: Bool
    /// Failed reads or structurings, not counting rate limits (RV-24).
    var attempts: Int
    /// The last failure's `String(describing:)`, for the log.
    var lastError: String?
    /// Not tried before this time.
    var notBefore: Date

    init(
        id: UUID = UUID(),
        recipeID: UUID,
        scannedHere: Bool = false,
        attempts: Int = 0,
        lastError: String? = nil,
        notBefore: Date = Date()
    ) {
        self.id = id
        self.recipeID = recipeID
        self.scannedHere = scannedHere
        self.attempts = attempts
        self.lastError = lastError
        self.notBefore = notBefore
    }
}
