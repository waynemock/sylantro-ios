# Sylantro — Milestone 1: The Accuracy Spike

**A Syzygy Softwerks task document · a hidden, debug-only screen that reads and structures test
pages on Pops's iPhone and exports the results for scoring**
Version 0.29 · 22 November 2026 · Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md`,
`00B_SYLANTRO_GUARDRAILS.md`, `02_ARCHITECTURE.md` §2, §4 and §8, and `06_MILESTONE_1_DOMAIN.md`'s
types and parser.

---

## 0. What this is

Milestone 1 is an accuracy spike and a tested Domain layer (SLT-090). `06` built the Domain half
(M1-1, M1-2). This document is the spike half: M1-3 builds the first real pieces of
the extraction pipeline (`02` §4) and a hidden screen to run them on the test pages (SLT-093);
M1-4 to M1-11 refine the structurer from each spike run's results; M1-12 puts the screen behind
an AppConfig flag in every build; M1-13 adds a progress section; M1-14 and M1-15 refine the structurer from runs 4 and 5.

**How the spike runs** (SLT-093, SLT-017):

1. Pops copies the test photos (`~/GIT/Syzygy/sylantro-testpages/Pages/`) to his **iPhone 18 Pro**
   by AirDrop into a folder in Files. They never enter the repository (SLT-092, `00B` §2).
2. He runs Sylantro on that phone, in any build configuration, opens Settings, and taps **Accuracy
   spike**. The row shows only while `AppConfig.AccuracySpike.isEnabled` is true (SLT-093, M1-12).
3. On the spike screen he adds one capture per recipe (one selection of that recipe's photos, as
   `10` §1 groups them), taps **Run All**, then **Export Results**, and saves the file to Files.
4. He AirDrops the results file back to the Mac, into
   `~/GIT/Syzygy/sylantro-testpages/results/`, outside git.
5. Claude scores it against the answer key (`10` §2) and writes a summary with no recipe content
   into `10` §7.

Timings are measured on an iPhone 18 Pro, a generation newer than her iPhone 17 Pro; `10` §7 notes
that her phone may be somewhat slower.

The spike saves nothing to the store, writes nothing to the mirror and changes no `@Model`. What
it builds in `Extraction/` (the reader and the structurer) is kept and reused by Milestone 3's
`ExtractionQueue`.

---

### Task M1-3 · Sylantro · The reader, the structurer and the spike screen

**Inputs:** `00`, `00A`, `00B`, `02` §2, §4 and §8, `06` (M1-1's types and M1-2's parser, both
done), `10` §1 and §2 for context, this document.

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Extraction/TextReader.swift` | App | Reads one page image with Vision |
| `Sylantro/Extraction/PageReading.swift` | App | The reader's result |
| `Sylantro/Extraction/GeneratedRecipe.swift` | App | The `@Generable` shape Foundation Models fills |
| `Sylantro/Extraction/RecipeStructurer.swift` | App | Structures a capture's text into `Recipe`s |
| `Sylantro/Extraction/Spike/SpikeReport.swift` | App | The exported results, `Codable` |
| `Sylantro/Extraction/Spike/SpikeRunner.swift` | App | Runs captures through the reader and structurer, timed |
| `Sylantro/Views/Spike/SpikeView.swift` | Screens | The hidden screen |
| `Sylantro/Views/Settings/SettingsSheet.swift` | Screens | One debug-only row added |
| `SylantroTests/Extraction/RecipeStructurerTests.swift` | Tests | The mapping, with made-up values |

`Extraction/`, `Extraction/Spike/`, `Views/Spike/` and `SylantroTests/Extraction/` are new folders,
named here (`00A` §10). The project's folders are synchronized.

Everything in `Extraction/Spike/` and `Views/Spike/`, and the Settings row, is wrapped in
`#if DEBUG … #endif` so a Release build contains none of it. `TextReader`, `PageReading`,
`GeneratedRecipe` and `RecipeStructurer` are not wrapped: they are the pipeline's own pieces.

**`PageReading`** (`nonisolated struct PageReading: Codable, Sendable, Equatable`):
`lines: [ReadLine]`, `text: String` (the lines joined with `\n`, top to bottom as Vision orders
them), `meanConfidence: Double?`, `minConfidence: Double?`. `ReadLine` (nested, same conformances):
`text: String`, `confidence: Double`, `box: CGRectCodable` where `CGRectCodable` is a nested
`x, y, width, height: Double`, normalized 0 to 1, origin top left (the same convention as
`SourceBox`, so it maps onto one later).

**`TextReader`** (`nonisolated struct TextReader: Sendable`):

- `func read(_ image: CGImage) async throws -> PageReading`: Vision's text recognition at the
  **accurate** level, language correction on, recognition language `en-US`, one observation per
  line, its top candidate's string and confidence. Vision's bottom-left boxes are flipped to top
  left.
- `func readBottom(_ image: CGImage, fraction: Double = 0.2) async throws -> PageReading`: the same
  at the **fast** level, limited to the bottom `fraction` of the page (Vision's region of
  interest). This is Save's quick read (SLT-046), timed here only; nothing decides anything from it
  in this task.
- Use the Swift Vision API (`RecognizeTextRequest`) if it compiles against the pinned SDK, else
  `VNRecognizeTextRequest`; report which.

**`GeneratedRecipe`** (`GeneratedRecipe.swift`, `import FoundationModels`): `@Generable` structs
mirroring only what the model is asked to fill. Each property carries a `@Guide` description, given
verbatim below.

`GeneratedCapture`: `recipes: [GeneratedRecipe]` — "Every separate recipe on these pages, in page
order. Usually one. A page from a magazine may hold several."

`GeneratedRecipe`:

| Property | Type | `@Guide` description (verbatim) |
|---|---|---|
| `title` | `String` | "The recipe's title exactly as printed. Empty if the pages show no title." |
| `yieldText` | `String?` | "The yield or servings exactly as printed, such as 'Serves 4' or 'Makes about 1 1/4 cups'." |
| `timesText` | `String?` | "Prep, cook and total times exactly as printed." |
| `ingredientGroups` | `[GeneratedGroup]` | "The ingredients, in printed order, grouped under their printed headings." |
| `steps` | `[GeneratedStep]` | "The method's steps in printed order, each with its words unchanged." |
| `notes` | `String?` | "Tips, notes or serving suggestions printed apart from the steps." |
| `author` | `String?` | "The person credited for the recipe, if printed." |
| `publisher` | `String?` | "The website or magazine, if printed." |
| `sourceURL` | `String?` | "The web address printed on the page, if any." |
| `equipment` | `[String]` | "Items listed under an Equipment heading, if any." |
| `printedNutrition` | `String?` | "Nutrition facts exactly as printed, if any." |

`GeneratedGroup`: `name: String?` — "The group's printed heading, such as 'For the sauce'. Empty if
none."; `lines: [GeneratedIngredient]` — "The ingredient lines under it."

`GeneratedIngredient`: `rawText: String` — "The whole ingredient line exactly as printed, with
nothing added or corrected."; `item: String?` — "The food itself, such as 'flour'."; `preparation:
String?` — "How it is prepared, such as 'sifted' or 'chopped'."; `note: String?` — "Any other note
on the line, such as 'plus more to taste'."; `isOptional: Bool` — "True only if the line says it is
optional."

`GeneratedStep`: `text: String` — "The step's words exactly as printed."; `groupName: String?` —
"The heading the step is printed under, if any."

The model is never asked for quantities or units: those come from `IngredientLineParser` on
`rawText` (`01` §3.3, SLT-048, SLT-049). The model is not asked about handwriting or unreadable
text either; `isHandwritten` and `isUnreadable` stay `false` in the spike (SLT-065, SLT-066 come
with Milestone 3).

**`RecipeStructurer`** (`nonisolated struct RecipeStructurer: Sendable`, `import FoundationModels`):

- `static var isAvailable: Bool`: `SystemLanguageModel.default.availability == .available`.
- `func structure(_ readings: [PageReading], pageIDs: [UUID]) async throws -> [Recipe]`: one
  `LanguageModelSession` per call, with these instructions verbatim:
  "You turn the text of printed recipe pages into structured recipes. Copy words exactly as they
  appear. Never add, correct or guess anything that is not in the text. Leave out web page clutter,
  advertisements, ratings, navigation links and page footers." The prompt is the pages' `text`
  joined with `\n\n--- next page ---\n\n`. It calls `respond(to:generating: GeneratedCapture.self)`
  and maps each `GeneratedRecipe` with `makeRecipe`. A thrown error (context too long, guardrail,
  decoding) is rethrown unchanged; there are no retries in the spike.
- `static func makeRecipe(from generated: GeneratedRecipe, pageIDs: [UUID]) -> Recipe`, pure:
  - `title` as given; `yield = Yield(rawText: yieldText)` when `yieldText` is non-nil, else nil;
    `times = Times(rawText: timesText)` likewise; `notes`, `equipment`, `printedNutrition` as given.
  - `attribution = Attribution(author:, publisher:, sourceURL:)` when any of the three is non-nil,
    else nil.
  - Each `GeneratedGroup` becomes an `IngredientGroup(name:)`; each `GeneratedIngredient` becomes an
    `Ingredient` with `rawText`, `item`, `preparation`, `note`, `isOptional`, and `quantity` and
    `unit` from `IngredientLineParser.parse(rawText)`.
  - Steps get `index` 0, 1, 2 … in order, `text` and `groupName` as given.
  - `sourcePageIDs = pageIDs`, `reviewState = .needsReview`, `extraction = Extraction(modelID: nil,
    promptVersion: 1, extractedAt: nil)`.
  - Empty strings from the model are treated as nil for every optional field.

**`SpikeReport`** (`Extraction/Spike/`, `Codable`, sorted-key JSON like `RecipeJSON`, dates
`.iso8601`): `runAt: Date`, `deviceModel: String` (the hardware identifier, such as `iPhone18,1`),
`systemVersion: String`, `modelAvailable: Bool`, `captures: [SpikeCaptureResult]`.

`SpikeCaptureResult`: `fileNames: [String]` (in order), `readings: [PageReading]`, `readMillis:
[Int]` (one per page), `bottomReadMillis: Int?` (the last page's `readBottom`), `bottomText:
String?`, `structureMillis: Int?`, `recipes: [Recipe]`, `error: String?` (the error's
`String(describing:)`).

**`SpikeRunner`** (`@MainActor @Observable final class`): holds `captures` (each its file URLs and
a status), `report: SpikeReport?`. `func addCapture(_ urls: [URL])` sorts the URLs by file name
(`localizedStandardCompare`), so `TP-05` comes before `TP-06`. `func runAll() async` runs captures
one at a time, in the order added; for each: every page's `read` (timed), then the last page's
`readBottom` (timed), then, if `RecipeStructurer.isAvailable`, `structure` (timed). Times are wall
clock around each call, in whole milliseconds. Images load from the security-scoped URLs into
`CGImage` with ImageIO, upright per their orientation. A failing capture records its `error` and
the run moves on. Logging: `AppLogger(category: "Spike")`, state changes only, no page text above
debug level (`00B` §3).

**`SpikeView`** (Screens, `#if DEBUG`), copy verbatim:

| Element | Text |
|---|---|
| Navigation title | `Accuracy Spike` |
| Empty state | `Add a capture: pick the photos of one recipe's pages.` |
| Toolbar buttons | `Add Capture`, `Run All`, `Export Results`, `Clear` |
| Unavailable banner (when `RecipeStructurer.isAvailable` is false) | `Apple Intelligence isn't available on this device. Pages will be read but not structured.` |
| Row title | the capture's file names joined with ` + ` |
| Row status | `Waiting`, `Reading…`, `Structuring…`, `Done`, or `Failed: ` followed by the error |
| Row detail when done | `<n> recipe(s) · read <r> ms · structure <s> ms` with the numbers filled in; `<r>` is the total of the capture's page reads, and ` · structure <s> ms` is left out when the capture wasn't structured (Pops, in the M1-3 session) |

- **Add Capture** opens `fileImporter` for images (`.image`), multiple selection; one selection is
  one capture.
- **Run All** is disabled while running or with no captures.
- **Export Results** is enabled once a report exists; it opens `fileExporter` with the report as a
  JSON document named `spike-results-<yyyy-MM-dd-HHmm>.json`.
- **Clear** empties the captures and the report.
- No other copy, icons or styling beyond the template's list style.

**`SettingsSheet`**: one new `Section`, last in the `Form`, inside `#if DEBUG`, with no header and a
single `NavigationLink` titled `Accuracy spike` that shows `SpikeView`. Nothing else in the file
changes.

**Tests** (`SylantroTests/Extraction/RecipeStructurerTests.swift`, `@Suite("Recipe structurer
mapping")`, `@testable import Sylantro`, `import FoundationModels` only if needed to build a
`GeneratedRecipe`). Made-up values only (`00B` §2):

1. "a generated recipe maps to a recipe": a `GeneratedRecipe` with title "Test Soup", one unnamed
   group with the lines `2 cups water` and `1 T salt`, two steps, `publisher` "Example Kitchen";
   `makeRecipe` gives that title, `ingredients[0]` Q(2) cup with `rawText` "2 cups water",
   `ingredients[1]` Q(1) tablespoon with raw unit "T", steps indexed 0 and 1, attribution's
   publisher "Example Kitchen", `reviewState` `.needsReview`, and the given page IDs.
2. "empty strings become nil": `yieldText` "", `notes` "", `author` "" give `yield` nil, `notes`
   nil and `attribution` nil.
3. "a line the parser can't read keeps its words": `Salt to taste` gives quantity nil, unit nil,
   and `rawText` "Salt to taste".

**Done when:**

1. The files above exist in their folders; `Domain/` is unchanged and imports nothing new.
2. The 3 tests exist, named as above, and pass.
3. Sylantro builds in **Debug and Release** with no new warnings, and the suite passes on the pinned
   destination (`00B` §5.2). Expected total: 16 + 3 = **19**. Report the run's own total.
