import CoreGraphics
import Foundation
import SwiftData
import Testing
@testable import Sylantro

/// Saving a capture (`14` Task M2-3): its pages, their photos and one new recipe in one save, Add
/// Page, and a failed photo write that saves nothing. On an in-memory container and a temporary
/// folder, with small made-up images.
@MainActor
@Suite("Capture recorder")
struct CaptureRecorderTests {
    static let now = Date(timeIntervalSince1970: 1_795_000_000)

    /// A recorder on a fresh in-memory store and `photoRoot`.
    static func makeRecorder(photoRoot: URL) throws -> (recorder: CaptureRecorder, context: ModelContext, container: ModelContainer) {
        let container = try ModelTwinTests.makeContainer()
        let context = container.mainContext
        let recorder = CaptureRecorder(context: context,
                                       photoFiles: PhotoFiles(root: photoRoot),
                                       recipeEditor: RecipeEditor(context: context))
        return (recorder, context, container)
    }

    /// A new, empty temporary folder; the caller removes it.
    static func makeFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "CaptureRecorderTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    @Test("a capture becomes one recipe with its pages")
    func captureBecomesOneRecipe() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let tall = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let wide = try #require(PhotoFilesTests.makeImage(width: 60, height: 40))

        let sessionID = try recorder.startSession(now: Self.now)
        let recipeID = try recorder.saveCapture([tall, wide], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)

        #expect(try context.fetch(FetchDescriptor<ScanSessionModel>()).count == 1)

        let pages = try context.fetch(FetchDescriptor<SourcePageModel>()).compactMap { $0.toDomain() }
        #expect(pages.count == 2)
        for page in pages {
            #expect(page.kind == .scan)
            #expect(page.structuringState == .waiting)
            #expect(page.sessionID == sessionID)
        }

        let photos = try context.fetch(FetchDescriptor<PhotoModel>()).compactMap { $0.toDomain() }
        #expect(photos.count == 2)
        let photoFiles = PhotoFiles(root: folder)
        for photo in photos {
            #expect(photo.kind == .pageCropped)
            let pageID = try #require(photo.sourcePageID)
            #expect(pages.contains { $0.id == pageID })
            let fileName = try #require(photo.fileName)
            #expect(FileManager.default.fileExists(atPath: photoFiles.url(for: fileName).path(percentEncoded: false)))
        }
        let tallPhoto = try #require(photos.first { $0.pixelWidth == 40 && $0.pixelHeight == 60 })
        let widePhoto = try #require(photos.first { $0.pixelWidth == 60 && $0.pixelHeight == 40 })

        let recipes = try context.fetch(FetchDescriptor<RecipeModel>())
        #expect(recipes.count == 1)
        let recipe = try #require(recipes.first?.toDomain())
        #expect(recipe.id == recipeID)
        #expect(recipe.title == "")
        // In capture order: the tall page was first.
        #expect(recipe.sourcePageIDs == [tallPhoto.sourcePageID, widePhoto.sourcePageID].compactMap { $0 })
        #expect(recipe.reviewState == .needsReview)
        #expect(recipe.continuesOnUnscannedPage == false)
    }

    @Test("Save Without It marks the recipe, Add Page clears it")
    func saveWithoutItThenAddPage() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let tall = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let wide = try #require(PhotoFilesTests.makeImage(width: 60, height: 40))

        let sessionID = try recorder.startSession(now: Self.now)
        let recipeID = try recorder.saveCapture([tall, wide], sessionID: sessionID, continuesOnUnscannedPage: true, now: Self.now)
        let marked = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first?.toDomain())
        #expect(marked.continuesOnUnscannedPage == true)
        let firstTwo = marked.sourcePageIDs

        try recorder.addPages([tall], to: recipeID, sessionID: sessionID, now: Self.now.addingTimeInterval(60))

        let recipe = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first?.toDomain())
        #expect(recipe.sourcePageIDs.count == 3)
        #expect(Array(recipe.sourcePageIDs.prefix(2)) == firstTwo)
        let pageIDs = Set(try context.fetch(FetchDescriptor<SourcePageModel>()).map(\.id))
        #expect(pageIDs == Set(recipe.sourcePageIDs))
        #expect(recipe.continuesOnUnscannedPage == false)
    }

    @Test("deleting a recipe keeps its pages and photos")
    func deletingRecipeKeepsPagesAndPhotos() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let tall = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let wide = try #require(PhotoFilesTests.makeImage(width: 60, height: 40))
        let sessionID = try recorder.startSession(now: Self.now)
        let recipeID = try recorder.saveCapture([tall, wide], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)

        try RecipeEditor(context: context).delete(recipeID)

        #expect(try context.fetch(FetchDescriptor<RecipeModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<SourcePageModel>()).count == 2)
        let photos = try context.fetch(FetchDescriptor<PhotoModel>())
        #expect(photos.count == 2)
        let photoFiles = PhotoFiles(root: folder)
        for photo in photos {
            let fileName = try #require(photo.fileName)
            #expect(FileManager.default.fileExists(atPath: photoFiles.url(for: fileName).path(percentEncoded: false)))
        }
    }

    @Test("a failed photo write saves nothing")
    func failedPhotoWriteSavesNothing() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        // The photo root is a file, not a folder, so no photo can be written into it.
        let notAFolder = folder.appending(path: "Photos")
        try Data([0x00]).write(to: notAFolder)
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: notAFolder)
        _ = container
        let tall = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))

        let sessionID = try recorder.startSession(now: Self.now)
        #expect(throws: (any Error).self) {
            try recorder.saveCapture([tall], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)
        }

        #expect(try context.fetch(FetchDescriptor<SourcePageModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<PhotoModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RecipeModel>()).isEmpty)
    }
}
