import Foundation
import CoreGraphics
import SwiftData
import SyLibCore

/// Why `CaptureRecorder` didn't save.
enum CaptureRecorderError: Error, Equatable {
    /// A capture with no pages.
    case noPages
    /// No page has this id.
    case pageNotFound(UUID)
}

/// The writer for captures (`02` §5.2, SLT-082): it saves a capture's pages, their photos and one
/// new recipe (SC-1) in one save, and only ever adds. Photo files are written first, so a capture
/// is never saved without them; files already written are kept even when the save fails (SLT-030).
/// For the queue (`15` M3-2) it also writes a page's reading once, its structuring state, and a
/// structured recipe with its pages in one save.
@MainActor
final class CaptureRecorder {
    private let log = AppLogger(category: "Capture")
    private let context: ModelContext
    private let photoFiles: PhotoFiles
    private let recipeEditor: RecipeEditor
    /// The copy in Files, written after each save on this device (MT-15); nil writes none.
    private let mirror: MirrorWriter?
    /// Told the recipe's id after each capture or Add Page saved here, so the queue takes it first
    /// (RV-3); never after a failure.
    var onRecipeSaved: ((UUID) -> Void)?

    init(context: ModelContext, photoFiles: PhotoFiles, recipeEditor: RecipeEditor, mirror: MirrorWriter? = nil) {
        self.context = context
        self.photoFiles = photoFiles
        self.recipeEditor = recipeEditor
        self.mirror = mirror
    }

    /// Starts a scanning session and saves it.
    func startSession(now: Date = Date()) throws -> UUID {
        let session = ScanSession(startedAt: now)
        let model = ScanSessionModel()
        model.hydrate(from: session)
        context.insert(model)
        do {
            try context.save()
        } catch {
            context.rollback()
            log.error(self, "session not saved: \(error)")
            throw error
        }
        log.info(self, "session \(session.id) started")
        return session.id
    }

    /// Saves `pages`, in order, as one new recipe in `sessionID`, and returns the recipe's id.
    func saveCapture(_ pages: [CGImage], sessionID: UUID, continuesOnUnscannedPage: Bool, now: Date = Date()) throws -> UUID {
        let written = try writePhotos(pages)
        do {
            insertPages(written, sessionID: sessionID, now: now)
            let recipe = recipeEditor.insertDraft(pageIDs: written.map(\.pageID),
                                                  continuesOnUnscannedPage: continuesOnUnscannedPage,
                                                  now: now)
            try context.save()
            log.info(self, "capture saved: \(pages.count) pages, recipe \(recipe.id)")
            mirrorAfterSave(recipe)
            onRecipeSaved?(recipe.id)
            return recipe.id
        } catch {
            context.rollback()
            log.error(self, "capture not saved (\(pages.count) pages; their files are kept): \(error)")
            throw error
        }
    }

    /// Saves `pages`, in order, after the recipe's pages (Add Page), clearing its page-2 warning.
    func addPages(_ pages: [CGImage], to recipeID: UUID, sessionID: UUID, now: Date = Date()) throws {
        let written = try writePhotos(pages)
        do {
            insertPages(written, sessionID: sessionID, now: now)
            try recipeEditor.appendPages(written.map(\.pageID), to: recipeID, now: now)
            try context.save()
            log.info(self, "pages added: \(pages.count) pages, recipe \(recipeID)")
        } catch {
            context.rollback()
            log.error(self, "pages not added to recipe \(recipeID) (\(pages.count) pages; their files are kept): \(error)")
            throw error
        }
        mirrorAfterSave(recipeID: recipeID)
        onRecipeSaved?(recipeID)
    }

    // MARK: The queue's writes (`15` M3-2)

