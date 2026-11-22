# Sylantro — Accuracy Test Set

**Design document · the spike's 25 real binder pages: how they are scored, what makes them hard,
and the design questions they raise**
Version 0.25 · 22 November 2026 · **Draft, not accepted; proposals TS-5, TS-10, TS-11 and TS-15 are
Pops's to decide; the rest are settled (SLT-045 to SLT-048, SLT-062 to SLT-065, SLT-070, SLT-071) and TS-12 is
done.** Not for the agent until a task names it.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It serves Milestone 1's spike (SLT-090, `01` §7).

---

## 0. What this is

On 21 November 2026 Pops photographed 25 pages from the binder (18, then 7 more for handwriting
and mixed pages), left in their plastic sleeves and
not posed, as she will scan them. This document is the git-safe half of the test set: the method,
the scoring rubric, the hard cases the pages show, and the decisions they raise.

**The pages themselves never enter the repository** (`00B` §2, SLT-092). The photos and the answer
key (what a perfect extraction returns for each page) live outside git, beside the repository:

```
~/GIT/Syzygy/sylantro-testpages/
    TEST_SET_ANSWER_KEY.md
    Pages/TP-01.jpeg … TP-25.jpeg
```

This document names pages only by their IDs (TP-01 to TP-25) and kind. Every ingredient line quoted
below is made up to show the pattern, not copied from a page. Test fixtures in the repository are
made up the same way.

---

## 1. The set

| Kind | Pages | What it is |
|---|---|---|
| Web print, recipe site | TP-01, TP-03, TP-04, TP-09, TP-16 to TP-18, TP-22, TP-23, TP-25 | A browser's print of a recipe page: logo, photo, ratings, "Related Pages", and a footer with the URL, the print date and "Page n of m" |
| Typed, family | TP-05 to TP-08, TP-10 to TP-13 | Word-processor pages from one family cook: no headings, kitchen shorthand, a running method, notes inside the method |
| Magazine clipping | TP-14, TP-15, TP-20, TP-24 | Glossy pages, text over or beside large photos, multi-column, stained and yellowed |
| Class handout | TP-02 | A kids' cooking class sheet with an Equipment column and an alternate method |
| Handwritten | TP-19, TP-21 | Written by hand on notebook paper or the back of a printed page: kitchen shorthand, no headings, crossed-out words |
| Printed with handwritten additions | TP-23, TP-25 (also web prints) | Her own changes written beside the printed list: a column of added ingredients, one line in red ink |

25 pages make **25 recipes**. Three recipes run across two pages (TP-05 + TP-06, TP-07 + TP-08,
TP-16 + TP-17), and the first page of one of them (TP-16) holds only the header. One page (TP-24)
holds **four recipes**, the last cut off at its foot; she picks which to save (SLT-047). Six recipes have a page that was not
photographed: three web prints say "Page 1 of 2" (TP-03, TP-04, TP-18), TP-22 is "Page 2 of 3",
TP-23 is "Page 1 of 3", and TP-24's last recipe continues overleaf. TP-18, TP-22, TP-23 and that
last recipe lose recipe content. TP-18's last step runs off the bottom of the page mid-sentence,
and a footnote asterisk has no footnote; Pops reports its page 2 was likely blank or ads and was
discarded, but the cut-off says page 2 held at least the end of step 4.

**One capture is one recipe** (SLT-045), so the spike runs each joined pair as one capture of two
pages, as she will scan them.

**Handwriting:** two pages are fully handwritten (TP-19, TP-21) and two are printed with
handwritten additions (TP-23, TP-25), which closes the gap `01` §7 named (TS-12). Handwriting is
the weakest case for on-device reading (`01` §3.1), so the spike reports these four pages
separately as well as in the totals.

---

## 2. How a page is scored

Each page goes through Vision and Foundation Models as `01` §3 describes, and its result is
compared with the answer key, field by field.

| Field | Scored as |
|---|---|
| Recipe boundaries | One recipe per capture (SLT-045); a two-page capture rejoins the sentence split across its pages (H-1); an unfinished last page triggers Save's page-2 question (H-3, SLT-046) |
| Title | Exact, or exact after case and whitespace |
| Yield and times | Value and unit right; the raw text kept |
| Each ingredient | Verbatim line kept (always required, SLT-042); then quantity, unit, item, preparation, optional, note, each right or wrong |
| Ingredient count | Missing, extra (bleed-through, steps, noise) and split lines counted separately |
| Steps | Count, order, and text with no words added or lost; groups named where printed |
| Notes and attribution | Present where the key has them; noise absent (H-4) |
| Warnings | The key's expected warnings raised (an ingredient used but not listed, a cut-off page) |

For each page, three numbers are reported:

1. **Field accuracy:** the share of fields right.
2. **Fixes in review:** how many edits she would make to reach the key. This is the number that
   says whether import feels fast.
3. **Vision confidence:** the mean and the lowest word confidence, to see which damage costs most.

The spike also times each page's reading and structuring on Pops's iPhone 18 Pro (SLT-017), and Save's quick read of a
last page's bottom lines (SLT-046) (§6).

---

## 3. What a page must never do

These are failures whatever the field score:

- Lose or duplicate text where a capture's two pages meet.
- Put words from the reverse side of the paper (bleed-through) into any field.
- Add an ingredient the page does not list, even one the steps use.
- Correct the page's spelling, typos or arithmetic.
- Read `t` and `T` the same (H-7).
- Guess letters cut off at the photo's edge.
- Guess or drop handwriting it can't read; it is marked unreadable and located (SLT-066).
- Merge a handwritten line into the printed line beside it, or drop it.
- Let an ingredient, step or contributor from one recipe on a page land in another.

---

## 4. The hard cases

### Pages and layout

