# ADR-0023 — M11: Art Rework (Gothic-Watercolor Hybrid)

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M11 (Art Rework)
- Supersedes: none (extends ADR-0016)
- Related: ADR-0016 (M5-Real-UI-Assets), ADR-0018 (M6), docs/style-bible.md

## Context

M10-Co-op-Live-Mode (ADR-0022)
lieferte die Co-op-Live-Mode.
M11 ist das **Art-Rework** —
ein Mix aus **Gothic Dark
Fantasy** und **Storybook
Watercolor** für alle In-Game
Visuals.

Per user request:
> "a - mix aud gothic dark
> fantasy und storybook
> watercolor
> b h
> c i und ii -> könntest Du
> nicht auch selbst generieren
> d a"

Aktueller Stand (M5-Real-UI-
Assets): 32 prozedural-generierte
PNGs mit einfachen Formen +
flachen Farben. Funktional,
aber ohne künstlerische Tiefe.

Diese ADR pinnt den M11-Scope
*testbar* in **3 Buckets**
(AI-Art-Generation, Prozedural-
Upgrade, Shader-Pipeline).
Jeder Bucket hat testbare
Kriterien (wie M0-M10).

## Decision

M11 wird in **3 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (H)**:

### Visual Style Brief

The M11 closeout establishes
the canonical PitPact visual
style as a **hybrid of Gothic
Dark Fantasy and Storybook
Watercolor**:

- **Gothic Dark Fantasy** —
  the moody, atmospheric base
  (dark palette, dramatic
  lighting, ornate details)
- **Storybook Watercolor** —
  the soft, painterly overlay
  (gentle brushwork, soft
  edges, hand-drawn feel)

**Palette** (per ADR-0016 +
extension):
- Background: Deep Indigo
  `#1a1a2e`, Charcoal
  `#2d2d3a`
- Mid: Dusty Rose `#a86b6b`,
  Tarnished Gold `#b8924a`
- Accent: Pale Gold `#d4af37`,
  Bone White `#e8e3d8`
- Highlight: Soft Cream
  `#f4ebd0`

**Reference**:
- Darkest Dungeon (Gothic
  base)
- Hades (Watercolor overlay)
- Slay the Spire (UI style)

### Bucket 1 — AI-Art Generation

**Goal**: AI-generierte Art für
Inhabitants (13) + Tiles (15) +
UI-Icons (5-10) + Crises (2).

**Definition-of-Done**:
- **AI-Generation-Pipeline**
  (`tools/assets/generate_ai_art.sh`):
  - Calls `mavis` `image_synthesize`
    with the canonical style prompt
  - Saves to `assets/ai/` (NEW
    directory, CC0 by default
    per M6 licensing)
  - Re-generates deterministically
    via seed (per ADR-0005)
- **Style-Prompt-Template**:
  shared prompt template at
  `tools/assets/ai_style_prompt.txt`
  with: "Gothic Dark Fantasy
  + Storybook Watercolor,
  dark moody background,
  ornate details, soft
  brushwork, 2D game art,
  PitPact style, [subject]"
- **Asset-List**:
  `tools/assets/ai_asset_manifest.json`
  lists all 35-40 assets with
  prompts, seeds, output paths
- **Tests**: 4+ tests (manifest
  exists, all files generated,
  CC0 license headers).

### Bucket 2 — Prozedural Upgrade

**Goal**: Verbessere die
prozedural-generierten Tiles
+ Inhabitants ohne API-Calls
(textures, variations).

**Definition-of-Done**:
- **Tile-Texturen**: Perlin-Noise-
  basierte Variationen für
  `hearth`, `shrine`, `forge`,
  `well`, `trap`, `altar`,
  `vault`, `garden`, `library`
  etc. (15+ tiles).
- **Inhabitant-Variations**:
  Hue-Shift + Accessory-Layer
  für die 13 portraits (Brust-
  panzer, Hüte, Halsketten).
- **Tile-Connection**: Tiles
  matchen aneinander (Wand an
  Wand, Ecke-Inferenz).
