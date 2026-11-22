# Sylantro — Image Storage Design

**Design document · page scans and dish photos: how they are stored, synced, mirrored and shared**
Version 0.11 · 22 November 2026 · **Draft: not accepted.** Only the rulings in §1 are decided; every
proposal (P-1 to P-7) and option is Pops's to decide, marked *(rec.)* where Claude recommends one.
No task is written from an open proposal.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It fills in the photos of `01_INGESTION_DESIGN.md` inside `02_ARCHITECTURE.md`'s layers; shared
files are `04_SHARING_DESIGN.md`'s.

---

## 0. What this is

Sylantro keeps two kinds of image: **page scans**, the photos of her binder pages that ingestion
keeps forever, and, proposed here, **dish photos** of what she cooked. Photos are most of the app's
data by size, and they sync through her own iCloud, so how they are stored decides how fast the
library feels and how much of her iCloud plan Sylantro uses.

---

## 1. What is already decided

| ID | Ruling | What it means for images |
|---|---|---|
| SLT-030 | Her data outlives the app | The original page photo is never thrown away |
| SLT-050 | SwiftData on the CloudKit private database, plus a mirror in Files | Photos sync through her iCloud and are copied into the mirror |
| SLT-014 | Every synced property optional or defaulted | So is every photo field |
| SLT-084 | SyLibCache is added when thumbnails are built | `ImageCache` is the thumbnail cache |
| SLT-100 | A shared recipe file carries its page photos | `04` §2 |
| SLT-053 | **No image data in the database** | Every photo is a file; its record in the store holds only metadata and the file's name (§4, §4.1) |

---

## 2. What was verified about iCloud and photos

**Background since SLT-053.** These findings are why storing photos in the database was costly
and hard to control. Pops ruled that no image data goes in the database at all, so the
asset-or-bytes question below no longer applies to Sylantro; it is kept as the reason for the rule.

Read on Apple's developer forums and its archived CloudKit limits page, 21 Nov 2026 (§10).

- **It is her storage.** In the private database, synced data counts against her own iCloud plan,
  not the studio's. Apple staff say one CloudKit asset can be up to 50 GB if she has the space, and
  that an app should handle `CKError.quotaExceeded`.
- **`.externalStorage` is about the device only.** It keeps large bytes in files beside the store on
  the device. It does not decide how CloudKit carries them.
- **The app does not choose asset or bytes.** Core Data's CloudKit mirroring (which SwiftData uses)
  decides whether a binary field syncs as a CloudKit asset or as bytes inside the record. Apple
  staff say this can't be controlled. In practice it moves to an asset as the record nears 1 MB, a
  record's own limit (not counting assets), but there is no fixed threshold.
- **Bytes cost more.** Apple staff say bytes inside a record use much more iCloud storage than the
  same data as an asset; one report measured about ten times. A photo of a few hundred KB could sync
  as bytes.
- **Still to verify:** what actually happens to Sylantro's photos. §7 measures it in the spike.

---

## 3. Proposals

