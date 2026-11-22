import Foundation

/// Groups the spike's test photos into captures by page ID only, never by page content (SLT-154,
/// `00B` §2). Behind SLT-093's `AppConfig.AccuracySpike` flag.
nonisolated enum TestSetGroups {
    /// The page pairs `10` §1 joins into one capture.
    private static let joinedPairs: [(first: Int, second: Int)] = [(5, 6), (7, 8), (16, 17)]

    private static let extensions: Set<String> = ["jpeg", "jpg", "png", "heic"]

    /// The names that are exactly `TP-` and two digits, `.`, then `jpeg`, `jpg`, `png` or `heic`
    /// (any case), in page order. A joined pair is one capture when both pages are present; every
    /// other page is its own capture.
    static func captures(fileNames: [String]) -> [[String]] {
        let pages = fileNames
            .compactMap { name in pageNumber(name).map { (number: $0, name: name) } }
            .sorted { ($0.number, $0.name) < ($1.number, $1.name) }
        let numbers = Set(pages.map(\.number))

        var groups: [[String]] = []
        var joinedIndex: [Int: Int] = [:]
        for page in pages {
            if let pair = joinedPairs.first(where: { $0.first == page.number || $0.second == page.number }),
               numbers.contains(pair.first), numbers.contains(pair.second) {
                if let index = joinedIndex[pair.first] {
                    groups[index].append(page.name)
                } else {
                    joinedIndex[pair.first] = groups.count
                    groups.append([page.name])
                }
            } else {
                groups.append([page.name])
            }
        }
        return groups
    }

    /// The page number of a name like `TP-05.jpeg`, or nil for any other name.
    private static func pageNumber(_ name: String) -> Int? {
        let chars = Array(name)
        guard chars.count > 6, String(chars[0..<3]) == "TP-",
              chars[3].isASCII, chars[3].isNumber, chars[4].isASCII, chars[4].isNumber, chars[5] == ".",
              extensions.contains(String(chars[6...]).lowercased()) else {
            return nil
        }
        return Int(String(chars[3...4]))
    }
}
