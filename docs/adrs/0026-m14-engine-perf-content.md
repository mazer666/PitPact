# ADR-0026 — M14: Engine Performance & Content Depth

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M14 (Engine Performance & Content Depth)
- Supersedes: none (extends ADR-0025)
- Related: ADR-0025 (M13), ADR-0019 (M7), docs/roadmap.md

## Context

M13-Visual-Polish (ADR-0025)
lieferte Idle-Animationen,
Particles, DayNight-Integration,
Audio-Reactive-Visuals.
M14 ist das **Engine-Performance
& Content-Depth** Milestone —
das Spiel wird tiefer (mehr
Content, Achievements, Kampagne)
UND schneller (Engine-Opt).

Per user request:
> "weiter" (post-M13)

Diese ADR pinnt den M14-Scope
*testbar* in **3 Buckets**
(Achievement-System, Kampagne-
Modus, Engine-Optimierung) +
1 Side-Quest (K — Speed-Run-
Modus).

## Decision

M14 wird in **3 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (K)**:

### Bucket 1 — Achievement System

**Goal**: Spieler werden für
bestimmte Aktionen belohnt
(45-day win, 10 inhabitants,
no crisis for 30 days, etc.).

**Definition-of-Done**:
- **`Achievement` carrier**
  (`src/progression/achievement.gd`):
  - `static func make(id: StringName, title: String, description: String, condition: Callable) -> Achievement`
  - `func is_unlocked() -> bool`
  - `func check(state: Dictionary) -> bool`
  - `func unlock() -> void`
- **`AchievementRegistry` carrier**
  (`src/progression/achievement_registry.gd`):
  - `static func make() -> AchievementRegistry`
  - `func add(achievement: Achievement) -> int`
  - `func check_all(state: Dictionary) -> Array`
    returns newly-unlocked IDs
  - `func unlocked_count() -> int`
  - `func total_count() -> int`
- **Built-in-Achievements** (10):
  - `first_step` — first day ticked
  - `first_inhabitant` — first inhabitant recruited
  - `first_hearth` — first hearth built
  - `mid_game` — 20 days survived
  - `full_house` — 10 inhabitants
  - `survivor` — 45 days (M7 win)
  - `pacifist` — no crisis for 30 days
  - `warlord` — defeat 3 crises
  - `builder` — build 5 hearths + 5 shrines
  - `completionist` — unlock 9/10 achievements
- **Tests**: 8+ tests (add,
  check, unlock, check_all,
  count).

### Bucket 2 — Kampagne Modus

**Goal**: Story-getriebene
Kampagne mit mehreren
Kapiteln + Boss-Crises.

**Definition-of-Done**:
- **`Chapter` carrier**
  (`src/progression/chapter.gd`):
  - `static func make(id: StringName, title: String, target_days: int, required_inhabitants: int) -> Chapter`
  - `func is_complete(state: Dictionary) -> bool`
  - `func progress(state: Dictionary) -> float`
    returns 0.0-1.0
- **`Campaign` carrier**
  (`src/progression/campaign.gd`):
  - `static func make() -> Campaign`
  - `func add_chapter(chapter: Chapter) -> int`
  - `func chapter_count() -> int`
  - `func current_chapter() -> Chapter`
  - `func advance() -> Chapter`
  - `func is_complete() -> bool`
- **5 Chapters**:
  1. `awakening` — 10 days, 2 inhabitants
  2. `settlement` — 20 days, 4 inhabitants
  3. `expansion` — 30 days, 6 inhabitants
  4. `crisis` — 40 days, 8 inhabitants
  5. `mastery` — 45 days, 10 inhabitants
- **Tests**: 6+ tests (make,
  add chapter, current, advance,
  complete, progress).

### Bucket 3 — Engine Optimierung

**Goal**: Engine-Opt für
60 FPS auf 4-year-old laptop
(mit allen M11-M13 features
aktiv: shader + particles +
animations).

**Definition-of-Done**:
- **`EngineProfiler` carrier**
  (`src/engine/engine_profiler.gd`):
  - `static func make() -> EngineProfiler`
  - `func record_frame(delta_ms: float) -> void`
  - `func avg_frame_ms() -> float`
  - `func p99_frame_ms() -> float`
  - `func frame_count() -> int`
  - `func is_within_budget(budget_ms: float) -> bool`
- **`ObjectPool` carrier**
  (`src/engine/object_pool.gd`):
  - `static func make(factory: Callable) -> ObjectPool`
  - `func acquire() -> Variant`
  - `func release(obj: Variant) -> void`
  - `func available_count() -> int`
  - `func total_count() -> int`
  - Used to pool particles
  (M13) + inhabitants + tiles
- **Tests**: 6+ tests (frame
  recording, p99, budget check,
  pool acquire/release, pool
  count).

### Side-Quest K — Speed-Run Modus

**Goal**: Ein Speed-Run-Modus
mit Timer + Leaderboard (in-
memory).

**Definition-of-Done**:
- **`SpeedRun` carrier**
  (`src/progression/speed_run.gd`):
  - `static func make(target: StringName) -> SpeedRun`
  - `func start() -> void`
  - `func stop() -> int`
    returns elapsed seconds
  - `func elapsed_seconds() -> int`
  - `func is_running() -> bool`
- **Targets**:
  - `45_days` — win in 45 sim-days
  - `survivor` — survive 60 days
  - `builder` — 10 hearths in 20 days
- **Tests**: 4+ tests (start,
  stop, elapsed, is_running).

## Out of scope (M14)

- **Cloud-Sync für Achievements**
  — out of scope (M15+;
  requires backend).
- **Multiplayer-Campaign** —
  out of scope (M15+; per
  ADR-0025).
- **Custom-Levels / Map-Editor**
  — out of scope (M15+; would
  require major UI work).
- **Narrative-Branching** — out
  of scope (the M14 closeout's
  campaign is linear).

## Consequences

### Positive

- M14 adds **replayability**
  via achievements + speed-run.
- Engine-Opt keeps 60 FPS
  budget with all visuals
  active.
- Kampagne gives the game
  a clear progression arc.

### Negative / Tradeoffs

- Achievements are in-memory
  only (no cloud sync).
- Speed-run leaderboard is
  local; the M15 closeout
  can add cloud-leaderboards.
- Engine-Opt is headless-only
  (no real device profiling).

## Validation (per Bucket)

- **Quality gate**:
  `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 444 + 24-32
  neue Tests = 470+ Tests,
  2000+ Asserts
- **Mutation sweep**: M14
  mutations (5+ je Bucket)
- **Performance budget**:
  60 FPS maintained

## Prio-Order

1. **Bucket 3 (Engine Opt)** —
   high leverage (perf matters
   most with M11-M13 visuals).
2. **Bucket 1 (Achievements)** —
   high impact (replayability).
3. **Bucket 2 (Kampagne)** —
   medium impact (progression).
4. **Side-Quest K (Speed-Run)** —
   replayability.

## References

- ADR-0025 — M13-Visual-Polish
- ADR-0019 — M7-Content-and-Balance
- ADR-0022 — M10-Co-op-Live-Mode
- Godot Performance:
  https://docs.godotengine.org/en/stable/tutorials/performance/index.html
- Object Pool Pattern:
  https://en.wikipedia.org/wiki/Object_pool_pattern
