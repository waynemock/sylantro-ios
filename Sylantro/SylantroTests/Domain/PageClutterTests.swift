import Foundation
import Testing
@testable import Sylantro

/// Page clutter (SLT-149, `15` M3-3m). Every line is made up.
@Suite("Page clutter")
struct PageClutterTests {
    @Test("a misread web address")
    func misreadWebAddress() {
        #expect(PageClutter.isClutter("naps www madeupsite.com recipes made-up-page"))
        #expect(PageClutter.isClutter("madeupsite.com/recipes/made-up"))
        #expect(!PageClutter.isClutter("1 cup made-up sugar"))
        #expect(!PageClutter.isClutter("Stir the made-up sauce."))
    }
}
