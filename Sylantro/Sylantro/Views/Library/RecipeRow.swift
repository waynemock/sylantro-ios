import SwiftUI
import UIKit
import SyLibCache

/// One recipe in the library (`13` §2): its cover's thumbnail, its title ("New recipe" until it is
/// read), and when it was scanned with its page count.
struct RecipeRow: View {
    let title: String
    let createdAt: Date
    let pageCount: Int
    /// The cover photo's file: the recipe's first page.
    let coverFileName: String?
    let photoFiles: PhotoFiles?

    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            cover
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "New recipe" : title)
                    .font(.headline)
                Text("Scanned \(createdAt, format: .dateTime.month(.abbreviated).day()) · \(pagesText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: coverFileName) { await loadThumbnail() }
    }

    private var pagesText: String {
        pageCount == 1 ? "1 page" : "\(pageCount) pages"
    }

    @ViewBuilder
    private var cover: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // A photo not on this device yet (SC-6).
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Downloading from iCloud…")
        }
    }

    /// The thumbnail from memory, or made off the main actor once the file is here, checked again
    /// every 2 seconds until it is (SC-6). Kept in memory only, never on disk (M2-4a, SLT-054).
    private func loadThumbnail() async {
        guard let photoFiles, let coverFileName else {
            thumbnail = nil
            return
        }
        let url = photoFiles.url(for: coverFileName)
        if let cached = await ImageCache.shared.memoryImage(for: url) {
            thumbnail = cached
            return
        }
        while !Task.isCancelled {
            let image = await Task.detached {
                photoFiles.thumbnail(of: coverFileName).map { UIImage(cgImage: $0) }
            }.value
            if let image {
                await ImageCache.shared.store(image, for: url, toDisk: false)
                thumbnail = image
                return
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
