---
name: ikui
description: Manages ikui components and blocks — searching, adding, composing, and debugging UI from the ikui registry (@ikui). ikui ships copy-paste React primitives for media/timeline editing (audio waveform + player, video thumbnail strips, a zoom-aware timeline of ruler / element / playhead, image compare / crop, particle image, copy button) AND ready-made business blocks composed from them — audio trimmer, video trimmer, image cropper — that deliver a finished feature end to end. Triggers when adding or fixing any of these, when the project's components.json contains an "@ikui" registry, or for requests like "add an ikui waveform", "build a video trimmer", "drop in an audio trimmer block", "image before/after slider", "crop an image", or "add @ikui/<name>".
allowed-tools: Bash(npx shadcn@latest add *), Bash(npx shadcn@latest init *), Bash(pnpm dlx shadcn@latest add *), Bash(pnpm dlx shadcn@latest init *), Bash(bunx --bun shadcn@latest add *), Bash(bunx --bun shadcn@latest init *), Bash(curl -s https://ik-ui.pages.dev/*)
metadata:
  author: wudi
  version: "2026.08.09"
  source: https://github.com/WuChenDi/skills
---

# ikui

A copy-paste React component library distributed as a **shadcn-style registry**, not an npm package. Components are added as source code into the user's project. ikui has **no CLI of its own** — installation goes through the shadcn CLI pointed at the `@ikui` registry.

- Registry: `https://ik-ui.pages.dev/r/{name}.json`
- Docs: `https://ik-ui.pages.dev`
- Built on **Base UI** (`@base-ui/react`) — **never Radix** — with Tailwind CSS v4, `lucide-react`, and `motion`.

> **IMPORTANT:** Run all CLI commands with the project's package runner — `npx shadcn@latest`, `pnpm dlx shadcn@latest`, or `bunx --bun shadcn@latest`, based on the project's `packageManager`. Examples below use `npx`; substitute the correct runner.

## Two layers: primitives and blocks

ikui is organized in two tiers — **knowing which one the user needs is the single most important routing decision.**

- **Primitives** (`registry:component` / `registry:lib`) are small, single-purpose, intentionally "dumb" parts: a waveform, a thumbnail strip, a timeline ruler/element/playhead, a crop box. They own no business logic — the playback clock, seeking, and track wiring are left to the consumer. Reach for these when the user is **building their own** editor/feature.
- **Blocks** (`registry:block`) are **business compositions** — ikui's signature value. Each block stitches many primitives together into a working feature with all the wiring done: state, playback, readouts, export. Reach for a block when the user wants the **finished thing**, not the parts.

Current blocks (always confirm against the live registry — see "Current Components" below):

| Block | Composed from | Delivers |
| --- | --- | --- |
| `@ikui/audio-trimmer` | `timeline-ruler` + `timeline-element` + `timeline-playhead` + `audio-waveform` + shadcn `button`/`card`/`slider`/`scroll-area`/`skeleton` | Trim an audio clip and play back only the `[start, start+duration]` window, waveform coloring + In/Out/length readout. |
| `@ikui/video-trimmer` | the timeline primitives + `thumbnail-strip` + mediabunny | Trim a video over a thumbnail strip, preview the trimmed window, and **export the cut to MP4**. |
| `@ikui/image-cropper` | `image-crop` + shadcn `button`/`card` | Frame a crop with a live preview beside it and download the result at full resolution. |

Default: if the user names the outcome ("trim this video", "let users crop their avatar"), install the **block**. Only drop to primitives when they want to customize beyond what the block exposes, or are assembling a different feature.

## Current Components

Before advising or installing, fetch the live manifest — don't work from memory. Fetch `https://ik-ui.pages.dev/r/registry.json` and read its `items` array; each item's `name` is the `@ikui/<name>` install id, with `type`, `category`, and `description` alongside. **Never hardcode the component list** — it changes as ikui grows.

## Prerequisite: register `@ikui`

The shadcn CLI can only resolve `@ikui/<name>` if the registry is declared in the project's `components.json`. Before adding, check for:

```json
{
  "registries": {
    "@ikui": "https://ik-ui.pages.dev/r/{name}.json"
  }
}
```

If it's missing, add it (merge into the existing `registries` object; don't clobber other registries). Alternatively, install by full URL without editing config: `npx shadcn@latest add https://ik-ui.pages.dev/r/<name>.json`.

