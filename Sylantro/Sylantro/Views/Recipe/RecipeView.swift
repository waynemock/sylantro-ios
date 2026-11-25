import SwiftUI
import SwiftData
import UIKit
import VisionKit
import SyLibCache
import SyLibCore
import SyLibUI

/// A recipe (`13` §4). Before it is read, M2's screen: its title, "Waiting to be read" (or
/// "Reading…" while the queue has it, or "couldn't read" with Try Again), the page-2 warning, and
/// its pages full width in order. Once read, the review screen (`13` §4.4, SC-9, `15` M3-3): the
/// page beside or above the fields, flags tinted with their lines, tap a line to see it on the
/// page, Edit and Done for the kitchen fields (each row edited in a sheet, SC-19) and the pages
/// (`13` §4.6, M3-4), and Looks Good. The toolbar is only ⋯ (Edit, Add Page, View Pages, Delete
/// Recipe), or Done in Edit (SC-20). After its pages change, a read recipe is read again, asking
/// first if she edited it (RV-7).
struct RecipeView: View {
    private let log = AppLogger(category: "Recipe")

    let recipeID: UUID
    let photoFiles: PhotoFiles?
    let recipeEditor: RecipeEditor?
    let captureRecorder: CaptureRecorder?
    /// For "Reading…" (S-45); nil until the root has it.
    let extractionQueue: ExtractionQueue?
    /// Called once the recipe is deleted, so the selection clears.
    let onDeleted: () -> Void

    @Environment(\.syTheme) private var syTheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// For reading the recipe as just saved (RV-7's question); writes go through the writers.
    @Environment(\.modelContext) private var modelContext
    @Query private var recipeModels: [RecipeModel]
    @Query private var photoModels: [PhotoModel]
    /// Every page, for its structuring state.
    @Query private var pageModels: [SourcePageModel]

    @State private var isAddingPages = false
    @State private var isShowingNoCamera = false
    @State private var isConfirmingDelete = false
    @State private var viewedPage: ViewedPage?

    /// What the page shows: nil at first (the top of page 1), a line, or a page whole.
    @State private var pageSelection: PageSelection?
    /// iPhone: the strip opened to the whole page.
    @State private var isStripExpanded = false
    /// Edit and Done (SC-10).
    @State private var editMode: EditMode = .inactive
    /// The fields as she edits them.
    @State private var draft = ReviewEdit(title: "", yieldText: "", groups: [], steps: [], notes: "")
    /// The fields as they were when Edit began; nil when not editing.
    @State private var editStart: ReviewEdit?
    @State private var isShowingSaveFailed = false
    /// The row open in the edit sheet (SC-19), and whether its sheet was closed by Save.
    @State private var editingField: EditingField?
    @State private var editingFieldSaved = false
    /// The last row opened, kept after the sheet clears `editingField`, for its close.
    @State private var openedField: EditingField?
    /// The page order as she edits it (M3-4); the order as saved; the pages she removed, not yet
    /// saved.
    @State private var draftPageIDs: [UUID] = []
    @State private var savedPageIDs: [UUID] = []
    @State private var removedPageIDs: [UUID] = []
    /// The rows waiting on the remove alert (S-54).
    @State private var pendingPageRemoval: IndexSet?
    @State private var isConfirmingPageRemoval = false
    /// Its pages changed and it isn't read again yet (RV-7).
    @State private var needsReadAgain = false
    @State private var isAskingReadAgain = false
    /// Read Again from ⋯ on a recipe she edited (RV-33, S-73).
    @State private var isAskingReadAgainFromMenu = false
    /// Read Again from ⋯ on a recipe she hasn't edited (SC-23, S-78).
    @State private var isAskingReadAgainNotEdited = false
    /// Add Page saved pages: RV-7 runs once the camera has closed.
    @State private var pagesWereAdded = false
    /// She has tapped a line, so S-61's hint no longer shows on this device (SC-16): device-only,
    /// never synced, never in the store.
    @AppStorage("reviewHintSeen") private var reviewHintSeen = false

    /// The row open in the edit sheet: its field, and whether + just added it (Cancel removes it).
    private struct EditingField: Identifiable {
        let id = UUID()
        let field: ReviewEdit.Field
        let isNew: Bool
    }

    /// The pages open in the full-screen viewer: from this page, with this line outlined.
    private struct ViewedPage: Identifiable {
        let id = UUID()
        let startPageID: UUID?
        let box: SourceBox?
    }

    /// What the page shows after a tap (RV-11).
    enum PageSelection: Equatable {
        /// A line with a place on the page, outlined.
        case line(SourceBox)
        /// A page whole: a tapped field with no place on the page shows the first page.
        case wholePage(UUID)
    }

