# Pact & Pit

*Pact & Pit — An Underworld of Terms and Terrors* is an original, open-source, offline-first Godot 4 management and simulation game about building an underground realm through bargains, decrees, limited supernatural intervention, and indirect authority.

## Current status

**M0 Foundation, M1 Playable realm core, M2 Simulation
core, and M3 World and campaign are all complete on
`main`.** The local quality command
(`./tools/run_quality.sh`) is green end-to-end on Godot
4.7+ headless: **100/100 GUT tests** (99 passing + 1
pre-existing skeleton-risky) in ~0.40s / 628 Asserts.
**Minimum supported Godot version: 4.7.**
See [`CHANGELOG.md`](CHANGELOG.md) for the live log of
merged changes, [`docs/roadmap.md`](docs/roadmap.md) for
the M0-M6 status table, and
[`docs/milestones.md`](docs/milestones.md) for the
Definition-of-Done per milestone.

M4 (Knowledge and crisis) and M5-Foundation
(PlayableShell + code-driven PlayableShellUI) are
complete on `main`. **Phase 2.5 (echte UI mit
prozeduralen Assets)** is also complete: 21
prozedural PNGs (Tile-Atlas, UI-Icons, Inhabitant-
Portraits, Crisis-Icons) + TileSet-Resource + UI-Theme
(Gothic-Fantasy Dark) + echte `scenes/main/
PlayableShell.tscn` + Animation-Entry-Points.
**M5-Closeout + M6-Release-Readiness + M7-Content-and-Balance
+ M8-iPadOS-and-Mobile + M9-Co-op-Foundation + M10-Co-op-Live-Mode + M11-Art-Rework + M12-UI-Grafical-Rework + M13-Visual-Polish komplett abgeschlossen**
— alle 34 M5/M6/M7/M8/M9/M10/M11/M12/M13-Buckets + 5 Side-Quests geliefert:
- **M5-Bucket 4 (Success/Failure/Restart)**
- **M5-Bucket 1 (Six Cultures)**: 6 inhabitants,
  7 portrait PNGs
- **M5-Bucket 2 (Ten Rooms)**: 11 tile PNGs,
  4x3 TileSet-Atlas
- **M5-Bucket 3 (Fifteen Events)**: 15 events
  mit weighted random draw
- **M5-Bucket 5 (en/de i18n)**: 36 neue
  Locale-Keys
- **M5-Bucket 6 (Audio)**: 5 SFX + 1 Ambient
- **M6-Bucket 1 (Performance)**: 1.11ms/tick
  (45x headroom gegen 5s target)
- **M6-Bucket 2 (Reproducible Builds)**: Build-
  Script + GitHub Action
- **M6-Bucket 3 (Release Notes)**: hand-written
  + auto-generator
- **M6-Bucket 4 (Accessibility)**: WCAG 2.1 AA
  (Label 9.6:1, Button 9.0:1, hover 7.2:1)
- **M6-Bucket 5 (Licensing/IP)**: 30 PNGs + 6
  WAVs + 2 .tres, alle CC0/GPL, audit PASS
- **M6-Bucket 6 (Known-Issues)**: 3 dokumentierte
  Issues
- **M7-Bucket 1 (Content Expansion)**: 6
  alternative Portraits + 4 neue Tiles + 15
  neue Events (15 tile PNGs, 13 portraits)
- **M7-Bucket 2 (Balance)**: `M7BalanceConfig`
  mit easy/balanced/hard factories
  (45-day win / 6-inhab minimum)
- **M7-Bucket 3 (Mod Interface)**:
  `M5Events.load_from_mods()` +
  `data/mods/example_mod/` +
  `tools/mod_template/`

**444/444 GUT tests / 1942 Asserts** auf Godot 4.7+
headless. Mutation sweeps: M5-Real-UI-Assets 6/6 REAL,
M5-Closeout-Bucket-4 9/9 REAL, M8-iPadOS-and-Mobile 4/4 REAL, M9-Co-op-Foundation 5/5 REAL, M10-Co-op-Live-Mode 5/5 REAL, M11-Art-Rework 5/5 REAL, M12-UI-Grafical-Rework 5/5 REAL, M13-Visual-Polish 5/5 REAL.
Minimum supported Godot
version: 4.7.

**PitPact v0.9.0-m13 ist bereit für die
öffentliche Veröffentlichung.**

Post-M13: Echtes Internet-Co-op (M14+). Die M13 closeout
liefert das Visual-Polish (Idle-Animationen, Particles,
DayNight-Integration, Audio-Reactive Visuals); die
M14 closeout aktiviert echtes Internet-Co-op mit
NAT-Traversal.

## Start here

- Product baseline: [`docs/requirements.md`](docs/requirements.md)
- Milestone plan: [`docs/milestones.md`](docs/milestones.md)
- Repository map: [`docs/repository-structure.md`](docs/repository-structure.md)
- Contributor guidance for agents and humans: [`AGENTS.md`](AGENTS.md)

## Core principles

1. Indirect authority, not click-commanding.
2. Consequences remain legible.
3. Failure teaches at a price.
4. Simulation supports story.
5. Complexity is optional.
6. Privacy and ownership first.
7. Open development is a quality feature.
8. **Best in class.** Every commit on `main` is held to
   the best-in-class bar defined in
   [`AGENTS.md`](AGENTS.md) — architecture-grade,
   test-grade, documentation-grade, local-quality-grade,
   content-grade, audit-grade. A commit that passes the
   automated checks but breaks an ADR, drops a test, or
   drifts a doc is *not* best in class.

## License intent

- Original source code: GPL-3.0-or-later.
- Original art, audio, writing, and data: CC BY-SA 4.0 unless a documented exception is required.

Formal license files and asset provenance records are part of M0 foundation work.
