import Foundation
import SwiftData

extension ScanSessionModel {
    /// Sets every property from `value`.
    func hydrate(from value: ScanSession) {
        id = value.id
        startedAt = value.startedAt
        binderSection = value.binderSection
    }

    func toDomain() -> ScanSession? {
        ScanSession(id: id, startedAt: startedAt, binderSection: binderSection)
    }
}
