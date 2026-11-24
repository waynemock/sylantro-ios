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

    @Test("deleting a recipe removes its pages, photos and files")
    func deletingRecipeRemovesEverything() async throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let tall = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let wide = try #require(PhotoFilesTests.makeImage(width: 60, height: 40))
        let sessionID = try recorder.startSession(now: Self.now)
        let recipeID = try recorder.saveCapture([tall, wide], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)
        let photoFiles = PhotoFiles(root: folder)
        let fileNames = try context.fetch(FetchDescriptor<PhotoModel>()).compactMap(\.fileName)
        #expect(fileNames.count == 2)

        let removal = try RecipeEditor(context: context, photoFiles: photoFiles).delete(recipeID)
        await removal?.value

        #expect(try context.fetch(FetchDescriptor<RecipeModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<SourcePageModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<PhotoModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<ScanSessionModel>()).isEmpty)
        for fileName in fileNames {
            #expect(!FileManager.default.fileExists(atPath: photoFiles.url(for: fileName).path(percentEncoded: false)))
        }
    }

    @Test("a page another recipe uses is kept")
    func pageAnotherRecipeUsesIsKept() async throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let tall = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let wide = try #require(PhotoFilesTests.makeImage(width: 60, height: 40))
        let sessionID = try recorder.startSession(now: Self.now)
        let firstID = try recorder.saveCapture([tall], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)
        let secondID = try recorder.saveCapture([wide], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)
        let photoFiles = PhotoFiles(root: folder)
        let editor = RecipeEditor(context: context, photoFiles: photoFiles)

        // The first recipe's page is also listed by the second (SLT-047, M3).
        let firstModel = try #require(try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == firstID })).first)
        let sharedPageID = try #require(firstModel.toDomain()?.sourcePageIDs.first)
        try editor.appendPages([sharedPageID], to: secondID, now: Self.now)
        try context.save()
        let secondBefore = try #require(try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == secondID })).first?.toDomain())
        let sharedPhoto = try #require(try context.fetch(FetchDescriptor<PhotoModel>()).first { $0.sourcePageID == sharedPageID })
        let sharedFileName = try #require(sharedPhoto.fileName)

        let removal = try editor.delete(firstID)
        await removal?.value

        #expect(try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == firstID })).isEmpty)
        #expect(try context.fetch(FetchDescriptor<SourcePageModel>()).contains { $0.id == sharedPageID })
        #expect(try context.fetch(FetchDescriptor<PhotoModel>()).contains { $0.sourcePageID == sharedPageID })
        #expect(FileManager.default.fileExists(atPath: photoFiles.url(for: sharedFileName).path(percentEncoded: false)))
        let secondAfter = try #require(try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == secondID })).first?.toDomain())
        #expect(secondAfter == secondBefore)
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

    // MARK: The queue's writes (`15` M3-2)

    /// Inserts `count` copies of a waiting page with no reading, and saves.
    static func insertPageCopies(_ page: SourcePage, count: Int, in context: ModelContext) throws {
        for _ in 0..<count {
            let model = SourcePageModel()
            model.hydrate(from: page)
            context.insert(model)
        }
        try context.save()
    }

    static func word(_ text: String, pageID: UUID) -> OCRWord {
        OCRWord(text: text, box: SourceBox(pageID: pageID, x: 0.125, y: 0.25, width: 0.5, height: 0.0625), confidence: 0.5)
    }

    @Test("the reading is written")
    func readingIsWritten() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let page = SourcePage(capturedAt: Self.now)
        try Self.insertPageCopies(page, count: 2, in: context)
        let words = [Self.word("Test Soup", pageID: page.id), Self.word("2 cups water", pageID: page.id)]

        try recorder.recordReading(pageID: page.id, text: "Test Soup\n2 cups water", words: words)

        let copies = try context.fetch(FetchDescriptor<SourcePageModel>()).compactMap { $0.toDomain() }
        #expect(copies.count == 2)
        for copy in copies {
            #expect(copy.ocrText == "Test Soup\n2 cups water")
            #expect(copy.ocrWords == words)
        }
    }

    @Test("read once")
    func readOnce() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let first = [Self.word("Test Soup", pageID: UUID())]
        let page = SourcePage(capturedAt: Self.now, ocrText: "Test Soup", ocrWords: first)
        try Self.insertPageCopies(page, count: 1, in: context)

        try recorder.recordReading(pageID: page.id, text: "Made-up Other Text",
                                   words: [Self.word("Made-up Other Text", pageID: page.id)])

        let copy = try #require(try context.fetch(FetchDescriptor<SourcePageModel>()).first?.toDomain())
        #expect(copy.ocrText == "Test Soup")
        #expect(copy.ocrWords == first)
    }

    @Test("structured")
    func structuredRecipeIsSaved() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let image = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let sessionID = try recorder.startSession(now: Self.now)
        let recipeID = try recorder.saveCapture([image, image], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)
        let structured = Recipe(title: "Test Soup", steps: [Step(text: "Boil the water.")])

        let saved = try recorder.finishStructuring(structured, recipeID: recipeID, lastPageEnds: false, now: Self.now.addingTimeInterval(60))

        #expect(saved)
        let recipe = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first?.toDomain())
        #expect(recipe.id == recipeID)
        #expect(recipe.title == "Test Soup")
        #expect(recipe.steps.map(\.text) == ["Boil the water."])
        let pages = try context.fetch(FetchDescriptor<SourcePageModel>()).compactMap { $0.toDomain() }
        #expect(pages.count == 2)
        #expect(pages.allSatisfy { $0.structuringState == .structured })
    }

    @Test("already done")
    func alreadyDoneIsNotSaved() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let image = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let sessionID = try recorder.startSession(now: Self.now)
        let recipeID = try recorder.saveCapture([image], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)
        _ = try recorder.finishStructuring(Recipe(title: "Test Soup"), recipeID: recipeID, lastPageEnds: false, now: Self.now)
        let before = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first?.toDomain())

        let saved = try recorder.finishStructuring(Recipe(title: "Made-up Other Title"), recipeID: recipeID, lastPageEnds: false,
                                                   now: Self.now.addingTimeInterval(60))

        #expect(!saved)
        let after = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first?.toDomain())
        #expect(after == before)
    }

    @Test("failed")
    func pagesAreMarkedFailed() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let page = SourcePage(capturedAt: Self.now)
        let other = SourcePage(capturedAt: Self.now)
        try Self.insertPageCopies(page, count: 2, in: context)
        try Self.insertPageCopies(other, count: 1, in: context)

        try recorder.markFailed(pageIDs: [page.id])

        let pages = try context.fetch(FetchDescriptor<SourcePageModel>()).compactMap { $0.toDomain() }
        #expect(pages.filter { $0.id == page.id }.map(\.structuringState) == [.failed, .failed])
        #expect(pages.filter { $0.id == other.id }.map(\.structuringState) == [.waiting])
    }

    @Test("the queue is told")
    func queueIsTold() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, _, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        var told: [UUID] = []
        recorder.onRecipeSaved = { told.append($0) }
        let image = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let sessionID = try recorder.startSession(now: Self.now)

        let recipeID = try recorder.saveCapture([image], sessionID: sessionID, continuesOnUnscannedPage: false, now: Self.now)
        try recorder.addPages([image], to: recipeID, sessionID: sessionID, now: Self.now)

        #expect(told == [recipeID, recipeID])
    }

    @Test("an edited recipe is kept")
    func editedRecipeIsKept() throws {
        let container = try ModelTwinTests.makeContainer()
        let context = container.mainContext
        let edited = Recipe(title: "Her Test Soup", reviewState: .edited, createdAt: Self.now, updatedAt: Self.now)
        let model = RecipeModel()
        model.hydrate(from: edited)
        context.insert(model)
        try context.save()

        #expect(throws: RecipeEditorError.recipeEdited(edited.id)) {
            try RecipeEditor(context: context).applyStructure(Recipe(title: "Test Soup"), to: edited.id, lastPageEnds: false, now: Self.now)
        }

        let after = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first?.toDomain())
        #expect(after == edited)
    }

    @Test("the warning is cleared")
    func warningIsCleared() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (recorder, context, container) = try Self.makeRecorder(photoRoot: folder)
        _ = container
        let image = try #require(PhotoFilesTests.makeImage(width: 40, height: 60))
        let sessionID = try recorder.startSession(now: Self.now)
        // Saved with Save Without It: the page-2 warning is on.
        let recipeID = try recorder.saveCapture([image], sessionID: sessionID, continuesOnUnscannedPage: true, now: Self.now)

        let saved = try recorder.finishStructuring(Recipe(title: "Test Soup"), recipeID: recipeID, lastPageEnds: true,
                                                   now: Self.now.addingTimeInterval(60))

        #expect(saved)
        let recipe = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first?.toDomain())
        #expect(recipe.continuesOnUnscannedPage == false)
    }
}
