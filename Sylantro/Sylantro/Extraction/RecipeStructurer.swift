import Foundation
import FoundationModels

/// What `RecipeStructurer.structure` made of one capture, and how.
nonisolated struct StructuringOutcome: Sendable {
    var recipes: [Recipe]
    /// `parts` or `oneShot`.
    var path: String
    /// Each model call's wall-clock time, keyed by part.
    var partMillis: [String: Int]
    var usedLineLabels: Bool
    /// A part that threw, keyed by part: its error's `String(describing:)`.
    var partErrors: [String: String]
}

/// Structures a capture's text into `Recipe`s with Foundation Models, on the device (SLT-040), in
/// parts (SLT-140): the page is split by its headings (or by line labels), then the model is asked
/// separately for the header, the ingredients and the steps, each call greedy and capped (SLT-141).
/// Yield, times and the URL come from `PageRules`, notes, equipment and nutrition from their
/// sections (SLT-143); quantities and units from `IngredientLineParser`. Every recipe is checked
/// against the page by `RecipeValidator` (SLT-142). No retries in the spike; a rate-limit refusal
/// propagates so the caller can wait (SLT-144).
nonisolated struct RecipeStructurer: Sendable {
    static let instructions = "You turn the text of printed recipe pages into structured recipes. Copy words exactly as they appear. Never add, correct or guess anything that is not in the text. Leave out web page clutter, advertisements, ratings, navigation links and page footers."

    static let pageSeparator = "\n\n--- next page ---\n\n"

    /// Each call's maximum response length (SLT-141).
    enum TokenCap {
        static let header = 300
        static let lineLabels = 1_200
        static let ingredients = 1_500
        static let steps = 2_000
        static let oneShot = 2_500
    }

    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// Whether `error` is the model's rate-limit refusal, the old type or iOS 27's.
    static func isRateLimit(_ error: any Error) -> Bool {
        if case LanguageModelSession.GenerationError.rateLimited = error {
            return true
        }
        if #available(iOS 27.0, *), let error = error as? LanguageModelError, case .rateLimited = error {
            return true
        }
        return false
    }

    func structure(_ readings: [PageReading], pageIDs: [UUID]) async throws -> StructuringOutcome {
        var outcome = StructuringOutcome(recipes: [], path: "parts", partMillis: [:], usedLineLabels: false, partErrors: [:])

        // 1. Lines, sections and rule fields.
        let pages = readings.map { $0.lines.map(\.text) }
        let allLines = Array(pages.joined())
        let pageText = allLines.joined(separator: "\n")
        var split = PageSplitter.split(pages)
        let rules = PageRules.find(in: allLines)

        // 2. Line labels, when the page lacks an ingredients or a steps heading.
        if !split.hasIngredientsAndSteps {
            outcome.usedLineLabels = true
            let prompt = allLines.enumerated().map { "\($0.offset + 1): \($0.element)" }.joined(separator: "\n")
            if let labels = try await call("lineLabels", prompt: prompt, generating: GeneratedLineLabels.self,
                                            cap: TokenCap.lineLabels, outcome: &outcome) {
                split = Self.labelled(allLines, labels: labels, keeping: split)
            }
        }

        // 3. The header; several recipes take the one-shot call (SLT-047).
        var header: GeneratedHeader?
        if !split.header.isEmpty {
            header = try await call("header", prompt: split.header.joined(separator: "\n"), generating: GeneratedHeader.self,
                                    cap: TokenCap.header, outcome: &outcome)
        }
        if let header, !header.otherTitles.isEmpty {
            outcome.path = "oneShot"
            let prompt = readings.map(\.text).joined(separator: Self.pageSeparator)
            let start = ContinuousClock.now
            let capture = try await Self.respond(to: prompt, generating: GeneratedCapture.self, cap: TokenCap.oneShot)
            outcome.partMillis["oneShot"] = Self.millis(since: start)
            outcome.recipes = capture.recipes.map {
                RecipeValidator.check(Self.makeRecipe(from: $0, pageIDs: pageIDs), pageText: pageText)
            }
            return outcome
        }

        // 4. The ingredients and the steps; a part with no lines is skipped.
        var ingredients: GeneratedIngredientPart?
        if !split.ingredients.isEmpty {
            ingredients = try await call("ingredients", prompt: split.ingredients.joined(separator: "\n"),
                                         generating: GeneratedIngredientPart.self, cap: TokenCap.ingredients, outcome: &outcome)
        }
        var steps: GeneratedStepPart?
        if !split.steps.isEmpty {
            steps = try await call("steps", prompt: split.steps.joined(separator: "\n"),
                                   generating: GeneratedStepPart.self, cap: TokenCap.steps, outcome: &outcome)
        }

        // 5 and 6. Assemble, then check against the page.
        let recipe = Self.assemble(header: header, ingredients: ingredients, steps: steps,
                                   split: split, rules: rules, pageIDs: pageIDs)
        outcome.recipes = [RecipeValidator.check(recipe, pageText: pageText)]
        return outcome
    }

    /// One part's call, timed. A rate-limit refusal is rethrown; any other error is recorded in
    /// `partErrors` and the part contributes nothing.
    private func call<Content: Generable>(
        _ part: String,
        prompt: String,
        generating type: Content.Type,
        cap: Int,
        outcome: inout StructuringOutcome
    ) async throws -> Content? {
        let start = ContinuousClock.now
        do {
            let content = try await Self.respond(to: prompt, generating: type, cap: cap)
            outcome.partMillis[part] = Self.millis(since: start)
            return content
        } catch where Self.isRateLimit(error) {
            throw error
        } catch {
            outcome.partMillis[part] = Self.millis(since: start)
            outcome.partErrors[part] = String(describing: error)
            return nil
        }
    }

    /// A new session with M1-3's instructions, greedy and capped.
    private static func respond<Content: Generable>(to prompt: String, generating type: Content.Type, cap: Int) async throws -> Content {
        let session = LanguageModelSession(instructions: instructions)
        let options = GenerationOptions(samplingMode: .greedy, maximumResponseTokens: cap)
        return try await session.respond(to: prompt, generating: type, options: options).content
    }

    /// The sections the line labels give: `header`, `ingredient`, `step` and `note` lines; `other`
    /// and unlabelled lines are dropped. Equipment and nutrition stay as the headings found them.
    private static func labelled(_ lines: [String], labels: GeneratedLineLabels, keeping split: SplitPage) -> SplitPage {
        var kinds: [Int: String] = [:]
        for label in labels.labels where kinds[label.line] == nil {
            kinds[label.line] = label.kind
        }
        var result = SplitPage(equipment: split.equipment, nutrition: split.nutrition, hasIngredientsAndSteps: split.hasIngredientsAndSteps)
        for (offset, line) in lines.enumerated() {
            switch kinds[offset + 1] {
            case "header": result.header.append(line)
            case "ingredient": result.ingredients.append(line)
            case "step": result.steps.append(line)
            case "note": result.notes.append(line)
            default: break
            }
        }
        return result
    }

    /// The parts as one `Recipe`, needing review. Title, author and publisher from the header; the
    /// URL, yield and times from `rules`; notes, equipment and nutrition from their sections.
    static func assemble(
        header: GeneratedHeader?,
        ingredients: GeneratedIngredientPart?,
        steps: GeneratedStepPart?,
        split: SplitPage,
        rules: RuleFields,
        pageIDs: [UUID]
    ) -> Recipe {
        let author = nonEmpty(header?.author)
        let publisher = nonEmpty(header?.publisher)
        let sourceURL = nonEmpty(rules.sourceURL)
        let attribution = (author == nil && publisher == nil && sourceURL == nil)
            ? nil
            : Attribution(author: author, publisher: publisher, sourceURL: sourceURL)

        return Recipe(
            title: header?.title ?? "",
            yield: nonEmpty(rules.yieldText).map { Yield(rawText: $0) },
            times: nonEmpty(rules.timesText).map { Times(rawText: $0) },
            ingredientGroups: (ingredients?.groups ?? []).map(makeGroup),
            steps: makeSteps(steps?.steps ?? []),
            notes: split.notes.isEmpty ? nil : split.notes.joined(separator: "\n"),
            attribution: attribution,
            printedNutrition: split.nutrition.isEmpty ? nil : split.nutrition.joined(separator: "\n"),
            equipment: split.equipment,
            sourcePageIDs: pageIDs,
            reviewState: .needsReview,
            extraction: Extraction(promptVersion: 2)
        )
    }

    /// M1-3's one-shot reading as a `Recipe`, needing review. Empty strings are nil.
    static func makeRecipe(from generated: GeneratedRecipe, pageIDs: [UUID]) -> Recipe {
        let author = nonEmpty(generated.author)
        let publisher = nonEmpty(generated.publisher)
        let sourceURL = nonEmpty(generated.sourceURL)
        let attribution = (author == nil && publisher == nil && sourceURL == nil)
            ? nil
            : Attribution(author: author, publisher: publisher, sourceURL: sourceURL)

        return Recipe(
            title: generated.title,
            yield: nonEmpty(generated.yieldText).map { Yield(rawText: $0) },
            times: nonEmpty(generated.timesText).map { Times(rawText: $0) },
            ingredientGroups: generated.ingredientGroups.map(makeGroup),
            steps: makeSteps(generated.steps),
            notes: nonEmpty(generated.notes),
            attribution: attribution,
            printedNutrition: nonEmpty(generated.printedNutrition),
            equipment: generated.equipment,
            sourcePageIDs: pageIDs,
            reviewState: .needsReview,
            extraction: Extraction(modelID: nil, promptVersion: 1, extractedAt: nil)
        )
    }

    /// A group, its quantities and units from `IngredientLineParser` on each `rawText`.
    private static func makeGroup(_ group: GeneratedGroup) -> IngredientGroup {
        IngredientGroup(name: nonEmpty(group.name), ingredients: group.lines.map { line in
            let parsed = IngredientLineParser.parse(line.rawText)
            return Ingredient(
                rawText: line.rawText,
                quantity: parsed.quantity,
                unit: parsed.unit,
                item: nonEmpty(line.item),
                preparation: nonEmpty(line.preparation),
                isOptional: line.isOptional,
                note: nonEmpty(line.note)
            )
        })
    }

    /// Steps indexed from 0.
    private static func makeSteps(_ steps: [GeneratedStep]) -> [Step] {
        steps.enumerated().map { index, step in
            Step(index: index, text: step.text, groupName: nonEmpty(step.groupName))
        }
    }

    private static func nonEmpty(_ text: String?) -> String? {
        guard let text, !text.isEmpty else {
            return nil
        }
        return text
    }

    private static func millis(since start: ContinuousClock.Instant) -> Int {
        let (seconds, attoseconds) = (ContinuousClock.now - start).components
        return Int(seconds * 1000 + attoseconds / 1_000_000_000_000_000)
    }
}
