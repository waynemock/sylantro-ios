# Sylantro — Image Storage Design

**Design document · page scans and dish photos: how they are stored, synced, mirrored and shared**
Version 0.1 · 21 November 2026 · **Draft: not accepted.** Only the rulings in §1 are decided; every
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

---

## 2. What was verified about iCloud and photos

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
| P-1 | **Dish photos.** A recipe can have any number of photos of the finished dish, taken with the camera or picked from Photos; the first is the recipe's cover in the library | A recipe she has cooked is easier to find by its picture |
| P-2 | **One `PhotoModel` for every photo** (§4) | Lists fetch recipes and pages without loading image bytes; each photo syncs as its own record |
| P-3 | **HEIC, sized sensibly** (§5) | Fast sync and less of her iCloud plan, while staying sharp enough to read a page |
| P-4 | **Thumbnails made on each device, never synced**, cached with `ImageCache` | They can always be rebuilt |
| P-5 | **JPEG copies in the mirror**, beside each recipe's plain file (§6) | Any computer can open them; the mirror is the copy that outlives the app |
| P-6 | **A shared recipe file includes its dish photos** as well as its page photos | The receiver gets the whole recipe (`04` SH-5) |
| P-7 | **Settings shows how much iCloud storage Sylantro's photos use**, with a note that it counts against her plan | Photos are the bulk of her data |

---

## 4. The model (P-2)

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
| `data` | `Data?` | `@Attribute(.externalStorage)` |

Every property is optional or defaulted and both relationships are optional (SLT-014). No list or
query reads `data`. Writes go through the writers (SLT-082): `CaptureRecorder` adds page photos and
never removes one (SLT-030); `RecipeEditor` adds, orders and removes dish photos.

**Option:** keep page photos on `SourcePageModel` as today and use `PhotoModel` for dish photos only.
Simpler for the first milestones, but two shapes for the same thing *(rec.: one model for all)*.

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
| **A. The camera's image as HEIC at full resolution** *(rec.)* | Every pixel the camera saw, at a fraction of the size |
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
        page-1.jpg
      photos/
        dish-1.jpg
```

JPEG, not HEIC, so the mirror opens anywhere. `MirrorWriter` writes the copies after each save
(`02` §5.4). A dish photo removed in the app is removed from the mirror; a page photo is never
removed.

---

## 7. What the spike measures

Before any photo task is written:

1. Sync a dozen page and dish photos at §5's sizes between two devices.
2. In CloudKit Console, check whether each photo's field landed as an asset or as bytes, and the
   storage it showed.
3. Note the sync time for a 30-page session.

**If photos land as bytes**, the options are:

| Option | What it is |
|---|---|
| A. Accept it | Simple, but costs her more iCloud storage |
| B. Larger photos, so they cross into assets | Works against P-3 |
| C. Keep image files ourselves and sync them as assets outside SwiftData (for example with `CKSyncEngine`) | Controls the cost; a larger design, made only if the measurement calls for it |

---

## 8. How it fits `01` and `02`

- `01` §5.7 and `02` §5.7 point here.
- `02` §5.1's synced models gain `PhotoModel`; `Domain/` gains `PhotoEncoding`.
- `04`'s file carries photos as §5 encodes them.

---

## 9. Open decisions for Pops

| # | Question |
|---|---|
| P-1 to P-7 | Accept, change or drop each proposal (§3) |
| IS-1 | One `PhotoModel` for all photos, or dish photos only (§4) |
| IS-2 | How the page original is kept (§5: A *(rec.)*, B, C) |
| IS-3 | What to do if the spike shows photos syncing as bytes (§7: A, B, C) |

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
| 0.1 | First version, from `01` §5.7 and `02` §5.7, with the verified CloudKit behavior and the open details as options | Pops, 21 Nov 2026: "Write up docs for sharing and image storage" |
