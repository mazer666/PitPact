# ADR-0021 — M9: Co-op Foundation

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M9 (Co-op Foundation)
- Supersedes: none (extends ADR-0020)
- Related: ADR-0020 (M8), ADR-0019 (M7), docs/roadmap.md

## Context

M8-iPadOS-and-Mobile (ADR-0020) lieferte
Touch-Input, Mobile-UI-Reflow, iOS-
Export-Preset. M9 ist die
**Co-op-Foundation** — der
Grundstein für Multiplayer, ohne
den vollen Co-op-Modus zu
implementieren.

Per `docs/roadmap.md` Post-release
backlog:
> "Co-op only after the single-
> player architecture is stable."

Diese ADR pinnt den M9-Scope
*testbar* in **4 orthogonalen
Buckets** (Co-op-Protokoll,
Lobby, Mod-Hot-Reload, Balance-
Iteration). Jeder Bucket hat
testbare Kriterien (wie M0-M8).

## Decision

M9 wird in **4 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (F)**:

### Bucket 1 — Co-op Protocol (E)

**Goal**: Ein deterministisches,
lockstep-basiertes Co-op-Protokoll
für den sim-state-sync zwischen
2+ Spielern.

**Definition-of-Done**:
- **`CoopProtocol` carrier**
  (`src/net/coop_protocol.gd`):
  - `static func version() -> String`
    → `"0.5.0-m9-coop-foundation"`
  - `static func hash_state(state: Dictionary) -> int`
    → FNV-1a 64-bit hash des sim
      states (deterministisch, kein
      RNG, kein Wall-Clock)
  - `static func diff_states(old: Dictionary, new: Dictionary) -> Array`
    → Liste von operations (add/
      remove/set) zwischen states
  - `static func apply_diff(state: Dictionary, ops: Array) -> Dictionary`
    → wendet ops auf state an
- **Determinismus-Garantie**: zwei
  identische seeds + identische
  inputs ergeben identische hashes
  (per `tools/audit/determinism_check.gd`).
- **Tests**: 8+ tests (hash
  determinism, diff roundtrip,
  conflict-free merges).

### Bucket 2 — Lobby (A)

**Goal**: Ein In-Game-Lobby wo 2-4
Spieler einen sim-state teilen
können.

**Definition-of-Done**:
- **`CoopLobby` carrier**
  (`src/net/coop_lobby.gd`):
  - `static func make(host: bool, peer_count: int) -> CoopLobby`
  - `func add_peer(peer_id: int) -> int`
  - `func remove_peer(peer_id: int) -> int`
  - `func peer_count() -> int`
  - `func is_host() -> bool`
- **Headless-Tests** (kein echtes
  networking): 4+ tests
  (lifecycle, peer add/remove,
  host handoff).
- **Optional**: ENet-Adapter
  (`src/net/enet_adapter.gd`) mit
  dem `MultiplayerAPI` — commented
  out, ready für M9.1.

### Bucket 3 — Mod Hot-Reload (C)

**Goal**: Mods können zur Laufzeit
hot-reloaded werden ohne sim
restart.

**Definition-of-Done**:
- **`M5Events.hot_reload_mod(mod_path: String) -> int`**
  → reload events aus einem mod,
    gibt neue event-count zurück
- **`M5Events.unload_mod(mod_id: String) -> int`**
  → entfernt mod events
- **File-watcher** (optional, via
  `FileAccess.get_modified_time()`):
  pollt jede 5s, lädt mod neu wenn
  geändert.
- **Tests**: 6+ tests (hot-reload,
  unload, conflict-resolution).

### Bucket 4 — Balance Iteration (D)

**Goal**: A/B-Test-Framework für
iterative balance-passes ohne
sim-restart.

**Definition-of-Done**:
- **`M7BalanceConfig.apply_patch(patch: Dictionary) -> M7BalanceConfig`**
  → wendet balance-patch live an
- **`BalancePatchLog` carrier**
  (`src/sim/balance_patch_log.gd`):
  - `static func make() -> BalancePatchLog`
  - `func record(patch: Dictionary, tick: int) -> int`
  - `func history() -> Array`
  - `func revert_to(tick: int) -> M7BalanceConfig`
- **Tests**: 6+ tests (patch
  apply, history, revert).

### Side-Quest F — Touch-Visualizer

**Goal**: Eine Debug-Visualisierung
der Touch-Inputs (tap zones, drag
paths, multi-touch).

**Definition-of-Done**:
- **`scenes/debug/TouchVisualizer.tscn`** +
  `src/debug/touch_visualizer.gd`:
  - visualisiert aktive touch-
    punkte als farbige Kreise
  - loggt drag-paths als Linien
  - zentriert: Bottom-Center-
    zone für step-button ist
    farbig markiert
- **Optional**: kann via
  `PlayableShellUI._input()`
  integriert werden (entkommentiert
  für dev-mode).

## Out of scope (M9)

- **Echter Multiplayer-Test** — out
  of scope (kein Multiplayer-Network
  in CI, keine 2+ Spieler in
  headless-mode).
- **Voice-Chat** — out of scope
  (WebRTC oder Drittanbieter).
- **Cloud-Lobby** — out of scope
  (dedicated server erforderlich).
- **Anti-Cheat** — out of scope
  (lockstep + determinism ist
  bereits ein guter start).
- **Mobile-Sound-Design** — bleibt
  out-of-scope (per ADR-0020).

## Consequences

### Positive

- M9 legt die Grundlage für
  Co-op ohne den vollen Modus zu
  bauen.
- Hot-Reload beschleunigt Mod-
  Entwicklung.
- Balance-Iteration ermöglicht
  A/B-Tests ohne sim-restart.
- Touch-Visualizer hilft beim
  M8-Polish.

### Negative / Tradeoffs

- Co-op-Protokoll ist headless-
  only getestet (kein echter
  Multiplayer-Test).
- Hot-Reload kann sim-state
  korrumpieren (deshalb tests).
- Balance-Iteration braucht
  Telemetrie (out-of-scope M9).

## Validation (per Bucket)

- **Quality gate**: `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 291 + 24-30 neue
  Tests = 320+ Tests, 1750+ Asserts
- **Mutation sweep**: M9 mutations
  (5+ je Bucket)
- **Determinism check** (Bucket 1):
  2 seeds × 100 ticks ergeben
  identische hashes

## Prio-Order

1. **Bucket 1 (Co-op Protocol)** —
   high leverage (Multiplayer-
   Grundlage).
2. **Bucket 4 (Balance Iteration)** —
   high impact (gameplay-tuning).
3. **Bucket 3 (Mod Hot-Reload)** —
   medium impact (mod-ecosystem).
4. **Bucket 2 (Lobby)** — preparation
   (kein echter netzwerk-test).
5. **Side-Quest F (Touch
   Visualizer)** — dev-tooling.

## References

- ADR-0020 — M8-iPadOS-and-Mobile
- ADR-0019 — M7-Content-and-Balance
- ADR-0017 — M5-Closeout (events)
- ADR-0015 — M5-Foundation
- Godot MultiplayerAPI:
  https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- Godot ENetMultiplayerPeer:
  https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html
- Lockstep networking:
  https://en.wikipedia.org/wiki/Lockstep_protocol
