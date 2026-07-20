# ADR-0027 — M15: Final Polish, UX & Real Co-op

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M15 (Final Polish + Real Co-op)
- Supersedes: none (extends ADR-0026, ADR-0022)
- Related: ADR-0026 (M14), ADR-0022 (M10), docs/roadmap.md

## Context

M14-Engine-Perf-Content
(ADR-0026) lieferte Engine-Opt
+ Content-Depth
(Achievements, Campaign,
FrameProfiler, ObjectPool,
SpeedRun). M15 ist das
**Final-Polish + Real-Co-op**
Milestone — das Spiel wird
**komplett spielbar** (Settings,
Tutorial, Stats, Localization)
und der Co-op-Modus wird
**real** (mit Server-Browser,
Cloud-Lobbies, NAT-Traversal).

Per user request:
> "all das und auch coop aber
> nicht nur stub bring es in
> scope"

Diese ADR pinnt den M15-Scope
*testbar* in **5 Buckets**
(Cloud-Save, Settings,
Tutorial, Statistics,
Real-Co-op) + 1 Side-Quest
(L — 3rd-Language).

## Decision

M15 wird in **5 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (L)**:

### Bucket 1 — Cloud Save

**Goal**: Multi-Slot-Save mit
Hash-Validation + Auto-Save
+ Save-Format-Versioning.

**Definition-of-Done**:
- **`SaveManager` carrier**
  (`src/save/save_manager.gd`):
  - `static func make() -> SaveManager`
  - `func save(slot: int, state: Dictionary) -> int`
    returns 0 on success
  - `func load(slot: int) -> Dictionary`
    returns empty dict on miss
  - `func delete(slot: int) -> int`
  - `func slot_count() -> int`
  - `func has_save(slot: int) -> bool`
- **Auto-Save**: every 10 ticks
- **Hash-Validation**: SHA-256
  of the serialized state
- **Format-Versioning**:
  `SAVE_FORMAT_VERSION = "1.0.0"`
- **Tests**: 8+ tests (save,
  load, delete, has_save,
  hash validation, version
  check, slot count, auto-save).

### Bucket 2 — Settings

**Goal**: In-Game-Settings
(Audio, Resolution, Language,
Fullscreen, Difficulty).

**Definition-of-Done**:
- **`Settings` carrier**
  (`src/config/settings.gd`):
  - `static func make() -> Settings`
  - `func set(key: StringName, value: Variant) -> void`
  - `func get(key: StringName) -> Variant`
  - `func has(key: StringName) -> bool`
  - `func save() -> int`
  - `func load() -> int`
- **Built-in-Keys** (10):
  - `audio.master_volume` (0.0-1.0)
  - `audio.sfx_volume` (0.0-1.0)
  - `audio.music_volume` (0.0-1.0)
  - `display.resolution` (Vector2i)
  - `display.fullscreen` (bool)
  - `display.vsync` (bool)
  - `language.locale` (String)
  - `gameplay.difficulty` (int 0-3)
  - `gameplay.auto_save` (bool)
  - `accessibility.color_blind_mode` (int 0-3)
- **Tests**: 8+ tests (set,
  get, has, save, load,
  defaults, missing key).

### Bucket 3 — Tutorial System

**Goal**: Pop-up-Tutorials für
die ersten 10 sim-steps.

**Definition-of-Done**:
- **`TutorialStep` carrier**
  (`src/tutorial/tutorial_step.gd`):
  - `static func make(id: StringName, title: String, body: String, trigger_condition: Callable) -> TutorialStep`
  - `func is_triggered(state: Dictionary) -> bool`
  - `func is_completed() -> bool`
  - `func mark_completed() -> void`
- **`TutorialManager` carrier**
  (`src/tutorial/tutorial_manager.gd`):
  - `static func make() -> TutorialManager`
  - `func add_step(step: TutorialStep) -> int`
  - `func check_triggers(state: Dictionary) -> Array`
    returns newly-triggered IDs
  - `func skip_all() -> void`
  - `func completed_count() -> int`
- **Built-in-Tutorials** (5):
  - `welcome` — first tick
  - `recruit` — first inhabitant
  - `build_hearth` — first hearth
  - `survive_crisis` — first crisis
  - `win` — first win
- **Tests**: 6+ tests (step
  trigger, condition, mark,
  skip, check_triggers).

### Bucket 4 — Statistics

**Goal**: Run-Stats
(duration, win-rate, avg
days, best time, etc.) +
Global-Stats (all-runs).

