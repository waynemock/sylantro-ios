# Sylantro — Architecture

**A Syzygy Softwerks engineering contract · how the app is put together, and the rules every task
follows**
Version 0.14 · 22 November 2026 · **Accepted** (Pops, 22 Nov 2026), including the App-layer names in §2
and §8 (`RecipeEditor`, `CaptureRecorder`, `ExtractionQueue`, `MirrorWriter`) and §5.1, §5.2, §5.4 and
§5.5 as written; §3's Domain names by SLT-091. **Still open:** the recovery screen's copy
(§5.3, `13` §6), and the photo details §5.7 points to (`05`). No app code is written from those until Pops rules.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
*Every task that writes app code reads this file in full first.*

Built from Score It \*'s `13_ARCHITECTURE.md` (the layers, one writer, the root, CloudKit reading
and writing) and SyJong's `06_ARCHITECTURE.md` (its form), with SydeTwo's `SydeTwoApp.swift` as
the reference for two stores and background work (SLT-080). What Sylantro adds is the camera, the
on-device reader and structurer, and the mirror.

---

## 0. Instructions for the implementing agent

This document is a **contract**. Structure that is re-derived each session drifts; this file is
where it is fixed once.

**Before writing app code:** read `00`, `00A`, `00B`, this file, and the task's own documents.
Inspect what is already in the source tree and extend it.

**Hard rules.** Each is a stop condition (`00A` §4) unless a task names the exception.

- Do **not** invent top-level types, folders or layers. Everything is named in §2 to §9. If
  something seems missing, say so.
- **Nothing under `Domain/` imports SwiftUI, SwiftData, UIKit, Vision, VisionKit or
  FoundationModels** (§2, SLT-081).
- **Every write to the synced store goes through `RecipeEditor` or `CaptureRecorder`** (§5.2). No
  view or coordinator writes a `@Model` property directly.
- **The store is never deleted, wiped or replaced by a fresh one on a failure** (§5.3, SLT-031).
- **Nothing in the reading or structuring path touches the network** (SLT-040).

---

## 1. Stack (locked where a ruling is cited)

| Concern | Decision |
|---|---|
| App shell | SwiftUI; `NavigationSplitView` on iPad and Mac, one column on iPhone, as Score It \* does *(rec.)* |
| Devices | iPhone, iPad; Mac as "Designed for iPad" (SLT-012) |
| Floor | iOS 26.5; Xcode 27 (SLT-013) |
| Store | SwiftData: a synced store on CloudKit's private database `iCloud.com.syzygysoftwerksllc.Sylantro`, and a device-only store (SLT-050, SLT-051) |
| Capture | VisionKit's `VNDocumentCameraViewController`, hosted in SwiftUI *(rec.)* |
| Reading | Vision text recognition *(rec.: the request API is chosen in the spike)* |
| Structuring | FoundationModels, guided generation into `@Generable` mirrors of the Domain types (SLT-040) |
| Background | A main-actor `ExtractionQueue` while the app runs, and a `BGProcessingTask` for work left over, as SydeTwo's `DiscogsEnrichmentCoordinator` does *(rec.)* |
| Mirror | `MirrorWriter`, file-coordinated writes into the iCloud ubiquity container's `Documents`, or the app's own `Documents` with iCloud off (SLT-032, SLT-050) |
| Look | SyLibUI (`SyTheme`, `Chip`, `CapsuleButton`, `IconButton`, `EmptyStateView`, `FlowLayout`, `SettingRow`, `AboutView`) |
| iCloud status | SyLibCloud (`CloudAccountStatus`, `ICloudStatusButton`, `ICloudInfoSheet`) |
| Thumbnails | SyLibCache's `ImageCache`, when thumbnails are built (SLT-084) |
| Logging | SyLibCore's `AppLogger` |
| Never linked | `SyLibScoring`, `SyLibScoringData`, `SyLibScoringUI`, `SyLibGameNight`, `SyLibGameNightMatch`, `SyLibDice`, `SyLibDiceFeel`, `SyLibCommentary`, `SyLibYatzy`, `SyLibYatzyUI`, `SyLibInput`, `SyLibSprite` *(rec.)* |
| Concurrency | `MainActor` default isolation, approachable concurrency, member import visibility (SLT-012) |
| Tests | Swift Testing, pinned destination at the floor (SLT-004, SLT-016) |