| # | Proposal | Why |
|---|---|---|
| P-1 | **Dish photos** *(ruled: the model now, the screens after M3)*. A recipe can have any number of photos of the finished dish, taken with the camera or picked from Photos; the first is the recipe's cover in the library. M2's `PhotoModel` carries the `dish` kind and the recipe link; taking, picking and showing dish photos is built after M3 | A recipe she has cooked is easier to find by its picture |
| P-2 | **One `PhotoModel` for every photo** (§4) | Lists fetch recipes and pages without loading image bytes; each photo syncs as its own record |
| P-3 | **HEIC, sized sensibly** (§5) *(ruled: §5's figures as starting points, tuned after the sync check)* | Fast sync and less of her iCloud plan, while staying sharp enough to read a page |
| P-4 | **Thumbnails made on each device, never synced**, cached with `ImageCache` *(ruled; also required by SLT-053)* | They can always be rebuilt |
| P-5 | **HEIC copies in the mirror** *(ruled)*, beside each recipe's plain file (§6): the same files the app keeps | Smaller, and identical to the app's own; some older PCs and websites can't open HEIC. Pops, 22 Nov 2026 (decision card, "HEIC copies") |
| P-6 | **A shared recipe file includes its dish photos** as well as its page photos | The receiver gets the whole recipe (`04` SH-5) |
| P-7 | **Settings shows how much iCloud storage Sylantro's photos use**, with a note that it counts against her plan *(ruled: yes, built after M2)* | Photos are the bulk of her data |

---

## 4. The model (P-2, ruled)

**Ruled: one `PhotoModel` for every photo** (P-2, IS-1), Pops, 22 Nov 2026 (decision card, "One PhotoModel for every photo").

`PhotoModel`, in the synced store:

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `kindRaw` | `String` | `pageOriginal`, `pageCropped` or `dish`; a raw string, so an unknown future kind survives |
| `sourcePage` | `SourcePageModel?` | For a page photo; the inverse on `SourcePageModel` |
| `recipe` | `RecipeModel?` | For a dish photo; the inverse on `RecipeModel` |
| `sortIndex` | `Int` | Dish photo order; 0 is the cover |
| `pixelWidth`, `pixelHeight` | `Int` | For layout before the image loads |
| `takenAt` | `Date` | |
| `fileName` | `String?` | The image file's name, `<id>.heic`, in the photo folder (§4.1). Never the bytes (SLT-053) |

Every property is optional or defaulted and both relationships are optional (SLT-014). The record
is a few hundred bytes, so lists and sync never carry an image. Writes go through the writers (SLT-082): `CaptureRecorder` adds page photos and
never removes one (SLT-030); `RecipeEditor` adds, orders and removes dish photos.

**Option:** keep page photos' file names on `SourcePageModel` as today and use `PhotoModel` for dish photos only.
Simpler for the first milestones, but two shapes for the same thing. *Not taken (IS-1).*

### 4.1 Where the image files live (IS-4, ruled: A)

**Ruled: option A**, Pops, 22 Nov 2026 (decision card, "App-only folder in iCloud Drive"). Filed in the ledger at this document's close-out.

The store holds the file's name; the file has to be somewhere that reaches her other devices.

| Option | What it is | For | Against |
|---|---|---|---|
| **A. An app-only photo folder in her iCloud Drive** *(ruled)* | HEIC files in the app's iCloud container but outside `Documents`, so Files doesn't show them; iCloud Drive syncs them. The mirror keeps its own HEIC copies (P-5) | Nothing she does in Files can break the app; sync is Apple's, file by file | Two copies of each photo in her iCloud (one in the hidden folder, one in the mirror) |
| B. The mirror's folders are the photo store | Each photo lives once, in its recipe's folder in Files | One copy; less iCloud use | Moving or deleting a file in Files breaks the app; a page moves folders when it joins a recipe |
| C. CloudKit assets the app syncs itself | Files on the device, sent as CloudKit assets with `CKSyncEngine`, outside SwiftData | Full control of sync and cost | A much larger design and more code to get right |

In every option, with iCloud off the files go in the app's own folder on the device. A record can
arrive on a device before its file does: the app asks iCloud to download it and shows a
placeholder until it lands, and never treats a missing file as a deleted photo (SLT-030).

---

## 5. Encoding (P-3)

| Image | Size | Format | Typical size |
|---|---|---|---|
| Page, original | The document camera's own resolution | HEIC, quality about 0.7 | A few hundred KB to about 1 MB |
| Page, cropped | The same | HEIC, quality about 0.7 | A few hundred KB |
| Dish photo | Long edge 2,048 px | HEIC, quality about 0.7 | A few hundred KB |
| Thumbnail | Long edge about 400 px, on the device only | In `ImageCache` | Tens of KB |

The figures are starting points for the spike (§7), held as one constant each in `Domain/`'s
`PhotoEncoding` (`00A` §10).

**Options for the page original:**

| Option | What it keeps |
|---|---|
| **A. The camera's image as HEIC at full resolution** *(ruled, IS-2)* | Every pixel the camera saw, at a fraction of the size |
| B. Lossless (PNG) | Exactly what the camera returned, at several times the size |
| C. Original only, no separate cropped copy; crop on the fly | Half the photos, but the crop is redone every time |

---

## 6. The mirror (P-5)

```
Sylantro/
  Recipes/
    <title-slug>-<first 8 of id>/
      recipe.json
      recipe.md
      pages/
        page-1.heic
      photos/
        dish-1.heic
```

HEIC, the same as the app's own files (P-5, SLT-054): Sylantro is Apple-only. A recipe exported
out of Sylantro carries JPEG copies instead (SLT-054). `MirrorWriter` writes the copies after each save
(`02` §5.4). A dish photo removed in the app is removed from the mirror; a page photo is never
removed.

---

## 7. What the spike measures

Since SLT-053 there is no asset-or-bytes question. Once the photo task is built, Pops checks on
his iPhone and iPad:

1. A 30-page session's photos reach the other device, and how long it takes.
2. A recipe opened on the other device before its photos arrive shows placeholders, then the
   photos, with nothing lost.
3. In CloudKit Console, the photo records are small (no image field), as SLT-053 requires.

---

## 8. How it fits `01` and `02`

- `01` §5.7 and `02` §5.7 point here.
- `02` §5.1's synced models gain `PhotoModel`; `Domain/` gains `PhotoEncoding`.
- `04`'s file carries photos as §5 encodes them.
- Unreadable handwriting (SLT-066, `10` TS-15) is shown as a piece of the cropped page photo, cut on
  the fly by its `sourceBox`. It is not a new photo kind and nothing extra is stored or synced; it
  relies on the cropped page being on every device, which §5's option C would change.

---

## 9. Open decisions for Pops

| # | Question |
|---|---|
| P-6 | Accept, change or drop (§3), at M6's start; P-1 to P-5 and P-7 are ruled |
| IS-1 | *Ruled:* one `PhotoModel` for all photos (§4) |
| IS-2 | *Ruled: A,* HEIC at full resolution, plus a separate cropped copy (§5) |
| IS-3 | *Settled by SLT-053:* no photo bytes in the store, so none can sync as bytes |
| IS-4 | *Ruled: A,* an app-only photo folder in her iCloud Drive (§4.1) |

---

## 10. Sources

- Apple Developer Forums, "Best Practices for Binary Data ('Allows External Storage') in Core Data
  with CloudKit Sync": https://developer.apple.com/forums/thread/803646
- Apple Developer Forums, "Clarification on Current CloudKit CKAsset File Size Limits":
  https://developer.apple.com/forums/thread/827897
- Apple Developer Forums, "Core Data Plus CloudKit — Binary Data w/ External Storage":
  https://developer.apple.com/forums/thread/728412
- Apple Developer Forums, "Why does CloudKit data field (bytes) take up more iCloud storage than
  asset field?": https://developer.apple.com/forums/thread/659570
- CloudKit Web Services Reference, "Data Size Limits" (archived, 2016):
  https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/PropertyMetrics.html

---

## 11. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.11 | §6: SLT-054, HEIC in the app and the mirror, JPEG only on export | Pops, 22 Nov 2026: "I decide on heic instead of jpg, this will only be an apple apple, if we need to export a recipe it can be jpg." |
| 0.10 | P-7 ruled: Settings shows Sylantro's iCloud photo use, built after M2 | Pops, 22 Nov 2026 (decision card, "Yes, but after M2") |
| 0.9 | P-3 and P-4 ruled: §5's sizes as starting points; thumbnails on each device only | Pops, 22 Nov 2026 (decision card, "Accept as starting points") |
| 0.8 | P-5 ruled: HEIC copies in the mirror, not JPEG | Pops, 22 Nov 2026 (decision card, "HEIC copies") |
| 0.7 | IS-2 ruled: the page original as HEIC at full resolution, with a separate cropped copy | Pops, 22 Nov 2026 (decision card, "HEIC at full resolution") |
| 0.6 | P-1 ruled: dish photos; the `dish` kind and recipe link in M2's model, the screens after M3 | Pops, 22 Nov 2026 (decision card, "Yes, model now, screens later") |
| 0.5 | P-2 and IS-1 ruled: one `PhotoModel` for every photo, page and dish | Pops, 22 Nov 2026 (decision card, "One PhotoModel for every photo") |
| 0.4 | IS-4 ruled: A, HEIC files in an app-only folder in her iCloud container, outside `Documents`; the mirror keeps its JPEG copies | Pops, 22 Nov 2026 (decision card, "App-only folder in iCloud Drive") |
| 0.3 | SLT-053: no image data in the database. §4's `data` becomes `fileName`; §4.1 and IS-4 added (where the files live); §7's measurement rewritten; IS-3 settled | Pops, 22 Nov 2026: "looks good. can you make sure we are storing no image data in the database" |
| 0.2 | §8: unreadable handwriting is cut from the cropped page photo on the fly, not stored | SLT-066 (Pops, 21 Nov 2026: "Handwritten that cannot be decoded should be called out and maybe inlined as an image in the recipe view.") |
| 0.1 | First version, from `01` §5.7 and `02` §5.7, with the verified CloudKit behavior and the open details as options | Pops, 21 Nov 2026: "Write up docs for sharing and image storage" |
