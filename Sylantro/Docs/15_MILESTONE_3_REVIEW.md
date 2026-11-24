# Sylantro — Milestone 3: Extraction and Review

**A Syzygy Softwerks task document · every saved page read and structured behind her, and a review
where she checks each recipe against its photo**
Version 0.13 · 24 November 2026 · **Draft: the task plan (RV-1), flags (RV-10), the test set's four
proposals (RV-18) the spike leftovers (RV-19) the device-only store (RV-2) which device reads (RV-3) how a reading is kept (RV-4) no background work (RV-5) reading M2's recipes (RV-6) and her edits on a page change (RV-7) are ruled; the rest of RV-2 to RV-22 is open.
**M3-1 complete** (123 tests); spike run 7 next.** The questions in §3 are
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
| M3-2 | **The queue:** the device-only store (`ExtractionJobModel`, `DeviceStateModel`) if RV-2 keeps it; `ExtractionQueue` reading and structuring waiting pages one recipe at a time; the reading written once to the page (RV-4); the result handed to `RecipeEditor` as the recipe's draft; the Files copy rewritten. The library rows fill in with titles. No review screen yet | M3-1; RV-2 to RV-7 |
| M3-3 | **Review:** where recipes that need review are listed (RV-8), the review screen with the photo and the fields (RV-9), flags in plain words (RV-10), tap a line to see it on the photo (RV-11), editing (RV-12), and Looks Good (RV-13) | M3-2; `13` v0.18 with the review screens and every string (RV-21) |
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

**Status: complete** (24 Nov 2026, 123 tests; Results log), checked by Claude against its Done when. Pops's spike run 7 is still to run. The agent's note (a), that `continuesOnUnscannedPage` is a `recipe` flag, is what RV-10 means; part 2's table now says so.

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

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
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
| RV-8 | Where the recipes that need review are | **A.** A "Needs Review" section at the top of the library, newest first, gone when empty. **B.** A separate review inbox, opened from a toolbar button with a count. **C.** A filter on the library | **A** *(rec.)*: no new place to learn; the + flow already returns her to the library, where the new recipes appear as they are read |
| RV-9 | The review screen's layout | **iPhone:** the fields, with the page photo in a strip at the top she can pull down to see whole. **iPad and Mac:** the photo beside the fields. A recipe still being read shows its pages and "Reading…" | **As written** *(rec.)*; drawn in `13` before M3-3 |
| RV-10 | How flags are shown | **A.** Each warning becomes a typed `ReviewFlag` naming its field; that field is tinted and carries one short line in her words ("Check the title"); flags that belong to the whole recipe (may hold other recipes, continues on a page not scanned) are a line at the top. **B.** One list of everything to check at the top, no tints | **Ruled: A.** Pops, 23 Nov 2026 (decision card, "Tint each field, one line why"). The structurer has no per-field confidence today; flags come from its warnings only, which run 6 showed are the ones that matter |
| RV-11 | Tap a line to see it on the photo | The photo zooms to the line's `sourceBox` with a highlight; a field with no box (the model's title on a fallback) shows the whole page | **As written** *(rec.)*; M3-1 fills the boxes |
| RV-12 | What she can edit in M3 | **A.** Title, servings, each ingredient line, each step, notes; the rest (times, attribution, equipment, printed nutrition) shown, not edited yet. **B.** Every field. **C.** Title only, the rest later | **A** *(rec.)*: what she reads in a kitchen. An edited ingredient line is parsed again (quantity, unit); the line she typed becomes its text, and the page's own words stay on the page (SLT-060) |
| RV-13 | How she finishes a recipe | A **Looks Good** button marks it reviewed and takes it out of Needs Review; an edit marks it edited. A recipe she never reviews is still usable | **As written** *(rec.)*; the button's words in `13` |
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
| RV-21 | Where the review screens are designed | **`13` v0.18** *(rec.)*, which already says M3's screens come "in a later version of this document"; drawn after RV-8 to RV-16 are ruled |
| RV-22 | The duplicate check (`01` §2, "a matching title and similar ingredients") | **Not in M3** *(rec.)*; built with sharing (M6), which needs it for imports (SLT-103) |

When Pops rules, the rulings are filed in the ledger at this document's close-out, as `14`'s were.

---

## 4. Decision log

| Version | Decision | Rationale |
|---|---|---|
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
