# Sylantro — Apple News Recipe Import

**Design document · bringing the recipes she and Pops saved in Apple News into Sylantro**
Version 0.2 · 21 November 2026 · **Draft; one ruling in (SLT-120, the way in).** Everything else is
an option for Pops, marked *(rec.)* where Claude recommends one. No task is written from an open
option.

Ships with `00_DECISION_LEDGER.md`, `00A_STUDIO_CONVENTIONS.md` and `00B_SYLANTRO_GUARDRAILS.md`.
It builds on `01_INGESTION_DESIGN.md` (the pipeline, the review inbox, the schema) and
`04_SHARING_DESIGN.md` (importing a recipe, and the duplicate rule SLT-103). It sits inside
`02_ARCHITECTURE.md`'s layers.

---

## 0. What this is

Pops and their partner both save recipes in Apple News (the Food section of Apple News+). They would
like those recipes in Sylantro, beside the binder. The recipe screen in News has a share button;
Pops suspects it sends only a link. This document records what was found about what Apple News
gives an app, lays out the ways in, and lists the decisions that are Pops's.

**The short answer:** the share sheet sends a link, and Apple News has no export of saved recipes,
one or many. So any import works from that link (find the publisher's page, read its recipe data),
from what is on the screen (a screenshot or copied text, through the ingestion pipeline Sylantro
already has), or from both.

---

## 0.1 Rulings

| ID | Ruling |
|---|---|
| SLT-120 | **Link first, screenshots as the fallback** (§2.1 option D). Sharing a recipe from Apple News sends its link to Sylantro, which fetches that one shared page (and the `apple.news` page that leads to it) to read its recipe data; nothing else is fetched, and no third-party service is used (§4 option A). When the page can't be read, she is asked for screenshots, which go through the binder pipeline (`01`). Extraction stays on device (SLT-040) |

Source: Pops, 21 Nov 2026 (decision card, "Link first, screenshots fallback").

---

## 1. What Apple News provides (research, 21 Nov 2026)

| Question | Finding | Confidence |
|---|---|---|
| What is Food? | A section of Apple News+ with recipes from publishers such as Allrecipes, Bon Appétit, Food & Wine, Serious Eats and Epicurious; launched with iOS 18.4 (April 2025). Recipes can be saved and read offline; it has a cook mode with timers | Verified: Apple Newsroom, TechCrunch |
| Does it need a subscription? | Yes, Apple News+ ($12.99 a month in the US). "Select" recipes are free to non-subscribers. US, UK, Canada and Australia only | Verified: Apple Newsroom, TechCrunch |
| What does the share sheet send? | A link. Macworld: "Sharing appears to be limited to sending links." Apple News links are `apple.news/…` addresses, which open the News app on Apple devices and a preview page elsewhere | The link: verified by press. Whether text or an image rides along: **not verified**; the spike checks (§7) |
| Can recipes be printed, saved as PDF or exported? | No. Macworld: "there's no way to print a recipe, save it as a PDF, or any other way to get it out of the app." TechCrunch: no import or export to other apps. A MacRumors thread (May 2025) found no way to print; the workarounds offered were copy and paste, or printing from the publisher's site | Verified for 2025; **to recheck on iOS 26** |
| Can saved recipes be exported in bulk? | No export of any kind was found, and no API or file reaches the saved list | Verified as far as the sources go |
| Does a recipe link back to its publisher? | Yes. TechCrunch says recipe pages link to the publisher's website; Macworld notes a "Read the story" link | Verified by press |
| Can an `apple.news` link be turned into the publisher's address? | Historically yes: the `apple.news` web page carried the original address in a `redirectToUrl("…")` call, which a 2022 script reads. Six Colors (2021) describes the same redirect. Whether a **recipe** link still does in 2026, and whether News+-only items expose it, is **not verified**; network access was blocked from Claude's machine, so the spike checks (§7) | Unverified |
| Do publisher pages carry machine-readable recipes? | Most large recipe sites embed a schema.org `Recipe` in JSON-LD (title, yield, times, ingredient lines, steps, sometimes nutrition), because search engines use it. Some put it behind a paywall or omit it | General knowledge, **not checked against her saved publishers**; the spike checks |
| Is there an Apple API for News content? | No public API reads a user's News library or saved recipes | Verified by absence |

**What this means.** There is nothing to "sync" from Apple News. Each saved recipe is brought in
one at a time, by her acting on it in News. The design's job is to make each one quick, and to make
a run of twenty feel like the binder: share, share, share, and review later (SLT-041).

Sources: [Apple Newsroom, Feb 2025](https://www.apple.com/newsroom/2025/02/apple-introduces-news-plus-food/);
[TechCrunch, Feb 2025](https://techcrunch.com/2025/02/21/apple-takes-on-recipe-apps-with-apple-news-food);
[Macworld, Mar 2025](https://www.macworld.com/article/2648587/apple-news-food-should-be-the-best-way-to-cook-heres-why-its-not.html);
[MacRumors forum, May 2025](https://forums.macrumors.com/threads/cannot-print-recipes-from-apple-news-food.2456484/);
[Six Colors, Aug 2021](https://sixcolors.com/member/2021/08/tip-reform-wayward-apple-news-links/);
[apple-news.sh gist, 2022](https://gist.github.com/remi/da04f16bd05250a6283dc3b1ca9a1ef3);
[Apple support: recipes in Apple News+](https://support.apple.com/guide/iphone/iph0b8f646ca/ios).

---

## 2. The ways in

### 2.1 The options

| Option | What she does | What Sylantro does | For | Against |
|---|---|---|---|---|
| **A. Share the link: resolve it and read the publisher's recipe data** | In News: Share → Sylantro | Saves the link at once, then in the background follows `apple.news` to the publisher's page, reads its schema.org `Recipe`, and puts a draft in the review inbox | One tap; exact text, no reading errors; ingredients arrive as lines, ready for the parser; keeps the source address for dedup | Needs the network, and the page fetch reveals the address to the publisher (§4); depends on an undocumented `apple.news` page and on each publisher's markup; a paywalled page may give nothing |
| **B. Screenshots through the existing pipeline** | Screenshots the recipe (two or three for a long one), then Share → Sylantro | Treats each image as a `SourcePage` and runs Vision and Foundation Models, as for a binder page | Works for News+-only recipes and any app; fully on device (SLT-040); reuses `01` end to end; the screenshot is a lasting original (SLT-030) | Several screenshots a recipe; reading errors are possible, though screen text reads far better than paper; joining pages in review |
| **C. Copy the text** | Selects the recipe's text in News, copies, then pastes in Sylantro (or shares the text) | Skips Vision; Foundation Models structures the text | No reading errors; on device | Text selection in Food is unverified; selecting a whole recipe on a phone is fiddly; no picture of the original |
| **D. A + B together** *(rec.)* | Share → Sylantro from News; if the page cannot be read, she is asked for screenshots | Tries A; falls back to B | Most recipes in one tap; nothing is lost when a publisher blocks it; the fallback is a pipeline already being built | Two paths to build and test; the network question (§4) still applies to the A half |
| E. Visual Intelligence or on-screen content (iOS 26) | Uses Apple's screenshot actions to send the screen to Sylantro | An App Intent receives the screen | Feels native | Unverified that a third-party app can receive a recipe this way; Apple's surface here moves each release. Noted, not proposed |

### 2.2 Generalizing beyond Apple News

Option A reads schema.org `Recipe` data, which most recipe websites carry. The same share
extension, offered for any web link, would import from Safari too. That is a product expansion
(the binder app becomes a web clipper as well), so it is Pops's question, NI-2 *(rec.: build A for
any `https` link, since the work is the same, and present it as "Apple News and the web")*.

---

## 3. How option A would work

1. **Receive.** A share extension accepts one or more web links
   (`NSExtensionActivationSupportsWebURLWithMaxCount`). It does almost nothing itself: it writes
   each link into a small inbox in a shared App Group container and closes, well under a second.
   Extensions have a tight memory limit and can be killed, so no network fetching or Foundation
   Models runs there *(rec.)*.
2. **Save first.** The app picks the links up (on launch, or from the extension's handoff) and
   saves each as a pending import in the synced store, so a link shared on her iPhone is not lost
   if the phone dies before it is fetched. This mirrors "the page is safe" in `01` §2.
3. **Resolve.** An `apple.news` link is fetched once to find the publisher's address (the
   redirect, `og:url` or canonical link, whichever the spike finds reliable). A link that is
   already a publisher's address skips this.
4. **Read.** The publisher's page is fetched and its JSON-LD searched for a `Recipe`
   (including one inside an `@graph`). Its fields map to `Recipe`: `name` → title,
   `recipeYield` → `Yield`, `prepTime`, `cookTime`, `totalTime` (ISO 8601 durations) → `Times`,
   `recipeIngredient` → ingredient lines through `IngredientLineParser`, `recipeInstructions`
   (text, `HowToStep` or `HowToSection`) → `Step`s and groups, `author` and the publisher →
   attribution. Printed nutrition, if present, is kept as the publisher's figures, apart from
   Sylantro's own calculation (`03`).
5. **No recipe data?** If the page is paywalled, blocked or has no `Recipe`, the import is
   flagged "Needs screenshots" in the inbox, with the link, and she can add screenshots that run
   through option B *(rec.)*. A page's plain text is **not** fed to Foundation Models as a
   fallback: web pages are long and noisy for its small context, and the screenshot path is
   better tested.
6. **Review.** The draft enters the same review inbox as a scanned page, marked as from the web,
   with the publisher's name and a link to the page.
7. **Save.** Through `RecipeEditor` (SLT-082), mirrored like any recipe (SLT-050).

The parsing of JSON-LD into `Recipe` is pure and belongs in `Domain/` (a `SchemaOrgRecipeReader`,
name to be accepted), tested on made-up fixtures. The fetching belongs in the App layer.

### 3.1 What is kept as the original (SLT-030, SLT-060)

A binder page keeps its photo forever. A web recipe has no paper, so something must stand in for
it, or a future reader can't re-read it and the publisher may later change or remove the page.

| Option | What is kept | For | Against |
|---|---|---|---|
| **A. The JSON-LD block and the address** *(rec.)* | The raw `Recipe` JSON as fetched, its URL, and the fetch date, as a new kind of source alongside `SourcePage` | Small; exactly what was read; can be re-read by a better mapper | Not something she can look at |
| B. A, plus a snapshot of the page | Also a PDF or web archive of the page | She can see what it looked like | Large; cookie banners and ads; copyright of the whole page |
| C. A, plus a screenshot-like image of the recipe | Also an image rendered from the recipe data | Something to show in review | Made up by Sylantro, not an original |

How the source is modeled (a `SourcePage` with a kind, or a separate `SourceWebPage`) is a schema
change to `01` §4 and `06`'s M1-1, NI-5.

---

## 4. The network question (SLT-040)

SLT-040 says extraction is on device: Vision and Foundation Models, nothing sent out. Option A
reads no photo and sends none of her data out, but it **does** fetch two web pages, so the
publisher sees a request for that recipe from her phone. That is the same as her opening the
recipe in Safari, and Sylantro would send no identifiers, cookies or account. It is still the first
time Sylantro uses the network for content, so it is Pops's to allow (NI-1). Options:

| Option | What it means |
|---|---|
| **A. Allow fetching the shared page only** *(rec.)* | Sylantro fetches the page she shared, and nothing else; no third-party service, no tracking, no cookies kept; SLT-040 stays as it is for extraction, with a new ruling for web import |
| B. No network | Option B or C only (screenshots, copied text) |

No third-party "recipe scraper" service is proposed: it would see every link and is a running
cost, against the spirit of SLT-040.

---

## 5. Duplicates (SLT-103)

The rule stays SLT-103: skip when clearly the same, otherwise ask (Keep Both, Replace, Skip).
Web imports add one strong signal:

| Case | How it is recognized | What happens |
|---|---|---|
| **Clearly the same** | The resolved publisher address (normalized: no tracking parameters, no fragment, `https`) matches a recipe she holds, and title and ingredients are identical | Skipped with a short note |
| **Possibly the same** | The same address but the publisher has changed the text; or a matching title and similar ingredients by ingestion's check (`01` §2), for example the same recipe she once printed and scanned from the binder | She chooses Keep Both, Replace or Skip |
| Not the same | Neither | Imported as new |

This needs the recipe to store its source address, normalized, in `attribution` (NI-5). Two people
saving the same recipe (Pops and their partner, on separate Apple IDs) end up with two independent
copies in two libraries; sending one to the other through `04` meets this same rule.

---

## 6. Rights and limits

- **Personal use only.** Importing a recipe she has access to into her own library is like
  printing it for the binder. It is never published (SLT-102).
- **Sending to family** (`04`, SLT-100) sends the publisher's text in the file. The publisher and
  the address travel with it as attribution *(rec.)*.
- **News+-only recipes.** A recipe free in News but paywalled on the publisher's site may come
  back without data; option B covers it. Sylantro never logs in to a publisher or works around a
  paywall.
- **No Apple News+ branding** in the app beyond plain words ("Apple News") in help text, and no
  claim of a partnership. App Review copy is Pops's.
- **Countries.** Food exists in the US, UK, Canada and Australia; the import itself does not
  depend on where she is.

---

## 7. A small spike before any task

Most of §1's open points can be settled in half an hour on her phone and Pops's Mac, without code:

1. In News, share five saved recipes from different publishers into Notes or Messages. Record
   exactly what arrives: the link's form (`apple.news/A…`), and whether any text or image comes
   with it.
2. On the Mac, open each link in Safari (File → Open in Safari, per Six Colors) and note where it
   lands. View the page source of the `apple.news` page for `redirectToUrl`, `og:url` or a
   canonical link.
3. On each publisher page, check for `"@type":"Recipe"` in the page source, logged in and not.
4. In News, try to select and copy a recipe's ingredients (option C), and take a full screenshot
   (option B; check whether News offers "Full Page").
5. Count roughly how many recipes each of them has saved, and from which publishers.

Claude can write this up as a checklist for Pops, or as a spike task with a results log in the
`00A` form. No recipe content from the spike enters the repository (`00B` §2).

---

## 8. How it fits `01`, `02`, `04` and `05`

- `01` §2 gains a second entry to the pipeline: a shared link or screenshot, beside the camera.
  The review inbox is shared. §4's schema gains the web source (§3.1) and the source address (§5).
- `02` gains a share extension target, an App Group (an entitlements change, `00B` §2) and the App
  layer's fetcher; `Domain/` gains the JSON-LD reader. All of it is Pops's to approve, and built by
  the Xcode agent from a task.
- `04`'s import path and duplicate check are reused; a web recipe is sent like any other.
- `05`: screenshots are stored as page images, at screenshot size; whether they get a
  `PhotoModel` kind of their own is `05`'s P-2.
- **When.** After Milestone 3 (extraction and review), since it feeds the review inbox *(rec.)*.
  Option B needs nothing new but the share target once Milestone 3 exists.

---

## 9. Open decisions for Pops

| # | Question | Options |
|---|---|---|
| ~~NI-1~~ | ~~Which way in, and may Sylantro fetch the shared page~~ | **Decided: SLT-120**, link first with screenshots as fallback, fetching the shared page only |
| NI-2 | Apple News only, or any recipe website | §2.2: any `https` link *(rec.)*; Apple News only |
| NI-3 | Where it sits in the milestones | §8: after Milestone 3 *(rec.)*; sooner, as a separate milestone |
| NI-4 | What is kept as the original of a web recipe | §3.1: A, the JSON-LD and address *(rec.)*; B, plus a page snapshot; C, plus a rendered image |
| NI-5 | How the web source and address enter the schema | §3.1, §5: a `SourcePage` kind or a new source type; the address in `attribution`. Settled with `06` M1-1, before its JSON is frozen |
| NI-6 | A paywalled or unreadable page | §3 step 5: flag "Needs screenshots" *(rec.)*; or try Foundation Models on the page text |
| NI-7 | Run the spike in §7 first | Yes, as a checklist for Pops *(rec.)*; as a spike task doc |

When Pops rules, the rulings are filed in the ledger as SLT-120 onward at this document's close-out.

---

## 10. Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.2 | SLT-120: link first, screenshots as the fallback; fetching only the shared page is allowed; NI-1 closed | Pops, 21 Nov 2026 (decision card, "Link first, screenshots fallback") |
| 0.1 | First version: what Apple News provides (a link only, no export), five ways in, the network question, duplicates, the original's stand-in, a spike, and open decisions NI-1 to NI-7 | Pops, 21 Nov 2026: "importing recipes from apple news… i suspect its just a link. start a new design doc for this idea." |
