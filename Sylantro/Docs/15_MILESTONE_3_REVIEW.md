# Sylantro — Milestone 3: Extraction and Review

**A Syzygy Softwerks task document · every saved page read and structured behind her, and a review
where she checks each recipe against its photo**
Version 0.98 · 27 November 2026 · **Draft: the task plan (RV-1), flags (RV-10), the test set's four
proposals (RV-18) the spike leftovers (RV-19) the device-only store (RV-2) which device reads (RV-3) how a reading is kept (RV-4) no background work (RV-5) reading M2's recipes (RV-6) and her edits on a page change (RV-7) where review lives (RV-8) the review layout (RV-9) tap-to-highlight (RV-11) what she edits (RV-12) Looks Good (RV-13) and where the screens are drawn (RV-21) are ruled; the rest of RV-2 to RV-22 is open.
**M3-1 complete** (123 tests; run 7 scored). **M3-2 complete** (142 tests). **M3-2a complete** (149 tests); **M3-3 complete** (163 tests); **M3-4 complete** (172 tests); **M3-3a complete** (181 tests); **M3-3b complete** (184 tests); **M3-3c complete** (187 tests); **M3-3d complete** (191 tests); **M3-5s complete** (197 tests); run 8 scored (`10` §7), the model's title list kept (RV-35); RV-36 ruled (own copy); **M3-3e complete** (199 tests); **M3-3f complete** (202 tests); **M3-3g complete** (209 tests); **M3-3h complete** (206 tests); **M3-3i complete** (209 tests); the kolaches device check after M3-3e to M3-3i passed on iPhone (iPad open); run 9 scored (same as run 8); RV-39 ruled: steps, then titles, then units; **M3-3j complete** (216 tests); run 10 scored (steps keep the page's words; splitting faults left, `10` §7); **M3-3k complete** (223 tests; spike run 11 next); **M3-3l complete** (spike test: does the model answer in the background under a task she starts; 224 tests; RV-5 and SLT-144 unchanged until Pops's run reports); run 11 scored (`10` §7: step counts match the key on 13 pages); **M3-3m complete** (232 tests; spike run 12 next); the background test crashed on device → **M3-3n complete** (232 tests: the handler is registered under the concrete identifier, the wildcard stays in `Info.plist`; no submit without a handler); the background run reached the model once, then hit the rate limit → **M3-3o complete** (waits out the limit in the background, BG Run All on the screen; 234 tests); its background run structured 2 captures in the background, then iOS expired the task as stalled → **M3-3p complete** (progress at each step, no title comparison in the background, an expiry ends the task but not the run; 236 tests); run 12 scored, run in the background (all 23 captures structured with the app in the background, `10` §7) → **M3-3q complete** (each ingredient's name from its own line, no flag on lines put back under a printed heading; 239 tests; run 13 scored: every name from its own line, the five-page recipe with no warning); SLT-161 → **M3-3r complete** (SyLib's components where Sylantro rolled its own, `CapsuleButton` gains `.small`; 239 tests); **M3-3s complete** (the title rules: SP-21's area, label, navigation and breadcrumb lines out of titles, a title line labelled a step; 243 tests); run 14 scored (three titles fixed, four cards' titles take in ingredient lines) → **M3-3t complete** (titles stop at the ingredients; 246 tests; spike run 15 next); RV-40 ruled (her reading in the background, after the title rules); **M3-5 written, on hold** until single-recipe reading works better (Pops, 25 Nov 2026), waiting on `13`'s SC-22 and S-74 to S-77; RV-37 ruled (M3-5a, marking a missed line, after M3-5); Pops's device checks to run.** The questions in §3 are
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
| M3-3e ✓ | **Two fixes found reading the kolaches again:** ingredient lines before a group's first one put back (RV-29), and the iPhone strip moving to a tapped line's page (RV-11) | M3-3d |
| M3-3f ✓ | **Read Again always asks, and a reading progress bar** (`13` SC-23) | M3-3e; SC-23 |
| M3-3g ✓ | **Page photos that go blank:** one shared loader at display size, a photo on the device always shown, a failing decode logged and retried smaller | M3-3f |
| M3-3h ✓ | **Ingredient groups from the printed headings** (RV-38): headings ending `:` group the ingredients under them, skipped lines put back | M3-3g; RV-38 |
| M3-3i ✓ | **The progress bar on a recipe read again** (SC-23, M3-3f note b), moved out of M3-5 | M3-3f |
| M3-3j ✓ | **Steps in the page's own words** (RV-39): the steps part returns line numbers; skipped lines put back; `promptVersion` 4; spike run 10 | M3-3i; RV-39 |
| M3-3k ✓ | **Steps split where the page splits them** (run 10): mid-step lines the labels gave elsewhere, joins across a sentence, step markers, put back only between steps, headings with no colon, fragments; rules only; spike run 11 | M3-3j; run 10 |
| M3-3l ✓ | **Does reading go on in the background?** (spike test, Pops 25 Nov 2026): Run All in Background (Test) under a `BGContinuedProcessingTask`; each structuring attempt recorded with the scene's state; the queue unchanged | M3-3k's run 11 |
| M3-3m ✓ | **Steps under printed labels and headings** (run 11): label and heading lines taken out of a range, a step after one put back, colonless headings on numbered pages, where the method ends, runs of mislabelled step lines, misread web addresses as clutter; the model's raw answers in the spike report; the five-page recipe loads as one capture; spike run 12 | M3-3l; run 11 |
| M3-3n ✓ | **The background test crashed on device**: no submit without a registered handler; the installed app's `Info.plist` checked and fixed | M3-3m |
| M3-5s ✓ | **Finding each recipe's title on a page (spike):** big-type lines and a model call, side by side in run 8 (RV-35) | M3-3d; RV-35 |
| M3-5 | **Several recipes on a page** (SLT-047; written, 222 tests): she picks which to save; each is structured on its own and shares the photo (RV-14); a page that isn't a recipe is flagged (RV-32) | M3-3; RV-14, RV-32; a spike check on the test set's four-recipe page (`10` H-38) |
| M3-5a | **Marking a missed line** (`16` FI-11): in Edit, tap a line on the page and mark what it is; a corrections file in TestFlight builds (RV-37) | M3-5; RV-37; `13` with its screen and words |
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

**Status: complete, 25 Nov 2026 (199 tests; §2).** Notes a to e accepted. Nothing new to rule: both fixes make M3-3a's RV-29 and RV-11
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

### Task M3-3f · Sylantro · Read Again always asks, and a reading progress bar

**Status: complete, 25 Nov 2026 (202 tests; §2).** Notes a and c to g accepted; (b), no bar on a recipe read again, is fixed in M3-5 Part 4 item 7. SC-23 ruled; S-78 proposed (the agent uses it as written
and notes it).

**Inputs:** `00`, `00A`, `00B`, `13` v0.41 (§2's row table, §4.2, §4.4, §6, SC-23), this
document (RV-33, Tasks M3-2, M3-3c), and these files: `Views/Recipe/RecipeView.swift`
(`readAgainFromMenu`, `readAgainOrAsk`, the "Reading…" line), `Views/Library/RecipeRow.swift`,
`Views/Library/LibraryView.swift`, `Extraction/ExtractionQueue.swift` (`runJob`,
`currentRecipeID`), `Extraction/RecipeStructurer.swift` (`structure`, `call`).

*Why:* Pops, 25 Nov 2026: "the re-read menu item should confirm before starting, also, can we have
a progress bar on the reading?" The model reports nothing within a call, so the bar moves by the
steps the queue knows: each page read, then each part structured.

#### Part 1 · `ReadingProgress` (Domain, `Domain/Extraction/ReadingProgress.swift`, Foundation only)

1. A value type: `init(pagesToRead: Int)`; `static let parts = ["header", "ingredients", "steps"]`;
   `mutating func pageRead()`; `mutating func partDone(_ part: String)` (a part not in `parts`,
   such as `lineLabels` or a fallback, changes nothing; a part counts once).
2. `fraction: Double`: (pages read + parts done) ÷ (`pagesToRead` + 3), from 0 to 1. Pages
   already read (Read Again keeps readings, RV-4) aren't counted in `pagesToRead`.

#### Part 2 · The queue and the structurer

1. `RecipeStructurer.structure(_:pageIDs:onPartDone:)` gains an optional
   `onPartDone: (@Sendable (String) -> Void)? = nil`, called with the part's name after each part's
   call returns (whatever it gave). Every existing caller is unchanged. The prompts,
   `instructions`, the `@Guide`s and `promptVersion` are unchanged.
2. `ExtractionQueue` gains an observable `progress: Double?`: set to 0 when a job starts for
   `currentRecipeID` (with `pagesToRead` = its pages with no reading), moved on each page read and
   each part done, and nil when the job ends however it ends. A job that waits (photo not here,
   refused) sets it nil too.

#### Part 3 · The bar (`RecipeView`, `RecipeRow`, every device)

1. Under "Reading…" (S-45) on the recipe screen: a `ProgressView(value:)` in the palette's accent,
   the line's width, while `currentRecipeID` is this recipe and `progress` isn't nil.
2. In the library, the row being read: the same bar, thin (the default linear style), under its
   "Reading…" line. `LibraryView` passes the queue's `progress` to that row only.
3. The bar animates between steps (`.animation(.easeInOut, value:)`). No new words; VoiceOver
   reads the bar's value as the system does.

#### Part 4 · Read Again always asks (`RecipeView`, SC-23)

1. ⋯ › Read Again always shows a plain alert first. Not edited: title S-57 "Read the Pages
   Again?", message **S-78**, buttons S-59 Read Again and **Cancel** (`.cancel`). Edited: as M3-3c
   (S-57, S-73, Read Again and Keep My Edits). Read Again calls `readAgain`; the other does
   nothing. A failure shows S-14 with OK, as now.
2. M3-4's question after a page change (S-57, S-58) is unchanged.

#### Part 5 · Tests

| File | Test | Checks |
|---|---|---|
| `ReadingProgressTests` (new) | pages then parts | 2 pages to read: 0, then 0.2 after one page, 0.4 after both, 1.0 after header, ingredients and steps |
| | other parts don't count | `lineLabels` and `ingredients fallback` leave it unchanged; a part done twice counts once |
| | nothing to read | 0 pages to read: three parts take it from 0 to 1, in thirds |

**The suite total:** the total before plus these 3.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with the total before plus 3, said, with the
   destination string and the run's own total.
3. `ReadingProgress.swift` imports only Foundation; `git diff` of `RecipeStructurer.swift` adds
   only the `onPartDone` parameter and its calls (no prompt, `instructions`, `@Guide` or
   `promptVersion` change); `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty;
   `CaptureRecorder` and `RecipeEditor` are unchanged.
4. A scan of every string literal in the changed views finds only `13` §6's words (S-78 new), SF
   Symbol names and log text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro)

1. ⋯ › Read Again on a recipe not edited: "Read the Pages Again?" with "This replaces the current
   reading of this recipe.", Read Again and Cancel. Cancel does nothing.
2. Read Again: under "Reading…" a bar fills in steps and ends full; back in the library, the row
   in New Scans shows a thin bar while it reads.
3. A new multi-page scan: the bar moves page by page, then by parts.

#### Do not

Change the prompts or `promptVersion`, `SylantroSchemaV1` or any synced model, `CaptureRecorder`,
`RecipeEditor`, `MirrorWriter`, `Info.plist`, the entitlements, build settings or SyLib. No
popover, tip bubble or confirmation dialog (SLT-088). No string she reads beyond `13` §6. No
network. Edit no document except §2 of this one.

---

### Task M3-3g · Sylantro · Page photos that go blank

**Status: complete, 25 Nov 2026 (209 tests; §2), after M3-3h.** Notes a to h accepted. Nothing new to rule: page photos show as `13` §4.4 already
says.

**Inputs:** `00`, `00A`, `00B`, `05` (photos, HEIC at full size), `14A` (SyLib `ImageCache`'s
memory-only store), this document (Tasks M3-3e, M3-3f), and these files:
`Views/Recipe/PagePhotoView.swift` (`loadImage`), `Views/Recipe/RecipeView.swift` (`PageStrip`,
its `load()`), `Views/Recipe/PagePhotoViewer.swift`, `Capture/PhotoFiles.swift` (`availability`,
`fullImage`, `thumbnail`), `Domain/Capture/PhotoEncoding.swift`,
`SylantroTests/Capture/PhotoFilesTests.swift`.

*Why:* on device after M3-3e and M3-3f (Pops, 25 Nov 2026, two screenshots: "sometimes the
images shows blank, it was showing before, only relaunch seems to fix it"), the strip shows the
outline over gray, once with the download icon, which `PageStrip` draws whenever it has no image,
downloaded or not. Two likely causes, both in the code as it is:

1. **Memory.** Every page view (`PageStrip`, the edit sheet's crop, iPad's pages column, View
   Pages, the viewer) loads the page at full size (`UIImage(contentsOfFile:)` then
   `preparingForDisplay()`, about 50 MB decoded for a 12-megapixel photo), nothing is shared, and
   the decode is detached, so it isn't cancelled. Since M3-3e every tap on another page makes a new
   strip and a new full decode, while earlier ones may still be running. When memory runs short a
   decode gives nil; `load()` retries every 2 seconds and keeps getting nil, and only a relaunch
   frees the memory.
2. **iCloud's "downloaded" state.** `availability` treats a file whose status isn't `.current` as
   still downloading, so a photo that is on the device but whose status reads `.downloaded` is never
   loaded. Page photos are never changed once written (`05`), so a local copy is the photo.

#### Part 1 · One loader, at display size, shared (`PhotoFiles`, `PagePhotoView`)

1. `PhotoEncoding.displayLongEdge = 2_560`.
2. `PhotoFiles.displayImage(of fileName: String, maxPixelSize: Int) -> CGImage?`: as `fullImage`,
   with `kCGImageSourceThumbnailMaxPixelSize` the smaller of `maxPixelSize` and the photo's long
   edge (upright, never larger than the file).
3. `PagePhotoView.loadImage(_:from:maxPixelSize:)`, `maxPixelSize` defaulting to
   `displayLongEdge`, nil meaning full size: first SyLib `ImageCache.shared.memoryImage(for:)`, keyed
   by the file's URL with the size added (for example `…/name.heic#2560`); else decodes with
   `displayImage` (or `fullImage` for nil), stores it with `toDisk: false` (`14A`), and returns it.
   Memory-only, so the system can drop it under pressure and the next load decodes again.
4. Every page view uses it: `PageStrip` and the edit sheet's crop, iPad's pages column, View Pages
   at display size; `PagePhotoViewer` at full size (her pinch goes to 6×).

#### Part 2 · A page photo that is here is shown (`PhotoFiles.availability`)

1. A static rule, `PhotoFiles.isOnDevice(isUbiquitous: Bool?, status:
   URLUbiquitousItemDownloadingStatus?) -> Bool`: true when not ubiquitous, or when the status is
   `.current` or `.downloaded`; false for `.notDownloaded` or no status.
2. `availability` uses it: a file on the device is `.available`; only one not on the device is
   asked for and reads `.downloading`. A placeholder (`.<name>.icloud`) is unchanged.

#### Part 3 · A load that keeps failing says why (`PageStrip`, `PagePhotoView`, `PagePhotoViewer`)

1. When a load returns nil for a file that `availability` calls `.available`, one log line (file
   name only, no recipe text) says the decode failed, and the next try asks for half the size
   (down to `thumbnailLongEdge`), so a page is shown smaller rather than not at all.
2. While a file reads `.downloading`, retries stay every 2 seconds, as now.

#### Part 4 · Tests

| File | Test | Checks |
|---|---|---|
| `PhotoFilesTests` | display size | a 4000 × 3000 test image written then read with `displayImage(maxPixelSize: 2560)` is 2560 × 1920; with 8000 it is 4000 × 3000 |
| | on the device | `isOnDevice`: not ubiquitous true; `.current` and `.downloaded` true; `.notDownloaded` and nil false |
| | full size unchanged | `fullImage` of the same file is 4000 × 3000 |

**The suite total:** the total before plus these 3 (209 after M3-3h's 206).

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with the total before plus 3, said, with the
   destination string and the run's own total.
3. No view decodes a page photo except through `PagePhotoView.loadImage` (a search for
   `contentsOfFile` and `fullImage(` in `Views/` finds only it); `git diff --
   Sylantro/Store/SylantroSchemaV1.swift` is empty; no change in SyLib.
4. No string she reads changes; the new log line holds only a file name.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad)

1. Kolaches in review: tap lines on every page, back and forth, quickly, for a minute. The page
   always shows; a line zoomed to 2.5× stays readable.
2. Edit, open a few rows' sheets: each crop shows its page.
3. iPad: the pages column shows every page; open the viewer and pinch in: sharp at full size.
4. If a page still goes blank, the console has a "decode failed" line naming its file: send it.

#### Do not

Change the prompts or `promptVersion`, `SylantroSchemaV1` or any synced model, how photos are
written or their files (`05`), `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`,
`MirrorWriter`, `Info.plist`, the entitlements, build settings or SyLib. No string she reads. No
network. Edit no document except §2 of this one.

---

### Task M3-3h · Sylantro · Ingredient groups from the printed headings

**Status: complete, 25 Nov 2026 (206 tests; §2), run before M3-3g.** Notes a to e accepted. RV-38 ruled.

**Inputs:** `00`, `00A`, `00B`, this document (RV-29, RV-38, Tasks M3-3a, M3-3e), and these
files: `Extraction/RecipeStructurer.swift` (`ingredientGroups(from:lines:)`, its put-back),
`Domain/Structuring/WrapJoiner.swift` (`startsIngredient`), `Domain/Structuring/PageSplitter.swift`
(`heading`), `Domain/Recipe/IngredientGroup.swift`,
`SylantroTests/Extraction/RecipeStructurerTests.swift`.

*Why:* RV-38 (Pops, 25 Nov 2026: "the ingredients are grouped in the Kolache and Filling. we
should try to detect ingredient groups and store them that way"). Groups are stored already
(`IngredientGroup.name`, `nameBox`), but they come only from the model's answer. On the kolaches
the model skipped the whole "Plum/Apricot Filling:" group, heading and lines, and RV-29's put-back
only looks next to a group the model kept, so the filling never came back.

#### Part 1 · Heading lines (Domain, `Domain/Structuring/IngredientHeadings.swift`, Foundation only)

`IngredientHeadings.lines(_ lines: [String]) -> [Int]`: the numbers (from 1) of the lines in an
ingredient section that are group headings: trimmed, ending with `:`, 2 to 60 characters before
the `:`, at least half of them letters, not starting like an ingredient
(`WrapJoiner.startsIngredient`), and not a section heading (`PageSplitter.heading` is nil).

#### Part 2 · Groups by heading (`RecipeStructurer.ingredientGroups`)

When the section has one or more heading lines, after the model's items are mapped and RV-29's
put-back has run (as now):

1. **Put back under a heading:** every line still unused that starts like an ingredient and comes
   after the first heading line is put back as RV-29's are (parsed, `put back: ingredient n`).
2. **Regroup by line:** every ingredient, with its first line, goes to the last heading line before
   it. Ingredients before the first heading form a first group with no name. A heading with no
   ingredient under it makes no group. Each group's name is its heading's text without the `:`;
   the model's group names aren't used. Groups and ingredients keep line order.
3. Heading lines count as used, so they raise no `unused ingredient line` warning.

With no heading line, the groups are the model's, as now. The prompts, `instructions`, the
`@Guide`s and `promptVersion` are unchanged. `SourceLocator` places each group's name as now
(`nameBox`).

#### Part 3 · Tests

| File | Test | Checks |
|---|---|---|
| `RecipeStructurerTests` | headings regroup | lines "Dough:", "2 cups flour", "1 tsp salt", "Filling:", "1 cup jam", "1 tbsp sugar"; the model gives one unnamed group of the four ingredients: two groups, "Dough" and "Filling", two each, no warnings |
| | a skipped group comes back | the same lines; the model gives only the dough's two: "Filling" holds "1 cup jam" and "1 tbsp sugar", each with `put back: ingredient n` |
| | no headings, no change | lines with no heading: the groups are the model's, names and order unchanged |
| `IngredientHeadingsTests` (new) | what a heading is | "For the sauce:" and "Plum/Apricot Filling:" are; "Ingredients:", "1 cup flour:", "Note" and a 70-character line ending `:` aren't |

**The suite total:** the total before plus these 4 (209 after M3-3g's 205).

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with the total before plus 4, said, with the
   destination string and the run's own total.
3. `IngredientHeadings.swift` imports only Foundation; `git diff` of `RecipeStructurer.swift`
   changes only `ingredientGroups(from:lines:)` and its helpers (no prompt, `instructions`,
   `@Guide` or `promptVersion` change); `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is
   empty.
4. No string she reads changes. No page content in the repo: tests use made-up lines.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro)

1. Kolaches: ⋯ › Read Again. Ingredients show "Kolaches" and "Plum/Apricot Filling" as
   subheadings; the apricots, the sugar and any filling lines on page 2 are under the filling,
   flagged "Put back from the page. Check it." where the model had skipped them.
2. Tap "Plum/Apricot Filling": the strip outlines it on the page.
3. A one-group recipe with no subheadings looks as before.

#### Do not

Change the prompts or `promptVersion`, `SylantroSchemaV1` or any synced model, `CaptureRecorder`,
`RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, the views, `Info.plist`, the entitlements,
build settings or SyLib. No string she reads. No page content in the repo (SLT-092). No network.
Edit no document except §2 of this one.

---

### Task M3-3i · Sylantro · The progress bar on a recipe read again

**Status: complete, 25 Nov 2026 (209 tests; §2).** Notes a to c accepted. SC-23 ruled; `13` v0.42 §4.4 says how it looks.
Moved out of M3-5 (on hold), where it was Part 4 item 7.

**Inputs:** `00`, `00A`, `00B`, `13` v0.42 (§4.4 "A recipe still being read", SC-23, S-45), this
document (Task M3-3f and its note b), and these files: `Views/Recipe/RecipeView.swift` (the
whole-recipe lines under the title, M3-3f's bar), `Extraction/ExtractionQueue.swift`
(`currentRecipeID`, `progress`, read only).

*Why:* M3-3f's note b: the bar shows only under the "Reading…" line of a recipe not read yet; a
recipe she reads again from ⋯ is already read, so its review screen has no such line and shows no
progress. Pops, 25 Nov 2026: "We should have a reading progress bar show in the recipe details too
since we kick off a re read from its menu."

#### Part 1 · Reading again shows its progress (`RecipeView`, every device)

1. While the queue is reading this recipe (`currentRecipeID` is its ID) and it was read before
   (it has an `extraction`), a whole-recipe line sits first under the title: S-45 "Reading…" with
   M3-3f's bar under it (`progress`), styled as the other whole-recipe lines but not tinted. It
   goes when the job ends, and the fields then show the new reading.
2. Not in Edit. Read Again is already disabled while the recipe is being read (M3-3c).
3. Nothing else changes: a recipe not read yet shows M3-3f's line and bar as now.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with the same total as before (no test added),
   said, with the destination string and the run's own total.
3. Only `RecipeView.swift` changes; `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. A scan of the string literals added finds only S-45 "Reading…" and log text.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's check on device (iPhone 18 Pro, then iPad)

1. Open a read recipe, ⋯ › Read Again › Read Again: "Reading…" and a bar appear under the title
   and fill in steps; when it ends they go and the recipe shows its new reading.
2. While it reads, ⋯ › Read Again is greyed.

#### Do not

Change the queue, the structurer, the prompts or `promptVersion`, `SylantroSchemaV1` or any synced
model, `CaptureRecorder`, `RecipeEditor`, `MirrorWriter`, `Info.plist`, the entitlements, build
settings or SyLib. No string she reads beyond `13` §6. No popover, tip bubble or confirmation
dialog (SLT-088). No network. Edit no document except §2 of this one.

---

### Task M3-3j · Sylantro · Steps in the page's own words

**Status: complete (216 tests); run 10 scored (`10` §7).** RV-39 ruled. A prompt change: `promptVersion`
goes from 3 to 4, and spike run 10 checks it (`10` §7).

**Inputs:** `00`, `00A`, `00B`, `10` §7 (run 9), `11` (the structurer's parts, SLT-146), this
document (RV-29, RV-38, RV-39, Tasks M3-3e, M3-3h), and these files:
`Extraction/RecipeStructurer.swift` (the steps part, its fallback, `ingredientGroups(from:lines:)`
as the model to follow, `assemble`, `makeSteps`), `Extraction/GeneratedParts.swift`
(`GeneratedStepPart`, `GeneratedStep`, `GeneratedIngredientLines`),
`Domain/Structuring/IngredientHeadings.swift`, `Domain/Structuring/PageClutter.swift`,
`Domain/Structuring/ReviewFlag.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`,
`SylantroTests/Domain/ReviewFlagTests.swift`.

*Why:* run 9 (`10` §7): the steps part asks the model to retype each step, and it sometimes
stitches a step's start to its end and drops the middle (10 steps on 8 pages aren't on the page,
for example "Add … still crisp, 5-8 minutes."). Step counts also differ from the key on 7 pages.
Ingredients already come back as line numbers, with the words taken from the page (SLT-146), and
have lost no words since. RV-39 (Pops, 25 Nov 2026): do the same for steps.

#### Part 1 · The steps as line numbers (`GeneratedParts`, `RecipeStructurer`)

1. `@Generable GeneratedStepLines { steps: [GeneratedStepRange] }`, guide "The method steps in
   printed order, each as the numbers of its lines."; `GeneratedStepRange { firstLine: Int,
   lastLine: Int }`, guides "The number of the step's first line." and "The number of its last
   line, the same as the first if it fits on one line." They replace `GeneratedStepPart` and
   `GeneratedStep`, which go.
2. The steps part's prompt: `"The method lines of a recipe, numbered:"` then the section's lines
   numbered (`numbered`), as the ingredients part is. The same token cap. The steps fallback asks
   the same over every readable line.
3. `promptVersion` 3 → 4. The header, ingredients and line-label prompts, `instructions` and their
   `@Guide`s are unchanged.

#### Part 2 · From line numbers to steps (`RecipeStructurer.steps(from:lines:)`, static, tested)

Over the numbered lines (from 1), in order:

1. **Headings:** lines `IngredientHeadings.lines` finds (a short line ending `:`) are step
   headings, not steps: each step after one, until the next, has that heading (less the `:`) as its
   `groupName`.
2. **The model's ranges:** each in range, `firstLine <= lastLine`, at most 15 lines, its lines not
   already used and not headings, is a step; others are dropped with `step lines out of range`.
3. **A printed number starts a step:** a line starting with a step number (digits then `.` or `)`
   and a space, or digits then a space and a capital) inside a range starts a new step there.
4. **Lines the model skipped** (not used, not a heading, not clutter): joined to the step before
   when it starts lowercase or that step doesn't end with `.`, `!` or `?`; otherwise it starts a
   new step, with `put back: step n`. In the fallback (every readable line), skipped lines are
   left out, as now.
5. **The words:** a step's text is its lines joined with a space, except that a line ending with
   `-` joins the next with no space; a leading step number is removed. Steps are indexed from 0 in
   line order.

#### Part 3 · The flag (`ReviewFlag`)

`put back: step n` is `putBack` on that step (S-52l "Put back from the page. Check it."), as
`put back: ingredient n` is on an ingredient.

#### Part 4 · Tests

| File | Test | Checks |
|---|---|---|
| `RecipeStructurerTests` | steps by lines | made-up lines 1 to 5, ranges 1–2 and 3–5: two steps whose texts are the lines joined, every word as printed |
| | a hyphen at a line's end | "until golden-" then "brown." gives "until golden-brown." |
| | a skipped line | a skipped line starting lowercase joins the step before; one after a step ending `.` starting with a capital is its own step with `put back: step n` |
| | a printed number starts a step | a range over "1. Mix the flour." and "2. Add the eggs." gives two steps, "Mix the flour." and "Add the eggs." |
| | a step heading | "For the filling:" before two steps gives both `groupName` "For the filling" and isn't a step |
| | bad ranges | a range past the last line and one overlapping an earlier step are dropped, with `step lines out of range` |
| `ReviewFlagTests` | a step put back | `put back: step 2` is `putBack` on the second step |

**The suite total:** M3-3i's total (209) plus these 7: **216**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **216** tests (or the total before plus 7,
   said), with the destination string and the run's own total.
3. `git diff` of `GeneratedParts.swift` changes only the steps types; of `RecipeStructurer.swift`,
   only the steps part, its fallback, the new `steps(from:lines:)`, `assemble`/`makeSteps` and
   `promptVersion` (now 4); the header, ingredients and line-label prompts and `instructions` are
   unchanged; `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. No page content in the repo: tests use made-up lines.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. Spike run 10, as before, saved to `sylantro-testpages/results/`. Claude scores it against run 9:
   steps not on the page (10 in run 9), step positions (64 of 74), step counts against the key, and
   no change to titles or ingredients.
2. Kolaches: ⋯ › Read Again. Each step reads as printed, and tapping it outlines its own lines.

#### Do not

Change the header, ingredients or line-label prompts, `instructions`, `SylantroSchemaV1` or any
synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, the views,
`Info.plist`, the entitlements, build settings or SyLib. No string she reads. No page content in
the repo (SLT-092). No network. Edit no document except §2 of this one.

---

### Task M3-3k · Sylantro · Steps split where the page splits them

**Status: complete (223 tests); spike run 11 to score.** RV-39 ruled; run 10 (`10` §7) chose this
before the title rules (Pops, 25 Nov 2026, "Step clean-up rules, then run 11"). Rules only: no
prompt, `instructions`, `@Guide` or `promptVersion` change (it stays 4). Spike run 11 checks it.

**Inputs:** `00`, `00A`, `00B`, `10` §7 (run 10), this document (RV-29, RV-39, Task M3-3j and
its row in §2), and these files: `Extraction/RecipeStructurer.swift` (`steps(from:lines:putsBackSkipped:)`
and its helpers, `labelled(_:labels:keeping:)`), `Domain/Structuring/IngredientHeadings.swift`,
`Domain/Structuring/PageClutter.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`.

*Why:* run 10: since M3-3j the model no longer drops words from a step, but the steps are split
worse (the step count matches the key on 8 pages, against about 11 in run 9). What is left is
mechanical:

1. On line-labelled pages, a line in the middle of a step labelled an ingredient or a note leaves
   a gap in the step (3 pages).
2. The model's ranges break a sentence, and only skipped lines are joined back (5 pages).
3. "Step 1" labels, a lone "4.", a footer, a copyright line and a time label become steps, and a
   skipped line before the first step or after the last is put back as one (6 pages).
4. A short heading with no colon, like a section name, becomes a step (1 page).

#### Part 1 · A step line the labels gave elsewhere (`RecipeStructurer.labelled`)

A line labelled `ingredient` or `note` whose nearest labelled lines before and after it (skipping
clutter, headings and lines with no label) are both labelled `step` is a step line: it goes into
`steps`, in its place, and not into `ingredients` or `notes`. Only `labelled` changes, so pages
with printed sections are as before.

#### Part 2 · The steps' rules (`RecipeStructurer.steps(from:lines:putsBackSkipped:)`)

The rules M3-3j built stay, with these changes and additions, in this order:

1. **A step marker line:** a line that is only a step number (`4.`, `4)`), or `Step` and a
   number, with or without a `:` after it, adds no text. The next line starts a new step,
   inside a range or as a skipped line. A line starting with `Step` and a number and then text
   (for example "Step 4 Bake …") starts a step, as a printed number does, and the `Step n` is
   removed from its text.
2. **A numbered page:** when two or more of `lines` start with a step number or are step markers,
   a step starts only at a step number or a marker, and at the first step after a heading. A range
   or a skipped line that starts anywhere else joins the step before.
3. **A range that continues a sentence:** on any page, a range that doesn't start at a step number
   or a marker joins the step before, in the same group, when its first line starts lowercase or
   the step before doesn't end with `.`, `!` or `?`. This is the rule skipped lines already follow.
4. **Put back only between steps:** a skipped line that would start a step of its own is put back
   (`put back: step n`) only when it comes after the first kept step and before the last one's
   last line, or when it starts with a step number or follows a marker. Any other skipped line is
   left out. A skipped line that joins the step before is joined, as now.
5. **A heading with no colon:** a one-line step of at most 4 words, with every word starting with
   a capital letter, no digit, and no `.` or `?` at its end, followed by another step in its group,
   is not a step. It names the steps after it as a heading does (`groupName`), until the next
   heading.
6. **A fragment:** a step whose text has fewer than 2 words with a letter, and doesn't end with `.`,
   `!` or `?`, is left out. For example ": 10 min" is left out, and "Enjoy!" stays.

Steps are indexed from 0 after these rules, and `put back: step n` counts the steps kept. The
fallback (`putsBackSkipped: false`) follows rules 1, 2, 3, 5 and 6; it puts back nothing, as now.

#### Part 3 · Tests

| File | Test | Checks |
|---|---|---|
| `RecipeStructurerTests` | a range that continues a sentence | lines "Simmer the made-up sauce for 10", "minutes. Serve it hot."; ranges 1–1 and 2–2: one step, the two lines joined |
| | a numbered page | lines "1. Mix the made-up flour.", "Add the eggs.", "2. Bake it."; ranges 1–1, 2–2, 3–3: two steps, "Mix the made-up flour. Add the eggs." and "Bake it." |
| | step markers | lines "Step 1", "Heat the made-up oven.", "Step 2", "Mix the dough.", "4.", "Bake it well."; one range 1–6: three steps, "Heat the made-up oven.", "Mix the dough." and "Bake it well." |
| | a heading with no colon | lines "Campfire Method", "Warm the made-up tortilla.", "Add the sauce."; ranges 1–1, 2–2, 3–3: two steps, both with `groupName` "Campfire Method" |
| | a fragment | lines ": 10 min", "Stir the made-up soup."; ranges 1–1 and 2–2: one step, "Stir the made-up soup." |
| | put back only between steps | lines "Made-up Notes Here.", "Mix the batter.", "Rest the batter.", "Bake the batter.", "Related Recipes Below."; ranges 2–2 and 4–4: three steps, "Rest the batter." put back (`put back: step 2`); lines 1 and 5 are left out |
| | a step line labelled an ingredient | `labelled` over "Mix the made-up oats and", "2 cups of the nuts until", "coated. Bake it."; labels step, ingredient, step: all three in `steps`, `ingredients` empty; the same with `note` for the middle line: `notes` empty |

"A skipped step line" (M3-3j) changes: its skipped line "Serve it warm." was the last line, which
rule 4 now leaves out, so a fourth line "Cool it a little." is added with a range 4–4. It then
expects three steps, the second put back (`put back: step 2`). No other existing test changes.

**The suite total:** M3-3j's total (216) plus these 7: **223**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **223** tests (or the total before plus 7,
   said), with the destination string and the run's own total.
3. `git diff` of `RecipeStructurer.swift` changes only `steps(from:lines:putsBackSkipped:)`, its
   private helpers and `labelled(_:labels:keeping:)`. `promptVersion` stays 4. No prompt,
   `instructions` or `@Guide` change. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is
   empty.
4. No string she reads changes. No page content in the repo: the tests use made-up lines.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. Spike run 11, as before, saved to `sylantro-testpages/results/`. Claude scores it against run
   10. The checks: step counts against the key (8 pages in run 10), steps with no position (10 in
   run 10), every step still in the page's words, and no change to titles or ingredients.
2. Kolaches: ⋯ › Read Again. The steps read as printed, one per printed step.

#### Do not

Change any prompt, `instructions`, a `@Guide` or `promptVersion`. Don't change `SylantroSchemaV1`
or any synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`,
`SourceLocator`, `PageClutter`, `PageSplitter`, the views, `Info.plist`, the entitlements, build
settings or SyLib. No string she reads. No page content in the repo (SLT-092). No network. Edit
no document except §2 of this one.

---


### Task M3-3l · Sylantro · Does reading go on in the background? (spike test)

**Status: ready, not started; runs after M3-3k and its run 11, before the title rules.** Pops,
25 Nov 2026: "what would it take to get the reading and spike analysis to run in the bg?", "so,
keeps running when the app is in the bg", then the decision card, "Test it in the spike first".
**Spike only.** RV-5 and SLT-144 stay as ruled for her reading: `ExtractionQueue` doesn't change.
This task only finds out whether the on-device model answers while Sylantro is in the background
under a task she starts. The answer decides whether a second task moves the queue onto it.

**Inputs:** `00`, `00A`, `00B`, `00` SLT-144 and SLT-153, this document (RV-5), `10` §6, and
these files: `Extraction/Spike/SpikeRunner.swift` (`runAll`, `read`, `structure`,
`sceneBecameActive`, `sceneLeftActive`, `wait`), `Extraction/Spike/SpikeReport.swift`,
`Views/Spike/SpikeView.swift` (the ⋯ menu, `scenePhase`), `Sylantro/Info.plist`,
`SylantroTests/Extraction/SpikeRunnerTests.swift`. Apple's BackgroundTasks documentation for
`BGContinuedProcessingTask` and `BGContinuedProcessingTaskRequest` (iOS 26). Read it from the SDK's
headers or Xcode's documentation; no network.

*Why:* the spike can't structure while Sylantro is in the background. In run 1 the model refused
requests then (SLT-144), so the spike waits for the app (`waitingForApp`). iOS 26's
`BGContinuedProcessingTask` lets work that a person starts with a tap keep running after they leave
the app, with a system progress indicator they can see and cancel. Nobody knows yet whether the
on-device model answers inside one.

#### Part 1 · The background run (`SpikeRunner`, `SpikeView`, `Info.plist`)

1. **`Info.plist`:** add `BGTaskSchedulerPermittedIdentifiers` holding one identifier,
   `com.syzygysoftwerksllc.Sylantro.spike.run`. Pops allows this one key for this task. Add a
   `UIBackgroundModes` value only if the SDK's documentation says a continued processing task needs
   one; then say which and why in the notes. Change no other key.
2. **A ⋯ menu item on the spike screen, "Run All in Background (Test)":** enabled when "Run All"
   is. A spike-only label, in English like the screen's others; she never sees it. It:
   - registers a launch handler for the identifier, if it isn't registered yet;
   - submits a `BGContinuedProcessingTaskRequest` (title "Spike run", subtitle "Starting", the
     strategy that fails rather than queues when it can't start now);
   - runs `runAll` in background-test mode inside the handler.
   If the submit throws, the run goes ahead as "Run All" does, and the report says why.
3. **Inside the task:**
   - Set the task's `progress` (total = captures; completed + 1 as each capture ends, however it
     ends).
   - Update the subtitle to "Capture n of m".
   - On expiry, cancel the run as Close does, and record the capture it stopped at.
   - At the end, call `setTaskCompleted(success:)` (true when the run wasn't cancelled or expired).
   - Don't ask for GPU or other extra resources.
4. **Background-test mode in `structure`:** structuring is tried whether or not the scene is
   active. A refusal while the scene is active is retried as now (SLT-153). A refusal while it isn't
   active is recorded, and the capture waits for the app as now (`waitingForApp`, SLT-144). Reading
   pages (`read`) is unchanged. "Run All" without the test mode is unchanged.

#### Part 2 · What the run records (`SpikeReport`)

New fields, all decoded with `decodeIfPresent`, so earlier results files still read:

- **Report:**
  - `backgroundTask: String?`: nil for a plain run; otherwise "completed", "cancelled",
    "expired at capture n" or "not started: <error>".
- **Each capture:**
  - `readWhileInBackground: Bool?`: whether the scene was inactive when its pages were read.
  - `structureAttempts: [Attempt]?`, one for each structuring attempt, each holding:
    - `sceneActive: Bool`;
    - `outcome`: "done", "refused" or "failed: <error's description>";
    - `millis: Int`;
    - `at`: the attempt's start, as an ISO 8601 date.
  - The time the scene left and came back is logged, as now.

No recipe text in any new field or log line.

#### Part 3 · Tests

| File | Test | Checks |
|---|---|---|
| `SpikeRunnerTests` | background fields round trip | a report with `backgroundTask` "expired at capture 3" and a capture with two attempts (one active "refused", one inactive "done") encodes and decodes unchanged; "older results read" still passes with none of the new fields |

**The suite total:** M3-3k's total (223) plus this 1: **224**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **224** tests (or the total before plus 1,
   said), with the destination string and the run's own total.
3. `git diff` touches only `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift`,
   `Info.plist` (the one key, and a background mode only if the notes justify it) and
   `SpikeRunnerTests.swift`. `ExtractionQueue`, `RecipeStructurer` and every prompt are
   unchanged. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. No recipe text in logs or the new fields.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. Load Test Set, then ⋯ › Run All in Background (Test).
2. After the first two captures finish, swipe up to the Home Screen and open another app. A
   "Spike run" progress indicator should show. Stay away about 5 minutes, then come back.
3. Let the run finish, Export Results to `sylantro-testpages/results/`, and tell Claude the file
   name. Say whether the progress indicator showed.
4. If there's time, a second run, locking the phone instead of switching apps.

Claude reads each capture's attempts. Did structuring succeed with the scene inactive, how often
was it refused, and did the task expire? From that comes the proposal: move the reading queue onto
this kind of task, or leave SLT-144 as it is.

#### Do not

Change `ExtractionQueue`, `RecipeStructurer`, any prompt, `instructions`, a `@Guide` or
`promptVersion`. Don't change `SylantroSchemaV1` or any synced model, `CaptureRecorder`,
`RecipeEditor`, `MirrorWriter`, the views other than `SpikeView`, `Info.plist` beyond Part 1,
the entitlements, build settings or SyLib. Don't use `BGProcessingTask` or `beginBackgroundTask`.
No string she reads. No page content in the repo (SLT-092). No network. Edit no document except §2
of this one.

---


### Task M3-3m · Sylantro · Steps under printed labels and headings

**Status: complete (232 tests); spike run 12 to score.** RV-39 ruled
(steps first); run 11 (`10` §7) found what's left. Rules only: no prompt, `instructions`, `@Guide`
or `promptVersion` change (it stays 4). Spike run 12 checks it.

**Inputs:** `00`, `00A`, `00B`, `10` §7 (runs 10 and 11), this document (Tasks M3-3h, M3-3j,
M3-3k and their rows in §2), and these files: `Extraction/RecipeStructurer.swift`
(`steps(from:lines:putsBackSkipped:)` and its helpers, `labelled(_:labels:keeping:)`,
`ingredientGroups(from:lines:)`), `Domain/Structuring/PageClutter.swift`,
`Domain/Structuring/IngredientParser.swift` (or wherever a line's unit is found),
`Extraction/Spike/SpikeRunner.swift`, `Extraction/Spike/SpikeReport.swift`,
`Extraction/Spike/TestSetGroups.swift`,
`SylantroTests/Extraction/RecipeStructurerTests.swift`, `SylantroTests/Domain/PageClutterTests.swift`
(or its tests' file), `SylantroTests/Extraction/SpikeRunnerTests.swift`.

*Why:* run 11: step counts now match the key on 13 of 22 pages, against 7. But the new five-page
recipe (TP-26 to TP-30) lost 6 of its 10 steps, with 8 `step lines out of range`. Each printed step
there is a "Step n" line, a heading line ending `:`, then the step's lines. The model's range for a
step most likely takes in its label and heading, and M3-3j drops any range that touches a heading.
The skipped lines then come back only between kept steps (M3-3k rule 4), so the first and last
steps are lost. The same recipe's 31 ingredients all came back flagged "put back", after 4
`ingredient lines out of range`, and nobody can see why without the model's answer. Smaller faults
on the 22: a heading with no colon swallowed on a numbered page; two step lines in a row given to
the ingredients; a "Related Pages" list joined to the last step; an ingredient line moved into a
step; a footer whose `https` was misread, joined to an ingredient.

#### Part 1 · What the spike records (`SpikeReport`, `SpikeRunner`, spike only)

New fields on each capture, decoded with `decodeIfPresent`:

- `stepRanges: [[Int]]?`: the steps part's answer as the model gave it, `[firstLine, lastLine]`
  each.
- `ingredientItems: [[Int]]?`: each item's `[groupIndex, firstLine, lastLine]`, with the group's
  `nameLine` as `[groupIndex, nameLine, -1]` first.
- `sectionLineCounts: [String: Int]?`: how many lines the ingredients and steps sections held
  (`ingredients`, `steps`), after wraps are joined.

They carry no text, only numbers. `RecipeStructurer`'s outcome gains what the spike needs to fill
them. The app ignores them.

#### Part 2 · The steps' rules (`RecipeStructurer.steps(from:lines:putsBackSkipped:)`)

M3-3k's rules stay, with these changes:

1. **A range over a label or a heading:** step marker lines and heading lines inside a range are
   taken out of it, not counted toward its 15 lines, and the rest of the range is checked as
   before. Only a range with nothing left, or one that touches a line already used, is dropped
   (`step lines out of range`). The heading still names the steps after it, and the marker still
   starts the next step.
2. **A step after a label or a heading is put back anywhere:** a skipped line that is the first
   line (not empty, not clutter) after a marker, or after a heading, starts a step and is put back
   (`put back: step n`) even before the first kept step or after the last. This extends M3-3k
   rule 4.
3. **A heading with no colon on a numbered page:** M3-3k rule 2's join doesn't join a one-line
   piece that has rule 5's heading shape, and doesn't join anything onto one. Rule 5 then makes it
   a heading.
4. **Where the method ends:** a line that reads "Related Pages", "Related Recipes", "More Recipes",
   "You May Also Like" or "Frequently Asked Questions" (trimmed, any case, with or without a `:`)
   ends the steps. That line and every line after it in `lines` are no step's, and a range over it
   is cut short before it.

#### Part 3 · A run of step lines the labels gave elsewhere (`RecipeStructurer.labelled`)

M3-3k Part 1 moves one line. It now moves a run of 1 to 3 lines labelled `ingredient` or `note`
whose nearest labelled lines before and after the run are both `step`. If any line in the run starts
with a quantity followed by a unit (as the ingredient parser reads it: "½ cup …" yes, "25 minutes."
no), the whole run stays where the labels put it.

#### Part 4 · A misread web address is page clutter (`PageClutter.isClutter`)

As well as today's rules, a line is clutter when any of its words is `www`, starts with `www.`,
contains `.com/`, or ends with `.com`, `.org` or `.net`. Words are separated by spaces, and a word's
trailing punctuation is ignored.

#### Part 5 · The five-page recipe loads as one (`TestSetGroups`, spike only)

`TestSetGroups.captures(fileNames:)` joins runs of pages, not only pairs: 5–6, 7–8, 16–17 as now,
and 26 to 30 (`10` §1). A run is one capture, in page order, when every page in it is present.
Otherwise each of its pages is its own capture, as a pair is today. HEIC is already read
(`extensions`); nothing else about loading changes. With this, Load Test Set gives 23 captures.

#### Part 6 · The background test's identifier (`Info.plist`, `SpikeRunner`, M3-3l note b)

Apple's documentation for `BGContinuedProcessingTaskRequest` asks for a wildcard identifier. So
`BGTaskSchedulerPermittedIdentifiers` holds `com.syzygysoftwerksllc.Sylantro.spike.*` instead of
`…spike.run`, the launch handler is registered for that wildcard, and the request keeps
`com.syzygysoftwerksllc.Sylantro.spike.run`. Nothing else about M3-3l changes. This is Part 1's
one `Info.plist` key from M3-3l, which Pops allowed; no other key changes.

#### Part 7 · Tests

| File | Test | Checks |
|---|---|---|
| `RecipeStructurerTests` | a range over a label and a heading | lines "Step 1", "Mix it:", "Stir the made-up flour.", "Add the water.", "Step 2", "Bake it:", "Bake the made-up bread."; ranges 1–4 and 5–7: two steps, "Stir the made-up flour. Add the water." (`groupName` "Mix it") and "Bake the made-up bread." ("Bake it"); no warnings |
| | a first step after a label is put back | the same lines; range 5–7 only: two steps, the first put back (`put back: step 1`) |
| | a heading on a numbered page | lines "1. Mix the made-up dough.", "2. Bake it.", "Campfire Method", "1.", "Warm the made-up tortilla."; ranges 1–1, 2–2, 3–3, 5–5: three steps, the last with `groupName` "Campfire Method" |
| | where the method ends | lines "Simmer the made-up cider for 10", "minutes. Serve it hot.", "Related Pages", "Made-up Cider Recipe"; range 1–4: one step, "Simmer the made-up cider for 10 minutes. Serve it hot." |
| | a run of step lines labelled ingredients | `labelled` over "Whisk the made-up", "butter, sugar, honey,", "spice and salt in a", "medium bowl."; labels step, ingredient, ingredient, step: all four in `steps`. The same with the second line "1/2 cup made-up sugar,": it and the third line stay in `ingredients` |
| `PageClutterTests` | a misread web address | "naps www madeupsite.com recipes made-up-page" and "madeupsite.com/recipes/made-up" are clutter; "1 cup made-up sugar" and "Stir the made-up sauce." aren't |
| `SpikeRunnerTests` | a run of five pages is one capture | `captures(fileNames:)` over TP-25.jpeg and TP-26.heic to TP-30.heic gives two captures: TP-25 alone, then TP-26 to TP-30 in order; without TP-28, TP-26, TP-27, TP-29 and TP-30 are four captures of one page each; "the test set groups by page ID" still passes |
| | step and ingredient answers recorded | a capture with `stepRanges`, `ingredientItems` and `sectionLineCounts` encodes and decodes unchanged; "older results read" still passes |

No existing test should change. If one does, say which and why.

**The suite total:** M3-3l's total (224) plus these 8: **232**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **232** tests (or the total before plus 8,
   said), with the destination string and the run's own total.
3. `git diff` of `Info.plist` is Part 6's one value. `git diff` of `RecipeStructurer.swift` changes only `steps(from:lines:putsBackSkipped:)`, its
   helpers, `labelled(_:labels:keeping:)`, and what its outcome passes to the spike. No prompt,
   `instructions`, `@Guide` or `promptVersion` change. `PageClutter.swift` changes only
   `isClutter` and its helpers. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. No page content in the repo: the tests use made-up lines. The new
   spike fields hold numbers only.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. Before the run, move `TP-26.heic` to `TP-30.heic` from `New/` into `Pages/`. Spike run 12:
   Load Test Set (23 captures, the five-page recipe as one), then Run All. Export to `sylantro-testpages/results/`. Claude scores it against run 11, the
   five-page recipe's 10 steps first, and uses the new fields to find why its ingredients came back
   flagged.
2. Kolaches: ⋯ › Read Again. The steps read as printed, one per "Step n".

#### Do not

Change any prompt, `instructions`, a `@Guide` or `promptVersion`. Don't change
`ingredientGroups(from:lines:)`'s rules (this task only records its answer), `SylantroSchemaV1` or
any synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`,
`SourceLocator`, `PageSplitter`, the views, `Info.plist` beyond Part 6, the entitlements, build settings or SyLib.
No string she reads. No page content in the repo (SLT-092). No network. Edit no document except
§2 of this one.

---


### Task M3-3n · Sylantro · The background test crashed on device

**Status: ready, not started; runs after M3-3m.** A fix to M3-3l and M3-3m Part 6. Spike only.

**Inputs:** `00`, `00A`, `00B`, this document (Tasks M3-3l and M3-3m, their rows in §2), and these
files: `Extraction/Spike/SpikeRunner.swift` (`runAllInBackground`,
`registerLaunchHandlerIfNeeded`), `Sylantro/Info.plist`, the target's build settings
(`INFOPLIST_FILE`, `GENERATE_INFOPLIST_FILE`), and Apple's BackgroundTasks documentation for
`BGContinuedProcessingTaskRequest` and `BGTaskScheduler.register(forTaskWithIdentifier:using:launchHandler:)`,
from the SDK or Xcode's documentation; no network.

*Why:* Pops, 25 Nov 2026, on the iPhone 18 Pro after M3-3m, ⋯ › Run All in Background (Test)
ended the app:

```
Registration rejected; com.syzygysoftwerksllc.Sylantro.spike.* is not advertised in the application's Info.plist
*** Assertion failure in -[BGTaskScheduler _handleSubmissionWithoutRegistrationForTaskRequest:error:], BGTaskScheduler.m:350
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'No launch handler registered for task with identifier com.syzygysoftwerksllc.Sylantro.spike.run'
```

There are two faults. First, `register` returned false, and the run submitted anyway; a submit with
no handler isn't thrown as an error, it ends the app. Second, the system didn't find
`…spike.*` in the installed app's `Info.plist`, though the source file holds it. Either the
installed app's plist differs from the source, or the system wants the wildcard written another
way.

#### Part 1 · Never submit without a handler (`SpikeRunner`)

When `registerLaunchHandlerIfNeeded` hasn't registered a handler, `runAllInBackground` doesn't
submit. The run goes ahead as Run All, with `backgroundTask` "not started: registration rejected".
It logs one line naming the identifier it tried.

#### Part 2 · What the installed app holds (`SpikeRunner`, the build)

1. When the spike screen opens, it logs one line with `Bundle.main`'s
   `BGTaskSchedulerPermittedIdentifiers`, or says it has none.
2. Build for a generic iOS device (`-destination 'generic/platform=iOS'`) and read the built app's
   `Info.plist` (`plutil -p`). Say in the notes whether it holds
   `BGTaskSchedulerPermittedIdentifiers` with `com.syzygysoftwerksllc.Sylantro.spike.*`.
   - If it doesn't, find out why from the target's settings and fix it so it does. Say what was
     wrong.
   - If it does, read Apple's documentation again for how the permitted identifier, the
     registration and the request's identifier must be written for a continued processing task.
     Change only what the documentation shows is wrong. Quote the lines that decide it in the
     notes.

#### Part 3 · Tests

None can run the scheduler. The suite total stays **232**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings, for the
   pinned simulator and for a generic iOS device.
2. The suite passes on the pinned destination with **232** tests, with the destination string and
   the run's own total.
3. `git diff` touches only `SpikeRunner.swift` and, if Part 2 needs it, `Info.plist`'s
   `BGTaskSchedulerPermittedIdentifiers` value or the target's Info.plist settings, each change
   explained. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. The new log lines hold identifiers only.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. In Xcode, Product › Clean Build Folder, then run on the iPhone, so the installed app has the
   new `Info.plist`.
2. Open the spike. In Xcode's console, check the line listing the permitted identifiers.
3. ⋯ › Run All in Background (Test), as before. Whatever happens, the app shouldn't crash. Export
   and send the file name, whether the progress indicator showed, and any console lines starting
   with "background task".

#### Do not

Change `RecipeStructurer`, `ExtractionQueue`, any prompt or `promptVersion`, `SylantroSchemaV1` or
any synced model, the views, other `Info.plist` keys, the entitlements, other build settings or
SyLib. No string she reads. No network. Edit no document except §2 of this one.

---


### Task M3-3o · Sylantro · Background reading waits out the rate limit (spike test)

**Status: complete (234 tests); Pops's device run next.** Was: runs after M3-3n. Pops, 25 Nov 2026, decision card, "Write M3-3o
now"; then "move bg run out of menu, called BG Run All". A follow-up to M3-3l and M3-3n. **Spike only.** RV-5 and SLT-144 stay as ruled for her
reading: `ExtractionQueue` doesn't change.

**Inputs:** `00`, `00A`, `00B`, `00` SLT-144 and SLT-153, this document (RV-5, Tasks M3-3l and
M3-3n and their rows in §2), and these files: `Extraction/Spike/SpikeRunner.swift` (`runAll`,
`runAllInBackground`, `structure`, `retryDelay(afterRefusal:)`, `structureWaiting`, `wait`),
`Extraction/Spike/SpikeReport.swift` (`SpikeCaptureResult.Attempt`),
`Views/Spike/SpikeView.swift` (the button row, the ⋯ menu), `Extraction/RecipeStructurer.swift` (read only: `structure(_:pageIDs:onPartDone:)`, `call`,
`respond`, `isRateLimit`), `SylantroTests/Extraction/SpikeRunnerTests.swift`. Apple's
BackgroundTasks documentation for `BGContinuedProcessingTask` (its `progress` and expiry) and the
FoundationModels documentation for `LanguageModelSession.GenerationError.rateLimited`, from the
SDK's headers or Xcode's documentation; no network.

*Why:* Pops's background run after M3-3n, on the iPhone 18 Pro. The task started and showed
"Spike run". Capture 0 was structured with the scene inactive ("capture 0: done, 1 recipe"), so
**the on-device model does answer in the background.** Captures 1 to 22 were then "refused, scene
active false" one after another. The console's error under each was "Client rate limit exceeded",
with the system's hint: "If you are using streaming responses in a background request, consider
using non-streaming requests in background activities to reduce the likelihood of rate limiting."
Because `structure` sends a refusal with the scene inactive straight to `waitingForApp`, and
`runAll` counts every capture "however it ends", the indicator jumped from 1/23 to 23/23 and the
task ended with nothing done.

The hint doesn't apply: `RecipeStructurer.respond` already calls `session.respond(to:generating:options:)`,
which doesn't stream. So the limit is a budget on how many requests a background app may make, and
each capture makes several (line labels or header, ingredients, steps, and the spike's title
lister). This task finds out whether waiting it out works.

#### Part 1 · Wait out a refusal in the background (`SpikeRunner.structure`)

1. **Background test only:** a rate-limit refusal while the scene is inactive is retried after a
   wait, as a refusal in front already is (SLT-153), instead of going straight to `waitingForApp`.
   The waits come from a new `nonisolated static func backgroundRetryDelay(afterRefusal count: Int) -> Duration?`:
   30, 60, 120, 240, 300 and 300 seconds for refusals 1 to 6, then nil. After the sixth, or if the
   wait is cancelled, the capture waits for the app as now (SLT-144).
2. A refusal while the scene is active keeps `retryDelay(afterRefusal:)` (30 seconds, three times).
   When the scene changes during a capture's refusals, the next wait follows the scene at that
   moment, and the count of refusals carries on.
3. During a wait the task's subtitle is "Capture n of m, waiting" (a spike-only label, English like
   the others; she never sees it). It goes back to "Capture n of m" when structuring starts again.
4. "Run All" without the test mode is unchanged.
5. Don't fake progress to keep the task alive. If the documentation says the system expires a
   continued-processing task whose progress doesn't advance, quote that line in the notes. An
   expiry during a wait is a finding, recorded as M3-3l records it ("expired at capture n").

#### Part 2 · Progress that tells the truth (`SpikeRunner.runAll`, `runAllInBackground`)

1. The task's `completedUnitCount` is the runner's `processedCount` (done or failed, never waiting
   for the app, `11` M1-13), the same count the screen's own bar shows. It is set after each
   capture and after each capture `structureWaiting` structures while the task runs.
2. The report's `backgroundTask` is "completed" when no capture is left waiting, and
   "completed, n waiting for the app" when some are. "cancelled", "expired at capture n" and
   "not started: …" are unchanged.

#### Part 3 · The button (`SpikeView`)

"Run All in Background (Test)" leaves the ⋯ menu. Instead, a `CapsuleButton("BG Run All")`
goes in the button row right after "Run All", in the default style (Run All keeps the accent). It
starts `runner.runAllInBackground()` as the menu item did, is disabled when Run All is, and Close
cancels it as before. A spike-only label, in English like the screen's others; she never sees it.
The ⋯ menu keeps Add Capture and Clear. Change nothing else in the view; update the comment that
names the old item.

#### Part 4 · What each attempt records (`SpikeReport`)

`SpikeCaptureResult.Attempt` gains two fields, decoded with `decodeIfPresent`, so earlier results
files still read:

- `partsDone: [String]?`: the names `onPartDone` gave during this attempt, in order, before it
  ended. It shows how many requests got through before the limit.
- `retryAfterSeconds: Int?`: the wait before the next attempt, when there is one; nil otherwise.

Part names only: no recipe text in any new field or log line. Each wait is logged as one line:
"capture n: refused, scene active <Bool>, retrying in <s> s".

#### Part 5 · Tests

| File | Test | Checks |
|---|---|---|
| `SpikeRunnerTests` | background retries are timed and limited | `backgroundRetryDelay(afterRefusal:)` is 30, 60, 120, 240, 300, 300 seconds for 1 to 6, nil for 0 and 7 |
| | attempt parts and waits round trip | an attempt with `partsDone` ["line labels", "ingredients"] and `retryAfterSeconds` 60 encodes and decodes unchanged; "older results read" and "background fields round trip" still pass |

No existing test should change. If one does, say which and why.

**The suite total:** M3-3n's total (232) plus these 2: **234**. The button and the progress
count need the device; they are checked there.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings, for the
   pinned simulator and for a generic iOS device.
2. The suite passes on the pinned destination with **234** tests (or the total before plus 2,
   said), with the destination string and the run's own total.
3. `git diff` touches only `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift` (Part 3 only) and
   `SpikeRunnerTests.swift`.
   `RecipeStructurer.swift`, `ExtractionQueue`, every prompt and `Info.plist` are unchanged.
   `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. No recipe text in logs or the new fields.
5. The notes say what the documentation says about `progress` and expiry, quoted, and whether
   `rateLimited` carries a suggested wait (if it does, say so and don't use it yet).
6. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. Run from Xcode onto the iPhone. Open the spike: "BG Run All" sits after "Run All", and the ⋯
   menu no longer has the background item. Load Test Set, then BG Run All.
2. The "Spike run" indicator and the screen's bar should show the same count. After the first
   capture finishes, swipe up to the Home Screen and open another app. Stay away
   about 15 minutes. Glance at the "Spike run" indicator now and then, and note what it showed.
3. Come back, let the run finish, Export Results to `sylantro-testpages/results/`, and send the
   file name and any console lines with "refused" or "background task".

Claude reads each capture's attempts: how many requests got through between refusals, whether the
waits let structuring go on in the background, and whether the task expired. From that comes the
proposal: move the reading queue onto this kind of task with these waits, or leave SLT-144 as it is.

#### Do not

Change `RecipeStructurer`, `ExtractionQueue`, any prompt, `instructions`, a `@Guide` or
`promptVersion`. Don't change `SylantroSchemaV1` or any synced model, `CaptureRecorder`,
`RecipeEditor`, `MirrorWriter`, the views other than Part 3's change to `SpikeView`, `Info.plist`, the entitlements, build settings or
SyLib. Don't ask for GPU or other extra resources, and don't use `BGProcessingTask` or
`beginBackgroundTask`. No string she reads. No page content in the repo (SLT-092). No network.
Edit no document except §2 of this one.

---

### Task M3-3p · Sylantro · Background progress at each step (spike test)

**Status: complete (236 tests); Pops's device run next.** Was: runs after M3-3o. Pops, 25 Nov 2026, decision card, "Write M3-3p
now"; then "it did not finish after the stall...". A follow-up to M3-3o. **Spike only.** RV-5 and SLT-144 stay as ruled for her reading:
`ExtractionQueue` doesn't change.

**Inputs:** `00`, `00A`, `00B`, this document (Tasks M3-3l, M3-3n and M3-3o and their rows in §2,
note a of M3-3o's row in particular), and these files: `Extraction/Spike/SpikeRunner.swift`
(`runAll`, `runAllInBackground`, `read`, `structure`, `findTitles`, `pieces`, `structureWaiting`,
`expireBackgroundRun`), `Extraction/Spike/SpikeReport.swift`,
`SylantroTests/Extraction/SpikeRunnerTests.swift`.

*Why:* Pops's BG Run All after M3-3o, on the iPhone 18 Pro. Captures 0 and 1 were structured with
the scene inactive and nothing was rate-limited, so **the on-device model works in the background
under this task.** Then iOS expired the task during capture 2 (the report's "expired at capture 3"
counts from 1) and showed "Task failed". The indicator still read "Capture 1 of 23" with an empty
ring. M3-3o's note a quotes the SDK: a continued-processing task "_must_ report progress", and
"Tasks that appear stalled may be forcibly expired by the scheduler". Today progress moves only
when a whole capture ends. A capture can take a minute or more, and much longer in the spike,
because `findTitles` structures every piece again (capture 2 had 5 titles by type size, so 5 more
structurings). Between captures the task looks stalled.

#### Part 1 · Progress at each step (`SpikeRunner`, background test only)

1. The task's `totalUnitCount` is captures × 10.
2. A step inside a capture adds one unit, up to 9 for that capture. The steps are: each page read;
   the bottom read; each name `onPartDone` gives (passed from `structure` as M3-3o does); and in
   `findTitles`, the title lister's answer and each piece structured.
3. `completedUnitCount` is a new
   `nonisolated static func completedUnits(processed: Int, stepsInCurrent: Int) -> Int64`:
   `processed × 10 + min(stepsInCurrent, 9)`, where `processed` is `processedCount` (M3-3o Part 2:
   done or failed, never waiting for the app). Set it after each step and wherever M3-3o sets it
   now. A capture's steps start from 0 when it starts and when `structureWaiting` takes it up again.
4. The subtitle names the last step done: "Capture n of m, <step>", where `<step>` is "read",
   "line labels", "header", "ingredients", "steps", "titles" or "pieces" (the part's name as
   `onPartDone` gives it, retries and fallbacks under their part's name). M3-3o's
   "Capture n of m, waiting" stays for a wait. Spike-only labels, English like the others; she
   never sees them.
5. Plain "Run All" is unchanged: no task, no units.

#### Part 2 · No title comparison in the background test (`SpikeRunner.structure`)

In background-test mode `findTitles` is not called, so each capture makes only the structurer's
calls. Its fields stay nil in that run's report, as in a file from before M3-5s. Plain "Run All"
still calls it, so run 12 and later scored runs are unchanged. With Part 2, Part 1.2's title and
piece steps happen only in a plain run, which has no task; they are counted anyway, so the code
doesn't depend on Part 2.

#### Part 3 · When the task started and ended (`SpikeReport`)

The report gains `backgroundTaskStartedAt: Date?` and `backgroundTaskEndedAt: Date?`, decoded with
`decodeIfPresent`: the task's launch, and its end however it ended (completed, cancelled or
expired). Nil for a plain run. With each attempt's `at` and `millis`, they show how long the task
lived and where it stopped. Log one line at the end: "background task lasted <s> s".

#### Part 4 · An expiry ends the task, not the run (`SpikeRunner`)

Pops: "it did not finish after the stall...". Today an expiry cancels the run as Close does
(M3-3l), so the captures after it are never read, even once the app is in front again.

1. On expiry, the task is completed at once with `setTaskCompleted(success: false)`, the report
   records "expired at capture n" as now, and the runner stops touching the task (no more progress
   or subtitle).
2. The run is not cancelled. Background-test mode ends there, and the rest of the run goes on as
   "Run All" does: structuring only while the scene is active, a capture waiting for the app
   otherwise (SLT-144), then `structureWaiting` when it comes back. A capture cut off by the
   expiry ends however its call ends (done, refused and waiting, or failed), recorded as an attempt.
3. Close still cancels the run, with or without a task. After an expiry, the report's
   `backgroundTask` stays "expired at capture n" whether the run then finishes or is closed.
4. Log one line: "background task expired at capture n, run goes on in the app".

#### Part 5 · Tests

| File | Test | Checks |
|---|---|---|
| `SpikeRunnerTests` | background progress by steps | `completedUnits(processed:stepsInCurrent:)`: (0, 0) is 0; (0, 3) is 3; (2, 4) is 24; (2, 15) is 29 |
| | background task times round trip | a report with `backgroundTaskStartedAt` and `backgroundTaskEndedAt` encodes and decodes unchanged; "older results read" and "background fields round trip" still pass |

No existing test should change. If one does, say which and why.

**The suite total:** M3-3o's total (234) plus these 2: **236**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings, for the
   pinned simulator and for a generic iOS device.
2. The suite passes on the pinned destination with **236** tests (or the total before plus 2,
   said), with the destination string and the run's own total.
3. `git diff` touches only `SpikeRunner.swift`, `SpikeReport.swift` and `SpikeRunnerTests.swift`.
   `RecipeStructurer.swift`, `TitleLister`, `ExtractionQueue`, every prompt and `Info.plist` are
   unchanged. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. No recipe text in logs, subtitles or the new fields.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. Run from Xcode onto the iPhone. Load Test Set, then BG Run All.
2. After the first capture finishes, go to the Home Screen and open another app. The "Spike run"
   ring should move every few seconds, and the subtitle should name the step. Stay away about 15
   minutes, glancing at it now and then.
3. Come back. If the task expired, the run should go on in the app and finish. Let it finish, Export Results to `sylantro-testpages/results/`, and send the
   file name, what the indicator showed, and any console lines with "refused" or "background task".

Claude reads how long the task lived, how many captures were structured in the background, and any
refusals. From that comes the proposal: move the reading queue onto this kind of task, or leave
SLT-144 as it is.

#### Do not

Change `RecipeStructurer`, `TitleLister`, `ExtractionQueue`, any prompt, `instructions`, a `@Guide`
or `promptVersion`. Don't change M3-3o's waits. Don't change `SylantroSchemaV1` or any synced
model, `CaptureRecorder`, `RecipeEditor`, `MirrorWriter`, the views, `Info.plist`, the
entitlements, build settings or SyLib. Don't fake progress: a unit is added only when its step is
done. Don't ask for GPU or other extra resources, and don't use `BGProcessingTask` or
`beginBackgroundTask`. No string she reads. No page content in the repo (SLT-092). No network.
Edit no document except §2 of this one.

---

### Task M3-3q · Sylantro · Each ingredient's name from its own line

**Status: complete (239 tests); run 13 scored (`10` §7): 0 names from another line, the five-page recipe's flags gone.** Was: runs after M3-3p. Pops, 25 Nov 2026, decision card after run 12,
"Fix item names, then title rules". Rules only: no prompt, `instructions`, `@Guide` or
`promptVersion` change (it stays 4). Spike run 13 checks it. The title rules come after this task.

**Inputs:** `00`, `00A`, `00B`, `10` §7 (run 12), this document (RV-29, RV-38, Tasks M3-3h and
M3-3m and their rows in §2), and these files: `Extraction/RecipeStructurer.swift`
(`ingredientGroups(from:lines:)`, `putBackIngredient`, `startsWithQuantityAndUnit`),
`Domain/Structuring/IngredientLineParser.swift`, `Domain/Structuring/IngredientHeadings.swift`,
`SylantroTests/Extraction/RecipeStructurerTests.swift`.

*Why:* run 12, read with M3-3m's new spike fields. Two ingredient faults:

1. **A name from the next line.** An ingredient's words (`rawText`), quantity, unit and position
   come from the line numbers the model gives. Its `item`, `preparation` and `note` are the model's
   own text. On three pages the model's numbers are one line off from its text, so the item name
   belongs to the next line: the five-page recipe's first group has 10 such lines (the warm-water
   line is named "1/4 cup unsalted butter"), the magazine salad 4, the four-recipe page 7. The same
   since run 9. The model's item text sometimes also carries the quantity ("1/4 cup unsalted butter").
2. **Flags on lines that are right.** The five-page recipe has printed group headings. The model
   answered for the first group only, so M3-3h put the other 4 groups' 21 lines back, each flagged
   `put back: ingredient n`. All 21 are the page's own ingredient lines under their own headings.
   She would be asked to check 21 lines that are right.

#### Part 1 · The name comes from the line when the model's doesn't match (`ingredientGroups`)

For each ingredient made from the model's item:

1. Compare without case, with runs of whitespace as one space and the ends trimmed.
2. **`item`:** the model's item text is kept only when it is found in the parser's `rest` for the
   ingredient's own `rawText` (`IngredientLineParser.parse`, after the bullet is removed, as
   `putBackIngredient` does). Otherwise `item` is that `rest`, as a put-back line's is, or nil when
   `rest` is empty.
3. **`preparation` and `note`:** each is kept only when it is found in the ingredient's `rawText`;
   otherwise it is nil.
4. `isOptional`, `rawText`, quantity, unit and the line numbers are unchanged.
5. No warning: the ingredient's words are right, only the model's own name is replaced.

#### Part 2 · No flag on a line put back under a printed heading (`ingredientGroups`)

When the section prints group headings (`IngredientHeadings`, M3-3h), a line put back anywhere
after the first heading gets no `put back: ingredient n` warning when the parser finds a quantity
in it. It is still put back, in its place, under its heading. Any other line put back keeps its
warning as now: one with no quantity under a heading, any before the first heading, and every one
on a section with no printed headings (RV-29). "unused ingredient line n" is unchanged.

#### Part 3 · Tests

| File | Test | Checks |
|---|---|---|
| `RecipeStructurerTests` | an item name from the next line | lines "1 cup made-up flour, sifted", "2 tablespoons made-up sugar"; the model gives line 1 with item "made-up sugar" and preparation "melted", line 2 with item "made-up sugar": the first ingredient's item is "made-up flour, sifted" (or the parser's own rest for that line, said) with no preparation, the second's "made-up sugar"; no warnings |
| | an item name with its quantity | line "1/4 cup made-up butter"; the model's item "1/4 cup made-up butter": item "made-up butter" |
| | lines put back under headings unflagged | lines "Made-up dough:", "1 cup made-up flour", "Made-up filling:", "2 tablespoons made-up jam", "- made-up sprinkles"; the model gives line 2 only: line 4 is put back under "Made-up filling" with no warning; line 5 (no quantity) is put back with `put back: ingredient 3` |

**One existing test changes:** M3-3h's "a skipped group comes back" expects `put back: ingredient 3`
and `put back: ingredient 4` for "1 cup jam" and "1 tbsp sugar" under "Filling:". Under Part 2 both
have quantities, so it now expects no `put back` warning, and the rest of it as before. No other
existing test should change. If one does, say which and why.

**The suite total:** M3-3p's total (236) plus these 3: **239**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **239** tests (or the total before plus 3,
   said), with the destination string and the run's own total.
3. `git diff` of `RecipeStructurer.swift` changes only `ingredientGroups(from:lines:)` and its
   private helpers. No prompt, `instructions`, `@Guide` or `promptVersion` change.
   `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. No page content in the repo: the tests use made-up lines.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

1. Spike run 13: Load Test Set, then Run All (in front, so the title comparison runs too). Export
   to `sylantro-testpages/results/` and send the file name. Claude scores it against run 12: every
   ingredient's name from its own line, and the five-page recipe's flags.
2. Kolaches: ⋯ › Read Again. Each ingredient's name matches its line, and the filling and topping
   lines aren't marked to check.

#### Do not

Change any prompt, `instructions`, a `@Guide` or `promptVersion`. Don't change the steps' rules,
`labelled`, `IngredientLineParser`, `IngredientHeadings`, `ReviewFlag`, `SylantroSchemaV1` or any
synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, the spike, the
views, `Info.plist`, the entitlements, build settings or SyLib. No string she reads. No page
content in the repo (SLT-092). No network. Edit no document except §2 of this one.

---

### Task M3-3r · Sylantro · SyLib's components where Sylantro rolled its own

**Status: complete (Sylantro 239, SyLib 1,765 tests); Pops's device check next.** Was: runs after M3-3q, before the title rules. SLT-161 (Pops, 25 Nov 2026:
"we should us as much sylib ui components as possible. keep in mind we can make any change to
sylib we might need"); decision card, "A small task now". One SyLib change, named here (`00B` §2
allows a SyLib edit only when the task names it). No reading code changes.

**Inputs:** `00`, `00A`, `00B` (§3, SLT-089 and SLT-161), `13` (S-50 and the screens below), and
these files: `LIB/Sources/SyLibUI/Components/CapsuleButton.swift`, `MoreMenu.swift`,
`LIB/Docs/UI_COMPONENTS.md` (CapsuleButton, MoreMenu), `LIB/Tests/SyLibTests/SyLibUI/` (the
CapsuleButton tests), and in Sylantro `Views/Spike/SpikeView.swift`, `Views/Recipe/RecipeView.swift`
(the toolbar's ⋯ and the "Continues on a page not scanned" row), `Views/Recovery/StoreRecoveryView.swift`,
`Views/Capture/SavedPauseView.swift`, and `Views/Library/LibraryView.swift` (its `MoreMenu`, as the
model to follow).

*Why:* the spike's buttons are already SyLib's `CapsuleButton`, but four places still roll their
own where SyLib has, or can have, a component:

1. The ⋯ menus on the spike screen and the recipe screen are a hand-built `Menu` with an
   `IconButton` label. The library uses SyLib's `MoreMenu(look: .toolbar)`.
2. The store recovery screen's Try Again and Start Fresh are system bordered buttons.
3. The pause after saving pairs `CapsuleButton("Next Recipe")` with a plain "Done" button.
4. "That's All of It" in a recipe is a small system bordered button. `CapsuleButton` has no small
   size.

Left as they are, on purpose: list section headers (SyLib's `SectionHeader` is another style),
toolbar text buttons such as Done (SLT-089), alert buttons (the system's), iOS's `EditButton`, and
the photo strip's grab handle (no SyLib piece, and too small to add one).

#### Part 1 · SyLib: a small `CapsuleButton` (`CapsuleButton.swift`, `UI_COMPONENTS.md`)

1. `CapsuleButton.Size` gains `.small`, first in the list: label font `.footnote`, regular weight;
   padding 8 × 4 (horizontal × vertical); stroke width 1. Every other size is unchanged.
2. `UI_COMPONENTS.md`: the size table gains the `.small` row, and "five sizes" becomes "six
   sizes". Name no app anywhere in SyLib's code, comments or docs.
3. A SyLib test: `textStyle(of: .small)` is `.footnote`, and the five other sizes are unchanged.

#### Part 2 · Sylantro: the swaps

1. **The ⋯ menus** (`SpikeView`, `RecipeView`): `MoreMenu(look: .toolbar)` with the same items in
   the same order, as `LibraryView` does. No badge. The items, their labels, their `disabled` and
   their conditions are unchanged.
2. **Store recovery** (`StoreRecoveryView`): Try Again becomes
   `CapsuleButton("Try Again", style: .primary, size: .large, fillsWidth: true)`, and Start Fresh
   `CapsuleButton("Start Fresh", style: .destructive, size: .large, fillsWidth: true)`, with the
   same actions (Start Fresh still asks first with its plain alert). The `.controlSize(.large)` goes.
3. **The pause after saving** (`SavedPauseView`): Next Recipe becomes `.primary` (the main action),
   and Done becomes `CapsuleButton("Done", fillsWidth: true)`, below it, with the same action.
4. **"That's All of It"** (`RecipeView`): `CapsuleButton("That's All of It", size: .small)`, with
   the same action and `disabled`.

Each title is the string it was, so no string she reads changes.

#### Part 3 · Tests

SyLib: the one test in Part 1.3. Sylantro: none (views only); its suite total stays **239**.

#### Done when

1. SyLib builds and its suite passes (`00B` §5, item 3), with the run's own total and the total
   before plus 1, said.
2. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings, and its
   suite passes on the pinned destination with **239** tests, with the destination string and
   the run's own total.
3. `git diff` in Sylantro touches only the four view files named in Part 2. In SyLib it touches
   only `CapsuleButton.swift`, `UI_COMPONENTS.md` and the one test file. `grep` of SyLib's diff for
   any app's name finds none. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes.
5. `git status` before and after in both repositories (`00A` §9); the summary is a row at the top
   of §2.

#### Pops's step on device (iPhone 18 Pro)

1. The library's, a recipe's and the spike's ⋯ look the same and open the same items.
2. A recipe flagged "Continues on a page not scanned": "That's All of It" is a small capsule, and
   it still clears the line.
3. After saving a scan: Next Recipe is a filled capsule, and Done a capsule below it.
4. Store recovery can't be reached on purpose; its buttons are checked in the build only.

#### Do not

Change any reading or structuring code, prompt or `promptVersion`, `SylantroSchemaV1` or any
synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, the spike's
behavior, any other view, `Info.plist`, the entitlements or build settings. In SyLib, change only
what Part 1 names: no other size, style or component. No string she reads. No network. Edit no
document except §2 of this one.

---

### Task M3-3s · Sylantro · Titles the rules can fix

**Status: complete (243 tests); run 14 scored, M3-3t follows.** Was: runs after M3-3r. RV-39 ruled (steps, then the title rules, then
the unit rules); run 13 (`10` §7). Rules only: no prompt, `instructions`, `@Guide` or
`promptVersion` change (it stays 4). Spike run 14 checks it. RV-40's task (her reading in the
background) comes after this one.

**Inputs:** `00`, `00A`, `00B`, `10` §7 (runs 7 to 13) and SP-21, this document (RV-25, RV-35,
RV-39, Task M3-5 Part 4 item 4, Tasks M3-2a and M3-3k and their rows in §2), and these files:
`Domain/Structuring/HeaderArea.swift` (`lines(_:stopAt:)`, `snappedTitle`, `isSideLine`),
`Extraction/RecipeStructurer.swift` (`structure`'s step 2 and 3: `stopAt` and the header;
`labelled(_:labels:keeping:)`), `Domain/Structuring/PageClutter.swift`,
`SylantroTests/Domain/StructuringRulesTests.swift` (or wherever `HeaderArea`'s tests are),
`SylantroTests/Extraction/RecipeStructurerTests.swift`.

*Why:* titles have matched the key on the same pages since run 8. Three are wrong for reasons a
rule can fix, and on a fourth the title line ends up in a step:

1. **The magazine salad (labels path):** the labels end the header area at its second line, so the
   title, printed over three lines, is cut to its first word.
2. **The granola web print:** the line after the title, "Author: … Prep Time: … Cook Time: …", is
   the same size and the model's next line, so it joins the title.
3. **The slow-cooker web print:** the page opens with the site's section name, then a navigation
   line ("… Index | … Recipes | All Recipe Pages"), then the recipe's title. The title becomes the
   section name and the navigation line.
4. **The hummus magazine page (labels path):** the recipe's title line, printed below a three-line
   deck, is labelled a step and starts step 1. (Which line the model picks as the title there is
   its own choice, and this task doesn't change it.)

#### Part 1 · The header area on the labels path (`HeaderArea.lines`, SP-21)

When `stopAt` is given (labels ran), the area runs to the later of `stopAt` and the page's 5th
line (index 5), within `maximumLines` as now. Clutter, non-Latin and heading lines are still
dropped after. Without `stopAt`, nothing changes.

#### Part 2 · Lines that are never part of a title (`HeaderArea`)

1. **A label line** (moved here from M3-5 Part 4 item 4): one whose normalized text starts with
   `author`, `by `, `prep time`, `cook time`, `total time`, `active time`, `yield`, `serves`,
   `servings` or `makes`, followed by `:` or a space and more text. `isSideLine` takes it, so a
   snapped title never takes it in. A title that is itself such a line is unchanged (the start
   line isn't checked), as `isSideLine` works now.
2. **A navigation line:** an area line holding ` | ` (space, bar, space) two or more times.
3. **A breadcrumb line:** the area line directly before a navigation line.
4. In `snappedTitle`, the model's lines that equal (normalized) a navigation or breadcrumb line of
   the area are dropped with the side lines in step 2, and the title never takes one in, in step 4.
   So when the model answers with the section name, the navigation line and the title, the title
   starts at its own line.

#### Part 3 · A title line labelled a step (`RecipeStructurer.labelled`, `stopAt`)

On the labels path, a line labelled `step` that comes before the first line labelled `ingredient`
is taken out of the steps (left unlabelled) when at least one line labelled `step` comes after the
last line labelled `ingredient`. A page whose steps all come before its ingredients is unchanged.
`stopAt` is found from the labels after this rule, so such a line stays in the header area.

#### Part 4 · Tests

| File | Test | Checks |
|---|---|---|
| `StructuringRulesTests` (`HeaderArea`) | the labels path keeps five lines | 8 made-up lines with `stopAt` 1: the area holds the first 5 (none clutter); with `stopAt` 6: the first 6 |
| | a label line isn't title | the M3-5 test, moved: a title line followed by "Author: Made-up Cook Prep Time: 5 mins" at the same size, the model's next line, gives the title line only |
| | a breadcrumb and navigation line aren't title | area "Made-up Recipes", "Main Index \| Made-up Casseroles \| All Pages", "Made-up Bean Dish"; the model's answer is the three lines: the title is "Made-up Bean Dish" |
| `RecipeStructurerTests` | a title line labelled a step | `labelled` over "Made-up Hummus", "1 can made-up chickpeas", "Puree the made-up chickpeas."; labels step, ingredient, step: "Made-up Hummus" isn't in `steps`. Over "Mix the made-up batter.", "2 cups made-up flour"; labels step, ingredient: the step stays |

No existing test should change. If one does, say which and why.

**The suite total:** M3-3r's total (239) plus these 4: **243**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **243** tests (or the total before plus 4,
   said), with the destination string and the run's own total.
3. `git diff` touches only `HeaderArea.swift`, `RecipeStructurer.swift` (`labelled`, and where
   `stopAt` is found) and the two test files. No prompt, `instructions`, `@Guide` or
   `promptVersion` change. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty.
4. No string she reads changes. No page content in the repo: the tests use made-up lines.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

Spike run 14: Load Test Set, then plain Run All. Export to `sylantro-testpages/results/` and send
the file name. Claude scores it against run 13: the three titles, the hummus page's first step, and
no other title changed.

#### Do not

Change any prompt, `instructions`, a `@Guide` or `promptVersion`. Don't change the steps' or the
ingredients' rules beyond Part 3, `PageClutter`, `PageSplitter`, `PageTitles`, `SylantroSchemaV1`
or any synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, the
spike, the views, `Info.plist`, the entitlements, build settings or SyLib. No string she reads. No
page content in the repo (SLT-092). No network. Edit no document except §2 of this one.

---

### Task M3-3t · Sylantro · Titles stop at the ingredients

**Status: complete (246 tests); spike run 15 next.** Was: runs after M3-3s. Pops, 25 Nov 2026, decision card after run 14,
"Fix titles first (M3-3t)". Rules only: no prompt, `instructions`, `@Guide` or `promptVersion`
change (it stays 4). Spike run 15 checks it. RV-40's task (her reading in the background) comes
after this one.

**Inputs:** `00`, `00A`, `00B`, `10` §7 (runs 13 and 14) and SP-21, this document (Task M3-3s and
its row in §2), and these files: `Domain/Structuring/HeaderArea.swift` (`lines(_:stopAt:)`,
`minimumLabelledLines`, `snappedTitle` step 4), `Domain/Structuring/WrapJoiner.swift`
(`startsIngredient`, read only), `Domain/Structuring/IngredientLineParser.swift`
(`unicodeFractions`, read only), `SylantroTests/Domain/StructuringRulesTests.swift`.

*Why:* run 14. M3-3s's three titles are right, but four short cards on the labels path now take in
their first ingredient lines ("Made-up Casserole 8 large made-up potatoes"). The labels end the
area at the title, as they should; SP-21's 5-line minimum then brings in the ingredient lines below
it; the model answers with all of them as its title; and they are the same size, so step 4 of
`snappedTitle` takes in one or two. Every such line opens with a quantity and a space. The
magazine salad's and the hummus page's own lines don't ("5-minute …" has a hyphen after the
number), so neither changes.

#### Part 1 · A quantity line (`HeaderArea`)

A new `nonisolated static func startsWithQuantity(_ text: String) -> Bool`, true when the text,
trimmed, starts with:

1. a bullet (as `PageSplitter.removingBullet` finds one), or
2. a quantity followed by a space: one or more digits, a fraction such as `1/2`, a fraction
   character (`IngredientLineParser.unicodeFractions`), or digits joined to one (`1½`).

So "2 bags made-up berries", "½ c made-up sugar", "1½ c made-up port" and "2 * made-up meat" are
quantity lines; "5-minute made-up dip", "3-Bean Made-up Chili" and "Made-up Sauce" are not.

#### Part 2 · The labels path's minimum stops at a quantity line (`HeaderArea.lines`)

When `stopAt` is given and is before the 5th line, the lines from `stopAt` up to the 5th are added
only up to (not including) the first that `startsWithQuantity`. Lines before `stopAt` are taken as
now, whatever they start with. When `stopAt` is the 5th line or later, or not given, nothing
changes. Clutter, non-Latin and heading lines are still dropped after.

#### Part 3 · A title never takes in a quantity line (`HeaderArea.snappedTitle`, step 4)

In step 4, a line that `startsWithQuantity` ends the title, as a side line or a barred line does.
The start line isn't checked, so a title that opens with a number ("5-minute …") is unchanged.

#### Part 4 · Tests

| File | Test | Checks |
|---|---|---|
| `StructuringRulesTests` (`HeaderArea`) | quantity lines | `startsWithQuantity` is true for "2 bags made-up berries", "½ c made-up sugar", "1½ c made-up port", "1/2 c made-up oil", "2 * made-up meat", "• made-up salt"; false for "5-minute made-up dip", "3-Bean Made-up Chili", "Made-up Sauce", "" |
| | the labels path stops at a quantity line | lines "Made-up Sauce", "Made-up Berry Relish", "2 bags made-up berries", "1 c made-up sugar", "Made-up line 5", "Made-up line 6" with `stopAt` 1: the area holds the first 2; with `stopAt` 4: the first 4 (lines before `stopAt` are kept) |
| | a quantity line isn't title | area "Made-up Casserole", "8 large made-up potatoes", "1 stick made-up butter", all the same size; the model's answer is the three lines: the title is "Made-up Casserole" |

"the labels path keeps five lines" (M3-3s) still passes: its lines start with words. No existing
test should change. If one does, say which and why.

**The suite total:** M3-3s's total (243) plus these 3: **246**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **246** tests (or the total before plus 3,
   said), with the destination string and the run's own total.
3. `git diff` touches only `HeaderArea.swift` and `StructuringRulesTests.swift`. No prompt,
   `instructions`, `@Guide` or `promptVersion` change. `git diff -- Sylantro/Store/SylantroSchemaV1.swift`
   is empty.
4. No string she reads changes. No page content in the repo: the tests use made-up lines.
5. `git status` before and after (`00A` §9); the summary is a row at the top of §2.

#### Pops's step on device (iPhone 18 Pro)

Spike run 15: Load Test Set, then plain Run All. Export to `sylantro-testpages/results/` and send
the file name. Claude scores it against run 14: the four cards' titles back to their own line, the
three titles M3-3s fixed still right, and no other title changed.

#### Do not

Change any prompt, `instructions`, a `@Guide` or `promptVersion`. Don't change `RecipeStructurer`,
`lineKinds`, `labelled`, the steps' or ingredients' rules, `WrapJoiner`, `IngredientLineParser`,
`PageClutter`, `PageSplitter`, `PageTitles`, `SylantroSchemaV1` or any synced model,
`CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, the spike, the views,
`Info.plist`, the entitlements, build settings or SyLib. No string she reads. No page content in
the repo (SLT-092). No network. Edit no document except §2 of this one.

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

**Status: written, on hold.** Pops, 25 Nov 2026: "we will not move on to task 5 until we get single recipe reading working better". Its test total is rebased when it is released. Part 4 item 4 (a label line is a side line) and its test "a label line isn't title" moved to M3-3s; drop both from M3-5 when it is released. RV-14, RV-32, RV-35 and RV-36 ruled; `13`
v0.41's SC-22 and S-74 to S-77 proposed, with S-52m and S-73 (the agent uses them as written and
notes it).

**Inputs:** `00`, `00A`, `00B`, `10` §7 (run 8), `13` v0.41 (§4.4 "Several recipes on a page" and
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
7. *(Moved to M3-3i: the progress bar on a recipe read again.)*

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

**The suite total:** M3-3g's total (205) plus these 17: **222**.

#### Done when

1. Sylantro builds through `Sylantro.xcworkspace` with no errors and no new warnings.
2. The suite passes on the pinned destination with **222** tests (or the total before plus 17,
   said), with the destination string and the run's own total.
3. `git diff` of `RecipeStructurer.swift` and `GeneratedParts.swift` is empty; `TitleLister`'s
   `@Guide` and the structurer's `promptVersion` are unchanged; `git diff --
   Sylantro/Store/SylantroSchemaV1.swift` is empty; `PageTitle.swift`, `PageTitles.swift`,
   `HeaderArea.swift` and `RecipeCheck.swift` import only Foundation.
4. A scan of every string literal in the changed views finds only `13` §6's words (S-74 to S-77
   and S-52m new, S-45 reused), SF Symbol names, accessibility labels already named, and log text; no log line
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
| M3-3t | 27 Nov 2026 | **complete** | **git status before:** HEAD `83581c0`. Everything from M3-3j to M3-3s and the docs staged (`M `/`A `); nothing unstaged or untracked. **After:** the staged state is unchanged. `MM` `Sylantro/Domain/Structuring/HeaderArea.swift` and `SylantroTests/Domain/StructuringRulesTests.swift` (this task, unstaged), and `MM` `Docs/15_MILESTONE_3_REVIEW.md` for this row. I staged or committed nothing. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`; `xcodebuild build -workspace Sylantro.xcworkspace` `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). **Suite total:** "✔ Test run with 246 tests in 29 suites passed after 1.001 seconds."; `** TEST SUCCEEDED **`. **Total before: 243** (M3-3s), plus 3 = 246. **Built:** Part 1: `HeaderArea.startsWithQuantity(_:)` (`nonisolated static`). It's true when the trimmed text opens with a bullet (`PageSplitter.removingBullet` changes it), or with digits, digits `/` digits, a fraction character (`IngredientLineParser.unicodeFractions`) or digits joined to one, then a space. Part 2: on the labels path, the end is `max(stopAt, min(5, first quantity line among the first 5, else 5))`. Part 3: `snappedTitle` step 4 stops at a quantity line, beside side and barred lines; the start line isn't checked. **Clauses:** ✅ 1 Build, as above. ✅ 2 246 tests, as above. ✅ 3 `git diff` touches only `HeaderArea.swift` and `StructuringRulesTests.swift`. No prompt, `instructions`, `@Guide` or `promptVersion` change, and `RecipeStructurer`, `lineKinds` and `labelled` are untouched. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes, and the tests use made-up lines. ✅ 5 git status before and after, as above; this row. **Tests added (3):** "quantity lines" (the six true and four false cases), "the labels path stops at a quantity line" (`stopAt` 1 gives the first 2; `stopAt` 4 the first 4) and "a quantity line isn't title" ("Made-up Casserole"). No existing test changed, and M3-3s's "the labels path keeps five lines" passes. **Notes for Claude:** (a) **Part 2's text and its test disagree; the test was followed.** The text: "the lines from `stopAt` up to the 5th are added only up to the first that `startsWithQuantity`". Read over those lines alone, `stopAt` 4 on the test's lines adds "Made-up line 5" (index 4, not a quantity line) and gives 5 lines, but the test expects the first 4. The rule built cuts the extension at the first quantity line anywhere in the first 5 lines, never below `stopAt`: once a quantity line has been seen (here at index 2, before `stopAt`), nothing more is added. On every case in the task this matches the test (first 2, first 4; M3-3s's first 5 and first 6), and lines before `stopAt` are kept whatever they start with. If the text's reading is meant instead, the second expectation would be the first 5. (b) A fraction needs digits before the `/` (`1/2`, not `/2`), and a quantity must be followed by a space. So "5-minute", "3-Bean" and "2x" aren't quantity lines, and "2 * made-up meat" is (digits then a space). Bullets are `PageSplitter`'s (`•`, `·`, `-`, `*` followed by a space). "- made-up salt" counts; "-5°" doesn't. (c) `startsWithQuantity` is a new function rather than `WrapJoiner.startsIngredient`, which is true for a line that merely starts with a digit ("5-minute …", "3-Bean …"). That would have changed the magazine salad's and the hummus page's titles. |
| M3-3s | 25 Nov 2026 | **complete** | **git status before:** HEAD `83581c0`; every source file from M3-3j to M3-3r staged (`M `/`A `), nothing unstaged in code; `MM` Docs 00, 00B, 10, 12, 15 and README (Pops's). **After:** the staged state is unchanged. ` M` `Domain/Structuring/HeaderArea.swift` and `SylantroTests/Domain/StructuringRulesTests.swift`; `MM` `Extraction/RecipeStructurer.swift` and `SylantroTests/Extraction/RecipeStructurerTests.swift`; `MM` `Docs/15_MILESTONE_3_REVIEW.md` for this row. Nothing else changed since the start. I staged or committed nothing. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`; `xcodebuild build -workspace Sylantro.xcworkspace` `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). **Suite total:** "✔ Test run with 243 tests in 29 suites passed after 0.952 seconds."; `** TEST SUCCEEDED **`. **Total before: 239** (M3-3r), plus 4 = 243. **Built:** Part 1: `HeaderArea.lines` with `stopAt` ends at `max(stopAt, 5)`, within `maximumLines`; clutter, non-Latin and heading lines are dropped after, as before. Without `stopAt`, unchanged. Part 2: `isSideLine` takes a label line: normalized, it starts with `author`, `by`, `prep time`, `cook time`, `total time`, `active time`, `yield`, `serves`, `servings` or `makes`, then a space and more text. A printed `:` normalizes to a space, so "followed by `:` or a space" is one check. New `barredLines(in:)` finds the area's navigation lines (` | ` two or more times) and the line just before each (its breadcrumb). In `snappedTitle`, step 2 drops the model's lines equal to one of these as well as side lines, and step 4 stops at one. Part 3: `labelled`'s label logic moves into a new `lineKinds(_:labels:)`: the first label per line, then M3-3k's and M3-3m's run moves, then Part 3 (a `step` line before the first `ingredient` line is left unlabelled when a `step` line comes after the last one). `labelled` reads its sections from it, and `structure`'s step 2 finds `stopAt` from it, so a title line labelled a step stays in the header area. **Clauses:** ✅ 1 Build, as above. ✅ 2 243 tests, as above. ✅ 3 Only `HeaderArea.swift`, `RecipeStructurer.swift` and the two test files changed. `RecipeStructurer.swift`'s hunks are the `stopAt` lines in step 2 and `labelled` with its new `lineKinds`. No prompt, `instructions`, `@Guide` or `promptVersion` line is in the diff. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes, and the tests use made-up lines. ✅ 5 git status before and after, as above; this row. **Tests added (4):** StructuringRulesTests "the labels path keeps five lines", "a label line isn't title" and "a breadcrumb and navigation line aren't title" (the area with the model's three lines gives "Made-up Bean Dish"); RecipeStructurerTests "a title line labelled a step". **One existing test changed:** M3-3m's "a run of step lines labelled ingredients", its second half. Its lines are labelled step ("Whisk the made-up"), ingredient ("1/2 cup made-up sugar,"), ingredient, step ("medium bowl."). The quantity and unit keep the run as ingredients, so a `step` line comes before the first ingredient and another after the last: Part 3's shape, the same as the hummus test's. "Whisk the made-up" is now left unlabelled, and the test expects `kept.steps == ["medium bowl."]`; the first half (the run moved to the steps) and the ingredient expectation are unchanged. **Notes for Claude:** (a) **Part 3 runs after M3-3k's and M3-3m's moves, on purpose.** Run on the raw labels, it would also take the first line out of M3-3k's "a step line labelled an ingredient" and both halves of M3-3m's test, all labelled step, ingredient(s), step. Run after the moves, a run of ingredient or note lines that becomes step lines leaves no `ingredient` line, so Part 3 doesn't apply. Only a page whose ingredient lines stay ingredients (a quantity and a unit, as "1 can made-up chickpeas": `can` is a unit) is read as "title or deck labelled a step". M3-3m's quantity variant is that shape, hence the one changed test. (b) **The label-line check isn't applied to the model's first line.** `snappedTitle`'s step 2 also passes the model's own lines through `isSideLine`. So a model title that is itself a label line ("By the Sea Chowder", "Makes Ahead …") would be dropped there, against "A title that is itself such a line is unchanged". `isSideLine(_:author:sourceHost:labels:)` takes `labels: false` for the model's first line. Every later model line and every area line the title might take in are checked. (c) The navigation test is ` | ` appearing at least twice (`components(separatedBy: " | ")` gives 3 or more). A breadcrumb is only the area line directly before a navigation line. The model's lines are compared normalized against those area lines, so the answer's section name and navigation line drop out and the title starts at "Made-up Bean Dish". (d) Part 1's "5th line (index 5)" is read as the area's first 5 lines when `stopAt` is smaller, which is what the test checks (stopAt 1 gives 5 lines, 6 gives 6). The clutter and heading drop still applies after, so the area can hold fewer than 5. (e) `stopAt` now also reflects M3-3k's and M3-3m's moves. They only turn ingredient or note lines into step lines, so the set of lines labelled `ingredient` or `step` is the same as before; only Part 3 changes it. |
| M3-3r | 25 Nov 2026 | **complete** | **git status before:** Sylantro: HEAD `83581c0`. M3-3j to M3-3n staged. M3-3o to M3-3q unstaged over them (`MM` `RecipeStructurer.swift`, `RecipeStructurerTests.swift`, `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift`, `SpikeRunnerTests.swift`). ` M` Docs 00 (v0.61) and 00B (v0.20); `MM` Docs 10, 12, 15 and README (Pops's). SyLib (`sylib-swift`): clean, HEAD `9d3c9ce`. **After:** Sylantro: the staged state is unchanged. Against the diff saved at the start, only `Views/Capture/SavedPauseView.swift`, `Views/Recipe/RecipeView.swift`, `Views/Recovery/StoreRecoveryView.swift` (now ` M`) and `Views/Spike/SpikeView.swift` (`MM`, over M3-3o's change) changed, plus `MM` `Docs/15_MILESTONE_3_REVIEW.md` for this row. SyLib: ` M` `Docs/UI_COMPONENTS.md`, `Sources/SyLibUI/Components/CapsuleButton.swift`, `Tests/SyLibTests/SyLibUI/CapsuleButtonAccessoryTests.swift`. I staged or committed nothing in either. **SyLib suite** (`xcodebuild test -scheme SyLib-Package -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5'`, from `LIB/`): "✔ Test run with 1765 tests in 229 suites passed after 4.457 seconds."; `** TEST SUCCEEDED **`. **Total before: 1,764**, plus 1 = 1,765. No SyLib total was recorded anywhere, and the diff adds one test and removes none, so 1,764 is this run's total less the one added; the suite wasn't run twice. **Sylantro:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`; `xcodebuild build -workspace Sylantro.xcworkspace` `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). "✔ Test run with 239 tests in 29 suites passed after 0.914 seconds."; `** TEST SUCCEEDED **`; 239, unchanged. **Built:** Part 1 (SyLib): `CapsuleButton.Size.small`, first in the enum, with `.footnote` regular, padding 8 × 4 and stroke 1 in each of the size switches (`textStyle(of:)`, `labelFont`, `horizontalPadding`, `verticalPadding`, `borderLineWidth`); every other case unchanged. `UI_COMPONENTS.md` gets the `.small` row first in the size table, and "Four styles, five sizes" becomes "Four styles, six sizes". The test "the small size takes the footnote style, the other sizes as before" in `CapsuleButtonAccessoryTests.swift`, the file that holds `CapsuleButton`'s tests, checks `textStyle(of:)` for all six sizes. Part 2 (Sylantro): 1. `SpikeView` and `RecipeView`: the ⋯ is `MoreMenu(look: .toolbar, accessibilityLabel: "More") { … }`, with the same items, order, conditions and `disabled`; the hand-built `Menu` with an `IconButton` label is gone. 2. `StoreRecoveryView`: `CapsuleButton("Try Again", style: .primary, size: .large, fillsWidth: true, action: tryAgain)` and `CapsuleButton("Start Fresh", style: .destructive, size: .large, fillsWidth: true)`, which still sets `isConfirmingStartFresh` for its plain alert; `.controlSize(.large)` is gone. 3. `SavedPauseView`: Next Recipe is `.primary`, and Done is `CapsuleButton("Done", fillsWidth: true)` below it, with the same action. 4. `RecipeView`: `CapsuleButton("That's All of It", size: .small)`, with the same action and `disabled`. **Clauses:** ✅ 1 SyLib's suite, as above. ✅ 2 Sylantro's build and suite, as above. ✅ 3 Sylantro's `git diff` touches only the four view files; SyLib's only `CapsuleButton.swift`, `UI_COMPONENTS.md` and the one test file. A case-insensitive grep of SyLib's added lines for Sylantro, SyJong, Syderal, Score It, Game Night and Sesh finds none. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 Every title is the string it was. ✅ 5 git status before and after in both repositories, as above; this row. **Notes for Claude:** (a) **The ⋯'s VoiceOver label.** `MoreMenu`'s default `accessibilityLabel` is "Menu". The old ⋯ was a bare `ellipsis.circle` that iOS labelled itself (MT-11), as "More". To follow `LibraryView`, the task's model, both menus pass `accessibilityLabel: "More"`, the library's own string, so what VoiceOver says is unchanged and the same on all three screens. No badge, so `badgedAccessibilityLabel` isn't passed. (b) SyLib's `CapsuleButton.swift` and the test file already name SyJong in comments from earlier work ("SyJong `20` 20.11L" and others). None of those lines were touched, and none of the added lines names an app. Whether to scrub the existing ones is outside this task, which says to change only what Part 1 names. (c) `.small` isn't added to the test file's `sizes` table, which drives the accessory and old-button tests at every size. Adding it would change those existing tests, and Part 1.3 names one new test only. (d) No other SyLib component, size or style changed, and Sylantro's other views are untouched. |
| M3-3q | 25 Nov 2026 | **complete** | **git status before:** HEAD `83581c0`. M3-3j to M3-3n staged. M3-3o and M3-3p unstaged over them (`MM` `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift`, `SpikeRunnerTests.swift`); `MM` Docs 10, 12, 15 and README (Pops's). `RecipeStructurer.swift` and `RecipeStructurerTests.swift` staged, with nothing unstaged. **After:** the staged state is unchanged. Against the diff saved at the start, only `RecipeStructurer.swift` and `RecipeStructurerTests.swift` changed, now `MM`. `MM` `Docs/15_MILESTONE_3_REVIEW.md` for this row. I staged or committed nothing. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`; `xcodebuild build -workspace Sylantro.xcworkspace` `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). **Suite total:** "✔ Test run with 239 tests in 29 suites passed after 1.019 seconds."; `** TEST SUCCEEDED **`. **Total before: 236** (M3-3p), plus 3 = 239. **Built:** Part 1: `ingredientGroups` makes each answered item's names through a new private `namesFromLine`. `item` is the model's text when the parser's `rest` for the ingredient's own `rawText` (bullet removed) holds it, else that `rest`, or nil when `rest` is empty. `preparation` and `note` are kept only when `rawText` holds them. Comparison goes through a new private `comparable`: lowercased, whitespace runs as one space, trimmed. `isOptional`, `rawText`, quantity, unit and line numbers are unchanged, and no warning is added. Part 2: in the printed-headings branch, after all lines are placed, an ingredient put back on a line after the first heading with a parser quantity is dropped from the `put back` set: still put back, in place under its heading, but unflagged. Lines before the first heading, lines with no quantity, and sections with no printed heading keep their warnings. "unused ingredient line n" is unchanged. **Clauses:** ✅ 1 Build, as above. ✅ 2 239 tests, as above. ✅ 3 `RecipeStructurer.swift`'s hunks are `ingredientGroups(from:lines:)`'s doc comment and body (the `namesFromLine` call, the unflagging loop) and the two new private helpers `namesFromLine` and `comparable`, placed before `putBackIngredient`. No prompt, `instructions`, `@Guide` or `promptVersion` line is in it, and the steps' rules and `labelled` are untouched. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes, and the tests use made-up lines. ✅ 5 git status before and after, as above; this row. **Tests added (3):** "an item name from the next line" (the first ingredient's item is the parser's rest, "made-up flour, sifted", with no preparation; the second keeps "made-up sugar"; no warnings), "an item name with its quantity" and "lines put back under headings unflagged" (line 4 put back under "Made-up filling" with no warning; line 5, "- made-up sprinkles", with `put back: ingredient 3` and nothing else). **Existing tests changed (2):** (1) M3-3h's "a skipped group comes back", as the task names: it now expects no `put back` warning, the rest as before. (2) **Not named by the task:** M3-3e's "lines before the first are put back". Its lines start with the printed heading "Dough:", and the two lines it puts back by M3-3e's walk-back ("1 Tbsp. yeast", "1/2 cup water") come after that heading with quantities. Part 2 ("a line put back anywhere after the first heading") unflags them, so it now expects no `put back` warning; the grouping and order expectations are unchanged. A test of the walk-back's flags would now need a line before any printed heading, or a section with none. **Notes for Claude:** (a) **A missing model item stays nil.** Part 1 is "for each ingredient made from the model's item". When the model gives no item (nil, or an empty answer such as "none", SLT-152), `item` stays nil as before rather than becoming `rest`. That keeps "'none' fields are nil" unchanged; it failed under the first reading. If the parser's rest should fill an item the model left empty too, that's a one-line change and that test would change. (b) "Found in" is a substring test after the comparison form: the model's item must appear within `rest`, and a preparation or note within the whole `rawText`. So "flour" is kept for "made-up flour, sifted", and "1/4 cup made-up butter" isn't kept for its own line's rest ("made-up butter"). (c) The bullet is removed with `PageSplitter.removingBullet` before parsing for Part 1. The section's lines normally arrive bullet-free (SLT-149), so this rarely matters. `putBackIngredient` itself parses the line as given, and its rule is unchanged. (d) Part 2 applies to every way a line is put back after the first heading: the headings branch's own put-backs, M3-3e's walk-back and the span put-backs (RV-29). That's why test (2) changed. |
| M3-3p | 25 Nov 2026 | **complete (the device run is Pops's)** | **git status before:** HEAD `83581c0`. M3-3j to M3-3n staged. M3-3o unstaged over them (`MM` `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift`, `SpikeRunnerTests.swift`); `MM` Docs 12, 15 and README (Pops's). **After:** the staged state is unchanged. Against the diff saved at the start, only `SpikeRunner.swift`, `SpikeReport.swift` and `SpikeRunnerTests.swift` changed. `SpikeView.swift` still has only M3-3o's unstaged change. `MM` `Docs/15_MILESTONE_3_REVIEW.md` for this row. I staged or committed nothing. **Destinations:** builds for `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5` and `generic/platform=iOS`, both `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). **Suite total:** "✔ Test run with 236 tests in 29 suites passed after 0.869 seconds."; `** TEST SUCCEEDED **`. **Total before: 234** (M3-3o), plus 2 = 236. **Built:** Part 1: `totalUnitCount` = captures × 10. `stepDone(_:capture:)` adds one unit for each step: each page read, the bottom read, each `onPartDone` name, and in `findTitles` the title lister's answer and each piece. `completedUnitCount` is the new `completedUnits(processed: processedCount, stepsInCurrent:)` (= processed × 10 + min(steps, 9)), set after each step and where M3-3o set it. Steps start from 0 when a capture starts in `runAll` and when `structureWaiting` takes one up again. The subtitle is "Capture n of m, <step>": "read", "line labels", "header", "ingredients", "steps", "titles" or "pieces", with fallbacks under their part's name via `stepName`. M3-3o's ", waiting" is kept. Plain Run All has no task, so it gets no units or subtitles. Part 2: `structure` calls `findTitles` only when the attempt started outside background-test mode, so in that run's report the title fields stay nil. Part 3: `SpikeReport.backgroundTaskStartedAt` and `backgroundTaskEndedAt` (optional, synthesized `decodeIfPresent`), set at the task's launch and at its end, however it ends, with one log line `background task lasted <s> s`. Both are nil for a plain run. Part 4: `expireBackgroundTask` completes the task at once (`setTaskCompleted(success: false)`), records "expired at capture n" and the end time, ends background-test mode (no more progress or subtitles), and logs `background task expired at capture n, run goes on in the app`. The run isn't cancelled: it goes on as Run All, then `structureWaiting`. Close still cancels it through `runTask`. After an expiry, `runAllInBackground` neither overwrites the outcome nor completes the task again. **Clauses:** ✅ 1 Both builds, as above. A first generic-device build warned that `unitsPerCapture` (main-actor by the target's default isolation) was read from the `nonisolated` `completedUnits`. Making it `private nonisolated static let` fixed that, and both builds are now clean. ✅ 2 236 tests, as above. ✅ 3 Only `SpikeRunner.swift`, `SpikeReport.swift` and `SpikeRunnerTests.swift` changed. `RecipeStructurer.swift`, `TitleLister`, `ExtractionQueue`, every prompt and `Info.plist` are unchanged (their staged copies match the start). `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes. Subtitles and the new log lines hold capture numbers, step names, seconds and identifiers only, and the new fields are dates. ✅ 5 git status before and after, as above; this row. **Tests added (2):** SpikeRunnerTests "background progress by steps" ((0,0) 0, (0,3) 3, (2,4) 24, (2,15) 29) and "background task times round trip". No existing test changed. "Older results read" and "background fields round trip" pass. **Notes for Claude:** (a) **Progress can step back, by design.** When a capture ends waiting for the app, its steps leave the count (it isn't processed), so `completedUnitCount` drops by up to 9. That's the truth Part 1 asks for, and progress isn't faked. In the background test without refusals this doesn't happen; with M3-3o's waits it happens only after the last wait. (b) `onPartDone` is called off the main actor. Each step hops to it with `Task { @MainActor in … }`, carrying the capture's id, so a step that lands after its capture has moved on is dropped rather than counted for the next one. (c) The structurer gives part names `lineLabels`, `header`, `ingredients`, `steps`, `ingredients fallback` and `steps fallback`; a retry reports under its part's own name. So the subtitle maps `lineLabels` to "line labels" and drops " fallback". `partsDone` (M3-3o) keeps the names as given. M3-3o's note c wrote "line labels"; the recorded name is `lineLabels`. (d) Background-test mode is decided per attempt for Part 2. After an expiry, later captures in the same run are structured as Run All, title comparison included, as Part 4.2 says. (e) A capture cut off by the expiry ends however its call ends. A refusal after it, with the scene inactive, gets no wait (the test mode is over) and the capture waits for the app. A capture in one of M3-3o's waits at the expiry goes to wait for the app when the wait ends, unless the scene is active by then. (f) The task's expiry handler reaches the runner through `Task { @MainActor … }`, as in M3-3l. The task is completed there, before anything else runs on the main actor. |
| M3-3o | 25 Nov 2026 | **complete (the device run is Pops's)** | **git status before:** HEAD `83581c0`. M3-3j to M3-3m and `PageClutterTests.swift` (`A `) staged; my M3-3n change unstaged (`MM` `SpikeRunner.swift`); `MM` Docs 12, 15 and README (Pops's). **After:** Pops staged M3-3n's `SpikeRunner.swift` and the docs during the session. I rebuilt the starting tree from HEAD and the two saved diffs, and every staged source file matches it. My changes are unstaged: `MM` `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift`, `SpikeRunnerTests.swift`, and `MM` `Docs/15_MILESTONE_3_REVIEW.md` for this row. I staged or committed nothing. **Destinations:** builds for `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5` and `generic/platform=iOS`, both `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). **Suite total:** "✔ Test run with 234 tests in 29 suites passed after 0.909 seconds."; `** TEST SUCCEEDED **`. **Total before: 232** (M3-3n), plus 2 = 234. **Built:** Part 1: `structure` picks each refusal's wait by the scene at that moment. In front it uses `retryDelay` (30 s ×3, SLT-153). Behind, in the background test only, it uses the new `backgroundRetryDelay(afterRefusal:)` (30, 60, 120, 240, 300, 300 s, then nil). Otherwise there's no wait. One `refusals` count carries across scene changes. After the last wait, or a cancelled one, the capture waits for the app (SLT-144). During a wait the subtitle is "Capture n of m, waiting", and it goes back to "Capture n of m" when the retry starts. Each wait logs one line: `capture n: refused, scene active <Bool>, retrying in <s> s`. A refusal with no wait still logs `capture n: refused, scene active <Bool>`. Plain Run All behaves as before: with the scene inactive outside the test there's no wait, and a scene that leaves during an in-front wait still sends the capture to wait for the app. Part 2: `completedUnitCount` = `processedCount`, set after each capture in `runAll` and after each capture `structureWaiting` structures. `backgroundTask` is "completed", or "completed, n waiting for the app"; the other values are unchanged. Part 3: `CapsuleButton("BG Run All")` right after Run All, default style, the same `disabled` and the same `runTask`, so Close cancels it. The ⋯ menu item is removed, the menu keeps Add Capture and Clear, and the `runTask` comment now names BG Run All. Part 4: `Attempt.partsDone` and `Attempt.retryAfterSeconds`, optional (synthesized `decodeIfPresent`). `partsDone` comes from `onPartDone`, which the spike now passes to `structure(_:pageIDs:onPartDone:)`, collected in an `OSAllocatedUnfairLock` since it can be called off the main actor. **Clauses:** ✅ 1 Both builds, as above. ✅ 2 234 tests, as above. ✅ 3 My `git diff` touches only `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift` (Part 3: the button, the removed menu item, the comment) and `SpikeRunnerTests.swift`. `RecipeStructurer.swift`, `ExtractionQueue`, every prompt and `Info.plist` are unchanged, and the staged copies match the start. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes. "BG Run All" and the ", waiting" subtitle are spike-only English. `partsDone` holds part names only, and the new log line holds numbers and a Bool. ✅ 5 See notes (a) and (b). ✅ 6 git status before and after, as above; this row. **Tests added (2):** SpikeRunnerTests "background retries are timed and limited" and "attempt parts and waits round trip". No existing test changed. "Older results read" and "background fields round trip" pass, the latter building its `Attempt`s without the new fields. **Notes for Claude:** (a) **`progress` and expiry**, from the SDK's `BackgroundTasks.framework/Headers/BGTask.h` (`BGContinuedProcessingTask`): "``BGContinuedProcessingTask``s _must_ report progress via the ``NSProgressReporting`` protocol conformance during runtime and are subject to expiration based on changing system conditions and user input. Tasks that appear stalled may be forcibly expired by the scheduler to preserve system resources." Xcode's article "Performing long-running tasks on iOS and iPadOS": "Your app regularly reports progress of the task, which enables the system to make informed suggestions through the interface about possibly stuck tasks that a person can cancel."; "It’s important to display accurate progress, as a person can cancel a task through the Live Activity widget if the task appears to be stuck."; "The system also prioritizes the termination of tasks that reflect minimal progress, if resource constraints occur at run time." And `BGTask.expirationHandler`: "The handler may be called before the background process uses the full amount of its allocated time." So yes: a task whose progress doesn't advance may be expired. Progress isn't faked, as Part 1.5 says, so an expiry during a long wait (up to 300 s) is a likely finding and will be recorded as "expired at capture n". (b) **`rateLimited` carries no suggested wait on iOS 26.** `LanguageModelSession.GenerationError.rateLimited(_:)` holds a `Context`, which has only `debugDescription`. Its doc: "This failure can happen if you make too many requests in a short window. You can recover from this error by spacing your requests or reducing system load. The exact solution may be model dependent." In the iOS 27 SDK that case is deprecated ("Use ``LanguageModelError/rateLimited(_:)`` instead"). The replacement's `LanguageModelError.RateLimited` has `resetDate: Date?`, documented as "The date after which retrying is likely to succeed, if known." `RecipeStructurer.isRateLimit` already matches both. So on an iOS 27 device a suggested wait may come as `resetDate`. It isn't used or recorded yet, as the task says: reading it would mean `RecipeStructurer` passing the error through, which this task doesn't allow. (c) An attempt's `partsDone` lists `RecipeStructurer`'s parts only ("line labels", "header", "ingredients", "steps", their retries and fallbacks). The spike's title lister and title pieces don't call `onPartDone`, so a refusal there doesn't throw out of `structure` (it's recorded in `partErrors`, as before). (d) `retryAfterSeconds` is set on the refused attempt that is followed by a wait, and nil on a refusal that sends the capture to wait for the app. (e) A capture that ends waiting for the app is not counted in `completedUnitCount`. If many wait, the indicator stops short of the total, which is the truth Part 2 asks for. |
| M3-3n | 25 Nov 2026 | **complete (the device check is Pops's)** | **git status before:** HEAD `83581c0`. M3-3j to M3-3l and Doc 10 staged (`M `). M3-3m unstaged over them (` M`/`MM`: `PageClutter.swift`, `TestSetGroups.swift`, `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `Info.plist`, the two test files). `??` `PageClutterTests.swift`; `MM` Docs 12, 15 and README (Pops's). **After:** Pops staged everything during the session, M3-3m and `PageClutterTests.swift` (`A `) included. I rebuilt the starting tree from HEAD and the two saved diffs, and every staged source file matches it. The one change left unstaged is mine: `MM` `Sylantro/Extraction/Spike/SpikeRunner.swift`, plus `MM` `Docs/15_MILESTONE_3_REVIEW.md` for this row. I staged or committed nothing. **Destinations:** builds for `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5` and `generic/platform=iOS`, both `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). **Suite total:** "✔ Test run with 232 tests in 29 suites passed after 1.193 seconds."; `** TEST SUCCEEDED **`. **232**, as before; no test added. **Built:** Part 1: `registerLaunchHandlerIfNeeded()` returns whether a handler is registered. If not, `runAllInBackground` doesn't submit: it logs `background task registration rejected: com.syzygysoftwerksllc.Sylantro.spike.run` and runs as Run All, with `backgroundTask` "not started: registration rejected". Part 2.1: the first time the spike screen comes to the front (`sceneBecameActive`, which `SpikeView`'s `scenePhase` handler calls with `initial: true`), the runner logs `background task permitted identifiers: <list>`, or `… none`. That's once per runner, so no view changes. Part 2.2: the handler is now registered for `com.syzygysoftwerksllc.Sylantro.spike.run`, the request's own identifier, instead of the wildcard. `backgroundTaskWildcard` is removed. `Info.plist` is unchanged and keeps `…spike.*`. **Clauses:** ✅ 1 Both builds, as above. ✅ 2 232 tests, as above. ✅ 3 My `git diff` is only `SpikeRunner.swift` (33+, 8−). `Info.plist` and the target's settings are unchanged, since Part 2 found nothing wrong there. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes. The two new log lines hold identifiers only. ✅ 5 git status before and after, as above; this row. **Notes for Claude:** (a) **The installed app's plist was right.** The `generic/platform=iOS` build (derived data in `/tmp`), read with `plutil -p Sylantro.app/Info.plist`, holds `"BGTaskSchedulerPermittedIdentifiers" => [ 0 => "com.syzygysoftwerksllc.Sylantro.spike.*" ]`, before and after this change. The target's `INFOPLIST_FILE` is `Sylantro/Info.plist` with `GENERATE_INFOPLIST_FILE = YES`, and the two merge as expected. So the fault wasn't the build: the system wanted the identifiers written differently. (b) **What Apple's documentation shows** (Xcode's documentation, no network). `BGContinuedProcessingTaskRequest.init(identifier:title:subtitle:)`: "The identifier must leverage a base wildcard notation, where the prefix of the identifier must at least contain the bundle ID of the submitting application, followed by optional semantic context, and finally ending with `.*`. An example: `<MainBundle>.<SemanticContext>.*` transforms to `com.foo.MyApplication.continuedProcessingTask.*`. Thus, a submitted identifier is of the form `com.foo.MyApplication.continuedProcessingTask.HD830D`." The article "Performing long-running tasks on iOS and iPadOS", under Run the continuous background task: "To run the job, register the task request with the shared `BGTaskScheduler` using the unique `taskIdentifier`: `BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in … }`", and it submits `BGContinuedProcessingTaskRequest(identifier: taskIdentifier, …)`, the same identifier. So only the permitted identifier is a wildcard. The registration and the request both use the concrete identifier under it. M3-3m registered the literal `…spike.*`, which the device rejected ("…spike.* is not advertised"), and the submit of `…spike.run` then found no handler. (c) **What's left for the device.** That `register(forTaskWithIdentifier: "…spike.run")` matches the permitted `…spike.*` is what the documentation describes; only Pops's run confirms it. If it's rejected again, Part 1 means the app doesn't crash: the log says `background task registration rejected: …spike.run`, and the file says `not started: registration rejected`. (d) The permitted-identifiers line is logged at info level through `AppLogger` (category Spike). Like the other new lines, it starts with "background task", as Pops's step 3 looks for. (e) The generic-device build used its own derived data in `/tmp/m33n_dd`, so Xcode's build folder wasn't touched. Pops's Clean Build Folder is still the step before installing. |
| M3-3m | 25 Nov 2026 | **complete** | **git status before:** HEAD `83581c0`. Everything from M3-3j to M3-3l and Docs 10, 12, 15 and README staged (`M `), nothing unstaged, nothing untracked. **After:** the staged changes are as they were. ` M` `PageClutter.swift`, `TestSetGroups.swift`; `MM` `RecipeStructurer.swift`, `SpikeReport.swift`, `SpikeRunner.swift`, `Info.plist`, `RecipeStructurerTests.swift`, `SpikeRunnerTests.swift` (this task unstaged over the staged changes); `MM` `Docs/15_MILESTONE_3_REVIEW.md` (this row); `??` `SylantroTests/Domain/PageClutterTests.swift` (new). I staged or committed nothing. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 232 tests in 29 suites passed after 0.857 seconds."; `** TEST SUCCEEDED **`. **Total before: 224** (M3-3l), plus 8 = 232. The new `PageClutterTests` file adds the 29th suite. **Built:** Part 1: `StructuringOutcome` gains `stepRanges`, `ingredientItems` and `sectionLineCounts`, filled after each ingredients and steps answer. The spike copies them into `SpikeCaptureResult` (optional fields, decoded with `decodeIfPresent`, numbers only). Part 2 in `steps(from:lines:putsBackSkipped:)`. Part 3 in `labelled`, with the helper `startsWithQuantityAndUnit` (`IngredientLineParser.parse`: quantity and unit both found). Part 4 in `isClutter`, with the helper `isWebAddressWord`. Part 5: `TestSetGroups.joinedRuns` = 5–6, 7–8, 16–17, 26–30, each joined only when every page is present. Part 6: `Info.plist` holds `com.syzygysoftwerksllc.Sylantro.spike.*`, the handler is registered for `SpikeRunner.backgroundTaskWildcard`, and the request keeps `…spike.run`. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). ✅ 2 232 tests, as above. ✅ 3 Against the staged state, which hasn't changed since the start: `Info.plist`'s diff is the one value (`…spike.run` → `…spike.*`). `RecipeStructurer.swift`'s hunks are the three outcome fields; the four `record` calls in `structure` and the two `record` helpers (what the outcome passes to the spike); `labelled`, its doc comment and its new helper; and the steps block (doc comment, body, `StepPiece.followsLabel`, and the helpers `methodEnds`, `endsMethod`, `isHeadingShapedLine`). No prompt, `instructions`, `@Guide` or `promptVersion` line is in it, and `ingredientGroups(from:lines:)` is untouched. `PageClutter.swift` changes only `isClutter` (a doc line and the new check) and the new helper. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes. The tests use made-up lines, and the new spike fields hold numbers only. ✅ 5 git status before and after, as above; this row. **Tests added (8):** RecipeStructurerTests "a range over a label and a heading", "a first step after a label is put back", "a heading on a numbered page", "where the method ends", "a run of step lines labelled ingredients"; PageClutterTests "a misread web address" (a new file: none existed); SpikeRunnerTests "a run of five pages is one capture", "step and ingredient answers recorded". **One existing test changed.** M3-3k's "a step line labelled an ingredient" failed under Part 3: its middle line "2 cups of the nuts until" starts with a quantity and a unit, so Part 3 now keeps it in `ingredients`. Its middle line is now "all of the nuts until", so it still checks that one line between step lines moves, as an ingredient and as a note. "The test set groups by page ID" and "older results read" pass unchanged. **Notes for Claude:** (a) Part 2.1. A range's lines are taken out when they are markers, colon headings or at or after the method's end. What's left must number 1 to 15 and touch no line already used, else the range is dropped with `step lines out of range`. A range out of bounds (first below 1, last past `lines`, first after last) is still dropped as before. `keptSpan` (M3-3k rule 4) runs over the kept lines only. (b) Part 2.2. The first line (not empty, not clutter) after a marker or a heading carries `followsLabel`, and a skipped one is put back wherever it is. A marker and then a heading ("Step 1", "Mix it:") both count. The line after them is first in its group, so it starts a step. (c) Part 2.3. A one-line piece with rule 5's shape (its step number removed) doesn't join on a numbered page, and nothing joins onto one; rule 5 then names the steps after it. (d) Part 2.4. The method ends at the first line in `lines` that reads as one of the five phrases (trimmed, any case, less a trailing `:`). On a numbered page, lines from there on aren't counted. A range that starts at or after the end has nothing left, so it is dropped with `step lines out of range`, as rule 1 says. (e) Part 3. A run is the consecutive `ingredient`/`note` lines among the labelled lines (clutter, headings and unlabelled lines skipped, as M3-3k). Ingredient and note lines can mix in one run. A run of 4 or more stays as labelled. The quantity and unit check uses `IngredientLineParser.parse` on the line less its bullet: both `quantity` and `unit` must be found. "25 minutes." has no unit (the parser has no time units). (f) Part 4. Words are split on spaces only, as the task says, lowercased, with trailing Unicode punctuation stripped. So "madeupsite.com." counts, but a word with a leading bracket doesn't lose it. A step line that mentions a web site is now clutter and left out of its step. (g) Part 1. A fallback's answer replaces its part's numbers and line count (`ingredients` counted over the wrap-joined whole page, `steps` over every readable line), so the numbers always match the count beside them. `nameLine` is recorded as the model gave it, 0 for none. (h) Part 6. The wildcard is used for `Info.plist` and the registration, as written. That a concrete `…spike.run` request reaches the wildcard's handler is Apple's documented notation; only the device run confirms it. (i) `PageClutterTests.swift` is new, in `SylantroTests/Domain/`. The project's synchronized folders picked it up (the 29th suite). Inputs read: `10` §7 runs 10 and 11, and the M3-3j, M3-3k and M3-3l rows. |
| M3-3l | 25 Nov 2026 | **complete (spike build; the device run is Pops's)** | **git status before:** HEAD `83581c0`. `M ` (staged): `ReviewFlag.swift`, `GeneratedParts.swift`, `ReviewFlagTests.swift`. `MM`: `RecipeStructurer.swift`, `RecipeStructurerTests.swift` (M3-3k unstaged over M3-3j), and Docs 10, 12, 15 and README (Pops's). **After:** ` M` `Extraction/Spike/SpikeRunner.swift`, `Info.plist`, `Views/Spike/SpikeView.swift`, `SylantroTests/Extraction/SpikeRunnerTests.swift`; `M ` `Extraction/Spike/SpikeReport.swift`. Pops staged my edit to `SpikeReport.swift` mid-session, so its whole diff is staged and is only this task's fields. Also `M ` `RecipeStructurer.swift`, `RecipeStructurerTests.swift` and Doc 10, which Pops staged during the session with no unstaged change left; `MM` Docs 12, 15 (this row) and README. I staged or committed nothing. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 224 tests in 28 suites passed after 0.946 seconds."; `** TEST SUCCEEDED **`. **Total before: 223** (M3-3k), plus 1 = 224. **Built:** `Info.plist` gets `BGTaskSchedulerPermittedIdentifiers` = [`com.syzygysoftwerksllc.Sylantro.spike.run`]. The ⋯ menu gets **Run All in Background (Test)**, enabled when Run All is. `SpikeRunner.runAllInBackground()`: 1. registers the launch handler once, on the main queue; 2. submits a `BGContinuedProcessingTaskRequest` (title "Spike run", subtitle "Starting", `strategy = .fail`, default resources, so no GPU); 3. waits for the launch, then runs `runAll(in: task)`. In the run, `progress.totalUnitCount` = captures and `completedUnitCount` += 1 as each capture ends, however it ends. The subtitle is "Capture n of m". On expiry the run is cancelled and the report records "expired at capture n". At the end, `setTaskCompleted(success:)` is called, true unless cancelled or expired. A submit that throws runs Run All plain, with `backgroundTask` = "not started: <error>". In `structure`, test mode skips the scene-active check. A refusal while active is still retried (SLT-153); a refusal while inactive is recorded and the capture waits for the app (SLT-144). `read` is unchanged apart from recording `readWhileInBackground`, and plain Run All is unchanged. The report has `backgroundTask`, and each capture has `readWhileInBackground` and `structureAttempts` (`sceneActive`, `outcome`, `millis`, `at`). **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). ✅ 2 224 tests, as above. ✅ 3 Against a baseline of `git diff` and `git diff --cached` saved at the start, my changes are only in `SpikeRunner.swift`, `SpikeReport.swift`, `SpikeView.swift`, `Info.plist` (the one key; no background mode, see (a)) and `SpikeRunnerTests.swift`. `ExtractionQueue.swift` has no change. `RecipeStructurer.swift` has no unstaged change, and its HEAD diff has no background code. No prompt was touched. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes. The new label, the task's title and subtitles, and the report values are spike-only English; there's no string catalog. The new fields and log lines carry no recipe text (see (e)). ✅ 5 git status before and after, as above; this row. **Test added (1):** SpikeRunnerTests "background fields round trip". "Older results read" also checks that the two capture fields decode as nil. **Notes for Claude:** (a) **No `UIBackgroundModes` value added.** The SDK headers (`BackgroundTasks.framework` in the iOS 27.2 simulator SDK) and Xcode's documentation name a mode for `BGAppRefreshTask` (`fetch`) and `BGProcessingTask` (`processing`), but none for `BGContinuedProcessingTask`. (b) **The identifier may be refused.** Xcode's documentation for `BGContinuedProcessingTaskRequest.init(identifier:title:subtitle:)` says the identifier "must leverage a base wildcard notation": the bundle ID, then optional context, then `.*` (for example `<bundle>.spike.*`), with a concrete identifier submitted under it. The SDK header says "ought to". The task's exact `com.syzygysoftwerksllc.Sylantro.spike.run` is used as written, in both `Info.plist` and the request. If iOS rejects it on device, the submit throws `notPermitted`, the run goes ahead as Run All, and the report says `not started: …`. If that happens, the fix is `com.syzygysoftwerksllc.Sylantro.spike.*` in `Info.plist` and the registration, with the request's identifier under it. That's for Claude and Pops to rule; I didn't change the key beyond what Part 1 allows. (c) The simulator can't show whether the task runs: the SDK's `unavailable` error lists Simulator among the causes. Only Pops's device run answers it. (d) **APIs.** The sync `submit(_:)` is used. The SDK marks it deprecated from iOS 27.0, but the deployment target is 26.5, so it gives no warning. The async replacement is iOS 27 only. (e) **Wiring.** The handler is registered when first needed: continued-processing registrations are exempt from the before-launch rule, and a second registration of an identifier kills the app, so a static flag guards it. The handler runs on the main queue and resumes a continuation kept before the submit. The run inside the task is its own `Task`, awaited through `withTaskCancellationHandler`, so Close's existing `runTask?.cancel()` reaches it and the expiry handler can cancel it. A launched task nobody waits for is completed at once with `false`. A cancel or expiry that lands mid-structuring may end that capture as a failure, with an attempt of `failed: <cancellation>`. `failed: <error>` uses `String(describing:)`, as the existing `error` field does. (f) **Field choices.** An attempt's `millis` spans the whole attempt, from its start to its outcome, including the spike's title pass on success. `readWhileInBackground` is true if the scene was inactive at the start or after any page's read. Attempts are recorded in plain runs too. `backgroundTask` is omitted from a plain run's file, since nil isn't encoded. The new optionals decode through Swift's synthesized `decodeIfPresent`, as the M3-5s title fields do, and `SpikeReport.decoded(from:)` (ISO 8601 dates) was added for the round trip. (g) After a background run, captures still waiting for the app are structured when Sylantro comes back to the front, as now, with their attempts recorded. The task is already ended by then ("completed"). (h) This document moved from v0.77 to v0.78 (and a v0.79 log row) during the session: run 11 scored and M3-3m written and revised. M3-3l's text is unchanged, so nothing was redone. |
| M3-3k | 25 Nov 2026 | **complete** | **git status before:** HEAD `83581c0`; M3-3j's five files staged (`M `), with ` M` `Docs/10_ACCURACY_TEST_SET.md`, `Docs/12_IMPLEMENTATION_PLAN.md` and `Docs/README.md`, and `MM` `Docs/15_MILESTONE_3_REVIEW.md` (Pops's). **After:** `M ` `ReviewFlag.swift`, `GeneratedParts.swift`, `ReviewFlagTests.swift`, `Docs/12_IMPLEMENTATION_PLAN.md`; `MM` `RecipeStructurer.swift` and `RecipeStructurerTests.swift` (this task's changes unstaged, over M3-3j's staged ones); `MM` `Docs/10_ACCURACY_TEST_SET.md` and `Docs/README.md`; `MM` `Docs/15_MILESTONE_3_REVIEW.md` (this row unstaged). Pops staged the docs and edited 10 and the README during the session; I edited neither. Nothing staged or committed by me. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 223 tests in 28 suites passed after 1.102 seconds."; `** TEST SUCCEEDED **`. **Total before: 216** (M3-3j), plus 7 = 223. **Built:** Part 1 in `labelled`; Part 2's six rules in `steps(from:lines:putsBackSkipped:)`, with private helpers `StepPiece`, `endsSentence`, `isFragment`, `isHeadingShaped`, `isStepMarker`, `droppingStepWord` and `isDigit`, and `stepNumberLength` taking `Step n`. `startsWithStepNumber` is gone, since nothing else used it. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's appintentsmetadataprocessor line). ✅ 2 223 tests, as above. ✅ 3 `git diff` (against M3-3j's staged file) of `RecipeStructurer.swift` touches only `labelled` (lines 341 to 360) and the steps block: `steps(from:)`'s doc comment and body, and its helpers. No prompt, `instructions`, `promptVersion` (still 4) or `@Guide` line is in it, and `GeneratedParts.swift` has no unstaged change. `git diff HEAD -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes; tests use made-up lines. ✅ 5 git status before and after, as above; this row. **Tests:** the 7 in Part 3's table, under the same names. "A skipped step line" now has a fourth line, "Cool it a little.", with range 4–4, and expects three steps with `put back: step 2`, as Part 3 says. No other existing test changed. **Notes for Claude:** (a) How the rules are ordered. Rules 5 and 6 run after the joins, as written. Rule 3's "step before doesn't end with `.`, `!` or `?`" alone would join "Warm the …" onto "Campfire Method" and "Stir the …" onto ": 10 min", and Part 3's tests expect neither. So a step before that is heading-shaped and one line, or a fragment, doesn't count as left open: only a line starting lowercase joins it. Rule 2's numbered-page join has no such check. (b) Markers. A marker is digits then `.` or `)`, or `Step` (any case) and a number, either with an optional `:`. A `Step n` line with text starts a step when the number is followed by a space (after an optional `:` or `.`), and `Step n` is removed. A lone "4" with no mark isn't a marker, but rule 6 drops it. A marker affects only the next line that isn't empty, clutter or a heading. Markers count wherever they are, in a range or skipped, and in the fallback too. (c) Rule 2 counts every line in `lines`. In the whole-page fallback, an ingredient line such as "2 Eggs" (digits, a space and a capital: M3-3j's number pattern) can count toward a numbered page, as written. Worth watching in run 11. (d) A numbered line or a line after a marker never joins the step before, not even a skipped one. That extends rule 3's "doesn't start at a step number or a marker" to skipped lines, which M3-3j joined on case alone. (e) Rule 4's "after the first kept step and before the last one's last line" is read as strictly between the smallest kept range's first line and the largest one's last line. Kept means the ranges that pass the range checks, before rules 5 and 6. (f) Rule 5. "Every word starting with a capital" is checked on each whitespace-separated word, and "no digit" means no number character. "Followed by another step in its group" means the next built step has the same group before rule 6. The name holds until the group changes or another no-colon heading. A rule-5 heading that was put back gives no `put back` warning. (g) Part 1 skips clutter, `PageSplitter` headings and `IngredientHeadings` lines when finding the nearest labelled lines, so a heading between two step lines doesn't stop the change. Lines labelled `header` or `other` do count as labelled, so they stop it. (h) Run 10 in `10` §7 was read as input. Its fifth fault (a step across two pages has no position) isn't in this task, and I didn't touch it. Run 11 is Pops's; I didn't run it. |
| M3-3j | 25 Nov 2026 | **complete** | **git status before:** clean, HEAD `83581c0`. **After:** ` M` `Docs/15_MILESTONE_3_REVIEW.md` (this row), `Domain/Structuring/ReviewFlag.swift`, `Extraction/GeneratedParts.swift`, `Extraction/RecipeStructurer.swift`, `SylantroTests/Domain/ReviewFlagTests.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`; nothing staged or committed. **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 216 tests in 28 suites passed after 1.046 seconds."; `** TEST SUCCEEDED **`. **Total before: 209**, plus 7 = 216. **Built:** `GeneratedStepLines`/`GeneratedStepRange` replace the steps types; the steps part asks `"The method lines of a recipe, numbered:"` + `numbered(section lines)` (same cap, 2 000), the fallback the same over every readable line; `RecipeStructurer.steps(from:lines:putsBackSkipped:)` maps the ranges; `assemble` takes `[Step]?` and `makeSteps` is gone; `promptVersion` 4. `ReviewFlag` maps `put back: step n` to `putBack` on that step (`.steps` if there is no step n). **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source (only the build tool's existing appintentsmetadataprocessor line). ✅ 2 216 tests, as above. ✅ 3 `GeneratedParts.swift`'s diff is the steps types only (lines 62 to 78). `RecipeStructurer.swift`'s hunks are: `stepsPromptIntro`; step 5 and its fallback; a `stepsPrompt` helper beside `ingredientsPrompt`; `assemble`'s `steps` parameter and `steps ?? []`; `promptVersion: 4`; `makeSteps` replaced by `steps(from:lines:)` and its private helpers. `instructions`, `headerPromptIntro`, `ingredientsPromptIntro` and the line-label prompt don't appear in the diff. `git diff -- Sylantro/Store/SylantroSchemaV1.swift` is empty. ✅ 4 No string she reads changes: `ReviewFlag`'s lines are as before, and `put back: step n` reuses `putBack`'s line. The new tests use made-up lines only. ✅ 5 git status before and after, as above; this row. **Tests added (7):** RecipeStructurerTests "steps by lines", "a hyphen at a line's end", "a skipped step line", "a printed number starts a step", "a step heading" and "bad step ranges"; ReviewFlagTests "a step put back". Existing tests changed: "parts assemble with rule fields" now passes `[Step(index: 0, text: "Boil the water.")]`, and it and "unreadable areas and warnings reach the recipe" pin `promptVersion == 4`. **Notes for Claude:** (a) Range rules the task left open: a range is out of range when its first line is below 1, its last line is past the end, its first line is after its last, it spans more than 15 lines (`maximumStepLines`, as the ingredients' 15), or it touches a line already used or a heading. Each one dropped gives one `step lines out of range`. (b) A printed step number is digits then `.` or `)` and a space, or digits, a space and a capital letter. A line starting with one inside a range starts a new step, and the number is removed from the text. (c) A skipped line is one not used, not a heading, not empty and not `PageClutter.isClutter`. It joins the step before when it starts lowercase or that step doesn't end with `.`, `!` or `?`. Otherwise, or when there's no step yet in its group, it starts a step of its own with `put back: step n` (n counted after empty steps are dropped). (d) In the whole-page fallback (`putsBackSkipped: false`), skipped lines are left out, so the title, ingredients and notes aren't put back as steps. Its range warnings follow `steps from whole page`. (e) Clutter lines inside a range are left out of the step's text. Lines are trimmed and joined with a space; a line ending in `-` joins the next with no space, keeping the `-` (as the test asks: "golden-brown."). (f) Warnings come in this order: out of range in the model's order, then put back in step order. `step lines out of range` has no flag of its own and reads as `other` ("Check this."), as any unknown warning does; the task didn't name one. (g) Run 9 in `10` §7 was read as input. Its scoring (10 steps not on the page; step counts off the key on 7 pages) is for Pops's run 10, which I did not run. |
| M3-3i | 25 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 209 tests in 28 suites passed after 0.851 seconds."; `** TEST SUCCEEDED **`. **Total before: 209** (after M3-3g and M3-3h); no test added, so 209 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 209 tests, the same as before. ✅ 3 this session changed only `Sylantro/Views/Recipe/RecipeView.swift`: one hunk, `@@ -514,0 +515,15 @@` in `headerSection`. The file's other unstaged hunk (`PageStrip.load`) is M3-3g's, from before this session. `git diff HEAD --stat -- Sylantro/Store/SylantroSchemaV1.swift`: empty. ✅ 4 a Python scan of the string literals on this session's added lines finds only S-45 "Reading…". ✅ 5 git status before and after: the same paths and states (` M` `RecipeView.swift`'s working copy already had M3-3g's change, so it stays `MM`); this row. **What was built:** part 1 `RecipeView.headerSection`: while `extractionQueue?.currentRecipeID` is this recipe's ID, the recipe has an `extraction` and she isn't in Edit, a whole-recipe line sits first under the title. It holds S-45 "Reading…" in secondary, and M3-3f's bar under it (`ProgressView(value: progress)`, the palette's accent, full width, `.animation(.easeInOut, value:)`), not tinted. It goes when the job ends (`currentRecipeID` nil), and the fields then show the new reading from the store. A recipe not read yet keeps M3-3f's line and bar (`unreadContent`), unchanged; Read Again stays disabled while reading (M3-3c). **Files:** `Sylantro/Views/Recipe/RecipeView.swift`; this document (this row only). `ExtractionQueue.swift` read, not changed. No queue, structurer, prompt, `promptVersion`, `SylantroSchemaV1`, synced model, `CaptureRecorder`, `RecipeEditor`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no new words beyond S-45; no popover or confirmation dialog; no network. **Git status before** (branch `milestone-3`, HEAD `d7814a6`): staged M3-3e, M3-3f and Pops's docs; unstaged M3-3g and M3-3h (as at the end of the M3-3g rows below). **After:** the same. **Git:** `git status --short` (×2), `git log --oneline -3`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (the three unchanged since this session read them: v0.60, v1.15, v0.19), `git diff -U0 -- Sylantro/Views/Recipe/RecipeView.swift`, `git diff HEAD --stat -- Sylantro/Store/SylantroSchemaV1.swift`. **Notes, for Claude to confirm:** (a) "Styled as the other whole-recipe lines" is taken as their secondary text color and place under the title, without their `exclamationmark.triangle`, which marks a warning, and without a tint, as part 1.1 says. (b) The bar shows only while `progress` isn't nil, so while a refusal waits the line shows "Reading…" alone, as M3-3f's does. (c) It is in the list's header section, above the page-2 warning and the other whole-recipe lines, below the title (and below SC-16's hint when that shows, since the hint sits above the title). **Next:** Pops's check on device (iPhone 18 Pro, then iPad), items 1 and 2. Not run in this session |
| M3-3g (re-run) | 25 Nov 2026 | **complete, nothing rebuilt** | Asked again against v0.69, expecting 206 + 3 = 209. **M3-3g was already built**, in the session whose row is the next one below (M3-3g, 25 Nov 2026), and its changes are in the tree, unstaged (` M` `PhotoFiles.swift`, `PhotoEncoding.swift`, `PagePhotoView.swift`, `PagePhotoViewer.swift`, `PhotoFilesTests.swift`; `MM` `RecipeView.swift`). So **the total before this run was 209, not 206**, and building it again would only duplicate it. v0.69's only change is Claude's check of M3-3h; M3-3g's text is the same (its status line still reads "ready, not started" until it is checked). Nothing was rebuilt or edited but this row. **Verified instead:** **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 209 tests in 28 suites passed after 0.993 seconds."; `** TEST SUCCEEDED **` (206 + 3, as expected after M3-3h and M3-3g). **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace …`: `** BUILD SUCCEEDED **`, no warnings from source. ✅ 2 209 tests passed. ✅ 3 `grep -rn "contentsOfFile\|fullImage(\|displayImage(" Sylantro/Views/` finds only `PagePhotoView.swift:70` and `:71`, inside `loadImage`. `git diff HEAD --stat -- Sylantro/Store/SylantroSchemaV1.swift`: empty. SyLib's `git status --short`: clean. ✅ 4 no string she reads changes (unchanged since the row below). ✅ 5 git status before and after: the same as at the end of the row below, with this document still `MM` (this row added). **Git:** `git status --short` (×2), `git log --oneline -3`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (the three unchanged since this session read them: v0.60, v1.15, v0.19), `git diff HEAD --stat -- Sylantro/Store/SylantroSchemaV1.swift`, `git -C /Users/wayne/GIT/Syzygy/sylib-swift status --short`. **Notes, for Claude to confirm:** (a) The row below holds M3-3g's results and notes a to h; this row only confirms them against the current tree. **Next:** Claude's check of M3-3g against that row, then Pops's check on device, items 1 to 4 |
| M3-3g | 25 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 209 tests in 28 suites passed after 0.857 seconds."; `** TEST SUCCEEDED **`. **Total before: 206** (`@Test` count at session start, after M3-3h, which ran before this task, note h), so 206 + 3 = 209 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 209 tests (206 + 3) on the pinned destination. ✅ 3 `grep -rn "contentsOfFile\|fullImage(\|displayImage(" Sylantro/Views/` finds only `PagePhotoView.swift:70` and `:71`, inside `PagePhotoView.loadImage`. `git diff HEAD --stat -- Sylantro/Store/SylantroSchemaV1.swift`: empty. `git -C …/sylib-swift status --short`: clean, no change in SyLib. ✅ 4 no string she reads changes. The literals added are the logger's category "Photos", the cache key's `#` and "full", and the log line `decode failed: ‹file name› at ‹size›`, which holds only the file name and a pixel size. ✅ 5 git status before and after below; this row. **What was built:** part 1 `PhotoEncoding.displayLongEdge = 2_560`. `PhotoFiles.displayImage(of:maxPixelSize:)`, as `fullImage` with the long edge the smaller of `maxPixelSize` and the file's; both share one private `decoded(_:maxPixelSize:)`, and `fullImage` is unchanged. `PagePhotoView.loadImage(_:from:maxPixelSize:)`, `maxPixelSize` defaulting to `displayLongEdge`, nil for full size, works like this. It looks first in SyLib's `ImageCache.shared.memoryImage(for:)`, keyed by the file's URL plus `#‹size›` (`#full` for full size). Otherwise it decodes off the main actor with `displayImage` (or `fullImage`) and stores the image with `toDisk: false` (`14A`). Every page view uses it: `PageStrip` (the strip and the edit sheet's crop), the pages column and M2's pages (`PagePhotoView`) at display size, and `PagePhotoViewer` at full size. Part 2 `PhotoFiles.isOnDevice(isUbiquitous:status:)` (not ubiquitous, `.current` or `.downloaded`: true; `.notDownloaded` or no status: false), used by `availability`; the placeholder rule is unchanged. Part 3 `PagePhotoView.loadImageRetrying(_:from:maxPixelSize:)`, used by all three loaders, works like this. It tries every 2 seconds, keeping the size while the file is downloading. When the file is `.available` and the decode gives nil, it logs `decode failed: ‹file name› at ‹size›` and asks for half the size next, down to `thumbnailLongEdge`. Part 4: 3 tests in `PhotoFilesTests`, with made-up 4000 × 3000 images. **Files:** `Sylantro/Domain/Capture/PhotoEncoding.swift`, `Sylantro/Capture/PhotoFiles.swift`, `Sylantro/Views/Recipe/PagePhotoView.swift`, `Sylantro/Views/Recipe/PagePhotoViewer.swift`, `Sylantro/Views/Recipe/RecipeView.swift` (`PageStrip.load` only), `SylantroTests/Capture/PhotoFilesTests.swift`; this document (this row only). Inputs `05` and `14A` relied on as the task states them; not otherwise changed. No prompt, `promptVersion`, `SylantroSchemaV1`, synced model, photo writing or files, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no string she reads; no network. **Git status before** (branch `milestone-3`, HEAD `d7814a6`): staged M3-3e and M3-3f and Pops's docs (`M `/`A `/`MM` as at M3-3h's end), with M3-3h unstaged (`MM` `RecipeStructurer.swift`, `RecipeStructurerTests.swift`; `??` `IngredientHeadings.swift`, `IngredientHeadingsTests.swift`). **After:** the same, plus ` M` on `PhotoFiles.swift`, `PhotoEncoding.swift`, `PagePhotoView.swift`, `PagePhotoViewer.swift` and `PhotoFilesTests.swift`, and `RecipeView.swift` now `MM`. **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -3`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (the three unchanged since this session read them: v0.60, v1.15, v0.19), `git diff HEAD --stat -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff -U0 -- Sylantro/Views/ Sylantro/Capture/`, `git -C /Users/wayne/GIT/Syzygy/sylib-swift status --short`. **Notes, for Claude to confirm:** (a) **View Pages is the viewer.** Part 1.4 lists "View Pages at display size" and "`PagePhotoViewer` at full size", but ⋯ › View Pages opens `PagePhotoViewer`. So the viewer, View Pages included, decodes at full size for her pinch to 6×; the strip, the crop and the pages column are at display size. (b) The full-size cache key ends `#full`. (c) A failed decode logs one line per failed try. After a failure at full size the next try is `displayLongEdge`, then halves to the 400 floor, which it keeps. (d) The viewer now retries until it has an image (before, one try). (e) `availability`: a file whose ubiquity can't be read (`isUbiquitous` nil) counts as on the device, as before. An iCloud file with no status now counts as not on the device (before, it read `.available`), so it is asked for. If iCloud refuses the request it still reads `.available`, as before. (f) `preparingForDisplay()` is no longer called: ImageIO's thumbnail is already a decoded bitmap. (g) This document is v0.68, not the v0.66 the request named; M3-3g's text is the same. (h) This task ran after M3-3h, not before it as M3-3h's status line expected; they touch different files, so the totals are simply 206 then 209. **Next:** Pops's check on device (iPhone 18 Pro, then iPad), items 1 to 4. Not run in this session |
| M3-3h | 25 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 206 tests in 28 suites passed after 0.863 seconds."; `** TEST SUCCEEDED **`. **Total before: 202** (`@Test` count at session start, after M3-3f; M3-3g not built, note a), so 202 + 4 = 206 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 206 tests (202 + 4) on the pinned destination. ✅ 3 `IngredientHeadings.swift:1` is `import Foundation`, its only import. `git diff -U0 -- Sylantro/Extraction/RecipeStructurer.swift` (this session's lines; M3-3e and M3-3f were staged by Pops before it): three hunks, all in `ingredientGroups(from:lines:)`, its doc comment and its grouping at the end, with no line holding `promptVersion`, `instructions`, `PromptIntro`, `@Guide` or `TokenCap`. `git diff HEAD --stat` of `SylantroSchemaV1.swift` and `GeneratedParts.swift`: empty. ✅ 4 no string she reads changes (no view changed in this session: `git diff --stat -- Sylantro/Views/` is empty); the tests use made-up lines only. ✅ 5 git status before and after below; this row. **What was built:** part 1 `Domain/Structuring/IngredientHeadings.swift`: `lines(_:)` gives the numbers (from 1) of the section's lines that are group headings: trimmed, ending with `:`, 2 to 60 characters before it, at least half letters, not `WrapJoiner.startsIngredient`, and `PageSplitter.heading` nil. Part 2 `ingredientGroups`: when the section has a heading line, after the model's items and RV-29's put-backs as before, (1) every line still unused after the first heading that starts like an ingredient is put back (parsed, `put back: ingredient n`); (2) every ingredient goes under the last heading before its first line, those before the first heading in a first group with no name, a heading with nothing under it making no group, each group named by its heading less the `:` (the model's names unused), in line order; (3) heading lines count as used. With no heading line, the model's groups as before. `SourceLocator` still places each name (`nameBox`). Part 3: 4 tests as the table (`RecipeStructurerTests` 3; `IngredientHeadingsTests` 1, new), made-up lines. **Files:** new `Sylantro/Domain/Structuring/IngredientHeadings.swift`, `SylantroTests/Domain/IngredientHeadingsTests.swift`; changed `Sylantro/Extraction/RecipeStructurer.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`; this document (this row only). Read and not changed: `WrapJoiner.swift`, `PageSplitter.swift`, `IngredientGroup.swift`. No prompt, `promptVersion`, `SylantroSchemaV1`, synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, view, `Info.plist`, entitlement, build setting or SyLib change; no page content; no network. **Git status before** (branch `milestone-3`, HEAD `d7814a6`): staged M3-3e and M3-3f and Pops's docs (`M `/`A ` on `ReadingProgress.swift`, `ExtractionQueue.swift`, `RecipeStructurer.swift`, `LibraryView.swift`, `RecipeRow.swift`, `RecipeView.swift`, `ReadingProgressTests.swift`, `RecipeStructurerTests.swift`, `Docs/16_FEATURE_IDEAS.md`; `MM` on `Docs/12_IMPLEMENTATION_PLAN.md`, `Docs/13_SCREENS.md`, this document, `Docs/README.md`). **After:** the same, with `RecipeStructurer.swift` and `RecipeStructurerTests.swift` now `MM`, and `??` on `IngredientHeadings.swift` and `IngredientHeadingsTests.swift`. **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -3`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (the three unchanged since this session read them: v0.60, v1.15, v0.19), `git diff -U0 -- Sylantro/Extraction/RecipeStructurer.swift`, `git diff HEAD --stat -- Sylantro/Store/SylantroSchemaV1.swift Sylantro/Extraction/GeneratedParts.swift Sylantro/Views/`, `git diff --stat -- Sylantro/Views/`. **Notes, for Claude to confirm:** (a) **M3-3g hasn't run.** M3-3h says it runs after M3-3g ("209 after M3-3g's 205"), but M3-3g ("Page photos that go blank") is still "ready, not started" and the suite stood at 202. M3-3h touches only the structurer and Domain, not the views M3-3g changes, and its total is "the total before plus 4", so it was done as asked: 202 + 4 = 206. With M3-3g after it, the total will be 209. (b) This document is v0.68, not the v0.67 the request named; 0.68 only adds Task M3-3i, and M3-3h's text is unchanged. (c) A heading's group name is its whole heading less the `:` (up to 60 characters). The model's `maximumGroupNameLength` (40) doesn't apply to it. (d) With headings, the earlier rules still run first (the walk back, the heading before a span, the put-back inside a span) and only decide which lines are used; the groups then come from the headings alone. Two of the model's groups under one heading become one group, and a model group name that isn't a heading line is dropped. (e) Part 2.1's put-back takes every unused ingredient-like line after the first heading, to the section's end, including one after the last group's last item; RV-29's line outside a group stays out only when the section has no heading. The M3-3a test "a line outside a group stays out" has no heading, so it holds. **Next:** Pops's check on device (iPhone 18 Pro), items 1 to 3, after ⋯ › Read Again on the kolaches. Not run in this session |
| M3-3f | 25 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 202 tests in 27 suites passed after 0.833 seconds."; `** TEST SUCCEEDED **`. **Total before: 199** (`@Test` count at session start, after M3-3e), so 199 + 3 = 202 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source. Two warnings this session caused on the way (a `[weak self]` in the part callback) were fixed by capturing the queue plainly (note f). The one warning left is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 202 tests (199 + 3) on the pinned destination. ✅ 3 `ReadingProgress.swift:1` is `import Foundation`, its only import. `git diff HEAD -U0 -- Sylantro/Extraction/RecipeStructurer.swift`: this session's hunks (lines 92 to 297) add only the `onPartDone` parameter, to the public `structure`, the private `structure(…into:)` and `call`, its six call sites, and its calls in `call`. The hunks from line 364 on are M3-3e's, not yet committed (`ingredientGroups` and `putBackIngredient`). The only changed lines naming `TokenCap` are four call sites gaining `onPartDone:`, their caps unchanged; nothing changes in a prompt, `instructions`, `@Guide` or `promptVersion`. `git diff HEAD --stat` of `SylantroSchemaV1.swift`, `CaptureRecorder.swift`, `RecipeEditor.swift`, `GeneratedParts.swift` and `Sylantro/Mirror/`: empty. ✅ 4 a Python scan of the string literals added to the changed views since `HEAD` (`RecipeView.swift`, `RecipeRow.swift`, `LibraryView.swift`) found S-57 "Read the Pages Again?", S-59 "Read Again", "Cancel" (S-26, S-56), and S-78 "This replaces the current reading of this recipe." (proposed in `13` v0.41, used as written, note a). The rest is M3-3e's log line (log text) and no SF Symbol; nothing else. ✅ 5 git status before and after below; this row. **What was built:** part 1 `Domain/Extraction/ReadingProgress.swift`: `init(pagesToRead:)`, `parts` = header, ingredients, steps, `pageRead()` (never past `pagesToRead`), `partDone(_:)` (other parts change nothing; each counts once), `fraction` = (pages read + parts done) ÷ (pages to read + 3), 0 to 1. Part 2 `RecipeStructurer.structure(_:pageIDs:onPartDone:)`, defaulting to nil, so every existing caller is unchanged. `call` reports the part after its call returns (answer or nil), not on a rate-limit throw. `ExtractionQueue.progress: Double?`, observed, `private(set)`: set to 0 once a job's recipe is found waiting, with `pagesToRead` its pages with no reading; it moves on each page read and each part done (back on the main actor, for the job still running), and goes nil when the job ends however it ends and while a refusal waits. Part 3 under "Reading…" on the recipe screen, a `ProgressView(value:)` in the palette's accent, the line's width; in the library, the row being read gets the same bar (thin, default linear style) under its "Reading…", with `LibraryView` passing the queue's `progress` to that row only (`RecipeRow.progress`, default nil). Both animate with `.animation(.easeInOut, value:)`. No new words. Part 4 ⋯ › Read Again always asks: not edited, a plain alert S-57 with S-78, Read Again and Cancel (`.cancel`); edited, M3-3c's S-57 with S-73, Read Again and Keep My Edits. Read Again calls `readAgain` (S-14 on failure, as before). M3-4's page-change question is unchanged. Part 5: `ReadingProgressTests` (new), 3 tests as the table. **Files:** new `Sylantro/Domain/Extraction/ReadingProgress.swift`, `SylantroTests/Domain/ReadingProgressTests.swift`; changed `Sylantro/Extraction/RecipeStructurer.swift` (`onPartDone`), `Sylantro/Extraction/ExtractionQueue.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `Sylantro/Views/Library/RecipeRow.swift`, `Sylantro/Views/Library/LibraryView.swift`; this document (this row only). No prompt, `promptVersion`, `SylantroSchemaV1`, synced model, `CaptureRecorder`, `RecipeEditor`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no popover, tip bubble or confirmation dialog; no network. **Git status before** (branch `milestone-3`, HEAD `d7814a6`): ` M` `Docs/12_IMPLEMENTATION_PLAN.md`, `Docs/13_SCREENS.md`, this document, `Docs/16_FEATURE_IDEAS.md`, `Docs/README.md` (Pops's), and M3-3e's `Sylantro/Extraction/RecipeStructurer.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`. During the session Pops staged the docs, M3-3e's files and this session's `ReadingProgress.swift` (this session ran no git write). **After:** `M ` four docs (`12`, `13`, `16`, `README`), `RecipeStructurer.swift`, `RecipeStructurerTests.swift`; `A ` `ReadingProgress.swift`; `MM` `RecipeView.swift` and this document (staged by Pops, then this row); ` M` `ExtractionQueue.swift`, `LibraryView.swift`, `RecipeRow.swift`; `??` `ReadingProgressTests.swift`. **Git:** `git status --short` (×3), `git branch --list`, `git log --oneline -3`, `git log --oneline -1`, `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (the three unchanged since this session read them), `git diff -U0` and `git diff HEAD -U0` of `RecipeStructurer.swift` and `Sylantro/Views/`, `git diff --stat` and `git diff HEAD --stat` of the guarded files, `git diff --cached --quiet`. **Notes, for Claude to confirm:** (a) **S-78 is used as written**, "This replaces the current reading of this recipe.", still *proposed* in `13` v0.41, as the task says. (b) **The recipe screen's bar won't show during a Read Again.** Part 3.1 puts it under "Reading…", but a recipe being read again keeps its `extraction`, so the screen is the review screen, which has no "Reading…" line (that line is only before a recipe is read, `13` §4.4). Pops's check 2 ("Read Again: under 'Reading…' a bar fills") will see no bar there, and nothing was added, since the task didn't say to. The library row does show "Reading…" and the bar, but in Needs Review or the rest, not New Scans (SC-21 puts only recipes not yet read there). A first scan shows both, as check 3 expects. (c) `onPartDone` is also called for a part that failed and wasn't retried, or whose retry failed (it "returns, whatever it gave"); not when a refusal is thrown. (d) `parts` counts only header, ingredients and steps, as written. A recipe whose ingredients or steps come only from a fallback (no section) never reaches 1 before its job ends, when the bar goes. (e) The bar starts once the job's recipe is found waiting, not before that check, so a job removed at once shows none. While a refusal waits 30 s the bar is nil; on the retry it starts again with the pages counted read and the parts from 0. A part reported after its job ended is ignored (checked against `currentRecipeID`). (f) The part callback captures the queue plainly, not weakly: a `[weak self]` drew Swift 6 warnings, and the queue lives as long as the app. (g) "The line's width" is the row's full width (`.frame(maxWidth: .infinity)`). The library's bar takes the list's tint, which is the palette's accent. **Next:** Pops's check on device (iPhone 18 Pro), items 1 to 3, with item 2 as note (b) says. Not run in this session |
| M3-3e | 25 Nov 2026 | **complete** | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`. **Suite total:** "✔ Test run with 199 tests in 26 suites passed after 0.758 seconds."; `** TEST SUCCEEDED **`. **Total before: 197** (`@Test` count at session start, after M3-5s; M3-5 not built), so 197 + 2 = 199 expected. **Clauses:** ✅ 1 `xcodebuild build -workspace Sylantro.xcworkspace -scheme Sylantro -destination '<that string>'`: `** BUILD SUCCEEDED **`, no errors, no warnings from source; the one warning is the build tool's existing "appintentsmetadataprocessor: Metadata extraction skipped". ✅ 2 the suite passed with 199 tests (197 + 2) on the pinned destination. ✅ 3 `git diff -U0 -- Sylantro/Extraction/RecipeStructurer.swift` (against `d7814a6`): its hunks are `ingredientGroups(from:lines:)`'s doc comment and body, and one new `private static func putBackIngredient(_:)` just after it (note b). No changed line holds `promptVersion`, `instructions`, `PromptIntro`, `@Guide` or `TokenCap`; `GeneratedParts.swift` unchanged. `git diff --stat -- Sylantro/Store/SylantroSchemaV1.swift`: empty; `--cached --quiet`: exit 0. ✅ 4 no string she reads changes: the only literals added to the view are the new log line's (`tap: box on page ‹n›, showing page ‹n› (‹file name›)`, with "none" and "no photo" when missing), page numbers and a file name, no recipe text. ✅ 5 git status before and after below; this row. **What was built:** part 1 `ingredientGroups`: before the naming rule, for each group with a span, a walk back from the line before its first line. Each line that is unused, doesn't end with `:` and `startsIngredient` is put back as RV-29's are (parsed, `put back: ingredient n`), and the span starts at it. The walk stops at a used line, a heading, a line that isn't an ingredient's, or line 1. So the heading before the moved span then names the group. The two put-back sites share `putBackIngredient(_:)`. Part 2 `RecipeView`: `PageStrip` gets `.id(… sourcePageID)` in the strip (`stripPhoto(recipe)?.sourcePageID`) and in the edit sheet's crop (`photo?.sourcePageID`). Each tap in `show` logs one info line: the tapped box's page number (from 1 in `sourcePageIDs`), and the page number and file name of the photo shown for it. `PageStrip.load()` also checks for cancellation after its load (note a). Part 3: 2 tests in `RecipeStructurerTests`, made-up lines. **Files:** `Sylantro/Extraction/RecipeStructurer.swift`, `Sylantro/Views/Recipe/RecipeView.swift`, `SylantroTests/Extraction/RecipeStructurerTests.swift`; this document (this row only). `WrapJoiner.swift` read, not changed. No prompt, `promptVersion`, `SylantroSchemaV1`, synced model, `CaptureRecorder`, `RecipeEditor`, `ExtractionQueue`, `MirrorWriter`, `Info.plist`, entitlement, build setting or SyLib change; no string she reads; no page content; no network. **Git status before** (branch `milestone-3`, HEAD `0897bd5`): staged M3-3c, M3-3d and M3-5s and Pops's docs (`M `/`A ` on 21 paths; `MM` on `Docs/12_IMPLEMENTATION_PLAN.md`, this document and `Docs/README.md`). During the session Pops committed them as `d7814a6`. **After:** ` M` on the 3 files above and this document. **Git:** `git status --short` (×2), `git branch --list`, `git log --oneline -4`, `git log --oneline -3` and `git log --oneline -3 -- Docs/00_DECISION_LEDGER.md Docs/00A_STUDIO_CONVENTIONS.md Docs/00B_SYLANTRO_GUARDRAILS.md` (the three unchanged since this session read them: v0.60, v1.15, v0.19), `git show --stat --oneline HEAD`, `git diff -U0 -- Sylantro/Extraction/RecipeStructurer.swift`, `git diff --stat -- Sylantro/Extraction/GeneratedParts.swift Sylantro/Store/SylantroSchemaV1.swift`, `git diff --cached --quiet -- Sylantro/Store/SylantroSchemaV1.swift`, `git diff -U0 -- Sylantro/Views/`. **Notes, for Claude to confirm:** (a) **Why the strip's image didn't change with `.task(id:)` alone.** What Pops saw (the right outline on page 1's photo) means the strip had the step's page's `Photo`, since the outline is drawn only when the box's page is the photo's (`PageStrip.page(in:)`), while its `image` was still page 1's. So the reload didn't load the new file. `load()` takes the file name from `self.photo` and isn't given it, so a restarted task that runs the strip's earlier closure loads the earlier page again, while the outline comes from the current body. Restarting `.task(id:)` doesn't refresh a view's own `@State` and doesn't promise the action from the newest body. A second, smaller cause: `load()` didn't check for cancellation after its `await`, and the decode runs detached, so it isn't cancelled with the task. A load still running when the page changed could finish later and overwrite the new page's image. `.id(sourcePageID)` gives each page a fresh `PageStrip`, new `@State`, new task, new closure, so neither can happen. `load()` now also returns, without setting the image, once its task is cancelled. Neither cause could be watched on a device in this session (no simulator or device sessions, `00A` §3); the tap log is there for Pops's check. (b) The put-back code, used twice now, is a `private static func putBackIngredient(_:)` beside `ingredientGroups`, not inside it. It is the same code moved, so the diff touches only `ingredientGroups` and that helper. (c) "Stop at … line 1": line 1 is checked, and put back if it qualifies; the walk then ends. (d) The walk runs for every group with a span, as written, including one whose span starts at its name line. An unused ingredient-like line between the previous group's last item and this group's name line comes into this group, not the previous one. (e) The log's "showing page" is the page shown for the tap: the strip's on iPhone in review, the viewer's start page when the strip is hidden, the column's page on iPad. Its file name is the photo's, a UUID name. **Next:** Pops's check on device (iPhone 18 Pro): ⋯ › Read Again on the kolaches ("Kolaches" a subheading, the yeast and the warm water first, flagged); tap steps 1 and 2 and watch the strip move to each page, with the log line. Not run in this session |
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
| RV-37 | Marking a line the reading missed (`16` FI-11; Pops, 25 Nov 2026: "tap a row in the scan, like a missed ingredient, and mark it what it is") | **Ruled: in M3, after M3-5** (task M3-5a): in Edit, tap a line on the page and mark it Ingredient, Step, Note, Title or not part of the recipe; plus a corrections file in TestFlight builds behind the spike switch, saved outside git; corrections never logged as text; nothing sent from the shipped app. Pops, 25 Nov 2026 (decision card, "In M3, after M3-5"). Its screen and words go into `13` first |
| RV-38 | Ingredient groups (Pops, 25 Nov 2026: "the ingredients are grouped in the Kolache and Filling. we should try to detect ingredient groups and store them that way"; the model skipped the kolaches' whole filling group) | **Ruled: from the printed headings, by rule, in a task before M3-5** (M3-3h): a short line ending `:` in the ingredient section heads a group; each ingredient goes under the heading above it; skipped ingredient lines after a heading are put back; the model's groups only when there is no heading. Pops, 25 Nov 2026 (decision card, "Yes, a task before M3-5") |
| RV-39 | What comes next for single-recipe accuracy (run 9, `10` §7: steps lose words, three titles fixable by rule, amounts and units) | **Ruled: all three, steps first.** M3-3j: steps as line numbers with the page's words (a prompt change, spike run 10); then the three title rules (labels-path area SP-21, a label line after the title, a breadcrumb first line); then the amount and unit rules. Pops, 25 Nov 2026 (decision card, "All three, steps first") |
| RV-40 | Reading her recipes in the background (revisits RV-5 and SLT-144). Pops, 25 Nov 2026: "I'm going to want the post scanning reading of an imported recipe be bg too". M3-3l to M3-3p proved it on device: in run 12 all 23 captures were structured with Sylantro in the background under a `BGContinuedProcessingTask`, none refused (`10` §7). What it took: a task started by her tap, progress at each step (a stalled task is ended), and nothing lost when iOS ends it | **A.** When she saves a capture (or taps Read Again), the queue's work runs inside a continued-processing task: the system's progress indicator shows while she is elsewhere, with progress at each step as M3-3p; if iOS ends it, what's left waits until she opens Sylantro, as today. The indicator's words go in `13`. A task after M3-3q and the title rules, before the unit rules. **B.** The same, but after M3 (with M4). **C.** Keep RV-5: reading only while Sylantro is open | **Ruled: A.** Pops, 25 Nov 2026 (decision card, "After the title rules"): a task after M3-3q and the title rules, before the unit rules; the indicator's words proposed in `13` with it. RV-5 and SLT-144 stand until that task |

When Pops rules, the rulings are filed in the ledger at this document's close-out, as `14`'s were.

---

## 4. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.73 | RV-39 added and ruled; Task M3-3j written: steps in the page's own words, `promptVersion` 4, spike run 10 (+ 7 tests, 216) | Run 9 (`10` v0.28); Pops, 25 Nov 2026 (decision card, "All three, steps first") |
| 0.74 | M3-3j complete (216 tests); spike run 10 next | The agent's row in §2 |
| 0.75 | Run 10 scored (`10` v0.29); Task M3-3k written: step clean-up rules, no prompt change (+ 7 tests, 223) | Pops, 25 Nov 2026 (decision card, "Step clean-up rules, then run 11") |
| 0.76 | M3-3k complete (223 tests); spike run 11 next | The agent's row in §2 |
| 0.77 | Task M3-3l written: a spike-only test of structuring in the background under a `BGContinuedProcessingTask` (+ 1 test, 224); one `Info.plist` key allowed for it | Pops, 25 Nov 2026: "so, keeps running when the app is in the bg"; decision card, "Test it in the spike first" |
| 0.78 | Run 11 scored (`10` v0.31); Task M3-3m written: steps under printed labels and headings, rules only (+ 7 tests, 231) | RV-39 (steps first); run 11 |
| 0.79 | M3-3m revised before it ran: Part 5, the test set's five-page recipe loads as one capture (`TestSetGroups`, moved forward from the title-rules task); + 1 test, 232 | Pops, 25 Nov 2026: "how do we get the load test set to just load them properly like the others?" |
| 0.80 | M3-3l complete (224); M3-3m Part 6: the background test's identifier becomes a wildcard, as Apple's documentation asks (M3-3l note b) | The agent's row in §2 |
| 0.81 | M3-3m complete (232 tests); spike run 12 and the background test next | The agent's row in §2 |
| 0.82 | Task M3-3n written: the background test's crash on device (registration rejected, then a submit with no handler) | Pops, 25 Nov 2026 (the crash log) |
| 0.83 | M3-3n complete (232): the installed `Info.plist` was right; the handler must be registered under the concrete identifier, with only the permitted identifier a wildcard | The agent's row in §2 |
| 0.84 | Task M3-3o written: in the background test, a rate-limit refusal is waited out (30 s to 300 s, six times), progress counts only finished captures, each attempt records its parts and wait; BG Run All moves out of the ⋯ menu (+ 2 tests, 234) | Pops, 25 Nov 2026: the background run's console (capture 0 done in the background, then "Client rate limit exceeded"); decision card, "Write M3-3o now"; "move bg run out of menu, called BG Run All" |
| 0.85 | M3-3o checked by Claude: complete, 234 tests, every Done-when clause met; notes a to e accepted. Note a: the SDK says a continued-processing task whose progress stalls may be expired, so an expiry during a long wait is the thing to watch in Pops's run. Note b: iOS 27's `LanguageModelError.RateLimited` has a `resetDate`, not used yet | The agent's row in §2; Pops, 25 Nov 2026: "Task M3-3o done" |
| 0.86 | Task M3-3p written: in the background test, progress at each step inside a capture, no title comparison, the task's start and end recorded, and an expiry ends the task but not the run (+ 2 tests, 236) | Pops, 25 Nov 2026: the BG Run All log (captures 0 and 1 done in the background, then "expired at capture 3", "Task failed"); decision card, "Write M3-3p now"; "it did not finish after the stall..." |
| 0.87 | M3-3p checked by Claude: complete, 236 tests, every Done-when clause met; notes a to f accepted (progress can step back when a capture ends waiting for the app; the recorded part name is `lineLabels`) | The agent's row in §2; Pops, 25 Nov 2026: "task M3-3p done" |
| 0.88 | Run 12 scored (`10` v0.32): the model answers in the background (all 23 captures, none refused); Task M3-3q written: an ingredient's name from its own line when the model's doesn't match, no flag on a line with a quantity put back under a printed heading (+ 3 tests, one existing test changed, 239) | Pops, 25 Nov 2026: "ok, run in bg completed"; decision card, "Fix item names, then title rules" |
| 0.89 | RV-40 added: reading her recipes in the background, revisiting RV-5 and SLT-144 now that run 12 proved it; proposed A (a task after M3-3q and the title rules). Noted: BG Run All's skipped title comparison (M3-3p Part 2) may be turned back on later, at Pops's word | Pops, 25 Nov 2026: "maybe we can take the bg lid off again at some point. I'm going to want the post scanning reading of an imported recipe be bg too..." |
| 0.90 | M3-3q checked by Claude: complete, 239 tests, every Done-when clause met; notes a to d accepted. Two existing tests changed: the one the task named, and M3-3e's "lines before the first are put back", whose lines come after a printed heading, so Part 2 rightly unflags them | The agent's row in §2; Pops, 25 Nov 2026: "Task M3-3q done" |
| 0.91 | RV-40 ruled A: her reading moves to the background in a task after the title rules, before the unit rules | Pops, 25 Nov 2026 (decision card, "After the title rules") |
| 0.92 | Task M3-3r written: SyLib's `MoreMenu` for the spike's and a recipe's ⋯, `CapsuleButton` on store recovery and the pause after saving, and a new SyLib `CapsuleButton` size `.small` for "That's All of It" (SyLib + 1 test; Sylantro 239) | SLT-161 (Pops, 25 Nov 2026); decision card, "A small task now" |
| 0.93 | Run 13 scored (`10` v0.33): M3-3q confirmed on device data | Pops, 25 Nov 2026: "spike run done" |
| 0.94 | M3-3r checked by Claude: complete (Sylantro 239, SyLib 1,765), every Done-when clause met; notes a to d accepted (the ⋯ keeps VoiceOver's "More"; older SyLib code comments name an app, which is allowed: only SyLib's `.md` docs must not) | The agent's row in §2; Pops, 25 Nov 2026: "Task M3-3r done" |
| 0.95 | Task M3-3s written: the title rules RV-39 named (SP-21's labels-path area; label lines, moved from M3-5; navigation and breadcrumb lines) and a title line labelled a step (+ 4 tests, 243) | RV-39; run 13 |
| 0.96 | M3-3s checked by Claude: complete, 243 tests, every Done-when clause met; notes a to e accepted. One existing test changed (M3-3m's run test, its quantity half: a step line before a lone ingredient run is now read as a title line); real pages list ingredients before steps, so run 14 watches for a first step lost | The agent's row in §2; Pops, 25 Nov 2026: "Task M3-3s done" |
| 0.97 | Task M3-3t written: the labels path's 5-line minimum stops at a quantity line, and a title never takes one in (+ 3 tests, 246) | Run 14 (`10` §7); Pops, 25 Nov 2026 (decision card, "Fix titles first (M3-3t)") |
| 0.98 | M3-3t checked by Claude: complete, 246 tests, every Done-when clause met; no existing test changed; notes a to c accepted. Note a: Part 2 is built as its test reads it (the extension stops once a quantity line is seen anywhere in the first 5 lines, never cutting below `stopAt`), which is the rule intended | The agent's row in §2; Pops, 27 Nov 2026: "Task M3-3t. done" |
| 0.72 | Pops's kolaches check on iPhone after M3-3e to M3-3i: Read Again's question and bar, the ingredient groups and put-back lines, each line's own page, no blank photos: all passed; the iPad item not yet reported | Pops, 25 Nov 2026: "1--passed 2--passed! all the ingredient groups look fantastic 3--passed 4--passed" |
| 0.71 | M3-3i checked by Claude: complete, 209 tests, every Done-when clause met; notes a to c accepted | M3-3i Results row; Pops, 25 Nov 2026: "Task M3-3i is done." |
| 0.70 | M3-3g checked by Claude: complete, 209 tests, every Done-when clause met; notes a to h accepted | M3-3g Results row; Pops, 25 Nov 2026: "Task M3-3g done" |
| 0.69 | M3-3h checked by Claude: complete, 206 tests (run before M3-3g), every Done-when clause met; notes a to e accepted; M3-3g's total now 209 | M3-3h Results row; Pops, 25 Nov 2026: "Task M3-3h done" |
| 0.68 | Task M3-3i written: the progress bar on a recipe read again, moved out of M3-5 (on hold) | Pops, 25 Nov 2026: "We should have a reading progress bar show in the recipe details too since we kick off a re read from its menu" |
| 0.67 | RV-38 added and ruled; Task M3-3h written: ingredient groups from the printed headings (+ 4 tests); M3-5 on hold until single-recipe reading works better | Pops, 25 Nov 2026 (decision card, "Yes, a task before M3-5"); "we will not move on to task 5 until we get single recipe reading working better" |
| 0.66 | Task M3-3g written: page photos that go blank (display-size shared loader, `.downloaded` counts as on the device, a failing decode logged and retried smaller); + 3 tests; M3-5 now after it, 222 | Pops, 25 Nov 2026, two screenshots: "sometimes the images shows blank, it was showing before, only relaunch seems to fix it" |
| 0.65 | M3-3e and M3-3f checked by Claude: complete (199, 202 tests), every Done-when clause met; M3-3e notes a to e and M3-3f notes a, c to g accepted; M3-3f note b (no bar on a recipe read again) added to M3-5 Part 4 item 7; M3-5's total now 219 | M3-3e and M3-3f Results rows; Pops, 25 Nov 2026: "M3-3e", "M3-3f is done" |
| 0.64 | Task M3-3f written: Read Again always asks (S-78 proposed), a progress bar by steps on the recipe and its row; + 3 tests | Pops, 25 Nov 2026: "the re-read menu item should confirm before starting, also, can we have a progress bar on the reading?"; `13` v0.41 SC-23 |
| 0.63 | RV-37 added and ruled: marking a missed line, task M3-5a after M3-5 | Pops, 25 Nov 2026 (decision card, "In M3, after M3-5") |
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