ikui requires a shadcn-initialized project (a `components.json`). If there is none, run `npx shadcn@latest init` first.

## Installing

```bash
# By registry id (requires @ikui in components.json).
npx shadcn@latest add @ikui/image-compare
npx shadcn@latest add @ikui/audio-waveform @ikui/waveform-player

# By full URL (no config needed).
npx shadcn@latest add https://ik-ui.pages.dev/r/image-crop.json

# Preview before writing.
npx shadcn@latest add @ikui/video-trimmer --dry-run
```

`registryDependencies` are resolved automatically: some items pull **plain shadcn** components (`button`, `card`, `slider`, `scroll-area`, `skeleton`) and some pull **other ikui** items (`@ikui/audio-waveform`, `@ikui/timeline-element`, …). Both install transitively — you don't add them by hand. `dependencies` (npm packages like `lucide-react`, `mediabunny`) install via the project's package manager automatically.

## Item types

- **`registry:component`** — a single UI primitive (e.g. `image-crop`, `timeline-ruler`).
- **`registry:lib`** — a non-UI helper (e.g. `video-thumbnail-cache`); pulled in as a dependency, rarely added directly.
- **`registry:block`** — a full business composition wired from primitives (e.g. `audio-trimmer`, `video-trimmer`, `image-cropper`). Reach for a block when the user wants the finished feature; reach for the primitives when they want to build their own.

## Composition map

ikui's value is the timeline/media stack. Know what builds on what:

- **Audio**: `audio-waveform` (canvas peaks) → `waveform-player` (play/seek wrapper).
- **Video**: `video-thumbnail-cache` (frame decode) → `thumbnail-strip` → `segmented-timeline-strip` (multi-clip overview).
- **Timeline primitives** (pure, share the `time × pixelsPerSecond × zoom` basis): `timeline-ruler` (the scale), `timeline-element` (a trimmable positioned clip), `timeline-playhead` (draggable seek line). The track, clock, and click-to-seek are left to the consumer.
- **Blocks** combine the above: `audio-trimmer` = timeline primitives + waveform; `video-trimmer` = timeline primitives + thumbnail-strip + mediabunny export; `image-cropper` = `image-crop` + live preview/download.
- **Image**: `image-compare` (before/after slider), `image-crop` (the crop primitive), `particle-image` (pointer-scatter effect).

For a real editor UI, compose the primitives (ruler + element + playhead over your own track) rather than forcing a block to fit.

## Conventions (match these when editing ikui code)

- **Base UI only.** If a primitive is needed, it comes from `@base-ui/react`. Do not introduce Radix or any other UI library.
- **RSC default.** The host is Next.js App Router with `rsc: true`. ikui components that use `useState`/`useEffect`/refs/canvas/pointer handlers already carry `"use client"`; keep it, and add it to any new client component.
- **Tailwind v4, semantic tokens.** CSS-first (`globals.css`, no `tailwind.config`). Use `cn()` from the project's `utils` alias for class merging; `className` is for layout, not for overriding component colors/typography.
- **Icons** are `lucide-react`. **Animations** are `motion`.
- **Import alias** comes from `components.json` `aliases` (e.g. `@/components/...`). After adding, verify the written files use the project's real alias — don't assume `@/`.

See [references/conventions.md](./references/conventions.md) for the fuller rule list and rationale.

## Workflow

1. **Confirm setup** — project has `components.json`; `@ikui` registry is declared (add it if not). Note the package runner.
2. **List, don't guess** — fetch `registry.json` (see "Current Components" above) to get current names, types, categories, and descriptions.
3. **Pick the right grain** — a `block` for a finished feature, `component` primitives to build something custom. Don't reimplement a primitive that already exists.
4. **Add** — `npx shadcn@latest add @ikui/<name>` (or full URL). Use `--dry-run` to preview.
5. **Review the written files** — confirm imports resolve to the project's aliases, `"use client"` is present where needed, and transitive deps landed. Read the component's source/props before wiring it up rather than guessing the API.
6. **Verify** — build / run the dev server and check the rendered component; ikui has no unit tests, so visual confirmation is the check.
