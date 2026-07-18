# ADR-0019 — M7: Content & Balance

- Status: Accepted
- Date: 2026-01
- Authors: PitPact contributors
- Phase: M7 (post-release content & balance)
- Supersedes: none
- Related: ADR-0017 (M5-Closeout), ADR-0018 (M6-Release), docs/roadmap.md

## Context

M5-Closeout (ADR-0017) lieferte die kanonische
Inhaltsmenge: 6 Kulturen, 10 Räume, 15 Events,
Win/Lose, en/de, Audio. M6-Release-Readiness
(ADR-0018) lieferte die Härtung: Performance,
Builds, Release-Notes, Accessibility, Licensing,
Known-Issues.

M7 ist die **Post-release** Phase. Per
`docs/roadmap.md`:
> "Post-release work (balancing, additional
> content, mod/content interfaces, iPadOS
> preparation, eventual co-op) is out of scope
> for M0-M6 and tracked separately."

Diese ADR pinnt den M7-Scope *testbar*. Zwei
Buckets sind in scope (content + balance +
mod-interface), drei sind out-of-scope (iPadOS,
co-op, real-money-shop).

## Decision

M7 wird in **drei orthogonalen Buckets** geliefert.
Jeder Bucket hat eine Definition-of-Done mit
*testbaren* Kriterien (wie bei M0-M6).

### Bucket 1 — Content Expansion

**Goal**: Die kanonische Inhaltsmenge verdoppeln
(2x content). Die Spieler bekommen signifikant
mehr Tiefe ohne Game-Mechanik-Änderungen.

**Definition-of-Done**:
- **6 weitere Portrait-PNGs** für 6 alternative
  Rollen (lanternbearer_pilot, bellows_smoker,
  ember_keeper, ledger_scholar, silvershroud_guard,
  tide_warden) — 2 pro Kultur, total 14 portraits.
- **4 weitere Tile-PNGs** für 4 alternative
  Räume (altar, vault, garden, library).
- **15 weitere Events** (15 crisis + 5 good +
  5 narrative) für insgesamt 30 events.
- **`M5Events.expand_catalogue(new_events)`**:
  factory die das Katalog erweitert (idempotent).
- Tests: `test_m7_content_*.gd` (15+ neue Tests).

### Bucket 2 — Balance Pass

**Goal**: Die Win/Lose-Parameter sind balanciert.
Der Spieler kann das Spiel gewinnen ohne
triviale Strategie (1-3 inhabs + 1 hearth reicht
nicht).

**Definition-of-Done**:
- **`M5BalanceConfig`** carrier mit den M7-balanced
  Werten: WIN_DAYS=45 (vorher 30), LOSE_MIN_INHAB=2
  (vorher 1), Shrine/Forge/Well/Trap jeweils mind. 1.
- **`M5GameState.from_balance(cfg)`** factory
  der eine Game-State mit den balance-Config
  Werten erzeugt.
- Test `test_balance_win_path_is_achievable`:
  30-tick balance-sim → win (deterministisch).
- Test `test_balance_lose_path_is_achievable`:
  fail-to-build-room → lose.

### Bucket 3 — Mod/Content Interface

**Goal**: Drittanbieter-Mods können PitPact-
Inhalte (neue Events, neue Räume, neue Portraits)
ohne Code-Änderung hinzufügen.

**Definition-of-Done**:
- **`data/mods/`** Verzeichnis mit `manifest.json`
  pro mod (id, name, version, author, license,
  content).
- **`M5Events.load_from_mods(dir)`** factory
  die mods aus `data/mods/` lädt und in das
  catalogue appended.
- **`tools/mod_template/`** Verzeichnis mit
  `manifest.json` template + Beispiel-Event.
- Tests: `test_m7_mods_*.gd` (5+ neue Tests).

## Out of scope (M7)

Per `docs/roadmap.md`:

- **iPadOS preparation** — out of scope (M8+).
- **Co-op** — out of scope (M9+).
- **Real-money shop** — explicitly out of scope
  (the project is open-source, offline-first,
  per `docs/requirements.md` §1).
- **Mobile UI rework** — out of scope (M8+).

## Consequences

### Positive

- M7 erweitert die Inhaltsmenge ohne
  Mechanik-Änderungen (geringes Risiko).
- Mod-Interface ermöglicht Community-
  Beiträge ohne Fork.
- Balance-Pass macht das Spiel
  strategisch interessanter.

### Negative / Tradeoffs

- Content-Expansion ist hand-rolled
  (prozedural-generiert via
  `tools/assets/generate_assets.gd`).
- Mod-Interface ist minimal (kein hot-reload,
  keine Mod-Konflikte-Auflösung).
- Balance-Werte sind 1-pass
  (keine A/B-Tests, keine Community-Feedback-
  loops).

## Validation (per Bucket)

- **Quality gate**: `tools/run_quality.sh` →
  ALL CHECKS PASSED ✓
- **GUT headless**: 251 + 25-40 neue Tests =
  280+ Tests, 1800+ Asserts
- **Mutation sweep**: M7 mutations (5+ je Bucket)
- **Content coverage**: 2x mehr content als M6

## Prio-Order

1. **Bucket 3 (Mod Interface)** — high leverage
   (Community-Beiträge).
2. **Bucket 1 (Content Expansion)** — high
   impact (Spieler-Tiefe).
3. **Bucket 2 (Balance Pass)** — important
   (game-feel).

## References

- ADR-0017 — M5-Closeout scope (Vorgänger-Inhalte)
- ADR-0018 — M6-Release-Readiness
- docs/roadmap.md (Post-release backlog)
- docs/requirements.md §1 (offline-first,
  no real-money)
