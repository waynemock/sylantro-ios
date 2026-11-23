import SwiftUI
import SyLibCore
import SyLibUI

/// Shown instead of the library when the store won't open (`02` §5.3, `13` §5, SC-7). Nothing has
/// been deleted: Try Again retries, and Start Fresh, after a plain alert (SLT-088), sets the old
/// store aside untouched and opens a new one. S-32 says the copy in Files is safe (M2-5). Copy is `13` §6.
struct StoreRecoveryView: View {
    private let log = AppLogger(category: "StoreRecovery")
    @Binding var store: StoreState
    /// The error's description, shown under Details.
    let errorText: String
    @State private var isConfirmingStartFresh = false

    // The root's theme: Forest and System by default (SLT-085).
    @AppStorage(SettingsKey.appPalette.rawValue) private var appPalette = AppPalette.defaultType.rawValue
    @AppStorage(SettingsKey.colorScheme.rawValue) private var colorSchemeSetting = AppearanceSetting.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var theme: SyTheme {
        AppPalette.theme(appPalette, colorScheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sylantro Can't Open Your Recipes")
                    .font(.title2.bold())
                Text("Something went wrong opening your recipe library. Nothing has been deleted.")
                Text("A copy of every recipe and photo is safe in Files, in the Sylantro folder.")

                VStack(spacing: 12) {
                    Button(action: tryAgain) {
                        Text("Try Again")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        isConfirmingStartFresh = true
                    } label: {
                        Text("Start Fresh")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                DisclosureGroup("Details") {
                    Text(errorText)
                        .font(.footnote)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(theme.backgroundColor)
        .alert("Start Fresh?", isPresented: $isConfirmingStartFresh) {
            Button("Start Fresh", role: .destructive, action: startFresh)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current library is set aside, not deleted, and Sylantro opens a new one. Recipes saved in iCloud will come back.")
        }
        .environment(\.syTheme, theme)
        .tint(theme.primaryAccent)
        .onAppear {
            WindowAppearance.apply(AppearanceSetting(rawValue: colorSchemeSetting) ?? .system)
            WindowTint.apply(UIColor(theme.primaryAccent))
            UIWindow.applyContentSizeRange(DynamicTypeSize.appRange)
        }
        // AX2 at most, as the root.
        .appTextSizeCap()
    }

    /// Opens the store again: the library on success, this screen with the new error on failure.
    private func tryAgain() {
        log.info(self, "try again")
        store = StoreState.opening()
    }

    /// Sets the old store aside, untouched, then opens a new one.
    private func startFresh() {
        log.info(self, "start fresh")
        do {
            try StoreSetAside.moveAside(storeURL: StoreOpener.storeURL)
        } catch {
            log.error(self, "set aside failed: \(error)")
            store = .failed(String(describing: error))
            return
        }
        store = StoreState.opening()
    }
}

#Preview {
    StoreRecoveryView(store: .constant(.failed("A made-up error")), errorText: "A made-up error: the store could not be opened.")
}
