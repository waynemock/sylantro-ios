import Foundation
import SwiftData

/// Version 1 of Sylantro's synced schema (`02` §5.1), shaped as SyLib's `ScoringSchemaV1`. Every
/// property is defaulted (SLT-014); there is no `.unique` (CloudKit refuses it) and no
/// relationship: models link by ids, as the Domain types do (`14` MT-4). No image data (SLT-053).
/// Once the CloudKit Production schema is deployed it is frozen; changes go in a new version.
enum SylantroSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [ScanSessionModel.self, SourcePageModel.self, RecipeModel.self, PhotoModel.self]
    }

    /// A `ScanSession`.
    @Model final class ScanSessionModel {
        var id: UUID = UUID()
        var startedAt: Date = Date()
        var binderSection: String? = nil
        init() {}
    }

    /// A `SourcePage`. Its photos are `PhotoModel`s that carry its id.
    @Model final class SourcePageModel {
        var id: UUID = UUID()
        var kindRaw: String = "scan"
        var sessionID: UUID? = nil
        var capturedAt: Date = Date()
        var binderPageLabel: String? = nil
        var ocrText: String? = nil
        /// The `[OCRWord]` as `CaptureJSON`: text and boxes, never pixels.
        var ocrWordsData: Data? = nil
        var structuringStateRaw: String = "waiting"
        var webAddress: String? = nil
        var fetchedAt: Date? = nil
        var fetchedRecipeJSON: String? = nil
        init() {}
    }

    /// A `Recipe`, held whole as `RecipeJSON` (`14` MT-5); `title`, `reviewStateRaw` and the dates
    /// are copies kept for `@Query` sorting.
    @Model final class RecipeModel {
        var id: UUID = UUID()
        var title: String = ""
        var createdAt: Date = Date()
        var updatedAt: Date = Date()
        var reviewStateRaw: String = "needsReview"
        var recipeData: Data? = nil
        init() {}
    }

    /// A `Photo`: its metadata and file name, never its bytes (SLT-053).
    @Model final class PhotoModel {
        var id: UUID = UUID()
        var kindRaw: String = "pageOriginal"
        var sourcePageID: UUID? = nil
        var recipeID: UUID? = nil
        var sortIndex: Int = 0
        var pixelWidth: Int? = nil
        var pixelHeight: Int? = nil
        var takenAt: Date = Date()
        var fileName: String? = nil
        init() {}
    }
}

typealias ScanSessionModel = SylantroSchemaV1.ScanSessionModel
typealias SourcePageModel = SylantroSchemaV1.SourcePageModel
typealias RecipeModel = SylantroSchemaV1.RecipeModel
typealias PhotoModel = SylantroSchemaV1.PhotoModel

/// The store's schema history: one version, no stages yet.
enum SylantroMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SylantroSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
