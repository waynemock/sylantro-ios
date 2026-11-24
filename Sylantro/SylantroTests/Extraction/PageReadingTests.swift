import Foundation
import Testing
@testable import Sylantro

/// `PageReading(words:)` (`15` M3-2): a page's kept reading, each `OCRWord` one line (RV-4), read
/// back for structuring. Every value is made up.
@Suite("Page reading")
struct PageReadingTests {
    @Test("words to lines")
    func wordsToLines() {
        let pageID = UUID()
        let words = [
            OCRWord(text: "Test Soup", box: SourceBox(pageID: pageID, x: 0.125, y: 0.0625, width: 0.5, height: 0.0625),
                    confidence: 0.5),
            OCRWord(text: "2 cups water", box: SourceBox(pageID: pageID, x: 0.25, y: 0.125, width: 0.375, height: 0.03125),
                    confidence: nil),
        ]

        let reading = PageReading(words: words)

        #expect(reading.lines.map(\.text) == ["Test Soup", "2 cups water"])
        #expect(reading.lines.map(\.confidence) == [0.5, 0])
        #expect(reading.lines[0].box == .init(x: 0.125, y: 0.0625, width: 0.5, height: 0.0625))
        #expect(reading.lines[1].box == .init(x: 0.25, y: 0.125, width: 0.375, height: 0.03125))
        #expect(reading.text == "Test Soup\n2 cups water")
    }
}
