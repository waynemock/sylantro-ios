import Foundation

/// The one sheet presenter's routes (`00A` §12): every sheet is a case here, never a boolean of
/// its own. From Score It *'s `Sheet.swift`; later tasks add cases.
enum Sheet: Hashable, Identifiable {
    /// Settings, from the ⋯ menu.
    case settings
    /// About, from the ⋯ menu.
    case about
    /// SyLib's iCloud sheet, from the library's iCloud button.
    case iCloud

    var id: Self { self }
}
