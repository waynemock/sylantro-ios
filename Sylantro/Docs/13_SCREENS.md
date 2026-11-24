# Sylantro — Screens

**Design document · the library, the camera, a recipe and its review, and the recovery screen,
with every word she reads**
Version 0.22 · 24 November 2026 · **M2's screens and copy accepted (SC-1 to SC-8). M3's review
screens drawn (§2, §3.2, §4.4, §4.5; `15` RV-8 to RV-13, RV-26, RV-28 ruled); SC-9 to SC-12 ruled; S-44 to S-53
approved.** Accepted for M3-3. Every
string in §6 is Claude's proposal. The layout
and the copy are Pops's (`02` §7, `00B` §2). No task is written from an open proposal.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It is the Screens document `02` §7 and `12` §4 ask for before Milestone 2's first task. From v0.18
it also holds Milestone 3's review screens (`15` RV-21). M3-4's (a recipe's pages, and RV-7's
alert) and M3-5's (several recipes on a page) come in a later version.

---

## 0. What this is

Milestone 2 ends with her tapping **+**, photographing a recipe's pages, tapping Save,
and seeing it in the library on iPhone, iPad and Mac (`12` §2). Nothing is read or structured yet
(that is M3), so every screen here has to make sense for a recipe that is, so far, only its
photos. This document says what each screen shows, what each button does, and the exact words.

---

## 1. What is already decided

| ID | Ruling | On screen |
|---|---|---|
| SLT-043 | A scan session starts from the **+** button in the toolbar (rewritten 23 Nov 2026) | §2, §3 |
| SLT-045 | One capture is one recipe; the camera reopens for the next | §3 |
| SLT-046 | Save asks "Is there a page 2?" only when the last page looks unfinished | §3.2 |
| SLT-030, SLT-031, SLT-157 | No photo is thrown away on its own, but Delete Recipe removes everything; the store is never wiped | §4.3, §5 |
| SLT-086 | The library's toolbar: the iCloud button and ⋯ (Update Available, Settings, About, App Store) | §2 |
| SLT-088 | Every confirmation or message is a plain centered alert | throughout |
| SLT-053 | No image data in the database; photos are files that may arrive after their record | §2, §4 |
| `15` RV-8 to RV-13 | Needs Review atop the library; photo and fields; tinted flags; tap to see a line; the kitchen fields editable; Looks Good | §2, §4.4 |
| `15` RV-26, RV-28 | A wrong page-2 warning: cleared by a "Page n of n" footer, dismissed in review, or never set by a third button at the camera | §3.2, §4.4 |
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
| Being read now (M3) | "New recipe" (S-2) | "Reading…" (S-45) |
| Couldn't be read (M3, RV-24) | "New recipe" (S-2) | "Couldn't read these pages" (S-46) |
| Read and structured (M3 on) | its title | its source or author; S-3 when it has neither |
| Photo not downloaded yet | as above | as above; the thumbnail is a placeholder (SC-6) |

**Order:** newest scan first. Sorting and search come with titles in M3 (SC-3; `15` RV-16).

**Needs Review (RV-8, ruled):** a section at the top of the list, headed S-44, holding the read
recipes that still need review, newest first; below it, every other recipe, unheaded, as now.
The section is gone when it's empty. A recipe leaves it at Looks Good (§4.4) or when she edits
it (SC-11, ruled). Recipes not read yet stay in the main list.

**The scan button** (SC-2): a **+** button in the library's toolbar, immediately to the left of
⋯, on iPhone and iPad *(ruled)*, labeled only by its symbol; on the Mac it is hidden, since the
Mac has no document camera (`01` §1).

**Empty library:** SyLibUI's `EmptyStateView`, with a title (S-4) and one line (S-5); no button
of its own (+ is the one way in).

**Toolbar:** as built (SLT-086), plus the + (SC-2).

---

## 3. The camera

Tapping **+** opens VisionKit's document camera full screen (`02` §1). Its own controls
and words are Apple's and are not changed.

