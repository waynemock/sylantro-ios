import Foundation
import SwiftData

/// An `ExtractionJob`, in the device-only store (`02` §5.1, `15` RV-2, RV-23): its own small
/// container, `"SylantroLocal"`, off CloudKit, opened by `ExtractionQueue`. Never synced, so it can
/// change freely; every property is defaulted all the same.
@Model final class ExtractionJobModel {
    var id: UUID = UUID()
    var recipeID: UUID = UUID()
    var scannedHere: Bool = false
    var attempts: Int = 0
    var lastError: String? = nil
    var notBefore: Date = Date()
    init() {}

    /// Sets every property from `value`.
    func hydrate(from value: ExtractionJob) {
        id = value.id
        recipeID = value.recipeID
        scannedHere = value.scannedHere
        attempts = value.attempts
        lastError = value.lastError
        notBefore = value.notBefore
    }

    /// The job.
    func toDomain() -> ExtractionJob? {
        ExtractionJob(id: id, recipeID: recipeID, scannedHere: scannedHere, attempts: attempts,
                      lastError: lastError, notBefore: notBefore)
    }
}