| # | Case | Pages | What correct looks like |
|---|---|---|---|
| H-1 | **A recipe continues onto the next page.** The second page has no title and starts mid-sentence, often in lowercase | TP-05 → TP-06, TP-07 → TP-08, TP-16 → TP-17 | Captured together (SLT-045): one recipe, both pages in `sourcePageIDs`, the split sentence rejoined |
| H-2 | **A page holds only the header**: title, description, times, yield, no ingredients or steps | TP-16 | Captured with its next page (SLT-045); structuring takes the header from page 1 and the rest from page 2 |
| H-3 | **A page ends early**: "Page 1 of 2" with page 2 not scanned, a heading with nothing under it, a step cut off by the photo's edge | TP-03, TP-04, TP-18, TP-22, TP-23, TP-24 | Saved with a warning; a recipe complete on the page is not held back by "Page 1 of 2" alone. TS-3 |
| H-4 | **Noise on the page**: "Related Pages" lists, star ratings and review counts, photo credits, logos, "Read It!"-style boxes, a school's phone and email, a shopping sidebar with prices and web addresses, site navigation links | TP-01 to TP-04, TP-02, TP-16, TP-18, TP-20, TP-24, TP-25 | In no field; still in `ocrText`. TS-5 |
| H-5 | **Bleed-through**: the reverse side's text showing through, faintly or (TP-09) strongly enough to overlap the ingredient list | TP-02, TP-04, TP-09, TP-15, TP-19, TP-21, TP-22 | None of it read. The spike measures whether Vision's confidence separates it |
| H-6 | **Layout**: two-column ingredients, directions beside ingredients, three columns under a photo, a TIP sidebar, text printed over a photo, a yield printed above the title | TP-01, TP-09, TP-14, TP-15, TP-04, TP-20, TP-24 | Columns read in order; a sidebar becomes a note |

### Ingredient lines

| # | Case | Made-up example | What correct looks like |
|---|---|---|---|
| H-7 | **`T` and `t`**: capital T is tablespoon, lowercase t is teaspoon | `1 t baking soda`, `2 T vinegar` | Case-sensitive. Reading both as one unit is a 3× error. TS-9 |
| H-8 | **Kitchen shorthand**: `c`, `pt.`, `lb.`, `lbs`, `lg`, `pkg`, `asst.`, `XL`, `med-high`, `OJ` | `1 ½ c diced carrot` | Canonical unit; size words (`lg`, `XL`) kept as a size, not an item |
| H-9 | **One line, several ingredients**: a shared quantity, or a list with no quantity; salt and pepper written `S/P`, `s/p`, `S&P` | `Dried basil, oregano (1 t each)`; `Paprika, cumin, s/p` | Split into one ingredient each, every one keeping the same verbatim line. TS-8 |
| H-10 | **Fractions and compounds**: `½`, `1 ½`, `2 ½`, `1/4`, `⅔`, `½ cup + ⅓ cup`, ranges `16 to 20`, `4-8 T`, `2-3` | `½ cup + 2 T sugar` | Unicode and ASCII fractions alike; a compound kept as both parts; a range as min and max |
| H-11 | **A count and a package size**: a can, box or tub with its weight | `1 14-ounce can tomatoes`, `1 16 oz box broth` | Count 1, unit can (14 ounce); not "114 ounce" |
| H-12 | **A number that isn't a quantity**: a fraction inside a product name; a quantity after the item | `4 ounces 1/2-fat cheese`; `Zest of 1 lime`; `Pinch nutmeg` | The name keeps its fraction; "Zest of 1" is 1 zest; "Pinch" is a unit |
| H-13 | **Long parentheticals, alternatives and optional marks**: notes nested two deep, "or" substitutions, "-optional" glued to a line, "Totally optional" prefixes, footnote asterisks | `1 cup rice (or quinoa (cooked))-optional` | Optional set; the parenthetical kept whole as a note, never split into extra ingredients |
| H-14 | **Typos in the source**: a digit 1 for "l", a dropped letter | `2 1bs potatoes` | Verbatim kept; a parsed value, if any, at low confidence; spelling never corrected |

### Recipe fields

| # | Case | Pages | What correct looks like |
|---|---|---|---|
| H-15 | **Odd yields**: a range of drinks, a volume ("makes 1½ cups", "8 cups"), a bare number, a printed yield that can't be right (30 servings of 2 cups from 60 bite-size shells) | TP-03, TP-14, TP-18, TP-04, TP-16 | Kept as printed in `servingsText`, parsed where it parses; never corrected. A description's "about 16 servings" is not copied into servings |
| H-16 | **Odd times**: "1.08 hours", "Active", "Hands-On", times only inside the method | TP-09, TP-03, TP-15, TP-05 | 1.08 hours is 65 minutes; Active and Hands-On map to prep; method times stay in the steps |
| H-17 | **Ingredients used but not listed**: salt, pepper, water, cooking spray, or a quantity given only in a step | TP-07, TP-09, TP-14, TP-19, TP-20, TP-24 | Never added as ingredients; raised as a review warning |
| H-18 | **Ingredients split across steps** (part of the butter now, the rest later), and optional extras named only in a step | TP-05 | Listed once as printed; the steps keep their own amounts |
| H-19 | **Alternate method** printed as a second numbered list | TP-02 | A second step group with its printed name, not a second recipe |
| H-20 | **Equipment column** | TP-02, TP-23 | See TS-7 |
| H-21 | **Notes inside the method**: make-ahead advice, "add whatever you like", a TIP box, a personal remark | TP-05, TP-07, TP-13, TP-15 | A note where the page separates it; accepted either way where it runs inside a step |
| H-22 | **SEO and suffixed titles**: "… Recipe", "… Recipe - Snacking with …"; lowercase magazine titles | TP-04, TP-09, TP-14, TP-15 | Kept as printed. TS-11 |
| H-23 | **Web-print footer**: URL, print date and time, "Page n of m"; copyright lines; "Recipe courtesy of", Show and Episode | TP-01, TP-03, TP-04, TP-09, TP-17 | URL, print date, author and publisher captured into attribution; "Page n of m" used only for H-1 and H-3. TS-4 |
| H-24 | **Printed nutrition facts** | TP-17, TP-24 | Kept as printed text, not as Sylantro's nutrition. TS-6 |
| H-25 | **Cross-reference to another page of the source**: "(recipe, page 264)" | TP-15, TP-20 | A note; no link |
| H-26 | **Same dish, different recipe**: two versions of the same dish from different sources | TP-07 + TP-08, TP-09 | Not flagged as duplicates. Feeds the duplicate rule (`01` §8) |

