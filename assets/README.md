# `assets/` — Original Art, Audio, and Fonts

> This directory holds the project's original art, audio, fonts,
> and shader files. Original assets are licensed under CC BY-SA
> 4.0; the project's source code is licensed under GPL-3.0-or-later
> (see [`LICENSE`](../LICENSE) for the split). Third-party assets
> are recorded in [`licenses/THIRD-PARTY.md`](../licenses/THIRD-PARTY.md)
> with their provenance, license, and attribution.

## Layout

```
assets/
  art/         # sprites, tilesets, UI art, character portraits
  audio/       # music, sound effects, ambient loops
  fonts/       # UI fonts and bitmap fonts
  shaders/     # GLSL shaders and Godot shader resources
```

Each subdirectory's README documents the specific conventions
that apply to its content type. M0 ships these directories as
placeholders; the M1 art pass and the M3 audio pass populate
them.

## The asset manifest

The authoritative inventory of every asset in this directory
lives in [`licenses/THIRD-PARTY.md`](../licenses/THIRD-PARTY.md).
Every asset is listed there with:

- the path within the repository,
- the author or rights holder,
- the source URL or upstream identifier (for derivatives),
- the license (SPDX identifier),
- the modifications made (if any),
- the AI generation disclosure (if any), per §20.2 of
  [`docs/requirements.md`](../docs/requirements.md).

When the project grows to ship a large number of original
assets (planned for M3+), the M0 third-party table at
`licenses/THIRD-PARTY.md` is split into a dedicated
`assets/MANIFEST.md` for the project's own works, with
`licenses/THIRD-PARTY.md` keeping the third-party entries. The
move is a documentation-only change.

`licenses/THIRD-PARTY.md` is updated **in the same commit** that
adds an asset. A PR that introduces a new file under `assets/`
without updating the inventory fails review.

## Original work

The long-term target is original assets across the board
(§20.2 of the requirements spec). Until then, M0-M5 work
proceeds with three categories of asset:

1. **Original assets** — created for the project, licensed
   CC BY-SA 4.0, listed in `MANIFEST.md` with the author.
2. **Free placeholders** — public-domain or compatible-license
   work used temporarily. The MANIFEST entry records the
   upstream URL and the license. The placeholder is replaced
   before the M6 public release.
3. **AI-generated assets** — permitted under §20.2 if the
   generation method, tool/source, prompt intent, and human
   modifications are recorded in `MANIFEST.md`. AI-generated
   assets must still pass the originality and style review
   documented in [`docs/ip-license-checklist.md`](../docs/ip-license-checklist.md).

## What goes where

### `art/`

- **Sprites** — `assets/art/sprites/`. PNG or SVG; SVG preferred
  for scalable UI. Atlas generation lives in
  `src/content/atlases.gd` (planned for M1).
- **Tilesets** — `assets/art/tilesets/`. PNG tilesets aligned
  to the isometric grid documented in
  [`docs/adrs/0004-spatial-model.md`](../docs/adrs/0004-spatial-model.md).
  Tile size in pixels: 64×32 (diamond).
- **UI art** — `assets/art/ui/`. PNG or SVG, exported at the
  intended scale (1×, 2×, 3× variants where appropriate).
- **Character portraits** — `assets/art/portraits/`. PNG,
  512×512 base resolution, transparent background.

### `audio/`

- **Music** — `assets/audio/music/`. OGG or Opus, 96 kbps or
  higher. One file per track, named by track id
  (`act_theme_hollow.ogg`).
- **Sound effects** — `assets/audio/sfx/`. OGG, mono, 44.1 kHz.
  Named by SFX id (`sfx_hearth_paint.ogg`,
  `sfx_hearth_complete.ogg`).
- **Ambient loops** — `assets/audio/ambient/`. OGG, seamless
  loop, 30-60 seconds.

### `fonts/`

- UI fonts in OTF or TTF. The default UI font is recorded in
  `assets/fonts/README.md` (planned). Bitmap fonts are
  permitted for in-world text (e.g. the
  "Pact & Pit" title) but require an entry in
  `assets/MANIFEST.md`.

### `shaders/`

- GLSL `.gdshader` files. Each shader has a doc comment that
  names the use case, the input uniforms, and the licensing
  status. Shaders are original work unless explicitly marked
  otherwise.

## Forbidden patterns

- **No copyrighted material in any form.** No song lyrics, no
  book excerpts, no recognisable limericks or memes embedded
  in shipped assets.
- **No recognisable designs from existing games.** Even a
  redrawn creature is forbidden if the silhouette or palette
  is recognisable as a protected work.
- **No AI-generated assets without disclosure.** The MANIFEST
  entry must record the tool, the prompt intent, the human
  modifications, and the applicable rights.
- **No assets without a MANIFEST entry.** A new file under
  `assets/` without a MANIFEST update fails review.

## See also

- [`assets/MANIFEST.md`](MANIFEST.md) — the authoritative
  inventory.
- [`licenses/THIRD-PARTY.md`](../licenses/THIRD-PARTY.md) —
  third-party license records.
- [`docs/ip-license-checklist.md`](../docs/ip-license-checklist.md) —
  the pre-release review checklist.
- [`docs/style-bible.md`](../docs/style-bible.md) — tone, palette,
  and silhouette rules that apply to art and audio.
- [`LICENSE`](../LICENSE) — the split license notice.
