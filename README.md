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
**M5-Closeout Bucket 4 (Success/Failure/Restart)**,
**Bucket 1 (Six Cultures)**, **Bucket 2 (Ten Rooms)**,
**Bucket 3 (Fifteen Events)**, and **Bucket 5 (en/de
i18n)** are complete: `M5GameState` carrier + Win/
Lose conditions + `GameOverBanner` + 6 cultures
(lanternbearer, bellows, ember, ledger, silvershroud,
tide) + 10 rooms (floor_stone/marsh/highland, wall,
hearth, fog, shrine, forge, well, trap) + 15 events
(5 crisis, 5 good, 5 narrative) + 36 Locale-Keys in
`locales/en.po` + `locales/de.po` + `M5Events.format_event()`
+ `tr()` integration. **229/229 GUT tests / 1496
Asserts** auf Godot 4.7+ headless. Mutation sweeps:
M5-Real-UI-Assets 6/6 REAL, M5-Closeout-Bucket-4 9/9
REAL. Minimum supported Godot version: 4.7.

The next milestone is M5-Closeout-Bucket-6 (Audio),
per ADR-0017 — kann auf M6 deferred werden wenn
Zeit knapp ist.

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
