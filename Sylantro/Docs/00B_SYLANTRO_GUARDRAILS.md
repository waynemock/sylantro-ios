# Sylantro — Project Guard Rails

**Project-level. Sylantro only.** Companion to `00A_STUDIO_CONVENTIONS.md`.
Version 0.10 · 21 November 2026 · Ships in every agent prompt, alongside `00A`,
`00_DECISION_LEDGER.md` and the task's own documents.

---

## 0. What this is

`00A` holds the studio's conventions. It is identical in every project and is canonical: this
document does not restate it. `00B` holds what only Sylantro has: its stop conditions and
prohibitions, its build and test commands, its pre-archive checklist, and its first task.

**What Sylantro is.** A recipe app that turns a binder of printed recipes into structured
recipes, one camera page at a time, for Pops's partner on iPhone (SLT-020). Reading and
structuring happen on the device (SLT-040). **Her data outlives the app** (SLT-030): the page
photo is never thrown away, an open-format copy of every recipe lives in Files, and the store is
never wiped (SLT-031). Nutrition, protein and phenylalanine per serving, comes later (SLT-022).

**Authority, in order:**

1. `00_DECISION_LEDGER.md` is HEAD for every design ruling (SLT-001).
2. `00A` governs how any agent session runs.
3. `00B` governs what is specific to Sylantro.
4. The task's design document governs the task.

Where two of them seem to disagree, that is a stop condition (`00A` §4). Do not prefer either.

**`02_ARCHITECTURE.md` is the architecture contract once Pops accepts it.** Until then it is a
draft, and no app code is written from it except Task A-1 below.

**How `00B` grows.** As `00A` §0 says: a lesson from Sylantro goes into its ledger first, and into
`00B` once it is a standing rule for Sylantro's sessions. When another project needs the same
rule, it is promoted to `00A` in project-neutral terms, and this document cites it instead.

**Paths.** A path with no prefix (`SylantroApp.swift`) is in the source folder,
`sylantro-ios/Sylantro/Sylantro/`. `PROJ/` is `sylantro-ios/Sylantro/`, which holds
`Sylantro.xcodeproj`, `Sylantro.xcworkspace` and `Docs/`. `REPO/` is the repository root,
`sylantro-ios/`. `LIB/` is the SyLib package root, `sylib-swift/`, reached as `../../sylib-swift`
from `PROJ/`.

**The project file is Xcode 27's JSON format**, `PROJ/Sylantro.xcodeproj/project.xcproj`, not the
older `project.pbxproj`. Build settings are keys in each target's `"build-settings"` object. A
task that names a build setting names it there.

---

## 1. Exceptions to `00A`

None. Sylantro's documents follow `00A` as written. *(SyJong and Score It \* may change SyLib's
public signatures under their E-1; Sylantro has no such exception until Pops grants one.)*

---

## 2. Stop conditions (Sylantro)

These are in addition to `00A` §4. Halt and ask; do not resolve inline.

