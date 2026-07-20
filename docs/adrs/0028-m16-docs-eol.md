# ADR-0028 — M16: Final Documentation + Ease of Life

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M16 (Final Docs + Ease of Life)
- Supersedes: none (extends ADR-0027)
- Related: ADR-0027 (M15), ADR-0018 (M6), docs/requirements.md

## Context

M15-Final-Polish-Coop
(ADR-0027) lieferte Cloud-Save,
GameSettings, Tutorial,
RunStats, LobbyServer,
NAT-Traversal-Stub, Localization
(en/de/ja). M16 ist das
**Final-Documentation +
Ease-of-Life** Milestone —
die Doku wird auf M15-Stand
gebracht und das Spiel
bekommt Quality-of-Life-
Features (Reduce-Motion,
Quick-Save, Pause-Indicator,
In-Game-Help).

Per user request:
> "ja mach das alles der reihe
> nach"

Diese ADR pinnt den M16-Scope
*testbar* in **5 Buckets** (Doc-
Sync, Reduce-Motion, Quick-
Save, Pause-Indicator, In-
Game-Help) + 1 Side-Quest (M —
Performance-Overlay).

## Decision

M16 wird in **5 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (M)**:

### Bucket 1 — Documentation Sync

**Goal**: Alle 11 docs sind
auf M15-Stand (inkl. Style-
Bible mit Gothic-Watercolor-
Palette, Localization mit
Japanisch, Sound-Guide,
Animation-Guide).

**Definition-of-Done**:
- **`docs/style-bible.md`** —
  Gothic Dark Fantasy +
  Storybook Watercolor hybrid
  (per ADR-0023); palette
  mit hex-codes; 6 culture
  silhouettes; 6 SFX motifs.
- **`docs/localization.md`** —
  3 locales (en, de, ja); PO-
  format with msgctxt.
- **`docs/data-schema.md`** —
  M5-M15 datatypes (cultures,
  tiles, events, achievements,
  chapters, mods, save-slot).
- **`docs/sound-guide.md`** (NEW)
  — 6 SFX motifs; 1 ambient
  track; per-event sound.
- **`docs/animation-guide.md`**
  (NEW) — idle, particle, day/
  night, hover, fade, 60 FPS
  budget.
- **`docs/accessibility.md`** —
  Reduce-Motion setting +
  color-blind modes.
- Tests: 0 (documentation is
  verified via content
  checks).

### Bucket 2 — Reduce-Motion Setting

**Goal**: Per WCAG 2.1
(motion-actuator-disabling),
Players can disable all
non-essential animations
(idle, particles, fade-ins,
day-night cycle).

**Definition-of-Done**:
- **`ReduceMotion` carrier**
  (`src/config/reduce_motion.gd`):
  - `static func make() -> ReduceMotion`
  - `func is_active() -> bool`
  - `func set_active(active: bool) -> void`
  - `func animation_allowed(name: StringName) -> bool`
- **Disabled Animations**:
  - `idle_breathing`
  - `particles`
  - `day_night_cycle`
  - `hover_tween`
  - `title_fade_in`
- **Allowed Animations**
  (functional):
  - `step_button_pulse`
  - `crisis_banner_slide`
  - `game_over_banner_slide`
- **Tests**: 6+ tests (default
  state, set_active, allowed/
  blocked animations).

### Bucket 3 — Quick-Save (F5/F9)

**Goal**: Quick-Save-Slot
(F5) + Quick-Load (F9) per
PC-Gaming-Convention.

**Definition-of-Done**:
- **`QuickSave` carrier**
  (`src/save/quick_save.gd`):
  - `static func make() -> QuickSave`
  - `func save(state: Dictionary) -> int`
  - `func load() -> Dictionary`
  - `func has_quick_save() -> bool`
  - `func timestamp() -> int`
  - `func delete() -> int`
- **Sentinel slot**: slot 99
  (out of normal 0-4 range).
- **F5/F9 hotkeys** handled by
  `PlayableShell` (per M8
  InputMap).
- **Tests**: 6+ tests (save,
  load, has_quick_save,
  timestamp, delete,
  overwrites).

### Bucket 4 — Pause-Indicator

**Goal**: When the window
loses focus, show a "PAUSED"
overlay + pause auto-tick.

