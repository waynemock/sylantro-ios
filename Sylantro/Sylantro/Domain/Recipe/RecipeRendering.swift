import Foundation

/// A recipe's plain copy in Files (`02` §3, §5.4): `recipe.json`, `recipe.md` and its folder's
/// name. The words in `recipe.md` are `13` §6's (S-2, S-40, S-20, S-21); ingredients and steps are
/// M3's to add.
nonisolated enum RecipeRendering {
    /// `recipe.json`: `RecipeJSON`'s sorted keys, carrying `schemaVersion`.
    static func json(_ recipe: Recipe) throws -> Data {
        try RecipeJSON.encode(recipe)
    }

    /// `recipe.md` for a recipe not yet read (MT-18): the title or S-2, S-40, S-20 while it has no
    /// extraction, S-21 when flagged, then one image per page, blocks one blank line apart, ending in
    /// one newline.
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
        for fileName in pageFileNames {
            blocks.append("![](pages/\(fileName))")
        }
        return blocks.joined(separator: "\n\n") + "\n"
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
