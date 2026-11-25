import Foundation

/// How photos are encoded and named (`05` §5, P-3): one constant each, starting points tuned after
/// the sync check. The encoding itself needs ImageIO, which `Domain/` doesn't import (SLT-081).
nonisolated enum PhotoEncoding {
    static let heicQuality = 0.7
    static let dishLongEdge = 2_048
    static let thumbnailLongEdge = 400
    /// The longest edge a page photo is decoded to for showing on screen (`15` M3-3g); the viewer
    /// decodes at full size.
    static let displayLongEdge = 2_560
    static let fileExtension = "heic"

    /// A photo's file name is its id: `<id>.heic`.
    static func fileName(for id: UUID) -> String {
        "\(id.uuidString).heic"
    }
}
