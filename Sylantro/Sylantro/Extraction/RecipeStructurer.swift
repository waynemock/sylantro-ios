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
    /// For the spike only (`15` M3-3m), numbers only: the steps answer's `[firstLine, lastLine]`
    /// ranges; the ingredients answer as `[groupIndex, nameLine, -1]` for each group, then
    /// `[groupIndex, firstLine, lastLine]` for each of its items; and how many lines each section
    /// held (`ingredients` after wraps are joined, `steps`). A fallback's answer replaces its part's,
    /// with its own line count. The app ignores them.
    var stepRanges: [[Int]]?
    var ingredientItems: [[Int]]?
    var sectionLineCounts: [String: Int]?
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

    static let stepsPromptIntro = "The method lines of a recipe, numbered:"

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

    /// `onPartDone` is told each part's name after its call returns, whatever it gave (`15` M3-3f).
    func structure(_ readings: [PageReading], pageIDs: [UUID],
                   onPartDone: (@Sendable (String) -> Void)? = nil) async throws -> StructuringOutcome {
        var outcome = StructuringOutcome(recipes: [], path: "parts", partMillis: [:], usedLineLabels: false,
                                         partErrors: [:], retried: [], fallbacks: [], headerTitle: nil, modelTitle: nil, otherTitles: [],
                                         headerArea: [])
        do {
            try await structure(readings, pageIDs: pageIDs, onPartDone: onPartDone, into: &outcome)
            return outcome
        } catch where Self.isRateLimit(error) {
            throw error
        } catch {
            throw StructuringFailed(outcome: outcome, underlying: error)
        }
    }

    /// The steps of `structure`, filling `outcome` as they go so a failure keeps what was learned.
    private func structure(_ readings: [PageReading], pageIDs: [UUID], onPartDone: (@Sendable (String) -> Void)?,
                           into outcome: inout StructuringOutcome) async throws {
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
                                            cap: TokenCap.lineLabels(forLineCount: allLines.count), onPartDone: onPartDone, outcome: &outcome) {
                split = Self.labelled(allLines, labels: labels, keeping: split)
                // From the labels as `labelled` reads them, so a title line labelled a step stays
                // in the header area (`15` M3-3s).
                stopAt = Self.lineKinds(allLines, labels: labels)
                    .filter { $0.value == "ingredient" || $0.value == "step" }
                    .map { $0.key - 1 }
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
                                    cap: TokenCap.header, onPartDone: onPartDone, outcome: &outcome)
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
                                     generating: GeneratedIngredientLines.self, cap: TokenCap.ingredients, onPartDone: onPartDone, outcome: &outcome) {
            let mapped = Self.ingredientGroups(from: part, lines: ingredientLines)
            ingredientGroups = mapped.groups
            warnings.append(contentsOf: mapped.warnings)
            Self.record(part, lineCount: ingredientLines.count, into: &outcome)
        }

        // 5. The steps, as line numbers into their section's lines, so their words are the page's
        // (RV-39, `15` M3-3j).
        var steps: [Step]?
        if !split.steps.isEmpty,
           let part = try await call("steps", prompt: Self.stepsPrompt(split.steps),
                                     generating: GeneratedStepLines.self, cap: TokenCap.steps, onPartDone: onPartDone, outcome: &outcome) {
            let mapped = Self.steps(from: part, lines: split.steps)
            steps = mapped.steps
            warnings.append(contentsOf: mapped.warnings)
            Self.record(part, lineCount: split.steps.count, into: &outcome)
        }

        // 6. A part still missing is asked over every readable line, not retried (SLT-147).
        if ingredientGroups == nil || split.ingredients.isEmpty {
            outcome.fallbacks.append("ingredients")
            let joinedLines = WrapJoiner.join(allLines)
            if let part = try await call("ingredients fallback", prompt: Self.ingredientsPrompt(joinedLines),
                                         generating: GeneratedIngredientLines.self, cap: TokenCap.ingredients,
                                         retrying: false, onPartDone: onPartDone, outcome: &outcome) {
                let mapped = Self.ingredientGroups(from: part, lines: joinedLines)
                ingredientGroups = mapped.groups
                Self.record(part, lineCount: joinedLines.count, into: &outcome)
                warnings.append("ingredients from whole page")
                warnings.append(contentsOf: Self.fallbackWarnings(mapped.warnings))
            }
        }
        if steps == nil || split.steps.isEmpty {
            outcome.fallbacks.append("steps")
            if let part = try await call("steps fallback", prompt: Self.stepsPrompt(allLines),
                                         generating: GeneratedStepLines.self, cap: TokenCap.steps,
                                         retrying: false, onPartDone: onPartDone, outcome: &outcome) {
                let mapped = Self.steps(from: part, lines: allLines, putsBackSkipped: false)
                steps = mapped.steps
                Self.record(part, lineCount: allLines.count, into: &outcome)
                warnings.append("steps from whole page")
                warnings.append(contentsOf: mapped.warnings)
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

    /// The ingredients answer's numbers for the spike (M3-3m).
    private static func record(_ part: GeneratedIngredientLines, lineCount: Int, into outcome: inout StructuringOutcome) {
        outcome.ingredientItems = part.groups.enumerated().flatMap { index, group in
            [[index, group.nameLine, -1]] + group.items.map { [index, $0.firstLine, $0.lastLine] }
        }
        outcome.sectionLineCounts = (outcome.sectionLineCounts ?? [:]).merging(["ingredients": lineCount]) { $1 }
    }

    /// The steps answer's numbers for the spike (M3-3m).
    private static func record(_ part: GeneratedStepLines, lineCount: Int, into outcome: inout StructuringOutcome) {
        outcome.stepRanges = part.steps.map { [$0.firstLine, $0.lastLine] }
        outcome.sectionLineCounts = (outcome.sectionLineCounts ?? [:]).merging(["steps": lineCount]) { $1 }
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
        onPartDone: (@Sendable (String) -> Void)?,
        outcome: inout StructuringOutcome
    ) async throws -> Content? {
        let start = ContinuousClock.now
        defer {
            outcome.partMillis[part] = Self.millis(since: start)
        }
        do {
            let content = try await Self.respond(to: prompt, generating: type, cap: cap)
            onPartDone?(part)
            return content
        } catch where Self.isRateLimit(error) {
            throw error
        } catch {
            outcome.partErrors[part] = String(describing: error)
        }
        guard retrying else {
            onPartDone?(part)
            return nil
        }
        outcome.retried.append(part)
        do {
            let content = try await Self.respond(to: prompt, generating: type, cap: cap * 2)
            onPartDone?(part)
            return content
        } catch where Self.isRateLimit(error) {
            throw error
        } catch {
            outcome.partErrors["\(part) retry"] = String(describing: error)
            onPartDone?(part)
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

    private static func stepsPrompt(_ lines: [String]) -> String {
        stepsPromptIntro + "\n" + numbered(lines)
    }

    /// The sections the line labels give: `header`, `ingredient`, `step` and `note` lines; `other`,
    /// unlabelled, clutter and heading lines are dropped, and bullets are removed from ingredient,
    /// step and note lines, as in headed sections (SLT-149). Equipment and nutrition stay as the
    /// headings found them. A run of 1 to 3 `ingredient` or `note` lines whose nearest labelled
    /// lines before and after it (clutter, headings and unlabelled lines skipped) are both `step`
    /// lines is step lines, in their place (`15` M3-3k, M3-3m), unless a line in the run starts
    /// with a quantity and a unit, as the ingredient parser reads it. A title line labelled a step
    /// is no step (M3-3s, `lineKinds`).
    static func labelled(_ lines: [String], labels: GeneratedLineLabels, keeping split: SplitPage) -> SplitPage {
        let kinds = lineKinds(lines, labels: labels)
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

    /// Each line's label as `labelled` reads it: the first given for the line; then a run of
    /// ingredient or note lines between step lines made step lines (M3-3k, M3-3m); then a line
    /// labelled `step` before the first line labelled `ingredient` left unlabelled when a `step`
    /// line also comes after the last `ingredient` line, since on such a page it is the title or
    /// a deck, not a step (`15` M3-3s). A page whose steps all come before its ingredients is
    /// unchanged. `stopAt` is found from these, so such a line stays in the header area.
    static func lineKinds(_ lines: [String], labels: GeneratedLineLabels) -> [Int: String] {
        var kinds: [Int: String] = [:]
        for label in labels.labels where kinds[label.line] == nil {
            kinds[label.line] = label.kind
        }
        let headingLines = Set(IngredientHeadings.lines(lines))
        let labelledLines = lines.indices.map { $0 + 1 }.filter { number in
            let line = lines[number - 1]
            return kinds[number] != nil && !PageClutter.isClutter(line) && PageSplitter.heading(line) == nil
                && !headingLines.contains(number)
        }
        // Each run of ingredient or note lines, in the labelled lines' order.
        var position = 0
        while position < labelledLines.count {
            guard kinds[labelledLines[position]] == "ingredient" || kinds[labelledLines[position]] == "note" else {
                position += 1
                continue
            }
            var end = position
            while end + 1 < labelledLines.count,
                  kinds[labelledLines[end + 1]] == "ingredient" || kinds[labelledLines[end + 1]] == "note" {
                end += 1
            }
            let run = labelledLines[position...end]
            if run.count <= 3, position > 0, end + 1 < labelledLines.count,
               kinds[labelledLines[position - 1]] == "step", kinds[labelledLines[end + 1]] == "step",
               !run.contains(where: { startsWithQuantityAndUnit(lines[$0 - 1]) }) {
                for number in run {
                    kinds[number] = "step"
                }
            }
            position = end + 1
        }
        // A title line labelled a step (M3-3s).
        let ingredientLines = kinds.filter { $0.value == "ingredient" }.keys
        if let firstIngredient = ingredientLines.min(), let lastIngredient = ingredientLines.max(),
           kinds.contains(where: { $0.value == "step" && $0.key > lastIngredient }) {
            for (line, kind) in kinds where kind == "step" && line < firstIngredient {
                kinds[line] = nil
            }
        }
        return kinds
    }

    /// Whether the line starts with a quantity followed by a unit, as `IngredientLineParser` reads
    /// it: "½ cup …" does, "25 minutes." doesn't (M3-3m).
    private static func startsWithQuantityAndUnit(_ line: String) -> Bool {
        let parsed = IngredientLineParser.parse(PageSplitter.removingBullet(line))
        return parsed.quantity != nil && parsed.unit != nil
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
    /// one item at most. Lines the model skipped (RV-29, `15` M3-3a, M3-3e): unused lines just before
    /// a group's first line that start like an ingredient are put back, the span starting at them;
    /// then a group with no name takes an unused heading line (ending `:`) just before its span; an
    /// unused line inside a group's span that starts like an ingredient is put back too. Each goes
    /// among the group's ingredients in line order, with `put back: ingredient n`. When the section
    /// prints group headings (`IngredientHeadings`, RV-38, M3-3h), they make the groups: skipped
    /// ingredient lines after the first heading are put back, and every ingredient goes under the
    /// last heading before it. Warnings for numbers out of range, a long group name, a repeated
    /// line, each line put back, and every line nothing used.
    ///
    /// M3-3q: an item's `item`, when the model gives one, is its text only when its own line's
    /// parser `rest` holds it (compared without case, whitespace runs as one space), else that `rest`; its `preparation`
    /// and `note` only when its line holds them, else nil. Under printed headings, a line put back
    /// after the first heading with a quantity the parser finds gets no `put back` warning.
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
                let names = Self.namesFromLine(rawText, item: item)
                ingredients.append((item.firstLine, Ingredient(
                    rawText: rawText,
                    quantity: parsed.quantity,
                    unit: parsed.unit,
                    item: names.item,
                    preparation: names.preparation,
                    isOptional: item.isOptional ?? false,
                    note: names.note
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

        // Lines just before a group's first line that start like an ingredient are put back too,
        // walking back to a used line, a heading (`:`), a line that isn't an ingredient's, or line
        // 1; the span starts at the first one (RV-29, `15` M3-3e).
        var putBack = Set<UUID>()
        for index in made.indices {
            guard let span = made[index].span else { continue }
            var start = span.lowerBound
            var number = start - 1
            while number >= 1, !used.contains(number) {
                let text = lines[number - 1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.hasSuffix(":"), WrapJoiner.startsIngredient(text) else { break }
                let ingredient = Self.putBackIngredient(text)
                made[index].ingredients.append((number, ingredient))
                putBack.insert(ingredient.id)
                used.insert(number)
                start = number
                number -= 1
            }
            made[index].span = start...span.upperBound
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
        for index in made.indices {
            guard let span = made[index].span else { continue }
            for number in span where !used.contains(number) {
                let text = lines[number - 1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard WrapJoiner.startsIngredient(text) else { continue }
                let ingredient = Self.putBackIngredient(text)
                made[index].ingredients.append((number, ingredient))
                putBack.insert(ingredient.id)
                used.insert(number)
            }
            made[index].ingredients.sort { $0.line < $1.line }
        }

        var groups: [IngredientGroup] = []
        let headings = IngredientHeadings.lines(lines)
        if let firstHeading = headings.first {
            // RV-38 (`15` M3-3h): the printed headings make the groups. Every line still unused
            // after the first heading that starts like an ingredient is put back; then each
            // ingredient goes under the last heading before it, those before the first in a group
            // with no name; a heading with nothing under it makes no group. The model's names
            // aren't used. Heading lines count as used.
            let headingLines = Set(headings)
            used.formUnion(headingLines)
            var all = made.flatMap(\.ingredients)
            for number in lines.indices.map({ $0 + 1 }) where number > firstHeading && !used.contains(number) {
                let text = lines[number - 1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard WrapJoiner.startsIngredient(text) else { continue }
                let ingredient = Self.putBackIngredient(text)
                all.append((number, ingredient))
                putBack.insert(ingredient.id)
                used.insert(number)
            }
            all.sort { $0.line < $1.line }
            // M3-3q: a line put back under a printed heading, with a quantity, is the page's own
            // ingredient line under its own heading; it isn't flagged.
            for (line, ingredient) in all where line > firstHeading && ingredient.quantity != nil {
                putBack.remove(ingredient.id)
            }
            let before = all.filter { $0.line < firstHeading }.map(\.ingredient)
            if !before.isEmpty {
                groups.append(IngredientGroup(name: nil, ingredients: before))
            }
            for (index, heading) in headings.enumerated() {
                let next = index + 1 < headings.count ? headings[index + 1] : Int.max
                let under = all.filter { $0.line > heading && $0.line < next }.map(\.ingredient)
                guard !under.isEmpty else { continue }
                var name = lines[heading - 1].trimmingCharacters(in: .whitespacesAndNewlines)
                name.removeLast()
                groups.append(IngredientGroup(name: name.trimmingCharacters(in: .whitespaces), ingredients: under))
            }
        } else {
            // No heading: the model's groups; one with no name after the first joins the one
            // before it.
            for group in made {
                let ingredients = group.ingredients.map(\.ingredient)
                if group.name == nil, !groups.isEmpty {
                    groups[groups.count - 1].ingredients.append(contentsOf: ingredients)
                } else {
                    groups.append(IngredientGroup(name: group.name, ingredients: ingredients))
                }
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

    /// An item's names checked against its own line (M3-3q): the model's `item` only when the
    /// parser's `rest` for the line (bullet removed) holds it, else that `rest` (nil when empty);
    /// no item from the model (nil, or an empty answer such as "none") stays nil, as before. Its
    /// `preparation` and `note` only when the line holds them, else nil.
    private static func namesFromLine(_ rawText: String, item: GeneratedLineItem)
        -> (item: String?, preparation: String?, note: String?) {
        let line = comparable(rawText)
        let rest = IngredientLineParser.parse(PageSplitter.removingBullet(rawText)).rest
            .trimmingCharacters(in: .whitespacesAndNewlines)
        func onLine(_ text: String?, in target: String) -> String? {
            guard let text = nonEmpty(text), !comparable(text).isEmpty,
                  target.contains(comparable(text)) else { return nil }
            return text
        }
        let name: String? = nonEmpty(item.item) == nil ? nil
            : onLine(item.item, in: comparable(rest)) ?? (rest.isEmpty ? nil : rest)
        return (name,
                onLine(item.preparation, in: line),
                onLine(item.note, in: line))
    }

    /// Text for comparing: lowercased, trimmed, whitespace runs as one space (M3-3q).
    private static func comparable(_ text: String) -> String {
        text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// A line the model skipped, made as an item is: the line, and the parser's quantity, unit and
    /// rest as its item (RV-29).
    private static func putBackIngredient(_ text: String) -> Ingredient {
        let parsed = IngredientLineParser.parse(text)
        let rest = parsed.rest.trimmingCharacters(in: .whitespacesAndNewlines)
        return Ingredient(rawText: text, quantity: parsed.quantity, unit: parsed.unit,
                          item: rest.isEmpty ? nil : rest)
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
        steps: [Step]?,
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
            steps: steps ?? [],
            notes: split.notes.isEmpty ? nil : split.notes.joined(separator: "\n"),
            attribution: attribution,
            printedNutrition: split.nutrition.isEmpty ? nil : split.nutrition.joined(separator: "\n"),
            equipment: split.equipment,
            unreadableAreas: unreadableAreas,
            sourcePageIDs: pageIDs,
            reviewState: .needsReview,
            extraction: Extraction(promptVersion: 4, warnings: warnings)
        )
    }

    // MARK: Steps (`15` M3-3j, RV-39)

    /// A step range spanning more lines than this is out of range.
    static let maximumStepLines = 15

    /// The steps the model's line numbers give, the words being `lines`' own (numbered from 1), in
    /// line order (M3-3j, with M3-3k's rules). A group heading (`IngredientHeadings`: a short line
    /// ending `:`) is no step: each step after it, until the next, has it (less the `:`) as its
    /// `groupName`. A range in range, `firstLine <= lastLine`, at most 15 lines, its lines neither
    /// used nor headings, is kept; any other is dropped with `step lines out of range`. Then:
    ///
    /// 1. A step marker line (`4.`, `4)`, `Step 4`, with or without a `:`) adds no text, and the
    ///    next line starts a step. A line starting with a printed step number or `Step 4` starts a
    ///    step inside a range, and the number is removed from its text.
    /// 2. On a numbered page (two or more lines start with a step number or are markers), a step
    ///    starts only at a number, after a marker, or first after a heading; anything else joins
    ///    the step before.
    /// 3. A range or skipped line that doesn't start at a number or marker joins the step before,
    ///    in its group, when it starts lowercase or that step is left open (no `.`, `!` or `?` at
    ///    its end, and it is neither a heading-shaped line nor a fragment).
    /// 4. With `putsBackSkipped`, a skipped line (not used, not a heading, not clutter) that would
    ///    start a step is put back (`put back: step n`) only between the first kept range's first
    ///    line and the last one's last line, or when it starts with a number or follows a marker;
    ///    any other is left out. Without it (the fallback over the whole page), skipped lines are
    ///    left out.
    /// 5. A one-line step of at most 4 capitalised words, no digit, no `.` or `?` at its end,
    ///    followed by another step in its group, names the steps after it in that group instead.
    /// 6. A step with fewer than 2 words with a letter, not ending with `.`, `!` or `?`, is left out.
    ///
    /// M3-3m: marker and heading lines inside a range are taken out of it (not counted toward its
    /// 15 lines), so only a range with nothing left, or one touching a line already used, is
    /// dropped; the first line after a marker or a heading, skipped, is put back wherever it is;
    /// on a numbered page, rule 2 joins neither a heading-shaped one-line piece nor anything onto
    /// one; and a line such as "Related Pages" ends the steps, it and every line after it no
    /// step's.
    ///
    /// A step's text is its lines (clutter left out) joined with a space, a line ending with `-`
    /// joining the next with no space. Indexed from 0 after these rules.
    static func steps(from part: GeneratedStepLines, lines: [String],
                      putsBackSkipped: Bool = true) -> (steps: [Step], warnings: [String]) {
        var warnings: [String] = []
        let headings = Set(IngredientHeadings.lines(lines))
        // M3-3m: the method ends before a line such as "Related Pages"; only lines before it are
        // steps' lines.
        let stepLineCount = lines.firstIndex(where: endsMethod) ?? lines.count
        let markers = Set(lines.indices.filter { isStepMarker(lines[$0]) }.map { $0 + 1 })

        // The kept ranges, by line: each line's range's first line. Marker and heading lines are
        // taken out of a range (M3-3m), and it is cut short before the method's end.
        var rangeStart: [Int: Int] = [:]
        var keptSpan: ClosedRange<Int>?
        for range in part.steps {
            guard range.firstLine >= 1, range.lastLine <= lines.count, range.firstLine <= range.lastLine else {
                warnings.append("step lines out of range")
                continue
            }
            let numbers = (range.firstLine...range.lastLine).filter { number in
                number <= stepLineCount && !markers.contains(number) && !headings.contains(number)
            }
            guard let first = numbers.first, let last = numbers.last, numbers.count <= maximumStepLines,
                  numbers.allSatisfy({ rangeStart[$0] == nil }) else {
                warnings.append("step lines out of range")
                continue
            }
            for number in numbers {
                rangeStart[number] = range.firstLine
            }
            keptSpan = keptSpan.map { min($0.lowerBound, first)...max($0.upperBound, last) } ?? first...last
        }

        // Rule 1: the lines as pieces, in line order. A piece is a run of a range's lines up to a
        // number or a marker, or one skipped line; a heading is its own piece.
        var pieces: [StepPiece] = []
        var afterMarker = false
        // The last line before this one (not empty, not clutter) was a marker or a heading (M3-3m).
        var afterLabel = false
        for (offset, rawLine) in lines.prefix(stepLineCount).enumerated() {
            let number = offset + 1
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if headings.contains(number) {
                pieces.append(StepPiece(heading: String(line.dropLast()).trimmingCharacters(in: .whitespaces)))
                afterMarker = false
                afterLabel = true
                continue
            }
            guard !line.isEmpty, !PageClutter.isClutter(line) else { continue }
            if markers.contains(number) {
                afterMarker = true
                afterLabel = true
                continue
            }
            let startsNumbered = stepNumberLength(line) != nil
            if let start = rangeStart[number], let last = pieces.last, last.rangeStart == start,
               !startsNumbered, !afterMarker {
                pieces[pieces.count - 1].lines.append(line)
            } else {
                pieces.append(StepPiece(lines: [line], line: number, rangeStart: rangeStart[number],
                                        isNumbered: startsNumbered || afterMarker, followsLabel: afterLabel))
            }
            afterMarker = false
            afterLabel = false
        }

        // Rules 2 to 4: each piece starts a step, joins the one before, or is left out.
        let isNumberedPage = lines.prefix(stepLineCount).filter { line in
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return stepNumberLength(text) != nil || isStepMarker(text)
        }.count >= 2
        var built: [(lines: [String], groupName: String?, isPutBack: Bool)] = []
        var groupName: String?
        var stepsInGroup = 0
        for piece in pieces {
            if let heading = piece.heading {
                groupName = heading
                stepsInGroup = 0
                continue
            }
            let isSkipped = piece.rangeStart == nil
            if isSkipped && !putsBackSkipped { continue }
            let joins: Bool
            if stepsInGroup == 0 || piece.isNumbered {
                joins = false
            } else if isNumberedPage {
                // M3-3m: never a heading-shaped one-line piece, nor anything onto one.
                let before = built[built.count - 1].lines
                joins = !isHeadingShapedLine(piece.lines) && !isHeadingShapedLine(before)
            } else {
                let before = built[built.count - 1].lines
                let beforeText = removingStepNumber(joinedStepText(before))
                let isOpen = !endsSentence(beforeText) && !isFragment(beforeText)
                    && !(before.count == 1 && isHeadingShaped(beforeText))
                joins = (piece.lines[0].first?.isLowercase ?? false) || isOpen
            }
            if joins {
                built[built.count - 1].lines.append(contentsOf: piece.lines)
                continue
            }
            if isSkipped {
                let isBetweenSteps = keptSpan.map { piece.line > $0.lowerBound && piece.line < $0.upperBound } ?? false
                guard piece.isNumbered || piece.followsLabel || isBetweenSteps else { continue }
            }
            built.append((piece.lines, groupName, isSkipped))
            stepsInGroup += 1
        }

        // Rule 5: a heading-shaped one-line step followed by another in its group names the
        // steps after it in that group.
        var named: [(text: String, groupName: String?, isPutBack: Bool)] = []
        var heading: (group: String?, name: String)?
        for (index, step) in built.enumerated() {
            let text = removingStepNumber(joinedStepText(step.lines))
            if let current = heading, current.group != step.groupName {
                heading = nil
            }
            if step.lines.count == 1, isHeadingShaped(text),
               index + 1 < built.count, built[index + 1].groupName == step.groupName {
                heading = (step.groupName, text)
                continue
            }
            named.append((text, heading?.name ?? step.groupName, step.isPutBack))
        }

        // Rule 6: fragments are left out; the rest are indexed from 0.
        var steps: [Step] = []
        for step in named where !step.text.isEmpty && !isFragment(step.text) {
            steps.append(Step(index: steps.count, text: step.text, groupName: step.groupName))
            if step.isPutBack {
                warnings.append("put back: step \(steps.count)")
            }
        }
        return (steps, warnings)
    }

    /// A run of a step range's lines, one skipped line, or a heading, in `steps(from:lines:)`.
    private struct StepPiece {
        var lines: [String] = []
        /// Its first line's number.
        var line = 0
        /// The first line of the kept range it is in; nil for a skipped line.
        var rangeStart: Int?
        /// It starts at a printed step number or follows a marker.
        var isNumbered = false
        /// It is the first line after a marker or a heading (M3-3m).
        var followsLabel = false
        /// A heading's name.
        var heading: String?
    }

    /// The lines that end a recipe's method (M3-3m), compared trimmed, in lowercase, less a `:`.
    private static let methodEnds: Set<String> = [
        "related pages", "related recipes", "more recipes", "you may also like", "frequently asked questions",
    ]

    /// Whether the line reads as one of `methodEnds`.
    private static func endsMethod(_ line: String) -> Bool {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text.hasSuffix(":") {
            text = String(text.dropLast()).trimmingCharacters(in: .whitespaces)
        }
        return methodEnds.contains(text)
    }

    /// One line with a heading's shape (rule 5), its step number removed.
    private static func isHeadingShapedLine(_ lines: [String]) -> Bool {
        lines.count == 1 && isHeadingShaped(removingStepNumber(joinedStepText(lines)))
    }

    /// Whether the text ends with `.`, `!` or `?`.
    private static func endsSentence(_ text: String) -> Bool {
        text.hasSuffix(".") || text.hasSuffix("!") || text.hasSuffix("?")
    }

    /// Fewer than 2 words with a letter, and no `.`, `!` or `?` at its end (M3-3k rule 6).
    private static func isFragment(_ text: String) -> Bool {
        let words = text.split(whereSeparator: \.isWhitespace).filter { $0.contains(where: \.isLetter) }
        return words.count < 2 && !endsSentence(text)
    }

    /// At most 4 words, each starting with a capital letter, no digit, and no `.` or `?` at its
    /// end (M3-3k rule 5).
    private static func isHeadingShaped(_ text: String) -> Bool {
        let words = text.split(whereSeparator: \.isWhitespace)
        return (1...4).contains(words.count)
            && words.allSatisfy { $0.first?.isUppercase ?? false }
            && !text.contains(where: \.isNumber)
            && !text.hasSuffix(".") && !text.hasSuffix("?")
    }

    /// A line that is only a step number (`4.`, `4)`) or `Step` and a number, with or without a
    /// `:` after it.
    private static func isStepMarker(_ line: String) -> Bool {
        var text = Substring(line.trimmingCharacters(in: .whitespacesAndNewlines))
        if text.hasSuffix(":") {
            text = text.dropLast()
        }
        if let rest = droppingStepWord(text) {
            return !rest.isEmpty && rest.allSatisfy(isDigit)
        }
        let digits = text.prefix(while: isDigit)
        let mark = text.dropFirst(digits.count)
        return !digits.isEmpty && (mark == "." || mark == ")")
    }

    /// Whether the character is 0 to 9.
    private static func isDigit(_ character: Character) -> Bool {
        ("0"..."9").contains(character)
    }

    /// The text after a leading `Step` and its spaces, or nil when it doesn't start with `Step`.
    private static func droppingStepWord(_ text: Substring) -> Substring? {
        guard text.prefix(4).lowercased() == "step" else { return nil }
        let rest = text.dropFirst(4)
        let trimmed = rest.drop(while: \.isWhitespace)
        return trimmed.first.map(isDigit) == true ? trimmed : nil
    }

    /// How many characters a leading step number takes (with its mark and space), or nil: digits,
    /// then `.` or `)` and a space; digits, a space and a capital letter; or `Step` and a number,
    /// a `:` or `.` if printed, and a space (M3-3k rule 1).
    private static func stepNumberLength(_ text: String) -> Int? {
        let whole = Substring(text)
        if let afterWord = droppingStepWord(whole) {
            let digits = afterWord.prefix(while: isDigit)
            var rest = afterWord.dropFirst(digits.count)
            if rest.first == ":" || rest.first == "." {
                rest = rest.dropFirst()
            }
            guard rest.first?.isWhitespace == true, rest.contains(where: { !$0.isWhitespace }) else { return nil }
            return whole.count - rest.drop(while: \.isWhitespace).count
        }
        let digits = text.prefix { ("0"..."9").contains($0) }
        guard !digits.isEmpty else { return nil }
        let rest = Array(text.dropFirst(digits.count))
        if rest.count >= 2, rest[0] == "." || rest[0] == ")", rest[1] == " " {
            return digits.count + 2
        }
        if rest.count >= 2, rest[0] == " ", rest[1].isUppercase {
            return digits.count + 1
        }
        return nil
    }

    /// The text without its leading step number.
    private static func removingStepNumber(_ text: String) -> String {
        guard let length = stepNumberLength(text) else { return text }
        return String(text.dropFirst(length)).trimmingCharacters(in: .whitespaces)
    }

    /// Lines trimmed and joined with a space, except that a line ending with `-` joins the next
    /// with no space (the `-` kept).
    private static func joinedStepText(_ lines: [String]) -> String {
        var result = ""
        for line in lines.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) where !line.isEmpty {
            if result.isEmpty || result.hasSuffix("-") {
                result += line
            } else {
                result += " " + line
            }
        }
        return result
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
