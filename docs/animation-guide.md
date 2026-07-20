# PitPact Animation Guide

> Status: **M16 final** (post M13 Visual Polish & Animation).
> This is the canonical animation guide for PitPact. All
> animations are **60 FPS-friendly** (per ADR-0023 performance
> budget of 16.67ms/frame).

## Why a separate document

Animation is the **second-fastest channel** for player feedback
(after sound). A 0.15s hover-tween on a button is the difference
between "snappy" and "sluggish". The rules below make animation
a **first-class citizen**.

## Animation catalogue

The M13 closeout ships 4 animation carriers + 5 M12/M13 effects:

| Animation | Carrier | Cycle | Use |
|-----------|---------|-------|-----|
| `idle_breathing` | `IdleAnimator` (M13) | 2.0s (3 frames: 1.0/1.05/0.95) | Inhabitant portraits |
| `particle_spawner` | `ParticleSpawner` (M13) | 1-2s per spawn | Crises, powers |
| `day_night_cycle` | `DayNightIntegrator` (M13) | 0.5s/tick (30 frames) | Background brightness |
| `audio_reactive_visual` | `AudioReactiveVisual` (M13) | 0.3s decay | Step, crisis, power |
| `hover_tween` | `HoverTween` (M12) | 0.15s (9 frames @ 60 FPS) | Button hover states |
| `title_fade_in` | `TitleScreen` (M12) | 1.5s (90 frames) | Title screen |
| `post_process` | `PostProcess` (M11) | Real-time | Bloom + vignette + color-grade |
| `time_of_day` | `TimeOfDay` (M11) | 0.5s/tick | 4 phases (dawn/midday/dusk/night) |

## Animation design principles

The M13 closeout follows these principles:

- **All animation runs at 60 FPS** (per ADR-0023)
- **Frame-time budget: ≤ 16.67ms/frame** (per M11 performance
  benchmark)
- **No animation is mandatory** (per Reduce-Motion, M16 Bucket 2)
- **Animations are interruptible** (e.g., `hover_tween` resets on
  re-hover)
- **Animations are deterministic** (per ADR-0005)

## Frame-time budget

Per the M11 performance benchmark:

| Frame | Budget | Actual (M11) |
|-------|--------|--------------|
| 60 FPS | 16.67ms | 9.98ms avg ✓ |
| 1% low | 20ms | 11.92ms ✓ |
| 0.1% low | 30ms | 11.92ms ✓ |

The M16 closeout maintains this budget. `PerformanceOverlay`
(M16 Side-Quest M) gives players a real-time view of frame-time.

## Reduce-Motion (M16 Bucket 2)

The M16 closeout adds `ReduceMotion` carrier. When `active=true`:

| Animation | Allowed? |
|-----------|----------|
| `idle_breathing` | ❌ Disabled |
| `particles` | ❌ Disabled |
| `day_night_cycle` | ❌ Disabled (instant transitions) |
| `hover_tween` | ❌ Disabled (instant) |
| `title_fade_in` | ❌ Disabled (instant) |
| `step_button_pulse` | ✅ Allowed (functional feedback) |
| `crisis_banner_slide` | ✅ Allowed (important info) |
| `game_over_banner_slide` | ✅ Allowed (important info) |
| `victory_banner_slide` | ✅ Allowed (important info) |

This follows **WCAG 2.1 motion-actuator-disabling** principle.

## Adding new animations

When adding a new animation:

1. **Create a carrier** in `src/ui/` or `src/effects/`
2. **Use Godot's Tween API** (with explicit `set_speed_scale(1.0)`
   for determinism)
3. **Document the cycle duration** in this file
4. **Add to Reduce-Motion** if non-essential
5. **Test headless** (use `Node` test fixtures, not `CanvasItem` —
   per M13 note that `CanvasItem` is abstract in Godot 4.7)
6. **Add frame-time test** in `tests/integration/test_m16_perf.gd`

## Performance overlay (M16 Side-Quest M)

The M16 closeout ships `PerformanceOverlay` carrier with:
- `is_visible()` / `toggle()` / `set_visible()`
- `update_metrics(fps, frame_ms, draw_calls, memory_mb)`
- F3 hotkey to toggle

The M17 closeout will add a graph view (last 60 frames).

## References

- M11-Art-Rework (commit `1aa4536`) — TimeOfDay, post_process.gdshader
- M12-UI-Grafical-Rework (commit `99952b0`) — HoverTween, title_fade_in
- M13-Visual-Polish (commit `fc86dde`) — IdleAnimator, ParticleSpawner,
  DayNightIntegrator, AudioReactiveVisual
- M16 Side-Quest M — PerformanceOverlay
- ADR-0023 — M11 Art Rework (60 FPS budget)
- ADR-0025 — M13 Visual Polish
- `src/ui/idle_animator.gd` (existing)
- `src/effects/particle_spawner.gd` (existing)
- `src/world/day_night_integrator.gd` (existing)
- `src/ui/audio_reactive_visual.gd` (existing)
- `src/ui/hover_tween.gd` (existing)
- `src/ui/title_screen.gd` (existing)
- `src/world/time_of_day.gd` (existing)
- `shaders/post_process.gdshader` (existing)