### Photo damage

| # | Case | Pages |
|---|---|---|
| H-27 | Sleeve glare and reflections | TP-06, most pages faintly |
| H-28 | Water damage: ink run through words, crinkled paper, a crease, a stain edge | TP-12 |
| H-29 | Oil and water stains on glossy paper; tape on a corner; yellowed paper | TP-14, TP-15 |
| H-30 | Dim, gray, uneven light; vignetting | TP-08, TP-10, TP-11 |
| H-31 | The page shot at an angle, the binder's rings and tab labels in the frame, the page edge cut off | TP-01, TP-03, TP-18 |, TP-20, TP-24
| H-32 | Marker over printed labels; words printed in red | TP-01, TP-03, TP-07, TP-13 |

### Handwriting and mixed pages (added with TP-19 to TP-25)

| # | Case | Pages | What correct looks like |
|---|---|---|---|
| H-33 | **A whole page written by hand**: cursive and print mixed, an uneven baseline, lined notebook paper | TP-19, TP-21 | Scored on the same rubric; low-confidence words flagged, never guessed |
| H-34 | **Handwritten shorthand**: `#` after a number for pound, `Tbl`, `T` and `t` where case is the only signal, "2T" with no space, `w/`, `&`, `@ 350°`, `til`, `hrs.` | TP-19, TP-21 | Canonical units; `#` after a number is pound; a degree sign with no unit is Fahrenheit, flagged. TS-9 |
| H-35 | **An ingredient list written as a sentence** under a label (made up: `Blender: 1 onion, 2 carrots, 1 t salt`) | TP-19 | The label becomes the group name; each item its own ingredient |
| H-36 | **Crossed-out or scribbled-out words** | TP-21 | In no field |
| H-37 | **Handwritten additions on a printed page**: a column of added ingredients beside the printed list; one line in red ink on a printed line's baseline | TP-23, TP-25 | Kept and marked as handwritten; never merged into the printed line beside it, never dropped. TS-14 |
| H-38 | **Several recipes on one page**: recipes flowing across three columns, the last cut off at the foot, each contributor printed after their recipe | TP-24 | Each recipe kept apart; nothing crosses into a neighbor; a contributor belongs to the recipe above. TS-13 |
| H-39 | **A step cut from another page and taped on sideways** | TP-22 | Read in its rotation and placed by its number |
| H-40 | **A typeface whose digit 1 looks like a capital I** (`I cup`, `II ounces`, `Servings: IO`) | TP-24 | Read as digits wherever a quantity belongs |
| H-41 | **A word hyphenated across a line break** (`tea-spoons`, `can-not`) | TP-20, TP-24 | Rejoined |
| H-42 | **A page that starts mid-step**, and step numbers that restart under a group heading | TP-22 | The opening text kept as the end of a step from a missing page; groups kept |

---

## 5. Proposals for Pops (TS-1 to TS-15)

Each is a recommendation; none is ruled.

