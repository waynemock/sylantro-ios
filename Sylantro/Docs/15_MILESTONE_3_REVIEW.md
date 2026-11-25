# Sylantro — Milestone 3: Extraction and Review

**A Syzygy Softwerks task document · every saved page read and structured behind her, and a review
where she checks each recipe against its photo**
Version 0.62 · 25 November 2026 · **Draft: the task plan (RV-1), flags (RV-10), the test set's four
proposals (RV-18) the spike leftovers (RV-19) the device-only store (RV-2) which device reads (RV-3) how a reading is kept (RV-4) no background work (RV-5) reading M2's recipes (RV-6) and her edits on a page change (RV-7) where review lives (RV-8) the review layout (RV-9) tap-to-highlight (RV-11) what she edits (RV-12) Looks Good (RV-13) and where the screens are drawn (RV-21) are ruled; the rest of RV-2 to RV-22 is open.
**M3-1 complete** (123 tests; run 7 scored). **M3-2 complete** (142 tests). **M3-2a complete** (149 tests); **M3-3 complete** (163 tests); **M3-4 complete** (172 tests); **M3-3a complete** (181 tests); **M3-3b complete** (184 tests); **M3-3c complete** (187 tests); **M3-3d complete** (191 tests); **M3-5s complete** (197 tests); run 8 scored (`10` §7), the model's title list kept (RV-35); RV-36 ruled (own copy); **M3-3e written** (two fixes found on device, + 2 tests); **M3-5 written** (214 tests), waiting on `13`'s SC-22 and S-74 to S-77; Pops's device checks to run.** The questions in §3 are
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
| **M3-3** ✓ | **Review:** where recipes that need review are listed (RV-8), the review screen with the photo and the fields (RV-9), flags in plain words (RV-10), tap a line to see it on the photo (RV-11), editing (RV-12), and Looks Good (RV-13) | M3-2; `13` v0.18 with the review screens and every string (RV-21) |
| M3-3a ✓ | **Review, after using it:** the strip only while she checks, scans under ⋯, a hint to tap a line, one line for a whole-list flag; skipped ingredient lines put back (RV-29) and steps across a page break found (RV-30) | M3-4; `13` v0.29 SC-14 to SC-17 |
| M3-3b ✓ | **Editing a row in a sheet:** in Edit, a tap on a row opens a sheet (medium, can go large) with the row's part of the page, its text in full, Cancel and Save; Add Page and Edit move into ⋯; New Scans atop the library | M3-3a; `13` v0.35 SC-19 to SC-21 |
| M3-3c ✓ | **Read Again in ⋯, and a zoom limit** (RV-33) | M3-3b; `13` v0.39 S-73 |
| M3-3d ✓ | **Every line placed on the page:** yield, times, notes, nutrition, equipment, source lines and group names zoom when tapped (RV-34) | M3-3c |
| M3-4 ✓ | **A recipe's pages:** reorder and remove (MT-29, MT-31, RV-15), and reading again after a page is added, moved or removed (RV-7) | M3-3; RV-7, RV-15 |
| M3-3e | **Two fixes found reading the kolaches again:** ingredient lines before a group's first one put back (RV-29), and the iPhone strip moving to a tapped line's page (RV-11) | M3-3d |
| M3-5s ✓ | **Finding each recipe's title on a page (spike):** big-type lines and a model call, side by side in run 8 (RV-35) | M3-3d; RV-35 |
| M3-5 | **Several recipes on a page** (SLT-047; written, 214 tests): she picks which to save; each is structured on its own and shares the photo (RV-14); a page that isn't a recipe is flagged (RV-32) | M3-3; RV-14, RV-32; a spike check on the test set's four-recipe page (`10` H-38) |
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

**Status: complete** (24 Nov 2026, 163 tests; Results log), checked by Claude against its Done
when: all six clauses pass. The agent's notes (a) to (o) are accepted. Two are left for later
rulings, not fixes: (a) the title has no page position, so the strip starts at the top of page 1
(placing it needs a `Recipe` field or a structurer change); (g) the strip's grabber has no
VoiceOver label, since `13` §6 has no word for it. Pops's check on device is still to run.
Every question it depended on was ruled: RV-8 to RV-13, RV-21,
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

### Task M3-4 · Sylantro · A recipe's pages

**Status: complete, 24 Nov 2026 (172 tests; §2).** Notes a to j accepted; (a) the Pages section's heading, S-72 "Pages", is M3-3b's. RV-7 and RV-15 ruled; `13` v0.25 §4.6 (SC-13, S-54 to S-60 approved; `13` v0.30).

**Inputs:** `00`, `00A`, `00B`, `02` §5.2 and §5.4, `13` v0.25 (§4.4, §4.6, §6), this document
(RV-7, RV-15, Tasks M3-2 and M3-3), and these files: `Store/RecipeEditor.swift`,
`Capture/CaptureRecorder.swift`, `Mirror/MirrorWriter.swift`, `Views/Recipe/RecipeView.swift`,
`Views/Capture/CaptureFlowView.swift`, `Domain/Extraction/ExtractionPlanner.swift` (to read: an
`.edited` recipe gets no job), and the tests `SylantroTests/Capture/CaptureRecorderTests.swift`,
`SylantroTests/Mirror/MirrorWriterTests.swift`.

*Why:* pages scanned out of order, or a page that isn't the recipe's (M2's device check, MT-29,
MT-31), can't be fixed today; and a page added to a read recipe either isn't read or, if she
edited it, waits forever. This task lets her reorder and remove pages in Edit and reads the
recipe again afterward, asking first if she has edited it (RV-7).

#### Part 1 · The writers

`RecipeEditor` (each changes every copy of the recipe after checking every copy reads, then
saves through `saveAndMirror`, as M3-3's calls do):

- `reorderPages(_ pageIDs: [UUID], of recipeID: UUID, now: Date) throws`: `pageIDs` must hold
  exactly the recipe's `sourcePageIDs` in some order, else it throws a new
  `RecipeEditorError.pagesDontMatch(UUID)` and changes nothing. Sets the order and `updatedAt`.
- `removePage(_ pageID: UUID, from recipeID: UUID, now: Date) throws -> Task<Void, Never>?`: the
  recipe's only page throws a new `RecipeEditorError.lastPage(UUID)`; a page not in the recipe
  throws `pagesDontMatch`. Removes the id from `sourcePageIDs` and sets `updatedAt`. If no other
  recipe lists the page, every copy of its `SourcePageModel`, its `PhotoModel`s and any session
  left with no page are deleted in the same save, and its photo files are removed after the
  save in a detached task it returns, exactly as `delete` does for a recipe (SLT-157). Factor
  the shared part out of `delete` rather than copying it.
- `saveAndMirror` gains `pagesChanged: Bool` (default false), passed to the mirror (Part 2).
  Both calls above pass true.

`CaptureRecorder.readAgain(recipeID: UUID, now: Date) throws`: if the recipe is `.edited`, its
`reviewState` becomes `.needsReview` (through a new `RecipeEditor.reopenForReading(_:now:)`,
which doesn't save); every copy of each of its pages becomes `.waiting` (a page already read
keeps its reading, so only new pages are read, RV-4); one save; then `onRecipeSaved(recipeID)`
so the queue structures it again from its pages in their order. Nothing else changes: the new
reading replaces the recipe's fields through `applyStructure`, as M3-2 built it.

#### Part 2 · The Files copy

`MirrorSnapshot` gains `pagesChanged: Bool` (false from `make` unless asked;
`make(for:in:pagesChanged:)`). In `MirrorWriter.write`, when it is true, every `page-‹n›.heic`
in the recipe's `pages` folder is removed first (one coordinated delete each), then the pages
are copied as today, `page-1.heic` onward in the new order. Otherwise page copies are still
never replaced. Update the type comment.

#### Part 3 · The recipe screen (`13` §4.6)

1. **In Edit** (M3-3's `EditButton`): a **Pages**
   section first in the fields `List`, one row per page in order, each row the page's
   thumbnail (`RecipeRow`'s size, from memory or made off the main actor, as
   `RecipeRow` does) with the VoiceOver label S-60 ("Page ‹n›"), and no visible text. `.onMove`
   reorders; `.onDelete` asks with a plain alert (S-54, S-55, S-56: Remove destructive, Cancel)
   and, on Remove, takes the page out of the draft order. A recipe with one page has no delete
   on its row. This section is the same on every device; the page photos (strip or column)
   show the draft order once Done saves.
2. **Done** applies, in order: the field edits (M3-3's `saveEdits`, if any changed); then the
   page changes, if any: `removePage` for each removed page, then `reorderPages` with the draft
   order when it differs; then, if any page change was made and the recipe has an `extraction`,
   the RV-7 rule below. A failed step shows S-14 with OK and stays in Edit, as M3-3.
3. **Add Page** (S-22) on a read recipe: `CaptureFlowView` in `.addPages` mode gains an
   `onPagesAdded: () -> Void`, called after `addPages` succeeds and before it closes;
   `RecipeView` then applies the RV-7 rule. On a recipe not read yet, as today.
4. **The RV-7 rule:** if the recipe is `.edited`, a plain alert (S-57, S-58; buttons S-59:
   **Read Again**, then **Keep My Edits** as the cancel role). Read Again, or a recipe that isn't
   `.edited`, calls `readAgain`. Keep My Edits does nothing more: the pages keep their new order
   and the recipe isn't read again (a page she added stays `.waiting`; the queue leaves an
   edited recipe alone).

#### Part 4 · Tests

Swift Testing, made-up values only.

| File | Test | Checks |
|---|---|---|
| `CaptureRecorderTests` (the editor's tests live here, as M3-2 chose) | pages reordered | `reorderPages` saves the new order on every copy |
| | not the same pages | a list missing one, or with an extra, throws `pagesDontMatch` and changes nothing |
| | a page removed | `removePage` drops it from the recipe and deletes its page and photo records |
| | a shared page is kept | a page another recipe lists leaves this recipe but keeps its records |
| | not the last page | the only page throws `lastPage` |
| | read again | `readAgain` makes every page `.waiting`, keeps their readings, and calls `onRecipeSaved` once |
| | read again, edited | an `.edited` recipe becomes `.needsReview` |
| `MirrorWriterTests` | pages rewritten in order | two pages written; then the snapshot with them swapped and `pagesChanged`: `page-1.heic` has the old `page-2.heic`'s bytes |
| | a removed page goes | three pages written; then two with `pagesChanged`: only `page-1.heic` and `page-2.heic` remain |

**The suite total:** 163 plus these 9: **172**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **172** tests (or the total before plus 9,
   said), with the destination string and the run's own total.
3. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. A scan of every string literal in the changed views finds only `13` §6's words (S-54 to S-60
   new), SF Symbol names, and log text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad)

1. A recipe whose pages are out of order: Edit, drag them into order, Done. The photos show the
   new order, the recipe is read again (Reading…), and its steps follow the pages. In Files,
   `pages/page-1.heic` is the new first page.
2. A recipe with a stray page: Edit, delete it, Remove, Done. It's gone, on the iPad too.
3. Edit a recipe's title, then Add Page: "Read the Pages Again?" Keep My Edits keeps the title;
   do it again and Read Again replaces it with the new reading, and it's back in Needs Review.
4. A recipe's only page has no delete.

#### Do not

Change `SylantroSchemaV1` or any synced model, `StoreOpener`, the structurer or its prompts,
`TextReader`, `ExtractionPlanner`, `ExtractionQueue`, the spike, `Info.plist`, the entitlements,
build settings or SyLib. No popover or confirmation dialog (SLT-088). No several-recipes choice
(M3-5), no search (M3-6). No string she reads beyond `13` §6. No network. Edit no document
except §2 of this one.

---

### Task M3-3a · Sylantro · Review, after using it

**Status: complete, 24 Nov 2026 (181 tests; §2).** Notes a to l accepted. Ran after M3-4. Found on Pops's
device, 24 Nov 2026. RV-29 and RV-30 here; `13` v0.31 SC-14 to SC-18; RV-31; S-52l, S-61 and S-62
approved (`13` v0.30); S-63 to S-65 approved (`13` v0.36).

**Inputs:** `00`, `00A`, `00B`, `13` v0.31 (§4.4 and its v0.26 to v0.31 rulings, §6), `10` §7
(SP-22), this document (RV-29 to RV-31, Tasks M3-1, M3-3, M3-4), and these files:
`Views/Recipe/RecipeView.swift`, `Views/Recipe/PagePhotoViewer.swift`,
`Domain/Recipe/Recipe.swift`, `Domain/Review/ReviewEdit.swift`,
`Extraction/RecipeStructurer.swift`, `Domain/Structuring/RecipeValidator.swift`,
`Domain/Structuring/SourceLocator.swift`, `Domain/Structuring/PageClutter.swift`,
`Domain/Structuring/WrapJoiner.swift`, `Domain/Structuring/ReviewFlag.swift`,
`Domain/Parsing/IngredientLineParser.swift`, and the tests `RecipeStructurerTests.swift`,
`SourceLocatorTests.swift`, `ReviewFlagTests.swift`, `StructuringRulesTests.swift`,
`RecipeJSONTests.swift`.

*Why:* on device, the pinned scan strip took a third of the screen even when she was only
reading (SC-14); new users don't know a line can be tapped (SC-16); a flag on a whole list tinted
every row (SC-17); the kolaches' first ingredient was dropped (RV-29, SP-24); and its first step,
which runs across a page break, was flagged "Not found on the page" with no position (RV-30,
SP-22); and the large title slid over the scan as the list scrolled (SC-18); and a tap on the title couldn't show where it is (RV-31).

#### Part 1 · A step across a page break (RV-30, SP-22)

1. `RecipeStructurer`: the found-on-the-page check gets a second text, the same lines less every
   `PageClutter.isClutter` line. `RecipeValidator.check(_:pageText:clutterFreeText:)`: a value is
   found when it is in either text. Callers that have no such text pass `pageText` twice.
2. `locatorLines` leaves out `PageClutter.isClutter` lines.
3. `SourceLocator.find`: a run may continue from the last line of one page onto the next page
   (two pages at most, still `maximum` lines in all). Its box is the union of its lines on the
   **first** page only. A run within one page is tried first, as now; the cross-page run only
   when no single-page run matches.

#### Part 2 · Ingredient lines the model skipped (RV-29, SP-24)

In `RecipeStructurer.ingredientGroups(from:lines:)`, after the items are made:

1. A group's **span** runs from its `nameLine` when that is in range (whether or not it became
   the name), else its first item's `firstLine`, to its last item's `lastLine`.
