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
| 00 | `00_DECISION_LEDGER.md` | Every locked ruling, and the open decisions | **Ships with every task** · v0.3 |
| 00A | `00A_STUDIO_CONVENTIONS.md` | Studio conventions — canonical; cited, never restated | v1.15 — studio-wide, verbatim from SyWords |
| 00B | `00B_SYLANTRO_GUARDRAILS.md` | Sylantro's stop conditions, prohibitions, commands, checklist; Task A-1 | v0.3 — Pops's steps before A-1 open (§7); tests pinned to the iPhone SE (3rd generation) at iOS 26.6 |
| 01 | `01_INGESTION_DESIGN.md` | The camera ingestion engine: pipeline, on-device reading and structuring, the data, storage, the mirror, nutrition slots, milestones | v0.2 — rulings in (SLT-020 to SLT-090) |
| 02 | `02_ARCHITECTURE.md` | The architecture contract: layers, Domain, capture and extraction, the two stores, the writers, recovery, the mirror's layout, file map | v0.2 — **draft, not accepted** |

---

## Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.1 | The first document set, from SyJong's and Score It \*'s | SLT-006 (Pops, 21 Nov 2026) |
