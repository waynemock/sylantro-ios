# Sylantro — Decision Ledger

*One row per locked design decision, always showing the **current** ruling. Sylantro's documents
are rewritten in place (`00A` §1); this ledger is where a reversal survives. This file is HEAD.*

**Version 0.30** · 21 November 2026 · Companion to all numbered Sylantro documents

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
| SLT-003 | **Claude writes the specifications and edits documents directly in `PROJ/Docs/`; the Xcode agent builds code from them; Pops checks each task.** **Claude never writes or edits Sylantro's source or project files, whatever the request's wording;** the one exception is asset-catalog content (images and their `Contents.json`), which Claude may place after asking Pops first; a request for app code becomes a task for the Xcode agent. *(The app shell, `00B` Task A-2, was written by Claude in error on 21 Nov 2026; Pops kept it.)* The agent works only from Sylantro's own documents: Claude reads the sibling projects during design and writes into `PROJ/Docs/` every decision, value and piece of code a task needs, so no task points the agent at another project (`00A` §3, §12). **Pops manages git:** the agent runs only read-only git (`00A` §9). | Pops's standing rule → SIA-003, JONG-003 pattern → Pops, 21 Nov 2026: Claude wrote Task A-2's shell in error → Pops, 21 Nov 2026: "you are not suppose to write code… the Xcode agent does that. dont delete it, but dont do it again." → Pops, 21 Nov 2026: "you can do this one, these kinds of changes are ok for you to make, but do ask first." (assets, asked first) |
| SLT-004 | **Tests run at the deployment floor:** iPhone SE (3rd generation), iOS 26.5, through `Sylantro.xcworkspace`, pinned in `00B` §5, as in every other studio app. It runs the Domain and store tests; the camera and Foundation Models (which the SE cannot run) are checked by Pops on a device. | `00A` §7 → Pops, 21 Nov 2026: "lets use the SE, we've done that on all the other projects too" (as SIA-004, JONG-004) |
| SLT-005 | **Documents live in `PROJ/Docs/`, beside `Sylantro.xcodeproj`,** flat, as SyJong's and Score It \*'s do, added to the Xcode project as a folder reference in no target (`00A` §1). Images live in `PROJ/Docs/Images/`, named for the document they belong to; the app icon's files live in `PROJ/Docs/AppIcon/` (`07`), as SyJong's. | Pops, 21 Nov 2026: "add the docs to sylantro-ios/Sylantro/Docs"; SyJong named as the starter |
| SLT-006 | **SyJong's documents are the starter for Sylantro's, with Score It \*'s next.** Their structure, wording and rails are reused; anything game-specific is left out. | Pops, 21 Nov 2026: "syjong-ios is our latest project, so the 00* docs are likely the best starter, score-it-all-ios is the next one" |

