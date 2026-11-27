import Foundation
import FoundationModels

/// What Foundation Models fills for each part of a recipe (SLT-140, `11` M1-4 and M1-5): the
/// header, the ingredient lines, the steps, and line labels for a page with no headings. The
/// ingredient lines are answered as line numbers, so their words come from the page (SLT-146); the
/// title is snapped to the page's lines (SLT-148).
@Generable
nonisolated struct GeneratedHeader {
    @Guide(description: "The recipe's title exactly as printed, all of its lines. Empty if none.")
    var title: String

    @Guide(description: "The person credited for the recipe, if printed.")
    var author: String?

    @Guide(description: "The website or magazine, if printed.")
    var publisher: String?

    @Guide(description: "Titles of any other separate recipes printed on these lines. Leave it empty when there is only one recipe.")
    var otherTitles: [String]?
}

/// The ingredients, in groups, as numbers of the lines they were read from.
@Generable
nonisolated struct GeneratedIngredientLines {
    @Guide(description: "The ingredients in printed order, grouped under their printed subheadings.")
    var groups: [GeneratedLineGroup]
}

/// One group of ingredients.
@Generable
nonisolated struct GeneratedLineGroup {
    @Guide(description: "The number of the group's printed subheading line, such as 'For the sauce'. 0 if none.")
    var nameLine: Int

    @Guide(description: "The ingredients under it.")
    var items: [GeneratedLineItem]
}

/// One ingredient, by its line numbers.
@Generable
nonisolated struct GeneratedLineItem {
    @Guide(description: "The number of the ingredient's first line.")
    var firstLine: Int

    @Guide(description: "The number of its last line, the same as the first unless the ingredient wraps onto the next line.")
    var lastLine: Int

    @Guide(description: "The food itself, such as 'flour'.")
    var item: String?

    @Guide(description: "How it is prepared, such as 'sifted' or 'chopped'.")
    var preparation: String?

    @Guide(description: "Any other note on the line, such as 'plus more to taste'.")
    var note: String?

    @Guide(description: "True only if the line says it is optional.")
    var isOptional: Bool?
}

/// The steps, as numbers of the lines they were read from, so their words come from the page
/// (`15` RV-39, M3-3j), as the ingredients' do (SLT-146).
@Generable
nonisolated struct GeneratedStepLines {
    @Guide(description: "The method steps in printed order, each as the numbers of its lines.")
    var steps: [GeneratedStepRange]
}

/// One step, by its line numbers.
@Generable
nonisolated struct GeneratedStepRange {
    @Guide(description: "The number of the step's first line.")
    var firstLine: Int

    @Guide(description: "The number of its last line, the same as the first if it fits on one line.")
    var lastLine: Int
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
