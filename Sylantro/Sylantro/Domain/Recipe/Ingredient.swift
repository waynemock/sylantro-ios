import Foundation

/// One ingredient. "2 to 3 cups flour, sifted" is min 2, max 3, cup, flour, sifted; the verbatim
/// line is always kept (SLT-042).
nonisolated struct Ingredient: Codable, Sendable, Equatable {
    var id: UUID
    /// The verbatim line (SLT-042).
    var rawText: String
    var quantity: Quantity?
    var unit: UnitRef?
    /// "flour".
    var item: String?
    /// "sifted".
    var preparation: String?
    var isOptional: Bool
    var note: String?
    var sourceBox: SourceBox?
    /// 0 to 1.
    var confidence: Double?
    /// Added by hand on a printed page (SLT-065).
    var isHandwritten: Bool
    /// Couldn't be read; its `sourceBox` says where it is (SLT-066).
    var isUnreadable: Bool

    init(
        id: UUID = UUID(),
        rawText: String = "",
        quantity: Quantity? = nil,
        unit: UnitRef? = nil,
        item: String? = nil,
        preparation: String? = nil,
        isOptional: Bool = false,
        note: String? = nil,
        sourceBox: SourceBox? = nil,
        confidence: Double? = nil,
        isHandwritten: Bool = false,
        isUnreadable: Bool = false
    ) {
        self.id = id
        self.rawText = rawText
        self.quantity = quantity
        self.unit = unit
        self.item = item
        self.preparation = preparation
        self.isOptional = isOptional
        self.note = note
        self.sourceBox = sourceBox
        self.confidence = confidence
        self.isHandwritten = isHandwritten
        self.isUnreadable = isUnreadable
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText) ?? ""
        quantity = try container.decodeIfPresent(Quantity.self, forKey: .quantity)
        unit = try container.decodeIfPresent(UnitRef.self, forKey: .unit)
        item = try container.decodeIfPresent(String.self, forKey: .item)
        preparation = try container.decodeIfPresent(String.self, forKey: .preparation)
        isOptional = try container.decodeIfPresent(Bool.self, forKey: .isOptional) ?? false
        note = try container.decodeIfPresent(String.self, forKey: .note)
        sourceBox = try container.decodeIfPresent(SourceBox.self, forKey: .sourceBox)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        isHandwritten = try container.decodeIfPresent(Bool.self, forKey: .isHandwritten) ?? false
        isUnreadable = try container.decodeIfPresent(Bool.self, forKey: .isUnreadable) ?? false
    }
}
