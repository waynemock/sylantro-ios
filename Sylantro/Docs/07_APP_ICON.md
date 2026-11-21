# Sylantro — App Icon

**A Syzygy Softwerks record · Delivered**
Version 0.4 · 21 November 2026 · **Records the icon's concept, the palette it uses, and the prompt that will produce it — not for the agent.** Locked by Pops and filed as SLT-110 to SLT-115.

Modeled on SyJong's `11_APP_ICON.md` (v1.11, Pops's best icon doc yet), which descends from SyDice's `03_APP_ICON.md`, Syzygies' `07_APP_ICON.md`, Score It \*'s `APP_ICON.md` and Syderal's `02_APP_ICON_PROMPT.md`. Its lighting follows SyFive's `APP_ICON_PROMPT.md`, Pops's favorite of the family, which ChatGPT generated.

---

## Status

**Delivered, 21 Nov 2026: locked by Pops and placed in `AppIcon.appiconset` by Claude** (decision card: "Lock; Claude places the PNGs"): `SylantroAppIcon.png` in the any and dark slots, `SylantroAppIconTinted.png` in the tinted slot, the Mac slots left empty. About's full-size copy is in `AppIconFull.imageset` (placed by Claude, SLT-115); its test is the Xcode agent's `00B` Task A-4. Open: the on-device check.

**Generated, 21 Nov 2026:** Pops's ChatGPT render of THE PROMPT, checked by Claude. Pops, on the render: "looks great".

| | |
|---|---|
| Asset | `AppIcon/SylantroAppIcon.png` (for the any and dark slots) and `AppIcon/SylantroAppIconTinted.png` (tinted). The untouched original is `AppIcon/SylantroAppIcon_ChatGPTRaw.png` |
| Format | 1024 × 1024, 8-bit RGB, no alpha, non-interlaced, sRGB profile embedded, no EXIF: made by Claude, 21 Nov 2026. **The render arrived at 1254 × 1254** (with an sRGB chunk and EXIF), so it was scaled to 1024 (Lanczos), with no other change. If Pops has ChatGPT's own download at another size, it replaces the raw and the master is remade from it |
| How it was made | ChatGPT's image generation (AI-6): THE PROMPT in a fresh chat with `SylantroIconDraft.png` attached; the first render Pops liked |
| Checked | `AppIcon/Sylantro_AppIcon_checks.png`, below |

### What Claude checked on the icon, 21 November 2026

`AppIcon/Sylantro_AppIcon_checks.png`: the icon at 180, 60 and 29 px with Apple's corner rounding, 29 px zoomed 4×, the tinted variant at 60 and 29 px, and a row with SyJong, SyFive and SyDice on light and dark Home Screens.

| Check | Result |
|---|---|
| The subject | One sprig: a crown of three overlapping rounded leaflets on a slender stem, a smaller leaflet either side, pale veins. Nothing else on the canvas, no text. The leaflets are broad and soft-lobed, never pointed. Small round nubs sit at a few lobe tips, visible only at full size |
| Colors, sampled | The field `#032B1E`–`#042D1E` around the sprig, `#002219`–`#012419` at the corners, the shadow `#00180F`: **darker than asked** (`#113724` to `#08291D`), close to SyJong's first delivered field (`#072013`, JONG-172 before its 10% lift). It reads as green, not black. The leaves `#45AA5D` in shade to `#8BDA97` lit, the stem `#36994F`, veins `#86D795`: Forest, as §The palette |
| Contrast | Relative luminance about 34 for the field against 169 for the leaves: the sprig stands well clear, the green-on-green worry answered |
| Extent | The sprig spans x 126–906 and y 83–955 of 1024, about 85% of the canvas tall, as AI-4. **Nothing falls outside Apple's corner rounding** (0 pixels, checked against a 229 px radius) |
| Small sizes | At 60 px a bright green sprig, its three leaf clusters and stem clear. At 29 px three green clusters on dark green, the stem a thread: it reads as a plant, lighter in weight than SyJong's tile or SyFive's die, since a sprig has more field around it than a solid object. **At 29 px it could be taken for a clover**; the name beside it settles that |
| Beside the family | SyFive's lighting and scale. It shares SyJong's dark green field, as Pops chose, and is told apart by its shape: a sprig, where SyJong is an ivory tile |
| Grayscale | Field dark, leaves light, veins lighter: the tinted variant reads at 60 and 29 px |