---

## 2. The layers (SLT-081)

```
┌────────────────────────────────────────────────────────────┐
│  SCREENS     SwiftUI views. Read with @Query; call App.     │
├────────────────────────────────────────────────────────────┤
│  APP         RecipeEditor, CaptureRecorder, ExtractionQueue, │
│              MirrorWriter, the reader and the structurer,   │
│              store recovery                                 │
├────────────────────────────────────────────────────────────┤
│  DOMAIN      Plain Swift: Recipe and its value types, the   │
│              ingredient-line parser, units, the schema      │
│              check, the Markdown and JSON renderings        │
├────────────────────────────────────────────────────────────┤
│  SyLib       logging, UI pieces, iCloud status              │
└────────────────────────────────────────────────────────────┘
```

**Dependencies point down only.** Screens know App and Domain; App knows Domain; Domain knows
Foundation and nothing else.

**Why:** every rule that decides what a recipe says (parsing a line, normalizing a unit, accepting
or refusing a structuring result, rendering `recipe.md`) lives in Domain, where it is tested with
plain values and no camera, model, store or view. That is Milestone 1's half that needs no device
(SLT-090).

---

## 3. Domain *(names accepted, SLT-091)*

- **`Recipe` and its values**: `Yield`, `Times`, `IngredientGroup`, `Ingredient`, `Quantity`,
  `UnitRef`, `Step`, `Extraction`, `ReviewState`, as `01` §4 lists, `Codable`, `Sendable`,
  `Equatable`. Ids are `UUID`s.
- **`IngredientLineParser`**: from a line and the structurer's split, the normalized quantity
  (fractions, unicode fractions, mixed numbers, ranges, "about") and the canonical unit. Pure; the
  table of unit spellings is one constant (`00A` §10).
- **`RecipeValidator`**: the schema check (SLT-042). A structuring result is accepted or refused
  with reasons; refused results are never saved.
- **`RecipeRendering`**: `recipe.json` (sorted keys, carrying `schemaVersion`) and `recipe.md`.
- **Fixtures** are made-up pages and recorded structuring output, never real binder pages
  (`00B` §2).

---

## 4. Capture, reading and structuring *(rec.)*

- **Capture** saves each page through `CaptureRecorder` the moment the camera returns it: the
  original and the cropped image, a `SourcePage` in the session's `ScanSession`, then a queue entry
  and a mirror write. Nothing else runs on the capture path (SLT-041).
- **`ExtractionQueue`** takes waiting pages one at a time: read (Vision), then structure
  (FoundationModels, in parts for a long recipe, retried on a schema refusal), then hand the result
  to `RecipeEditor` as a draft with `reviewState = needsReview`.
- **Availability.** On a device where `SystemLanguageModel` is unavailable, pages are read but not
  structured, and stay marked as waiting on the synced `SourcePage` (SLT-044). The queue on a
  capable device rebuilds itself from those marks at launch and when sync delivers pages.
- **Instrument before diagnosing** (`00A` §12): the queue logs each page's state changes with
  `AppLogger(category: "Extraction")`, without recipe text above debug level.

---

## 5. Data

### 5.1 The containers (SLT-050, SLT-051) *(rec.)*

One `ModelContainer` with two configurations, as SydeTwo builds its own:

- **Synced**: `SylantroApp.syncedModels` (`ScanSessionModel`, `SourcePageModel`, `RecipeModel`) on
  `.private("iCloud.com.syzygysoftwerksllc.Sylantro")`, under `SylantroSchemaV1` (`VersionedSchema`).
- **Device-only**: `SylantroApp.localModels` (`ExtractionJobModel`, `DeviceStateModel`), named
  `"SylantroLocal"`, with `cloudKitDatabase: .none`.
