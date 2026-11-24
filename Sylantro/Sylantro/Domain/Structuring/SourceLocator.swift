import Foundation

/// Where each ingredient and step is on the page (`15` M3-1): its text matched to a run of the
/// capture's readable lines, so review can show it on the photo (RV-11).
nonisolated enum SourceLocator {
    /// One readable line of a capture, in reading order, its box already on its page.
    nonisolated struct Line: Sendable, Equatable {
        var text: String
        var box: SourceBox
    }

    static let maximumIngredientRun = 4
    static let maximumStepRun = 15

    /// `recipe` with a `sourceBox` on every ingredient and step that has none and is found in
    /// `lines`. Nothing else changes.
    static func locate(_ recipe: Recipe, lines: [Line]) -> Recipe {
        var recipe = recipe

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
                  let found = find(step.text, in: lines, from: cursor, maximum: maximumStepRun) else {
                continue
            }
            recipe.steps[stepIndex].sourceBox = found.box
            cursor = found.next
        }
        return recipe
    }

    /// The first run of 1 to `maximum` lines on one page whose normalized text equals the
    /// normalized target (pass 1), else contains it (pass 2). Start lines are tried from `cursor`
    /// to the last, then from 0 to `cursor - 1`. The box is the run's union; `next` is the line
    /// after the run. Nil for an empty target or no match.
    private static func find(_ target: String, in lines: [Line], from cursor: Int,
                             maximum: Int) -> (box: SourceBox, next: Int)? {
        let normalizedTarget = TextMatch.normalize(target)
        guard !normalizedTarget.isEmpty, !lines.isEmpty else {
            return nil
        }
        let start = min(max(cursor, 0), lines.count)
        let order = Array(start..<lines.count) + Array(0..<start)

        for equals in [true, false] {
            for first in order {
                var last = first
                while last < lines.count, last - first < maximum, lines[last].box.pageID == lines[first].box.pageID {
                    let run = lines[first...last]
                    let text = TextMatch.normalize(run.map(\.text).joined(separator: "\n"))
                    if equals ? text == normalizedTarget : text.contains(normalizedTarget) {
                        return (union(run), last + 1)
                    }
                    last += 1
                }
            }
        }
        return nil
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