**Ready to generate, 21 Nov 2026 (v0.2).** **The Sprig on dark Forest, chosen 21 Nov 2026; ready for ChatGPT.** Pops: "the sprig on dark forest looks best to me. use a similar bg color as we did for syjong." The field is SyJong's delivered one (`#113724` behind the subject, `#08291D` at the corners, JONG-172). The draft to attach is `AppIcon/SylantroIconDraft.png` (the Sprig's field study on that field); Pops runs THE PROMPT below in a fresh ChatGPT chat.

**Concepts proposed, 21 Nov 2026.** Pops: "I want to design the app icon next, look at the syjong-ios APP_ICON doc. its our best one yet. we use chatgpt for it." Claude drew four rough concepts in code, each with a paste-ready ChatGPT prompt below (§The concept prompts), so Pops can choose from the sketches, or run any of the prompts first and choose from ChatGPT's renders.

| | |
|---|---|
| Concepts compared | `AppIcon/Sylantro_Concepts_Compare.png`: the four concepts at 300, 60 and 29 px with Apple's corner rounding, 29 px zoomed 4×, and 60 px in grayscale; then The Sprig on three fields (midnight, dark Forest, kitchen ivory) |
| The draft | `AppIcon/SylantroIconDraft.png`: The Sprig on SyJong's dark Forest field, code-drawn, the same image as `Sylantro_Field_forest.png`. Attached to THE PROMPT as the layout and color reference |
| The sketches | `AppIcon/Sylantro_Concept1_Sprig.png`, `…Concept2_RecipeCard.png`, `…Concept3_ScannedPage.png`, `…Concept4_LeafInViewfinder.png`; the field studies `AppIcon/Sylantro_Field_midnight.png`, `…_forest.png`, `…_kitchen.png`. 1024 × 1024, code-drawn layouts, not finished art: ChatGPT renders the finished icon (AI-6) |
| The asset catalog | `Sylantro/Assets.xcassets/AppIcon.appiconset` has the three iOS slots (any, dark, tinted) and ten Mac sizes from the template, **all empty** (read 21 Nov 2026). The `AppIconFull.imageset` About would draw at full size (SyJong's `22` M10-2) does not exist yet |

### Open items

- [x] Pops picks the concept (AI-1) and the field (AI-3): The Sprig on dark Forest, 21 Nov 2026
- [x] Claude names the draft (`SylantroIconDraft.png`, checked in the compare sheet's field row) and writes THE PROMPT from Concept 1's
- [x] Pops generates in ChatGPT: THE PROMPT, the draft attached; the render chosen ("looks great"), 21 Nov 2026
- [x] Claude checks the chosen image (§Process step 3) and makes the tinted variant: `Sylantro_AppIcon_checks.png`
- [x] Pops locks the icon and the remaining *(rec.)* rulings; Claude files them in the ledger as SLT-110 to SLT-115: 21 Nov 2026
- [x] The files go in `AppIcon.appiconset`: Claude, at Pops's choice, 21 Nov 2026 (`Contents.json` names them in the three iOS slots)
- [x] `AppIconFull` for About: placed by Claude at Pops's go-ahead, 21 Nov 2026 (SLT-115)
- [ ] About's icon test: the Xcode agent, `00B` Task A-4
- [ ] On-device check at **29 × 29 px** and 60 × 60 px, in light, dark and tinted Home Screens, beside the family's icons
- [x] Archive the untouched raw original as the master: `AppIcon/SylantroAppIcon_ChatGPTRaw.png`

---

## What the icon has to say

- **Sylantro is cilantro.** The name is the studio's *Sy* on cilantro, and the App Color defaults to Forest because green suits a cilantro app (SLT-085). A cilantro leaf is the one mark that is Sylantro's own; no other recipe app owns it.
- **It reads printed recipes.** Its first job is turning a binder of printed pages into structured recipes (SLT-020, SLT-021). A page or a scan frame says that; a leaf alone does not.
- **One object on the night table.** The family's formula (SyFive's die, SyDice's d20, SyJong's tile): one bold silhouette, lit from the top left, readable at 29 px. Every studio icon learned that busy marks turn to mush at that size.
- **Kitchen, not chemistry.** "Let's cook." is only an in-app nod (SLT-043). **No Breaking Bad imagery at all:** no lab glassware, flasks, beakers, blue crystals, periodic-table tiles, hazmat suits, gas masks, RVs or desert, and nothing that leans on the show's colors or type.
- **Calm and warm.** Her kitchen in daylight, a page she trusts with her recipes (SLT-030). Not a loud food-delivery icon.

---

## The concepts (AI-1)

Each is one paste-ready prompt in §The concept prompts. Small-size notes come from `Sylantro_Concepts_Compare.png`.

| # | Concept | What it says | At 60 and 29 px | Risks |
|---|---|---|---|---|
| 1 | **The Sprig.** One cilantro sprig standing on the field: a stem, a crown of three rounded leaflets at the top, a smaller leaflet either side | Cilantro, so the name. Fresh, simple, calm | The strongest silhouette of the four: a green plant at both sizes | Says nothing about recipes or scanning; a generic herb could be read as parsley or basil. Image models drift cilantro toward a cannabis leaf; the prompt guards against it |
| 2 | **The Recipe Card.** An ivory recipe card lying on the table, turned a little, a green title line and gray ingredient and step lines on it, a cilantro sprig laid across its lower corner | A recipe, and Sylantro's. The page from her binder | At 60 px a card with a green sprig; at 29 px a light card with a green spot | The lines turn to stripes, as text does at that size; two objects instead of one, so it is the busiest |
| 3 | **The Scanned Page.** An ivory printed recipe page, upright and flat, framed by four rounded green camera-scan corners, a small cilantro leaf beside its title line | The app's job: the camera reads a printed recipe | At 60 px a page in a viewfinder; at 29 px a light rectangle in green corners, still a "scan" | The most like a document-scanner app; the leaf is too small to read below 60 px |
| 4 | **The Leaf in the Viewfinder.** One large cilantro leaf, centered, framed by four rounded green scan corners | Cilantro, scanned: both ideas in one bold mark | The cleanest at 29 px: a green leaf in green corners | No page, so "recipe" is left to the name; the corners and leaf in one green can merge in grayscale (the tinted icon) |

**Chosen: Concept 1, The Sprig** (Pops, 21 Nov 2026). Claude's recommendation had been the same: **Concept 1, The Sprig**, or Concept 4 if Pops wants the scanning story in the mark. Both are one object with one silhouette, which every studio icon has found reads best; the Sprig is the purest version of the family's formula, and a leaf is what makes Sylantro's name land. Concepts 2 and 3 tell the story better at full size and lose it at 29 px. This is Pops's call.

---

## The field (AI-3)

`AppIcon/Sylantro_Field_*.png` show The Sprig on each.

| Field | Hex | For | Against |
|---|---|---|---|
| Midnight (Claude's first recommendation) | `#0B0B16` at the edges, `#1C1A33` behind the subject | The family's shared field (SyFive, SyDice, Syzygies); the Forest green has the most contrast on it; dark-native, so one PNG serves light and dark (AI-5) | Night table, where Sylantro is a daylight kitchen app (SLT-085) |
| **Dark Forest — chosen** | `#08291D` at the edges, `#113724` behind: SyJong's delivered field | Matches the App Color; Pops's pick | **SyJong's field already** (JONG-172): two green icons side by side; the green subject is lowest in contrast on it |
| Kitchen ivory | `#E3D6BC` at the edges, `#FBF6EA` behind | Daylight and paper, the only light icon in the family, so it stands out | Breaks the family's look; a light icon needs its own dark variant made, and a page on ivory (Concepts 2 and 3) loses its edge |

---

## The palette

| Element | Hex | Source |
|---|---|---|
| Leaf, light side | `#6FCB8F` | Forest, lifted for the lit side |
| Leaf and scan corners | `#4DB373` | Forest's `primaryAccent` (`SyTheme`), Sylantro's default App Color (SLT-085), as read in SyJong's `11`. **If `SyTheme`'s Forest changes, it changes here too** |
| Leaf, shaded side and stem | `#2A7A4B` | Forest, deepened |
| Veins | `#A6E0B8` | Forest, pale |
| Paper | `#F7F4EC`, lit to `#FFFDF7` and shaded to `#E4DDCD` | The family's ivory (SyJong's tile face) |
| Printed lines | `#B8B0A0` | Warm gray on the paper |
| Field | see §The field | AI-3 |

---

## THE PROMPT

For ChatGPT's image generation, in a **fresh chat**, with `AppIcon/SylantroIconDraft.png` attached. It is Concept 1's prompt on SyJong's dark Forest field, the reference line first, and one change for the green-on-green: the leaves are asked to stay clearly brighter than the field, the lesson of SyJong's base that "kinda disappears on the dark forest bg" (JONG-172).

```
Use the attached image as the layout and color reference; render it in the style described. The attached image is a rough code-drawn sketch: keep its composition, not its flat look.

Create a full-bleed 1024×1024 square App Store icon.

Background: a continuous dark forest green, about #113724 behind the sprig, falling to about #08291D at the edges and corners, with a soft glow behind the sprig and an extremely subtle vignette, filling the entire canvas edge-to-edge. It reads clearly as green, but stays dark. No inner panel, no inset, no framing, no borders, no container shapes. No flat black, no texture, no grain, no pattern.

Main subject: a single fresh cilantro (coriander) sprig standing upright, as if laid in soft light on an unseen night table, that dominates the canvas, laid out as in the attached image.

• The sprig occupies about 85–90% of the canvas height, centered, and no part of it is cropped.
• One slender stem rising from the bottom, with a crown of three broad, rounded cilantro leaflets at the top and one smaller leaflet branching out to each side, lower down.
• Every leaflet is unmistakably cilantro: flat, broad and fan-shaped, with three soft rounded lobes and gently scalloped edges, like a flat-leaf coriander leaf. Not pointed, not narrow, not serrated like a saw, never palmate with long finger-like points.
• Minimal negative space; the composition feels bold, but nothing is cropped.

Color: bright, fresh forest green leaves (#4DB373), lighter (#6FCB8F) where the light falls and deeper (#2A7A4B) in the shade and on the stem, with fine, pale green veins (#A6E0B8). The leaves are clearly brighter and fresher than the dark green background, so the sprig stands out crisply against it and never blends in. Matte and fresh, slightly stylized, not photorealistic and not cartoony.

Lighting: soft cinematic light from the top left, as on a premium die on a night table. Gentle highlights on the upper-left edges of the leaves; soft shade on their lower right. Subtle depth where the leaflets overlap. A soft grounding shadow below the sprig that blends seamlessly into the background and stays visible. Extremely subtle vignette.

No texture.
No grain.
No glow effects.
No extra objects.
No text, letters or numbers.

Minimal, calm, premium, high-contrast, optimized for small icon readability.

This is final production App Store icon artwork.
```

**If it misses**, one change per follow-up in that chat, and stop after two (SyJong's 2 Dot lesson):

- *The sprig blends into the field:* 

```
Keep this image exactly as it is. Make the leaves a little brighter and fresher green, so they stand out more against the dark green background; nothing else changes.
```

- *The leaves read as parsley, basil or cannabis:* 

```
Keep this image exactly as it is, but redraw each leaflet as a flat-leaf cilantro leaf: broad and fan-shaped, three soft rounded lobes, gently scalloped edges, no points; nothing else changes.
```

**Checks when it comes back** (§Process step 3): one sprig, nothing else; every leaflet broad, rounded and lobed; the field sampled near `#113724` and `#08291D`, still green, with the shadow showing; the leaves clearly brighter than the field; nothing outside the corner rounding; at 29 px a green plant beside SyJong's icon, which shares the field.

## The concept prompts

*Kept for the record; Concept 1 became THE PROMPT above.*

For ChatGPT's image generation, written in the manner of SyFive's prompt and SyJong's THE PROMPT. **One concept per fresh ChatGPT chat.** Each is written on the midnight field *(rec.)*; for another field, send the field follow-up below in the same chat. To hold ChatGPT to the sketch's layout, attach that concept's `AppIcon/Sylantro_Concept*.png` and paste this line above the prompt:

```
Use the attached image as the layout and color reference; render it in the style described. The attached image is a rough code-drawn sketch: keep its composition, not its flat look.
```

### Concept 1 — The Sprig

```
Create a full-bleed 1024×1024 square App Store icon.

Background: a continuous deep midnight indigo-black (#0B0B16 at the edges, rising to a deep indigo #1C1A33 glow behind the subject), filling the entire canvas edge-to-edge. No inner panel, no inset, no framing, no borders, no container shapes. One seamless background surface. Dark, but not a flat pure-black void.

Main subject: a single fresh cilantro (coriander) sprig standing upright, as if laid in soft light on an unseen night table, that dominates the canvas.

• The sprig occupies about 85–90% of the canvas height, centered, and no part of it is cropped.
• One slender stem rising from the bottom, with a crown of three broad, rounded cilantro leaflets at the top and one smaller leaflet branching out to each side, lower down.
• Every leaflet is unmistakably cilantro: flat, broad and fan-shaped, with three soft rounded lobes and gently scalloped edges, like a flat-leaf coriander leaf. Not pointed, not narrow, not serrated like a saw, never palmate with long finger-like points.
• Minimal negative space; the composition feels bold, but nothing is cropped.

Color: fresh forest green leaves (#4DB373), lighter (#6FCB8F) where the light falls and deeper (#2A7A4B) in the shade and on the stem, with fine, pale green veins (#A6E0B8). Matte and fresh, slightly stylized, not photorealistic and not cartoony.

Lighting: soft cinematic light from the top left, as on a premium die on a night table. Gentle highlights on the upper-left edges of the leaves; soft shade on their lower right. Subtle depth where the leaflets overlap. A soft grounding shadow below the sprig that blends seamlessly into the same background plane. Extremely subtle vignette.

No texture.
No grain.
No glow effects.
No extra objects.
No text.

Minimal, calm, premium, high-contrast, optimized for small icon readability.

This is final production App Store icon artwork.
```

### Concept 2 — The Recipe Card

```
Create a full-bleed 1024×1024 square App Store icon.

Background: a continuous deep midnight indigo-black (#0B0B16 at the edges, rising to a deep indigo #1C1A33 glow behind the subject), filling the entire canvas edge-to-edge. No inner panel, no inset, no framing, no borders, no container shapes. One seamless background surface. Dark, but not a flat pure-black void.

Main subject: a single printed recipe card lying on an unseen night table, turned a little counterclockwise, with a fresh cilantro (coriander) sprig laid across its lower-right corner. Together they dominate the canvas.

• The card occupies about 80% of the canvas height; no part of it or the sprig is cropped.
• The card: warm ivory paper (#F7F4EC), matte, softly rounded corners, a hint of paper thickness at its edge. On it, abstract printed lines, never real words: one bold green title bar (#4DB373) near the top, then a short list of ingredient lines, each with a small round bullet, then a few longer lines of method. The lines are a soft warm gray (#B8B0A0), crisp and evenly spaced.
• The sprig: a short stem with three or four broad, rounded cilantro leaflets, each flat and fan-shaped with three soft rounded lobes and gently scalloped edges. Not pointed, not serrated like a saw, never palmate with long finger-like points. Fresh forest green (#4DB373), lighter (#6FCB8F) where lit and deeper (#2A7A4B) in shade, with pale veins (#A6E0B8). It casts a small soft shadow on the card.

Lighting: soft cinematic light from the top left, as on a premium die on a night table. Gentle highlights on the paper and on the upper-left edges of the leaves; soft shade on the lower right. A soft grounding shadow below the card that blends seamlessly into the same background plane. Extremely subtle vignette.

No texture.
No grain.
No glow effects.
No extra objects.
No readable text, letters or numbers.

Minimal, calm, premium, high-contrast, optimized for small icon readability.

This is final production App Store icon artwork.
```

### Concept 3 — The Scanned Page

```
Create a full-bleed 1024×1024 square App Store icon.

Background: a continuous deep midnight indigo-black (#0B0B16 at the edges, rising to a deep indigo #1C1A33 glow behind the subject), filling the entire canvas edge-to-edge. No inner panel, no inset, no framing, no borders, no container shapes. One seamless background surface. Dark, but not a flat pure-black void.

Main subject: a single printed recipe page, upright and facing the viewer straight on, held inside four camera-scan corner brackets, as a phone camera frames a page it is reading.

• The four brackets mark the corners of a square that fills about 85% of the canvas: thick, rounded L-shaped strokes with rounded ends, in fresh forest green (#4DB373), softly lit, with a hint of depth. No full frame, only the four corners.
• The page sits inside them, about 65% of the canvas height: warm ivory paper (#F7F4EC), matte, softly rounded corners, a hint of paper thickness at its edge.
• On the page, abstract printed lines, never real words: at the top, one small cilantro leaf followed by a bold green title bar (#4DB373); then a short list of ingredient lines with small round bullets; then a few longer lines of method. The lines are a soft warm gray (#B8B0A0), crisp and evenly spaced.
• The leaf is unmistakably cilantro: flat, broad and fan-shaped, with three soft rounded lobes. Not pointed, not serrated like a saw, never palmate with long finger-like points.

Lighting: soft cinematic light from the top left, as on a premium die on a night table. Gentle highlights on the paper and the brackets' upper-left edges; soft shade on the lower right. A soft shadow behind the page that blends seamlessly into the background. Extremely subtle vignette.

No texture.
No grain.
No glow effects.
No phone, no camera, no hands, no extra objects.
No readable text, letters or numbers.

Minimal, calm, premium, high-contrast, optimized for small icon readability.

This is final production App Store icon artwork.
```

### Concept 4 — The Leaf in the Viewfinder

```
Create a full-bleed 1024×1024 square App Store icon.

Background: a continuous deep midnight indigo-black (#0B0B16 at the edges, rising to a deep indigo #1C1A33 glow behind the subject), filling the entire canvas edge-to-edge. No inner panel, no inset, no framing, no borders, no container shapes. One seamless background surface. Dark, but not a flat pure-black void.

Main subject: a single large fresh cilantro (coriander) leaf, centered, held inside four camera-scan corner brackets, as a phone camera frames what it is reading.

• The four brackets mark the corners of a square that fills about 85% of the canvas: thick, rounded L-shaped strokes with rounded ends, softly lit, with a hint of depth. No full frame, only the four corners. They are a lighter, fresher green (#6FCB8F) than the leaf, so the two stay apart.
• The leaf fills about 60% of the canvas, upright, its short stalk at the bottom. It is unmistakably cilantro: flat, broad and fan-shaped, with three soft rounded lobes and gently scalloped edges. Not pointed, not serrated like a saw, never palmate with long finger-like points.
• The leaf is forest green (#4DB373), deeper (#2A7A4B) toward its base and on its shaded side, with fine pale veins (#A6E0B8) fanning from the stalk into each lobe. Matte and fresh, slightly stylized, not photorealistic and not cartoony.

Lighting: soft cinematic light from the top left, as on a premium die on a night table. Gentle highlights on the leaf's upper-left edges and the brackets; soft shade on the lower right. A soft shadow beneath the leaf that blends seamlessly into the background. Extremely subtle vignette.

No texture.
No grain.
No glow effects.
No phone, no camera, no hands, no extra objects.
No text.

Minimal, calm, premium, high-contrast, optimized for small icon readability.

This is final production App Store icon artwork.
```

### Field follow-ups

Sent in the same ChatGPT chat as a generation Pops likes, with that image in view. As SyJong and SyDice found, asking for one change to an image ChatGPT already has keeps the rest, where a fresh generation redraws the subject.

Dark Forest:

```
Keep this image exactly as it is: same subject, same shape, size and position, same colors, lighting and shadows. Change only the background: replace the dark indigo with a deep, dark forest green, about #113724 behind the subject, falling to about #08291D at the edges and corners, with the same soft glow and vignette as before. It must read clearly as green, but stay dark: no flat black, no texture, no grain, no pattern. Nothing else changes: no text, no extra objects, no new highlights or glow.
```

Kitchen ivory:

```
Keep this image exactly as it is: same subject, same shape, size and position, same colors and lighting. Change only the background: replace the dark indigo with a warm, light kitchen ivory, about #FBF6EA behind the subject, falling softly to about #E3D6BC at the edges and corners, with a gentle glow and an extremely subtle vignette. Keep a soft grounding shadow under the subject so it still sits on the surface. No texture, no grain, no pattern. Nothing else changes: no text, no extra objects.
```

### Negative requirements

For every prompt; already written into each.

- No text, letters, numbers or logos: no "S", no "Sylantro", no "Let's cook."
- **No Breaking Bad imagery:** no lab glassware, flasks or beakers, no blue crystals, no periodic-table tiles or element symbols, no hazmat suit or gas mask, no RV, no desert, and none of the show's green-and-yellow type
- **No cannabis-like leaf:** cilantro is broad, flat and rounded with soft lobes, never narrow, pointed, saw-toothed or palmate with long fingers. Reject any generation that could be read that way
- No chef's hat, fork and knife, pot, pan, flame or plate: the generic food-app marks
- No phone, camera, hands or second object (Concept 2's sprig is the one allowed pair)
- No rounded-square icon frame, no border, no App Store mockup, no transparency
- No wood table, cutting board, marble or tablecloth texture: the table is implied only

---

## Variations to ask for

As SyJong's, in the same chat as the chosen concept:

1. **Primary**: as the prompt.
2. **Larger**: the subject filling about 95% of the canvas height, as SyFive's die nearly touches its edges.
3. **Simpler**: fewer leaflets, bolder shapes, for 29 px.
4. **Contrast test**: the primary on a field one step lighter.

---

## Appearances (AI-5)

The asset catalog has the three iOS slots (any, dark and tinted) and ten Mac sizes from the template (`AppIcon.appiconset`, read 21 Nov 2026), all empty. *(rec.)*, as SyJong's (JONG-173):

| Slot | What goes in it |
|---|---|
| Any (light) | `SylantroAppIcon.png` |
| Dark | The same file, if the field is midnight or dark Forest (dark-native, as the family). If Pops chooses kitchen ivory, a dark version is made, from the field follow-up back to midnight |
| Tinted | `SylantroAppIconTinted.png`: a grayscale version of the master, made by Claude, opaque. iOS applies the person's tint to it |
| Mac sizes | Expected to stay empty: Sylantro runs on the Mac as "Designed for iPad" (SLT-012). If they raise a warning in Xcode, removing them is a project change, for the Xcode agent |

**About's full-size icon:** SyJong ships the icon a second time in `Assets.xcassets/AppIconFull.imageset`, which SyLib's `Bundle.icon` loads first, so About's icon is sharp (JONG-281). Sylantro's About comes from Score It \*'s shell (SLT-086); adding `AppIconFull` is a task for the Xcode agent when the icon is placed (SLT-003). When the icon changes, both are replaced.

**Icon Composer is not used, for now**, for the family's reasons: its tinted icons are reported to render poorly on older iOS (unverified), and it needs the icon rebuilt as layers.

---

## Process

1. **Claude draws the draft** of the chosen concept in code, from this palette, with its checks sheet: at 300, 60 and 29 px with Apple's corner rounding, in grayscale, and beside the family's icons. The concept sketches are the start.
2. **Pops generates in ChatGPT**: THE PROMPT (the chosen concept prompt, updated with Pops's changes), the draft attached with the reference line. Ask for the variations.
3. **Claude checks** the chosen image: format (convert to an 8-bit RGB PNG, 1024 × 1024, non-interlaced, no alpha, sRGB embedded, no EXIF, no other change); colors sampled against §The palette; the leaf reads as cilantro and nothing else; no text or stray marks; extent, with nothing outside Apple's corner rounding (a 229 px radius at 1024); renders at 29 and 60 px beside SyFive's, SyDice's and SyJong's icons; the grayscale pass. Then makes the tinted variant.
4. **The files go in the asset catalog**, Claude asking first, and Pops checks them on device.

Changes to a chosen image are asked of ChatGPT (a follow-up in the same chat, or a fresh generation from an example), not recolored in code: SyJong's recolor in code left blotches (JONG-174).

---

## If regenerating

- **No flat pure-black background.** It swallows the mark at small sizes (Syderal).
- **No rounded-square frame.** Apple applies the corner radius; a baked-in one double-rounds.
- **The leaf is cilantro.** Broad, flat, rounded lobes. Reject anything parsley-curly, basil-smooth, or pointed and fingered like cannabis.
- **One subject.** Image models like to add a bowl, a knife or a second sprig.
- **Nothing from Breaking Bad**, however faint: no glassware, crystals, element tiles or the show's type.

Any regenerated icon takes the same 29 px check, beside the family's, before it ships.

---

## Rulings

AI-1, AI-3 and AI-6 ruled by Pops; the rest *(rec.)*. **Locked by Pops, 21 Nov 2026, and filed in the ledger** (`00` §App icon).

| # | Question | Ruling | Ledger row |
|---|---|---|---|
| AI-1 | The concept | **The Sprig: one cilantro sprig, the family's one-object formula** — Pops, 21 Nov 2026: "the sprig on dark forest looks best to me" | SLT-110, with AI-4 |
| AI-2 | The leaf | **Flat-leaf cilantro leaflets: broad, soft rounded lobes, pale veins; never pointed or fingered** *(rec.)*; the render as chosen | SLT-111 |
| AI-3 | The field | **Dark Forest, after SyJong's; the leaves in Forest, clearly brighter than it.** Asked as `#113724` / `#08291D`; delivered darker, about `#032B1E` around the sprig and `#002219` at the corners, accepted as rendered — Pops, 21 Nov 2026: "use a similar bg color as we did for syjong"; "looks great" | SLT-112 |
| AI-4 | The geometry | **One sprig, upright and centered, about 85% of the canvas tall, lit from the top left, nothing outside the corner rounding** *(rec.)* | SLT-110 |
| AI-5 | Appearances | **One PNG for the any and dark slots; a grayscale tinted variant made by Claude; Mac slots left empty; Icon Composer not used for now** *(rec.)* | SLT-113 |
| AI-6 | The maker | **ChatGPT's image generation, with Claude's code-drawn draft attached; changes asked of ChatGPT, not made in code** — Pops, 21 Nov 2026: "we use chatgpt for it" | SLT-114 |
| — | About's icon | **A second copy of the icon in `Assets.xcassets/AppIconFull.imageset`, so About draws it sharp, replaced with it whenever the icon changes;** added by the Xcode agent in `00B` Task A-4 (SLT-003), as JONG-281 | SLT-115 |

---

## Decision log

| Version | Decision | Rationale |
|---|---|---|
| 0.4 | Delivered: locked; SLT-110 to SLT-115 filed; the master and tinted variant placed in `AppIcon.appiconset` by Claude; `AppIconFull` written as `00B` Task A-4 for the Xcode agent | Pops, 21 Nov 2026 (decision card, "Lock; Claude places the PNGs") |
| 0.3 | Generated: Pops's ChatGPT render chosen ("looks great"); the raw archived, scaled from 1254 to 1024 with sRGB embedded, the tinted variant made; checked in `Sylantro_AppIcon_checks.png` (field darker than asked, clear contrast, nothing outside the rounding, reads at 60 and 29 px); the rulings proposed as SLT-110 to SLT-115 | Pops, 21 Nov 2026: "looks great" |
| 0.2 | The Sprig on dark Forest chosen (AI-1, AI-3), the field SyJong's delivered `#113724` / `#08291D`; THE PROMPT written from Concept 1's, asking for leaves brighter than the field; the draft named `SylantroIconDraft.png`; two follow-ups and the checks added | Pops, 21 Nov 2026: "the sprig on dark forest looks best to me. use a similar bg color as we did for syjong." |
| 0.1 | First version, from SyJong's `11_APP_ICON.md`: four concepts drawn in code and compared at 300, 60 and 29 px (`AppIcon/Sylantro_Concepts_Compare.png`), a paste-ready ChatGPT prompt for each, three fields compared, the palette from Forest, the family's appearances and process; AI-1 to AI-6 proposed, SLT-110 to SLT-115 reserved. Images in `Docs/AppIcon/`, as SyJong's are | Pops, 21 Nov 2026: "I want to design the app icon next, look at the syjong-ios APP_ICON doc. its our best one yet. we use chatgpt for it." |
