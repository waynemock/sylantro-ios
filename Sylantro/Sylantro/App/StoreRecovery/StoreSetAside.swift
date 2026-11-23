import Foundation
import SyLibCore

/// Start Fresh's one file operation (`13` §5, SC-7): the store and its siblings are moved, untouched,
/// into a dated folder beside them. It moves, and never deletes or overwrites (SLT-030, SLT-031).
nonisolated enum StoreSetAside {
    private static let log = AppLogger(category: "StoreRecovery")

    /// The folder that holds every set-aside store, beside the store.
    static let folderName = "Set Aside"

    /// The SQLite files that make up a store, beside its main file.
    static let siblingSuffixes = ["-shm", "-wal"]

    /// Moves the file at `storeURL` and its `-shm` and `-wal` siblings (those that exist) into
    /// `Set Aside/<yyyy-MM-dd HHmmss>/` beside it, and returns that folder. A folder that already
    /// exists for the same second gets ` 2`, ` 3` and so on.
    @discardableResult
    static func moveAside(storeURL: URL, now: Date = Date(), fileManager: FileManager = .default) throws -> URL {
        let setAsideRoot = storeURL.deletingLastPathComponent().appending(path: folderName, directoryHint: .isDirectory)
        let stamp = folderStamp(for: now)
        var destination = setAsideRoot.appending(path: stamp, directoryHint: .isDirectory)
        var suffix = 2
        while fileManager.fileExists(atPath: destination.path(percentEncoded: false)) {
            destination = setAsideRoot.appending(path: "\(stamp) \(suffix)", directoryHint: .isDirectory)
            suffix += 1
        }
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        let storeName = storeURL.lastPathComponent
        let names = [storeName] + siblingSuffixes.map { storeName + $0 }
        for name in names {
            let source = storeURL.deletingLastPathComponent().appending(path: name)
            guard fileManager.fileExists(atPath: source.path(percentEncoded: false)) else { continue }
            // `moveItem` fails rather than replace a file, so nothing is overwritten.
            try fileManager.moveItem(at: source, to: destination.appending(path: name))
            log.info(StoreSetAside.self, "moved \(name) to \(folderName)/\(destination.lastPathComponent)")
        }
        return destination
    }

    /// `yyyy-MM-dd HHmmss`, in this device's time zone, so the folder name is the time she chose.
    static func folderStamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HHmmss"
        return formatter.string(from: date)
    }
}
