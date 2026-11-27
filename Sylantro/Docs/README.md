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
| 00 | `00_DECISION_LEDGER.md` | Every locked ruling, and the open decisions | **Ships with every task** · v0.61 |
| 00A | `00A_STUDIO_CONVENTIONS.md` | Studio conventions — canonical; cited, never restated | v1.15 — studio-wide, verbatim from SyWords |
| 00B | `00B_SYLANTRO_GUARDRAILS.md` | Sylantro's stop conditions, prohibitions, commands, checklist; Tasks A-1 to A-4 | v0.20 — SyLib's UI components wherever one fits (SLT-161); the spike flag goes off when App Store copy starts for RC0 (SLT-093); plain centered alerts (SLT-088); toolbar buttons are `IconButton` (SLT-089); a permission needs its usage key (stop condition); Delete Recipe is the one named photo delete (SLT-157); tests pinned to the iPhone SE (3rd generation) at iOS 26.5 |
| 01 | `01_INGESTION_DESIGN.md` | The camera ingestion engine: pipeline, on-device reading and structuring, the data, storage, the mirror, nutrition slots, milestones | v0.21 — rulings in (SLT-020 to SLT-103); one capture is one recipe, with a pause after Save (SLT-045); Save asks "Is there another page?" when unfinished (SLT-046); sharing in `04`, photos in `05` |
| 02 | `02_ARCHITECTURE.md` | The architecture contract: layers, Domain, capture and extraction, the two stores, the writers, recovery, the mirror's layout, file map | v0.17 — **accepted** (22 Nov 2026); Files copy layout per SLT-157, SLT-158; the queue only while open and its own small store (`15` RV-5, RV-23) |
| 03 | `03_NUTRITION_DESIGN.md` | Nutrition for recipes that don't print it: USDA FoodData Central (SR Legacy), a trimmed bundled copy, food matching with her confirmation, grams from portions, protein and phenylalanine per serving, the flagged phe estimate, custom foods, substitutions | v0.4 — **draft, not accepted; phe and diet features on hold, out of 1.0 (§16)**; open decisions N-1 to N-13; §15 unscheduled ideas (recipe from a label, from a dish photo) |
| 04 | `04_SHARING_DESIGN.md` | Sending one recipe as a file, importing it, duplicates; a shared family binder parked, no public database | v0.1 — SLT-100 to SLT-103 in; open details SH-1 to SH-6 |
| 05 | `05_IMAGE_STORAGE_DESIGN.md` | Page scans and dish photos: the photo model, HEIC sizes, thumbnails, the mirror's copies, what iCloud does with them, the spike's check | v0.15 — **draft**; §1's rulings decided (SLT-053, SLT-054); P-8 (a switch for the Files photo copies) open |
| 06 | `06_MILESTONE_1_DOMAIN.md` | Milestone 1's Domain tasks: M1-1, the recipe value types and their JSON; M1-2, the ingredient-line parser | v1.0 — **closed** (SLT-156); "a few" and "-inch" ruled (SLT-155, built in `11` M1-14); names accepted (SLT-091); schema additions SLT-062 to SLT-066; dozen and `T`/`t` ruled (SLT-048, SLT-049); **M1-1 and M1-2 complete** (16 tests; the `UnitRef` fix, SLT-067, in) |
| 07 | `07_APP_ICON.md` | The app icon: four concepts drawn in code, a paste-ready ChatGPT prompt for each, the field, palette, appearances, process, rulings; its files in `AppIcon/` | v0.4 — **locked and placed** (SLT-110 to SLT-115); About's full-size copy is `00B` Task A-4; on-device check open |
| 08 | `08_APPLE_NEWS_IMPORT.md` | Importing recipes saved in Apple News: what its share sheet gives (a link; no export), the ways in (the publisher's recipe data, screenshots, copied text), fetching the shared page, duplicates, what stands in for the original, a spike | v0.5 — draft; SLT-120 in (link first, screenshots fallback); NI-5, NI-8 (QR codes, §2.3) and NI-9 (photos from Photos, §2.4) ruled; NI-2 to NI-4, NI-6, NI-7 open |
| 09 | `09_MEALS.md` | Meals: a named meal (Thanksgiving) made of recipes from the library, how it maps to the model, and later a combined shopping list, scaling, meal-level protein and phe, a cooking timeline, yearly reuse | v0.1 — idea, nothing ruled; open decisions ML-1 to ML-8 |
| 10 | `10_ACCURACY_TEST_SET.md` | The spike's test set: 25 real binder pages by ID, how each is scored, 42 hard cases (recipes across two pages, several recipes on one page, handwriting, bleed-through, shorthand, odd yields, damage), the design questions they raise; the pages and answer key live outside git in `~/GIT/Syzygy/sylantro-testpages/` (SLT-092) | v0.35 — TP-26 to TP-30 added (a five-page recipe, 26 recipes); run 12 scored, run in the background (all 23 captures structured in the background; the five-page recipe's 10 steps right); run 13 scored (every ingredient's name from its own line; the five-page recipe with no warning); SP-21 in M3-3s; run 14 scored (three titles fixed, four cards take in ingredient lines) |
| 11 | `11_MILESTONE_1_SPIKE.md` | Milestone 1's spike task: M1-3, the reader, the structurer and a hidden spike screen, behind an AppConfig flag, that runs the test pages on Pops's iPhone 18 Pro and exports results (SLT-093) | v1.0 — **closed** (SLT-156): M1-3 to M1-15 complete, 60 tests, six runs scored |
| 12 | `12_IMPLEMENTATION_PLAN.md` | The build order: how the build runs, the SyLib queue, the milestones M0 to M9 in build order, every document mapped to the milestone that builds it, each milestone's gates, and the proposals for Pops | v0.17 — M3's tasks in `15` (draft); **draft**; M0, M1 (SLT-156) and M2 (SLT-160) done; M9 turns the spike flag off (SLT-093); IP-7 ruled (1.0 holds M1 to M8 except the PKU features; M5 after 1.0); IP-10 open; proposals IP-1 to IP-6, IP-8, IP-9; **build order is read only from its §2** |
| 13 | `13_SCREENS.md` | The screens: the library, the camera, a recipe and its review, and the recovery screen, with every string she reads | v0.42 — several recipes on a page drawn (SC-22, S-74 to S-77 proposed); SC-23 ruled (Read Again asks, progress bar), S-78 proposed |
| 14 | `14_MILESTONE_2_CAPTURE.md` | Milestone 2's tasks: the plan M2-1 to M2-6 (capture types, store and recovery screen, photo files and `CaptureRecorder`, screens, mirror, device check), M2-1 to M2-5 written in full | v1.0 — **closed** (SLT-160); M2-1 to M2-5 and fixes M2-4a to M2-4g complete (107 tests); every device check passed |
| 14A | `14A_SYLIB_IMAGE_CACHE_MEMORY.md` | One SyLib task (M2-4a): `ImageCache` keeps an image in memory without writing a JPEG, for M2-4's thumbnails | v0.3 — **M2-4a complete** (SyLib 1659 tests) |
| 15 | `15_MILESTONE_3_REVIEW.md` | Milestone 3's tasks: the plan M3-1 to M3-7 (Domain and structurer fixes, the extraction queue, review, a recipe's pages, several recipes on a page, unreadable handwriting and search, device check) and the questions they wait on | v0.98 — **draft**; run 14 scored; M3-3t complete (titles stop at the ingredients, 246), spike run 15 next; kolaches device check passed; RV-39 ruled; M3-3j complete (216 tests, steps by line numbers), run 10 scored; M3-3k complete (step clean-up rules, 223), run 11 next; M3-3l complete (background spike test, 224); run 11 scored; M3-3m complete (232), run 12 next; M3-3n complete (background test crash fixed); M3-3o complete (background run waits out the rate limit, 234); M3-3p complete (background progress at each step, an expiry doesn't end the run, 236); run 12 scored (all 23 captures structured in the background); M3-3q complete (ingredient names from their own lines, 239), spike run 13 next; M3-3r complete (SyLib components, SLT-161); M3-3s complete (title rules, 243), spike run 14 next; RV-40 ruled (her reading in the background, after the title rules); M3-3e (199) and M3-3f (202) complete; M3-3h, M3-3g and M3-3i complete (209); M3-5 on hold; RV-37 ruled (M3-5a); M3-3e written (two device fixes); run 8 scored, the model's title list kept (RV-35); RV-36 ruled; **M3-5 written** (214 tests); RV-1 to RV-13, RV-18, RV-19, RV-21 and RV-23 to RV-27 ruled; **M3-1 complete** (123 tests); **M3-2 complete** (142 tests); **M3-2a complete** (149 tests); **M3-3 complete** (163 tests); **M3-4 complete** (172 tests); **M3-3a complete** (181 tests); **M3-3b complete** (184 tests); **M3-3c complete** (187 tests); **M3-3d complete** (191 tests); **M3-5s complete** (197 tests); spike run 8 next |
| 16 | `16_FEATURE_IDEAS.md` | Features popular recipe apps have and how each would fit: cook mode, scaling and unit conversion, a grocery list, organizing, import from other apps, the pantry, Apple extras, export and print | v0.2 — FI-11 (marking a missed line) placed in M3; — ideas; SLT-170 to SLT-172 in (cook mode and scaling in 1.0; import eventually); FI-1 to FI-10 open |

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
| 0.69 | Row 16 added: feature ideas from popular recipe apps | SLT-170 to SLT-172 |
| 0.68 | Row 03 to v0.4 and row 12 to v0.16 (PKU features out of 1.0, M5 after it; IP-10); row 00 to v0.59 | Pops, 24 Nov 2026 |
| 0.67 | Row 03 to v0.3 (§16: phe and diet features on hold, options A to E; N-13); row 00 to v0.58 | Pops, 24 Nov 2026 |
| 0.66 | Row 03 to v0.2 (§15: recipe-from-label and dish-photo ideas, unscheduled; N-11, N-12); row 00 to v0.57 | Pops, 24 Nov 2026 |
| 0.73 | Row 15 to v0.58: M3-5s complete | Pops, 24 Nov 2026 |
| 0.74 | Row 10 to v0.27: run 8 scored; row 15 to v0.59: RV-35's outcome, RV-36 proposed | Pops, 25 Nov 2026 |
| 0.76 | Row 15 to v0.62: M3-3e written | Pops, 25 Nov 2026 |
| 0.88 | Row 15 to v0.73: RV-39, M3-3j written | Pops, 25 Nov 2026 |
| 0.89 | Row 15 to v0.74: M3-3j complete | Pops, 25 Nov 2026 |
| 0.90 | Row 10 to v0.29: run 10 scored | Pops, 25 Nov 2026 |
| 0.91 | Row 15 to v0.75: M3-3k written | Pops, 25 Nov 2026 |
| 0.92 | Row 10 to v0.30: TP-26 to TP-30 added | Pops, 25 Nov 2026 |
| 0.93 | Row 15 to v0.76: M3-3k complete | Pops, 25 Nov 2026 |
| 0.94 | Row 15 to v0.77: M3-3l written | Pops, 25 Nov 2026 |
| 0.95 | Row 10 to v0.31 (run 11), row 15 to v0.78 (M3-3m written) | Pops, 25 Nov 2026 |
| 0.96 | Row 15 to v0.80: M3-3l complete, M3-3m revised (232) | Pops, 25 Nov 2026 |
| 0.97 | Row 15 to v0.81: M3-3m complete | Pops, 25 Nov 2026 |
| 0.98 | Row 15 to v0.82: M3-3n written | Pops, 25 Nov 2026 |
| 0.99 | Row 15 to v0.83: M3-3n complete | Pops, 25 Nov 2026 |
| 1.00 | Row 15 to v0.84: M3-3o written | Pops, 25 Nov 2026 |
| 1.01 | Row 15 to v0.85: M3-3o complete | Pops, 25 Nov 2026 |
| 1.02 | Row 15 to v0.86: M3-3p written | Pops, 25 Nov 2026 |
| 1.03 | Row 15 to v0.87: M3-3p complete | Pops, 25 Nov 2026 |
| 1.04 | Row 10 to v0.32: run 12 scored | Pops, 25 Nov 2026 |
| 1.05 | Row 15 to v0.88: M3-3q written | Pops, 25 Nov 2026 |
| 1.06 | Row 15 to v0.89: RV-40 proposed | Pops, 25 Nov 2026 |
| 1.07 | Row 15 to v0.90: M3-3q complete | Pops, 25 Nov 2026 |
| 1.08 | Row 15 to v0.91: RV-40 ruled | Pops, 25 Nov 2026 |
| 1.09 | Rows 00 to v0.61 and 00B to v0.20: SLT-161, SyLib's UI components wherever one fits | Pops, 25 Nov 2026 |
| 1.10 | Row 15 to v0.92: M3-3r written | Pops, 25 Nov 2026 |
| 1.11 | Row 10 to v0.33: run 13 scored | Pops, 25 Nov 2026 |
| 1.12 | Row 15 to v0.94: M3-3r complete | Pops, 25 Nov 2026 |
| 1.13 | Row 15 to v0.95: M3-3s written; row 10 to v0.34 | Pops, 25 Nov 2026 |
| 1.14 | Row 15 to v0.96: M3-3s complete | Pops, 25 Nov 2026 |
| 1.15 | Row 15 to v0.97: M3-3t written; row 10 to v0.35: run 14 scored | Pops, 25 Nov 2026 |
| 1.16 | Row 15 to v0.98: M3-3t complete | Pops, 27 Nov 2026 |
| 0.87 | Row 10 to v0.28: run 9 scored | Pops, 25 Nov 2026 |
| 0.86 | Row 15 to v0.72: kolaches device check passed | Pops, 25 Nov 2026 |
| 0.85 | Row 15 to v0.71: M3-3i complete | Pops, 25 Nov 2026 |
| 0.84 | Row 15 to v0.70: M3-3g complete | Pops, 25 Nov 2026 |
| 0.83 | Row 15 to v0.69: M3-3h complete | Pops, 25 Nov 2026 |
| 0.82 | Row 15 to v0.68: M3-3i written | Pops, 25 Nov 2026 |
| 0.81 | Row 15 to v0.67: RV-38, M3-3h written, M3-5 on hold | Pops, 25 Nov 2026 |
| 0.80 | Row 15 to v0.66: M3-3g written | Pops, 25 Nov 2026 |
| 0.79 | Row 13 to v0.42, row 15 to v0.65: M3-3e and M3-3f complete | Pops, 25 Nov 2026 |
| 0.78 | Row 13 to v0.41: SC-23; row 15 to v0.64: M3-3f written | Pops, 25 Nov 2026 |
| 0.77 | Row 15 to v0.63: RV-37; row 16 to v0.2: FI-11 | Pops, 25 Nov 2026 |
| 0.75 | Row 13 to v0.40: the pick list drawn; row 15 to v0.61: RV-36 ruled, M3-5 written | Pops, 25 Nov 2026 |
| 0.72 | Row 15 to v0.57: RV-35, M3-5s ready | Pops, 24 Nov 2026 |
| 0.71 | Row 15 to v0.56: M3-3d complete | Pops, 24 Nov 2026: "M3-3d. done" |
| 0.70 | Row 15 to v0.55: M3-3c complete, M3-3d ready | Pops, 24 Nov 2026 |
| 0.69 | Row 15 to v0.54 (M3-3c, RV-34), row 13 to v0.39 (S-73) | Pops, 24 Nov 2026 |
| 0.68 | Row 15 to v0.52: M3-3b complete | Pops, 24 Nov 2026: "Task M3-3b done" |
| 0.67 | Row 15 to v0.51: M3-3a complete | Pops, 24 Nov 2026: "m3-3a done" |
| 0.66 | Row 15 to v0.50: M3-4 complete; row 13 to v0.38 (S-72) | Pops, 24 Nov 2026: "Task M3-4 done" |
| 0.65 | Row 08 to v0.5 (QR codes in scans, NI-8; photos from Photos, NI-9); row 15 to v0.48 (RV-32 ruled); row 13 to v0.37 | Pops, 24 Nov 2026 |
| 0.64 | Row 13 to v0.36 (SC-19 to SC-21, S-63 to S-71 approved); row 15 to v0.46 (M3-3b) | Pops, 24 Nov 2026 |
| 0.63 | Row 13 to v0.31 (SC-18, the recipe screen's bar); row 15 to v0.42 (RV-31) | Pops, 24 Nov 2026 |
| 0.62 | Row 13 to v0.30 (S-52l, S-60 to S-62 approved); row 15 to v0.40 | Pops, 24 Nov 2026: "Yes" |
| 0.61 | Row 13: M3's review screens drawn and accepted (v0.22) | `15` RV-21; Pops, 24 Nov 2026 |
| 0.60 | Rows 12 and 15: M3-1, M3-2 and M3-2a complete; row 12 to v0.15 | Pops, 24 Nov 2026: "M3-2 is complete" |
