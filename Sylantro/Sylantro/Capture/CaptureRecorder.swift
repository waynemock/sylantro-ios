import Foundation
import CoreGraphics
import SwiftData
import SyLibCore

/// Why `CaptureRecorder` didn't save.
enum CaptureRecorderError: Error, Equatable {
    /// A capture with no pages.
    case noPages
}

/// The writer for captures (`02` §5.2, SLT-082): it saves a capture's pages, their photos and one
/// new recipe (SC-1) in one save, and only ever adds. Photo files are written first, so a capture
/// is never saved without them; files already written are kept even when the save fails (SLT-030).
@MainActor
final class CaptureRecorder {
    private let log = AppLogger(category: "Capture")
    private let context: ModelContext
    private let photoFiles: PhotoFiles
    private let recipeEditor: RecipeEditor

    init(context: ModelContext, photoFiles: PhotoFiles, recipeEditor: RecipeEditor) {
        self.context = context
        self.photoFiles = photoFiles
        self.recipeEditor = recipeEditor
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
