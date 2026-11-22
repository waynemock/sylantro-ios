# Sylantro — Milestone 2: Capture and Storage

**A Syzygy Softwerks task document · her pages photographed, saved, synced and copied to Files,
before anything is read**
Version 0.2 · 22 November 2026 · **Draft.** §1's task plan is ruled (MT-1); **Task M2-1 is ready to
run** (MT-2 ruled). M2-2 onward are outlines, each
written in full against what was built before it, when its gates (§1) are cleared.
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

**Status: ready** (MT-1 and MT-2 ruled, 22 Nov 2026).

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

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| — | | | |

---

## 3. Open in this document

| # | Question | Proposal |
|---|---|---|
| MT-1 | The task plan (§1), including the device-only store waiting for M3 | **Ruled:** as §1. Pops, 22 Nov 2026 (decision card, "Accept the plan") |
| MT-2 | Where "continues on a page not scanned" is kept (SLT-046) | **Ruled:** a `Bool` on `Recipe`, `continuesOnUnscannedPage`. Pops, 22 Nov 2026 (decision card, "A yes/no flag on the recipe") |
| MT-3 | The App-layer type that writes and reads photo files (M2-3) | `PhotoFiles` *(rec.)*; `02` §8 gains it under `Capture/` |

---

## 4. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.2 | MT-1 ruled (the six-task plan; the device-only store waits for M3) and MT-2 ruled (`Recipe.continuesOnUnscannedPage`); M2-1 ready | Pops, 22 Nov 2026 (decision card, "Accept the plan"); Pops, 22 Nov 2026 (decision card, "A yes/no flag on the recipe") |
| 0.1 | First draft: the task plan M2-1 to M2-6, M2-1 written in full, MT-1 to MT-3 open | Pops, 22 Nov 2026: "make it so" (prep Milestone 2); built on the rulings in §0 |
