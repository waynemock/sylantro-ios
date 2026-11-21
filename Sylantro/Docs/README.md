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
| 00 | `00_DECISION_LEDGER.md` | Every locked ruling, and the open decisions | **Ships with every task** · v0.17 |
| 00A | `00A_STUDIO_CONVENTIONS.md` | Studio conventions — canonical; cited, never restated | v1.15 — studio-wide, verbatim from SyWords |
| 00B | `00B_SYLANTRO_GUARDRAILS.md` | Sylantro's stop conditions, prohibitions, commands, checklist; Tasks A-1 to A-4 | v0.10 — Task A-4 (About's full-size icon test) ready; Pops's steps 1 to 4 done (§7); tests pinned to the iPhone SE (3rd generation) at iOS 26.5 |
| 01 | `01_INGESTION_DESIGN.md` | The camera ingestion engine: pipeline, on-device reading and structuring, the data, storage, the mirror, nutrition slots, milestones | v0.7 — rulings in (SLT-020 to SLT-103); sharing in `04`, photos in `05` |
| 02 | `02_ARCHITECTURE.md` | The architecture contract: layers, Domain, capture and extraction, the two stores, the writers, recovery, the mirror's layout, file map | v0.8 — **draft, not accepted** |
| 03 | `03_NUTRITION_DESIGN.md` | Nutrition for recipes that don't print it: USDA FoodData Central (SR Legacy), a trimmed bundled copy, food matching with her confirmation, grams from portions, protein and phenylalanine per serving, the flagged phe estimate, custom foods, substitutions | v0.1 — **draft, not accepted**; open decisions N-1 to N-10 |
| 04 | `04_SHARING_DESIGN.md` | Sending one recipe as a file, importing it, duplicates; a shared family binder parked, no public database | v0.1 — SLT-100 to SLT-103 in; open details SH-1 to SH-6 |
| 05 | `05_IMAGE_STORAGE_DESIGN.md` | Page scans and dish photos: the photo model, HEIC sizes, thumbnails, the mirror's copies, what iCloud does with them, the spike's check | v0.1 — **draft, not accepted**; proposals P-1 to P-7, IS-1 to IS-3 |
| 06 | `06_MILESTONE_1_DOMAIN.md` | Milestone 1's Domain tasks: M1-1, the recipe value types and their JSON; M1-2, the ingredient-line parser | v0.2 — names accepted (SLT-091); M1-1 ready, then M1-2 |
| 07 | `07_APP_ICON.md` | The app icon: four concepts drawn in code, a paste-ready ChatGPT prompt for each, the field, palette, appearances, process, rulings; its files in `AppIcon/` | v0.4 — **locked and placed** (SLT-110 to SLT-115); About's full-size copy is `00B` Task A-4; on-device check open |
| 08 | `08_APPLE_NEWS_IMPORT.md` | Importing recipes saved in Apple News: what its share sheet gives (a link; no export), the ways in (the publisher's recipe data, screenshots, copied text), fetching the shared page, duplicates, what stands in for the original, a spike | v0.2 — draft; SLT-120 in (link first, screenshots fallback); open decisions NI-2 to NI-7 |

---

## Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.1 | The first document set, from SyJong's and Score It \*'s | SLT-006 (Pops, 21 Nov 2026) |
| 0.2 | `03_NUTRITION_DESIGN.md` added to the list, as a draft | Pops, 21 Nov 2026: "Start a write up for this." |
| 0.3 | `06_MILESTONE_1_DOMAIN.md` added, as a draft | Pops, 21 Nov 2026: the recipe model and the parser next |
| 0.4 | `07_APP_ICON.md` added, with its images in `AppIcon/` | Pops, 21 Nov 2026: "I want to design the app icon next" |
| 0.5 | `08_APPLE_NEWS_IMPORT.md` added, as a draft | Pops, 21 Nov 2026: "start a new design doc for this idea" (importing from Apple News) |
