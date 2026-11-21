import Foundation

/// The `@AppStorage` keys for this device's settings (`02` §5.5). Raw string keys appear only here;
/// later tasks add cases. From Score It *'s `SettingsKey.swift`.
enum SettingsKey: String {
    /// A SyLib `SyTheme.ThemeType` raw value, the App Color; default `AppPalette.defaultType`.
    case appPalette = "appPalette"
    /// A SyLib `AppearanceSetting` raw value; default `.system` (SLT-085).
    case colorScheme = "colorScheme"
}
