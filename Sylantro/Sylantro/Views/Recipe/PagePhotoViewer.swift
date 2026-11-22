import SwiftUI
import UIKit

/// A page photo full screen, pinch to zoom (`13` §4.1). Closed with the system's close button,
/// which iOS labels (MT-11); the image keeps the system's default label.
struct PagePhotoViewer: View {
    let fileName: String
    let photoFiles: PhotoFiles?

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1

    private static let scaleRange: ClosedRange<CGFloat> = 1...6

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * scale, height: geometry.size.height * scale)
                    } else {
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = min(max(settledScale * value.magnification, Self.scaleRange.lowerBound), Self.scaleRange.upperBound)
                        }
                        .onEnded { _ in settledScale = scale }
                )
            }
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .task {
            guard let photoFiles else { return }
            image = await PagePhotoView.loadImage(fileName, from: photoFiles)
        }
    }
}
