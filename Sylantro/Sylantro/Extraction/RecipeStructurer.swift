import Foundation
import FoundationModels

/// What `RecipeStructurer.structure` made of one capture, and how.
nonisolated struct StructuringOutcome: Sendable {
    var recipes: [Recipe]
    /// Always `parts` (SLT-151).
    var path: String
    /// Each part's wall-clock time, a retry's added in, keyed by part.
    var partMillis: [String: Int]
    var usedLineLabels: Bool
    /// A part that threw, keyed by part (`<part> retry` for its retry): the error's
    /// `String(describing:)`.
    var partErrors: [String: String]
    /// The parts that were asked a second time (SLT-147).
    var retried: [String]
    /// The parts that were asked over the whole page (SLT-147).
    var fallbacks: [String]
    /// The title step 3 chose; nil until the header step is reached.
    var headerTitle: String?
    /// The header answer's title as the model wrote it; nil with no header answer.
    var modelTitle: String?
    /// The header answer's `otherTitles`, as returned.
    var otherTitles: [String]
    /// The lines the header step showed the model, with their sizes (`15` M3-1).
    var headerArea: [HeaderArea.HeaderLine]
}

/// Structuring failed with something other than a rate limit. It carries what was learned before
/// the failure, so the spike's file can show it (`11` M1-9).
nonisolated struct StructuringFailed: Error, CustomStringConvertible {
    let outcome: StructuringOutcome
    let underlying: any Error

    var description: String {
        String(describing: underlying)
    }
}

