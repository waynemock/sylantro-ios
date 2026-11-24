import Foundation

/// What she typed in review's Edit (`15` M3-3, RV-12, SC-10): the kitchen fields, to apply to a
/// recipe. The page's own words stay on the page (SLT-060); a changed ingredient line is parsed
/// again.
nonisolated struct ReviewEdit: Sendable, Equatable {
    /// An ingredient group's lines, in order.
    nonisolated struct Group: Sendable, Equatable {
        var id: UUID
        var name: String?
        var lines: [Line]
    }

    /// One ingredient line: an existing ingredient's id, or a new one.
    nonisolated struct Line: Sendable, Equatable {
        var id: UUID
        var text: String
    }

    /// One step: an existing step's id, or a new one.
    nonisolated struct StepLine: Sendable, Equatable {
        var id: UUID
        var text: String
    }

    /// One field she edits in a sheet (`15` M3-3b, SC-19).
    nonisolated enum Field: Sendable, Equatable, Hashable {
        case title
        case yield
        case notes
        case ingredient(UUID)
        case step(UUID)
    }

    var title: String
    var yieldText: String
    var groups: [Group]
    var steps: [StepLine]
    var notes: String

    /// The field's text in the edit; `""` for an id not in it.
    func text(for field: Field) -> String {
        switch field {
        case .title: title
        case .yield: yieldText
        case .notes: notes
        case .ingredient(let id): groups.lazy.flatMap(\.lines).first { $0.id == id }?.text ?? ""
        case .step(let id): steps.first { $0.id == id }?.text ?? ""
        }
    }

    /// The edit with the field's text replaced, nothing else changed; an id not in it changes
    /// nothing.
    func setting(_ text: String, for field: Field) -> ReviewEdit {
        var edit = self
        switch field {
        case .title:
            edit.title = text
        case .yield:
            edit.yieldText = text
        case .notes:
            edit.notes = text
        case .ingredient(let id):
            for groupIndex in edit.groups.indices {
                if let lineIndex = edit.groups[groupIndex].lines.firstIndex(where: { $0.id == id }) {
                    edit.groups[groupIndex].lines[lineIndex].text = text
                    return edit
                }
            }
        case .step(let id):
            if let index = edit.steps.firstIndex(where: { $0.id == id }) {
                edit.steps[index].text = text
            }
        }
        return edit
    }

    /// The edit without the field: an ingredient line or step removed by id (an emptied group
    /// stays; `applied` drops it), the title, yield or notes emptied.
    func removing(_ field: Field) -> ReviewEdit {
        var edit = self
        switch field {
        case .title, .yield, .notes:
            return setting("", for: field)
        case .ingredient(let id):
            for groupIndex in edit.groups.indices {
                edit.groups[groupIndex].lines.removeAll { $0.id == id }
            }
        case .step(let id):
            edit.steps.removeAll { $0.id == id }
        }
        return edit
    }

    /// The recipe's kitchen fields as she starts to edit them: each ingredient's `rawText`, the
    /// yield's printed text, the notes.
    static func from(_ recipe: Recipe) -> ReviewEdit {
        ReviewEdit(
            title: recipe.title,
            yieldText: recipe.yield?.rawText ?? "",
            groups: recipe.ingredientGroups.map { group in
                Group(id: group.id, name: group.name,
                      lines: group.ingredients.map { Line(id: $0.id, text: $0.rawText) })
            },
            steps: recipe.steps.map { StepLine(id: $0.id, text: $0.text) },
            notes: recipe.notes ?? ""
        )
    }

    /// `recipe` with these fields applied, marked edited (RV-13, SC-11): the title and notes
    /// trimmed; the yield's text, with servings read from "Serves"; ingredients and steps in the
    /// edit's order, an unchanged one kept as it is, a changed one parsed again, a new one made
    /// with no place on the page, and empty ones (and emptied groups) dropped; steps numbered from
    /// 1; step links to dropped ingredients removed. Pages, warning, extraction, tags, times,
    /// attribution, equipment and printed nutrition are untouched.
    func applied(to recipe: Recipe, now: Date) -> Recipe {
        var result = recipe
        result.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        result.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        result.yield = Self.appliedYield(yieldText, existing: recipe.yield)

        // Ingredients, by id across every group.
        var existingIngredients: [UUID: Ingredient] = [:]
        for ingredient in recipe.ingredientGroups.flatMap(\.ingredients) where existingIngredients[ingredient.id] == nil {
            existingIngredients[ingredient.id] = ingredient
        }
        result.ingredientGroups = groups.compactMap { group in
            let ingredients = group.lines.compactMap { line -> Ingredient? in
                let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                let existing = existingIngredients[line.id]
                if let existing, existing.rawText == text {
                    return existing
                }
                return Self.ingredient(id: line.id, text: text, keeping: existing)
            }
            return ingredients.isEmpty ? nil : IngredientGroup(id: group.id, name: group.name, ingredients: ingredients)
        }

        // Steps, by id, numbered from 1.
        var existingSteps: [UUID: Step] = [:]
        for step in recipe.steps where existingSteps[step.id] == nil {
            existingSteps[step.id] = step
        }
        let keptIngredientIDs = Set(result.ingredientGroups.flatMap(\.ingredients).map(\.id))
        let texts = steps.compactMap { line -> (id: UUID, text: String)? in
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : (line.id, text)
        }
        result.steps = texts.enumerated().map { offset, line in
            var step = existingSteps[line.id] ?? Step(id: line.id)
            step.index = offset + 1
            step.text = line.text
            step.ingredientIDs = step.ingredientIDs.filter { keptIngredientIDs.contains($0) }
            return step
        }

        result.reviewState = .edited
        result.updatedAt = now
        return result
    }

    /// The yield for `text`, trimmed: none when empty; otherwise its text, with servings its first
    /// whole number when it starts with "Serves" (any case). The rest of `existing` is kept when the
    /// text is unchanged and cleared when it changed.
    private static func appliedYield(_ text: String, existing: Yield?) -> Yield? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var result = (existing?.rawText == trimmed ? existing : nil) ?? Yield()
        result.rawText = trimmed
        if trimmed.lowercased().hasPrefix("serves"), let number = firstWholeNumber(in: trimmed) {
            result.servings = Quantity(min: Double(number))
        }
        return result
    }

    /// The first run of ASCII digits, as a number.
    private static func firstWholeNumber(in text: String) -> Int? {
        let digits = text.drop { !("0"..."9").contains($0) }.prefix { ("0"..."9").contains($0) }
        return Int(digits)
    }

    /// A line she typed, read by `IngredientLineParser`: its quantity, unit and the rest as the
    /// item; preparation, note and confidence cleared. A changed line keeps its id, its place on
    /// the page and its handwritten, unreadable and optional marks; a new one has none.
    private static func ingredient(id: UUID, text: String, keeping existing: Ingredient?) -> Ingredient {
        let parsed = IngredientLineParser.parse(text)
        let rest = parsed.rest.trimmingCharacters(in: .whitespacesAndNewlines)
        return Ingredient(
            id: id,
            rawText: text,
            quantity: parsed.quantity,
            unit: parsed.unit,
            item: rest.isEmpty ? nil : rest,
            preparation: nil,
            isOptional: existing?.isOptional ?? false,
            note: nil,
            sourceBox: existing?.sourceBox,
            confidence: nil,
            isHandwritten: existing?.isHandwritten ?? false,
            isUnreadable: existing?.isUnreadable ?? false
        )
    }
}
