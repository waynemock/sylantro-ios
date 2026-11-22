# Sylantro — Sharing Design

**Design document · sending one recipe to another Sylantro user, and what is left for later**
Version 0.2 · 22 November 2026 · **Rulings SLT-100 to SLT-103 in; everything else is an option for
Pops**, marked *(rec.)* where Claude recommends one. No task is written from an open option.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It builds on `01_INGESTION_DESIGN.md` (the recipe and its pages) and sits inside
`02_ARCHITECTURE.md`'s layers. Photos in a shared file follow `05_IMAGE_STORAGE_DESIGN.md`.

---

## 0. What this is

She will want to send a recipe to a friend or a family member who also uses Sylantro. This document
fixes how that works for the MVP, and records what was deliberately left out: a shared family
binder, and any public recipe database.

---

## 1. Rulings

| ID | Ruling |
|---|---|
| SLT-100 | **The MVP shares one recipe at a time, as a file.** From a recipe, the share sheet sends a Sylantro recipe file (the recipe's JSON with its page photos). Another Sylantro user opens it and it is imported as a new recipe in their own library. No server and no CloudKit: the file travels by AirDrop, Messages or Mail like any other |
| SLT-101 | **A shared database (a family binder through CloudKit sharing) is parked.** Not designed or built for the MVP. When it is revisited, first verify what SwiftData's sync supports on iOS 26: it has historically synced only the private database (§6) |
| SLT-102 | **No public database.** Recipes are never published for strangers: moderation, abuse, other people's copyright, and the App Review burden of user-generated content |
| SLT-103 | **A recipe she already has is skipped when it is clearly the same, and she is asked when it might be** (§4) |

Source for all four: Pops, 21 Nov 2026 ("Send a recipe for mvp. Park shared db for later. No public
given the issues." and "Dedup of clear otherwise ask the user what to do").

---

## 2. Sending

- **Where:** a Share button on the recipe screen; the system share sheet does the rest.
- **What goes:** the recipe as `recipe.json` describes it (`01` §4), with its `schemaVersion`, the
  id of the recipe it came from (the source id, which §4 needs), and its page photos. Whether dish
  photos go too is `05`'s P-6 *(rec.: yes)*. Photos are HEIC inside Sylantro and JPEG when a
  recipe is exported (SLT-054); whether a file sent to another Sylantro is an export, and so
  JPEG, is open *(rec.: no, HEIC, since both ends are Sylantro)*.
- **What never goes:** anything about her other recipes, her nutrition settings, or her review
  history beyond the recipe's own `reviewState`.
- **How it is built** *(rec.)*: a `ShareLink` with a `Transferable` that writes the file;
  the file itself is made in `Domain/` by `RecipeTransfer`, so it is tested with plain values.

### 2.1 The file's format: options

| Option | What it is | For | Against |
|---|---|---|---|
| **A. One JSON document, photos embedded as base64** *(rec.)* | `recipe.json` plus a `photos` array, in one file | Plain Foundation; one file travels anywhere; trivially tested | About a third larger than the photos alone |
| B. A zip archive | `recipe.json` and the photo files, zipped | Smaller; the photos stay real files | Needs an archive library or Apple Archive; more to test |
| C. A file package (a folder shown as one file) | The mirror's folder layout as a package | Matches the mirror exactly | Messages and Mail don't carry folders well |

### 2.2 Its name: options

| Option | Extension | Type identifier |
|---|---|---|
| **A** *(rec.)* | `.sylantro` | `com.syzygysoftwerksllc.sylantro.recipe`, conforming to `public.data` |
| B | `.sylrecipe` | the same identifier |

The type is exported in `Info.plist`, so the file opens in Sylantro from Files, Mail and Messages.
Adding it touches `Info.plist`, which is Pops's to approve in the task that does it.

### 2.3 For people without Sylantro: option

| Option | What it does |
|---|---|
| **A. Not in the MVP** *(rec.)* | Only Sylantro users can open the file |
| B. Also offer Send as Text | The share sheet also offers the recipe as plain text (`recipe.md`'s content), readable by anyone |
| C. Also offer a PDF | A printable page, with the cover photo |

---

## 3. Receiving

- Opening the file launches Sylantro, which decodes it and runs it through `RecipeValidator`, the
  same schema check structuring results pass (SLT-042). A file that fails is refused with a
  message; nothing is saved from it.
- A file is from a newer Sylantro if its `schemaVersion` is higher than the app knows: it is
  refused with a message to update the app *(rec.)*.
- A file that passes, and is not a duplicate (§4), becomes a new recipe in her library: new ids, its
  page photos saved as `SourcePage`s, `reviewState` kept, and a note of where it came from (the
  sender's display name is not known, so the note is "Imported" and the date) *(rec.)*. It is
  mirrored like any other recipe.
- **Nothing links the two copies afterward.** An edit on one never reaches the other.
- Writes go through the writers (SLT-082): `CaptureRecorder` saves the pages, `RecipeEditor` the
  recipe.

---

## 4. A recipe she already has (SLT-103)

| Case | How it is recognized | What happens |
|---|---|---|
| **Clearly the same** | The file's source id is a recipe she holds (she sent it from her own library, or imported it before), and the title, yield, ingredients and steps are identical | Skipped, with a short note that she already has it |
| **Possibly the same** | A matching title or similar ingredients, by ingestion's duplicate check (`01` §2) | She chooses **Keep Both**, **Replace** or **Skip** |
| Not the same | Neither | Imported as new |

Nothing is merged or replaced without her choice. To recognize the clear case, an imported recipe
stores the source id it arrived with.

**What Replace keeps: options.**

| Option | What it does |
|---|---|
| **A. Replace the text, keep her photos and notes** *(rec.)* | Title, yield, ingredients and steps come from the file; her id, her dish photos, her own notes and her nutrition matches stay |
| B. Replace everything | Her copy becomes exactly the file's |

The copy for the note and the choice is Pops's (`00B` §2).

---

## 5. Not in the MVP

- **A shared family binder** (SLT-101): §6.
- **A public database** (SLT-102): never.
- **Sending several recipes at once**, or a whole binder section *(option for later)*.
- **Following a recipe** so a sender's later edits arrive: not planned; SLT-100 says the copies are
  independent.

---

## 6. Later: a shared family binder (SLT-101)

When Pops reopens it, the questions are:

1. **Can SwiftData sync a shared database on iOS 26?** It has historically synced only the private
   database. If it still can't, the options are Core Data's `NSPersistentCloudKitContainer` with a
   shared store, or CloudKit directly (for example with `CKSyncEngine`) for the shared part. To
   verify against Apple's current documentation before any design.
2. **What is shared:** a whole binder, or chosen sections.
3. **Who owns a shared recipe**, and whose iCloud storage its photos use (the owner's, in CloudKit
   sharing).
4. **How it meets the mirror:** whether shared recipes are mirrored on every member's device.

---

## 7. How it fits `01` and `02`

- `01` §5.6 and `02` §5.6 point here.
- `02` gains `RecipeTransfer` in `Domain/` (§2) and the import path in the root's file handling
  (§3), through the one sheet presenter for §4's choice.
- The container keeps only its private database (SLT-101, SLT-102).

---

## 8. Open decisions for Pops

| # | Question | Options |
|---|---|---|
| SH-1 | The file's format | §2.1: A *(rec.)*, B, C |
| SH-2 | Its extension and type identifier | §2.2: A *(rec.)*, B |
| SH-3 | Anything for people without Sylantro | §2.3: A *(rec.)*, B, C |
| SH-4 | What Replace keeps | §4: A *(rec.)*, B |
| SH-5 | Whether dish photos go in the file | `05` P-6 *(rec.: yes)* |
| SH-6 | A file from a newer Sylantro | §3: refuse with a message to update *(rec.)* |

---

## 9. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.2 | §2: SLT-054's photo format; HEIC or JPEG in a Sylantro-to-Sylantro file left open | Pops, 22 Nov 2026: "I decide on heic instead of jpg, this will only be an apple apple, if we need to export a recipe it can be jpg." |
| 0.1 | First version, from `01` §5.6 and `02` §5.6 and SLT-100 to SLT-103, with the open details laid out as options | Pops, 21 Nov 2026: "Write up docs for sharing and image storage" |
