# Sylantro — Ingestion Design

**Design document · printed recipe pages to structured recipes, on the device, without losing
anything**
Version 0.7 · 21 November 2026 · **Rulings in from the design conversation (SLT-020 to SLT-090);
not for the agent until a task names it**

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
The structure it is built in is `02_ARCHITECTURE.md`'s.

---

## 0. What this is

Sylantro's first job: she points her iPhone at a binder page and, a moment later, the page is
safe and on its way to becoming a recipe she can search, scale and, later, count protein and
phenylalanine for. This document fixes what ingestion does, what it stores and why. It was the
design draft "LetsCook ingestion engine: architecture and schema" (21 Nov 2026), rewritten here as
the specification.

**Who it is for.** Pops's partner, on iPhone, with a binder of printed recipes (typed pages,
magazine clippings, some handwritten notes). She lost a previous recipe app's data in an iPhone
upgrade, so durability outranks everything (SLT-030).

**Principles, in priority order:**

1. **Her data outlives the app** (SLT-030). The original photo is never thrown away; an
   open-format copy of every recipe sits in Files; the store is never wiped (SLT-031).
2. **Scanning never waits on processing** (SLT-041). She can shoot 30 pages in a row; reading and
   structuring fill a review inbox behind her.
3. **Nothing is guessed silently** (SLT-042). Every ingredient keeps its verbatim line, a response
   that fails the schema is never saved, and shaky fields are flagged.
4. **Nutrition plugs in later without a migration** (SLT-022). Ingredients carry slots for a food
   match and a gram weight from day one.

---

## 1. Platform (SLT-012, SLT-013)

- iPhone and iPad; the Mac runs the iPad app. Scanning is iPhone and iPad first; the Mac is for
  browsing, editing and cooking from a bigger screen.
- The floor is iOS 26.5 (SLT-013). Foundation Models needs iOS 26 and an Apple Intelligence device: iPhone 15 Pro or newer, or an Apple silicon iPad or Mac.
- Built on sylib-swift, with Score It \* as the template (SLT-080, `02`).

---

## 2. The pipeline (SLT-041)

| Step | What happens | Where | She waits? |
|---|---|---|---|
| 1. Scan | VisionKit's document camera: auto-capture, crop and flatten, many pages per session. A session starts from the **"Let's cook."** scan button (SLT-043) | Capture | Yes |
| 2. Save the page | The original photo and the cropped image are saved as a `SourcePage` in a `ScanSession`, then mirrored to Files. From here the page is safe | Capture | Yes, about a second a page with step 1 |
| 3. Read the text | Vision's text recognition: words, positions, confidence | Background queue | No |
| 4. Structure the recipe | Foundation Models, guided generation into the schema (§3) | Background queue | No |
| 5. Review inbox | The photo beside the fields; shaky fields tinted; tap a field to see where it came from on the photo | Review | She skims |
| 6. Saved recipe | Written through the store's one writer, synced through her iCloud, mirrored as `recipe.json`, `recipe.md` and the photos | App | No |

A 30-page session ends with 30 drafts to skim, not 30 forms to type.

- **Multi-page and multi-recipe pages.** In review she can join a page to the previous recipe, or
  split a page into two recipes. Pages and recipes are many-to-many (§4).
- **Duplicates.** A recipe with a matching title and similar ingredients is flagged before it is
  saved twice. The rule for "similar" is set in the spike (§7).

---

## 3. Turning a photo into a recipe (SLT-040)

### 3.1 The choice

| Approach | Printed pages | Handwriting, odd layouts | Cost | Offline | Privacy |
|---|---|---|---|---|---|
| Vision OCR only, rules-based parsing | High for text, poor for structure | Weak | Free | Yes | On device |
| **Vision OCR + Foundation Models** | Good on simple one-column pages | Weak; small model, short context | Free | Yes | On device |
| Cloud vision model reading the photo and the OCR text | Highest | Good | About a cent or two a page (unverified) | No | Photo leaves the device |

**Ruling: on-device only** (SLT-040). Nothing leaves her devices, there is no per-page cost and no
API key. The cloud row was offered and declined; `Extraction.engine` keeps the door open, and the
question is reopened only if Pops asks.

### 3.2 Reading

Vision returns every word with its bounding box and confidence. The whole result is kept on the
`SourcePage` (`ocrText`, `ocrWords`), so the page never needs to be read again unless the reader
improves.

### 3.3 Structuring

- Foundation Models fills the schema by guided generation. A response that does not match is
  retried, never saved (SLT-042); after the retries it is saved as a page with no recipe, flagged
  for review, and the photo is still safe.
- The model's context is small, so a long recipe is structured in parts (header, ingredients,
  steps) and stitched together.
