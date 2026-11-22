# Sylantro — Milestone 2: Capture and Storage

**A Syzygy Softwerks task document · her pages photographed, saved, synced and copied to Files,
before anything is read**
Version 0.18 · 22 November 2026 · **Draft.** §1's task plan is ruled (MT-1); **M2-1 complete** (68
tests, 22 Nov 2026); **M2-2 complete** (76 tests; Pops's CloudKit check done); **M2-3 complete** (84 tests); **M2-4a complete** (SyLib, `14A`); **M2-4 ready** (run 2). M2-4 onward are outlines,
each written in full against what was built before it, when its gates (§1) are cleared.
Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md`, `00B_SYLANTRO_GUARDRAILS.md`,
`02_ARCHITECTURE.md`, `05_IMAGE_STORAGE_DESIGN.md` and `13_SCREENS.md`.

---

## 0. What this is

Milestone 2 ends with her tapping **Let's cook.**, photographing a recipe's pages, tapping Save,
and seeing it in the library on iPhone, iPad and Mac, synced, with the photos and a plain copy in
Files, and the recovery screen if the store won't open (`12` §2). Nothing is read or structured
(that is M3).

**What it is built on (all ruled, 22 Nov 2026):**

- `02` accepted (App-layer names, §5.1, §5.2, §5.4, §5.5; the recovery screen's choices, §5.3).
- **No image data in the database** (SLT-053): photos are HEIC files in an app-only folder in her
  iCloud container (`05` IS-4); the store holds only their metadata and file names.
- One `PhotoModel` for every photo (`05` P-2), with a `dish` kind ready though dish screens come
  after M3 (P-1); page originals as full-resolution HEIC plus a cropped copy (IS-2); `05` §5's
  sizes as starting points (P-3); thumbnails only on each device (P-4); HEIC copies in the mirror
  (P-5).
- A web original is a kind of `SourcePage` (`08` NI-5).
- `13`'s screen choices SC-1 to SC-7: a capture is a recipe at once ("New recipe"); Let's cook. is
  a capsule at the bottom of the library; Delete Recipe keeps its pages; the recovery screen offers
  Try Again or Start Fresh.

---

## 1. The task plan (MT-1, ruled)

**Ruled:** Pops, 22 Nov 2026 (decision card, "Accept the plan").

One task at a time, in order. Each is checked before the next is written.

| Task | What it builds | Gates before it is written in full |
|---|---|---|
| **M2-1** | **Domain:** the capture value types (`ScanSession`, `SourcePage`, `Photo` and their parts), `PhotoEncoding`'s constants, and `Recipe`'s page-2 flag (MT-2), with their JSON and tests. No store, no view | — (MT-1, MT-2 ruled) |
| M2-2 | **The store:** the `@Model` twins (`ScanSessionModel`, `SourcePageModel`, `RecipeModel`, `PhotoModel`) under `SylantroSchemaV1`, the synced container on CloudKit, the schema push behind `AppConfig.DebugCloudKit.runSchemaExercise`, `Item.swift` and the template store retired, and **the recovery screen** replacing `fatalError` (`02` §5.3) | M2-1; `13` §6's recovery copy (S-30 to S-38) |
| M2-3 | **Photo files and `CaptureRecorder`:** HEIC files written to and read from the app-only folder (or the app's own folder with iCloud off), downloads asked for when a record arrives first; `CaptureRecorder` saving a capture as a session, pages, photos and one recipe | M2-2; **Pops adds the iCloud Documents capability and `NSUbiquitousContainers`** (`00B` §7); MT-3 (the photo-file type's name) |
| M2-4 | **The screens:** the library with rows and the Let's cook. capsule, the document camera, Save with the page-2 check (SLT-046), the saved line, Add Page, a recipe's pages, Delete Recipe, placeholders while photos download | M2-3; `13` §6's copy (S-0 to S-27) |
| M2-5 | **`MirrorWriter`:** the Files copy (`02` §5.4): `recipe.json`, `recipe.md`, HEIC page photos, pages without a recipe; after every save, never blocking it | M2-4 |
| M2-6 | **Pops's device check:** a 30-page session on his iPhone 18 Pro synced to his iPad and Mac (`05` §7), the Files copy, the recovery screen forced once | M2-5 |

**The device-only store** (`02` §5.1) *(rec.)*: its models (`ExtractionJobModel`,
`DeviceStateModel`) arrive with M3's `ExtractionQueue`, their only user, so M2 builds the synced
store only. The container takes the second configuration then, additively.

---

### Task M2-1 · Sylantro · The capture value types

**Status: complete** (22 Nov 2026, 68 tests; Results log).

**Inputs:** `00`, `00A`, `00B`, `02` §2, §3 and §5.1, `05` §4 and §5, `08` §3.1, `06` M1-1 (the
rules it set), this document.

**Deliverable:** the types below in `Sylantro/Domain/Capture/`, `PhotoEncoding` in
`Sylantro/Domain/Capture/`, one property added to `Recipe`, and
`SylantroTests/Domain/CaptureJSONTests.swift`.

**Rules (as M1-1's):** every type is `nonisolated`, conforms to `Codable`, `Sendable` and
`Equatable` (an enum: `String`, `Codable`, `Sendable`, `CaseIterable`), and imports `Foundation`
only. One type per file, named for the type. Each struct has an explicit memberwise `init` whose
parameters, in the order listed, default to the Default column. **Decoding:** `init(from:)` by
hand, every property `decodeIfPresent` falling back to its default, except `id`, which uses
`decode` and throws when missing. Unknown keys are ignored; encoding is synthesized. Fixtures are
made up (`00B` §2). `Domain/Capture/` is a new folder named here.

**No image data** (SLT-053): no type here holds `Data`, `[UInt8]` or any image. A photo is known
by its `fileName`.

`ScanSession` (`ScanSession.swift`), one sitting of scanning:

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Required when decoding |
| `startedAt` | `Date` | `Date()` | |
| `binderSection` | `String?` | `nil` | Reserved; no screen sets it in M2 |

`SourceKind` (`SourceKind.swift`): `nonisolated enum SourceKind: String` with `scan`,
`screenshot`, `web` (NI-5). Its `init(from:)` decodes a single string and gives `.scan` for any
value it doesn't know (SLT-067).

`StructuringState` (`StructuringState.swift`): `nonisolated enum StructuringState: String` with
`waiting`, `structured`, `failed`. Unknown values read as `.waiting` (SLT-067, SLT-044: a page a
newer app marked is looked at again, never lost).

`OCRWord` (`OCRWord.swift`): `text: String` (default `""`), `box: SourceBox` (no default; `decode`,
throws when missing), `confidence: Double?` (default `nil`, 0 to 1).

`SourcePage` (`SourcePage.swift`), the record of one original, never edited once saved (SLT-060):

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Required when decoding |
| `kind` | `SourceKind` | `.scan` | NI-5 |
| `sessionID` | `UUID?` | `nil` | Its `ScanSession` |
| `capturedAt` | `Date` | `Date()` | |
| `binderPageLabel` | `String?` | `nil` | Reserved |
| `ocrText` | `String?` | `nil` | Filled by M3 |
| `ocrWords` | `[OCRWord]` | `[]` | Filled by M3 |
| `structuringState` | `StructuringState` | `.waiting` | SLT-044 |
| `webAddress` | `String?` | `nil` | A web original's address as fetched (NI-5); text, not `URL` |
| `fetchedAt` | `Date?` | `nil` | A web original's fetch date |
| `fetchedRecipeJSON` | `String?` | `nil` | The recipe data exactly as fetched (`08` §3.1 A) |

`PhotoKind` (`PhotoKind.swift`): `nonisolated enum PhotoKind: String` with `pageOriginal`,
`pageCropped`, `dish` (`05` §4). Not decoded directly: `Photo` keeps the raw string (below).

`Photo` (`Photo.swift`), one image file's record (`05` §4):

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Required when decoding |
| `kindRaw` | `String` | `PhotoKind.pageOriginal.rawValue` | A raw string, so a future kind survives a round trip (`05` §4) |
| `sourcePageID` | `UUID?` | `nil` | A page photo's page |
| `recipeID` | `UUID?` | `nil` | A dish photo's recipe |
| `sortIndex` | `Int` | `0` | Dish photo order; 0 is the cover |
| `pixelWidth` | `Int?` | `nil` | |
| `pixelHeight` | `Int?` | `nil` | |
| `takenAt` | `Date` | `Date()` | |
| `fileName` | `String?` | `nil` | `PhotoEncoding.fileName(for: id)`; never the bytes (SLT-053) |

plus a computed `var kind: PhotoKind? { PhotoKind(rawValue: kindRaw) }` (nil for an unknown kind;
not encoded).

`PhotoEncoding` (`PhotoEncoding.swift`), a `nonisolated enum` of constants (`05` §5, P-3, each one
constant, `00A` §10):

- `static let heicQuality = 0.7`
- `static let dishLongEdge = 2_048`
- `static let thumbnailLongEdge = 400`
- `static let fileExtension = "heic"`
- `static func fileName(for id: UUID) -> String`: `"\(id.uuidString).heic"`

No encoding code: turning pixels into HEIC needs ImageIO, which `Domain/` doesn't import (SLT-081);
that is M2-3's.

**`Recipe` gains one property** (MT-2, ruled), after `sourcePageIDs`:
`continuesOnUnscannedPage: Bool`, default `false`, decoded with `decodeIfPresent` like the rest.
Set when she answers Save Without It at "Is there a page 2?" (SLT-046); cleared by Add Page. Test 1
of `RecipeJSONTests` (`full`) sets it `true`, so `full` keeps every property non-default.

**`CaptureJSON`** (`CaptureJSON.swift`), a `nonisolated enum` with `encode<T: Encodable>(_:)` and
`decode<T: Decodable>(_:from:)`, configured exactly as `RecipeJSON` (sorted keys, pretty printed,
no escaped slashes, ISO 8601 dates), each making its own coder.

**Tests** (`SylantroTests/Domain/CaptureJSONTests.swift`, `@Suite("Capture JSON")`). Dates are whole
seconds (`Date(timeIntervalSince1970: 1_795_000_000)`). Fixtures `fullSession`, `fullPage` (kind
`.web`, every property non-default, two `OCRWord`s) and `fullPhoto` (kind `dish`, every property
non-default). Tests, named for the rule:

1. "a session, a page and a photo survive a round trip": each decodes equal to its fixture.
2. "a page with only an id reads with every default": `{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F"}`
   gives that id, `.scan`, `.waiting`, empty `ocrWords`, nil optionals.
3. "a page without an id is refused": `{"kind":"scan"}` throws.
4. "an unknown source kind reads as scan": `"kind":"fax"` decodes as `.scan`.
5. "an unknown structuring state reads as waiting": `"structuringState":"archived"` decodes as
   `.waiting`.
6. "an unknown photo kind survives": a `Photo` with `kindRaw` `"sketch"` round-trips with that
   value and `kind` nil.
7. "a photo's file name is its id": `PhotoEncoding.fileName(for:)` of the fixed id above is
   `"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F.heic"`, and `fullPhoto`'s encoded JSON has no key other
   than the nine in the table (no image data, SLT-053).
8. "an older recipe reads with no page-2 warning": `RecipeJSON.decode` of
   `{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F"}` has `continuesOnUnscannedPage` `false`.

**Done when:**

1. The 10 files above (`ScanSession`, `SourceKind`, `StructuringState`, `OCRWord`, `SourcePage`,
   `PhotoKind`, `Photo`, `PhotoEncoding`, `CaptureJSON`, and the test file) exist where named, and
   `Recipe.swift` has the one new property, its `init` parameter and its decoding line.
2. The 8 tests pass, and `RecipeJSONTests` still passes with `full` updated.
3. Sylantro builds with no new warnings, and the suite passes on the pinned destination (`00B` §5).
   The total is the previous run's 60 plus 8: **68**. The summary reports the destination string
   and the run's own total.
4. No other file changes except this document's Results log (`00A` §6).
5. `git status` before and after is reported, and every git command run (`00A` §9).

**Do not:** add any `@Model`; change `Item.swift`, the store, any view, any build setting, the
entitlements or SyLib; add image encoding, file reading or writing; add `CaptureRecorder`,
`MirrorWriter` or `RecipeRendering`; add any other property to `Recipe`.

---

### Task M2-2 · Sylantro · The synced store and the recovery screen

**Status: complete** (22 Nov 2026, 76 tests; Pops's CloudKit check done, Results log).

**Inputs:** `00`, `00A`, `00B`, `02` §2, §5.1 to §5.3, §6 and §8, `05` §4, `13` §5 and §6
(S-30, S-31, S-33 to S-38), this document's M2-1, and SyLib's `SyLibScoringData/Schema/` and
SydeTwo's `SydeTwoApp.swift` as the patterns named below.

**What it does:** replaces the template store with Sylantro's real synced store on CloudKit, and
replaces its `fatalError` with the recovery screen (SLT-031). Nothing writes to the store yet
(that is M2-3); the library stays as it is.

**This task names, so they are not stop conditions:** turning on CloudKit for the store
(`00B` §2; the container and entitlements are already Pops's, unchanged); deleting `Item.swift`
and the template store code; moving the store's files aside, only through Start Fresh below.

**1. The schema** (`Sylantro/Store/SylantroSchemaV1.swift`), shaped as SyLib's
`ScoringSchemaV1`: a `VersionedSchema` enum, `versionIdentifier` `.init(1, 0, 0)`, whose
`@Model final class`es are nested inside it, each with every property defaulted (SLT-014), an
empty `init()`, no `@Attribute(.unique)` (CloudKit refuses it) and **no relationships** (MT-4):
links are ids, as M2-1's types already carry them. **No image data** (SLT-053, `00B` §2).

| Model | Properties (all defaulted) |
|---|---|
| `ScanSessionModel` | `id: UUID = UUID()`, `startedAt: Date = Date()`, `binderSection: String? = nil` |
| `SourcePageModel` | `id`, `kindRaw: String = "scan"`, `sessionID: UUID? = nil`, `capturedAt: Date = Date()`, `binderPageLabel: String? = nil`, `ocrText: String? = nil`, `ocrWordsData: Data? = nil` (the `[OCRWord]` as `CaptureJSON`; text and boxes, never pixels), `structuringStateRaw: String = "waiting"`, `webAddress: String? = nil`, `fetchedAt: Date? = nil`, `fetchedRecipeJSON: String? = nil` |
| `RecipeModel` | `id`, `title: String = ""`, `createdAt`, `updatedAt` (both `Date()`), `reviewStateRaw: String = "needsReview"`, `recipeData: Data? = nil` (the whole `Recipe` as `RecipeJSON`, MT-5) |
| `PhotoModel` | `id`, `kindRaw: String = "pageOriginal"`, `sourcePageID: UUID? = nil`, `recipeID: UUID? = nil`, `sortIndex: Int = 0`, `pixelWidth: Int? = nil`, `pixelHeight: Int? = nil`, `takenAt: Date = Date()`, `fileName: String? = nil` |

Each model has `func hydrate(from value:)` (sets every property from its M2-1 or M1-1 value) and
`func toDomain() -> Value?` in an extension in its own file under `Sylantro/Store/`
(`ScanSessionModel+Domain.swift` and so on). `RecipeModel.toDomain()` decodes `recipeData`
(nil if missing or unreadable, logged at error level without recipe text); `title`,
`reviewStateRaw` and the dates are copies kept for `@Query` sorting, written by `hydrate`.
Typealiases at file scope in `SylantroSchemaV1.swift` (`typealias RecipeModel =
SylantroSchemaV1.RecipeModel`, and the other three), and `SylantroMigrationPlan` with
`schemas = [SylantroSchemaV1.self]` and no stages.

**2. The container** (`SylantroApp.swift`), from SydeTwo's, synced store only (MT-1):

- `static let syncedModels: [any PersistentModel.Type] = SylantroSchemaV1.models`.
- `ModelConfiguration("Sylantro", schema: Schema(syncedModels), cloudKitDatabase:
  .private(SylantroApp.cloudKitContainerID))`.
- `#if DEBUG`, when `AppConfig.DebugCloudKit.runSchemaExercise`: SyLibCloud's
  `CloudKitSchema.initializeDevelopment(models: syncedModels, configuration:, containerIdentifier:)`
  before opening, as SydeTwo does. The flag stays `false`.
- Opening is `StoreOpener.open() throws -> ModelContainer` (`Sylantro/App/StoreRecovery/`), with
  `SylantroMigrationPlan`. It never deletes, wipes or opens a fresh store on failure (SLT-031).
- `SylantroApp` keeps `@State private var store: StoreState` (`.open(ModelContainer)` or
  `.failed(String)`, the error's description), set in `init` from `StoreOpener.open()`. The body
  shows `RootView().modelContainer(container)` when open, and `StoreRecoveryView` when failed.
- `Item.swift` is deleted, with the template `Schema([Item.self])` and its `fatalError`.

**3. The recovery screen** (`Sylantro/Views/Recovery/StoreRecoveryView.swift`), `13` §5, option A
(SC-7), with the root's theme (Forest, System appearance) and text cap:

- S-30 as the title, S-31 below it. **S-32 is not shown until M2-5** (Pops, card "As drafted,
  S-32 waits for M2-5").
- **Try Again** (S-33): `StoreOpener.open()` again; on success the app shows the library, on
  failure the screen stays with the new error.
- **Start Fresh** (S-34): a plain centered `.alert` (SLT-088) titled S-35, message S-36, buttons
  S-37 (Start Fresh as `.destructive`, Cancel as `.cancel`). Start Fresh calls
  `StoreSetAside.moveAside(storeURL:)`, then `StoreOpener.open()`.
- **Details** (S-38): a `DisclosureGroup` showing the error text in `.footnote`, selectable.
- All copy verbatim from `13` §6 (`00B` §2).

**4. Setting the store aside** (`Sylantro/App/StoreRecovery/StoreSetAside.swift`), a
`nonisolated enum`:

- `static func moveAside(storeURL: URL, now: Date = Date(), fileManager: FileManager = .default)
  throws -> URL` moves the store file and its `-shm` and `-wal` siblings (those that exist) into
  `Application Support/Set Aside/<yyyy-MM-dd HHmmss>/` beside the store, and returns that folder.
  It **moves, never deletes or overwrites**; if the dated folder exists it appends ` 2`, ` 3`.
- Logged with `AppLogger(category: "StoreRecovery")`: the folder and file names, never contents.

**Tests** (Swift Testing, in-memory or temporary-folder only, never the live store):

`SylantroTests/Store/ModelTwinTests.swift`, `@Suite("Model twins")`, on an in-memory container
(`cloudKitDatabase: .none`) built from `SylantroApp.syncedModels`:

1. "a scan session survives the store": M2-1's `fullSession` → `hydrate` → insert, save, fetch →
   `toDomain()` equals it.
2. "a source page survives the store": the same with `fullPage`, two `OCRWord`s included.
3. "a photo survives the store": the same with `fullPhoto`.
4. "a recipe survives the store": M1-1's `full` the same way, and the model's `title` equals the
   recipe's.
5. "no model holds image data": every stored property of the four models, read from the
   container's `Schema`, is not `Data` except `ocrWordsData` and `recipeData` (SLT-053).

`SylantroTests/App/StoreSetAsideTests.swift`, `@Suite("Store set aside")`, in a temporary folder:

6. "the store and its siblings are moved, not deleted": three files `Sylantro.store`,
   `-shm`, `-wal` with known bytes end up, byte for byte, in `Set Aside/2026-11-22 093000/`, and
   are gone from the original place.
7. "a second set-aside in the same second gets its own folder": the second call returns
   `… 093000 2`, and the first folder is untouched.
8. "a missing sibling is not an error": only `Sylantro.store` present moves without throwing.

**Done when:**

1. The files above exist where named; `Item.swift` is gone; `SylantroApp` has no `fatalError`.
2. The 8 tests pass, named as above.
3. Sylantro builds with no new warnings, and the suite passes on the pinned destination: the
   previous 68 plus 8, **76**, with the destination string and the run's own total.
4. No other file changes except this document's Results log (`00A` §6). Claude updates `02` §8's
   file map.
5. `git status` before and after is reported, and every git command run (`00A` §9).
6. **Pops's check on his iPhone 18 Pro** (not hers, SLT-017): the app launches to the empty
   library signed into iCloud; with `runSchemaExercise` set `true` once in a Debug run, CloudKit
   Console's Development schema shows the four record types with no image field; the flag is set
   back to `false`. The agent lists these steps in its summary and does not do them.

**Do not:** write to the store from anywhere (no `CaptureRecorder`, no `RecipeEditor` yet); add
the device-only store; add any relationship, `.unique` or `.externalStorage`; change the
entitlements, Info.plist, capabilities or `AppConfig`'s values; show S-32; delete anything in
Start Fresh; touch the library, Settings or the spike screen beyond what `RootView` needs.

---

### Task M2-3 · Sylantro · Photo files and saving a capture

**Status: complete** (22 Nov 2026, 84 tests; Results log).

**Inputs:** `00`, `00A`, `00B`, `02` §2, §5.1, §5.2 and §8, `05` §4, §4.1, §5 and §8, `13` §3.1
and §4.2, this document's M2-1 and M2-2 and their Results rows, and the built code they made.

**What it does:** the App-layer pieces that make a capture safe, with no screen yet (M2-4 adds the
camera): `PhotoFiles` writes each page as a HEIC file in the app's hidden iCloud folder, and
`CaptureRecorder` saves a capture as one session's pages, their photos and one new recipe
(SC-1), in one save. Nothing reads, structures or mirrors (M3, M2-5).

**Step 0, before anything else:** confirm `Sylantro.entitlements` lists `CloudDocuments` in
`com.apple.developer.icloud-services` and `iCloud.com.syzygysoftwerksllc.Sylantro` in
`com.apple.developer.ubiquity-container-identifiers` (Pops added the capability, 22 Nov 2026). If
either is missing, **stop and tell Pops**. Also confirm `Info.plist` has the `NSUbiquitousContainers`
dictionary for that container (added 22 Nov 2026 at Pops's request; used from M2-5) and report it;
do not change it.

**1. `PhotoFiles`** (`Sylantro/Capture/PhotoFiles.swift`, MT-3), a `nonisolated struct`,
`Sendable`, holding one `root: URL`:

- `static func resolveRoot(ubiquityContainer: URL?, applicationSupport: URL) -> URL`: with iCloud,
  `<ubiquityContainer>/Photos/` (the container's root, **outside `Documents`**, so Files never shows
  it, `05` IS-4); with iCloud off (nil), `<applicationSupport>/Photos/`. Pure, so it is tested.
- `static func live() async -> PhotoFiles`: calls `FileManager.default.url(forUbiquityContainerIdentifier:
  SylantroApp.cloudKitContainerID)` **off the main actor** (it can block), then `resolveRoot`,
  creates the folder if missing, and logs which one (`AppLogger(category: "Photos")`, path only).
- `func write(_ image: CGImage, fileName: String) throws -> (width: Int, height: Int)`: encodes HEIC
  with ImageIO (`CGImageDestination`, type `UTType.heic`, `kCGImageDestinationLossyCompressionQuality`
  = `PhotoEncoding.heicQuality`, full resolution, IS-2), and writes it to `root/fileName` through an
  `NSFileCoordinator` write. It **never overwrites**: if the file exists it throws. Returns the
  image's pixel size.
- `func url(for fileName: String) -> URL`.
- `func availability(of fileName: String) -> PhotoAvailability`, a `nonisolated enum` in the same
  file: `.available`, `.downloading` (an iCloud file not yet on this device; this call asks iCloud
  to download it with `startDownloadingUbiquitousItem`), `.missing`. **A missing file is never
  treated as a deleted photo** (`05` §4.1, SLT-030).
- No delete or move function: nothing removes a page photo (SLT-030). Dish photos' removal comes
  with their screens after M3.

**2. `RecipeEditor`** (`Sylantro/Store/RecipeEditor.swift`, MT-8), `@MainActor final class`,
holding the `ModelContext` it is given. M2-3 gives it only what capture needs; review's edits come
in M3:

- `func insertDraft(pageIDs: [UUID], continuesOnUnscannedPage: Bool, now: Date) -> Recipe`: a
  `Recipe` with `title` `""`, those `sourcePageIDs` in order, the flag, `.needsReview`, `createdAt`
  and `updatedAt` = `now`; inserts a `RecipeModel` hydrated from it. **Does not save** (the caller
  saves once).
- `func appendPages(_ pageIDs: [UUID], to recipeID: UUID, now: Date) throws`: adds them after the
  recipe's existing `sourcePageIDs`, sets `continuesOnUnscannedPage` to `false` (Add Page, SLT-046),
  `updatedAt` = `now`; re-hydrates the model. Throws if the recipe isn't found. Does not save.

**3. `CaptureRecorder`** (`Sylantro/Capture/CaptureRecorder.swift`), `@MainActor final class`,
holding a `ModelContext`, a `PhotoFiles` and a `RecipeEditor`. It only ever adds (`02` §5.2):

- `func startSession(now: Date = Date()) throws -> UUID`: inserts and saves a `ScanSessionModel`.
- `func saveCapture(_ pages: [CGImage], sessionID: UUID, continuesOnUnscannedPage: Bool,
  now: Date = Date()) throws -> UUID` (the new recipe's id), in this order:
  1. For each page, in order: a new page id and photo id; `PhotoFiles.write` the image as
     `PhotoEncoding.fileName(for: photoID)`. **If any write throws, stop and rethrow before
     inserting anything**; files already written stay (never deleted, SLT-030) and are logged.
  2. Insert one `SourcePageModel` per page (`kind` `.scan`, the session id, `capturedAt` = `now`,
     `.waiting`) and one `PhotoModel` per page (`kindRaw` `"pageCropped"`, MT-7: the camera's flattened page is the only image, its `sourcePageID`, the pixel
     size, `takenAt` = `now`, `fileName`).
  3. `recipeEditor.insertDraft(pageIDs:continuesOnUnscannedPage:now:)`.
  4. **One** `context.save()`. If it throws, roll back the context and rethrow.
- `func addPages(_ pages: [CGImage], to recipeID: UUID, sessionID: UUID, now: Date = Date()) throws`:
  steps 1 and 2 the same, then `recipeEditor.appendPages`, then one save.
- An empty `pages` array throws without writing anything.
- Logs each capture's page count and recipe id at info, never recipe text or pixels.

`SylantroApp` and the screens are **not** changed: M2-4 creates these at the root.

**Tests** (Swift Testing; an in-memory container as `ModelTwinTests.makeContainer()`, and a
`PhotoFiles` on a fresh temporary folder, removed at the end; images are small made-up `CGImage`s
drawn in code, 40 × 60 and 60 × 40 pixels, never real pages):

`SylantroTests/Capture/PhotoFilesTests.swift`, `@Suite("Photo files")`:

1. "with iCloud the folder is outside Documents": `resolveRoot(ubiquityContainer: X, …)` is
   `X/Photos`, and its path contains no `Documents` component.
2. "with iCloud off the folder is local": `resolveRoot(ubiquityContainer: nil, applicationSupport: Y)`
   is `Y/Photos`.
3. "a photo is written as HEIC at full size": writing the 40 × 60 image returns (40, 60); the file
   exists; its bytes 4 to 11 read `ftypheic` (or `ftypmif1`, both HEIC brands); `CGImageSource`
   reads it back as 40 × 60.
4. "a photo is never overwritten": writing the same file name twice throws, and the first file's
   bytes are unchanged.
5. "a missing photo is missing, not an error": `availability` of an unknown name is `.missing`.

`SylantroTests/Capture/CaptureRecorderTests.swift`, `@Suite("Capture recorder")`:

6. "a capture becomes one recipe with its pages": a session, then two pages saved → 1 session,
   2 `SourcePageModel`s (`.scan`, `.waiting`, the session id), 2 `PhotoModel`s with their page ids,
   pixel sizes and existing files, and 1 `RecipeModel` whose `toDomain()` has `title` `""`, the two
   page ids **in capture order**, `.needsReview` and `continuesOnUnscannedPage` `false`.
7. "Save Without It marks the recipe, Add Page clears it": saved with the flag `true`, then
   `addPages` of one more page → the recipe has three page ids in order and the flag `false`.
8. "a failed photo write saves nothing": with a `PhotoFiles` whose root is a file, not a folder,
   `saveCapture` throws and the store has no pages, photos or recipes.

**Done when:**

1. Step 0 is reported (both entitlement entries present; whether `NSUbiquitousContainers` is in
   `Info.plist`).
2. `PhotoFiles.swift`, `CaptureRecorder.swift`, `RecipeEditor.swift` and the two test files exist
   where named.
3. The 8 tests pass, named as above.
4. Sylantro builds with no new warnings, and the suite passes on the pinned destination: 76 + 8 =
   **84**, with the destination string and the run's own total. **If the simulator cannot encode
   HEIC, stop and report it**; do not switch format (SLT-054).
5. No other file changes except this document's Results log (`00A` §6).
6. `git status` before and after is reported, and every git command run (`00A` §9).

**Do not:** add the camera, any view or copy; change `SylantroApp`, `RootView`, the entitlements,
`Info.plist` or `AppConfig`; add `MirrorWriter`; put any image bytes in a model (SLT-053); delete,
move or overwrite any photo file; resize page photos; write JPEG anywhere (SLT-054).

---

### Task M2-4 · Sylantro · The library, the camera and a recipe

**Status: ready** (run 2; M2-4a complete, 22 Nov 2026: `ImageCache.store(_:for:toDisk:)` exists). Revised
after run 1's blocker (§2): the cache (MT-13), the labels (MT-11) and Cancel while pages are
pending (MT-12).

**Inputs:** `00`, `00A`, `00B`, `02` §1, §2, §5.2, §6 and §8, `05` §4.1 and §5, `13` in full (all
copy approved, 22 Nov 2026), this document's M2-1 to M2-3 and their Results rows, and the built
code: `RootView`, `LibraryView`, `NoRecipeSelectedView`, `Sheet`, `TextReader.readBottom`,
`PhotoFiles`, `CaptureRecorder`, `RecipeEditor`; SyLibUI's `CapsuleButton` and `EmptyStateView`;
SyLibCache's `ImageCache` with M2-4a's `toDisk:` argument (`14A`).

**What it does:** the first screens she uses: the library's rows and the **Let's cook.** capsule,
VisionKit's document camera, Save with the page-2 question (SLT-046), the saved line, a recipe's
pages, Add Page and Delete Recipe. Nothing is read beyond Save's bottom-lines check; nothing is
mirrored (M2-5). **All copy is `13` §6 verbatim** (S-0 to S-28); none is invented.

**This task names, so they are not stop conditions:** linking SyLib's `SyLibCache` product to the
app target (SLT-084, for thumbnails); the Domain type `UnfinishedPageCheck` (MT-9); new views in
`Views/Library/`, `Views/Capture/` and `Views/Recipe/` named below.

**1. `UnfinishedPageCheck`** (`Sylantro/Domain/Capture/UnfinishedPageCheck.swift`), a
`nonisolated enum`, Foundation only (SLT-081). `static func looksUnfinished(_ lines: [String]) ->
Bool`, given the bottom lines of the capture's last page **top to bottom** (MT-10, SLT-046):

1. **Footer lines are set aside first:** a line that is only a web address (`http`, `https` or
   `www.`), only a date or time (digits with `/`, `:`, `,`, `AM`/`PM`), only "Page n of m", only
   "n/m" or "n of m", or only digits. They are read for rule 2 and ignored by rules 3 and 4.
2. **"Page n of m" with n < m** (case-insensitive, also a footer's "n/m" or "n of m" alone on a
   line, n < m) → true.
3. **Ends mid-sentence:** the last line that isn't a footer ends with a letter, a digit, a comma,
   a hyphen or "and"/"or" (not `.`, `!`, `?`, `:`, `)`, a closing quote) → true. A finished step
   ends with a full stop; a page that ends on a heading such as "Notes" asks, which is wanted.
4. **A footnote asterisk with no footnote:** a word ending in `*` on any non-footer line, and no
   line starting with `*` → true.
5. Otherwise, and for no lines at all, false.

A wrong "yes" only asks her a question; a wrong "no" is fixed later with Add Page (SLT-045).

**2. `PhotoFiles` gains** `func thumbnail(of fileName: String, longEdge: Int =
PhotoEncoding.thumbnailLongEdge) -> CGImage?`: ImageIO's `CGImageSourceCreateThumbnailAtIndex`
with `kCGImageSourceThumbnailMaxPixelSize` = `longEdge`, nil if the file isn't available. Never
written to the store (P-4, SLT-053). Views cache the `UIImage` in `ImageCache.shared` with
`store(_:for:toDisk: false)` (M2-4a: memory only, no file, no JPEG), keyed by the photo's file
URL, and look it up with `memoryImage(for:)` only, never `diskImage(for:)`.

**3. `RecipeEditor` gains** `func delete(_ recipeID: UUID) throws`: deletes the `RecipeModel`
only and saves; its `SourcePageModel`s, `PhotoModel`s and files stay, as pages without a recipe
(SC-5, SLT-030). Throws if not found.

**4. The root** (`RootView`): in its launch `.task`, `await PhotoFiles.live()`, then makes one
`RecipeEditor` and one `CaptureRecorder` on the environment's `modelContext`, kept as `@State`
optionals and passed to the library and the recipe view (nil until ready: the capsule is disabled
until then). The split view's selection is a `UUID?` recipe id; the detail is `RecipeView` for a
selected recipe, else `NoRecipeSelectedView` (S-1). No change to `SylantroApp`.

**5. The library** (`LibraryView`, extended; title S-0 as built):

- `@Query(sort: \RecipeModel.createdAt, order: .reverse)` recipes, **one row per id** (CloudKit
  allows duplicates, `02` §5.2: the first of each id wins), and `@Query` photos to find each
  recipe's cover: the `PhotoModel` of its first `sourcePageID`.
- **`RecipeRow`** (`Views/Library/RecipeRow.swift`): a 56 pt square thumbnail (rounded 8 pt,
  `.fill`, a placeholder with `icloud.and.arrow.down` while not available, VoiceOver S-27), the
  title (S-2 "New recipe" when `title` is empty), and S-3 under it ("Scanned Nov 22 · 2 pages",
  `Date.FormatStyle` month abbreviated and day in her locale; "1 page" for one).
- Empty: `EmptyStateView(systemImage: "book.closed", title: S-4, message: S-5)`.
- **The capsule** (SC-2): `CapsuleButton(S-6, fillsWidth: true)` in `.safeAreaInset(edge:
  .bottom)`, on iPhone and iPad; **hidden when `ProcessInfo.processInfo.isiOSAppOnMac`**. Tap:
  if `VNDocumentCameraViewController.isSupported` is false, a plain `.alert` S-16 / S-17 with
  **OK** (S-28); else the camera.

**6. The camera** (`Views/Capture/DocumentCameraView.swift`, a `UIViewControllerRepresentable`
for `VNDocumentCameraViewController`, and `Views/Capture/CaptureFlowView.swift`, presented
`.fullScreenCover` from the library), SLT-045:

1. The first camera of a sitting calls `captureRecorder.startSession()`; later recipes in the same
   sitting reuse that session id.
2. On the camera's Save (`didFinishWith scan`): the pages are `scan.imageOfPage(at:)` for each
   index, as `CGImage`s, kept in memory as the **pending capture**.
3. **The page-2 question** (SLT-046): `TextReader().readBottom(lastPage)`, its lines sorted by
   `box.y`, then `UnfinishedPageCheck.looksUnfinished`. If true, a plain `.alert` S-10 / S-11 with
   **Add Page** (S-12): reopen the camera and append its pages to the pending capture, then ask
   again of the new last page. **Cancel in that camera** (MT-12) keeps the pending pages and asks
   the same question again of the pending last page, so she can still choose Save Without It and
   nothing is lost. **Save Without It** (S-13): save with the flag. A failed read is
   logged and counts as false. Log the read's duration at info (the spike's open timing).
4. **Save:** `captureRecorder.saveCapture(pending, sessionID:, continuesOnUnscannedPage:)`. On
   success the camera reopens for the next recipe and **S-7** shows for 2 seconds as a capsule
   label over the camera's top edge (SC-4). On failure, a plain `.alert` S-14 / S-15 with **Save**
   (S-18: try the same pending pages again) and **Cancel** (S-19: drop them and close the camera).
5. **Cancel in the camera** with nothing pending closes it and returns to the library. A camera
   error is logged and closes it.

**7. A recipe** (`Views/Recipe/RecipeView.swift`, `Views/Recipe/PagePhotoView.swift`,
`Views/Recipe/PagePhotoViewer.swift`):

- Title: the recipe's, or S-2. Under it **S-20** while it has no `extraction` (all of M2), and
  **S-21** with `exclamationmark.triangle` when `continuesOnUnscannedPage`.
- **The pages**, in `sourcePageIDs` order, each full width at its aspect ratio (`pixelWidth`,
  `pixelHeight`), loaded off the main actor from `PhotoFiles.url`; while `availability` isn't
  `.available`, the placeholder with S-27, checked again every 2 seconds while the view is shown
  (SC-6). Tap a page: `PagePhotoViewer` full screen, pinch to zoom, closed with the system's
  close button (`Button(role: .close)`, no text of ours, MT-11). Each page image keeps the system's
  default accessibility label; none is written (MT-11).
- Toolbar: **Add Page** (S-22) opens the camera in add mode: its pages go to
  `captureRecorder.addPages(_:to:sessionID:)` (a new session if none is open). No page-2 question
  for Add Page. **⋯**, a `Menu` labeled only with the `ellipsis.circle` symbol (the
  system's own label, no text of ours, MT-11), with **Delete Recipe** (S-23): a plain `.alert` S-24 / S-25, **Delete**
  (`.destructive`) and **Cancel** (S-26), then `recipeEditor.delete`, and the selection clears.

**Tests** (Swift Testing; made-up lines and images only):

`SylantroTests/Domain/UnfinishedPageCheckTests.swift`, `@Suite("Unfinished page")`:

1. "page 1 of 2 asks": `["Bake until golden.", "Page 1 of 2"]` → true.
2. "the last page doesn't ask": `["Serve warm.", "Page 2 of 2"]` → false.
3. "a sentence cut off asks": `["Stir in the flour and"]` → true; `["Add the milk,"]` → true.
4. "a finished step doesn't ask": `["Serve warm."]` → false.
5. "web footers are set aside": `["Serve warm.", "https://www.example.com/recipes/soup",
   "11/20/26, 3:45 PM", "1/1"]` → false; the same with `"1/2"` last → true.
6. "a footnote asterisk with no footnote asks": `["2 cups oats*", "Bake 20 minutes."]` → true;
   adding `"* Use gluten-free oats."` → false.
7. "no lines don't ask": `[]` → false.

`SylantroTests/Capture/CaptureRecorderTests.swift` (the existing suite) gains:

8. "deleting a recipe keeps its pages and photos": after a two-page capture, `delete` → no recipes,
   two pages, two photos, and both files still on disk.

`SylantroTests/Capture/PhotoFilesTests.swift` (the existing suite) gains:

9. "a thumbnail is no bigger than asked": the 40 × 60 photo's `thumbnail(longEdge: 30)` is 20 × 30.

**Done when:**

1. The files above exist where named; `SyLibCache` is linked to the app target only.
2. The 9 tests pass, named as above.
3. Sylantro builds with no new warnings, and the suite passes on the pinned destination: 84 + 9 =
   **93**, with the destination string and the run's own total.
4. Every string on screen is from `13` §6, verbatim; a grep of the new views for string literals
   finds no other user-facing text. The close button, the ⋯ menu and the page images use iOS's own
   labels (MT-11), each named in the row.
5. No other file changes except this document's Results log (`00A` §6).
6. `git status` before and after is reported, and every git command run (`00A` §9).
7. **Pops's check on his iPhone 18 Pro and iPad** (listed by the agent, not done by it): an empty
   library shows S-4 / S-5 and the capsule; scan a two-page recipe, Save, see S-7 and the camera
   again, Cancel; the library shows "New recipe" with the first page's thumbnail and "· 2 pages";
   scan a page ending mid-sentence and get "Is there a page 2?"; the recipe shows its pages,
   zooms, Add Page appends a page and clears the warning; Delete Recipe removes the row; on the
   iPad the new recipes arrive by sync, with placeholders until the photos download; on the Mac
   the capsule is hidden.

**Do not:** add `MirrorWriter` or any Files copy; show S-32; read or structure beyond Save's
bottom-lines check; put image bytes or thumbnails in any model (SLT-053); delete, move or
overwrite any photo file; write JPEG (SLT-054); use a `.confirmationDialog`, action sheet or
anchored popover (SLT-088); change the entitlements, `Info.plist`, `AppConfig` or the store's
models; add search or sorting (SC-3).

---

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| M2-4 (run 2) | 22 Nov 2026 | **complete** (clause 7 is Pops's, not yet done) | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 93 tests in 17 suites passed after 0.248 seconds."; `** TEST SUCCEEDED **` (84 + 9). **Clauses:** ✅ 1 the files exist where named. New: `Domain/Capture/UnfinishedPageCheck.swift` (a `nonisolated enum`, Foundation only), `Views/Library/RecipeRow.swift`, `Views/Capture/DocumentCameraView.swift`, `Views/Capture/CaptureFlowView.swift`, `Views/Recipe/RecipeView.swift`, `Views/Recipe/PagePhotoView.swift` and `Views/Recipe/PagePhotoViewer.swift`. Extended: `PhotoFiles.thumbnail(of:longEdge:)` (ImageIO, `kCGImageSourceThumbnailMaxPixelSize`, nil unless `.available`), `RecipeEditor.delete(_:)`, `RootView` and `LibraryView`. `SyLibCache` is linked to the app target only: one `package-product-members` entry on target `Sylantro` in `project.xcproj`, and the test target is unchanged. ✅ 2 the 9 tests pass, named as written: `@Suite("Unfinished page")` 1 to 7; "deleting a recipe keeps its pages and photos" in `Capture recorder`; "a thumbnail is no bigger than asked" in `Photo files`. ✅ 3 builds and passes on the pinned destination with 93 tests. The only warnings are the existing appintentsmetadataprocessor "Metadata extraction skipped" (×2), so there are no new warnings (see Fixes). ✅ 4 a `python3` scan of every string literal in the new and changed views (`LibraryView`, `RecipeRow`, `DocumentCameraView`, `CaptureFlowView`, `RecipeView`, `PagePhotoView`, `PagePhotoViewer`, `RootView`) finds user-facing text only from `13` §6: S-0, S-2 to S-7, S-10 to S-28. Everything else is logger categories and log lines, SF Symbol names, and the library toolbar and About copy, which were already built and are unchanged. iOS's own labels (MT-11): the viewer closes with `Button(role: .close) { dismiss() }` in its toolbar, with no label of ours. The ⋯ is a `Menu` whose label is only `Image(systemName: "ellipsis.circle")`. Each page is a `.plain` `Button` whose label is the page `Image(uiImage:)`, with no accessibility label written, so it keeps the system's default. The photo placeholders carry S-27 as their VoiceOver label, as the task says. ✅ 5 no other file changed except this row; `sylib-swift` was not edited (its M2-4a changes are as M2-4a left them). ✅ 6 git status is below. ⚠️ 7 Pops's device check, on his iPhone 18 Pro and iPad, is not done; the agent doesn't do it. Steps: (i) an empty library shows "No recipes yet" / "Tap Let's cook. and photograph a recipe from your binder." and the **Let's cook.** capsule. (ii) Scan a two-page recipe and tap Save: "Saved. Ready for the next one." shows and the camera reopens. Tap Cancel to return to the library. (iii) The library shows "New recipe", the first page's thumbnail, and "Scanned ‹date› · 2 pages". (iv) Scan a page ending mid-sentence and get "Is there a page 2?". Try Add Page, then Cancel in that camera: the question comes back (MT-12). (v) Open the recipe: its pages show in order, and tapping one opens it full screen, where it pinch-zooms and closes with the system close button. Add Page appends a page and clears "Continues on a page not scanned". (vi) ⋯ › Delete Recipe › Delete removes the row, and the selection clears. (vii) On the iPad, the new recipes arrive by sync, with download placeholders until the photos land. (viii) On the Mac, the capsule is hidden. **What the code does:** `UnfinishedPageCheck` follows MT-10: footers (web address, date or time, "Page n of m", "n/m", "n of m", digits) are set aside. n < m in a footer → true. The last non-footer line ending in a letter, digit, comma or hyphen → true. A word ending in `*` with no line starting with `*` → true. `RootView`'s launch `.task` (after its preview guard) awaits `PhotoFiles.live()`, then makes one `RecipeEditor` and one `CaptureRecorder` on `modelContext`, held as `@State` optionals. Selection is `UUID?`; the detail is `RecipeView(…).id(selection)` or `NoRecipeSelectedView`. `LibraryView`: `@Query(sort: \RecipeModel.createdAt, order: .reverse)` with the first of each id kept, and `@Query` photos for each cover (the photo of the first page, `pageCropped` preferred). `EmptyStateView` is an overlay when there are no rows. `CapsuleButton("Let's cook.", fillsWidth: true)` sits in `.safeAreaInset(edge: .bottom)`, hidden when `isiOSAppOnMac` and disabled until the recorder exists; without `VNDocumentCameraViewController.isSupported` it shows S-16 / S-17 / OK. `RecipeRow` reads `ImageCache.shared.memoryImage(for:)` and never `diskImage`. Otherwise it makes the thumbnail in a detached task, stores it with `store(_:for:toDisk: false)`, and retries every 2 seconds until the file is available. `CaptureFlowView` starts the session in `.task` (and again at Save if that failed), and keeps the pending pages. Its bottom read is `TextReader().readBottom`, lines sorted by `box.y`; a failed read counts as finished, and the duration is logged at info in milliseconds. The page-2 alert is S-10 to S-13. Saving goes through `saveCapture`; on success it reopens the camera (a new `.id`) and shows S-7 for 2 seconds. The failure alert is S-14, S-15, Save (S-18, retry) and Cancel (S-19, drop and close). Cancel with pages pending asks the page-2 question again (MT-12). `RecipeView`: S-2 title fallback, S-20 while there is no `extraction`, S-21 with `exclamationmark.triangle`, and the pages in `sourcePageIDs` order. Add Page opens `CaptureFlowView(mode: .addPages)`, which calls `addPages` and closes, with no page-2 question. The Delete alert is S-24 to S-26, then `delete`, then `onDeleted` clears the selection. **Files:** new: the 7 files above and `SylantroTests/Domain/UnfinishedPageCheckTests.swift`. Changed: `Sylantro.xcodeproj/project.xcproj` (SyLibCache), `Capture/PhotoFiles.swift`, `Store/RecipeEditor.swift`, `Views/Root/RootView.swift`, `Views/Library/LibraryView.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift` and `SylantroTests/Capture/PhotoFilesTests.swift`; and this row. **Fixes:** the first build failed in `RootView` ("'modelContext' / 'modelContainer(for:inMemory:…)' is not available due to missing import of defining module 'SwiftData'"), my own change. Fixed with `import SwiftData`. **Git status before** (branch `milestone-2`): everything from M2-1 to M2-3 staged by Pops, with `MM` on `Docs/12`, `14` and `README.md` and `AM` on `Docs/14A`. **After:** the same index, plus unstaged ` M` on `project.xcproj`, `LibraryView.swift` and `RootView.swift`; `AM` on `PhotoFiles.swift`, `RecipeEditor.swift`, `CaptureRecorderTests.swift` and `PhotoFilesTests.swift`; and `??` for `Domain/Capture/UnfinishedPageCheck.swift`, `Views/Capture/`, `Views/Library/RecipeRow.swift`, `Views/Recipe/` and `SylantroTests/Domain/UnfinishedPageCheckTests.swift`. This row is in `14`'s unstaged changes. SyLib (read only): ` M` on its three M2-4a files, unchanged by this session. **Git:** Sylantro: `git status --short` (×2), `git branch --list`, `git log --oneline -3`, `git diff --stat HEAD -- Sylantro/Docs/00A_STUDIO_CONVENTIONS.md Sylantro/Docs/00B_SYLANTRO_GUARDRAILS.md` (empty: unchanged). SyLib: `git status --short` (×2). **Notes:** (a) A camera **error** with pages pending is treated as Cancel, so the page-2 question is asked again rather than the camera closing and losing them. With nothing pending, an error closes the camera, as §6.5 says. MT-12 names only Cancel; this extends it to errors so no pages are lost. Tell me if errors should close regardless. (b) Add Page from a recipe also checks `VNDocumentCameraViewController.isSupported` and shows S-16 / S-17 / OK, as the capsule does; the task doesn't say. (c) `saveCapture` is synchronous (HEIC encoding of every page on the main actor, as M2-3 built it), so Save holds the camera briefly. On a device this is the "about a second a page" of SLT-041, for Pops to time. (d) A recipe page decodes the full-resolution image for display (`UIImage(contentsOfFile:)` then `preparingForDisplay()`, off the main actor). A recipe with many pages may use a lot of memory; worth watching on a device. (e) `RecipeEditor.delete` deletes every `RecipeModel` with that id, since CloudKit allows duplicates, and throws when there are none. (f) The page images come from `scan.imageOfPage(at:).cgImage`; VisionKit's pages are upright, so no orientation is applied. (g) `RootView`'s and `LibraryView`'s previews gained `.modelContainer(for: SylantroApp.syncedModels, inMemory: true)`, so their `@Query`s have a store. They were written, not rendered. (h) S-3's date is `createdAt` formatted `.dateTime.month(.abbreviated).day()` in her locale. |
| M2-4 | 22 Nov 2026 | **blocked** before any code: the thumbnail cache can't be both `ImageCache` and memory only without writing JPEG, and three labels have no approved copy | **No code written; no build or test run** (the last suite total is M2-3's 84). **Blocker 1 (`00A` §4: a done-when that can't be met as written; `00B` §2):** §2 says "Views cache the `UIImage` in `ImageCache.shared` (memory only, keyed by the file URL)". As built, SyLibCache's `ImageCache` has no memory-only store. `store(_:for:)` always writes to disk as JPEG as well (`sylib-swift/Sources/SyLibCache/ImageCache.swift`, lines 61 to 68: `image.jpegData(compressionQuality: 0.85)` written to the caches folder), and the Do not says "write JPEG (SLT-054)". The only memory call is the read, `memoryImage(for:)`. Meeting the task as written would need an unnamed SyLib edit (`00B` §2). **Options for Pops:** (a) *(rec.)* a small memory-only `NSCache<NSURL, UIImage>` in Sylantro, keyed by the file URL: no SyLib change, no JPEG, and SyLibCache linked as named but unused for now; (b) a SyLib task that adds a memory-only `store` to `ImageCache` first; (c) no cache in M2 (ImageIO thumbnails are fast), with SyLibCache not linked. **Blocker 2 (`00B` §2: user-facing text the task doesn't give):** three controls need labels that aren't in `13` §6. These are §7's `PagePhotoViewer` "Done to close"; the recipe's **⋯** menu button, which needs an accessibility label (`00A` §5: label every control); and each tappable page image, which also needs one. Done-when 4 allows no text outside §6. **Options:** (a) *(rec.)* iOS's own labelled controls, so no new strings are written: `Button(role: .close)` for the viewer, a `Menu` labelled with the `ellipsis.circle` symbol, and the system's default for the page images, each reported in the row; (b) Pops approves strings such as "Done", "More" and "Page 1" in `13` §6; (c) reuse the library's built "More" (SyLib's `MoreMenu`). **Also noted for the rerun:** the task doesn't say what Cancel in the camera does while a capture is pending, that is, after Add Page from "Is there a page 2?". The agent would re-ask the page-2 question so no pages are lost, unless told otherwise. **Clauses:** ⚠️ 1 to 4 not started. ✅ 5 no file changed except this row. ✅ 6 git status is below. ⚠️ 7 Pops's checks are not reached. **Git status before and after** (branch `milestone-2`): as M2-3's After, unchanged by this session apart from this row in `14`. **Git:** `git status --short`, `git branch --list`, `git diff --stat`, `git diff -- Sylantro/Docs/00_DECISION_LEDGER.md Sylantro/Docs/00A_STUDIO_CONVENTIONS.md Sylantro/Docs/00B_SYLANTRO_GUARDRAILS.md Sylantro/Docs/02_ARCHITECTURE.md Sylantro/Docs/05_IMAGE_STORAGE_DESIGN.md`. |
| M2-3 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 84 tests in 16 suites passed after 0.183 seconds."; `** TEST SUCCEEDED **` (76 before + 8). **HEIC on the simulator:** encodes and reads back (test 3), so there is no format question. **Clauses:** ✅ 1 Step 0: `Sylantro.entitlements` lists `CloudDocuments` (with `CloudKit`) in `com.apple.developer.icloud-services`, and `iCloud.com.syzygysoftwerksllc.Sylantro` in `com.apple.developer.ubiquity-container-identifiers` (and still in `icloud-container-identifiers`). `Info.plist` has `NSUbiquitousContainers` with `iCloud.com.syzygysoftwerksllc.Sylantro`: `NSUbiquitousContainerIsDocumentScopePublic` `true`, `NSUbiquitousContainerName` "Sylantro", `NSUbiquitousContainerSupportedFolderLevels` "Any". Both changes are unstaged in the tree (Pops's and Claude's); neither file was changed by this session. ✅ 2 the files exist where named: `Sylantro/Capture/PhotoFiles.swift`, `Sylantro/Capture/CaptureRecorder.swift`, `Sylantro/Store/RecipeEditor.swift`, `SylantroTests/Capture/PhotoFilesTests.swift` and `SylantroTests/Capture/CaptureRecorderTests.swift`. In `PhotoFiles` (a `nonisolated struct`, `Sendable`, `root: URL`): `resolveRoot` gives `<container>/Photos/` with iCloud and `<applicationSupport>/Photos/` with it off. `live()` asks `url(forUbiquityContainerIdentifier:)` in a `Task.detached`, creates the folder, and logs local or iCloud with the path. `write` encodes HEIC through `CGImageDestination` (`UTType.heic`, quality `PhotoEncoding.heicQuality`, full resolution) and writes inside an `NSFileCoordinator` write; it throws when the file exists. `url(for:)`. `availability(of:)` returns `.available`, `.downloading` (after `startDownloadingUbiquitousItem`) or `.missing`, and has no delete or move. `RecipeEditor` (`@MainActor final class`, holding its `ModelContext`) has only `insertDraft` and `appendPages`, neither of which saves. `CaptureRecorder` (`@MainActor final class`) has `startSession`, `saveCapture` and `addPages`, in the steps as written. All photo files are written first, and a failed write rethrows before anything is inserted. Then one `SourcePageModel` (`.scan`, the session, `now`, `.waiting`) and one `pageCropped` `PhotoModel` per page, then `insertDraft` or `appendPages`, then one `save()`, rolled back on failure. Empty `pages` throws `noPages` before writing. The logs give page counts and ids only. ✅ 3 the 8 tests pass, named as written: `@Suite("Photo files")` 1 to 5 and `@Suite("Capture recorder")` 6 to 8. ✅ 4 builds and passes on the pinned destination with 84 tests. The only warnings are the existing appintentsmetadataprocessor "Metadata extraction skipped" (×2), so there are no new warnings (see Fixes). ✅ 5 no other file changed except this row: `SylantroApp`, `RootView`, the entitlements, `Info.plist` and `AppConfig` are untouched. There is no view, camera, `MirrorWriter` or JPEG. No model gained a property, so no image bytes are in any model. ✅ 6 git status before and after is below. **Files:** new: `Sylantro/Capture/PhotoFiles.swift`, `Sylantro/Capture/CaptureRecorder.swift`, `Sylantro/Store/RecipeEditor.swift`, `SylantroTests/Capture/PhotoFilesTests.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`; and this row. **Fixes:** the first build warned "main actor-isolated static property 'cloudKitContainerID' cannot be accessed from outside of the actor" in `PhotoFiles.live()`, my own code. I fixed it by marking `live()` `@MainActor`: it reads the id there, and the blocking call stays in the detached task. No other file was changed, and the re-run is warning-free. **Git status before** (branch `milestone-2`): as M2-2's After, plus Pops's unstaged ` M Sylantro/Sylantro/Info.plist` and ` M Sylantro/Sylantro/Sylantro.entitlements`, and Claude's doc edits (` M` on `02`, `05`, `13`; `MM` on `14`). **After:** the same, plus `?? Sylantro/Sylantro/Capture/` and `?? Sylantro/SylantroTests/Capture/`; `RecipeEditor.swift` is inside the already untracked `Sylantro/Sylantro/Store/`. This row is in `14`'s unstaged changes. **Git:** `git status --short` (×2), `git branch --list`, `git diff --stat`, `git diff -- Sylantro/Docs/00_DECISION_LEDGER.md Sylantro/Docs/00A_STUDIO_CONVENTIONS.md Sylantro/Docs/00B_SYLANTRO_GUARDRAILS.md Sylantro/Docs/02_ARCHITECTURE.md Sylantro/Docs/05_IMAGE_STORAGE_DESIGN.md Sylantro/Docs/13_SCREENS.md` (the docs' changes since M2-2), `git diff -- Sylantro/Sylantro/Sylantro.entitlements Sylantro/Sylantro/Info.plist` (Step 0). **Notes:** (a) Three small error enums, one in each file, are not named by the task but are needed to throw: `PhotoFilesError` (`fileExists`, `encodingFailed`), `RecipeEditorError` (`recipeNotFound`, `recipeUnreadable`: `appendPages` won't re-hydrate a recipe whose data can't be read) and `CaptureRecorderError.noPages`. (b) `write` encodes into memory (`NSMutableData`), then writes with `.withoutOverwriting` inside the coordinated write, so a file that appears after the existence check is still never overwritten. The bytes are transient and never reach a model (SLT-053). (c) `write` doesn't create `root`; `live()` does. That is why test 8's file-as-root fails at the write. (d) The rollback also covers `addPages` when `appendPages` throws (recipe not found), so its inserted pages and photos are undone while their files are kept. `startSession` also rolls back if its save fails. (e) `availability`: when a file is present but its iCloud status isn't current, it asks iCloud to download and returns `.downloading`. A legacy `.<name>.icloud` placeholder is also asked for. If iCloud refuses the request, the result is `.missing`, or `.available` when the file is there. (f) Neither `saveCapture` nor `addPages` checks that the session id exists; the task doesn't ask. (g) `PhotoFiles.live()` is not called anywhere yet (M2-4). (h) Test 6 tells capture order by pixel size: the 40 × 60 page is first. (i) The tests each remove their own temporary folder. (j) For Claude: §0 still says "page originals as full-resolution HEIC plus a cropped copy", which MT-7 (one `pageCropped` per scanned page) now refines. I built MT-7, the newer ruling. |
| M2-2 check | 22 Nov 2026 | **Pops: passed** | Done-when 6 on Pops's iPhone 18 Pro: the schema push logged "Development schema initialized"; CloudKit Console (Development) shows `CD_PhotoModel`, `CD_RecipeModel`, `CD_ScanSessionModel` and `CD_SourcePageModel`. No image field: `CD_PhotoModel`'s fields are its nine properties as strings, numbers and dates, plus Core Data's own. **Note:** `CD_PhotoModel` shows `CD_moveReceipt` (BYTES, with a `_ckAsset` twin). That is not Sylantro's: Core Data's CloudKit mirroring adds `CD_moveReceipt` to every record type it creates, to track a record moved between stores or zones. It holds Core Data's small bookkeeping record, never image data, so it is within SLT-053. The `_ckAsset` twins on string fields (`CD_fileName_ckAsset`, `CD_kindRaw_ckAsset`) are likewise Core Data's, used only if a string grows too large for the record. The M2-2 row's statement that `CD_PhotoModel` has no bytes field missed `CD_moveReceipt`. Flag set back to `false` (Pops). |
| M2-2 | 22 Nov 2026 | **complete** (clause 6 is Pops's, not yet done) | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 76 tests in 14 suites passed after 0.056 seconds."; `** TEST SUCCEEDED **` (68 before + 8). **Clauses:** ✅ 1 `Sylantro/Store/SylantroSchemaV1.swift` holds the `VersionedSchema` (`.init(1, 0, 0)`) with the four nested `@Model final class`es, as in the table. Every property is defaulted, each has an empty `init()`, and none has `.unique`, `.externalStorage` or a relationship. It also holds the four file-scope typealiases and `SylantroMigrationPlan` (one schema, no stages). `ScanSessionModel+Domain.swift`, `SourcePageModel+Domain.swift`, `RecipeModel+Domain.swift` and `PhotoModel+Domain.swift` hold `hydrate(from:)` and `toDomain()`. `RecipeModel.toDomain()` returns nil when `recipeData` is missing or unreadable, logged at error level with the id and byte count only. `App/StoreRecovery/` holds `StoreState.swift`, `StoreOpener.swift` and `StoreSetAside.swift`, and `Views/Recovery/` holds `StoreRecoveryView.swift`. `SylantroApp.syncedModels` is `SylantroSchemaV1.models`; the configuration is `ModelConfiguration("Sylantro", schema: Schema(syncedModels), cloudKitDatabase: .private(cloudKitContainerID))`, opened with `SylantroMigrationPlan`; the schema push runs under `#if DEBUG` when `runSchemaExercise` (still `false`). `@State private var store: StoreState` is set in `init`, and the body shows `RootView().modelContainer(container)` or `StoreRecoveryView`. `Item.swift` is deleted, and `SylantroApp` has no `fatalError`; a grep of `App/` finds none. The recovery screen shows S-30, S-31, Try Again (S-33), Start Fresh (S-34), and a plain `.alert` with S-35, S-36 and S-37 (Start Fresh `.destructive`, Cancel `.cancel`). Details (S-38) is a `DisclosureGroup` with the error in `.footnote`, selectable. **S-32 is not shown.** All copy is verbatim from `13` §6. ✅ 2 the 8 tests pass: `@Suite("Model twins")` 1 to 5 and `@Suite("Store set aside")` 6 to 8, named as written. ✅ 3 builds and passes on the pinned destination with 76 tests. The only warnings are the existing appintentsmetadataprocessor "Metadata extraction skipped" (×2), so there are no new warnings. ✅ 4 no other file changed except this row; `02` §8 already lists the new folders (Claude's). ✅ 5 git status before and after is below. ⚠️ 6 Pops's device check is not done; the agent doesn't do it. Steps, on his iPhone 18 Pro (SLT-017), signed into iCloud: (i) run a Debug build and confirm it opens to the empty library, not the recovery screen. (ii) Set `AppConfig.DebugCloudKit.runSchemaExercise` to `true`, run once in Debug, and look for "initializeDevelopment: Development schema initialized" in the console (category CloudKit). (iii) In CloudKit Console, `iCloud.com.syzygysoftwerksllc.Sylantro`, Development, check that the record types `CD_ScanSessionModel`, `CD_SourcePageModel`, `CD_RecipeModel` and `CD_PhotoModel` exist. None should have an image field: the only bytes fields are `CD_ocrWordsData` and `CD_recipeData`, and `CD_PhotoModel` has none. Each of the two may also show a `_ckAsset` twin (`CD_recipeData_ckAsset`), which Core Data+CloudKit adds for every binary attribute and uses when the JSON is large; it holds the same JSON, not an image. (iv) Set the flag back to `false`, then rebuild and relaunch to confirm the library opens. **Files:** new: `Sylantro/Store/SylantroSchemaV1.swift`, `ScanSessionModel+Domain.swift`, `SourcePageModel+Domain.swift`, `RecipeModel+Domain.swift`, `PhotoModel+Domain.swift`; `Sylantro/App/StoreRecovery/StoreState.swift`, `StoreOpener.swift`, `StoreSetAside.swift`; `Sylantro/Views/Recovery/StoreRecoveryView.swift`; `SylantroTests/Store/ModelTwinTests.swift`; `SylantroTests/App/StoreSetAsideTests.swift`. Changed: `Sylantro/App/SylantroApp.swift`. Deleted: `Sylantro/Item.swift`. And this row. **Fixes:** none needed. **Git status before** (branch `milestone-2`): Pops's M2-1 files staged (`A` the 9 `Domain/Capture/` files and `CaptureJSONTests.swift`, `M` `Recipe.swift` and `RecipeJSONTests.swift`); unstaged ` M` on `Docs/02_ARCHITECTURE.md`, `05_IMAGE_STORAGE_DESIGN.md`, `13_SCREENS.md`, and `MM` on `Docs/14_MILESTONE_2_CAPTURE.md` (Claude's doc edits). **After:** the same, plus ` M Sylantro/App/SylantroApp.swift`, ` D Sylantro/Item.swift`, and `??` for `Sylantro/App/StoreRecovery/`, `Sylantro/Store/`, `Sylantro/Views/Recovery/`, `SylantroTests/App/` and `SylantroTests/Store/`; this row is in `14`'s unstaged changes. **Git:** `git status --short` (×3), `git branch --list`, `git log --oneline -3`, `git diff --stat`, `git diff -- Sylantro/Docs/02_ARCHITECTURE.md Sylantro/Docs/05_IMAGE_STORAGE_DESIGN.md Sylantro/Docs/13_SCREENS.md` (to see the docs' changes since M2-1). **Notes:** (a) `StoreState` has one helper, `static func opening() -> StoreState`, so `init`, Try Again and Start Fresh share one `do`/`catch` around `StoreOpener.open()`; the error's description is `String(describing: error)`. (b) `StoreOpener` exposes `configuration` and `storeURL` (`configuration.url`, `Application Support/Sylantro.store`), which Start Fresh needs. (c) The task names no time zone for the folder's `yyyy-MM-dd HHmmss`, so it uses the device's current zone, `en_US_POSIX`, Gregorian; test 6 builds 09:30:00 on 22 Nov 2026 in the same zone. (d) For review: Set Aside moves only the three files the task names. If Core Data's CloudKit mirroring keeps a `.Sylantro_SUPPORT` folder beside the store, it is left in place, untouched. (e) If a move fails partway, the files already moved stay in the dated folder, nothing is deleted, and the screen shows the new error. (f) Test 5 also checks the four entity names, and it checks that the `Data` properties it finds are *exactly* the two, so it can't pass by never matching. (g) The set-aside tests each remove their own temporary folder at the end (`defer`). That is never the store; noted against `00B` §2's delete rule. (h) The test host on the simulator has no iCloud account, and the store still opened ("store opened: Sylantro.store"); CoreData+CloudKit logged `CKAccountStatusNoAccount`, as expected. (i) The template's old `default.store` on any device that ran an earlier build is left in place, untouched and unused. (j) The screen's layout wasn't specified: title in `.title2.bold()`, Try Again `.borderedProminent`, Start Fresh `.bordered` with the destructive role, both full width at `.large`, in a scroll view at most 560 pt wide, on the theme's background. It reads the same `@AppStorage` palette and appearance as `RootView`, applies `WindowAppearance`, `WindowTint` and the content-size range on appear, and has the text cap. A `#Preview` is written, not rendered, for Pops to look at. |
| M2-1 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 68 tests in 12 suites passed after 0.036 seconds."; `** TEST SUCCEEDED **` (60 before + 8). **Clauses:** ✅ 1 the 9 Domain files are in `Sylantro/Domain/Capture/` (`ScanSession`, `SourceKind`, `StructuringState`, `OCRWord`, `SourcePage`, `PhotoKind`, `Photo`, `PhotoEncoding`, `CaptureJSON`), each `import Foundation` only and `nonisolated`, and `SylantroTests/Domain/CaptureJSONTests.swift` exists. Each struct has an explicit memberwise `init` in the table's order with the Default column, and a hand-written `init(from:)` where only `id` (and `OCRWord.box`, which has no default) use `decode`. `SourceKind` and `StructuringState` decode a single string falling back to `.scan` and `.waiting`; `PhotoKind` is synthesized and `Photo` keeps `kindRaw`, with the computed `kind` not encoded. No type holds `Data`, `[UInt8]` or an image (SLT-053). `Recipe.swift` has `continuesOnUnscannedPage: Bool` after `sourcePageIDs`, its `init` parameter (default `false`) and its `decodeIfPresent … ?? false` line. ✅ 2 the 8 tests in `@Suite("Capture JSON")`, named as in M2-1, all pass; `RecipeJSONTests` passes with `full` setting `continuesOnUnscannedPage: true`. ✅ 3 builds and passes on the pinned destination with 68 tests. The only warnings in the log are the existing appintentsmetadataprocessor "Metadata extraction skipped" (×2), so there are no new warnings. ✅ 4 no other file changed except this row. ✅ 5 git status before and after is below. **Files:** the 9 files in `Sylantro/Domain/Capture/`, `SylantroTests/Domain/CaptureJSONTests.swift`, `Sylantro/Domain/Recipe/Recipe.swift`, `SylantroTests/Domain/RecipeJSONTests.swift` (`full` only), and this row. **Fixes:** none needed. **Git status before** (branch `milestone-2`): clean. **After:** ` M Sylantro/Docs/14_MILESTONE_2_CAPTURE.md`, ` M Sylantro/Sylantro/Domain/Recipe/Recipe.swift`, ` M Sylantro/SylantroTests/Domain/RecipeJSONTests.swift`, `?? Sylantro/Sylantro/Domain/Capture/`, `?? Sylantro/SylantroTests/Domain/CaptureJSONTests.swift`. **Git:** `git status --short` (×3), `git branch --list`. **Notes:** (a) Properties are `var`, as M1-1's. (b) `PhotoEncoding` and `CaptureJSON` are namespace enums with no cases and no conformances, as `RecipeJSON` is; the rule's enum conformances were applied to the three value enums. (c) `CaptureJSON.decode` is `decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T`; `encode` is `encode<T: Encodable>(_ value: T) throws -> Data`. (d) Test 7's nine-key check relies on `fullPhoto` setting every optional, since synthesized encoding leaves out nil optionals. (e) `RecipeJSONTests` test 3 ("a file with only an id…") was not given a line for the new property; test 8 here covers it. |

---

## 3. Open in this document

| # | Question | Proposal |
|---|---|---|
| MT-1 | The task plan (§1), including the device-only store waiting for M3 | **Ruled:** as §1. Pops, 22 Nov 2026 (decision card, "Accept the plan") |
| MT-2 | Where "continues on a page not scanned" is kept (SLT-046) | **Ruled:** a `Bool` on `Recipe`, `continuesOnUnscannedPage`. Pops, 22 Nov 2026 (decision card, "A yes/no flag on the recipe") |
| MT-3 | The App-layer type that writes and reads photo files (M2-3) | **Ruled:** `PhotoFiles`, under `Capture/` in `02` §8. Pops, 22 Nov 2026 (decision card, "PhotoFiles") |
| MT-4 | How the models link (M2-2) | **Ruled:** by ids, as the Domain types and Score It \*'s models do; no SwiftData relationships. Pops, 22 Nov 2026 (decision card, "By ids") |
| MT-5 | What `RecipeModel` stores (M2-2) | **Ruled:** the whole `Recipe` as `recipe.json`'s JSON, plus copies of title, review state and dates for sorting. Pops, 22 Nov 2026 (decision card, "The whole recipe as JSON") |
| MT-7 | What a scanned page's photo is (M2-3) | **Ruled:** VisionKit's document camera returns only its flattened, cropped page, so each scanned page keeps that one image, full resolution, as `pageCropped` (what `SourceBox` is measured on); `pageOriginal` stays for screenshots and future imports. Pops, 22 Nov 2026 (decision card, "One cropped photo per page") |
| MT-8 | Who writes the new recipe at capture (M2-3) | **Ruled:** `RecipeEditor`, introduced now with only `insertDraft` and `appendPages`, called by `CaptureRecorder` inside its one save. Pops, 22 Nov 2026 (decision card, "Yes, RecipeEditor now") |
| MT-9 | The Domain type for the page-2 check (M2-4) | **Ruled:** `UnfinishedPageCheck` in `Domain/Capture/`. Pops, 22 Nov 2026 (decision card, "UnfinishedPageCheck") |
| MT-10 | What counts as "looks unfinished" (SLT-046's three signs, made exact) | M2-4 §1: web footers set aside; "Page n of m" or a footer "n/m" with n < m; the last line ending without `.`, `!`, `?`, `:`, `)` or a quote; a word ending in `*` with no line starting with `*` **Ruled:** as written. Pops, 22 Nov 2026 (decision card, "Accept the rules") |
| MT-11 | Labels with no copy in `13` (M2-4 run 1): the viewer's close button, the ⋯ menu, the page images | **Ruled:** iOS's own labels: `Button(role: .close)`, a symbol-only `Menu`, the system's default image labels; no new strings. Pops, 22 Nov 2026 (decision card, "iOS's own labels") |
| MT-12 | Cancel in the camera while pages are pending, after Add Page from "Is there a page 2?" (M2-4 run 1) | **Ruled:** ask "Is there a page 2?" again of the pending last page; no pages lost. Pops, 22 Nov 2026 (decision card, "Ask 'Is there a page 2?' again") |
| MT-13 | The thumbnail cache (M2-4 run 1's blocker) | **Ruled:** SyLib first: `ImageCache` gains a memory-only store (task M2-4a in `14A`), which M2-4 uses. Pops, 22 Nov 2026 (decision card, "Add memory-only to SyLib first"); its API shape, `toDisk: Bool = true`, is `14A` SY-1, ruled |
| MT-6 | The recovery types' names (M2-2) | **Ruled:** `StoreOpener`, `StoreSetAside`, `StoreState` in `App/StoreRecovery/`, and `StoreRecoveryView` in `Views/Recovery/`. Pops, 22 Nov 2026 (decision card, "Accept the names") |

---

## 4. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.18 | M2-4a complete (`14A` v0.3); M2-4 ready for run 2 | `14A` §3 row; Pops, 22 Nov 2026: "m2-4a done" |
| 0.17 | M2-4 revised after run 1's blocker: MT-11 (iOS's own labels), MT-12 (Cancel re-asks), MT-13 (memory-only cache in SyLib, task M2-4a in `14A`); M2-4 waits for M2-4a | M2-4 Results row; Pops, 22 Nov 2026 (decision cards, "iOS's own labels", "Ask 'Is there a page 2?' again", "Add memory-only to SyLib first") |
| 0.16 | MT-9 ruled; M2-4 ready | Pops, 22 Nov 2026 (decision card, "UnfinishedPageCheck") |
| 0.15 | MT-10 ruled: the page-2 check's rules as written; S-18, S-19, S-28 approved in `13` | Pops, 22 Nov 2026 (decision card, "Accept the rules"); Pops, 22 Nov 2026 (decision card, "Use Save, Cancel, OK") |
| 0.14 | Task M2-4 written in full (library, camera, page-2 check, recipe, Add Page, Delete; 93 tests); MT-9 and MT-10 open; S-18 and S-19 proposed in `13` | M2-3 complete; `13` copy approved, Pops, 22 Nov 2026 |
| 0.13 | M2-3 complete, checked by Claude against its Done-when (84 tests) | M2-3 Results log; Pops, 22 Nov 2026: "m2-3 done" |
| 0.12 | MT-7 ruled (one `pageCropped` photo per scanned page) and MT-8 ruled (`RecipeEditor` now); M2-3 ready; `Info.plist`'s `NSUbiquitousContainers` added by Claude at Pops's request | Pops, 22 Nov 2026 (decision card, "One cropped photo per page"); Pops, 22 Nov 2026 (decision card, "Yes, RecipeEditor now"); Pops, 22 Nov 2026: "can you add it?" |
| 0.11 | Task M2-3 written in full (`PhotoFiles`, `RecipeEditor`'s first two calls, `CaptureRecorder`; 84 tests); MT-7 and MT-8 open | MT-3 ruled; Pops added iCloud Documents, 22 Nov 2026 (screenshot) |
| 0.10 | M2-2's Done-when 6: Pops's CloudKit check passed; `CD_moveReceipt` explained (Core Data's own field, no image data) | Pops, 22 Nov 2026: CloudKit Console screenshot |
| 0.9 | MT-3 ruled: `PhotoFiles` | Pops, 22 Nov 2026 (decision card, "PhotoFiles") |
| 0.8 | M2-2 complete in code, checked by Claude against its Done-when (76 tests); Pops's CloudKit check open | M2-2 Results log; Pops, 22 Nov 2026: "m2-2 done" |
| 0.7 | MT-6 ruled: the recovery types' names; M2-2 ready | Pops, 22 Nov 2026 (decision card, "Accept the names") |
| 0.6 | MT-5 ruled: `RecipeModel` holds the whole recipe as JSON | Pops, 22 Nov 2026 (decision card, "The whole recipe as JSON") |
| 0.5 | MT-4 ruled: models link by ids | Pops, 22 Nov 2026 (decision card, "By ids") |
| 0.4 | Task M2-2 written in full (the synced store and the recovery screen, 76 tests); MT-4 to MT-6 open | M2-1 complete; Pops, 22 Nov 2026 (decision card, "As drafted, S-32 waits for M2-5") |
| 0.3 | M2-1 complete, checked by Claude against its Done-when (68 tests) | M2-1 Results log; Pops, 22 Nov 2026: "m2-1 done" |
| 0.2 | MT-1 ruled (the six-task plan; the device-only store waits for M3) and MT-2 ruled (`Recipe.continuesOnUnscannedPage`); M2-1 ready | Pops, 22 Nov 2026 (decision card, "Accept the plan"); Pops, 22 Nov 2026 (decision card, "A yes/no flag on the recipe") |
| 0.1 | First draft: the task plan M2-1 to M2-6, M2-1 written in full, MT-1 to MT-3 open | Pops, 22 Nov 2026: "make it so" (prep Milestone 2); built on the rulings in §0 |
