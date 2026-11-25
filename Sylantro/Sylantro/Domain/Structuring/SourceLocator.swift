import Foundation

/// Where the title and each ingredient and step are on the page (`15` M3-1, M3-3a): its text
/// matched to a run of the capture's readable lines, so review can show it on the photo (RV-11,
/// RV-31). A step that runs onto the next page is placed by its part on the first (RV-30); a title
/// or an ingredient stays within one page. Every other line she sees (the yield, times, notes,
/// nutrition, equipment, source lines and group names) is placed by its parts (RV-34, M3-3d).
nonisolated enum SourceLocator {
    /// One readable line of a capture, in reading order, its box already on its page.
    nonisolated struct Line: Sendable, Equatable {
        var text: String
        var box: SourceBox
    }

    static let maximumIngredientRun = 4
    static let maximumStepRun = 15
    static let maximumTitleRun = 3
    /// The most lines one part of a field (RV-34) runs over.
    static let maximumFieldPartRun = 4

    /// `recipe` with a `sourceBox` on every ingredient and step that has none and is found in
    /// `lines`, and its `titleBox` when it has none and its title isn't empty. Nothing else
    /// changes.
    static func locate(_ recipe: Recipe, lines: [Line]) -> Recipe {
        var recipe = recipe

        // The title: a run of 1 to 3 lines on one page equal to it, from the first line; never
        // one that only contains it, so a step that names the dish isn't taken (RV-31).
        if recipe.titleBox == nil, !recipe.title.isEmpty {
            recipe.titleBox = find(recipe.title, in: lines, from: 0, maximum: maximumTitleRun,
                                   equalsOnly: true)?.box
        }

        // Every other line she sees (RV-34): the yield, times, notes, nutrition, each equipment
        // item, each source line and each group's name, each by its parts.
        var fields: [(key: String, text: String?)] = [
            (Recipe.FieldBoxKey.yield, recipe.yield.flatMap(RecipeRendering.yieldLine)),
            (Recipe.FieldBoxKey.times, recipe.times.flatMap(RecipeRendering.timesLine)),
            (Recipe.FieldBoxKey.notes, recipe.notes),
            (Recipe.FieldBoxKey.nutrition, recipe.printedNutrition),
        ]
        for (index, item) in recipe.equipment.enumerated() {
            fields.append((Recipe.FieldBoxKey.equipment(index), item))
        }
        for (index, line) in RecipeRendering.sourceLines(recipe.attribution).enumerated() {
            fields.append((Recipe.FieldBoxKey.source(index), line))
        }
        for field in fields where recipe.fieldBoxes[field.key] == nil {
            if let text = field.text, let box = fieldBox(text, in: lines) {
                recipe.fieldBoxes[field.key] = box
            }
        }
        for groupIndex in recipe.ingredientGroups.indices where recipe.ingredientGroups[groupIndex].nameBox == nil {
            if let name = recipe.ingredientGroups[groupIndex].name, let box = fieldBox(name, in: lines) {
                recipe.ingredientGroups[groupIndex].nameBox = box
            }
        }

        // Ingredients: every group's, in recipe order, with one cursor.
        var cursor = 0
        for groupIndex in recipe.ingredientGroups.indices {
            for ingredientIndex in recipe.ingredientGroups[groupIndex].ingredients.indices {
                let ingredient = recipe.ingredientGroups[groupIndex].ingredients[ingredientIndex]
                guard ingredient.sourceBox == nil,
                      let found = find(ingredient.rawText, in: lines, from: cursor, maximum: maximumIngredientRun) else {
                    continue
                }
                recipe.ingredientGroups[groupIndex].ingredients[ingredientIndex].sourceBox = found.box
                cursor = found.next
            }
        }

        // Steps, with their own cursor.
        cursor = 0
        for stepIndex in recipe.steps.indices {
            let step = recipe.steps[stepIndex]
            guard step.sourceBox == nil,
                  let found = find(step.text, in: lines, from: cursor, maximum: maximumStepRun, crossingPages: true) else {
                continue
            }
            recipe.steps[stepIndex].sourceBox = found.box
            cursor = found.next
        }
        return recipe
    }

    /// The first run of 1 to `maximum` lines on one page whose normalized text equals the
    /// normalized target (pass 1), else contains it (pass 2; not with `equalsOnly`). Start lines
    /// are tried from `cursor` to the last, then from 0 to `cursor - 1`. With `crossingPages` (a
    /// step, RV-30, SP-22), only when no run on one page matches, the same passes over runs that
    /// continue from a page's last line onto the next page (two pages at most, still `maximum`
    /// lines in all). The box is the union of the run's lines on its first page; `next` is the
    /// line after the run. Nil for an empty target or no match.
    private static func find(_ target: String, in lines: [Line], from cursor: Int, maximum: Int,
                             equalsOnly: Bool = false, crossingPages: Bool = false) -> (box: SourceBox, next: Int)? {
        let normalizedTarget = TextMatch.normalize(target)
        guard !normalizedTarget.isEmpty, !lines.isEmpty else {
            return nil
        }
        let start = min(max(cursor, 0), lines.count)
        let order = Array(start..<lines.count) + Array(0..<start)
        let passes = equalsOnly ? [true] : [true, false]

        for crossesPage in crossingPages ? [false, true] : [false] {
            for equals in passes {
                for first in order {
                    var last = first
                    while last < lines.count, last - first < maximum {
                        let pages = Set(lines[first...last].map(\.box.pageID)).count
                        // One page, or (on the second round) exactly two.
                        guard pages <= (crossesPage ? 2 : 1) else { break }
                        if pages == (crossesPage ? 2 : 1) {
                            let run = lines[first...last]
                            let text = TextMatch.normalize(run.map(\.text).joined(separator: "\n"))
                            if equals ? text == normalizedTarget : text.contains(normalizedTarget) {
                                let firstPage = run.prefix { $0.box.pageID == lines[first].box.pageID }
                                return (union(firstPage), last + 1)
                            }
                        }
                        last += 1
                    }
                }
            }
        }
        return nil
    }

    /// A field's place (RV-34): its text split into parts at `;` and line breaks, trimmed, empty
    /// ones dropped; each part found as a run of up to `maximumFieldPartRun` lines (equal, else
    /// contains, as `find`); the union of the parts found on the first found part's page. Nil
    /// when no part is found.
    private static func fieldBox(_ text: String, in lines: [Line]) -> SourceBox? {
        let parts = text.split(whereSeparator: { $0 == ";" || $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let found = parts.compactMap { find($0, in: lines, from: 0, maximum: maximumFieldPartRun)?.box }
        guard let first = found.first else { return nil }
        let samePage = found.filter { $0.pageID == first.pageID }
        let lineBoxes = samePage.map { Line(text: "", box: $0) }
        return union(lineBoxes[...])
    }

    /// The smallest box holding every line's box, on the run's page.
    private static func union(_ run: ArraySlice<Line>) -> SourceBox {
        let boxes = run.map(\.box)
        let x = boxes.map(\.x).min() ?? 0
        let y = boxes.map(\.y).min() ?? 0
        let right = boxes.map { $0.x + $0.width }.max() ?? x
        let bottom = boxes.map { $0.y + $0.height }.max() ?? y
        return SourceBox(pageID: boxes[0].pageID, x: x, y: y, width: right - x, height: bottom - y)
    }
}
