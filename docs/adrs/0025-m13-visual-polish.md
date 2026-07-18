# ADR-0025 — M13: Visual Polish & Animation

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M13 (Visual Polish & Animation)
- Supersedes: none (extends ADR-0023, ADR-0024)
- Related: ADR-0024 (M12), ADR-0023 (M11), docs/style-bible.md

## Context

M12-UI-Grafical-Rework
(ADR-0024) lieferte die AI-driven
.tscn scenes + Theme v2 +
HoverTween + TitleScreen.
M13 ist das **Visual-Polish &
Animation** Milestone — die
Visuals werden lebendig
gemacht durch:
- Idle-Animationen (3-frame
  breathing)
- Particle-Effects (Crises,
  Powers)
- Day/Night-Integration (M11
  TimeOfDay wired into the
  shader)
- Audio-Reactive Visuals
  (Step-Pulse, Crisis-Flash)
- Animated Crisis-Banner
  (slide-in, pulse)

Per user request:
> "weiter" (post-M12)

Diese ADR pinnt den M13-Scope
*testbar* in **3 Buckets**
(Idle-Animation, Particle-
System, DayNight-Integration)
+ 1 Side-Quest (J — Audio-
Reactive Visuals).

## Decision

M13 wird in **3 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (J)**:

### Bucket 1 — Idle Animation

**Goal**: Die Inhabitanten haben
subtile 3-frame breathing
animations (idle).

**Definition-of-Done**:
- **`IdleAnimator` carrier**
  (`src/ui/idle_animator.gd`):
  - `static func make() -> IdleAnimator`
  - `func add_node(path: String) -> int`
  - `func tick(delta: float) -> void`
  - `func frame_count() -> int`
  - `func current_frame(path: String) -> int`
- **3-Frame-Breathing**:
  - Frame 0: normal
  - Frame 1: slight scale (1.05x)
  - Frame 2: slight scale (0.95x)
  - Cycle 2.0s (120 frames @ 60 FPS)
- **Tests**: 6+ tests (frame
  progression, scale values,
  cycle reset, multi-node).

### Bucket 2 — Particle System

**Goal**: Crises + Powers
spawnen Particle-Effects
(fire, smoke, magic).

**Definition-of-Done**:
- **`ParticleSpawner` carrier**
  (`src/effects/particle_spawner.gd`):
  - `static func make(particle_type: StringName) -> ParticleSpawner`
  - `func spawn(position: Vector2) -> int`
    returns particle count
  - `func particle_type() -> StringName`
  - `func is_active() -> bool`
- **Particle-Types**:
  - `fire` (red/orange, 20 particles)
  - `smoke` (gray, 15 particles)
  - `magic` (purple, 25 particles)
  - `blood` (dark red, 10 particles)
- **Tests**: 6+ tests (types,
  spawn count, position,
  active state).

### Bucket 3 — DayNight Integration

**Goal**: Das M11 TimeOfDay
treibt das M11 Shader
real-time. Die Scene wird
sichtbar heller/dunkler.

**Definition-of-Done**:
- **`DayNightIntegrator` carrier**
  (`src/world/day_night_integrator.gd`):
  - `static func make(time_of_day: TimeOfDay, scene_root: Node) -> DayNightIntegrator`
  - `func tick(delta: float) -> void`
  - `func apply_color_grade() -> void`
  - `func brightness() -> float`
  - `func phase() -> int`
- **Wiring**:
  - `PlayableShell` instantiates
    `DayNightIntegrator` in
    `_ready()`
  - `tick()` updates the
    shader's `brightness` +
    `warm_shift` + `cool_shift`
    uniforms
- **Tests**: 6+ tests (init,
  tick, brightness mapping,
  shader param update).

### Side-Quest J — Audio-Reactive Visuals

**Goal**: Die UI reagiert auf
Audio-Events (Step-Pulse,
Crisis-Flash).

**Definition-of-Done**:
- **`AudioReactiveVisual` carrier**
  (`src/ui/audio_reactive_visual.gd`):
  - `static func make() -> AudioReactiveVisual`
  - `func on_step() -> void` —
    triggers a button pulse
  - `func on_crisis() -> void` —
    triggers a screen flash
  - `func on_power() -> void` —
    triggers a button glow
  - `func tick(delta: float) -> void`
- **Pulse-Duration**: 0.3s
  (= 18 frames @ 60 FPS).
- **Tests**: 4+ tests (pulse
  state, decay, multi-event).

## Out of scope (M13)

- **Skeletal-Animation** (full
  Skeleton2D / Bone2D) — out
  of scope (M14+; would
  require art-redesign).
- **Particle-Shader-Customization**
  — out of scope (the M13
  closeout uses Godot's
  default `CPUParticles2D`).
- **3D-Particles** — out of
  scope (PitPact is 2D).
- **Audio-Visual-Sync für
  alle 6 SFX** — out of scope
  (the M13 closeout covers
  step + crisis + power; the
  M14 closeout can add the
  other 3).

## Consequences

### Positive

- M13 brings PitPact to life
  with idle animations +
  particles + day/night.
- Audio-reactive visuals
  give the UI immediate
  feedback.
- Performance budget (60 FPS)
  is maintained (per
  ADR-0023).

### Negative / Tradeoffs

- Particles can be heavy;
  the M13 closeout caps at
  25 particles per spawn.
- Day/night is global; the
  M14 closeout can add
  per-tile lighting.
- Idle animation is
  breathing-only; the M14
  closeout can add walk/work
  animations.

## Validation (per Bucket)

- **Quality gate**:
  `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 407 + 22-28
  neue Tests = 430+ Tests,
  1950+ Asserts
- **Mutation sweep**: M13
  mutations (5+ je Bucket)
- **Performance budget**:
  60 FPS maintained with
  particles + animations

## Prio-Order

1. **Bucket 3 (DayNight
   Integration)** — high
   impact (immediate visual
   change).
2. **Bucket 1 (Idle)** —
   high leverage (most
   visible).
3. **Bucket 2 (Particles)** —
   medium impact (events).
4. **Side-Quest J (Audio-
   Reactive)** — polish.

## References

- ADR-0024 — M12-UI-Grafical-Rework
- ADR-0023 — M11-Art-Rework
- Godot CPUParticles2D:
  https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html
- Godot Tween:
  https://docs.godotengine.org/en/stable/classes/class_tween.html