| # | Question | Recommended | Why |
|---|---|---|---|
| TS-1 | ~~How continuation pages are joined~~ | **Settled by SLT-045:** one capture is one recipe; she captures a recipe's pages together | Pops, 21 Nov 2026 |
| TS-2 | ~~A header-only page~~ | **Settled by SLT-045:** it is captured with its next page | Pops, 21 Nov 2026 |
| TS-3 | ~~When Save asks "Is there a page 2?"~~ | **Settled by SLT-046:** only when the last page looks unfinished (ends mid-sentence, "Page 1 of 2", an asterisk with no footnote), by a fast read of its bottom lines at Save; a no saves it with a warning, fixed later with Add page | Pops, 21 Nov 2026 (decision card, "Only when the page looks unfinished") |
| TS-4 | ~~Attribution from web prints and clippings~~ | **Settled by SLT-062:** stored in parts (author, publisher, show, episode, source URL, printed date, issue date, copyright), plus free text; "Page n of m" not stored | Pops, 21 Nov 2026 (decision card, "Separate parts") |
| TS-5 | **Page noise** | Dropped from every field, kept in `ocrText`. Personal contact details printed on a page (a school's phone and email) are never lifted into fields | Nothing is lost, because the page and its full text stay (SLT-060) |
| TS-6 | ~~Printed nutrition facts~~ | **Settled by SLT-063:** kept as `printedNutrition`, printed text, shown in review; a check for `03`, never a replacement | Pops, 21 Nov 2026 (decision card, "Keep as printed text") |
| TS-7 | ~~An Equipment list~~ | **Settled by SLT-064:** an optional `equipment` list of strings | Pops, 21 Nov 2026 (decision card, "Its own equipment list") |
| TS-8 | ~~One line, several ingredients~~ (H-9) | **Settled by SLT-070 and SLT-071:** split, each keeping the shared verbatim line and the shared quantity; S/P, s/p and S&P are salt and pepper, to taste | Pops, 21 Nov 2026 (decision card, "Split into separate ingredients") |
| TS-9 | ~~`t` and `T`~~ | **Settled by SLT-048:** case decides, `T` tablespoon, `t` teaspoon; when Vision's case is unsure, the unit is flagged | Pops, 21 Nov 2026 ("T tablespoon, t teaspoon") |
| TS-10 | **Alternate methods** | A second step group with the printed heading | Keeps one recipe, as the page has one ingredient list |
| TS-11 | **SEO-style titles** | Kept as printed; she edits in review if she wants. No automatic trimming of "Recipe" or subtitles | Nothing is guessed silently (SLT-042); a trim rule would be wrong for some title one day |
| TS-12 | ~~Handwriting in the set~~ | **Done:** Pops added two handwritten pages and two printed pages with handwritten additions (TP-19, TP-21, TP-23, TP-25) | Pops, 21 Nov 2026 |
| TS-13 | ~~A page with several recipes~~ | **Settled by SLT-047:** review lists every recipe found on the page and she picks which to save (one, some or all), each its own recipe sharing the photo; a cut-off one gets the warning and Add page | Pops, 21 Nov 2026 (decision card, "She picks which to save") |
| TS-14 | ~~Handwritten additions on a printed page~~ (H-37) | **Settled by SLT-065:** real ingredients or steps where they belong, marked `isHandwritten` and shown in a different style; an unclear one goes last, flagged | Pops, 21 Nov 2026 (decision card, "Real ingredients, marked") |
| TS-15 | **Unreadable handwriting in the recipe view** (SLT-066) | The cropped piece of the page photo is shown in place of the unreadable ingredient or step (and unplaced areas at the end), with "Couldn't read this" and a way to type it in; cut on the fly from the page by its `sourceBox`, nothing new stored | Pops, 21 Nov 2026, suggested it; she sees her own writing exactly as it is, and the page photo is already on every device |

TS-4, TS-6, TS-7 and TS-14 are in `01` §4's schema table and `06` Task M1-1's value types
(SLT-062 to SLT-065); M1-2's parser fixtures cover H-7 to H-14 with made-up lines.

---

## 6. Running the spike

The spike is Pops's to run, on his iPhone 18 Pro (SLT-017), through the hidden spike screen `11` builds (SLT-093); the SE can't run Foundation Models (SLT-004). For each
page it records the three numbers in §2 and the time to read and structure, then writes a results
table into the answer-key folder, outside git. A summary with no recipe content (counts, accuracy,
fixes per page, which hard cases failed) comes back into this document as §7.

## 7. Results

### Run 1 · 22 November 2026

Pops's iPhone 18 Pro, iOS 27.2.1, `11` M1-3's spike screen, all 25 pages as 22 captures. Scored by
Claude against the answer key; the per-page table is outside git
(`sylantro-testpages/results/SPIKE_1_SCORING.md`). No recipe content here.

**Reading (Vision) is fast and, on print, near perfect.**

| Measure | Result |
|---|---|
| Page read, accurate level | 93 to 386 ms a page |
| Save's bottom-lines read (SLT-046) | 6 to 37 ms, so it costs Save nothing noticeable |
| Mean word confidence, printed pages | 0.99 to 1.00 |
| Mean word confidence, handwritten pages | 0.93 to 0.94, with garbled lines and some letters read as Cyrillic look-alikes |

**Structuring (Foundation Models) finds the ingredients but not the shape of the recipe.**

| Measure | Result |
|---|---|
| Captures structured | 14 of 22. 4 ran past the model's 8,192-token limit on short pages (the output looping, not the input); 1 failed with a model error; 3 were refused as rate-limited: Pops took a phone call during the run, which put the app in the background |
| Titles right | 12 of 14 (one dropped the first line of a two-line title; one was an OCR misread on handwriting) |
| Ingredient lines found, printed pages | 103 of 106 (97%) |
| Quantity right / unit right on those lines (from M1-2's parser) | 93 of 100 / 89 of 100 |
| Ingredient lines found, handwritten pages | 10 of 21 |
| Non-ingredients put in the ingredient list | 48 on 12 printed pages, mostly the steps copied in a second time |
| Structure time | 4 to 23 s a recipe, about 11 s typical |

Other faults: `item` filled on 75 of 178 ingredients; `attribution` never filled; `printedNutrition`
filled on pages that print none; `equipment` and `yield` sometimes invented or holding step text,
including a yield on both handwritten pages that the page does not say; group names often an
ingredient line or a heading such as "Method".

**What it means.** The reader is ready. Asking the model for the whole recipe in one go is not:
it copies the method into the ingredients, fills fields with text from elsewhere, invents a few
values, and sometimes loops until it runs out of room. Nothing here was saved (M1-3 has no
validator), but in the app each of these would reach review or, worse, pass as true.

### Proposals from run 1 (SP-1 to SP-6): all accepted, SLT-140 to SLT-145

| # | Proposal | Why |
|---|---|---|
| SP-1 | **Structure in parts** (`01` §3.3): split the page text first (by headings such as Ingredients, Directions, Notes, and by layout), then ask the model one small question per part: the header, the ingredient lines, the steps | Fixes the copied method and the misplaced fields, and keeps each call far from the token limit |
| SP-2 | **Cap and steady the model's output**: a maximum response length per call and greedy (non-random) sampling | Stops the looping runs; a capped run fails fast and is retried in parts |
| SP-3 | **A "found on the page" check in `RecipeValidator`**: every value the model returns (title, yield, times, equipment, nutrition, group names) must appear in the page's OCR text, or it is dropped and flagged | Catches the invented yield and equipment, honoring "never guessed" (SLT-042) |
| SP-4 | **Rule-based fields first**: a printed URL, a "Page n of m", "Serves", "Makes", "Prep/Cook/Total time" are found by Domain rules, not the model | Cheap, exact, testable with made-up lines |
| SP-5 | **Structure only while the app is in front, or retry later**: a rate-limit refusal leaves the page waiting (SLT-044's mark) and it is tried again when Sylantro is next open | The model refused three pages while a phone call had the app in the background; she will get calls mid-scan too. This shapes `ExtractionQueue` (`02` §4) |
| SP-6 | **Handwriting reading**: turn off automatic language detection and fix the language to English; run 2 compares | Removes the Cyrillic look-alikes; handwriting stays the weak case, so TS-15's cropped image matters |

Pops accepted all six ("all six", 22 Nov 2026): SLT-140 to SLT-145, built by `11` Task M1-4. Run 2
repeats the 22 captures with Do Not Disturb on and the screen kept awake.

### Run 2 · 22 November 2026

The same phone and pages, on `11` M1-4's build (structuring in parts, SLT-140 to SLT-145), with Do
Not Disturb on. 23 captures: TP-19 was added twice, and both gave identical results, so greedy
sampling repeats. Per-page table outside git (`sylantro-testpages/results/SPIKE_2_SCORING.md`).

**Reliability is fixed. Accuracy on the pages that worked is better; four pages lost a whole part.**

| Measure | Run 1 | Run 2 |
|---|---|---|
| Captures finished | 14 of 22 | 22 of 22 (no runaway output, no rate limits, no waits) |
| Titles right | 12 of 14 | 13 of 22 (see below) |
| Ingredient lines found, printed pages | 103 of 106 on 12 pages | 118 of 166 on 20 pages; 107 of 117 on the 16 pages where no part failed |
| Quantity right / unit right on those lines | 93 / 89 of 100 | 105 / 100 of 115 |
| Non-ingredients in the ingredient list | 48 | 14, 7 of them one page's rewritten lines |
| Ingredient lines found, handwritten pages | 10 of 21 | 7 of 21 |
| `item` filled | 75 of 178 | 137 of 145 |
| `attribution` filled | never | 10 captures |
| Invented yield on handwritten pages | both | none |
| Structure time | 4 to 23 s, about 11 s typical | 2.5 to 34 s, about 10 s typical |

Where it went wrong:
- **A part was lost on four pages.** On TP-04 and TP-24 the model's answer was missing a required
  field ("GeneratedContent does not contain a property …"), so the whole part was thrown away. On
  TP-03 the page reads its headings before its lines, so the splitter found an empty Ingredients
  section and never asked. TP-25 never asked for its header.
- **The model rewrote ingredient lines on TP-07**, dropping quantities ("4 T butter" became
  "butter") and merging wrapped lines. The found-on-the-page check passes, because "butter" is on
  the page.
- **Titles:** a kicker or section heading taken as the title (TP-14, TP-20), half of a two-line
  title (TP-15), a publisher prefix or extra line (TP-02, TP-09), and the header part's failure on
  TP-24.
- **`equipment` and `times` still hold text from elsewhere** on six pages (steps, a footer, "Page
  1 of 3"), all of it on the page, so the check lets it through.
- **Pinning English (SLT-145) didn't change the Cyrillic look-alikes**: the same three lines on
  TP-19 and TP-21 as run 1.

**What it means.** Splitting the page was the right call: nothing loops, nothing is refused, and
the parts that ran are mostly clean. What's left is making each part fail safe (never lose the
whole ingredient list to one bad field or one odd layout) and taking text from the page's own lines
rather than the model's copy of them.

### Proposals from run 2 (SP-7 to SP-11): all accepted, SLT-146 to SLT-150

| # | Proposal | Fixes |
|---|---|---|
| SP-7 | **Lines come from the page, not the model**: the ingredients part answers with line numbers, and `rawText` is the OCR line (wrapped lines joined by rule); quantity and unit come only from M1-2's parser | TP-07's lost quantities, TP-13's split lines; the check can no longer be passed by a shortened line |
| SP-8 | **A failed part is retried, then falls back**: on a decoding error or an empty section, retry that part once with every generated field optional, then fall back to asking for that part over the whole page text, with a review warning | TP-03, TP-04, TP-24, TP-25: no page loses its whole ingredient list |
| SP-9 | **Title from the page's layout**: the title is the largest text near the top (Vision gives each line's box), joining a title printed over two lines; the model only picks among those candidates | TP-02, TP-09, TP-14, TP-15, TP-20, TP-24 |
| SP-10 | **Fields stay inside their own section**: `equipment` stops at the next heading, and `times` comes only from labeled time lines (Prep, Cook, Total, Hands-on); the found-on-the-page check also checks the section | TP-02's and TP-23's equipment, the step text in `times` |
| SP-11 | **Handwriting script check**: drop or flag OCR lines with non-Latin letters on an English page, and check with the agent whether `recognitionLanguages` takes effect | The Cyrillic look-alikes; the lines go to the unreadable-areas mark (SLT-066) instead |

Pops accepted all five ("All", 22 Nov 2026): SLT-146 to SLT-150, built by `11` Task M1-5. Run 3
repeats the captures. One finding changes SP-8's detail: the three unreadable answers were each
cut off at the end, so they look like answers that reached their length cap, and the retry doubles
the cap.

### Run 3 · 22 November 2026 (stopped)

On `11` M1-5's build. Pops stopped it partway because failing captures took too long, and no
results file was exported. From his screenshots:
- TP-01 and TP-03 failed. Both took the several-recipes (one-shot) path, which should run only on a
  page like TP-24. The header answer's other-titles list most likely held the word "none" (the model
  wrote "none" into empty fields), which counted as another recipe. The one-shot answer copied the
  method into the ingredients, reached its cap, was retried at double the cap, and failed again.
  The fault is in M1-5's text: it made that list optional.
- TP-05+06 sat at "Waiting for Sylantro to be open" with the app in front: a rate limit, which
  waits for the app to come back to the front (`11` §1). The extra calls from retries make a
  refusal more likely.
- TP-07+08 was added twice.
- TP-02, TP-04 and TP-07+08 finished, in about 12 seconds each. Their content isn't scored, so
  M1-5's real changes (lines and titles from the page, sections) are not measured yet.

Pops chose all three fixes (decision card, "M1-6: all three fixes"): SLT-151 to SLT-153, built by
`11` Task M1-6, then run 3 again.

### Run 3 again · 22 November 2026 (not exported)

On M1-8's build with Load Test Set. TP-03 and TP-23 failed again in the one-call path for several
recipes: both pages have real lines that read as titles, so M1-6's gate passed. Export stayed off
because the report was built only at the end of the run. Pops chose to retire the one-call path
(SLT-151, rewritten; decision card, "Always use parts; flag it") and to make the export work at
any time, failures included: `11` Task M1-9.

### Run 3 · 22 November 2026

On `11` M1-5 to M1-10's build (ingredient lines and the title by line number, parts only, Load
Test Set, screen kept awake). Per-page table outside git (`SPIKE_3_SCORING.md`).

