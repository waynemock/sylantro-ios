import SwiftUI
import SyLibUI
import SyLibCloud

/// Settings: Appearance, App Color and iCloud. Every setting is this device's `@AppStorage`
/// (`02` §5.5), which the root reads, so a change applies at once and outlasts a relaunch; Forest
/// and System by default, as `RootView`'s (SLT-085). iCloud Sync shows the root's
/// `CloudAccountStatus` and opens SyLib's iCloud sheet. From Score It *'s `SettingsSheet.swift`,
/// without Keep Screen On, Audio & Feedback, Dice and the Feel Board.
struct SettingsSheet: View {
    /// The sheet this one shows over itself.
    enum Route: Identifiable {
        case iCloud
        var id: Self { self }
    }

    @AppStorage(SettingsKey.appPalette.rawValue) private var appPalette = AppPalette.defaultType.rawValue
    @AppStorage(SettingsKey.colorScheme.rawValue) private var colorSchemeSetting = AppearanceSetting.system.rawValue
    @Environment(CloudAccountStatus.self) private var cloudStatus
    @Environment(\.syTheme) private var syTheme
    @Environment(\.dismiss) private var dismiss
    @State private var route: Route?

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    SegmentedPicker("Appearance", selection: $colorSchemeSetting,
                                    segments: AppearanceSetting.allCases.map { ($0.rawValue, $0.displayName) })
                }
                .paletteRowBackground()

                Section("App Color") {
                    PaletteChips(themeID: $appPalette)
                }
                .paletteRowBackground()

                Section("iCloud") {
                    Button {
                        route = .iCloud
                    } label: {
                        LabeledContent("iCloud Sync", value: cloudStatus.isAvailable ? "On" : "Off")
                            .foregroundStyle(.primary)
                    }
                }
                .paletteRowBackground()
            }
            .paletteListBackground()
            .navigationTitle("Settings")
            // The palette behind the bar once content scrolls under it.
            .paletteBarBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(syTheme.primaryAccent)
        .sheet(item: $route) { route in
            switch route {
            case .iCloud:
                ICloudInfoSheet(appName: "Sylantro",
                                accentColor: syTheme.primaryAccent,
                                backgroundColor: syTheme.backgroundColor)
                    // A presented sheet doesn't take the root's cap.
                    .appTextSizeCap()
            }
        }
    }
}

// A preview's `CloudAccountStatus` never asks CloudKit, so iCloud Sync shows Off.
#Preview("Settings: the defaults, Forest and System (iCloud Off)") {
    SettingsSheet()
        .environment(CloudAccountStatus())
        .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .light))
}

#Preview("Settings in Forest, dark") {
    SettingsSheet()
        .environment(CloudAccountStatus())
        .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .dark))
        .preferredColorScheme(.dark)
}
