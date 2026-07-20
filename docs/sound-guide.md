# PitPact Sound Guide

> Status: **M16 final** (post M5-Closeout Bucket 6 audio pass).
> This is the canonical sound-effects + ambient guide for PitPact.
> All SFX are procedurally generated (per ADR-0005) or CC0-licensed
> (per M6 licensing audit).

## Why a separate document

Sound is the **fastest channel** for player feedback. A 0.2s
"step" blip on every game tick gives the player a sense of
"yes, my action did something" — without it, the game feels
sluggish even at 60 FPS. The rules below make sound a **first-class
citizen**, not a polish task.

## SFX catalogue

The M5-Closeout Bucket 6 ships 6 procedurally-generated SFX
(16-bit PCM @ 22050 Hz, all CC0):

| File | Use | Duration | Notes |
|------|-----|----------|-------|
| `step.wav` | Step button (game tick) | 0.2s | Soft "thunk" — confirms tick |
| `power_seal.wav` | Power: Seal Breach | 0.5s | Magical seal sound |
| `power_pause.wav` | Power: Pause Crisis | 0.5s | Time-slowing sound |
| `power_reveal_tile.wav` | Power: Reveal Tile | 0.5s | Discovery chime |
| `crisis_horn.wav` | Crisis event | 0.8s | Warning horn |
| `game_over.wav` | Game over | 1.5s | Sad horn + bell |
| `ambient_loop.wav` | Background ambient | 30s loop | Soft pad + wind |

All SFX are stored in `assets/audio/`. The M5 closeout uses
Godot's built-in `AudioStreamPlayer` (per-scene) and
`AudioStreamPlayer` nodes.

## SFX design principles

The M5 closeout's procedural SFX are designed to:

- **Be short** (≤ 1.5s) — no musical phrases, just sonic events
- **Have a clear attack + decay** — no looping tail (except
  `ambient_loop.wav`)
- **Match the visual style** — warm mid-tones, no harsh
  high-frequency spikes
- **Be deterministic** — per ADR-0005, the same input always
  produces the same output

## Per-event sound mapping

The M5 closeout's `PlayableShell` triggers:

| Event | SFX | Trigger |
|-------|-----|---------|
| Step button | `step.wav` | `_on_step_pressed()` |
| Power 1 (Seal Breach) | `power_seal.wav` | `_on_power_pressed("seal_breach")` |
| Power 2 (Pause Crisis) | `power_pause.wav` | `_on_power_pressed("pause_crisis")` |
| Power 3 (Reveal Tile) | `power_reveal_tile.wav` | `_on_power_pressed("reveal_tile")` |
| Crisis triggered | `crisis_horn.wav` | `M5Events.roll_event()` returns crisis |
| Game over | `game_over.wav` | `M5GameState.outcome = "loss"` |
| Game won | `game_over.wav` (modified) | `M5GameState.outcome = "win"` |
| Background | `ambient_loop.wav` | Always playing during game |

## Future sound (M17+)

The M17 closeout will add:

- **Per-culture ambient** — each culture has a unique ambient track
- **Crisis-specific SFX** — faction, plague, marsh, highland,
  bone, oath (M5-Closeout has 2 crises; the M5-Closeout Bucket 6
  ships 1 `crisis_horn.wav`; M17 will add per-crisis SFX)
- **Inhabitant recruit SFX** — soft "welcome" chime
- **Achievement unlock SFX** — small bell + chord
- **Day/Night transition SFX** — soft whoosh (M13's DayNight)
- **Voice-acting** — for inhabit-quotes (planned M18+)

## Audio-reactive visuals (M13)

The M13 closeout's `AudioReactiveVisual` carrier provides:

- `on_step()` — triggers step-button pulse
- `on_crisis()` — triggers screen flash
- `on_power()` — triggers button glow

The pulse/flash/glow decay over 0.3s (= 18 frames @ 60 FPS).

## Performance

The M11 closeout's `FrameProfiler` measures frame times with
all audio + visuals active. The M16 closeout's performance budget
is **60 FPS @ 16.67ms/frame** (per ADR-0023).

## Licensing

All SFX are procedurally generated (per ADR-0005) and therefore
CC0 (per M6 licensing). The M6 closeout's `licenses/asset-manifest.md`
documents this.

## References

- M5-Closeout Bucket 6 — 6 SFX + 1 ambient (commit `7c2ca25`)
- ADR-0005 — Determinism (procedural SFX)
- ADR-0025 — M13 Visual Polish (AudioReactiveVisual)
- `assets/audio/` — 6 WAVs + 6 .import files
- `tools/benchmarks/run_perf_v2.gd` — frame-time benchmark
- `tests/integration/test_m5_audio.gd` — existing SFX tests
