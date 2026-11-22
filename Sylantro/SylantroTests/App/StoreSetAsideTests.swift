import Foundation
import Testing
@testable import Sylantro

/// Start Fresh's set-aside (`14` Task M2-2): the store's files are moved into a dated folder, byte
/// for byte, and never deleted or overwritten (SLT-031). In a temporary folder, never the live store.
@Suite("Store set aside")
struct StoreSetAsideTests {
    /// 22 Nov 2026, 09:30:00 in this device's time zone, as the folder name is.
    static let now: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = DateComponents(year: 2026, month: 11, day: 22, hour: 9, minute: 30, second: 0)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }()

    static let storeBytes = Data([0x53, 0x51, 0x4C, 0x01])
    static let shmBytes = Data([0x02, 0x03])
    static let walBytes = Data([0x04, 0x05, 0x06])

    /// A new, empty temporary folder for one test.
    static func makeFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "StoreSetAsideTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    @Test("the store and its siblings are moved, not deleted")
    func storeAndSiblingsAreMoved() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = folder.appending(path: "Sylantro.store")
        try Self.storeBytes.write(to: store)
        try Self.shmBytes.write(to: folder.appending(path: "Sylantro.store-shm"))
        try Self.walBytes.write(to: folder.appending(path: "Sylantro.store-wal"))

        let destination = try StoreSetAside.moveAside(storeURL: store, now: Self.now)

        let expected = folder.appending(path: "Set Aside/2026-11-22 093000", directoryHint: .isDirectory)
        #expect(destination.standardizedFileURL.path == expected.standardizedFileURL.path)
        #expect(try Data(contentsOf: destination.appending(path: "Sylantro.store")) == Self.storeBytes)
        #expect(try Data(contentsOf: destination.appending(path: "Sylantro.store-shm")) == Self.shmBytes)
        #expect(try Data(contentsOf: destination.appending(path: "Sylantro.store-wal")) == Self.walBytes)
        for name in ["Sylantro.store", "Sylantro.store-shm", "Sylantro.store-wal"] {
            #expect(!FileManager.default.fileExists(atPath: folder.appending(path: name).path(percentEncoded: false)))
        }
    }

    @Test("a second set-aside in the same second gets its own folder")
    func secondSetAsideGetsItsOwnFolder() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = folder.appending(path: "Sylantro.store")
        try Self.storeBytes.write(to: store)
        let first = try StoreSetAside.moveAside(storeURL: store, now: Self.now)

        let secondBytes = Data([0x09])
        try secondBytes.write(to: store)
        let second = try StoreSetAside.moveAside(storeURL: store, now: Self.now)

        #expect(second.lastPathComponent == "2026-11-22 093000 2")
        #expect(first.lastPathComponent == "2026-11-22 093000")
        #expect(try Data(contentsOf: first.appending(path: "Sylantro.store")) == Self.storeBytes)
        #expect(try Data(contentsOf: second.appending(path: "Sylantro.store")) == secondBytes)
    }

    @Test("a missing sibling is not an error")
    func missingSiblingIsNotAnError() throws {
        let folder = try Self.makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = folder.appending(path: "Sylantro.store")
        try Self.storeBytes.write(to: store)

        let destination = try StoreSetAside.moveAside(storeURL: store, now: Self.now)

        #expect(try Data(contentsOf: destination.appending(path: "Sylantro.store")) == Self.storeBytes)
        #expect(!FileManager.default.fileExists(atPath: store.path(percentEncoded: false)))
    }
}