    init(recipeID: UUID, photoFiles: PhotoFiles?, recipeEditor: RecipeEditor?,
         captureRecorder: CaptureRecorder?, extractionQueue: ExtractionQueue?, onDeleted: @escaping () -> Void) {
        self.recipeID = recipeID
        self.photoFiles = photoFiles
        self.recipeEditor = recipeEditor
        self.captureRecorder = captureRecorder
        self.extractionQueue = extractionQueue
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

    private var isEditing: Bool {
        editMode.isEditing
    }

    private func content(_ recipe: Recipe) -> some View {
        Group {
            if recipe.extraction == nil {
                unreadContent(recipe)
            } else {
                readContent(recipe)
            }
        }
        .background(syTheme.backgroundColor)
        // SC-18: a small title naming the view, not the recipe.
        .navigationTitle(barTitle(recipe))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if isEditing {
                    // In Edit, only iOS's Done (S-50, SC-20), which ends Edit and saves.
                    EditButton()
                } else {
                    // Only ⋯ (SC-20), the symbol alone: iOS gives it its own label (MT-11).
                    Menu {
                        // Edit (S-70), once read; `beginEditing` runs from `onChange`.
                        if recipe.extraction != nil {
                            Button { editMode = .active } label: { Label("Edit", systemImage: "pencil") }
                        }
                        Button { addPage() } label: { Label("Add Page", systemImage: "doc.badge.plus") }
                            .disabled(captureRecorder == nil)
                        // The scans, when the strip isn't shown (SC-14, S-62).
                        if recipe.extraction != nil && horizontalSizeClass == .compact && !showsStrip(recipe) {
                            Button("View Pages") {
                                viewedPage = ViewedPage(startPageID: recipe.sourcePageIDs.first, box: nil)
                            }
                        }
                        // Read Again (S-59, RV-33), once read; not while the queue is reading it.
                        if recipe.extraction != nil {
                            Button { readAgainFromMenu(recipe) } label: {
                                Label("Read Again", systemImage: "arrow.clockwise")
                            }
                            .disabled(captureRecorder == nil || extractionQueue?.currentRecipeID == recipe.id)
                        }
                        Divider()
                        Button("Delete Recipe", role: .destructive) { isConfirmingDelete = true }
                            .disabled(recipeEditor == nil)
                    } label: {
                        IconButton("ellipsis.circle", context: .toolbar)
                    }
                    .appTextSizeCap()
                }
            }
        }
        .environment(\.editMode, $editMode)
        .onChange(of: editMode) { old, new in
            if !old.isEditing && new.isEditing {
                beginEditing()
            } else if old.isEditing && !new.isEditing {
                finishEditing()
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
        // An edit that didn't save (S-14); she stays in Edit.
        .alert("Couldn't Save", isPresented: $isShowingSaveFailed) {
            Button("OK") {}
        }
        // Removing a page in Edit (S-54 to S-56).
        .alert("Remove This Page?", isPresented: $isConfirmingPageRemoval) {
            Button("Remove", role: .destructive) { removePendingPages() }
            Button("Cancel", role: .cancel) { pendingPageRemoval = nil }
        } message: {
            Text("This removes the page and its photo from all your devices. This can't be undone.")
        }
        // RV-7: her edits would be replaced (S-57 to S-59).
        .alert("Read the Pages Again?", isPresented: $isAskingReadAgain) {
            Button("Read Again") { readAgainAfterAsking() }
            Button("Keep My Edits", role: .cancel) { needsReadAgain = false }
        } message: {
            Text("The pages changed. Reading them again replaces your edits to this recipe.")
        }
        // RV-33: Read Again from ⋯ on a recipe she edited (S-57, S-73, S-59).
        .alert("Read the Pages Again?", isPresented: $isAskingReadAgainFromMenu) {
            Button("Read Again") { readAgainAfterAsking() }
            Button("Keep My Edits", role: .cancel) {}
        } message: {
            Text("Reading the pages again replaces your edits to this recipe.")
        }
        // SC-23: Read Again from ⋯ always asks; not edited (S-57, S-78, S-59 and Cancel).
        .alert("Read the Pages Again?", isPresented: $isAskingReadAgainNotEdited) {
            Button("Read Again") { readAgainAfterAsking() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces the current reading of this recipe.")
        }
        .fullScreenCover(isPresented: $isAddingPages, onDismiss: pagesAddedCameraClosed) {
            if let captureRecorder {
                CaptureFlowView(mode: .addPages(recipeID: recipeID), captureRecorder: captureRecorder,
                                onPagesAdded: { pagesWereAdded = true })
            }
        }
        // The edit sheet (SC-19): a swipe down, allowed only while nothing changed, is a Cancel.
        .sheet(item: $editingField, onDismiss: editSheetClosed) { editing in
            RowEditSheet(title: sheetTitle(editing.field),
                         original: draft.text(for: editing.field),
                         photo: fieldBox(editing.field, recipe).flatMap { photo(forPage: $0.pageID) },
                         box: fieldBox(editing.field, recipe),
                         photoFiles: photoFiles,
                         accent: syTheme.primaryAccent) { text in
                draft = draft.setting(text, for: editing.field)
                editingFieldSaved = true
                editingField = nil
            } onCancel: {
                editingField = nil
            }
            .appTextSizeCap()
        }
        .fullScreenCover(item: $viewedPage) { page in
            let fileNames = recipe.sourcePageIDs.compactMap { photo(forPage: $0)?.fileName }
            let pagesWithPhotos = recipe.sourcePageIDs.filter { photo(forPage: $0)?.fileName != nil }
            PagePhotoViewer(fileNames: fileNames,
                            startIndex: page.startPageID.flatMap { pagesWithPhotos.firstIndex(of: $0) } ?? 0,
                            box: page.box, photoFiles: photoFiles)
                .appTextSizeCap()
        }
    }

    // MARK: Before it is read (M2, `13` §4.1)

    private func unreadContent(_ recipe: Recipe) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if extractionQueue?.currentRecipeID == recipe.id {
                    Text("Reading…")
                        .foregroundStyle(.secondary)
                    // SC-23: a bar under it, the line's width, moving step by step.
                    if let progress = extractionQueue?.progress {
                        ProgressView(value: progress)
                            .tint(syTheme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut, value: progress)
                    }
                } else if hasFailedPage(recipe) {
                    // RV-24's three tries are spent: Try Again puts it back in the queue.
                    Text("Sylantro couldn't read these pages. Check that they're in focus, or try again.")
                        .foregroundStyle(.secondary)
                    CapsuleButton("Try Again") { retry() }
                        .disabled(captureRecorder == nil)
                } else {
                    Text("Waiting to be read")
                        .foregroundStyle(.secondary)
                }
                if recipe.continuesOnUnscannedPage {
                    Label("Continues on a page not scanned", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
                ForEach(recipe.sourcePageIDs, id: \.self) { pageID in
                    pageButton(pageID, selectedBox: nil)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Once read (`13` §4.4)

    @ViewBuilder
    private func readContent(_ recipe: Recipe) -> some View {
        if horizontalSizeClass == .compact && !showsStrip(recipe) {
            // iPhone, once checked (SC-14): the fields from the title, no photo at the top.
            fields(recipe)
        } else if horizontalSizeClass == .compact {
            // iPhone while she checks it or edits: the page strip across the top, about a third of
            // the height, then the fields.
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    PageStrip(photo: stripPhoto(recipe), selectedBox: stripBox(recipe),
                              showsWholePage: isWholePageSelected,
                              isExpanded: isStripExpanded, photoFiles: photoFiles,
                              accent: syTheme.primaryAccent) {
                        withAnimation(.easeInOut) { isStripExpanded.toggle() }
                    }
                    // A fresh strip for each page, so its image is that page's (RV-11, M3-3e).
                    .id(stripPhoto(recipe)?.sourcePageID)
                    .frame(height: isStripExpanded ? geometry.size.height : geometry.size.height / 3)
                    if !isStripExpanded {
                        fields(recipe)
                    }
                }
            }
        } else {
            // iPad and Mac: the pages on the left, the fields on the right, about 45% / 55%.
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    pagesColumn(recipe)
                        .frame(width: geometry.size.width * 0.45)
                    fields(recipe)
                        .frame(width: geometry.size.width * 0.55)
                }
            }
        }
    }

    /// The selected line's box, if a line is selected.
    private var selectedBox: SourceBox? {
        if case .line(let box) = pageSelection { return box }
        return nil
    }

    /// The strip's line: the selected one; with nothing selected, the title's (RV-31).
    private func stripBox(_ recipe: Recipe) -> SourceBox? {
        pageSelection == nil ? recipe.titleBox : selectedBox
    }

    /// SC-14: on iPhone the strip shows while she checks the recipe or edits it.
    private func showsStrip(_ recipe: Recipe) -> Bool {
        recipe.needsReview || isEditing
    }

    /// SC-16: S-61 shows while the strip does (iPhone) or while she checks it (iPad and Mac),
    /// until her first tap on a line.
    private func showsHint(_ recipe: Recipe) -> Bool {
        guard !reviewHintSeen else { return false }
        return horizontalSizeClass == .compact ? showsStrip(recipe) : recipe.needsReview
    }

    /// SC-18's bar title: S-2 before it is read, S-64 in Edit, S-63 while she checks it, S-65 once
    /// reviewed.
    private func barTitle(_ recipe: Recipe) -> LocalizedStringKey {
        if recipe.extraction == nil { return "New recipe" }
        if isEditing { return "Edit" }
        return recipe.needsReview ? "Review" : "Recipe"
    }

    private var isWholePageSelected: Bool {
        if case .wholePage = pageSelection { return true }
        return false
    }

    /// The strip's page: the selected line's, the page shown whole, else the title's, else the
    /// first page.
    private func stripPhoto(_ recipe: Recipe) -> Photo? {
        switch pageSelection {
        case .line(let box): photo(forPage: box.pageID)
        case .wholePage(let pageID): photo(forPage: pageID)
        case nil: (recipe.titleBox?.pageID ?? recipe.sourcePageIDs.first).flatMap(photo(forPage:))
        }
    }

    /// iPad and Mac: every page, full column width, the selected line outlined on its page and
    /// scrolled into view.
    private func pagesColumn(_ recipe: Recipe) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(recipe.sourcePageIDs, id: \.self) { pageID in
                        pageButton(pageID, selectedBox: selectedBox.flatMap { $0.pageID == pageID ? $0 : nil })
                            .id(pageID)
                    }
                }
                .padding()
            }
            .onChange(of: pageSelection) { _, selection in
                withAnimation(.easeInOut) {
                    switch selection {
                    case .line(let box):
                        proxy.scrollTo(box.pageID, anchor: UnitPoint(x: 0.5, y: box.y + box.height / 2))
                    case .wholePage(let pageID):
                        proxy.scrollTo(pageID, anchor: .top)
                    case nil:
                        break
                    }
                }
            }
        }
    }

    /// One page, full width; a tap opens it full screen (`13` §4.1). `selectedBox` is outlined.
    @ViewBuilder
    private func pageButton(_ pageID: UUID, selectedBox: SourceBox?) -> some View {
        if let photo = photo(forPage: pageID) {
            Button {
                if photo.fileName != nil {
                    viewedPage = ViewedPage(startPageID: pageID, box: nil)
                }
            } label: {
                PagePhotoView(photo: photo, photoFiles: photoFiles)
                    .overlay {
                        if let selectedBox {
                            GeometryReader { geometry in
                                LineOutline(box: selectedBox, size: geometry.size, accent: syTheme.primaryAccent)
                            }
                        }
                    }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: The fields

    private func fields(_ recipe: Recipe) -> some View {
        let flags = recipe.needsReview ? ReviewFlag.flags(for: recipe) : []
        return List {
            pagesSection()
            headerSection(recipe, flags: flags)
            ingredientsSection(recipe, flags: flags)
            stepsSection(recipe, flags: flags)
            notesSection(recipe, flags: flags)
            equipmentSection(recipe, flags: flags)
            nutritionSection(recipe, flags: flags)
            sourceSection(recipe, flags: flags)
            if recipe.needsReview && !isEditing {
                Section {
                    CapsuleButton("Looks Good", fillsWidth: true) { markReviewed() }
                        .disabled(recipeEditor == nil)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .paletteListBackground()
    }

    /// The flags naming `field`.
    private func flags(_ flags: [ReviewFlag], on field: ReviewFlag.Field) -> [ReviewFlag] {
        flags.filter { $0.field == field }
    }

    /// In Edit, the pages first (`13` §4.6): one thumbnail row each, no words, VoiceOver reading
    /// S-60; drag to move; delete asks first (S-54), and the only page has none.
    @ViewBuilder
    private func pagesSection() -> some View {
        if isEditing {
            Section {
                ForEach(Array(draftPageIDs.enumerated()), id: \.element) { offset, pageID in
                    PageThumbnail(photo: photo(forPage: pageID), photoFiles: photoFiles)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Page \(offset + 1)")
                }
                .onMove { draftPageIDs.move(fromOffsets: $0, toOffset: $1) }
                .onDelete(perform: draftPageIDs.count > 1 ? { offsets in
                    pendingPageRemoval = offsets
                    isConfirmingPageRemoval = true
                } : nil)
            } header: {
                // S-72 (`13` §4.6).
                heading("Pages")
            }
        }
    }

    /// Title, the whole-recipe lines, Serves or Makes, and the times.
    @ViewBuilder
    private func headerSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let titleFlags = flags(all, on: .title)
        Section {
            // SC-16: the hint, above the title.
            if showsHint(recipe) {
                Label("Tap a line to see it on the page.", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if isEditing {
                editRow(.title, recipe, emptyWord: "Title") { text in
                    Text(verbatim: text)
                        .font(.title.bold())
                }
                .flaggedRow(titleFlags)
            } else {
                Button { show(recipe.titleBox, recipe) } label: {
                    Text(verbatim: recipe.title.isEmpty ? "New recipe" : recipe.title)
                        .font(.title.bold())
                        .flagged(titleFlags)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Show on page")
                .flaggedRow(titleFlags)
            }

            // Read again (M3-3i, SC-23): while the queue reads this read recipe, "Reading…" and
            // M3-3f's bar, first under the title, as a whole-recipe line, not tinted; not in Edit.
            if !isEditing, recipe.extraction != nil, extractionQueue?.currentRecipeID == recipe.id {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading…")
                        .foregroundStyle(.secondary)
                    if let progress = extractionQueue?.progress {
                        ProgressView(value: progress)
                            .tint(syTheme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut, value: progress)
                    }
                }
            }

            // The whole-recipe lines (S-52h, S-52i, S-52j, S-52k).
            if recipe.continuesOnUnscannedPage {
                HStack {
                    Label("Continues on a page not scanned", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("That's All of It") { dismissPageTwoWarning() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(recipeEditor == nil)
                }
            }
            ForEach(Array(flags(all, on: .recipe).enumerated()), id: \.offset) { _, flag in
                if flag.kind != .continuesOnUnscannedPage {
                    Label(ReviewFlag.line(for: flag.kind), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            }

            if isEditing {
                editRow(.yield, recipe, emptyWord: "Serves") { Text(verbatim: $0) }
            } else if let yield = recipe.yield.flatMap(RecipeRendering.yieldLine) {
                placedLine(recipe.fieldBoxes[Recipe.FieldBoxKey.yield], recipe) { Text(verbatim: yield) }
            }
            if let times = recipe.times.flatMap(RecipeRendering.timesLine) {
                placedLine(recipe.fieldBoxes[Recipe.FieldBoxKey.times], recipe) { Text(verbatim: times) }
                    .dimmed(isEditing)
            }
        }
    }

    @ViewBuilder
    private func ingredientsSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let listFlags = flags(all, on: .ingredients)
        let hasIngredients = recipe.ingredientGroups.contains { !$0.ingredients.isEmpty }
        if isEditing {
            Section {
                ForEach($draft.groups, id: \.id) { $group in
                    if let name = group.name, !name.isEmpty {
                        Text(verbatim: name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .dimmed(true)
                    }
                    ForEach(group.lines, id: \.id) { line in
                        editRow(.ingredient(line.id), recipe, emptyWord: "Ingredient") { Text(verbatim: $0) }
                    }
                    .onDelete { group.lines.remove(atOffsets: $0) }
                    .onMove { group.lines.move(fromOffsets: $0, toOffset: $1) }
                    addRow("Add Ingredient") {
                        let line = ReviewEdit.Line(id: UUID(), text: "")
                        group.lines.append(line)
                        openSheet(.ingredient(line.id), isNew: true)
                    }
                }
                if draft.groups.isEmpty {
                    addRow("Add Ingredient") {
                        let line = ReviewEdit.Line(id: UUID(), text: "")
                        draft.groups.append(ReviewEdit.Group(id: UUID(), name: nil, lines: [line]))
                        openSheet(.ingredient(line.id), isNew: true)
                    }
                }
            } header: {
                heading("Ingredients")
            }
        } else if hasIngredients || !listFlags.isEmpty {
            Section {
                // SC-17: a flag on the whole list is one tinted line atop it; its rows stay plain.
                listFlagLines(listFlags)
                ForEach(recipe.ingredientGroups, id: \.id) { group in
                    if let name = group.name, !name.isEmpty {
                        placedLine(group.nameBox, recipe) {
                            Text(verbatim: name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(group.ingredients, id: \.id) { ingredient in
                        let ingredientFlags = flags(all, on: .ingredient(ingredient.id))
                        tappableLine(ingredient.sourceBox, recipe) {
                            Text(verbatim: ingredient.rawText)
                                .flagged(ingredientFlags)
                        }
                        .flaggedRow(ingredientFlags)
                    }
                }
            } header: {
                heading("Ingredients")
            }
        }
    }

    @ViewBuilder
    private func stepsSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let listFlags = flags(all, on: .steps)
        if isEditing {
            Section {
                ForEach(draft.steps, id: \.id) { step in
                    editRow(.step(step.id), recipe, emptyWord: "Step \(stepNumber(step.id))") { Text(verbatim: $0) }
                }
                .onDelete { draft.steps.remove(atOffsets: $0) }
                .onMove { draft.steps.move(fromOffsets: $0, toOffset: $1) }
                addRow("Add Step") {
                    let step = ReviewEdit.StepLine(id: UUID(), text: "")
                    draft.steps.append(step)
                    openSheet(.step(step.id), isNew: true)
                }
            } header: {
                heading("Steps")
            }
        } else if !recipe.steps.isEmpty || !listFlags.isEmpty {
            Section {
                // SC-17, as for ingredients.
                listFlagLines(listFlags)
                ForEach(Array(recipe.steps.enumerated()), id: \.element.id) { offset, step in
                    let stepFlags = flags(all, on: .step(step.id))
                    tappableLine(step.sourceBox, recipe) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(verbatim: "\(offset + 1).")
                                .monospacedDigit()
                            Text(verbatim: step.text)
                        }
                        .flagged(stepFlags)
                    }
                    .flaggedRow(stepFlags)
                }
            } header: {
                heading("Steps")
            }
        }
    }

    @ViewBuilder
    private func notesSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let notesFlags = flags(all, on: .notes)
        if isEditing {
            Section {
                editRow(.notes, recipe, emptyWord: "Notes") { Text(verbatim: $0) }
            } header: {
                heading("Notes")
            }
        } else if recipe.notes?.isEmpty == false || !notesFlags.isEmpty {
            Section {
                if let notes = recipe.notes, !notes.isEmpty {
                    placedLine(recipe.fieldBoxes[Recipe.FieldBoxKey.notes], recipe) { Text(verbatim: notes) }
                        .flaggedRow(notesFlags)
                }
                listFlagLines(notesFlags)
            } header: {
                heading("Notes")
            }
        }
    }

    @ViewBuilder
    private func equipmentSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let equipmentFlags = flags(all, on: .equipment)
        if !recipe.equipment.isEmpty || !equipmentFlags.isEmpty {
            Section {
                ForEach(Array(recipe.equipment.enumerated()), id: \.offset) { index, item in
                    placedLine(recipe.fieldBoxes[Recipe.FieldBoxKey.equipment(index)], recipe) { Text(verbatim: item) }
                        .dimmed(isEditing)
                        .flaggedRow(equipmentFlags)
                }
                listFlagLines(equipmentFlags)
            } header: {
                heading("Equipment")
            }
        }
    }

    @ViewBuilder
    private func nutritionSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let nutritionFlags = flags(all, on: .printedNutrition)
        if recipe.printedNutrition?.isEmpty == false || !nutritionFlags.isEmpty {
            Section {
                if let nutrition = recipe.printedNutrition, !nutrition.isEmpty {
                    placedLine(recipe.fieldBoxes[Recipe.FieldBoxKey.nutrition], recipe) { Text(verbatim: nutrition) }
                        .dimmed(isEditing)
                        .flaggedRow(nutritionFlags)
                }
                listFlagLines(nutritionFlags)
            } header: {
                heading("Nutrition")
            }
        }
    }

    @ViewBuilder
    private func sourceSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let sourceFlags = flags(all, on: .attribution)
        let author = recipe.attribution?.author.flatMap(Self.nonEmpty)
        let publisher = recipe.attribution?.publisher.flatMap(Self.nonEmpty)
        let address = recipe.attribution?.sourceURL.flatMap(Self.nonEmpty)
        // Each line's place is `source.‹n›`, n its place among the lines shown (RV-34).
        let authorIndex = 0
        let publisherIndex = author == nil ? 0 : 1
        if author != nil || publisher != nil || address != nil || !sourceFlags.isEmpty {
            Section {
                if let author {
                    placedLine(recipe.fieldBoxes[Recipe.FieldBoxKey.source(authorIndex)], recipe) { Text(verbatim: author) }
                        .dimmed(isEditing)
                        .flaggedRow(sourceFlags)
                }
                if let publisher {
                    placedLine(recipe.fieldBoxes[Recipe.FieldBoxKey.source(publisherIndex)], recipe) { Text(verbatim: publisher) }
                        .dimmed(isEditing)
                        .flaggedRow(sourceFlags)
                }
                if let address {
                    Group {
                        if let url = Self.webURL(address) {
                            Link(destination: url) { Text(verbatim: address) }
                        } else {
                            Text(verbatim: address)
                        }
                    }
                    .dimmed(isEditing)
                    .flaggedRow(sourceFlags)
                }
                listFlagLines(sourceFlags)
            } header: {
                heading("Source")
            }
        }
    }

    /// An S-51 heading, as written.
    private func heading(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .textCase(nil)
    }

    /// The S-52 lines of a field's flags, as one tinted row (atop a list, SC-17; at the end of the
    /// other fields, as M3-3).
    @ViewBuilder
    private func listFlagLines(_ flags: [ReviewFlag]) -> some View {
        if !flags.isEmpty {
            FlagLines(flags: flags)
                .flaggedRow(flags)
        }
    }

    /// A + at the end of a list in Edit, with no visible text (`15` M3-3 part 4.5).
    private func addRow(_ label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.green)
        }
        .accessibilityLabel(Text(label))
    }

    /// A row in Edit (SC-19): the edit's text in full, wrapping; empty, its heading's word in
    /// secondary color. A tap shows its place on the page and opens the edit sheet.
    private func editRow<Content: View>(_ field: ReviewEdit.Field, _ recipe: Recipe, emptyWord: LocalizedStringKey,
                                        @ViewBuilder text: (String) -> Content) -> some View {
        let value = draft.text(for: field)
        return Button {
            show(fieldBox(field, recipe), recipe)
            openSheet(field, isNew: false)
        } label: {
            Group {
                if value.isEmpty {
                    Text(emptyWord)
                        .foregroundStyle(.secondary)
                } else {
                    text(value)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openSheet(_ field: ReviewEdit.Field, isNew: Bool) {
        editingFieldSaved = false
        let editing = EditingField(field: field, isNew: isNew)
        openedField = editing
        editingField = editing
    }

    /// The sheet closed: by Save, its text is in the edit already; otherwise it was a Cancel, and a
    /// line or step the + just added comes out again.
    private func editSheetClosed() {
        defer { editingFieldSaved = false }
        guard !editingFieldSaved, let closed = openedField, closed.isNew else { return }
        draft = draft.removing(closed.field)
    }

    /// The field's place on the page: the title's, Serves' or Notes' (RV-34), an ingredient's or a
    /// step's; none for a new row.
    private func fieldBox(_ field: ReviewEdit.Field, _ recipe: Recipe) -> SourceBox? {
        switch field {
        case .title: recipe.titleBox
        case .yield: recipe.fieldBoxes[Recipe.FieldBoxKey.yield]
        case .notes: recipe.fieldBoxes[Recipe.FieldBoxKey.notes]
        case .ingredient(let id): recipe.ingredientGroups.lazy.flatMap(\.ingredients).first { $0.id == id }?.sourceBox
        case .step(let id): recipe.steps.first { $0.id == id }?.sourceBox
        }
    }

    /// The step's place in the edit, from 1.
    private func stepNumber(_ id: UUID) -> Int {
        (draft.steps.firstIndex { $0.id == id } ?? draft.steps.count) + 1
    }

    /// The sheet's title (S-66, S-51, S-67, S-68).
    private func sheetTitle(_ field: ReviewEdit.Field) -> LocalizedStringKey {
        switch field {
        case .title: "Title"
        case .yield: "Serves"
        case .notes: "Notes"
        case .ingredient: "Ingredient"
        case .step(let id): "Step \(stepNumber(id))"
        }
    }

    /// One of the other lines (RV-34): outside Edit, tapped to see its place on the page as any
    /// line is; in Edit, as read.
    @ViewBuilder
    private func placedLine<Content: View>(_ box: SourceBox?, _ recipe: Recipe,
                                           @ViewBuilder label: () -> Content) -> some View {
        if isEditing {
            label()
        } else {
            tappableLine(box, recipe, label: label)
        }
    }

    /// A line she can tap to see it on the page (RV-11): the whole row; VoiceOver hears a button,
    /// "Show on page".
    private func tappableLine<Content: View>(_ box: SourceBox?, _ recipe: Recipe,
                                            @ViewBuilder label: () -> Content) -> some View {
        Button { show(box, recipe) } label: {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Show on page")
    }

    // MARK: Actions

    /// A tapped line: its place on the page, or its first page whole when it has none (RV-11).
    /// With the strip not shown (iPhone, SC-14), the viewer opens on its page, zoomed and outlined.
    /// Her first tap ends the hint (SC-16).
    private func show(_ box: SourceBox?, _ recipe: Recipe) {
        reviewHintSeen = true
        // RV-11's trace (M3-3e): the tapped box's page and the page photo shown for it, by page
        // number and file name only, no recipe text.
        let shownPageID = box?.pageID ?? recipe.sourcePageIDs.first
        let shown = shownPageID.flatMap(photo(forPage:))
        let boxPage = box.flatMap { box in recipe.sourcePageIDs.firstIndex(of: box.pageID).map { $0 + 1 } }
        let shownPage = shown?.sourcePageID.flatMap { recipe.sourcePageIDs.firstIndex(of: $0) }.map { $0 + 1 }
        log.info(self, "tap: box on page \(boxPage.map(String.init) ?? "none"), showing page \(shownPage.map(String.init) ?? "none") (\(shown?.fileName ?? "no photo"))")
        if horizontalSizeClass == .compact && !showsStrip(recipe) {
            viewedPage = ViewedPage(startPageID: box?.pageID ?? recipe.sourcePageIDs.first, box: box)
            return
        }
        withAnimation(.easeInOut) {
            if let box {
                pageSelection = .line(box)
            } else if let firstPage = recipe.sourcePageIDs.first {
                pageSelection = .wholePage(firstPage)
            }
        }
    }

    /// Edit began: the fields and the page order as they are now. A draft kept after a failed save
    /// stays.
    private func beginEditing() {
        guard editStart == nil, let recipe = recipeModels.first?.toDomain() else { return }
        draft = ReviewEdit.from(recipe)
        editStart = draft
        draftPageIDs = recipe.sourcePageIDs
        savedPageIDs = recipe.sourcePageIDs
        removedPageIDs = []
    }

    /// Done (`15` M3-4 part 3.2), in order: her field edits, if any; each removed page, then the
    /// new order if it differs; then, after a page change, RV-7. Each step done is remembered, so a
    /// failed step (S-14, staying in Edit) is the next Done's first.
    private func finishEditing() {
        guard let editStart else { return }
        do {
            guard let recipeEditor else { throw RecipeEditorError.recipeNotFound(recipeID) }
            if draft != editStart {
                try recipeEditor.saveEdits(draft, to: recipeID, now: Date())
                self.editStart = draft
            }
            while let pageID = removedPageIDs.first {
                try recipeEditor.removePage(pageID, from: recipeID, now: Date())
                removedPageIDs.removeFirst()
                savedPageIDs.removeAll { $0 == pageID }
                needsReadAgain = true
            }
            if draftPageIDs != savedPageIDs {
                try recipeEditor.reorderPages(draftPageIDs, of: recipeID, now: Date())
                savedPageIDs = draftPageIDs
                needsReadAgain = true
            }
            if needsReadAgain {
                try readAgainOrAsk()
            }
            self.editStart = nil
        } catch {
            log.error(self, "recipe \(recipeID): changes not saved: \(error)")
            isShowingSaveFailed = true
            editMode = .active
        }
    }

    /// RV-7, once a read recipe's pages changed: an edited recipe asks first (S-57); any other is
    /// read again now. A recipe not read yet is left to the queue.
    private func readAgainOrAsk() throws {
        let recipe = savedRecipe()
        guard recipe?.extraction != nil else {
            needsReadAgain = false
            return
        }
        if recipe?.reviewState == .edited {
            isAskingReadAgain = true
        } else {
            try readAgain()
        }
    }

    private func readAgain() throws {
        guard let captureRecorder else { throw RecipeEditorError.recipeNotFound(recipeID) }
        try captureRecorder.readAgain(recipeID: recipeID, now: Date())
        needsReadAgain = false
    }

    /// Read Again in ⋯ (RV-33, SC-23): always asks first, with S-73 when she has edited the
    /// recipe, else S-78. A failed read again shows S-14.
    private func readAgainFromMenu(_ recipe: Recipe) {
        if recipe.reviewState == .edited {
            isAskingReadAgainFromMenu = true
        } else {
            isAskingReadAgainNotEdited = true
        }
    }

    /// Read Again at RV-7's or RV-33's question.
    private func readAgainAfterAsking() {
        do {
            try readAgain()
        } catch {
            log.error(self, "recipe \(recipeID): not read again: \(error)")
            isShowingSaveFailed = true
        }
    }

    /// The camera Add Page opened has closed: after pages were added, RV-7 (part 3.3).
    private func pagesAddedCameraClosed() {
        guard pagesWereAdded else { return }
        pagesWereAdded = false
        needsReadAgain = true
        do {
            try readAgainOrAsk()
        } catch {
            log.error(self, "recipe \(recipeID): not read again: \(error)")
            isShowingSaveFailed = true
        }
    }

    /// The recipe as last saved, read from the store, not the view's query.
    private func savedRecipe() -> Recipe? {
        var descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == recipeID })
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first?.toDomain()
    }

    /// Remove at the alert: the rows leave the draft order, to be removed at Done.
    private func removePendingPages() {
        guard let offsets = pendingPageRemoval else { return }
        pendingPageRemoval = nil
        removedPageIDs.append(contentsOf: offsets.map { draftPageIDs[$0] })
        draftPageIDs.remove(atOffsets: offsets)
    }

    private func markReviewed() {
        do {
            try recipeEditor?.markReviewed(recipeID, now: Date())
        } catch {
            log.error(self, "recipe \(recipeID): not marked reviewed: \(error)")
        }
    }

    private func dismissPageTwoWarning() {
        do {
            try recipeEditor?.dismissPageTwoWarning(recipeID, now: Date())
        } catch {
            log.error(self, "recipe \(recipeID): page-2 warning not dismissed: \(error)")
        }
    }

    private func retry() {
        do {
            try captureRecorder?.retryFailed(recipeID: recipeID)
        } catch {
            log.error(self, "recipe \(recipeID): Try Again failed: \(error)")
        }
    }

    // MARK: Helpers

    /// Whether any of the recipe's pages failed (RV-24).
    private func hasFailedPage(_ recipe: Recipe) -> Bool {
        let pageIDs = Set(recipe.sourcePageIDs)
        return pageModels.contains { pageIDs.contains($0.id) && $0.structuringStateRaw == StructuringState.failed.rawValue }
    }

    /// The page's photo: its cropped photo (MT-7) if it has one, else any photo of it.
    private func photo(forPage pageID: UUID) -> Photo? {
        let photos = photoModels.filter { $0.sourcePageID == pageID }
        let model = photos.first { $0.kindRaw == PhotoKind.pageCropped.rawValue } ?? photos.first
        return model?.toDomain()
    }

    private nonisolated static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// A printed web address as a link: as printed when it has a scheme, else with `https://`.
    private nonisolated static func webURL(_ address: String) -> URL? {
        if let url = URL(string: address), url.scheme != nil {
            return url
        }
        return URL(string: "https://" + address)
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

// MARK: - Flags

/// A flagged field's S-52 lines under it, caption, secondary (`15` M3-3 part 4.3).
private struct FlagLines: View {
    let flags: [ReviewFlag]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(flags.enumerated()), id: \.offset) { _, flag in
                Text(verbatim: ReviewFlag.line(for: flag.kind))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension View {
    /// The field with its own flags' lines under it.
    func flagged(_ flags: [ReviewFlag]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            self
            if !flags.isEmpty {
                FlagLines(flags: flags)
            }
        }
    }

    /// A flagged row's pale amber, rounded background (`13` §4.4); none when not flagged. A
    /// flagged list tints each of its rows; its lines are shown once, at its end.
    @ViewBuilder
    func flaggedRow(_ flags: [ReviewFlag]) -> some View {
        if flags.isEmpty {
            self
        } else {
            listRowBackground(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.15)))
        }
    }

    /// The fields Edit doesn't change, shown as read, dimmed.
    func dimmed(_ isDimmed: Bool) -> some View {
        opacity(isDimmed ? 0.5 : 1)
    }
}

// MARK: - A page's row in Edit

/// A page's thumbnail at `RecipeRow`'s size, from memory or made off the main actor, as
/// `RecipeRow` does (`15` M3-4); a placeholder until its file is here (SC-6).
private struct PageThumbnail: View {
    let photo: Photo?
    let photoFiles: PhotoFiles?

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: [photo?.fileName, photoFiles?.root.path]) { await load() }
    }

    /// From memory, or made off the main actor once the file is here, checked again every 2
    /// seconds until it is. Kept in memory only (SLT-054).
    private func load() async {
        guard let photoFiles, let fileName = photo?.fileName else {
            thumbnail = nil
            return
        }
        let url = photoFiles.url(for: fileName)
        if let cached = await ImageCache.shared.memoryImage(for: url) {
            thumbnail = cached
            return
        }
        while !Task.isCancelled {
            let image = await Task.detached {
                photoFiles.thumbnail(of: fileName).map { UIImage(cgImage: $0) }
            }.value
            if let image {
                await ImageCache.shared.store(image, for: url, toDisk: false)
                thumbnail = image
                return
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }
}

// MARK: - The page

/// The selected line's outline on a page drawn at `size`: a rounded rectangle, 2 pt, the accent.
/// The full-screen viewer draws it too (`15` M3-3a).
struct LineOutline: View {
    let box: SourceBox
    let size: CGSize
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(accent, lineWidth: 2)
            .frame(width: box.width * size.width, height: box.height * size.height)
            .position(x: (box.x + box.width / 2) * size.width, y: (box.y + box.height / 2) * size.height)
            .allowsHitTesting(false)
    }
}

// MARK: - The edit sheet

/// One row's edit sheet (SC-19, `15` M3-3b): medium, able to go large, with its drag indicator;
/// iPad and Mac show the system's form sheet. Its bar names the field, with ✕ (Cancel) and ✓
/// (Save, disabled until the text changes). The row's part of the page (as the strip draws it,
/// about 120 pt tall, none without a place), then its text in full, focused. Once she has typed, a
/// swipe down doesn't close it, so her words are never lost.
private struct RowEditSheet: View {
    let title: LocalizedStringKey
    let original: String
    let photo: Photo?
    let box: SourceBox?
    let photoFiles: PhotoFiles?
    let accent: Color
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String
    @State private var detent: PresentationDetent = .medium
    @FocusState private var isFocused: Bool

    /// The page crop's height, in points.
    private static let cropHeight: CGFloat = 120

    init(title: LocalizedStringKey, original: String, photo: Photo?, box: SourceBox?, photoFiles: PhotoFiles?,
         accent: Color, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.original = original
        self.photo = photo
        self.box = box
        self.photoFiles = photoFiles
        self.accent = accent
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: original)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let box {
                        PageStrip(photo: photo, selectedBox: box, showsWholePage: false, isExpanded: false,
                                  photoFiles: photoFiles, accent: accent, isInteractive: false) {}
                            .id(photo?.sourcePageID)
                            .frame(height: Self.cropHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    TextField("", text: $text, axis: .vertical)
                        .lineLimit(3...)
                        .focused($isFocused)
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    IconButton("xmark", context: .toolbar) { onCancel() }
                        .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    IconButton("checkmark", context: .toolbar) { onSave(text) }
                        .tint(accent)
                        .disabled(text == original)
                        .accessibilityLabel("Save")
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(text != original)
        .onAppear { isFocused = true }
    }
}

/// iPhone's page strip (`13` §4.4, `15` M3-3 part 4.1): the area around the selected line, zoomed
/// to fill the width with a margin and outlined; at first the top of the page; a page selected
/// whole, fitted. A drag down or a tap on the grabber opens the whole page at full height; a drag
/// up or a second tap closes it.
private struct PageStrip: View {
    let photo: Photo?
    let selectedBox: SourceBox?
    let showsWholePage: Bool
    let isExpanded: Bool
    let photoFiles: PhotoFiles?
    let accent: Color
    /// False in the edit sheet: no grabber, no drag (`15` M3-3b).
    var isInteractive = true
    let onToggle: () -> Void

    @State private var image: UIImage?

    /// The space each side of a zoomed line, in points.
    private static let margin: CGFloat = 16
    /// How far a drag must go to open or close the strip, in points.
    private static let dragDistance: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            page(in: geometry.size)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(alignment: .bottom) {
            if isInteractive {
                Capsule()
                    .fill(.secondary)
                    .frame(width: 36, height: 5)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 40)
                    .contentShape(Rectangle())
                    .onTapGesture { onToggle() }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard isInteractive else { return }
                    if value.translation.height > Self.dragDistance && !isExpanded {
                        onToggle()
                    } else if value.translation.height < -Self.dragDistance && isExpanded {
                        onToggle()
                    }
                }
        )
        .task(id: [photo?.fileName, photoFiles?.root.path]) { await load() }
    }

    /// Width over height: the image's, else the record's, else 3:4.
    private var aspectRatio: CGFloat {
        if let image, image.size.height > 0 {
            return image.size.width / image.size.height
        }
        if let width = photo?.pixelWidth, let height = photo?.pixelHeight, width > 0, height > 0 {
            return CGFloat(width) / CGFloat(height)
        }
        return 3.0 / 4.0
    }

    @ViewBuilder
    private func page(in size: CGSize) -> some View {
        let frame = pageFrame(in: size)
        let box = selectedBox.flatMap { $0.pageID == photo?.sourcePageID ? $0 : nil }
        ZStack(alignment: .topLeading) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: frame.width, height: frame.height)
            } else {
                ZStack {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .frame(width: frame.width, height: frame.height)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Downloading from iCloud…")
            }
            if let box {
                LineOutline(box: box, size: frame.size, accent: accent)
                    .frame(width: frame.width, height: frame.height)
            }
        }
        .offset(x: frame.minX, y: frame.minY)
        .animation(.easeInOut, value: frame)
    }

    /// Where the page is drawn in the strip. Open, or a page shown whole: fitted and centered. A
    /// selected line: zoomed so it fills the width less the margins, never smaller than the width
    /// nor past `LineZoom.maximum` (RV-33), centered on the line within the page's edges. Otherwise: the page's width, from its top.
    private func pageFrame(in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        let ratio = aspectRatio
        if isExpanded || showsWholePage {
            let height = min(size.height, size.width / ratio)
            let width = height * ratio
            return CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height)
        }
        guard let box = selectedBox, box.pageID == photo?.sourcePageID, box.width > 0 else {
            return CGRect(x: 0, y: 0, width: size.width, height: size.width / ratio)
        }
        // At most `LineZoom.maximum`, the line centered with the page around it (RV-33).
        let zoom = CGFloat(LineZoom.scale(boxWidth: box.width, viewWidth: size.width, margin: Self.margin))
        let width = size.width * zoom
        let height = width / ratio
        let midX = (box.x + box.width / 2) * width
        let midY = (box.y + box.height / 2) * height
        let offsetX = min(max(midX - size.width / 2, 0), max(width - size.width, 0))
        let offsetY = min(max(midY - size.height / 2, 0), max(height - size.height, 0))
        return CGRect(x: -offsetX, y: -offsetY, width: width, height: height)
    }

    private func load() async {
        image = nil
        guard let photoFiles, let fileName = photo?.fileName else { return }
        // At display size, shared and retried smaller if a decode fails (M3-3g).
        let loaded = await PagePhotoView.loadImageRetrying(fileName, from: photoFiles)
        // A load the strip has moved on from (its decode is detached, so not cancelled with it)
        // never overwrites the new page's image (M3-3e).
        guard !Task.isCancelled else { return }
        if let loaded {
            image = loaded
        }
    }
}
