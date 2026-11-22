# Sylantro — Screens

**Design document · the library, the camera, a recipe and the recovery screen, with every word
she reads**
Version 0.6 · 22 November 2026 · **Draft: screen choices ruled (SC-1 to SC-7); the copy (§6, SC-8) waits for Pops.** Every
string in §6 is Claude's proposal. The layout
and the copy are Pops's (`02` §7, `00B` §2). No task is written from an open proposal.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It is the Screens document `02` §7 and `12` §4 ask for before Milestone 2's first task. The review
inbox's screens are Milestone 3's, in a later version of this document or its own.

---

## 0. What this is

Milestone 2 ends with her tapping **Let's cook.**, photographing a recipe's pages, tapping Save,
and seeing it in the library on iPhone, iPad and Mac (`12` §2). Nothing is read or structured yet
(that is M3), so every screen here has to make sense for a recipe that is, so far, only its
photos. This document says what each screen shows, what each button does, and the exact words.

---

## 1. What is already decided

| ID | Ruling | On screen |
|---|---|---|
| SLT-043 | A scan session starts from the **"Let's cook."** button | §3 |
| SLT-045 | One capture is one recipe; the camera reopens for the next | §3 |
| SLT-046 | Save asks "Is there a page 2?" only when the last page looks unfinished | §3.2 |
| SLT-030, SLT-031 | No photo is ever thrown away; the store is never wiped | §4.3, §5 |
| SLT-086 | The library's toolbar: the iCloud button and ⋯ (Update Available, Settings, About, App Store) | §2 |
| SLT-088 | Every confirmation or message is a plain centered alert | throughout |
| SLT-053 | No image data in the database; photos are files that may arrive after their record | §2, §4 |
| Built (A-2) | The library is titled "Recipes"; the empty detail says "Choose a recipe" (drafts, waiting for Pops) | §2 |

---

## 2. The library

**iPhone:** one list, a recipe opens by push. **iPad and Mac:** the list is the sidebar, the
recipe is the detail (`02` §1, accepted).

**A row** shows a square thumbnail of the recipe's cover (its first page's cropped photo until it
has a dish photo, `05` P-1), the title, and one line under it:

| The recipe | Title line | Under it |
|---|---|---|
| Saved, not read yet (all of M2) | "New recipe" (S-2) | "Scanned Nov 22 · 2 pages" (S-3) |
| Read and structured (M3 on) | its title | its source or author |
| Photo not downloaded yet | as above | as above; the thumbnail is a placeholder (SC-6) |

**Order:** newest scan first. Sorting and search come with titles in M3 (SC-3).

**The scan button** (SC-2): a **Let's cook.** capsule button at the bottom of the library, always
visible, on iPhone and iPad *(ruled)*; on the Mac it is hidden, since the Mac has no document
camera (`01` §1).

**Empty library:** SyLibUI's `EmptyStateView`, with a title (S-4), one line (S-5) and the Let's
cook. button below it.

**Toolbar:** as built (SLT-086). Nothing is added in M2.

---

## 3. The camera

Tapping **Let's cook.** opens VisionKit's document camera full screen (`02` §1). Its own controls
and words are Apple's and are not changed.

### 3.1 After Save

1. The capture's pages are saved at once (`CaptureRecorder`, SLT-041) as one new recipe (SC-1,
   ruled), shown in the library as "New recipe" until M3 reads it.
2. The camera **reopens for the next recipe** (SLT-045), with a short confirmation that the last
   one was saved (SC-4).
3. **Cancel** in the camera (with no pages taken) ends the session and returns to the library,
   scrolled to the newest recipe.

### 3.2 Is there a page 2? (SLT-046)

When the last page looks unfinished, Save shows a plain alert before saving (S-10 to S-13):
**Add Page** reopens the camera on the same recipe; **Save Without It** saves it with the
"continues on a page not scanned" warning.

### 3.3 When saving fails

A plain alert (S-14, S-15), and the pages stay in the camera so nothing is lost. The likely cause
is a full device.

### 3.4 Camera not available

On a device or simulator with no document camera, Let's cook. shows a plain alert (S-16, S-17).

---

## 4. A recipe (M2's version)

### 4.1 What it shows

- **The pages**, full width, one after another; tap one to see it full screen and zoom.
- Under the title, the line "Waiting to be read" (S-20) until M3 reads it; with the page-2
  warning when SLT-046 applies (S-21).
- On iPad and Mac with nothing selected: "Choose a recipe" (S-1, built).

### 4.2 Its toolbar

- **Add Page** (S-22): opens the camera, adds the pages to this recipe (SLT-045).
- **⋯** with **Delete Recipe** (S-23), SC-5 (ruled).

### 4.3 Deleting a recipe (SC-5, ruled)

Her photos are never thrown away (SLT-030). Delete Recipe asks with a plain alert
(S-24 to S-26) and removes the recipe, but its pages are kept as **pages without a recipe**,
which the mirror already has a folder for (`02` §5.4); M3's review can attach them to a recipe
again. No screen lists them in M2.

---

## 5. When the store won't open (`02` §5.3, SLT-031)

The app opens to this screen instead of the library. Nothing has been deleted.

**Shows** *(rec.)*: a title (S-30), what happened in plain words (S-31), that her recipes in Files
are safe (S-32), and the error's own text in small type under a **Details** disclosure, so Pops
can read it.

**Choices** (SC-7):

