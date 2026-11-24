# Sylantro — Milestone 3: Extraction and Review

**A Syzygy Softwerks task document · every saved page read and structured behind her, and a review
where she checks each recipe against its photo**
Version 0.30 · 24 November 2026 · **Draft: the task plan (RV-1), flags (RV-10), the test set's four
proposals (RV-18) the spike leftovers (RV-19) the device-only store (RV-2) which device reads (RV-3) how a reading is kept (RV-4) no background work (RV-5) reading M2's recipes (RV-6) and her edits on a page change (RV-7) where review lives (RV-8) the review layout (RV-9) tap-to-highlight (RV-11) what she edits (RV-12) Looks Good (RV-13) and where the screens are drawn (RV-21) are ruled; the rest of RV-2 to RV-22 is open.
**M3-1 complete** (123 tests; run 7 scored). **M3-2 complete** (142 tests). **M3-2a complete** (149 tests); M3-3 written in full and ready (`13` v0.22 accepted).** The questions in §3 are
Claude's proposals for Pops. No task is written in full until the questions it depends on are
ruled (§1's Gates column).
Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md`, `00B_SYLANTRO_GUARDRAILS.md`,
`01_INGESTION_DESIGN.md`, `02_ARCHITECTURE.md`, `10_ACCURACY_TEST_SET.md` and `13_SCREENS.md`.

---

## 0. What this is

Milestone 3 ends with her scanning twenty pages without waiting, then working through the recipes
that need review: each one read and structured in the background, its shaky fields flagged, a tap on
a line showing where it sits on the photo, a page with several recipes split into the ones she
picks (SLT-047), and a recipe's pages reordered or removed (`14` MT-29, MT-31) (`12` §2, row 4).

**What it is built on (all ruled):**

- **The reader and the structurer already exist**, from the spike (SLT-093: "the reader and
  structurer it builds are the pipeline's own and carry into Milestone 3"). `TextReader.read(_:)`
  returns a `PageReading` (lines with boxes and confidence, English pinned, SLT-145);
  `RecipeStructurer.structure(_:pageIDs:)` returns a `StructuringOutcome` whose one `Recipe` has
  already passed `RecipeValidator` (SLT-042, SLT-142), with its review warnings in
  `extraction.warnings`. Structuring is in parts (SLT-140 to SLT-153). M3 wires them to saved
  pages; it does not redesign them.
- **Run 6's scores** (`10` §7, SLT-156): print read near perfect at 93 to 386 ms a page; 91% of
  printed ingredient lines found, 95% of quantities and 90% of units right; titles 14 of 22, each
  with a warning when unsure; 4.5 to 37 s of structuring a recipe; no errors in runs 3 to 6.
  Review is where the rest gets corrected.
- **M2's store and writers** (`14`, SLT-160): `SourcePageModel` already has `ocrText`,
  `ocrWordsData` and `structuringStateRaw` (`waiting` for every page saved so far);
  `RecipeModel` holds the whole `Recipe` as JSON plus title and review state (MT-5); every write
  goes through `CaptureRecorder` or `RecipeEditor` (SLT-082); `MirrorWriter` rewrites a recipe's
  Files copy after each save (SLT-158).
- **The rules the queue must keep:** scanning never waits (SLT-041); nothing leaves the device
  (SLT-040); a device without Apple Intelligence reads but doesn't structure, and the page stays
  marked waiting for a capable device (SLT-044); structuring only while Sylantro is open (SLT-144),
  with a 30-second retry up to three times on a refusal in front (SLT-153); nothing saved that
  fails the schema check (SLT-042).
- **Delete means all gone** (SLT-157), including removing one page (MT-31).

**Carried in** (`12` §4): from M1, SP-20's two title fixes, the header area missing from the
report, several recipes on a page (SLT-047), handwriting, and `10`'s TS-5, TS-10, TS-11, TS-15;
from M2, reorder and remove pages (MT-29, MT-31) and the device-only store with `ExtractionQueue`
(MT-1). **Gate from `12` §4:** the review screens and their copy, and whether restoring from the
mirror is offered.

**What the code shows today** (read 23 Nov 2026, for the questions below):

- The structurer fills no `sourceBox` on ingredients or steps, and no per-field confidence. Tap to
  see a line on the photo needs those boxes (RV-11).
- Ingredient lines come from page lines by number (SLT-146), so each ingredient's box is already
  known to the structurer; a step's box has to be found by matching its text to the page
  (`TextMatch`).
- Review warnings are English strings for Pops (`no title`, `title from layout`,
  `not on page: step 3`, `may hold other recipes: …`), not copy she reads (RV-10).
- The structurer always returns one recipe; several recipes on a page is a warning only
  (SLT-151).
- `SourcePage.ocrWords` is `[OCRWord]` (text, box, confidence); the reader returns lines, not
  words (RV-4).

---

## 1. The task plan (RV-1, ruled)

**Ruled:** Pops, 23 Nov 2026 (decision card, "Accept the plan").

One task at a time, in order. Each is checked before the next is written, as M2 was.

| Task | What it builds | Gates before it is written in full |
|---|---|---|
| **M3-1** ✓ | **Domain and the structurer, before any screen:** SP-20's two title fixes; the header area in the spike report; each ingredient's `sourceBox` from its page line, and each step's from `TextMatch`; `ReviewFlag`, a Domain type that turns `extraction.warnings` into typed flags that name a field (RV-10); the spike's leftovers (one fraction table, `GeneratedRecipe` and `makeRecipe` removed with their tests, the fallback's noisy warnings dropped). Checked by a spike run 7 on Pops's iPhone | RV-1, RV-10, RV-19; TS-5, TS-10, TS-11 (RV-18) |
| **M3-2** ✓ | **The queue:** the device-only store (`ExtractionJobModel`, `DeviceStateModel`) if RV-2 keeps it; `ExtractionQueue` reading and structuring waiting pages one recipe at a time; the reading written once to the page (RV-4); the result handed to `RecipeEditor` as the recipe's draft; the Files copy rewritten. The library rows fill in with titles. No review screen yet | M3-1; RV-2 to RV-7 |
| **M3-2a** ✓ | **Three fixes found on device:** a title holding the author's name (RV-25, SP-23); "Page n of n" on the last page clears the page-2 warning (RV-26); the Files folder follows the title (RV-27) | M3-2; RV-25 to RV-27 |
| M3-3 (ready) | **Review:** where recipes that need review are listed (RV-8), the review screen with the photo and the fields (RV-9), flags in plain words (RV-10), tap a line to see it on the photo (RV-11), editing (RV-12), and Looks Good (RV-13) | M3-2; `13` v0.18 with the review screens and every string (RV-21) |
| M3-4 | **A recipe's pages:** reorder and remove (MT-29, MT-31, RV-15), and reading again after a page is added, moved or removed (RV-7) | M3-3; RV-7, RV-15 |
| M3-5 | **Several recipes on a page** (SLT-047): she picks which to save; each is structured on its own and shares the photo (RV-14) | M3-3; RV-14; a spike check on the test set's four-recipe page (`10` H-38) |
| M3-6 | **Handwriting she can't read and search:** the unreadable piece of the photo shown in place (TS-15, if accepted), and search by title and ingredient (RV-16) | M3-3; RV-16, RV-18 |
| M3-7 | **Pops's device check:** twenty pages scanned without waiting on his iPhone 18 Pro, read behind him, reviewed, a page reordered and one removed, a several-recipe page split, synced to iPad and Mac; one recipe scanned on a device without Apple Intelligence, if he has one | M3-6 |

**Why this order:** M3-1 changes only Domain and the structurer, so it is tested with plain values
and a spike run before anything is wired. M3-2 makes the library fill in by itself, which is
useful before review exists. M3-3 is the largest piece and waits on its screens. M3-4 to M3-6 each
add one thing to review.

---

### Task M3-1 · Sylantro · Line positions, review flags and the spike's leftovers

**Status: complete** (24 Nov 2026, 123 tests; Results log), checked by Claude against its Done when. Spike run 7 scored (24 Nov 2026, `10` §7): titles 16 of 22 (run 6: 14), ingredient lines, quantities and units unchanged, positions for 185 of 193 ingredients and 63 of 74 steps. The agent's note (a), that `continuesOnUnscannedPage` is a `recipe` flag, is what RV-10 means; part 2's table now says so.

**Inputs:** `00`, `00A`, `00B`, `02` §2 and §3, `10` §7 (run 6) and §5 (TS-5, TS-10, TS-11), `11`
§1, this document (§0, RV-10, RV-18, RV-19), and these files: `Extraction/RecipeStructurer.swift`,
`Extraction/GeneratedRecipe.swift`, `Extraction/GeneratedParts.swift`,
`Extraction/Spike/SpikeReport.swift`, `Extraction/Spike/SpikeRunner.swift`,
`Domain/Structuring/HeaderArea.swift`, `Domain/Structuring/TextMatch.swift`,
`Domain/Structuring/WrapJoiner.swift`, `Domain/Structuring/RecipeValidator.swift`,
`Domain/Parsing/IngredientLineParser.swift`, `Domain/Recipe/SourceBox.swift`,
`Domain/Recipe/Ingredient.swift`, `Domain/Recipe/Step.swift`,
`SylantroTests/Extraction/RecipeStructurerTests.swift`.

*Why:* review (M3-3) tints each flagged field with one line saying why (RV-10), and a tap on a line
shows it on the photo (RV-11). So every ingredient and step needs to know where it is on the page,
and every warning needs to name its field. Both are Domain rules, tested here with plain values
before any screen exists. The spike's leftovers (RV-19) are in the same files. **No `@Model`, no
store, no view and no prompt changes**, so `promptVersion` stays 3. TS-5, TS-10 and TS-11 (RV-18)
add no code here: page clutter is already kept out of fields (SLT-149), titles are already kept as
printed (SLT-148), and steps already carry the heading they are printed under (`groupName`). Run 7
checks all three on the test set; a gap it finds becomes its own fix.

**Deliverable:** two new Domain files, `Domain/Structuring/SourceLocator.swift` and
`Domain/Structuring/ReviewFlag.swift`; the changes in parts 3 to 7 below; their tests.

#### 1. `SourceLocator`: where each ingredient and step is on the page

`nonisolated enum SourceLocator` in `Domain/Structuring/SourceLocator.swift`, importing
`Foundation` only.

```swift
nonisolated enum SourceLocator {
    /// One readable line of a capture, in reading order, its box already on its page.
    nonisolated struct Line: Sendable, Equatable {
        var text: String
        var box: SourceBox
    }

    static let maximumIngredientRun = 4
    static let maximumStepRun = 15

    /// `recipe` with a `sourceBox` on every ingredient and step that has none and is found in
    /// `lines`. Nothing else changes.
    static func locate(_ recipe: Recipe, lines: [Line]) -> Recipe
}
```

**The rule, exactly:**

1. A *run* is 1 to `maximum` consecutive lines that all have the same `box.pageID`. A run never
   crosses a page.
2. A run's *text* is its lines' `text` joined with `"\n"`, then `TextMatch.normalize`d. The
   *target* is the ingredient's `rawText` or the step's `text`, normalized. An empty target is
   never found.
3. A search starts at a *cursor* (a line index) and tries start lines in the order `cursor` to the
   last line, then `0` to `cursor - 1`. **Pass 1:** at each start line, runs of length 1 up to
   `maximum`; the first run whose text **equals** the target wins. **Pass 2**, only if pass 1 found
   none: the same order, the first run whose text **contains** the target.
4. The found run's box is the union of its lines' boxes: `x` and `y` the smallest, `width` the
   largest `x + width` less `x`, `height` the largest `y + height` less `y`, `pageID` the run's.
   The new cursor is the line after the run.
5. **Ingredients:** every ingredient of every group, in recipe order, with one cursor starting at
   0 and `maximumIngredientRun`. **Steps:** in order, with their own cursor starting at 0 and
   `maximumStepRun`. An ingredient or step that isn't found keeps `sourceBox` nil and leaves the
   cursor where it was.
6. An ingredient or step that already has a `sourceBox` is left as it is and does not move the
   cursor.

*Why the cursor:* two ingredients printed the same ("1 tsp salt" in the dough and the filling) get
their own lines, in order. *Why equals before contains:* a short ingredient ("salt") finds its own
line before a sentence that mentions it.

#### 2. `ReviewFlag`: each warning, named by its field

`nonisolated struct ReviewFlag` in `Domain/Structuring/ReviewFlag.swift`, importing `Foundation`
only. It is worked out when shown and **never stored**: no JSON, no `Codable`.

```swift
nonisolated struct ReviewFlag: Sendable, Equatable {
    nonisolated enum Field: Sendable, Equatable, Hashable {
        case recipe              // the whole recipe, shown at the top (RV-10)
        case title
        case ingredients         // the ingredient list as a whole
        case ingredient(UUID)
        case steps               // the steps as a whole
        case step(UUID)
        case notes
        case equipment
        case printedNutrition
        case attribution
    }

    nonisolated enum Kind: Sendable, Equatable, Hashable {
        case noTitle
        case titleFromLayout
        case notOnPage                     // kept, but not found on the page
        case droppedNotOnPage              // removed because not found on the page
        case ingredientWasStep
        case ingredientsFromWholePage
        case stepsFromWholePage
        case ingredientLinesUnsure
        case mayHoldOtherRecipes([String])
        case unreadableLine(page: Int)
        case continuesOnUnscannedPage
        case other(String)
    }

    var kind: Kind
    var field: Field

    /// The recipe's flags: `continuesOnUnscannedPage` first when it is true, then one per
    /// warning in `extraction.warnings` order, by the table below, each (kind, field) pair once.
    static func flags(for recipe: Recipe) -> [ReviewFlag]
}
```

**The table.** Each warning string is as the structurer and `RecipeValidator` write it today; `n`
is a whole number.

| Warning | Kind | Field |
|---|---|---|
| `no title` | `noTitle` | `title` |
| `title from layout` | `titleFromLayout` | `title` |
| `not on page: ingredient n` | `notOnPage` | `ingredient(id)` (below) |
| `not on page: step n` | `notOnPage` | `step(steps[n - 1].id)`; `steps` when out of range |
| `not on page: group name` | `droppedNotOnPage` | `ingredients` |
| `not on page: step group` | `droppedNotOnPage` | `steps` |
| `not on page: equipment` | `droppedNotOnPage` | `equipment` |
| `not on page: notes` | `droppedNotOnPage` | `notes` |
| `not on page: printed nutrition` | `droppedNotOnPage` | `printedNutrition` |
| `not on page: author`, `not on page: publisher` | `droppedNotOnPage` | `attribution` |
| `ingredient n is a step` | `ingredientWasStep` | `ingredients` |
| `ingredients from whole page` | `ingredientsFromWholePage` | `ingredients` |
| `steps from whole page` | `stepsFromWholePage` | `steps` |
| `group name too long`, `ingredient lines out of range`, `ingredient line repeated`, `unused ingredient line n` | `ingredientLinesUnsure` | `ingredients` |
| `may hold other recipes: <titles>` | `mayHoldOtherRecipes(titles)`: the text after `: `, split on `"; "` | `recipe` |
| `unreadable line on page n` | `unreadableLine(page: n)` | `recipe` |
| *(no warning: `continuesOnUnscannedPage` is true)* | `continuesOnUnscannedPage` | `recipe` |
| anything else | `other(the warning)` | `recipe` |

**`not on page: ingredient n`.** `RecipeValidator` numbers ingredients from 1 across all groups
*before* it removes the ones that are copied steps, so `n` is resolved like this. The removed
numbers are those of every `ingredient n is a step` warning. The kept ingredients, in recipe
order, take the numbers from 1 upward that were not removed, in order. `n` is the kept ingredient
with that number; if none has it, the field is `ingredients`.

*Why `other` is shown, not hidden:* nothing is guessed silently (SLT-042), so a warning the table
doesn't know yet still tells her to check the recipe. The words she reads for each kind are
written in `13` with the review screens (RV-21), not here.

#### 3. The structurer: positions and the header area

In `RecipeStructurer.swift`:

1. `StructuringOutcome` gains `var headerArea: [HeaderArea.HeaderLine]`, set to `area` in step 3
   of `structure` (where `HeaderArea.lines` is called), and `[]` in the initial outcome.
2. In steps 7 and 8, the recipe that passed `RecipeValidator.check` is passed through
   `SourceLocator.locate(_:lines:)` before it goes in `outcome.recipes`. The lines are every
   readable line of `pageLines` (the lines kept in step 1), in page then reading order, each with
   `SourceBox(pageID: pageIDs[pageIndex], x:, y:, width:, height:)` from its `box`. A page with no
   page ID (an index at or past `pageIDs.count`) adds no lines.
3. **The fallback's noise** (`11` §1): on the `ingredients fallback` path only, the warnings from
   `ingredientGroups(from:lines:)` that start with `unused ingredient line ` are left out. A new
   `static func fallbackWarnings(_ warnings: [String]) -> [String]` does the filtering, so it can
   be tested.

#### 4. The two title fixes (SP-20, `10` §7 run 6)

In `HeaderArea.swift`:

1. **A one-word author doesn't make a side line.** In `isSideLine`, the author's name counts only
   when its normalized text has at least two words (at least one space). A one-word answer
   ("Smith") is ignored there.
2. **The step-number check applies to the fallback.** In `snappedTitle`, when the answer matches no
   line and the largest line is used, a largest line that starts with a step number gives
   `("", false)`, as a snapped title does. The function's doc comment says so.

`HeaderArea.HeaderLine` gains `Codable`, for the report (part 5).

#### 5. The spike report

`SpikeCaptureResult` gains `var headerArea: [HeaderArea.HeaderLine]` (each line's text and size),
set in `copyDiagnostics` from the outcome, and `[]` in `read(_:)`'s initial result. It closes
run 6's gap: a title cut short can be traced to the lines the model was shown. Nothing else in the
report changes; each recipe's `sourceBox` values are already in its JSON.

#### 6. One fraction table (`11` §1)

`IngredientLineParser`'s `unicodeFractions` becomes `static let` (internal, not `private`).
`TextMatch.normalize` builds its ` n/d` text from it (`" \(numerator)/\(denominator)"`), and
`WrapJoiner`'s set is its keys. The private tables in `TextMatch` and `WrapJoiner` are removed. No
behavior changes: every existing test passes as it is.

#### 7. M1-3's unused one-shot path (`11` §1, SLT-151)

- `GeneratedStep` moves, unchanged, from `GeneratedRecipe.swift` to `GeneratedParts.swift`, where
  `GeneratedStepPart` uses it.
- `GeneratedRecipe.swift` is deleted, with `GeneratedCapture`, `GeneratedRecipe`, `GeneratedGroup`
  and `GeneratedIngredient`.
- `RecipeStructurer.makeRecipe(from:pageIDs:)` and `makeGroup(_:)` are removed; `makeSteps` stays.
- In `RecipeStructurerTests.swift`, the `generated(…)` helper and the three tests that use
  `makeRecipe` are deleted: "a generated recipe maps to a recipe", "empty strings become nil" and
  "a line the parser can't read keeps its words". The suite's comment says it tests the parts'
  mapping.

#### 8. Tests

Swift Testing, made-up text only (`00B` §2). New files `SylantroTests/Domain/SourceLocatorTests.swift`
and `SylantroTests/Domain/ReviewFlagTests.swift`; the rest go in the existing files named.

| File | Test | Checks |
|---|---|---|
| `SourceLocatorTests` | a one-line ingredient | its box is that line's box |
| | a wrapped ingredient | an ingredient joined from two lines gets their union |
| | the same line twice | two ingredients "1 tsp salt" get the first and the second line, in order |
| | a step over three lines | found by pass 2; its box is the three lines' union |
| | not found | an ingredient not in the lines keeps `sourceBox` nil, and the next one is still found |
| | never across pages | a target split over the last line of page 1 and the first of page 2 is not found |
| `ReviewFlagTests` | the title | `no title` and `title from layout` give `title` flags |
| | an ingredient by number | `ingredient 2 is a step` then `not on page: ingredient 3` points at the second kept ingredient's id |
| | a step by number | `not on page: step 2` gives `step(steps[1].id)` |
| | other recipes | `may hold other recipes: Lemon Bars; Fudge` gives both titles, field `recipe` |
| | continues | `continuesOnUnscannedPage` true gives that flag first |
| | unknown | an unknown warning gives `other`, field `recipe` |
| | once each | `unused ingredient line 3` and `unused ingredient line 4` give one `ingredientLinesUnsure` flag |
| | dropped values | `not on page: notes` and `not on page: author` give `droppedNotOnPage` on `notes` and `attribution` |
| the file that tests `HeaderArea` today | a one-word author | a title line holding a one-word author's name is still the title |
| | a two-word author | a line holding a two-word author's name is still a side line |
| | a step as the largest line | an answer that matches nothing, with "1. Preheat the oven" the largest line, gives no title |
| `RecipeStructurerTests` | the fallback's noise | `fallbackWarnings` drops `unused ingredient line 2` and keeps `ingredient line repeated` |
| `SpikeRunnerTests` | the header area in the report | a result with one header line encodes a `headerArea` array with its `text` and `size` |

**The suite total** is the total before this task, 107, less the 3 deleted tests, plus the 19
above: **123**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination (`00B` §5.2) with **123** tests; the summary reports
   the destination string and the run's own total. If the total before the task isn't 107, the
   summary says what it was and expects that total less 3 plus 19.
3. `grep -rn "unicodeFractions" Sylantro/` shows only `IngredientLineParser.swift` declaring one,
   and `grep -rn "GeneratedRecipe\|makeRecipe" Sylantro/ SylantroTests/` finds nothing.
4. `Domain/Structuring/SourceLocator.swift` and `ReviewFlag.swift` import `Foundation` only.
5. `git status` before and after is reported (`00A` §9).
6. The session's summary is a row at the top of §2 (`00A` §6).

#### Pops's check on device: spike run 7

On his iPhone 18 Pro, with the spike sheet's one-tap test set (SLT-154), exported to
`sylantro-testpages/results/`. Claude scores it against run 6 (`10` §7): titles (run 6: 14 of 22;
the two SP-20 pages should now be right); ingredient lines, quantities and units (should be
unchanged: 151 of 166, 139 and 132 of 146); and two new counts, the ingredients and steps that have
a `sourceBox`.

#### Do not

Change any `@Model`, the store, `RecipeEditor`, `CaptureRecorder`, `MirrorWriter`, a view, a
prompt or `promptVersion`, `TokenCap`, `RecipeValidator`'s rules or its warning strings, the
`Recipe` JSON, `Info.plist`, the entitlements, any build setting or SyLib. Do not write any string
she reads (RV-10's words belong in `13`). Do not edit any other document except §2 of this one.

---

### Task M3-2 · Sylantro · The extraction queue

**Status: complete** (24 Nov 2026, 142 tests; Results log), checked by Claude against its Done when: all five clauses pass, and the synced schema is unchanged. The agent's notes (a) to (l) are accepted as written: each is the narrowest reading, and (b), (c), (d) and (e) close gaps this task left. Pops's check on device (the five items under Done when) is still to run. Every question it depended on was ruled (RV-2 to RV-7, RV-23,
RV-24). `02` v0.17 is in line with RV-5 and RV-23.

**Inputs:** `00`, `00A`, `00B`, `02` (all of it: this task adds to the App layer), `01` §3.4, this
document (§0, RV-2 to RV-7, RV-23, RV-24), and these files: `App/SylantroApp.swift`,
`Views/Root/RootView.swift`, `Capture/CaptureRecorder.swift`, `Capture/PhotoFiles.swift`,
`Store/RecipeEditor.swift`, `Store/SylantroSchemaV1.swift`, `Store/SourcePageModel+Domain.swift`,
`Store/RecipeModel+Domain.swift`, `Extraction/TextReader.swift`, `Extraction/PageReading.swift`,
`Extraction/RecipeStructurer.swift`, `Extraction/Spike/SpikeRunner.swift` (its rate-limit wait, to
copy, not to change), `Domain/Capture/SourcePage.swift`, `Domain/Capture/OCRWord.swift`,
`Domain/Capture/StructuringState.swift`, `Domain/Recipe/Recipe.swift`,
`Domain/Recipe/Extraction.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`,
`SylantroTests/Store/ModelTwinTests.swift`.

*Why:* every recipe saved so far says "Waiting to be read". This task reads and structures them
behind her, one recipe at a time, while Sylantro is open (SLT-041, SLT-144, RV-5), and the library
fills in with titles. It builds the device-only store (RV-2) and `ExtractionQueue` (`02` §4). No
screen changes except that "Waiting to be read" goes away once a recipe is read, which `RecipeView`
already does (it shows S-20 only while `extraction` is nil). **No synced `@Model` changes.** No
new words she reads.

**Deliverable:** the Domain rules (part 1), the device-only store (part 2), the writers' additions
(part 3), `PhotoFiles.fullImage` and `PageReading(words:)` (part 4), `ExtractionQueue` (part 5),
wiring in `RootView` (part 6), and their tests (part 7).

#### 1. Domain: `ExtractionJob` and `ExtractionPlanner`

A new folder, `Domain/Extraction/`, named here. Both files import `Foundation` only and follow
`14` M2-1's rules for value types, except that neither is `Codable` (neither is ever in a file).

`ExtractionJob` (`ExtractionJob.swift`), one recipe this device means to read and structure:

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | |
| `recipeID` | `UUID` | none | One job per recipe on a device |
| `scannedHere` | `Bool` | `false` | True when this device saved the capture or the added page (RV-3) |
| `attempts` | `Int` | `0` | Failed reads or structurings, not counting rate limits (RV-24) |
| `lastError` | `String?` | `nil` | The last failure's `String(describing:)`, for the log |
| `notBefore` | `Date` | `Date()` | Not tried before this time |

`ExtractionPlanner` (`ExtractionPlanner.swift`), `nonisolated enum`:

```swift
nonisolated enum ExtractionPlanner {
    /// Another device waits this long after a page's capture before taking it (RV-3).
    static let otherDeviceWait: TimeInterval = 600
    /// After this many failed attempts the recipe's pages are marked failed (RV-24).
    static let maximumAttempts = 3
    /// A photo not yet on this device is looked for again after this long.
    static let photoWait: TimeInterval = 60

    /// The wait after the `attempt`th failure: 60 s after the first, 300 s after the second; nil
    /// from the third on, which gives up (RV-24).
    static func retryDelay(afterAttempt attempt: Int) -> TimeInterval?

    /// The jobs to add and the job ids to remove, from the synced store's pages and recipes and
    /// this device's jobs (rules below).
    static func plan(pages: [SourcePage], recipes: [Recipe], jobs: [ExtractionJob],
                     canStructure: Bool, now: Date) -> (add: [ExtractionJob], remove: [UUID])

    /// The job to run next: due (`notBefore <= now`), its recipe's `createdAt` the oldest, then
    /// the smaller `id` (compared as `uuidString`); nil when none is due or its recipe is gone.
    static func next(jobs: [ExtractionJob], recipes: [Recipe], now: Date) -> ExtractionJob?

    /// The structurer's recipe as a reading of `existing` (rules below).
    static func merged(_ structured: Recipe, into existing: Recipe, now: Date) -> Recipe
}
```

**`plan`, exactly:**

1. Pages and recipes are taken once per `id`, the first of any duplicates (CloudKit allows them,
   `02` §5.2).
2. A recipe *is waiting* when any of its `sourcePageIDs` is a page whose `structuringState` is
   `.waiting`. A recipe whose `reviewState` is `.edited` is never waiting here (RV-7: M3-4 asks her
   first).
3. A recipe *needs reading* when any of its waiting pages has `ocrText` nil.
4. **Add** a job for each waiting recipe with no job, when `canStructure` is true, or when it is
   false and the recipe needs reading (a device that can't structure still reads, SLT-044):
   `scannedHere` false, `notBefore` the latest `capturedAt` among its waiting pages plus
   `otherDeviceWait`.
5. **Remove** every job whose recipe isn't in `recipes`, or isn't waiting, or (when
   `canStructure` is false) doesn't need reading.

**`merged`, exactly:** `structured` with these taken from `existing`: `id`, `sourcePageIDs`,
`continuesOnUnscannedPage`, `tags`, `parentRecipeID`, `createdAt`; and `reviewState` `.needsReview`,
`updatedAt` `now`, `schemaVersion` `Recipe.currentSchemaVersion`, and `extraction` the structured
one's (or a new `Extraction()` if it has none) with `engine` `Extraction.onDeviceEngine` and
`extractedAt` `now`. Everything else (title, yield, times, groups, steps, notes, attribution,
printed nutrition, equipment, unreadable areas) is `structured`'s.

#### 2. The device-only store (RV-2, RV-23)

`Store/SylantroLocalSchema.swift`: `ExtractionJobModel`, a `@Model` with the six properties of
`ExtractionJob`, every one defaulted (`recipeID` defaults to `UUID()`), and `hydrate(from:)` and
`toDomain()` as the synced twins have. No `DeviceStateModel`: nothing needs it yet (RV-23).

Its own `ModelContainer`, **not** the synced one (RV-23): `ModelConfiguration("SylantroLocal",
schema: Schema([ExtractionJobModel.self]), cloudKitDatabase: .none)`, opened by
`ExtractionQueue.live` (part 5). **If it fails to open**, the queue logs the error and uses an
in-memory container of the same schema for this launch; it never deletes, moves or replaces the
file (`00B` §2). Its jobs are rebuilt from the synced marks at every launch (part 1's `plan`), so
nothing of hers is lost either way. `StoreOpener`, `StoreSetAside` and the recovery screen are not
changed.

#### 3. The writers

`CaptureRecorder` (it writes pages, `02` §5.2; RV-4):

1. `var onRecipeSaved: ((UUID) -> Void)?`, called with the recipe's id after a successful
   `saveCapture` and after a successful `addPages`, never after a failure.
2. `func recordReading(pageID: UUID, text: String, words: [OCRWord]) throws`: on every copy of the
   page whose `ocrText` is nil, sets `ocrText` and `ocrWordsData` (through `hydrate`, as now); a copy
   that already has a reading is left as it is (`01` §3.2: read once). Saves. Throws if no copy
   exists.
3. `func finishStructuring(_ structured: Recipe, recipeID: UUID, now: Date) throws -> Bool`: if
   none of the recipe's pages (any copy) is `.waiting`, returns false and changes nothing (another
   device got there first, RV-3). Otherwise calls `recipeEditor.applyStructure(_:to:now:)`, sets
   every copy of every one of the recipe's pages to `.structured`, saves once, and writes the Files
   copy as `addPages` does; returns true. On a failed save it rolls back and rethrows, as
   `saveCapture` does.
4. `func markFailed(pageIDs: [UUID]) throws`: every copy of those pages to `.failed`. Saves.

`RecipeEditor`:

1. `func applyStructure(_ structured: Recipe, to recipeID: UUID, now: Date) throws`: the recipe
   becomes `ExtractionPlanner.merged(structured, into: existing, now: now)` on every copy. Throws
   `recipeNotFound`, `recipeUnreadable`, or a new `recipeEdited(UUID)` when its `reviewState` is
   `.edited` (RV-7). Does not save.

#### 4. Two helpers

1. `PhotoFiles.fullImage(of fileName: String) -> CGImage?`: the file upright at full size (ImageIO,
   `kCGImageSourceCreateThumbnailFromImageAlways`, `…WithTransform`, the max pixel size its longer
   side, as `SpikeRunner.loadImage` does but with no security scope), or nil when `availability` is
   not `.available` or the file can't be read.
2. `PageReading.init(words: [OCRWord])`: one `ReadLine` per word, in order, with its `text`, its
   `confidence` (0 when nil) and its box's `x`, `y`, `width` and `height`. The reverse, for
   `recordReading`, is in the queue: each `ReadLine` becomes an `OCRWord` with its text, confidence
   and `SourceBox(pageID:…)` (RV-4: each `OCRWord` is a line).

#### 5. `ExtractionQueue`

`Extraction/ExtractionQueue.swift`, `@MainActor @Observable final class ExtractionQueue`, the name
`02` §2 accepted. It holds the synced `ModelContext` (reads only), the local context (its jobs, the
one thing it writes itself), the `CaptureRecorder`, the `PhotoFiles`, a `TextReader` and a
`RecipeStructurer`. `AppLogger(category: "Extraction")`; no recipe text above debug (`02` §4).

```swift
@MainActor @Observable final class ExtractionQueue {
    static func live(syncedContext: ModelContext, captureRecorder: CaptureRecorder,
                     photoFiles: PhotoFiles) -> ExtractionQueue
    /// A capture or added page saved here (RV-3): its job is due now, `scannedHere` true; an
    /// existing job is made due now, its attempts kept.
    func enqueue(recipeID: UUID)
    /// The scene's activity, from `RootView`. Work runs only while active (SLT-144).
    func setSceneActive(_ isActive: Bool)
}
```

**What it does, in order:**

1. **Planning.** At its first `setSceneActive(true)`, at each one after, and every 600 s while
   active, it fetches every `SourcePageModel` and `RecipeModel` (their `toDomain()`), runs
   `ExtractionPlanner.plan` with `canStructure: RecipeStructurer.isAvailable`, and adds and removes
   jobs in the local store. Then it runs (step 2) if it isn't already running.
2. **Running.** One job at a time, while active: `ExtractionPlanner.next`; none due, it stops and
   waits for the next planning, `enqueue` or the earliest `notBefore`, whichever comes first.
3. **One job.** Its recipe and pages are fetched fresh. A recipe that is gone, edited, or no longer
   waiting: the job is removed. Otherwise:
   - **Read.** Each of the recipe's pages, in order, with `ocrText` nil: its photo is the
     `PhotoModel` with that `sourcePageID` and kind `pageCropped`, else `pageOriginal`.
     `photoFiles.fullImage` nil because the file isn't here yet: the job's `notBefore` becomes now
     plus `photoWait` (attempts unchanged) and the queue moves on. Else `TextReader.read`, then
     `captureRecorder.recordReading`.
   - **Stop here** when `RecipeStructurer.isAvailable` is false: the pages are read and stay
     waiting for a capable device (SLT-044); the job is removed.
   - **Structure.** `structurer.structure` with each page's `PageReading(words:)` and the recipe's
     `sourcePageIDs`. A rate-limit refusal while active waits 30 s and tries again, up to three
     times (SLT-153, as `SpikeRunner.structure` does); after that, or when not active, the job
     stays as it is until the scene is active again (SLT-144), attempts unchanged.
   - **Save.** `captureRecorder.finishStructuring(outcome.recipes[0], recipeID:, now:)`; the job
     is removed whether it returns true or false.
   - **Any other failure** (a read, a structuring that throws, an empty `outcome.recipes`, a
     failed save): `attempts` plus 1 and `lastError` set; `retryDelay(afterAttempt:)` gives the new
     `notBefore`; nil gives up: `captureRecorder.markFailed(pageIDs:)` and the job is removed
     (RV-24).
4. **Logging:** each job's start, each page read (milliseconds), structured (milliseconds and the
   warning count), each wait and its reason, each failure with its attempt number, and each give-up,
   by recipe id. Never the recipe's text above debug.

#### 6. Wiring

In `RootView`'s `.task`, after the writers are made: `ExtractionQueue.live(...)` on the same
`modelContext`, kept in `@State`; `captureRecorder.onRecipeSaved` set to call
`queue.enqueue(recipeID:)`. `.onChange(of: scenePhase, initial: true)` calls
`queue.setSceneActive(phase == .active)`. Not in Previews (the same check the task already makes).
The spike is not changed.

#### 7. Tests

Swift Testing, made-up values only. In-memory containers with `cloudKitDatabase: .none`.

| File | Test | Checks |
|---|---|---|
| new `SylantroTests/Domain/ExtractionPlannerTests.swift` | a waiting recipe gets a job | `scannedHere` false, `notBefore` its page's `capturedAt` + 600 |
| | one job a recipe | a recipe that has a job gets no second |
| | a read recipe's job goes | a recipe whose pages are all `.structured` gets none, and its job is removed |
| | a deleted recipe's job goes | a job whose recipe isn't there is removed |
| | can't structure | with `canStructure` false, a job only for a recipe with an unread page; a read one's job is removed |
| | edited recipes wait | an `.edited` recipe with a waiting page gets no job |
| | duplicates count once | two copies of a page and of a recipe give one job |
| | next | the oldest recipe's due job; a job not yet due is passed over; nil when none is due |
| | retry delays | 60, 300, then nil; `maximumAttempts` is 3 |
| | merged | keeps the six fields from `existing`, takes the rest from `structured`, `.needsReview`, `extractedAt` and `updatedAt` now, engine on-device |
| `CaptureRecorderTests` | the reading is written | `recordReading` sets text and words on every copy |
| | read once | `recordReading` leaves a copy that already has text unchanged |
| | structured | `finishStructuring` returns true, the recipe has the structured title and keeps its id, every page is `.structured` |
| | already done | with every page `.structured`, `finishStructuring` returns false and the recipe is unchanged |
| | failed | `markFailed` sets every copy of the pages to `.failed` |
| | the queue is told | `onRecipeSaved` gets the recipe's id after `saveCapture` and after `addPages` |
| `RecipeEditorTests` (new, `SylantroTests/Store/`) or `CaptureRecorderTests` | an edited recipe is kept | `applyStructure` throws `recipeEdited` and changes nothing |
| `ModelTwinTests` | a job survives the store | an `ExtractionJob` round-trips through `ExtractionJobModel` |
| new `SylantroTests/Extraction/PageReadingTests.swift` | words to lines | `PageReading(words:)` keeps text, box and confidence, 0 for nil |

**The suite total:** 123 plus these 19: **142**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **142** tests (or the total before plus 19,
   said), with the destination string and the run's own total.
3. `Domain/Extraction/` imports `Foundation` only; `ExtractionQueue` writes the synced store only
   through `CaptureRecorder` (`grep -n "context.save\|\.insert(" Extraction/ExtractionQueue.swift`
   shows only the local context).
4. No synced `@Model` (`SylantroSchemaV1`) changed: `git diff` of `SylantroSchemaV1.swift` is
   empty.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad and Mac)

1. Open the build with M2's recipes in the library: they fill in with titles, oldest first,
   without him doing anything (RV-6). The log shows each job.
2. Scan three recipes in a row: the camera never waits (SLT-041); each fills in within a minute
   or so of its Save.
3. With the iPad open too: the iPad structures nothing the iPhone scanned (no `structured` line in
   its log for those recipes); titles arrive by sync.
4. In Files, a read recipe's `recipe.json` has its ingredients and steps. (`recipe.md` still shows
   only the title and pages; its sections come with M3-3's words.)
5. Background the app mid-structure, come back: it carries on (SLT-144).

#### Do not

Change `SylantroSchemaV1` or any synced model, `StoreOpener`, `StoreSetAside`, the recovery
screen, `RecipeStructurer`'s rules or prompts, `TextReader`, the spike, `MirrorWriter`,
`RecipeRendering`, any view other than `RootView`'s wiring, `Info.plist`, the entitlements, build
settings or SyLib. No `BGProcessingTask` (RV-5). No string she reads. No network (SLT-040). Edit no
document except §2 of this one.

---

### Task M3-2a · Sylantro · Three fixes found on device

**Status: complete** (24 Nov 2026, 149 tests; Results log), checked by Claude against its Done
when: all five clauses pass. The agent's notes (a) to (f) are accepted: (a), (b) and (d) are the
narrowest readings, (c) is the log asked for, (e) is a rare case left as is, and (f) is the
simulator. Pops's check on device is still to run. Found on Pops's M3-2 device check (24 Nov 2026); RV-25, RV-26
and RV-27 ruled.

**Inputs:** `00`, `00A`, `00B`, `02` §5.4, this document (RV-25 to RV-27, Task M3-2), and these
files: `Domain/Structuring/HeaderArea.swift`, `Domain/Structuring/TextMatch.swift`,
`Domain/Capture/UnfinishedPageCheck.swift`, `Domain/Extraction/ExtractionPlanner.swift`,
`Store/RecipeEditor.swift`, `Capture/CaptureRecorder.swift`, `Extraction/ExtractionQueue.swift`,
`Extraction/PageReading.swift`, `Mirror/MirrorWriter.swift`, `Domain/Recipe/RecipeRendering.swift`
(`folderName`, to call, not to change), and the tests `SylantroTests/Domain/StructuringRulesTests.swift`,
`UnfinishedPageCheckTests.swift`, `ExtractionPlannerTests.swift`,
`SylantroTests/Capture/CaptureRecorderTests.swift`, `SylantroTests/Mirror/MirrorWriterTests.swift`.

*Why:* on device, a recipe titled with its author's name ("<author>'s Texas …") came out titled
with the last word of its subtitle; a five-page recipe whose last footer read "Page 5 of 5" kept
"Continues on a page not scanned"; and every recipe's Files folder stayed `new-recipe-<id>` after
it was read, though `02` §5.4 says a rename renames its folder.

#### Part 1 · The author's line (RV-25, SP-23)

`HeaderArea.isSideLine`, the author half only. Today a line is the author's when its normalized
text *contains* the author's normalized name (and the name holds a space). New rule, with `line`
and `name` both `TextMatch.normalize`d: the line is the author's when `line == name`, or when
`" " + line + " "` contains `" by " + name + " "`. The name no longer needs a space (the new rule
no longer catches "Example Test Soup" for the author "Example"). The site-name half is unchanged.
Update the doc comments on `isSideLine` and `snappedTitle` ("the site's name or the author's") to
say "the author's line: the name alone, or `by` and the name".

#### Part 2 · "Page n of n" clears the page-2 warning (RV-26, footer half)

1. `UnfinishedPageCheck.saysLastPage(_ lines: [String]) -> Bool`: true when any line, lowercased
   and split on spaces, holds the consecutive words `page`, *n*, `of`, *m* with *n* and *m* whole
   numbers, *n* == *m*, *n* ≥ 1. "5/5" and "5 of 5" without `page` don't count (a date or an
   ingredient could read that way). Foundation only, like the rest of the file.
2. `ExtractionPlanner.merged(_:into:lastPageEnds:now:)`: the new `Bool` sits before `now`.
   `continuesOnUnscannedPage` is `existing.continuesOnUnscannedPage && !lastPageEnds`; nothing else
   changes. Its doc comment says so.
3. `RecipeEditor.applyStructure(_:to:lastPageEnds:now:)` and
   `CaptureRecorder.finishStructuring(_:recipeID:lastPageEnds:now:)` pass it through. No default
   value: every caller says it.
4. `ExtractionQueue`: `lastPageEnds` is `UnfinishedPageCheck.saysLastPage` of the last reading's
   line texts (`readings.last?.lines.map(\.text) ?? []`). Log at info whether it cleared the
   warning, by recipe id only.

Recipes already structured keep their flag; she dismisses those in review (M3-3, RV-26).

#### Part 3 · The Files folder follows the title (RV-27)

In `MirrorWriter.write`: when `existingFolder(for:)` finds a folder (not an iCloud placeholder)
whose name isn't `RecipeRendering.folderName(title:id:)` of the snapshot's recipe, and nothing is
at that name, move the folder there in one coordinated move (`NSFileCoordinator`, `.forMoving` on
the source, `.forReplacing` on the destination, `item(at:willMoveTo:)` and `item(at:didMoveTo:)`),
then write into it as today. If the move fails, log it at error and write into the old folder.
A placeholder is never moved; the next write after it downloads moves it. Page copies are never
replaced, as today. The rename's log line gives the recipe id only, never the folder names
(`00B` §3: no recipe text in logs). Update the type comment ("a title change renames its folder").

This also renames a folder she renamed herself in Files: the mirror is written, never read
(SLT-052), so the title wins.

#### Part 4 · Tests

Swift Testing, made-up values only.

| File | Test | Checks |
|---|---|---|
| `StructuringRulesTests` | a title holding the author's name | area `("Pat Example's Test Soup", 2.0)`, `("Pat Example makes this for her", 1.0)`, `("family.", 1.0)`, `("By Pat Example", 1.0)`; model `"Pat Example's Test Soup"`, author `"Pat Example"`: title `"Pat Example's Test Soup"`, snapped |
| | the author's name alone | area `("Test Soup", 2.0)`, `("Pat Example", 1.0)`; model `"Test Soup\nPat Example"`, author `"Pat Example"`: title `"Test Soup"`, snapped |
| `UnfinishedPageCheckTests` | the last page says so | `saysLastPage` true for `["Stir.", "Page 5 of 5"]`, `["https://example.com/x Page 1 of 1"]` |
| | not the last page | false for `["Page 4 of 5"]`, `["5/5"]`, `["5 of 5"]`, `[]` |
| `ExtractionPlannerTests` | merged clears the warning | `existing` flagged: `lastPageEnds` true gives false; false keeps true; `existing` not flagged stays false |
| `CaptureRecorderTests` | the warning is cleared | a capture saved with the flag, `finishStructuring(…, lastPageEnds: true, …)`: the recipe's flag is false |
| `MirrorWriterTests` | a folder follows the title | write with title `""` (folder `new-recipe-<id>`), then with title `"Test Soup"`: the only folder is `test-soup-<id>`, and `page-1.heic` is there with the same bytes and date |
| | (rewritten) a renamed folder is still found | keep its name and purpose: move the folder to `x-<id>`, write the same snapshot again: the only folder is the title's name (moved back), and `recipe.md` is there. The old expectation that `x-<id>` stays is what RV-27 changes |

The existing `merged` test and every caller in tests pass `lastPageEnds: false`. **The suite
total:** 142 plus these 7 new: **149** (the rewritten test counts once).

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **149** tests (or the total before plus 7,
   said), with the destination string and the run's own total.
3. `HeaderArea.swift`, `UnfinishedPageCheck.swift` and `ExtractionPlanner.swift` still import
   `Foundation` only.
4. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro)

1. Scan a recipe whose title holds its author's name (the kolaches pages): the title is the
   printed title.
2. Scan a recipe whose last page's footer reads "Page n of n" and answer the page-2 question with
   Save Without It: once read, "Continues on a page not scanned" is gone.
3. In Files, a new scan's folder is `new-recipe-<id>` until it is read, then takes its title.
   Recipes read before this task keep `new-recipe-<id>` until they next change (her review, M3-3).
4. A spike run (run 8): titles at least run 7's 16 of 22; nothing else moves.

#### Do not

Change `SylantroSchemaV1` or any synced model, `RecipeStructurer`'s prompts, `promptVersion`, the
site-name half of `isSideLine`, `UnfinishedPageCheck.reason`, `RecipeRendering`, any view,
`Info.plist`, the entitlements, build settings or SyLib. No string she reads. No network. Edit no
document except §2 of this one.

---

### Task M3-3 · Sylantro · Review

**Status: ready, not started.** Every question it depends on is ruled: RV-8 to RV-13, RV-21,
RV-26, RV-28 here, and `13` v0.22 (SC-9 to SC-12; S-44 to S-53 approved).

**Inputs:** `00`, `00A`, `00B`, `02` (§1, §4, §5.2, §6), `13` v0.22 (all of it: §2, §3.2, §4.4,
§4.5 and §6 are this task's screens and words), this document (§0, RV-8 to RV-13, RV-26, RV-28,
Tasks M3-2 and M3-2a), and these files: `Views/Root/RootView.swift`,
`Views/Library/LibraryView.swift`, `Views/Library/RecipeRow.swift`, `Views/Recipe/RecipeView.swift`,
`Views/Recipe/PagePhotoView.swift`, `Views/Recipe/PagePhotoViewer.swift`,
`Views/Capture/CaptureFlowView.swift`, `Store/RecipeEditor.swift`, `Capture/CaptureRecorder.swift`,
`Extraction/ExtractionQueue.swift`, `Mirror/MirrorWriter.swift` (`MirrorSnapshot.make`), `Domain/Recipe/` (all), `Domain/Structuring/ReviewFlag.swift`,
`Domain/Parsing/IngredientLineParser.swift`, `Domain/Recipe/RecipeRendering.swift`, and the tests
`SylantroTests/Domain/RecipeRenderingTests.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`.

*Why:* recipes now fill in by themselves, but she can't see what was read, check it against the
page, fix it, or say it's right. This task builds review on the recipe's own screen (SC-9), the
Needs Review section, and the page question's third button.

#### Part 1 · Domain (Foundation only)

New folder `Domain/Review/`.

1. **`ReviewEdit`**: what she typed, to apply to a recipe.
   `struct ReviewEdit { var title: String; var yieldText: String; var groups: [Group]; var steps: [StepLine]; var notes: String }`,
   `struct Group { var id: UUID; var name: String?; var lines: [Line] }`,
   `struct Line { var id: UUID; var text: String }`, `struct StepLine { var id: UUID; var text: String }`.
   `static func from(_ recipe: Recipe) -> ReviewEdit` fills it from the recipe (ingredient lines are
   `rawText`; `yieldText` is `yield?.rawText ?? ""`; `notes` is `notes ?? ""`).
2. **`ReviewEdit.applied(to recipe: Recipe, now: Date) -> Recipe`**, by these rules:
   - Title, trimmed. Notes, trimmed; empty is nil.
   - `yieldText`, trimmed: empty leaves `yield` nil; otherwise `yield.rawText` is it, and
     `yield.servings` is its first whole number when it starts with "Serves" (any case), as a
     `Quantity` of that number; other `yield` values are kept if the text is unchanged, cleared
     if it changed.
   - Ingredients, group by group, in the edit's order. A line whose id and text match an
     existing ingredient is that ingredient unchanged (its `sourceBox` too). A line whose text
     changed keeps its id and `sourceBox`; its `rawText` is the new text, `quantity` and `unit`
     come from `IngredientLineParser.parse`, `item` is the parse's `rest` trimmed (nil if empty),
     and `preparation`, `note` and `confidence` are cleared. A new line (an id the recipe
     doesn't have) is made the same way with no `sourceBox`. An empty line is dropped. A group
     left with no lines is dropped.
   - Steps in the edit's order, `index` 1, 2, 3…; a kept step keeps its id, `sourceBox`,
     `groupName` and `ingredientIDs`; a new one has none; an empty one is dropped.
   - Every step's `ingredientIDs` loses ids no longer in the recipe.
   - `reviewState` is `.edited`; `updatedAt` is `now`. Nothing else changes (pages, warning,
     extraction, tags, times, attribution, equipment, printed nutrition).
3. **`ReviewState` helpers** on `Recipe`: `var needsReview: Bool { extraction != nil && reviewState == .needsReview }`.
4. **`ReviewFlag` lines**: `static func line(for kind: Kind) -> String` giving `13` S-52a to
   S-52k exactly (S-52h with the page number; S-52i with the titles joined by ", "). Strings
   here so a test checks them; the view only shows them.

#### Part 2 · The writers

`RecipeEditor` (each saves, then writes the Files copy as `CaptureRecorder` does after its saves,
through a private `saveAndMirror(recipeID:)`; on a failed save, rolls back, logs and rethrows;
every copy of the recipe changes, as `applyStructure`):

- `markReviewed(_ recipeID: UUID, now: Date) throws`: `reviewState` `.reviewed`, `updatedAt` now.
  An `.edited` recipe stays `.edited`.
- `saveEdits(_ edit: ReviewEdit, to recipeID: UUID, now: Date) throws`: `edit.applied(to:now:)`.
- `dismissPageTwoWarning(_ recipeID: UUID, now: Date) throws`: `continuesOnUnscannedPage` false,
  `updatedAt` now (S-53 in review, RV-26).

Update the type comment: these three save; the others still don't.

`CaptureRecorder.retryFailed(recipeID: UUID) throws`: every copy of the recipe's pages that is
`.failed` becomes `.waiting`; saves; then calls `onRecipeSaved(recipeID)` so the queue takes it
(RV-24's Try Again). A recipe with no failed page does nothing and doesn't save.

`ExtractionQueue`: a read-only, observed `private(set) var currentRecipeID: UUID?`, set while a
job runs (from its start to its removal or failure), nil otherwise. Nothing else changes.

#### Part 3 · The library (`13` §2)

`LibraryView`, given the queue (from `RootView`, optional like the writers):

- A **Needs Review** section (S-44) first, holding the rows whose recipe `needsReview`, newest
  first; then every other row, in a section with no header, as now. No S-44 section when it's
  empty.
- `RecipeRow`'s line under the title, in this order: S-45 when `currentRecipeID` is the recipe;
  S-46 when the recipe has no `extraction` and any of its pages is `.failed`; S-3 when it has no
  `extraction`; otherwise the author, else the publisher, else S-3. The title is S-2 until read.
  The row reads its pages' states from a `@Query` of `SourcePageModel` (not a new fetch per row).

#### Part 4 · The recipe screen (`13` §4.4)

`RecipeView` becomes M3's screen. Before it is read, it is M2's, plus S-45 (in place of S-20)
while `currentRecipeID` is the recipe, and S-47 with a **Try Again** button (S-48, SyLib's
`CapsuleButton`) when any page is `.failed` and it has no `extraction`; Try Again calls
`retryFailed`.

Once read (`extraction != nil`):

1. **Layout.** `horizontalSizeClass == .compact` (iPhone): a page strip across the top, about a
   third of the screen's height, then the fields in a `ScrollView`. The strip shows the area of
   the page around the selected line (first, the title's `sourceBox`, else the top of page 1),
   zoomed so that area fills the strip's width with a margin, the line outlined (a rounded
   rectangle, 2 pt, the theme's accent). A drag down on the strip, or a tap on its grabber,
   opens the whole page in the strip at full height; a drag up or a second tap closes it.
   Regular width (iPad, Mac): an `HStack`, pages on the left (scrolling, each full column width,
   as M2's) and the fields on the right, about 45% / 55%; the selected line outlined on its page
   and scrolled into view.
2. **The fields**, top to bottom, each only when present: the title (large); the whole-recipe
   flag lines, each with `exclamationmark.triangle` (S-52h, S-52i, S-52k; S-52k carries a small
   **That's All of It** button, S-53, calling `dismissPageTwoWarning`); Serves or Makes
   (`yield.rawText`, headed S-51's Serves or Makes by whether it starts "Serves"; else as
   printed); times (`times.rawText`, else "Prep ‹m› · Cook ‹m› · Total ‹m›" with ‹m› as "15 min",
   "1 hr", "1 hr 15 min"); **Ingredients** with each group name as a subheading; **Steps**,
   numbered; **Notes**; **Equipment**, one per line; **Nutrition** as printed; **Source**: the
   author, publisher and URL, each on its own line, the URL a link. Headings are S-51.
3. **Flags.** For each field a `ReviewFlag` names (`ReviewFlag.flags(for:)`), only while
   `needsReview`: the field (a title, one ingredient, one step, or a whole list) gets a rounded
   background of `Color.orange.opacity(0.15)` and its S-52 line under it in the caption style,
   secondary color. Whole-recipe flags are the lines in 2.
4. **Tap a line** (not in Edit): an ingredient, step or title with a `sourceBox` becomes the
   selected line (1); one without shows its first page whole. The tap is the row's whole area;
   VoiceOver hears it as a button, "Show on page".
5. **Edit and Done** (SC-10): `EditButton()` in the toolbar, before Add Page. In edit mode the
   title, Serves/Makes, each ingredient line, each step and the notes are `TextField`s (axis
   vertical for steps and notes), the lists have `.onDelete` and `.onMove` and a **+** row at
   the end of each list and group (an `Image(systemName: "plus.circle.fill")` with the
   accessibility label "Add Ingredient" or "Add Step"; no visible text). The rest is shown as
   read, dimmed. Done calls `saveEdits` with the `ReviewEdit` built when Edit began, as changed;
   no change made, no save. A failed save shows a plain alert with S-14 and OK, and stays in
   edit mode.
6. **Looks Good** (S-49): while `needsReview`, SyLib's `CapsuleButton(fillsWidth: true)` at the
   end of the fields, hidden in edit mode; calls `markReviewed`. The screen stays open.
7. The toolbar keeps Add Page and ⋯ (Delete Recipe) as built; toolbar buttons are SyLib's
   `IconButton` where they are ours.

Every string she reads is from `13` §6 (S-1 to S-53); nothing new.

#### Part 5 · The page question's third button (`13` §3.2, RV-28)

`CaptureFlowView`'s "Is there another page?" alert gains **That's All of It** (S-53), after Save
Without It, calling `save(continuesOnUnscannedPage: false)`. Still a plain centered alert.

#### Part 6 · `recipe.md` (`13` §4.5)

`RecipeRendering.markdown`, for a recipe with an `extraction`: after the title and the
"Scanned" line (and S-21 when flagged), these blocks, each only when present: `Serves …`/`Makes …`
(as the screen), the times line, `## Ingredients` (each group name as `### ‹name›`, each line
`- ‹rawText›`), `## Steps` (`1. ‹text›`…), `## Notes`, `## Equipment` (`- ` lines),
`## Nutrition`, `## Source` (one line each); then the pages, as now. No flags. A recipe without
an `extraction` is unchanged. The headings are S-51; the times line is built by one shared
function the screen uses too (in `RecipeRendering`).

