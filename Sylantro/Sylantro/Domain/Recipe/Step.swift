import Foundation

/// One method step, pointing at the ingredients it uses.
nonisolated struct Step: Codable, Sendable, Equatable {
    var id: UUID
    var index: Int
    var text: String
    var groupName: String?
    var ingredientIDs: [UUID]
    var sourceBox: SourceBox?
    /// Added by hand on a printed page (SLT-065).
    var isHandwritten: Bool
    /// Couldn't be read; its `sourceBox` says where it is (SLT-066).
    var isUnreadable: Bool

    init(
        id: UUID = UUID(),
        index: Int = 0,
        text: String = "",
        groupName: String? = nil,
        ingredientIDs: [UUID] = [],
        sourceBox: SourceBox? = nil,
        isHandwritten: Bool = false,
        isUnreadable: Bool = false
    ) {
        self.id = id
        self.index = index
        self.text = text
        self.groupName = groupName
        self.ingredientIDs = ingredientIDs
        self.sourceBox = sourceBox
        self.isHandwritten = isHandwritten
        self.isUnreadable = isUnreadable
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        index = try container.decodeIfPresent(Int.self, forKey: .index) ?? 0
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        groupName = try container.decodeIfPresent(String.self, forKey: .groupName)
        ingredientIDs = try container.decodeIfPresent([UUID].self, forKey: .ingredientIDs) ?? []
        sourceBox = try container.decodeIfPresent(SourceBox.self, forKey: .sourceBox)
        isHandwritten = try container.decodeIfPresent(Bool.self, forKey: .isHandwritten) ?? false
        isUnreadable = try container.decodeIfPresent(Bool.self, forKey: .isUnreadable) ?? false
    }
}
