---
name: editorial-poster
description: Build a ready-to-paste image-generation prompt that turns a photo into a 3:4 editorial poster split into two equal halves — the original photograph preserved on top, a minimal hand-drawn paper illustration of the same subject below. Trigger when the user attaches or describes a photo and asks for the top-photo / bottom-illustration poster, the photo + sketch art-book cover, the split editorial poster, or simply "the poster prompt" for one or more photos. Outputs one prompt per photo, under 2000 characters. Not for illustration-only output with no photograph in the frame — use paper-illustration for that.
metadata:
  author: wudi
  version: "2026.09.21"
  source: https://github.com/WuChenDi/skills
---

# editorial-poster

Produces the prompt, not the image. The deliverable is a text prompt the user pastes into an image model together with the photo as a reference image. One photo in, one prompt out; several photos in, several separate prompts out — the format forbids collages, so never merge photos into one prompt.

The template is tuned to fit a 2000-character input box (verified with GPT Image 2.5 Pro). It stays under that limit with roughly 70 characters spare for the user's text.

## Step 1 — Collect input

- **Photo(s)** — attached to the message, or described in words if the user cannot attach.
- **Text to include** (optional) — a title, place, year, or short phrase the user wants on the poster. If nothing is given, use `none`.

Do not ask for anything else. Aspect ratio, split ratio, and style are fixed by the template; only change them if the user explicitly overrides.

## Step 2 — Emit the prompt

Output the template below verbatim, replacing only `<text or none>`. Put each prompt in its own fenced code block. For multiple photos, label the blocks `Photo 1`, `Photo 2`, … in the order received.

````
```text
Create one high-end editorial poster from the attached photograph. Use this photo alone; no collage.

FORMAT
Strict 3:4 vertical canvas, split into two exactly equal halves (top 50%, bottom 50%), reading together as one refined art-publication cover.

TOP HALF — ORIGINAL PHOTOGRAPH
Reproduce the photo faithfully: composition, subjects, identity, faces, proportions, poses, clothing, objects, and spatial relationships stay unchanged. Keep the photographic texture, natural light, and colour mood. Apply only subtle editorial colour grading; stay photorealistic, never over-retouched. If the frame must be extended, extend the background seamlessly; never stretch, distort, or alter the subject.

BOTTOM HALF — MINIMAL HAND-DRAWN PAPER ILLUSTRATION
Reinterpret the photo's most recognisable elements as a minimalist hand-drawn paper-cover illustration. Keep only the main subject, its silhouette, key gesture, and important objects; drop every other detail.
Technique: delicate, slightly imperfect hand-drawn lines; a few bold acrylic-style flat colour shapes; rough paper texture; visible brush marks; irregular organic edges.
The subject is small and centred, about 10–20% of the bottom half, with generous negative space on rough white or warm off-white paper. Suggest the environment with only a few lines or small colour shapes.

COLOUR PALETTE
Compress the photo's dominant colours to at most 4: restrained, harmonious flat blocks with subtle paper grain, a simplified colour interpretation of the photo.

TYPOGRAPHY
Text to include: <text or none>
Render exactly this text and nothing else; never add a year, date, place, or any other words. If none, the image has no text. Set it small, understated and editorial, in the negative space.

VISUAL LANGUAGE
Quiet · Poetic · Refined · Minimal · Innocent · Premium.
"A small subject surrounded by a large amount of empty space." An art-publication cover, not an advertisement.
```
````

After the code block(s), add at most two lines: the prompt expects the photo attached as a reference image, and if text was given, check its spelling in the generated image. Nothing else.

## Step 3 — Refine on request

- **Different text** — change only the `Text to include` line.
- **Different photo, same series** — reuse the same text style so the posters read as a set.
- **Illustration only, no photo half** — hand off to `paper-illustration`.
- **The model ignored a rule** — move that rule to the top of the block and restate it in one imperative sentence. Cut elsewhere to stay under 2000 characters; do not add prose.
- **The model added extra words to the text** — the `Render exactly this text` sentence already forbids it; if it still happens, put the text in quotes on the `Text to include` line.

## Anti-patterns

- Rewriting the template freely per photo. The template is the contract; only the text line varies.
- Describing the photo inside the prompt. The model sees the reference image; a description only competes with it.
- Exceeding 2000 characters. Many image UIs truncate silently and the last section (visual language) is lost first.
- Merging several photos into one prompt.
