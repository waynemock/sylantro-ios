import Foundation
import SwiftData
import SyLibCore

extension SourcePageModel {
    private static let log = AppLogger(category: "Store")

    /// Sets every property from `value`; the words are stored as `CaptureJSON`.
    func hydrate(from value: SourcePage) {
        id = value.id
        kindRaw = value.kind.rawValue
        sessionID = value.sessionID
        capturedAt = value.capturedAt
        binderPageLabel = value.binderPageLabel
        ocrText = value.ocrText
        if value.ocrWords.isEmpty {
            ocrWordsData = nil
        } else {
            do {
                ocrWordsData = try CaptureJSON.encode(value.ocrWords)
            } catch {
                ocrWordsData = nil
                Self.log.error(self, "page \(value.id): OCR words not encoded: \(error)")
            }
        }
        structuringStateRaw = value.structuringState.rawValue
        webAddress = value.webAddress
        fetchedAt = value.fetchedAt
        fetchedRecipeJSON = value.fetchedRecipeJSON
    }

    /// The page, with an unknown kind or state read as the Domain types do (SLT-067). Words that
    /// can't be read are logged and left empty.
    func toDomain() -> SourcePage? {
        var words: [OCRWord] = []
        if let ocrWordsData {
            do {
                words = try CaptureJSON.decode([OCRWord].self, from: ocrWordsData)
            } catch {
                Self.log.error(self, "page \(id): OCR words unreadable: \(error)")
            }
        }
        return SourcePage(
            id: id,
            kind: SourceKind(rawValue: kindRaw) ?? .scan,
            sessionID: sessionID,
            capturedAt: capturedAt,
            binderPageLabel: binderPageLabel,
            ocrText: ocrText,
            ocrWords: words,
            structuringState: StructuringState(rawValue: structuringStateRaw) ?? .waiting,
            webAddress: webAddress,
            fetchedAt: fetchedAt,
            fetchedRecipeJSON: fetchedRecipeJSON
        )
    }
}