| Condition | Why |
|---|---|
| App code no task names, or structure `02_ARCHITECTURE.md` doesn't specify | The structure is designed upstream (§0) |
| **Any code path that deletes, truncates, overwrites or moves aside the store's files**, or deletes a `SourcePage`'s original photo, other than a task that names it | Her data outlives the app (SLT-030, SLT-031) |
| **A store that fails to open handled by anything but `02` §5.3's recovery screen**: no `fatalError`, no wipe, no silent fresh store | SLT-031 |
| A network call of any kind in the reading or structuring path, or any page image, text or recipe sent off the device | Extraction is on-device only (SLT-040) |
| A structuring result saved without passing the schema check | Nothing is guessed silently (SLT-042) |
| An ingredient saved without its verbatim line | SLT-042 |
| Reading or structuring work on the capture path, so the camera waits on it | Scanning never waits on processing (SLT-041) |
| A change to any SwiftData `@Model` that the task does not name | Once a CloudKit Production schema is deployed it is additive-only (SLT-015) |
| A synced model property that is non-optional with no default value, or a non-optional relationship | CloudKit refuses to load the store, and the app traps on launch (SLT-014) |
| Nested recipe data (ingredient groups, steps, OCR words) stored as its own `@Model` rather than as JSON `Data` | SLT-061 |
| Turning on CloudKit sync for the store (`cloudKitDatabase`), or a change to the container, entitlements or capabilities | Sync stays off until the real models exist (SLT-014); entitlements are Pops's |
| A change to the bundle ID, display name, team or signing | Each matches a registered record (SLT-011) |
| Anything under `Domain/` importing SwiftUI, SwiftData, UIKit, Vision, VisionKit or FoundationModels | SLT-081 |
| A write to the synced store from anywhere but the writer `02` §5.2 names | SLT-082 |
| A unit conversion, gram weight, nutrient value or phenylalanine estimate the task does not give | Nutrition values are specified upstream and checked with her clinic (SLT-022) |
| User-facing text the task does not give verbatim: UI copy, alerts, help, About, iCloud wording, App Store metadata | Copy is Pops's. The agent pastes it; it never writes it |
| A real binder page, its photo, its OCR text or a recipe made from it appearing anywhere git can see it, fixtures included | It is her personal data; test fixtures are made-up pages |
| A new dependency, SDK or network endpoint | None is planned beyond SyLib and Apple's frameworks |
| A SyLib edit the task does not name | `00A` §3 |
| Sylantro's or SyLib's suite total falls without a deletion the task names | A suite that silently shrinks has stopped testing something |
| The pinned test destination (§5) is unavailable, or the installed Xcode cannot build SyLib | `00A` §7. Never substitute another device, runtime or toolchain |

---

## 3. Standing prohibitions (Sylantro)

In addition to `00A`. These apply to every task, in perpetuity.

- **The rules live outside the UI.** The recipe types, the ingredient-line parser, unit
  normalization and the schema check live in `Domain/` and import none of the frameworks in §2,
  so they are tested with plain values (SLT-081).
- **The template stays until a task replaces it.** `Item.swift`, `ContentView.swift` and the store
  in `SylantroApp.swift` are left as they are until a task names their replacement, except for the
  change Task A-1 names.
- **Logging goes through SyLibCore's `AppLogger`, never `print()`.** Log no recipe text or OCR
  text above debug level.
- **Unit tests use Swift Testing** (`@Test`, `#expect`), never XCTest. Sylantro has no UI test
  target (SLT-016).
- **Build through `Sylantro.xcworkspace`**, never the bare project.
- **Previews and simulators: `00A` §3.** Previews are written, never rendered or used as a check;
  no simulator or device sessions unless Pops asks in that message. Here that also means no
  view-hierarchy dumps and no Accessibility Inspector. The camera, Vision and Foundation Models are
  checked by Pops on a device; the build and the suite on the pinned simulator (§5) are the
  session's checks.
- **One project at a time:** `00A` §3. The shared package a task may touch is SyLib, and only where
  the task names the change.
- **Edit files with the editor's own file tools**, never `sed`, `awk`, `perl`, `tee` or shell
  redirection (`>`, `>>`); an edit too large for those tools is a short `python3` script (`00A` §9).
  The terminal is otherwise for building and testing (§5), read-only `git` (`00A` §9) and read-only
  searches (`grep`, `find`, `ls`, `cat`). *Why:* Pops, 16 Nov 2026: Xcode's permission check reads a
  `sed` script's own syntax as separate commands and stops to ask about each.
- **Read files with the editor's own file tools too**: to see part of a file, the editor's read with
  its line range, or `grep -n` to find the lines. **No `sed`, `awk`, `perl`, `head` or `tail` at all,
  not even to print.** *Why:* Pops, 16 Nov 2026.

---

## 4. Session start

1. Read `00_DECISION_LEDGER.md`. It comes first because it is the only place a reversed ruling is
   visibly current.
2. Read `00A` and this document.
3. Read the task, and only the documents it names as inputs. Sylantro's documents are in
   `PROJ/Docs/`. SyLib's usage docs are in `LIB/Docs/`.
4. Run `git status --short` and record it and the branch in the session summary. Work on that
   branch as found: Pops manages git, and an agent only reads it (`00A` §9). Changes already in the
   tree are Pops's and are never a reason to stop (`00A` §9).
5. Inspect the existing tree, and extend what is there.

---

## 5. Validation (Sylantro's commands)

`00A` §7 and §8 govern, and override any agent-side memory that says otherwise. These are
Sylantro's actual commands.

