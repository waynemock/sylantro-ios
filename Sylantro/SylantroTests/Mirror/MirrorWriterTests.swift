import CoreGraphics
import Foundation
import Testing
@testable import Sylantro

/// The copy in Files (`14` Task M2-5): a recipe's folder, its page copies never replaced, a
/// renamed folder found again, a deleted recipe's pages moved out, and the pending file. On a
/// `PhotoFiles` and a mirror root in temporary folders, with small made-up images.
@Suite("Mirror writer")
struct MirrorWriterTests {
    /// A temporary folder holding the photo folder, the mirror root and the pending file.
    struct Fixture {
        let folder: URL
        let photoFiles: PhotoFiles
        let mirror: MirrorWriter
        var mirrorRoot: URL { folder.appending(path: "Mirror", directoryHint: .isDirectory) }
        var recipesFolder: URL { mirrorRoot.appending(path: "Recipes", directoryHint: .isDirectory) }

        init() throws {
            folder = FileManager.default.temporaryDirectory
                .appending(path: "MirrorWriterTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            let photos = folder.appending(path: "Photos", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
            photoFiles = PhotoFiles(root: photos)
            mirror = MirrorWriter(root: folder.appending(path: "Mirror", directoryHint: .isDirectory),
                                  photoFiles: photoFiles,
                                  pendingURL: folder.appending(path: "Support/pending.json"))
        }

        func remove() {
            try? FileManager.default.removeItem(at: folder)
        }

        /// A new photo file written from a made-up image; returns its name.
        func writePhoto(width: Int = 40, height: Int = 60) throws -> String {
            let image = try #require(PhotoFilesTests.makeImage(width: width, height: height))
            let fileName = PhotoEncoding.fileName(for: UUID())
            try photoFiles.write(image, fileName: fileName)
            return fileName
        }

        /// The one folder in `Recipes/` for `recipeID`.
        func recipeFolder(_ recipeID: UUID) throws -> URL? {
            let names = try FileManager.default.contentsOfDirectory(atPath: recipesFolder.path(percentEncoded: false))
            return names.first { $0.hasSuffix("-" + RecipeRendering.idPrefix(recipeID)) }
                .map { recipesFolder.appending(path: $0, directoryHint: .isDirectory) }
        }
    }

