import Foundation

/// Splits a capture's lines into sections by their headings (SLT-140), before the model sees them.
nonisolated enum PageSplitter {
    private nonisolated enum Section {
        case header, ingredients, steps, notes, equipment, nutrition
    }

    /// The headings, lowercase, compared after trimming and removing one trailing `:`.
    private static let headings: [String: Section] = [
        "ingredients": .ingredients, "ingredient": .ingredients, "what you need": .ingredients,
        "you will need": .ingredients, "you'll need": .ingredients, "you’ll need": .ingredients,
        "directions": .steps, "instructions": .steps, "method": .steps, "preparation": .steps,
        "steps": .steps, "how to make it": .steps, "procedure": .steps,
        "notes": .notes, "note": .notes, "recipe notes": .notes, "tips": .notes, "tip": .notes,
        "cook's tip": .notes, "cook’s tip": .notes,
        "equipment": .equipment, "tools": .equipment,
        "nutrition": .nutrition, "nutrition facts": .nutrition, "nutrition information": .nutrition,
    ]

    /// A leading bullet: one of these, followed by a space.
    private static let bullets: [Character] = ["•", "·", "-", "*"]

    /// `pages` holds each page's lines in reading order. A section runs on across a page break.
    static func split(_ pages: [[String]]) -> SplitPage {
        var result = SplitPage()
        var section = Section.header
        var foundIngredients = false
        var foundSteps = false

        for line in pages.joined() {
            if let heading = heading(line) {
                section = heading
                foundIngredients = foundIngredients || heading == .ingredients
                foundSteps = foundSteps || heading == .steps
                continue
            }
            switch section {
            case .header: result.header.append(line)
            case .ingredients: result.ingredients.append(removingBullet(line))
            case .steps: result.steps.append(removingBullet(line))
            case .notes: result.notes.append(removingBullet(line))
            case .equipment: result.equipment.append(removingBullet(line))
            case .nutrition: result.nutrition.append(removingBullet(line))
            }
        }
        result.hasIngredientsAndSteps = foundIngredients && foundSteps
        return result
    }

    private static func heading(_ line: String) -> Section? {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasSuffix(":") {
            text.removeLast()
        }
        return headings[text.lowercased()]
    }

    private static func removingBullet(_ line: String) -> String {
        let text = line.drop { $0.isWhitespace }
        guard let first = text.first, bullets.contains(first),
              text.dropFirst().first == " " else {
            return line
        }
        return String(text.dropFirst(2))
    }
}
