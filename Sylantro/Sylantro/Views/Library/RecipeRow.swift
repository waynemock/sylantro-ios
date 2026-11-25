import SwiftUI
import UIKit
import SyLibCache
import SyLibCore

/// One recipe in the library (`13` §2): its cover's thumbnail, its title ("New recipe" until it is
/// read), and one line under it (`15` M3-3).
struct RecipeRow: View {
    /// The line under the title, in `15` M3-3's order.
    enum Detail: Equatable {
        /// Being read now (S-45).
        case reading
        /// Couldn't be read (S-46, RV-24).
        case couldNotRead
        /// When it was scanned and its page count (S-3).
        case scanned(Date, pageCount: Int)
        /// Its author or publisher, as printed.
        case source(String)
    }

    private let log = AppLogger(category: "Library")

    let title: String
    let detail: Detail
    /// The cover photo's file: the recipe's first page.
    let coverFileName: String?
    let photoFiles: PhotoFiles?
    /// While this row's recipe is being read, how far, 0 to 1 (SC-23, `15` M3-3f); nil otherwise.
    var progress: Double? = nil

    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            cover
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "New recipe" : title)
                    .font(.headline)
                detailText
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                // A thin bar under "Reading…" (SC-23), moving step by step.
                if detail == .reading, let progress {
                    ProgressView(value: progress)
                        .animation(.easeInOut, value: progress)
                }
            }
        }
        // Runs again when `photoFiles` arrives after launch, not only when the cover changes
        // (`14` M2-4g).
        .task(id: [coverFileName, photoFiles?.root.path]) { await loadThumbnail() }
    }

    private var detailText: Text {
        switch detail {
        case .reading:
            Text("Reading…")
        case .couldNotRead:
            Text("Couldn't read these pages")
        case .scanned(let createdAt, let pageCount):
            Text("Scanned \(createdAt, format: .dateTime.month(.abbreviated).day()) · \(pageCount == 1 ? "1 page" : "\(pageCount) pages")")
        case .source(let source):
            Text(verbatim: source)
        }
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
        let clock = ContinuousClock()
        let start = clock.now
        if let cached = await ImageCache.shared.memoryImage(for: url) {
            thumbnail = cached
            logShown(coverFileName, after: start.duration(to: clock.now))
            return
        }
        while !Task.isCancelled {
            let image = await Task.detached {
                photoFiles.thumbnail(of: coverFileName).map { UIImage(cgImage: $0) }
            }.value
            if let image {
                await ImageCache.shared.store(image, for: url, toDisk: false)
                thumbnail = image
                logShown(coverFileName, after: start.duration(to: clock.now))
                return
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }

    /// Debug only: how long the thumbnail took, by the file name's first 8 characters (no titles,
    /// `00B` §3).
    private func logShown(_ fileName: String, after elapsed: Duration) {
        let milliseconds = Int(elapsed.components.seconds * 1_000 + elapsed.components.attoseconds / 1_000_000_000_000_000)
        log.debug(self, "thumbnail \(fileName.prefix(8)): \(milliseconds) ms")
    }
}