#### Part 7 · Tests

Swift Testing, made-up values only.

| File | Test | Checks |
|---|---|---|
| new `SylantroTests/Domain/ReviewEditTests.swift` | nothing changed | `from` then `applied` keeps every ingredient and step (ids, boxes, text); `reviewState` `.edited` |
| | a changed line is parsed | "2 cups flour" → "3 tbsp sugar": same id and box, rawText, quantity 3, unit tablespoon (as the parser gives it), item "sugar", preparation nil |
| | a new line | a line with a new id is added with no box |
| | empty lines and groups go | an emptied line is dropped; a group with none left is dropped; a step's `ingredientIDs` loses the dropped id |
| | steps renumber | reordered and one deleted: indexes 1, 2…, kept ids |
| | serves | "Serves 6 to 8" gives servings 6, rawText as typed; "" gives no yield |
| `SylantroTests/Domain/ReviewFlagTests.swift` | the lines | `line(for:)` gives S-52a, S-52h with "page 2", S-52i with "A, B", S-52j |
| | needs review | `needsReview` false with no extraction, true when read and `.needsReview`, false when `.reviewed` or `.edited` |
| `RecipeRenderingTests` | a read recipe's sections | headings, group subheading, numbered steps, times "Prep 15 min · Cook 1 hr 15 min", in order before the pages |
| | an unread recipe is unchanged | the M2 output exactly |
| `CaptureRecorderTests` (where M3-2 put the editor's test) | looks good | `markReviewed` gives `.reviewed`; an `.edited` recipe stays `.edited` |
| | edits are saved | `saveEdits` changes the title and is `.edited` in a fresh fetch |
| | the warning goes | `dismissPageTwoWarning` clears it |
| `CaptureRecorderTests` | try again | `retryFailed` makes failed pages `.waiting` and calls `onRecipeSaved` once; with none failed, neither |

**The suite total:** 149 plus these 14: **163**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **163** tests (or the total before plus 14,
   said), with the destination string and the run's own total.
3. `Domain/Review/` imports `Foundation` only.
4. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
5. A scan of every string literal in the changed views finds only `13` §6's words, SF Symbol
   names, accessibility labels named here, and log text.
6. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad and Mac)

