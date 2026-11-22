import Foundation

/// Splits a capture's lines into sections by their headings (SLT-140), before the model sees them.
/// Page clutter goes to no section, and the equipment section ends where the method starts
/// (SLT-149).
nonisolated enum PageSplitter {
    nonisolated enum Section {
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

    /// An equipment line longer than this is a sentence, so the equipment section has ended.
    private static let equipmentMaximumLength = 40

    /// `pages` holds each page's lines in reading order. A section runs on across a page break.
    static func split(_ pages: [[String]]) -> SplitPage {
        var result = SplitPage()
        var section = Section.header
        var foundIngredients = false
        var foundSteps = false
        // Set once an equipment section has ended; its later lines are unsectioned.
        var equipmentEnded = false

        for line in pages.joined() {
            if let heading = heading(line) {
                section = heading
                equipmentEnded = false
                foundIngredients = foundIngredients || heading == .ingredients
                foundSteps = foundSteps || heading == .steps
                continue
            }
            if PageClutter.isClutter(line) {
                continue
            }
            switch section {
            case .header: result.header.append(line)
            case .ingredients: result.ingredients.append(removingBullet(line))
            case .steps: result.steps.append(removingBullet(line))
            case .notes: result.notes.append(removingBullet(line))
            case .equipment:
                let text = removingBullet(line)
                equipmentEnded = equipmentEnded || endsEquipment(text)
                if equipmentEnded {
                    result.unsectioned.append(text)
                } else {
                    result.equipment.append(text)
                }
            case .nutrition: result.nutrition.append(removingBullet(line))
            }
        }
        // A heading whose section holds no line counts as not found (SLT-147).
        result.hasIngredientsAndSteps = foundIngredients && foundSteps
            && !result.ingredients.isEmpty && !result.steps.isEmpty
        return result
    }

    /// A line that starts with digits and `.` or `)`, is longer than 40 characters, or ends with
    /// `.`: a step or a sentence, not equipment.
    private static func endsEquipment(_ text: String) -> Bool {
        let digits = text.prefix { ("0"..."9").contains($0) }
        if !digits.isEmpty, let next = text.dropFirst(digits.count).first, next == "." || next == ")" {
            return true
        }
        return text.count > equipmentMaximumLength || text.hasSuffix(".")
    }

    /// The section a heading line starts, or nil when the line is not a heading.
    static func heading(_ line: String) -> Section? {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasSuffix(":") {
            text.removeLast()
        }
        return headings[text.lowercased()]
    }

    /// The line without a leading bullet and its space; the line unchanged when it has none.
    static func removingBullet(_ line: String) -> String {
        let text = line.drop { $0.isWhitespace }
        guard let first = text.first, bullets.contains(first),
              text.dropFirst().first == " " else {
            return line
        }
        return String(text.dropFirst(2))
    }
}
