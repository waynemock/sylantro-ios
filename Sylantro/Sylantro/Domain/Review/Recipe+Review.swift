import Foundation

extension Recipe {
    /// Read, and not yet marked reviewed or edited: shown in Needs Review, with its flags
    /// (`15` M3-3, RV-8, RV-13).
    nonisolated var needsReview: Bool {
        extraction != nil && reviewState == .needsReview
    }
}
