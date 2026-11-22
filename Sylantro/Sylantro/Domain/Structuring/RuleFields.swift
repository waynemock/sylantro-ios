import Foundation

/// What `PageRules` finds on a capture's lines by rule, not by the model (SLT-143).
nonisolated struct RuleFields: Equatable, Sendable {
    var sourceURL: String?
    var yieldText: String?
    var timesText: String?
    var pageNumber: Int?
    var pageCount: Int?

    init(
        sourceURL: String? = nil,
        yieldText: String? = nil,
        timesText: String? = nil,
        pageNumber: Int? = nil,
        pageCount: Int? = nil
    ) {
        self.sourceURL = sourceURL
        self.yieldText = yieldText
        self.timesText = timesText
        self.pageNumber = pageNumber
        self.pageCount = pageCount
    }
}
