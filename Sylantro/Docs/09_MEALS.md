# Sylantro — Meals

**Design idea · a meal made of recipes from the book, like the Thanksgiving pages at the front of
the binder**
Version 0.1 · 21 November 2026 · **Idea, jotted down; nothing ruled.** Everything here is an option
for Pops, marked *(rec.)* where Claude recommends one. No task is written from this document until
Pops rules.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It builds on the recipe model (`01` §4, `06` M1-1), nutrition (`03`) and sharing (`04`), inside
`02_ARCHITECTURE.md`'s layers.

---

## 0. The idea

Pops's partner pulled the recipes for this year's Thanksgiving out of the binder and put them
together at the front: turkey, stuffing, sides, pies. Sylantro should let her do the same: make a
**meal**, give it a name ("Thanksgiving 2026"), and add recipes she already has to it. The meal is
a short list that points at recipes; the recipes themselves stay where they are, once each, in the
library.

Pops, 21 Nov 2026: "Put together a meal made up of recipes on the book. My partner had her recipes
organized at the front of the book for our upcoming thanksgiving meal."

---

## 1. What a meal is *(rec.)*

| Part | What it holds |
|---|---|
| Name | "Thanksgiving 2026", "Sunday dinner" |
| Date | Optional; the day it is served |
| Guests | Optional; how many people, used to scale (§3.2) |
| Courses or sections | Optional; "Mains", "Sides", "Desserts", or none |
| Entries | Each points at one recipe by its `id`, with an optional servings override and a short note ("Grandma's way", "make the day before") |
| Notes | Free text for the whole meal |

**A meal never copies a recipe.** An entry holds the recipe's `id`, so an edit to the stuffing
shows in every meal that has it. A recipe can sit in any number of meals. Deleting a meal never
touches its recipes; deleting a recipe that a meal uses leaves the entry saying the recipe is gone,
rather than silently dropping it *(rec.)*, in the spirit of SLT-031.

---

## 2. How it maps to the existing model

`Recipe` (`06` M1-1) needs **no change**. A meal is a new Domain value beside it, in its own synced
`@Model`, so it is additive and costs no migration of recipes (SLT-014, SLT-015).

| Proposed name | Layer | Shape, roughly |
|---|---|---|
| `Meal` | Domain | `id`, `schemaVersion`, `name`, `date?`, `guests?`, `sections: [MealSection]`, `notes?`, `createdAt`, `updatedAt` |
| `MealSection` | Domain | `id`, `name?` (nil is an unnamed section), `entries: [MealEntry]` |
| `MealEntry` | Domain | `id`, `recipeID: UUID`, `servings: Quantity?`, `note?` |
| `MealModel` | App (synced store) | The `@Model` twin, with the sections as sorted-key JSON `Data` (SLT-061) |

These names are proposals, like `02`'s, and are settled only if Pops takes the idea forward.

**Other ways to model it, for comparison:**

- **A tag** ("thanksgiving") on each recipe. Free today (`Recipe.tags`), but it has no order, no
  date, no per-recipe servings, and no place for a combined list. Fine for "show me holiday
  recipes", not for planning a meal.
- **A collection or folder** with no date or servings: simpler, and the same as a meal with the
  optional fields left empty. A meal covers it.

**The writer.** Meals are written through `RecipeEditor` or a new `MealEditor` (SLT-082, single
store owner); Pops's call.

**The mirror (SLT-050).** Each meal gets a small file in a `Meals/` folder beside `Recipes/`
(`02` §5.4), naming its recipes by title and folder, so the plan survives outside the app too
*(rec.)*.

---

## 3. Natural extensions

Each is a later step, and each could be left out of a first version.

### 3.1 A combined shopping list

