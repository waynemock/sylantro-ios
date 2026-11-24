import SwiftUI
import SwiftData
import UIKit
import VisionKit
import SyLibCore
import SyLibUI

/// A recipe (`13` §4). Before it is read, M2's screen: its title, "Waiting to be read" (or
/// "Reading…" while the queue has it, or "couldn't read" with Try Again), the page-2 warning, and
/// its pages full width in order. Once read, the review screen (`13` §4.4, SC-9, `15` M3-3): the
/// page beside or above the fields, flags tinted with their lines, tap a line to see it on the
/// page, Edit and Done for the kitchen fields, and Looks Good. Add Page and Delete Recipe in the
/// toolbar.
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

    /// The page open in the full-screen viewer.
    private struct ViewedPage: Identifiable {
        let id: String
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
        .navigationTitle(recipe.title.isEmpty ? "New recipe" : recipe.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // iOS's own Edit and Done (S-50, SC-10), before Add Page, once read.
                if recipe.extraction != nil {
                    EditButton()
                }
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

    // MARK: Before it is read (M2, `13` §4.1)

    private func unreadContent(_ recipe: Recipe) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if extractionQueue?.currentRecipeID == recipe.id {
                    Text("Reading…")
                        .foregroundStyle(.secondary)
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
        if horizontalSizeClass == .compact {
            // iPhone: the page strip across the top, about a third of the height, then the fields.
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    PageStrip(photo: stripPhoto(recipe), selectedBox: selectedBox,
                              showsWholePage: isWholePageSelected,
                              isExpanded: isStripExpanded, photoFiles: photoFiles,
                              accent: syTheme.primaryAccent) {
                        withAnimation(.easeInOut) { isStripExpanded.toggle() }
                    }
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

    private var isWholePageSelected: Bool {
        if case .wholePage = pageSelection { return true }
        return false
    }

    /// The strip's page: the selected line's, the page shown whole, else the first page.
    private func stripPhoto(_ recipe: Recipe) -> Photo? {
        switch pageSelection {
        case .line(let box): photo(forPage: box.pageID)
        case .wholePage(let pageID): photo(forPage: pageID)
        case nil: recipe.sourcePageIDs.first.flatMap(photo(forPage:))
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
                if let fileName = photo.fileName {
                    viewedPage = ViewedPage(id: fileName)
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

    /// Title, the whole-recipe lines, Serves or Makes, and the times.
    @ViewBuilder
    private func headerSection(_ recipe: Recipe, flags all: [ReviewFlag]) -> some View {
        let titleFlags = flags(all, on: .title)
        Section {
            if isEditing {
                TextField("", text: $draft.title)
                    .font(.title.bold())
                    .flagged(titleFlags)
            } else {
                Button { show(nil, recipe) } label: {
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
                TextField("Serves", text: $draft.yieldText)
            } else if let yield = recipe.yield.flatMap(RecipeRendering.yieldLine) {
                Text(verbatim: yield)
            }
            if let times = recipe.times.flatMap(RecipeRendering.timesLine) {
                Text(verbatim: times)
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
                    ForEach($group.lines, id: \.id) { $line in
                        TextField("", text: $line.text)
                    }
                    .onDelete { group.lines.remove(atOffsets: $0) }
                    .onMove { group.lines.move(fromOffsets: $0, toOffset: $1) }
                    addRow("Add Ingredient") { group.lines.append(ReviewEdit.Line(id: UUID(), text: "")) }
                }
                if draft.groups.isEmpty {
                    addRow("Add Ingredient") {
                        draft.groups.append(ReviewEdit.Group(id: UUID(), name: nil,
                                                             lines: [ReviewEdit.Line(id: UUID(), text: "")]))
                    }
                }
            } header: {
                heading("Ingredients")
            }
        } else if hasIngredients || !listFlags.isEmpty {
            Section {
                ForEach(recipe.ingredientGroups, id: \.id) { group in
                    if let name = group.name, !name.isEmpty {
                        Text(verbatim: name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .flaggedRow(listFlags)
                    }
                    ForEach(group.ingredients, id: \.id) { ingredient in
                        let ingredientFlags = flags(all, on: .ingredient(ingredient.id))
                        tappableLine(ingredient.sourceBox, recipe) {
                            Text(verbatim: ingredient.rawText)
                                .flagged(ingredientFlags)
                        }
                        .flaggedRow(ingredientFlags + listFlags)
                    }
                }
                listFlagLines(listFlags)
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
                ForEach($draft.steps, id: \.id) { $step in
                    TextField("", text: $step.text, axis: .vertical)
                }
                .onDelete { draft.steps.remove(atOffsets: $0) }
                .onMove { draft.steps.move(fromOffsets: $0, toOffset: $1) }
                addRow("Add Step") { draft.steps.append(ReviewEdit.StepLine(id: UUID(), text: "")) }
            } header: {
                heading("Steps")
            }
        } else if !recipe.steps.isEmpty || !listFlags.isEmpty {
            Section {
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
                    .flaggedRow(stepFlags + listFlags)
                }
                listFlagLines(listFlags)
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
                TextField("", text: $draft.notes, axis: .vertical)
            } header: {
                heading("Notes")
            }
        } else if recipe.notes?.isEmpty == false || !notesFlags.isEmpty {
            Section {
                if let notes = recipe.notes, !notes.isEmpty {
                    Text(verbatim: notes)
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
                ForEach(Array(recipe.equipment.enumerated()), id: \.offset) { _, item in
                    Text(verbatim: item)
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
                    Text(verbatim: nutrition)
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
        if author != nil || publisher != nil || address != nil || !sourceFlags.isEmpty {
            Section {
                if let author {
                    Text(verbatim: author)
                        .dimmed(isEditing)
                        .flaggedRow(sourceFlags)
                }
                if let publisher {
                    Text(verbatim: publisher)
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

    /// The S-52 lines of a list's flags, as a tinted row at its end.
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
    private func show(_ box: SourceBox?, _ recipe: Recipe) {
        withAnimation(.easeInOut) {
            if let box {
                pageSelection = .line(box)
            } else if let firstPage = recipe.sourcePageIDs.first {
                pageSelection = .wholePage(firstPage)
            }
        }
    }

    /// Edit began: the fields as they are now. A draft kept after a failed save stays.
    private func beginEditing() {
        guard editStart == nil, let recipe = recipeModels.first?.toDomain() else { return }
        draft = ReviewEdit.from(recipe)
        editStart = draft
    }

    /// Done: her changes saved, or nothing when she made none. A failed save says so (S-14) and
    /// stays in Edit.
    private func finishEditing() {
        guard let editStart else { return }
        guard draft != editStart else {
            self.editStart = nil
            return
        }
        do {
            guard let recipeEditor else { throw RecipeEditorError.recipeNotFound(recipeID) }
            try recipeEditor.saveEdits(draft, to: recipeID, now: Date())
            self.editStart = nil
        } catch {
            log.error(self, "recipe \(recipeID): edits not saved: \(error)")
            isShowingSaveFailed = true
            editMode = .active
        }
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

// MARK: - The page

/// The selected line's outline on a page drawn at `size`: a rounded rectangle, 2 pt, the accent.
private struct LineOutline: View {
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
            Capsule()
                .fill(.secondary)
                .frame(width: 36, height: 5)
                .padding(.vertical, 8)
                .padding(.horizontal, 40)
                .contentShape(Rectangle())
                .onTapGesture { onToggle() }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
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
    /// selected line: zoomed so it fills the width less the margins (never smaller than the width),
    /// centered on the line within the page's edges. Otherwise: the page's width, from its top.
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
        let zoom = max(1, (size.width - 2 * Self.margin) / (box.width * size.width))
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
        while !Task.isCancelled {
            if let loaded = await PagePhotoView.loadImage(fileName, from: photoFiles) {
                image = loaded
                return
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