2. An unused line inside a group's span that `WrapJoiner.startsIngredient` is **put back**: an
   `Ingredient` made from it as items are (`rawText` the line, `quantity` and `unit` from
   `IngredientLineParser.parse`, `item` the parse's `rest` trimmed, nil if empty), placed among
   the group's ingredients in line order. Its `unused ingredient line n` warning is not added;
   instead `put back: ingredient n`, numbered as `not on page: ingredient n` is (its place among
   all the recipe's ingredients, 1-based).
3. A group with no name, whose span starts at a line just after an unused line that ends with
   `:`, doesn't `startsIngredient` and is no longer than `maximumGroupNameLength`, takes that line
   as its name (less the `:`); the line is used.
4. `ReviewFlag`: a new `Kind.putBack` on that `ingredient(UUID)`, resolved as `notOnPage`'s
   number is; `line(for: .putBack)` is S-52l.

#### Part 3 · The recipe screen (`13` §4.4 with SC-14 to SC-18)

1. **SC-14, iPhone (compact) only:** the scan strip shows only while the recipe `needsReview`
   or she is in Edit. Otherwise the fields start at the title, with no photo at the top (no dish
   photo yet: SC-15 is after M3). iPad and Mac are unchanged.
2. **The scans, when the strip isn't shown:** ⋯ gains **View Pages** (S-62), above Delete
   Recipe, opening `PagePhotoViewer` on page 1. `PagePhotoViewer` gains paging between the
   recipe's pages (a `TabView` with `.page` style, each page zoomable as now) and an optional
   starting page and box.
3. **Tap a line when the strip isn't shown:** opens `PagePhotoViewer` on the line's page, zoomed
   so the box fills the width with a 16 pt margin, outlined as in the strip. A line with no box
   opens its first page whole.
4. **SC-16, the hint:** while the strip shows (iPhone) or the recipe `needsReview` (iPad and
   Mac), a line S-61 with `Image(systemName: "hand.tap")`, caption style, secondary color, under
   the strip and above the title (iPad and Mac: atop the fields), until she first taps a line.
   Then it never shows again on that device: `@AppStorage("reviewHintSeen")` (device-only,
   never synced, never in the store).
5. **SC-17:** a flag whose field is a whole list (`.ingredients`, `.steps`) is one tinted row
   at the top of that list holding its S-52 line; the list's rows aren't tinted. Single-row
   flags (one ingredient, one step, the title) tint their row as now.
6. **SC-18, the bar (every device):** `RecipeView` uses `.navigationBarTitleDisplayMode(.inline)`
   always, and its `navigationTitle` names the view, not the recipe: S-63 "Review" while the
   recipe `needsReview` and she isn't in Edit, S-64 "Edit" in Edit, S-65 "Recipe" once reviewed,
   and S-2 before it is read (as now). The recipe's title is only the fields' first row, as now,
   and scrolls with them; nothing in the bar or above the strip moves when the list scrolls.
   No test (a view change).
7. **RV-31, where the title is:** `Recipe` gains `titleBox: SourceBox?`, encoded with the
   recipe and decoded with `decodeIfPresent` (nil when missing), so older recipes still read and
   `schemaVersion` is unchanged. `SourceLocator.locate` also places the title when `titleBox` is
   nil and the title isn't empty: a run of 1 to 3 lines on one page (`maximumTitleRun = 3`)
   whose normalized text **equals** the normalized title (pass 1 only, never "contains", so a
   step mentioning the dish isn't taken), tried from the first line. `ReviewEdit.applied` keeps
   it when she changes the title (as a changed ingredient keeps its box). `RecipeView`: a tap on
   the title row selects `titleBox` like any line (strip zoomed and outlined; when the strip
   isn't shown, item 3), and the strip starts at it when nothing is selected. With no
   `titleBox`, page 1 whole, as now. `recipe.json` carries it as it carries the other boxes.

#### Part 4 · Tests

| File | Test | Checks |
|---|---|---|
| `SourceLocatorTests` | a step across pages | a step whose first lines end page 1 and last line starts page 2, with a footer line between: located, box on page 1 holding only page 1's lines |
| | one page first | a step found within one page isn't given a cross-page box |
| `StructuringRulesTests` or `RecipeStructurerTests` (where `ingredientGroups` is tested) | a skipped line is put back | a group whose `nameLine` points at an ingredient line and whose items start after it: that line is an ingredient, first, with `put back: ingredient 1` and no `unused` warning |
| | a line outside a group stays out | an unused line after the last group's last item isn't put back |
| | a heading becomes the name | an unused `Kolaches:` line just before the span names the group "Kolaches" |
| `RecipeValidatorTests` (new) or `RecipeStructurerTests` | a value across a page break is found | a step whose text is split by a footer line in `pageText` is found with `clutterFreeText` |
| `SourceLocatorTests` | the title is placed | a title equal to a page-1 line gets that line's box; a title found only inside a step's line gets none |
| `RecipeJSONTests` | an older recipe reads | recipe JSON with no `titleBox` decodes, `titleBox` nil, the rest unchanged |
| `ReviewFlagTests` | put back | `put back: ingredient 2` gives `.putBack` on the second ingredient, and `line(for:)` is S-52l |

**The suite total:** M3-4's total (172) plus these 9: **181**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **181** tests (or the total before plus 9,
   said), with the destination string and the run's own total.
3. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty; `promptVersion` and the prompts
   are unchanged (these are rules after the model).
4. A scan of every string literal in the changed views finds only `13` §6's words (S-52l, S-61,
   S-62, S-63 to S-65 new), SF Symbol names, the `AppStorage` key, accessibility labels already named, and log
   text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad)

1. Rescan the kolaches pages: the yeast line is first under a "Kolaches" subheading, tinted with
   "Put back from the page. Check it."; step 1 "Bloom yeast" has no flag, and tapping it outlines
   its part at the foot of page 2.
2. The hint shows on the first recipe in review and is gone after the first tap, for good.
3. Looks Good: the strip goes and the recipe starts at its title. ⋯ › View Pages swipes through
   the pages; tapping an ingredient opens its page zoomed and outlined.
3a. The bar reads Review while checking, Edit in Edit, Recipe once reviewed, small; scrolling the
   list moves nothing over the scan, and the recipe's title scrolls with the list.
3b. After Read Again on the kolaches (or a rescan), tapping the title outlines it on page 1.
4. A recipe with "Check the ingredients.": one tinted line atop the list, rows plain.
5. Spike run 8 (or 9): titles, lines and steps no worse than run 7; step positions up.

#### Do not

Change `SylantroSchemaV1` or any synced model, the prompts or `promptVersion`, `TextReader`,
`ExtractionPlanner`, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, the entitlements, build
settings or SyLib. No dish photos (SC-15: after M3). No popover, tip bubble or confirmation
dialog (SLT-088). No string she reads beyond `13` §6. No network. Edit no document except §2 of
this one.

---

### Task M3-3b · Sylantro · Editing a row in a sheet

**Status: complete, 24 Nov 2026 (184 tests; §2).** Notes a to k accepted. SC-19 to SC-21 ruled
(`13` v0.35); S-66 to S-71 approved (`13` v0.36) (the agent uses them as written and notes it).

**Inputs:** `00`, `00A`, `00B`, `13` v0.38 (§2, §4.2, §4.4 "Editing", §4.6, SC-10, SC-14, SC-18 to SC-21, §6), this
document (Tasks M3-3, M3-3a, M3-4), and these files: `Views/Recipe/RecipeView.swift`,
`Views/Library/LibraryView.swift`, `Domain/Review/ReviewEdit.swift`, `SylantroTests/Domain/ReviewEditTests.swift`, and SyLib's
`IconButton`.

*Why:* on device (Pops, 24 Nov 2026: "Editing is useless as is. The rows are long and only having
a single line text field ain't gonna cut it. The multi line is better but still clunky… Tap a
row, see a new sheet for editing it. Save cancel."), an ingredient line was cut off in its
one-line field and a long step grew the list as she typed. And (SC-20) Add Page and Edit are
seldom needed after the first scan, so they move into ⋯. And (SC-21) a scan still being read sat among finished recipes.

#### Part 1 · `ReviewEdit` by field (Domain, `import Foundation` only)

1. `ReviewEdit.Field`, an enum: `title`, `yield`, `notes`, `ingredient(UUID)`, `step(UUID)`.
2. `text(for: Field) -> String`: that field's text in the edit; `""` for an id not in it.
3. `setting(_ text: String, for: Field) -> ReviewEdit`: the edit with that field's text
   replaced, nothing else changed; an id not in it changes nothing.
4. `removing(_ field: Field) -> ReviewEdit`: an ingredient or step removed by id (an emptied
   group stays; `applied` already drops it); `title`, `yield` and `notes` set to `""`.

`applied(to:now:)` and `RecipeEditor.saveEdits` are unchanged: Done still saves the whole edit.

#### Part 2 · Edit's rows (`RecipeView`, every device)

1. In Edit, the title, Serves or Makes, each ingredient line, each step and the notes are plain
   text rows showing the edit's text in full (wrapping, no line limit), not text fields. An empty
   one shows its heading's word in secondary color (S-51 "Serves", "Notes"; S-66 for the title).
   Delete (red minus and swipe), the drag handles, the + rows and M3-4's Pages section stay as
   they are.
2. **A tap on a row in Edit** selects its place on the page, as a tap does outside Edit (the strip
   zooms and outlines it; iPad and Mac: the pages column), and opens the **edit sheet** for that
   field. Outside Edit, a tap only shows the row on the page, as now (SC-19).
3. **A + row** adds an empty line or step to the edit, as now, and opens the sheet for it.

#### Part 3 · The edit sheet (a private view in `RecipeView.swift`, or `Views/Recipe/RowEditSheet.swift`)

1. Presented with `.sheet`, `.presentationDetents([.medium, .large])`, starting at `.medium`,
   with the drag indicator showing. On iPad and Mac it is the system's form sheet (detents are
   iPhone's).
2. **Its bar:** a title naming the field (S-66 "Title", S-51 "Serves", S-67 "Ingredient", S-68
   "Step ‹n›" with the step's place from 1, S-51 "Notes"), inline. Leading: SyLib `IconButton`
   `xmark`, VoiceOver label S-69 "Cancel". Trailing: `IconButton` `checkmark`, the palette's
   accent, VoiceOver label S-69 "Save", disabled while the text equals what the sheet opened with.
3. **Its content, top to bottom:** the field's place on the page, cropped and zoomed as the strip
   does (box fills the width with a 16 pt margin, outlined), about 120 pt tall, so she can read
   the page while the keyboard is up; none when the field has no place. Then one
   `TextField(axis: .vertical)` with `lineLimit(3...)`, focused when the sheet opens, holding the
   field's text in full.
4. **Save** puts the text into the edit (`setting`) and closes the sheet. Nothing is stored yet:
   Done saves as now, and an unchanged edit still saves nothing.
5. **Cancel** closes the sheet and leaves the edit as it was; for a line or step the + just added,
   it is removed (`removing`). A swipe down closes it as Cancel does while nothing changed, and is
   blocked once she has typed (`interactiveDismissDisabled`), so a swipe never loses her words.
6. No alert, popover or confirmation dialog (SLT-088).

#### Part 4 · The toolbar (SC-20) and the library (SC-21), every device

1. Outside Edit, `RecipeView`'s toolbar holds only ⋯ (SyLib `IconButton` `ellipsis.circle`, as
   now). Its menu, in order: **Edit** (S-70, `pencil`; only once the recipe is read, as the Edit
   button is now), **Add Page** (S-22, `doc.badge.plus`; disabled with no `CaptureRecorder`, as
   now), **View Pages** (S-62, M3-3a; only when the strip isn't shown), a `Divider`, then
   **Delete Recipe** (S-23, destructive, as now).
2. Edit in the menu sets `editMode` to `.active`; `beginEditing` runs from the existing
   `onChange`, unchanged.
3. In Edit the toolbar holds only iOS's `EditButton()` (its Done, S-50), which ends Edit and saves
   as now; ⋯ is hidden until Edit ends.
4. The Add Page and Edit toolbar buttons are removed. Add Page's camera, the page question and
   M3-4's Pages section are unchanged.
5. **SC-21, `LibraryView`:** a recipe not read yet (`extraction == nil`: waiting, reading, or
   couldn't be read) goes in a new first section headed **New Scans** (S-71), newest first, only
   while it holds a recipe. Then Needs Review (S-44) as now, then the unheaded rest. Each row's
   line is unchanged (S-45, S-46, S-47's row line as M3-3 built it). Once read, a recipe moves
   to Needs Review (or the rest) on its own, since the sections come from the same query.
6. **S-72:** M3-4's Pages section in Edit gets the heading **Pages** (`13` §4.6; M3-4 note a).

#### Part 5 · Tests

| File | Test | Checks |
|---|---|---|
| `ReviewEditTests` | text by field | `text(for:)` gives the title, yield, notes, an ingredient's line and a step's text by id; `""` for an unknown id |
| | setting a field | `setting` changes only that ingredient's text; the groups, order and other fields are equal |
| | removing a new line | `removing(.ingredient(id))` takes that line out and leaves its group; `removing(.step(id))` the same for a step |

**The suite total:** M3-3a's total (181) plus these 3: **184**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **184** tests (or the total before plus 3,
   said), with the destination string and the run's own total.
3. `Domain/Review/ReviewEdit.swift` imports only Foundation; `git diff --
   Sylantro/Store/SylantroSchemaV1.swift` is empty; `RecipeEditor` is unchanged.
4. A scan of every string literal in the changed views finds only `13` §6's words (S-66 to S-72
   new), SF Symbol names, accessibility labels already named, and log text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad)

1. Edit, tap a long step: a half-height sheet opens with the step's part of the page at its top
   and the whole step in the field; the strip above outlines it.
2. Change it, Save, then Done: the step is saved and the recipe is edited. Edit again, change a
   line, Cancel: nothing changed.
3. Type in a sheet and swipe down: it stays open. Drag it up: it goes full height.
4. + under the ingredients opens an empty sheet; Cancel leaves no empty row.
5. Outside Edit, a tap still only shows the row on the page.
6. The toolbar shows only ⋯ (Edit, Add Page, View Pages, Delete Recipe); in Edit only Done.
7. Scan a recipe: it sits under New Scans, "Reading…", above Needs Review; once read it moves to
   Needs Review.

#### Do not

Change `SylantroSchemaV1` or any synced model, `RecipeEditor`, `ReviewEdit.applied`, the
structurer, the prompts, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, the entitlements, build
settings or SyLib. No editing outside Edit. No toolbar button but ⋯, and Done in Edit. No popover, tip bubble or confirmation dialog
(SLT-088). No string she reads beyond `13` §6. No network. Edit no document except §2 of this one.

---

### Task M3-3c · Sylantro · Read Again in ⋯, and a zoom limit

**Status: complete, 24 Nov 2026 (187 tests; §2).** Notes a to d accepted. RV-33 ruled; S-73 proposed (used as written).

**Inputs:** `00`, `00A`, `00B`, `13` v0.39 (§4.2, §4.4, §6), this document (RV-7, RV-33, Tasks
M3-3, M3-3a, M3-3b, M3-4), and these files: `Views/Recipe/RecipeView.swift` (`PageStrip`,
`readAgainOrAsk`, `readAgain`, the ⋯ menu), `Views/Recipe/PagePhotoViewer.swift`,
`Capture/CaptureRecorder.swift` (`readAgain`, read only).

*Why:* on device after M3-3b (Pops, 24 Nov 2026, screen recording), the kolaches recipe still
showed its old reading (no yeast line, steps outlined in the wrong places) because M3-3a's fixes
apply only when a recipe is read, and the only ways to read again were Add Page or a rescan. And a
short line such as "2 large eggs" was zoomed to fill the strip, blurry.

#### Part 1 · `LineZoom` (Domain, `Domain/Review/LineZoom.swift`, `import Foundation` only)

1. `LineZoom.maximum = 2.5`.
2. `static func scale(boxWidth: Double, viewWidth: Double, margin: Double) -> Double`: the zoom
   that makes a box (its width normalized 0 to 1 of the page) fill `viewWidth` less a margin each
   side, never below 1 (the page at the view's width) and never above `maximum`. A box of zero
   width, or a view narrower than two margins, gives 1.

#### Part 2 · The zoom limit (`RecipeView.swift`, `PagePhotoViewer.swift`)

1. `PageStrip` uses `LineZoom.scale` in place of its own `max(1, …)`, so a line is never shown
   more than 2.5× the page-at-width size. When the cap applies, the box stays centered
   horizontally and vertically in the strip (clamped to the page's edges as now), so the page
   around it shows. The edit sheet's crop (M3-3b) uses `PageStrip`, so it follows.
2. `PagePhotoViewer`'s zoom to a box when it opens uses `LineZoom.scale` too. Her pinch range
   (1 to 6) is unchanged.

#### Part 3 · Read Again in ⋯ (RV-33)

1. The ⋯ menu gains **Read Again** (S-59's word, `arrow.clockwise`), after View Pages and before
   the divider. It shows once the recipe is read, and is disabled while the queue is reading this
   recipe (`currentRecipeID`) or with no `CaptureRecorder`.
2. A recipe she hasn't edited (`reviewState != .edited`) is read again at once (`readAgain`, as
   M3-4's). An edited one asks first with a plain alert: title S-57 "Read the Pages Again?",
   message **S-73**, buttons S-59 Read Again and Keep My Edits; Read Again calls `readAgain`;
   Keep My Edits does nothing. A failed read again shows S-14 with OK, as M3-4's.
3. M3-4's own question after a page change (S-57, S-58) is unchanged.

#### Part 4 · Tests

| File | Test | Checks |
|---|---|---|
| `LineZoomTests` (new) | a short line is capped | a box 0.1 wide in a 390 pt view with 16 pt margins gives 2.5 |
| | a wide line fits | a box 0.8 wide gives (390 − 32) / (0.8 × 390), between 1 and 2.5 |
| | never below the page | a box 1.0 wide gives 1; a box of width 0 gives 1 |

**The suite total:** M3-3b's total (184) plus these 3: **187**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **187** tests (or the total before plus 3,
   said), with the destination string and the run's own total.
3. `Domain/Review/LineZoom.swift` imports only Foundation; `git diff --
   Sylantro/Store/SylantroSchemaV1.swift` is empty; `CaptureRecorder` and `RecipeEditor` are
   unchanged.
4. A scan of every string literal in the changed views finds only `13` §6's words (S-73 new),
   SF Symbol names and log text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro)

1. Kolaches: ⋯ › Read Again. If it was edited, the question comes first. It reads ("Reading…"),
   then the yeast line is back under "Kolaches", and each step outlines its own part of the page.
2. Tap "2 large eggs": the line is larger than on the page but sharp, with the lines around it
   showing; a long step still fits the width.
3. ⋯ › Read Again is greyed while the recipe is being read.

#### Do not

Change `SylantroSchemaV1` or any synced model, `CaptureRecorder`, `RecipeEditor`, the structurer,
the prompts, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, the entitlements, build settings or
SyLib. No popover, tip bubble or confirmation dialog (SLT-088). No string she reads beyond `13` §6.
No network. Edit no document except §2 of this one.

---

### Task M3-3d · Sylantro · Every line placed on the page

**Status: complete, 24 Nov 2026 (191 tests; §2).** Notes a to g accepted; (e) a short part can match inside an unrelated line, to watch on device. RV-34 ruled. No new words.

**Inputs:** `00`, `00A`, `00B`, `13` v0.39 (§4.4, §6), this document (RV-31, RV-34, Tasks M3-3a,
M3-3b, M3-3c), and these files: `Domain/Recipe/Recipe.swift`, `Domain/Recipe/IngredientGroup.swift`,
`Domain/Recipe/RecipeRendering.swift` (read only), `Domain/Structuring/SourceLocator.swift`,
`Domain/Review/ReviewEdit.swift` (read only), `Views/Recipe/RecipeView.swift`, and the tests
`SourceLocatorTests.swift`, `RecipeJSONTests.swift`.

*Why:* only the title, ingredients and steps had a place on the page (Pops, 24 Nov 2026: "I think
all the lines should zoom, even the ones in the header like yield, and active time"). Written
after M3-3c had already run, so it is its own task.

#### Part 1 · Every line placed on the page (RV-34)

1. `Recipe` gains `fieldBoxes: [String: SourceBox]`, encoded with the recipe, decoded with
   `decodeIfPresent` (empty when missing), `schemaVersion` unchanged. Its keys: `yield`, `times`,
   `notes`, `nutrition`, `equipment.‹n›` and `source.‹n›` (from 0, in the order the screen shows
   them: `equipment`, and `RecipeRendering.sourceLines`). `IngredientGroup` gains `nameBox:
   SourceBox?` the same way.
2. `SourceLocator.locate` also places these, after the title, each only when it has no box yet,
   with one rule: the field's text is split into **parts** at `;` and line breaks (trimmed, empty
   parts dropped); each part is found as a line or a run of up to 4 lines (equal, else contains,
   as `find`); the box is the union of the parts found on the page of the first part found. A
   field with no part found gets no box. The yield uses `yieldLine`, the times `timesLine`, the
   notes and nutrition their text, each equipment item and source line its own text, a group's
   name its name.
3. `RecipeView`: a tap on any of those rows (yield, times, notes, nutrition, an equipment item, a
   source line, a group's name) shows its box as a line's is shown (strip, iPad and Mac column,
   or the viewer when the strip is hidden), zoomed with M3-3c's `LineZoom` limit; with no box, its first
   page whole, as now. In Edit the yield and notes sheets show their box's crop (M3-3b part 3).
4. `ReviewEdit.applied` keeps `fieldBoxes` and `nameBox` (it starts from the recipe). Older
   recipes get them on ⋯ › Read Again (M3-3c).

#### Part 2 · Tests

| File | Test | Checks |
|---|---|---|
| `SourceLocatorTests` | the times are placed | times text "Active Time: 1 hr; Total Time: 3 hrs 25 mins" printed on two page-1 lines gets one box, their union |
| | the yield is placed | a yield "Yield: 3 dozen" equal to a page-1 line gets that line's box |
| | a group's name is placed | a group named "Kolaches" with a page line "Kolaches:" gets that line's box as `nameBox` |
| `RecipeJSONTests` | older recipes read | recipe JSON with no `fieldBoxes` or `nameBox` decodes, empty and nil |

**The suite total:** M3-3c's total (187) plus these 4: **191**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **191** tests (or the total before plus 4,
   said), with the destination string and the run's own total.
3. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty; the prompts and `promptVersion`
   are unchanged; `SourceLocator.swift` and the changed Domain files import only Foundation.
4. A scan of every string literal in the changed views finds nothing new she reads.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro)

1. Kolaches: ⋯ › Read Again. Then tap Yield, the times, "Kolaches" (the group's name) and a source
   line: each zooms to its place on the page; the times outline every times line together.
2. A recipe not read again: those rows show page 1 whole, as before.

#### Do not

Change `SylantroSchemaV1` or any synced model, `CaptureRecorder`, `RecipeEditor`, the structurer's
prompts, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, the entitlements, build settings or
SyLib. No popover or confirmation dialog (SLT-088). No string she reads beyond `13` §6. No network.
Edit no document except §2 of this one.

---

### Task M3-3e · Sylantro · Two fixes found reading the kolaches again

**Status: ready, not started; runs before or after M3-5** (they touch different parts; the test
total is the total before plus 2). Nothing new to rule: both fixes make M3-3a's RV-29 and RV-11
work as ruled.

**Inputs:** `00`, `00A`, `00B`, this document (RV-11, RV-29, Tasks M3-3, M3-3a, M3-3c), and these
files: `Extraction/RecipeStructurer.swift` (`ingredientGroups(from:lines:)`),
`Domain/Structuring/WrapJoiner.swift` (`startsIngredient`), `SylantroTests/Extraction/RecipeStructurerTests.swift`,
`Views/Recipe/RecipeView.swift` (`PageStrip`, `stripPhoto`, `show`).

*Why:* on device (Pops, 25 Nov 2026, screen recording after ⋯ › Read Again on the kolaches):
1. The first two ingredients under "Kolaches:" (the yeast and the warm water) are still missing.
   The model's answer starts the group at the third line and gives no name line, so the group's
   span starts there; RV-29's put-back only looks inside a span, and the heading rule looks at the
   line before the span, which is an ingredient, so the heading is lost too.
2. On iPhone, tapping step 1 or step 2 outlines the right shape but on page 1's photo; the steps
   are on later pages. On iPad the pages column scrolls to the right page, so the steps' boxes
   carry the right page: the iPhone strip keeps showing the first page's image.

#### Part 1 · Ingredient lines before a group's first one (`RecipeStructurer`, RV-29)

In `ingredientGroups(from:lines:)`, **before** the rule that names a group from the heading before
its span, for each group with a span, in order: walk back from the line before the span's first
line while the line is not used, doesn't end with `:`, and `WrapJoiner.startsIngredient` is true;
each such line is put back as RV-29's are (parsed, `put back: ingredient n` warning) and the span
starts at it. Stop at a used line, a line ending with `:`, a line that doesn't start like an
ingredient, or line 1. Then the naming rule runs as now, so the heading before the moved span
(here "Kolaches:") names the group. The structurer's prompts, `instructions`, `@Guide`s and
`promptVersion` are unchanged.

#### Part 2 · The strip shows the tapped line's page (`RecipeView`, RV-11)

1. `PageStrip` is given `.id(photo?.sourcePageID)` where `RecipeView` places it (the strip and
   the edit sheet's crop), so a line on another page gets a fresh strip with that page's image.
   The agent checks why the image didn't change with `.task(id:)` alone and says so in the notes;
   if it finds a different cause, it fixes that one instead and explains.
2. One log line on each tap in `show`: the tapped box's page number (its place in
   `sourcePageIDs`, from 1), the strip photo's page number and file name. No recipe text.

#### Part 3 · Tests

| File | Test | Checks |
|---|---|---|
| `RecipeStructurerTests` | lines before the first are put back | lines "Dough:", "1 Tbsp. yeast", "1/2 cup water", "1/4 cup butter", "1 cup milk", with the model giving only the last two and no name line: the group is named "Dough" and holds all four, the first two with `put back` warnings |
| | a used line stops the walk | the line before the span belongs to another group: nothing is put back from it |

**The suite total:** the total before plus these 2 (199 after M3-5s; 216 after M3-5).

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with the total before plus 2, said, with the
   destination string and the run's own total.
3. `git diff` of `RecipeStructurer.swift` changes only `ingredientGroups(from:lines:)` (no prompt,
   `instructions`, `@Guide` or `promptVersion` change); `git diff --
   Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes; the new log line holds no recipe text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro)

1. Kolaches: ⋯ › Read Again. "Kolaches" is a subheading again, with the yeast and the warm water
   first, each flagged "Put back from the page. Check it."
2. Tap step 1, then step 2: the strip moves to each step's own page, outlined.

#### Do not

Change the prompts or `promptVersion`, `SylantroSchemaV1` or any synced model, `CaptureRecorder`,
`RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, the entitlements, build settings
or SyLib. No string she reads. No page content in the repo (SLT-092). No network. Edit no document
except §2 of this one.

---

### Task M3-5s · Sylantro · Finding each recipe's title on a page (spike)

**Status: complete, 24 Nov 2026 (197 tests; §2); run 8 scored 25 Nov 2026 (`10` §7): the model's list kept.** Notes a to g accepted; (f) a refused piece isn't retried, so run 8 is best kept in front. RV-14 and RV-35 ruled. Spike only: nothing
she sees changes. Its spike run is **run 8**, which also serves as M3-3a's check 5.

**Inputs:** `00`, `00A`, `00B`, `10` §7 (runs 6 and 7), `11` (the spike's rules), this document
(RV-14, RV-35, Task M3-1), and these files: `Extraction/RecipeStructurer.swift`,
`Extraction/GeneratedParts.swift`, `Extraction/PageReading.swift`,
`Extraction/Spike/SpikeRunner.swift`, `Extraction/Spike/SpikeReport.swift`,
`Domain/Structuring/HeaderArea.swift`, `Domain/Structuring/TextMatch.swift`.

*Why:* RV-14 ruled that she picks the recipes to save from a list of the page's titles, then
each is structured from its title to the next. That assumed the header answer's `otherTitles`
(SLT-151) names them, but in run 7 it named none on TP-24, the four-recipe page. RV-35: try two
ways to find the titles side by side in the spike, on every test page, and keep the better one
for M3-5.

#### Part 1 · Big-type titles (Domain, `Domain/Structuring/PageTitles.swift`, Foundation only)

1. `PageTitles.bigType(_ pages: [[(text: String, height: Double)]]) -> [Found]`, where
   `Found` is `(page: Int, firstLine: Int, lastLine: Int, text: String)`. On each page, a line
   is **big** when its height is at least 1.4× the median height of that page's lines, its text
   has 3 to 80 characters, at least half of them letters, and its normalized text is not a
   section word (ingredients, directions, instructions, method, steps, preparation, notes,
   equipment, nutrition, for the …, and their singulars). Big lines next to each other on one
   page are one title (a wrapped title), their texts joined with a space.
2. `PageTitles.cut(lineCount: [Int], titles: [Found]) -> [(from: (page: Int, line: Int), to:
   (page: Int, line: Int))]`: with two or more titles, the pieces from each title's first line
   to the line before the next title's (the last one to the end); with fewer, none.

#### Part 2 · The model's titles (`Extraction/TitleLister.swift`, spike only)

1. `@Generable GeneratedPageTitles { titles: [String] }`, guide: "The title of every separate
   recipe on this page, exactly as printed, in reading order. One title if there is one recipe."
2. `TitleLister.titles(numberedLines:) async throws -> [String]`: one call with the structurer's
   numbered page lines and its instructions, the same token cap as the header part. A returned
   title is kept only when it is a whole line or two adjacent lines of the page
   (`TextMatch.normalize` equal), as SLT-151 checks; the rest are dropped and counted.
3. Not used outside the spike. The structurer, its prompts and `promptVersion` are unchanged.

#### Part 3 · The spike (`SpikeRunner`, `SpikeReport`)

After a capture is structured as now, the spike also, for each way (`bigType`, `model`):

1. records the titles found (`[String]`) and, for the model, the count dropped;
2. when it found two or more, cuts the capture with `PageTitles.cut` and structures each piece
   on its own with `structurer.structure` (the piece's readings, the same page IDs), recording
   for each piece its title, ingredient count, step count and warnings, and the total time.

`SpikeCaptureResult` gains `titlesBigType`, `titlesModel`, `titlesModelDropped`,
`piecesBigType`, `piecesModel` (each piece `{title, ingredientCount, stepCount, warnings,
millis}`), all optional so older results still decode. The JSON export carries them. A refusal or
failure in this extra work is recorded on the capture and doesn't fail it.

#### Part 4 · Tests

| File | Test | Checks |
|---|---|---|
| `PageTitlesTests` (new) | big lines are titles | on a made-up page with body lines 10 high and two lines 16 high, both are found, in order |
| | a section word isn't | a line "Ingredients" 16 high isn't found |
| | a wrapped title is one | two adjacent big lines give one title, joined |
| | cut by titles | three titles on a 30-line page give three pieces, each from its title to the line before the next |
| | one title, no cut | one title gives no pieces |
| `SpikeReportTests` or `SpikeRunnerTests` (where the export is tested) | older results read | a result without the new fields decodes, each nil |

**The suite total:** M3-3d's total (191) plus these 6: **197**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **197** tests (or the total before plus 6,
   said), with the destination string and the run's own total.
3. `git diff` of `RecipeStructurer.swift` and `GeneratedParts.swift` has no change to the
   prompts, `instructions`, `@Guide`s or `promptVersion`; `SylantroSchemaV1` is unchanged;
   `PageTitles.swift` imports only Foundation; nothing outside `Extraction/Spike/` calls
   `TitleLister` or `PageTitles.cut`.
4. No string she reads changes.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

Run the spike's test set (run 8) and save the results JSON to `sylantro-testpages/results/` as
before. Claude scores it: for each way, TP-24's four titles found and cut, and on the other 21
pages no second title found (no false splits); and, for M3-3a's check 5, titles, lines and steps
against run 7.

#### Do not

Change what she sees, the structurer's prompts or `promptVersion`, `SylantroSchemaV1` or any
synced model, `ExtractionQueue`, `CaptureRecorder`, `RecipeEditor`, `MirrorWriter`,
`Info.plist`, the entitlements, build settings or SyLib. No page content in the repo (SLT-092):
the tests use made-up lines. No network. Edit no document except §2 of this one.

---

### Task M3-5 · Sylantro · Several recipes on a page, and a page that isn't a recipe

**Status: ready, not started; runs after M3-5s.** RV-14, RV-32, RV-35 and RV-36 ruled; `13`
v0.40's SC-22 and S-74 to S-77 proposed, with S-52m and S-73 (the agent uses them as written and
notes it).

**Inputs:** `00`, `00A`, `00B`, `10` §7 (run 8), `13` v0.40 (§4.4 "Several recipes on a page" and
"Not a recipe", §6), this document (RV-14, RV-32, RV-35, RV-36, Tasks M3-3b, M3-3c, M3-5s), and
these files: `Extraction/ExtractionQueue.swift`, `Extraction/TitleLister.swift`,
`Extraction/RecipeStructurer.swift` (read only), `Extraction/Spike/SpikeRunner.swift`,
`Domain/Structuring/PageTitles.swift`, `Domain/Structuring/HeaderArea.swift`,
`Domain/Structuring/ReviewFlag.swift`, `Domain/Structuring/TextMatch.swift`,
`Domain/Structuring/ScriptCheck.swift`, `Domain/Recipe/Recipe.swift`,
`Domain/Extraction/ExtractionPlanner.swift` (`merged`), `Store/RecipeEditor.swift`,
`Capture/CaptureRecorder.swift`, `Capture/PhotoFiles.swift`, `Views/Recipe/RecipeView.swift`.

*Why:* SLT-047 and RV-14: on a page with several recipes she picks which to save, and each is
read from its title to the next. Run 8 (`10` §7) found TP-24's four titles with the model's list
and one false split (a wrapped title given as its two lines), so the list is kept with titles on
adjacent lines joined (RV-35). Each recipe split off gets its own copy of the page (RV-36). RV-32:
the floss box was read as a recipe, so a reading that doesn't look like one is flagged. And run 8
lost TP-18's title to the "Author: … Prep Time: …" line after it.

**Line numbers.** Throughout, a page's lines are its **readable lines**: the reading's lines that
pass `ScriptCheck.isLatin`, in order, numbered from 0, as `SpikeRunner.findTitles` uses them.

#### Part 1 · Domain (`import Foundation` only)

1. **`PageTitle`** (`Domain/Recipe/PageTitle.swift`), `Codable, Hashable, Sendable`: `text`,
   `pageID: UUID`, `firstLine: Int`, `lastLine: Int`. **`PagePiece`**, the same file: `title:
   String`, `fromPageID`, `fromLine`, `toPageID`, `toLine`.
2. **`Recipe`** gains, each decoded with `decodeIfPresent` so older blobs read (no schema change):
   `pageTitles: [PageTitle]` (default `[]`): the recipe titles the list found on its pages, kept
   only when two or more; `piece: PagePiece?` (default nil): set on a recipe split off a page (and
   on the one it was split from), the part of its pages it is read from; `isOneRecipe: Bool`
   (default false): It's All One Recipe was tapped.
3. **`PageTitles`** (`Domain/Structuring/PageTitles.swift`) gains:
   - `positions(of titles: [String], in pages: [[String]]) -> [Found]`: `SpikeRunner.positions`
     moved here unchanged (a title is the first line, or two adjacent lines on one page, equal to
     it normalized; already placed or not found, left out; in reading order). `SpikeRunner` calls
     this one.
   - `joiningAdjacent(_ titles: [Found]) -> [Found]`: titles on one page whose lines touch (one's
     `lastLine + 1` is the next's `firstLine`) become one, texts joined with a space (TP-04's
     wrapped title).
   - `pieces(of all: [PageTitle], keeping kept: [PageTitle], pageIDs: [UUID], lineCounts: [UUID:
     Int]) -> [PagePiece]`: for each kept title, in page order, from its first line to the line
     before the **next title in `all`** (kept or not), the last one to the end of the last page;
     `pageIDs` gives the page order.
   - `lines(_ pages: [[String]], pageIDs: [UUID], in piece: PagePiece) -> [[String]]`: each page's
     lines kept only when inside the piece (both ends included), every page kept, so the page IDs
     line up (as `SpikeRunner.pieces` does).
   - `otherRecipesWarnings(_ warnings: [String], titles: [PageTitle], title: String) -> [String]`:
     the warnings with every `may hold other recipes: …` warning removed, then, with two or more
     titles, `RecipeStructurer.otherRecipesWarning`'s text added for the titles whose normalized
     text isn't the recipe's title. (The text is `may hold other recipes: ` and the titles joined
     with `; `; Domain repeats it rather than importing the structurer.)
4. **`HeaderArea.isSideLine`** also takes a **label line**: one whose normalized text starts with
   `author`, `by `, `prep time`, `cook time`, `total time`, `active time`, `yield`, `serves`,
   `servings` or `makes`, followed by `:` or a space and more text. So a snapped title never takes
   it in (TP-18). A title that is itself such a line is unchanged (the start line isn't checked).
5. **`RecipeCheck`** (`Domain/Structuring/RecipeCheck.swift`, new), RV-32:
   `warnings(for recipe: Recipe) -> [String]` gives `["may not be a recipe"]` when no ingredient
   has a quantity or a unit, or when more than half of its ingredients and steps together carry a
   `not on page: ingredient n` or `not on page: step n` warning; else `[]`.
6. **`ReviewFlag`**: `may not be a recipe` becomes `Kind.notARecipe`, field `.recipe`, line
   S-52m.

#### Part 2 · Finding the titles, behind her (`ExtractionQueue`, `TitleLister`)

1. `TitleLister` is no longer spike only. `titles(numberedLines:)` is unchanged; the queue calls
   it. The structurer, its prompts, `instructions`, the `@Guide`s and `promptVersion` are
   unchanged.
2. After `structurer.structure` returns, the queue, before `finishStructuring`:
   - **a recipe with a `piece`:** was structured from only the piece's lines
     (`PageTitles.lines`, page readings rebuilt from those lines); its title is set to the piece's
     title, as printed, with `no title` and `title from layout` removed, and its `titleBox` placed
     as any title is (`SourceLocator`); every `may hold other recipes` warning removed; the list
     isn't asked.
   - **a recipe with `isOneRecipe`:** every `may hold other recipes` warning removed; the list
     isn't asked.
   - **any other:** `TitleLister.titles` on the readable lines; `PageTitles.positions`, then
     `joiningAdjacent`; with two or more, they are the recipe's `pageTitles` (page IDs from
     `sourcePageIDs`), else `[]`; the warnings become `otherRecipesWarnings(...)`. A rate-limit
     refusal goes through the same retry as structuring (SLT-153); any other error or refusal
     ("unsafe content", TP-25) means no titles, is logged (no recipe text) and doesn't fail the
     job.
   - **every recipe:** `RecipeCheck.warnings` added.
3. `ExtractionPlanner.merged` keeps the stored recipe's `piece` and `isOneRecipe`; `pageTitles`
   comes from the structured one.
4. The spike keeps both ways as M3-5s built them; it uses `PageTitles.positions` and
   `joiningAdjacent` for the model's titles, so run 9 measures what ships.

#### Part 3 · The writers

1. **`PhotoFiles.copy(_ fileName: String, to newFileName: String) throws`**: the file's bytes
   written as `newFileName` with a coordinated write, never over an existing file (as `write`).
2. **`CaptureRecorder.splitRecipe(_ recipeID: UUID, keeping kept: [PageTitle], now: Date) throws
   -> [UUID]`** (RV-36), with `kept` in page order and at least one:
   - the pieces from `PageTitles.pieces` (all = the recipe's `pageTitles`, line counts from each
     page's readable lines);
   - **this recipe** takes the first piece: `piece` set, `pageTitles` kept, and it is read again
     as `readAgain` does (edited → reopened; its pages wait; readings kept);
   - **each other piece** becomes a new recipe: for each page the piece touches, a new
     `SourcePageModel` (new id, the same session, `ocrText` and `ocrWordsData` copied with each
     word's `SourceBox.pageID` set to the new id, waiting) and a new `PhotoModel` for it whose
     file is a `PhotoFiles.copy` under a new name; then `recipeEditor.insertDraft` (with `continuesOnUnscannedPage` false) with those
     pages, its title the piece's title, its `piece` with the new page IDs;
   - files first, then records, in **one save**, rolled back on failure (as `saveCapture`; copied
     files left behind are logged); then each new recipe mirrored and `onRecipeSaved` called for
     this recipe and each new one, so the queue reads them. Returns the new recipes' IDs.
3. **`RecipeEditor.keepAsOneRecipe(_ recipeID: UUID, now: Date)`**: `isOneRecipe` set, the `may
   hold other recipes` warnings removed, `pageTitles` emptied; saves, as `dismissPageTwoWarning`.

#### Part 4 · Choosing the recipes (`RecipeView`, `13` §4.4, SC-22)

1. When the recipe has two or more `pageTitles`, no `piece` and isn't `isOneRecipe`, S-52i's line
   under the title gets a small **Choose Recipes** button (S-74), styled as That's All of It. Not
   in Edit.
2. It opens a sheet, as `RowEditSheet` is presented (`.medium` and `.large`, starting `.medium`,
   drag indicator; iPad and Mac a form sheet), titled S-75, inline. Leading `IconButton` `xmark`
   (S-69 Cancel); trailing `IconButton` `checkmark` in the accent (S-69 Save), disabled with none
   checked.
3. Content: a list of `pageTitles`, each row the title with a checkmark (`checkmark.circle.fill`
   or `circle`), all checked when the sheet opens, a tap toggling it; under the list S-76 in
   secondary text; at the bottom a plain full-width **It's All One Recipe** button (S-77).
4. **✓**: for a recipe she hasn't edited, `splitRecipe` with the checked titles, and the sheet
   closes. For an edited one, M3-3c's plain alert first (S-57, S-73, Read Again and Keep My
   Edits); Read Again splits, Keep My Edits does nothing and leaves the sheet open. A failure
   shows S-14 with OK.
5. **It's All One Recipe**: `keepAsOneRecipe`, and the sheet closes. **✕** and a swipe down close
   it and change nothing.
6. S-52m shows as any whole-recipe line. No popover, tip bubble or confirmation dialog (SLT-088).

#### Part 5 · Tests

| File | Test | Checks |
|---|---|---|
| `PageTitlesTests` | adjacent titles joined | titles on lines 3 and 4 of one page give one, lines 3 to 4, texts joined; titles on lines 3 and 5 stay two |
| | positions | a one-line and a two-line title are placed; a title not on the page is left out |
| | pieces of the kept | four titles, keeping the 1st and 3rd: two pieces, each ending on the line before the next title of the four |
| | lines in a piece | a piece from page 1 line 8 to page 2 line 3 keeps only those lines, both pages present |
| | the other recipes' warning | three titles, the recipe's own first: one warning naming the other two; one title: the old warning removed, none added |
| `StructuringRulesTests` | a label line isn't title | a title line followed by "Author: … Prep Time: …" at the same size, the model's next line, gives the title line only |
| `RecipeCheckTests` (new) | no amounts | ingredients with no quantity or unit give `may not be a recipe` |
| | most not on the page | 3 of 5 ingredients and steps not on the page give it |
| | a recipe | a recipe with amounts and every line on the page gives none |
| `ReviewFlagTests` | not a recipe | `may not be a recipe` is `notARecipe` on the whole recipe, with S-52m |
| `RecipeJSONTests` | older blobs read | a blob without the three fields decodes with `[]`, nil and false; the fields round-trip |
| `ExtractionPlannerTests` | merged keeps the split | `merged` keeps the stored `piece` and `isOneRecipe` and takes `pageTitles` from the structured recipe |
| `PhotoFilesTests` | copy | a copy has the same bytes under the new name; copying onto an existing name throws |
| `CaptureRecorderTests` | split makes recipes | keeping 3 of 4 titles gives two new recipes, titled, each with its piece and its own pages, waiting, readings copied with their page IDs |
| | split copies photos | each new page's photo has a new file name; the original file is untouched |
| | split keeps this recipe | it takes the first piece, its pages wait, its readings stay |
| wherever `RecipeEditor` is tested | all one recipe | `keepAsOneRecipe` sets the flag, removes the warning, empties `pageTitles` |

**The suite total:** M3-5s's total (197) plus these 17: **214**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **214** tests (or the total before plus 17,
   said), with the destination string and the run's own total.
3. `git diff` of `RecipeStructurer.swift` and `GeneratedParts.swift` is empty; `TitleLister`'s
   `@Guide` and the structurer's `promptVersion` are unchanged; `git diff --
   Sylantro/Store/SylantroSchemaV1.swift` is empty; `PageTitle.swift`, `PageTitles.swift`,
   `HeaderArea.swift` and `RecipeCheck.swift` import only Foundation.
4. A scan of every string literal in the changed views finds only `13` §6's words (S-74 to S-77
   and S-52m new), SF Symbol names, accessibility labels already named, and log text; no log line
   holds a title or any recipe text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad)

1. Scan TP-24 (the four-recipe page). Once read, the line under the title names the other three
   recipes, with Choose Recipes.
2. Choose Recipes: four titles, all checked. Uncheck one, ✓. This recipe now reads as the first
   title only; two new recipes appear in New Scans, then Needs Review, each with the page and its
   own title. Delete one of them: the others keep their page photo.
3. Scan a one-recipe page whose title wraps onto two lines (TP-04): no Choose Recipes line.
4. On a page that does get one wrongly, It's All One Recipe removes it, and ⋯ › Read Again doesn't
   bring it back.
5. Scan something that isn't a recipe (the floss box): "This may not be a recipe. Check it." under
   the title.
6. Scan TP-18: the title is "Healthy Granola" only.
7. Spike run 9 (optional): titles, lines and steps as run 8, TP-18 right again.

#### Do not

Change the structurer's prompts, `instructions`, `@Guide`s or `promptVersion`, `TitleLister`'s
`@Guide`, `SylantroSchemaV1` or any synced model, `MirrorWriter`, `Info.plist`, the entitlements,
build settings or SyLib. Don't share a photo file between recipes (RV-36). No popover, tip bubble
or confirmation dialog (SLT-088). No string she reads beyond `13` §6. No page content in the repo
(SLT-092): tests use made-up lines. No recipe text in logs. No network. Edit no document except §2
of this one.

---

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| M3-5s | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 197 tests in 26 suites passed after 0.779 seconds."; `** TEST SUCCEEDED **`. Total before: 191 (`@Test` count at session start), so 191 + 6 = 197 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 197 tests on the pinned destination. ✅ 3 `git diff -U0` of `RecipeStructurer.swift` and `GeneratedParts.swift`: one change only, `numbered(_:)` from `private static` to `static` with its comment (note b); no prompt, `instructions`, `@Guide`, `TokenCap` or `promptVersion` line; `GeneratedParts.swift` unchanged. `git diff --stat` of `SylantroSchemaV1.swift`: empty; `--cached --quiet`: exit 0. `PageTitles.swift:1` is `import Foundation`, its only import. `grep -rn "TitleLister\.\|PageTitles.cut" Sylantro/`, less `Extraction/Spike/`: nothing. ✅ 4 no view changed (`git diff --stat -- Sylantro/Views/`, unstaged: empty), so no string she reads changes; the spike's export gains fields only. ✅ 5 git status before and after below; this row. **What was built:** part 1 `Domain/Structuring/PageTitles.swift`: `Found` (page, first line, last line, text); `bigType(_:)` (a line at least 1.4× its page's median height, 3 to 80 characters, at least half letters, not a section word or "for the …"; adjacent big lines on one page joined as one title); `cut(lineCount:titles:)` (with two or more titles, each title's first line to the line before the next, the last to the end; with fewer, none). Part 2 `Extraction/TitleLister.swift`: `@Generable GeneratedPageTitles { titles }` with the guide as written; `TitleLister.titles(numberedLines:)`, one greedy call with the structurer's numbered lines and instructions, capped at `TokenCap.header`, keeping a title only when it is a whole line or two adjacent lines (normalized), and counting the rest. Part 3 `SpikeRunner`: after a capture is structured as now, `findTitles` runs both ways, records the titles (and the model's dropped count), and with two or more cuts the capture and structures each piece on its own with `structurer.structure`. Each piece keeps its own lines, the other lines left out, every page kept so the page IDs line up. It records the piece's title, ingredient count, step count, warnings and time. `SpikeCaptureResult` gains `titlesBigType`, `titlesModel`, `titlesModelDropped`, `piecesBigType` and `piecesModel` (`Piece { title, ingredientCount, stepCount, warnings, millis }`), all optional, so older results decode; the export carries them. A failure in this work goes in `partErrors` and doesn't fail the capture. Part 4: 6 tests as the table (`PageTitlesTests` 5, new; `SpikeRunnerTests` 1), every line made up. **Files:** new `Sylantro/Domain/Structuring/PageTitles.swift`, `Sylantro/Extraction/TitleLister.swift`, `SylantroTests/Domain/PageTitlesTests.swift`; changed `Sylantro/Extraction/RecipeStructurer.swift` (`numbered` only), `Sylantro/Extraction/Spike/SpikeRunner.swift`, `Sylantro/Extraction/Spike/SpikeReport.swift`, `SylantroTests/Extraction/SpikeRunnerTests.swift`; this document (this row only). Read and not changed: `GeneratedParts.swift`, `PageReading.swift`, `HeaderArea.swift`, `TextMatch.swift`. No view, prompt, `promptVersion`, `SylantroSchemaV1`, synced model, `ExtractionQueue`, `CaptureRecorder`, `RecipeEditor`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no page content in the repo; no network. **Git status before** (branch `milestone-3`; M3-3b committed as `0897bd5`): staged (`M ` or `A `), Pops's M3-3c and M3-3d and docs: `Docs/12_IMPLEMENTATION_PLAN.md`, `Docs/13_SCREENS.md`, this document, `Docs/README.md`, `Sylantro/Domain/Recipe/IngredientGroup.swift`, `Recipe.swift`, `Domain/Review/LineZoom.swift`, `Domain/Structuring/SourceLocator.swift`, `Views/Recipe/PagePhotoViewer.swift`, `Views/Recipe/RecipeView.swift`, `SylantroTests/Domain/LineZoomTests.swift`, `RecipeJSONTests.swift`, `SourceLocatorTests.swift`. **After:** those as before (this document now `MM`), plus ` M` on `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift` and `SpikeRunnerTests.swift`, and `??` on `PageTitles.swift`, `TitleLister.swift` and `PageTitlesTests.swift`. **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -3`, `git log --oneline -2 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md Docs/10_ACCURACY_TEST_SET.md Docs/11_MILESTONE_1_SPIKE.md`, `git diff -U0 -- Sylantro/Extraction/RecipeStructurer.swift Sylantro/Extraction/GeneratedParts.swift`, `git diff --stat -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff --cached --quiet -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff --stat -- Sylantro/Views/`. **Notes, for Claude to confirm:** (a) Pages and lines in `Found` and `cut` are numbered from 0, as their arrays are; the task didn't say. (b) `TitleLister.titles(numberedLines:)` takes the page's lines and numbers them with the structurer's own `numbered`, made internal, not private. The prompt is those numbered lines alone, with the structurer's instructions and no intro line, since the guide asks the question. It returns `(titles: [String], dropped: Int)`, not `[String]`, so the dropped count reaches the report; the check is `kept(_:lines:)`. (c) The model's "page lines" are the whole capture's readable lines (the structurer's Latin filter, SLT-150), so its "two adjacent lines" check may join the last line of one page and the first of the next. To cut, each kept title is placed on one page (one line, or two adjacent lines there); a title that can't be placed, or a second copy of one already placed, isn't cut, though it stays in `titlesModel`. An empty answer ("none") is dropped and counted. (d) Big type: the median is over all of a page's readable lines, the big ones included. The 3 to 80 characters and the half that are letters are counted on the trimmed text, spaces included. A section word matches only whole, after normalizing, besides the "for the" prefix, so "Ingredients for the cake" isn't caught. (e) Lines before the first title belong to no piece. (f) A piece's title is the title's text (the model's own for `model`), and its `millis` is the piece's parts' times added (the "total time"). A failed piece, a rate-limit refusal included, is left out and recorded in `partErrors["pieces ‹way› ‹n›"]`; a failed model call in `partErrors["titles model"]`. There is no wait or retry for a refusal in this extra work. (g) The extra work runs only after a capture structures successfully, before it is marked done (so it still shows as structuring meanwhile). `structureMillis` doesn't include it. **Next:** Pops's step on device (iPhone 18 Pro): spike run 8 on the test set, results saved to `sylantro-testpages/results/`, scored by Claude for both ways (TP-24's four titles and cut; no second title on the other 21) and for M3-3a's check 5. Not run in this session |
| M3-3d | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 191 tests in 25 suites passed after 0.669 seconds."; `** TEST SUCCEEDED **`. Total before: 187 (`@Test` count at session start), so 187 + 4 = 191 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 191 tests on the pinned destination. ✅ 3 `git diff --stat` of `SylantroSchemaV1.swift`, `Sylantro/Extraction/` (the structurer, its prompts and `promptVersion`), `CaptureRecorder.swift`, `RecipeEditor.swift` and `Sylantro/Mirror/`: empty; `git diff --cached --quiet`: exit 0. `Recipe.swift:1`, `IngredientGroup.swift:1` and `SourceLocator.swift:1` are each `import Foundation`, the only import. ✅ 4 a Python scan of the string literals this session added to the changed view (`RecipeView.swift`; its diff less M3-3c's, kept from that session): none, so nothing new she reads. ✅ 5 git status before and after below; this row. **What was built:** part 1.1 `Recipe.fieldBoxes: [String: SourceBox]` (`decodeIfPresent`, empty when missing, `schemaVersion` unchanged), its keys in `Recipe.FieldBoxKey` (`yield`, `times`, `notes`, `nutrition`, `equipment(n)` and `source(n)`, from 0); `IngredientGroup.nameBox: SourceBox?` (`decodeIfPresent`, nil when missing). Part 1.2 `SourceLocator.locate`, after the title, places each field with no box yet by one rule (`fieldBox`): the text split at `;` and line breaks, trimmed, empty parts dropped; each part found by `find` (equal, else contains) as a run of up to `maximumFieldPartRun = 4` lines on one page; the union of the parts found on the first found part's page; no box when no part is found. The texts are `yieldLine`, `timesLine`, the notes, the printed nutrition, each equipment item, each of `RecipeRendering.sourceLines`, and each group's name. Part 1.3 `RecipeView`: outside Edit, the yield, times, notes, nutrition, each equipment item, the author and publisher lines, and each group's name are tappable lines (`placedLine`, through M3-3's `tappableLine` and `show`). So a tap uses the strip, the iPad and Mac column, or the viewer when the strip is hidden, with M3-3c's `LineZoom` limit; with no box, the first page whole. In Edit, the Serves and Notes sheets (and their rows' taps) use `fieldBoxes` through `fieldBox`. Part 1.4 `ReviewEdit.applied` is unchanged and keeps both, since it starts from the recipe; older recipes get them on Read Again. Part 2: 4 tests as the table (`SourceLocatorTests` 3, `RecipeJSONTests` 1). **Files:** `Sylantro/Domain/Recipe/Recipe.swift`, `Sylantro/Domain/Recipe/IngredientGroup.swift`, `Sylantro/Domain/Structuring/SourceLocator.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `SylantroTests/Domain/SourceLocatorTests.swift`, `SylantroTests/Domain/RecipeJSONTests.swift`; this document (this row only). Read and not changed: `RecipeRendering.swift`, `ReviewEdit.swift`. No `SylantroSchemaV1`, synced model, `CaptureRecorder`, `RecipeEditor`, prompt, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no popover or confirmation dialog; no new words; no network. **Git status before** (branch `milestone-3`; M3-3b committed as `0897bd5`, M3-3c not yet committed): ` M` `Docs/12_IMPLEMENTATION_PLAN.md`, `Docs/13_SCREENS.md`, this document, `Docs/README.md`, `Sylantro/Views/Recipe/PagePhotoViewer.swift`, `Sylantro/Views/Recipe/RecipeView.swift`; `??` `Sylantro/Domain/Review/LineZoom.swift`, `SylantroTests/Domain/LineZoomTests.swift`. **After:** those, plus ` M` on `Recipe.swift`, `IngredientGroup.swift`, `SourceLocator.swift`, `RecipeJSONTests.swift` and `SourceLocatorTests.swift` (`RecipeView.swift` and this document already ` M`). **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -3`, `git log --oneline -2 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md`, `git diff --stat -- Sylantro/Store/SylantroSchemaV1.swift Sylantro/Extraction/ Sylantro/Capture/CaptureRecorder.swift Sylantro/Store/RecipeEditor.swift Sylantro/Mirror/`, `git diff --cached --quiet`, `git diff -U0 -- Sylantro/Views/`. **Notes, for Claude to confirm:** (a) The keys are in a nested `Recipe.FieldBoxKey`, so `SourceLocator` and `RecipeView` read one set (`00A` §10); the task named the keys, not where they live. (b) `fieldBoxes` is encoded by the synthesized encoder, so a recipe with none writes `"fieldBoxes" : {}` in `recipe.json`; a nil `nameBox` isn't written. Older files decode with it empty and nil. (c) **The source's web address stays a link**: a tap opens it, as before, rather than showing its place. Its box is still saved as `source.‹n›`. The author and publisher lines show their places. (d) In Edit, the other lines (times, equipment, nutrition, source, group names) stay as read and aren't tappable, as M3-3b's Edit had them. Only the Serves and Notes rows and sheets use their boxes, as part 1.3 says. (e) Each part is looked for from the first line, apart from the others (no cursor), on one page (no crossing). With "contains", a short part can match inside an earlier, unrelated line (an equipment item "Pot" inside a step), as `find`'s second pass does for any target. (f) A source line's number is its place among the lines shown: the author 0 when present, then the publisher, then the address, as `sourceLines` numbers them. (g) The working tree held M3-3c's uncommitted work at the start; it was built on as found. **Next:** Pops's check on device (iPhone 18 Pro), items 1 and 2, after ⋯ › Read Again on the kolaches. Not run in this session |
| M3-3c | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 187 tests in 25 suites passed after 0.848 seconds."; `** TEST SUCCEEDED **`. Total before: 184 (`@Test` count at session start), so 184 + 3 = 187 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 187 tests on the pinned destination. ✅ 3 `Domain/Review/LineZoom.swift:1` is `import Foundation`, its only import. `git diff --stat` of `SylantroSchemaV1.swift`, `CaptureRecorder.swift` and `RecipeEditor.swift`: empty; `git diff --cached --quiet`: exit 0. ✅ 4 a Python scan of every string literal on the lines this session added to the changed views (`RecipeView.swift`; `PagePhotoViewer.swift` added none): S-59 "Read Again" (twice) and "Keep My Edits", S-57 "Read the Pages Again?", S-73 "Reading the pages again replaces your edits to this recipe." (proposed in `13` v0.39; used as written, as the task says), and the SF Symbol `arrow.clockwise`; nothing else. ✅ 5 git status before and after below; this row. **What was built:** part 1 `Domain/Review/LineZoom.swift`: `LineZoom.maximum = 2.5`; `scale(boxWidth:viewWidth:margin:)`, the box filling the view less a margin each side, clamped to 1 to 2.5, and 1 for a box of no width or a view narrower than two margins. Part 2 `PageStrip.pageFrame` uses `LineZoom.scale` in place of `max(1, …)`; its centering on the box, clamped to the page's edges, is unchanged, so with the cap the page shows around the line. The edit sheet's crop is a `PageStrip`, so it follows. `PagePhotoViewer`'s zoom to a box uses `LineZoom.scale` (note a); the pinch range 1 to 6 is unchanged. Part 3 ⋯ gains Read Again (`arrow.clockwise`) after View Pages and before the divider, once read, disabled with no `CaptureRecorder` or while `currentRecipeID` is this recipe. A recipe not `.edited` calls `readAgain` at once. An edited one asks with a plain alert (S-57, S-73; Read Again, Keep My Edits as cancel). Read Again calls `readAgain`; a failure shows S-14 with OK, through M3-4's `readAgainAfterAsking`. M3-4's question after a page change (S-57, S-58) is unchanged. Part 4: `LineZoomTests` (new), 3 tests as the table. **Files:** new `Sylantro/Domain/Review/LineZoom.swift`, `SylantroTests/Domain/LineZoomTests.swift`; changed `Sylantro/Views/Recipe/RecipeView.swift`, `Sylantro/Views/Recipe/PagePhotoViewer.swift`; this document (this row only). `CaptureRecorder.swift` read (`readAgain`), not changed. No `SylantroSchemaV1`, synced model, `CaptureRecorder`, `RecipeEditor`, structurer, prompt, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no popover, tip bubble or confirmation dialog; no network. **Git status before** (branch `milestone-3`; M3-3b committed as `0897bd5`): ` M` `Docs/12_IMPLEMENTATION_PLAN.md`, `Docs/13_SCREENS.md`, `Docs/15_MILESTONE_3_REVIEW.md`, `Docs/README.md` (Pops's, unstaged). **After:** those four (this document with this row too), ` M` `Sylantro/Views/Recipe/PagePhotoViewer.swift` and `Sylantro/Views/Recipe/RecipeView.swift`, `??` `Sylantro/Domain/Review/LineZoom.swift` and `SylantroTests/Domain/LineZoomTests.swift`. **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -3`, `git log --oneline -2 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md`, `git diff -- Docs/13_SCREENS.md` (Pops's v0.39 changes: §4.2's Read Again, S-73, the 2.5× note), `git diff --stat -- Sylantro/Store/SylantroSchemaV1.swift Sylantro/Capture/CaptureRecorder.swift Sylantro/Store/RecipeEditor.swift`, `git diff --cached --quiet`, `git diff -U0 -- Sylantro/Views/`. **Notes, for Claude to confirm:** (a) In `PagePhotoViewer` the page is first drawn fitted to the screen, which can be narrower than the view when a page is wide. So the box's width passed to `LineZoom.scale` is taken against the view's width as drawn (`box.width × fitted width ÷ view width`): the line fills the width less the margins, and the cap is 2.5 × the page as first drawn. For a portrait page on a portrait phone, the fitted width is the view's, so it is exactly part 1's rule. (b) Read Again from ⋯ has its own alert, with S-73, beside M3-4's with S-58. Both have the title S-57. Its Keep My Edits does nothing, as part 3.2 says; M3-4's clears its pending re-read, as before. (c) Read Again shares M3-4's `readAgainAfterAsking`, which also clears M3-4's pending re-read flag when it succeeds. That is harmless, since the recipe is being read again either way. (d) The menu item is disabled while the queue reads this recipe, from `currentRecipeID`. Its waiting pages before the job starts don't disable it, and a second tap then only makes the pages wait again. **Next:** Pops's check on device (iPhone 18 Pro), items 1 to 3. Not run in this session |
| M3-3b | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 184 tests in 24 suites passed after 0.688 seconds."; `** TEST SUCCEEDED **`. Total before: 181 (`@Test` count at session start), so 181 + 3 = 184 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 184 tests on the pinned destination. A first run failed "removing a new line" on the test's own helper (note k), fixed in the test. ✅ 3 `Domain/Review/ReviewEdit.swift:1` is `import Foundation`, its only import. `git diff --stat` of `SylantroSchemaV1.swift` and `RecipeEditor.swift`: empty; `git diff --cached --quiet -- Sylantro/Store/`: exit 0. `git diff -U0` of `ReviewEdit.swift` has only two added hunks (`Field`, and `text`/`setting`/`removing`); `applied(to:now:)` is untouched. ✅ 4 a Python scan of every string literal on the lines this session added to the changed views (`RecipeView.swift`, `LibraryView.swift`) found only: S-71 "New Scans", S-70 "Edit", S-22 "Add Page", S-62 "View Pages", S-23 "Delete Recipe", S-72 "Pages", S-66 "Title", S-51 "Serves" and "Notes", S-67 "Ingredient", S-68 "Step \(…)", S-69 "Cancel" and "Save" (VoiceOver labels), the accessibility labels already named "Add Ingredient" and "Add Step", the SF Symbols `pencil`, `doc.badge.plus`, `ellipsis.circle`, `xmark` and `checkmark`, and `""` (the sheet field's empty placeholder, and a new line's empty text, which is data and never shown). ✅ 5 git status before and after below; this row. **What was built:** part 1 `ReviewEdit.Field` (`title`, `yield`, `notes`, `ingredient(UUID)`, `step(UUID)`), `text(for:)`, `setting(_:for:)` and `removing(_:)`, Foundation only. Part 2 in Edit, the title, Serves or Makes, each ingredient line, each step and the notes are plain text rows (`editRow`), in full and wrapping; an empty one shows its word in secondary. A tap shows the row's place on the page (the same `show` as outside Edit: the strip, or the iPad and Mac column) and opens the sheet. A + row adds an empty line or step and opens the sheet for it. Delete, drag, the + rows and the Pages section are unchanged. Part 3 `RowEditSheet`, private in `RecipeView.swift`: `.sheet(item:onDismiss:)`, `.presentationDetents([.medium, .large], selection:)` starting at `.medium`, the drag indicator visible. Its bar: an inline title naming the field; leading `IconButton("xmark")` labeled "Cancel"; trailing `IconButton("checkmark")` in the accent, labeled "Save", disabled while the text is unchanged. Its content: the row's place on the page via `PageStrip` (non-interactive), 120 pt tall, none without a place; then `TextField(axis: .vertical)` with `lineLimit(3...)`, focused on appear. Save puts the text in the edit (`setting`). Cancel, or a swipe (blocked by `interactiveDismissDisabled` once the text differs), leaves it as it was, and takes out a line or step the + just added (`removing`). No alert, popover or confirmation dialog. Part 4: outside Edit the toolbar is only ⋯, its menu Edit (`pencil`, once read, sets `editMode = .active`), Add Page (`doc.badge.plus`, disabled with no recorder), View Pages (when the strip isn't shown), `Divider`, Delete Recipe. In Edit it is only `EditButton()`. The Add Page and Edit toolbar buttons are gone. `LibraryView`: New Scans (S-71) first for every recipe not read yet, then Needs Review, then the unheaded rest, each only while it holds a row. The Pages section is headed S-72. Part 5: 3 tests in `ReviewEditTests`. **Files:** `Sylantro/Domain/Review/ReviewEdit.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `Sylantro/Views/Library/LibraryView.swift`, `SylantroTests/Domain/ReviewEditTests.swift`; this document (this row only). SyLib's `IconButton.swift` read (its two initializers), not changed. No `SylantroSchemaV1`, synced model, `RecipeEditor`, `ReviewEdit.applied`, structurer, prompt, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no editing outside Edit; no toolbar button but ⋯ (and Done in Edit); no popover, tip bubble or confirmation dialog; no network. **Git status before** (branch `milestone-3`): clean (M3-3a committed as `bc6a564`). **After:** ` M` on the 4 files above and this document. **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -3`, `git log --oneline -2 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md`, `git diff --stat -- Sylantro/Store/SylantroSchemaV1.swift Sylantro/Store/RecipeEditor.swift`, `git diff --cached --quiet -- Sylantro/Store/`, `git diff -U0 -- Sylantro/Domain/Review/ReviewEdit.swift`, `git diff -U0 -- Sylantro/Views/`. **Notes, for Claude to confirm:** (a) An empty ingredient row in Edit shows S-67 "Ingredient", and an empty step S-68 "Step ‹n›", in secondary color. Part 2.1 names words only for the title, Serves and Notes. (b) The sheet's page crop is the strip's own view (`PageStrip`, given an `isInteractive` flag, false here: no grabber, no drag), so its zoom, 16 pt margin and outline are the strip's. Its corners are rounded 8 pt. (c) The sheet's text field has an empty placeholder (§6 has no word for it); the bar's title names the field. The sheet's title for Serves or Makes is always S-51 "Serves", as part 3.2 says, even for a "Makes" yield. (d) One `onDismiss` handles Cancel and a swipe alike: any close but Save takes out a line or step the + just added. The opened field is kept in its own `@State`, since the sheet clears `editingField` before `onDismiss` runs. (e) A tap on a row in Edit uses the same `show` as outside Edit, so it also ends SC-16's hint. On iPhone in Edit the strip is shown, so it selects there. A row with no place shows its first page whole, as outside Edit. (f) In ⋯, Edit and Add Page have the symbols part 4.1 names; View Pages and Delete Recipe stay text only, as before. Add Page's old `.accessibilityLabel` went with its toolbar button: the menu item's `Label` text reads S-22. (g) In Edit, flags tint the title row as before. The ingredient and step rows in Edit aren't tinted (as M3-3's Edit fields weren't). (h) New Scans takes every row whose recipe has no `extraction`, including a recipe whose data can't be read. (i) An Edit row uses `.fixedSize(horizontal: false, vertical: true)` so its text wraps in full. (j) Save is disabled while the text equals what the sheet opened with, exactly; a space added counts as a change. (k) "removing a new line" first compared against a second `edit()`, which is a fresh recipe with new ids. The test now compares against one base edit. **Next:** Pops's check on device (iPhone 18 Pro, then iPad), items 1 to 7. Not run in this session |
| M3-3a | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 181 tests in 24 suites passed after 0.792 seconds."; `** TEST SUCCEEDED **`. Total before: 172 (`@Test` count at session start), so 172 + 9 = 181 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source. A first draft of one test drew three `#expect` macro warnings; that test was rewritten (note l). The one warning left is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 181 tests on the pinned destination. ✅ 3 `git diff -- Sylantro/Store/SylantroSchemaV1.swift`: empty; `--cached --quiet`: exit 0. `git diff -U0` of `RecipeStructurer.swift` and `GeneratedParts.swift` has no changed line with `promptVersion`, `instructions`, `PromptIntro`, `@Guide` or `TokenCap`; `GeneratedParts.swift` is unchanged. ✅ 4 a Python scan of every string literal on the lines this session added to the changed views (`RecipeView.swift`, `PagePhotoViewer.swift`): S-62 "View Pages", S-2 "New recipe", S-64 "Edit", S-63 "Review", S-65 "Recipe", S-61 "Tap a line to see it on the page.", the `AppStorage` key `reviewHintSeen`, and the SF Symbol `hand.tap`; nothing else (S-52l is in `ReviewFlag.line(for:)`, Domain). ✅ 5 git status before and after below; this row. **What was built:** part 1 `RecipeValidator.check(_:pageText:clutterFreeText:)`, a value found in either text; the structurer passes the lines less `PageClutter` lines; the four validator test callers pass `pageText` twice. `RecipeStructurer.locatorLines` leaves out clutter lines. `SourceLocator.find` adds a second round of runs that cross from one page's last line onto the next (two pages, `maximum` lines in all), boxed by the first page's lines, only after no one-page run matches (for steps only, note a). Part 2 `ingredientGroups`: each answered group's span; an unused line ending `:` just before a nameless group's span names it; an unused line in a span that `startsIngredient` is put back in line order, made from the line and the parser, with `put back: ingredient n` instead of its `unused` warning; `ReviewFlag.Kind.putBack` on that ingredient, resolved as `notOnPage`'s number, `line(for: .putBack)` S-52l. Part 3 `RecipeView`: SC-14 (iPhone: the strip only while `needsReview` or in Edit; otherwise the fields from the title); ⋯ View Pages (S-62) above Delete Recipe; a tapped line with the strip hidden opens `PagePhotoViewer` on its page, zoomed and outlined (no box: its first page whole); SC-16's hint (S-61, `hand.tap`, caption, secondary) until the first tap, `@AppStorage("reviewHintSeen")`; SC-17 (a list's flag is one tinted line atop it, its rows plain); SC-18 (`.navigationBarTitleDisplayMode(.inline)`, the bar S-2, S-64, S-63 or S-65); RV-31 (`Recipe.titleBox`, `decodeIfPresent`, nil when missing, `schemaVersion` unchanged; `SourceLocator` places it, equal runs of 1 to 3 lines on one page from the first line, `maximumTitleRun = 3`; `ReviewEdit.applied` keeps it, as it starts from the recipe; a tap on the title selects it; the strip starts at it). `PagePhotoViewer` pages through the recipe's pages (`TabView`, `.page`), each zoomable, with a starting page and box. Part 4: 9 tests as the table (`SourceLocatorTests` 3, `RecipeStructurerTests` 3, `RecipeValidatorTests` 1, `RecipeJSONTests` 1, `ReviewFlagTests` 1). **Files:** `Sylantro/Domain/Recipe/Recipe.swift`, `Sylantro/Domain/Structuring/RecipeValidator.swift`, `Sylantro/Domain/Structuring/SourceLocator.swift`, `Sylantro/Domain/Structuring/ReviewFlag.swift`, `Sylantro/Extraction/RecipeStructurer.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `Sylantro/Views/Recipe/PagePhotoViewer.swift`, `SylantroTests/Domain/SourceLocatorTests.swift`, `SylantroTests/Domain/RecipeValidatorTests.swift`, `SylantroTests/Domain/RecipeJSONTests.swift`, `SylantroTests/Domain/ReviewFlagTests.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`; this document (this row only). Read and not changed: `ReviewEdit.swift`, `PageClutter.swift`, `WrapJoiner.swift`, `IngredientLineParser.swift`, `StructuringRulesTests.swift`. Nothing of SC-19 to SC-21 (M3-3b) built. No `SylantroSchemaV1`, synced model, prompt, `promptVersion`, `TextReader`, `ExtractionPlanner`, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no dish photos, popover, tip bubble or confirmation dialog; no network. **Git status before** (branch `milestone-3`): `M ` (staged, M3-4's) `Docs/12_IMPLEMENTATION_PLAN.md`, `Docs/15_MILESTONE_3_REVIEW.md`, `Docs/README.md`, `Sylantro/Capture/CaptureRecorder.swift`, `Mirror/MirrorWriter.swift`, `Store/RecipeEditor.swift`, `Views/Capture/CaptureFlowView.swift`, `Views/Recipe/RecipeView.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`, `Mirror/MirrorWriterTests.swift`. During the session Pops committed those as `91dd005` and edited `Docs/13_SCREENS.md` (v0.38: S-72 "Pages", for M3-3b), this document (v0.50) and `Docs/README.md`; none bears on M3-3a. **After:** ` M` on the 12 files above, this document, `Docs/13_SCREENS.md` and `Docs/README.md` (the last two Pops's). **Git:** `git status --short` (×3), `git branch --list`, `git log --oneline -3` (×2), `git log --oneline -2 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md Docs/13_SCREENS.md`, `git diff -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff --cached --quiet -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff -U0 -- Sylantro/Extraction/RecipeStructurer.swift Sylantro/Extraction/GeneratedParts.swift`, `git diff --stat -- Sylantro/Extraction/GeneratedParts.swift`, `git diff -U0 -- Sylantro/Views/`, `git diff --stat` and `git diff` of `Docs/13_SCREENS.md`, `Docs/README.md` and this document (to see Pops's changes). **Notes, for Claude to confirm:** (a) **Cross-page runs are for steps only.** Part 1.3 names `SourceLocator.find`, which places ingredients too. Applied to every target, it failed M3-1's test "never across pages" (an ingredient split over a page break was found). RV-30 and SP-22 rule it for a step, so `find` gained `crossingPages`, true only for steps, and M3-1's test is unchanged. The title stays on one page, as part 3.7 says. (b) `RecipeStructurer.locatorLines` is now internal, not private, so "a step across pages" passes a footer through the structurer's own filter. (c) The cross-page round keeps the same start order and passes, so with "contains" the first match can start before the step's own first line, as one-page "contains" has since M3-1. The test puts the step's first line at the top of page 1. (d) Put-back: a span needs at least one item that was kept, so a group with only a name line has none. Heading names (part 2.3) are given before put-back, so the line just before a span is checked as it was. The heading's length is checked without its `:`, as `nameLine`'s is. A group named by a heading no longer joins the group before it, as any named group. A put-back ingredient has `isOptional` false and no preparation or note. The warnings come in this order: the loop's, then put back, then unused. (e) `put back: ingredient n` is the ingredient's 1-based place across every group once put-backs are placed. `ReviewFlag` resolves it with `notOnPage`'s mapping, skipping `is a step` numbers. (f) View Pages shows only on iPhone, for a read recipe, while the strip is hidden (`13` §4.2: "when the scan strip isn't shown"). It doesn't show on a recipe not read yet (whose pages are on screen) or on iPad and Mac (unchanged). (g) `PagePhotoViewer` takes the recipe's page photos, a start index and a box, so every caller pages: M2's tap on a page and the iPad column's open on the tapped page and swipe through all of them. A page with no photo record is left out. The zoom to a box stays within the existing pinch range 1 to 6, so a very narrow box can't fill the width past 6×. The scroll to it waits for the content to grow (`onScrollGeometryChange`). The outline is `LineOutline`, now internal, not private. (h) The hint shows on iPhone in Edit too (the strip shows in Edit). It is the first row of the fields, above the title, not fixed under the strip. Any tap on a line, the title included, counts as her first. (i) SC-17 is for `.ingredients` and `.steps` only; notes, equipment, nutrition and source keep M3-3's tint and line at the end. Group-name rows are no longer tinted. (j) The strip starts at the title's box (and its page) when nothing is selected. The iPad and Mac column doesn't outline the title until it is tapped (unchanged). (k) In Edit the bar reads S-64 even while the recipe needs review. A read recipe that is reviewed or edited reads S-65. (l) "A value across a page break is found" first wrote `!(x.extraction?.warnings ?? []).contains(…)` inside `#expect`. That drew macro warnings and failed although the validator was right, so the warnings are now taken first, as the file's other tests do. **Next:** Pops's check on device (iPhone 18 Pro, then iPad), items 1 to 5, with spike run 8 or 9. Not run in this session |
| M3-4 | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 172 tests in 24 suites passed after 0.791 seconds."; `** TEST SUCCEEDED **`. Total before: 163 (`@Test` count at session start), so 163 + 9 = 172 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 172 tests on the pinned destination. ✅ 3 `git diff -- Sylantro/Store/SylantroSchemaV1.swift`: empty (exit 0). ✅ 4 a Python scan of every string literal on the lines this session added to the changed views (`RecipeView.swift`; `CaptureFlowView.swift` added none): S-54 "Remove This Page?", S-55, S-56 "Remove" and "Cancel", S-57 "Read the Pages Again?", S-58, S-59 "Read Again" and "Keep My Edits", S-60 "Page \(offset + 1)", the SF Symbol `icloud.and.arrow.down`, and three log lines; nothing else. ✅ 5 git status before and after below; this row. **What was built:** part 1 `RecipeEditor`: `reorderPages(_:of:now:)`; `removePage(_:from:now:) -> Task<Void, Never>?`, deleting the page's records when no other recipe lists it and its files after the save; `reopenForReading(_:now:)`, which doesn't save; the new `pagesDontMatch(UUID)` and `lastPage(UUID)`; `saveAndMirror(recipeID:pagesChanged:)`, which both page calls pass true. `delete` now shares `recordsOnly(of:pageIDs:)` (a recipe's pages no other recipe lists, their photos, sessions left empty) and `removeFilesAfterSave(_:of:removingFolder:)` with `removePage`, rather than a copy. `change` is built on a new `changedCopies(_:_:)`, whose body may throw before anything is written. `CaptureRecorder.readAgain(recipeID:now:)`. Part 2 `MirrorSnapshot.pagesChanged` (default false; `make(for:in:pagesChanged:)`); `MirrorWriter.write` with it true removes every `page-‹n›.heic` (one coordinated delete each) and copies the pages again from `page-1.heic`; both type comments updated. Part 3 `RecipeView`: in Edit, a Pages section first in the fields `List`, one 56 pt thumbnail row per page in the draft order, VoiceOver S-60, `.onMove`, `.onDelete` asking with S-54 to S-56 (none when one page is left). Done saves the field edits, then each removed page, then the order if it differs, then RV-7; a failed step shows S-14 with OK and stays in Edit. RV-7's alert (S-57 to S-59); Read Again, or a recipe not edited, calls `readAgain`. `CaptureFlowView` gains `onPagesAdded`, called after `addPages` succeeds and before it closes. Part 4: 9 tests as the table (`CaptureRecorderTests` 7, `MirrorWriterTests` 2). **Files:** `Sylantro/Store/RecipeEditor.swift`, `Sylantro/Capture/CaptureRecorder.swift`, `Sylantro/Mirror/MirrorWriter.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `Sylantro/Views/Capture/CaptureFlowView.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`, `SylantroTests/Mirror/MirrorWriterTests.swift`; this document (this row only). `ExtractionPlanner.swift` read, not changed. Nothing of SC-14 to SC-21 (M3-3a, M3-3b) built. No `SylantroSchemaV1`, synced model, `StoreOpener`, structurer, prompt, `TextReader`, `ExtractionPlanner`, `ExtractionQueue`, spike, `Info.plist`, entitlement, build setting or SyLib change; no popover or confirmation dialog; no network. **Git status before** (branch `milestone-3`): clean (M3-3 committed as `a6618f9`). **After:** ` M` on the 7 files above and this document. **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -4`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md Docs/02_ARCHITECTURE.md`, `git diff 9f21088 HEAD -- Docs/00_DECISION_LEDGER.md` (the ledger went from v0.56 to v0.60 since this session read it; the new rows are SLT-170 to SLT-172 and nutrition and feature-idea open decisions, none bearing on M3-4), `git show --stat --oneline a6618f9`, `git diff -U0 -- Sylantro/Views/`, `git diff -- Sylantro/Store/SylantroSchemaV1.swift`. **Notes, for Claude to confirm:** (a) **The Pages section has no header.** `13` §4.6 calls it "a **Pages** section", but §6 has no string "Pages", so the section has no title. Its rows have no visible text either, as §4.6 says. (b) After Add Page, RV-7 runs when the camera has closed (the `fullScreenCover`'s `onDismiss`): `onPagesAdded` only sets a flag. Otherwise the question would be asked under the camera. (c) Done remembers each step it finished, so after a failed step the next Done repeats nothing that saved. RV-7 is one of the steps: a failed `readAgain` shows S-14, stays in Edit and is tried again at the next Done. A failed Read Again from RV-7's alert shows S-14 (not in Edit). (d) On a read recipe she hasn't edited, Add Page's own `addPages` already tells the queue (M3-2), which reads the new page and structures again. RV-7 then makes every page wait and tells it again, so the recipe may be structured twice. That is harmless, and the spec calls both. (e) `reopenForReading` changes only `reviewState` ("Nothing else changes"), not `updatedAt`. `readAgain` doesn't write the Files copy (the new reading's save does). With no copy of the recipe it throws `recipeNotFound`. (f) "A recipe with one page has no delete" is judged by the draft order, so after removing one of two pages, the one left has no delete either (`removePage` would throw `lastPage`). (g) The row thumbnail (`PageThumbnail`, private in `RecipeView.swift`) copies `RecipeRow`'s loading, from memory or made off the main actor, sharing `ImageCache`'s key with the library's rows. Its placeholder has no label of its own, since the row's S-60 covers it. (h) `MirrorWriter` removes only names `page-` + digits + `.heic`. A failed delete there leaves the recipe pending, so catch-up writes it again. (i) `RecipeView` reads `modelContext` (a fetch only) for the recipe as just saved when deciding RV-7, since its `@Query` may not have refreshed after Done's saves. (j) The test log again shows CoreData+CloudKit "Unable to initialize without an iCloud account" from the test host on a simulator with no account. Every test passed. **Next:** Pops's check on device (iPhone 18 Pro, then iPad), items 1 to 4. Not run in this session |
| M3-3 | 24 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 163 tests in 24 suites passed after 0.564 seconds."; `** TEST SUCCEEDED **`. Total before: 149 (`@Test` count at session start), so 149 + 14 = 163 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source (two of this session's own were fixed: `nonEmpty`/`webURL` made `nonisolated`, an unused test value); the one warning left is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 163 tests on the pinned destination. ✅ 3 `Domain/Review/ReviewEdit.swift:1` and `Domain/Review/Recipe+Review.swift:1` are each `import Foundation`, the only import. ✅ 4 `git diff -- Sylantro/Store/SylantroSchemaV1.swift`: empty (exit 0); `--cached --quiet`: exit 0. ✅ 5 a Python scan of every string literal in `RecipeView.swift`, `LibraryView.swift`, `RecipeRow.swift`, `CaptureFlowView.swift` and `RootView.swift` (comments skipped). The new ones are all `13` §6's: S-2, S-3, S-14, S-16, S-17, S-20 to S-26, S-27, S-28, S-44 to S-49, S-51's eight words, S-53. The rest are accessibility labels named here ("Show on page", "Add Ingredient", "Add Step"), SF Symbol names (`doc.badge.plus`, `ellipsis.circle`, `exclamationmark.triangle`, `plus.circle.fill`, `icloud.and.arrow.down`), log text, the logger category, and three that are none of these, given as notes j and k: `""` (the empty placeholders), `"\(offset + 1)."` (a step's number) and `"https://"` (a link's destination, never shown). The S-52 lines live in `ReviewFlag.line(for:)` (Domain) and the times words in `RecipeRendering.timesLine`, both S-51's and S-52's text. The literals already in `LibraryView` and `RootView` are unchanged. ✅ 6 git status before and after below; this row. **What was built:** part 1 `Domain/Review/ReviewEdit.swift` (`ReviewEdit` with `Group`, `Line`, `StepLine`; `from(_:)`; `applied(to:now:)` by the rules) and `Recipe.needsReview`; `ReviewFlag.line(for:)` with S-52a to S-52k. Part 2 `RecipeEditor.markReviewed`, `saveEdits`, `dismissPageTwoWarning`, each on every copy after checking every copy reads, then a private `saveAndMirror(recipeID:)` (save, roll back/log/rethrow on failure, then the Files copy as `CaptureRecorder` writes it); type comment updated. `CaptureRecorder.retryFailed(recipeID:)`. `ExtractionQueue.currentRecipeID`, `private(set)`, observed, set at a job's start and cleared by `defer` when it ends. Part 3 `LibraryView` takes the queue. Needs Review (S-44) first when it isn't empty, newest first, then an unheaded section. `RecipeRow`'s line is a `Detail` (S-45, S-46, S-3, or the author, else publisher, else S-3), from one `@Query` of `SourcePageModel`. Part 4 `RecipeView` (below, and notes a to j): before reading, M2's screen with S-45 or S-47 and Try Again (`CapsuleButton`) in place of S-20. Once read: the compact strip (`PageStrip`) over the fields, or a 45%/55% `HStack` with the pages scrolled to the selected line, outlined. Then the fields in order with S-51 headings; flags tinted `Color.orange.opacity(0.15)` with their S-52 line, caption, secondary, only while `needsReview`; tap a line; `EditButton()` before Add Page, with the kitchen fields as `TextField`s, `.onDelete`/`.onMove` and + rows; Done saves only a changed edit, and a failed save shows S-14 with OK and stays in Edit; Looks Good (`CapsuleButton(fillsWidth: true)`), hidden in Edit; That's All of It on S-52k. `RootView` passes the queue to both views. Part 5 `CaptureFlowView`'s alert gains That's All of It after Save Without It, saving with no warning. Part 6 `RecipeRendering.markdown` adds a read recipe's sections in order (yield, times, `## Ingredients` with `### ‹group›` and `- ` lines, `## Steps` numbered, `## Notes`, `## Equipment`, `## Nutrition`, `## Source`), with shared `yieldLine`, `timesLine` (and `duration`) and `sourceLines` that the screen uses too; an unread recipe is unchanged. Part 7: 14 tests as the table (`ReviewEditTests` 6, new; `ReviewFlagTests` 2; `RecipeRenderingTests` 2; `CaptureRecorderTests` 4). **Files:** new `Sylantro/Domain/Review/ReviewEdit.swift`, `Sylantro/Domain/Review/Recipe+Review.swift`, `SylantroTests/Domain/ReviewEditTests.swift`; changed `Sylantro/Domain/Structuring/ReviewFlag.swift`, `Sylantro/Domain/Recipe/RecipeRendering.swift`, `Sylantro/Store/RecipeEditor.swift`, `Sylantro/Capture/CaptureRecorder.swift`, `Sylantro/Extraction/ExtractionQueue.swift`, `Sylantro/Views/Library/LibraryView.swift`, `Sylantro/Views/Library/RecipeRow.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `Sylantro/Views/Capture/CaptureFlowView.swift`, `Sylantro/Views/Root/RootView.swift`, `SylantroTests/Capture/CaptureRecorderTests.swift`, `SylantroTests/Domain/RecipeRenderingTests.swift`, `SylantroTests/Domain/ReviewFlagTests.swift`; this document (this row only). Read and not changed: `PagePhotoView.swift`, `PagePhotoViewer.swift`, `MirrorWriter.swift`, `IngredientLineParser.swift`. No `SylantroSchemaV1`, synced model, `StoreOpener`, structurer, prompt, `TextReader`, `ExtractionPlanner`, spike, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no popover or confirmation dialog; no page reorder/remove, several-recipes choice or search; no network. **Git status before** (branch `milestone-3`): clean (M3-2a committed as `179d0a7`). **After:** at the session's check, ` M` on the 13 changed files and `??` on `Sylantro/Domain/Review/` and `SylantroTests/Domain/ReviewEditTests.swift`. By the final `git status`, those had been staged outside this session (`M ` and `A `; this session ran no git write), and this document shows ` M` for this row. **Git:** `git status --short` (×3), `git branch --list`, `git log --oneline -3`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (the three unchanged since this session read them), `git diff -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff --cached --quiet -- Sylantro/Store/SylantroSchemaV1.swift`. **Notes, details the task left open, for Claude to confirm:** (a) **The title has no `sourceBox`**: `Recipe` has no field for one and `SourceLocator` places only ingredients and steps. So the strip starts at the top of page 1 (part 4.1's "else"), and a tap on the title shows page 1 whole (part 4.4's "one without"). Pops's check 2 ("the strip shows the title on the page") will see the top of page 1. Placing the title needs a schema or structurer ruling. (b) Serves or Makes is one line, the yield's text as printed (`RecipeRendering.yieldLine`), with no separate heading: a printed yield already reads "Serves 4" or "Makes 24 cookies", and `recipe.md` writes the same line. (c) The fields are a `List` (`.insetGrouped`, the palette background), not a `ScrollView`, because `.onDelete` and `.onMove` work only in a `List`, which scrolls. A flagged ingredient, step or title gets a rounded amber row background (`listRowBackground`). A flagged list tints each of its rows and shows its S-52 line once, in a tinted row at its end. (d) A flagged field that isn't present (for example notes dropped as not on the page) still shows its heading and its flag line, so the flag isn't lost. (e) The whole-recipe lines: S-52k shows whenever the recipe is flagged, as M2's screen did, after review too. S-52h, S-52i and S-52j (an `other` warning, always field `recipe`) show only while `needsReview`. S-52j is among them because `ReviewFlag` says an unknown warning is shown, not hidden. (f) The strip's numbers, none given: a 16 pt margin each side of a zoomed line; zoom never below the page's width and no maximum; the outline's corner radius 4; a 40 pt drag to open or close; a 36 × 5 pt grabber; background `secondarySystemBackground`. A page shown whole is fitted at the strip's height. A tap on the strip itself does nothing (the iPad and Mac pages keep M2's tap to open full screen). (g) The grabber has no VoiceOver label, since §6 has no word for it, so VoiceOver can't open the strip. Tap a line uses the hint "Show on page", not a label, so the line's own words are still read first. (h) Edit: the yield and notes fields show even when empty. The yield's placeholder is "Serves" (S-51's word). The title, line, step and notes fields have an empty placeholder (§6 has no words for them), so they have no VoiceOver label. With no ingredients, the + adds a new unnamed group. The fields Edit doesn't change are dimmed by opacity 0.5. Flags still show in Edit. Done with no `RecipeEditor` yet counts as a failed save. (i) Before reading: S-45 takes precedence; otherwise a failed page shows S-47 and Try Again in place of S-20, not under it. (j) An empty title after reading still shows as S-2 in the row, the navigation title and the fields, as before. `navigationTitle` is unchanged, so a read recipe's title is in the bar and large in the fields. The step number is drawn from the step's position, so the structurer's index from 0 and `applied`'s from 1 (as part 1 rules, and as its test checks) look the same on screen and in `recipe.md`. (k) A printed web address without a scheme is linked with `https://` before it and shown as printed. (l) `ReviewEdit.applied`: line and step texts are trimmed before comparing. A changed ingredient keeps its `isOptional`, `isHandwritten` and `isUnreadable`; part 1 lists only what is cleared. (m) `needsReview` is in a new file, `Domain/Review/Recipe+Review.swift`; the task named the folder, not the file. `PageStrip`, `LineOutline` and `FlagLines` are private views inside `RecipeView.swift`. (n) A failed Looks Good, That's All of It or Try Again is logged only, with no alert, since the task gives no copy for one. That's All of It is a small bordered button. (o) In `recipe.md`, a section's lines (ingredients, steps, equipment, source) are one block joined by single newlines. **Next:** Pops's check on device (iPhone 18 Pro, then iPad and Mac), items 1 to 8, with item 2 as note (a) says. Not run in this session |
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
| RV-14 | Several recipes on a page (SLT-047) | **A.** When the structurer names other titles found on the page, review lists every title with a checkbox; each one she keeps is structured again with its title given and only the lines from that title to the next. **B.** She marks each recipe's area on the photo. **C.** She gets copies of the recipe and trims each by hand | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Pick titles from a list"): the titles are already found (SLT-151), and a title-to-next-title cut fits the test set's four-recipe page; checked in a spike run before M3-5's screens |
| RV-15 | Reorder and remove a page (MT-29, MT-31) | An Edit button on the recipe's pages: drag to reorder, remove with a plain alert (the page and its photo gone everywhere, SLT-157); then RV-7 | **Ruled: as written.** Pops, 24 Nov 2026 (decision card, "Edit on the pages"); in M3-3's Edit mode; the alert's words in `13` |
| RV-16 | Search and sort (`13` SC-3 said "in M3, when recipes have titles") | **A.** Search by title and ingredient text; newest first stays. **B.** A, plus sort by title. **C.** None in M3 | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Search titles and ingredients"); tags later |

### Carried items and what waits

| # | Question | Proposal |
|---|---|---|
| RV-17 | Restoring a recipe from the Files copy (`12` §4's gate, `02` §5.3) | **Ruled: not in M3.** Pops, 24 Nov 2026 (decision card, "All three out of M3"): iCloud refills a fresh store, and the Files copy is the safety net, not a second source. Parked with no milestone, as Hide or Archive is |
| RV-18 | `10`'s TS-5, TS-10, TS-11, TS-15 | **Ruled: all four as `10` §5 recommends.** Pops, 23 Nov 2026 (decision card, "All four as recommended"): page noise in no field, kept in `ocrText`, contact details never lifted (TS-5); an alternate method as a second step group with its printed heading (TS-10); titles kept as printed, no trimming (TS-11); unreadable handwriting shown as its piece of the photo, with "Couldn't read this" and a way to type it (TS-15, built in M3-6) |
| RV-19 | The spike's leftovers (`11` §1) | **Ruled: all in M3-1.** Pops, 23 Nov 2026 (decision card, "All of them in M3-1"): SP-20's two title fixes, the header area in the report, one fraction table, `GeneratedRecipe` removed, the fallback's noisy warnings dropped. The spike screen stays, behind its flag (SLT-093) |
| RV-20 | Vision's newer document reading for columns (`11` §1) | **Ruled: not in M3.** Pops, 24 Nov 2026 (decision card, "All three out of M3"); tried only if M3-5's spike check shows the column pages fail |
| RV-21 | Where the review screens are designed | **Ruled: `13` v0.18.** Pops, 24 Nov 2026 (decision card, "In 13, as version 0.18"); `13` already says M3's screens come "in a later version of this document"; drawn after RV-8 to RV-16 are ruled |
| RV-22 | The duplicate check (`01` §2, "a matching title and similar ingredients") | **Ruled: not in M3.** Pops, 24 Nov 2026 (decision card, "All three out of M3"); built with sharing (M6), which needs it for imports (SLT-103) |
| RV-23 | The device-only store's shape (found writing M3-2) | **A.** Its own small container, `"SylantroLocal"`, opened by the queue; if it won't open, the queue logs it and runs from memory for that launch (its jobs are rebuilt from the synced marks anyway). Only `ExtractionJobModel`; `DeviceStateModel` waits until something needs it. **B.** As `02` §5.1 says: a second configuration in the one container, with both models; a broken device-only store then shows the recovery screen, and Start Fresh must also set it aside | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Yes, its own store"). A broken job list never keeps her from her recipes; `02` §5.1 updated (v0.17) |
| RV-24 | A recipe that keeps failing to read or structure | **A.** Three tries, 1 and then 5 minutes apart; then its pages are marked failed and it stays "New recipe" until review offers Try Again (M3-3). **B.** Keep trying at every launch. **C.** One try | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Three tries, then wait"). Try Again comes with review (M3-3) |
| RV-25 | A title holding the author's name (found on device, 24 Nov 2026: "Lydia Faust's Texas Kolaches" came out "kolaches."). `HeaderArea.isSideLine` skips any line *containing* the author's two-word name, so the true title and the subtitle were skipped and the subtitle's wrapped tail was matched (SP-23) | **A.** A small fix task before M3-3: the author's line is a side line only when it is mostly the name ("By Lydia Faust"), with a unit test and a spike run. **B.** Fold it into M3-3. **C.** No fix; she corrects it in review | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Small fix task before M3-3") |
| RV-26 | A wrong "Continues on a page not scanned" (found on device, 24 Nov 2026: a 5-page recipe whose footers read "Page n of 5" kept it). Only the camera's page-2 question sets the flag (Save Without It); structuring keeps it (`ExtractionPlanner.merged`) | **A.** Structuring clears it when the last page's footer reads "Page n of n", and she can dismiss it in review. **B.** Footer only. **C.** Review only. **D.** As now | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Clear on Page n of n, and in review"). The footer half goes in the RV-25 fix task; the dismiss is M3-3's, drawn in `13` v0.18 |
| RV-27 | A recipe's Files folder after its title changes (found on device, 24 Nov 2026: every folder stayed `new-recipe-<id>` after reading). `02` §5.4 says a rename renames its folder; `MirrorWriter.write` reuses the folder it finds by id and never renames it | **A.** Rename it to the title, as `02` says, in the RV-25 fix task. **B.** Keep the first name and change `02` | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Yes, rename it") |
| RV-28 | Saying the missing pages don't matter (Pops, 24 Nov 2026: a printout's last page may be only ads, so its footer reads "4 of 5" and no rescan clears the warning) | **A.** At the camera and in review: "Is there another page?" gets a third button meaning "that's all of it", saving with no warning; the review dismiss (RV-26) stays for recipes already flagged. A dismissed or never-set warning stays off on a re-read (`merged` keeps only a warning that is still on). **B.** Review only. **C.** Save Without It no longer warns | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "At the camera, and in review"). In M3-3; the button's words in `13` v0.18 (a plain centered alert, SLT-088) |
| RV-29 | An ingredient line the model's answer skipped (found on device, 24 Nov 2026: the kolaches rescan lost "1 1/2 Tbsp. active dry yeast…", first under "Kolaches:"; its "unused ingredient line" warning tinted the whole list) (SP-24) | **A.** In M3-3a: a skipped line that starts like an ingredient (`WrapJoiner.startsIngredient`) and sits between a group's name or first item and its last item goes back in its place, made as any item is, flagged on that ingredient only. **B.** Flag the missing line, don't add it. **C.** No change | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Yes, in M3-3a") |
| RV-30 | A step that runs across a page break (found on device, 24 Nov 2026: kolaches step 1 "Bloom yeast" ends page 2 and continues on page 3; it was flagged "Not found on the page" and had no position) (SP-22, `10` §7) | **A.** In M3-3a: the found-on-the-page check and `SourceLocator` skip page clutter (footers, headers) where one page ends and the next begins, so the step is found; its position is the part on its first page. **B.** Later, with M3-5 | **Ruled: A.** Pops, 24 Nov 2026 (decision card, "Yes, in M3-3a") |
| RV-31 | Where the title is on the page (M3-3 note a: `Recipe` had no box for it, so a tap on the title showed page 1 whole; Pops, 24 Nov 2026: "Recipe titles need to be review like any other row in the list anyways.") | **A.** In M3-3a: `Recipe` gains `titleBox`, saved inside the recipe as ingredients' and steps' boxes are (no `SylantroSchemaV1` change), placed by `SourceLocator` at reading. A tap on the title outlines it like any row. Older recipes get it on Read Again (M3-4) or a rescan; until then page 1 whole. Pops, 24 Nov 2026 (decision card, "Yes, saved with the recipe, in M3-3a") |
| RV-32 | A page that isn't a recipe (Pops's trick scan of a floss box, 24 Nov 2026: read as a recipe titled "FDA", the box copy as ingredients and steps, one row flagged) | **A, ruled.** A rule after the model, no prompt change: a reading with no ingredient line carrying an amount or unit, or with most of its lines not found on the page, gets a whole-recipe flag S-52m "This may not be a recipe. Check it." and stays in Needs Review; in M3-5, with the other structurer work. Pops, 24 Nov 2026 (decision card, "A simple rule, in M3-5"). *Not chosen:* ask the model (a prompt change and a spike run); not in M3 |
| RV-33 | Reading a recipe again on demand, and how far a line is zoomed (found on device after M3-3b: the kolaches kept its pre-M3-3a reading, since fixes apply only when a recipe is read; "2 large eggs" filled the strip, blurry) | **Ruled: both, as Task M3-3c.** ⋯ gains Read Again (asks first with S-57, S-73, S-59 when she has edited the recipe); a line is zoomed at most 2.5× the page at the view's width, centered with the page around it. Pops, 24 Nov 2026, after a screen recording of M3-3b (decision card, "Both, as task M3-3c") |
| RV-34 | Every line placed on the page (Pops, after M3-3b on device: "all the lines should zoom, even the ones in the header like yield, and active time") | **Ruled, in M3-3d** (M3-3c had already run). Yield, times, notes, nutrition, each equipment item, each source line and each group name get a place on the page, found at reading by one rule (split at `;` and line breaks, union of the parts on one page), saved inside the recipe (no `SylantroSchemaV1` change); a tap zooms to it like any line. Pops, 24 Nov 2026: "I think all the lines should zoom, even the ones in the header like yield, and active time" |
| RV-35 | How a multi-recipe page's titles are found (run 7: the header answer's `otherTitles` named none of TP-24's four, so RV-14's list would be empty) | **Ruled: try both in the spike, keep the better.** Big-type lines (printed noticeably larger than the body, not section words) and one extra model call listing the titles, side by side on all 22 pages in run 8 (Task M3-5s); M3-5 is written for whichever finds TP-24's four with no false splits. Pops, 24 Nov 2026 (decision card, "Try both in the spike, keep the better") **Run 8 (`10` §7): the model's list found TP-24's four with one false split (a wrapped title as its two lines), big type one of four with ten false splits. Kept: the model's list, titles on adjacent lines joined into one, a refusal meaning one recipe;** TP-18's title lost to a label line is fixed in M3-5 too. Pops, 25 Nov 2026 (decision card, "Model list, join adjacent lines") |
| RV-36 | The photos of a recipe she splits off a page (M3-5): a page belongs to a recipe through its photo record, and Delete Recipe removes the recipe's photo files (SLT-157) | **A.** Each new recipe gets its own copy of the page: new page and photo records, the photo file copied, the reading copied; every recipe stands alone and Delete Recipe works as now; a few MB more per recipe. **B.** The new recipes point at the same photo file; Delete Recipe removes a file only when no other recipe uses it, a change to `RecipeEditor`'s delete and the mirror *(rec. A: nothing that exists changes, and deleting one recipe can never take another's photo)* **Ruled: A.** Pops, 25 Nov 2026 (decision card, "Each gets its own copy") |

When Pops rules, the rulings are filed in the ledger at this document's close-out, as `14`'s were.

---

## 4. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.62 | Task M3-3e written: lines before a group's first ingredient put back, the iPhone strip shows the tapped line's page; + 2 tests | Pops, 25 Nov 2026, screen recording after Read Again on the kolaches; iPad check: "ipad seems to scroll the images fine" |
| 0.61 | Task M3-5 written in full: the model's title list behind her, adjacent titles joined, Choose Recipes (SC-22, S-74 to S-77 proposed), split-off recipes with their own page copies, It's All One Recipe, the not-a-recipe flag (RV-32), label lines out of titles (TP-18); 214 tests | RV-14, RV-32, RV-35, RV-36; `13` v0.40 |
| 0.60 | RV-36 ruled: A, each split-off recipe gets its own copy of the page | Pops, 25 Nov 2026 (decision card, "Each gets its own copy") |
| 0.59 | Run 8 scored (`10` v0.27 §7); RV-35's outcome: the model's title list, adjacent titles joined; RV-36 proposed: the photos of a recipe split off a page | Pops, 24 Nov 2026: "ok run 8 done"; 25 Nov 2026 (decision card, "Model list, join adjacent lines") |
| 0.58 | M3-5s checked by Claude: complete, 197 tests, every Done-when clause met; notes a to g accepted | M3-5s Results row; Pops, 24 Nov 2026: "M3-5s done" |
| 0.57 | RV-35 added and ruled; Task M3-5s written in full: finding the titles two ways in spike run 8 (197 tests) | Run 7's TP-24 had no `otherTitles`; Pops, 24 Nov 2026 (decision card, "Try both in the spike, keep the better") |
| 0.56 | M3-3d checked by Claude: complete, 191 tests, every Done-when clause met; notes a to g accepted | M3-3d Results row; Pops, 24 Nov 2026: "M3-3d. done" |
| 0.55 | M3-3c checked by Claude: complete as first written (187 tests; notes a to d accepted; S-73 used as written). RV-34's part moved out to a new Task M3-3d (191 tests), since M3-3c had run before it was added | M3-3c Results row; Pops, 24 Nov 2026: "3c already ran is done" |
| 0.54 | RV-34 ruled: every line placed on the page, in M3-3c part 4 (tests now part 5; 191 tests) | Pops, 24 Nov 2026: "I think all the lines should zoom, even the ones in the header like yield, and active time" |
| 0.53 | RV-33 ruled; Task M3-3c written in full: Read Again in ⋯, a 2.5× zoom limit (187 tests) | Pops, 24 Nov 2026, after a screen recording of M3-3b (decision card, "Both, as task M3-3c") |
| 0.52 | M3-3b checked by Claude: complete, 184 tests, every Done-when clause met; notes a to k accepted | M3-3b Results row; Pops, 24 Nov 2026: "Task M3-3b done" |
| 0.51 | M3-3a checked by Claude: complete, 181 tests, every Done-when clause met; notes a to l accepted | M3-3a Results row; Pops, 24 Nov 2026: "m3-3a done" |
| 0.50 | M3-3b part 4 item 6: the Pages section's heading (S-72). Tests unchanged (184) | M3-4 note a; Pops, 24 Nov 2026: "sure add the heading in 3b" |
| 0.49 | M3-4 checked by Claude: complete, 172 tests, every Done-when clause met; notes a to j accepted | M3-4 Results row; Pops, 24 Nov 2026: "Task M3-4 done" |
| 0.48 | RV-32 ruled: A, a rule after the model, in M3-5 (S-52m proposed in `13`) | Pops, 24 Nov 2026 (decision card, "A simple rule, in M3-5") |
| 0.47 | RV-32 proposed: a page that isn't a recipe | Pops's trick scan, 24 Nov 2026 |
| 0.46 | M3-3a and M3-3b status: all their wording approved (S-63 to S-71) | `13` v0.36; Pops, 24 Nov 2026: "Yes" |
| 0.45 | M3-3b part 4 item 5: New Scans, a first library section for recipes not read yet (SC-21, S-71). Tests unchanged (184) | Pops, 24 Nov 2026: "Seems like new scans should be in their own section at the top of the list." Then decision card, "Own section on top: New Scans" |
| 0.44 | M3-3b part 4 (tests now part 5): Add Page and Edit move into ⋯; in Edit the toolbar is Done only (SC-20, S-70). Tests unchanged (184) | Pops, 24 Nov 2026: "I think the add page toolbar button can be in the menu. Not needed much after initial scan. Same for edit button. Less clutter." |
| 0.43 | Task M3-3b written in full: editing a row in a sheet (SC-19; 184 tests), after M3-3a | Pops, 24 Nov 2026: "Editing is useless as is… Tap a row, see a new sheet for editing it. Save cancel. Boom. Maybe starting with medium sheet that can be large would work." Then decision card, "Edit mode: tap opens the sheet" |
| 0.42 | RV-31 added and ruled: the title's place on the page, saved with the recipe, in M3-3a (part 3 item 7, two tests: 181) | Pops, 24 Nov 2026 (decision card, "Yes, saved with the recipe, in M3-3a") |
| 0.41 | M3-3a part 3 item 6: the recipe screen's bar is a small view title (SC-18, S-63 to S-65); Done when 4 and check 3a to match | `13` v0.31; Pops, 24 Nov 2026, after a screen recording of the title sliding over the scan |
| 0.40 | M3-4 and M3-3a status: their wording (S-52l, S-60 to S-62) is approved, nothing waits on Pops | `13` v0.30; Pops, 24 Nov 2026: "Yes" |
| 0.39 | Task M3-3a written in full (SC-14 to SC-17, RV-29, RV-30; 179 tests), after M3-4 | Pops, 24 Nov 2026, after using M3-3 on device |
| 0.38 | RV-30 added and ruled: SP-22 (a step across a page break) in M3-3a | Pops, 24 Nov 2026 (decision card, "Yes, in M3-3a") |
| 0.37 | RV-29 added and ruled: skipped ingredient lines put back, flagged on their own row (SP-24), in M3-3a | Pops, 24 Nov 2026 (decision card, "Yes, in M3-3a") |
| 0.36 | RV-17, RV-20 and RV-22 ruled: not in M3 (restore from Files parked; column reading only if M3-5's spike needs it; duplicate check with sharing, M6). Every RV is ruled | Pops, 24 Nov 2026 (decision card, "All three out of M3") |
| 0.35 | RV-16 ruled: search by title and ingredient text, newest first stays | Pops, 24 Nov 2026 (decision card, "Search titles and ingredients") |
| 0.34 | RV-14 ruled: several recipes on a page are picked from a list of the titles found, each cut from its title to the next and read again; a spike check first | Pops, 24 Nov 2026 (decision card, "Pick titles from a list") |
| 0.33 | Task M3-4 written in full: reorder and remove pages in Edit, read again after (RV-7), the Files copy rewritten in the new order; 172 tests | `13` v0.25 §4.6; Pops, 24 Nov 2026 |
| 0.32 | RV-15 ruled: pages reordered and removed in Edit, removal after a plain alert, then RV-7 | Pops, 24 Nov 2026 (decision card, "Edit on the pages") |
| 0.31 | M3-3 complete (163 tests), checked against its Done when; notes (a) to (o) accepted, (a) and (g) left for later rulings | Pops, 24 Nov 2026: "Task M3-3 done" |
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
