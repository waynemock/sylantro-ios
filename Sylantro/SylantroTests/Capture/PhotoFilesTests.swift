import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import Sylantro

/// The photo files (`14` Task M2-3): where they live, written as HEIC at full size, never
/// overwritten, and a missing one is missing, not deleted (SLT-030). In a temporary folder, with
/// small made-up images drawn in code.
@Suite("Photo files")
struct PhotoFilesTests {
    /// A made-up image of one flat color, `width` × `height` pixels.
    static func makeImage(width: Int, height: Int) -> CGImage? {
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        context.setFillColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    /// A `PhotoFiles` on a new, empty temporary folder; the caller removes `folder`.
    static func makePhotoFiles() throws -> (photoFiles: PhotoFiles, folder: URL) {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "PhotoFilesTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let root = folder.appending(path: "Photos", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return (PhotoFiles(root: root), folder)
    }

    @Test("with iCloud the folder is outside Documents")
    func iCloudFolderIsOutsideDocuments() {
        let container = URL(filePath: "/private/var/mobile/Library/Mobile Documents/iCloud~com~syzygysoftwerksllc~Sylantro", directoryHint: .isDirectory)
        let support = URL(filePath: "/var/mobile/Application Support", directoryHint: .isDirectory)
        let root = PhotoFiles.resolveRoot(ubiquityContainer: container, applicationSupport: support)
        #expect(root.standardizedFileURL.path == container.appending(path: "Photos").standardizedFileURL.path)
        #expect(!root.pathComponents.contains("Documents"))
    }

    @Test("with iCloud off the folder is local")
    func iCloudOffFolderIsLocal() {
        let support = URL(filePath: "/var/mobile/Application Support", directoryHint: .isDirectory)
        let root = PhotoFiles.resolveRoot(ubiquityContainer: nil, applicationSupport: support)
        #expect(root.standardizedFileURL.path == support.appending(path: "Photos").standardizedFileURL.path)
    }

    @Test("a photo is written as HEIC at full size")
    func photoIsWrittenAsHEIC() throws {
        let (photoFiles, folder) = try Self.makePhotoFiles()
        defer { try? FileManager.default.removeItem(at: folder) }
        let image = try #require(Self.makeImage(width: 40, height: 60))

        let size = try photoFiles.write(image, fileName: "page.heic")

        #expect(size.width == 40)
        #expect(size.height == 60)
        let fileURL = photoFiles.url(for: "page.heic")
        let bytes = try Data(contentsOf: fileURL)
        let brand = String(decoding: bytes.dropFirst(4).prefix(8), as: UTF8.self)
        #expect(brand == "ftypheic" || brand == "ftypmif1")
        let source = try #require(CGImageSourceCreateWithURL(fileURL as CFURL, nil))
        let readBack = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(readBack.width == 40)
        #expect(readBack.height == 60)
    }

    @Test("a photo is never overwritten")
    func photoIsNeverOverwritten() throws {
        let (photoFiles, folder) = try Self.makePhotoFiles()
        defer { try? FileManager.default.removeItem(at: folder) }
        let first = try #require(Self.makeImage(width: 40, height: 60))
        let second = try #require(Self.makeImage(width: 60, height: 40))
        try photoFiles.write(first, fileName: "page.heic")
        let firstBytes = try Data(contentsOf: photoFiles.url(for: "page.heic"))

        #expect(throws: (any Error).self) {
            try photoFiles.write(second, fileName: "page.heic")
        }
        #expect(try Data(contentsOf: photoFiles.url(for: "page.heic")) == firstBytes)
    }

    @Test("a thumbnail is no bigger than asked")
    func thumbnailIsNoBiggerThanAsked() throws {
        let (photoFiles, folder) = try Self.makePhotoFiles()
        defer { try? FileManager.default.removeItem(at: folder) }
        let image = try #require(Self.makeImage(width: 40, height: 60))
        try photoFiles.write(image, fileName: "page.heic")

        let thumbnail = try #require(photoFiles.thumbnail(of: "page.heic", longEdge: 30))

        #expect(thumbnail.width == 20)
        #expect(thumbnail.height == 30)
    }

    @Test("a missing photo is missing, not an error")
    func missingPhotoIsMissing() throws {
        let (photoFiles, folder) = try Self.makePhotoFiles()
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(photoFiles.availability(of: "\(UUID().uuidString).heic") == .missing)
    }
}
