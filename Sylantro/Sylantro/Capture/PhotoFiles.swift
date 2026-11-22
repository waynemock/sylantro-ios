import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import SyLibCore

/// Whether a photo's file is on this device (`05` §4.1). A file not here yet is never treated as a
/// deleted photo (SLT-030).
nonisolated enum PhotoAvailability: Sendable, Equatable {
    /// The file is on this device.
    case available
    /// An iCloud file not yet on this device; iCloud has been asked to download it.
    case downloading
    /// No file, and nothing iCloud knows of yet.
    case missing
}

/// Why a photo file wasn't written.
nonisolated enum PhotoFilesError: Error, Equatable {
    /// A file of that name is already there; it is never overwritten.
    case fileExists(String)
    /// ImageIO couldn't encode the image as HEIC.
    case encodingFailed(String)
}

/// The photo files (`05` §4.1, IS-4, `14` MT-3): HEIC files in the app's iCloud container, outside
/// `Documents` so Files never shows them, or in Application Support with iCloud off. The store holds
/// only their names (SLT-053). Files are only ever added: nothing here deletes, moves or overwrites
/// one (SLT-030).
nonisolated struct PhotoFiles: Sendable {
    private static let log = AppLogger(category: "Photos")

    /// The folder every photo file is in.
    let root: URL

    /// The photo folder: `<ubiquityContainer>/Photos/` with iCloud, `<applicationSupport>/Photos/`
    /// with iCloud off.
    static func resolveRoot(ubiquityContainer: URL?, applicationSupport: URL) -> URL {
        (ubiquityContainer ?? applicationSupport).appending(path: "Photos", directoryHint: .isDirectory)
    }

    /// The live folder. Asking for the ubiquity container can block, so it is asked in a detached
    /// task, off the main actor; the main actor only reads the container's id.
    @MainActor
    static func live() async -> PhotoFiles {
        let containerID = SylantroApp.cloudKitContainerID
        let ubiquityContainer = await Task.detached {
            FileManager.default.url(forUbiquityContainerIdentifier: containerID)
        }.value
        let applicationSupport = URL.applicationSupportDirectory
        let root = resolveRoot(ubiquityContainer: ubiquityContainer, applicationSupport: applicationSupport)
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        } catch {
            log.error(PhotoFiles.self, "photo folder not created at \(root.path(percentEncoded: false)): \(error)")
        }
        log.info(PhotoFiles.self, "photo folder (\(ubiquityContainer == nil ? "local" : "iCloud")): \(root.path(percentEncoded: false))")
        return PhotoFiles(root: root)
    }

    func url(for fileName: String) -> URL {
        root.appending(path: fileName)
    }

    /// Encodes `image` as HEIC at full resolution (IS-2) and writes it as `fileName` through a
    /// coordinated write. Throws rather than overwrite a file already there. Returns its pixel size.
    @discardableResult
    func write(_ image: CGImage, fileName: String) throws -> (width: Int, height: Int) {
        let destinationURL = url(for: fileName)
        if FileManager.default.fileExists(atPath: destinationURL.path(percentEncoded: false)) {
            throw PhotoFilesError.fileExists(fileName)
        }

        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(encoded, UTType.heic.identifier as CFString, 1, nil) else {
            throw PhotoFilesError.encodingFailed(fileName)
        }
        let options = [kCGImageDestinationLossyCompressionQuality: PhotoEncoding.heicQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else {
            throw PhotoFilesError.encodingFailed(fileName)
        }

        var coordinationError: NSError?
        var writeError: (any Error)?
        NSFileCoordinator().coordinate(writingItemAt: destinationURL, options: [], error: &coordinationError) { url in
            do {
                // `.withoutOverwriting` fails if a file appeared since the check above.
                try (encoded as Data).write(to: url, options: [.withoutOverwriting])
            } catch {
                writeError = error
            }
        }
        if let error = coordinationError ?? writeError {
            throw error
        }
        Self.log.debug(PhotoFiles.self, "wrote \(fileName) (\(image.width) × \(image.height))")
        return (image.width, image.height)
    }

    /// A thumbnail of `fileName` no longer than `longEdge` pixels, made by ImageIO, or nil if the
    /// file isn't available. Never stored (P-4, SLT-053); views keep it in memory only.
    func thumbnail(of fileName: String, longEdge: Int = PhotoEncoding.thumbnailLongEdge) -> CGImage? {
        guard availability(of: fileName) == .available,
              let source = CGImageSourceCreateWithURL(url(for: fileName) as CFURL, nil) else {
            return nil
        }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: longEdge,
        ] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }

    /// Whether `fileName` is on this device. An iCloud file not here yet is asked for and reads as
    /// `.downloading`; one with no file at all reads as `.missing`, never as deleted (SLT-030).
    func availability(of fileName: String) -> PhotoAvailability {
        let fileURL = url(for: fileName)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path(percentEncoded: false)) {
            let values = try? fileURL.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
            guard values?.isUbiquitousItem == true,
                  let status = values?.ubiquitousItemDownloadingStatus,
                  status != .current else {
                return .available
            }
            return requestDownload(of: fileURL) ? .downloading : .available
        }
        // An older iCloud placeholder for a file not downloaded: `.<name>.icloud` beside it.
        let placeholder = root.appending(path: ".\(fileName).icloud")
        if fileManager.fileExists(atPath: placeholder.path(percentEncoded: false)) {
            return requestDownload(of: fileURL) ? .downloading : .missing
        }
        return .missing
    }

    /// Asks iCloud to download the file; false when iCloud doesn't know it.
    private func requestDownload(of fileURL: URL) -> Bool {
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: fileURL)
            Self.log.debug(PhotoFiles.self, "download asked for \(fileURL.lastPathComponent)")
            return true
        } catch {
            Self.log.debug(PhotoFiles.self, "download not started for \(fileURL.lastPathComponent): \(error)")
            return false
        }
    }
}
