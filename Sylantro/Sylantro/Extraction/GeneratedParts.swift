import Foundation
import FoundationModels

/// What Foundation Models fills for each part of a recipe (SLT-140, `11` M1-4): the header, the
/// ingredient lines, the steps, and line labels for a page with no headings.
@Generable
nonisolated struct GeneratedHeader {
    @Guide(description: "The recipe's title exactly as printed, all of its lines. Empty if none.")
    var title: String

    @Guide(description: "The person credited for the recipe, if printed.")
    var author: String?

    @Guide(description: "The website or magazine, if printed.")
    var publisher: String?

    @Guide(description: "Titles of any other separate recipes on these pages. Usually empty.")
    var otherTitles: [String]
}

/// The ingredient lines, in groups.
@Generable
nonisolated struct GeneratedIngredientPart {
    @Guide(description: "The ingredient lines in printed order, grouped under their printed subheadings. Join a line that wraps onto the next line.")
    var groups: [GeneratedGroup]
}

/// The steps.
@Generable
nonisolated struct GeneratedStepPart {
    @Guide(description: "The steps in printed order, each with its words unchanged.")
    var steps: [GeneratedStep]
}

/// A label for each numbered line of a page with no headings.
@Generable
nonisolated struct GeneratedLineLabels {
    @Guide(description: "One label for every numbered line.")
    var labels: [GeneratedLineLabel]
}

/// One numbered line's label.
@Generable
nonisolated struct GeneratedLineLabel {
    @Guide(description: "The line's number.")
    var line: Int

    @Guide(description: "What the line is: part of the title area, an ingredient, a step, a note, or anything else.",
           .anyOf(["header", "ingredient", "step", "note", "other"]))
    var kind: String
}
