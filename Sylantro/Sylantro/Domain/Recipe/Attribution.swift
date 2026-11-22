import Foundation

/// Where a recipe came from, in parts, each as printed (SLT-062). Nothing is parsed into a `URL`
/// or a `Date`.
nonisolated struct Attribution: Codable, Sendable, Equatable {
    var author: String?
    /// The site or magazine.
    var publisher: String?
    var show: String?
    var episode: String?
    var sourceURL: String?
    var printedDate: String?
    var issueDate: String?
    var copyright: String?
    /// Anything else: "From Aunt May", a cookbook's name.
    var text: String?

    init(
        author: String? = nil,
        publisher: String? = nil,
        show: String? = nil,
        episode: String? = nil,
        sourceURL: String? = nil,
        printedDate: String? = nil,
        issueDate: String? = nil,
        copyright: String? = nil,
        text: String? = nil
    ) {
        self.author = author
        self.publisher = publisher
        self.show = show
        self.episode = episode
        self.sourceURL = sourceURL
        self.printedDate = printedDate
        self.issueDate = issueDate
        self.copyright = copyright
        self.text = text
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        show = try container.decodeIfPresent(String.self, forKey: .show)
        episode = try container.decodeIfPresent(String.self, forKey: .episode)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        printedDate = try container.decodeIfPresent(String.self, forKey: .printedDate)
        issueDate = try container.decodeIfPresent(String.self, forKey: .issueDate)
        copyright = try container.decodeIfPresent(String.self, forKey: .copyright)
        text = try container.decodeIfPresent(String.self, forKey: .text)
    }
}