- **Tests**: 6+ tests (textures
  have noise, hue-shifts are
  consistent, tile-connection
  is correct).

### Bucket 3 — Shader Pipeline

**Goal**: Godot-Shader für
Post-Processing (Bloom,
Vignette, Color-Grade).

**Definition-of-Done**:
- **`shaders/post_process.gdshader`**:
  - Bloom (subtle glow on
    highlights)
  - Vignette (darker corners)
  - Color-Grade (warm shadows,
    cool highlights)
  - Day/Night-Mix-Parameter
- **Day/Night-Cycle**:
  - `TimeOfDay` carrier
    (`src/world/time_of_day.gd`)
  - Cycles through 4 phases
    (dawn, noon, dusk, night)
  - Drives the shader's
    color-grade parameter
- **Tests**: 4+ tests (shader
  compiles, time-of-day
  progresses, parameters
  are correct).

### Side-Quest H — Performance Budget

**Goal**: 60 FPS auf einem
4-year-old laptop (per user
request).

**Definition-of-Done**:
- **Performance-Benchmark v2**
  (`tools/benchmarks/run_perf_v2.gd`):
  - Renders 100 frames with
    the post-processing
    shader active
  - Reports avg frame time
    + 1% low + 0.1% low
- **Budget-Target**:
  - Avg: < 16.67ms (60 FPS)
  - 1% low: < 20ms
  - 0.1% low: < 30ms
- **Tests**: 3+ tests
  (benchmark runs, metrics
  recorded, budget enforced).

## Out of scope (M11)

- **3D-Modelle** — out of scope
  (PitPact is 2D).
- **Live-Animationen** (komplexe
  Skeletal-Animation) — out of
  scope (M12+).
- **Hand-drawn Frame-by-Frame**
  — out of scope (M13+; would
  require a dedicated artist).
- **Voice-Acting** — out of
  scope (PitPact is text-driven;
  M12+).
- **Cutscenes** — out of scope
  (M12+).

## Consequences

### Positive

- M11 transforms PitPact from
  "functional placeholder art"
  to "Gothic-Watercolor hybrid
  that matches the design doc".
- AI-generation gives us
  35-40 unique pieces in <1h
  (vs weeks of manual work).
- Prozedural-upgrade keeps
  the art deterministic
  (per ADR-0005) and
  reproducible.
- Shader pipeline unifies
  the visual style (every
  asset gets the same
  color-grade + bloom).

### Negative / Tradeoffs

- AI-art is not pixel-perfect
  (variation between
  generations); the M11
  closeout uses fixed seeds
  for determinism but
  different seeds may give
  better results.
- Performance budget (60 FPS
  on 4-year-old laptop) is
  tight; the shader is
  simplified if needed.
- Style-mix (Gothic +
  Watercolor) is unusual;
  may not be everyone's cup
  of tea. The M11.1 closeout
  can adjust if user feedback
  is negative.

## Validation (per Bucket)

- **Quality gate**: `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 367 + 17-23
  neue Tests = 385+ Tests,
  1850+ Asserts
- **Mutation sweep**: M11
  mutations (5+ je Bucket)
- **Performance budget**:
  benchmark within target

## Prio-Order

1. **Bucket 1 (AI-Art)** —
   high leverage (biggest
   visual impact).
2. **Bucket 3 (Shader)** —
   high impact (unifies
   style).
3. **Bucket 2 (Prozedural)** —
   medium impact (variations).
4. **Side-Quest H (Perf)** —
   validation.

## References

- ADR-0022 — M10-Co-op-Live-Mode
- ADR-0016 — M5-Real-UI-Assets
- ADR-0018 — M6-Release-Readiness
- docs/style-bible.md (PitPact
  visual identity)
- Darkest Dungeon art:
  https://www.darkestdungeon.com/
- Hades art:
  https://www.supergiantgames.com/games/hades/
- Slay the Spire art:
  https://www.megacrit.com/
- Godot Shaders:
  https://docs.godotengine.org/en/stable/tutorials/shading/shading_reference.html