1. The library shows **Needs Review** at the top with the read recipes; a recipe being read
   says "Reading…".
2. Open one: the strip shows the title on the page; tap ingredients and steps and the strip
   moves to each, outlined; pull the strip down for the whole page.
3. Flags: a tinted field with its line (the test-set pages with warnings show them).
4. Edit: change an ingredient's amount, add a step, delete one, Done. The recipe leaves Needs
   Review. In Files, `recipe.md` shows the change.
5. Looks Good on another: it leaves Needs Review, the tints go, the screen stays.
6. A recipe with "Continues on a page not scanned": That's All of It removes it.
7. Scan a printout whose last page is "4 of 5": the question has That's All of It, and the
   recipe has no warning.
8. On iPad and Mac: the pages beside the fields; tapping a line scrolls to it.

#### Do not

Change `SylantroSchemaV1` or any synced model, `StoreOpener`, the structurer or its prompts,
`TextReader`, `ExtractionPlanner`, the spike, `MirrorWriter`, `Info.plist`, the entitlements,
build settings or SyLib. No anchored popover or confirmation dialog (SLT-088). No string she
reads beyond `13` §6. No reorder or remove of pages (M3-4), no several-recipes choice (M3-5), no
search (M3-6). No network. Edit no document except §2 of this one.

