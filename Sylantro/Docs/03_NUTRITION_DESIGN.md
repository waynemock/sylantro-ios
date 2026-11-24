# Sylantro — Nutrition Design

**Design document · protein, phenylalanine and general nutrition for recipes that don't print it,
computed on the device**
Version 0.4 · 24 November 2026 · **Draft: not accepted. Phenylalanine and diet features on hold and out of 1.0 (§16).** Every option marked *(rec.)* is
Claude's recommendation, waiting for Pops. Nothing here is a ruling until Pops makes it, and no
task is written from it until then (`00B` §0).

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It fills the slots `01_INGESTION_DESIGN.md` §6 left, inside `02_ARCHITECTURE.md`'s layers.

---

## 0. What this is

Most of the binder's recipes print no nutrition. Sylantro works it out from the ingredient lines
ingestion already produces (amount, unit, food), so every recipe can show **protein and
phenylalanine per serving** (SLT-022), plus general nutrition, without her typing anything but the
occasional confirmation.

**Principles, in priority order:**

1. **An estimate never passes for a measurement.** Every number says where it came from, and a
   value built on an estimate is marked as one, all the way up to the per-serving total.
2. **Protein and phenylalanine are both required.** A recipe never shows one without the other.
   If phe can't be found, it is estimated and flagged (§8), never left blank or silently zero.
3. **Nothing is guessed silently** (SLT-042, carried over). An uncertain food match is asked
   about, not assumed.