**Reliability is solved; the line-number changes cost accuracy.**

| Measure | Run 2 | Run 3 |
|---|---|---|
| Captures finished | 22 of 22, 4 with a lost part | 22 of 22, no part errors, retries, fallbacks or rate limits |
| Titles right | 13 of 22 | 7 of 22 |
| Ingredient lines found, printed pages | 118 of 166 | 121 of 166 |
| Quantity right / unit right | 105 / 100 of 115 | 92 / 89 of 118 |
| Non-ingredients in the ingredient list | 14 | 38 |
| Non-Latin lines | 3 read as text | 3 taken out and marked unreadable |
| Structure time | 2.5 to 34 s | 4.5 to 32 s |

Why:
- **Titles by line range** take neighboring lines (a byline, the yield, a blurb, the site's
  name). On 13 pages the model's other-titles answer holds the right title as text: it writes the
  title well and picks line numbers badly. The wrong title also made "may hold other recipes" fire
  on 8 pages, all false.
- **Ingredients by line number** aren't joined across a wrap: the model gives one line per item, so
  wrapped ingredients split in two (four pages), and on one page it joined different ingredients.
- **The line-labels path keeps bullets and the Ingredients heading** in the lines, so the parser
  finds no quantity there (two pages). `PageSplitter` strips them; the labels path doesn't.

