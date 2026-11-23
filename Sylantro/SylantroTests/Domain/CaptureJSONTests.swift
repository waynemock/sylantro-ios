import Foundation
import Testing
@testable import Sylantro

/// The capture types' JSON (`14` Task M2-1): they round-trip, a file missing a key or carrying a
/// value this app doesn't know still reads (SLT-061, SLT-067), and a photo holds no image data
/// (SLT-053). Every fixture is made up.
@Suite("Capture JSON")
struct CaptureJSONTests {
    // MARK: Fixtures

    /// Whole seconds, since `.iso8601` drops fractions.
    static let date = Date(timeIntervalSince1970: 1_795_000_000)
    static let fetched = Date(timeIntervalSince1970: 1_795_000_300)

    static let fixedID = UUID(uuidString: "8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F")!
    static let sessionID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    static let pageID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    static let photoID = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!
    static let recipeID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!

    static let fullSession = ScanSession(
        id: sessionID,
        startedAt: date,
        binderSection: "Desserts"
    )

    /// A web page, every property non-default, with two words.
    static let fullPage = SourcePage(
        id: pageID,
        kind: .web,
        sessionID: sessionID,
        capturedAt: date,
        binderPageLabel: "D-12",
        ocrText: "Plum Tart\n2 cups flour",
        ocrWords: [
            OCRWord(text: "Plum", box: SourceBox(pageID: pageID, x: 0.125, y: 0.0625, width: 0.25, height: 0.05), confidence: 0.875),
            OCRWord(text: "Tart", box: SourceBox(pageID: pageID, x: 0.4, y: 0.0625, width: 0.25, height: 0.05), confidence: 0.5),
        ],
        structuringState: .structured,
        webAddress: "https://example.com/plum-tart",
        fetchedAt: fetched,
        fetchedRecipeJSON: #"{"@type":"Recipe","name":"Plum Tart"}"#
    )

    /// A dish photo, every property non-default.
    static let fullPhoto = Photo(
        id: photoID,
        kindRaw: PhotoKind.dish.rawValue,
        sourcePageID: pageID,
        recipeID: recipeID,
        sortIndex: 2,
        pixelWidth: 2_048,
        pixelHeight: 1_536,
        takenAt: date,
        fileName: PhotoEncoding.fileName(for: photoID)
    )

    // MARK: Tests

    @Test("a session, a page and a photo survive a round trip")
    func roundTrip() throws {
        let session = try CaptureJSON.decode(ScanSession.self, from: CaptureJSON.encode(Self.fullSession))
        let page = try CaptureJSON.decode(SourcePage.self, from: CaptureJSON.encode(Self.fullPage))
        let photo = try CaptureJSON.decode(Photo.self, from: CaptureJSON.encode(Self.fullPhoto))
        #expect(session == Self.fullSession)
        #expect(page == Self.fullPage)
        #expect(photo == Self.fullPhoto)
    }

    @Test("a page with only an id reads with every default")
    func pageWithOnlyAnIDReadsWithDefaults() throws {
        let json = #"{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F"}"#
        let page = try CaptureJSON.decode(SourcePage.self, from: Data(json.utf8))
        #expect(page.id == Self.fixedID)
        #expect(page.kind == .scan)
        #expect(page.sessionID == nil)
        #expect(page.binderPageLabel == nil)
        #expect(page.ocrText == nil)
        #expect(page.ocrWords.isEmpty)
        #expect(page.structuringState == .waiting)
        #expect(page.webAddress == nil)
        #expect(page.fetchedAt == nil)
        #expect(page.fetchedRecipeJSON == nil)
    }

    @Test("a page without an id is refused")
    func pageWithoutAnIDIsRefused() {
        let json = #"{"kind":"scan"}"#
        #expect(throws: (any Error).self) {
            try CaptureJSON.decode(SourcePage.self, from: Data(json.utf8))
        }
    }

    @Test("an unknown source kind reads as scan")
    func unknownSourceKindIsScan() throws {
        let json = #"{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F","kind":"fax"}"#
        let page = try CaptureJSON.decode(SourcePage.self, from: Data(json.utf8))
        #expect(page.kind == .scan)
    }

    @Test("an unknown structuring state reads as waiting")
    func unknownStructuringStateIsWaiting() throws {
        let json = #"{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F","structuringState":"archived"}"#
        let page = try CaptureJSON.decode(SourcePage.self, from: Data(json.utf8))
        #expect(page.structuringState == .waiting)
    }

    @Test("an unknown photo kind survives")
    func unknownPhotoKindSurvives() throws {
        let photo = Photo(id: Self.photoID, kindRaw: "sketch", takenAt: Self.date)
        let decoded = try CaptureJSON.decode(Photo.self, from: CaptureJSON.encode(photo))
        #expect(decoded.kindRaw == "sketch")
        #expect(decoded.kind == nil)
    }

    @Test("a photo's file name is its id")
    func photoFileNameIsItsID() throws {
        #expect(PhotoEncoding.fileName(for: Self.fixedID) == "8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F.heic")
        let data = try CaptureJSON.encode(Self.fullPhoto)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let expectedKeys: Set<String> = [
            "id", "kindRaw", "sourcePageID", "recipeID", "sortIndex",
            "pixelWidth", "pixelHeight", "takenAt", "fileName",
        ]
        #expect(Set(object.keys) == expectedKeys)
    }

    @Test("an older recipe reads with no page-2 warning")
    func olderRecipeHasNoPageTwoWarning() throws {
        let json = #"{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F"}"#
        let recipe = try RecipeJSON.decode(Data(json.utf8))
        #expect(recipe.continuesOnUnscannedPage == false)
    }
}
