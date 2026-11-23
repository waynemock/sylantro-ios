import Foundation
import SwiftData

extension PhotoModel {
    /// Sets every property from `value`: metadata and the file name, never the bytes (SLT-053).
    func hydrate(from value: Photo) {
        id = value.id
        kindRaw = value.kindRaw
        sourcePageID = value.sourcePageID
        recipeID = value.recipeID
        sortIndex = value.sortIndex
        pixelWidth = value.pixelWidth
        pixelHeight = value.pixelHeight
        takenAt = value.takenAt
        fileName = value.fileName
    }

    func toDomain() -> Photo? {
        Photo(
            id: id,
            kindRaw: kindRaw,
            sourcePageID: sourcePageID,
            recipeID: recipeID,
            sortIndex: sortIndex,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            takenAt: takenAt,
            fileName: fileName
        )
    }
}
