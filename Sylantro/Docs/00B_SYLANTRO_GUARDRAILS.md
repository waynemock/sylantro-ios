# Sylantro — Project Guard Rails

**Project-level. Sylantro only.** Companion to `00A_STUDIO_CONVENTIONS.md`.
Version 0.3 · 21 November 2026 · Ships in every agent prompt, alongside `00A`,
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

**Toolchain.** Xcode 27 (the iOS 27 SDK). The deployment floor is iOS 26.6 (SLT-013).

1. **Build** after any code change, incrementally across multi-file edits, through
   `Sylantro.xcworkspace`.
2. **Sylantro's suite** on the pinned destination, from `PROJ/`:

   ```
   xcodebuild test -workspace Sylantro.xcworkspace -scheme Sylantro -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.6'
   ```

   The destination is the deployment floor on the smallest supported phone (SLT-004). Report the
   destination string and the run's own test total in the session summary. Redirect output to a file if it will be searched more than once,
   and do not re-run a suite just to read it differently.
3. **SyLib's suite**, when a task touches SyLib, from `LIB/`:

   ```
   xcodebuild test -scheme SyLib-Package -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.6'
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

**Pops, before Task A-1:**

1. Add `PROJ/Docs/` to the Xcode project as a folder reference in no target (SLT-005).
2. Delete `PROJ/SylantroUITests/`. It has no target, but the template's folder is still on disk
   (SLT-016).
3. Share the `Sylantro` scheme (Manage Schemes › Shared), so the command in §5 finds it.
4. Create the git repository for `REPO/`, so session start's `git status` (§4) has something to
   read.
5. Install the iOS 26.6 simulator runtime with an iPhone SE (3rd generation), the pinned
   destination (§5).

**Pops, before the mirror task:** add the iCloud Documents service to the iCloud capability for
`iCloud.com.syzygysoftwerksllc.Sylantro`, and the `NSUbiquitousContainers` entry that makes the
Sylantro folder visible in iCloud Drive (`02` §5.4). An agent never changes the entitlements (§2).

**Already in the project** (Pops, 21 Nov 2026), so no task adds them: SyLib as a local package
(`../../sylib-swift`) with `SyLibCloud`, `SyLibCore` and `SyLibUI` on the app target; the CloudKit
and push entitlements, naming `iCloud.com.syzygysoftwerksllc.Sylantro`; the remote-notification
background mode; `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD`; the studio's concurrency settings.

### Task A-1 · Sylantro · A local-only template store

**Inputs:** `00A`, `00B`, `00_DECISION_LEDGER.md`, `SylantroApp.swift`

**Deliverable:** the template store kept off CloudKit, and the suite run once.

*Why:* `Sylantro.entitlements` already turns on CloudKit and names
`iCloud.com.syzygysoftwerksllc.Sylantro`, and SwiftData's default configuration syncs with the
first container the entitlements name. The template `Item` has a non-optional `timestamp` with no
default, which CloudKit refuses; Score It \* trapped on its first launch the same way (SLT-014).
The test target is already at the floor (`"26.6"` for both targets), so no build setting changes.

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
| | | | |

---

## 9. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.3 | §5: the pinned destination is the iPhone SE (3rd generation) at iOS 26.6 | SLT-004 (Pops, 21 Nov 2026) |
| 0.2 | §5 and Task A-1: the floor is iOS 26.6 | SLT-013 (Pops, 21 Nov 2026) |
| 0.1 | First version, from SyJong's `00B` v1.27 and Score It \*'s v1.9: the shared rails kept, the game rails left out, and Sylantro's own added (never wipe the store, on-device only, the verbatim line, the schema check, personal data out of git) | SLT-006 (Pops, 21 Nov 2026) |