**Toolchain.** Xcode 27 (the iOS 27 SDK). The deployment floor is iOS 26.5 (SLT-013).

1. **Build** after any code change, incrementally across multi-file edits, through
   `Sylantro.xcworkspace`.
2. **Sylantro's suite** on the pinned destination, from `PROJ/`:

   ```
   xcodebuild test -workspace Sylantro.xcworkspace -scheme Sylantro -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5'
   ```

   The destination is the deployment floor on the smallest supported phone (SLT-004). Report the
   destination string and the run's own test total in the session summary. Redirect output to a file if it will be searched more than once,
   and do not re-run a suite just to read it differently.
3. **SyLib's suite**, when a task touches SyLib, from `LIB/`:

   ```
   xcodebuild test -scheme SyLib-Package -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5'
   ```

   Never `swift test`: on macOS every `#if os(iOS)` suite compiles away and the run reports success
   without running it. Check the total against the previous run's, plus additions, less named
   deletions.
4. **No other app is built or tested** (`00A` §3).

**What the simulator can't check.** The document camera needs a device, and Foundation Models runs
only where Apple Intelligence is available. Tests of the Domain layer use made-up OCR text and
recorded structuring output as fixtures; anything that touches the camera or the model is a
validation row for Pops on a device.

---

## 6. Pre-archive checklist

Before any archive, TestFlight or App Store build:

- `MARKETING_VERSION` is the release version in **both** of the app target's configurations.
- **`AppConfig.DebugCloudKit.runSchemaExercise` is `false`**: the CloudKit Development schema push
  (SLT-015).
- Every other debug flag is `false` in Release.
- No real binder page, photo or recipe is in the bundle.
- CloudKit Production matches Development for `iCloud.com.syzygysoftwerksllc.Sylantro`, once sync
  is on (SLT-015).

---

## 7. Adopting `00A` and `00B`

Sylantro starts with these documents; there is nothing to remove. Claude placed them in
`PROJ/Docs/` (SLT-005).

