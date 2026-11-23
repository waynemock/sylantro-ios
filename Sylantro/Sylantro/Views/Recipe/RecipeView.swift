import SwiftUI
import SwiftData
import VisionKit
import SyLibCore
import SyLibUI

/// A recipe, M2's version (`13` §4): its title, "Waiting to be read" until M3 reads it, the page-2
/// warning, and its pages full width in order. Add Page and Delete Recipe in the toolbar.
struct RecipeView: View {
    private let log = AppLogger(category: "Recipe")

    let recipeID: UUID
    let photoFiles: PhotoFiles?
    let recipeEditor: RecipeEditor?
    let captureRecorder: CaptureRecorder?
    /// Called once the recipe is deleted, so the selection clears.
    let onDeleted: () -> Void

    @Environment(\.syTheme) private var syTheme
    @Query private var recipeModels: [RecipeModel]
    @Query private var photoModels: [PhotoModel]

    @State private var isAddingPages = false
    @State private var isShowingNoCamera = false
    @State private var isConfirmingDelete = false
    @State private var viewedPage: ViewedPage?

    /// The page open in the full-screen viewer.
    private struct ViewedPage: Identifiable {
        let id: String
    }

    init(recipeID: UUID, photoFiles: PhotoFiles?, recipeEditor: RecipeEditor?,
         captureRecorder: CaptureRecorder?, onDeleted: @escaping () -> Void) {
        self.recipeID = recipeID
        self.photoFiles = photoFiles
        self.recipeEditor = recipeEditor
        self.captureRecorder = captureRecorder
        self.onDeleted = onDeleted
        _recipeModels = Query(filter: #Predicate<RecipeModel> { $0.id == recipeID })
        _photoModels = Query(filter: #Predicate<PhotoModel> { $0.sourcePageID != nil })
    }

    var body: some View {
        if let recipe = recipeModels.first?.toDomain() {
            content(recipe)
        } else {
            NoRecipeSelectedView()
        }
    }

    private func content(_ recipe: Recipe) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if recipe.extraction == nil {
                    Text("Waiting to be read")
                        .foregroundStyle(.secondary)
                }
                if recipe.continuesOnUnscannedPage {
                    Label("Continues on a page not scanned", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
                ForEach(recipe.sourcePageIDs, id: \.self) { pageID in
                    if let photo = photo(forPage: pageID) {
                        Button {
                            if let fileName = photo.fileName {
                                viewedPage = ViewedPage(id: fileName)
                            }
                        } label: {
                            PagePhotoView(photo: photo, photoFiles: photoFiles)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(syTheme.backgroundColor)
        .navigationTitle(recipe.title.isEmpty ? "New recipe" : recipe.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // SyLib's toolbar buttons (SLT-089); Add Page reads as S-22 (MT-26).
                IconButton("doc.badge.plus", context: .toolbar) { addPage() }
                    .accessibilityLabel("Add Page")
                    .disabled(captureRecorder == nil)
                // The ⋯ symbol alone: iOS gives it its own label (MT-11).
                Menu {
                    Button("Delete Recipe", role: .destructive) { isConfirmingDelete = true }
                        .disabled(recipeEditor == nil)
                } label: {
                    IconButton("ellipsis.circle", context: .toolbar)
                }
                .appTextSizeCap()
            }
        }
        // Plain centered alerts (SLT-088).
        .alert("Delete This Recipe?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes the recipe and its page photos from all your devices. This can't be undone.")
        }
        .alert("Camera Not Available", isPresented: $isShowingNoCamera) {
            Button("OK") {}
        } message: {
            Text("Scanning needs an iPhone or iPad camera.")
        }
        .fullScreenCover(isPresented: $isAddingPages) {
            if let captureRecorder {
                CaptureFlowView(mode: .addPages(recipeID: recipeID), captureRecorder: captureRecorder)
            }
        }
        .fullScreenCover(item: $viewedPage) { page in
            PagePhotoViewer(fileName: page.id, photoFiles: photoFiles)
                .appTextSizeCap()
        }
    }

    /// The page's photo: its cropped photo (MT-7) if it has one, else any photo of it.
    private func photo(forPage pageID: UUID) -> Photo? {
        let photos = photoModels.filter { $0.sourcePageID == pageID }
        let model = photos.first { $0.kindRaw == PhotoKind.pageCropped.rawValue } ?? photos.first
        return model?.toDomain()
    }

    private func addPage() {
        guard VNDocumentCameraViewController.isSupported else {
            log.info(self, "Add Page: no document camera")
            isShowingNoCamera = true
            return
        }
        isAddingPages = true
    }

    private func delete() {
        guard let recipeEditor else { return }
        do {
            try recipeEditor.delete(recipeID)
            onDeleted()
        } catch {
            log.error(self, "recipe \(recipeID) not deleted: \(error)")
        }
    }
}