**Definition-of-Done**:
- **`PauseIndicator` carrier**
  (`src/ui/pause_indicator.gd`):
  - `static func make() -> PauseIndicator`
  - `func set_focused(focused: bool) -> void`
  - `func is_paused() -> bool`
  - `func pause_reason() -> String`
  - `func resume() -> void`
- **Reasons**:
  - `"window_unfocused"`
  - `"manual_pause"`
  - `"auto_pause"`
- **Tests**: 5+ tests (default
  state, set_focused,
  manual_pause, auto_pause,
  resume).

### Bucket 5 — In-Game-Help (F1)

**Goal**: F1 opens a context-
sensitive help dialog.

**Definition-of-Done**:
- **`HelpSystem` carrier**
  (`src/ui/help_system.gd`):
  - `static func make() -> HelpSystem`
  - `func add_topic(topic: HelpTopic) -> int`
  - `func get_topic(id: StringName) -> HelpTopic`
  - `func topics_for_context(context: StringName) -> Array`
  - `func topic_count() -> int`
- **`HelpTopic` carrier**
  (`src/ui/help_topic.gd`):
  - `static func make(id, title, body, related: Array) -> HelpTopic`
- **Built-in-Topics** (5):
  - `getting_started` (welcome)
  - `inhabitants` (how to recruit)
  - `crises` (how to handle)
  - `co_op` (how to join)
  - `settings` (all settings)
- **Tests**: 6+ tests (add,
  get, topics_for_context,
  default topics, missing).

### Side-Quest M — Performance Overlay

**Goal**: F3 toggles a debug
overlay showing FPS, frame
time, draw calls, memory.

**Definition-of-Done**:
- **`PerformanceOverlay` carrier**
  (`src/debug/performance_overlay.gd`):
  - `static func make() -> PerformanceOverlay`
  - `func is_visible() -> bool`
  - `func toggle() -> bool`
  - `func set_visible(v: bool) -> void`
  - `func update_metrics(fps: int, frame_ms: float, draw_calls: int, memory_mb: float) -> void`
  - `func metrics() -> Dictionary`
- **Tests**: 5+ tests (default
  state, toggle, update,
  get_metrics, persistence).

## Out of scope (M16)

- **Mobile-Specific-QoL** (M8
  already covers touch).
- **Achievement-Progress-Display**
  — out of scope (M17+; the
  M14 closeout ships the
  underlying system).
- **Replay-Scrubbing** — out
  of scope (M17+; the M10
  closeout ships the recorder).

## Consequences

### Positive

- M16 brings the documentation
  to **M15-stand** (8/11 docs
  were stale since M0).
- M16 adds **5 quality-of-life
  features** that players
  expect from a best-in-class
  game.
- The M16 closeout is
  **headless-testable** in CI.

### Negative / Tradeoffs

- Performance overlay requires
  a real GPU; the M16 closeout
  uses simulated metrics.
- F1/F3/F5/F9 hotkeys are
  PC-only; the M8 closeout
  already covers touch.

## Validation (per Bucket)

- **Quality gate**:
  `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 563 + 28-37
  neue Tests = 595+ Tests,
  2200+ Asserts
- **Mutation sweep**: M16
  mutations (5+ je Bucket)
- **Performance budget**:
  60 FPS maintained

## Prio-Order

1. **Bucket 1 (Doc-Sync)** —
   high impact (best-in-class
   requires good docs).
2. **Bucket 2 (Reduce-Motion)** —
   high impact (accessibility).
3. **Bucket 5 (In-Game-Help)** —
   high impact (onboarding).
4. **Bucket 3 (Quick-Save)** —
   high impact (ease-of-life).
5. **Bucket 4 (Pause-Indicator)** —
   medium impact (polish).
6. **Side-Quest M (Perf
   Overlay)** — dev-tooling.

## References

- ADR-0027 — M15-Final-Polish-Coop
- ADR-0018 — M6-Release-Readiness
- ADR-0006 — Best-in-Class
- WCAG 2.1 Motion Actuation:
  https://www.w3.org/TR/WCAG21/#motion-actuation
- Godot NOTIFICATION_APPLICATION_FOCUS_OUT:
  https://docs.godotengine.org/en/stable/classes/class_node.html
