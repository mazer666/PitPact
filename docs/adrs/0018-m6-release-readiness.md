# ADR-0018 — M6: Public Release Readiness

- Status: Accepted
- Date: 2026-01
- Authors: PitPact contributors
- Phase: M6 (public release readiness)
- Supersedes: none
- Related: ADR-0001 (M0 Foundation), ADR-0017 (M5-Closeout scope), docs/roadmap.md

## Context

M5-Closeout (ADR-0017) lieferte alle 6 Inhalts-Buckets:
Six Cultures, Ten Rooms, Fifteen Events, Success/Failure/
Restart, en/de i18n, Audio. Das Spiel ist **funktional
komplett** — 236/236 GUT tests passing, 1566 Asserts, ALL
CHECKS PASSED. Was fehlt für eine **öffentliche
Veröffentlichung** ist die M6-Hardening-Phase.

`docs/roadmap.md` und `docs/milestones.md` listen M6 als
"Public release readiness" mit 6 sub-buckets: Performance
target, Accessibility review, Licensing/IP audit,
Reproducible builds, Release notes, Known-issues list. Diese
ADR pinnt den scope *testbar*.

## Decision

M6 wird in **sechs orthogonalen Buckets** geliefert. Jeder
Bucket hat eine Definition-of-Done mit *testbaren* Kriterien
(wie bei M0-M5). Die Buckets sind nach Leverage sortiert:
erst Performance (das hat den größten impact auf Player-
Experience), dann Reproducible Builds (CI/Sign), dann
Release-Notes/Docs, dann Accessibility/Licensing/Known-Issues.

### Bucket 1 — Performance Target

**Goal**: dokumentieren + messen + enforcen, dass das Spiel
mit 60 FPS auf einem M2-Mac läuft (per `docs/requirements.md`).

**Definition-of-Done**:
- `docs/performance.md` dokumentiert den M6-Performance-
  Target (60 FPS @ 24x24 grid, 6 cultures, 15 events).
- `tools/benchmarks/run_perf.gd` script misst die Frame-
  Time für 100 sim-ticks + 6 ui-renders.
- Test `test_performance_target` in `tools/benchmarks/`:
  Pinned Threshold: 100 sim-ticks < 5 sec (headless).
- Performance-Regression in CHANGELOG dokumentiert.

### Bucket 2 — Reproducible Builds

**Goal**: Ein Git-Tag (z.B. `v0.2.0-m6`) muss byte-identische
builds produzieren, deterministisch.

**Definition-of-Done**:
- `tools/build/build_release.sh`: script das einen
  Release-Build erzeugt (Godot-Export auf Linux/Mac/Win).
- `docs/build-reproducibility.md`: dokumentiert das
  Build-Verfahren + die Determinism-Garantien.
- `tools/build/verify_checksums.gd`: vergleicht zwei
  Builds und meldet ob sie byte-identisch sind.
- GitHub Action `.github/workflows/build.yml` das den
  Build auf jedem Tag triggert.

### Bucket 3 — Release Notes

**Goal**: Die Release-Notes (für GitHub Release + Webseite)
sind strukturiert + vollständig + aus dem CHANGELOG ableitbar.

**Definition-of-Done**:
- `RELEASE_NOTES.md` (M6) — von Hand geschrieben, mit
  Highlights + Bug-Fixes + Breaking-Changes.
- `tools/build/generate_release_notes.sh`: script das
  aus CHANGELOG.md einen Release-Notes-Draft generiert.
- GitHub Action `.github/workflows/release.yml` das auf
  Tag-Push einen GitHub-Release erstellt mit den Notes.

### Bucket 4 — Accessibility Review

**Goal**: Das Spiel ist keyboard-navigierbar, hat sichtbaren
Focus, ausreichende Color-Contrast.

**Definition-of-Done**:
- `docs/accessibility.md`: dokumentiert den M6-Standard
  (WCAG 2.1 AA-konform für UI-Contrast, full-keyboard-
  navigation, screen-reader friendly via `tr()`).
- `gothic_fantasy_theme.tres` updated: Color-Contrast
  mind. 4.5:1 (WCAG AA) für alle Text-Foregrounds.
- `PlayableShellUI` Tab-Order: Top → Inhabitants → Pactmaker
  → Tick (logical order).

### Bucket 5 — Licensing/IP Audit

**Goal**: Alle Assets und Code-Teile sind sauber lizenziert.

**Definition-of-Done**:
- `licenses/`-Verzeichnis mit per-Asset-Records.
- `tools/audit/check_licenses.sh`: assertet dass alle
  prozedural generierten PNGs/WAVs keine externen IP
  enthalten.
- `docs/ip-license-checklist.md` updated mit M6-Status.

### Bucket 6 — Known-Issues List

**Goal**: Spieler + Maintainer wissen, was im aktuellen
Release kaputt ist.

**Definition-of-Done**:
- `KNOWN_ISSUES.md` (M6) — gepflegt, mit Workarounds.
- `tools/audit/check_known_issues.gd`: prüft ob alle
  offenen Issues einen Status haben.

## Consequences

### Positive

- M6 ist *konkret* testbar (kein moving target).
- 6 Buckets sind unabhängig: ein Coder pro Bucket.
- Best-in-Class bleibt enforced: jeder Bucket hat DoD.

### Negative / Tradeoffs

- Performance-Targets sind per-Platform unterschiedlich;
  der M6-Target ist "60 FPS @ M2 Mac" (per requirements).
- Reproducible Builds erfordern deterministische Build-
  Pipeline (kein "make install" in der CI).
- Accessibility-Audit ist manuell (per Asset); M6 kann
  nur die automatisierten Checks garantieren.

## Validation (per Bucket)

- **Quality gate**: `tools/run_quality.sh` → ALL CHECKS PASSED ✓
- **GUT headless**: 236 + 15-30 neue Tests = 250+ Tests
- **Mutation sweep**: M6 mutations (5+ je Bucket)
- **Build**: `tools/build/build_release.sh` exit 0
- **Performance**: < 5 sec für 100 sim-ticks

## Prio-Order

1. **Bucket 2 (Reproducible Builds)** — high impact (CI/CD)
2. **Bucket 3 (Release Notes)** — needed for v0.2.0-m6
3. **Bucket 1 (Performance)** — measured + documented
4. **Bucket 5 (Licensing/IP Audit)** — compliance
5. **Bucket 4 (Accessibility)** — keyboard + contrast
6. **Bucket 6 (Known-Issues List)** — last polish

## References

- ADR-0017 — M5-Closeout scope (Vorgänger-Phase)
- ADR-0001 — M0 Foundation
- docs/requirements.md §18 (CI), §20 (IP/Licensing)
- docs/roadmap.md (M6 status)
- docs/milestones.md (M6 Definition-of-Done)
- docs/style-bible.md (Theme/Contrast)