- The schema push is `CloudKitSchema.initializeDevelopment(models: syncedModels, configuration:
  syncedConfig, containerIdentifier:)`, synced models only, inside `#if DEBUG` behind
  `AppConfig.DebugCloudKit.runSchemaExercise` (SLT-015).
- Each model is a `@Model` twin of a Domain value with `hydrate(from:)` and `toDomain()`; nested
  data is sorted-key JSON `Data` (SLT-061). **No image data is stored in either store**
  (SLT-053): a photo's record holds only its metadata and a reference to its file, and the image
  is a file, kept where `05` IS-4 rules (§5.7).
- Previews and tests use an in-memory container with `cloudKitDatabase: .none`, never the live
  store.

### 5.2 The writers (SLT-082) *(rec.)*

- **`CaptureRecorder`** writes sessions and pages, and only ever adds: a page's photos and OCR are
  never edited.
- **`RecipeEditor`** writes recipes: drafts from the queue, her edits in review, joins and splits,
  and variants. Each edit writes the smallest row it can (Score It \*'s `13` §3.4).
- Both call `MirrorWriter` after a successful save. A failed mirror write is logged and retried;
  it never blocks or undoes the save.
- **Reading**: screens read live with `@Query`, and show one row per id, since CloudKit enforces no
  uniqueness (Score It \*'s `13` §3.3).

### 5.3 When the store won't open (SLT-031) *(rec.)*

`SylantroApp` builds the container in a `do`/`catch`. On failure it does **not** delete anything,
does not call `fatalError`, and does not open a fresh store in the same place. It shows a recovery
screen with: what failed, in Pops's words; that the mirror in Files is intact; and, only after she
confirms, **Try Again** (retry opening the store) or **Start Fresh** (move the old store,
untouched, to a dated folder and open a new empty one, which iCloud refills), ruled in `13` §5
(SC-7). Restoring from the mirror is M3's (`12` §4). The screen's copy is `13` §6.

### 5.4 The mirror's layout *(rec.)*

```
Sylantro/
  Recipes/
    <title-slug>-<first 8 of id>/
      recipe.json
      recipe.md
      pages/
        page-1.heic
        page-2.heic
      photos/            (dish photos, if P-1 is accepted)
        dish-1.heic
  Pages without a recipe/
    <session date>/page-<n>.heic
```

Written with `NSFileCoordinator` into the ubiquity container's `Documents` folder, which shows in
iCloud Drive as Sylantro once Pops adds the iCloud Documents service and `NSUbiquitousContainers`
(`00B` §7). With iCloud off, the same layout goes in the app's own `Documents`, shown under On My
iPhone with `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace`. A rename of a recipe
renames its folder.

### 5.5 Settings

On each device, in `@AppStorage`, as Score It \* keeps them *(rec.)*.

### 5.6 Sharing a recipe (SLT-100 to SLT-103)

`RecipeTransfer` in `Domain/` makes and reads the file; a `ShareLink` sends it; the root opens
it, `RecipeValidator` checks it, and the writers save it, applying SLT-103's duplicate rule. The
container keeps only its private database. The design is `04_SHARING_DESIGN.md`.

### 5.7 Photos *(proposed)*

`PhotoModel` in `syncedModels` holds a photo's metadata and file reference only, never its bytes
(SLT-053); the image files live where `05` IS-4 rules. `PhotoEncoding` in `Domain/`, thumbnails in
SyLibCache's `ImageCache` (on each device, never stored), HEIC copies from `MirrorWriter` (`05` P-5). The design is `05_IMAGE_STORAGE_DESIGN.md`.

---

## 6. The root *(rec.)*

`SylantroApp` owns, as `@State`: `CloudAccountStatus(containerIdentifier:)`, `AppUpdateState`,
`CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`. It sets `AppLogger.appName = "Sylantro"`,
registers the `BGProcessingTask` in `init`, and caps Dynamic Type at AX2 with
`sceneDynamicTypeCeiling` (`00A` §5).

---

## 7. Screens *(outline only; designed in their own document)*

The library (search, tags), a recipe, the scan button and camera, the review inbox, Settings with
iCloud status, About. Their layout and copy are Pops's and are specified before any is built.

---

## 8. File map *(rec.)*

```
Sylantro/
  App/            SylantroApp.swift, AppConfig.swift, StoreRecovery
    Settings/     SettingsKey, AppPalette (built, SLT-086)
  Capture/        CaptureRecorder, the camera host
  Extraction/     ExtractionQueue, TextReader, RecipeStructurer
  Store/          the @Model twins, SylantroSchemaV1, RecipeEditor
  Mirror/         MirrorWriter
  Domain/         Recipe values, IngredientLineParser, RecipeValidator, RecipeRendering,
                  RecipeTransfer
  Views/          the screens (the Screens layer)
    Root/         RootView, Sheet, View+TextSizeCap (built, SLT-086)
    Library/      LibraryView, NoRecipeSelectedView (built, empty, SLT-086)
    Settings/     SettingsSheet (built, SLT-086)
SylantroTests/    Domain tests first; fixtures are made up
```

---

## 9. Testing *(rec.)*

- Domain is tested exhaustively with plain values: every fraction and range form, every unit
  spelling, every validator refusal, and a round trip of `recipe.json`.
- The writers are tested against an in-memory container.
- The camera, Vision and FoundationModels are checked by Pops on a device; their tasks carry
  validation rows for him (`00B` §5).

---

## 10. Open in this document

- The recovery screen's copy (`13` §6) and photos (§5.7, `05`); the rest is accepted.
- The recovery screen's choices and copy (§5.3).
- Restoring from the mirror (§5.3).
- Sharing's and photos' open details: `04` §8, `05` §9.
- The Vision request to use, and how a long recipe is split for the model, from the spike.

---

## 11. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.14 | §5.4, §5.7: the mirror's photos are HEIC copies | `05` P-5, Pops, 22 Nov 2026 (decision card, "HEIC copies") |
| 0.13 | §5.3: the recovery screen offers Try Again or Start Fresh (`13` SC-7) | Pops, 22 Nov 2026 (decision card, "Try Again or Start Fresh") |
| 0.12 | §5.1, §5.7: no image data in either store; photos are files the records refer to | SLT-053 (Pops, 22 Nov 2026: "looks good. can you make sure we are storing no image data in the database") |
| 0.11 | §5.1, §5.2, §5.4 and §5.5 accepted as written (settings stay per device); §5.3 and §5.7 still open | Pops, 22 Nov 2026 (decision card, "Accept all four as written") |
| 0.10 | Accepted except §5 (Data), App-layer names included; §5 walked through with Pops before its ruling | Pops, 22 Nov 2026: "walk me thru section 5 Data, everything else looks good and can be. accepted" |
| 0.9 | §3's Domain type names accepted, with `06`'s four additions | SLT-091 (Pops, 21 Nov 2026) |
| 0.8 | §5.6 and §5.7 moved to `04` and `05`; pointers left | Pops, 21 Nov 2026 |
| 0.7 | §5.6: duplicate imports, SLT-103 | Pops, 21 Nov 2026 |
| 0.6 | §5.7: `PhotoModel` and photo storage, proposed; §5.1 no longer says photos always sync as assets; §5.4 gains `photos/` | `01` §5.7 (Pops, 21 Nov 2026: "Make it so") |
| 0.5 | §5.6: sharing one recipe as a file; `RecipeTransfer` in Domain; no CloudKit sharing | SLT-100 to SLT-102 (Pops, 21 Nov 2026) |
| 0.4 | §8: the app shell's folders, built from Score It \* (Task A-2) | SLT-086 (Pops, 21 Nov 2026) |
| 0.3 | §1: the floor is iOS 26.5 | SLT-013 (Pops, 21 Nov 2026) |
| 0.2 | §1: the floor is iOS 26.6 | SLT-013 (Pops, 21 Nov 2026) |
| 0.1 | Draft, from Score It \*'s `13`, SyJong's `06` and SydeTwo's store, for Pops to accept | SLT-080 (Pops, 21 Nov 2026) |
