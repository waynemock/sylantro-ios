import Foundation

/// A capture's lines split into sections by heading (`PageSplitter`).
nonisolated struct SplitPage: Equatable, Sendable {
    /// Lines before the first heading.
    var header: [String] = []
    var ingredients: [String] = []
    var steps: [String] = []
    var notes: [String] = []
    var equipment: [String] = []
    var nutrition: [String] = []
    /// Lines after the equipment section ended, up to the next heading (SLT-149).
    var unsectioned: [String] = []
    /// Both an ingredients heading and a steps heading were found, and both sections hold a line.
    var hasIngredientsAndSteps = false
}
