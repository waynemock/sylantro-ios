# Sylantro — Implementation Plan

**The build, in milestones, and where every feature document lands**
Version 0.17 · 24 November 2026 · **Draft: the order is Claude's proposal for Pops, except 1.0's
contents (IP-7, ruled: everything designed so far, M1 to M8, except the PKU features: M5 and phenylalanine follow 1.0).** Otherwise only what a ledger row already rules is decided (SLT-021,
SLT-090, SLT-093, SLT-100); every proposal is marked
*(rec.)* and listed in §6. M0 done; M1 done (SLT-156; six spike runs scored); M2 done (SLT-160; every device check passed)

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
Modeled on SyJong's `12_IMPLEMENTATION_PLAN.md`. Not for the agent: tasks live in the milestone
documents it names.

---

## 0. How the build runs (IP-1 to IP-6)

- **No schedule, no release pressure.** The plan has no dates. If something gets too hard, or Pops
  just wants to stop and release, he can cut what 1.0 holds at that point and ship what is done; the
  rest moves after 1.0. Pops, 22 Nov 2026: "there are no schedules or pressure to release".
- **A thin slice first** (IP-1) *(rec.)*. The Domain and the spike first, then her photos saved
  safely, then read and structured, then shared and shipped, and everything widens from there.
  Each milestone ends with something Pops can use on a device: his iPhone 18 Pro, never hers
  (SLT-017).
- **This document is the plan; each milestone has its own documents** (IP-2) *(rec.; already the
  practice)*. M0's tasks are in `00B` §7; from M1 each milestone's tasks are in a document named
  `NN_MILESTONE_N_<TOPIC>.md` (`06_MILESTONE_1_DOMAIN.md`, `11_MILESTONE_1_SPIKE.md`), its tasks
  numbered `Mn-k`. Each is written when its milestone starts, against what was actually built, and
  checked by Pops on device.
- **Numbers are names; this document holds the order** (IP-3) *(rec.)*. A document takes the next
  free number when it is written, whatever its kind, so numbers record when a document arrived,
  not when it is built: `08` (Apple News) is built after `03` (nutrition) is started, or before,
  as §2 says. Milestone numbers are permanent too: M1 to M5 are `01` §7's, and a new milestone
  takes the next number, never a renumbering. **Build order is only ever read from §2's Order
  column**, as SyJong built M10 before M8.
- **A new feature document enters as an idea, not a milestone** (IP-4) *(rec.)*. When Pops starts
  a new design document, Claude adds it to §3 with what it needs and a proposed place in the order;
  it joins §2 only when Pops places it.
- **A design document is accepted when its milestone starts** (IP-5) *(rec.)*, as SyJong's were:
  `02` and `05` at M2's start, `10` at M1's close, `04` at M6's, `03` at M4's, `08` at M7's, `09`
  at M8's. Until then each stays a draft and no task is written from it (`00B` §0).
- **Sync from the first real model** (IP-6) *(rec.)*. The template store stays local (SLT-014,
  `00B` Task A-1) until M2's first model task, which turns on the CloudKit private database, so
  every later milestone is built and tested on the real container, as Score It \* and SyJong did.
  Development may be reset freely until M9's Production deploy (SLT-015).

---

## 1. The SyLib queue

One, below. New ground (the iCloud Drive mirror, Vision reading, Foundation Models structuring)
stays in Sylantro until a second app needs it (SLT-083). `SyLibCache` is linked when
thumbnails are built (SLT-084, in M2), after the one additive change below. A milestone that finds a gap in SyLib adds a row here before
its task is written.

| Order | Change | Designed in | Needed by |
|---|---|---|---|
| 1 ✓ | `SyLibCache`: `ImageCache.store(_:for:toDisk:)`, a memory-only store (no JPEG written) | `14A` (task M2-4a) | M2-4's thumbnails |

---

## 2. Milestones

**The order below is proposed** *(rec.)*. Rows marked ✓ are done; the Order column is the build
order (IP-3).

