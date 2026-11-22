import SwiftData

/// Whether the synced store opened (`02` §5.3): the app shows the library when it did, and the
/// recovery screen with the error's description when it didn't.
enum StoreState {
    case open(ModelContainer)
    case failed(String)

    /// Opens the store, never throwing: a failure becomes `.failed` with the error's description.
    static func opening() -> StoreState {
        do {
            return .open(try StoreOpener.open())
        } catch {
            return .failed(String(describing: error))
        }
    }
}
