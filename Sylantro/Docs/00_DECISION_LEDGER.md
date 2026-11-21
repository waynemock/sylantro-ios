# Sylantro — Decision Ledger

*One row per locked design decision, always showing the **current** ruling. Sylantro's documents
are rewritten in place (`00A` §1); this ledger is where a reversal survives. This file is HEAD.*

**Version 0.3** · 21 November 2026 · Companion to all numbered Sylantro documents

---

## How this file works

- **Rows are append-only; IDs are permanent.** Never renumber, never delete. A reversed decision
  has its row rewritten to the current ruling, with the source chain extended. The ledger is the
  only place a reversal survives, because every other document is rewritten in place (`00A` §1).
- **IDs are `SLT-nnn`** (Sylantro), grouped by tens per heading; gaps are deliberate. They are
  distinct from SyJong's `JONG-`, Score It \*'s `SIA-`, SyFive's `D-`, Syderal's `SYD-`, Sydoku's
  `DOKU-`, ScoreIt's `SIL-`, SyDice's `SDC-`, Syzygies' `SYZ-`, SyFLUX's `SFX-`, SyWord's `SYW-`,
  SydeTwo's `S2-`, SeedStorm's `SST-` and BizzyBaby's `BZB-` series.
- **Precedence:** newest ruling wins. Where a document and this ledger disagree, that is a stop
  condition (`00A` §4).
- **Scope guard:** design decisions only. Implementation status lives in the code and the task
  documents, never here.
- **Operational rule:** this file ships in **every** Xcode-agent prompt, with `00A` (studio,
  canonical) and `00B` (Sylantro).
- **Rulings a document makes are filed here by Claude at that document's close-out**, not by the
  tasks that implement them. Until then they live in the document and are listed under Open
  decisions below.
- `(rec.)` marks a ruling that entered as Claude's recommendation and was accepted rather than
  explicitly directed: same force, noted for the record.
- Rows dated 21 Nov 2026 were decided in the design conversation that produced `01`, before any
  numbered document existed (its working title was LetsCook); their source is that conversation.

---

## Governance

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-001 | **This ledger is HEAD.** Sylantro's documents follow `00A` §1 as written: rewritten in place, each with a version and a decision log. | `00B` §0 *(rec.)* |
| SLT-002 | **`00A_STUDIO_CONVENTIONS.md` is canonical for how sessions run; `00B_SYLANTRO_GUARDRAILS.md` holds Sylantro's own rails.** Project documents cite them rather than restate them. Sylantro carries `00A` v1.15, verbatim (copied from SyWords, the newest copy; it merges SyJong's and SyFive's v1.14s). | `00A` §11 → `00B` §7 |
| SLT-003 | **Claude writes the specifications and edits documents directly in `PROJ/Docs/`; the Xcode agent builds code from them; Pops checks each task.** Claude does not edit Sylantro's source. The agent works only from Sylantro's own documents: Claude reads the sibling projects during design and writes into `PROJ/Docs/` every decision, value and piece of code a task needs, so no task points the agent at another project (`00A` §3, §12). **Pops manages git:** the agent runs only read-only git (`00A` §9). | Pops's standing rule → SIA-003, JONG-003 pattern |
| SLT-004 | **Tests run at the deployment floor:** iPhone SE (3rd generation), iOS 26.6, through `Sylantro.xcworkspace`, pinned in `00B` §5, as in every other studio app. It runs the Domain and store tests; the camera and Foundation Models (which the SE cannot run) are checked by Pops on a device. | `00A` §7 → Pops, 21 Nov 2026: "lets use the SE, we've done that on all the other projects too" (as SIA-004, JONG-004) |
| SLT-005 | **Documents live in `PROJ/Docs/`, beside `Sylantro.xcodeproj`,** flat, as SyJong's and Score It \*'s do, added to the Xcode project as a folder reference in no target (`00A` §1). Images live in `PROJ/Docs/Images/`, named for the document they belong to. | Pops, 21 Nov 2026: "add the docs to sylantro-ios/Sylantro/Docs"; SyJong named as the starter |
| SLT-006 | **SyJong's documents are the starter for Sylantro's, with Score It \*'s next.** Their structure, wording and rails are reused; anything game-specific is left out. | Pops, 21 Nov 2026: "syjong-ios is our latest project, so the 00* docs are likely the best starter, score-it-all-ios is the next one" |

