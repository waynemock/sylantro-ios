import Foundation

/// How far a line is zoomed when it is shown on its page (`15` RV-33, M3-3c): enough to fill the
/// view's width less a margin, but never past `maximum`, so a short line stays sharp with the page
/// around it.
nonisolated enum LineZoom {
    /// The most a line is zoomed: 2.5 times the page at the view's width.
    static let maximum = 2.5

    /// The zoom that makes a box `boxWidth` wide (0 to 1 of the page) fill `viewWidth` less
    /// `margin` each side, never below 1 (the page at the view's width) nor above `maximum`. A box
    /// of no width, or a view narrower than two margins, gives 1.
    static func scale(boxWidth: Double, viewWidth: Double, margin: Double) -> Double {
        let room = viewWidth - 2 * margin
        guard boxWidth > 0, viewWidth > 0, room > 0 else {
            return 1
        }
        return min(max(room / (boxWidth * viewWidth), 1), maximum)
    }
}