    /// Noon on 22 Nov 2026 here, so its day is 2026-11-22 in this time zone.
    static let captured: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 22, hour: 12)) ?? Date(timeIntervalSince1970: 0)
    }()

    /// A snapshot of a draft read from `fileNames`, in order; whole-second dates.
    static func snapshot(id: UUID = UUID(), fileNames: [String], updatedAt: Date = captured,
                         continuesOnUnscannedPage: Bool = false) -> MirrorSnapshot {
        let pages = fileNames.map { MirrorSnapshot.Page(pageID: UUID(), fileName: $0, capturedAt: captured) }
        let recipe = Recipe(id: id, sourcePageIDs: pages.map(\.pageID),
                            continuesOnUnscannedPage: continuesOnUnscannedPage,
                            createdAt: captured, updatedAt: updatedAt)
        return MirrorSnapshot(recipe: recipe, pages: pages)
    }

    static func modificationDate(_ url: URL) throws -> Date? {
        try url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    @Test("a write copies the recipe and its pages")
    func writeCopiesRecipeAndPages() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let first = try fixture.writePhoto()
        let second = try fixture.writePhoto(width: 60, height: 40)
        let snapshot = Self.snapshot(fileNames: [first, second])

        await fixture.mirror.write(snapshot)

        let folder = try #require(try fixture.recipeFolder(snapshot.recipe.id))
        let json = try Data(contentsOf: folder.appending(path: "recipe.json"))
        #expect(try RecipeJSON.decode(json) == snapshot.recipe)
        let markdown = try String(contentsOf: folder.appending(path: "recipe.md"), encoding: .utf8)
        #expect(markdown == RecipeRendering.markdown(snapshot.recipe, pageFileNames: ["page-1.heic", "page-2.heic"]))
        #expect(try Data(contentsOf: folder.appending(path: "pages/page-1.heic")) == Data(contentsOf: fixture.photoFiles.url(for: first)))
        #expect(try Data(contentsOf: folder.appending(path: "pages/page-2.heic")) == Data(contentsOf: fixture.photoFiles.url(for: second)))
        #expect(await fixture.mirror.pendingIDs().isEmpty)
    }

    @Test("a second write adds pages and never replaces one")
    func secondWriteAddsPages() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let first = try fixture.writePhoto()
        let second = try fixture.writePhoto(width: 60, height: 40)
        let snapshot = Self.snapshot(fileNames: [first, second], continuesOnUnscannedPage: true)
        await fixture.mirror.write(snapshot)
        let folder = try #require(try fixture.recipeFolder(snapshot.recipe.id))
        let pageOne = folder.appending(path: "pages/page-1.heic")
        let bytesBefore = try Data(contentsOf: pageOne)
        let dateBefore = try Self.modificationDate(pageOne)

        // Add Page: a third page after the two.
        let third = try fixture.writePhoto(width: 50, height: 50)
        var recipe = snapshot.recipe
        let added = MirrorSnapshot.Page(pageID: UUID(), fileName: third, capturedAt: Self.captured)
        recipe.sourcePageIDs.append(added.pageID)
        recipe.continuesOnUnscannedPage = false
        await fixture.mirror.write(MirrorSnapshot(recipe: recipe, pages: snapshot.pages + [added]))

        #expect(FileManager.default.fileExists(atPath: folder.appending(path: "pages/page-3.heic").path(percentEncoded: false)))
        #expect(try Data(contentsOf: pageOne) == bytesBefore)
        #expect(try Self.modificationDate(pageOne) == dateBefore)
    }

    @Test("a renamed folder is still found")
    func renamedFolderIsFound() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let snapshot = Self.snapshot(fileNames: [try fixture.writePhoto()])
        await fixture.mirror.write(snapshot)
        let folder = try #require(try fixture.recipeFolder(snapshot.recipe.id))
        let renamed = fixture.recipesFolder.appending(path: "x-" + RecipeRendering.idPrefix(snapshot.recipe.id), directoryHint: .isDirectory)
        try FileManager.default.moveItem(at: folder, to: renamed)
        try FileManager.default.removeItem(at: renamed.appending(path: "recipe.md"))

        await fixture.mirror.write(snapshot)

        // Found by its id and moved back to the title's name (RV-27: the title wins).
        let titledName = RecipeRendering.folderName(title: snapshot.recipe.title, id: snapshot.recipe.id)
        let names = try FileManager.default.contentsOfDirectory(atPath: fixture.recipesFolder.path(percentEncoded: false))
        #expect(names == [titledName])
        let titled = fixture.recipesFolder.appending(path: titledName, directoryHint: .isDirectory)
        #expect(FileManager.default.fileExists(atPath: titled.appending(path: "recipe.md").path(percentEncoded: false)))
    }

    @Test("a folder follows the title")
    func folderFollowsTheTitle() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let snapshot = Self.snapshot(fileNames: [try fixture.writePhoto()])
        let recipeID = snapshot.recipe.id
        await fixture.mirror.write(snapshot)
        let draftFolder = try #require(try fixture.recipeFolder(recipeID))
        #expect(draftFolder.lastPathComponent == "new-recipe-" + RecipeRendering.idPrefix(recipeID))
        let pageOne = draftFolder.appending(path: "pages/page-1.heic")
        let bytesBefore = try Data(contentsOf: pageOne)
        let dateBefore = try Self.modificationDate(pageOne)

        var titled = snapshot.recipe
        titled.title = "Test Soup"
        await fixture.mirror.write(MirrorSnapshot(recipe: titled, pages: snapshot.pages))

        let names = try FileManager.default.contentsOfDirectory(atPath: fixture.recipesFolder.path(percentEncoded: false))
        #expect(names == ["test-soup-" + RecipeRendering.idPrefix(recipeID)])
        let movedName = try #require(names.first)
        let movedPage = fixture.recipesFolder.appending(path: movedName, directoryHint: .isDirectory)
            .appending(path: "pages/page-1.heic")
        #expect(try Data(contentsOf: movedPage) == bytesBefore)
        #expect(try Self.modificationDate(movedPage) == dateBefore)
    }

    // MARK: A recipe's pages (`15` M3-4)

    @Test("pages rewritten in order")
    func pagesRewrittenInOrder() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let first = try fixture.writePhoto()
        let second = try fixture.writePhoto(width: 60, height: 40)
        let snapshot = Self.snapshot(fileNames: [first, second])
        await fixture.mirror.write(snapshot)
        let folder = try #require(try fixture.recipeFolder(snapshot.recipe.id))
        let oldPageTwo = try Data(contentsOf: folder.appending(path: "pages/page-2.heic"))

        var recipe = snapshot.recipe
        recipe.sourcePageIDs.reverse()
        await fixture.mirror.write(MirrorSnapshot(recipe: recipe, pages: snapshot.pages.reversed(), pagesChanged: true))

        #expect(try Data(contentsOf: folder.appending(path: "pages/page-1.heic")) == oldPageTwo)
    }

    @Test("a removed page goes")
    func removedPageGoes() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let snapshot = Self.snapshot(fileNames: [try fixture.writePhoto(), try fixture.writePhoto(), try fixture.writePhoto()])
        await fixture.mirror.write(snapshot)
        let folder = try #require(try fixture.recipeFolder(snapshot.recipe.id))

        var recipe = snapshot.recipe
        recipe.sourcePageIDs.removeLast()
        await fixture.mirror.write(MirrorSnapshot(recipe: recipe, pages: Array(snapshot.pages.prefix(2)), pagesChanged: true))

        let names = try FileManager.default.contentsOfDirectory(atPath: folder.appending(path: "pages").path(percentEncoded: false))
        #expect(names.sorted() == ["page-1.heic", "page-2.heic"])
    }

    @Test("deleting removes the recipe's folder")
    func deletingRemovesRecipeFolder() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let first = try fixture.writePhoto()
        let second = try fixture.writePhoto(width: 60, height: 40)
        let snapshot = Self.snapshot(fileNames: [first, second])
        await fixture.mirror.write(snapshot)
        let folder = try #require(try fixture.recipeFolder(snapshot.recipe.id))
        // Marked pending, as a copy not yet complete would be.
        let pendingURL = fixture.folder.appending(path: "Support/pending.json")
        try FileManager.default.createDirectory(at: pendingURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode([snapshot.recipe.id.uuidString]).write(to: pendingURL)
        #expect(await fixture.mirror.pendingIDs() == [snapshot.recipe.id])

        await fixture.mirror.removeRecipe(recipeID: snapshot.recipe.id)

        #expect(!FileManager.default.fileExists(atPath: folder.path(percentEncoded: false)))
        let pagesWithoutRecipe = fixture.mirrorRoot.appending(path: "Pages without a recipe", directoryHint: .isDirectory)
        #expect(!FileManager.default.fileExists(atPath: pagesWithoutRecipe.path(percentEncoded: false)))
        // The mirror never removes a photo.
        #expect(FileManager.default.fileExists(atPath: fixture.photoFiles.url(for: first).path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: fixture.photoFiles.url(for: second).path(percentEncoded: false)))
        #expect(await fixture.mirror.pendingIDs().isEmpty)
    }

    @Test("a missing photo leaves the recipe pending")
    func missingPhotoLeavesRecipePending() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let missing = PhotoEncoding.fileName(for: UUID())
        let snapshot = Self.snapshot(fileNames: [missing])

        await fixture.mirror.write(snapshot)

        let folder = try #require(try fixture.recipeFolder(snapshot.recipe.id))
        #expect(FileManager.default.fileExists(atPath: folder.appending(path: "recipe.json").path(percentEncoded: false)))
        #expect(!FileManager.default.fileExists(atPath: folder.appending(path: "pages/page-1.heic").path(percentEncoded: false)))
        #expect(await fixture.mirror.pendingIDs() == [snapshot.recipe.id])

        // The photo arrives; catch-up copies it and clears the pending entry.
        let image = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        try fixture.photoFiles.write(image, fileName: missing)
        await fixture.mirror.catchUp([snapshot])

        #expect(try Data(contentsOf: folder.appending(path: "pages/page-1.heic")) == Data(contentsOf: fixture.photoFiles.url(for: missing)))
        #expect(await fixture.mirror.pendingIDs().isEmpty)
    }

    @Test("catch-up writes only what's missing")
    func catchUpWritesOnlyWhatIsMissing() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let now = Date()
        let old = now.addingTimeInterval(-3_600)
        let withFolder = Self.snapshot(fileNames: [try fixture.writePhoto()], updatedAt: old)
        let withoutFolder = Self.snapshot(fileNames: [try fixture.writePhoto()], updatedAt: old)
        let recentlyUpdated = Self.snapshot(fileNames: [try fixture.writePhoto()], updatedAt: now.addingTimeInterval(-60))
        await fixture.mirror.write(withFolder)
        let existingFolder = try #require(try fixture.recipeFolder(withFolder.recipe.id))
        let jsonDateBefore = try Self.modificationDate(existingFolder.appending(path: "recipe.json"))

        await fixture.mirror.catchUp([withFolder, withoutFolder, recentlyUpdated], now: now)

        #expect(try Self.modificationDate(existingFolder.appending(path: "recipe.json")) == jsonDateBefore)
        #expect(try fixture.recipeFolder(withoutFolder.recipe.id) != nil)
        #expect(try fixture.recipeFolder(recentlyUpdated.recipe.id) == nil)
    }
}
