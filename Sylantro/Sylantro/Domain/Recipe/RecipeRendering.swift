import Foundation

/// A recipe's plain copy in Files (`02` §3, §5.4): `recipe.json`, `recipe.md` and its folder's
/// name. The words in `recipe.md` are `13` §6's (S-2, S-40, S-20, S-21, S-51); a read recipe's
/// sections follow `13` §4.5 (`15` M3-3), and the yield and times lines are the screen's too.
nonisolated enum RecipeRendering {
    /// `recipe.json`: `RecipeJSON`'s sorted keys, carrying `schemaVersion`.
    static func json(_ recipe: Recipe) throws -> Data {
        try RecipeJSON.encode(recipe)
    }

    /// `recipe.md` (MT-18, `13` §4.5): the title or S-2, S-40, S-20 while it has no extraction,
    /// S-21 when flagged; once read, its sections (`readSections`); then one image per page, blocks
    /// one blank line apart, ending in one newline.
    static func markdown(_ recipe: Recipe, pageFileNames: [String], locale: Locale = .current,
                         timeZone: TimeZone = .current) -> String {
        var blocks: [String] = []
        blocks.append("# \(recipe.title.isEmpty ? "New recipe" : recipe.title)")
        let style = Date.FormatStyle(locale: locale, timeZone: timeZone).month(.abbreviated).day().year()
        let count = recipe.sourcePageIDs.count
        let pages = count == 1 ? "1 page" : "\(count) pages"
        blocks.append("Scanned \(recipe.createdAt.formatted(style)) · \(pages)")
        if recipe.extraction == nil {
            blocks.append("Waiting to be read")
        }
        if recipe.continuesOnUnscannedPage {
            blocks.append("Continues on a page not scanned")
        }
        if recipe.extraction != nil {
            blocks.append(contentsOf: readSections(recipe))
        }
        for fileName in pageFileNames {
            blocks.append("![](pages/\(fileName))")
        }
        return blocks.joined(separator: "\n\n") + "\n"
    }

    /// A read recipe's blocks for `recipe.md` (`13` §4.5), each only when present, under S-51's
    /// headings: Serves or Makes, the times, Ingredients (group names as `###`, lines as `- `),
    /// Steps (numbered), Notes, Equipment (`- `), Nutrition, Source (one line each). No flags.
    private static func readSections(_ recipe: Recipe) -> [String] {
        var blocks: [String] = []
        if let yield = recipe.yield.flatMap(yieldLine) {
            blocks.append(yield)
        }
        if let times = recipe.times.flatMap(timesLine) {
            blocks.append(times)
        }
        let groups = recipe.ingredientGroups.filter { !$0.ingredients.isEmpty }
        if !groups.isEmpty {
            blocks.append("## Ingredients")
            for group in groups {
                if let name = group.name, !name.isEmpty {
                    blocks.append("### \(name)")
                }
                blocks.append(group.ingredients.map { "- \($0.rawText)" }.joined(separator: "\n"))
            }
        }
        if !recipe.steps.isEmpty {
            blocks.append("## Steps")
            blocks.append(recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element.text)" }.joined(separator: "\n"))
        }
        if let notes = recipe.notes, !notes.isEmpty {
            blocks.append("## Notes")
            blocks.append(notes)
        }
        if !recipe.equipment.isEmpty {
            blocks.append("## Equipment")
            blocks.append(recipe.equipment.map { "- \($0)" }.joined(separator: "\n"))
        }
        if let nutrition = recipe.printedNutrition, !nutrition.isEmpty {
            blocks.append("## Nutrition")
            blocks.append(nutrition)
        }
        let source = sourceLines(recipe.attribution)
        if !source.isEmpty {
            blocks.append("## Source")
            blocks.append(source.joined(separator: "\n"))
        }
        return blocks
    }

    /// The yield as printed ("Serves 4", "Makes 24 cookies", S-51), for the screen and
    /// `recipe.md`; nil when it has no text.
    static func yieldLine(_ yield: Yield) -> String? {
        guard let text = yield.rawText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    /// The times as printed; else "Prep ‹m› · Cook ‹m› · Total ‹m›" from the minutes present
    /// (S-51), for the screen and `recipe.md`; nil when it has neither.
    static func timesLine(_ times: Times) -> String? {
        if let text = times.rawText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        }
        let parts = [("Prep", times.prepMinutes), ("Cook", times.cookMinutes), ("Total", times.totalMinutes)]
            .compactMap { label, minutes in minutes.map { "\(label) \(duration($0))" } }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// "15 min", "1 hr", "1 hr 15 min".
    static func duration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (_, 0): return "\(hours) hr"
        default: return "\(hours) hr \(rest) min"
        }
    }

    /// The source's author, publisher and web address, each as printed, those present.
    static func sourceLines(_ attribution: Attribution?) -> [String] {
        [attribution?.author, attribution?.publisher, attribution?.sourceURL]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// The most characters the title part of a folder name keeps.
    static let folderTitleLimit = 40

    /// The recipe's folder: its title lowercased, diacritics folded, letters and digits kept,
    /// apostrophes dropped, every other run made one `-`, trimmed, at most 40 characters, or
    /// `new-recipe`; then `-` and the first 8 characters of the id, lowercased.
    static func folderName(title: String, id: UUID) -> String {
        let folded = title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        var slug = ""
        var pendingDash = false
        for character in folded {
            if character.isLetter || character.isNumber {
                if pendingDash && !slug.isEmpty { slug.append("-") }
                pendingDash = false
                slug.append(character)
            } else if character == "'" || character == "\u{2019}" {
                // An apostrophe joins its word: "Grandma's" is "grandmas".
                continue
            } else {
                pendingDash = true
            }
        }
        if slug.count > folderTitleLimit {
            slug = String(slug.prefix(folderTitleLimit))
            while slug.hasSuffix("-") { slug.removeLast() }
        }
        if slug.isEmpty { slug = "new-recipe" }
        return "\(slug)-\(idPrefix(id))"
    }

    /// The first 8 characters of the id, lowercased: the end of every recipe folder's name.
    static func idPrefix(_ id: UUID) -> String {
        String(id.uuidString.lowercased().prefix(8))
    }
}
