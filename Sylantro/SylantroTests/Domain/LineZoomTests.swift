import Testing
@testable import Sylantro

/// `LineZoom` (`15` RV-33, M3-3c): a line fills the view's width less its margins, at most 2.5
/// times the page at the view's width, never less than the page itself.
@Suite("Line zoom")
struct LineZoomTests {
    @Test("a short line is capped")
    func shortLineIsCapped() {
        #expect(LineZoom.scale(boxWidth: 0.1, viewWidth: 390, margin: 16) == 2.5)
        #expect(LineZoom.maximum == 2.5)
    }

    @Test("a wide line fits")
    func wideLineFits() {
        let scale = LineZoom.scale(boxWidth: 0.8, viewWidth: 390, margin: 16)

        #expect(scale == (390 - 32) / (0.8 * 390))
        #expect(scale > 1 && scale < 2.5)
    }

    @Test("never below the page")
    func neverBelowThePage() {
        #expect(LineZoom.scale(boxWidth: 1.0, viewWidth: 390, margin: 16) == 1)
        #expect(LineZoom.scale(boxWidth: 0, viewWidth: 390, margin: 16) == 1)
    }
}