/// Structures a capture's text into `Recipe`s with Foundation Models, on the device (SLT-040), in
/// parts (SLT-140): the page is split by its headings (or by line labels), then the model is asked
/// separately for the header, the ingredients and the steps, each call greedy and capped (SLT-141).
/// The ingredient lines are the page's own lines, wraps joined by rule and chosen by number
/// (SLT-146); the title is the model's text snapped to the page's lines (SLT-148). A part that fails is retried with double its cap, and the ingredients and steps fall
/// back to the whole page (SLT-147). Lines in non-Latin letters are unreadable areas (SLT-150).
/// Yield, times and the URL come from `PageRules`, notes, equipment and nutrition from their
/// sections (SLT-143, SLT-149); quantities and units from `IngredientLineParser`. Every recipe is
/// checked against the page by `RecipeValidator` (SLT-142). A page that may hold other recipes is
/// flagged and still structured in parts (SLT-151). A rate-limit refusal propagates so the caller
/// can wait (SLT-144); any other failure is thrown as `StructuringFailed`.
nonisolated struct RecipeStructurer: Sendable {
    static let instructions = "You turn the text of printed recipe pages into structured recipes. Copy words exactly as they appear. Never add, correct or guess anything that is not in the text. Leave out web page clutter, advertisements, ratings, navigation links and page footers."

    static let headerPromptIntro = "Lines from the top of the page, with each line's text size compared with the page's usual text (1.0):"

    static let ingredientsPromptIntro = "The ingredient lines of a recipe, numbered:"

    /// Each call's maximum response length (SLT-141). A retry doubles it (SLT-147).
    enum TokenCap {
        static let header = 300
        /// At least this; more for a long page (`lineLabels(forLineCount:)`).
        static let lineLabels = 1_200
        static let ingredients = 1_500
        static let steps = 2_000

        /// `max(1_200, 16 × line count + 200)`.
        static func lineLabels(forLineCount count: Int) -> Int {
            max(lineLabels, 16 * count + 200)
        }
    }

    /// An item spanning more lines than this is out of range.
    static let maximumItemLines = 3
    /// A group name longer than this is not used.
    static let maximumGroupNameLength = 40

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
        var outcome = StructuringOutcome(recipes: [], path: "parts", partMillis: [:], usedLineLabels: false,
                                         partErrors: [:], retried: [], fallbacks: [], headerTitle: nil, modelTitle: nil, otherTitles: [],
                                         headerArea: [])
        do {
            try await structure(readings, pageIDs: pageIDs, into: &outcome)
            return outcome
        } catch where Self.isRateLimit(error) {
            throw error
        } catch {
            throw StructuringFailed(outcome: outcome, underlying: error)
        }
    }

    /// The steps of `structure`, filling `outcome` as they go so a failure keeps what was learned.
    private func structure(_ readings: [PageReading], pageIDs: [UUID], into outcome: inout StructuringOutcome) async throws {
        var warnings: [String] = []

        // 1. Lines. A line in non-Latin letters is taken out as an unreadable area (SLT-150).
        var unreadableAreas: [SourceBox] = []
        var pageLines: [[PageReading.ReadLine]] = []
        for (pageIndex, reading) in readings.enumerated() {
            var kept: [PageReading.ReadLine] = []
            for line in reading.lines {
                if ScriptCheck.isLatin(line.text) {
                    kept.append(line)
                } else if pageIndex < pageIDs.count {
                    unreadableAreas.append(SourceBox(pageID: pageIDs[pageIndex], x: line.box.x, y: line.box.y,
                                                     width: line.box.width, height: line.box.height))
                    warnings.append("unreadable line on page \(pageIndex + 1)")
                } else {
                    warnings.append("unreadable line on page \(pageIndex + 1)")
                }
            }
            pageLines.append(kept)
        }
        let pages = pageLines.map { $0.map(\.text) }
        let allLines = Array(pages.joined())
        let pageText = allLines.joined(separator: "\n")
        // The same lines less page clutter, so a step split by a footer is found (RV-30).
        let clutterFreeText = allLines.filter { !PageClutter.isClutter($0) }.joined(separator: "\n")
        var split = PageSplitter.split(pages)
        let rules = PageRules.find(in: allLines)

        // 2. Line labels, when the page lacks an ingredients or a steps section.
        var stopAt: Int?
        if !split.hasIngredientsAndSteps {
            outcome.usedLineLabels = true
            if let labels = try await call("lineLabels", prompt: Self.numbered(allLines), generating: GeneratedLineLabels.self,
                                            cap: TokenCap.lineLabels(forLineCount: allLines.count), outcome: &outcome) {
                split = Self.labelled(allLines, labels: labels, keeping: split)
                stopAt = labels.labels
                    .filter { $0.kind == "ingredient" || $0.kind == "step" }
                    .map { $0.line - 1 }
                    .filter { $0 >= 0 }
                    .min()
            }
        }

        // 3. The header, from the top of page 1 with each line's size (SLT-148).
        let firstPage = (pageLines.first ?? []).map { (text: $0.text, height: $0.box.height) }
        let area = HeaderArea.lines(firstPage, stopAt: stopAt)
        outcome.headerArea = area
        var header: GeneratedHeader?
        if !area.isEmpty {
            header = try await call("header", prompt: Self.headerPrompt(area), generating: GeneratedHeader.self,
                                    cap: TokenCap.header, outcome: &outcome)
        }
        // The model's title, snapped to the page's lines; else the largest line, flagged (SLT-148).
        let snapped = HeaderArea.snappedTitle(header?.title ?? "", area: area, author: header?.author,
                                              sourceHost: HeaderArea.host(of: rules.sourceURL))
        let title = snapped.title
        if title.isEmpty {
            warnings.append("no title")
        } else if !snapped.snapped {
            warnings.append("title from layout")
        }
        outcome.modelTitle = header?.title
        outcome.headerTitle = title
        outcome.otherTitles = header?.otherTitles ?? []
        // A page that may hold other recipes is flagged for review, and still structured in parts
        // (SLT-151).
        if let warning = Self.otherRecipesWarning(Self.otherRecipeTitles(header?.otherTitles, title: title, lines: allLines)) {
            warnings.append(warning)
        }

        // 4. The ingredients, as line numbers into their section's lines, wraps joined first (SLT-146).
        var ingredientGroups: [IngredientGroup]?
        let ingredientLines = WrapJoiner.join(split.ingredients)
        if !split.ingredients.isEmpty,
           let part = try await call("ingredients", prompt: Self.ingredientsPrompt(ingredientLines),
                                     generating: GeneratedIngredientLines.self, cap: TokenCap.ingredients, outcome: &outcome) {
            let mapped = Self.ingredientGroups(from: part, lines: ingredientLines)
            ingredientGroups = mapped.groups
            warnings.append(contentsOf: mapped.warnings)
        }

        // 5. The steps.
        var steps: GeneratedStepPart?
        if !split.steps.isEmpty {
            steps = try await call("steps", prompt: split.steps.joined(separator: "\n"),
                                   generating: GeneratedStepPart.self, cap: TokenCap.steps, outcome: &outcome)
        }

        // 6. A part still missing is asked over every readable line, not retried (SLT-147).
        if ingredientGroups == nil || split.ingredients.isEmpty {
            outcome.fallbacks.append("ingredients")
            let joinedLines = WrapJoiner.join(allLines)
            if let part = try await call("ingredients fallback", prompt: Self.ingredientsPrompt(joinedLines),
                                         generating: GeneratedIngredientLines.self, cap: TokenCap.ingredients,
                                         retrying: false, outcome: &outcome) {
                let mapped = Self.ingredientGroups(from: part, lines: joinedLines)
                ingredientGroups = mapped.groups
                warnings.append("ingredients from whole page")
                warnings.append(contentsOf: Self.fallbackWarnings(mapped.warnings))
            }
        }
        if steps == nil || split.steps.isEmpty {
            outcome.fallbacks.append("steps")
            if let part = try await call("steps fallback", prompt: allLines.joined(separator: "\n"),
                                         generating: GeneratedStepPart.self, cap: TokenCap.steps,
                                         retrying: false, outcome: &outcome) {
                steps = part
                warnings.append("steps from whole page")
            }
        }

        // 7 and 8. Assemble, check against the readable lines, then place each ingredient and step
        // on its page (`15` M3-1).
        let recipe = Self.assemble(title: title, header: header,
                                   ingredientGroups: ingredientGroups ?? [], steps: steps, split: split, rules: rules,
                                   pageIDs: pageIDs, unreadableAreas: unreadableAreas, warnings: warnings)
        let checked = RecipeValidator.check(recipe, pageText: pageText, clutterFreeText: clutterFreeText)
        outcome.recipes = [SourceLocator.locate(checked, lines: Self.locatorLines(pageLines, pageIDs: pageIDs))]
    }

    /// Every readable line but page clutter (RV-30), in page then reading order, its box on its
    /// page. A page with no page ID adds no lines. Not private, so a test can place a step across
    /// a page's footer.
    static func locatorLines(_ pageLines: [[PageReading.ReadLine]], pageIDs: [UUID]) -> [SourceLocator.Line] {
        var lines: [SourceLocator.Line] = []
        for (pageIndex, page) in pageLines.enumerated() where pageIndex < pageIDs.count {
            for line in page where !PageClutter.isClutter(line.text) {
                lines.append(SourceLocator.Line(text: line.text, box: SourceBox(
                    pageID: pageIDs[pageIndex], x: line.box.x, y: line.box.y,
                    width: line.box.width, height: line.box.height
                )))
            }
        }
        return lines
    }

    /// The ingredients fallback's warnings, less its `unused ingredient line ` ones: asked over the
    /// whole page, every line that isn't an ingredient is unused (`11` §1).
    static func fallbackWarnings(_ warnings: [String]) -> [String] {
        warnings.filter { !$0.hasPrefix("unused ingredient line ") }
    }

    /// `may hold other recipes: ` and the titles joined with `; `, or nil when there are none
    /// (SLT-151).
    static func otherRecipesWarning(_ titles: [String]) -> String? {
        titles.isEmpty ? nil : "may hold other recipes: " + titles.joined(separator: "; ")
    }

    /// One part's call, timed. A rate-limit refusal is rethrown. Any other error is recorded in
    /// `partErrors[part]` and, when `retrying`, the part is asked once more with double the cap,
    /// a second error going in `partErrors["<part> retry"]`. Nil when the part gave nothing.
    private func call<Content: Generable>(
        _ part: String,
        prompt: String,
        generating type: Content.Type,
        cap: Int,
        retrying: Bool = true,
        outcome: inout StructuringOutcome
    ) async throws -> Content? {
        let start = ContinuousClock.now
        defer {
            outcome.partMillis[part] = Self.millis(since: start)
        }
        do {
            return try await Self.respond(to: prompt, generating: type, cap: cap)
        } catch where Self.isRateLimit(error) {
            throw error
        } catch {
            outcome.partErrors[part] = String(describing: error)
        }
        guard retrying else {
            return nil
        }
        outcome.retried.append(part)
        do {
            return try await Self.respond(to: prompt, generating: type, cap: cap * 2)
        } catch where Self.isRateLimit(error) {
            throw error
        } catch {
            outcome.partErrors["\(part) retry"] = String(describing: error)
            return nil
        }
    }

    /// A new session with M1-3's instructions, greedy and capped.
    private static func respond<Content: Generable>(to prompt: String, generating type: Content.Type, cap: Int) async throws -> Content {
        let session = LanguageModelSession(instructions: instructions)
        let options = GenerationOptions(samplingMode: .greedy, maximumResponseTokens: cap)
        return try await session.respond(to: prompt, generating: type, options: options).content
    }

    // MARK: Prompts

    /// Each line as `<n>: <text>`, numbered from 1. Not private: the spike's `TitleLister` numbers
    /// lines the same way (`15` M3-5s).
    static func numbered(_ lines: [String]) -> String {
        lines.enumerated().map { "\($0.offset + 1): \($0.element)" }.joined(separator: "\n")
    }

    private static func headerPrompt(_ area: [HeaderArea.HeaderLine]) -> String {
        let lines = area.enumerated().map { "\($0.offset + 1) [size \($0.element.size)]: \($0.element.text)" }
        return headerPromptIntro + "\n" + lines.joined(separator: "\n")
    }

    private static func ingredientsPrompt(_ lines: [String]) -> String {
        ingredientsPromptIntro + "\n" + numbered(lines)
    }

    /// The sections the line labels give: `header`, `ingredient`, `step` and `note` lines; `other`,
    /// unlabelled, clutter and heading lines are dropped, and bullets are removed from ingredient,
    /// step and note lines, as in headed sections (SLT-149). Equipment and nutrition stay as the
    /// headings found them.
    static func labelled(_ lines: [String], labels: GeneratedLineLabels, keeping split: SplitPage) -> SplitPage {
        var kinds: [Int: String] = [:]
        for label in labels.labels where kinds[label.line] == nil {
            kinds[label.line] = label.kind
        }
        var result = SplitPage(equipment: split.equipment, nutrition: split.nutrition,
                               unsectioned: split.unsectioned, hasIngredientsAndSteps: split.hasIngredientsAndSteps)
        for (offset, line) in lines.enumerated() where !PageClutter.isClutter(line) && PageSplitter.heading(line) == nil {
            switch kinds[offset + 1] {
            case "header": result.header.append(line)
            case "ingredient": result.ingredients.append(PageSplitter.removingBullet(line))
            case "step": result.steps.append(PageSplitter.removingBullet(line))
            case "note": result.notes.append(PageSplitter.removingBullet(line))
            default: break
            }
        }
        return result
    }

    // MARK: Mapping

    /// The other recipes' titles the header names that are really on the page (SLT-151): not an
    /// empty answer, not the recipe's own title, and a whole line of `lines`, all compared
    /// normalized. Duplicates are removed; order is kept.
    static func otherRecipeTitles(_ titles: [String]?, title: String, lines: [String]) -> [String] {
        let ownTitle = TextMatch.normalize(title)
        let pageLines = Set(lines.map(TextMatch.normalize))
        var seen = Set<String>()
        var result: [String] = []
        for candidate in titles ?? [] where !TextMatch.isEmptyAnswer(candidate) {
            let normalized = TextMatch.normalize(candidate)
            guard !normalized.isEmpty, normalized != ownTitle, pageLines.contains(normalized),
                  seen.insert(normalized).inserted else {
                continue
            }
            result.append(candidate)
        }
        return result
    }

    /// The ingredient groups the model's line numbers give, the words being `lines`' own
    /// (SLT-146). A group's name is its `nameLine` only when that line is in range, isn't any
    /// item's line, doesn't start like an ingredient (`WrapJoiner.startsIngredient`) and isn't too
    /// long; a group after the first with no name joins the group before it. Each line is used by
    /// one item at most. Lines the model skipped (RV-29, `15` M3-3a): a group with no name takes an
    /// unused heading line (ending `:`) just before its span; an unused line inside a group's span
    /// that starts like an ingredient is put back among its ingredients, in line order, with
    /// `put back: ingredient n`. Warnings for numbers out of range, a long group name, a repeated
    /// line, each line put back, and every line nothing used.
    static func ingredientGroups(from part: GeneratedIngredientLines, lines: [String]) -> (groups: [IngredientGroup], warnings: [String]) {
        var warnings: [String] = []
        var used = Set<Int>()
        var usedByItems = Set<Int>()

        // Every in-range line any item in the answer names, so a group name is never one of them.
        var itemLines = Set<Int>()
        for item in part.groups.flatMap(\.items) where item.firstLine >= 1 && item.lastLine >= item.firstLine {
            itemLines.formUnion(item.firstLine...min(item.lastLine, max(lines.count, item.firstLine)))
        }

        /// One answered group: its name, its ingredients with each one's first line, and its span.
        struct Made {
            var name: String?
            var ingredients: [(line: Int, ingredient: Ingredient)]
            var span: ClosedRange<Int>?
        }
        var made: [Made] = []

        for generated in part.groups {
            var name: String?
            let nameLineInRange = generated.nameLine >= 1 && generated.nameLine <= lines.count
            if nameLineInRange, !itemLines.contains(generated.nameLine) {
                var text = lines[generated.nameLine - 1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !WrapJoiner.startsIngredient(text) {
                    if text.hasSuffix(":") {
                        text.removeLast()
                    }
                    if text.count > maximumGroupNameLength {
                        warnings.append("group name too long")
                    } else {
                        name = text
                        used.insert(generated.nameLine)
                    }
                }
            }

            var ingredients: [(line: Int, ingredient: Ingredient)] = []
            var itemRanges: [ClosedRange<Int>] = []
            for item in generated.items {
                guard item.firstLine >= 1, item.lastLine <= lines.count, item.lastLine >= item.firstLine,
                      item.lastLine - item.firstLine + 1 <= maximumItemLines else {
                    warnings.append("ingredient lines out of range")
                    continue
                }
                let numbers = Set(item.firstLine...item.lastLine)
                guard usedByItems.isDisjoint(with: numbers) else {
                    warnings.append("ingredient line repeated")
                    continue
                }
                usedByItems.formUnion(numbers)
                used.formUnion(numbers)
                itemRanges.append(item.firstLine...item.lastLine)
                let rawText = joinedLines(Array(lines[(item.firstLine - 1)...(item.lastLine - 1)]))
                let parsed = IngredientLineParser.parse(rawText)
                ingredients.append((item.firstLine, Ingredient(
                    rawText: rawText,
                    quantity: parsed.quantity,
                    unit: parsed.unit,
                    item: nonEmpty(item.item),
                    preparation: nonEmpty(item.preparation),
                    isOptional: item.isOptional ?? false,
                    note: nonEmpty(item.note)
                )))
            }

            // The span: from the name line when in range, else the first item, to the last item.
            var span: ClosedRange<Int>?
            if let first = itemRanges.first, let last = itemRanges.last {
                let start = nameLineInRange ? generated.nameLine : first.lowerBound
                span = min(start, last.upperBound)...last.upperBound
            }
            made.append(Made(name: name, ingredients: ingredients, span: span))
        }

        // A group with no name takes an unused heading just before its span (RV-29).
        for index in made.indices where made[index].name == nil {
            guard let span = made[index].span, span.lowerBound >= 2, !used.contains(span.lowerBound - 1) else { continue }
            var text = lines[span.lowerBound - 2].trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.hasSuffix(":"), !WrapJoiner.startsIngredient(text) else { continue }
            text.removeLast()
            guard text.count <= maximumGroupNameLength else { continue }
            made[index].name = text
            used.insert(span.lowerBound - 1)
        }

        // An unused line inside a group's span that starts like an ingredient is put back (RV-29).
        var putBack = Set<UUID>()
        for index in made.indices {
            guard let span = made[index].span else { continue }
            for number in span where !used.contains(number) {
                let text = lines[number - 1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard WrapJoiner.startsIngredient(text) else { continue }
                let parsed = IngredientLineParser.parse(text)
                let rest = parsed.rest.trimmingCharacters(in: .whitespacesAndNewlines)
                let ingredient = Ingredient(rawText: text, quantity: parsed.quantity, unit: parsed.unit,
                                            item: rest.isEmpty ? nil : rest)
                made[index].ingredients.append((number, ingredient))
                putBack.insert(ingredient.id)
                used.insert(number)
            }
            made[index].ingredients.sort { $0.line < $1.line }
        }

        // The groups: one with no name after the first joins the one before it.
        var groups: [IngredientGroup] = []
        for group in made {
            let ingredients = group.ingredients.map(\.ingredient)
            if group.name == nil, !groups.isEmpty {
                groups[groups.count - 1].ingredients.append(contentsOf: ingredients)
            } else {
                groups.append(IngredientGroup(name: group.name, ingredients: ingredients))
            }
        }

        // `put back: ingredient n`, numbered across every group as `RecipeValidator` numbers.
        for (offset, ingredient) in groups.flatMap(\.ingredients).enumerated() where putBack.contains(ingredient.id) {
            warnings.append("put back: ingredient \(offset + 1)")
        }
        for number in lines.indices.map({ $0 + 1 }) where !used.contains(number) {
            warnings.append("unused ingredient line \(number)")
        }
        return (groups, warnings)
    }

    /// Lines trimmed and joined with one space, except that a line ending with `-` before a line
    /// starting with a lowercase letter loses the `-` and joins with no space.
    private static func joinedLines(_ lines: [String]) -> String {
        var result = ""
        for line in lines.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
            if result.isEmpty {
                result = line
            } else if result.hasSuffix("-"), let first = line.first, first.isLowercase {
                result.removeLast()
                result += line
            } else {
                result += " " + line
            }
        }
        return result
    }

    /// The parts as one `Recipe`, needing review. Author and publisher from the header; the URL,
    /// yield and times from `rules`; notes, equipment and nutrition from their sections; the
    /// unreadable areas and warnings as given.
    static func assemble(
        title: String,
        header: GeneratedHeader?,
        ingredientGroups: [IngredientGroup],
        steps: GeneratedStepPart?,
        split: SplitPage,
        rules: RuleFields,
        pageIDs: [UUID],
        unreadableAreas: [SourceBox],
        warnings: [String]
    ) -> Recipe {
        let author = nonEmpty(header?.author)
        let publisher = nonEmpty(header?.publisher)
        let sourceURL = nonEmpty(rules.sourceURL)
        let attribution = (author == nil && publisher == nil && sourceURL == nil)
            ? nil
            : Attribution(author: author, publisher: publisher, sourceURL: sourceURL)

        return Recipe(
            title: title,
            yield: nonEmpty(rules.yieldText).map { Yield(rawText: $0) },
            times: nonEmpty(rules.timesText).map { Times(rawText: $0) },
            ingredientGroups: ingredientGroups,
            steps: makeSteps(steps?.steps ?? []),
            notes: split.notes.isEmpty ? nil : split.notes.joined(separator: "\n"),
            attribution: attribution,
            printedNutrition: split.nutrition.isEmpty ? nil : split.nutrition.joined(separator: "\n"),
            equipment: split.equipment,
            unreadableAreas: unreadableAreas,
            sourcePageIDs: pageIDs,
            reviewState: .needsReview,
            extraction: Extraction(promptVersion: 3, warnings: warnings)
        )
    }

    /// Steps indexed from 0.
    private static func makeSteps(_ steps: [GeneratedStep]) -> [Step] {
        steps.enumerated().map { index, step in
            Step(index: index, text: step.text, groupName: nonEmpty(step.groupName))
        }
    }

    /// The text, or nil for an empty answer such as "none" (SLT-152).
    private static func nonEmpty(_ text: String?) -> String? {
        TextMatch.isEmptyAnswer(text) ? nil : text
    }

    private static func millis(since start: ContinuousClock.Instant) -> Int {
        let (seconds, attoseconds) = (ContinuousClock.now - start).components
        return Int(seconds * 1000 + attoseconds / 1_000_000_000_000_000)
    }
}
