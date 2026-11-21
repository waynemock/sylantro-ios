import SwiftUI
import UIKit

extension DynamicTypeSize {
    /// The app's Dynamic Type range for a device (`00A` §5, `02` §6): on iPad xxxLarge to AX2,
    /// which it has room for; elsewhere (iPhone) Large to AX2. Change it here and both SwiftUI's
    /// views and UIKit's menus and alerts follow. From Score It *'s `View+TextSizeCap.swift`.
    static func appRange(for idiom: UIUserInterfaceIdiom) -> ClosedRange<DynamicTypeSize> {
        idiom == .pad ? .xxxLarge ... .accessibility2 : .large ... .accessibility2
    }

    /// The app's range on this device.
    @MainActor static var appRange: ClosedRange<DynamicTypeSize> {
        appRange(for: UIDevice.current.userInterfaceIdiom)
    }
}

extension View {
    /// Holds text within `DynamicTypeSize.appRange`. The root applies it, and so must every
    /// sheet and menu, since presented views don't take the root's.
    func appTextSizeCap() -> some View {
        dynamicTypeSize(DynamicTypeSize.appRange)
    }
}
