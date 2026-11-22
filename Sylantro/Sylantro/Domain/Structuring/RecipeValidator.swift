import Foundation

/// The found-on-the-page check (SLT-142, extending SLT-042): every value the model returned is
/// looked for in the page's text. Values that aren't found are dropped or flagged, and an
/// ingredient that is a copied step is removed. Warnings go to `extraction.warnings`.
nonisolated enum RecipeValidator {
    /// An ingredient longer than this that matches a step is the copied method.
    private static let copiedStepLength = 60

    static func check(_ recipe: Recipe, pageText: String) -> Recipe {
        var recipe = recipe
        var warnings: [String] = []

        func found(_ value: String) -> Bool {
            TextMatch.contains(value, in: pageText)
        }

        /// A value that isn't on the page is removed, with a warning.
        func checked(_ value: String?, field: String) -> String? {
            guard let value, !value.isEmpty else {
                return value
            }
            if found(value) {
                return value
            }
            warnings.append("not on page: \(field)")
            return nil
        }

        // The title isn't checked: a snapped title is the page's own lines, and this page text has
        // clutter taken out, so a title printed there could be dropped (SLT-148).
        let stepTexts = recipe.steps.map { TextMatch.normalize($0.text) }
        var ingredientNumber = 0
        for groupIndex in recipe.ingredientGroups.indices {
            recipe.ingredientGroups[groupIndex].name = checked(recipe.ingredientGroups[groupIndex].name, field: "group name")
            var kept: [Ingredient] = []
            for ingredient in recipe.ingredientGroups[groupIndex].ingredients {
                ingredientNumber += 1
                let normalized = TextMatch.normalize(ingredient.rawText)
                if normalized.count > copiedStepLength,
                   stepTexts.contains(where: { $0 == normalized || $0.contains(normalized) }) {
                    warnings.append("ingredient \(ingredientNumber) is a step")
                    continue
                }
                if !found(ingredient.rawText) {
                    warnings.append("not on page: ingredient \(ingredientNumber)")
                }
                kept.append(ingredient)
            }
            recipe.ingredientGroups[groupIndex].ingredients = kept
        }

        for stepIndex in recipe.steps.indices {
            if !found(recipe.steps[stepIndex].text) {
                warnings.append("not on page: step \(stepIndex + 1)")
            }
            recipe.steps[stepIndex].groupName = checked(recipe.steps[stepIndex].groupName, field: "step group")
        }

        recipe.equipment = recipe.equipment.filter { item in
            checked(item, field: "equipment") != nil
        }
        recipe.notes = checked(recipe.notes, field: "notes")
        recipe.printedNutrition = checked(recipe.printedNutrition, field: "printed nutrition")
        if var attribution = recipe.attribution {
            attribution.author = checked(attribution.author, field: "author")
            attribution.publisher = checked(attribution.publisher, field: "publisher")
            recipe.attribution = attribution
        }

        if !warnings.isEmpty {
            var extraction = recipe.extraction ?? Extraction()
            extraction.warnings.append(contentsOf: warnings)
            recipe.extraction = extraction
        }
        return recipe
    }
}
