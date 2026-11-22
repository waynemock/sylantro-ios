import Foundation

/// Where something is on a page: normalized 0 to 1, origin top left, on the cropped page image.
nonisolated struct SourceBox: Codable, Sendable, Equatable {
    var pageID: UUID
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(
        pageID: UUID,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) {
        self.pageID = pageID
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Every property is required.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageID = try container.decode(UUID.self, forKey: .pageID)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
    }
}