- **Ingredient lines** are split by the model into quantity, unit, item and preparation; a
  deterministic parser in `Domain/` then normalizes fractions (1 1/2, ½), ranges (2 to 3) and units
  (c., cup, cups) to a canonical list. The verbatim line is always kept.
- Each field carries a confidence; low ones are tinted in review.
- Handwritten notes and multi-column magazine pages will be weaker, so review carries more weight
  there.

### 3.4 A device that can't structure (SLT-044)

A page scanned on a device without Apple Intelligence is saved and read, and marked as waiting for
structuring. A capable device that receives it by sync structures it. Whether a page is waiting is
stored on the synced `SourcePage`, not only in the device-local queue, so every capable device can
find the work (`02` §4).

---

## 4. The data (SLT-060, SLT-061)

What was on the paper is kept apart from what was understood, so a better extractor can re-read the
same photos without a re-scan. One page can hold two short recipes, and one recipe can run onto the
next page.

**CloudKit shapes the models** (SLT-014). Every property is optional or has a default; every
relationship is optional, page to recipe included. Ingredient groups, steps and OCR words are
sorted-key JSON `Data` on their model, not models of their own. That same JSON is what
`recipe.json` holds, so the mirror costs almost nothing extra.

| Entity | Key fields | Why it exists |
|---|---|---|
| `ScanSession` | id, startedAt, pageIDs, binderSection | One batch of scanning, so she can see what came in together |
| `SourcePage` | id, imageFile (original), croppedImageFile, ocrText, ocrWords (text, bounding box, confidence), capturedAt, binderPageLabel, structuringState | The immutable record of the paper; never edited. `structuringState` says whether it is waiting (§3.4) |
| `Recipe` | id, schemaVersion, title, yield, times, ingredientGroups, steps, notes, tags, attribution, sourcePageIDs, reviewState, extraction, createdAt, updatedAt, parentRecipeID | The structured recipe. `parentRecipeID` links a variant, such as a low-protein version, to its original |
| `Yield` | servings (number or range), servingsText, quantity, unit | "Makes 24 cookies" and "Serves 4 to 6" both fit; per-serving nutrition divides by this |
| `Times` | prepMinutes, cookMinutes, totalMinutes, rawText | Parsed where possible, the raw text always kept |
| `IngredientGroup` | name, ingredients | "For the sauce", "For the crust" |
| `Ingredient` | id, rawText, quantity (min, max, isApproximate), unit (canonical and raw), item, preparation, isOptional, note, sourceBox, confidence, foodMatch | "2 to 3 cups flour, sifted" becomes min 2, max 3, cup, flour, sifted |
| `Step` | index, text, groupName, ingredientIDs, sourceBox | Steps point at the ingredients they use, which helps substitutions later |
| `Extraction` | engine (on-device; cloud reserved), modelID, promptVersion, overallConfidence, extractedAt, warnings | Lets a newer extractor re-run only recipes an older one made |
| `reviewState` | needsReview, reviewed, edited | Drives the review inbox |

`Yield`, `Times`, `IngredientGroup`, `Ingredient`, `Step` and `Extraction` are value types inside
`Recipe`'s JSON, not models. A schema change bumps `schemaVersion`, and the JSON mirror always
carries it, so old exports stay readable.

---

## 5. Storage and sync (SLT-050 to SLT-052)

### 5.1 The choice

| Option | Survives app deletion | Syncs her devices | Portable outside the app | Cost and upkeep |
|---|---|---|---|---|
| **SwiftData + CloudKit private database** | Yes, in her iCloud | Automatic | No, Apple's format | Free; the developer account exists |
| Files in iCloud Drive as the source of truth | Yes | Yes, but edit conflicts are messy | Yes | Free; harder to query and search |
| A backend of our own | Yes | Yes | Yes, if exported | A monthly cost, a server, an account |

**Ruling: SwiftData + CloudKit, plus an automatic open-format mirror** (SLT-050). The database gives
fast search and painless sync; the mirror is the copy that survives the app.

### 5.2 Two stores (SLT-051)

Recipes, pages and sessions are in the synced store. The extraction queue and device state are in
a device-only store, as SydeTwo keeps `SydeTwoLocal`. The detail is `02` §5.1.

### 5.3 The mirror (SLT-050, SLT-032, SLT-052)

After every save the app writes, for that recipe, `recipe.json`, `recipe.md` and its original page
photos into a Sylantro folder in her iCloud Drive. If the app ever disappears, the binder is still
in Files, readable by anything. With iCloud off, the same folder is written under On My iPhone, and
the iCloud sheet says that copy goes with the phone. The mirror is written, never read back as the
source of truth; restoring from it is a recovery feature (open decision). The folder layout is
`02` §5.4.

