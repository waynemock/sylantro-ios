import SwiftUI
import UIKit
import SyLibCache
import SyLibCore

/// One page photo, full width at its aspect ratio (`13` §4.1). Loaded off the main actor at display
/// size through `loadImage` (`15` M3-3g); until the file is here, a placeholder, checked again
/// every 2 seconds while shown (SC-6).
/// The image keeps the system's default accessibility label (MT-11).
struct PagePhotoView: View {
    let photo: Photo
    let photoFiles: PhotoFiles?

    @State private var image: UIImage?

    /// Width over height, from the record, so the space is right before the image loads.
    private var aspectRatio: CGFloat {
        guard let width = photo.pixelWidth, let height = photo.pixelHeight, width > 0, height > 0 else {
            return 3.0 / 4.0
        }
        return CGFloat(width) / CGFloat(height)
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Downloading from iCloud…")
            }
        }
        .frame(maxWidth: .infinity)
        // Runs again when `photoFiles` arrives after launch (`14` M2-4g).
        .task(id: [photo.fileName, photoFiles?.root.path]) { await load() }
    }

    private func load() async {
        guard let photoFiles, let fileName = photo.fileName else { return }
        if let loaded = await Self.loadImageRetrying(fileName, from: photoFiles) {
            image = loaded
        }
    }

    private static let log = AppLogger(category: "Photos")

    /// The page photo decoded for showing, the one way every view decodes one (`15` M3-3g): at
    /// most `maxPixelSize` on its long edge (nil: full size, for the viewer's pinch), from SyLib's
    /// memory-only `ImageCache` when it is there (keyed by the file's URL with the size added),
    /// else decoded off the main actor and kept there (`toDisk: false`, `14A`), so the system can
    /// drop it under pressure. Nil while the file isn't available, or when the decode fails.
    static func loadImage(_ fileName: String, from photoFiles: PhotoFiles,
                          maxPixelSize: Int? = PhotoEncoding.displayLongEdge) async -> UIImage? {
        let fileURL = photoFiles.url(for: fileName)
        let size = maxPixelSize.map(String.init) ?? "full"
        let key = URL(string: fileURL.absoluteString + "#" + size) ?? fileURL
        if let cached = await ImageCache.shared.memoryImage(for: key) {
            return cached
        }
        let decoded = await Task.detached {
            let image = maxPixelSize.map { photoFiles.displayImage(of: fileName, maxPixelSize: $0) }
                ?? photoFiles.fullImage(of: fileName)
            return image.map { UIImage(cgImage: $0) }
        }.value
        if let decoded {
            await ImageCache.shared.store(decoded, for: key, toDisk: false)
        }
        return decoded
    }

    /// `loadImage`, tried again every 2 seconds until it gives an image or the task is cancelled.
    /// While the file is downloading the size stays; when the file is here and the decode still
    /// fails, that is logged (file name only) and the next try asks for half the size, down to
    /// `thumbnailLongEdge`, so a page shows smaller rather than not at all (M3-3g).
    static func loadImageRetrying(_ fileName: String, from photoFiles: PhotoFiles,
                                  maxPixelSize: Int? = PhotoEncoding.displayLongEdge) async -> UIImage? {
        var size = maxPixelSize
        while !Task.isCancelled {
            if let loaded = await loadImage(fileName, from: photoFiles, maxPixelSize: size) {
                return loaded
            }
            if photoFiles.availability(of: fileName) == .available {
                log.error(PagePhotoView.self, "decode failed: \(fileName) at \(size.map(String.init) ?? "full size")")
                size = max((size ?? PhotoEncoding.displayLongEdge * 2) / 2, PhotoEncoding.thumbnailLongEdge)
            }
            try? await Task.sleep(for: .seconds(2))
        }
        return nil
    }
}