### 3.1 After Save

1. The capture's pages are saved at once (`CaptureRecorder`, SLT-041) as one new recipe (SC-1,
   ruled), shown in the library as "New recipe" until M3 reads it.
2. A **pause** shows S-7 with **Next Recipe** (S-42: the camera again, same session) and **Done**
   (S-43: back to the library) (SLT-045, SC-4). Nothing is scanned until Next Recipe, so
   auto-capture can't take the same page twice.
3. **Cancel** in the camera (with no pages taken) ends the session and returns to the library,
   scrolled to the newest recipe.

### 3.2 Is there a page 2? (SLT-046)

When the last page looks unfinished, Save shows a plain alert before saving (S-10 to S-13, S-53):
**Add Page** reopens the camera on the same recipe; **Save Without It** saves it with the
"continues on a page not scanned" warning; **That's All of It** (RV-28, ruled; S-53)
saves it with no warning, for a page that is only ads or a printout's leftovers. Three buttons,
still a plain centered alert (SLT-088).

### 3.3 When saving fails

A plain alert (S-14, S-15), and the pages stay in the camera so nothing is lost. The likely cause
is a full device.

### 3.4 Camera not available

On a device or simulator with no document camera, + shows a plain alert (S-16, S-17).

---

## 4. A recipe

### 4.1 What it shows, before it is read (M2)

- **The pages**, full width, one after another; tap one to see it full screen and zoom.
- Under the title, the line "Waiting to be read" (S-20) until M3 reads it; with the page-2
  warning when SLT-046 applies (S-21).
- On iPad and Mac with nothing selected: "Choose a recipe" (S-1, built).

### 4.2 Its toolbar

- **Add Page** (S-22): opens the camera, adds the pages to this recipe (SLT-045).
- **⋯** with **Delete Recipe** (S-23), SC-5 (ruled).

### 4.3 Deleting a recipe (SC-5, ruled; rewritten by SLT-157)

Delete means all gone (SLT-157). Delete Recipe asks with a plain alert (S-24 to S-26), then
removes the recipe, its pages, their photos and its folder in Files, on every device. There is no
undo and no Recently Deleted. A page another recipe still uses is kept. Hiding or archiving a
recipe is parked for later.

### 4.4 A read recipe: the review screen (M3, RV-9 to RV-13)

Once a recipe is read, its screen *is* the review screen (SC-9, ruled): the same screen she opens
from the library, whether or not it still needs review. Nothing else to learn.

**Layout (RV-9, ruled).**

- **iPhone:** the page photo in a strip across the top, about a third of the screen, showing the
  part of the page she last tapped (the title at first). She pulls the strip down to see the
  whole page, and pushes it back up. Below it, the fields, scrolling.
- **iPad and Mac:** the page photos on the left, scrolling, at full width of their column; the
  fields on the right.
- **A recipe still being read:** its pages, with "Reading…" (S-45) under the title in place of
  "Waiting to be read".
- **A recipe that couldn't be read** (RV-24's three tries): its pages, with S-47 under the title
  and a **Try Again** button (S-48), which puts it back in the queue.

**The fields, top to bottom:** the title; the whole-recipe lines (below); Serves or Makes (S-51);
times; Ingredients, with any group names as subheadings; Steps, numbered; Notes; Equipment;
Nutrition, as printed; the source or author. A field the recipe doesn't have isn't shown.
The section headings are S-51.

**Flags (RV-10, ruled).** A field with a flag is tinted (a pale amber background, the system's
`.orange` at low opacity, so it reads in dark mode too) and carries one short line under it in
her words (S-52). A flag that belongs to the whole recipe (continues on a page not scanned; may
hold other recipes) is a line under the title instead, with the warning icon. Flags come from
the structurer's warnings and go away when she taps Looks Good; they aren't stored.

