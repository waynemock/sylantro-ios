# Sylantro — SyLib Image Cache, Memory Only

**A Syzygy Softwerks working contract**
Version 0.3 · 22 November 2026 · **M2-4a complete** (1659 SyLib tests); Pops's diff check open. Companion to `14_MILESTONE_2_CAPTURE.md` (task M2-4) · Ships with `00A`, `00B` and `00_DECISION_LEDGER.md`
*One additive SyLibCache task (M2-4a): `ImageCache` can keep an image in memory without writing it to disk. The new argument defaults to today's behavior, so every existing caller is unchanged.*

---

## 0. How to use this document

Protocol is `00A` and `00B`, unchanged. The task ends at "ready for Pops's check". This document
lives in Sylantro's suite, but every edit it makes is in SyLib. No other app's repository is
opened, built or tested (`00A` §3).

**Status: complete** (22 Nov 2026; checked by Claude against its Done-when).

**Paths.** `LIB/` is the SyLib package root (`sylib-swift/`).

**Line numbers are the tree at SyLib `f4a1eda` (Improve game night reconnection).** Find every
edit by its quoted text.

**Tests** run on an iOS simulator from `LIB/`, never with `swift test`:

```sh
xcodebuild test -scheme SyLib-Package -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5'
```

**Compatibility.** Additive: one new last parameter on `store(_:for:)`, defaulting to today's
behavior. A test proves the default. Report the suite total before and after.

---

## 1. Task M2-4a · `ImageCache.store(_:for:toDisk:)`

**Why.** Sylantro shows a thumbnail of each recipe's first page in the library (`13` §2). Its
thumbnails are made on each device and never stored (`05` P-4, SLT-053), and its photos are HEIC,
never JPEG (SLT-054). Today `store(_:for:)` always writes a JPEG to the caches folder as well as
keeping the image in memory (`LIB/Sources/SyLibCache/ImageCache.swift`, `public func store(_ image:
UIImage, for url: URL)`), and there is no way to keep one in memory only. Pops chose to add one to
SyLib rather than keep a separate cache in Sylantro (card "Add memory-only to SyLib first",
22 Nov 2026).

**Read:** `LIB/Sources/SyLibCache/ImageCache.swift`;
`LIB/Tests/SyLibTests/SyLibCache/ImageCacheTests.swift`; `LIB/Docs/CACHE.md`, section ImageCache.
Nothing else.

1. **`store`** gains a last parameter: `public func store(_ image: UIImage, for url: URL, toDisk:
   Bool = true)`. The image goes into memory exactly as today. The JPEG is encoded and written
   only when `toDisk` is true; when false, nothing is encoded, no file is written, and **an
   existing file for that URL is left as it is** (not deleted, not replaced). With `toDisk` true
   the method does exactly what it does today. No other member changes.

2. **The doc comment** on the type gains one line in its example: `await ImageCache.shared.store(image,
   for: url, toDisk: false) // memory only`. The method gets a doc comment saying what `toDisk`
   does.

3. **Tests**, added to `ImageCacheTests.swift` in the existing `@Suite("ImageCache")`, each with
   its own `TempCache`:
   - "Storing in memory only writes no file": `store(image, for: url, toDisk: false)`, then
     `memoryImage(for:)` is non-nil, `currentDiskSize()` is 0, and after `purgeMemoryCache()`
     `diskImage(for:)` is nil.
   - "Storing in memory only keeps an existing file": `store(image, for: url)`, note
     `currentDiskSize()`, then `store(otherImage, for: url, toDisk: false)`; the size is unchanged
     and, after `purgeMemoryCache()`, `diskImage(for:)` is non-nil.
   - "Storing without toDisk still writes to disk" (the default reproduces today): `store(image,
     for: url)`, then `currentDiskSize()` is greater than 0 and, after `purgeMemoryCache()`,
     `diskImage(for:)` is non-nil. If an existing test already proves exactly this, name it in the
     row instead of adding one, and say the count.