| Option | What she can do |
|---|---|
| **A. Try Again, or Start Fresh** *(ruled)* | **Try Again** retries opening the store. **Start Fresh** (after a plain alert, S-35 to S-37) moves the old store, untouched, to a dated folder and opens a new empty one; recipes come back from iCloud and the mirror (restoring from the mirror is M3, `12` §4) |
| B. Try Again only | She can't do anything else until Pops looks at it |
| C. A, plus open the old store read-only | She can still look at her recipes while it is broken; more to build and test |

---

## 6. Copy

Every string she reads in M2. Pops approves or rewrites each; the agent pastes them verbatim
(`00B` §2).

| ID | Where | Proposed text |
|---|---|---|
| S-1 | Detail, nothing selected | Choose a recipe *(built)* |
| S-0 | Library title | Recipes *(built)* |
| S-2 | Row title, not read yet | New recipe |
| S-3 | Row line, not read yet | Scanned Nov 22 · 2 pages (date in her locale; "1 page") |
| S-4 | Empty library, title | No recipes yet |
| S-5 | Empty library, line | Tap Let's cook. and photograph a recipe from your binder. |
| S-6 | Scan button | Let's cook. *(SLT-043)* |
| S-7 | Saved confirmation (SC-4) | Saved. Ready for the next one. |
| S-10 | Page 2 alert, title | Is there a page 2? |
| S-11 | Page 2 alert, message | This page looks like it keeps going. |
| S-12 | Page 2 alert, button | Add Page |
| S-13 | Page 2 alert, button | Save Without It |
| S-14 | Save failed, title | Couldn't Save |
| S-15 | Save failed, message | Your pages are still here. Free up some space on your iPhone and tap Save again. |
| S-16 | No camera, title | Camera Not Available |
| S-17 | No camera, message | Scanning needs an iPhone or iPad camera. |
| S-20 | Recipe, not read yet | Waiting to be read |
| S-21 | Recipe, page-2 warning | Continues on a page not scanned |
| S-22 | Recipe toolbar | Add Page |
| S-23 | Recipe ⋯ menu | Delete Recipe |
| S-24 | Delete alert, title | Delete This Recipe? |
| S-25 | Delete alert, message | Its page photos are kept, so nothing from your binder is lost. |
| S-26 | Delete alert, buttons | Delete (destructive), Cancel |
| S-27 | Photo still downloading | Downloading from iCloud… (VoiceOver label on the placeholder) |
| S-30 | Recovery, title | Sylantro Can't Open Your Recipes |
| S-31 | Recovery, message | Something went wrong opening your recipe library. Nothing has been deleted. |
| S-32 | Recovery, reassurance | A copy of every recipe and photo is safe in Files, in the Sylantro folder. |
| S-33 | Recovery, button | Try Again |
| S-34 | Recovery, button | Start Fresh |
| S-35 | Start Fresh alert, title | Start Fresh? |
| S-36 | Start Fresh alert, message | Your current library is set aside, not deleted, and Sylantro opens a new one. Recipes saved in iCloud will come back. |
| S-37 | Start Fresh alert, buttons | Start Fresh (destructive), Cancel |
| S-38 | Recovery, disclosure | Details |

---

## 7. Open decisions for Pops

| # | Question | Proposal |
|---|---|---|
| SC-1 | What a capture becomes before it is read | **Ruled:** a recipe right away, titled "New recipe", that M3 fills in. Pops, 22 Nov 2026 (decision card, "A recipe right away") |
| SC-2 | Where Let's cook. lives | **Ruled:** a capsule at the bottom of the library, hidden on Mac. Pops, 22 Nov 2026 (decision card, "Capsule at the bottom") |
| SC-3 | Search and sort in M2 | **Ruled:** not until M3, when recipes have titles. Pops, 22 Nov 2026 (decision card, "Accept all three") |
| SC-4 | After Save, how she knows it worked | **Ruled:** the camera reopens with a brief "Saved" line. Pops, 22 Nov 2026 (decision card, "Accept all three") |
| SC-5 | Delete Recipe in M2 | **Ruled:** yes, keeping its pages as pages without a recipe. Pops, 22 Nov 2026 (decision card, "Yes, keep its page photos") |
| SC-6 | A photo that hasn't downloaded yet | **Ruled:** a placeholder with a small download icon, filled in when it lands. Pops, 22 Nov 2026 (decision card, "Accept all three") |
| SC-7 | The recovery screen's choices | **Ruled: A**, Try Again or Start Fresh (§5). Pops, 22 Nov 2026 (decision card, "Try Again or Start Fresh") |
| SC-8 | The copy | §6, string by string |

When Pops rules, the rulings are filed in the ledger at this document's close-out.

---

## 8. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.6 | SC-3, SC-4 and SC-6 ruled as proposed; only the copy (SC-8) is open | Pops, 22 Nov 2026 (decision card, "Accept all three") |
| 0.5 | SC-7 ruled: the recovery screen offers Try Again or Start Fresh; Start Fresh sets the old store aside in a dated folder | Pops, 22 Nov 2026 (decision card, "Try Again or Start Fresh") |
| 0.4 | SC-5 ruled: Delete Recipe in M2, its pages kept as pages without a recipe | Pops, 22 Nov 2026 (decision card, "Yes, keep its page photos") |
| 0.3 | SC-2 ruled: Let's cook. is a capsule at the bottom of the library, hidden on Mac | Pops, 22 Nov 2026 (decision card, "Capsule at the bottom") |
| 0.2 | SC-1 ruled: a capture becomes a recipe right away | Pops, 22 Nov 2026 (decision card, "A recipe right away") |
| 0.1 | First draft: the library, the camera, a recipe and the recovery screen for Milestone 2, with SC-1 to SC-8 and every string proposed | `12` §4 and `02` §7: a Screens document before M2's first task; Pops, 22 Nov 2026: "make it so" |