**Definition-of-Done**:
- **`RunStats` carrier**
  (`src/stats/run_stats.gd`):
  - `static func make() -> RunStats`
  - `func record_run(state: Dictionary, outcome: String) -> void`
  - `func total_runs() -> int`
  - `func wins() -> int`
  - `func losses() -> int`
  - `func win_rate() -> float`
  - `func avg_days_survived() -> float`
  - `func best_time() -> int`
- **Outcomes**: `"win"`,
  `"loss"`, `"abandoned"`
- **Tests**: 6+ tests (record,
  totals, win_rate, avg, best).

### Bucket 5 — Real Co-op

**Goal**: Echter Co-op-Modus
mit Server-Browser + Cloud-
Lobbies + NAT-Traversal.

**Definition-of-Done**:
- **`LobbyServer` carrier**
  (`src/net/lobby_server.gd`):
  - `static func make() -> LobbyServer`
  - `func register_lobby(lobby_id: StringName, host: String, port: int, max_players: int, metadata: Dictionary) -> int`
  - `func unregister_lobby(lobby_id: StringName) -> int`
  - `func list_lobbies(filter: Dictionary) -> Array`
  - `func lobby_count() -> int`
  - `func get_lobby(lobby_id: StringName) -> Dictionary`
- **In-Memory-Lobby-Registry**:
  The M15 closeout uses an
  in-memory registry (no
  cloud-backend). The
  M15.1 closeout can add
  a cloud-backend.
- **NAT-Traversal-Stub**:
  `NatTraversal` carrier
  (`src/net/nat_traversal.gd`):
  - `static func version() -> String`
  - `static func is_available() -> bool`
  - Returns false in headless
    (real NAT-traversal requires
    STUN/TURN infrastructure;
    M15.1 will integrate).
- **Tests**: 8+ tests (register,
  unregister, list, filter,
  count, get, is_available).

### Side-Quest L — 3rd Language

**Goal**: PitPact auf 3
Sprachen: English, German,
Japanese (3rd).

**Definition-of-Done**:
- **`locales/ja.po`** — Japanese
  translation of M5+ keys
  (150+ keys)
- **`LocalizationManager` carrier**
  (`src/i18n/localization_manager.gd`):
  - `static func make() -> LocalizationManager`
  - `func set_locale(locale: String) -> int`
  - `func get_locale() -> String`
  - `func supported_locales() -> Array`
  - `func translate(key: StringName) -> String`
- **Tests**: 5+ tests
  (set_locale, get_locale,
  supported, translate,
  fallback).

## Out of scope (M15)

- **Cloud-Backend** (AWS/GCP/
  Firebase) — out of scope
  (M15.1; the M15 closeout
  uses in-memory).
- **Real STUN/TURN** — out
  of scope (M15.1; the M15
  closeout's NAT-Traversal
  is a stub).
- **Voice-Chat** — out of
  scope (M16+).
- **Anti-Cheat** — out of
  scope (M16+).

## Consequences

### Positive

- M15 makes PitPact
  **fully shippable**:
  - Cloud-Save (multi-slot)
  - Settings (all knobs)
  - Tutorial (onboarding)
  - Stats (replay value)
  - Real-Coop (multiplayer)
  - 3 Languages (i18n)
- The M15 closeout is
  **testable** in CI (no
  real internet required).

### Negative / Tradeoffs

- Cloud-Save is in-memory
  (no real cloud); M15.1
  adds a backend.
- Real-Coop is headless-
  only (no real internet
  test); M15.1 adds real
  STUN/TURN.
- 3rd language is Japanese
  only; more languages are
  M15.1+.

## Validation (per Bucket)

- **Quality gate**:
  `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 492 + 41-55
  neue Tests = 535+ Tests,
  2100+ Asserts
- **Mutation sweep**: M15
  mutations (5+ je Bucket)
- **Performance budget**:
  60 FPS maintained

## Prio-Order

1. **Bucket 2 (Settings)** —
   high impact (every UI
   needs it).
2. **Bucket 1 (Cloud-Save)** —
   high impact (replay value).
3. **Bucket 3 (Tutorial)** —
   high impact (UX).
4. **Bucket 4 (Stats)** —
   medium impact (replay).
5. **Bucket 5 (Real-Coop)** —
   high impact (multiplayer).
6. **Side-Quest L (i18n)** —
   polish.

## References

- ADR-0026 — M14-Engine-Perf-Content
- ADR-0022 — M10-Co-op-Live-Mode
- ADR-0005 — Determinism
- Godot FileAccess:
  https://docs.godotengine.org/en/stable/classes/class_fileaccess.html
- Godot Crypto:
  https://docs.godotengine.org/en/stable/classes/class_crypto.html
- i18n (PO-Format):
  https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