4. **Docs.** `LIB/Docs/CACHE.md` § ImageCache: the example block gains the memory-only line; the
   Lookup and storage table's `store` row becomes `func store(_ image: UIImage, for url: URL,
   toDisk: Bool = true)`, "Puts `image` in memory and, when `toDisk` is true (the default), writes
   it to disk as a JPEG at 85% quality. With `toDisk` false no file is written and an existing one
   is left as it is. A failed write is ignored."; the line "Every image is stored as JPEG" becomes
   "Every image written to disk is stored as JPEG"; and the adoption note *Sylantro adoption:
   library thumbnails, made on the device from HEIC photo files, are kept in memory only
   (`toDisk: false`), so no JPEG is written (Sylantro `14A`, SLT-053, SLT-054).*

**Done when:**

1. The package tests pass on the destination above, including the new ones; the suite total is
   reported before and after (before + the tests added).
2. No file changes outside `LIB/Sources/SyLibCache/ImageCache.swift`,
   `LIB/Tests/SyLibTests/SyLibCache/ImageCacheTests.swift`, `LIB/Docs/CACHE.md`, and this
   document's §3 row. Sylantro's own source is not touched; it adopts the argument in M2-4.
3. No new warnings in the SyLib build.
4. `git status` before and after, in `LIB/` and in Sylantro, and every git command run (`00A` §9).

**Do not:** change `diskImage`, `memoryImage`, the limits, the key, the JPEG quality, `CachedImage`
or any other module; add a cost argument; delete any file in the cache.

**Pops check M2-4a.** Read the diff and the doc section.

---

## 2. Open in this document

| # | Question | Proposal |
|---|---|---|
| SY-1 | The shape of the new API | **Ruled:** a last parameter `toDisk: Bool = true` on `store(_:for:)`; the default is today's behavior. Pops, 22 Nov 2026 (decision card, "A toDisk: argument") |

---

## 3. Results log

| Task | Date | Status | Summary |
|---|---|---|---|
| M2-4a | 22 Nov 2026 | **complete**, ready for Pops's check | **Destination:** `platform=iOS Simulator,name=iPhone SE (3rd generation),OS=26.5`, from `LIB/`, `xcodebuild test -scheme SyLib-Package`. **Suite total before:** "✔ Test run with 1656 tests in 214 suites passed after 4.338 seconds." **After:** "✔ Test run with 1659 tests in 214 suites passed after 4.961 seconds."; `** TEST SUCCEEDED **` (1656 + 3). **Clauses:** ✅ 1 the package tests pass, including the three new tests in `@Suite("ImageCache")`, each with its own `TempCache`: "Storing in memory only writes no file", "Storing in memory only keeps an existing file" and "Storing without toDisk still writes to disk". I added the third rather than naming an existing test: no single existing test checks both the disk size and the disk read-back after a purge. "currentDiskSize returns > 0 after storing an image" checks only the size, and "Stored image survives memory purge and is readable from disk" checks only the read. ✅ 2 the only files changed are `LIB/Sources/SyLibCache/ImageCache.swift`, `LIB/Tests/SyLibTests/SyLibCache/ImageCacheTests.swift`, `LIB/Docs/CACHE.md` and this row. Sylantro's source is untouched. ✅ 3 no new warnings. The after log's only `warning:` line is the build tool's own "appintentsmetadataprocessor: Metadata extraction skipped, no AppIntents.framework dependency found" for `SyLibTests`, which prints when the test bundle is relinked. The before run was already up to date and didn't reach that step, which is why its count was 0. There is no compiler warning in either log. ✅ 4 git status and commands are below. **What changed:** `ImageCache.store(_ image: UIImage, for url: URL, toDisk: Bool = true)` puts the image in memory as before, then `guard toDisk else { return }`. With `false`, nothing is encoded or written and an existing file is left as it is. With `true` the body is byte-for-byte today's. It now has a doc comment on `toDisk`, and the type's example gains `await ImageCache.shared.store(image, for: url, toDisk: false) // memory only`. `diskImage`, `memoryImage`, the limits, the key, the JPEG quality and `CachedImage` are unchanged. `CACHE.md` § ImageCache gets the example line, the `store` row as written in 14A, "Every image written to disk is stored as JPEG", and the Sylantro adoption note, in italics after that line. **Git status, SyLib, before** (branch `syjong-integration`, head `f4a1eda` as 14A expects): clean. **After:** ` M Docs/CACHE.md`, ` M Sources/SyLibCache/ImageCache.swift`, ` M Tests/SyLibTests/SyLibCache/ImageCacheTests.swift`. **Git status, Sylantro, before** (branch `milestone-2`): Pops's M2-1 files staged; unstaged ` M` on `Docs/02`, `05`, `12`, `13`, `README.md`, `SylantroApp.swift`, `Info.plist`, `Sylantro.entitlements`, ` D Item.swift`, `MM` on `Docs/14`; `??` for `Docs/14A_SYLIB_IMAGE_CACHE_MEMORY.md` and M2-2's and M2-3's new folders. **After:** everything above is now staged (`A`, `M` and `D` in the index, nothing unstaged or untracked). Pops did that during the session; the agent ran no git write. This row adds an unstaged change to `14A`. **Git (SyLib):** `git status --short` (×2), `git branch --list`, `git log --oneline -3`. **Git (Sylantro):** `git status --short` (×4, the last confirming that this row is the only unstaged change: `AM` on `14A`), `git diff --stat -- Sylantro/Docs/00A_STUDIO_CONVENTIONS.md Sylantro/Docs/00B_SYLANTRO_GUARDRAILS.md Sylantro/Docs/00_DECISION_LEDGER.md` (empty: unchanged since the last read). **Notes:** the branch `syjong-integration` was worked on as found (`00A` §9). M2-4 can now cache thumbnails with `ImageCache.shared.store(image, for: url, toDisk: false)`. |

---

## 4. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.3 | M2-4a complete, checked by Claude against its Done-when (1656 + 3 = 1659 SyLib tests; the diff matches §1) | §3 row; Pops, 22 Nov 2026: "m2-4a done" |
| 0.2 | SY-1 ruled (`toDisk:` argument); M2-4a ready | Pops, 22 Nov 2026 (decision card, "A toDisk: argument") |
| 0.1 | First draft: task M2-4a, SY-1 open | M2-4 blocked (`14` §2): `ImageCache` has no memory-only store; Pops, 22 Nov 2026 (decision card, "Add memory-only to SyLib first") |