### Proposals from run 3 (SP-12 to SP-14): all accepted

| # | Proposal | Fixes |
|---|---|---|
| SP-12 | **Title as text, snapped to the page**: the model writes the title (as in run 2); it is kept only if it matches one line of the header area or two or three lines in a row, and those lines as read become the title; otherwise the largest line near the top | The wrong titles and the false "other recipes" warnings |
| SP-13 | **Wrapped lines joined by rule before numbering**: a line joins the one above when it starts lowercase or with `(`, or the line above ends with `,`, `-`, or a joining word (and, or, such as, plus, of, with, to); then each ingredient is one numbered line | The split and merged ingredients |
| SP-14 | **The line-labels path cleans lines as the splitter does**: bullets removed, heading lines and clutter dropped | The lost quantities on bulleted pages |

Pops accepted all three ("all", 22 Nov 2026), recorded by rewriting SLT-146, SLT-148 and SLT-149;
built by `11` Task M1-11, then run 4.

### Run 4 · 22 November 2026

On `11` M1-11 to M1-13's build (title as text snapped to the page, wrapped lines joined by rule,
labelled lines cleaned). Per-page table outside git (`SPIKE_4_SCORING.md`).

**The best run so far on ingredients; titles are back near run 2 but still the weak spot.**

| Measure | Run 2 | Run 3 | Run 4 |
|---|---|---|---|
| Captures finished | 22 of 22, 4 with a lost part | 22 of 22, no errors | 22 of 22, no part errors, retries, fallbacks or rate limits |
| Titles right | 13 of 22 | 7 of 22 | 11 of 22 |
| Ingredient lines found, printed pages | 118 of 166 | 121 of 166 | 151 of 166 |
| Quantity right / unit right | 105 / 100 of 115 | 92 / 89 of 118 | 139 / 131 of 146 |
| Non-ingredients in the ingredient list | 14 | 38 | 34 (20 on one page) |
| Non-Latin lines | 3 read as text | 3 marked unreadable | 3 marked unreadable |
| Structure time | 2.5 to 34 s | 4.5 to 32 s | 4.5 to 37 s |

Why:
- **Wraps and bullets are fixed.** The pages that lost lines to wrapping or bullets in run 3 are
  whole or nearly whole now.
- **Titles.** Four right titles came only from the largest-line fallback ("title from layout"),
  and the report doesn't hold the model's own title text, so why those didn't snap is unknown.
  Of the 11 wrong, three are a blurb or the magazine's deck chosen over the title, one is the
  first word only, one is a section label, one is a prefix on the title's own line, and one is
  missing the second line of a two-line title. Two more were snapped with the site's name or
  breadcrumbs, then dropped as "not on page: title", because the checker's page text has that
  clutter taken out. The page with no title got its largest line, a step, because an empty answer
  falls back too (`11` M1-11's rule, Claude's spec fault).
- **Ingredient groups.** The model now names most groups after one of their own ingredient lines:
  84 of 161 groups (run 3: 62 of 141; run 2: 0 of 24). The scorer doesn't count groups, but
  review would show one group per ingredient.
- **Repeated lines.** On two pages the model maps the same line up to five times, most of the 34
  non-ingredients.
- **Parser readings** (`06` §1, which Pops asked about): no ingredient line on the 25 pages has the
  shape "A few sprigs mint" or "1-inch piece ginger"; "a few" and "-inch" appear only in steps. The
  test set can't measure them, so a fix would be tested with made-up lines.

### Proposals from run 4 (SP-15 to SP-18): all accepted