**Tap a line to see it on the page (RV-11, ruled).** Tapping a field (not while editing) zooms
the photo to that line, with a highlight around it; on iPhone the strip slides to it; on iPad
and Mac the page scrolls to it. A field with no known place on the page shows the whole page.

**Editing (RV-12, SC-10, ruled).** An **Edit** button in the toolbar (iOS's own Edit
and Done) makes the title, Serves or Makes, each ingredient line, each step and the notes
editable in place; the other fields stay as read. In Edit she can also add an ingredient or a
step (a + at the end of each list) and delete one (swipe, or the red minus). Done saves. An
ingredient line she changes is read again for its amount and unit; the page's own words stay
with the page (SLT-060). Saving an edit marks the recipe edited (RV-13).

**Looks Good (RV-13, ruled).** While a recipe needs review, a **Looks Good** button (S-49) sits
at the bottom of the fields, full width (SyLib's `CapsuleButton`). It marks the recipe reviewed,
clears its flags and takes it out of Needs Review; the screen stays open. A recipe she never
reviews is still usable.

**"Continues on a page not scanned" (RV-26, RV-28, ruled).** The line under the title (S-21)
gets a small **That's All of It** button (S-53). Tapping it removes the warning for good;
reading the recipe again doesn't bring it back.

**Several recipes on a page.** When the structurer saw other titles on the page, the line under
the title reads S-52's "may hold other recipes" with the titles. Choosing which to keep is M3-5
(RV-14), not drawn here.

### 4.5 The recipe in Files (`recipe.md`, M3)

Once read, `recipe.md` holds the recipe as text, under the same headings as the screen (S-51):
the title, the "Scanned" line (S-40), then Serves or Makes, times, Ingredients, Steps (numbered),
Notes, Equipment, Nutrition and Source, each only when the recipe has it, then the page photos.
No flags. A recipe not read yet stays as M2 wrote it.

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
| S-5 | Empty library, line | Tap + to photograph a recipe from your binder. *(rewritten, approved: Pops, 23 Nov 2026, decision card "Tap + to photograph…")* |
| S-6 | Scan button | *(retired 23 Nov 2026: the + has no text, SLT-043)* |
| S-7 | Saved pause, title (SC-4) | Saved. Ready for the next one. |
| S-42 | Saved pause, button | Next Recipe *(approved: Pops, 23 Nov 2026, decision card "Pause: Next Recipe or Done")* |
| S-43 | Saved pause, button | Done *(approved, as S-42)* |
| S-10 | Page 2 alert, title | Is there another page? *(rewritten, approved: Pops, 23 Nov 2026, decision card "Is there another page?"; was "Is there a page 2?")* |
| S-11 | Page 2 alert, message | This page looks like it keeps going. |
| S-12 | Page 2 alert, button | Add Page |
| S-13 | Page 2 alert, button | Save Without It |
| S-14 | Save failed, title | Couldn't Save |
| S-15 | Save failed, message | Your pages are still here. Free up some space on this device and tap Save again. |
| S-18 | Save failed, button: try again | Save *(approved, Pops, 22 Nov 2026 (decision card, "Use Save, Cancel, OK"))* |
| S-19 | Save failed, button: give up | Cancel *(approved; drops the unsaved pages and closes the camera)* |
| S-16 | No camera, title | Camera Not Available |
| S-17 | No camera, message | Scanning needs an iPhone or iPad camera. |
| S-28 | No camera, button | OK *(approved)* |
| S-20 | Recipe, not read yet | Waiting to be read |
| S-21 | Recipe, page-2 warning | Continues on a page not scanned |
| S-22 | Recipe toolbar | Add Page |
| S-23 | Recipe ⋯ menu | Delete Recipe |
| S-24 | Delete alert, title | Delete This Recipe? |
| S-25 | Delete alert, message | This deletes the recipe and its page photos from all your devices. This can't be undone. |
| S-26 | Delete alert, buttons | Delete (destructive), Cancel |
| S-27 | Photo still downloading | Downloading from iCloud… (VoiceOver label on the placeholder) |
| S-30 | Recovery, title | Sylantro Can't Open Your Recipes |
| S-31 | Recovery, message | Something went wrong opening your recipe library. Nothing has been deleted. |
| S-32 | Recovery, reassurance (from M2-5 only) | A copy of every recipe and photo is safe in Files, in the Sylantro folder. |
| S-33 | Recovery, button | Try Again |
| S-34 | Recovery, button | Start Fresh |
| S-35 | Start Fresh alert, title | Start Fresh? |
| S-36 | Start Fresh alert, message | Your current library is set aside, not deleted, and Sylantro opens a new one. Recipes saved in iCloud will come back. |
| S-37 | Start Fresh alert, buttons | Start Fresh (destructive), Cancel |
| S-38 | Recovery, disclosure | Details |
| S-40 | `recipe.md` in Files, not read yet (M2-5, MT-18 in `14`) | Scanned Nov 22, 2026 · 2 pages (S-3 with the year; "1 page") *(approved: Pops, 22 Nov 2026, decision card "With the year")* |
| S-44 | Library section, recipes to check (RV-8) | Needs Review *(approved)* |
| S-45 | Row line and recipe line, being read | Reading… *(approved)* |
| S-46 | Row line, couldn't be read (RV-24) | Couldn't read these pages *(approved)* |
| S-47 | Recipe, couldn't be read | Sylantro couldn't read these pages. Check that they're in focus, or try again. *(approved)* |
| S-48 | Recipe, couldn't be read, button | Try Again *(approved)* |
| S-49 | Review button (RV-13) | Looks Good *(approved)* |
| S-50 | Edit and Done | iOS's own Edit and Done *(no words of ours)* |
| S-51 | Section headings, screen and `recipe.md` | Serves · Makes · Ingredients · Steps · Notes · Equipment · Nutrition · Source *(approved; "Serves 4", "Makes 24 cookies"; times as printed, "Prep 15 min · Cook 1 hr")* |
| S-52a | Flag, `noTitle` (title) | No title found. Add one. *(approved)* |
| S-52b | Flag, `titleFromLayout` (title) | Check the title. *(approved)* |
| S-52c | Flag, `notOnPage` (one ingredient or step) | Not found on the page. Check it. *(approved)* |
| S-52d | Flag, `droppedNotOnPage` (its field) | Something here wasn't on the page and was left out. *(approved)* |
| S-52e | Flag, `ingredientWasStep` (ingredients) | One of these looked like a step and was moved. *(approved)* |
| S-52f | Flag, `ingredientsFromWholePage` or `ingredientLinesUnsure` (ingredients) | Check the ingredients. *(approved)* |
| S-52g | Flag, `stepsFromWholePage` (steps) | Check the steps. *(approved)* |
| S-52h | Flag, `unreadableLine(page:)` (whole recipe) | A line on page ‹n› couldn't be read. *(approved)* |
| S-52i | Flag, `mayHoldOtherRecipes` (whole recipe) | This page may hold other recipes: ‹titles, comma-separated›. *(approved)* |
| S-52j | Flag, `other` (its field) | Check this. *(approved; the warning's own text is never shown)* |
| S-52k | Flag, `continuesOnUnscannedPage` (whole recipe) | S-21, unchanged |
| S-53 | Page-2 warning, dismiss; and page-2 alert, third button (RV-26, RV-28) | That's All of It *(approved; saves with no warning / removes the warning)* |
| S-41 | Camera permission (`NSCameraUsageDescription`, iOS's own prompt) | Sylantro uses the camera to photograph the pages of your recipes. *(approved: Pops, 23 Nov 2026, decision card "Photograph binder pages")* |

---

## 7. Open decisions for Pops

| # | Question | Proposal |
|---|---|---|
| SC-1 | What a capture becomes before it is read | **Ruled:** a recipe right away, titled "New recipe", that M3 fills in. Pops, 22 Nov 2026 (decision card, "A recipe right away") |
| SC-2 | Where scanning starts | **Ruled:** a + button in the toolbar, left of ⋯, hidden on Mac; the empty library has no button of its own. Pops, 23 Nov 2026 (the + message; decision card, "No, just the + in the toolbar"). *Was: a Let's cook. capsule at the bottom, Pops, 22 Nov 2026* |
| SC-3 | Search and sort in M2 | **Ruled:** not until M3, when recipes have titles. Pops, 22 Nov 2026 (decision card, "Accept all three") |
| SC-4 | After Save, how she knows it worked | **Ruled:** a pause view with S-7, Next Recipe and Done; nothing is scanned until Next Recipe. Pops, 23 Nov 2026 (decision card, "Pause: Next Recipe or Done"). *Was: the camera reopens with a brief "Saved" line, 22 Nov 2026* |
| SC-5 | Delete Recipe in M2 | **Ruled:** yes; **rewritten 23 Nov 2026 (SLT-157):** the recipe, its pages, their photos and its Files folder are all removed; S-25 rewritten. Was: its pages kept as pages without a recipe. Pops, 22 Nov 2026 (decision card, "Yes, keep its page photos"); Pops, 23 Nov 2026: "delete for real… Delete should mean all gone." |
| SC-6 | A photo that hasn't downloaded yet | **Ruled:** a placeholder with a small download icon, filled in when it lands. Pops, 22 Nov 2026 (decision card, "Accept all three") |
| SC-7 | The recovery screen's choices | **Ruled: A**, Try Again or Start Fresh (§5). Pops, 22 Nov 2026 (decision card, "Try Again or Start Fresh") |
| SC-8 | The copy | §6, string by string. **Approved:** S-30, S-31 and S-33 to S-38 as drafted; S-32 as drafted, shown only from M2-5, once the Files copy exists. Pops, 22 Nov 2026 (decision card, "As drafted, S-32 waits for M2-5"). S-0 to S-27 approved as drafted, S-15 saying "this device". Pops, 22 Nov 2026 (decision card, "As drafted, with 'this device'"). **All copy approved.** |

| SC-9 | Review: its own screen, or the recipe's | **Ruled: the recipe's.** Pops, 24 Nov 2026 (decision card, "The recipe's own screen"): a read recipe's screen is the review screen; Looks Good shows only while it needs review. Nothing new to find, and a recipe looks the same before and after review. *Other:* a separate review screen opened from Needs Review |
| SC-10 | How editing starts (RV-12) | **Ruled: iOS's Edit and Done.** Pops, 24 Nov 2026 (decision card, "iOS's Edit and Done"): one Edit makes the kitchen fields editable in place, with + and delete on the lists; Done saves. *Other:* tap any field to edit just that one |
| SC-11 | Does an edit take a recipe out of Needs Review | **Ruled: yes.** Pops, 24 Nov 2026 (decision card, "Yes, an edit takes it out"): editing means she has looked at it, and the store already marks it edited (`ReviewState.edited`), which RV-7 needs. *Other:* it stays until Looks Good, which needs a new stored field |
| SC-12 | M3's copy | **Ruled: as drafted.** S-44 to S-53 approved. Pops, 24 Nov 2026 (decision card, "As drafted") |

When Pops rules, the rulings are filed in the ledger at this document's close-out.

---

## 8. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.22 | SC-12 ruled: S-44 to S-53 approved as drafted; M3's screens accepted for M3-3 | Pops, 24 Nov 2026 (decision card, "As drafted") |
| 0.21 | SC-11 ruled: an edit takes a recipe out of Needs Review (`ReviewState.edited`) | Pops, 24 Nov 2026 (decision card, "Yes, an edit takes it out") |
| 0.20 | SC-10 ruled: iOS's Edit and Done edit the kitchen fields in place | Pops, 24 Nov 2026 (decision card, "iOS's Edit and Done") |
| 0.19 | SC-9 ruled: a read recipe's own screen is its review screen | Pops, 24 Nov 2026 (decision card, "The recipe's own screen") |
| 0.18 | M3's review screens drawn: Needs Review in the library (§2), the page question's third button (§3.2), the review screen (§4.4) and `recipe.md`'s sections (§4.5); SC-9 to SC-12 and S-44 to S-53 proposed | `15` RV-8 to RV-13, RV-21, RV-26, RV-28 ruled; Pops, 24 Nov 2026 |
| 0.17 | SC-5 and §4.3 rewritten: Delete Recipe removes everything (SLT-157); S-25 rewritten | Pops, 23 Nov 2026: "delete for real… Delete should mean all gone." (S-25 wording from the decision card he answered) |
| 0.16 | SC-4 rewritten: a pause after Save; S-42 Next Recipe and S-43 Done added and approved | Pops, 23 Nov 2026: "what is the green check in. the camera view for? it take it as an I'm done scanning, but when I tap it the camera stays on the screen. and it typically get another scan of the same document."; decision card, "Pause: Next Recipe or Done" |
| 0.15 | S-10 rewritten: "Is there another page?" | Pops, 23 Nov 2026 (decision card, "Is there another page?") |
| 0.14 | SC-2 rewritten: + in the toolbar replaces the Let's cook. capsule; S-5 rewritten; S-6 retired; the empty library has no button | Pops, 23 Nov 2026: "lets move the lets cook button to just a + button to the left of the menu button. odd name and placement. + is commmon in lots of our apps and other apps too."; decision cards "Tap + to photograph…", "No, just the + in the toolbar" |
| 0.13 | S-41 added and approved: the camera permission message, in `Info.plist` | Pops, 23 Nov 2026 (decision card, "Photograph binder pages") |
| 0.12 | S-40 approved | Pops, 22 Nov 2026 (decision card, "With the year") |
| 0.11 | §6: S-40 proposed, `recipe.md`'s date line for M2-5 (`14` MT-18) | M2-5 written; Pops, 22 Nov 2026 |
| 0.10 | S-18, S-19 and S-28 approved | Pops, 22 Nov 2026 (decision card, "Use Save, Cancel, OK") |
| 0.9 | S-18, S-19 and S-28 proposed: the Save-failed and No-camera alerts' buttons, which §6 had left out | `14` M2-4 |
| 0.8 | S-0 to S-27 approved; S-15 says "this device", not "your iPhone"; all of §6 approved | Pops, 22 Nov 2026 (decision card, "As drafted, with 'this device'") |
| 0.7 | The recovery screen's copy approved (S-30 to S-38); S-32 shown only once the Files copy exists (M2-5) | Pops, 22 Nov 2026 (decision card, "As drafted, S-32 waits for M2-5") |
| 0.6 | SC-3, SC-4 and SC-6 ruled as proposed; only the copy (SC-8) is open | Pops, 22 Nov 2026 (decision card, "Accept all three") |
| 0.5 | SC-7 ruled: the recovery screen offers Try Again or Start Fresh; Start Fresh sets the old store aside in a dated folder | Pops, 22 Nov 2026 (decision card, "Try Again or Start Fresh") |
| 0.4 | SC-5 ruled: Delete Recipe in M2, its pages kept as pages without a recipe | Pops, 22 Nov 2026 (decision card, "Yes, keep its page photos") |
| 0.3 | SC-2 ruled: Let's cook. is a capsule at the bottom of the library, hidden on Mac | Pops, 22 Nov 2026 (decision card, "Capsule at the bottom") |
| 0.2 | SC-1 ruled: a capture becomes a recipe right away | Pops, 22 Nov 2026 (decision card, "A recipe right away") |
| 0.1 | First draft: the library, the camera, a recipe and the recovery screen for Milestone 2, with SC-1 to SC-8 and every string proposed | `12` §4 and `02` §7: a Screens document before M2's first task; Pops, 22 Nov 2026: "make it so" |
