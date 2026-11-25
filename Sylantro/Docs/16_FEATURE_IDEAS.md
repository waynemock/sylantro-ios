# Sylantro — Feature Ideas

**Design ideas · what popular recipe apps offer beyond reading a recipe, and how each would fit
Sylantro**
Version 0.2 · 25 November 2026 · **Ideas list; three rulings in (SLT-170 to SLT-172); FI-11 placed in M3 (`15` RV-37).** Everything
else is an option for Pops, marked *(rec.)* where Claude recommends one. No task is written from
this document until Pops rules and places the feature in `12` §2.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It builds on the recipe model (`01` §4, `06` M1-1) and `02_ARCHITECTURE.md`'s layers; its
placement lives in `12_IMPLEMENTATION_PLAN.md` (IP-3, IP-4).

---

## 0. What this is

Pops asked what else popular recipe apps do (Pops, 24 Nov 2026: "Given all you know about
everything, what other features do popular recipe apps have. Keep it public info."). This
document notes every one, from public descriptions of apps such as Paprika, Mela, Crouton, NYT
Cooking and Apple's own apps, and says for each how it would sit in Sylantro: what it reuses, what
it adds, and what it would need ruled. Nothing here is copied from any app's design; these are
features common across the category.

Sylantro's own rulings still hold over every idea: on-device only (SLT-040), her data outlives the
app (SLT-030), one writer per store (SLT-082), and nothing guessed silently (SLT-042).

---

## 1. Rulings (Pops, 24 Nov 2026)

Source for all three: Pops, 24 Nov 2026: "Note them all somewhere appropriate. Cook mode and
scaling seems mvp, import least interesting to me but good to include eventually".

| ID | Ruling |
|---|---|
| SLT-170 | **Cook mode is in 1.0** (§2.1). What it holds and which milestone builds it are open (FI-1, FI-2). |
| SLT-171 | **Scaling a recipe is in 1.0** (§2.2). How it scales and which milestone builds it are open (FI-1, FI-3); unit conversion is a separate question (FI-4). |
| SLT-172 | **Importing from other recipe apps comes eventually, at the lowest priority** (§2.5). It is not placed in a milestone. |

---

## 2. The features

### 2.1 Cook mode *(in 1.0, SLT-170)*

**What apps do.** A full-screen view for cooking from: the screen stays on, text is large, the
steps come one at a time (swipe or tap to move on), the ingredients can be ticked off as they go
in, and a time named in a step ("bake 25 minutes") is a button that starts a timer. Some show the
step's own ingredients beside it, and some keep timers running on the Lock Screen as a Live
Activity or on the Watch.

**In Sylantro.**

- Reuses SyLib's `ScreenAwake`, already used by the spike sheet (`11` M1-10). The app shell left
  out Keep Screen On (SLT-086); cook mode brings it back for this one screen only.
- Steps already carry their heading (`groupName`); a step's ingredients would need a match from
  step text to ingredient lines, which is new (FI-2).
- Times in steps would be found by a Domain rule, as yield and times are (SLT-143), never by the
  model, and a time it can't read is simply not a button (SLT-042).
- Ticks are cooking state, not recipe data: device-only, cleared when she leaves *(rec.)*, so
  nothing is synced or mirrored.
- The page photo stays a tap away, so she can check the original while cooking (SLT-030).

### 2.2 Scaling and unit conversion *(scaling in 1.0, SLT-171)*

**What apps do.** Change the servings (or pick ½×, 2×, 3×) and every quantity is recomputed and
shown as a kitchen fraction. Many also switch between US and metric units.

**In Sylantro.**

- Scaling reuses `Quantity` (min, max, approximate) and `Yield.servings` from M1-1. The scaled
  numbers are shown only; the recipe is never edited, as `09` §3.2 already proposes for meals.
- A recipe with no servings scales by a factor only *(rec.)*. Lines with no quantity ("salt to
  taste") stay as written; pan sizes, times and temperatures are not scaled, and a scaled view says
  so in one line *(rec.)*.
- Display rounds to kitchen fractions (⅛, ¼, ⅓, ½, ⅔, ¾) and sensible units (3 tsp shows as 1 T)
  *(rec.)*; the line as printed stays visible on request (SLT-042).
- **Unit conversion** within volume or within weight is simple arithmetic on `CanonicalUnit`.
  Volume to weight ("1 cup flour" to grams) needs densities, which `03` §6 will hold for nutrition
  and `06` M1-2 forbids in the parser. So conversion is its own question (FI-4).
- Meals (`09` §3.2) and the grocery list (§2.3) both build on this.

### 2.3 Grocery list

**What apps do.** Add a recipe's ingredients to a list, merge matching items ("2 onions" and "1
onion" become 3), sort by store aisle, tick items off in the store, and often sync the list to
Apple's Reminders so the family shares it.

**In Sylantro.**

- `09` §3.1 already proposes a combined shopping list for a meal; a single recipe's list is the
  same feature with one recipe.
- Merging needs the item part of each line, which structuring fills (`item`), and unit math from
  §2.2.
- Two ways to hold it: Sylantro's own list (a synced model, one writer), or a list written to
  Reminders through EventKit, which asks her permission and is shared with the family through
  Reminders' own sharing (FI-5). Aisle sorting needs a small built-in item-to-aisle table.

### 2.4 Organizing: tags, favorites, ratings, notes and history

**What apps do.** Tags or categories, a favorites star, a star rating, her own notes on a recipe,
"cooked on" dates, and sorting or filtering by any of them.

**In Sylantro.**

- `Recipe.tags` and `notes` already exist (M1-1); `notes` holds what was printed, so her own
  notes would be a separate field so the two never mix *(rec.)*.
- Favorites, rating and cooked-on dates are small optional fields, added additively before the
  Production schema is deployed (SLT-015).
- Search and sort are `15` RV-16's; filters by tag, favorite or rating extend it.
- A "cooked it" button fits cook mode's last step (§2.1).

### 2.5 Import from other recipe apps *(eventually, SLT-172)*

**What apps do.** Read another app's export so a library moves over in one step. Paprika and Mela,
for example, export recipe files that other apps import.

**In Sylantro.**

- The receiving path is sharing's (`04` §3) and the duplicate check is SLT-103's. Each imported
  recipe arrives already structured, so it goes to review only if a field fails the schema check.
- Formats are to be checked against a real export before any task: the public descriptions say
  Paprika's export is an archive of compressed JSON recipes with photos and Mela's an archive of
  JSON recipes. Which apps, and when, are open (FI-7).
- Web and Apple News import (`08`, M7) is a different way in and is already placed.

### 2.6 Pantry: "what can I make?"

**What apps do.** Keep a list of what's in the house and suggest recipes that use it, or flag what
is missing.

**In Sylantro.** It needs ingredient items matched to a common food, which is nutrition's food
matching (`03` §5). It is the furthest from the binder's purpose and needs the most new data, so
parking it is an option (FI-8).

### 2.7 Apple extras

**What apps do.** Siri and Shortcuts ("show me the lasagna recipe"), Spotlight search of recipes,
widgets (a recipe of the day, the grocery list), the iPad's side-by-side windows (a recipe beside
the list), Live Activities for timers, and Apple Watch apps for steps and timers.

**In Sylantro.**

- App Intents give Siri, Shortcuts and Spotlight from one piece of work. Spotlight in particular
  fits a binder: she finds a recipe from the Home Screen.
- iPad windows come largely from the split view the shell already has (SLT-086); several windows at
  once is a scene setting to rule.
- Widgets and Live Activities need a widget extension target and an App Group (an entitlements
  change, `00B` §2), as `08`'s share extension does.
- **A Watch app is a new platform.** SLT-012 lists iPhone, iPad and the Mac running the iPad app;
  a watchOS target would change that ruling, so it is Pops's to reopen (FI-9).

### 2.8 Export and print

**What apps do.** Print a recipe on a clean page, make a PDF, or export the whole library.

**In Sylantro.**

- The mirror already writes `recipe.md` and `recipe.json` for every recipe (SLT-050), so the
  library is exported all the time.
- A print layout and a PDF are one piece of work (the same page, rendered); `04` §2.3's option C
  already offers a PDF to people without Sylantro (SH-3).
- Printing the original page photo is also a choice, since that is her binder page as it was.

### 2.9 Marking a missed line (FI-11, Pops's idea)

**The idea** (Pops, 25 Nov 2026): "a way to 'train' the algorithm from the outside in… tap a row
in the scan, like a missed ingredient, and mark it what it is, like ingredient, step, etc. this
would be a good feature for the shipped app too since our reader will never be perfect."

**In Sylantro.**

- The on-device model isn't trained on the phone. Her marks improve Sylantro the way the spike
  does: they become examples, and the rules and prompts are fixed against them (as M3-3e's
  put-back walk was).
- **For her:** in Edit, tap a line on the page that the reading missed and say what it is
  (Ingredient, Step, Note, Title, or not part of the recipe). It goes into the recipe at its
  place, in the page's own words and with its outline, so there is nothing to type. Put-back
  (RV-29) guesses lines back; this lets her say.
- **For tuning (TestFlight builds, behind `AppConfig.AccuracySpike.isEnabled`):** a corrections
  file (each marked line, what the reading made of it, what she said it is) that Pops saves to
  `sylantro-testpages/results/`, outside git (SLT-092), scored like a spike run; a corrected
  recipe can also join the test set.
- **Privacy:** logs never carry recipe text, so corrections aren't logged. In the shipped app
  marks stay on her device; nothing is sent; an export happens only when she taps Share herself.

---

## 3. How it fits the other documents

- `09` (meals): the shopping list (§2.3) and scaling (§2.2) are shared; if scaling is built first
  for 1.0, meals reuses it.
- `04` (sharing): import from other apps (§2.5) reuses its receiving path; printing (§2.8) overlaps
  SH-3.
- `03` (nutrition): densities for conversion (§2.2) and food matching for the pantry (§2.6).
- `13` (screens): cook mode and the scaling control are new screens and wording, specified there
  before any is built (`02` §7).
- `12`: each feature here is an idea in `12` §3 until Pops places it in §2 (IP-4).

---

## 4. Open decisions for Pops

| # | Question | Options |
|---|---|---|
| FI-1 | Where cook mode and scaling are built (both in 1.0) | A milestone of their own after M3, since both need structured recipes *(rec.)*; inside M3; with M6 |
| FI-2 | What cook mode holds in 1.0 | Screen awake, large text, one step at a time, ingredient ticks, timers from step text *(rec.)*; also each step's own ingredients; also timers on the Lock Screen (a Live Activity, needs an extension) |
| FI-3 | How scaling works | By servings and by factor, kitchen fractions, the recipe never edited *(rec.)*; by factor only |
| FI-4 | Unit conversion (US and metric) | Not in 1.0 *(rec.)*; within volume and within weight only in 1.0; full conversion with densities after nutrition |
| FI-5 | A grocery list, and where it lives | Later, with meals' shopping list (`09` ML-5) *(rec.)*; Sylantro's own list; written to Reminders |
| FI-6 | Which organizing features, and when | Favorites and her own notes in 1.0, ratings and cooked-on dates later *(rec.)*; all in 1.0; none until asked |
| FI-7 | Which apps to import from, and when | Paprika and Mela after 1.0, formats checked against real exports first *(rec.)*; others as asked |
| FI-8 | The pantry | Park it *(rec.)*; after nutrition's food matching |
| FI-9 | Which Apple extras | App Intents (Siri, Shortcuts, Spotlight) after 1.0 *(rec.)*; widgets; a Watch app (reopens SLT-012) |
| FI-11 | Marking a missed line (§2.9) | **Ruled: in M3, after M3-5** (`15` RV-37, task M3-5a), with the TestFlight corrections file. Pops, 25 Nov 2026 (decision card, "In M3, after M3-5") |
| FI-10 | Export and print | A print layout and PDF together, after 1.0 *(rec.)*; with sharing (M6, SH-3) |

When Pops rules, the rulings are filed in the ledger as SLT-173 onward at this document's
close-out.

---

## 5. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.2 | §2.9 and FI-11: marking a missed line on the page, placed in M3 after M3-5 | Pops, 25 Nov 2026: "I think we need a way to 'train' the algorithm from the outside in…"; decision card, "In M3, after M3-5" |
| 0.1 | First version: eight feature areas from popular recipe apps, how each fits Sylantro, SLT-170 to SLT-172, open decisions FI-1 to FI-10 | Pops, 24 Nov 2026: "Given all you know about everything, what other features do popular recipe apps have. Keep it public info." → "Note them all somewhere appropriate. Cook mode and scaling seems mvp, import least interesting to me but good to include eventually" |
