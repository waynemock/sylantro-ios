# Sylantro — Milestone 1: The Accuracy Spike

**A Syzygy Softwerks task document · a hidden, debug-only screen that reads and structures test
pages on Pops's iPhone and exports the results for scoring**
Version 0.5 · 22 November 2026 · Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md`,
`00B_SYLANTRO_GUARDRAILS.md`, `02_ARCHITECTURE.md` §2, §4 and §8, and `06_MILESTONE_1_DOMAIN.md`'s
types and parser.

---

## 0. What this is

Milestone 1 is an accuracy spike and a tested Domain layer (SLT-090). `06` built the Domain half
(M1-1, M1-2). This document is the spike half: M1-3 builds the first real pieces of
the extraction pipeline (`02` §4) and a hidden screen to run them on the test pages (SLT-093);
M1-4 and M1-5 refine the structurer from each spike run's results.

**How the spike runs** (SLT-093, SLT-017):

1. Pops copies the test photos (`~/GIT/Syzygy/sylantro-testpages/Pages/`) to his **iPhone 18 Pro**
   by AirDrop into a folder in Files. They never enter the repository (SLT-092, `00B` §2).
2. He runs a **Debug** build of Sylantro on that phone, opens Settings, and taps **Accuracy spike**.
   Release builds have no such row.
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

## 1. Open in this document

- **Two copies of the unicode-fraction table** (M1-4 Results, note (a)): `TextMatch` and
  `IngredientLineParser` each hold one. A later task makes the parser's table the shared one
  (`00A` §10).
- **A rate limit while Sylantro is in front** waits until the app is next brought back to the front
  (M1-4 Results, note (e)). For `ExtractionQueue` (Milestone 3), a timed retry may be needed too.
- Vision's newer document reading (`RecognizeDocumentsRequest`, iOS 26) returns paragraphs, lists
  and tables, which may help multi-column pages (`10` H-6, H-38). Not in M1-3; worth a second run
  if the spike's column results are poor.
- Long recipes may exceed the model's context. M1-4 structures in parts (SLT-140) and caps each
  part's output (SLT-141); M1-5 retries a part that reaches its cap (SLT-147).

---

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| M1-4 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 31 tests in 9 suites passed after 0.031 seconds."; `** TEST SUCCEEDED **` (19 + 12). **SDK gate:** `RecognizeTextRequest.automaticallyDetectsLanguage` exists and is set to `false` in both requests. `LanguageModelSession.GenerationError.rateLimited` exists in the pinned SDK (iPhoneSimulator27.2), but it is deprecated from iOS 27 with "Use `LanguageModelError/rateLimited(_:)` instead", and `LanguageModelError` is iOS 27 only. `GenerationOptions(sampling:…)` is deprecated (renamed `samplingMode:`). **Asked of Pops in the session:** (1) a rate-limit refusal is recognized as either `GenerationError.rateLimited` or, under `#available(iOS 27.0, *)`, `LanguageModelError.rateLimited` (`RecipeStructurer.isRateLimit`), since his phone runs iOS 27.2.1. (2) calls use `GenerationOptions(samplingMode: .greedy, maximumResponseTokens:)`, which behaves the same, is back-deployed to 26 and raises no warning. **Clauses:** ✅ 1 `Domain/Structuring/` holds `TextMatch`, `PageSplitter`, `SplitPage`, `PageRules`, `RuleFields` and `RecipeValidator`, all `nonisolated`. All 23 `import` lines under `Domain/` are `import Foundation`. `Extraction/GeneratedParts.swift` is new. `RecipeStructurer.swift`, `TextReader.swift`, `Spike/SpikeReport.swift`, `Spike/SpikeRunner.swift` and `Views/Spike/SpikeView.swift` are changed as M1-4 says. The new tests are `SylantroTests/Domain/PageSplitterTests.swift`, `PageRulesTests.swift` and `RecipeValidatorTests.swift`, plus test 12 in `RecipeStructurerTests.swift`. `GeneratedRecipe.swift` is unchanged. ✅ 2 the 12 new tests pass. M1-3's 3 structurer tests pass unchanged: `makeRecipe`'s output is the same, and it now shares `makeGroup` and `makeSteps` with `assemble`. ✅ 3 Debug (the test run) and Release (`xcodebuild build … -configuration Release`, same destination, `-derivedDataPath /tmp/m1-4-release-dd`) both succeed. The only warning is the existing appintentsmetadataprocessor one. One error from this session was fixed: `RecipeValidator` "overlapping accesses to 'recipe.attribution'", fixed by copying `attribution` to a local before checking it. ✅ 4 Release `Sylantro.app/Sylantro`: `nm -a` has 0 symbols matching `spike`, and `strings` has 0 matches for `spike`, `Accuracy` or `Waiting for Sylantro`. The same binary has 8 symbols matching `RecipeStructurer`, `RecipeValidator`, `PageSplitter` or `TextReader`. Control: the Debug `Sylantro.debug.dylib` has 2,007 `spike` symbols. ✅ 5 no file outside M1-4's list changed except this row. ✅ 6 git status is below. **Git status before** (branch `milestone-1`): `A .gitignore`; `MM` the ledger, `10` and `README.md`; `M ` `01` and `06`; `AM` `11`; `D ` the 3 xcuserdata files; `A ` M1-1's and M1-2's files; ` M Views/Settings/SettingsSheet.swift`, `??` `Extraction/`, `Views/Spike/` and `SylantroTests/Extraction/` (M1-3's work, not yet staged); `?? Docs/12_IMPLEMENTATION_PLAN.md`. **After:** the same, plus `?? Sylantro/Domain/Structuring/`, `??` the three new Domain test files, and this row in `11`. M1-3's files are still untracked, so M1-4's edits to them don't show as a separate diff. **Git:** `git status --short` (×2), `git branch --list`. **Notes:** decisions where 11 is silent, for review: (a) `TextMatch` keeps its own copy of M1-2's unicode-fraction table, because `IngredientLineParser`'s copy is `private` and that file is outside this task. That is two copies of one constant (`00A` §10); making the parser's table shared is a one-line follow-up. (b) `PageRules` yield: each `|`-separated part of a line is tested for starting with the word. That is the only reading under which test 7 gives `SERVES 4`, because the line starts with `PREP`. (c) `RecipeValidator`: an empty or nil title, group name, notes, nutrition, author or publisher is not checked, so a missing value gets no warning. The copied-step length (more than 60) is measured on the normalized `rawText`. A removed copied step gets only `ingredient <n> is a step`, not also `not on page`. An `Extraction` is created only when there is a warning. (d) `RecipeStructurer`: a line-labels or header call that throws something other than a rate limit is recorded in `partErrors` like the ingredients and steps calls, and structuring goes on: unlabelled sections, or no header. A header with no lines is skipped. The one-shot call rethrows as in M1-3. With line labels, equipment and nutrition keep what the headings found. `partMillis` keys are `lineLabels`, `header`, `ingredients`, `steps` and `oneShot`. `structureMillis` is the sum of `partMillis`. `StructuringOutcome` sits in `RecipeStructurer.swift`, and the caps are `RecipeStructurer.TokenCap`. (e) `SpikeRunner`: Run All resets every capture and reads them all. Each read capture is structured only if the scene is active; otherwise it waits. After the loop, and on `sceneBecameActive()` when not already running, waiting captures are structured in order. The report is rebuilt each time. A capture rate-limited while the scene is still active waits until the scene next becomes active. |
| M1-3 | 22 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 19 tests in 6 suites passed after 0.035 seconds."; `** TEST SUCCEEDED **` (16 + 3). **Clauses:** ✅ 1 `Extraction/TextReader.swift`, `PageReading.swift`, `GeneratedRecipe.swift`, `RecipeStructurer.swift`, `Extraction/Spike/SpikeReport.swift`, `SpikeRunner.swift`, `Views/Spike/SpikeView.swift`, the Settings row, and `SylantroTests/Extraction/RecipeStructurerTests.swift` all exist. `Domain/` is unchanged (no `Domain/` path in `git status`). ✅ 2 the 3 tests, `@Suite("Recipe structurer mapping")`, named as in M1-3, pass. They build `GeneratedRecipe` with its memberwise init, so `import FoundationModels` wasn't needed. ✅ 3 Debug builds through the test run, and Release with `xcodebuild build … -configuration Release` (same destination, `-derivedDataPath /tmp/m1-3-release-dd`): `** BUILD SUCCEEDED **`. The only warning in either is the existing appintentsmetadataprocessor "Metadata extraction skipped". The first Debug run had one new warning, `SpikeView.swift:59` "call to main actor-isolated static method 'fileName' in a synchronous nonisolated context", fixed by calling it in a closure (`runner.report.map { Self.fileName($0) }`) before the run above. ✅ 4 **No spike code in Release:** `nm -a` on the Release `Sylantro.app/Sylantro` has 0 symbols matching `spike` (case-insensitive), and `strings` has 0 matches for `spike` or `Accuracy`. In the same binary, 4 symbols match `RecipeStructurer` or `TextReader`, so the check does see app symbols. As a control, the Debug build's `Sylantro.debug.dylib` has 1,737 symbols matching `spike`. ✅ 5 my edits outside the new files are the one `#if DEBUG` Section in `SettingsSheet.swift` and this row. ✅ 6 git status before and after is below. **Vision API:** the Swift `RecognizeTextRequest` compiles against the pinned SDK and is used (`.accurate` / `.fast`, `usesLanguageCorrection = true`, `recognitionLanguages = [en-US]`, `regionOfInterest = NormalizedRect(x: 0, y: 0, width: 1, height: fraction)` for the bottom read). **Asked of Pops in the session** (11 didn't say): the row detail's `<r>` is the total of the capture's `readMillis`; when a capture isn't structured, the ` · structure <s> ms` part is left out. **Git status before** (branch `milestone-1`): Pops's staged M1-1 and M1-2 files, `.gitignore`, the 3 deleted xcuserdata files; `MM` on `00_DECISION_LEDGER.md`, `01_INGESTION_DESIGN.md`, `06_MILESTONE_1_DOMAIN.md` and `README.md`; ` M Docs/10_ACCURACY_TEST_SET.md`; `?? Docs/11_MILESTONE_1_SPIKE.md`. **After:** Pops staged docs during the session, so the ledger, `01`, `06`, `10` and `README.md` are now `M ` and `11` is `AM` (staged, plus this row unstaged). My own changes are ` M Sylantro/Views/Settings/SettingsSheet.swift`, `?? Sylantro/Extraction/`, `?? Sylantro/Views/Spike/`, `?? SylantroTests/Extraction/` and this row. **Git:** `git status --short` (×2), `git branch --list`. **Notes:** (a) `readBottom`'s boxes are taken as Vision returns them for the region of interest and flipped to top left. I didn't check whether Vision reports them relative to the region or to the whole page; only the text and the time are used in this task. (b) The Settings row's Section has `.paletteRowBackground()` like the sheet's other sections; 11 named no styling for it. (c) `fileExporter`'s `defaultFilename` is `spike-results-<yyyy-MM-dd-HHmm>` from `runAt`, with no extension, expecting the `.json` content type to add `.json`; Pops's device check should confirm the name. (d) Images load with ImageIO's transformed full-size thumbnail (`kCGImageSourceCreateThumbnailWithTransform`) to make them upright. (e) The spike has no `SourcePage`s, so `SpikeRunner` gives each page a new `UUID` for `pageIDs` each run. (f) The structurer reads `SystemLanguageModel.default` and calls `respond(to:generating:)` with no options; no network call is made anywhere. |

---

## 3. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.5 | Task M1-5: ingredient lines and the title by line number, retry and fallback, clutter and equipment and times kept to their sections, non-Latin lines unreadable; then spike run 3 | SLT-146 to SLT-150 (Pops, 22 Nov 2026: "All") |
| 0.4 | M1-4 complete; §1: the duplicate fraction table and the foreground rate limit noted | M1-4 Results log |
| 0.3 | Task M1-4: structuring in parts, capped output, the found-on-the-page check, rule-based fields, foreground-only structuring, language detection off; then spike run 2 | SLT-140 to SLT-145 (Pops, 22 Nov 2026: "all six") |
| 0.2 | M1-3 complete; the row detail's two details Pops settled in the session written into the copy table | M1-3 Results log |
| 0.1 | First version: Task M1-3, the reader, the structurer and a debug-only spike screen; runs on Pops's iPhone 18 Pro | SLT-093 (Pops, 22 Nov 2026 (decision card, "Hidden spike screen in Sylantro")); SLT-017 (Pops, 22 Nov 2026: "we wont be running on my partners phone, she hates when I do that...we will use my iphone 18 pro.") |