| # | Proposal | Fixes |
|---|---|---|
| SP-15 | **Title fixes**: (a) an empty answer means no title, with the warning `no title`, not the largest line; (b) a snapped title is the page's own lines, so the checker doesn't drop it; (c) a snapped run loses its first or last line when that line is clearly smaller than the run's largest (a site name above the title); (d) the report keeps the model's own title text, to show why a title doesn't snap | The page with no title, the two dropped titles, the site name; and what to fix next |
| SP-16 | **Group names by rule**: a group's name is kept only when its line isn't one of the ingredient lines and doesn't start with a number, fraction or bullet; a group that loses its name joins the group before it | One group per ingredient in review |
| SP-17 | **Each line used once**: an ingredient line number already used is skipped | The repeated lines |
| SP-18 | **Parser readings from `06` §1**: "a few" (and "a couple", "several") is not a quantity, and its words stay in the item; a number joined to "-inch" is a size, so "1-inch piece ginger" has no quantity and its item is the whole line | Two lines read oddly, measured only with made-up lines |

Pops accepted all four (decision card, "All four, SP-15 to SP-18", 22 Nov 2026), recorded by
rewriting SLT-146 and SLT-148 and adding SLT-155; built by `11` Task M1-14, then run 5.

### Run 5 · 22 November 2026

On `11` M1-14's build (no title, trimmed and unchecked titles, group names by rule, each line used
once, "a few" and "-inch"). Per-page table outside git (`SPIKE_5_SCORING.md`).

**Ingredients hold at run 4's level and the groups are fixed; titles are the one thing left.**

| Measure | Run 3 | Run 4 | Run 5 |
|---|---|---|---|
| Captures finished | 22 of 22, no errors | 22 of 22, no errors | 22 of 22, no part errors, retries, fallbacks or rate limits |
| Titles right | 7 of 22 | 11 of 22 | 12 of 22 |
| Ingredient lines found, printed pages | 121 of 166 | 151 of 166 | 151 of 166 |
| Quantity right / unit right | 92 / 89 of 118 | 139 / 132 of 146 | 139 / 132 of 146 |
| Non-ingredients in the ingredient list | 38 | 34 | 30 |
| Ingredient groups (named after an ingredient line) | 141 (62) | 161 (84) | 24 (0) |

Why:
- **Groups and repeated lines are fixed.** Each recipe now has the groups the page prints, and
  repeated lines are skipped and flagged (two pages).
- **The model's title text**, now in the report, is usually the whole top of the page, one line
  per printed line: the title, then the byline, the show, the site, the yield. A many-line answer
  can't snap, so three right titles still come from the largest-line fallback.
- **M1-14's size trim cut one right title**: on one typed page the blurb under the title is
  printed larger, so the title line was trimmed off. It did fix the page that starts with the
  site's name.
