import SwiftUI
import SwiftData
import VisionKit
import SyLibCore
import SyLibUI
import SyLibCloud

/// The library (`02` §7, `13` §2), the sidebar: her recipes, newest scan first, one row per id, the
/// scans not read yet first under New Scans (S-71, SC-21), then the read ones still to check under
/// Needs Review (S-44, RV-8, `15` M3-3). Its
/// toolbar is Score It *'s Games list's: the iCloud button while iCloud is not available, the +
/// that starts a scan (SC-2, MT-21), and ⋯ with Update Available (while there is one), Settings,
/// About and App Store. From Score It *'s `GameListView.swift`, without its games, + and
/// Players, Teams, External Display and import items.
struct LibraryView: View {
    private let log = AppLogger(category: "Library")

    /// Opens a sheet on the root's one presenter.
    let present: (Sheet) -> Void
    /// The selected recipe's id.
    @Binding var selection: UUID?
    /// The photo folder, for the rows' thumbnails; nil until the root has it.
    let photoFiles: PhotoFiles?
    /// The capture writer; nil until the root has it, and the + waits for it.
    let captureRecorder: CaptureRecorder?
    /// The extraction queue, for "Reading…" (S-45); nil until the root has it.
    let extractionQueue: ExtractionQueue?

    @Environment(\.syTheme) private var syTheme
    @Environment(\.openURL) private var openURL
    @Environment(AppUpdateState.self) private var updateState: AppUpdateState?

    @Query(sort: \RecipeModel.createdAt, order: .reverse) private var recipeModels: [RecipeModel]
    @Query private var photoModels: [PhotoModel]
    /// Every page, for its structuring state: one query, not a fetch per row.
    @Query private var pageModels: [SourcePageModel]

    @State private var isShowingCamera = false
    @State private var isShowingNoCamera = false

    /// One row's values.
    private struct Row: Identifiable {
        let id: UUID
        let title: String
        let detail: RecipeRow.Detail
        let needsReview: Bool
        /// Read and structured; until then it is a new scan (SC-21).
        let isRead: Bool
        let coverFileName: String?
    }

    /// One row per id, newest first: CloudKit allows duplicates, and the first of each id wins
    /// (`02` §5.2). A recipe's cover is the photo of its first page. The line under the title, in
    /// `15` M3-3's order: being read now; not read with a failed page; not read; its author, else
    /// its publisher, else when it was scanned.
    private var rows: [Row] {
        var stateByPage: [UUID: String] = [:]
        for page in pageModels where stateByPage[page.id] == nil {
            stateByPage[page.id] = page.structuringStateRaw
        }
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
            let recipe = model.toDomain()
            let pageIDs = recipe?.sourcePageIDs ?? []
            let scanned = RecipeRow.Detail.scanned(model.createdAt, pageCount: pageIDs.count)
            let detail: RecipeRow.Detail
            if extractionQueue?.currentRecipeID == model.id {
                detail = .reading
            } else if recipe?.extraction == nil {
                let hasFailedPage = pageIDs.contains { stateByPage[$0] == StructuringState.failed.rawValue }
                detail = hasFailedPage ? .couldNotRead : scanned
            } else {
                let source = [recipe?.attribution?.author, recipe?.attribution?.publisher]
                    .compactMap { $0 }
                    .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                detail = source.map { .source($0) } ?? scanned
            }
            rows.append(Row(id: model.id,
                            title: model.title,
                            detail: detail,
                            needsReview: recipe?.needsReview == true,
                            isRead: recipe?.extraction != nil,
                            coverFileName: pageIDs.first.flatMap { coverByPage[$0]?.fileName }))
        }
        return rows
    }

    private func recipeRow(_ row: Row) -> some View {
        RecipeRow(title: row.title,
                  detail: row.detail,
                  coverFileName: row.coverFileName,
                  photoFiles: photoFiles)
            .tag(row.id)
    }

    var body: some View {
        let rows = rows
        let newScans = rows.filter { !$0.isRead }
        let toReview = rows.filter { $0.isRead && $0.needsReview }
        let others = rows.filter { $0.isRead && !$0.needsReview }
        List(selection: $selection) {
            // New Scans first (SC-21), then Needs Review (RV-8), each newest first and only while it
            // holds a recipe.
            if !newScans.isEmpty {
                Section("New Scans") {
                    ForEach(newScans) { recipeRow($0) }
                }
            }
            if !toReview.isEmpty {
                Section("Needs Review") {
                    ForEach(toReview) { recipeRow($0) }
                }
            }
            Section {
                ForEach(others) { recipeRow($0) }
            }
        }
        // Rounded inset groups in every column, as on iPhone.
        .listStyle(.insetGrouped)
        .paletteListBackground()
        .overlay {
            if rows.isEmpty {
                EmptyStateView(systemImage: "book.closed",
                               title: "No recipes yet",
                               message: "Tap + to photograph a recipe from your binder.")
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
                // The + starts a scan (SC-2, MT-21), SyLib's toolbar button (SLT-089); iOS labels
                // the symbol. The Mac has no document camera.
                if !ProcessInfo.processInfo.isiOSAppOnMac {
                    IconButton("plus", context: .toolbar) { startScan() }
                        .disabled(captureRecorder == nil)
                }
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
    private func startScan() {
        guard VNDocumentCameraViewController.isSupported else {
            log.info(self, "scan: no document camera")
            isShowingNoCamera = true
            return
        }
        isShowingCamera = true
    }
}

#Preview {
    NavigationStack {
        LibraryView(present: { _ in }, selection: .constant(nil), photoFiles: nil, captureRecorder: nil,
                    extractionQueue: nil)
    }
    .modelContainer(for: SylantroApp.syncedModels, inMemory: true)
    .environment(CloudAccountStatus())
    .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .light))
}