Every ingredient across the meal's recipes, scaled (§3.2), with matching items added together
("butter: 1 cup + 1/2 cup + 4 tbsp = 1 3/4 cups + 4 tbsp"). Lines only add when the item and unit
agree; anything Sylantro can't add safely is listed separately, never guessed. Adding across units
(cups and tablespoons, or "2 sticks" and "8 tbsp") needs the conversion tables `03` §6 already
plans, so the full version comes after Milestone 4. Ticking items off, and sending the list to
Reminders or as text, are options.

### 3.2 Scaling to the guest count

A meal for 12 scales each recipe from its `Yield.servings` to the entry's servings (or the meal's
guests). The recipe is never edited; the scaled numbers are shown in the meal and its list only.
A recipe with no servings is shown unscaled and flagged.

### 3.3 PKU totals for the meal (after `03`)

Using `03` §7's per-serving numbers: protein and phenylalanine for **one plate of the whole meal**
(one serving of each dish she marks as on that plate), beside each dish's own figures, each with
its provenance and estimate flags (`03` §7.3, §8). This is the PKU-friendly answer to "how much of
the budget is Thanksgiving dinner", and it points at where a low-protein variant (`03` §11) would
help most. The health caveat (`03` §1) applies.

### 3.4 A cooking timeline

Working back from the serving time with each recipe's `Times` (prep, cook, total): "turkey in at
11:00, pies the day before". `Times` is often missing or loose on printed recipes, so this is a
rough plan she adjusts, not a schedule Sylantro asserts. It is the most speculative extension.

### 3.5 Reusing a meal each year

"Thanksgiving 2026" can be duplicated as "Thanksgiving 2027", keeping the recipes and notes and
clearing the date. Her notes ("doubled the gravy, not enough") carry forward. This is most of what
the binder's front section does, year to year.

### 3.6 Sending a meal

With `04`'s one-recipe file (SLT-100), a meal could be sent as one file holding the meal and its
recipes; on import, each recipe meets SLT-103's duplicate rule. Later, if ever.

---

## 4. Where it fits

- **Screens.** A Meals list beside the library, a meal screen with its sections, and "Add to meal"
  on a recipe. The screens are designed in their own document (`02` §7).
- **When.** After Milestone 3 (extraction and review), once she has recipes to group *(rec.)*. The
  basic meal (§1, §2, §3.5) needs nothing from nutrition; the shopping list's unit math and the PKU
  totals wait for Milestone 4.

---

## 5. Open decisions for Pops

| # | Question | Options |
|---|---|---|
| ML-1 | Take the idea forward, and how far | A basic meal (§1, §2, reuse §3.5) first *(rec.)*; the basic meal plus shopping list; park the idea |
| ML-2 | A meal, a tag, or a plain collection | A meal with optional date, guests and sections *(rec.)*; tags only; a collection with no date or servings |
| ML-3 | Sections in a meal | Optional named sections *(rec.)*; a flat list only |
| ML-4 | When a recipe used in a meal is deleted | The entry stays and says the recipe is gone *(rec.)*; the entry is removed |
| ML-5 | Which extensions, and in what order | Reuse, then shopping list, then PKU totals, then timeline *(rec.)*; another order |
| ML-6 | Where it sits in the milestones | After Milestone 3 for the basic meal, extensions after 4 *(rec.)*; a milestone of its own later |
| ML-7 | The writer for meals | `RecipeEditor` *(rec.: one writer for the library)*; a new `MealEditor` |
| ML-8 | Meals in the mirror | A small file per meal in `Meals/` *(rec.)*; not mirrored |

When Pops rules, the rulings are filed in the ledger as SLT-130 onward at this document's
close-out.

---

## 6. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.1 | First version: the idea, a meal as a list of recipe references, how it maps to the model (no change to `Recipe`), extensions (shopping list, scaling, meal-level protein and phe, a timeline, yearly reuse, sending), and open decisions ML-1 to ML-8 | Pops, 21 Nov 2026: "Here's another feature idea to jot down. Put together a meal made up of recipes on the book." |