**Pops, before Task A-1** (1 to 4 done, 21 November 2026; the folder in step 2 deleted by Claude at Pops's request, with its line in `project.xcproj` and its entry in the shared scheme):

1. Add `PROJ/Docs/` to the Xcode project as a folder reference in no target (SLT-005).
2. Delete `PROJ/SylantroUITests/`. It has no target, but the template's folder is still on disk
   (SLT-016).
3. Share the `Sylantro` scheme (Manage Schemes › Shared), so the command in §5 finds it.
4. Create the git repository for `REPO/`, so session start's `git status` (§4) has something to
   read.
5. Install the iOS 26.5 simulator runtime with an iPhone SE (3rd generation), the pinned
   destination (§5).

**Pops, before the mirror task:** add the iCloud Documents service to the iCloud capability for
`iCloud.com.syzygysoftwerksllc.Sylantro`, and the `NSUbiquitousContainers` entry that makes the
Sylantro folder visible in iCloud Drive (`02` §5.4). An agent never changes the entitlements (§2).

**Already in the project** (Pops, 21 Nov 2026), so no task adds them: SyLib as a local package
(`../../sylib-swift`) with `SyLibCloud`, `SyLibCore` and `SyLibUI` on the app target; the CloudKit
and push entitlements, naming `iCloud.com.syzygysoftwerksllc.Sylantro`; the remote-notification
background mode; `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD`; the studio's concurrency settings.

### Task A-4 · Sylantro · Test About's full-size icon

**Inputs:** `00A`, `00B`, `00_DECISION_LEDGER.md` (SLT-113, SLT-115), `Sylantro/Assets.xcassets/AppIconFull.imageset/`, and `Views/Root/RootView.swift` (where About is shown).

*Why:* About draws the app icon large, and without a full-size copy it gets the Home Screen icon, at most 180 pixels across, which looks soft (SyJong found this, JONG-281). SyLib's `AboutView` draws `AppIconView(size: 200)`, which reads `Bundle.main.iconImage`; `Bundle.icon` (`SyLibUI/Branding/Bundle+Icon.swift`) returns `UIImage(named: Bundle.fullSizeIconName)` first, and that name is exactly `AppIconFull`. So the image set must be named `AppIconFull`, in the app target's `Assets.xcassets` (the main bundle), and no SyLib or About code changes. Checked in sylib-swift by Claude, 21 Nov 2026. **Both image sets are already in place**, placed by Claude at Pops's go-ahead, 21 Nov 2026: `AppIcon.appiconset` (SLT-113) and `AppIconFull.imageset`, holding an unchanged copy of `Docs/AppIcon/SylantroAppIcon.png` and a `Contents.json` naming it as one `universal` image (SLT-115). This task adds only the test.

**Deliverable:** one test that About's icon is full size.

**Done when:**

1. A test in `SylantroTests` checks that `Bundle.main.icon` is at least 600 pixels across (its `size` × `scale`), as SyJong's `AboutIconTests` does. If it fails because the image set is missing or wrong, that is a stop condition: report it, don't fix the asset.
2. Sylantro builds through `Sylantro.xcworkspace` with no new warnings, and the suite passes on the pinned destination (§5.2); the summary reports the destination string and the test total: the total before this task plus 1. That is 6 if `06`'s Task M1-1 has not run yet (5 + 1), or 14 if it has (13 + 1); the summary says which.
3. `git status` before and after is reported (`00A` §9).
4. The session's summary is a row at the top of §8 (`00A` §6).

**Do not:** change `AppIcon.appiconset`, `AppIconFull.imageset` or their images, re-encode or resize the PNG, change About's copy (SLT-087) or layout, any build setting, `Info.plist`, the entitlements, the SyLib package, or any other document.

### Task A-2 · Sylantro · The app shell from Score It \*

**Written by Claude in error, 21 November 2026, and kept by Pops** (SLT-003: Claude never writes
source; the Xcode agent does). It includes Task A-1's configuration line. Recorded here so the
next session finds the shell named; Task A-3 is the Xcode agent's check of it.

**Inputs:** Score It \*'s `ScoreItAllApp.swift`, `Utilities/AppConfig.swift`,
`App/Settings/SettingsKey.swift`, `App/Settings/AppPalette.swift`, `Views/Root/RootView.swift`,
`Views/Root/Sheet.swift`, `Views/Root/View+TextSizeCap.swift`, `Views/Game/NoGameSelectedView.swift`,
`Views/Settings/SettingsSheet.swift`, the ⋯ menu in `Views/Games/GameListView.swift`, and
`ScoreItAllTests/Domain/AppPaletteTests.swift` and `AppTextRangeTests.swift`.

**What it made:**

- `App/SylantroApp.swift`, moved from the source folder's root: `cloudKitContainerID`,
  `appStoreURL` (id6837557052), `AppLogger.appName = "Sylantro"`, the template store with
  `cloudKitDatabase: .none` (Task A-1), and `RootView` as the window's content. The template's
  `fatalError` stays until the recovery screen's task (`02` §5.3); none is added.
- `App/AppConfig.swift`: `DebugCloudKit.runSchemaExercise = false` only.
- `App/Settings/SettingsKey.swift` (`appPalette`, `colorScheme`) and `AppPalette.swift` (Forest by
  default, SLT-085).
- `Views/Root/RootView.swift`, `Sheet.swift` (`settings`, `about`, `iCloud`),
  `View+TextSizeCap.swift`.
- `Views/Library/LibraryView.swift` (empty list, "Recipes", the iCloud button and ⋯ with Update
  Available, Settings, About, App Store) and `NoRecipeSelectedView.swift` ("Choose a recipe").
- `Views/Settings/SettingsSheet.swift`: Appearance, App Color, iCloud Sync.
- `SylantroTests/AppPaletteTests.swift` (2 tests) and `AppTextRangeTests.swift` (2 tests); the
  template's placeholder test is unchanged. The suite should total 5.
- `ContentView.swift` deleted; `RootView` replaces it. `Item.swift` is unchanged.
- No change to `project.xcproj` (its folders are synchronized), the entitlements, `Info.plist` or
  the SyLib products.

**Copy:** About's tagline and description are SLT-087's, written by Claude at Pops's request.
"Recipes" and "Choose a recipe" are drafts until Pops confirms them (`00B` §2).

### Task A-3 · Sylantro · Check the app shell

**Inputs:** `00A`, `00B` (this task and Task A-2), `00_DECISION_LEDGER.md` (SLT-085, SLT-086,
SLT-087), and the files Task A-2 lists.

**Deliverable:** the shell building, and the suite run once on the pinned destination.

**Done when:**

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings in the files
   Task A-2 lists.
2. Sylantro's suite passes on the pinned destination (§5.2), and the summary reports the
   destination string and the test total. The expected total is 5: the template's placeholder,
   `AppPaletteTests` (2) and `AppTextRangeTests` (2).
3. Any fix needed for 1 or 2 is the smallest change that compiles, confined to the files Task A-2
   lists, and each is named in the summary. A fix that would change behavior, copy, a default
   (SLT-085) or a file outside that list is a stop condition.
4. `git status` before and after is reported (`00A` §9).
5. The session's summary is a row at the top of §8 (`00A` §6).

**Do not:** change `Item.swift`, the store's configuration, the template's `fatalError`, any build
setting, the entitlements, `Info.plist`, the SyLib products, About's copy (SLT-087), or any other
document. Do not restore `ContentView.swift`.

### Task A-1 · Sylantro · A local-only template store

**Inputs:** `00A`, `00B`, `00_DECISION_LEDGER.md`, `SylantroApp.swift`

**Deliverable:** the template store kept off CloudKit, and the suite run once.

*Why:* `Sylantro.entitlements` already turns on CloudKit and names
`iCloud.com.syzygysoftwerksllc.Sylantro`, and SwiftData's default configuration syncs with the
first container the entitlements name. The template `Item` has a non-optional `timestamp` with no
default, which CloudKit refuses; Score It \* trapped on its first launch the same way (SLT-014).
The test target is already at the floor (`"26.5"` for both targets), so no build setting changes.

**Done when:**

1. `SylantroApp.swift`: the configuration line reads exactly
   `let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)`.
   Nothing else in the file changes.
2. Sylantro's suite builds and passes on the pinned destination (§5.2), and the summary reports
   the destination string and the test total. At the time of writing the target holds one
   placeholder test. Do not edit the test (`00A` §7).
3. `git status` before and after the session is reported, and **this session's own edits** are
   only to `SylantroApp.swift` and this document. Changes already in the tree at session start are
   Pops's and don't count (`00A` §9).
4. The session's summary is a row at the top of §8 (`00A` §6).

**Do not:** change any build setting, the entitlements, `Info.plist`, the SyLib products,
`Item.swift`, `ContentView.swift`, or any other document.

---

## 8. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| A-3 (re-run) | 21 Nov 2026 | **complete** | Re-run after Pops added an iPhone SE (3rd generation) simulator on iOS 26.5. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 5 tests in 3 suites passed after 0.005 seconds." (`example()`, `AppPaletteTests` 2, `AppTextRangeTests` 2); `** TEST SUCCEEDED **`. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`; all 10 of Task A-2's app files were compiled in this build (`SwiftCompile` lines for each), with no errors or warnings in them. The one warning in the build is the tool's own "appintentsmetadataprocessor: Metadata extraction skipped, no AppIntents.framework dependency found", which comes from a build step and not from a listed file; reported, not suppressed. ✅ 2 the suite passed on the pinned destination with 5 tests, as expected. ✅ 3 fixes: none needed, none made. ✅ 4 git status before and after reported (below). ✅ 5 this row. **Files:** this document only (this row). No source or project file touched. **Git status before** (branch `main`): as in the blocked row below, except that `Docs/01_INGESTION_DESIGN.md`, `02_ARCHITECTURE.md` and `README.md` are now `MM`, and `Docs/03_NUTRITION_DESIGN.md`, `04_SHARING_DESIGN.md` and `05_IMAGE_STORAGE_DESIGN.md` are untracked (`??`); those are Pops's changes from between the runs. **After:** the same as before. **Git:** `git status --short` (×3), `git branch --list`, `git diff -- Docs/00_DECISION_LEDGER.md Docs/00B_SYLANTRO_GUARDRAILS.md` (to see what changed in the docs since the blocked run: the ledger's new SLT-100 to 103 and open decisions, none of which bear on A-3). **Notes:** the test host's launch logged CoreData errors: `Failed to stat path …/Library/Application Support/default.store`, `Sandbox access to file-write-create denied`. That was the template store's first open on a new simulator, with no `Application Support` folder yet. The app went on running and every test passed, so no trap occurred. Reported for the recovery-screen task (`02` §5.3), not acted on |
| A-3 | 20 Nov 2026 | **blocked**: the pinned destination is unavailable (`00A` §7, §2) | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'` exited 70 before compiling: "Unable to find a device matching the provided destination specifier". The iOS 26.5 runtime is installed (iPad (A16), iPad Air 11/13-inch (M4), iPhone 17 Pro Max, iPhone 17e, iPhone Air at 26.5), but the only iPhone SE (3rd generation) simulator runs iOS 18.6 (id `9076DA23-…`), below the 26.5 floor. No other device or runtime substituted. **Clauses:** ⚠️ 1 build: not reached (no compile ran, so no errors or warnings observed). ⚠️ 2 suite: not run; **test total: none** (expected 5). ✅ 3 fixes: none needed or made. ✅ 4 git status before and after reported (below). ✅ 5 this row. **Files:** this document only (its §8 row; it already had staged and unstaged changes from Pops). No source file touched. **Git status before** (branch `main`): `MM Docs/00B_SYLANTRO_GUARDRAILS.md`, `MM Docs/00_DECISION_LEDGER.md`, `M  Docs/01_INGESTION_DESIGN.md`, `M  Docs/02_ARCHITECTURE.md`, `M  Docs/README.md`, `M  Sylantro.xcodeproj/project.xcproj`, `M  Sylantro.xcodeproj/xcshareddata/xcschemes/Sylantro.xcscheme`, `MM Sylantro.xcworkspace/xcuserdata/wayne.xcuserdatad/UserInterfaceState.xcuserstate`, `A` the 10 app and 2 test files Task A-2 lists, `D  Sylantro/ContentView.swift`, `D  Sylantro/SylantroApp.swift`, `D  SylantroUITests/SylantroUITests.swift` (paths relative to `PROJ/`). **After:** the same entries; this session's only edit is this row in `00B`, already `MM`. **Git:** `git rev-parse --show-toplevel`, `git branch --show-current`, `git status --short` (×2). *(`rev-parse` and `branch --show-current` are read-only but not on `00A` §9's allowed list; reported for review.)* **Blocked:** Pops to create an iPhone SE (3rd generation) simulator on the iOS 26.5 runtime (`00B` §7, step 5), then re-run Task A-3 |
| A-2 (with A-1) | 21 Nov 2026 | Written by Claude in error, kept; check is Task A-3 | The app shell from Score It \* (SLT-086), with Task A-1's `cloudKitDatabase: .none`. 12 Swift files written or moved (10 app, 2 test), `ContentView.swift` deleted, 4 tests added (5 expected). Not built: Claude's shell cannot run `xcodebuild`. About's copy added afterward (SLT-087) |

---

## 9. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.10 | Task A-4 trimmed to the test: Claude placed `AppIconFull.imageset` | Pops, 21 Nov 2026: "you can do this one, these kinds of changes are ok for you to make, but do ask first." |
| 0.9 | Task A-4 added: `AppIconFull` for About's icon, with a test | SLT-115 (Pops, 21 Nov 2026) |
| 0.8 | Task A-2 marked as written in error (SLT-003); Task A-3 added, the Xcode agent's build and suite check of the shell | Pops, 21 Nov 2026 |
| 0.7 | Task A-2: About's copy is SLT-087's | Pops, 21 Nov 2026 |
| 0.6 | Task A-2 added (the app shell, done by Claude at Pops's request) and its results row | SLT-003, SLT-086 (Pops, 21 Nov 2026) |
| 0.5 | §5 and Task A-1: the floor and the pinned destination are iOS 26.5 | SLT-013 (Pops, 21 Nov 2026) |
| 0.4 | §7: steps 1 to 4 done; `SylantroUITests/` and its two project references removed | Pops, 21 Nov 2026 |
| 0.3 | §5: the pinned destination is the iPhone SE (3rd generation) at iOS 26.6 | SLT-004 (Pops, 21 Nov 2026) |
| 0.2 | §5 and Task A-1: the floor is iOS 26.6 | SLT-013 (Pops, 21 Nov 2026) |
| 0.1 | First version, from SyJong's `00B` v1.27 and Score It \*'s v1.9: the shared rails kept, the game rails left out, and Sylantro's own added (never wipe the store, on-device only, the verbatim line, the schema check, personal data out of git) | SLT-006 (Pops, 21 Nov 2026) |