    /// Writes the page's reading on every copy that has none, and saves; a copy already read is
    /// left as it is (`01` §3.2, RV-4). Throws when no copy of the page exists.
    func recordReading(pageID: UUID, text: String, words: [OCRWord]) throws {
        let models = try context.fetch(FetchDescriptor<SourcePageModel>(predicate: #Predicate { $0.id == pageID }))
        guard !models.isEmpty else {
            throw CaptureRecorderError.pageNotFound(pageID)
        }
        var written = 0
        for model in models where model.ocrText == nil {
            guard var page = model.toDomain() else { continue }
            page.ocrText = text
            page.ocrWords = words
            model.hydrate(from: page)
            written += 1
        }
        try save("page \(pageID): reading not saved")
        log.info(self, "page \(pageID): reading written on \(written) of \(models.count) copies, \(words.count) lines")
    }

    /// Saves the queue's structured reading of the recipe (RV-3): false, changing nothing, when
    /// none of its pages is waiting any more (another device got there first). Otherwise the recipe
    /// becomes the reading (`RecipeEditor.applyStructure`) and every copy of its pages is marked
    /// structured, in one save, then its copy in Files is written. `lastPageEnds` clears its page-2
    /// warning (M3-2a, RV-26). A failed save is rolled back and rethrown.
    func finishStructuring(_ structured: Recipe, recipeID: UUID, lastPageEnds: Bool, now: Date) throws -> Bool {
        let recipeModels = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID }))
        let pageIDs = Set(recipeModels.compactMap { $0.toDomain() }.flatMap(\.sourcePageIDs))
        let pages = try pageModels(pageIDs)
        guard pages.contains(where: { $0.structuringStateRaw == StructuringState.waiting.rawValue }) else {
            log.info(self, "recipe \(recipeID): not saved, no page waiting")
            return false
        }
        do {
            try recipeEditor.applyStructure(structured, to: recipeID, lastPageEnds: lastPageEnds, now: now)
            for page in pages {
                page.structuringStateRaw = StructuringState.structured.rawValue
            }
            try context.save()
        } catch {
            context.rollback()
            log.error(self, "recipe \(recipeID): structured reading not saved: \(error)")
            throw error
        }
        log.info(self, "recipe \(recipeID): structured, \(pages.count) page copies marked")
        mirrorAfterSave(recipeID: recipeID)
        return true
    }

    /// Try Again (S-48, RV-24): every copy of the recipe's failed pages waits again, saved, and
    /// the queue is told (`onRecipeSaved`). With no failed page it does nothing and doesn't save.
    func retryFailed(recipeID: UUID) throws {
        let recipeModels = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID }))
        let pageIDs = Set(recipeModels.compactMap { $0.toDomain() }.flatMap(\.sourcePageIDs))
        let failed = try pageModels(pageIDs).filter { $0.structuringStateRaw == StructuringState.failed.rawValue }
        guard !failed.isEmpty else {
            log.info(self, "recipe \(recipeID): Try Again, no failed page")
            return
        }
        for page in failed {
            page.structuringStateRaw = StructuringState.waiting.rawValue
        }
        try save("recipe \(recipeID): failed pages not reset")
        log.info(self, "recipe \(recipeID): Try Again, \(failed.count) page copies waiting")
        onRecipeSaved?(recipeID)
    }

    /// Read Again after its pages changed (RV-7, `15` M3-4): an edited recipe needs review again
    /// (`RecipeEditor.reopenForReading`), every copy of each of its pages waits, in one save; then
    /// the queue is told, so it structures the recipe again from its pages in order. A page already
    /// read keeps its reading, so only new pages are read (RV-4).
    func readAgain(recipeID: UUID, now: Date) throws {
        let recipeModels = try context.fetch(FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID }))
        guard !recipeModels.isEmpty else {
            throw RecipeEditorError.recipeNotFound(recipeID)
        }
        let recipes = recipeModels.compactMap { $0.toDomain() }
        let pages = try pageModels(Set(recipes.flatMap(\.sourcePageIDs)))
        do {
            if recipes.contains(where: { $0.reviewState == .edited }) {
                try recipeEditor.reopenForReading(recipeID, now: now)
            }
            for page in pages {
                page.structuringStateRaw = StructuringState.waiting.rawValue
            }
            try context.save()
        } catch {
            context.rollback()
            log.error(self, "recipe \(recipeID): not read again: \(error)")
            throw error
        }
        log.info(self, "recipe \(recipeID): read again, \(pages.count) page copies waiting")
        onRecipeSaved?(recipeID)
    }

    /// Marks every copy of the pages failed (RV-24), and saves.
    func markFailed(pageIDs: [UUID]) throws {
        let pages = try pageModels(Set(pageIDs))
        for page in pages {
            page.structuringStateRaw = StructuringState.failed.rawValue
        }
        try save("pages not marked failed")
        log.info(self, "\(pages.count) page copies marked failed")
    }

    /// Every copy of the pages with these ids.
    private func pageModels(_ pageIDs: Set<UUID>) throws -> [SourcePageModel] {
        try context.fetch(FetchDescriptor<SourcePageModel>()).filter { pageIDs.contains($0.id) }
    }

    /// Saves, or rolls back, logs and rethrows.
    private func save(_ failure: String) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            log.error(self, "\(failure): \(error)")
            throw error
        }
    }

    // MARK: The copy in Files

    /// After a save: the recipe's snapshot, built here on the main actor, handed to the mirror,
    /// which never blocks or undoes the save (`02` §5.2).
    private func mirrorAfterSave(_ recipe: Recipe) {
        guard let mirror else { return }
        do {
            guard let snapshot = try MirrorSnapshot.make(for: [recipe], in: context).first else { return }
            Task { await mirror.write(snapshot) }
        } catch {
            log.error(self, "recipe \(recipe.id): no copy in Files: \(error)")
        }
    }

    /// After Add Page: the recipe as saved, read back from the store.
    private func mirrorAfterSave(recipeID: UUID) {
        guard mirror != nil else { return }
        var descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID })
        descriptor.fetchLimit = 1
        guard let recipe = (try? context.fetch(descriptor))?.first?.toDomain() else {
            log.error(self, "recipe \(recipeID): no copy in Files: not readable")
            return
        }
        mirrorAfterSave(recipe)
    }

    // MARK: Steps

    /// One page's new ids, its file and its pixel size.
    private struct WrittenPage {
        let pageID: UUID
        let photoID: UUID
        let fileName: String
        let width: Int
        let height: Int
    }

    /// Step 1: every page's file, in order, before anything is inserted. A failed write stops here;
    /// the files already written stay and are logged.
    private func writePhotos(_ pages: [CGImage]) throws -> [WrittenPage] {
        guard !pages.isEmpty else { throw CaptureRecorderError.noPages }
        var written: [WrittenPage] = []
        for image in pages {
            let pageID = UUID()
            let photoID = UUID()
            let fileName = PhotoEncoding.fileName(for: photoID)
            do {
                let size = try photoFiles.write(image, fileName: fileName)
                written.append(WrittenPage(pageID: pageID, photoID: photoID, fileName: fileName,
                                           width: size.width, height: size.height))
            } catch {
                log.error(self, "photo \(written.count + 1) of \(pages.count) not written: \(error); kept: \(written.map(\.fileName))")
                throw error
            }
        }
        return written
    }

    /// Step 2: a scanned page waiting to be read and its one cropped photo (MT-7), per page.
    private func insertPages(_ written: [WrittenPage], sessionID: UUID, now: Date) {
        for page in written {
            let pageModel = SourcePageModel()
            pageModel.hydrate(from: SourcePage(id: page.pageID, kind: .scan, sessionID: sessionID,
                                               capturedAt: now, structuringState: .waiting))
            context.insert(pageModel)

            let photoModel = PhotoModel()
            photoModel.hydrate(from: Photo(id: page.photoID, kindRaw: PhotoKind.pageCropped.rawValue,
                                           sourcePageID: page.pageID, pixelWidth: page.width,
                                           pixelHeight: page.height, takenAt: now, fileName: page.fileName))
            context.insert(photoModel)
        }
    }
}
