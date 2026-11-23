import Foundation

/// One word as read from a page, and where it is.
nonisolated struct OCRWord: Codable, Sendable, Equatable {
    var text: String
    var box: SourceBox
    /// 0 to 1.
    var confidence: Double?

    init(
        text: String = "",
        box: SourceBox,
        confidence: Double? = nil
    ) {
        self.text = text
        self.box = box
        self.confidence = confidence
    }

    /// `box` is required; every other key falls back to its default.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        box = try container.decode(SourceBox.self, forKey: .box)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
    }
}