4. **On the device** (SLT-040's spirit). The food data ships with the app; no ingredient, recipe
   or match leaves her devices, and nutrition works offline.
5. **Ingestion is untouched.** Nutrition reads what ingestion saved and writes only its own slots
   (`01` §6).

---

## 1. Health caveat

Sylantro's numbers are **estimates for planning, not medical measurements.** Food tables are
averages, recipes vary, cooks vary, and a gram weight for "1 cup flour" is a typical value, not
her cup. **They do not replace the guidance of the family's metabolic clinic or dietitian**, whose
food list, targets and exchange system win wherever they differ from Sylantro's.

How this reaches her is copy, and copy is Pops's (`00B` §2). The design asks for three places:

- a one-time note the first time nutrition is shown;
- a line on every nutrition view ("Estimates. Check with your clinic.", or Pops's wording);
- the About screen, once nutrition ships (SLT-087 is revisited then).

*Open: the wording of all three, and whether the clinic should see the method in §8 before
release.*

---

## 2. The pipeline

| Step | What happens | Layer | Needs her? |
|---|---|---|---|
| 1. Parse | Ingestion has already split each line into quantity, unit, item and preparation (`01` §3.3) | Domain (done by ingestion) | No |
| 2. Match | Each ingredient's item is matched to a food in the bundled food data (§5) | App (search) + Domain (scoring) | Only when the match is uncertain |
| 3. Weigh | Quantity and unit become grams of that food (§6) | Domain | Only when no conversion exists |
| 4. Sum | Grams × per-100 g nutrients, summed over the recipe (§7) | Domain | No |
| 5. Divide | The total ÷ servings, from `Yield` (§7) | Domain | Only when servings are missing |
| 6. Show | Per serving and per recipe, each value with its provenance (§7.3) | Screens | She reads it |

Steps 2 to 5 run in the background after a recipe is reviewed, and again whenever an ingredient,
a match or the servings change. They never run on the capture path (SLT-041).

---

## 3. The food data: USDA FoodData Central

### 3.1 What FoodData Central is (verified 21 Nov 2026)

USDA's FoodData Central (FDC) is the US government's food composition database. Facts checked
against USDA's own pages (sources in §14):

- **License: public domain, CC0 1.0.** "No permission is needed for their use," and USDA asks that
  users list FoodData Central as the source. Bundling it in an app is allowed. [1]
- **Its data types differ in what they carry, and only one reliably carries phenylalanine:**

| FDC data type | Foods | Phenylalanine? | Updated | Download (zipped / unzipped) |
|---|---|---|---|---|
| **SR Legacy** (Standard Reference) | 8,618 in SR27, its last numbered release [5] | **Yes, nutrient 508**, for about 5,175 of SR27's 8,618 foods, a mix of laboratory and calculated values [5] | **Frozen**: "Final release April 2018" [3][4] | CSV 6.7 MB / 54 MB; JSON 12.3 MB / 205 MB [2] |
| Foundation Foods | A few hundred, growing; began with 73 [6] | **Not in its documentation**: proximates, energy, minerals, vitamins and lipids only [6] | April and October [3] | CSV 4.1 MB / 35 MB; JSON 681 KB / 9 MB (release 10/2026) [2] |
| FNDDS (survey foods) | 5,432 foods and drinks, with weights for 22,046 portions [7] | **No.** Energy plus 64 nutrients, no amino acids [7] | Every two years | CSV 200 MB / 1.6 GB; JSON 3.7 MB / 64 MB [2] |
| Branded Foods | Hundreds of thousands of labels | **No.** Label nutrients only | Monthly [3] | CSV 432 MB / 3 GB [2] |

- **The online API** needs a free data.gov key and allows 1,000 requests an hour [1]. Sylantro
  doesn't use it (§4), but it is how a food missing from the bundle could be looked up later, if
  Pops ever wants a network path.

*Not verified:* whether recent Foundation Foods releases include amino acids for some foods despite
the documentation's silence. The data download would settle it; the spike (§12) checks it. The SR27
counts above are from the release before SR Legacy; SR Legacy itself is the same database in its
final form, and its exact counts are checked from the download.

### 3.2 The choice

| Option | Phe coverage | Breadth for home recipes | Upkeep | Notes |
|---|---|---|---|---|
| **A. SR Legacy only** *(rec.)* | Best FDC has: about 60% of foods, including the staples (flour, eggs, milk, meat, legumes) | Broad: raw and cooked staples, baking ingredients, many prepared foods | None: it is frozen | Old (2018), but staples change little. Has household portion weights (§6) |
| B. SR Legacy + Foundation Foods | Same phe; Foundation adds newer, better-measured values for protein and other nutrients | Slightly broader | Twice-yearly refresh, and two records for the same food to reconcile | Worth it only if the spike finds Foundation carries amino acids |
| C. A PKU-specific list from the clinic | Whatever the clinic uses, likely measured phe for PKU-relevant foods | Narrow, but the foods that matter most | Depends on its license and format | Already an open decision (ledger: "Whether her clinic or dietitian uses a specific phenylalanine food list") |
| D. Add Branded Foods | No phe | Huge, but labels only | Monthly | Too big to bundle, and no phe; it adds little for a PKU app |

**Recommendation *(rec.)*:** A now, with the schema keeping `source` per food (`01` §6) so C can be
layered on top later: a clinic value, where one exists, wins over USDA's. B is reconsidered after
the spike.

---

## 4. Keeping it on the device: a trimmed, bundled copy

The whole SR Legacy download is 54 MB of CSV, most of it nutrients Sylantro won't show. The app
ships a trimmed copy built from it once.

**What the trimmed copy keeps** *(rec.)*:

- for each food: its FDC id, its description, its food group, and an alias list (§5.2);
- per 100 g: energy (kcal), protein, **phenylalanine**, total fat, saturated fat, carbohydrate,
  fiber, total sugars, sodium, and the nutrient's provenance (analytical or calculated, as SR
  records it [5]);
- its household portion weights (§6);
- the data's own version (`SR Legacy, April 2018`) and a build date, which go into
  `NutritionSummary.foodDataVersion` (`01` §6).

That is about 8,000 foods × roughly a dozen numbers plus portions. **Estimated size: well under
5 MB** *(not measured; the build of the trimmed file measures it)*.

**Its format** is a decision for Pops, because it shapes the code:

| Option | For | Against |
|---|---|---|
| **A. Sorted-key JSON in the bundle, loaded once into memory** *(rec.)* | Matches SLT-061's JSON habit; no new technology; easy to diff when rebuilt; Domain can test against a fixture of the same shape | Loaded at first use; a few MB in memory; search is done by Sylantro's own index (§5) |
| B. A read-only SQLite file, read with the system's SQLite library | Fast lookups and full-text search built in | New ground for the studio, and a C API in Swift; `00B` §2 makes a new SDK a stop condition, so this needs Pops's yes |
| C. A read-only SwiftData store in the bundle | Same framework as the app | SwiftData's predicates are weak for fuzzy search; a bundled read-only store is new ground too |

**The food data is reference data, not her data.** It is never synced or mirrored, and it is
replaced wholesale when the app updates. Only her own foods and her match choices (§5.3) are hers,
and those live in the synced store.

**Who builds the trimmed file.** It is a one-time conversion from USDA's CSV. Writing that
conversion is code, so it is a task for the Xcode agent once Pops picks the format (SLT-003). The
USDA download itself is public, so the trimmed file may live in git; it is not her data
(`00B` §2's rule is about binder pages).

---

## 5. Matching an ingredient to a food

"2 cups all-purpose flour, sifted" has to become **SR food "Wheat flour, white, all-purpose,
enriched, unbleached"**. USDA's descriptions are long and comma-ordered; recipe items are short and
casual. Matching is the step most likely to be wrong, so it is the step that asks her.

### 5.1 How a match is found *(rec.)*

1. **Her own earlier choice first.** If she has already matched "flour" (§5.3), that is used.
2. **A curated alias table.** A hand-checked list of the few hundred items that fill most home
   recipes ("flour", "AP flour", "butter", "egg", "sugar", "brown sugar", "milk", "heavy cream"...)
   each pointing at one SR food. Built upstream, by Claude from a word count of the spike's
   recipes, checked by Pops, handed to the task as a table (`00A` §2: the agent transcribes, it
   doesn't decide).
3. **Search.** Otherwise, a token search over SR descriptions and aliases, scored in Domain
   (shared words, word order, a penalty for "dry"/"cooked"/"canned" words the item doesn't have).
   Pure Swift, tested with plain values.
4. **Optionally, Foundation Models to rank the top few candidates.** On the device, so SLT-040's
   promise holds. *Open:* whether it is worth it; the spike compares search alone against search
   plus the model on the spike's recipes.

### 5.2 Confidence and confirmation

Each match carries `matchConfidence` (`01` §6). The rule *(rec.)*:

| Confidence | What happens |
|---|---|
| Her own earlier choice, or an alias table hit | Used without asking; shown as matched |
| A clear search winner (above a threshold set in the spike) | Used, shown with a small "check" mark she can tap |
| Anything less, or two close candidates | **Not used until she picks.** The recipe shows "2 ingredients need a match" and its totals are marked incomplete |
| Nothing found | She can pick a food by searching, enter a food from its package label (§9), or mark it "doesn't count" (water, salt for protein, a bay leaf) |

An unmatched ingredient is never counted as zero. The total says how many are missing (§7.3).

### 5.3 Remembering her choices

When she picks a food for an item, Sylantro remembers it (`FoodAlias`: her item text → food id) in
the synced store, so the next "flour" is matched on every device. *(rec.)* This is a small new
synced model, which `01` §6 doesn't list yet (§10).

---

## 6. From amount to grams

Nutrition data is per 100 g, so every ingredient becomes grams. The cases:

| The line says | How it becomes grams | Source of the number |
|---|---|---|
| A weight: "200 g", "8 oz", "1 lb" | Direct conversion | Fixed constants (1 oz = 28.3495 g, 1 lb = 453.592 g) |
| A volume: "2 cups", "1 tbsp", "250 ml" | Volume × that food's density | **SR's portion weight for that food** ("1 cup = 125 g" for flour) where it exists; otherwise a density table built upstream for common liquids and powders; otherwise ask |
| A count: "3 eggs", "1 onion", "2 cloves garlic" | Count × weight of one | **SR's portion weight** ("1 large = 50 g"); size words in the line ("large", "medium", "small") pick the row; no size means the food's "medium" or its first row *(rec.)* |
| A package: "1 can (15 oz) beans" | The weight in parentheses, if any | The line itself; otherwise ask |
| Vague: "a pinch", "to taste", "salt and pepper" | **Zero, and said so** for salt-like items; otherwise ask | A short "counts as zero" list built upstream |
| A range: "2 to 3 cups" | The midpoint for the total, with the range kept | `Quantity` min and max (`01` §4) *(rec.: Pops may prefer the high end for a phe budget, see §13)* |

**Volume units** (cup, tbsp, tsp, fl oz, ml, l, and their spellings) are converted to milliliters
by one constant table in Domain, as `02` §3 already plans for the ingredient-line parser. US
customary is assumed (1 cup = 236.588 ml) *(rec.; the binder is mostly US web recipes)*.

**Where each number comes from is part of the task, not the agent's choice.** `00B` §2 makes "a
unit conversion, gram weight, nutrient value or phenylalanine estimate the task does not give" a
stop condition. So the constant tables (units, densities, "counts as zero", the estimate in §8) are
written out in full in the task that builds them, with their sources.

*Not verified here:* the exact layout of SR Legacy's portion-weight file in FDC's download (SR27's
documentation lists a weight file; the FDC CSV calls it `food_portion`). The build of the trimmed
file confirms the columns.

---

## 7. Totals per serving

### 7.1 The sum

For each counted ingredient: `grams × nutrient per 100 g ÷ 100`, summed per nutrient over the
recipe. Optional ingredients are left out by default and listed *(rec.)*. A "for serving" group
("to garnish") is counted unless she marks it otherwise.

**Raw ingredients, not the cooked dish.** Water lost in the oven changes grams per 100 g of the
finished dish, but not protein or phe in the whole pan, so per-recipe and per-serving totals are
sound without cooking yields. Sylantro never shows "per 100 g of the finished dish" *(rec.)*.

### 7.2 Per serving

`Yield.servings` divides the total. A range ("Serves 4 to 6") shows both ("per serving: 4.1 to
6.2 g protein") *(rec.)*. When the recipe gives no servings, or only "Makes 24 cookies", the total
and per-item numbers show, and she can set servings; her number is stored on the recipe.

### 7.3 Showing provenance

Every displayed value has one of these marks *(rec.; the wording and symbols are Pops's)*:

| Mark | Meaning |
|---|---|
| (none) | Every counted ingredient matched, weighed from a portion or a weight, and measured data |
| ≈ | At least one ingredient's phe was estimated from protein (§8), or a weight came from a density guess |
| Incomplete | At least one ingredient is unmatched; the view lists which |

The per-serving card always shows **protein and phenylalanine side by side, in the same size**,
before calories or anything else (SLT-022). Phe in mg, protein in g, each to a precision Pops
chooses (§13).

---

## 8. When phenylalanine is missing: the estimate

About four in ten SR foods have protein but no phe value [5]. For those, phe is estimated from
protein.

- **The common rule of thumb is about 50 mg of phe per gram of protein.** A PKU education sheet
  from BioMarin gives "1 g Protein = 50 mg Phe (approximately)" [8].
- **It is rough.** Kim and Boutin (2015) found that the commonly used multipliers (30 and 50 mg per
  g) hold for less than 76.3% of the foods they analyzed, and proposed a range of 20 to 65 mg per g
  instead, correct for more than 97%; they found the usual averages for fruits (30) and vegetables
  (40) "more or less accurate" [9].

**The options:**

| Option | For | Against |
|---|---|---|
| **A. 50 mg per g everywhere, always flagged ≈** *(rec. as the starting point)* | Simple, matches what PKU families are commonly taught [8]; errs high for fruit and vegetables, which is the safer side for a phe budget | Wrong by tens of percent for some foods [9] |
| B. Food-group multipliers (fruit 30, vegetables 40, others 50) | Closer for produce [9] | More numbers to source and check; still flagged ≈ |
| C. The clinic's own figures | Whatever the family is already taught | Depends on what the clinic uses (open decision) |

Whichever is chosen, `Food.pheIsEstimated` (`01` §6) is set, and the flag flows up through
`FoodMatch` to the recipe's summary (§7.3). The multiplier and its source are one named constant in
Domain, given in the task, so a clinic correction is a one-line change.

**An aspartame warning *(rec.)*.** Aspartame is a source of phenylalanine. A recipe whose
ingredient matches aspartame, or a diet drink or sweetener she marks as containing it, gets a
warning regardless of the numbers. *(The FDA's "Phenylketonurics: contains phenylalanine" label
rule is from memory, not verified in this pass.)*

---

## 9. Her own foods

Low-protein specialty foods (low-protein flour, pasta, bread mixes) are central to a PKU kitchen and
are not in USDA's data. She adds them as **custom foods** from the package label: name, serving
size in grams, protein and, if printed, phe.

- A label's protein is rounded: a label showing 0 g can hold up to 0.49 g a serving, and 1 g can be
  0.50 to 1.49 g [8]. Sylantro stores what the label says and marks the food "from a label".
- A label with no phe gets the §8 estimate, flagged ≈.
- Custom foods are hers, so they are synced and mirrored (SLT-030), unlike the bundled data.

`01` §6 already allows this: `Food.source` includes "package label" and "custom".

---

## 10. How it fits the schema in `01` and `02`

`01` §6 reserved four slots. This design uses them as they are and proposes small additions, all
**additive** and all optional, so they cost no migration (SLT-014, SLT-015) *(rec.)*:

| `01` §6 entity | Where it lives | Proposed additions |
|---|---|---|
| `Food` | Bundled reference data (§4) for USDA foods; a synced `@Model` (`CustomFoodModel`) for hers | `fdcID`; `portions` (description, grams) replaces `unitWeights`' shape; per-nutrient provenance (measured, calculated, estimated, label); `dataVersion` |
| `FoodMatch` (on `Ingredient`, in `Recipe`'s JSON) | Unchanged: inside `ingredientGroups` JSON | `method` (herChoice, alias, search, model, manual); `gramsSource` (weight, portion, density, herEntry); `excluded` (doesn't count) |
| `NutritionSummary` (on `Recipe`, cached) | Unchanged: cached on `Recipe` | per-nutrient values for the general set (§4); `isEstimated`; `unmatchedCount`; `servingsUsed` |
| `Substitution` | Unchanged | before and after summaries (§11) |
| *(new)* `FoodAlias` | Synced store | her item text → food id (§5.3) |

`recipe.json` carries the matches and the summary already, since they live in the recipe's JSON
(SLT-061), so the mirror shows her nutrition with no extra work. `recipe.md` gains a short
nutrition section, marked as estimates *(rec.)*.

**Layers (`02` §2, SLT-081):**

- **Domain:** `UnitConverter` (weights, volumes, counts), `FoodMatchScorer` (search scoring),
  `NutritionCalculator` (sum, divide, provenance), the phe estimate constant. No frameworks; tested
  with made-up foods and recipes.
- **App:** `FoodDatabase` (loads the bundled file, answers searches), a `NutritionQueue` that
  recomputes summaries in the background, and writes through `RecipeEditor` (SLT-082). Custom foods
  and aliases are written through `RecipeEditor` too, or a new writer if Pops prefers.
- **Screens:** the per-serving card, the "needs a match" picker, the custom food form.

*These type names are proposals, like `02`'s, and are settled when `02` is accepted.*

---

## 11. Later: low-protein substitutions

Once a recipe has numbers, Sylantro can suggest swaps: regular flour → low-protein flour, milk →
a low-protein milk substitute, and show **before and after per serving** for protein and phe.

- A substitution is a food → food pair with a ratio ("1 cup flour → 1 cup low-protein baking mix")
  and a source (her, the clinic, or a built-in list Pops approves).
- Applying one never edits the original recipe: it creates a variant (`parentRecipeID`, `01` §4),
  so the original and the low-protein version sit side by side.
- The suggestion list itself is out of scope here; it gets its own document (`01` §7, Milestone 5).

---

## 12. Milestones and the spike

This is `01` §7's Milestone 4 (nutrition) and the start of 5 (PKU tools). Proposed order *(rec.)*:

1. **A nutrition spike**, alongside or after the ingestion spike: take the spike's recipes, match
   their ingredients by hand and by search, and measure how many need her (§5.2), how many grams
   come from a guess (§6), and how many phe values are estimated (§8). It also checks the two
   unverified facts (§3.1, §6) from the actual download.
2. **The trimmed food file**, in the format Pops picks (§4).
3. **Domain:** `UnitConverter`, `FoodMatchScorer`, `NutritionCalculator`, tested with made-up data.
4. **The per-serving card** and the match picker.
5. **Custom foods**, then **substitutions** (§11).

---

## 13. Open decisions for Pops

| # | Question | Recommendation |
|---|---|---|
| N-1 | Food data source (§3.2) | SR Legacy now; clinic list layered on top when known |
| N-2 | The bundled file's format (§4) | Sorted-key JSON, loaded into memory |
| N-3 | The phe estimate when data is missing (§8) | 50 mg per g protein, flagged ≈; revisit with the clinic |
| N-4 | Whether Foundation Models ranks food matches (§5.1) | Decide from the spike |
| N-5 | How a quantity range is counted (§6) | Midpoint, range kept; or the high end, for a cautious phe budget |
| N-6 | Units for phe: mg, or exchanges, and whose exchange (§7.3) | mg first; exchanges only in the clinic's definition (one US education sheet uses 15 mg phe per exchange [8]; other countries use other sizes) |
| N-7 | Rounding of protein (g) and phe (mg) on screen | Protein to 0.1 g, phe to the nearest 5 mg, pending the clinic |
| N-8 | The caveat's wording and placement (§1) | Pops's copy, in the three places listed |
| N-9 | The aspartame warning (§8) | Yes |
| N-10 | Whether the clinic reviews the method before nutrition ships | Yes, if they're willing |
| N-11 | Whether to pursue a recipe estimate from a nutrition label (§15.1), and when | A candidate for after Milestone 4; not in any milestone now |
| N-12 | Whether to pursue a recipe from a dish photo or menu description (§15.2) | Park the photo path unless SLT-040 is reopened; the menu-text path only as an editable starting list |
| N-13 | How, or whether, phe and PKU tools ship after 1.0, once the hold is lifted (§16) | None: Pops's call after talking to their manager. Not in 1.0 either way (`12` IP-7) |

Already open in the ledger and still needed here: whether the clinic uses a specific phe food list.

---

## 14. Sources

Sources 1 to 9 checked 21 November 2026.

1. USDA FoodData Central, *API Guide* (license, CC0 1.0; attribution requested; API key and rate
   limits). https://fdc.nal.usda.gov/api-guide
2. USDA FoodData Central, *Download Datasets* (formats, sizes, release dates).
   https://fdc.nal.usda.gov/download-datasets
3. USDA FoodData Central, *Data Type Comparison* (update frequency per data type).
   https://fdc.nal.usda.gov/data-documentation
4. USDA FoodData Central, *FAQ* (SR Legacy is final and will not be updated).
   https://fdc.nal.usda.gov/faq
5. USDA ARS, *Composition of Foods Raw, Processed, Prepared: USDA National Nutrient Database for
   Standard Reference, Release 27, Documentation* (8,618 foods; phenylalanine, nutrient 508, for
   5,175; analytical and calculated values; weight file).
   https://www.ars.usda.gov/ARSUserFiles/80400525/data/sr27/sr27_doc.pdf
6. USDA FoodData Central, *Foundation Foods Documentation* (nutrient groups; began with 73 foods;
   "does not provide data on all nutrients"). https://fdc.nal.usda.gov/Foundation_Foods_Documentation
7. USDA ARS, *FNDDS 2021–2023 Factsheet* (5,432 foods; energy and 64 nutrients; 22,046 portion
   weights). https://ars.usda.gov/ARSUserFiles/80400530/pdf/fndds/FNDDS_2021_2023_factsheet.pdf
8. BioMarin, *Methods for Tracking Phe Intake* (1 g protein ≈ 50 mg phe; 15 mg phe = 1 exchange;
   label rounding). https://pku.biomarin.com/en-us/wp-content/uploads/sites/7/2023/02/Methods-for-Tracking-Phe-Intake.pdf
9. Kim, J. and Boutin, M. (2015). "New multipliers for estimating the phenylalanine content of
   foods from the protein content." *Journal of Food Composition and Analysis* 42, 117–119.
   doi:10.1016/j.jfca.2015.03.001 (read from its abstract only).
   https://agris.fao.org/search/ru/records/65df573db766d82b180145b5
10. 21 CFR 101.4, *Food; designation of ingredients* (descending order of predominance by weight;
    the 2 percent or less provision; compound ingredients in parentheses). Checked 24 Nov 2026.
    https://www.law.cornell.edu/cfr/text/21/101.4
11. 21 CFR 101.9, *Nutrition labeling of food* (rounding of calories, fat and sodium read
    verbatim; protein, carbohydrate, sugars and fiber from a summary of the page, to be confirmed
    against the official text). Checked 24 Nov 2026. https://www.law.cornell.edu/cfr/text/21/101.9
12. 21 CFR 172.804, *Aspartame* (the "PHENYLKETONURICS: CONTAINS PHENYLALANINE" statement).
    Checked 24 Nov 2026. https://www.law.cornell.edu/cfr/text/21/172.804

---

## 15. Ideas, not scheduled: working backward to a recipe

Two ideas from Pops (24 Nov 2026), captured so they aren't lost. **Neither is in any milestone,
and neither is in Milestone 3's scope** (`15_MILESTONE_3_REVIEW.md`). Both depend on this
document's food data, matching and estimate (§3 to §8) existing first, so the earliest either
could start is after Milestone 4. Nothing here is a ruling.

### 15.1 From a nutrition label: estimate a product's recipe

**The idea.** She photographs a packaged food's Nutrition Facts panel and ingredient list (a
cracker, a sauce, a low-protein bread mix). Sylantro estimates how much of each ingredient is in
it, as a starting point for a home version, and gives a better phenylalanine estimate than the
label alone.

**Why it is feasible on the device.** Each step uses pieces this design and ingestion already need:

1. **Read the label** with Vision (SLT-040), as a page is read. The panel is a fixed, regulated
   layout, which helps; it is still a spike question how reliably Vision reads small print on a
   curved package.
2. **The ingredient list is ordered.** US labels list ingredients "in descending order of
   predominance by weight" [10]. That ordering is a hard constraint: the first ingredient
   weighs at least as much as the second, and so on. Two exceptions shape the math: ingredients
   at 2% or less (or a stated lower threshold) may come at the end, in any order, after a phrase
   such as "Contains 2 percent or less of" [10], and a compound ingredient may list its own
   ingredients in parentheses [10].
3. **Match each ingredient to a food** (§5), the same as a recipe line.
4. **Solve for proportions.** The unknowns are the grams of each ingredient per serving. The
   label's numbers (calories, fat, saturated fat, carbohydrate, fiber, sugars, protein, sodium)
   must each fall within its **rounding band**: for example, fat is declared to the nearest 0.5 g
   below 5 g and calories to the nearest 5 or 10 [11], and protein to the nearest gram, with
   under 0.5 g allowed to show as zero [8][11]. With the ordering constraints, that is a small
   linear program, a dozen or so unknowns, solvable in plain Swift in Domain with no new
   dependency (`00B` §2).
5. **Report a range, not an answer.** Many mixes fit the same label. Sylantro shows the range
   for each ingredient ("flour 45 to 60%") and the phe range that follows from it.

**PKU relevance.** This is where the idea earns its place:

- **A tighter phe estimate.** The label gives protein only. §8's rule (about 50 mg phe per g
  protein) applied to it is rough [9]. Working out the likely mix lets each ingredient's own phe
  ratio from SR Legacy (§3) apply, so a product that is mostly starch and fruit gets a fruit-like
  ratio rather than a flat 50.
- **The label's own rounding is the floor.** A label showing 0 g protein can still hold up to
  0.49 g a serving [8]; the solver's range makes that visible instead of hiding it.
- **Aspartame is caught directly.** Products with aspartame must carry "PHENYLKETONURICS:
  CONTAINS PHENYLALANINE" [12]. Reading that statement, or "aspartame" in the list, triggers §8's
  warning (N-9) without any math.
- **A path to her own foods.** The result can become a custom food (§9), flagged as estimated.

**Limits, stated plainly.**

- Ingredients the food data doesn't know (flavorings, "natural flavors", gums, specialty
  low-protein starches) can't be matched, so they widen the range or stay unknown.
- Processing changes weight (baking loses water), so proportions are of the ingredients as
  bought, not of the product as eaten. Per serving protein and phe are unaffected (§7.1).
- Manufacturers may declare a value somewhat off the true one; FDA's compliance rules allow
  some tolerance (not verified in this pass), which widens every band.
- The result is a formula estimate, not a method: it has no steps, temperatures or times.
- Everything it shows is an estimate under §1's caveat, never a measurement.

**What it would add to the schema** *(rec., additive only)*: a `LabelScan` (the photo, its OCR,
the parsed panel and list), and on a custom food (§9) the solved range and a link to its scan.
No change to `Recipe`.

### 15.2 From a photo of a dish, or a menu description

**The idea.** She photographs a plate at a restaurant, or types or photographs the menu's
description ("pan-seared salmon, lemon butter, wild rice pilaf"), and Sylantro proposes a likely
recipe and an estimate of protein and phe.

**Far less certain than 15.1.** A label carries numbers and an ordered list; a plate carries
neither. Sylantro would have to guess the ingredients, their amounts and the portion from what
the food looks like, and every guess compounds. For phe, where a budget is counted in tens of
milligrams, an estimate that can be off by half is not one to plan a day on.

**It probably needs a bigger model than SLT-040 allows.**

- Reading a dish from a photo needs a vision-language model. Apple's on-device Foundation Models
  takes text, as Sylantro uses it today *(image input is not verified either way for iOS 27)*,
  and Vision's built-in image classification gives broad labels ("salmon", "salad") with no
  amounts.
- A cloud vision model would do it far better, but SLT-040 rules extraction on-device only, and
  says the cloud question is reopened only if Pops asks. Pursuing the photo version is that
  question.

**What on the device could do:** the **menu text** path. A menu description is text, so the
on-device model could suggest a starting ingredient list for her to edit, with no amounts it
can't justify; she would weigh or estimate the portion herself. Every number would carry §7.3's
"≈" mark and §1's caveat.

**Recommendation** *(rec.)*: keep 15.1 as a candidate for after Milestone 4; park 15.2's photo
path unless Pops reopens SLT-040; consider 15.2's menu-text path only as a "start a recipe from a
description" helper, never as a source of trusted phe numbers.

---

## 16. On hold: how PKU features might ship, options for later

**Pops put the phenylalanine and diet features on hold on 24 Nov 2026**, for two reasons in their
own framing: they need to clear an app that veers into medical territory with their employer first,
and giving advice on PKU diets is outside their expertise, so the feature may stay within the
family.

**What the hold means (Pops, 24 Nov 2026):** the PKU features are not part of the MVP's initial
App Store release, but Pops still wants to experiment with them, after other work is built first.
General figures such as protein per serving seem possible for 1.0 (whether they are in it is
`12`'s IP-10). Direct PKU features, such as converting a recipe to a low-protein version (§11),
come later. In `12`, PKU tools (M5) now follow 1.0 (IP-7).

Until Pops lifts the hold, nothing in this document that touches phenylalanine, diet
budgets, substitutions or §15's phe estimates is expanded, scheduled or turned into a task. The
parts that are general nutrition (§2 to §7 without phe, §9's custom foods) stay as designed.

The options below are for Pops to consider later. **None is recommended and none is a decision.**
They can be combined.

| Option | What ships in the App Store build | What the family gets | Notes |
|---|---|---|---|
| A. Phe family-only, behind a flag | General nutrition (calories, protein, fat, carbohydrate, fiber, sugars, sodium) per serving | The same build with phe and the PKU tools switched on, by a build flag or a family TestFlight build | The flag is a build-time switch, not a hidden setting a stranger could find. Protein stays public, since it is ordinary nutrition |
| B. Phe as data only, no advice | Phe per serving shown as a food-table number with its source and "≈" mark, like any other nutrient | Same as the store | No budgets, targets, "safe" or "low" labels, warnings framed as guidance, or substitution suggestions; the app reports numbers and never recommends |
| C. No phe in the store build | General nutrition only | Phe and PKU tools in a family build (as A) | The simplest store app to explain; the schema's phe fields stay, empty and unused in the store build, so nothing migrates later |
| D. No nutrition in the store build at all | The binder app only (`12`'s IP-7, which puts nutrition in 1.0, would be revisited) | A family build with nutrition and PKU tools | Removes every nutrition question from the public app; costs the most if nutrition is wanted publicly later |
| E. Family-only app | Nothing nutrition-related; or no store release of these features ever | Everything, in a build that never goes to the App Store | Keeps Sylantro's public scope where it is today |

**What doesn't change under any option:** the schema's slots (`01` §6, §10 here) stay, because
they are additive and empty, and the ingestion work in Milestones 1 to 3 is unaffected.

**What this document doesn't answer:** whether any option counts as medical software, and what
their employer's policy allows. Those are questions for their manager and, if needed, someone who
knows the regulations; Claude has not researched them and offers no view on them.

---

## 17. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.4 | §16: the hold clarified. The PKU features are out of the initial App Store release and follow it; Pops will experiment with them after other work; protein per serving may be in 1.0 (`12` IP-10); converting a recipe comes later. N-13 reworded | Pops, 24 Nov 2026: "It’s just not gonna be part of mvp inital App Store release. I do wanna play around with it. Just build other stuff first." |
| 0.3 | §16 added: the phe and diet features put on hold by Pops pending their employer and the question of giving diet advice; five options for how they might ship (A to E), none recommended; N-13 | Pops, 24 Nov 2026: "giving advice on pku diets is way outside my wheelhouse. Might need to keep this feature within the family." |
| 0.2 | §15 added: two unscheduled ideas, a recipe estimate from a nutrition label (feasible on the device; tighter phe from the ingredient order and label rounding) and a recipe from a dish photo or menu description (far less certain; the photo path needs a model SLT-040 rules out); N-11 and N-12; sources 10 to 12. Neither idea is in Milestone 3 or any milestone | Pops, 24 Nov 2026: "Scan a foods nutrition label and try to reverse engineer its recipe." and "Or even from a photo of a dish and maybe menu description." |
| 0.1 | First draft: USDA SR Legacy as the source, a trimmed bundled copy, matching with her confirmation, grams from portions and densities, protein and phe per serving with provenance, the 50 mg per g estimate flagged, custom foods, and substitutions as variants. Not accepted; open decisions N-1 to N-10 | Pops, 21 Nov 2026: "Start a write up for this." |
