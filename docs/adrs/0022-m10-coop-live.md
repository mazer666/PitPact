# ADR-0022 — M10: Co-op Live Mode

- Status: Accepted
- Date: 2026-07
- Authors: PitPact contributors
- Phase: M10 (Co-op Live Mode)
- Supersedes: none (extends ADR-0021)
- Related: ADR-0021 (M9), ADR-0020 (M8), docs/roadmap.md

## Context

M9-Co-op-Foundation (ADR-0021)
lieferte die Co-op-Grundlage
(lockstep-Protokoll, Lobby,
Mod-Hot-Reload, Balance-
Iteration, Touch-Visualizer).
M10 ist der **echte Co-op-
Modus** mit ENet-Adapter und
Real-Multiplayer-Test.

Per `docs/roadmap.md` Post-
release backlog:
> "Co-op only after the single-
> player architecture is stable."

Diese ADR pinnt den M10-Scope
*testbar* in **3 orthogonalen
Buckets** (ENet-Adapter,
Peer-Sync, Replay-Recording).
Jeder Bucket hat testbare
Kriterien (wie M0-M9).

## Decision

M10 wird in **3 orthogonalen
Buckets** geliefert, plus einer
**Side-Quest (G)**:

### Bucket 1 — ENet Adapter

**Goal**: Eine echte ENet-
basierte Netzwerk-Schicht
für PitPact-Coop.

**Definition-of-Done**:
- **`EnetAdapter` carrier**
  (`src/net/enet_adapter.gd`):
  - `static func version() -> String`
    → `"0.6.0-m10-coop-live"`
  - `static func make_host(port: int, max_clients: int) -> EnetAdapter`
  - `static func make_client(host: String, port: int) -> EnetAdapter`
  - `func poll() -> Array` — returns
    pending events (connect, disconnect,
    receive)
  - `func send(peer_id: int, data: Dictionary) -> int`
  - `func close() -> void`
  - `func is_host() -> bool`
  - `func is_connected() -> bool`
  - `func peer_count() -> int`
- **Headless-Loopback-Tests**:
  2 Adapter im selben Prozess,
  einer hostet, der andere
  joint → tests verifizieren
  den Datenfluss.
- **Tests**: 8+ tests
  (lifecycle, send/receive
  roundtrip, disconnect,
  peer count).

### Bucket 2 — Peer Sync

**Goal**: Echtzeit-Sync der
sim-states zwischen 2-4
Peers via lockstep.

**Definition-of-Done**:
- **`PeerSync` carrier**
  (`src/net/peer_sync.gd`):
  - `static func version() -> String`
    → `"0.6.0-m10-coop-live"`
  - `static func make(adapter: EnetAdapter, tick_rate_ms: int) -> PeerSync`
  - `func tick(local_state: Dictionary) -> Array`
    → broadcasts the local state's
    hash + receives remote states,
    returns a list of (peer_id,
    state_hash) tuples
  - `func peers_in_sync() -> bool`
  - `func desync_count() -> int`
  - `func last_remote_state(peer_id: int) -> Dictionary`
- **Loopback-Test**: 2 PeerSync
  Instanzen, 100 ticks, alle
  hashes identisch.
- **Tests**: 6+ tests (sync
  lifecycle, hash broadcast,
  desync detection, recovery).

### Bucket 3 — Replay Recording

**Goal**: Aufnahme + Replay
von coop-sessions für
debugging + post-mortem.

**Definition-of-Done**:
- **`ReplayRecorder` carrier**
  (`src/net/replay_recorder.gd`):
  - `static func version() -> String`
    → `"0.6.0-m10-coop-live"`
  - `static func make(path: String) -> ReplayRecorder`
  - `func record_event(tick: int, peer_id: int, event: Dictionary) -> int`
  - `func events() -> Array`
  - `func event_count() -> int`
  - `func save() -> int` — write
    to disk (`.replay` file)
  - `static func load(path: String) -> ReplayRecorder`
- **Format**: JSON-lines
  (one event per line,
  human-readable, debuggable).
- **Tests**: 6+ tests (record,
  save, load, event_count,
  format).

### Side-Quest G — Network Stats

**Goal**: Live-Statistiken
über den Co-op-Network-State
(RTT, packet loss, sync-
quality).

**Definition-of-Done**:
- **`NetworkStats` carrier**
  (`src/net/network_stats.gd`):
  - `static func version() -> String`
  - `func record_rtt(peer_id: int, rtt_ms: int) -> void`
  - `func average_rtt(peer_id: int) -> int`
  - `func record_packet_loss(peer_id: int, lost: int, sent: int) -> void`
  - `func packet_loss_rate(peer_id: int) -> float`
- **Tests**: 5+ tests (RTT
  average, packet loss rate,
  per-peer tracking).

## Out of scope (M10)

- **Voice-Chat** — out of scope
  (WebRTC erforderlich; M11+).
- **Cloud-Lobby** — out of scope
  (dedicated server; M11+).
- **Anti-Cheat** — out of scope
  (lockstep + determinism ist
  bereits ein guter start;
  M12+).
- **Cross-Platform-Network**
  (z.B. WebSocket-Fallback für
  HTML5) — out of scope (M11+).
- **NAT-Traversal** (hole
  punching) — out of scope
  (STUN/TURN erforderlich;
  M12+).
- **Mobile-Sound-Design** —
  bleibt out-of-scope (per
  ADR-0020).

## Consequences

### Positive

- M10 liefert den ersten
  echten Multiplayer-Modus
  (ENet-basiert, headless-
  testbar).
- Replay-Recording ermöglicht
  Post-Mortem-Debugging.
- Network-Stats helfen beim
  Performance-Tuning.

### Negative / Tradeoffs

- Echte Multiplayer-Tests
  nur loopback (kein
  internet, keine NAT).
- ENet ist UDP-basiert —
  Paketverlust möglich
  (durch Network-Stats
  dokumentiert).
- Replay-Format ist nicht
  versioniert (M11 closeout
  kann version-tag hinzufügen).

## Validation (per Bucket)

- **Quality gate**: `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 333 + 25-30
  neue Tests = 360+ Tests,
  1800+ Asserts
- **Mutation sweep**: M10
  mutations (5+ je Bucket)
- **Loopback-Test**: 2
  EnetAdapter im selben
  Prozess, 100 ticks, alle
  hashes identisch

## Prio-Order

1. **Bucket 1 (ENet Adapter)** —
   high leverage (echtes
   networking).
2. **Bucket 3 (Replay)** —
   high impact (debugging).
3. **Bucket 2 (Peer Sync)** —
   medium impact (lockstep
   already from M9).
4. **Side-Quest G (Network
   Stats)** — dev-tooling.

## References

- ADR-0021 — M9-Co-op-Foundation
- ADR-0020 — M8-iPadOS-and-Mobile
- Godot ENetMultiplayerPeer:
  https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html
- Godot MultiplayerAPI:
  https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- ENet (the library):
  http://enet.bespin.org/
- Lockstep networking:
  https://en.wikipedia.org/wiki/Lockstep_protocol