---

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| M3-2a | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 149 tests in 23 suites passed after 0.517 seconds."; `** TEST SUCCEEDED **`. Total before: 142 (`@Test` count at session start), so 142 + 7 = 149 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped", reported, not suppressed. ✅ 2 the suite passed with 149 tests on the pinned destination. ✅ 3 `HeaderArea.swift:1`, `UnfinishedPageCheck.swift:1` and `ExtractionPlanner.swift:1` are each `import Foundation`, the only import. ✅ 4 `git diff -- Sylantro/Store/SylantroSchemaV1.swift`: empty (exit 0); `git diff --cached --quiet` on it: exit 0. ✅ 5 git status before and after below; this row. **What was built:** part 1 `HeaderArea.isSideLine`'s author half: with line and name normalized, the author's line is `line == name` or `" " + line + " "` containing `" by " + name + " "`; the name no longer needs a space; the site-name half unchanged; the doc comments on `isSideLine` and `snappedTitle` say "the author's line: the name alone, or `by` and the name". Part 2 `UnfinishedPageCheck.saysLastPage(_:)` (`page`, n, `of`, m in a row, whole numbers, n == m ≥ 1; Foundation only; `reason` unchanged); `ExtractionPlanner.merged(_:into:lastPageEnds:now:)` (`continuesOnUnscannedPage` is `existing`'s `&& !lastPageEnds`, doc comment says so); `RecipeEditor.applyStructure(_:to:lastPageEnds:now:)` and `CaptureRecorder.finishStructuring(_:recipeID:lastPageEnds:now:)` pass it through, with no default; `ExtractionQueue` computes it from `readings.last?.lines.map(\.text) ?? []` and logs at info by recipe id. Part 3 `MirrorWriter.write`: a found folder (never a placeholder; `existingFolder(for:)` without placeholders) whose name isn't `RecipeRendering.folderName(title:id:)`, with nothing at that name, is moved there in one coordinated move (a new private `move(_:to:)`: `.forMoving` on the source, `.forReplacing` on the destination, `item(at:willMoveTo:)` and `item(at:didMoveTo:)`), then written into; a failed move is logged at error and the old folder written. The rename's log lines give the recipe id only. Type comment and `write`'s comment updated. `RecipeRendering` unchanged. Part 4: 7 new tests as the table (`StructuringRulesTests` 2, `UnfinishedPageCheckTests` 2, `ExtractionPlannerTests` 1, `CaptureRecorderTests` 1, `MirrorWriterTests` 1), and "a renamed folder is still found" rewritten (same name and purpose: the folder is found by id and moved back to the title's name, with `recipe.md` there). The existing `merged` test and the four other test callers pass `lastPageEnds: false`. **Files** (this session's own edits): `Sylantro/Domain/Structuring/HeaderArea.swift`, `Sylantro/Domain/Capture/UnfinishedPageCheck.swift`, `Sylantro/Domain/Extraction/ExtractionPlanner.swift`, `Sylantro/Store/RecipeEditor.swift`, `Sylantro/Capture/CaptureRecorder.swift`, `Sylantro/Extraction/ExtractionQueue.swift`, `Sylantro/Mirror/MirrorWriter.swift`, `SylantroTests/Domain/StructuringRulesTests.swift`, `SylantroTests/Domain/UnfinishedPageCheckTests.swift`, `SylantroTests/Domain/ExtractionPlannerTests.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`, `SylantroTests/Mirror/MirrorWriterTests.swift`, and this document (this row only). M3-2's work was already staged, so where a file shows `MM` or `AM` the session's lines are `git diff` (unstaged) of it. `PageReading.swift` was read and needed no change. No `SylantroSchemaV1`, synced model, prompt, `promptVersion`, `UnfinishedPageCheck.reason`, `RecipeRendering`, view, `Info.plist`, entitlement, build setting or SyLib change; no string she reads; no network. **Git status before** (branch `milestone-3`): everything staged: `M ` `Docs/02_ARCHITECTURE.md`, `10_ACCURACY_TEST_SET.md`, `12_IMPLEMENTATION_PLAN.md`, `15_MILESTONE_3_REVIEW.md`, `README.md`, `Sylantro/Capture/CaptureRecorder.swift`, `PhotoFiles.swift`, `Extraction/PageReading.swift`, `Store/RecipeEditor.swift`, `Views/Root/RootView.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`, `Store/ModelTwinTests.swift`; `A ` `Domain/Extraction/ExtractionJob.swift`, `ExtractionPlanner.swift`, `Extraction/ExtractionQueue.swift`, `Store/SylantroLocalSchema.swift`, `SylantroTests/Domain/ExtractionPlannerTests.swift`, `Extraction/PageReadingTests.swift`. **After:** `MM` `CaptureRecorder.swift`, `RecipeEditor.swift`, `CaptureRecorderTests.swift`, and this document; `AM` `ExtractionPlanner.swift`, `ExtractionQueue.swift`, `ExtractionPlannerTests.swift`; ` M` `UnfinishedPageCheck.swift`, `HeaderArea.swift`, `MirrorWriter.swift`, `StructuringRulesTests.swift`, `UnfinishedPageCheckTests.swift`, `MirrorWriterTests.swift`; the rest as before. **Git:** `git status --short` (×3), `git branch --list`, `git log --oneline -3`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (to confirm the three were unchanged since this session last read them), `git diff -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff --cached --quiet -- Sylantro/Store/SylantroSchemaV1.swift`. **Notes, for Claude to confirm:** (a) `isSideLine` keeps a guard that the normalized name isn't empty (an author answer such as "—" normalizes to ""), so an area line that normalizes to "" isn't taken for the author's. (b) `saysLastPage` takes n and m as words of ASCII digits only, so "+5" or "５" don't count. (c) The queue logs on every structured save: "last page says it ends: true/false; page-2 warning none / cleared / kept". The warning state is from the draft as fetched at the job's start. (d) A failed rename logs the error's domain and code only, not its description: a file-system error's description carries the paths, which hold the title. (e) "Nothing is at that name" is checked as no file or folder at exactly the title's name. A `.<name>.icloud` placeholder at the new name isn't checked for, so a move could still land beside one; the spec named only the source placeholder. (f) The test run's log shows CoreData+CloudKit "Unable to initialize without an iCloud account" from the test host's synced store on a simulator with no account. It is from the environment, not this change, and every test passed. **Next:** Pops's check on device (iPhone 18 Pro): the kolaches pages' title; a "Page n of n" recipe saved with Save Without It loses "Continues on a page not scanned" once read; a new scan's Files folder takes its title once read; spike run 8, titles at least 16 of 22. Not run in this session |
| M3-2 | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 142 tests in 23 suites passed after 0.508 seconds."; `** TEST SUCCEEDED **`. Total before: 123 (`@Test` count at session start), so 123 + 19 = 142 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped", reported, not suppressed. ✅ 2 the suite passed with 142 tests on the pinned destination. ✅ 3 `ExtractionJob.swift` and `ExtractionPlanner.swift` each import `Foundation` only. `grep -n "context.save\|\.insert(" Extraction/ExtractionQueue.swift` (from the source folder): lines 78, 87, 145, 147, 368, 380, every one on `context`, the device-only store's context (`ExtractionQueue.swift:20`). The synced store is `syncedContext`, used only for `fetch` (lines 132, 133, 166, 316, 333, 340); every synced write goes through `captureRecorder` (`recordReading`, `finishStructuring`, `markFailed`). ✅ 4 `git diff -- Sylantro/Store/SylantroSchemaV1.swift`: empty (exit 0); no synced `@Model` changed. ✅ 5 git status before and after below; this row. **What was built:** part 1 `Domain/Extraction/ExtractionJob.swift` (the six properties, defaults as the table, not `Codable`) and `ExtractionPlanner.swift` (`otherDeviceWait` 600, `maximumAttempts` 3, `photoWait` 60, `retryDelay`, `plan`, `next`, `merged` by the rules). Part 2 `Store/SylantroLocalSchema.swift`: `ExtractionJobModel`, every property defaulted, `hydrate(from:)` and `toDomain()` (optional, as the synced twins'); no `DeviceStateModel`. Its own container, `ModelConfiguration("SylantroLocal", schema: Schema([ExtractionJobModel.self]), cloudKitDatabase: .none)`, opened in `ExtractionQueue.live`; on failure logged, then an in-memory container of the same schema; nothing deleted or moved. `StoreOpener`, `StoreSetAside` and the recovery screen are unchanged. Part 3 `CaptureRecorder`: `onRecipeSaved` after a successful `saveCapture` and `addPages`; `recordReading`; `finishStructuring`; `markFailed`. `RecipeEditor.applyStructure` checks every copy before changing any (not found, unreadable, edited, the new `recipeEdited(UUID)`); doesn't save. Part 4 `PhotoFiles.fullImage(of:)`; `PageReading.init(words:)`. Part 5 `Extraction/ExtractionQueue.swift` as specified: planning at each `setSceneActive(true)` and every 600 s while active, one job at a time, a wake at the earliest `notBefore`, read then structure then save, 30 s rate-limit retries ×3 (copied from `SpikeRunner`, which is unchanged), attempts and `retryDelay` on other failures, then `markFailed` and the job removed; `AppLogger(category: "Extraction")`, no recipe text logged. Part 6 `RootView`: the queue made in `.task` after the writers, kept in `@State`, `onRecipeSaved` calls `enqueue`, `.onChange(of: scenePhase, initial: true)` calls `setSceneActive`; inside the existing Previews guard. Part 7: 19 tests, named as the table: `ExtractionPlannerTests` 10 (new), `CaptureRecorderTests` 7 (the six, plus "an edited recipe is kept"), `ModelTwinTests` 1, `PageReadingTests` 1 (new). **Files:** new `Sylantro/Domain/Extraction/ExtractionJob.swift`, `Sylantro/Domain/Extraction/ExtractionPlanner.swift` (new folder, named by the task), `Sylantro/Store/SylantroLocalSchema.swift`, `Sylantro/Extraction/ExtractionQueue.swift`, `SylantroTests/Domain/ExtractionPlannerTests.swift`, `SylantroTests/Extraction/PageReadingTests.swift`; changed `Sylantro/Capture/CaptureRecorder.swift`, `Sylantro/Capture/PhotoFiles.swift`, `Sylantro/Extraction/PageReading.swift`, `Sylantro/Store/RecipeEditor.swift`, `Sylantro/Views/Root/RootView.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`, `SylantroTests/Store/ModelTwinTests.swift`; this document (this row only; it was already staged by Pops, so it now shows `MM`, and this row is the session's only line in it). No `SylantroSchemaV1`, synced model, `StoreOpener`, `StoreSetAside`, recovery screen, `RecipeStructurer`, `TextReader`, spike, `MirrorWriter`, `RecipeRendering`, other view, `Info.plist`, entitlement, build setting or SyLib change; no `BGProcessingTask`; no string she reads; no network. **Git status before** (branch `milestone-3`): `M  Docs/02_ARCHITECTURE.md`, `M  Docs/10_ACCURACY_TEST_SET.md`, `M  Docs/12_IMPLEMENTATION_PLAN.md`, `M  Docs/15_MILESTONE_3_REVIEW.md`, `M  Docs/README.md` (all staged; M3-1 was committed as `c676e92`). **After:** those five (this document now `MM`), plus ` M` on the 7 changed files above and `??` on `Sylantro/Domain/Extraction/`, `Sylantro/Extraction/ExtractionQueue.swift`, `Sylantro/Store/SylantroLocalSchema.swift`, `SylantroTests/Domain/ExtractionPlannerTests.swift`, `SylantroTests/Extraction/PageReadingTests.swift`. **Git:** `git status --short` (×3), `git branch --list`, `git log --oneline -5`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (to confirm the three were unchanged since this session last read them), `git diff -- Sylantro/Store/SylantroSchemaV1.swift`. **Notes, details the task left open, each chosen as the narrowest reading, for Claude to confirm:** (a) `recordReading`'s throw when no copy exists is a new `CaptureRecorderError.pageNotFound(UUID)`. (b) `finishStructuring` and `markFailed` set `structuringStateRaw` directly rather than through `toDomain`/`hydrate`, because a copy whose words couldn't be decoded would have its `ocrWordsData` cleared by a round trip (the recorder only adds). `finishStructuring` takes the page ids from every copy of the recipe; with no copy it returns false. (c) **`RootView` also calls `queue.setSceneActive(scenePhase == .active)` right after making the queue**: `.onChange(…, initial: true)`'s first call comes before `.task` has made it, so without this the queue wouldn't plan until the scene next changed. (d) A page with no `PhotoModel` (or no file name) yet is treated as "not here": wait `photoWait`, attempts unchanged. A file that is available but can't be decoded is a read failure and counts an attempt. Images are decoded off the main actor (`Task.detached`). (e) After three refusals in front, or a refusal while not active, the queue holds a flag and runs nothing until the next `setSceneActive(true)`. Planning and `enqueue` still update the jobs meanwhile. Without the flag, the same oldest job would be picked again at once. (f) If even the in-memory job store fails to open, the queue logs it and does nothing that launch (the pages stay waiting). (g) `enqueue` on an existing job also sets `scannedHere` true, by the property's definition. (h) `next` breaks a `createdAt` tie on the job's `id`, and passes over jobs whose recipe is gone. (i) On give-up, `markFailed` gets all the recipe's `sourcePageIDs`. If `markFailed` itself fails, it is logged and the job is still removed. (j) A recipe page missing from the store gives an empty `PageReading` in its place, so readings stay in step with `pageIDs`. (k) A failure is logged at error level by its type and attempt number, with its full description at debug only, in case a model error carries page text. (l) `RecipeEditor`'s type comment was updated: it said neither call saves, but `delete` already did. **Next:** Pops's check on device (iPhone 18 Pro, then iPad and Mac): M2's recipes fill in with titles, oldest first; three scans in a row with no camera wait; the iPad structures nothing the iPhone scanned; a read recipe's `recipe.json` in Files has ingredients and steps; backgrounding mid-structure carries on. Not run in this session |
| M3-1 | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 123 tests in 21 suites passed after 0.540 seconds."; `** TEST SUCCEEDED **`. Total before: 107 (`@Test` count in `SylantroTests/` at session start), so 107 − 3 + 19 = 123 expected. **Clauses:** ✅ 1 `xcodebuild build-for-testing -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** TEST BUILD SUCCEEDED **`, no errors and no warnings from source; the only warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped, no AppIntents.framework dependency found" (as in `00B` A-3), reported, not suppressed. ✅ 2 the suite passed on the pinned destination with 123 tests. ✅ 3 `grep -rn "unicodeFractions" Sylantro/`: one declaration, `Domain/Parsing/IngredientLineParser.swift:15` (`static let`); the other hits are uses, `IngredientLineParser.swift:141`, `:153`, `TextMatch.swift:12` and `WrapJoiner.swift:29`. `grep -rn "GeneratedRecipe\|makeRecipe" Sylantro/ SylantroTests/`: nothing (exit 1). ✅ 4 `SourceLocator.swift` and `ReviewFlag.swift` each have one import, `import Foundation`. ✅ 5 git status before and after below. ✅ 6 this row. **What was built:** part 1 `SourceLocator` as specified (runs within a page, pass 1 equals then pass 2 contains, cursor order, union box, separate ingredient and step cursors, boxes already set left alone). Part 2 `ReviewFlag` with `flags(for:)` by the table; `ingredient n` resolved over the kept ingredients with the `is a step` numbers skipped. Part 3 `StructuringOutcome.headerArea` (set where `HeaderArea.lines` is called, `[]` initially); the validated recipe goes through `SourceLocator.locate` with every readable line of `pageLines` (pages with no ID add none); `fallbackWarnings(_:)` used on the `ingredients fallback` path only. Part 4 `isSideLine` counts the author only when its normalized name holds a space; `snappedTitle`'s largest-line fallback gives `("", false)` for a step-numbered line, doc comment updated; `HeaderLine` is `Codable`. Part 5 `SpikeCaptureResult.headerArea`, `[]` in `read(_:)`, copied in `copyDiagnostics`. Part 6 one fraction table: `TextMatch` builds ` n/d` from the parser's table, `WrapJoiner` checks its keys; both private tables removed. Part 7 `GeneratedStep` moved unchanged to `GeneratedParts.swift`; `GeneratedRecipe.swift` deleted (Xcode's remove, moved to Trash; the folder is synchronized, so no project-file change); `makeRecipe` and `makeGroup` removed; the `generated(…)` helper and the 3 tests deleted, the suite comment now says it tests the parts' mapping. Part 8: 19 tests, named as the table: `SourceLocatorTests` 6, `ReviewFlagTests` 8, `StructuringRulesTests` (the file that tests `HeaderArea`) 3, `RecipeStructurerTests` 1, `SpikeRunnerTests` 1. **Files:** new `Sylantro/Domain/Structuring/SourceLocator.swift`, `Sylantro/Domain/Structuring/ReviewFlag.swift`, `SylantroTests/Domain/SourceLocatorTests.swift`, `SylantroTests/Domain/ReviewFlagTests.swift`; changed `Sylantro/Extraction/RecipeStructurer.swift`, `Sylantro/Extraction/GeneratedParts.swift`, `Sylantro/Extraction/Spike/SpikeReport.swift`, `Sylantro/Extraction/Spike/SpikeRunner.swift`, `Sylantro/Domain/Structuring/HeaderArea.swift`, `Sylantro/Domain/Structuring/TextMatch.swift`, `Sylantro/Domain/Structuring/WrapJoiner.swift`, `Sylantro/Domain/Parsing/IngredientLineParser.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`, `SylantroTests/Extraction/SpikeRunnerTests.swift`, `SylantroTests/Domain/StructuringRulesTests.swift`; deleted `Sylantro/Extraction/GeneratedRecipe.swift`; this document (this row only). No `@Model`, store, writer, view, prompt, `promptVersion`, `TokenCap`, `RecipeValidator`, `Recipe` JSON, `Info.plist`, entitlement, build setting or SyLib change. Fixes outside the list: none needed. **Git status before** (branch `milestone-3`): ` M Docs/12_IMPLEMENTATION_PLAN.md`, ` M Docs/README.md`, `?? Docs/15_MILESTONE_3_REVIEW.md`. **After:** those three, plus ` M` for the 11 changed files above, ` D Sylantro/Extraction/GeneratedRecipe.swift`, and `??` for the 4 new files (this document stays `??`). **Git:** `git status --short` (×2), `git branch --show-current`, `git branch --list`. *(`branch --show-current` is read-only but not on `00A` §9's list; reported for review.)* **Notes:** (a) The `continuesOnUnscannedPage` flag's field isn't in part 2's table; it is `recipe`, from RV-10's ruling ("continues on a page not scanned" is a whole-recipe line at the top) and `Field.recipe`'s comment. (b) Read beyond the Inputs to compile and test: `Domain/Recipe/Recipe.swift`, `IngredientGroup.swift`, `Extraction.swift` (initializers), `Extraction/PageReading.swift` (the line box type), and the two test files part 8 names (`StructuringRulesTests.swift`, `SpikeRunnerTests.swift`). (c) A `SpikeReport` file now always carries `headerArea`; decoding an older file without it would fail, but nothing decodes reports. **Next:** Pops's spike run 7 on his iPhone 18 Pro (one-tap test set, exported to `sylantro-testpages/results/`), scored by Claude against run 6; not run in this session |

---

## 3. Open in this document

Grouped by the task that waits on them. Each has a recommendation *(rec.)*; none is ruled.

### The plan and the engine (M3-1, M3-2)

| # | Question | Options | Proposal |
|---|---|---|---|
| RV-1 | The task plan | §1 as written; or fold M3-5 and M3-6 into M3-3 (fewer, larger tasks) | **Ruled:** §1 as written. Pops, 23 Nov 2026 (decision card, "Accept the plan") |
| RV-2 | The device-only store (`02` §5.1, accepted; `14` MT-1) | **A.** Build it as `02` says: `ExtractionJobModel` (page or recipe id, attempts, last error, next try) and `DeviceStateModel`, in a second configuration `"SylantroLocal"`. **B.** No second store: the queue is rebuilt at each launch from the synced `structuringState` marks, and attempts are counted in memory only | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Yes, build it as 02 says"). It is the accepted contract, and it remembers a page that keeps failing on this device across launches |
| RV-3 | Which device structures a page when more than one can (her iPhone, the iPad, the Mac all open) | **A.** The device that scanned it goes first; another capable device takes a page only once it has waited 10 minutes since `capturedAt` (as SLT-158's quiet period). **B.** Any device, first come; if two finish, the later result is dropped because the recipe is no longer waiting. **C.** Only the device that scanned it, unless that device can't (SLT-044) | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Scanning device first"). No work done twice in the usual case, and nothing stuck if the phone goes away |
| RV-4 | What is kept from reading, and who writes it | **A.** The page's `ocrText` and its lines as `ocrWords` (each `OCRWord` one line, with its box and confidence), written once by a new `CaptureRecorder.recordReading`, which never overwrites a reading already there. **B.** Rename `OCRWord` to a line type first (a model and JSON change). **C.** Keep nothing; read again each time | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Keep it once, on the page"). `01` §3.2 says the page is read once and kept; no migration; `CaptureRecorder` stays the page's only writer and still only adds |
| RV-5 | Background work (`02` §1 names a `BGProcessingTask`) | **A.** None in M3: the queue runs only while Sylantro is open (structuring can't run in the background anyway, SLT-144; reading takes under half a second a page). **B.** A `BGProcessingTask` that reads pages (not structure) while the phone charges | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "No, only while it's open"). `02` §1 and §6 are brought into line when M3-2 is written |
| RV-6 | Recipes already saved in M2 (every one is "waiting") | They are read and structured like any new capture, oldest first, the first time M3-2's build opens | **Ruled: as written.** Pops, 24 Nov 2026 (decision card, "Yes, read them automatically"). Nothing she does is needed |
| RV-7 | Adding, moving or removing a page after a recipe is structured | **A.** Read the recipe again. If she has edited it, ask first with a plain alert, because her edits would be replaced. **B.** Read again only if she hasn't edited it; otherwise leave it and show the new page without reading. **C.** Merge her edits with the new reading | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Read again; ask first if edited"). The alert's words are `13`'s, with the review screens |

### Review (M3-3 to M3-6; the screens go into `13`)

| # | Question | Options | Proposal |
|---|---|---|---|
| RV-8 | Where the recipes that need review are | **A.** A "Needs Review" section at the top of the library, newest first, gone when empty. **B.** A separate review inbox, opened from a toolbar button with a count. **C.** A filter on the library | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Section atop the library"): no new place to learn; the + flow already returns her to the library, where the new recipes appear as they are read |
| RV-9 | The review screen's layout | **iPhone:** the fields, with the page photo in a strip at the top she can pull down to see whole. **iPad and Mac:** the photo beside the fields. A recipe still being read shows its pages and "Reading…" | **Ruled: as written.** Pops, 24 Nov 2026 (decision card, "As proposed"); drawn in `13` before M3-3 |
| RV-10 | How flags are shown | **A.** Each warning becomes a typed `ReviewFlag` naming its field; that field is tinted and carries one short line in her words ("Check the title"); flags that belong to the whole recipe (may hold other recipes, continues on a page not scanned) are a line at the top. **B.** One list of everything to check at the top, no tints | **Ruled: A.** Pops, 23 Nov 2026 (decision card, "Tint each field, one line why"). The structurer has no per-field confidence today; flags come from its warnings only, which run 6 showed are the ones that matter |
| RV-11 | Tap a line to see it on the photo | The photo zooms to the line's `sourceBox` with a highlight; a field with no box (the model's title on a fallback) shows the whole page | **Ruled: as written.** Pops, 24 Nov 2026 (decision card, "Zoom to it on the photo"); M3-1 fills the boxes |
| RV-12 | What she can edit in M3 | **A.** Title, servings, each ingredient line, each step, notes; the rest (times, attribution, equipment, printed nutrition) shown, not edited yet. **B.** Every field. **C.** Title only, the rest later | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "The kitchen fields"): what she reads in a kitchen. An edited ingredient line is parsed again (quantity, unit); the line she typed becomes its text, and the page's own words stay on the page (SLT-060) |
| RV-13 | How she finishes a recipe | A **Looks Good** button marks it reviewed and takes it out of Needs Review; an edit marks it edited. A recipe she never reviews is still usable | **Ruled: as written.** Pops, 24 Nov 2026 (decision card, "A Looks Good button"); the button's words in `13` |
| RV-14 | Several recipes on a page (SLT-047) | **A.** When the structurer names other titles found on the page, review lists every title with a checkbox; each one she keeps is structured again with its title given and only the lines from that title to the next. **B.** She marks each recipe's area on the photo. **C.** She gets copies of the recipe and trims each by hand | **A** *(rec.)*: the titles are already found (SLT-151), and a title-to-next-title cut fits the test set's four-recipe page; checked in a spike run before M3-5's screens |
| RV-15 | Reorder and remove a page (MT-29, MT-31) | An Edit button on the recipe's pages: drag to reorder, remove with a plain alert (the page and its photo gone everywhere, SLT-157); then RV-7 | **As written** *(rec.)* |
| RV-16 | Search and sort (`13` SC-3 said "in M3, when recipes have titles") | **A.** Search by title and ingredient text; newest first stays. **B.** A, plus sort by title. **C.** None in M3 | **A** *(rec.)*; tags later |

### Carried items and what waits

| # | Question | Proposal |
|---|---|---|
| RV-17 | Restoring a recipe from the Files copy (`12` §4's gate, `02` §5.3) | **Not in M3** *(rec.)*: iCloud refills a fresh store, and the Files copy is the safety net, not a second source. Parked with no milestone, as Hide or Archive is |
| RV-18 | `10`'s TS-5, TS-10, TS-11, TS-15 | **Ruled: all four as `10` §5 recommends.** Pops, 23 Nov 2026 (decision card, "All four as recommended"): page noise in no field, kept in `ocrText`, contact details never lifted (TS-5); an alternate method as a second step group with its printed heading (TS-10); titles kept as printed, no trimming (TS-11); unreadable handwriting shown as its piece of the photo, with "Couldn't read this" and a way to type it (TS-15, built in M3-6) |
| RV-19 | The spike's leftovers (`11` §1) | **Ruled: all in M3-1.** Pops, 23 Nov 2026 (decision card, "All of them in M3-1"): SP-20's two title fixes, the header area in the report, one fraction table, `GeneratedRecipe` removed, the fallback's noisy warnings dropped. The spike screen stays, behind its flag (SLT-093) |
| RV-20 | Vision's newer document reading for columns (`11` §1) | **Not in M3** *(rec.)*; tried only if M3-5's spike check shows the column pages fail |
| RV-21 | Where the review screens are designed | **Ruled: `13` v0.18.** Pops, 24 Nov 2026 (decision card, "In 13, as version 0.18"); `13` already says M3's screens come "in a later version of this document"; drawn after RV-8 to RV-16 are ruled |
| RV-22 | The duplicate check (`01` §2, "a matching title and similar ingredients") | **Not in M3** *(rec.)*; built with sharing (M6), which needs it for imports (SLT-103) |
| RV-23 | The device-only store's shape (found writing M3-2) | **A.** Its own small container, `"SylantroLocal"`, opened by the queue; if it won't open, the queue logs it and runs from memory for that launch (its jobs are rebuilt from the synced marks anyway). Only `ExtractionJobModel`; `DeviceStateModel` waits until something needs it. **B.** As `02` §5.1 says: a second configuration in the one container, with both models; a broken device-only store then shows the recovery screen, and Start Fresh must also set it aside | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Yes, its own store"). A broken job list never keeps her from her recipes; `02` §5.1 updated (v0.17) |
| RV-24 | A recipe that keeps failing to read or structure | **A.** Three tries, 1 and then 5 minutes apart; then its pages are marked failed and it stays "New recipe" until review offers Try Again (M3-3). **B.** Keep trying at every launch. **C.** One try | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Three tries, then wait"). Try Again comes with review (M3-3) |
| RV-25 | A title holding the author's name (found on device, 24 Nov 2026: "Lydia Faust's Texas Kolaches" came out "kolaches."). `HeaderArea.isSideLine` skips any line *containing* the author's two-word name, so the true title and the subtitle were skipped and the subtitle's wrapped tail was matched (SP-23) | **A.** A small fix task before M3-3: the author's line is a side line only when it is mostly the name ("By Lydia Faust"), with a unit test and a spike run. **B.** Fold it into M3-3. **C.** No fix; she corrects it in review | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Small fix task before M3-3") |
| RV-26 | A wrong "Continues on a page not scanned" (found on device, 24 Nov 2026: a 5-page recipe whose footers read "Page n of 5" kept it). Only the camera's page-2 question sets the flag (Save Without It); structuring keeps it (`ExtractionPlanner.merged`) | **A.** Structuring clears it when the last page's footer reads "Page n of n", and she can dismiss it in review. **B.** Footer only. **C.** Review only. **D.** As now | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Clear on Page n of n, and in review"). The footer half goes in the RV-25 fix task; the dismiss is M3-3's, drawn in `13` v0.18 |
| RV-27 | A recipe's Files folder after its title changes (found on device, 24 Nov 2026: every folder stayed `new-recipe-<id>` after reading). `02` §5.4 says a rename renames its folder; `MirrorWriter.write` reuses the folder it finds by id and never renames it | **A.** Rename it to the title, as `02` says, in the RV-25 fix task. **B.** Keep the first name and change `02` | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Yes, rename it") |
| RV-28 | Saying the missing pages don't matter (Pops, 24 Nov 2026: a printout's last page may be only ads, so its footer reads "4 of 5" and no rescan clears the warning) | **A.** At the camera and in review: "Is there another page?" gets a third button meaning "that's all of it", saving with no warning; the review dismiss (RV-26) stays for recipes already flagged. A dismissed or never-set warning stays off on a re-read (`merged` keeps only a warning that is still on). **B.** Review only. **C.** Save Without It no longer warns | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "At the camera, and in review"). In M3-3; the button's words in `13` v0.18 (a plain centered alert, SLT-088) |

