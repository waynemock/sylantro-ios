import SwiftUI
import UIKit
import SyLibUI

/// A recipe's page photos full screen, swiping between them, each pinch to zoom (`13` §4.1,
/// `15` M3-3a). It opens on `startIndex`; with a `box` on that page, zoomed so the box fills the
/// width with a 16 pt margin and outlined, as in the strip. Closed with SyLib's `xmark` toolbar
/// button (SLT-089), which iOS labels; each image keeps the system's default label (MT-11).
struct PagePhotoViewer: View {
    /// The recipe's page photos, in order.
    let fileNames: [String]
    var startIndex: Int = 0
    /// A line to show on the starting page.
    var box: SourceBox?
    let photoFiles: PhotoFiles?

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(Array(fileNames.enumerated()), id: \.offset) { offset, fileName in
                    ZoomablePage(fileName: fileName, box: offset == startIndex ? box : nil, photoFiles: photoFiles)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // SyLib's toolbar button (SLT-089, replacing MT-11's system close button); iOS
                    // labels the xmark symbol.
                    IconButton("xmark", context: .toolbar) { dismiss() }
                }
            }
        }
        .onAppear { index = min(max(startIndex, 0), max(fileNames.count - 1, 0)) }
    }
}

/// One page, pinch to zoom; with a `box`, zoomed to it once the image is here and outlined.
private struct ZoomablePage: View {
    let fileName: String
    let box: SourceBox?
    let photoFiles: PhotoFiles?

    @Environment(\.syTheme) private var syTheme
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var position = ScrollPosition()
    /// Where to scroll once the content has grown to the zoom (the box's area, centered).
    @State private var pendingOffset: CGPoint?

    private static let scaleRange: ClosedRange<CGFloat> = 1...6
    /// The space each side of the zoomed box, in points, as the strip's.
    private static let margin: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width * scale, height: geometry.size.height * scale)
                        .overlay {
                            if let box {
                                let drawn = drawnRect(image: image, in: geometry.size, scale: scale)
                                LineOutline(box: box, size: drawn.size, accent: syTheme.primaryAccent)
                                    .frame(width: drawn.width, height: drawn.height)
                                    .offset(x: drawn.minX, y: drawn.minY)
                                    .frame(width: geometry.size.width * scale, height: geometry.size.height * scale,
                                           alignment: .topLeading)
                            }
                        }
                } else {
                    ProgressView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .scrollPosition($position)
            .onScrollGeometryChange(for: CGSize.self, of: \.contentSize) { _, _ in
                if let pendingOffset {
                    self.pendingOffset = nil
                    position.scrollTo(point: pendingOffset)
                }
            }
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        scale = min(max(settledScale * value.magnification, Self.scaleRange.lowerBound), Self.scaleRange.upperBound)
                    }
                    .onEnded { _ in settledScale = scale }
            )
            // Runs again when `photoFiles` arrives after launch (`14` M2-4g).
            .task(id: photoFiles?.root.path) {
                guard let photoFiles, image == nil else { return }
                image = await PagePhotoView.loadImage(fileName, from: photoFiles)
                if let image {
                    zoomToBox(image: image, in: geometry.size)
                }
            }
        }
    }

    /// Where the image is drawn inside its frame at `scale`: fitted and centered.
    private func drawnRect(image: UIImage, in size: CGSize, scale: CGFloat) -> CGRect {
        let frame = CGSize(width: size.width * scale, height: size.height * scale)
        guard image.size.height > 0, frame.height > 0 else { return CGRect(origin: .zero, size: frame) }
        let ratio = image.size.width / image.size.height
        let drawn = ratio > frame.width / frame.height
            ? CGSize(width: frame.width, height: frame.width / ratio)
            : CGSize(width: frame.height * ratio, height: frame.height)
        return CGRect(x: (frame.width - drawn.width) / 2, y: (frame.height - drawn.height) / 2,
                      width: drawn.width, height: drawn.height)
    }

    /// The zoom that makes the box fill the width less the margins (within the pinch range), and
    /// the scroll that centers it.
    private func zoomToBox(image: UIImage, in size: CGSize) {
        guard let box, box.width > 0, size.width > 0 else { return }
        let fitted = drawnRect(image: image, in: size, scale: 1)
        guard fitted.width > 0 else { return }
        let zoom = min(max((size.width - 2 * Self.margin) / (box.width * fitted.width), Self.scaleRange.lowerBound),
                       Self.scaleRange.upperBound)
        let drawn = drawnRect(image: image, in: size, scale: zoom)
        let center = CGPoint(x: drawn.minX + (box.x + box.width / 2) * drawn.width,
                             y: drawn.minY + (box.y + box.height / 2) * drawn.height)
        let contentWidth = size.width * zoom
        let contentHeight = size.height * zoom
        pendingOffset = CGPoint(x: min(max(center.x - size.width / 2, 0), max(contentWidth - size.width, 0)),
                                y: min(max(center.y - size.height / 2, 0), max(contentHeight - size.height, 0)))
        scale = zoom
        settledScale = zoom
    }
}