## Identity & platform

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-010 | **The app is named Sylantro**: the display name and the product, target and scheme name. The repository is `sylantro-ios`. LetsCook was its working title. | Pops, 21 Nov 2026 |
| SLT-011 | **Identifiers are frozen:** bundle ID `com.syzygysoftwerksllc.Sylantro` (tests `…SylantroTests`), team `PXZ9H8P4AQ`, iCloud container `iCloud.com.syzygysoftwerksllc.Sylantro` (named in `Sylantro.entitlements`), App Store Apple ID **6837557052**. | `project.xcproj` and `Sylantro.entitlements` as created by Pops, read 21 Nov 2026; the Apple ID given by Pops, 21 Nov 2026 |
| SLT-012 | **iPhone and iPad; the Mac runs the iPad app ("Designed for iPad", `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD`); no native macOS target, no Mac Catalyst, no visionOS.** Native Swift. Building needs Xcode 27. Default actor isolation is `MainActor`, with approachable concurrency and member import visibility on; Swift 5 language mode. *Why no native Mac:* most of SyLibUI's and SyLibCloud's views are iOS only, and the Mac is for browsing and cooking, not scanning. | Pops, 21 Nov 2026 (decision card, "iPad app on Mac (like SydeTwo)") → `project.xcproj` as created, 21 Nov 2026 |
| SLT-013 | **The deployment floor is iOS 26.6**, for the app and the test target. Foundation Models needs iOS 26. Building still needs Xcode 27 and the iOS 27 SDK, because SyLibUI names iOS 27 symbols. *(The project was created at 27.0; Pops lowered it.)* | `project.xcproj` as created (27.0) → Pops, 21 Nov 2026: "ok, switched to ios 26" (`project.xcproj` reads `"26.6"` for both targets) |
| SLT-014 | **Every stored property of a CloudKit-synced model is optional or has a default value**, and every relationship is optional. Until a task replaces the template store, it stays local (`cloudKitDatabase: .none`, `00B` Task A-1), so nothing reaches a CloudKit schema before the real models exist. | SIA-015, JONG-014, learned on Score It \* (29 Oct 2026) *(rec.)* |
| SLT-015 | **The CloudKit Production schema is deployed only from the real models, and is additive-only from its first deploy.** Development may be reset freely until then. The schema push is SyLibCloud's `CloudKitSchema.initializeDevelopment`, inside `#if DEBUG` behind `AppConfig.DebugCloudKit.runSchemaExercise`, which is `false` in every archive (`00B` §6). | SIA-016, SIA-284 pattern *(rec.)* |
| SLT-016 | **No UI test target.** Verification is the unit suite (Swift Testing) plus Pops's own on-device checks. The template's `SylantroUITests/` folder has no target and is Pops's to delete. | `project.xcproj` as created: one test target, `SylantroTests` → JONG-007 pattern *(rec.)* |

## Product scope

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-020 | **Sylantro turns a binder of printed recipes into structured recipes**, one page at a time, fast. Its first user is Pops's partner, on iPhone. Nutrition analysis comes later and must be PKU friendly. | Pops, 21 Nov 2026 |
| SLT-021 | **The first priority is the camera ingestion engine** (`01`): scan, save, read, structure, review. | Pops, 21 Nov 2026 |
| SLT-022 | **Nutrition tracks both protein and phenylalanine per serving.** Ingestion leaves slots for it so it needs no migration (`01` §6). | Pops, 21 Nov 2026 |

## Data ownership & durability

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-030 | **Her data outlives the app.** The original page photo is never thrown away, and an open-format copy of every recipe lives outside the app. *Why:* she lost a previous recipe app's data in an iPhone upgrade. | Pops, 21 Nov 2026 |
| SLT-031 | **Never delete or wipe the store.** When the container will not open, the app shows a recovery screen that keeps the data (`02` §5.3). SydeTwo's fallback, which deletes `default.store`, is never copied; Score It \*'s `fatalError` is not enough either. | Survey of the studio apps, 21 Nov 2026 *(rec.)* → `01` §5.4 |
| SLT-032 | **The mirror works with iCloud off.** With no iCloud account the mirror is written to a Sylantro folder under On My iPhone in Files, and `ICloudInfoSheet`'s wording says that copy is lost with the phone. | `01` §5.3 *(rec.)* |

## Ingestion

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-040 | **Extraction is on-device only.** Apple's Vision reads the page; Apple's Foundation Models structures the text into Sylantro's schema with guided generation. No cloud model, no API key, no per-page cost; nothing leaves her devices. A cloud engine was offered and declined; `Extraction.engine` stays in the schema so the question can be reopened only if Pops asks. | Pops, 21 Nov 2026 (decision card) |
| SLT-041 | **Scanning never waits on processing.** She waits only on capture and save, about a second a page; reading and structuring run in a background queue that fills a review inbox. | `01` §2 (Pops, 21 Nov 2026) |
| SLT-042 | **Nothing is guessed silently.** Every ingredient keeps its verbatim line; a structuring response that does not match the schema is retried, never saved; low-confidence fields are flagged in review. | `01` §2 (Pops, 21 Nov 2026) |
| SLT-043 | **A scan session starts from the "Let's cook." scan button.** | Design draft, 21 Nov 2026 |
| SLT-044 | **A page scanned on a device without Apple Intelligence is still saved and read**, and is structured when it syncs to a capable device. | `01` §3.4 (Pops, 21 Nov 2026) |

