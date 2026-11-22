import SwiftUI
import UIKit

/// One page photo, full width at its aspect ratio (`13` §4.1). Loaded off the main actor from its
/// file; until the file is here, a placeholder, checked again every 2 seconds while shown (SC-6).
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
        .task(id: photo.fileName) { await load() }
    }

    private func load() async {
        guard let photoFiles, let fileName = photo.fileName else { return }
        while !Task.isCancelled {
            let loaded = await Self.loadImage(fileName, from: photoFiles)
            if let loaded {
                image = loaded
                return
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }

    /// The decoded image, off the main actor, or nil while the file isn't available.
    static func loadImage(_ fileName: String, from photoFiles: PhotoFiles) async -> UIImage? {
        await Task.detached {
            guard photoFiles.availability(of: fileName) == .available else { return nil }
            let path = photoFiles.url(for: fileName).path(percentEncoded: false)
            return UIImage(contentsOfFile: path)?.preparingForDisplay()
        }.value
    }
}
