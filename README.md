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
**M5-Closeout komplett abgeschlossen** — alle 6
Buckets geliefert:
- **Bucket 4 (Success/Failure/Restart)**:
  `M5GameState` carrier + Win/Lose conditions +
  `GameOverBanner` + Restart-SEED-bump loop.
- **Bucket 1 (Six Cultures)**: 6 inhabitants
  (lanternbearer, bellows, ember, ledger, silvershroud,
  tide) + 7 portrait PNGs.
- **Bucket 2 (Ten Rooms)**: 11 tile PNGs (floor_stone/
  marsh/highland, wall, hearth, fog, shrine, forge,
  well, trap) + 4x3 TileSet-Atlas.
- **Bucket 3 (Fifteen Events)**: `M5Events` carrier mit
  15 events (5 crisis, 5 good, 5 narrative) +
  `roll_event(rng)` weighted draw.
- **Bucket 5 (en/de i18n)**: 36 neue Locale-Keys in
  `locales/en.po` + `locales/de.po` + `M5Events.format_event()`.
- **Bucket 6 (Audio)**: 5 SFX + 1 Ambient-Track
  prozedural generiert (16-bit PCM @ 22050 Hz) +
  `StepSfx` AudioStreamPlayer in `PlayableShell.tscn`.

**236/236 GUT tests / 1566 Asserts** auf Godot 4.7+
headless. Mutation sweeps: M5-Real-UI-Assets 6/6 REAL,
M5-Closeout-Bucket-4 9/9 REAL. Minimum supported Godot
version: 4.7.

The next milestone is **M6 (Public release readiness)**
— performance target, accessibility review, licensing/IP
audit, reproducible builds, release notes, known-issues
list.

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
