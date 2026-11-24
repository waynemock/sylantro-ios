import Foundation
import SwiftData
import SyLibCore

/// What `MirrorWriter` needs to copy one recipe: the recipe, and its pages in order with each
/// page's photo file and when it was captured.
nonisolated struct MirrorSnapshot: Sendable {
    nonisolated struct Page: Sendable {
        let pageID: UUID
        /// The page photo's file in `PhotoFiles`' folder; nil if the page has no photo record yet.
        let fileName: String?
        let capturedAt: Date
    }

    let recipe: Recipe
    let pages: [Page]
}

extension MirrorSnapshot {
    /// Snapshots of `recipes`, read from the store on the main actor: each recipe's pages in
    /// `sourcePageIDs` order, with its cropped photo (MT-7) or any photo of it.
    @MainActor
    static func make(for recipes: [Recipe], in context: ModelContext) throws -> [MirrorSnapshot] {
        var capturedAtByPage: [UUID: Date] = [:]
        for page in try context.fetch(FetchDescriptor<SourcePageModel>()) where capturedAtByPage[page.id] == nil {
            capturedAtByPage[page.id] = page.capturedAt
        }
        var photoByPage: [UUID: PhotoModel] = [:]
        for photo in try context.fetch(FetchDescriptor<PhotoModel>(predicate: #Predicate { $0.sourcePageID != nil })) {
            guard let pageID = photo.sourcePageID else { continue }
            if photoByPage[pageID] == nil || photo.kindRaw == PhotoKind.pageCropped.rawValue {
                photoByPage[pageID] = photo
            }
        }
        return recipes.map { recipe in
            MirrorSnapshot(recipe: recipe, pages: recipe.sourcePageIDs.map { pageID in
                Page(pageID: pageID,
                     fileName: photoByPage[pageID]?.fileName,
                     capturedAt: capturedAtByPage[pageID] ?? recipe.createdAt)
            })
        }
    }
}

/// The plain copy of every recipe in Files (`02` §5.4, SLT-050): `Recipes/<folder>/recipe.json`,
/// `recipe.md` and `pages/page-<n>.heic`. Written by the device that made the change (MT-15), after
/// its save, never blocking or undoing it; never read back as the app's data (SLT-052). A title
/// change renames its folder (`02` §5.4, RV-27); an iCloud placeholder is never moved. Page copies
/// are never replaced; a recipe she deletes has its whole folder removed (SLT-157). The mirror never
/// changes anything in `PhotoFiles`' folder. HEIC only (SLT-054).
actor MirrorWriter {
    private let log = AppLogger(category: "Mirror")

    /// The mirror folder.
    let root: URL
    let photoFiles: PhotoFiles
    /// The device-only list of recipes whose copy isn't complete yet; never in the mirror.
    let pendingURL: URL

    static let recipesFolderName = "Recipes"
    /// A recipe changed more recently than this may still have its copy arriving from the device
    /// that saved it (MT-15).
    static let catchUpQuietPeriod: TimeInterval = 10 * 60

    init(root: URL, photoFiles: PhotoFiles, pendingURL: URL) {
        self.root = root
        self.photoFiles = photoFiles
        self.pendingURL = pendingURL
    }

    /// The mirror folder: `<container>/Documents/` with iCloud, the app's own `Documents/` with it
    /// off (MT-17).
    static func resolveRoot(ubiquityContainer: URL?, documents: URL) -> URL {
        guard let ubiquityContainer else { return documents }
        return ubiquityContainer.appending(path: "Documents", directoryHint: .isDirectory)
    }

    /// The live mirror. The ubiquity container is asked for in a detached task, off the main actor,
    /// as `PhotoFiles.live()` does.
    @MainActor
    static func live(photoFiles: PhotoFiles) async -> MirrorWriter {
        let containerID = SylantroApp.cloudKitContainerID
        let ubiquityContainer = await Task.detached {
            FileManager.default.url(forUbiquityContainerIdentifier: containerID)
        }.value
        let root = resolveRoot(ubiquityContainer: ubiquityContainer, documents: URL.documentsDirectory)
        let pendingURL = URL.applicationSupportDirectory
            .appending(path: "Mirror", directoryHint: .isDirectory)
            .appending(path: "pending.json")
        let log = AppLogger(category: "Mirror")
        do {
            try FileManager.default.createDirectory(at: root.appending(path: recipesFolderName, directoryHint: .isDirectory),
                                                    withIntermediateDirectories: true)
        } catch {
            log.error(MirrorWriter.self, "Recipes folder not created: \(error)")
        }
        log.info(MirrorWriter.self, "mirror folder (\(ubiquityContainer == nil ? "local" : "iCloud")): \(root.path(percentEncoded: false))")
        return MirrorWriter(root: root, photoFiles: photoFiles, pendingURL: pendingURL)
    }

    private var recipesFolder: URL {
        root.appending(path: Self.recipesFolderName, directoryHint: .isDirectory)
    }

    // MARK: Writing a recipe

    /// Copies the recipe: its folder (moved to its title's name when that changed), page copies not
    /// already there, and `recipe.json` and `recipe.md` replaced. A failure or a page not yet on this device leaves it pending. Never
    /// throws.
    func write(_ snapshot: MirrorSnapshot) {
        let recipeID = snapshot.recipe.id
        var isComplete = true
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: recipesFolder, withIntermediateDirectories: true)
            let titledName = RecipeRendering.folderName(title: snapshot.recipe.title, id: recipeID)
            let titled = recipesFolder.appending(path: titledName, directoryHint: .isDirectory)
            var folder = titled
            if let existing = existingFolder(for: recipeID) {
                folder = existing
                // A title change renames its folder (`02` §5.4, RV-27), when nothing is at the new
                // name. A failed move writes into the old folder. Logged by recipe id only.
                if existing.lastPathComponent != titledName, !exists(titled) {
                    do {
                        try move(existing, to: titled)
                        folder = titled
                        log.info(self, "recipe \(recipeID): folder renamed to follow its title")
                    } catch {
                        let nsError = error as NSError
                        log.error(self, "recipe \(recipeID): folder not renamed (\(nsError.domain) \(nsError.code)); written in place")
                    }
                }
            }
            let pagesFolder = folder.appending(path: "pages", directoryHint: .isDirectory)
            try fileManager.createDirectory(at: pagesFolder, withIntermediateDirectories: true)

            var pageFileNames: [String] = []
            for (index, page) in snapshot.pages.enumerated() {
                let copyName = "page-\(index + 1).heic"
                pageFileNames.append(copyName)
                let destination = pagesFolder.appending(path: copyName)
                if exists(destination) { continue }
                guard let fileName = page.fileName, photoFiles.availability(of: fileName) == .available else {
                    log.info(self, "recipe \(recipeID): \(copyName) waits for its photo (\(page.fileName ?? "no file"))")
                    isComplete = false
                    continue
                }
                do {
                    try copy(photoFiles.url(for: fileName), to: destination)
                } catch {
                    log.error(self, "recipe \(recipeID): \(copyName) not copied from \(fileName): \(error)")
                    isComplete = false
                }
            }

            try replace(folder.appending(path: "recipe.json"), with: RecipeRendering.json(snapshot.recipe))
            let markdown = RecipeRendering.markdown(snapshot.recipe, pageFileNames: pageFileNames)
            try replace(folder.appending(path: "recipe.md"), with: Data(markdown.utf8))
            log.info(self, "recipe \(recipeID) copied to \(folder.lastPathComponent) (\(snapshot.pages.count) pages, complete: \(isComplete))")
        } catch {
            log.error(self, "recipe \(recipeID) not copied: \(error)")
            isComplete = false
        }
        setPending(recipeID, !isComplete)
    }

    // MARK: A deleted recipe

    /// A recipe she deleted (SLT-157): its whole folder, renamed or an iCloud placeholder included,
    /// goes in one coordinated delete, and it leaves the pending file. No folder: it only leaves the
    /// pending file. An existing `Pages without a recipe` folder is left alone. Never throws.
    func removeRecipe(recipeID: UUID) {
        if let folder = existingFolder(for: recipeID, includingPlaceholders: true) {
            do {
                try remove(folder)
                log.info(self, "recipe \(recipeID): folder \(folder.lastPathComponent) removed")
            } catch {
                log.error(self, "recipe \(recipeID): folder \(folder.lastPathComponent) not removed: \(error)")
            }
        } else {
            log.info(self, "recipe \(recipeID): no folder to remove")
        }
        setPending(recipeID, false)
    }

    // MARK: Catching up

    /// At launch (MT-15): every recipe in the pending file, and every recipe with no folder (nor an
    /// iCloud placeholder for one) last changed more than 10 minutes ago.
    func catchUp(_ snapshots: [MirrorSnapshot], now: Date = Date()) {
        let pending = pendingIDs()
        var written = 0
        for snapshot in snapshots {
            let recipe = snapshot.recipe
            let isMissing = existingFolder(for: recipe.id, includingPlaceholders: true) == nil
                && now.timeIntervalSince(recipe.updatedAt) > Self.catchUpQuietPeriod
            if pending.contains(recipe.id) || isMissing {
                write(snapshot)
                written += 1
            }
        }
        log.info(self, "catch-up: \(written) of \(snapshots.count) recipes written")
    }

    // MARK: The pending file

    /// The recipes whose copy isn't complete.
    func pendingIDs() -> Set<UUID> {
        guard let data = try? Data(contentsOf: pendingURL),
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private func setPending(_ recipeID: UUID, _ isPending: Bool) {
        var ids = pendingIDs()
        let changed = isPending ? ids.insert(recipeID).inserted : ids.remove(recipeID) != nil
        guard changed else { return }
        do {
            try FileManager.default.createDirectory(at: pendingURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(ids.map(\.uuidString).sorted())
            try data.write(to: pendingURL, options: .atomic)
        } catch {
            log.error(self, "pending file not written: \(error)")
        }
    }

    // MARK: Files

    /// The recipe's folder in `Recipes/`: the one whose name ends with `-<first 8 of id>`, however
    /// it was renamed. With `includingPlaceholders`, an iCloud placeholder (`.<name>.icloud`) counts.
    private func existingFolder(for recipeID: UUID, includingPlaceholders: Bool = false) -> URL? {
        let suffix = "-" + RecipeRendering.idPrefix(recipeID)
        let names = (try? FileManager.default.contentsOfDirectory(atPath: recipesFolder.path(percentEncoded: false))) ?? []
        for name in names {
            if name.hasSuffix(suffix) && !name.hasPrefix(".") {
                return recipesFolder.appending(path: name, directoryHint: .isDirectory)
            }
            if includingPlaceholders, name.hasPrefix("."), name.hasSuffix(".icloud"),
               name.dropFirst().dropLast(".icloud".count).hasSuffix(suffix) {
                return recipesFolder.appending(path: name)
            }
        }
        return nil
    }

    private func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    // MARK: Coordinated file operations

    /// Copies `source` to `destination`; fails rather than replace a file already there.
    private func copy(_ source: URL, to destination: URL) throws {
        try coordinate(reading: source, writing: destination, writingOptions: []) { reading, writing in
            try FileManager.default.copyItem(at: reading, to: writing)
        }
    }

    /// Writes `data` as `url`, replacing `recipe.json` or `recipe.md`.
    private func replace(_ url: URL, with data: Data) throws {
        var coordinationError: NSError?
        var operationError: (any Error)?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { target in
            do {
                try data.write(to: target, options: .atomic)
            } catch {
                operationError = error
            }
        }
        if let error = coordinationError ?? operationError { throw error }
    }

    /// Moves a recipe's folder to its title's name (RV-27), telling the coordinator of the move.
    private func move(_ source: URL, to destination: URL) throws {
        var coordinationError: NSError?
        var operationError: (any Error)?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: source, options: .forMoving,
                               writingItemAt: destination, options: .forReplacing,
                               error: &coordinationError) { from, to in
            coordinator.item(at: from, willMoveTo: to)
            do {
                try FileManager.default.moveItem(at: from, to: to)
                coordinator.item(at: from, didMoveTo: to)
            } catch {
                operationError = error
            }
        }
        if let error = coordinationError ?? operationError { throw error }
    }

    /// Removes a deleted recipe's folder (SLT-157).
    private func remove(_ url: URL) throws {
        var coordinationError: NSError?
        var operationError: (any Error)?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinationError) { target in
            do {
                try FileManager.default.removeItem(at: target)
            } catch {
                operationError = error
            }
        }
        if let error = coordinationError ?? operationError { throw error }
    }

    private func coordinate(reading source: URL, writing destination: URL, writingOptions: NSFileCoordinator.WritingOptions,
                            _ operation: (URL, URL) throws -> Void) throws {
        var coordinationError: NSError?
        var operationError: (any Error)?
        NSFileCoordinator().coordinate(readingItemAt: source, options: [],
                                       writingItemAt: destination, options: writingOptions,
                                       error: &coordinationError) { reading, writing in
            do {
                try operation(reading, writing)
            } catch {
                operationError = error
            }
        }
        if let error = coordinationError ?? operationError { throw error }
    }
}