- **What the model's first line is:** the title on 15 pages; the site's name on two (it matches
  the source URL's host); the first word of a three-line title on one, whose other lines start
  lowercase; a step on the page with no title; and a deck, section label, prize label or
  breadcrumbs on four.

### Proposal from run 5 (SP-19): accepted

| # | Proposal | Fixes |
|---|---|---|
| SP-19 | **The title starts at the model's first line**, in place of M1-14's size trim: (a) the model's answer is split into its lines, and a line that is the site's name (its letters found in the source URL's host) or holds the author's name is dropped; (b) the title starts at the first line left, found on the page; (c) it takes in the next page line, up to three in all, when that line starts lowercase, or when it is the model's next line and printed at nearly the same size (0.8 to 1.25 times); (d) a title that starts with a step number ("4. ") is no title | Expected 17 of 22: the two site-name pages, the larger blurb, the three-line title, the byline pages, the step |

Pops chose SP-19, then run 6 (decision card, "SP-19, then run 6", 22 Nov 2026), recorded by
rewriting SLT-148; built by `11` Task M1-15. After run 6 he decides whether Milestone 1 closes.

### Run 6 · 22 November 2026

On `11` M1-15's build (the title starts at the model's first line; site-name and author lines
dropped). Per-page table outside git (`SPIKE_6_SCORING.md`).

**The best run: titles up to 14 of 22, ingredients unchanged at run 4's level.**

| Measure | Run 4 | Run 5 | Run 6 |
|---|---|---|---|
| Captures finished | 22 of 22, no errors | 22 of 22, no errors | 22 of 22, no part errors, retries, fallbacks or rate limits |
| Titles right | 11 of 22 | 12 of 22 | 14 of 22 |
| Ingredient lines found, printed pages | 151 of 166 | 151 of 166 | 151 of 166 |
| Quantity right / unit right | 139 / 132 of 146 | 139 / 132 of 146 | 139 / 132 of 146 |
| Non-ingredients in the ingredient list | 34 | 30 | 30 |
| Ingredient groups (named after an ingredient line) | 161 (84) | 24 (0) | 24 (0) |

Why:
- **Fixed:** the page that starts with the site's name, the page whose blurb is printed larger,
  and the page whose second line is the author. Three more titles now snap instead of coming from
  the fallback.
- **One regression:** on one page the model's author answer is a single word that is also in the
  title line, so the title line was dropped as a side line.
- **The page with no title still gets a step:** the model's step text doesn't match the page, so
  the largest-line fallback runs, and the step-number check runs only on a snapped title.
- **Left to the model's choice:** a magazine deck, a section label, a prize label and breadcrumbs
  (four pages), plus one handwriting misread. Review (Milestone 3) is where these get corrected.

### Milestone 1's verdict · 22 November 2026

Pops closes Milestone 1 after run 6 (Pops, 22 Nov 2026: "close out milestone 1"; "ok we will
finish the spike"), recorded as SLT-156. **On-device reading and structuring are good enough to
go on**, so no cloud engine (SLT-040 stays closed):
- **Reading:** print is near perfect, at 93 to 386 ms a page. Handwriting is weak, and is a
  secondary case.
- **Ingredients:** 91% of printed lines found, with 95% of quantities and 90% of units right, and
  groups as printed.
- **Titles:** 14 of 22. Review shows each one with its warning (`title from layout`, `no title`),
  so a wrong title is fixed in review, not saved silently.
- **Reliability:** every capture finished in runs 3 to 6, with no errors, retries or rate limits,
  at 4.5 to 37 s of structuring a recipe.

**Carried to Milestone 3** (`11` §1): two title fixes found in run 6 (SP-20: an author answer of
one word doesn't make a line a side line; the step-number check also applies to the fallback);
pages with several recipes (SLT-047); handwriting; and the open proposals TS-5, TS-10, TS-11 and
TS-15.

---


## 8. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.25 | §7: run 6's results and Milestone 1's verdict; SP-20 carried to Milestone 3 | SLT-156 (Pops, 22 Nov 2026: "close out milestone 1"; "ok we will finish the spike") |
| 0.24 | §7: SP-19 accepted | Pops, 22 Nov 2026 (decision card, "SP-19, then run 6") |
| 0.23 | §7: run 5's results (no recipe content) and proposal SP-19 | Pops, 22 Nov 2026: "ok next results ready" |
| 0.22 | §7: SP-15 to SP-18 accepted | Pops, 22 Nov 2026 (decision card, "All four, SP-15 to SP-18") |
| 0.21 | §7: run 4's results (no recipe content) and proposals SP-15 to SP-18 | Pops, 22 Nov 2026: "ok next run done" |
| 0.20 | §7: SP-12 to SP-14 accepted | Pops, 22 Nov 2026: "all" |
| 0.19 | §7: run 3's results (no recipe content) and proposals SP-12 to SP-14 | Pops, 22 Nov 2026: "latest results done" |
| 0.18 | §7: run 3 again (not exported); the one-call path retired | SLT-151 (Pops, 22 Nov 2026 (decision card, "Always use parts; flag it")) |
| 0.17 | §7: run 3 stopped, its faults and SLT-151 to SLT-153 | Pops, 22 Nov 2026: "Got worse. Stopped it taking too long on the failing ones."; decision card, "M1-6: all three fixes" |
| 0.16 | §7: SP-7 to SP-11 accepted | SLT-146 to SLT-150 (Pops, 22 Nov 2026: "All" (spike run 2, `10` §7)) |
| 0.15 | §7: run 2's results (no recipe content) and proposals SP-7 to SP-11 | Pops, 22 Nov 2026: "ok run 2 better" |
| 0.14 | §7: SP-1 to SP-6 accepted | SLT-140 to SLT-145 (Pops, 22 Nov 2026: "all six" (spike run 1, `10` §7)) |
| 0.13 | §7: the rate-limited pages explained by a phone call during the run | Pops, 22 Nov 2026: "I got a phone call during the run" |
| 0.12 | §7: run 1's results (no recipe content) and proposals SP-1 to SP-6 | Pops, 22 Nov 2026: "ok, I added the results from the on device test" |
| 0.11 | §2, §6: the spike runs on Pops's iPhone 18 Pro through `11`'s hidden screen | SLT-017, SLT-093 |
| 0.10 | Unreadable handwriting marked and located (SLT-066); TS-15 proposed: show the cropped image in place | Pops, 21 Nov 2026: "Handwritten that cannot be decoded should be called out and maybe inlined as an image in the recipe view." |
| 0.9 | TS-4, TS-6, TS-7 and TS-14 settled; the §5 closing note rewritten | SLT-062 to SLT-065 (Pops, 21 Nov 2026 (decision cards: "Separate parts", "Keep as printed text", "Its own equipment list", "Real ingredients, marked")) |
| 0.8 | TS-8 settled: split | SLT-071 (Pops, 21 Nov 2026 (decision card, "Split into separate ingredients")) |
| 0.7 | TS-8 partly settled: S/P means salt and pepper, to taste | SLT-070 (Pops, 21 Nov 2026: "S/p salt and pepper to taste") |
| 0.6 | TS-9 settled: `T` tablespoon, `t` teaspoon | SLT-048 (Pops, 21 Nov 2026: "2-T tablespoon, t teaspoon, 12===dozen 3-iPhone 17 pro") |
| 0.5 | TS-13 settled: a page with several recipes, she picks which to save | SLT-047 (Pops, 21 Nov 2026 (decision card, "She picks which to save")) |
| 0.4 | Seven pages added (TP-19 to TP-25): two handwritten, two printed with handwritten additions, a page with four recipes, a step taped on sideways, a magazine page with a shopping sidebar; hard cases H-33 to H-42; TS-12 done; TS-13 and TS-14 proposed | Pops, 21 Nov 2026: "Completely hand written", "Lots of pics and small print", "Another handwritten", "Page 2 sideways note", "Combo printed and hand written", "Dense multiple recipes", "Print it with one handwritten note", "That should be enough…" |
| 0.3 | TS-3 settled: Save asks for a page 2 only when the last page looks unfinished | SLT-046 (Pops, 21 Nov 2026 (decision card, "Only when the page looks unfinished")) |
| 0.2 | One capture is one recipe: TS-1 and TS-2 settled, H-1 and H-2 rewritten; TS-3 becomes when Save asks "Is there a page 2?"; TP-18's missing page noted | SLT-045 (Pops, 21 Nov 2026: "I feel like we import one recipe at a time instead of trying to guess which pages goes with what recipe" → "Sure."); Pops, 21 Nov 2026: "We should prompt for hey is there a page two when they try to save." |
| 0.1 | First version: the set, the rubric, 32 hard cases, proposals TS-1 to TS-12; the pages and answer key placed outside git | Pops, 21 Nov 2026: photographed 18 pages for the accuracy test; chose "Folder beside the repo, outside git" (decision card) |