## Storage & sync

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-050 | **SwiftData on the CloudKit private database, plus an automatic open-format mirror.** After every save the app writes `recipe.json`, `recipe.md` and the original page photos into a Sylantro folder in her iCloud Drive. | Pops, 21 Nov 2026 (decision card) |
| SLT-051 | **Two stores** *(rec.)*: a synced store for recipes, pages and scan sessions, and a device-only store for the extraction queue and device state, as SydeTwo's `syncedModels` and `SydeTwoLocal` do. | `02` §5.1 |
| SLT-052 | **The mirror is written, never read back as the source of truth.** The database is the source of truth; the mirror is the copy that survives it. Restoring from the mirror is a recovery feature, not a sync path. | `01` §5.3 *(rec.)* |

## Schema

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-060 | **What was on the paper is kept apart from what was understood.** `SourcePage` is the immutable record of the paper; `Recipe` is the structured reading, so a better extractor can re-read the same photos without a re-scan. Pages and recipes are many-to-many. | `01` §4 (Pops, 21 Nov 2026) |
| SLT-061 | **Value types in `Domain/`, `@Model` twins in the store** with `hydrate(from:)` and `toDomain()`, a `VersionedSchema` from V1, and nested data (ingredient groups, steps, OCR words) as sorted-key JSON `Data` on its model, never separate models. The same JSON is what `recipe.json` holds. | SyLibScoringData's pattern (`ScoringSchemaV3`, `GameModel.optionsData`) *(rec.)* |

## Architecture

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-080 | **Score It \* is the starter template for the app; SydeTwo is the reference for the store and background work; Syderal for a model-first first milestone.** | Pops, 21 Nov 2026 ("score it all is the best starter framework"), with Claude's comparison → `02` |
| SLT-081 | **Layers are Screens, App, Domain and SyLib; dependencies point down only. Nothing under `Domain/` imports SwiftUI, SwiftData, UIKit, Vision, VisionKit or FoundationModels.** | Score It \*'s `13` §2 → `02` §2 *(rec.)* |
| SLT-082 | **Every write to the synced store goes through one writer** (`02` §5.2). | SIA-186, JONG pattern → `02` §5.2 *(rec.)* |
| SLT-083 | **New ground stays in Sylantro first.** The iCloud Drive mirror, on-device text reading and Foundation Models structuring move into SyLib only when a second app needs them (`00A` §0). | Survey, 21 Nov 2026 *(rec.)* |
| SLT-084 | **SyLib is a local package** (`../../sylib-swift`); the app links `SyLibCore`, `SyLibUI` and `SyLibCloud` today. `SyLibCache` is added when thumbnails are built. | `project.xcproj` as created by Pops, 21 Nov 2026 |

## Implementation plan

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-090 | **Milestone 1 is an accuracy spike and a tested Domain layer.** 15 to 20 real binder pages run through on-device extraction and are scored field by field; in parallel the Domain layer (recipe types, ingredient-line parser) is built and tested before any screen. | Pops, 21 Nov 2026 → Syderal pattern, `01` §7 |

---

## Open decisions

| Question | Where it is answered |
|---|---|
| Which iPhone she has; it must support Apple Intelligence (iPhone 15 Pro or newer) | Pops |
| Roughly how many binder pages there are, and how many are handwritten | Pops, before the spike |
| Whether her clinic or dietitian uses a specific phenylalanine food list | Pops, before nutrition |
| The iCloud Documents capability and `NSUbiquitousContainers` for the mirror (an entitlements change, `00B` §2) | Pops, before the mirror task |
| How a recipe is restored from the mirror, and whether the recovery screen offers it | `02` §5.3 |
| The names of the App-layer types `02` proposes (`RecipeEditor`, `CaptureRecorder`, `ExtractionQueue`, `MirrorWriter`) | `02`, at acceptance |

---

## Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.3 | SLT-004: the pinned destination is the iPhone SE (3rd generation) at iOS 26.6; its open decision closed | Pops, 21 Nov 2026 |
| 0.2 | SLT-013: the floor is iOS 26.6; its open decision closed | Pops lowered the project's floor, 21 Nov 2026 |
| 0.1 | Seeded from the design conversation of 21 November 2026 and the project as Pops created it | The project starts with its documents (`00A` §11) |
