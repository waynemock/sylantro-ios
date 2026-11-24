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
| 00 | `00_DECISION_LEDGER.md` | Every locked ruling, and the open decisions | **Ships with every task** · v0.56 |
| 00A | `00A_STUDIO_CONVENTIONS.md` | Studio conventions — canonical; cited, never restated | v1.15 — studio-wide, verbatim from SyWords |
| 00B | `00B_SYLANTRO_GUARDRAILS.md` | Sylantro's stop conditions, prohibitions, commands, checklist; Tasks A-1 to A-4 | v0.19 — the spike flag goes off when App Store copy starts for RC0 (SLT-093); plain centered alerts (SLT-088); toolbar buttons are `IconButton` (SLT-089); a permission needs its usage key (stop condition); Delete Recipe is the one named photo delete (SLT-157); tests pinned to the iPhone SE (3rd generation) at iOS 26.5 |
| 01 | `01_INGESTION_DESIGN.md` | The camera ingestion engine: pipeline, on-device reading and structuring, the data, storage, the mirror, nutrition slots, milestones | v0.21 — rulings in (SLT-020 to SLT-103); one capture is one recipe, with a pause after Save (SLT-045); Save asks "Is there another page?" when unfinished (SLT-046); sharing in `04`, photos in `05` |
| 02 | `02_ARCHITECTURE.md` | The architecture contract: layers, Domain, capture and extraction, the two stores, the writers, recovery, the mirror's layout, file map | v0.16 — **accepted** (22 Nov 2026); Files copy layout per SLT-157, SLT-158 |
| 03 | `03_NUTRITION_DESIGN.md` | Nutrition for recipes that don't print it: USDA FoodData Central (SR Legacy), a trimmed bundled copy, food matching with her confirmation, grams from portions, protein and phenylalanine per serving, the flagged phe estimate, custom foods, substitutions | v0.1 — **draft, not accepted**; open decisions N-1 to N-10 |
| 04 | `04_SHARING_DESIGN.md` | Sending one recipe as a file, importing it, duplicates; a shared family binder parked, no public database | v0.1 — SLT-100 to SLT-103 in; open details SH-1 to SH-6 |
| 05 | `05_IMAGE_STORAGE_DESIGN.md` | Page scans and dish photos: the photo model, HEIC sizes, thumbnails, the mirror's copies, what iCloud does with them, the spike's check | v0.15 — **draft**; §1's rulings decided (SLT-053, SLT-054); P-8 (a switch for the Files photo copies) open |
| 06 | `06_MILESTONE_1_DOMAIN.md` | Milestone 1's Domain tasks: M1-1, the recipe value types and their JSON; M1-2, the ingredient-line parser | v1.0 — **closed** (SLT-156); "a few" and "-inch" ruled (SLT-155, built in `11` M1-14); names accepted (SLT-091); schema additions SLT-062 to SLT-066; dozen and `T`/`t` ruled (SLT-048, SLT-049); **M1-1 and M1-2 complete** (16 tests; the `UnitRef` fix, SLT-067, in) |
| 07 | `07_APP_ICON.md` | The app icon: four concepts drawn in code, a paste-ready ChatGPT prompt for each, the field, palette, appearances, process, rulings; its files in `AppIcon/` | v0.4 — **locked and placed** (SLT-110 to SLT-115); About's full-size copy is `00B` Task A-4; on-device check open |
| 08 | `08_APPLE_NEWS_IMPORT.md` | Importing recipes saved in Apple News: what its share sheet gives (a link; no export), the ways in (the publisher's recipe data, screenshots, copied text), fetching the shared page, duplicates, what stands in for the original, a spike | v0.2 — draft; SLT-120 in (link first, screenshots fallback); open decisions NI-2 to NI-7 |
| 09 | `09_MEALS.md` | Meals: a named meal (Thanksgiving) made of recipes from the library, how it maps to the model, and later a combined shopping list, scaling, meal-level protein and phe, a cooking timeline, yearly reuse | v0.1 — idea, nothing ruled; open decisions ML-1 to ML-8 |
| 10 | `10_ACCURACY_TEST_SET.md` | The spike's test set: 25 real binder pages by ID, how each is scored, 42 hard cases (recipes across two pages, several recipes on one page, handwriting, bleed-through, shorthand, odd yields, damage), the design questions they raise; the pages and answer key live outside git in `~/GIT/Syzygy/sylantro-testpages/` (SLT-092) | v0.25 — runs 1 to 6 scored in §7, with Milestone 1's verdict (SLT-156) |
| 11 | `11_MILESTONE_1_SPIKE.md` | Milestone 1's spike task: M1-3, the reader, the structurer and a hidden spike screen, behind an AppConfig flag, that runs the test pages on Pops's iPhone 18 Pro and exports results (SLT-093) | v1.0 — **closed** (SLT-156): M1-3 to M1-15 complete, 60 tests, six runs scored |
| 12 | `12_IMPLEMENTATION_PLAN.md` | The build order: how the build runs, the SyLib queue, the milestones M0 to M9 in build order, every document mapped to the milestone that builds it, each milestone's gates, and the proposals for Pops | v0.14 — M3's tasks in `15` (draft); **draft**; M0, M1 (SLT-156) and M2 (SLT-160) done; M9 turns the spike flag off (SLT-093); IP-7 ruled (1.0 holds M1 to M8); proposals IP-1 to IP-6, IP-8, IP-9; **build order is read only from its §2** |
| 13 | `13_SCREENS.md` | Milestone 2's screens: the library, the camera, a recipe before it is read, and the recovery screen, with every string she reads (S-0 to S-38) | v0.17 — **accepted for M2** (SC-1 to SC-8; S-0 to S-43); M3's review screens to come |
| 14 | `14_MILESTONE_2_CAPTURE.md` | Milestone 2's tasks: the plan M2-1 to M2-6 (capture types, store and recovery screen, photo files and `CaptureRecorder`, screens, mirror, device check), M2-1 to M2-5 written in full | v1.0 — **closed** (SLT-160); M2-1 to M2-5 and fixes M2-4a to M2-4g complete (107 tests); every device check passed |
| 14A | `14A_SYLIB_IMAGE_CACHE_MEMORY.md` | One SyLib task (M2-4a): `ImageCache` keeps an image in memory without writing a JPEG, for M2-4's thumbnails | v0.3 — **M2-4a complete** (SyLib 1659 tests) |
| 15 | `15_MILESTONE_3_REVIEW.md` | Milestone 3's tasks: the plan M3-1 to M3-7 (Domain and structurer fixes, the extraction queue, review, a recipe's pages, several recipes on a page, unreadable handwriting and search, device check) and the questions they wait on | v0.7 — **draft**; task plan (RV-1), flags (RV-10), TS-5/10/11/15 (RV-18) and spike leftovers (RV-19) ruled; **M3-1 complete** (123 tests) |

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
| 0.26 | Row 11: M1-5 complete | `11` Results log |
| 0.27 | Rows 10 and 11: run 3 stopped; M1-6 added | SLT-151 to SLT-153 |
| 0.28 | Row 11: M1-6 complete | `11` Results log |
| 0.29 | Row 11: M1-7 added | Pops, 22 Nov 2026 (spike screen layout) |
| 0.30 | Row 11: M1-7 complete | `11` Results log |
| 0.31 | Rows 00B and 11: SLT-088, alerts are plain; M1-8 added | SLT-088 |
| 0.32 | Row 11: M1-8 complete | `11` Results log |
| 0.33 | Rows 10 and 11: run 3 again; M1-9 added | SLT-151 |
| 0.34 | Row 11: M1-9 complete | `11` Results log |
| 0.35 | Row 11: M1-10 added | Pops, 22 Nov 2026 |
| 0.36 | Row 11: M1-10 complete | `11` Results log |
| 0.37 | Row 10: spike run 3 scored | `10` v0.19 |
| 0.38 | Rows 10 and 11: SP-12 to SP-14 accepted; M1-11 added | SLT-146, SLT-148, SLT-149 |
| 0.39 | Row 11 at v0.18: M1-11 adds the Export Results capsule and `FlowLayout` | Pops, 22 Nov 2026 |
| 0.40 | Rows 00B and 11: M1-11 complete; SLT-093, the spike behind an AppConfig flag; M1-12 added | SLT-093 |
| 0.41 | Row 11 at v0.21: M1-12 also disables Clear with nothing to clear | Pops, 22 Nov 2026 |
| 0.42 | Rows 00B and 11: the spike flag stays on in every build | SLT-093 |
| 0.43 | Rows 00B, 11 and 12: the spike flag stays on through the TestFlight beta, off when App Store copy starts for RC0 | SLT-093 |
| 0.44 | Row 11: M1-12 complete; M1-13 added | Pops, 22 Nov 2026 |
| 0.45 | Row 11: M1-13 complete; run 4 next | `11` Results log |
| 0.46 | Rows 10 and 11: run 4 scored, SP-15 to SP-18 proposed | `10` v0.21 |
| 0.47 | Rows 06, 10 and 11: SP-15 to SP-18 accepted; SLT-155; M1-14 added | SLT-146, SLT-148, SLT-155 |
| 0.48 | Row 11: M1-14 complete; run 5 next | `11` Results log |
| 0.49 | Rows 10 and 11: run 5 scored, SP-19 proposed | `10` v0.23 |
| 0.50 | Rows 10 and 11: SP-19 accepted; M1-15 added | SLT-148 |
| 0.51 | Row 11: M1-15 complete; run 6 next | `11` Results log |
| 0.52 | Rows 06, 10, 11 and 12: Milestone 1 closed after run 6 | SLT-156 |
| 0.53 | Row 12: M0 done (About checked on device) | Pops, 22 Nov 2026 |
| 0.54 | `13_SCREENS.md` added, as a draft | Pops, 22 Nov 2026: "make it so" (prep Milestone 2) |
| 0.55 | Rows 13 and 14: `13` brought up to date; `14_MILESTONE_2_CAPTURE.md` added, as a draft | Pops, 22 Nov 2026 |
| 0.56 | Row 14: M2's plan ruled, M2-1 ready | Pops, 22 Nov 2026 |
| 0.57 | Row 14A: `14A_SYLIB_IMAGE_CACHE_MEMORY.md` added, as a draft | M2-4 run 1's blocker; Pops, 22 Nov 2026 (decision card, "Add memory-only to SyLib first") |
| 0.58 | Milestone 2 closed: rows 00, 00B, 01, 02, 05, 12, 13, 14 and 14A brought up to date | SLT-160 (Pops, 23 Nov 2026: "close out m2") |
| 0.59 | Row 15: `15_MILESTONE_3_REVIEW.md` added, as a draft; row 12 to v0.14 | Pops, 23 Nov 2026: "are we ready to start planning milestone 3?" |
