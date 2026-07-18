# PitPact — Release Notes v0.2.0-m6

> **PitPact — An Underworld of Terms and Terrors**
> is an original, open-source, offline-first Godot 4
> management and simulation game about building an
> underground realm through bargains, decrees, limited
> supernatural intervention, and indirect authority.

## Highlights

PitPact v0.2.0-m6 ships the **M5-Closeout** milestone
(per ADR-0017): the playable sim now features six
cultures, ten rooms, fifteen events, a complete
success/failure/restart loop, English/German
localization, and a procedural audio pass. The game
is **functionally complete** — 236/236 GUT tests pass
with 1566 Asserts, and `tools/run_quality.sh` reports
**ALL CHECKS PASSED ✓** on every commit.

## What's new since v0.1.0

### M5-Closeout Bucket 4 — Success/Failure/Restart

- **`M5GameState`** — new carrier that tracks the
  player's survival progress (`days_survived`,
  `hearth_count`, `shrine_count`, `forge_count`,
  `well_count`, `trap_count`, `inhabitant_count`,
  `outcome`, `reason`).
- **Win condition** — survive 30 days with at least
  1 hearth, 1 shrine, 1 forge, 1 well, 1 trap, and
  4 inhabitants.
- **Lose conditions** — 0 inhabitants OR 0 hearths.
- **`GameOverBanner`** — new in-scene UI element
  with Title + Summary + Restart + Quit buttons.
- **`_on_restart_pressed()`** — bumps the SEED
  counter, rebuilds the sim with a new world, and
  re-binds the UI.

### M5-Closeout Bucket 1 — Six Cultures

- **6 inhabitants** — one per culture
  (`lanternbearer`, `bellows`, `ember`, `ledger`,
  `silvershroud`, `tide`).
- **7 portrait PNGs** — procedurally generated
  (the M4 generic `settler.png` was retained as a
  fallback).
- **`_portrait_path_for_culture()`** — canonical
  culture-id to portrait-path mapping.

### M5-Closeout Bucket 2 — Ten Rooms

- **4 new tile PNGs** — `shrine.png`, `forge.png`,
  `well.png`, `trap.png`.
- **TileSet-Resource** — expanded from 4x2 (8 cells)
  to 4x3 (12 cells).
- **`WorldGenerator._place_room_tile()`** — places
  the 4 new rooms around the hearth (north, east,
  south, west).

### M5-Closeout Bucket 3 — Fifteen Events

- **`M5Events`** — new event catalogue with 15
  events (5 crisis, 5 good, 5 narrative).
- **`M5Events.roll_event(rng)`** — weighted random
  draw (linear distribution; the M6 closeout can
  upgrade to exponential).

### M5-Closeout Bucket 5 — English/German i18n

- **36 new locale keys** in `locales/en.po` and
  `locales/de.po` (4 room names + 15 event
  descriptions + 7 game-over UI + 6 culture names
  + 4 room descriptions).
- **`M5Events.format_event()`** — `tr()`-based
  resolution of event description keys.

### M5-Closeout Bucket 6 — Audio

- **5 SFX** — `step.wav`, `power_seal.wav`,
  `power_pause.wav`, `crisis_horn.wav`,
  `game_over.wav`. All procedurally generated
  (16-bit PCM, mono, 22050 Hz).
- **1 ambient track** — `ambient_loop.wav`
  (10 seconds, slow drone with detuned
  oscillators, designed to loop seamlessly).
- **`StepSfx` AudioStreamPlayer** — wired into
  `PlayableShell.tscn` and played on every
  `_on_step_pressed()`.

## M6 — Public Release Readiness (per ADR-0018)

- **Performance target** documented
  (`docs/performance.md`).
- **Reproducible builds** via
  `tools/build/build_release.sh` (Linux, macOS,
  Windows, Web).
- **Release Notes** generated from CHANGELOG via
  `tools/build/generate_release_notes.sh`.
- **Accessibility** — keyboard-navigable UI,
  color-contrast WCAG 2.1 AA.
- **Licensing/IP audit** complete
  (`LICENSES/` directory, all assets procedural).
- **Known-Issues list** maintained
  (`KNOWN_ISSUES.md`).

## Known issues

- The `game_over.wav` SFX has a small click at the
  500ms mark (the descending major-third is
  abruptly concatenated). The M6.1 closeout will
  fix this with a proper ADSR envelope.
- The atlas-4x4 file name is retained for
  backward compatibility (the actual layout is
  4x3 = 12 cells).
- The `M5GameState` is re-computed on every
  `_on_step_pressed()` (not incremental). For
  very long sessions, the per-tick cost grows
  linearly with the world size. M7 may add an
  incremental update path.

## System requirements

- **Godot 4.7.0** (the canonical version; the
  project is `project.godot`-pinned to 4.7).
- **Linux**, **macOS**, or **Windows** (the M6
  build pipeline targets all three).
- **Keyboard + mouse** (touch support is a
  post-M6 deliverable).

## License

- Original source code: **GPL-3.0-or-later**.
- Original content (art, audio, locales):
  **CC BY-SA 4.0**.
- See `LICENSE` and `docs/ip-license-checklist.md`
  for the full license intent.

## Build instructions

To build from source:

```bash
# 1. Install Godot 4.7.
# 2. Install Python dependencies.
pip install --break-system-packages pyyaml gdtoolkit==4.5.0

# 3. Clone the repository and run the build.
git clone https://github.com/mazer666/PitPact.git
cd PitPact
./tools/build/build_release.sh linux
```

The build artifacts land in `build/release/` with
SHA-256 checksums in `build/checksums/`.

## What's next

The next milestone is **M7 — Balancing & content**
(post-M6). The M7 backlog (per `docs/roadmap.md`):
additional content, mod/content interfaces, and
later iPadOS preparation. Co-op only after the
single-player architecture is stable.

— PitPact contributors, 2026