4. A Release build contains no spike symbol: report how you checked (for example, that
   `SpikeView` and `SpikeRunner` do not appear in the Release binary's symbols).
5. No other file changes except this document's Results log.
6. `git status` before and after, and every git command run. Do not commit.

**Pops checks on his iPhone 18 Pro** (`00B` §5): the Settings row appears in a Debug build; a
capture of two made-up pages reads, structures and exports; the exported file opens on the Mac.
Then the real run (§0).

**Do not:** write to the store, the mirror or any `@Model`; save a recipe; add retries, the
`ExtractionQueue`, `RecipeValidator` or the camera; send anything off the device (SLT-040); add
entitlements or capabilities; put a real page, its text or a result anywhere git can see it,
fixtures included; write copy not given above; render previews or run a simulator or device
session (`00B` §3).

---

### Task M1-4 · Sylantro · Structuring in parts, checked against the page (spike run 2)

**Why.** Spike run 1 (`10` §7) showed the reader is ready but one-shot structuring is not: the
method copied into the ingredients, fields filled from elsewhere, invented values, output loops
past the token limit, and refusals while a phone call had the app in the background. Pops accepted
all six fixes (SLT-140 to SLT-145). This task builds them and re-runs the spike.

**Inputs:** `00`, `00A`, `00B`, `02` §2, §3 and §4, `06` (types, parser), `10` §7 (run 1, no
recipe content), this document (§0 and M1-3 as built).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Domain/Structuring/TextMatch.swift` | Domain | The one text normalization used by the rules below |
| `Sylantro/Domain/Structuring/PageSplitter.swift` | Domain | Splits a capture's lines into sections by heading (SLT-140) |
| `Sylantro/Domain/Structuring/SplitPage.swift` | Domain | The splitter's result |
| `Sylantro/Domain/Structuring/PageRules.swift` | Domain | Yield, times, URL and "Page n of m" by rule (SLT-143) |
| `Sylantro/Domain/Structuring/RuleFields.swift` | Domain | The rules' result |
| `Sylantro/Domain/Structuring/RecipeValidator.swift` | Domain | The found-on-the-page check (SLT-142) |
| `Sylantro/Extraction/GeneratedParts.swift` | App | The `@Generable` shapes for each part |
| `Sylantro/Extraction/RecipeStructurer.swift` | App | Rewritten to structure in parts |
| `Sylantro/Extraction/TextReader.swift` | App | Language detection off (SLT-145) |
| `Sylantro/Extraction/Spike/SpikeReport.swift`, `SpikeRunner.swift` | App | New report fields; foreground-only with resume (SLT-144) |
| `Sylantro/Views/Spike/SpikeView.swift` | Screens | One new status string |
| `SylantroTests/Domain/PageSplitterTests.swift`, `PageRulesTests.swift`, `RecipeValidatorTests.swift` | Tests | Made-up lines only |
| `SylantroTests/Extraction/RecipeStructurerTests.swift` | Tests | One test added |

`Domain/Structuring/` is a new folder, named here. Domain files import `Foundation` only (SLT-081).
`GeneratedRecipe.swift` stays as it is: it is still used for a page with several recipes (below).

**`TextMatch`** (`nonisolated enum`): `static func normalize(_ text: String) -> String`: replace
the unicode fractions in `06` M1-2's table with ` n/d`; join a word broken by a hyphen at a line end
(`-` followed by a newline and a letter is removed with the newline); lowercase; replace every run
of characters other than letters, digits, `/` and `.` with one space; trim. `static func
contains(_ value: String, in text: String) -> Bool`: `normalize(text)` contains `normalize(value)`;
an empty normalized value is never contained.

**`PageSplitter`** (`nonisolated enum`), `static func split(_ pages: [[String]]) -> SplitPage`.
The input is each page's lines in reading order. A line is a **heading** when, trimmed, with one
trailing `:` removed and compared case-insensitively, it equals one of:

| Section | Headings |
|---|---|
| `ingredients` | `ingredients`, `ingredient`, `what you need`, `you will need`, `you'll need` |
| `steps` | `directions`, `instructions`, `method`, `preparation`, `steps`, `how to make it`, `procedure` |
| `notes` | `notes`, `note`, `recipe notes`, `tips`, `tip`, `cook's tip` (also with `’`) |
| `equipment` | `equipment`, `tools` |
| `nutrition` | `nutrition`, `nutrition facts`, `nutrition information` |

Lines before the first heading go to `header`; each later line goes to the section of the heading
above it (pages run on; a page break does not end a section). Heading lines themselves go nowhere.
A leading bullet (`•`, `·`, `-`, `*` followed by a space) is removed from every non-header line.
`SplitPage` (`nonisolated struct`, `Equatable`, `Sendable`): `header`, `ingredients`, `steps`,
`notes`, `equipment`, `nutrition`, all `[String]`, and `hasIngredientsAndSteps: Bool` (both headings
were found).

**`PageRules`** (`nonisolated enum`), `static func find(in lines: [String]) -> RuleFields`.
`RuleFields` (`nonisolated struct`, `Equatable`, `Sendable`, a memberwise `init` with every
parameter defaulting to `nil`): `sourceURL: String?`, `yieldText: String?`, `timesText: String?`,
`pageNumber: Int?`, `pageCount: Int?`.

- `sourceURL`: of every whitespace-separated token that starts with `http://`, `https://` or
  `www.`, the longest, with trailing `.`, `,`, `)` removed. A token that starts mid-word (such as
  `ps://`) is not a URL.
- `pageNumber`, `pageCount`: the last line containing `Page <n> of <m>` (case-insensitive).
- `yieldText`: the first line that starts, case-insensitively and after optional spaces, with
  `serves`, `makes`, `yield`, `yields` or `servings` followed by a space, `:` or a digit; the line
  as written, trimmed. If that line also holds a `|`, only the part holding the word.
- `timesText`: every line containing, case-insensitively, `prep`, `cook`, `total`, `active` or
  `hands-on`, optionally followed by ` time`, then optional `:` and spaces, then a digit; those
  lines as written, trimmed, joined with `; `. Nil if none.

**`RecipeValidator`** (`nonisolated enum`), `static func check(_ recipe: Recipe, pageText: String)
-> Recipe`: the found-on-the-page check. Using `TextMatch.contains(_, in: pageText)`:

- `title`, each ingredient group's `name`, each step's `groupName`, each `equipment` item,
  `notes`, `printedNutrition`, and `attribution`'s `author` and `publisher`: a value not found is
  removed (title becomes `""`, the others nil or dropped), and a warning added:
  `not on page: <field>` where `<field>` is `title`, `group name`, `step group`, `equipment`,
  `notes`, `printed nutrition`, `author` or `publisher`.
- Each ingredient's `rawText` and each step's `text`: kept even when not found, with the warning
  `not on page: ingredient <n>` or `not on page: step <n>` (1-based, counting across groups).
- An ingredient whose normalized `rawText` equals, or is contained in, a step's normalized `text`
  and is longer than 60 characters is removed with `ingredient <n> is a step` (the copied method).
- Warnings are appended to `extraction.warnings` (an `Extraction` is created if nil). Nothing else
  changes.

**`GeneratedParts`** (`import FoundationModels`), `@Generable`, `@Guide` descriptions verbatim:

- `GeneratedHeader`: `title: String` — "The recipe's title exactly as printed, all of its lines.
  Empty if none."; `author: String?` — "The person credited for the recipe, if printed.";
  `publisher: String?` — "The website or magazine, if printed."; `otherTitles: [String]` — "Titles
  of any other separate recipes on these pages. Usually empty."
- `GeneratedIngredientPart`: `groups: [GeneratedGroup]` (the existing type) — "The ingredient lines
  in printed order, grouped under their printed subheadings. Join a line that wraps onto the next
  line."
- `GeneratedStepPart`: `steps: [GeneratedStep]` (the existing type) — "The steps in printed order,
  each with its words unchanged."
- `GeneratedLineLabels`: `labels: [GeneratedLineLabel]` — "One label for every numbered line.";
  `GeneratedLineLabel`: `line: Int` — "The line's number."; `kind: String` with
  `@Guide(.anyOf(["header", "ingredient", "step", "note", "other"]))` and the description "What the
  line is: part of the title area, an ingredient, a step, a note, or anything else."

**`RecipeStructurer`**, rewritten. Every model call uses a new `LanguageModelSession` with M1-3's
instructions unchanged, and `GenerationOptions(sampling: .greedy, maximumResponseTokens:)`
(SLT-141) with these caps: header 300, line labels 1,200, ingredients 1,500, steps 2,000, one-shot
2,500. `structure(_ readings:pageIDs:)` returns `StructuringOutcome` (`nonisolated struct`,
`Sendable`): `recipes: [Recipe]`, `path: String` (`parts` or `oneShot`), `partMillis: [String:
Int]`, `usedLineLabels: Bool`, `partErrors: [String: String]`. The steps:

1. Lines: each reading's `lines` texts. `split = PageSplitter.split(…)`; `rules =
   PageRules.find(in: all lines)`.
2. If `!split.hasIngredientsAndSteps`: one **line-labels** call. The prompt is every line as
   `<number>: <text>`, numbered from 1 across pages. Lines labelled `ingredient`, `step`, `note`
   form those sections; `header` lines the header; `other` and unlabelled lines are dropped.
   `usedLineLabels = true`.
3. **Header** call on the header lines. If `otherTitles` is not empty, this capture holds several
   recipes (SLT-047): run M1-3's one-shot call (`GeneratedCapture`) with the one-shot cap instead,
   map with `makeRecipe`, set `path = "oneShot"`, and go to step 6.
4. **Ingredients** call on the ingredient lines, **steps** call on the step lines. A part with no
   lines is skipped. A part that throws records its error in `partErrors` and contributes nothing;
   the others go on.
5. `assemble` (below) builds the one `Recipe`. `path = "parts"`.
6. Every recipe goes through `RecipeValidator.check` with all lines joined by `\n`.

A rate-limit refusal (`LanguageModelSession.GenerationError.rateLimited`) is not caught here: it
propagates out of `structure` so the runner can wait (SLT-144). If that case does not exist in the
pinned SDK, stop and report what does.

`static func assemble(header: GeneratedHeader?, ingredients: GeneratedIngredientPart?, steps:
GeneratedStepPart?, split: SplitPage, rules: RuleFields, pageIDs: [UUID]) -> Recipe`, pure: title,
author and publisher from the header (empty strings nil); `sourceURL`, `yield = Yield(rawText:)`
and `times = Times(rawText:)` from `rules`; ingredients mapped as `makeRecipe` maps them (parser for
quantity and unit); steps indexed from 0; `notes` = `split.notes` joined by `\n` (nil if empty);
`equipment` = `split.equipment`; `printedNutrition` = `split.nutrition` joined by `\n` (nil if
empty); `extraction = Extraction(promptVersion: 2)`; `reviewState = .needsReview`. Nothing from
the model fills yield, times, URL, notes, equipment or nutrition.

**`TextReader`**: both requests set `automaticallyDetectsLanguage = false` (SLT-145), keeping
`en-US` and language correction. If the property does not exist in the pinned SDK, stop and report.

**`SpikeRunner`** (SLT-144): structuring runs only while the scene is active. The view passes
`scenePhase` changes to `func sceneBecameActive()` and `func sceneLeftActive()`. A capture whose
`structure` throws a rate-limit refusal, or that reaches structuring while the scene is not active,
gets the new status `.waitingForApp` and is not failed; `sceneBecameActive()` resumes waiting
captures in order (reading is not repeated). Each `SpikeCaptureResult` gains `path: String?`,
`partMillis: [String: Int]`, `usedLineLabels: Bool`, `partErrors: [String: String]`, `waits: Int`
(how many times it waited), and `warnings: [String]` (every recipe's `extraction.warnings`).
`structureMillis` stays the total of the structuring calls.

**`SpikeView`**: the status `.waitingForApp` shows `Waiting for Sylantro to be open`. No other copy
changes.

**Tests**, made-up lines only (`00B` §2):

`PageSplitterTests` (`@Suite("Page splitter")`):
1. "headings split the sections": `["Test Soup", "Serves 2", "Ingredients", "1 cup water", "Directions:", "Boil it.", "Notes", "Good cold."]` gives header `["Test Soup", "Serves 2"]`, ingredients `["1 cup water"]`, steps `["Boil it."]`, notes `["Good cold."]`, `hasIngredientsAndSteps` true.
2. "a section runs onto the next page": pages `[["Ingredients", "1 cup water"], ["2 cups flour", "Method", "Mix."]]` gives ingredients `["1 cup water", "2 cups flour"]`, steps `["Mix."]`.
3. "no headings leaves everything in the header": `["Test Soup", "1 cup water", "Boil it."]` gives that header, empty sections, `hasIngredientsAndSteps` false.
4. "bullets are removed and equipment and nutrition are found": `["Equipment", "• Pot", "Nutrition Facts", "100 calories"]` gives equipment `["Pot"]`, nutrition `["100 calories"]`.

`PageRulesTests` (`@Suite("Page rules")`):
5. "the longest full URL wins": lines `["https://example.com/r/1", "ps://example.com/_/print", "see www.example.com."]` give `https://example.com/r/1`.
6. "page n of m": `["12/1/24, 9:00 AM", "Page 2 of 3"]` gives 2 and 3.
7. "yield by rule": `["PREP TIME: 5 MIN | SERVES 4", "Makes about 2 cups"]` gives `SERVES 4`.
8. "times by rule": `["Prep Time: 10 mins", "Cook time 20 minutes", "Cook until done."]` gives `Prep Time: 10 mins; Cook time 20 minutes`.

`RecipeValidatorTests` (`@Suite("Recipe validator")`):
9. "a value not on the page is dropped": a recipe with title "Test Soup" and equipment `["Pot", "Wok"]` against the page text `"Test Soup\nUse a pot."` keeps the title, keeps `Pot`, drops `Wok`, and warns `not on page: equipment`.
10. "fractions and line-end hyphens still match": ingredient `1½ teaspoons salt` against the page text `"1 1/2 tea-\nspoons salt"` gets no warning.
11. "a step copied into the ingredients is removed": an ingredient whose `rawText` is a 70-character sentence that is also step 1's text is removed with `ingredient 1 is a step`.

`RecipeStructurerTests`, added:
12. "parts assemble with rule fields": `assemble` with a header titled "Test Soup", one ingredient line `2 cups water`, one step, and `RuleFields(sourceURL: "https://example.com", yieldText: "Serves 2", …)` gives that title, Q(2) cup, yield raw text `Serves 2`, attribution's `sourceURL`, and `extraction.promptVersion` 2.

**Done when:**

1. The files above exist; `Domain/Structuring/` imports `Foundation` only.
2. The 12 new tests pass, and M1-3's 3 structurer tests still pass (update them only where
   `makeRecipe`'s output is unchanged in meaning; report any change).
3. Debug and Release build with no new warnings; the suite passes on the pinned destination.
   Expected total: 19 + 12 = **31**. Report the run's own total.
4. A Release build still contains no spike code (check as in M1-3).
5. No other file changes except this document's Results log.
6. `git status` before and after, and every git command run. Do not commit.

**Pops's run 2** (on his iPhone 18 Pro, Do Not Disturb on, screen kept awake): the same 22
captures as run 1 (`10` §1), Run All, Export Results, the file to
`~/GIT/Syzygy/sylantro-testpages/results/`. Claude scores it against run 1.

**Do not:** write to the store, the mirror or any `@Model`; save a recipe; add the
`ExtractionQueue` or a background task; make any network call; add copy beyond the one status
string; let the model fill yield, times, URL, notes, equipment or nutrition; put a real page, its
text or a result anywhere git can see it; render previews or run a simulator or device session.

---

### Task M1-5 · Sylantro · Lines from the page, parts that fail safe (spike run 3)

**Why.** Spike run 2 (`10` §7) showed structuring in parts works: every capture finished, with no
loops and no refusals. But four pages lost a whole part, the model rewrote ingredient lines and
dropped their quantities, titles were right on 13 of 22, equipment and times picked up text from
elsewhere, and handwriting still came back with Cyrillic look-alike lines. Pops accepted all five
fixes (SLT-146 to SLT-150). This task builds them and re-runs the spike.

One finding from run 2 shapes the retry. All three unreadable answers ("GeneratedContent does not
contain a property …") were cut off at their last object: TP-24's 93 line labels stopped at
`{"line": 93}` with a cap of 1,200, and its header's title held the whole page. They reached
their length cap, so the retry doubles the cap.

**Inputs:** `00`, `00A`, `00B`, `02` §2 and §4, `06` (types, parser), `10` §7 (runs 1 and 2, no
recipe content), this document (§0, M1-3 and M1-4 as built).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Domain/Structuring/PageClutter.swift` | Domain | New: which lines are page clutter (SLT-149) |
| `Sylantro/Domain/Structuring/ScriptCheck.swift` | Domain | New: non-Latin letters (SLT-150) |
| `Sylantro/Domain/Structuring/HeaderArea.swift` | Domain | New: the title's candidate lines and their sizes (SLT-148) |
| `Sylantro/Domain/Structuring/PageSplitter.swift`, `SplitPage.swift` | Domain | Clutter dropped, equipment ends, an empty section is not found (SLT-147, SLT-149) |
| `Sylantro/Domain/Structuring/PageRules.swift` | Domain | Times need a label (SLT-149) |
| `Sylantro/Extraction/GeneratedParts.swift` | App | The header and ingredients answer with line numbers (SLT-146, SLT-148) |
| `Sylantro/Extraction/RecipeStructurer.swift` | App | Line numbers mapped to page lines; retry and fallback; unreadable lines (SLT-146 to SLT-150) |
| `Sylantro/Extraction/Spike/SpikeReport.swift`, `SpikeRunner.swift` | App | Three new report fields |
| `SylantroTests/Domain/PageSplitterTests.swift`, `PageRulesTests.swift` | Tests | Tests added |
| `SylantroTests/Domain/StructuringRulesTests.swift` | Tests | New: `ScriptCheck` and `HeaderArea` |
| `SylantroTests/Extraction/RecipeStructurerTests.swift` | Tests | Tests added; test 12 updated to the new `assemble` |

Domain files import `Foundation` only (SLT-081). `GeneratedRecipe.swift`, `RecipeValidator.swift`,
`TextReader.swift` and `SpikeView.swift` don't change.

**`PageClutter`** (`nonisolated enum`), `static func isClutter(_ line: String) -> Bool`. A line is
clutter when, trimmed:
- its first whitespace-separated token contains `://` or starts with `www.` (case-insensitive),
  so a broken scheme such as `ps://…` counts; or
- it holds `Page <n> of <m>` (`PageRules`'s match; make that match `static` internal to share it);
  or
- it starts with a date: 1 or 2 digits, `/`, 1 or 2 digits, `/`, 2 or 4 digits.

A web address in the middle of a sentence is not clutter.

**`ScriptCheck`** (`nonisolated enum`), `static func isLatin(_ line: String) -> Bool`: true when
every `Character` that `isLetter` has all of its unicode scalars in U+0000 to U+024F, U+0300 to
U+036F (combining marks) or U+1E00 to U+1EFF. `"1½ cups crème fraîche"` is Latin, and so is a line
with no letters.

**`HeaderArea`** (`nonisolated enum`). `HeaderLine` (`nonisolated struct`, `Equatable`,
`Sendable`): `text: String`, `size: Double`. `static func lines(_ lines: [(text: String, height:
Double)], stopAt: Int?) -> [HeaderLine]`, where `lines` is the first page's lines in reading order
with each box's height:
1. The end: `stopAt` when given (the index of the first line labelled `ingredient` or `step`),
   else the index of the first line that is a `PageSplitter` heading (make `heading(_:)` `static`
   internal), else the end of the page. At most the first 25 lines are taken.
2. If that leaves no lines, take the first 10 lines.
3. Drop clutter, non-Latin and heading lines.
4. `size` is the line's height over the median height of all of the page's lines (the whole
   `lines` input), rounded to one decimal. With no heights above 0, every size is 1.0.

**`PageSplitter`** and **`SplitPage`** (SLT-147, SLT-149):
- A clutter line goes to no section. `PageRules` still gets every line, so the URL and "Page n of
  m" are still found.
- The **equipment section ends** at the first line that, with its bullet removed, starts with
  digits followed by `.` or `)`, is longer than 40 characters, or ends with `.`. That line and the
  lines after it, up to the next heading, go to a new `SplitPage.unsectioned: [String]`.
- `hasIngredientsAndSteps` is true only when both headings were found and both sections hold at
  least one line. So a page whose headings are read before their lines (TP-03) is labelled line by
  line.

**`PageRules`**, times (SLT-149): a time word now counts only when it starts the line or follows a
character that isn't a letter, and is followed by ` time` or by `:`. The rest of the rule (then
optional spaces, then a digit) is as before. `Cook 3 to 4 hours` and `cook 2 minutes` are no
longer times; `Prep: 10 min`, `Cook Time 20 minutes` and `Hands-On: 50 mins` are. A line holding
`|` keeps only its parts that hold a time, joined with ` | `. Add `cooking` and `inactive` to the
time words. The yield rule doesn't change.

**`GeneratedParts`**, `@Guide` descriptions verbatim:
- `GeneratedHeader` (SLT-148) becomes:
  - `titleFirstLine: Int`: "The number of the title's first line. 0 if there is no title."
  - `titleLastLine: Int`: "The number of the title's last line, the same as the first for a
    one-line title. 0 if there is no title."
  - `author: String?` and `publisher: String?` as now.
  - `otherTitles: [String]?`: "Titles of any other separate recipes on these lines. Usually
    none."
- `GeneratedIngredientPart` is replaced by `GeneratedIngredientLines` (SLT-146):
  - `groups: [GeneratedLineGroup]`: "The ingredients in printed order, grouped under their printed
    subheadings."
  - `GeneratedLineGroup` has `nameLine: Int`: "The number of the group's printed subheading line,
    such as 'For the sauce'. 0 if none." It also has `items: [GeneratedLineItem]`: "The ingredients
    under it."
  - `GeneratedLineItem` has `firstLine: Int`: "The number of the ingredient's first line." It also
    has `lastLine: Int`: "The number of its last line, the same as the first unless the ingredient
    wraps onto the next line."
  - `GeneratedLineItem` keeps `item`, `preparation` and `note` with `GeneratedIngredient`'s
    descriptions, and has `isOptional: Bool?` with the description "True only if the line says it
    is optional."
- `GeneratedStepPart` and `GeneratedLineLabels` don't change.

**`RecipeStructurer`**:

1. **Lines.** Each reading's lines, with their page index. A line that fails
   `ScriptCheck.isLatin` is taken out (SLT-150): it becomes a `SourceBox(pageID:
   pageIDs[page], …)` from its box in the recipe's `unreadableAreas`, with the warning
   `unreadable line on page <p>` (1-based). The model, the splitter, the rules and the validator's
   page text never see it. Then `split` and `rules` are found as now, on the remaining lines.
2. **Line labels**, when `!split.hasIngredientsAndSteps`, as now. The cap is now `max(1_200, 16 ×
   line count + 200)`.
3. **Header** (SLT-148). `HeaderArea.lines` on page 1's remaining lines, with `stopAt` the first
   line labelled `ingredient` or `step` when labels ran. Skip the call if the area is empty. The
   prompt is `Lines from the top of the page, with each line's text size compared with the page's
   usual text (1.0):` and a newline, then each line as `<n> [size <s>]: <text>`, numbered from 1.
   The cap is 300. The title is `static func title(from header: GeneratedHeader?, area:
   [HeaderLine]) -> String`: lines `titleFirstLine` to `titleLastLine` joined with a space, or `""`
   when either is 0, out of range, or the last is before the first. If `otherTitles` is not empty,
   take the one-shot path as now.
4. **Ingredients** (SLT-146). The prompt is `The ingredient lines of a recipe, numbered:` and a
   newline, then `split.ingredients` as `<n>: <text>`. The cap is 1,500. Map the answer with
   `static func ingredientGroups(from part: GeneratedIngredientLines, lines: [String]) ->
   (groups: [IngredientGroup], warnings: [String])`:
   - Each item's `rawText` is lines `firstLine` to `lastLine`, trimmed and joined. Where a line
     ends with `-` and the next starts with a lowercase letter, the `-` is removed and the two are
     joined with no space. Otherwise they are joined with one space.
   - Quantity and unit come from `IngredientLineParser.parse(rawText)`. `item`, `preparation` and
     `note` are as now. `isOptional` is `?? false`.
   - An item whose numbers are out of range, whose last is before its first, or that spans more
     than 3 lines is skipped, with the warning `ingredient lines out of range`.
   - A group's name is line `nameLine` trimmed, with one trailing `:` removed, or nil for 0 or out
     of range. A name longer than 40 characters is not used, and gets the warning `group name too
     long`.
   - Every line that no item and no name used gets the warning `unused ingredient line <n>`.
5. **Steps**, as now.
6. **Retry and fallback** (SLT-147):
   - Any part (line labels, header, ingredients, steps or one-shot) that throws something other
     than a rate limit is asked once more, in a new session, with double its cap. The first error
     stays in `partErrors[part]`, and a second goes in `partErrors["<part> retry"]`. Its time is
     added to `partMillis[part]`. `retried` lists the part.
   - If the ingredients are still nil or `split.ingredients` was empty, the ingredients call is
     made over every remaining line of the capture, numbered across pages, and mapped against
     those lines. The steps work the same way when they are still nil or empty. Each adds the
     warning `ingredients from whole page` or `steps from whole page`, and `fallbacks` lists the
     part. A fallback is not retried.
7. **`assemble`** becomes `static func assemble(title: String, header: GeneratedHeader?,
   ingredientGroups: [IngredientGroup], steps: GeneratedStepPart?, split: SplitPage, rules:
   RuleFields, pageIDs: [UUID], unreadableAreas: [SourceBox], warnings: [String]) -> Recipe`. The
   new parameters go to the recipe's `unreadableAreas` and `extraction.warnings`, and the rest is as
   now. `extraction.promptVersion` is 3.
8. `RecipeValidator.check` as now, on the remaining lines joined by `\n`.

`StructuringOutcome` gains `retried: [String]` and `fallbacks: [String]`.

**`SpikeReport`**: `SpikeCaptureResult` gains `retried: [String]`, `fallbacks: [String]` and
`unreadableLines: Int` (the lines step 1 took out), all set by `SpikeRunner`. No copy changes.

**Tests**, made-up lines only (`00B` §2):

`PageSplitterTests`, added:

13. "clutter lines belong to no section": `["Ingredients", "1 cup water", "ps://example.com/r/1",
    "Page 1 of 2", "Directions", "Boil it.", "1/2/24, 9:00 AM"]` gives ingredients `["1 cup water"]`
    and steps `["Boil it."]`.
14. "equipment ends at a step": `["Equipment", "• Pot", "Spoon", "1. Boil the water in the pot.",
    "Ingredients", "1 cup water", "Directions", "Boil it."]` gives equipment `["Pot", "Spoon"]` and
    unsectioned `["1. Boil the water in the pot."]`.
15. "an empty section is not found": `["Ingredients", "Directions", "1 cup water", "Boil it."]`
    gives `hasIngredientsAndSteps` false.

`PageRulesTests`, added:

16. "times need a label": `["Prep: 10 min | Serves 4", "Cook 3 to 4 hours on low.", "Cook Time 20
    minutes"]` gives `Prep: 10 min; Cook Time 20 minutes`. Test 8 still passes unchanged.

`StructuringRulesTests` (`@Suite("Structuring rules")`):

17. "non-Latin letters are caught": `isLatin` is true for `2 T paprika` and `1½ cups crème
    fraîche`, and false for `2 Т рарика` (Cyrillic Т and р).
18. "the header area stops at the first heading": `[("Example Recipes", 0.01), ("Page 1 of 1",
    0.01), ("Test Soup", 0.02), ("Serves 2", 0.01), ("Ingredients", 0.012), ("1 cup water", 0.01)]`
    with `stopAt` nil gives `Example Recipes` 1.0, `Test Soup` 2.0 and `Serves 2` 1.0.

`RecipeStructurerTests`, added:

19. "ingredients come from the page's lines": lines `["For the soup", "2 cups water", "1 teaspoon
    salt, plus more to", "taste"]`, with one group (name line 1, items 2–2 and 3–4), gives the
    group name `For the soup`. The `rawText`s are `2 cups water` (Q(2) cup) and `1 teaspoon salt,
    plus more to taste`, and there are no warnings.
20. "a hyphen at a line end joins the word": lines `["1 1/2 tea-", "spoons salt"]`, item 1–2, gives
    `1 1/2 teaspoons salt`, unit teaspoon.
21. "bad line numbers are skipped": two lines, with items 5–5 and 2–1, gives no ingredients, two
    `ingredient lines out of range` warnings, and `unused ingredient line 1` and `2`.
22. "a long group name is not used": a 45-character name line gives name nil and `group name too
    long`.
23. "the title is the chosen lines": area `watercress`, `salad with beets`, `and Feta`, `Serves 4`
    with first 1 and last 3 gives `watercress salad with beets and Feta`. First 0 gives `""`, and
    first 3 with last 2 gives `""`.
24. "unreadable areas and warnings reach the recipe": `assemble` with one `SourceBox` and the
    warning `unreadable line on page 1` gives a recipe with that box in `unreadableAreas`, that
    warning, and `promptVersion` 3.

Test 12 is updated to the new `assemble` signature, with the same expectations except
`promptVersion` 3. Report the change.

**Done when:**

1. The files above exist, and `Domain/Structuring/` imports `Foundation` only.
2. The 12 new tests pass. Every earlier test passes, changed only where this task says (test 12).
   Report any other change.
3. Debug and Release build with no new warnings, and the suite passes on the pinned destination.
   Expected total: 31 + 12 = **43**. Report the run's own total.
4. A Release build still contains no spike code (check as in M1-3).
5. No other file changes except this document's Results log.
6. `git status` before and after, and every git command run. Do not commit.

**Pops's run 3** (on his iPhone 18 Pro, Do Not Disturb on, screen kept awake): Clear, then the
same 22 captures as run 1 (`10` §1), Run All, Export Results, and the file to
`~/GIT/Syzygy/sylantro-testpages/results/`. Claude scores it against runs 1 and 2.

**Do not:**
- Write to the store, the mirror or any `@Model`, or save a recipe.
- Add the `ExtractionQueue` or a background task.
- Make any network call.
- Change any copy.
- Let the model fill `rawText`, a group name, a title, yield, times, URL, notes, equipment or
  nutrition with its own words.
- Put a real page, its text or a result anywhere git can see it.
- Render previews or run a simulator or device session.

---

### Task M1-6 · Sylantro · Run 3's three fixes and a one-tap test set (spike run 3 again)

**Why.** Pops stopped spike run 3 partway (`10` §7). TP-01 and TP-03 failed with "GeneratedContent
does not contain a property 'steps'", and the failed content was M1-3's one-shot shape (title,
yield, times, then the ingredients). The one-shot path, meant only for a page with several recipes
(SLT-047), ran on single-recipe pages. M1-5 made the header's `otherTitles` optional. The answers
show the model writing the word "none" into empty fields, so `otherTitles` most likely came back
as `["none"]`, which isn't empty. The one-shot answer then copied the method into the ingredients,
reached its cap, was retried at double the cap, and failed. TP-05+06 also sat at "Waiting for
Sylantro to be open" with the app in front, because a rate limit while the scene is active waits
for the next activation (§1). Pops chose all three fixes (SLT-151 to SLT-153). The fault was in
M1-5's text, not in its build. He also asked not to add 22 captures by hand each run, and chose to
pick the test folder once (SLT-154).

**Inputs:** `00`, `00A`, `00B`, this document (M1-5 as built), `10` §7 (run 3).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Domain/Structuring/TextMatch.swift` | Domain | `isEmptyAnswer` (SLT-152) |
| `Sylantro/Extraction/GeneratedParts.swift` | App | One description changed |
| `Sylantro/Extraction/RecipeStructurer.swift` | App | `otherRecipeTitles` gates the one-shot path (SLT-151); `nonEmpty` uses `isEmptyAnswer` |
| `Sylantro/Extraction/Spike/SpikeRunner.swift`, `SpikeReport.swift` | App | A timed retry after a rate limit while in front (SLT-153); one new report field |
| `Sylantro/Extraction/Spike/TestSetGroups.swift` | App (Debug) | New: groups the test photos into captures by page ID (SLT-154) |
| `Sylantro/Views/Spike/SpikeView.swift` | Screens | One new menu item, Load Test Set |
| `SylantroTests/Domain/StructuringRulesTests.swift` | Tests | Test 25 |
| `SylantroTests/Extraction/RecipeStructurerTests.swift` | Tests | Tests 26 and 27 |
| `SylantroTests/Extraction/SpikeRunnerTests.swift` | Tests | New: tests 28 and 29 |

**`TextMatch.isEmptyAnswer(_ text: String?) -> Bool`** (SLT-152): true for nil, and for text
that, trimmed and lowercased, is empty or one of `none`, `n/a`, `na`, `null`, `nil`, `-`, `empty`,
`not specified` or `not applicable`.

**`RecipeStructurer`**:
- `nonEmpty(_:)` returns nil when `TextMatch.isEmptyAnswer` is true. Every field it maps then
  treats "none" as empty: author, publisher, an ingredient's `item`, `preparation` and `note`, and
  on the one-shot path also yield, times, notes and nutrition.
- New `static func otherRecipeTitles(_ titles: [String]?, title: String, lines: [String]) ->
  [String]` (SLT-151): the entries that aren't an empty answer, don't normalize
  (`TextMatch.normalize`) to the chosen title, and normalize to a whole line in `lines`. Duplicates
  are removed, and order is kept.
- Step 3 takes the one-shot path only when `otherRecipeTitles(header?.otherTitles, title: <the
  title from step 3>, lines: allLines)` is not empty. Nothing else in the structurer changes.

**`GeneratedParts`**: `GeneratedHeader.otherTitles` keeps its type, `[String]?`, and its
description becomes, verbatim: "Titles of any other separate recipes printed on these lines. Leave
it empty when there is only one recipe."

**`SpikeRunner`** (SLT-153): when `structure` throws a rate-limit refusal while the scene is
active, the capture keeps the status `.structuring` (no new copy), waits, and is structured again
from the start. Reading is not repeated. The waits come from `static func retryDelay(afterRefusal
count: Int) -> Duration?`, which gives `.seconds(30)` for counts 1 to 3 and nil after that. When
the delay is nil, or the scene left while it waited, the capture gets `.waitingForApp` as now.
`SpikeCaptureResult` gains `rateLimitRetries: Int`. A refusal while the scene is not active waits
for the app as now.

**Load Test Set** (SLT-154), Debug only like the rest of the spike (`#if DEBUG`):

- **`TestSetGroups`** (`nonisolated enum`), `static func captures(fileNames: [String]) ->
  [[String]]`. It keeps only names that are exactly `TP-` and two digits, a `.`, then `jpeg`, `jpg`,
  `png` or `heic` (any case). It orders them by number. The joined pairs from `10` §1 (05 and 06,
  07 and 08, 16 and 17) become one capture when both are present, in page order. Every other page
  is its own capture. The groupings use page IDs only, never page content (`00B` §2).
- **`SpikeRunner.loadTestSet(folder: URL)`**:
  - Starts security-scoped access to the folder and keeps it open until `clear()` or the next
    load.
  - Lists the folder's files and replaces `captures` with one `Capture` per group, sorted as
    `addCapture` sorts.
  - Saves a bookmark of the folder (`bookmarkData()`) in `UserDefaults` under `spikeTestSetFolder`.
- **`SpikeRunner.loadSavedTestSet() -> Bool`**:
  - Resolves that bookmark. If it's stale, it saves it again.
  - Calls `loadTestSet`, and returns false when there is no bookmark or it can't be resolved.
- **`SpikeView`** gains a menu item, `Load Test Set`, before `Add Capture`:
  - It calls `loadSavedTestSet()`. If that returns false, it shows a folder picker
    (`.fileImporter`, content type `.folder`), and the chosen folder goes to `loadTestSet`.
  - It is disabled while running.
  - No other copy changes.
- If iOS's bookmark API differs from this in the pinned SDK, stop and report.

**Tests**, made-up text only (`00B` §2):

25. `StructuringRulesTests`, "a 'none' answer is empty": `isEmptyAnswer` is true for nil, `""`,
    `"none"`, `" None "` and `"N/A"`, and false for `"nonfat milk"` and `"1 cup water"`.
26. `RecipeStructurerTests`, "other titles must be lines on the page": titles `["none", "Test
    Soup", "Side Salad", "Made-up Title", "Side Salad"]`, with title `Test Soup` and lines `["Test
    Soup", "1 cup water", "SIDE SALAD", "2 cups lettuce"]`, gives `["Side Salad"]`. Nil titles give
    `[]`.
27. `RecipeStructurerTests`, "'none' fields are nil": `ingredientGroups(from:lines:)` with an item
    whose `item` is `"none"`, `preparation` is `"None"` and `note` is `"n/a"` gives all three nil.
28. `SpikeRunnerTests` (`@Suite("Spike runner")`), "rate-limit retries are timed and limited":
    `retryDelay(afterRefusal:)` gives 30 seconds for 1, 2 and 3, and nil for 4.
29. `SpikeRunnerTests`, "the test set groups by page ID": `TestSetGroups.captures` of `["TP-06.jpeg",
    "TP-05.jpeg", "TP-01.jpeg", "TP-07.JPG", "notes.txt", "TP-01 copy.jpeg", "TP-17.jpeg"]` gives
    `[["TP-01.jpeg"], ["TP-05.jpeg", "TP-06.jpeg"], ["TP-07.JPG"], ["TP-17.jpeg"]]`.

**Done when:**

1. The files above exist or are changed, and `Domain/` imports `Foundation` only.
2. The 5 new tests pass, and every earlier test passes unchanged.
3. Debug and Release build with no new warnings, and the suite passes on the pinned destination.
   Expected total: 43 + 5 = **48**. Report the run's own total.
4. A Release build still contains no spike code (check as in M1-3).
5. No other file changes except this document's Results log.
6. `git status` before and after, and every git command run. Do not commit.

**Pops's run 3, again** (on his iPhone 18 Pro, Do Not Disturb on, screen kept awake): the first time,
tap Load Test Set and pick the folder of test photos in Files (later runs skip the picker). Check
there are 22 rows, then Run All, Export Results, and the file to
`~/GIT/Syzygy/sylantro-testpages/results/`. A row may pause for up to a minute and a half if the
model refuses; that is the timed retry. Claude scores it against runs 1 and 2.

**Do not:**
- Change the parts path, the caps or the retry and fallback (M1-5).
- Add copy beyond `Load Test Set`.
- Write to the store, the mirror or any `@Model`.
- Make any network call.
- Put a real page, its text or a result anywhere git can see it.
- Render previews or run a simulator or device session.

---

### Task M1-7 · Sylantro · The spike screen as a sheet, with its main buttons in the list

**Why.** Pops, after M1-6: the spike screen is too easy to dismiss by accident, and its toolbar is
crowded. He asked for Load Test Set and Run All as capsule buttons at the top of the list, Add
Capture moved into the menu, and a sheet that closes only from Done, after a confirmation. This
task is UI only and changes no structuring.

**Inputs:** `00A`, `00B`, this document (M1-6 as built), SyLib's `CapsuleButton`
(`sylib-swift/Sources/SyLibUI/Components/CapsuleButton.swift`).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Views/Settings/SettingsSheet.swift` | Screens | The Accuracy spike row presents a sheet instead of pushing |
| `Sylantro/Views/Spike/SpikeView.swift` | Screens | Buttons rearranged; Done with a confirmation; no swipe to dismiss |
| `Sylantro/Extraction/Spike/SpikeRunner.swift` | App | `runAll` stops between captures when its task is cancelled |

**`SettingsSheet`**: the `#if DEBUG` row keeps its label `Accuracy spike`, but it becomes a
`Button` that sets `@State isShowingSpike`. `.sheet(isPresented: $isShowingSpike)` shows
`NavigationStack { SpikeView() }`. The row's styling is unchanged.

**`SpikeView`**:
- **Top of the list:** a first row holding `CapsuleButton("Load Test Set")` and
  `CapsuleButton("Run All", style: .accent)` side by side (`HStack`), with the same actions and
  disabled states as now. Its section has no header.
- **Toolbar:**
  - `Done` (placement `.confirmationAction`).
  - A `Menu` with the system image `ellipsis.circle` (placement `.topBarLeading`). It holds
    `Add Capture`, `Export Results` and `Clear` with their current actions and disabled states.
  - No other toolbar items.
- **No swipe to dismiss:** `.interactiveDismissDisabled()`.
- **Done shows a confirmation** (`.confirmationDialog`). The title is `Close the accuracy spike?`
  and the message is `Captures and results that weren't exported are cleared. A run in progress
  stops.` The buttons are `Close` (destructive) and `Cancel`.
- **Close** cancels the run's task, if one is running, and dismisses the sheet. Keep the task
  started by Run All and Load Test Set in `@State` so it can be cancelled.
- The empty-list hint becomes `Tap Load Test Set to load the test pages.`
- No other copy changes.

**`SpikeRunner.runAll`**: checks `Task.isCancelled` before reading or structuring each capture.
Once cancelled it stops, and `isRunning` returns to false. A timed rate-limit wait (M1-6) that is
cancelled ends without retrying.

**Tests:** none added. The suite is unchanged at **48**; report the run's total.

**Done when:**
1. The three files are changed as above and nothing else, except this document's Results log.
2. Debug and Release build with no new warnings, and the 48 tests pass on the pinned destination.
3. A Release build still contains no spike code (check as in M1-3; also no `Close the accuracy
   spike`).
4. `git status` before and after, and every git command run. Do not commit.

**Pops checks on his phone:**
- Swiping down doesn't close the sheet.
- Done asks before closing.
- Load Test Set and Run All sit at the top of the list.
- Add Capture, Export Results and Clear are in the ••• menu.

**Do not:**
- Change structuring, reading, the report or Load Test Set's behavior.
- Add copy beyond the strings named here.
- Render previews or run a simulator or device session.

---

### Task M1-8 · Sylantro · The spike's close confirmation as a plain alert

**Why.** Pops, after M1-7: every alert is a plain centered alert, never one anchored to a button
(SLT-088, `00B` §3). M1-7's Done confirmation is a `.confirmationDialog`, the only one in the app.

**Inputs:** `00A`, `00B` (§3's new rule), this document (M1-7 as built).

**Deliverable:** `Sylantro/Views/Spike/SpikeView.swift` only. Replace the `.confirmationDialog`
with `.alert` and the same title, message and buttons: `Close the accuracy spike?`; `Captures and
results that weren't exported are cleared. A run in progress stops.`; `Close` (role
`.destructive`) and `Cancel` (role `.cancel`). Close does what it does now.

**Done when:**
1. `grep -rn "confirmationDialog\|actionSheet\|\.popover" Sylantro/Sylantro` finds nothing.
2. Debug and Release build with no new warnings, and the 48 tests pass on the pinned destination.
3. A Release build still contains no spike code (check as in M1-7).
4. `git status` before and after, and every git command run. Do not commit.

**Do not:** change any other file except this document's Results log, add copy, or render
previews.

---

### Task M1-9 · Sylantro · Parts only, and export at any time

**Why.** Run 3 on M1-8's build (`10` §7): TP-03 and TP-23 failed again in the one-call path for
several recipes. M1-6's gate passed because both pages have real lines that read as titles (TP-03's
Related Pages links, TP-23's site header). The header call sees only the top of the page, so it
can't reliably spot a second recipe anyway. Pops chose to retire that path (SLT-151, rewritten).
He also found Export Results disabled mid-run and wants failed results in the file (`report` is
built only when the whole run ends).

**Inputs:** `00`, `00A`, `00B`, this document (M1-5 to M1-8 as built).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Extraction/RecipeStructurer.swift` | App | No one-shot path; other titles become a warning; `StructuringFailed` |
| `Sylantro/Extraction/Spike/SpikeRunner.swift`, `SpikeReport.swift` | App | Report after every capture; diagnostics on failure |
| `Sylantro/Views/Spike/SpikeView.swift` | Screens | Export enabled whenever there is a report |
| `SylantroTests/Extraction/RecipeStructurerTests.swift` | Tests | Test 30 |

**`RecipeStructurer`** (SLT-151):
- Step 3 no longer branches. When `otherRecipeTitles(…)` is not empty, the recipe gets the
  warning from `static func otherRecipesWarning(_ titles: [String]) -> String?`, and structuring
  goes on in parts. The warning is `may hold other recipes: ` followed by the titles joined with
  `; `, or nil when there are none. `outcome.path` is always `parts`.
- `TokenCap.oneShot` and the one-shot branch are removed. `GeneratedRecipe.swift` and
  `makeRecipe` stay, because M1-3's tests use them; §1 notes them for removal.

**Export at any time** (Pops, run 3: "seems like I should be able to export the failed results
too"):
- `SpikeRunner` rebuilds `report` (`finishReport`) after each capture finishes, whether it's done
  or failed, and after a cancel. The report holds every capture that has a result, failed ones
  included, as now.
- `Export Results` is enabled whenever `report` is not nil, including during a run.
- A failed capture keeps what the structurer learned before it failed. `structure` throws a new
  `StructuringFailed` (`Error`, `CustomStringConvertible`) that carries the `StructuringOutcome`
  so far. The runner copies its `partMillis`, `partErrors`, `retried`, `fallbacks` and
  `usedLineLabels` into the result before `fail`.
- `SpikeCaptureResult` gains `headerTitle: String?` (the title step 3 chose) and `otherTitles:
  [String]` (the header answer's `otherTitles`, as returned), so a wrong path can be diagnosed
  from the file.

**Tests:**

30. `RecipeStructurerTests`, "other titles become a warning": `otherRecipesWarning(["Side Salad",
    "Pie"])` gives `may hold other recipes: Side Salad; Pie`, and `[]` gives nil.

Every earlier test passes unchanged. Expected total: 48 + 1 = **49**. Report the run's own total.

**Done when:**
1. `grep -n "oneShot" Sylantro/Sylantro/Extraction/RecipeStructurer.swift` finds nothing.
2. Debug and Release build with no new warnings, and the 49 tests pass on the pinned destination.
3. A Release build still contains no spike code (check as in M1-7).
4. Only the files above change, plus this document's Results log.
5. `git status` before and after, and every git command run. Do not commit.

**Pops's run 3, again:**
- Load Test Set, then Run All.
- Export Results works at any point, mid-run included.
- Export once at the end, then AirDrop the file to `~/GIT/Syzygy/sylantro-testpages/results/`.

**Do not:**
- Change the parts path, the caps, the retry and fallback, or the screen's layout.
- Add copy.
- Render previews or run a simulator or device session.

---

### Task M1-10 · Sylantro · Keep the screen awake on the spike sheet

**Why.** Pops, before run 3: keep the screen awake while the Accuracy Spike sheet is open, so a
run isn't paused by Auto-Lock. SyLib already has the helper SyJong uses, `ScreenAwake`
(`sylib-swift/Sources/SyLibUI/Device/ScreenAwake.swift`). It is the one owner of the idle timer,
so an app never sets `isIdleTimerDisabled` itself. The spike needs no setting; it is always on
while the sheet is open and in front.

**Inputs:** `00A`, `00B`, this document (M1-7 to M1-9 as built), SyLib's `ScreenAwake`, and SyJong's
`TableScreen.swift` (`holdsScreenAwake` and its `.onChange`) as the pattern.

**Deliverable:** `Sylantro/Views/Spike/SpikeView.swift` only.
- With `import SyLibUI`, call `ScreenAwake.shared.update(awake:holder:)` with the holder
  `"accuracySpike"`.
- `awake` is `scenePhase == .active`, set in the existing `.onChange(of: scenePhase, initial:
  true)`.
- The hold is released (`awake: false`) in `.onDisappear` and when Close dismisses the sheet.
- No setting and no copy.

**Tests:** none added. The suite stays at **49**; report the run's total.

**Done when:**
1. `grep -rn "isIdleTimerDisabled" Sylantro/Sylantro` finds nothing, and `ScreenAwake` is used only in
   `SpikeView.swift`.
2. Debug and Release build with no new warnings, and the 49 tests pass on the pinned destination.
3. A Release build still contains no spike code (check as in M1-7).
4. `git status` before and after, and every git command run. Do not commit.

**Pops checks on his phone:** with Auto-Lock set to 30 seconds, the screen stays on while the
sheet is open, and locks as usual once it is closed.

**Do not:**
- Change any other file except this document's Results log.
- Touch SyLib.
- Render previews.

---

### Task M1-11 · Sylantro · Title as text, wraps joined by rule, clean labelled lines (spike run 4)

**Why.** Spike run 3 (`10` §7) finished every capture, but accuracy fell. Titles were right on 7
of 22, against 13 in run 2: picked by line range, the model takes neighboring lines, yet it writes
the right title as text on 13 pages. Ingredients that wrap onto a second line weren't joined.
On the line-labels path, bullets and the Ingredients heading stayed in the lines, so the parser
found no quantity. Pops accepted all three fixes (SP-12 to SP-14). They are recorded by rewriting
SLT-148, SLT-146 and SLT-149. Pops also asked for Export Results to sit beside Run All, in a
button row that wraps.

**Inputs:** `00`, `00A`, `00B`, this document (M1-5 to M1-10 as built), `10` §7 (run 3), SyLibUI's
`FlowLayout`.

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Domain/Structuring/WrapJoiner.swift` | Domain | New: joins wrapped lines by rule (SLT-146) |
| `Sylantro/Domain/Structuring/HeaderArea.swift` | Domain | New `snappedTitle` (SLT-148) |
| `Sylantro/Domain/Structuring/PageSplitter.swift` | Domain | `removingBullet` made internal |
| `Sylantro/Extraction/GeneratedParts.swift` | App | `GeneratedHeader.title` replaces the line range |
| `Sylantro/Extraction/RecipeStructurer.swift` | App | Title snapped; ingredient lines joined before numbering; labelled lines cleaned |
| `Sylantro/Views/Spike/SpikeView.swift` | App | Export Results as a capsule after Run All, the row in `FlowLayout` |
| `SylantroTests/Domain/StructuringRulesTests.swift` | Tests | Tests 31 to 33 |
| `SylantroTests/Extraction/RecipeStructurerTests.swift` | Tests | Test 34; tests 23 and 24 updated |

**`WrapJoiner`** (`nonisolated enum`), `static func join(_ lines: [String]) -> [String]` (SP-13).
Lines are trimmed first.
- **New ingredient:** a line that starts with a digit, a unicode fraction from M1-2's table, or a
  bullet (`•`, `·`, `-`, `*` and a space) always starts a new line.
- **Continuation:** any other line is joined to the line before it when that line exists and
  either:
  - this line starts with a lowercase letter or `(`; or
  - the line before ends with `,` or `-`, or with one of the words `and`, `or`, `as`, `plus`,
    `of`, `with`, `to`, `for`, `into` or `in` (case-insensitive, as a whole word).
- **How lines join:** they join with one space. If the line before ends with `-` and this line
  starts with a lowercase letter, the `-` is removed and they join with no space (M1-5's rule).

**`HeaderArea.snappedTitle(_ text: String, area: [HeaderLine]) -> (title: String, snapped: Bool)`**
(SP-12):
- **Match:** with `TextMatch.normalize`, look for the first run of 1, 2 or 3 consecutive area
  lines whose texts, joined with a space, normalize to the same string as `text`. Return those
  lines as read, joined with a space, and `snapped` true.
- **Fallback:** if `text` is an empty answer (`TextMatch.isEmptyAnswer`) or nothing matches,
  return the area line with the largest `size` (the first of equal ones), and `snapped` false. An
  empty area gives `""`.

**`GeneratedHeader`**: `titleFirstLine` and `titleLastLine` are replaced by `title: String`, with
the description, verbatim: "The recipe's title exactly as printed, all of its lines. Empty if
none." `author`, `publisher` and `otherTitles` are unchanged, and the header prompt is unchanged.

**`RecipeStructurer`**:
- **Title (SLT-148):** the title is `HeaderArea.snappedTitle(header.title, area:)`. When `snapped`
  is false and the title isn't empty, add the warning `title from layout`. The old `title(from:area:)`
  is removed, and `otherRecipeTitles` uses the snapped title.
- **Ingredients (SLT-146):** the ingredients prompt, the fallback over the whole page, and the
  mapping (`ingredientGroups(from:lines:)`) all work on `WrapJoiner.join` of the lines. Line
  numbers refer to the joined lines.
- **Labelled lines (SLT-149):** `labelled(_:labels:keeping:)` becomes `static` internal. Every
  line it puts in `ingredients`, `steps` or `notes` has its bullet removed
  (`PageSplitter.removingBullet`). A line that is a heading (`PageSplitter.heading`) goes to no
  section, as clutter already doesn't.

**`SpikeView`** (Pops, 22 Nov 2026: "move the export button out of the menu and after the run
button, be sure to use FlowLayout if you are not already."):
- The first Section's `HStack` becomes SyLibUI's `FlowLayout` (default spacing), so the buttons
  wrap on a narrow screen.
- Its buttons, in order: `Load Test Set`, `Run All` (`.accent`), then
  `CapsuleButton("Export Results")`, which sets `isExporting` as the menu item did. It keeps the
  menu item's rule: disabled only when `runner.report == nil`, so it works mid-run and after
  failures (M1-9).
- The ••• menu keeps `Add Capture` and `Clear` only. Nothing else on the screen changes.

**Tests**, made-up text only (`00B` §2):

31. `StructuringRulesTests`, "wrapped lines are joined by rule":
    - Input: `["1 cup grape juice, such as", "Concord", "1 cup flour,", "sifted", "• 1 egg",
      "3 tea-", "spoons salt", "(about 2 cups)"]`.
    - Output: `["1 cup grape juice, such as Concord", "1 cup flour, sifted", "• 1 egg", "3
      teaspoons salt (about 2 cups)"]`.
32. `StructuringRulesTests`, "a new ingredient is never joined": `["2 cups water,", "1 cup
    flour", "½ cup sugar"]` is unchanged.
33. `StructuringRulesTests`, "the title snaps to the page's lines":
    - The area is `Example Kitchen` (1.0), `Test` (2.0), `Soup` (2.0) and `Serves 2` (1.0).
    - Text `test soup` gives (`Test Soup`, true).
    - Text `Made-up Title` gives (`Test`, false).
    - Text `none` gives (`Test`, false).
34. `RecipeStructurerTests`, "labelled lines are cleaned":
    - Lines: `["Test Soup", "Ingredients", "• 1 cup water", "ps://example.com/r/1"]`.
    - Labels: 1 `header`, and 2, 3 and 4 `ingredient`.
    - The result: header `["Test Soup"]` and ingredients `["1 cup water"]`.

Test 23 (title by line range) is rewritten. It now checks that `snappedTitle` joins `watercress`,
`salad with beets` and `and Feta` from the text `watercress salad with beets and Feta`, and is
renamed "the title snaps across three lines". The made-up words stay as M1-5 gave them. Test 24
is unchanged unless the title change touches it; report any change.

**Done when:**
1. The files above are changed or added, and `Domain/` imports `Foundation` only.
2. Expected total: 49 + 4 = **53**, with tests 23 and 24 as above. Report the run's own total.
3. Debug and Release build with no new warnings. A Release build still contains no spike code
   (check as in M1-7).
4. Only the files above change, plus this document's Results log.
5. `git status` before and after, and every git command run. Do not commit.

**Pops's run 4:** Load Test Set, Run All, then Export Results to
`~/GIT/Syzygy/sylantro-testpages/results/`. Claude scores it against runs 2 and 3.

**Do not:**
- Change the caps, the retry and fallback, the steps part, or the screen beyond the button row
  above.
- Add copy.
- Render previews or run a simulator or device session.

---

### Task M1-12 · Sylantro · The spike behind an AppConfig flag, in every build

**Why.** Pops, 22 Nov 2026: "I want to leave the accuracy spike in the app for now, so just put it behind a appconfig flag and no if DEBUG". SLT-093 is rewritten: the spike screen is reached from Settings in any build
configuration when an AppConfig flag is on, and nothing of it is inside `#if DEBUG`.

**Inputs:** `00`, `00A`, `00B`, this document (M1-3 to M1-11 as built).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/App/AppConfig.swift` | App | New `AccuracySpike.isEnabled` |
| `Sylantro/Views/Settings/SettingsSheet.swift` | App | The row and its sheet behind the flag |
| `Sylantro/Extraction/Spike/SpikeReport.swift`, `SpikeRunner.swift`, `TestSetGroups.swift` | App | `#if DEBUG` and its `#endif` removed |
| `Sylantro/Views/Spike/SpikeView.swift` | App | `#if DEBUG` and its `#endif` removed; Clear disabled with nothing to clear |
| `SylantroTests/Extraction/SpikeRunnerTests.swift` | Tests | `#if DEBUG` and its `#endif` removed |

**`AppConfig`**: a new nested `enum AccuracySpike` with `static let isEnabled = true`, beside
`DebugCloudKit`, with a doc comment that says it shows the accuracy spike's Settings row
(SLT-093). It stays `true` through the TestFlight beta and is turned off when App Store copy
starts for RC0 (`00B` §6, `12` M9).

**`SettingsSheet`**:
- `isShowingSpike` and the `.sheet` that presents `SpikeView` lose their `#if DEBUG`.
- The spike's Section is wrapped in `if AppConfig.AccuracySpike.isEnabled` in place of `#if DEBUG`.
  Its contents and styling are unchanged.

**The spike files**: the file-wide `#if DEBUG` and its `#endif` are removed, and nothing else
changes. Any comment that says the code is Debug-only now cites SLT-093's flag.

**`SpikeView`'s Clear** (Pops, 22 Nov 2026: "the clear menu item should be disabled if there's nothing to clear"): the ••• menu's `Clear` gets
`.disabled(runner.captures.isEmpty && runner.report == nil)`, so it is enabled whenever there is a
capture or a report to clear. Nothing else on the screen changes.

No new tests: the suite stays at **53**, and `SpikeRunnerTests` now runs in every configuration.

**Done when:**
1. `grep -rn "#if DEBUG" Sylantro/Sylantro Sylantro/SylantroTests` finds nothing.
2. The suite passes with 53 tests. Report the run's own total.
3. Debug and Release build with no new warnings. The Release binary now contains the spike's
   symbols: report their count from `nm -a`, as the earlier checks did. That is expected; M1-3 to
   M1-11's "no spike code in Release" check is retired.
4. Only the files above change, plus this document's Results log.
5. `git status` before and after, and every git command run. Do not commit.

**Pops's check:** a Release build on his iPhone 18 Pro shows Settings › Accuracy spike. With the
flag set to `false`, the row is gone.

**Do not:**
- Change the spike's behavior beyond Clear's disabled state, the pipeline, or any copy.
- Add a Settings toggle for the flag.
- Render previews or run a simulator or device session.

---

### Task M1-13 · Sylantro · A progress section on the spike sheet

**Why.** Pops, 22 Nov 2026: "add a stats section between the buttons and list of images that shows a progress bar and n / m of how much we processed." M1-12 also left the flag's doc comment on SLT-093's earlier wording
("App Store included"); it is corrected here.

**Inputs:** `00`, `00A`, `00B`, this document (M1-3 to M1-12 as built).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Extraction/Spike/SpikeRunner.swift` | App | New `processedCount` |
| `Sylantro/Views/Spike/SpikeView.swift` | App | The progress section |
| `Sylantro/App/AppConfig.swift` | App | `AccuracySpike`'s doc comment corrected |

**`SpikeRunner.processedCount: Int`**, a computed property: the number of captures whose status is
`.done` or `.failed`. A capture that is waiting, reading, structuring or waiting for the app is not
processed.

**`SpikeView`**:
- A new Section with no header, right after the button row's Section and before everything else
  (the Apple Intelligence note and the capture list). It shows only when `runner.captures` isn't
  empty.
- It holds a `ProgressView(value: Double(runner.processedCount), total: Double(runner.captures.count))`
  and, below it, `Text("\(runner.processedCount) / \(runner.captures.count)")` with
  `.monospacedDigit()`. That text is Pops's copy, verbatim; nothing else is added.
- Nothing else on the screen changes.

**`AppConfig.AccuracySpike`**'s doc comment ends: "It stays `true` through the TestFlight beta
and is turned off when App Store copy starts for RC0 (`00B` §6)." in place of "It stays `true` in
every build, App Store included."

No new tests: the suite stays at **53**.

**Done when:**
1. Only the files above change, plus this document's Results log.
2. The suite passes with 53 tests. Report the run's own total.
3. Debug and Release build with no new warnings.
4. `git status` before and after, and every git command run. Do not commit.

**Pops's check:** on Run All, the bar and `n / m` climb as each capture finishes, failures included.

**Do not:**
- Change the runner's behavior, the pipeline, or other copy.
- Render previews or run a simulator or device session.

---

### Task M1-14 · Sylantro · Titles, group names, lines used once, and two parser readings (spike run 5)

**Why.** Spike run 4 (`10` §7) was the best run yet on ingredients: 151 of 166 lines, and
quantities right on 139 of 146. Titles were right on 11 of 22. Four things are left:
- **No title:** the page with no title got its largest line, a step, as its title.
- **Dropped and padded titles:** two good titles were snapped with the site's name, then dropped
  by the checker.
- **Group names:** the model names most groups after one of their own ingredient lines.
- **Repeated lines:** one line was mapped up to five times.

Pops accepted all four fixes (SP-15 to SP-18), plus the two parser readings `06` §1 left open.
They are recorded by rewriting SLT-148 and SLT-146, and as the new SLT-155.

**Inputs:** `00`, `00A`, `00B`, `06` §1 and M1-2's parser table, this document (M1-5 to M1-13 as
built), `10` §7 (run 4).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Domain/Structuring/HeaderArea.swift` | Domain | `snappedTitle`: an empty answer is no title; small edge lines trimmed (SLT-148) |
| `Sylantro/Domain/Structuring/RecipeValidator.swift` | Domain | The title is no longer checked (SLT-148) |
| `Sylantro/Domain/Structuring/WrapJoiner.swift` | Domain | `startsNewLine` made internal, as `startsIngredient` |
| `Sylantro/Domain/Parsing/IngredientLineParser.swift` | Domain | "A few" and "-inch" (SLT-155) |
| `Sylantro/Extraction/RecipeStructurer.swift` | App | The `no title` warning; group names by rule; each line used once (SLT-146); `modelTitle` |
| `Sylantro/Extraction/Spike/SpikeReport.swift`, `SpikeRunner.swift` | App | `modelTitle` in the report |
| `SylantroTests/Domain/StructuringRulesTests.swift` | Tests | Test 33 updated; test 35 |
| `SylantroTests/Domain/RecipeValidatorTests.swift` | Tests | Test 36 |
| `SylantroTests/Domain/IngredientLineParserTests.swift` | Tests | Rows 32 to 36 of the parser table |
| `SylantroTests/Extraction/RecipeStructurerTests.swift` | Tests | Tests 37 and 38 |

**`HeaderArea.snappedTitle`** (SP-15, SLT-148):
- **No title:** if `text` is an empty answer (`TextMatch.isEmptyAnswer`), return `("", false)`.
  The largest-line fallback is only for a non-empty answer that matches nothing.
- **Trim:** when a run of 2 or 3 lines matches, drop its first line while it is smaller than 0.85
  times the run's largest `size`, then its last line by the same test. At least one line always
  stays. The title is the lines left, joined with a space, and `snapped` stays true.

**`RecipeValidator`** (SLT-148): `recipe.title` is no longer passed to `checked`. A snapped title
is the page's own lines; the checker's page text has clutter taken out, so it could drop a title
that was printed there. Everything else the validator checks is unchanged.

**`WrapJoiner`**: the private `startsNewLine(_:)` becomes `static func startsIngredient(_ line:
String) -> Bool`, internal, with the same rule (a digit, a unicode fraction or a bullet first). The
joiner calls it, so its behavior doesn't change.

**`RecipeStructurer`**:
- **Title warnings (SLT-148):** when the title is empty, add the warning `no title`. When it isn't
  empty and `snapped` is false, add `title from layout`, as before.
- **`modelTitle`:** `StructuringOutcome` gains `modelTitle: String?`, set to the header answer's
  `title` as the model wrote it (nil with no header answer).
- **Group names by rule (SP-16, SLT-146):** in `ingredientGroups(from:lines:)`, a group's
  `nameLine` gives a name only when all of these hold:
  - The line is in range.
  - It isn't one of the lines of any item in the whole answer.
  - Its text, trimmed, fails `WrapJoiner.startsIngredient`.
  - It isn't over `maximumGroupNameLength`, which keeps its warning `group name too long`.

  A group that ends up with no name, after the first group, joins the group before it: its
  ingredients are appended to that group's. The first group may have no name.
- **Each line used once (SP-17, SLT-146):** an item whose lines include a line already used by an
  earlier item is skipped, with the warning `ingredient line repeated`. A line used as a group
  name doesn't count as used by an item.

**`SpikeCaptureResult`** gains `modelTitle: String?`, which `copyDiagnostics` copies from the
outcome on success and on `StructuringFailed`, like `headerTitle`.

**`IngredientLineParser`** (SP-18, SLT-155), both read as row 26 is (no quantity, no unit, rest =
the whole trimmed line):
- **"A few":** after rule 2's prefix, if the line continues (case-insensitively) with `a few `,
  `a couple of `, `a couple ` or `several `, it has no quantity. This is checked before rule 3's
  number words, so `a` no longer reads as 1 there. `a pinch of salt` and `a dozen eggs` read as
  before.
- **"-inch":** if rule 3's first amount is followed directly by `-inch` or `-in.` (any case; `-`,
  U+2013 or U+2014), and then by a space or the end of the line, the amount is a size and the line
  has no quantity. A quantity before it is kept: `2 1-inch pieces ginger` reads Q(2), no unit,
  rest `1-inch pieces ginger`.

**Tests**, made-up text only (`00B` §2):

- **33** (rewritten): text `none` now gives (`""`, false). Its other two cases are unchanged.
- **35.** `StructuringRulesTests`, "a smaller line is trimmed from the title": with the area
  `Example Kitchen` (1.0), `Test Soup` (2.0) and `Serves 2` (1.0), the text `example kitchen test
  soup` gives (`Test Soup`, true).
- **36.** `RecipeValidatorTests`, "the title isn't checked": a recipe titled `Made-up Title`,
  checked against page text without it, keeps its title and gets no `not on page: title`.
- **37.** `RecipeStructurerTests`, "group names are subheadings only":
  - Lines: `["For the soup", "1 cup water", "2 cups stock", "For the top", "1 cup cheese"]`.
  - Groups: (nameLine 1, items 2), (nameLine 3, items 3), (nameLine 4, items 5).
  - The result has two groups: `For the soup` with `1 cup water` and `2 cups stock`, and
    `For the top` with `1 cup cheese`.
- **38.** `RecipeStructurerTests`, "a line is used once": one group with items 2, 2 and 3 over the
  same lines gives two ingredients, `1 cup water` and `2 cups stock`, and the warning
  `ingredient line repeated`.

**Parser rows 32 to 36**, added to M1-2's parameterized table:

| # | Line | Quantity | Unit | Rest |
|---|---|---|---|---|
| 32 | `A few sprigs mint` | – | – | `A few sprigs mint` |
| 33 | `a couple of eggs` | – | – | `a couple of eggs` |
| 34 | `several sprigs thyme` | – | – | `several sprigs thyme` |
| 35 | `1-inch piece ginger` | – | – | `1-inch piece ginger` |
| 36 | `2 1-inch pieces ginger` | Q(2, nil, false) | – | `1-inch pieces ginger` |

The table is one parameterized test, so the suite count doesn't change for these rows. Rows 1 to
31 must still pass unchanged.

**Done when:**
1. The files above are changed, and `Domain/` imports `Foundation` only.
2. Expected total: 53 + 4 = **57** (tests 35 to 38; the parser rows are cases of an existing
   test). Test 33 is rewritten as above. Report the run's own total, and the parser test's case
   count (36).
3. Debug and Release build with no new warnings.
4. Only the files above change, plus this document's Results log.
5. `git status` before and after, and every git command run. Do not commit.

**Pops's run 5:** Load Test Set, Run All, then Export Results to
`~/GIT/Syzygy/sylantro-testpages/results/`. Claude scores it against runs 2 to 4.

**Do not:**
- Change the prompts, the caps, the retry and fallback, the steps part, or the screen.
- Add copy beyond the warnings named above.
- Render previews or run a simulator or device session.

---

### Task M1-15 · Sylantro · The title starts at the model's first line (spike run 6)

**Why.** Spike run 5 (`10` §7) held run 4's ingredient numbers and fixed the groups. Titles were
right on 12 of 22. The model's own title text, now in the report, shows why:
- **The model copies the header block:** it usually answers with the whole top of the page, one
  line per printed line (title, byline, show, site, yield). That can't snap, so right titles came
  only from the largest-line fallback.
- **The size trim backfired:** M1-14's trim cut a right title where the blurb under it is printed
  larger.
- **The rest:** on two pages the model's first line is the site's name; on one it gives only the
  first word of a three-line title; on the page with no title it gives a step.

Pops chose SP-19, then run 6 (decision card, "SP-19, then run 6"). It is recorded by rewriting
SLT-148.

**Inputs:** `00`, `00A`, `00B`, this document (M1-5 to M1-14 as built), `10` §7 (run 5).

**Deliverable:**

| File | Layer | What |
|---|---|---|
| `Sylantro/Domain/Structuring/HeaderArea.swift` | Domain | `snappedTitle` rewritten; new `host(of:)`; the size trim removed |
| `Sylantro/Extraction/RecipeStructurer.swift` | App | Passes the author answer and the source URL's host |
| `SylantroTests/Domain/StructuringRulesTests.swift` | Tests | Test 35 rewritten; tests 39 to 41 |

**`HeaderArea.host(of url: String?) -> String?`**: the URL lowercased, with any scheme and `://`
removed, up to the first `/`. Nil for nil or empty. So `https://www.example.com/r/1` gives
`www.example.com`, and `www.example.com` gives itself.

**`HeaderArea.snappedTitle(_ text: String, area: [HeaderLine], author: String? = nil,
sourceHost: String? = nil) -> (title: String, snapped: Bool)`** (SP-19, SLT-148). `titleTrimShare`
and the trim are removed. In order:
1. **Empty:** an empty answer (`TextMatch.isEmptyAnswer`) gives `("", false)`.
2. **The model's lines:** split `text` on newlines, trim each, and drop empty ones. A line is a
   **side line**, and is dropped, when either holds:
   - **Site name:** its letters and digits only, lowercased, are at least 4 characters long and
     are found inside `sourceHost` with its dots removed. So `Tasting Table.` is found in
     `www.tastingtable.com`.
   - **Author:** `author` isn't an empty answer, and the line's normalized text contains the
     author's normalized text.
3. **The start:** the first line left is looked for in the area. The start is the first area line
   whose normalized text equals it; failing that, the first run of 2 or 3 consecutive area lines
   whose joined text normalizes to it. If no line is left, or none is found, return the largest
   line as now (the first of equal ones) with `snapped` false, and `""` for an empty area.
4. **The next lines:** the title takes in the area lines that follow its start or run, one at a
   time, up to 3 lines in all. The next area line joins when it isn't a side line by step 2's tests
   and either holds:
   - **Continues:** its first character is a lowercase letter.
   - **Same size:** its normalized text equals the model's next unused line, and its `size` is 0.8
     to 1.25 times the start line's. When the start line's size is 0, the size check passes.

   The first line that doesn't join ends the title.
5. **A step is no title:** if the title starts with one or more digits, then `.` or `)`, then a
   space, return `("", false)`.
6. Otherwise return the lines as read, joined with a space, and `snapped` true.

**`RecipeStructurer`**, step 3: `snappedTitle(header?.title ?? "", area: area, author:
header?.author, sourceHost: HeaderArea.host(of: rules.sourceURL))`. The warnings stay as M1-14
gives them (`no title`, `title from layout`).

**Tests**, made-up text only (`00B` §2):

- **33 and the three-line title test** (test 23) stay as they are and must still pass.
- **35** (rewritten), "the title starts at the model's first line":
  - The area is `Example Kitchen` (1.0), `Test Soup` (2.0), `Recipe by Pat Example` (1.0) and
    `Serves 2` (1.0).
  - The text is `Example Kitchen`, `Test Soup` and `Recipe by Pat Example` on three lines.
  - With author `Pat Example` and host `www.examplekitchen.com`, it gives (`Test Soup`, true).
- **39.** "a title's next line joins when it continues": the area is `Test` (1.0),
  `soup with beans` (2.0) and `Serves 2` (1.0). The text `Test` gives (`Test soup with beans`, true).
- **40.** "a same-size next line joins, a larger one doesn't": the area is `Test Soup` (2.0),
  `With Beans` (1.8) and `Example blurb text` (2.6). The text `Test Soup`, `With Beans` and
  `Example blurb text` on three lines gives (`Test Soup With Beans`, true).
- **41.** "a step is no title": the area is `4. Bake the test soup` (3.0). The text
  `4. Bake the test soup` gives (`""`, false).

**Done when:**
1. The files above are changed, and `Domain/` imports `Foundation` only.
2. Expected total: 57 + 3 = **60**, with test 35 rewritten. Report the run's own total.
3. Debug and Release build with no new warnings.
4. Only the files above change, plus this document's Results log.
5. `git status` before and after, and every git command run. Do not commit.

**Pops's run 6:** Load Test Set, Run All, then Export Results to
`~/GIT/Syzygy/sylantro-testpages/results/`. Claude scores it against runs 4 and 5, and Pops then
decides whether Milestone 1 closes (`12` §4).

**Do not:**
- Change the prompts, the ingredients or steps parts, the parser, or the screen.
- Add copy.
- Render previews or run a simulator or device session.

---

## 1. Open in this document

- **Two copies of the unicode-fraction table** (M1-4 Results, note (a)): `TextMatch` and
  `IngredientLineParser` each hold one. A later task makes the parser's table the shared one
  (`00A` §10).
- **A rate limit while Sylantro is in front** waits until the app is next brought back to the front
  (M1-4 Results, note (e)). M1-6 adds a timed retry (SLT-153).
- **The ingredients fallback is noisy** (M1-5 Results, note (e)): asked over the whole page, it
  warns `unused ingredient line <n>` for every line that isn't an ingredient. Run 3 shows how often
  the fallback runs; if it does, a later task can drop those warnings on the fallback path.
- **`GeneratedRecipe` and `makeRecipe` are unused by structuring** since M1-9 (SLT-151). Only
  M1-3's tests still use them; a later task removes them with those tests.
- Vision's newer document reading (`RecognizeDocumentsRequest`, iOS 26) returns paragraphs, lists
  and tables, which may help multi-column pages (`10` H-6, H-38). Not in M1-3; worth a second run
  if the spike's column results are poor.
- Long recipes may exceed the model's context. M1-4 structures in parts (SLT-140) and caps each
  part's output (SLT-141); M1-5 retries a part that reaches its cap (SLT-147).

---

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| M1-14 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 57 tests in 11 suites passed after 0.042 seconds."; `** TEST SUCCEEDED **` (53 + 4). **Parser test:** "✔ Test "each line parses as the table says" with 36 test cases passed"; rows 1 to 31 unchanged. **Changes:** (a) `HeaderArea.snappedTitle`: an empty answer returns `("", false)`. A matched run of 2 or 3 drops its first lines, then its last, while they are smaller than 0.85 × the run's largest size (`titleTrimShare`), keeping at least one, and stays snapped. The largest-line fallback is now only for a non-empty answer that matches nothing. (b) `RecipeValidator`: the title is no longer checked; a comment cites SLT-148. (c) `WrapJoiner.startsNewLine` is now `static func startsIngredient(_:)`, internal, with the same rule, and `join` calls it. (d) `IngredientLineParser` (SLT-155): after rule 2, a line continuing with `a few `, `a couple of `, `a couple ` or `several ` (case-insensitive) returns as row 26 does. After rule 3's first amount, a dash (`-`, `–`, `—`) then `inch` or `in.` (any case) then a space or the end also returns as row 26, before the range check, so `2 1-inch pieces ginger` keeps Q(2). (e) `RecipeStructurer`: the title warning is `no title` when the title is empty, else `title from layout` when not snapped. `StructuringOutcome.modelTitle` is `header?.title`. In `ingredientGroups(from:lines:)`, a `nameLine` names its group only when it is in range, isn't a line of any item in the answer, its trimmed text fails `WrapJoiner.startsIngredient`, and it isn't over 40 characters (else `group name too long`). A group after the first with no name has its ingredients appended to the group before it. An item that uses a line an earlier item used is skipped with `ingredient line repeated`; a name line doesn't count as used by an item. (f) `SpikeCaptureResult.modelTitle`, copied by `copyDiagnostics` on success and on `StructuringFailed`. **Tests:** 33 rewritten (`none` gives `("", false)`; its other two cases unchanged). Added: 35 in `StructuringRulesTests`, 36 in `RecipeValidatorTests`, 37 and 38 in `RecipeStructurerTests`, and parser rows 32 to 36. No other test changed. **Clauses:** ✅ 1 the files are changed as listed. All 27 `import` lines under `Domain/` are `import Foundation`. ✅ 2 57 tests and 36 parser cases. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-14-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". The first test run had two macro warnings and one failure, all from how I first wrote test 36's last check (`#expect(!(x ?? []).contains(…))`). That line now reads the warnings into a local first, with the same expectation. ✅ 4 only the listed files changed, plus this row. ✅ 5 below. **Git status before** (branch `milestone-1`): `MM` `00B`, the ledger, `10`, `11`, `README.md`, `PageSplitter.swift`, `GeneratedParts.swift`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `SettingsSheet.swift`, `SpikeView.swift` and `RecipeStructurerTests.swift`; `AM` `HeaderArea.swift`, `TestSetGroups.swift`, `StructuringRulesTests.swift` and `SpikeRunnerTests.swift`; ` M` `06`, `12` and `AppConfig.swift`; `?? WrapJoiner.swift`; the rest staged. **After:** the same, plus ` M` `IngredientLineParser.swift`, `RecipeValidator.swift`, `IngredientLineParserTests.swift` and `RecipeValidatorTests.swift`. **Git:** `git status --short` (×2), `git branch --list`, `git diff --numstat -- Sylantro/SylantroTests`. **Notes:** (a) "Any item's lines" for the group-name rule counts every item with `firstLine ≥ 1` and `lastLine ≥ firstLine`, whether or not that item is later skipped as out of range or repeated. (b) A name line rejected for starting like an ingredient gets no warning. Its line is reported as `unused ingredient line <n>` when no item uses it. |
| M1-13 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 53 tests in 11 suites passed after 0.036 seconds."; `** TEST SUCCEEDED **` (unchanged). **Changes:** (a) `Extraction/Spike/SpikeRunner.swift`: a computed `processedCount: Int`, the captures whose status is `.done` or `.failed`. The `switch` lists every status, so a status added later must be classed explicitly. (b) `Views/Spike/SpikeView.swift`: a new Section with no header, right after the button row's Section and before the Apple Intelligence note and the capture list, shown only when `runner.captures` isn't empty. It holds `ProgressView(value: Double(runner.processedCount), total: Double(runner.captures.count))` and, below it, `Text("\(runner.processedCount) / \(runner.captures.count)")` with `.monospacedDigit()`. (c) `App/AppConfig.swift`: `AccuracySpike`'s doc comment now ends "It stays `true` through the TestFlight beta and is turned off when App Store copy starts for RC0 (`00B` §6)." in place of "It stays `true` in every build, App Store included." **Clauses:** ✅ 1 only those three files changed, plus this row. `AppConfig.swift` and `SpikeRunner.swift` already had unstaged changes from M1-12 and M1-9, and `SpikeView.swift` from M1-8 to M1-12. ✅ 2 53 tests pass. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-13-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". ✅ 4 below. **Git status before** (branch `milestone-1`): `MM` `00B`, the ledger, `10`, `11`, `README.md`, `PageSplitter.swift`, `GeneratedParts.swift`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `SettingsSheet.swift`, `SpikeView.swift` and `RecipeStructurerTests.swift`; `AM` `HeaderArea.swift`, `TestSetGroups.swift`, `StructuringRulesTests.swift` and `SpikeRunnerTests.swift`; ` M` `12_IMPLEMENTATION_PLAN.md` and `AppConfig.swift`; `?? WrapJoiner.swift`; the rest staged. **After:** the same entries; the three edited files were already ` M` or `MM`. **Git:** `git status --short` (×2), `git branch --list`. |
| M1-12 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 53 tests in 11 suites passed after 0.035 seconds."; `** TEST SUCCEEDED **` (unchanged; `SpikeRunnerTests` now builds in every configuration). **Changes:** (a) `App/AppConfig.swift`: a new `enum AccuracySpike { static let isEnabled = true }` after `DebugCloudKit`, whose doc comment says it shows the spike's Settings row (SLT-093) and stays `true` in every build, App Store included. (b) `Views/Settings/SettingsSheet.swift`: `isShowingSpike` and the `.sheet` presenting `NavigationStack { SpikeView() }` lose their `#if DEBUG`. The spike's Section is inside `if AppConfig.AccuracySpike.isEnabled { … }` with its contents and styling unchanged; it is re-indented one level for the `if`. (c) `Extraction/Spike/SpikeReport.swift`, `SpikeRunner.swift`, `TestSetGroups.swift`, `Views/Spike/SpikeView.swift` and `SylantroTests/Extraction/SpikeRunnerTests.swift`: the file-wide `#if DEBUG` and `#endif` are removed. Their "Debug builds only" doc comments now cite SLT-093's `AppConfig.AccuracySpike` flag; the test file's comment just drops the phrase. Nothing else changed in them except (d). (d) `SpikeView`: the ••• menu's `Clear` has `.disabled(runner.captures.isEmpty && runner.report == nil)`. **Clauses:** ✅ 1 `grep -rn "#if DEBUG" Sylantro/Sylantro Sylantro/SylantroTests` (run from `PROJ/` as `grep -rn "#if DEBUG" Sylantro SylantroTests`) finds nothing (exit 1). ✅ 2 53 tests pass. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-12-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". **Release spike symbols, as expected now:** `nm -a` on Release `Sylantro.app/Sylantro` (no separate dylib) gives **1,534** symbols matching `spike` or `TestSetGroups` (1,508 matching `spike` alone), and `strings` gives 13 matches for the spike's names and copy. For comparison, the Debug `Sylantro.debug.dylib` has 2,450. The "no spike code in Release" check is retired, as M1-12 says. ✅ 4 only the listed files changed, plus this row. `SpikeReport.swift` and `SpikeRunner.swift` also carry M1-9's earlier unstaged changes. ✅ 5 below. **Git status before** (branch `milestone-1`): `MM` `00B`, the ledger, `10`, `11`, `README.md`, `HeaderArea.swift` (`AM`), `PageSplitter.swift`, `GeneratedParts.swift`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `SpikeView.swift`, `StructuringRulesTests.swift` (`AM`) and `RecipeStructurerTests.swift`; `?? WrapJoiner.swift`; the rest staged. **After:** the same, plus ` M App/AppConfig.swift`, `MM Views/Settings/SettingsSheet.swift`, `AM Extraction/Spike/TestSetGroups.swift` and `AM SylantroTests/Extraction/SpikeRunnerTests.swift`. **Git:** `git status --short` (×2), `git branch --list`. |
| M1-11 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 53 tests in 11 suites passed after 0.039 seconds."; `** TEST SUCCEEDED **` (49 + 4). **Changes:** (a) new `Domain/Structuring/WrapJoiner.swift`, `join(_:)` as M1-11 gives it (SLT-146). A bullet is detected with `PageSplitter.removingBullet(line) != line`, so the bullet list stays in one place. (b) `HeaderArea.snappedTitle(_:area:)` (SLT-148): the first run of 1 to 3 consecutive area lines, by start then by length, whose joined text normalizes to the model's; otherwise, or for an empty answer, the largest line (the first of equal ones), and `""` for an empty area. (c) `PageSplitter.removingBullet` is now internal. (d) `GeneratedHeader`: `title: String` with the description verbatim replaces `titleFirstLine` and `titleLastLine`; the prompt is unchanged. (e) `RecipeStructurer`: the title is `snappedTitle(header?.title ?? "", area:)`, with the warning `title from layout` when not snapped and not empty. `otherRecipeTitles` and `headerTitle` use it. `title(from:area:)` is removed. The ingredients prompt and mapping use `WrapJoiner.join(split.ingredients)`, and the fallback uses `WrapJoiner.join(allLines)`, so line numbers refer to the joined lines. `labelled(_:labels:keeping:)` is now `static` internal: it drops heading lines as well as clutter, and removes bullets from ingredient, step and note lines (SLT-149). (f) `SpikeView`: the first Section's `HStack` is now `FlowLayout()` holding `Load Test Set`, `Run All` (`.accent`) and `CapsuleButton("Export Results")` (disabled only when `report == nil`); the ••• menu keeps `Add Capture` and `Clear`. **Tests:** 31 to 33 added to `StructuringRulesTests`, and 34 to `RecipeStructurerTests`. Test 23 is rewritten and renamed "the title snaps across three lines": `snappedTitle("watercress salad with beets and Feta", …)` gives that title, snapped. Test 24 is unchanged. **Also changed (compile fix, `00A` §8): test 12**. It built `GeneratedHeader(titleFirstLine: 1, titleLastLine: 1, …)`, which no longer exists, and now builds `GeneratedHeader(title: "Test Soup", …)`. Its expectations are unchanged; `assemble` takes the title as its own parameter, so the header's title isn't read. **Clauses:** ✅ 1 the files are changed or added as listed. All 27 `import` lines under `Domain/` are `import Foundation`. ✅ 2 53 tests, with tests 23 and 24 as above, plus the test 12 compile fix. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-11-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". The first test build failed on test 12 (an error, plus an "unnecessary `try`" warning that came from it); after the fix, neither remains. **Release spike check:** Release `Sylantro.app/Sylantro` (no separate dylib): `nm -a` has 0 symbols matching `spike` or `TestSetGroups`, and `strings` has 0 matches for `spike`, `Accuracy`, `Waiting for Sylantro`, `Load Test Set`, `spikeTestSetFolder` or `Close the accuracy spike`. The same binary has 18 pipeline symbols (`WrapJoiner` included). Control: the Debug `Sylantro.debug.dylib` has 2,424 `spike`/`TestSetGroups` symbols. ✅ 4 only the listed files changed, plus this row. `SpikeReport.swift` and `SpikeRunner.swift` show unstaged diffs, but those are M1-9's and M1-11 didn't touch them. ✅ 5 below. **Git status before** (branch `milestone-1`): `MM` the ledger, `10`, `11`, `README.md`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `SpikeView.swift` and `RecipeStructurerTests.swift`; everything else staged. **After:** the same, plus `AM` `HeaderArea.swift` and `StructuringRulesTests.swift`, `MM` `PageSplitter.swift` and `GeneratedParts.swift`, and `?? Domain/Structuring/WrapJoiner.swift`. **Git:** `git status --short` (×2), `git branch --list`, `git diff --stat`. **Notes:** (a) `ingredientGroups(from:lines:)` doesn't join lines itself; its callers pass `WrapJoiner.join` of the lines. Joining inside it would have changed tests 19 and 20, which M1-11 keeps unchanged. Their multi-line items still map. (b) `WrapJoiner` holds a third copy of M1-2's unicode-fraction characters (`TextMatch` and `IngredientLineParser` hold the others), all private; §1's shared-table follow-up now covers three. (c) Without a header answer (no area, or the call failed), the title falls back to the area's largest line, with `title from layout`. (d) **Rule slip, reported:** one read-only command in this session included `sed -n '89p' … >/dev/null` while looking up test 12's line. It printed nothing and changed nothing, but `00B` §3 forbids `sed` entirely; the line was found with `grep -n` instead. |
| M1-10 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 49 tests in 11 suites passed after 0.041 seconds."; `** TEST SUCCEEDED **` (unchanged at 49). **Change:** in `Views/Spike/SpikeView.swift` only (it already imported `SyLibUI`): `private static let screenAwakeHolder = "accuracySpike"`. In the existing `.onChange(of: scenePhase, initial: true)`, `ScreenAwake.shared.update(awake: phase == .active, holder: Self.screenAwakeHolder)` runs before the runner's scene calls. The hold is released with `update(awake: false, …)` in a new `.onDisappear` and in Close's action, before `dismiss()`. No setting, no copy, no SyLib change. **Clauses:** ✅ 1 `grep -rn "isIdleTimerDisabled" Sylantro/Sylantro` finds nothing (exit 1). `grep -rln "ScreenAwake" Sylantro/Sylantro` lists only `Views/Spike/SpikeView.swift`. ✅ 2 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-10-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". All 49 tests pass. ✅ 3 **Release spike check:** Release `Sylantro.app/Sylantro` (no separate dylib): `nm -a` has 0 symbols matching `spike` or `TestSetGroups`, and `strings` has 0 matches for `spike`, `Accuracy`, `Waiting for Sylantro`, `Load Test Set`, `spikeTestSetFolder` or `Close the accuracy spike`. The same binary has 16 pipeline symbols. Control: the Debug `Sylantro.debug.dylib` has 2,398 `spike`/`TestSetGroups` symbols. ✅ 4 below. **Git status before** (branch `milestone-1`): `MM` the ledger, `10`, `11`, `README.md`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `SpikeView.swift` and `RecipeStructurerTests.swift` (M1-8's and M1-9's unstaged work); everything else staged (`M ` or `A `). **After:** the same entries, unchanged; `SpikeView.swift` and `11` were already `MM`. **Git:** `git status --short` (×2), `git branch --list`. **Notes:** (a) SyJong's `TableScreen.swift`, named as a pattern, was not opened. `00A` §3 forbids reading another project's repository, and M1-10's text plus SyLib's `ScreenAwake` (`update(awake:holder:)`, any `Hashable` holder) gave everything needed. (b) The holder is a `String` constant in `SpikeView`, inside `#if DEBUG` with the rest of the view, so nothing of it reaches Release. |
| M1-9 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 49 tests in 11 suites passed after 0.035 seconds."; `** TEST SUCCEEDED **` (48 + 1). **Changes:** (a) `Extraction/RecipeStructurer.swift` (SLT-151): step 3 no longer branches. `otherRecipeTitles(…)` feeds the new `static func otherRecipesWarning(_:) -> String?` (`may hold other recipes: ` + titles joined with `; `, nil for none), whose warning joins the recipe's warnings, and structuring goes on in parts. `outcome.path` is always `parts`. `TokenCap.oneShot`, the one-shot branch, `OneShotFailed` and the now-unused `pageSeparator` are removed. `makeRecipe` and `GeneratedRecipe.swift` stay. New `StructuringFailed` (`Error`, `CustomStringConvertible`; `outcome`, `underlying`, with `description` = the underlying error's): `structure` now runs its steps into an `inout` outcome, rethrows a rate limit unchanged (SLT-144), and throws anything else as `StructuringFailed` with the outcome so far. `StructuringOutcome` gains `headerTitle: String?` and `otherTitles: [String]` to carry the two new report fields. (b) `Spike/SpikeReport.swift`: `SpikeCaptureResult` gains `headerTitle: String?` and `otherTitles: [String]`. (c) `Spike/SpikeRunner.swift`: `finishReport()` runs after every capture in `runAll` (done, failed or waiting), after each capture structured by the waiting-capture pass, and after a cancel. One `copyDiagnostics` copies `partMillis`, `partErrors`, `retried`, `fallbacks`, `usedLineLabels`, `headerTitle` and `otherTitles` on success, and from `StructuringFailed.outcome` before `fail`. (d) `SylantroTests/Extraction/RecipeStructurerTests.swift`: test 30, "other titles become a warning". `Views/Spike/SpikeView.swift` needed no change: `Export Results` was already `.disabled(runner.report == nil)` with no running check, so it is enabled whenever a report exists. The report now exists after the first capture. **Clauses:** ✅ 1 `grep -n "oneShot" Sylantro/Sylantro/Extraction/RecipeStructurer.swift` finds nothing (exit 1). ✅ 2 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-9-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". All 49 tests pass, and no earlier test changed (the test file only gained test 30, 8 lines). ✅ 3 **Release spike check:** Release `Sylantro.app/Sylantro` (no separate dylib): `nm -a` has 0 symbols matching `spike` or `TestSetGroups`, and `strings` has 0 matches for `spike`, `Accuracy`, `Waiting for Sylantro`, `Load Test Set`, `spikeTestSetFolder` or `Close the accuracy spike`. The same binary has 16 pipeline symbols. Control: the Debug `Sylantro.debug.dylib` has 2,398 `spike`/`TestSetGroups` symbols and 1 `Close the accuracy spike` string. ✅ 4 only `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift` and `RecipeStructurerTests.swift` changed, plus this row (a subset of the list; `SpikeView.swift` not needed). ✅ 5 below. **Git status before** (branch `milestone-1`): `MM` the ledger, `10`, `11`, `README.md` and `SpikeView.swift` (M1-8's unstaged alert change); everything else staged (`M ` or `A `), including `00B`, M1-5 to M1-7's files and `SpikeRunnerTests.swift`. **After:** the same, plus `MM` on `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift` and `RecipeStructurerTests.swift`. `SpikeView.swift`'s unstaged diff is still only M1-8's 3 lines. **Git:** `git status --short` (×3), `git branch --list`, `git diff --stat`. **Notes:** (a) With the one-shot path gone, every model call goes through `call`, which catches every error that isn't a rate limit. So `StructuringFailed` is thrown only for an error outside those calls; none is reachable today. It is in place as M1-9 asks, so a failure path added later keeps its diagnostics. (b) `GeneratedCapture`, in `GeneratedRecipe.swift`, is no longer used anywhere. M1-3's tests use only `GeneratedRecipe` and `makeRecipe`. It stays because M1-9 keeps that file unchanged; it belongs with §1's removal note. |
| M1-8 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 48 tests in 11 suites passed after 0.042 seconds."; `** TEST SUCCEEDED **`. **Change:** in `Views/Spike/SpikeView.swift` only, `.confirmationDialog("Close the accuracy spike?", isPresented: $isConfirmingClose, titleVisibility: .visible)` became `.alert("Close the accuracy spike?", isPresented: $isConfirmingClose)` (SLT-088, `00B` §3). The buttons `Close` (`.destructive`, cancelling `runTask` and dismissing, as before) and `Cancel` (`.cancel`) and the message are unchanged. One code comment cites SLT-088. **Clauses:** ✅ 1 `grep -rn "confirmationDialog\|actionSheet\|\.popover" Sylantro/Sylantro` (run from `PROJ/` as `grep -rn … Sylantro`) finds nothing (exit 1). ✅ 2 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-8-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". All 48 tests pass. ✅ 3 **Release spike check:** Release `Sylantro.app/Sylantro` (no separate dylib): `nm -a` has 0 symbols matching `spike` or `TestSetGroups`, and `strings` has 0 matches for `spike`, `Accuracy`, `Waiting for Sylantro`, `Load Test Set`, `spikeTestSetFolder` or `Close the accuracy spike`. The same binary has 16 pipeline symbols. Control: the Debug `Sylantro.debug.dylib` has 2,370 `spike`/`TestSetGroups` symbols and 1 `Close the accuracy spike` string. ✅ 4 below. **Git status before** (branch `milestone-1`): as M1-7's "After", plus Pops's ` M Docs/00B_SYLANTRO_GUARDRAILS.md` (the new alerts rule). **After:** Pops staged the other changes during the session. The only entries with unstaged changes are `MM Sylantro/Views/Spike/SpikeView.swift` (this change) and `MM Docs/11_MILESTONE_1_SPIKE.md` (this row); everything else is staged (`M ` or `A `). **Git:** `git status --short` (×2), `git branch --list`. |
| M1-7 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 48 tests in 11 suites passed after 0.036 seconds."; `** TEST SUCCEEDED **` (unchanged at 48; no tests added). **Clauses:** ✅ 1 only the three files changed. (a) `Views/Settings/SettingsSheet.swift`: the `#if DEBUG` row is now a `Button` titled `Accuracy spike` that sets `@State isShowingSpike`. `.sheet(isPresented: $isShowingSpike) { NavigationStack { SpikeView() } }` presents it. The Section keeps `.paletteRowBackground()`. The `@State` and the `.sheet` are inside `#if DEBUG` too. (b) `Views/Spike/SpikeView.swift`: the first Section, with no header, holds an `HStack` with `CapsuleButton("Load Test Set")` (disabled while running) and `CapsuleButton("Run All", style: .accent)` (disabled while running or with no captures). The toolbar has `Done` (`.confirmationAction`) and a `Menu` labelled `Image(systemName: "ellipsis.circle")` (`.topBarLeading`) holding `Add Capture`, `Export Results` (disabled with no report) and `Clear`. `.interactiveDismissDisabled()` is set. The `.confirmationDialog` has the title `Close the accuracy spike?` (shown), the message as given, `Close` (destructive) and `Cancel`. Close cancels the Run All task kept in `@State runTask` and dismisses. The empty-list hint is `Tap Load Test Set to load the test pages.` (c) `Extraction/Spike/SpikeRunner.swift`: `runAll` checks `Task.isCancelled` before each capture's read and before its structuring. Once cancelled it stops, skips the waiting-capture pass and the report, and sets `isRunning` back to false. A cancelled timed rate-limit wait doesn't retry; the capture is left waiting for the app. ✅ 2 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-7-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped". All 48 tests pass. ✅ 3 **Release spike check:** Release `Sylantro.app/Sylantro` (no separate dylib): `nm -a` has 0 symbols matching `spike` or `TestSetGroups`, and `strings` has 0 matches for `spike`, `Accuracy`, `Waiting for Sylantro`, `Load Test Set`, `spikeTestSetFolder` or `Close the accuracy spike`. The same binary has 16 pipeline symbols (`RecipeStructurer`, `RecipeValidator`, `PageSplitter`, `TextReader`, `HeaderArea`, `ScriptCheck`, `PageClutter`, `TextMatch`). Control: the Debug `Sylantro.debug.dylib` has 2,370 `spike`/`TestSetGroups` symbols and 1 `Close the accuracy spike` string. ✅ 4 below. **Git status before** (branch `milestone-1`): as M1-6's "After": ` M` the ledger, `10`, `TextMatch.swift` and `SpikeView.swift`; `MM` `11`, `README.md`, `GeneratedParts.swift`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift` and `RecipeStructurerTests.swift`; `AM StructuringRulesTests.swift`; M1-5's staged files; `??` `TestSetGroups.swift` and `SpikeRunnerTests.swift`. **After:** the same, plus ` M Sylantro/Views/Settings/SettingsSheet.swift`. `SpikeView.swift`, `SpikeRunner.swift` and `11` were already modified, so they show the same letters. **Git:** `git status --short` (×3), `git branch --list`. **Notes:** decisions where M1-7 is silent, for review: (a) The Settings row's label has `.foregroundStyle(.primary)`, as the iCloud row's does, so as a `Button` it still reads like the `NavigationLink` it replaced, without the chevron. The spike sheet gets no `.appTextSizeCap()`, which M1-7 didn't name; the iCloud sheet has one. (b) `Load Test Set` is synchronous (it resolves the bookmark and lists the folder), so it starts no task and only Run All's task is kept for Close to cancel. (c) The ••• menu's label is the symbol alone, so no copy was added; VoiceOver reads the symbol's built-in name. (d) `runAll` also stops if the captures were cleared mid-run (`captures.indices.contains(index)`). Before, a Clear during a run could index past the end. (e) Close dismisses the sheet, and the runner goes with it; it doesn't call `clear()`. So a loaded test folder's security-scoped access isn't explicitly ended, and it lapses with the runner. Reported, not changed: M1-7 names only cancel and dismiss. |
| M1-6 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 48 tests in 11 suites passed after 0.038 seconds."; `** TEST SUCCEEDED **` (43 + 5). **SDK, bookmark API included:** no difference from what M1-6 assumes. `URL.bookmarkData()` (all parameters defaulted) and `URL(resolvingBookmarkData:bookmarkDataIsStale:)` compile against the pinned SDK as written. iOS has no `.withSecurityScope` option, and M1-6 doesn't ask for one. `UTType.folder` and `Task.sleep(for: Duration)` are as assumed. **Clauses:** ✅ 1 changed: `Domain/Structuring/TextMatch.swift` (`isEmptyAnswer`), `Extraction/GeneratedParts.swift` (the `otherTitles` description, verbatim; its type stays `[String]?`), `Extraction/RecipeStructurer.swift` (`otherRecipeTitles` gates the one-shot path, with the title computed first in step 3; `nonEmpty` uses `isEmptyAnswer`), `Spike/SpikeRunner.swift`, `Spike/SpikeReport.swift` (`rateLimitRetries`) and `Views/Spike/SpikeView.swift`. New: `Extraction/Spike/TestSetGroups.swift` (`#if DEBUG`) and `SylantroTests/Extraction/SpikeRunnerTests.swift` (`#if DEBUG`, like the code it tests). All 26 `import` lines under `Domain/` are `import Foundation`. ✅ 2 tests 25 to 29 pass. Against the index (M1-5 as Pops staged it), `git diff --numstat` shows only added lines in `StructuringRulesTests` (11) and `RecipeStructurerTests` (24). No earlier test changed. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-6-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped"; no fixes were needed. ✅ 4 **Release spike check:** Release `Sylantro.app/Sylantro` (no separate dylib): `nm -a` has 0 symbols matching `spike` or `TestSetGroups`, and `strings` has 0 matches for `spike`, `Accuracy`, `Waiting for Sylantro`, `Load Test Set` or `spikeTestSetFolder`. The same binary has 16 symbols matching `RecipeStructurer`, `RecipeValidator`, `PageSplitter`, `TextReader`, `HeaderArea`, `ScriptCheck`, `PageClutter` or `TextMatch`. Control: the Debug `Sylantro.debug.dylib` has 2,376 symbols matching `spike` or `TestSetGroups`. ✅ 5 no file outside M1-6's list changed except this row. ✅ 6 below. **Git status before** (branch `milestone-1`): ` M Docs/00_DECISION_LEDGER.md`, ` M Docs/10_ACCURACY_TEST_SET.md`, `MM Docs/11_MILESTONE_1_SPIKE.md`, `MM Docs/README.md`, and M1-5's files staged by Pops: `A ` `HeaderArea.swift`, `PageClutter.swift`, `ScriptCheck.swift` and `StructuringRulesTests.swift`; `M ` `PageRules.swift`, `PageSplitter.swift`, `SplitPage.swift`, `GeneratedParts.swift`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `PageRulesTests.swift`, `PageSplitterTests.swift` and `RecipeStructurerTests.swift`. **After:** the same index. Unstaged edits from this session: ` M TextMatch.swift`, ` M SpikeView.swift`, `MM` `GeneratedParts.swift`, `RecipeStructurer.swift`, `SpikeReport.swift` and `SpikeRunner.swift`, `AM StructuringRulesTests.swift`, `MM RecipeStructurerTests.swift`, `?? Extraction/Spike/TestSetGroups.swift`, `?? SylantroTests/Extraction/SpikeRunnerTests.swift`, and this row in `11`. **Git:** `git status --short` (×3), `git branch --list`, `git diff --numstat -- Sylantro/SylantroTests`. **Notes:** decisions where M1-6 is silent, for review: (a) "Menu item": `SpikeView`'s actions are toolbar buttons, so `Load Test Set` is a toolbar `Button` before `Add Capture`, disabled while running; iOS gathers what doesn't fit into the toolbar's overflow menu. The view keeps one `.fileImporter`, switched between photos (multiple `.image`) and the folder (`.folder`), because two importers on one view don't both present. (b) `otherRecipeTitles` drops duplicates by normalized text, and ignores an entry that normalizes to nothing. (c) Timed retry: the refusal count is per call of `structure(index)`, so a capture resumed after `waitingForApp` gets three more timed retries. `rateLimitRetries` counts the retries actually made, totalled across the run. (d) `SpikeRunner` checks that the capture at the index is still the same one (by `id`) after every `await` in `structure`, so a Clear or Load Test Set during a 30-second wait can't write to the wrong capture or crash. Before, a Clear during structuring could hit an index out of range. (e) `loadTestSet` always saves the bookmark again after listing, which is how `loadSavedTestSet` renews a stale one. If the folder can't be listed, the captures are left as they were and the error is logged. `loadSavedTestSet` returns true once a bookmark resolves, even if the listing then fails. (f) `TestSetGroups` matches `TP-` case-sensitively; the extension is any case. Names with the same page number sort by name. The key `spikeTestSetFolder` is a constant on `SpikeRunner` (`testSetFolderKey`), not in `SettingsKey`, because it is Debug-only spike state. |
| M1-5 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 43 tests in 10 suites passed after 0.051 seconds."; `** TEST SUCCEEDED **` (31 + 12). **SDK:** nothing M1-5 assumes differs from the pinned SDK. The new `@Generable` shapes (`Int`, `Bool?`, `[String]?`) build, and no API beyond M1-4's is used. **Clauses:** ✅ 1 new: `Domain/Structuring/PageClutter.swift`, `ScriptCheck.swift`, `HeaderArea.swift` (`HeaderLine` nested), `SylantroTests/Domain/StructuringRulesTests.swift`. Changed: `PageSplitter`, `SplitPage`, `PageRules`, `GeneratedParts`, `RecipeStructurer`, `SpikeReport`, `SpikeRunner`, and the tests in `PageSplitterTests`, `PageRulesTests` and `RecipeStructurerTests`. All 26 `import` lines under `Domain/` are `import Foundation`. `GeneratedRecipe.swift`, `RecipeValidator.swift`, `TextReader.swift` and `SpikeView.swift` are unchanged. ✅ 2 tests 13 to 24 pass. Earlier tests: `git diff --numstat` shows only added lines in `PageRulesTests` (6) and `PageSplitterTests` (20). The 9 removed lines in `RecipeStructurerTests` are all in test 12, which now calls the new `assemble(title:header:ingredientGroups:…)`. Its ingredients are built through `ingredientGroups(from:lines:)` from the line `2 cups water`, so the parser is still exercised. Its header is `GeneratedHeader(titleFirstLine: 1, titleLastLine: 1, …)`, and its expectations are the same except `promptVersion` 3. No other test changed. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-5-release-dd`) both build. The only warning is the existing appintentsmetadataprocessor "Metadata extraction skipped"; no fixes were needed. ✅ 4 **Release spike check:** Release `Sylantro.app/Sylantro` (no separate dylib): `nm -a` has 0 symbols matching `spike`, and `strings` has 0 matches for `spike`, `Accuracy` or `Waiting for Sylantro`. The same binary has 14 symbols matching `RecipeStructurer`, `RecipeValidator`, `PageSplitter`, `TextReader`, `HeaderArea`, `ScriptCheck` or `PageClutter`. Control: the Debug `Sylantro.debug.dylib` has 2,049 `spike` symbols. ✅ 5 no file outside M1-5's list changed except this row. ✅ 6 below. **Git status before** (branch `milestone-1`): clean, with no entries. **After:** ` M` `Domain/Structuring/PageRules.swift`, `PageSplitter.swift`, `SplitPage.swift`, `Extraction/GeneratedParts.swift`, `RecipeStructurer.swift`, `Spike/SpikeReport.swift`, `Spike/SpikeRunner.swift`, `SylantroTests/Domain/PageRulesTests.swift`, `PageSplitterTests.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift` and `Docs/11_MILESTONE_1_SPIKE.md` (this row). `??` `Domain/Structuring/HeaderArea.swift`, `PageClutter.swift`, `ScriptCheck.swift` and `SylantroTests/Domain/StructuringRulesTests.swift`. **Git:** `git status --short` (×3), `git branch --list`, `git diff --numstat -- Sylantro/SylantroTests`. **Notes:** decisions where M1-5 is silent, for review: (a) `PageSplitter.Section` is now internal, so `heading(_:)` can be internal as M1-5 asks. (b) `HeaderArea`: the median of an even count is the mean of the middle two. When no height is above 0, every size is 1.0. `stopAt` is the first `ingredient` or `step` label's number minus 1. Labels are numbered across the readable lines, so an index past page 1 just takes the page's first 25 lines. (c) With line labels, a clutter line is dropped from every labelled section too (SLT-149), and `unsectioned`, equipment and nutrition stay as the headings found them. (d) The one-shot path now sends only the readable lines, page texts joined with M1-3's separator. Each one-shot recipe also gets the capture's `unreadableAreas` and `unreadable line` warnings, so SLT-150 holds on that path. It is retried like the other parts. If the retry fails too, `structure` throws an error whose description is the retry's error, so the capture fails as in M1-3/M1-4. (e) A fallback (`ingredients fallback`, `steps fallback` in `partMillis` and `partErrors`) is listed in `fallbacks` when made. Its `… from whole page` warning is added only when it returns an answer. The steps fallback uses the steps call's form (lines joined by `\n`, cap 2,000). The ingredients fallback maps against every readable line, so it also warns `unused ingredient line <n>` for each line that isn't an ingredient. That is literal to M1-5, but noisy. (f) A group name over 40 characters is not used, so its line also gets `unused ingredient line <n>`. (g) `unreadableLines` in the report is counted by the runner, from the readings with `ScriptCheck.isLatin`, the same test step 1 uses. `StructuringOutcome` gained only `retried` and `fallbacks`, as M1-5 says. (h) A line whose page has no page ID still gets its `unreadable line` warning, but no `SourceBox`. This can't happen in the spike, where every page has an ID. |
| M1-4 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 31 tests in 9 suites passed after 0.031 seconds."; `** TEST SUCCEEDED **` (19 + 12). **SDK gate:** `RecognizeTextRequest.automaticallyDetectsLanguage` exists and is set to `false` in both requests. `LanguageModelSession.GenerationError.rateLimited` exists in the pinned SDK (iPhoneSimulator27.2), but it is deprecated from iOS 27 with "Use `LanguageModelError/rateLimited(_:)` instead", and `LanguageModelError` is iOS 27 only. `GenerationOptions(sampling:…)` is deprecated (renamed `samplingMode:`). **Asked of Pops in the session:** (1) a rate-limit refusal is recognized as either `GenerationError.rateLimited` or, under `#available(iOS 27.0, *)`, `LanguageModelError.rateLimited` (`RecipeStructurer.isRateLimit`), since his phone runs iOS 27.2.1. (2) calls use `GenerationOptions(samplingMode: .greedy, maximumResponseTokens:)`, which behaves the same, is back-deployed to 26 and raises no warning. **Clauses:** ✅ 1 `Domain/Structuring/` holds `TextMatch`, `PageSplitter`, `SplitPage`, `PageRules`, `RuleFields` and `RecipeValidator`, all `nonisolated`. All 23 `import` lines under `Domain/` are `import Foundation`. `Extraction/GeneratedParts.swift` is new. `RecipeStructurer.swift`, `TextReader.swift`, `Spike/SpikeReport.swift`, `Spike/SpikeRunner.swift` and `Views/Spike/SpikeView.swift` are changed as M1-4 says. The new tests are `SylantroTests/Domain/PageSplitterTests.swift`, `PageRulesTests.swift` and `RecipeValidatorTests.swift`, plus test 12 in `RecipeStructurerTests.swift`. `GeneratedRecipe.swift` is unchanged. ✅ 2 the 12 new tests pass. M1-3's 3 structurer tests pass unchanged: `makeRecipe`'s output is the same, and it now shares `makeGroup` and `makeSteps` with `assemble`. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-4-release-dd`) both succeed. The only warning is the existing appintentsmetadataprocessor one. One error from this session was fixed: `RecipeValidator` "overlapping accesses to 'recipe.attribution'", fixed by copying `attribution` to a local before checking it. ✅ 4 Release `Sylantro.app/Sylantro`: `nm -a` has 0 symbols matching `spike`, and `strings` has 0 matches for `spike`, `Accuracy` or `Waiting for Sylantro`. The same binary has 8 symbols matching `RecipeStructurer`, `RecipeValidator`, `PageSplitter` or `TextReader`. Control: the Debug `Sylantro.debug.dylib` has 2,007 `spike` symbols. ✅ 5 no file outside M1-4's list changed except this row. ✅ 6 git status is below. **Git status before** (branch `milestone-1`): `A .gitignore`; `MM` the ledger, `10` and `README.md`; `M ` `01` and `06`; `AM` `11`; `D ` the 3 xcuserdata files; `A ` M1-1's and M1-2's files; ` M Views/Settings/SettingsSheet.swift`, `??` `Extraction/`, `Views/Spike/` and `SylantroTests/Extraction/` (M1-3's work, not yet staged); `?? Docs/12_IMPLEMENTATION_PLAN.md`. **After:** the same, plus `?? Sylantro/Domain/Structuring/`, `??` the three new Domain test files, and this row in `11`. M1-3's files are still untracked, so M1-4's edits to them don't show as a separate diff. **Git:** `git status --short` (×2), `git branch --list`. **Notes:** decisions where 11 is silent, for review: (a) `TextMatch` keeps its own copy of M1-2's unicode-fraction table, because `IngredientLineParser`'s copy is `private` and that file is outside this task. That is two copies of one constant (`00A` §10); making the parser's table shared is a one-line follow-up. (b) `PageRules` yield: each `|`-separated part of a line is tested for starting with the word. That is the only reading under which test 7 gives `SERVES 4`, because the line starts with `PREP`. (c) `RecipeValidator`: an empty or nil title, group name, notes, nutrition, author or publisher is not checked, so a missing value gets no warning. The copied-step length (more than 60) is measured on the normalized `rawText`. A removed copied step gets only `ingredient <n> is a step`, not also `not on page`. An `Extraction` is created only when there is a warning. (d) `RecipeStructurer`: a line-labels or header call that throws something other than a rate limit is recorded in `partErrors` like the ingredients and steps calls, and structuring goes on: unlabelled sections, or no header. A header with no lines is skipped. The one-shot call rethrows as in M1-3. With line labels, equipment and nutrition keep what the headings found. `partMillis` keys are `lineLabels`, `header`, `ingredients`, `steps` and `oneShot`. `structureMillis` is the sum of `partMillis`. `StructuringOutcome` sits in `RecipeStructurer.swift`, and the caps are `RecipeStructurer.TokenCap`. (e) `SpikeRunner`: Run All resets every capture and reads them all. Each read capture is structured only if the scene is active; otherwise it waits. After the loop, and on `sceneBecameActive()` when not already running, waiting captures are structured in order. The report is rebuilt each time. A capture rate-limited while the scene is still active waits until the scene next becomes active. |
| M1-3 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 19 tests in 6 suites passed after 0.035 seconds."; `** TEST SUCCEEDED **` (16 + 3). **Clauses:** ✅ 1 `Extraction/TextReader.swift`, `PageReading.swift`, `GeneratedRecipe.swift`, `RecipeStructurer.swift`, `Extraction/Spike/SpikeReport.swift`, `SpikeRunner.swift`, `Views/Spike/SpikeView.swift`, the Settings row, and `SylantroTests/Extraction/RecipeStructurerTests.swift` all exist. `Domain/` is unchanged (no `Domain/` path in `git status`). ✅ 2 the 3 tests, `@Suite("Recipe structurer mapping")`, named as in M1-3, pass. They build `GeneratedRecipe` with its memberwise init, so `import FoundationModels` wasn't needed. ✅ 3 Debug builds through the test run, and Release with `xcodebuild build … -configuration Release` (same destination, `-derivedDataPath /tmp/m1-3-release-dd`): `** BUILD SUCCEEDED **`. The only warning in either is the existing appintentsmetadataprocessor "Metadata extraction skipped". The first Debug run had one new warning, `SpikeView.swift:59` "call to main actor-isolated static method 'fileName' in a synchronous nonisolated context", fixed by calling it in a closure (`runner.report.map { Self.fileName($0) }`) before the run above. ✅ 4 **No spike code in Release:** `nm -a` on the Release `Sylantro.app/Sylantro` has 0 symbols matching `spike` (case-insensitive), and `strings` has 0 matches for `spike` or `Accuracy`. In the same binary, 4 symbols match `RecipeStructurer` or `TextReader`, so the check does see app symbols. As a control, the Debug build's `Sylantro.debug.dylib` has 1,737 symbols matching `spike`. ✅ 5 my edits outside the new files are the one `#if DEBUG` Section in `SettingsSheet.swift` and this row. ✅ 6 git status before and after is below. **Vision API:** the Swift `RecognizeTextRequest` compiles against the pinned SDK and is used (`.accurate` / `.fast`, `usesLanguageCorrection = true`, `recognitionLanguages = [en-US]`, `regionOfInterest = NormalizedRect(x: 0, y: 0, width: 1, height: fraction)` for the bottom read). **Asked of Pops in the session** (11 didn't say): the row detail's `<r>` is the total of the capture's `readMillis`; when a capture isn't structured, the ` · structure <s> ms` part is left out. **Git status before** (branch `milestone-1`): Pops's staged M1-1 and M1-2 files, `.gitignore`, the 3 deleted xcuserdata files; `MM` on `00_DECISION_LEDGER.md`, `01_INGESTION_DESIGN.md`, `06_MILESTONE_1_DOMAIN.md` and `README.md`; ` M Docs/10_ACCURACY_TEST_SET.md`; `?? Docs/11_MILESTONE_1_SPIKE.md`. **After:** Pops staged docs during the session, so the ledger, `01`, `06`, `10` and `README.md` are now `M ` and `11` is `AM` (staged, plus this row unstaged). My own changes are ` M Sylantro/Views/Settings/SettingsSheet.swift`, `?? Sylantro/Extraction/`, `?? Sylantro/Views/Spike/`, `?? SylantroTests/Extraction/` and this row. **Git:** `git status --short` (×2), `git branch --list`. **Notes:** (a) `readBottom`'s boxes are taken as Vision returns them for the region of interest and flipped to top left. I didn't check whether Vision reports them relative to the region or to the whole page; only the text and the time are used in this task. (b) The Settings row's Section has `.paletteRowBackground()` like the sheet's other sections; 11 named no styling for it. (c) `fileExporter`'s `defaultFilename` is `spike-results-<yyyy-MM-dd-HHmm>` from `runAt`, with no extension, expecting the `.json` content type to add `.json`; Pops's device check should confirm the name. (d) Images load with ImageIO's transformed full-size thumbnail (`kCGImageSourceCreateThumbnailWithTransform`) to make them upright. (e) The spike has no `SourcePage`s, so `SpikeRunner` gives each page a new `UUID` for `pageIDs` each run. (f) The structurer reads `SystemLanguageModel.default` and calls `respond(to:generating:)` with no options; no network call is made anywhere. |

---

## 3. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.29 | Task M1-15: the title starts at the model's first line; site-name and author lines dropped; the size trim removed; then run 6 | SLT-148 rewritten (Pops, 22 Nov 2026 (decision card, "SP-19, then run 6")) |
| 0.28 | M1-14 complete | M1-14 Results log |
| 0.27 | Task M1-14: no-title and trimmed titles, the title unchecked, group names by rule, each line used once, "a few" and "-inch"; then run 5 | SLT-146, SLT-148 rewritten; SLT-155 (Pops, 22 Nov 2026 (decision card, "All four, SP-15 to SP-18")) |
| 0.26 | M1-13 complete | M1-13 Results log |
| 0.25 | Task M1-13: a progress bar and `n / m` processed on the spike sheet; the flag's doc comment corrected | Pops, 22 Nov 2026: "add a stats section between the buttons and list of images that shows a progress bar and n / m of how much we processed." |
| 0.24 | M1-12 complete | M1-12 Results log |
| 0.23 | M1-12: the flag's doc comment names when it goes off (App Store copy, on the way to RC0) | SLT-093 (Pops, 22 Nov 2026: "my partner will only be using testflight builds, and i want to keep this on during beta test. just need to be reinded to turn it off once we start writing app store copy headed to RC0.") |
| 0.22 | M1-12: the flag stays on in every build, App Store included | SLT-093 (Pops, 22 Nov 2026 (decision card, "Leave it on everywhere")) |
| 0.21 | M1-12 also disables Clear when there is nothing to clear | Pops, 22 Nov 2026: "the clear menu item should be disabled if there's nothing to clear" |
| 0.20 | Task M1-12: the spike behind `AppConfig.AccuracySpike.isEnabled` in every build, no `#if DEBUG` | SLT-093 rewritten (Pops, 22 Nov 2026: "I want to leave the accuracy spike in the app for now, so just put it behind a appconfig flag and no if DEBUG") |
| 0.19 | M1-11 complete | M1-11 Results log |
| 0.18 | M1-11 also moves Export Results out of the menu to a capsule after Run All, with the button row in SyLibUI's `FlowLayout` | Pops, 22 Nov 2026: "move the export button out of the menu and after the run button, be sure to use FlowLayout if you are not already." |
| 0.17 | Task M1-11: title as text snapped to the page, wrapped lines joined by rule, labelled lines cleaned; then run 4 | SLT-146, SLT-148, SLT-149 rewritten (Pops, 22 Nov 2026: "all") |
| 0.16 | M1-10 complete | M1-10 Results log |
| 0.15 | Task M1-10: the spike sheet keeps the screen awake through SyLib's `ScreenAwake` | Pops, 22 Nov 2026: "we should just keep the screen awake when on the Accuracy Pike sheet. SyJong and Syderal have a setting for that, and I think there's helpers in SyLib to do it." |
| 0.14 | M1-9 complete | M1-9 Results log |
| 0.13 | Task M1-9: the one-call path retired, other titles flagged; the report built after every capture and exportable mid-run, failures included | SLT-151 (Pops, 22 Nov 2026 (decision card, "Always use parts; flag it")); Pops, 22 Nov 2026: "export results button is still disabled when some fail. seems like I should be able to export the failed results too..." |
| 0.12 | M1-8 complete | M1-8 Results log |
| 0.11 | Task M1-8: the close confirmation becomes a plain `.alert` | SLT-088 (Pops, 22 Nov 2026: "all alerts should be normal alerts and not try to point to anything. swfitui still is furbar with this.") |
| 0.10 | M1-7 complete | M1-7 Results log |
| 0.9 | Task M1-7: the spike screen as a sheet closed only from Done after a confirmation; Load Test Set and Run All as capsule buttons atop the list; Add Capture, Export Results and Clear in a menu | Pops, 22 Nov 2026: "take the Load Test Set and Add Capture buttons out of the tool bar and just put them horizontally at the top of the list using CapsuleButton. also the page is too easy to accidently dismiss, it shoudl be a sheet that only dismisses with a tap of a Done button and a confirmation."; "move the Run button out of the menu and put Add Capture to the menu if we keep ti" |
| 0.8 | M1-6 complete | M1-6 Results log |
| 0.7 | Task M1-6: run 3's three fixes (the several-recipes path gated by the page, "none" is empty, a timed retry after a refusal) and Load Test Set | SLT-151 to SLT-153 (Pops, 22 Nov 2026 (decision card, "M1-6: all three fixes")); SLT-154 (Pops, 22 Nov 2026: "can this just be setup without me adding all those damn files?"; decision card, "Pick the folder once (Files)") |
| 0.6 | M1-5 complete; §1: the noisy ingredients fallback noted | M1-5 Results log |
| 0.5 | Task M1-5: ingredient lines and the title by line number, retry and fallback, clutter and equipment and times kept to their sections, non-Latin lines unreadable; then spike run 3 | SLT-146 to SLT-150 (Pops, 22 Nov 2026: "All") |
| 0.4 | M1-4 complete; §1: the duplicate fraction table and the foreground rate limit noted | M1-4 Results log |
| 0.3 | Task M1-4: structuring in parts, capped output, the found-on-the-page check, rule-based fields, foreground-only structuring, language detection off; then spike run 2 | SLT-140 to SLT-145 (Pops, 22 Nov 2026: "all six") |
| 0.2 | M1-3 complete; the row detail's two details Pops settled in the session written into the copy table | M1-3 Results log |
| 0.1 | First version: Task M1-3, the reader, the structurer and a debug-only spike screen; runs on Pops's iPhone 18 Pro | SLT-093 (Pops, 22 Nov 2026 (decision card, "Hidden spike screen in Sylantro")); SLT-017 (Pops, 22 Nov 2026: "we wont be running on my partners phone, she hates when I do that...we will use my iphone 18 pro.") |
