import Foundation
import SwiftData
import Testing
@testable import Sylantro

/// The `@Model` twins (`14` Task M2-2): each Domain value survives `hydrate`, a save and a fetch,
/// and no model holds image data (SLT-053). On an in-memory container, never the live store.
@MainActor
@Suite("Model twins")
struct ModelTwinTests {
    /// A fresh in-memory container of the synced models, off CloudKit.
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(SylantroApp.syncedModels)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @Test("a scan session survives the store")
    func scanSessionSurvives() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let model = ScanSessionModel()
        model.hydrate(from: CaptureJSONTests.fullSession)
        context.insert(model)
        try context.save()
        let fetched = try #require(try context.fetch(FetchDescriptor<ScanSessionModel>()).first)
        #expect(fetched.toDomain() == CaptureJSONTests.fullSession)
    }

    @Test("a source page survives the store")
    func sourcePageSurvives() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let model = SourcePageModel()
        model.hydrate(from: CaptureJSONTests.fullPage)
        context.insert(model)
        try context.save()
        let fetched = try #require(try context.fetch(FetchDescriptor<SourcePageModel>()).first)
        let page = try #require(fetched.toDomain())
        #expect(page.ocrWords.count == 2)
        #expect(page == CaptureJSONTests.fullPage)
    }

    @Test("a photo survives the store")
    func photoSurvives() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let model = PhotoModel()
        model.hydrate(from: CaptureJSONTests.fullPhoto)
        context.insert(model)
        try context.save()
        let fetched = try #require(try context.fetch(FetchDescriptor<PhotoModel>()).first)
        #expect(fetched.toDomain() == CaptureJSONTests.fullPhoto)
    }

    @Test("a recipe survives the store")
    func recipeSurvives() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let model = RecipeModel()
        model.hydrate(from: RecipeJSONTests.full)
        context.insert(model)
        try context.save()
        let fetched = try #require(try context.fetch(FetchDescriptor<RecipeModel>()).first)
        #expect(fetched.toDomain() == RecipeJSONTests.full)
        #expect(fetched.title == RecipeJSONTests.full.title)
    }

    @Test("a job survives the store")
    func jobSurvives() throws {
        // The device-only store's schema, in memory (`15` M3-2).
        let schema = Schema([ExtractionJobModel.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let job = ExtractionJob(recipeID: UUID(), scannedHere: true, attempts: 2, lastError: "made-up error",
                                notBefore: Date(timeIntervalSince1970: 1_795_000_000))
        let model = ExtractionJobModel()
        model.hydrate(from: job)
        context.insert(model)
        try context.save()
        let fetched = try #require(try context.fetch(FetchDescriptor<ExtractionJobModel>()).first)
        #expect(fetched.toDomain() == job)
    }

    @Test("no model holds image data")
    func noModelHoldsImageData() throws {
        let container = try Self.makeContainer()
        let schema = container.schema
        let names = Set(schema.entities.map(\.name))
        #expect(names == ["ScanSessionModel", "SourcePageModel", "RecipeModel", "PhotoModel"])
        // The two JSON properties hold text and numbers, never pixels.
        let allowedData: Set<String> = ["SourcePageModel.ocrWordsData", "RecipeModel.recipeData"]
        var bytesProperties: Set<String> = []
        for entity in schema.entities {
            for attribute in entity.attributes {
                let type = attribute.valueType
                if type == Data.self || type == Data?.self || type == [UInt8].self || type == [UInt8]?.self {
                    bytesProperties.insert("\(entity.name).\(attribute.name)")
                }
            }
        }
        // Exactly the two, so the check is seen to find `Data` where it is.
        #expect(bytesProperties == allowedData)
    }
}
