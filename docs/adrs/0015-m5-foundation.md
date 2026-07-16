# ADR-0015 — M5-Foundation: PlayableShell

- **Status:** Accepted
- **Date:** 2026-07-16
- **Deciders:** Owner (Mavis)
- **Supersedes:** —
- **Related:** ADR-0009 (best-in-class bar),
  ADR-0012 (M4-Closeout), ADR-0013
  (M4-Hardening), ADR-0014 (M0-M3 Audit),
  M1-Closeout (UI shell stubs).

## Context

The M0-M4 surface is audit-grade (ADR-0014,
ADR-0013). The M1-Closeout shipped a UI shell
with stubs for save/load, a title screen, a
pause menu, a camera, a minimap, and a
diagnostics overlay. The M2-Closeout shipped
the simulation core; the M3-Closeout shipped
the world generation and narrative anchors;
the M4-Closeout shipped the research, ritual,
Pactmaker, autonomous conflict, and difficulty
layers.

The end-to-end test (`test_m3_world_and_campaign_smoke`)
exercises the full sim loop in headless mode:
world generation, exploration, narrative
anchors, crisis resolution, save/load,
locale-switch, and determinism. The test
verifies the sim is correct; it does not
verify the UI exposes the sim to the player.

The M5-Foundation fills this gap. The
foundation is the minimal **PlayableShell**:
a single scene that composes the M0-M4 sim
with a UI that lets the player drive the
sim. The M5 closeout extends the foundation
with the milestone-plan content (six cultures,
ten rooms, fifteen events, success/failure/
restart loop, English/German, audio pass).

The M5-Foundation is held to the best-in-class
bar (ADR-0009): architecture-grade, test-grade,
documentation-grade, local-quality-grade,
content-grade, audit-grade.

## Decision

The M5-Foundation is a single "PlayableShell"
scene (`scenes/main/PlayableShell.tscn`) that:

1. **Composes the sim.** A `PlayableShell`
   carrier (`src/ui/playable_shell.gd`) creates
   a `Sim` (M2) with three inhabitants (M2), a
   24x24 world (M3), three narrative anchors
   (M3), one crisis (M3), a Pactmaker (M4),
   knowledge state (M4), factions (M4),
   settings (M4), and an exploration map (M3).
   The carrier is the canonical "playable sim"
   factory; the M5 closeout can swap in a
   different sim factory without touching the
   UI scene.

2. **Drives the per-tick loop.** The shell
   runs the sim at 1 tick / second by default
   (configurable via the Settings menu). The
   player can also step the sim manually with
   a "Step" button. The M5 closeout pins
   these to a constant on `Sim` (M2 + M4
   combined).

3. **Exposes the sim to the player.** The
   shell has:
   - **Tile grid** (M3 WorldTileMapLayer)
   - **Hearth placement** (click a tile to
     place a Hearth; the Hearth's lifecycle
     state is shown next to the cursor)
   - **Inhabitant panel** (left; shows the
     three inhabitants' id, culture, role,
     state, morale, stress, and the four
     needs as horizontal bars)
   - **Crisis banner** (top; shows the
     current pending crisis with its three
     choices)
   - **Pactmaker panel** (right; shows the
     three powers with cooldown and
     intervention-counter gauges; the player
     clicks a power to invoke it)
   - **Tick control** (bottom; the Step
     button, the auto-tick toggle, and the
     current time_days display)
   - **Settings menu** (Pause → Settings;
     difficulty dropdown with PEACEFUL /
     BALANCED / CRUEL, locale dropdown with
     en / de, auto-resolve-days slider)
   - **Save / Load** (Pause → Save / Load;
     uses the M2 save service)

4. **End-to-end test.** A new
   `test_m5_foundation_smoke.gd` exercises
   the PlayableShell in headless mode: the
   carrier creates a sim, the UI events
   fire, the sim ticks, the Pactmaker
   power triggers, and the post-state is
   asserted. The test is the regression net
   for the M5-Foundation.

## Consequences

Positive:

- The M5-Foundation is the first milestone
  that delivers a *playable* game: the
  player can drive the sim end-to-end.
- The `PlayableShell` carrier is the
  canonical "playable sim" factory; the
  M5 closeout can swap in a different
  sim factory (e.g. an M5-content-driven
  sim with the six cultures and ten
  rooms) without touching the UI scene.
- The M5-Foundation is the regression net
  for the UI shell; the M5 closeout's
  content additions can land on top of
  the foundation without breaking the
  end-to-end loop.

Negative:

- The PlayableShell is a minimal playable
  loop; the M5 closeout is where the
  content (six cultures, ten rooms,
  fifteen events) and the production
  features (audio pass, success/failure
  loop) land.
- The shell uses the M1 UI primitives
  (CanvasLayer, Button, Label); the M5
  closeout may want a richer UI
  framework (e.g. a dedicated theme
  resource). The M5-Foundation keeps
  the UI framework out of scope.

## References

- `docs/adrs/0009-best-in-class-bar.md` —
  the best-in-class bar.
- `docs/adrs/0012-m4-closeout.md` — the
  M4-Closeout (the sim surface).
- `docs/adrs/0013-m4-hardening.md` — the
  audit-grade pattern.
- `docs/adrs/0014-m0-m3-audit.md` — the
  M0-M3 audit.
- `docs/milestones.md` — the M5 milestone
  Definition-of-Done.
- `CHANGELOG.md` — the M5-Foundation
  entry.
