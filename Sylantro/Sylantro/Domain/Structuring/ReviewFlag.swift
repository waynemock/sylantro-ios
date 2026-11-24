import Foundation

/// One thing for her to check in review, named by its field (RV-10, `15` M3-1). Worked out from
/// `extraction.warnings` when shown, and never stored.
nonisolated struct ReviewFlag: Sendable, Equatable {
    nonisolated enum Field: Sendable, Equatable, Hashable {
        case recipe              // the whole recipe, shown at the top (RV-10)
        case title
        case ingredients         // the ingredient list as a whole
        case ingredient(UUID)
        case steps               // the steps as a whole
        case step(UUID)
        case notes
        case equipment
        case printedNutrition
        case attribution
    }

    nonisolated enum Kind: Sendable, Equatable, Hashable {
        case noTitle
        case titleFromLayout
        case notOnPage                     // kept, but not found on the page
        case droppedNotOnPage              // removed because not found on the page
        case ingredientWasStep
        case ingredientsFromWholePage
        case stepsFromWholePage
        case ingredientLinesUnsure
        case mayHoldOtherRecipes([String])
        case unreadableLine(page: Int)
        case continuesOnUnscannedPage
        case other(String)
    }

    var kind: Kind
    var field: Field

    /// The prefixes of warnings that carry a value after them.
    private static let notOnPageIngredient = "not on page: ingredient "
    private static let notOnPageStep = "not on page: step "
    private static let unusedIngredientLine = "unused ingredient line "
    private static let otherRecipes = "may hold other recipes: "
    private static let unreadableLine = "unreadable line on page "

    /// The warnings that name a dropped value, by field.
    private static let dropped: [String: Field] = [
        "not on page: group name": .ingredients,
        "not on page: step group": .steps,
        "not on page: equipment": .equipment,
        "not on page: notes": .notes,
        "not on page: printed nutrition": .printedNutrition,
        "not on page: author": .attribution,
        "not on page: publisher": .attribution,
    ]

    /// The warnings that mean the ingredient lines' numbers were unsure.
    private static let ingredientLinesUnsure: Set<String> = [
        "group name too long", "ingredient lines out of range", "ingredient line repeated",
    ]

    /// The recipe's flags: `continuesOnUnscannedPage` first when it is true, then one per
    /// warning in `extraction.warnings` order, by `15` M3-1's table, each (kind, field) pair once.
    static func flags(for recipe: Recipe) -> [ReviewFlag] {
        let warnings = recipe.extraction?.warnings ?? []
        let ingredientIDs = keptIngredientNumbers(recipe, warnings: warnings)

        var flags: [ReviewFlag] = []
        func add(_ flag: ReviewFlag) {
            if !flags.contains(flag) {
                flags.append(flag)
            }
        }

        if recipe.continuesOnUnscannedPage {
            add(ReviewFlag(kind: .continuesOnUnscannedPage, field: .recipe))
        }
        for warning in warnings {
            add(flag(for: warning, recipe: recipe, ingredientIDs: ingredientIDs))
        }
        return flags
    }

    /// One warning's flag, by `15` M3-1's table.
    private static func flag(for warning: String, recipe: Recipe, ingredientIDs: [Int: UUID]) -> ReviewFlag {
        if warning == "no title" {
            return ReviewFlag(kind: .noTitle, field: .title)
        }
        if warning == "title from layout" {
            return ReviewFlag(kind: .titleFromLayout, field: .title)
        }
        if let n = number(after: notOnPageIngredient, in: warning) {
            return ReviewFlag(kind: .notOnPage, field: ingredientIDs[n].map(Field.ingredient) ?? .ingredients)
        }
        if let n = number(after: notOnPageStep, in: warning) {
            let field: Field = recipe.steps.indices.contains(n - 1) ? .step(recipe.steps[n - 1].id) : .steps
            return ReviewFlag(kind: .notOnPage, field: field)
        }
        if let field = dropped[warning] {
            return ReviewFlag(kind: .droppedNotOnPage, field: field)
        }
        if copiedStepNumber(warning) != nil {
            return ReviewFlag(kind: .ingredientWasStep, field: .ingredients)
        }
        if warning == "ingredients from whole page" {
            return ReviewFlag(kind: .ingredientsFromWholePage, field: .ingredients)
        }
        if warning == "steps from whole page" {
            return ReviewFlag(kind: .stepsFromWholePage, field: .steps)
        }
        if ingredientLinesUnsure.contains(warning) || number(after: unusedIngredientLine, in: warning) != nil {
            return ReviewFlag(kind: .ingredientLinesUnsure, field: .ingredients)
        }
        if warning.hasPrefix(otherRecipes) {
            let titles = warning.dropFirst(otherRecipes.count).components(separatedBy: "; ")
            return ReviewFlag(kind: .mayHoldOtherRecipes(titles), field: .recipe)
        }
        if let page = number(after: unreadableLine, in: warning) {
            return ReviewFlag(kind: .unreadableLine(page: page), field: .recipe)
        }
        return ReviewFlag(kind: .other(warning), field: .recipe)
    }

    /// `RecipeValidator`'s ingredient numbers, from 1 across all groups before copied steps were
    /// removed, mapped to the kept ingredients: the removed numbers are every
    /// `ingredient n is a step`, and the kept ingredients, in recipe order, take the numbers from 1
    /// upward that were not removed.
    private static func keptIngredientNumbers(_ recipe: Recipe, warnings: [String]) -> [Int: UUID] {
        let removed = Set(warnings.compactMap(copiedStepNumber))
        var result: [Int: UUID] = [:]
        var number = 0
        for ingredient in recipe.ingredientGroups.flatMap(\.ingredients) {
            number += 1
            while removed.contains(number) {
                number += 1
            }
            result[number] = ingredient.id
        }
        return result
    }

    /// `n` in `ingredient n is a step`, or nil.
    private static func copiedStepNumber(_ warning: String) -> Int? {
        let prefix = "ingredient "
        let suffix = " is a step"
        guard warning.hasPrefix(prefix), warning.hasSuffix(suffix),
              warning.count > prefix.count + suffix.count else {
            return nil
        }
        return wholeNumber(String(warning.dropFirst(prefix.count).dropLast(suffix.count)))
    }

    /// The whole number that is all of `warning` after `prefix`, or nil.
    private static func number(after prefix: String, in warning: String) -> Int? {
        guard warning.hasPrefix(prefix) else {
            return nil
        }
        return wholeNumber(String(warning.dropFirst(prefix.count)))
    }

    /// The value of a non-empty run of ASCII digits, or nil.
    private static func wholeNumber(_ text: String) -> Int? {
        guard !text.isEmpty, text.allSatisfy({ ("0"..."9").contains($0) }) else {
            return nil
        }
        return Int(text)
    }
}
