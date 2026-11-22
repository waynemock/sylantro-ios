import Foundation
import FoundationModels

/// What Foundation Models fills for one capture (`11` M1-3). Quantities and units are never asked
/// of the model: `IngredientLineParser` reads them from `rawText`.
@Generable
nonisolated struct GeneratedCapture {
    @Guide(description: "Every separate recipe on these pages, in page order. Usually one. A page from a magazine may hold several.")
    var recipes: [GeneratedRecipe]
}

/// One recipe as the model reads it.
@Generable
nonisolated struct GeneratedRecipe {
    @Guide(description: "The recipe's title exactly as printed. Empty if the pages show no title.")
    var title: String

    @Guide(description: "The yield or servings exactly as printed, such as 'Serves 4' or 'Makes about 1 1/4 cups'.")
    var yieldText: String?

    @Guide(description: "Prep, cook and total times exactly as printed.")
    var timesText: String?

    @Guide(description: "The ingredients, in printed order, grouped under their printed headings.")
    var ingredientGroups: [GeneratedGroup]

    @Guide(description: "The method's steps in printed order, each with its words unchanged.")
    var steps: [GeneratedStep]

    @Guide(description: "Tips, notes or serving suggestions printed apart from the steps.")
    var notes: String?

    @Guide(description: "The person credited for the recipe, if printed.")
    var author: String?

    @Guide(description: "The website or magazine, if printed.")
    var publisher: String?

    @Guide(description: "The web address printed on the page, if any.")
    var sourceURL: String?

    @Guide(description: "Items listed under an Equipment heading, if any.")
    var equipment: [String]

    @Guide(description: "Nutrition facts exactly as printed, if any.")
    var printedNutrition: String?
}

/// A run of ingredient lines under one heading.
@Generable
nonisolated struct GeneratedGroup {
    @Guide(description: "The group's printed heading, such as 'For the sauce'. Empty if none.")
    var name: String?

    @Guide(description: "The ingredient lines under it.")
    var lines: [GeneratedIngredient]
}

/// One ingredient line.
@Generable
nonisolated struct GeneratedIngredient {
    @Guide(description: "The whole ingredient line exactly as printed, with nothing added or corrected.")
    var rawText: String

    @Guide(description: "The food itself, such as 'flour'.")
    var item: String?

    @Guide(description: "How it is prepared, such as 'sifted' or 'chopped'.")
    var preparation: String?

    @Guide(description: "Any other note on the line, such as 'plus more to taste'.")
    var note: String?

    @Guide(description: "True only if the line says it is optional.")
    var isOptional: Bool
}

/// One method step.
@Generable
nonisolated struct GeneratedStep {
    @Guide(description: "The step's words exactly as printed.")
    var text: String

    @Guide(description: "The heading the step is printed under, if any.")
    var groupName: String?
}
