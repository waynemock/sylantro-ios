import SwiftUI
import SyLibCore
import SyLibUI
import SyLibCloud

/// The library (`02` §7), the sidebar: empty until the recipe screens are designed. Its toolbar is
/// Score It *'s Games list's: the iCloud button while iCloud is not available, and ⋯ with Update
/// Available (while there is one), Settings, About and App Store. From Score It *'s
/// `GameListView.swift`, without its games, + and Players, Teams, External Display and import items.
struct LibraryView: View {
    /// Opens a sheet on the root's one presenter.
    let present: (Sheet) -> Void

    @Environment(\.syTheme) private var syTheme
    @Environment(\.openURL) private var openURL
    @Environment(AppUpdateState.self) private var updateState: AppUpdateState?

    var body: some View {
        List {
        }
        // Rounded inset groups in every column, as on iPhone.
        .listStyle(.insetGrouped)
        .paletteListBackground()
        .tint(syTheme.primaryAccent)
        .navigationTitle("Recipes")
        // The palette behind the bar once content scrolls under it.
        .paletteBarBackground()
        // Toolbar content takes its environment from where `.toolbar` is attached, so each item
        // is tinted with the window's palette.
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Draws itself only while iCloud is not available (SyLibCloud); no pulse in a toolbar.
                ICloudStatusButton(tint: syTheme.primaryAccent, pulses: false) { present(.iCloud) }
                MoreMenu(look: .toolbar, showsBadge: updateState?.showsBadge == true,
                         badgeColor: syTheme.successColor, accessibilityLabel: "More",
                         badgedAccessibilityLabel: "Menu, update available") {
                    if updateState?.isUpdateAvailable == true {
                        // The badge clears here, never on menu open; the root sends App Store
                        // links to the system.
                        Button {
                            updateState?.acknowledge()
                            openURL(SylantroApp.appStoreURL)
                        } label: {
                            Label("Update Available", systemImage: "arrow.down.circle")
                        }
                        Divider()
                    }
                    Button { present(.settings) } label: { Label("Settings", systemImage: "gearshape") }
                        .keyboardShortcut(",", modifiers: .command)
                    Divider()
                    Button { present(.about) } label: { Label("About", systemImage: "info.circle") }
                    // Syzygy Softwerks' developer page.
                    Button { openURL(SyzygyLinks.developerAppStore) } label: {
                        Label("App Store", systemImage: "storefront.fill")
                    }
                }
                .tint(syTheme.primaryAccent)
                // A menu's content doesn't take the root's cap.
                .appTextSizeCap()
            }
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView(present: { _ in })
    }
    .environment(CloudAccountStatus())
    .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .light))
}