## Identity & platform

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-010 | **The app is named Sylantro**: the display name and the product, target and scheme name. The repository is `sylantro-ios`. LetsCook was its working title. | Pops, 21 Nov 2026 |
| SLT-011 | **Identifiers are frozen:** bundle ID `com.syzygysoftwerksllc.Sylantro` (tests `…SylantroTests`), team `PXZ9H8P4AQ`, iCloud container `iCloud.com.syzygysoftwerksllc.Sylantro` (named in `Sylantro.entitlements`), App Store Apple ID **6837557052**. | `project.xcproj` and `Sylantro.entitlements` as created by Pops, read 21 Nov 2026; the Apple ID given by Pops, 21 Nov 2026 |
| SLT-012 | **iPhone and iPad; the Mac runs the iPad app ("Designed for iPad", `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD`); no native macOS target, no Mac Catalyst, no visionOS.** Native Swift. Building needs Xcode 27. Default actor isolation is `MainActor`, with approachable concurrency and member import visibility on; Swift 5 language mode. *Why no native Mac:* most of SyLibUI's and SyLibCloud's views are iOS only, and the Mac is for browsing and cooking, not scanning. | Pops, 21 Nov 2026 (decision card, "iPad app on Mac (like SydeTwo)") → `project.xcproj` as created, 21 Nov 2026 |
| SLT-013 | **The deployment floor is iOS 26.5**, for the app and the test target. Foundation Models needs iOS 26. Building still needs Xcode 27 and the iOS 27 SDK, because SyLibUI names iOS 27 symbols. *(The project was created at 27.0; Pops lowered it to 26.6, then to 26.5 so the floor has a simulator runtime.)* | `project.xcproj` as created (27.0) → Pops, 21 Nov 2026: "ok, switched to ios 26" (26.6) → Pops, 21 Nov 2026: no 26.6 simulator, "adding 26.5"; set to `"26.5"` for both targets by Claude at his request |
| SLT-014 | **Every stored property of a CloudKit-synced model is optional or has a default value**, and every relationship is optional. Until a task replaces the template store, it stays local (`cloudKitDatabase: .none`, `00B` Task A-1), so nothing reaches a CloudKit schema before the real models exist. | SIA-015, JONG-014, learned on Score It \* (29 Oct 2026) *(rec.)* |
| SLT-015 | **The CloudKit Production schema is deployed only from the real models, and is additive-only from its first deploy.** Development may be reset freely until then. The schema push is SyLibCloud's `CloudKitSchema.initializeDevelopment`, inside `#if DEBUG` behind `AppConfig.DebugCloudKit.runSchemaExercise`, which is `false` in every archive (`00B` §6). | SIA-016, SIA-284 pattern *(rec.)* |
| SLT-016 | **No UI test target.** Verification is the unit suite (Swift Testing) plus Pops's own on-device checks. The template's `SylantroUITests/` folder has no target and is Pops's to delete. | `project.xcproj` as created: one test target, `SylantroTests` → JONG-007 pattern *(rec.)* |
| SLT-017 | **Her phone is an iPhone 17 Pro**, so it runs Apple Intelligence: the spike reads and structures the test pages on it (the pinned SE runs only the unit tests, SLT-004). | Pops, 21 Nov 2026: "2-T tablespoon, t teaspoon, 12===dozen 3-iPhone 17 pro" |

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
| SLT-041 | **Scanning never waits on processing.** She waits only on capture and save, about a second a page; reading and structuring run in a background queue that fills a review inbox. The one exception is Save's quick read of the last page's bottom lines (SLT-046). | `01` §2 (Pops, 21 Nov 2026) |
| SLT-042 | **Nothing is guessed silently.** Every ingredient keeps its verbatim line; a structuring response that does not match the schema is retried, never saved; low-confidence fields are flagged in review. | `01` §2 (Pops, 21 Nov 2026) |
| SLT-043 | **A scan session starts from the "Let's cook." scan button.** | Design draft, 21 Nov 2026 |
| SLT-044 | **A page scanned on a device without Apple Intelligence is still saved and read**, and is structured when it syncs to a capable device. | `01` §3.4 (Pops, 21 Nov 2026) |
| SLT-045 | **One capture is one recipe.** She taps "Let's cook.", photographs that recipe's page or pages, and taps Save; everything in the capture becomes one recipe, and the camera reopens for the next. Sylantro never guesses which pages belong together. A forgotten page is added later with Add page; two recipes on one page are split in review. The capture's pages are read and structured in the background (SLT-041). | Pops, 21 Nov 2026: "I feel like we import one recipe at a time instead of trying to guess which pages goes with what recipe" → "Sure." → `01` §2, `10` |
| SLT-046 | **Save asks "Is there a page 2?" only when the capture's last page looks unfinished:** it ends mid-sentence, says "Page 1 of 2" (or any "Page n of m" with n < m), or has a footnote asterisk with no footnote. To tell, Save runs a fast text read of the last page's bottom lines only: the one exception to SLT-041, kept that narrow, its time measured in the spike. If she says no, the recipe is saved with a "continues on a page not scanned" warning, fixed later with Add page (SLT-045). | Pops, 21 Nov 2026: "We should prompt for hey is there a page two when they try to save." → Pops, 21 Nov 2026 (decision card, "Only when the page looks unfinished") → `01` §2, `10` TS-3 |
| SLT-047 | **A page with several recipes: she picks which to save.** When structuring finds more than one titled recipe in a capture, review lists them and she saves one, some or all; each saved one is its own recipe, sharing the page photo (pages and recipes are many-to-many). A recipe cut off at the foot is offered with a "continues on a page not scanned" warning and Add page. This refines SLT-045's "split in review"; one capture is still one recipe unless the page holds several. | Pops, 21 Nov 2026 (decision card, "She picks which to save") → `01` §2, `10` TS-13 |
| SLT-048 | **`T` is tablespoon, `t` is teaspoon:** case decides, in the ingredient-line parser (`06` M1-2's case-sensitive spellings) and in structuring. When Vision is unsure of the case, the unit is flagged for review, never guessed. | Pops, 21 Nov 2026: "2-T tablespoon, t teaspoon, 12===dozen 3-iPhone 17 pro" → `06` M1-2, `10` TS-9 |
| SLT-049 | **"dozen" and "a dozen" are 12** in the ingredient-line parser. | Pops, 21 Nov 2026: "2-T tablespoon, t teaspoon, 12===dozen 3-iPhone 17 pro" → `06` M1-2 |

## Ingredient lines

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-070 | **`S/P`, `s/p` and `S&P` mean salt and pepper, to taste.** | Pops, 21 Nov 2026: "S/p salt and pepper to taste" → `10` TS-8 |
| SLT-071 | **One line holding several ingredients is split into separate ingredients**, each keeping the shared verbatim line and any shared quantity ("Paprika, cumin, s/p" is four: paprika, cumin, salt, pepper). Done in structuring; M1-2's parser does not split. | Pops, 21 Nov 2026 (decision card, "Split into separate ingredients") → `10` TS-8 |

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
| SLT-062 | **Attribution is stored in parts:** author, publisher (site or magazine), show, episode, source URL, printed date, issue date and copyright line, each optional text, plus free text for anything else ("From Aunt May"). "Page n of m" is not stored. The type is `Attribution`, named after the existing `attribution` property. | Pops, 21 Nov 2026 (decision card, "Separate parts") → `01` §4, `06` M1-1, `10` TS-4 |
| SLT-063 | **Printed nutrition facts are kept as printed text** (`printedNutrition`) and shown in review. Sylantro's own nutrition (`03`) may check its protein figure against them, never replace it with them. | Pops, 21 Nov 2026 (decision card, "Keep as printed text") → `01` §4, `06` M1-1, `10` TS-6 |
| SLT-064 | **A printed Equipment list is its own optional list** (`equipment`, a list of strings), shown in its own section. | Pops, 21 Nov 2026 (decision card, "Its own equipment list") → `01` §4, `06` M1-1, `10` TS-7 |
| SLT-065 | **Handwritten additions are real ingredients or steps, marked:** each is placed where it belongs and carries `isHandwritten`, shown in review in a different style; one whose place is unclear goes last in its list, flagged. | Pops, 21 Nov 2026 (decision card, "Real ingredients, marked") → `01` §4, `06` M1-1, `10` TS-14 |
| SLT-066 | **Handwriting that can't be read is called out, never guessed or dropped.** An ingredient or step that can't be read keeps its place, is marked `isUnreadable`, and carries the `sourceBox` of where it is on the page; unreadable writing with no place in the recipe (a margin note) is kept as an area on the recipe (`unreadableAreas`). Whether the recipe view shows the cropped piece of the photo in place is open (`10` TS-15). | Pops, 21 Nov 2026: "Handwritten that cannot be decoded should be called out and maybe inlined as an image in the recipe view." → `01` §3.3, §4, `06` M1-1, `10` TS-15 |

## Architecture

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-080 | **Score It \* is the starter template for the app; SydeTwo is the reference for the store and background work; Syderal for a model-first first milestone.** | Pops, 21 Nov 2026 ("score it all is the best starter framework"), with Claude's comparison → `02` |
| SLT-081 | **Layers are Screens, App, Domain and SyLib; dependencies point down only. Nothing under `Domain/` imports SwiftUI, SwiftData, UIKit, Vision, VisionKit or FoundationModels.** | Score It \*'s `13` §2 → `02` §2 *(rec.)* |
| SLT-082 | **Every write to the synced store goes through one writer** (`02` §5.2). | SIA-186, JONG pattern → `02` §5.2 *(rec.)* |
| SLT-083 | **New ground stays in Sylantro first.** The iCloud Drive mirror, on-device text reading and Foundation Models structuring move into SyLib only when a second app needs them (`00A` §0). | Survey, 21 Nov 2026 *(rec.)* |
| SLT-085 | **The App Color defaults to Forest and Appearance to System.** Both are this device's `@AppStorage` (`SettingsKey.appPalette`, `.colorScheme`); Settings offers every SyLib palette and System, Light and Dark, as Score It \* does. *Why:* green suits a cilantro app, and a kitchen app is used in daylight, so it follows the system rather than Score It \*'s always-dark default. | Pops, 21 Nov 2026 (decision card, "Go: Forest, System appearance") |
| SLT-086 | **The app shell is Score It \*'s, minus its game pieces** (`00B` Task A-2): `App/` holds `SylantroApp`, `AppConfig` and `App/Settings/` (`SettingsKey`, `AppPalette`); `Views/Root/` holds `RootView` (the split view, theme, Appearance, window tint, AX2 cap, in-app web links, `CloudAccountStatus`, `AppUpdateState`), `Sheet` (the one sheet presenter) and the text cap; `Views/Library/` the library and its empty detail; `Views/Settings/` Settings (Appearance, App Color, iCloud). The library's toolbar is the iCloud status button and ⋯ with Update Available (badged), Settings (⌘,), About and App Store. Left out: feel, sound, haptics, Keep Screen On, celebrations, the TV board and External Display, dice, players and teams, import and export, per-screen palettes. The `Views/` folder is `02`'s Screens layer. | Pops, 21 Nov 2026: "I want the app's main structure to match score-it-all-ios, including the App Color, App Update Checker, logging, AppConfig…", "About, App Store, Settings in the menu"; plan approved on the decision card |
| SLT-087 | **About's copy** (in `RootView`): tagline "Your recipe binder, in your pocket."; description "Sylantro turns your binder of printed recipes into a cookbook you can search. Tap Let's cook., photograph a page, and keep going. Sylantro reads each page right on your device and lays out the title, ingredients and steps for you to check. Every original photo is kept, your recipes sync through iCloud to your iPhone, iPad and Mac, and a plain copy of each one is saved in Files, so your recipes always stay yours." It describes the app as designed, so it is revisited before release if a feature it names (the mirror in Files, iCloud sync) is not yet built. | Pops, 21 Nov 2026: "write the copy for the about view, we can always update it later"; Claude's draft |
| SLT-084 | **SyLib is a local package** (`../../sylib-swift`); the app links `SyLibCore`, `SyLibUI` and `SyLibCloud` today. `SyLibCache` is added when thumbnails are built. | `project.xcproj` as created by Pops, 21 Nov 2026 |

## Sharing

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-100 | **The MVP shares one recipe at a time, as a file.** From a recipe, the share sheet sends a Sylantro recipe file (the recipe's JSON with its page photos); another Sylantro user opens it and it is imported as a new recipe in their own library. It needs no server and no CloudKit work: it travels by AirDrop, Messages or Mail like any file. The design is `04_SHARING_DESIGN.md`. | Pops, 21 Nov 2026: "Send a recipe for mvp. Park shared db for later. No public given the issues." |
| SLT-101 | **A shared database (a family binder through CloudKit sharing) is parked for later**, not designed or built for the MVP. When it is revisited, verify first what SwiftData's CloudKit sync supports on iOS 26: it has historically synced only the private database, so a shared binder may need Core Data's `NSPersistentCloudKitContainer` or CloudKit directly. | Pops, 21 Nov 2026: "Send a recipe for mvp. Park shared db for later. No public given the issues."; the SwiftData caveat from the design conversation, to verify |
| SLT-102 | **No public database.** Recipes are never published for strangers. *Why:* moderation, abuse and copyright of other people's recipes, and the App Review burden of user-generated content. | Pops, 21 Nov 2026: "Send a recipe for mvp. Park shared db for later. No public given the issues." |
| SLT-103 | **An imported recipe she already has is skipped when it is clearly the same, and she is asked when it might be.** Clearly the same: the file names a source recipe she already holds (sent from her own library, or imported before) and its title, yield, ingredients and steps are identical; the import is skipped with a short note. Possibly the same: a matching title or similar ingredients, as ingestion's duplicate check (`01` §2; `04` §4); she chooses Keep Both, Replace or Skip. Nothing is merged or replaced without her choice. | Pops, 21 Nov 2026: "Dedup of clear otherwise ask the user what to do" |

## App icon

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-110 | **The app icon is one cilantro sprig, the family's one-object formula:** upright and centered, a crown of three rounded leaflets and one either side on a slender stem, about 85% of the canvas tall, lit from the top left as SyFive's die, nothing outside the corner rounding. Recorded in `07` (AI-1, AI-4). | Pops, 21 Nov 2026: "the sprig on dark forest looks best to me" → `07` v0.3; Pops, 21 Nov 2026 (decision card, "Lock; Claude places the PNGs") |
| SLT-111 | **The leaf is flat-leaf cilantro:** broad leaflets with soft rounded lobes and pale veins, never pointed or fingered (AI-2). | `07` *(rec.)*; the render as chosen → Pops, 21 Nov 2026 (decision card, "Lock; Claude places the PNGs") |
| SLT-112 | **The icon's colors: Forest leaves on a dark Forest field after SyJong's**, delivered at about `#032B1E` around the sprig and `#002219` at the corners (asked as `#113724` / `#08291D`; accepted as rendered), the leaves clearly brighter than the field. It shares SyJong's green field and is told apart by its shape (AI-3). | Pops, 21 Nov 2026: "use a similar bg color as we did for syjong"; "looks great" → Pops, 21 Nov 2026 (decision card, "Lock; Claude places the PNGs") |
| SLT-113 | **Appearances:** `SylantroAppIcon.png` in the any and dark slots, `SylantroAppIconTinted.png` (the master's luminance in gray, opaque, made by Claude) in the tinted slot; the Mac slots left empty; Icon Composer not used for now (AI-5). Placed in `AppIcon.appiconset` by Claude at Pops's choice, 21 Nov 2026. | `07` *(rec.)*, as JONG-173 → Pops, 21 Nov 2026 (decision card, "Lock; Claude places the PNGs") |
| SLT-114 | **Made with ChatGPT's image generation,** from Claude's code-drawn draft attached as the layout and color reference, with SyFive's lighting; changes to a chosen image are asked of ChatGPT (a follow-up, or a fresh generation from an example), not made in code (AI-6). | Pops, 21 Nov 2026: "we use chatgpt for it" → JONG-174 pattern |
| SLT-115 | **About's icon at full resolution:** a second copy of `SylantroAppIcon.png` in `Assets.xcassets/AppIconFull.imageset`, which SyLib's `Bundle.icon` loads first; replaced with the icon whenever it changes. Placed by Claude at Pops's go-ahead, 21 Nov 2026; the test that About's icon is at least 600 pixels across is the Xcode agent's (`00B` Task A-4). | JONG-281 pattern *(rec.)* → Pops, 21 Nov 2026 (decision card, "Lock; Claude places the PNGs"): "AppIconFull is still an agent task" → Pops, 21 Nov 2026: "you can do this one, these kinds of changes are ok for you to make, but do ask first." |

## Apple News & web import

*SLT-120 to SLT-129 are reserved for `08_APPLE_NEWS_IMPORT.md`'s rulings.*

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-120 | **Apple News recipes come in link first, with screenshots as the fallback.** Sharing a recipe from Apple News sends its link; Sylantro fetches that one shared page (and the `apple.news` page that leads to it) and reads its schema.org recipe data. Nothing else is fetched, no third-party service is used, and no cookies or identifiers are sent. A page that can't be read asks her for screenshots, which go through the binder pipeline. This is Sylantro's only network use for content; extraction stays on device (SLT-040). *Why:* Apple News shares only a link and has no export. The link gives exact text in one tap, and screenshots cover a paywalled page. The design is `08`. | Pops, 21 Nov 2026 (decision card, "Link first, screenshots fallback") |

## Meals

*SLT-130 to SLT-139 are reserved for `09_MEALS.md`'s rulings. None filed yet.*

## Implementation plan

| ID | Current ruling | Source → chain |
|---|---|---|
| SLT-090 | **Milestone 1 is an accuracy spike and a tested Domain layer.** 15 to 20 real binder pages run through on-device extraction and are scored field by field; in parallel the Domain layer (recipe types, ingredient-line parser) is built and tested before any screen. | Pops, 21 Nov 2026 → Syderal pattern, `01` §7 |
| SLT-091 | **The Domain type names are accepted:** `Recipe`, `Yield`, `Times`, `IngredientGroup`, `Ingredient`, `Quantity`, `UnitRef`, `Step`, `Extraction`, `ReviewState` and `IngredientLineParser` (`02` §3), with `SourceBox`, `CanonicalUnit`, `RecipeJSON` and `ParsedLine` (`06` §0). Their shapes are `06`'s Tasks M1-1 and M1-2. The rest of `02` stays a draft. | Pops, 21 Nov 2026 (decision card, "Accept as written") |
| SLT-092 | **The spike's real pages and their answer key live outside git**, in `~/GIT/Syzygy/sylantro-testpages/` beside the repository; `10_ACCURACY_TEST_SET.md` holds only the method, the rubric, the hard cases and made-up examples, naming pages by ID (TP-01 to TP-18). | `00B` §2 → Pops, 21 Nov 2026 (decision card, "Folder beside the repo, outside git") |

---

## Open decisions

| Question | Where it is answered |
|---|---|
| Roughly how many binder pages there are, and how many are handwritten | Pops, before the spike |
| The accuracy test set's proposals: page noise, alternate methods, titles as printed; whether unreadable handwriting shows as a cropped image in the recipe view | `10` §5, TS-5, TS-10, TS-11, TS-15 (Pops) |
| Whether her clinic or dietitian uses a specific phenylalanine food list | Pops, before nutrition |
| The iCloud Documents capability and `NSUbiquitousContainers` for the mirror (an entitlements change, `00B` §2) | Pops, before the mirror task |
| How a recipe is restored from the mirror, and whether the recovery screen offers it | `02` §5.3 |
| The library's "Recipes" title and "Choose a recipe" placeholder (drafts in the code) | Pops |
| Sharing's open details: the file's format and extension, anything for people without Sylantro, what Replace keeps, a file from a newer app (SLT-100, SLT-103) | `04` §8, SH-1 to SH-6 (Pops) |
| The names of the App-layer types `02` proposes (`RecipeEditor`, `CaptureRecorder`, `ExtractionQueue`, `MirrorWriter`) | `02`, at acceptance |
| Nutrition's food data source: USDA SR Legacy now, a clinic list layered on top later *(proposed)* | `03` §3.2, N-1 (Pops) |
| The bundled food file's format: sorted-key JSON in memory *(proposed)*, SQLite, or a read-only SwiftData store | `03` §4, N-2 (Pops) |
| The phenylalanine estimate when a food has none: 50 mg per g protein, always flagged *(proposed)*, food-group multipliers, or the clinic's figures | `03` §8, N-3 (Pops, with the clinic) |
| Whether on-device Foundation Models ranks food matches | `03` §5.1, N-4 (from the spike) |
| How a quantity range ("2 to 3 cups") is counted: midpoint or high end | `03` §6, N-5 (Pops) |
| Phe shown in mg or exchanges, whose exchange size, and the rounding of protein and phe | `03` §13, N-6 and N-7 (Pops, with the clinic) |
| The nutrition caveat's wording and placement, and whether the clinic reviews the method before release | `03` §1, N-8 and N-10 (Pops) |
| A phenylalanine warning on recipes containing aspartame *(proposed)* | `03` §8, N-9 (Pops) |
| Dish photos, a `PhotoModel` for every photo, HEIC sizes, device-only thumbnails, JPEG copies in the mirror, dish photos in a shared file, and iCloud use shown in Settings *(proposed)* | `05` §9, P-1 to P-7 and IS-1, IS-2 (Pops) |
| Whether photos sync as CloudKit assets or as costlier bytes in the record | `05` §7, measured in the spike; IS-3 |
| Apple News import (the way in is SLT-120): any website or Apple News only; when; what stands in for the original; the schema's web source and address; unreadable pages; a spike first | `08` §9, NI-2 to NI-7 (Pops) |
| Meals (a meal made of recipes, like Thanksgiving): whether to take it forward and how far; meal, tag or collection; sections; a deleted recipe in a meal; which extensions (reuse, shopping list, PKU totals, timeline) and when; the writer; the mirror | `09` §5, ML-1 to ML-8 (Pops) |

---

## Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.30 | SLT-066: unreadable handwriting is called out, marked and located; the inline image is open as TS-15 | Pops, 21 Nov 2026: "Handwritten that cannot be decoded should be called out and maybe inlined as an image in the recipe view." |
| 0.29 | SLT-062 to SLT-065: attribution in parts, printed nutrition kept as text, an equipment list, handwritten additions marked (`10` TS-4, TS-6, TS-7, TS-14 closed) | Pops, 21 Nov 2026 (decision cards: "Separate parts", "Keep as printed text", "Its own equipment list", "Real ingredients, marked") |
| 0.28 | SLT-071: one line with several ingredients is split (`10` TS-8 closed); SLT-070 trimmed to its meaning | Pops, 21 Nov 2026 (decision card, "Split into separate ingredients") |
| 0.27 | SLT-070: S/P means salt and pepper, to taste; a new "Ingredient lines" heading, since the Ingestion tens are full | Pops, 21 Nov 2026: "S/p salt and pepper to taste" |
| 0.26 | SLT-017: her phone is an iPhone 17 Pro (the open question closed); SLT-048: `T` tablespoon, `t` teaspoon (`10` TS-9 closed); SLT-049: dozen is 12 | Pops, 21 Nov 2026: "2-T tablespoon, t teaspoon, 12===dozen 3-iPhone 17 pro" |
| 0.25 | SLT-047: a page with several recipes, she picks which to save; `10`'s TS-13 closed | Pops, 21 Nov 2026 (decision card, "She picks which to save") |
| 0.24 | Open decision for `10`'s proposals updated: TS-12 done (handwritten pages added), TS-13 (a page with several recipes) and TS-14 (handwritten additions) proposed | Pops, 21 Nov 2026: added TP-19 to TP-25 |
| 0.23 | SLT-046: Save asks for a page 2 only when the last page looks unfinished, by a quick read of its bottom lines; SLT-041 notes that one exception; `10`'s TS-3 closed | Pops, 21 Nov 2026 (decision card, "Only when the page looks unfinished") |
| 0.22 | SLT-045: one capture is one recipe; `10`'s TS-1 and TS-2 closed by it | Pops, 21 Nov 2026: "I feel like we import one recipe at a time instead of trying to guess which pages goes with what recipe" → "Sure." |
| 0.21 | SLT-092: the spike's real pages and answer key live outside git; `10`'s proposals TS-1 to TS-12 listed as open | Pops, 21 Nov 2026 (decision card, "Folder beside the repo, outside git") |
| 0.20 | Meals heading added, SLT-130 to SLT-139 reserved for `09`; its open decisions listed; no rulings filed | Pops, 21 Nov 2026: "Here's another feature idea to jot down. Put together a meal made up of recipes on the book." |
| 0.19 | SLT-120: Apple News import is link first, with screenshots as the fallback; fetching only the shared page is allowed | Pops, 21 Nov 2026 (decision card) |
| 0.18 | Apple News & web import heading added, SLT-120 to SLT-129 reserved for `08`; its open decisions listed; no rulings filed | Pops, 21 Nov 2026: "start a new design doc for this idea" |
| 0.17 | SLT-003: Claude may place asset-catalog content, asking first. SLT-115: `AppIconFull` placed by Claude; the test stays the agent's | Pops, 21 Nov 2026: "you can do this one, these kinds of changes are ok for you to make, but do ask first." |
| 0.16 | SLT-110 to SLT-115: the app icon locked (the Sprig on dark Forest) and placed; that open decision closed | Pops, 21 Nov 2026 (decision card, "Lock; Claude places the PNGs") |
| 0.15 | App icon heading added, SLT-110 to SLT-115 reserved for `07`; its open decisions listed | Pops, 21 Nov 2026: "I want to design the app icon next" |
| 0.14 | SLT-091: the Domain type names accepted; that open decision closed | Pops, 21 Nov 2026 |
| 0.13 | Open decision added: `02` §3's Domain names and `06`'s four, before Milestone 1's Domain tasks | `06` v0.1 (21 Nov 2026) |
| 0.12 | Sharing and photos now point at `04` and `05` | Pops, 21 Nov 2026: "Write up docs for sharing and image storage" |
| 0.11 | SLT-103: duplicate imports skipped when clearly the same, otherwise she chooses; that open decision closed | Pops, 21 Nov 2026 |
| 0.10 | Open decisions: photos and image storage, proposed in `01` §5.7 | Pops, 21 Nov 2026: "Make it so" |
| 0.9 | Open decisions added from `03_NUTRITION_DESIGN.md` (draft, not accepted); no rulings filed | Pops, 21 Nov 2026: "Start a write up for this." |
| 0.8 | SLT-100 to SLT-102: share one recipe as a file for the MVP; a shared database parked; no public database | Pops, 21 Nov 2026 |
| 0.7 | SLT-003 restored and tightened: Claude never writes source; Task A-2 noted as written in error and kept | Pops, 21 Nov 2026 |
| 0.6 | SLT-087: About's copy, drafted by Claude at Pops's request; its open decision closed | Pops, 21 Nov 2026 |
| 0.5 | SLT-003: Claude edits source when Pops asks in that message. SLT-085 (App Color Forest, Appearance System) and SLT-086 (the app shell from Score It \*) added; About's copy opened | Pops, 21 Nov 2026 (Task A-2) |
| 0.4 | SLT-004, SLT-013: the floor and the pinned destination are iOS 26.5 | Pops, 21 Nov 2026: no iOS 26.6 simulator exists to install |
| 0.3 | SLT-004: the pinned destination is the iPhone SE (3rd generation) at iOS 26.6; its open decision closed | Pops, 21 Nov 2026 |
| 0.2 | SLT-013: the floor is iOS 26.6; its open decision closed | Pops lowered the project's floor, 21 Nov 2026 |
| 0.1 | Seeded from the design conversation of 21 November 2026 and the project as Pops created it | The project starts with its documents (`00A` §11) |