### 5.4 Never wipe the store (SLT-031)

When the store will not open, the app opens a recovery screen that keeps the data: it can open
the store read-only or move the file aside and start fresh only after she agrees, and it tells her
the mirror is intact. It never deletes the store and never traps. The screen's design is `02` §5.3.

### 5.5 iCloud status

SyLibCloud's `CloudAccountStatus` at the root, `ICloudStatusButton` in the main toolbar, and
`ICloudInfoSheet` with Sylantro's own `ICloudInfoContent`. Its wording is Pops's.

### 5.6 Sharing a recipe (SLT-100 to SLT-103)

One recipe at a time, as a file another Sylantro user imports; no shared or public database for
the MVP; a recipe she already has is skipped when clearly the same, otherwise she chooses. The
design is `04_SHARING_DESIGN.md`.

### 5.7 Photos and image storage *(proposed)*

Page scans and dish photos: one photo model, HEIC sizes, device-only thumbnails, JPEG copies in
the mirror, and what CloudKit does with them. The design, and what the spike measures, is
`05_IMAGE_STORAGE_DESIGN.md`.

---

## 6. Nutrition and PKU extension points (SLT-022)

These are empty during ingestion and filled by later features. Nothing about them changes the scan
flow.

| Entity | Key fields | Notes |
|---|---|---|
| `Food` | id, name, source (USDA FoodData Central, package label, custom), per-100 g nutrients (kcal, proteinG, pheMg, …), pheIsEstimated, unitWeights (grams per cup, per each, …) | Phenylalanine is often missing from food tables. A common estimate is about 50 mg per gram of protein, so the flag matters; to confirm with her clinic |
| `FoodMatch` (on `Ingredient`) | foodID, grams, matchConfidence, confirmedByUser | Turns "1 cup flour" into 125 g of a known food |
| `NutritionSummary` (on `Recipe`, cached) | per serving and total protein, phenylalanine, kcal; computedAt; foodDataVersion | Recalculated when an ingredient, a match or the servings change |
| `Substitution` | ingredientID, replacementFoodID, ratio, rationale, source | Powers "make this low-protein"; applying one creates a variant recipe |

---

## 7. Milestones

| # | Milestone | What it holds |
|---|---|---|
| 1 | **Spike and a tested Domain layer** (SLT-090) | 15 to 20 real binder pages (typed, clippings, handwritten) through on-device reading and structuring, scored field by field, to see how much review each page needs. In parallel, as Syderal did, the Domain layer (the recipe types, the ingredient-line parser, unit normalization, the schema check) built and tested before any screen exists |
| 2 | Capture and storage | Batch scanning, `SourcePage` storage, SwiftData + CloudKit, the mirror, the recovery screen. Usable before extraction works, because the photos are safe |
| 3 | Extraction and review | The background queue, structuring with Foundation Models, the review inbox with tap-to-highlight on the photo |
| 4 | Nutrition | Food matching against USDA FoodData Central, grams per ingredient, protein and phenylalanine per serving |
| 5 | PKU tools | A phenylalanine budget view, and low-protein substitutions that create variant recipes |

The spike's real pages and results never enter the repository (`00B` §2); fixtures are made up.

---

## 8. Open questions

- Which iPhone she has. It must support Apple Intelligence (iPhone 15 Pro or newer).
- Roughly how many pages the binder holds, and how many are handwritten.
- Whether her clinic or dietitian uses a specific phenylalanine food list.
- How a recipe is restored from the mirror, and whether the recovery screen offers it.
- The duplicate rule's threshold, set from the spike.
- Sharing's open details: `04` §8. Photos: `05` §9.

---

## 9. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.7 | §5.6 and §5.7 moved to `04` and `05`; pointers left | Pops, 21 Nov 2026 |
| 0.6 | §5.6: an import she already has is skipped when clearly the same, otherwise she chooses | SLT-103 (Pops, 21 Nov 2026) |
| 0.5 | §5.7: dish photos and an image storage plan, proposed (P-1 to P-7), with what was verified about CloudKit assets | Pops, 21 Nov 2026: "Make it so" |
| 0.4 | §5.6: sharing one recipe as a file for the MVP; a shared binder parked; no public database | SLT-100 to SLT-102 (Pops, 21 Nov 2026) |
| 0.3 | §1: the floor is iOS 26.5 | SLT-013 (Pops, 21 Nov 2026) |
| 0.2 | §1: the floor is iOS 26.6 | SLT-013 (Pops, 21 Nov 2026) |
| 0.1 | First version, from the design draft of 21 Nov 2026 and the studio survey: the platform, on-device extraction, the two stores and the mirror, never wiping the store, the schema, and the milestones | Pops, 21 Nov 2026: "write up the design as we have it" |
