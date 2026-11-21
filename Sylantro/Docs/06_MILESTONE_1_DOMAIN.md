# Sylantro — Milestone 1: The Domain Layer

**A Syzygy Softwerks task document · the recipe types and the ingredient-line parser, before any
screen**
Version 0.2 · 21 November 2026 · Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md`,
`00B_SYLANTRO_GUARDRAILS.md` and `02_ARCHITECTURE.md` §2 and §3.

---

## 0. What this is

Milestone 1 is an accuracy spike and a tested Domain layer (SLT-090). This document holds the
Domain half: two tasks, taken one at a time, in order.

- **Task M1-1:** the recipe value types and their JSON.
- **Task M1-2:** the ingredient-line parser.

Both are plain Swift in `Domain/`, tested with plain values. Neither touches a view, the store, the
camera, Vision or Foundation Models (SLT-081). Neither changes any `@Model`, `Item.swift`, the store,
a build setting, the entitlements or SyLib.

**Pops accepted `02` §3's Domain type names on 21 November 2026 (SLT-091)** (`Recipe`, `Yield`, `Times`,
`IngredientGroup`, `Ingredient`, `Quantity`, `UnitRef`, `Step`, `Extraction`, `ReviewState`,
`IngredientLineParser`). This document adds `SourceBox`, `CanonicalUnit`, `RecipeJSON` and
`ParsedLine`, which `02` §3 does not name; SLT-091 accepts them too. Both tasks may run, M1-1 first.

**Rules for both tasks:**

- Every type and extension in `Domain/` is declared `nonisolated` and conforms to `Sendable`, so the
  extraction queue can use it off the main actor (the app's default isolation is `MainActor`,
  SLT-012). Score It \*'s Domain does the same (`nonisolated enum SetupRules`).
- `Domain/` imports `Foundation` only (SLT-081).
- One type per file, the file named for the type.
- Tests use Swift Testing (`00B` §3), in `SylantroTests/Domain/`, and import the app with
  `@testable import Sylantro`. Every fixture is made up (`00B` §2).
- `Domain/`, `Domain/Recipe/`, `Domain/Parsing/` and `SylantroTests/Domain/` are new folders, named
  here, so creating them is not a stop condition (`00A` §10). The project's folders are synchronized,
  so `project.xcproj` does not change.

---

### Task M1-1 · Sylantro · The recipe value types and their JSON

**Inputs:** `00`, `00A`, `00B`, `02` §2 and §3, `01` §4, this document.

**Deliverable:** the types below in `Sylantro/Domain/Recipe/`, `RecipeJSON` beside them, and
`SylantroTests/Domain/RecipeJSONTests.swift`.

**The types.** Every one is a `nonisolated struct` (or `enum` where shown) conforming to `Codable`,
`Sendable` and `Equatable`, with a memberwise `init` whose parameters, in the order listed, default to
the value in the Default column. Property names are the JSON keys.

`Recipe` (`Recipe.swift`):

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Required when decoding |
| `schemaVersion` | `Int` | `Recipe.currentSchemaVersion` | `static let currentSchemaVersion = 1` |
| `title` | `String` | `""` | |
| `yield` | `Yield?` | `nil` | |
| `times` | `Times?` | `nil` | |
| `ingredientGroups` | `[IngredientGroup]` | `[]` | |
| `steps` | `[Step]` | `[]` | |
| `notes` | `String?` | `nil` | |
| `tags` | `[String]` | `[]` | |
| `attribution` | `String?` | `nil` | "From Aunt May", a cookbook's name |
| `sourcePageIDs` | `[UUID]` | `[]` | The `SourcePage`s it was read from (SLT-060) |
| `reviewState` | `ReviewState` | `.needsReview` | |
| `extraction` | `Extraction?` | `nil` | |
| `createdAt` | `Date` | `Date()` | |
| `updatedAt` | `Date` | `Date()` | |
| `parentRecipeID` | `UUID?` | `nil` | A variant's original |

`Yield` (`Yield.swift`):

| Property | Type | Default | Notes |
|---|---|---|---|
| `servings` | `Quantity?` | `nil` | "Serves 4 to 6" is min 4, max 6 |
| `amount` | `Quantity?` | `nil` | "Makes 24": 24 |
| `amountUnit` | `String?` | `nil` | "cookies" |
| `rawText` | `String?` | `nil` | As printed |

`Times` (`Times.swift`): `prepMinutes: Int?`, `cookMinutes: Int?`, `totalMinutes: Int?`,
`rawText: String?`, each defaulting to `nil`.

`IngredientGroup` (`IngredientGroup.swift`): `id: UUID` (default `UUID()`), `name: String?`
(default `nil`; nil is an unnamed group), `ingredients: [Ingredient]` (default `[]`).

`Ingredient` (`Ingredient.swift`):

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | |
| `rawText` | `String` | `""` | The verbatim line (SLT-042) |
| `quantity` | `Quantity?` | `nil` | |
| `unit` | `UnitRef?` | `nil` | |
| `item` | `String?` | `nil` | "flour" |
| `preparation` | `String?` | `nil` | "sifted" |
| `isOptional` | `Bool` | `false` | |
| `note` | `String?` | `nil` | |
| `sourceBox` | `SourceBox?` | `nil` | |
| `confidence` | `Double?` | `nil` | 0 to 1 |

`Quantity` (`Quantity.swift`): `min: Double` (no default), `max: Double?` (default `nil`; nil is a
single value), `isApproximate: Bool` (default `false`).

`UnitRef` (`UnitRef.swift`): `canonical: CanonicalUnit?` (default `nil`; nil is a unit Sylantro
doesn't know), `raw: String` (no default; as written, "Tbsp.").

`CanonicalUnit` (`CanonicalUnit.swift`): a `nonisolated enum CanonicalUnit: String, Codable,
Sendable, CaseIterable` with these cases, raw values equal to the case names, in this order:
`teaspoon`, `tablespoon`, `cup`, `fluidOunce`, `pint`, `quart`, `gallon`, `milliliter`, `liter`,
`ounce`, `pound`, `gram`, `kilogram`, `pinch`, `dash`, `clove`, `can`, `package`, `stick`, `slice`.
No conversion factors: those belong to the nutrition task (`03` §6, `00B` §2).

`Step` (`Step.swift`): `id: UUID` (default `UUID()`), `index: Int` (default `0`), `text: String`
(default `""`), `groupName: String?` (default `nil`), `ingredientIDs: [UUID]` (default `[]`),
`sourceBox: SourceBox?` (default `nil`).

`SourceBox` (`SourceBox.swift`): `pageID: UUID`, `x: Double`, `y: Double`, `width: Double`,
`height: Double`, none defaulted. Normalized 0 to 1, origin top left, on the cropped page image.

`Extraction` (`Extraction.swift`): `engine: String` (default `Extraction.onDeviceEngine`, with
`static let onDeviceEngine = "onDevice"`; a string, so a future engine's value survives),
`modelID: String?`, `promptVersion: Int?`, `overallConfidence: Double?`, `extractedAt: Date?`
(each default `nil`), `warnings: [String]` (default `[]`).

`ReviewState` (`ReviewState.swift`): `nonisolated enum ReviewState: String, Codable, Sendable,
CaseIterable` with `needsReview`, `reviewed`, `edited`. Its `init(from:)` decodes a single string
and gives `.needsReview` for any value it doesn't know.

**Decoding rule (every struct above).** Write `init(from decoder:)` by hand: each property is
`decodeIfPresent` and falls back to its Default column, so a file missing a key, from an older or
newer app, still reads (SLT-061, `04` SLT-100). The exceptions, which use `decode` and throw when
missing: `Recipe.id`, `Quantity.min`, `UnitRef.raw`, and all five of `SourceBox`'s properties.
Unknown keys are ignored. Encoding is synthesized.

**`RecipeJSON`** (`RecipeJSON.swift`), a `nonisolated enum`:

- `static func encode(_ recipe: Recipe) throws -> Data`: a `JSONEncoder` with
  `outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]` and
  `dateEncodingStrategy = .iso8601`.
- `static func decode(_ data: Data) throws -> Recipe`: a `JSONDecoder` with
  `dateDecodingStrategy = .iso8601`.

Each makes its coder inside the function; no shared mutable state.

**Tests** (`SylantroTests/Domain/RecipeJSONTests.swift`, `@Suite("Recipe JSON")`). Dates in
fixtures are whole seconds (`Date(timeIntervalSince1970: 1_795_000_000)`), since `.iso8601` drops
fractions. One fixture, `full`, sets every property of every type to a non-default value, including a
two-group recipe with a ranged, approximate, optional ingredient with a `sourceBox`, and a step
pointing at it. Tests, named for the rule:

1. "a recipe survives a round trip": `decode(encode(full)) == full`.
2. "keys are sorted and the schema version is written": the encoded string contains
   `"schemaVersion" : 1`, and the index of `"attribution"` is before the index of `"createdAt"`,
   which is before `"title"`.
3. "a file with only an id reads with every default": decoding
   `{"id":"8D5E1B3C-2F4A-4B6E-9C1D-7A8B9C0D1E2F"}` gives that id, `schemaVersion` 1, `title` "",
   empty arrays, nil optionals and `.needsReview`.
4. "a file without an id is refused": decoding `{"title":"Soup"}` throws.
5. "an unknown key is ignored": `full`'s JSON with `"futureField":true` added at the top level decodes
   equal to `full`.
6. "an unknown review state reads as needs review": a recipe whose `reviewState` is `"archived"`
   decodes with `.needsReview`.
7. "an unknown engine survives": an `Extraction` with `engine` `"futureEngine"` round-trips with that
   value.
8. "an unknown unit spelling has no canonical unit": a `UnitRef` with `raw` "handful" and no
   `canonical` round-trips with `canonical` nil.

**Done when:**

1. The 13 files above exist in `Sylantro/Domain/Recipe/`, each importing `Foundation` only, every
   type and extension `nonisolated`.
2. The 8 tests exist, named as above, and pass.
3. Sylantro builds with no new warnings, and the suite passes on the pinned destination (`00B` §5.2).
   The total is the previous run's 5 plus 8: **13**. The summary reports the destination string and
   the run's own total.
4. No other file changes except this document's Results log (`00A` §6).
5. `git status` before and after is reported, and every git command run (`00A` §9).

**Do not:** add any `@Model`, change `Item.swift`, the store, any view, any build setting, the
entitlements or SyLib; add conversion factors, gram weights or nutrient fields; add the nutrition
slots (`03` §10), which come additively with their own task; add `RecipeRendering`,
`RecipeValidator` or `RecipeTransfer`.

---

### Task M1-2 · Sylantro · The ingredient-line parser

**Inputs:** `00`, `00A`, `00B`, `02` §3, this document, and Task M1-1's types (done first).

**Deliverable:** `Sylantro/Domain/Parsing/IngredientLineParser.swift`,
`Sylantro/Domain/Parsing/ParsedLine.swift`, `Sylantro/Domain/Parsing/UnitSpellings.swift`, and
`SylantroTests/Domain/IngredientLineParserTests.swift`.

**What it does.** It reads the quantity and unit at the start of one ingredient line and hands back
the rest. Splitting the rest into item and preparation is the structurer's job (`02` §4), not this
parser's.

`ParsedLine`: a `nonisolated struct ParsedLine: Equatable, Sendable` with `quantity: Quantity?`,
`unit: UnitRef?`, `rest: String`.

`IngredientLineParser`: a `nonisolated enum` with one entry point,
`static func parse(_ line: String) -> ParsedLine`. Pure: no state, no locale, no regex literals
that depend on the locale.

**The rules, applied in order:**

1. **Trim** leading and trailing whitespace (spaces, tabs, non-breaking spaces). Call the result
   *line*.
2. **Approximate prefix.** If *line* starts, case-insensitively, with `about `, `approximately `,
   `approx. `, `approx ` or `~` (with or without a following space), remember `isApproximate =
   true` and drop the prefix and any spaces after it. If no quantity follows (rule 3 finds none),
   undo this rule: the result is quantity nil, unit nil, rest = *line*.
3. **Quantity.** Read one *amount*, then optionally a *range end*. An *amount* is the first of
   these that matches at the current position:
   - a **mixed number**: an integer, one or more spaces, then a fraction (`1 1/2`), or an integer
     followed directly or after spaces by a unicode fraction (`1½`, `1 ½`). Value = integer +
     fraction.
   - a **fraction**: integer `/` integer (`1/2`), also with the fraction slash U+2044 (`1⁄2`). A
     zero denominator means rule 3 finds no quantity at all (row 26); no shorter amount is tried.
   - a **unicode fraction** alone, from this table: ¼ 1/4, ½ 1/2, ¾ 3/4, ⅓ 1/3, ⅔ 2/3, ⅕ 1/5, ⅙ 1/6,
     ⅛ 1/8, ⅜ 3/8, ⅝ 5/8, ⅞ 7/8.
   - a **decimal**: digits `.` digits, or `.` digits (`1.5`, `.5`). The decimal mark is `.` only.
   - an **integer**: digits.
   - a **number word**, case-insensitive, followed by a space: `a` or `an` 1, `one` 1, `two` 2,
     `three` 3, `four` 4, `five` 5, `six` 6, `seven` 7, `eight` 8, `nine` 9, `ten` 10, `eleven` 11,
     `twelve` 12.

   Every fraction's value is `Double(numerator) / Double(denominator)`. A *range end* is optional
   spaces, then `-`, `–` (U+2013) or `—` (U+2014), or the word `to` between spaces, then optional
   spaces, then an *amount*. With one: `Quantity(min: first, max: second, isApproximate:)`; without:
   `Quantity(min: first, max: nil, isApproximate:)`. If no amount matches, the result is quantity
   nil, unit nil, rest = *line* (rule 2 undone).
4. **Unit.** Only when a quantity was read. Skip spaces (none is fine: `200g`). Take the next
   *word*: the run of letters and `.` up to a space, a digit, `(`, `,` or the end. Look it up in
   `UnitSpellings` (below), first, when a next word follows after exactly one space, as a two-word unit (this word, the space, the next word, compared
   with every `.` removed and lowercased: `fl oz`, `fl. oz.`), then as one word. A one-word lookup
   checks the case-sensitive spellings first (`T`, `t`), then compares the word lowercased with
   one trailing `.` removed. A match gives `UnitRef(canonical:, raw:)` with `raw` exactly as written,
   period included (`Tbsp.`, `fl oz`). No match: unit nil, and the word stays in the rest.
5. **"of".** Directly after a matched unit, drop a following `of ` (case-insensitive): "a pinch of
   salt" leaves "salt".
6. **Rest.** Everything after the last thing read, trimmed (rule 1's whitespace). It may be empty.

**`UnitSpellings`** (`UnitSpellings.swift`), a `nonisolated enum` holding the one table (`00A` §10):
`static let caseSensitive: [String: CanonicalUnit] = ["T": .tablespoon, "t": .teaspoon]`,
`static let twoWord: [String: CanonicalUnit]` and `static let oneWord: [String: CanonicalUnit]`,
exactly these keys (lowercase, no periods):

| Canonical | `twoWord` keys | `oneWord` keys |
|---|---|---|
| `teaspoon` | | `tsp`, `tsps`, `teaspoon`, `teaspoons` |
| `tablespoon` | | `tbsp`, `tbsps`, `tbs`, `tbl`, `tablespoon`, `tablespoons` |
| `cup` | | `c`, `cup`, `cups` |
| `fluidOunce` | `fl oz`, `fluid ounce`, `fluid ounces` | `floz` |
| `pint` | | `pt`, `pint`, `pints` |
| `quart` | | `qt`, `quart`, `quarts` |
| `gallon` | | `gal`, `gallon`, `gallons` |
| `milliliter` | | `ml`, `milliliter`, `milliliters`, `millilitre`, `millilitres` |
| `liter` | | `l`, `liter`, `liters`, `litre`, `litres` |
| `ounce` | | `oz`, `ounce`, `ounces` |
| `pound` | | `lb`, `lbs`, `pound`, `pounds` |
| `gram` | | `g`, `gr`, `gram`, `grams` |
| `kilogram` | | `kg`, `kilogram`, `kilograms` |
| `pinch` | | `pinch`, `pinches` |
| `dash` | | `dash`, `dashes` |
| `clove` | | `clove`, `cloves` |
| `can` | | `can`, `cans` |
| `package` | | `pkg`, `package`, `packages` |
| `stick` | | `stick`, `sticks` |
| `slice` | | `slice`, `slices` |

**Tests** (`SylantroTests/Domain/IngredientLineParserTests.swift`, `@Suite("The ingredient-line
parser")`). One parameterized `@Test("each line parses as the table says", arguments:)` over these
29 rows, plus one test, "every canonical unit has a spelling", that checks each `CanonicalUnit` case
appears as a value in `UnitSpellings`. Q is `Quantity(min:max:isApproximate:)`; U is
`UnitRef(canonical:raw:)`; `–` is nil.

| # | Line | Quantity | Unit | Rest |
|---|---|---|---|---|
| 1 | `2 cups flour` | Q(2, nil, false) | U(.cup, "cups") | `flour` |
| 2 | `1/2 cup sugar` | Q(0.5, nil, false) | U(.cup, "cup") | `sugar` |
| 3 | `1 1/2 cups milk` | Q(1.5, nil, false) | U(.cup, "cups") | `milk` |
| 4 | `½ tsp salt` | Q(0.5, nil, false) | U(.teaspoon, "tsp") | `salt` |
| 5 | `1½ cups water` | Q(1.5, nil, false) | U(.cup, "cups") | `water` |
| 6 | `1 ½ cups water` | Q(1.5, nil, false) | U(.cup, "cups") | `water` |
| 7 | `2 to 3 cups flour, sifted` | Q(2, 3, false) | U(.cup, "cups") | `flour, sifted` |
| 8 | `2-3 Tbsp. butter` | Q(2, 3, false) | U(.tablespoon, "Tbsp.") | `butter` |
| 9 | `1–2 tsp vanilla` (U+2013) | Q(1, 2, false) | U(.teaspoon, "tsp") | `vanilla` |
| 10 | `about 2 cups broth` | Q(2, nil, true) | U(.cup, "cups") | `broth` |
| 11 | `~1 lb ground beef` | Q(1, nil, true) | U(.pound, "lb") | `ground beef` |
| 12 | `1 T sugar` | Q(1, nil, false) | U(.tablespoon, "T") | `sugar` |
| 13 | `1 t salt` | Q(1, nil, false) | U(.teaspoon, "t") | `salt` |
| 14 | `200g butter` | Q(200, nil, false) | U(.gram, "g") | `butter` |
| 15 | `8 oz. cream cheese` | Q(8, nil, false) | U(.ounce, "oz.") | `cream cheese` |
| 16 | `4 fl oz milk` | Q(4, nil, false) | U(.fluidOunce, "fl oz") | `milk` |
| 17 | `1 can (15 oz) black beans` | Q(1, nil, false) | U(.can, "can") | `(15 oz) black beans` |
| 18 | `3 eggs` | Q(3, nil, false) | – | `eggs` |
| 19 | `2 large eggs` | Q(2, nil, false) | – | `large eggs` |
| 20 | `a pinch of salt` | Q(1, nil, false) | U(.pinch, "pinch") | `salt` |
| 21 | `Salt and pepper to taste` | – | – | `Salt and pepper to taste` |
| 22 | `1.5 kg potatoes` | Q(1.5, nil, false) | U(.kilogram, "kg") | `potatoes` |
| 23 | `⅓ cup oil` | Q(1.0 / 3.0, nil, false) | U(.cup, "cup") | `oil` |
| 24 | `2 cloves garlic, minced` | Q(2, nil, false) | U(.clove, "cloves") | `garlic, minced` |
| 25 | `  1 cup  rice  ` | Q(1, nil, false) | U(.cup, "cup") | `rice` |
| 26 | `1/0 cup` | – | – | `1/0 cup` |
| 27 | `one onion, diced` | Q(1, nil, false) | – | `onion, diced` |
| 28 | `1 garlic clove` | Q(1, nil, false) | – | `garlic clove` |
| 29 | `3/4 c. sugar` | Q(0.75, nil, false) | U(.cup, "c.") | `sugar` |

**Done when:**

1. The three files exist in `Sylantro/Domain/Parsing/`, `Foundation` only, `nonisolated`.
2. The tests exist, named as above, and pass: all 29 rows and "every canonical unit has a spelling".
3. Sylantro builds with no new warnings, and the suite passes on the pinned destination. The total
   is M1-1's 13 plus 29 arguments plus 1: report the run's own total and how Swift Testing counts the
   parameterized test.
4. No other file changes except this document's Results log.
5. `git status` before and after, and every git command run.

**Do not:** convert units, add gram weights or densities (`03` §6, `00B` §2); split the rest into
item and preparation; add a unit spelling, number word or rule not given here (a line the rules
read wrongly is reported, not fixed); change M1-1's types.

---

## 1. Open in this document

- **"a dozen".** As written, "about a dozen eggs" reads as Q(1, nil, true) with rest `dozen eggs`,
  which is wrong. Claude's recommendation for a later revision: `a dozen` and `dozen` as 12. Not in
  M1-2, and not tested, until Pops rules.

---

## 2. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| | | | |

---

## 3. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.2 | The type names accepted; both tasks may run | SLT-091 (Pops, 21 Nov 2026) |
| 0.1 | First version: Tasks M1-1 (recipe types and JSON) and M1-2 (the ingredient-line parser), for Milestone 1's Domain half | SLT-090; Pops, 21 Nov 2026: the next task is the recipe model and the parser, model-first, no screens |
