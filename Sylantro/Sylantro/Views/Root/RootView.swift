import SwiftUI
import SwiftData
import SyLibCore
import SyLibUI
import SyLibCloud

/// The app's root (`02` §6, §7): the library in the sidebar and the selected recipe in the detail,
/// one column on iPhone. It owns the one sheet presenter, the theme, the Appearance setting, the
/// iCloud status and the update check. From Score It *'s `RootView.swift`, without its game
/// navigation, per-screen palettes and TV board.
struct RootView: View {
    private let log = AppLogger(category: "RootView")
    @State private var sheet: Sheet?
    /// The iCloud account's state, for the library's iCloud button and Settings.
    @State private var cloudStatus = CloudAccountStatus(containerIdentifier: SylantroApp.cloudKitContainerID)
    /// Whether the App Store has a newer version, for the ⋯ badge and Update Available.
    @State private var updateState = AppUpdateState()

    @Environment(\.modelContext) private var modelContext
    /// The photo folder and the two writers (`02` §5.2), made once at launch; nil until then, so the
    /// + waits for them.
    @State private var photoFiles: PhotoFiles?
    @State private var recipeEditor: RecipeEditor?
    @State private var captureRecorder: CaptureRecorder?
    /// The selected recipe's id.
    @State private var selection: UUID?

    // Forest and System by default (SLT-085).
    @AppStorage(SettingsKey.appPalette.rawValue) private var appPalette = AppPalette.defaultType.rawValue
    @AppStorage(SettingsKey.colorScheme.rawValue) private var colorSchemeSetting = AppearanceSetting.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    /// The App Color chosen in Settings in the current color scheme. The whole window wears it:
    /// the environment's `syTheme` for both columns and every sheet, and the tint.
    private var theme: SyTheme {
        AppPalette.theme(appPalette, colorScheme: colorScheme)
    }

    /// What the window tint depends on, so it is set again whenever any of it changes.
    private var tintKey: String {
        "\(appPalette)|\(colorScheme == .dark ? "dark" : "light")"
    }

    /// The Appearance setting; System for a value it doesn't know.
    private var appearance: AppearanceSetting {
        AppearanceSetting(rawValue: colorSchemeSetting) ?? .system
    }

    /// The setting goes on every window (SyLib's `WindowAppearance`), so a sheet already presented
    /// changes with the app.
    private func applyAppearance() {
        log.debug(self, "appearance \(appearance.rawValue)")
        WindowAppearance.apply(appearance)
    }

    var body: some View {
        NavigationSplitView {
            LibraryView(present: { sheet = $0 },
                        selection: $selection,
                        photoFiles: photoFiles,
                        captureRecorder: captureRecorder)
        } detail: {
            if let selection {
                RecipeView(recipeID: selection,
                           photoFiles: photoFiles,
                           recipeEditor: recipeEditor,
                           captureRecorder: captureRecorder,
                           onDeleted: { self.selection = nil })
                    .id(selection)
            } else {
                NoRecipeSelectedView()
            }
        }
        .sheet(item: $sheet) { sheet in
            // A presented sheet doesn't take the root's cap. Each sheet opens its own web links,
            // since the root can't present over a sheet it is presenting.
            sheetContent(sheet)
                .opensWebLinksInApp()
                .appTextSizeCap()
        }
        // Web links stay in the app: web pages open in the in-app Safari view; App Store pages and
        // other schemes go to the system.
        .opensWebLinksInApp()
        .environment(\.syTheme, theme)
        .tint(theme.primaryAccent)
        .environment(cloudStatus)
        .environment(updateState)
        .task {
            // Previews never ask CloudKit or the App Store; the app asks once at launch, then SyLib
            // keeps both current.
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            // The photo folder, the copy in Files, then the writers on this window's store (`14`
            // M2-4, M2-5).
            let files = await PhotoFiles.live()
            // The views get the photo folder as soon as it is known (`14` M2-4g).
            photoFiles = files
            let mirror = await MirrorWriter.live(photoFiles: files)
            let editor = RecipeEditor(context: modelContext, mirror: mirror, photoFiles: files)
            recipeEditor = editor
            captureRecorder = CaptureRecorder(context: modelContext, photoFiles: files, recipeEditor: editor, mirror: mirror)
            catchUpMirror(mirror)
            await cloudStatus.refresh()
            await updateState.check()
            log.info(self, "update check: available \(updateState.isUpdateAvailable) storeVersion \(updateState.storeVersion ?? "none") showsBadge \(updateState.showsBadge)")
        }
        // Alerts, the navigation bars and Back take the window's tint, which `.tint` does not set.
        .onAppear {
            applyAppearance()
            WindowTint.apply(UIColor(theme.primaryAccent))
            // UIKit's menus and alerts take the cap from the window, not from SwiftUI.
            UIWindow.applyContentSizeRange(DynamicTypeSize.appRange)
        }
        .onChange(of: tintKey) { WindowTint.apply(UIColor(theme.primaryAccent)) }
        .onChange(of: colorSchemeSetting) { applyAppearance() }
        // AX2 at most; every presented view repeats the cap, since presentations don't take it.
        .appTextSizeCap()
    }

    /// At launch (MT-15): this device's pending copies and any recipe missing from Files, from
    /// snapshots of every recipe in the store (one per id), written in a detached task.
    private func catchUpMirror(_ mirror: MirrorWriter) {
        do {
            var seen: Set<UUID> = []
            let recipes = try modelContext.fetch(FetchDescriptor<RecipeModel>())
                .filter { seen.insert($0.id).inserted }
                .compactMap { $0.toDomain() }
            let snapshots = try MirrorSnapshot.make(for: recipes, in: modelContext)
            Task.detached { await mirror.catchUp(snapshots) }
        } catch {
            log.error(self, "mirror catch-up not started: \(error)")
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: Sheet) -> some View {
        switch sheet {
        case .settings:
            SettingsSheet()
        case .about:
            AboutView(appName: "Sylantro",
                      tagline: Self.aboutTagline,
                      description: Self.aboutDescription,
                      appStoreURL: SylantroApp.appStoreURL,
                      accentColor: theme.primaryAccent,
                      backgroundColor: theme.backgroundColor)
        case .iCloud:
            ICloudInfoSheet(appName: "Sylantro",
                            accentColor: theme.primaryAccent,
                            backgroundColor: theme.backgroundColor)
        }
    }

    /// About's tagline and description: Claude's draft at Pops's request, 21 Nov 2026 (SLT-087).
    private static let aboutTagline = "Your recipe binder, in your pocket."
    private static let aboutDescription = "Sylantro turns your binder of printed recipes into a cookbook you can search. Tap +, photograph a page, and keep going. Sylantro reads each page right on your device and lays out the title, ingredients and steps for you to check. Every original photo is kept, your recipes sync through iCloud to your iPhone, iPad and Mac, and a plain copy of each one is saved in Files, so your recipes always stay yours."
}

#Preview {
    RootView()
        .modelContainer(for: SylantroApp.syncedModels, inMemory: true)
        .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .light))
}