When Pops rules, the rulings are filed in the ledger at this document's close-out, as `14`'s were.

---

## 4. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.30 | Task M3-3 written in full: Domain `ReviewEdit`, the writers' review calls, Needs Review, the review screen, the third button, `recipe.md`'s sections; 163 tests | `13` v0.22 accepted (SC-9 to SC-12); Pops, 24 Nov 2026 |
| 0.29 | RV-28 added and ruled: a third button at the page question saves with no warning; the review dismiss stays; both in M3-3 | Pops, 24 Nov 2026 (decision card, "At the camera, and in review") |
| 0.28 | M3-2a complete (149 tests), checked against its Done when; notes (a) to (f) accepted | Pops, 24 Nov 2026: "Task M3-2a: done" |
| 0.27 | RV-27 added and ruled (the Files folder follows the title); Task M3-2a written in full (RV-25 to RV-27; 149 tests) | Pops, 24 Nov 2026 (decision card, "Yes, rename it") |
| 0.26 | RV-26 added and ruled: the flag is cleared on a last-page "Page n of n" footer, and can be dismissed in review | Pops, 24 Nov 2026 (decision card, "Clear on Page n of n, and in review") |
| 0.25 | RV-25 added and ruled: SP-23 (a title holding the author's name) fixed in a small task before M3-3 | Pops, 24 Nov 2026 (decision card, "Small fix task before M3-3") |
| 0.24 | RV-21 ruled: the review screens and their words go in `13` v0.18; M3-3's questions are all ruled | Pops, 24 Nov 2026 (decision card, "In 13, as version 0.18") |
| 0.23 | RV-13 ruled: a Looks Good button marks a recipe reviewed and takes it out of Needs Review; an unreviewed recipe stays usable | Pops, 24 Nov 2026 (decision card, "A Looks Good button") |
| 0.22 | RV-12 ruled: she edits title, servings, ingredient lines, steps and notes; the rest shown only | Pops, 24 Nov 2026 (decision card, "The kitchen fields") |
| 0.21 | RV-11 ruled: a tapped line zooms the photo to its `sourceBox`, highlighted; no box shows the whole page | Pops, 24 Nov 2026 (decision card, "Zoom to it on the photo") |
| 0.20 | RV-9 ruled: iPhone photo strip above the fields, pulled down to see whole; iPad and Mac photo beside the fields | Pops, 24 Nov 2026 (decision card, "As proposed") |
| 0.19 | RV-8 ruled: a Needs Review section at the top of the library, newest first, gone when empty | Pops, 24 Nov 2026 (decision card, "Section atop the library") |
| 0.18 | M3-2 complete (142 tests), checked against its Done when; the agent's notes (a) to (l) accepted | Pops, 24 Nov 2026: "M3-2 is complete" |
| 0.17 | M3-1: spike run 7 scored (`10` §7, v0.26): titles 16 of 22, 96% of ingredients and 85% of steps placed on the page | Pops, 24 Nov 2026: "ok run 7 done, check it out" |
| 0.16 | RV-24 ruled: three tries, 1 then 5 minutes apart, then the pages are marked failed; M3-2 ready | Pops, 24 Nov 2026 (decision card, "Three tries, then wait") |
| 0.15 | RV-23 ruled: the job list in its own small store; `02` brought into line (v0.17) | Pops, 24 Nov 2026 (decision card, "Yes, its own store") |
| 0.14 | Task M3-2 written in full (the device-only store, `ExtractionPlanner`, the writers' additions, `ExtractionQueue`, 142 tests); RV-23 and RV-24 added, found while writing it | RV-2 to RV-7 ruled; Pops, 24 Nov 2026 |
| 0.13 | RV-7 ruled: a page added, moved or removed reads the recipe again, asking first with a plain alert if she has edited it | Pops, 24 Nov 2026 (decision card, "Read again; ask first if edited") |
| 0.12 | RV-6 ruled: recipes saved in M2 are read and structured automatically, oldest first | Pops, 24 Nov 2026 (decision card, "Yes, read them automatically") |
| 0.11 | RV-5 ruled: no background task in M3; the queue runs only while Sylantro is open | Pops, 24 Nov 2026 (decision card, "No, only while it's open") |
| 0.10 | RV-4 ruled: the reading kept once on the page (`ocrText`, lines as `ocrWords`), written by `CaptureRecorder.recordReading` | Pops, 24 Nov 2026 (decision card, "Keep it once, on the page") |
| 0.9 | RV-3 ruled: the scanning device goes first; another capable device takes a page after it has waited 10 minutes | Pops, 24 Nov 2026 (decision card, "Scanning device first") |
| 0.8 | RV-2 ruled: the device-only store, as `02` §5.1 says | Pops, 24 Nov 2026 (decision card, "Yes, build it as 02 says") |
| 0.7 | M3-1 complete, checked by Claude against its Done when (123 tests); part 2's table names `continuesOnUnscannedPage`'s field, as the agent's note (a) read it | M3-1 Results log; Pops, 24 Nov 2026: "M3-1 is complete" |
| 0.6 | Task M3-1 written in full: `SourceLocator`, `ReviewFlag`, the header area in the report, SP-20's two title fixes, one fraction table, the one-shot path removed; 123 tests expected. The version line, left at 0.3 by 0.4 and 0.5, corrected | RV-1, RV-10, RV-18, RV-19 ruled; Pops, 23 Nov 2026 (decision card, "All of them in M3-1") |
| 0.5 | RV-19 ruled: every spike leftover in M3-1 | Pops, 23 Nov 2026 (decision card, "All of them in M3-1") |
| 0.4 | RV-18 ruled: TS-5, TS-10, TS-11 and TS-15 as `10` §5 recommends | Pops, 23 Nov 2026 (decision card, "All four as recommended") |
| 0.3 | RV-10 ruled: each flagged field tinted with one line why; whole-recipe flags at the top | Pops, 23 Nov 2026 (decision card, "Tint each field, one line why") |
| 0.2 | RV-1 ruled: the task plan M3-1 to M3-7 as §1 | Pops, 23 Nov 2026 (decision card, "Accept the plan") |
| 0.1 | First draft: what M3 is built on, what the code shows, the task plan M3-1 to M3-7, and RV-1 to RV-22 open | Pops, 23 Nov 2026: "are we ready to start planning milestone 3?" M2 closed (SLT-160) |