| Order | M | Name | What Pops can do at the end | Documents | Needs |
|---|---|---|---|---|---|
| 1 | **0** | **Setup** *(done)* | Build and run the shell on the pinned SE at iOS 26.5, store local-only, Score It \*'s menu, Settings and About with the full-size icon | `00B` §7 (Tasks A-1 to A-4) | — |
| 2 | 1 | Spike and a tested Domain layer *(done, SLT-156)* | Run the 25 test pages through on-device reading and structuring on his iPhone 18 Pro and read the scores; in the suite, the recipe types, their JSON, the ingredient-line parser, and structuring in parts checked against the page (splitter, page rules, validator) | `06` (M1-1 ✓, M1-2 ✓), `11` (M1-3 ✓, run 1 scored; M1-4 next, then run 2), `10` (the test set; §7 the scores) | the test pages (done, SLT-092) |
| 3 | 2 | Capture and storage *(done, SLT-160)* | Tap +, photograph a recipe's pages, Save, and see it in the library on iPhone, iPad and Mac, synced; the page question (SLT-046); Delete (all gone, SLT-157); the photos and a plain copy in Files; the recovery screen if the store won't open | `14` (M2-1 to M2-6, fixes M2-4a to M2-4g ✓), `14A` (SyLib ✓) | M1; `02` and `05` accepted; a Screens document for the library, camera and recipe (`02` §7); the iCloud Documents capability (Pops, before the mirror task, `00B` §7); NI-5 and P-1, P-2 settled (§4) |
| 4 | 3 | Extraction and review | Scan twenty pages without waiting, then work through the review inbox: each recipe read and structured in the background, flagged fields, tap a line to see it on the photo, pick which recipes to keep from a page with several (SLT-047), reorder and remove a recipe's pages (`14` MT-29, MT-31) | `15` (M3-1 to M3-7, draft); review screens in `13` | M2; the spike's findings (§4); `10`'s TS-5, TS-10, TS-11, TS-15; the review inbox's screens |
| 5 | 6 | Sharing a recipe | Send one recipe by AirDrop, Messages or Mail and open it in another Sylantro, with the duplicate check (SLT-100, SLT-103) | its own document; design `04` | M3; `04` accepted, SH-1 to SH-6 |
| 6 | 4 | Nutrition | Protein and general nutrition per serving on every recipe, from USDA data on the device, each food match confirmed by her. **No phenylalanine in 1.0** (IP-7; `03` §16); whether general nutrition itself is in 1.0 is IP-10 | its own document(s); design `03` | M3; `03` accepted, N-1 to N-13; the nutrition spike (`03` §12) |
| 11 | 5 | PKU tools *(after 1.0; on hold, `03` §16)* | Phenylalanine per serving; a phenylalanine budget view; low-protein substitutions that make variant recipes, before and after per serving. Pops experiments with these once other work is done; how, or whether, they ship is `03` N-13 | its own document(s); a substitutions design, not yet written (`03` §11) | M4; M9 (1.0 shipped); Pops lifts `03` §16's hold |
| 8 | 7 | Web and Apple News import | Share a recipe from Apple News (or any site, NI-2) and find it in the review inbox; screenshots when the page can't be read (SLT-120) | its own document; design `08` | M3; `08` accepted, NI-2 to NI-7; its spike (`08` §7); a share extension and App Group (Pops, entitlements) |
| 9 | 8 | Meals | Gather recipes into a named meal (Thanksgiving) and reuse it next year; the shopping list and meal totals later | its own document; design `09` | M3 (basic meal); M4 (totals, shopping-list unit math); ML-1 to ML-8 |
| 10 | 9 | Ship 1.0 | App Store listing (**when its copy starts, on the way to RC0, turn the accuracy spike's flag off**, SLT-093), the Production schema deployed (SLT-015), the pre-archive checklist (`00B` §6), About's copy checked against what was built (SLT-087), TestFlight, then the App Store | its own document | M1 to M8 except M5 and phenylalanine (IP-7, Pops, 22 and 24 Nov 2026) |

**Alongside, not milestones** (desk work that needs no code):

- **The nutrition spike** (`03` §12 step 1): Claude and Pops match the spike's ingredients by hand
  and by search. It can run as soon as M1's scores are in.
- **The Apple News check** (`08` §7, NI-7): a checklist Pops runs on his phone, any time before M7.
- **The photo sync check** (`05` §7): done in M2-6, passed (`14` §2).
- **The icon on device** (`07`): the 29 px check on his Home Screen, any time.

**Why this order** *(rec.)*: 1.0 holds M1 to M8 except the PKU features (IP-7), so Ship (M9) comes
after them, PKU tools (M5) follow 1.0, and the question is only the order inside 1.0. M2 and M3 are `01` §7's and the first priority (SLT-021), and nothing
else is useful until recipes exist. Sharing (M6) is small once `recipe.json` and the photos exist,
and finishes the ruled MVP (SLT-100). Nutrition (M4) comes next, general nutrition only, with time for its own spike;
PKU tools (M5) wait until after 1.0 (IP-7, `03` §16). Web import (M7) and
Meals (M8) come last because each still has most of its decisions open; either can move ahead of
M4, since each needs only M3, and Meals' totals need M4.

---

## 3. Feature documents and where they land

Every numbered document, by the milestone that builds it. When a document is added, Claude adds a
row here in the same change (IP-4).

| # | Document | Kind | Built in | Accepted when |
|---|---|---|---|---|
| 00, 00A, 00B | Ledger, studio conventions, guardrails | Rules | every task | in force |
| 01 | `01_INGESTION_DESIGN.md` | Design | M1 to M3 (its §7 is the outline M1 to M5 come from) | rulings in; the rest at M2 |
| 02 | `02_ARCHITECTURE.md` | Contract | M2 onward (§3's names already, M1) | M2's start (IP-5) |
| 03 | `03_NUTRITION_DESIGN.md` | Design | M4, M5 | M4's start |
| 04 | `04_SHARING_DESIGN.md` | Design | M6 | M6's start |
| 05 | `05_IMAGE_STORAGE_DESIGN.md` | Design | M2 (photos), M6 (photos in the file) | M2's start |
| 06 | `06_MILESTONE_1_DOMAIN.md` | Tasks | M1 (M1-1, M1-2) | — |
| 07 | `07_APP_ICON.md` | Design | M0 (Task A-4); done otherwise | locked (SLT-110 to SLT-115) |
| 08 | `08_APPLE_NEWS_IMPORT.md` | Design | M7 | M7's start |
| 09 | `09_MEALS.md` | Idea | M8 | M8's start, if taken forward (ML-1) |
| 10 | `10_ACCURACY_TEST_SET.md` | Test plan | M1 (scored in §7) | M1's close |
| 11 | `11_MILESTONE_1_SPIKE.md` | Tasks | M1 (M1-3, M1-4) | — |
| 12 | `12_IMPLEMENTATION_PLAN.md` | Plan | — | this document |
| 13 | `13_SCREENS.md` | Design | M2 (library, camera, recipe, recovery); M3's review screens (v0.22, accepted) | M2's first screen task |
| 14 | `14_MILESTONE_2_CAPTURE.md` | Tasks | M2 (M2-1 to M2-6) | closed, v1.0 (SLT-160) |
| 15 | `15_MILESTONE_3_REVIEW.md` | Tasks | M3 (M3-1 to M3-7, plan ruled) | draft, v0.31; M3-1 (123 tests), M3-2 (142), M3-2a (149), M3-3 (163), M3-4 (172), M3-3a (181) and M3-3b (184) and M3-3c (187) and M3-3d (191) and M3-5s (197) complete; run 8 scored (the model's title list kept); M3-3e written (two device fixes); M3-5 written (214 tests), waiting on `13`'s SC-22 and its wording |
| 16 | `16_FEATURE_IDEAS.md` | Ideas | not placed: cook mode and scaling are in 1.0 (SLT-170, SLT-171), the rest open (FI-1 to FI-10) | when Pops places each feature |

**Ideas, not yet placed** (Pops decides where they go):

| Idea | Raised | Notes |
|---|---|---|
| **Cook mode** (`16` §2.1): screen awake, one step at a time, ingredient ticks, timers from step text. **In 1.0** (SLT-170) | Pops, 24 Nov 2026 | Milestone open (`16` FI-1): a milestone of its own after M3 *(rec.)*. Needs structured recipes (M3) and its screens in `13` |
| **Scaling** (`16` §2.2): servings or a factor, kitchen fractions, the recipe never edited. **In 1.0** (SLT-171) | Pops, 24 Nov 2026 | Milestone open (FI-1), with cook mode *(rec.)*. Meals (M8) reuses it; unit conversion is FI-4 |
| Grocery list (`16` §2.3) | Pops, 24 Nov 2026 | FI-5; overlaps `09`'s shopping list |
| Tags, favorites, ratings, her notes, cooked-on dates (`16` §2.4) | Pops, 24 Nov 2026 | FI-6 |
| Import from other recipe apps (`16` §2.5) | Pops, 24 Nov 2026 | **Eventually, lowest priority** (SLT-172); FI-7 |
| Pantry (`16` §2.6) | Pops, 24 Nov 2026 | FI-8: park *(rec.)* |
| Siri, Shortcuts, Spotlight, widgets, Watch (`16` §2.7) | Pops, 24 Nov 2026 | FI-9; a Watch app reopens SLT-012 |
| Export and print (`16` §2.8) | Pops, 24 Nov 2026 | FI-10; overlaps `04` SH-3 |

---

## 4. Gates: what each milestone waits on

The decisions that must be made before a milestone's tasks can be written, so none surprises a
task.

**M1 closed** (22 Nov 2026, SLT-156) after six spike runs (`10` §7): on-device reading and
structuring are good enough to go on, and SLT-040 stays closed. **Carried to M3:** run 6's two
title fixes (`11` §1), several recipes on a page (SLT-047), handwriting, and `10`'s TS-5, TS-10,
TS-11 and TS-15. **Still open from the old gate:** whether Vision's document reading helps columns
(`11` §1) and the duplicate threshold (`01` §8). Task A-4's About screen was checked by Pops on device (M0 done).

**M2 closed** (23 Nov 2026, SLT-160): capture, storage, sync and the Files copy are built and every
device check passed (`14` §2). **Carried to M3:** reordering and removing a recipe's pages, with
the review screens (`14` MT-29, MT-31); the device-only store with `ExtractionQueue` (`14` MT-1).
**Parked for later, no milestone yet:** a Settings switch for the Files photo copies (`05` P-8) and
Hide or Archive a recipe (SLT-157).

**Before M2's first task** *(met)*: `02` accepted, with the App-layer names (`RecipeEditor`,
`CaptureRecorder`, `ExtractionQueue`, `MirrorWriter`) and the recovery screen's choices and copy
(`02` §5.3); `05`'s P-1 to P-7 ruled, and IS-4 (ruled A: an app-only photo folder in her iCloud Drive, so the iCloud Documents
capability is needed before the photo task, not only the mirror task); **NI-5** (how a web
source enters the schema) and **P-1, P-2** (the photo model) settled, because they shape
`SourcePage` *(rec.: before the first model task, even though M7 is later)*; the Screens document
for the library, the camera and a recipe, with its copy, including "Recipes" and "Choose a recipe";
the iCloud Documents capability and `NSUbiquitousContainers` before the mirror task (Pops).

**Before M3:** the review inbox's screens and copy; how a recipe is restored from the mirror, if
the recovery screen offers it (`02` §5.3).

**Before M4:** `03` accepted, N-1 to N-13; IP-10 (whether general nutrition is in 1.0); the
nutrition spike's results.

**Before M5 (after 1.0):** Pops lifts `03` §16's hold, after talking to their employer; `03` N-13; the clinic's phenylalanine list, if there is one.

**Before M6:** `04`'s SH-1 to SH-6; `05`'s P-6 (dish photos in the file).

**Before M7:** `08`'s NI-2 to NI-7; the share extension target and App Group (Pops, entitlements).

**Before M8:** `09`'s ML-1 to ML-8.

**Before M9:** M1 to M8 done except M5 and phenylalanine, which is what 1.0 holds (IP-7); every feature About names is built (SLT-087).

---

## 5. Where M0 and M1 stand

### Milestone 0 · Setup

**Done** (22 Nov 2026). Pops's steps 1 to 5 (`00B` §7) are done; Tasks A-1 (inside A-2), A-2
(written in error and kept, SLT-003) and A-3 are complete. Task A-4's goal, About's full-size icon,
was checked by Pops on his iPhone with the suite green (Pops, 22 Nov 2026: "about screen looks great -- all tests pass"). Its automated test
(`Bundle.main.icon` at least 600 pixels) was not added; it can be any time, as a one-test task.

### Milestone 1 · Spike and Domain

**Done** (22 Nov 2026, SLT-156). M1-1 ✓ (13 tests), M1-2 ✓ (16), and M1-3 to M1-15 ✓ (`11`, 60
tests in all). Six spike runs on Pops's iPhone 18 Pro, scored in `10` §7. `06` and `11` are at
v1.0, their rulings in the ledger.

---

## 6. Proposals for Pops

| # | Question | Proposal |
|---|---|---|
| IP-1 | How the build grows | A thin slice first; each milestone ends with something to use on his phone *(rec.)* |
| IP-2 | Where tasks are written | This plan plus one or more `NN_MILESTONE_N_<TOPIC>.md` per milestone, at its start *(rec.; already done for M1)* |
| IP-3 | How order is kept as documents are added | Numbers are names (documents and milestones); the order lives only in §2's Order column *(rec.)* |
| IP-4 | How a new feature document is placed | It enters §3's ideas list; Pops places it in §2 *(rec.)* |
| IP-5 | When design documents are accepted | Each at its milestone's start (§3) *(rec.)* |
| IP-6 | When sync comes in | With M2's first model task *(rec.)* |
| IP-7 | What 1.0 holds | **Ruled: everything designed so far,** M1 to M8 (the binder, sharing, nutrition, web and Apple News import, meals), **except the PKU features:** phenylalanine and PKU tools (M5) are not in the initial App Store release and follow it; Ship (M9) comes after the rest — Pops, 22 Nov 2026: "i want all of what we talked about to be in 1.0" (the card's "Binder app plus sharing" was a misread, withdrawn) → Pops, 24 Nov 2026: "It’s just not gonna be part of mvp inital App Store release. I do wanna play around with it. Just build other stuff first." |
| IP-10 | Whether general nutrition (M4: protein, calories and the rest per serving, no phe) is in 1.0 | Open. Pops, 24 Nov 2026: "I do think things like protein per serving would be possible"; Pops's call, likely after talking to their employer |
| IP-8 | The order after M3 | §2's: M6, M4, M5, M7, M8, then M9 *(rec.)*; M7 or M8 may move ahead of M4 |
| IP-9 | When NI-5 and P-1, P-2 are settled | Before M2's first model task *(rec.)* |

When Pops rules, the rulings are filed in the ledger under Implementation plan (SLT-094 onward) at
this document's close-out.

---

## 7. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.17 | `16_FEATURE_IDEAS.md` added to §3 and its features to the ideas list; cook mode and scaling are in 1.0 (SLT-170, SLT-171) with their milestone open; import from other apps eventually (SLT-172) | Pops, 24 Nov 2026: "Note them all somewhere appropriate. Cook mode and scaling seems mvp, import least interesting to me but good to include eventually" |
| 0.16 | IP-7 narrowed: phenylalanine and PKU tools (M5) are not in 1.0 and follow it; M5 moves after M9 in §2; M4 is general nutrition, with IP-10 (whether it is in 1.0) opened | Pops, 24 Nov 2026: "It’s just not gonna be part of mvp inital App Store release. I do wanna play around with it. Just build other stuff first." |
| 0.15 | §3 row 15: M3-1, M3-2 and M3-2a complete | Pops, 24 Nov 2026: "M3-2 is complete" |
| 0.14 | §3: `15_MILESTONE_3_REVIEW.md` added, M3's tasks (draft) | IP-2; Pops, 23 Nov 2026: "are we ready to start planning milestone 3?" |
| 0.13 | M2 closed: §2 row done, §4 what M3 inherits and what is parked, §3 row 14 closed | SLT-160 (Pops, 23 Nov 2026: "close out m2") |
| 0.12 | §1's SyLib queue gains its first row, `ImageCache`'s memory-only store (`14A`, task M2-4a) | M2-4 run 1 found the gap; Pops, 22 Nov 2026 (decision card, "Add memory-only to SyLib first") |
| 0.11 | §3: `14_MILESTONE_2_CAPTURE.md` added, M2's tasks | IP-2; Pops, 22 Nov 2026: "make it so" (prep Milestone 2) |
| 0.10 | §3: `13_SCREENS.md` added, the Screens document M2 waits on | IP-4; Pops, 22 Nov 2026: "make it so" (prep Milestone 2) |
| 0.9 | SLT-053: no image data in the database; the photo measurement becomes a sync check after the photo task; IS-4 joins M2's gate | Pops, 22 Nov 2026: "looks good. can you make sure we are storing no image data in the database" |
| 0.8 | M0 done: Pops checked About's full-size icon on device, suite green; A-4's automated test not added | Pops, 22 Nov 2026: "about screen looks great -- all tests pass" |
| 0.7 | M1 closed: §2, §4 and §5 brought up to date; what M3 inherits | SLT-156 (Pops, 22 Nov 2026: "close out milestone 1"; "ok we will finish the spike") |
| 0.6 | M9: turn the accuracy spike's flag off when App Store copy starts, on the way to RC0 | SLT-093 (Pops, 22 Nov 2026: "my partner will only be using testflight builds, and i want to keep this on during beta test. just need to be reinded to turn it off once we start writing app store copy headed to RC0.") |
| 0.5 | M1 brought up to date: M1-3 done, spike run 1 scored, SLT-140 to SLT-145 in; M1-4 and run 2 left; §4's M1 gate rewritten | `11` v0.3, `10` v0.14, ledger v0.35 |
| 0.4 | §0: no schedule or release pressure; Pops may cut 1.0's scope and release at any point | Pops, 22 Nov 2026: "it something gets to hard, or I just wanna stop and release we will cross that bridge when we get there...there are no schedules or pressure to release..." |
| 0.3 | IP-7 re-ruled: 1.0 holds everything designed so far, M1 to M8, with Ship (M9) last; §2's order moves M9 to the end; IP-8 restated | Pops, 22 Nov 2026: "i want all of what we talked about to be in 1.0...I thought that was a multiple choice question before..." |
| 0.2 | IP-7 ruled (superseded by 0.3): 1.0 is the binder app plus sharing (M1, M2, M3, M6); nutrition and PKU tools follow it | Pops, 22 Nov 2026 (decision card, "Binder app plus sharing") |
| 0.1 | First draft: IP-1 to IP-9 proposed; the SyLib queue (empty); ten milestones, M0 to M9, with M1 to M5 kept as `01` §7 numbered them and M6 to M9 added; the build order; every document mapped to its milestone; each milestone's gates; M0 and M1's status | Pops, 22 Nov 2026: "it's important, especially as we add more feature docs...order is important." From SyJong's `12_IMPLEMENTATION_PLAN.md` |
