import SwiftUI
import SwiftData
import VisionKit
import SyLibCore
import SyLibUI
import SyLibCloud

/// The library (`02` §7, `13` §2), the sidebar: her recipes, newest scan first, one row per id, and
/// the Let's cook. capsule at the bottom (SC-2). Its toolbar is Score It *'s Games list's: the
/// iCloud button while iCloud is not available, and ⋯ with Update Available (while there is one),
/// Settings, About and App Store. From Score It *'s `GameListView.swift`, without its games, + and
/// Players, Teams, External Display and import items.
struct LibraryView: View {
    private let log = AppLogger(category: "Library")

    /// Opens a sheet on the root's one presenter.
    let present: (Sheet) -> Void
    /// The selected recipe's id.
    @Binding var selection: UUID?
    /// The photo folder, for the rows' thumbnails; nil until the root has it.
    let photoFiles: PhotoFiles?
    /// The capture writer; nil until the root has it, and the capsule waits for it.
    let captureRecorder: CaptureRecorder?

    @Environment(\.syTheme) private var syTheme
    @Environment(\.openURL) private var openURL
    @Environment(AppUpdateState.self) private var updateState: AppUpdateState?

    @Query(sort: \RecipeModel.createdAt, order: .reverse) private var recipeModels: [RecipeModel]
    @Query private var photoModels: [PhotoModel]

    @State private var isShowingCamera = false
    @State private var isShowingNoCamera = false

    /// One row's values.
    private struct Row: Identifiable {
        let id: UUID
        let title: String
        let createdAt: Date
        let pageCount: Int
        let coverFileName: String?
    }

    /// One row per id, newest first: CloudKit allows duplicates, and the first of each id wins
    /// (`02` §5.2). A recipe's cover is the photo of its first page.
    private var rows: [Row] {
        var coverByPage: [UUID: PhotoModel] = [:]
        for photo in photoModels {
            guard let pageID = photo.sourcePageID else { continue }
            // A page's cropped photo wins over any other kind (MT-7).
            if coverByPage[pageID] == nil || photo.kindRaw == PhotoKind.pageCropped.rawValue {
                coverByPage[pageID] = photo
            }
        }
        var seen: Set<UUID> = []
        var rows: [Row] = []
        for model in recipeModels where seen.insert(model.id).inserted {
            let pageIDs = model.toDomain()?.sourcePageIDs ?? []
            rows.append(Row(id: model.id,
                            title: model.title,
                            createdAt: model.createdAt,
                            pageCount: pageIDs.count,
                            coverFileName: pageIDs.first.flatMap { coverByPage[$0]?.fileName }))
        }
        return rows
    }

    var body: some View {
        let rows = rows
        List(selection: $selection) {
            ForEach(rows) { row in
                RecipeRow(title: row.title,
                          createdAt: row.createdAt,
                          pageCount: row.pageCount,
                          coverFileName: row.coverFileName,
                          photoFiles: photoFiles)
                    .tag(row.id)
            }
        }
        // Rounded inset groups in every column, as on iPhone.
        .listStyle(.insetGrouped)
        .paletteListBackground()
        .overlay {
            if rows.isEmpty {
                EmptyStateView(systemImage: "book.closed",
                               title: "No recipes yet",
                               message: "Tap Let's cook. and photograph a recipe from your binder.")
            }
        }
        .safeAreaInset(edge: .bottom) {
            // The Mac has no document camera (SC-2).
            if !ProcessInfo.processInfo.isiOSAppOnMac {
                CapsuleButton("Let's cook.", fillsWidth: true) { letsCook() }
                    .disabled(captureRecorder == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
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
        // A plain centered alert (SLT-088), `13` §3.4.
        .alert("Camera Not Available", isPresented: $isShowingNoCamera) {
            Button("OK") {}
        } message: {
            Text("Scanning needs an iPhone or iPad camera.")
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            if let captureRecorder {
                CaptureFlowView(mode: .newRecipes, captureRecorder: captureRecorder)
            }
        }
    }

    /// Opens the document camera, or says it isn't there.
    private func letsCook() {
        guard VNDocumentCameraViewController.isSupported else {
            log.info(self, "Let's cook.: no document camera")
            isShowingNoCamera = true
            return
        }
        isShowingCamera = true
    }
}

#Preview {
    NavigationStack {
        LibraryView(present: { _ in }, selection: .constant(nil), photoFiles: nil, captureRecorder: nil)
    }
    .modelContainer(for: SylantroApp.syncedModels, inMemory: true)
    .environment(CloudAccountStatus())
    .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .light))
}
