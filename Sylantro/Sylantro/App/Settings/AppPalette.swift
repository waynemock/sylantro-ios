import SwiftUI
import SyLibUI

/// The App Color (SLT-085): the palette Settings stores under `SettingsKey.appPalette`, Forest when
/// nothing is stored. From Score It *'s `AppPalette.swift`.
nonisolated enum AppPalette {
    static let defaultType = SyTheme.ThemeType.forest

    /// The stored id's palette, Forest when it names none, in `colorScheme`.
    static func theme(_ storedID: String, colorScheme: ColorScheme) -> SyTheme {
        SyTheme(themeID: storedID, colorScheme: colorScheme, fallback: defaultType)
    }
}
