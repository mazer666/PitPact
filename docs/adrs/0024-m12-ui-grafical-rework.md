# ADR-0024 — M12: UI Grafical Rework

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M12 (UI Grafical Rework)
- Supersedes: none (extends ADR-0016, ADR-0023)
- Related: ADR-0023 (M11), ADR-0016 (M5-Real-UI-Assets), docs/style-bible.md

## Context

M11-Art-Rework (ADR-0023)
lieferte 18 AI-generierte
Assets (Inhabitants, Tiles,
UI-Icons, Crises) im
Gothic-Watercolor-Hybrid-Stil.
M12 ist das **UI-Grafical-
Rework** — die .tscn-Scenes
werden komplett auf die neuen
AI-Assets umgestellt und mit
Hover-States, Animated-
Transitions, und Layout-
Polish versehen.

Per user request:
> "auch die ui muss vollständig
> grafisch ausgearbeitet sein"

Aktueller Stand (M5/M11): die
`PlayableShell.tscn` nutzt die
alten prozeduralen Icons
(`step.png`, `pause.png`) und
ein einfaches Theme. Die
TopBar, InhabitantPanel,
PactmakerPanel, CrisisBanner,
GameOverBanner sind visuell
basic.

Diese ADR pinnt den M12-Scope
*testbar* in **3 Buckets**
(Scene-Rework, Hover-States,
Layout-Responsive). Jeder
Bucket hat testbare Kriterien
(wie M0-M11).

## Decision

M12 wird in **3 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (I)**:

### Bucket 1 — Scene Rework

**Goal**: Die `PlayableShell.tscn`
nutzt die neuen AI-Assets
(aus M11) und ist visuell
konsistent mit dem
Gothic-Watercolor-Stil.

**Definition-of-Done**:
- **`scenes/main/PlayableShell.tscn`**:
  - StepButton nutzt
    `res://assets/ai/ui/step.png`
  - AutoTickToggle nutzt
    `res://assets/ai/ui/auto_tick.png`
  - RestartButton nutzt
    `res://assets/ai/ui/restart.png`
  - PowerButtons nutzen
    `res://assets/ai/ui/power.png`
  - CrisisBanner nutzt die
    Crisis-AI-Icons
  - InhabitantPanel nutzt die
    13 AI-Inhabitants
  - TileSet nutzt die 6 AI-
    Tiles
- **`scenes/ui/CrisisBanner.tscn`**:
  neue Scene mit Crisis-Icon
- **`scenes/ui/GameOverBanner.tscn`**:
  neue Scene mit GameOver-
  Styling
- **Tests**: 4+ tests (alle
  Texture-Pfade korrekt).

### Bucket 2 — Hover States

**Goal**: Buttons haben
Hover/Pressed/Disabled
States mit animated
transitions.

**Definition-of-Done**:
- **`gothic_fantasy_theme_v2.tres`**:
  - 4 StyleBoxes pro Button
    (normal, hover, pressed,
    disabled)
  - Hover: subtle glow
    (Color + brightness shift)
  - Pressed: darker, slight
    scale
  - Disabled: gray-out
- **Animated-Transition**:
  - `tween_property()` für
    smooth color tween
    (0.15s)
  - 60 FPS perf budget
    (per ADR-0023)
- **Tests**: 4+ tests (theme
  has 4 states, transitions
  tween correctly, perf
  budget met).

### Bucket 3 — Layout Responsive

**Goal**: Die UI reagiert auf
portrait/landscape orientation
+ window resize (matches M8
Bucket 2 but applies the
M11/M12 art to the responsive
layout).

**Definition-of-Done**:
- **Portrait-Mode**:
  - TopBar fixed top
  - InhabitantPanel + PactmakerPanel
    stacked vertically
  - BottomBar fixed bottom
- **Landscape-Mode**:
  - TopBar fixed top
  - InhabitantPanel left,
    PactmakerPanel right
  - BottomBar fixed bottom
- **Tests**: 6+ tests
  (portrait layout, landscape
  layout, resize handling).

### Side-Quest I — Animated Title

**Goal**: Ein animiertes
Title-Screen mit Logo
+ Fade-in.

**Definition-of-Done**:
- **`scenes/main/TitleScreen.tscn`**:
  - PitPact-Logo
    (AI-generiert)
  - Fade-in animation
  - "Start" button
- **Tests**: 3+ tests (scene
  exists, logo is AI-gen,
  fade-in is 60 FPS).

## Out of scope (M12)

- **Animationen auf allen
  Sprites** — out of scope
  (M13+; skeletal animation).
- **UI-Sounds** — out of scope
  (M5-Closeout Bucket 6 audio
  is sufficient).
- **Multi-Language-UI** — out
  of scope (M5-Closeout
  Bucket 5 i18n is sufficient).
- **Custom-Font-Rendering** —
  out of scope (theme uses
  Godot defaults).

## Consequences

### Positive

- M12 transforms PitPact's
  UI from "code-driven skeleton"
  to "polished, animated
  Gothic-Watercolor UI".
- The UI now matches the
  AI-generated art (visual
  consistency).
- Hover/Pressed/Disabled
  states give clear feedback.

### Negative / Tradeoffs

- Scene-Rework is a big
  commit (lots of .tscn
  changes).
- Animated transitions
  must respect the perf
  budget (60 FPS, per
  ADR-0023).
- The M12 closeout is
  visual-heavy; the test
  net is structural (paths
  + sizes) rather than
  pixel-perfect.

## Validation (per Bucket)

- **Quality gate**:
  `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 392 + 17-23
  neue Tests = 410+ Tests,
  1900+ Asserts
- **Mutation sweep**: M12
  mutations (5+ je Bucket)
- **Performance budget**:
  60 FPS maintained

## Prio-Order

1. **Bucket 1 (Scene Rework)** —
   high leverage (the core
   visual change).
2. **Bucket 2 (Hover States)** —
   high impact (polish).
3. **Bucket 3 (Layout)** —
   medium impact (responsive).
4. **Side-Quest I (Title)** —
   presentation.

## References

- ADR-0023 — M11-Art-Rework
- ADR-0016 — M5-Real-UI-Assets
- ADR-0020 — M8-iPadOS-and-Mobile
- Godot Theme:
  https://docs.godotengine.org/en/stable/tutorials/themes/index.html
- Godot Tween:
  https://docs.godotengine.org/en/stable/classes/class_tween.html
