---
name: paper-illustration
description: Build a ready-to-paste image-generation prompt that reinterprets a photo as a minimal hand-drawn paper-cover illustration — small centred subject, imperfect lines, at most 4 flat acrylic colours pulled from the photo, rough paper, large negative space, 3:4 canvas. Trigger when the user attaches or describes a photo and asks for a minimal sketch, a hand-drawn paper illustration, a picture-book or art-book cover version, a flat-colour simplification, or "just the illustration half" of the editorial poster. Outputs one prompt per photo, under 2000 characters. Not for posters that keep the original photograph in the frame — use editorial-poster for that.
metadata:
  author: wudi
  version: "2026.09.21"
  source: https://github.com/WuChenDi/skills
---

# paper-illustration

Produces the prompt, not the image. The deliverable is a text prompt the user pastes into an image model together with the photo as a reference image. One photo in, one prompt out; several photos in, several separate prompts out — never merge photos into one illustration.

This is the illustration half of `editorial-poster` lifted onto its own canvas. The default canvas is a full 3:4 portrait, treated as the cover of a small independent art book; the subject stays small (10–20% of the canvas) so the empty paper does the work. The template fits a 2000-character input box (verified with GPT Image 2.5 Pro) with about 300 characters spare.

## Step 1 — Collect input

- **Photo(s)** — attached to the message, or described in words if the user cannot attach.
- **Text to include** (optional) — a title, place, year, or short phrase. If nothing is given, use `none`.
- **Aspect ratio** (optional) — default 3:4 portrait. Only change it if the user asks (3:2 landscape reproduces the poster's bottom half exactly).

Do not ask for anything else.

## Step 2 — Emit the prompt

Output the template below verbatim, replacing only `<text or none>` (and the aspect ratio in the first line under `FORMAT`, when asked). Put each prompt in its own fenced code block. For multiple photos, label the blocks `Photo 1`, `Photo 2`, … in the order received.

````
```text
Create one minimal hand-drawn paper illustration from the attached photograph. Use this photo alone; no collage. The output contains no photographic element: the whole canvas is illustration on paper.

FORMAT
Strict 3:4 vertical canvas, composed like the cover of a small independent art book. No frame, no border, no split; the paper runs edge to edge.

SUBJECT
Reinterpret the photo's most recognisable elements as a minimalist hand-drawn paper-cover illustration. Keep only the main subject, its silhouette, key gesture, and important objects; drop every other detail.
The subject is small and centred, about 10–20% of the canvas, with generous negative space around it.

TECHNIQUE
Delicate, slightly imperfect hand-drawn lines; a few bold acrylic-style flat colour shapes; rough paper texture; visible brush marks; irregular organic edges; handmade imperfections.
The background is rough white or warm off-white paper like book-cover stock. Suggest the environment with only a few lines or small colour shapes.

COLOUR PALETTE
Compress the photo's dominant colours to at most 4: restrained, harmonious, bold but controlled flat blocks with subtle paper grain, reading as a simplified colour interpretation of the photo.

TYPOGRAPHY
Text to include: <text or none>
Render exactly this text and nothing else; never add a year, date, place, or any other words. If none, the image has no text. Set it small, understated and editorial, in the negative space.

VISUAL LANGUAGE
Quiet · Poetic · Refined · Minimal · Innocent · Artistic · Premium.
"A small subject surrounded by a large amount of empty space." An independent art-publication cover, not an advertisement.
```
````

After the code block(s), add at most two lines: the prompt expects the photo attached as a reference image, and if text was given, check its spelling in the generated image. Nothing else.

## Step 3 — Refine on request

- **Different text** — change only the `Text to include` line.
- **Different photo, same series** — reuse the same text style so the covers read as a set.
- **Add the original photo above it** — hand off to `editorial-poster`.
- **The model ignored a rule** — move that rule to the top of the block and restate it in one imperative sentence. Stay under 2000 characters; do not add prose.
- **The model added extra words to the text** — the `Render exactly this text` sentence already forbids it; if it still happens, put the text in quotes on the `Text to include` line.

## Anti-patterns

- Rewriting the template freely per photo. The template is the contract; only the text line (and the aspect-ratio line, when asked) varies.
- Describing the photo inside the prompt. The model sees the reference image; a description only competes with it.
- Letting the subject grow to fill the canvas. Small subject, large paper — that is the whole look.
- Merging several photos into one prompt.
