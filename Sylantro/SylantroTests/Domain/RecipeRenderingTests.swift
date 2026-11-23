import Foundation
import Testing
@testable import Sylantro

/// A recipe's plain copy (`14` Task M2-5, MT-18): `recipe.md` for a recipe not yet read, and its
/// folder's name. `en_US` and UTC; every recipe is made up.
@Suite("Recipe rendering")
struct RecipeRenderingTests {
    static let locale = Locale(identifier: "en_US")
    static let utc = TimeZone(identifier: "UTC")!
    static let id = UUID(uuidString: "8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F")!

    /// A two-page draft created 22 Nov 2026 (UTC).
    static func draft(continuesOnUnscannedPage: Bool) -> Recipe {
        var components = DateComponents(year: 2026, month: 11, day: 22, hour: 15)
        components.timeZone = utc
        let created = Calendar(identifier: .gregorian).date(from: components)!
        return Recipe(id: id, sourcePageIDs: [UUID(), UUID()], continuesOnUnscannedPage: continuesOnUnscannedPage,
                      createdAt: created, updatedAt: created)
    }

    static let pageFileNames = ["page-1.heic", "page-2.heic"]

    @Test("a new recipe's markdown")
    func newRecipeMarkdown() {
        let markdown = RecipeRendering.markdown(Self.draft(continuesOnUnscannedPage: false),
                                                pageFileNames: Self.pageFileNames,
                                                locale: Self.locale, timeZone: Self.utc)
        #expect(markdown == """
        # New recipe

        Scanned Nov 22, 2026 · 2 pages

        Waiting to be read

        ![](pages/page-1.heic)

        ![](pages/page-2.heic)

        """)
    }

    @Test("the page-2 warning is in the markdown")
    func pageTwoWarningMarkdown() {
        let markdown = RecipeRendering.markdown(Self.draft(continuesOnUnscannedPage: true),
                                                pageFileNames: Self.pageFileNames,
                                                locale: Self.locale, timeZone: Self.utc)
        #expect(markdown == """
        # New recipe

        Scanned Nov 22, 2026 · 2 pages

        Waiting to be read

        Continues on a page not scanned

        ![](pages/page-1.heic)

        ![](pages/page-2.heic)

        """)
    }

    @Test("folder names")
    func folderNames() {
        #expect(RecipeRendering.folderName(title: "", id: Self.id) == "new-recipe-8d5e1b3c")
        #expect(RecipeRendering.folderName(title: "Grandma's Apple Pie!", id: Self.id) == "grandmas-apple-pie-8d5e1b3c")
        #expect(RecipeRendering.folderName(title: "Crème Brûlée", id: Self.id) == "creme-brulee-8d5e1b3c")
    }
}
