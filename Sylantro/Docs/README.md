# Sylantro — Documents

**Syzygy Softwerks · Sylantro · iOS / iPadOS / Mac (Designed for iPad)**
Read this first.

---

## For the implementing agent

1. **Read `00_DECISION_LEDGER.md` first.** It ships with every task, and it is the only place a
   reversed ruling is visible.
2. **Then `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.** `00A` is how every
   session runs; `00B` is what is specific to Sylantro.
3. **Then the task's own document, and only the documents it names.** Take one task.

If something is unspecified, stop and raise it (`00A` §4).

---

## What Sylantro is

A recipe app for Pops's partner, who keeps a binder of printed recipes. She photographs a page and
Sylantro saves it, reads it and turns it into a structured recipe, all on the device (SLT-020,
SLT-040). Her data outlives the app: the page photo is kept forever, every recipe is also a plain
file in Files, and the store is never wiped (SLT-030, SLT-031). Nutrition, with protein and
phenylalanine per serving for a PKU diet, comes later (SLT-022). Built on sylib-swift, with
Score It \* as its template (SLT-080).

---

## The documents

| # | Document | What it holds | Status |
|---|---|---|---|
| 00 | `00_DECISION_LEDGER.md` | Every locked ruling, and the open decisions | **Ships with every task** · v0.23 |
| 00A | `00A_STUDIO_CONVENTIONS.md` | Studio conventions — canonical; cited, never restated | v1.15 — studio-wide, verbatim from SyWords |
| 00B | `00B_SYLANTRO_GUARDRAILS.md` | Sylantro's stop conditions, prohibitions, commands, checklist; Tasks A-1 to A-4 | v0.11 — capture-path exception for Save's page-2 check (SLT-046); Task A-4 (About's full-size icon test) ready; Pops's steps 1 to 4 done (§7); tests pinned to the iPhone SE (3rd generation) at iOS 26.5 |
| 01 | `01_INGESTION_DESIGN.md` | The camera ingestion engine: pipeline, on-device reading and structuring, the data, storage, the mirror, nutrition slots, milestones | v0.10 — rulings in (SLT-020 to SLT-103); one capture is one recipe, Save asks for a page 2 when unfinished (SLT-045, SLT-046); sharing in `04`, photos in `05` |
| 02 | `02_ARCHITECTURE.md` | The architecture contract: layers, Domain, capture and extraction, the two stores, the writers, recovery, the mirror's layout, file map | v0.8 — **draft, not accepted** |
| 03 | `03_NUTRITION_DESIGN.md` | Nutrition for recipes that don't print it: USDA FoodData Central (SR Legacy), a trimmed bundled copy, food matching with her confirmation, grams from portions, protein and phenylalanine per serving, the flagged phe estimate, custom foods, substitutions | v0.1 — **draft, not accepted**; open decisions N-1 to N-10 |
| 04 | `04_SHARING_DESIGN.md` | Sending one recipe as a file, importing it, duplicates; a shared family binder parked, no public database | v0.1 — SLT-100 to SLT-103 in; open details SH-1 to SH-6 |
| 05 | `05_IMAGE_STORAGE_DESIGN.md` | Page scans and dish photos: the photo model, HEIC sizes, thumbnails, the mirror's copies, what iCloud does with them, the spike's check | v0.2 — **draft, not accepted**; proposals P-1 to P-7, IS-1 to IS-3 |
| 06 | `06_MILESTONE_1_DOMAIN.md` | Milestone 1's Domain tasks: M1-1, the recipe value types and their JSON; M1-2, the ingredient-line parser | v0.6 — names accepted (SLT-091); schema additions SLT-062 to SLT-066; dozen and `T`/`t` ruled (SLT-048, SLT-049); **M1-1 and M1-2 complete** (16 tests; the `UnitRef` fix, SLT-067, in) |
| 07 | `07_APP_ICON.md` | The app icon: four concepts drawn in code, a paste-ready ChatGPT prompt for each, the field, palette, appearances, process, rulings; its files in `AppIcon/` | v0.4 — **locked and placed** (SLT-110 to SLT-115); About's full-size copy is `00B` Task A-4; on-device check open |
| 08 | `08_APPLE_NEWS_IMPORT.md` | Importing recipes saved in Apple News: what its share sheet gives (a link; no export), the ways in (the publisher's recipe data, screenshots, copied text), fetching the shared page, duplicates, what stands in for the original, a spike | v0.2 — draft; SLT-120 in (link first, screenshots fallback); open decisions NI-2 to NI-7 |
| 09 | `09_MEALS.md` | Meals: a named meal (Thanksgiving) made of recipes from the library, how it maps to the model, and later a combined shopping list, scaling, meal-level protein and phe, a cooking timeline, yearly reuse | v0.1 — idea, nothing ruled; open decisions ML-1 to ML-8 |
| 10 | `10_ACCURACY_TEST_SET.md` | The spike's test set: 25 real binder pages by ID, how each is scored, 42 hard cases (recipes across two pages, several recipes on one page, handwriting, bleed-through, shorthand, odd yields, damage), the design questions they raise; the pages and answer key live outside git in `~/GIT/Syzygy/sylantro-testpages/` (SLT-092) | v0.16 — runs 1 and 2 scored (§7), SP-1 to SP-11 accepted; draft, not accepted; proposals TS-5, TS-10, TS-11, TS-15 (the rest settled; TS-12 done) |
| 11 | `11_MILESTONE_1_SPIKE.md` | Milestone 1's spike task: M1-3, the reader, the structurer and a hidden debug-only screen that runs the test pages on Pops's iPhone 18 Pro and exports results (SLT-093) | v0.5 — M1-3 and M1-4 complete (31 tests), runs 1 and 2 scored; **M1-5 ready for the agent** (43 tests expected; SLT-146 to SLT-150), then run 3 |
| 12 | `12_IMPLEMENTATION_PLAN.md` | The build order: how the build runs, the SyLib queue, the milestones M0 to M9 in build order, every document mapped to the milestone that builds it, each milestone's gates, and the proposals for Pops | v0.5 — **draft**; IP-7 ruled (1.0 holds M1 to M8); proposals IP-1 to IP-6, IP-8, IP-9; **build order is read only from its §2** |

---

## Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.1 | The first document set, from SyJong's and Score It \*'s | SLT-006 (Pops, 21 Nov 2026) |
| 0.2 | `03_NUTRITION_DESIGN.md` added to the list, as a draft | Pops, 21 Nov 2026: "Start a write up for this." |
| 0.3 | `06_MILESTONE_1_DOMAIN.md` added, as a draft | Pops, 21 Nov 2026: the recipe model and the parser next |
| 0.4 | `07_APP_ICON.md` added, with its images in `AppIcon/` | Pops, 21 Nov 2026: "I want to design the app icon next" |
| 0.5 | `08_APPLE_NEWS_IMPORT.md` added, as a draft | Pops, 21 Nov 2026: "start a new design doc for this idea" (importing from Apple News) |
| 0.6 | `09_MEALS.md` added, as an idea | Pops, 21 Nov 2026: "Here's another feature idea to jot down." |
| 0.7 | `10_ACCURACY_TEST_SET.md` added, as a draft; the real pages kept outside git | Pops, 21 Nov 2026: photographed 18 binder pages for the accuracy test |
| 0.8 | Row 10 updated: 25 pages, 42 hard cases, TS-13 and TS-14 | `10` v0.4 |
| 0.9 | Row 10: TS-13 settled by SLT-047 | `10` v0.5 |
| 0.10 | Rows 06 and 10: SLT-048, SLT-049 | `06` v0.3, `10` v0.6 |
| 0.11 | Row 10: TS-8 settled | `10` v0.8 |
| 0.12 | Rows 06 and 10: SLT-062 to SLT-065 | `06` v0.4, `10` v0.9 |
| 0.13 | Rows 05, 06 and 10: SLT-066 | `05` v0.2, `06` v0.5, `10` v0.10 |
| 0.14 | Row 06: M1-1 complete | `06` Results log |
| 0.15 | Row 06: SLT-067 folded into M1-2 | `06` v0.6 |
| 0.16 | Row 06: M1-2 complete | `06` Results log |
| 0.17 | Row 11 added | SLT-093 |
| 0.18 | Row 11: M1-3 complete | `11` Results log |
| 0.19 | Row 12 added: the implementation plan, the one place the build order is kept | Pops, 22 Nov 2026: "it's important, especially as we add more feature docs...order is important." |
| 0.20 | Row 10: spike run 1 scored | `10` v0.12 |
| 0.21 | Row 11: M1-4 added | SLT-140 to SLT-145 |
| 0.22 | Row 12: v0.5, M1 brought up to date | `12` v0.5 |
| 0.23 | Row 11: M1-4 complete | `11` Results log |
| 0.24 | Row 10: spike run 2 scored | `10` v0.15 |
| 0.25 | Rows 10 and 11: SP-7 to SP-11 accepted; M1-5 added | SLT-146 to SLT-150 |
