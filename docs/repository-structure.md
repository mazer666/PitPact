# Repository Structure

This document records the **current** repository layout. The tree
evolves as milestones progress; changes that affect module
boundaries or contributor workflow require an ADR in
`docs/adrs/`.

```text
/
  AGENTS.md                       # Rules for human and AI contributors
  README.md                       # Project entry point
  LICENSE                         # GPL-3.0-or-later (code)
  CHANGELOG.md                    # Live log of merged changes
  RELEASE_NOTES.md                # M6 release notes (v0.2.0-m6)
  KNOWN_ISSUES.md                 # M6 known-issues list
  docs/                           # Architecture, plans, ADRs, style bible
  src/                            # GDScript source by module
  scenes/                         # Godot scenes, with minimal embedded logic
  data/                           # Versioned game-content definitions
  data/mods/                      # M7 mod-content (events.json)
  locales/                        # Translation files (en.po, de.po)
  assets/                         # Original/licensed assets and manifests
  assets/tiles/                   # Procedural tile PNGs + TileSet
  assets/ui/                      # Procedural UI icons
  assets/inhabitants/             # Procedural portrait PNGs
  assets/crises/                  # Procedural crisis icons
  assets/audio/                   # Procedural SFX + ambient WAV
  tests/                          # Unit, integration, and smoke tests
  tools/                          # Build, test, lint, and validation scripts
  tools/audit/                    # Mutation-sweep + license-audit scripts
  tools/assets/                   # Asset + audio generators
  tools/build/                    # Reproducible-build scripts
  tools/benchmarks/               # Performance benchmarks
  tools/mod_template/             # M7 mod-template (manifest + events.json)
  LICENSES/                       # Asset license manifest (M6 Bucket 5)
  archive/                        # Superseded public plans/spec snapshots
```

## Module boundaries (per ADR-0002)

| Module   | May import from           | Forbidden imports |
|----------|---------------------------|-------------------|
| `core/`  | (no other modules)       | `sim`, `world`, `ui`, `realm`, `save`, `audit` |
| `sim/`   | `core`, `content`         | `ui`, `realm`, `save` |
| `world/` | `core`, `content`         | `sim`, `ui`, `realm`, `save` |
| `content/` | `core`                  | `ui`, `realm`, `save`, `audit` |
| `ui/`    | `core`, `sim`, `world`, `content`, `save` | `realm` |
| `save/`  | `core`, `sim`, `world`, `content` | `ui`, `realm` |
| `audit/` | `core`                    | `ui`, `realm`, `save` |

The module-boundary check is automated via
`tools/check_module_dependencies.sh`.

## Directory responsibilities

- **`docs/`** — requirements, architecture notes, milestone
  plans, ADRs, style guidance, IP/license checklists,
  accessibility, and contributor documentation.
- **`src/`** — deterministic game-domain logic and GDScript
  modules. The M0-M5 modules follow ADR-0002 strictly.
- **`scenes/`** — Godot scene files with minimal embedded
  logic. `scenes/main/PlayableShell.tscn` is the canonical
  M5+ scene.
- **`data/`** — versioned data definitions for content such
  as cultures, rooms, events, resources, biomes, research,
  and contracts. **`data/mods/`** is the M7 mod-content
  directory.
- **`locales/`** — source and translated localization files
  (en.po, de.po; M5-Closeout Bucket 5).
- **`assets/`** — procedural art, audio, fonts, and asset
  manifests. All assets are procedurally generated (per
  ADR-0017); the M5-Closeout ships 30 PNGs + 6 WAVs +
  2 .tres.
- **`tests/`** — automated checks for rules, simulation,
  generation, localization, saves, migrations, and
  regressions. 273 tests in M7.
- **`tools/`** — local build, test, lint, validation, and
  benchmark scripts. The M6 closeout ships reproducible
  builds + license-audit.
- **`tools/audit/`** — mutation-sweep scripts
  (`mutation_sweep_*.gd`) and the M6 license-audit script
  (`check_licenses.sh`).
- **`tools/assets/`** — asset + audio generators
  (`generate_assets.gd`, `generate_audio.gd`). SEED-pinned,
  idempotent.
- **`tools/build/`** — reproducible-build scripts
  (`build_release.sh`, `generate_release_notes.sh`).
- **`tools/benchmarks/`** — performance benchmarks
  (`run_perf.gd`).
- **`tools/mod_template/`** — M7 mod-template (manifest +
  sample events.json).
- **`LICENSES/`** — asset license manifest (M6 Bucket 5).
- **`archive/`** — superseded public plans/spec snapshots.

## ADRs (chronological)

| ADR | Title | Phase |
|-----|-------|-------|
| 0001 | M0 Foundation | M0 |
| 0002 | Module boundaries | M0 |
| 0003 | Save body format | M0 |
| 0004 | World coordinate system | M1 |
| 0005 | Determinism contract | M1 |
| 0006 | Save load body | M2 |
| 0007 | M3-Closeout generator | M3 |
| 0008 | M3-Closeout track B | M3 |
| 0009 | M3-Closeout track A | M3 |
| 0010 | M3-Closeout closeout | M3 |
| 0011 | M4-Closeout | M4 |
| 0012 | M4-Closeout | M4 |
| 0013 | M4-Hardening | M4 |
| 0014 | M0-M3-Audit | M4 |
| 0015 | M5-Foundation | M5 |
| 0016 | M5-Real-UI-Assets | M5 |
| 0017 | M5-Closeout | M5 |
| 0018 | M6-Release-Readiness | M6 |
| 0019 | M7-Content-and-Balance | M7 |
| 0020 | M8-iPadOS-and-Mobile | M8 |
| 0021 | M9-Co-op-Foundation | M9 |
| 0022 | M10-Co-op-Live-Mode | M10 |
| 0023 | M11-Art-Rework | M11 |
| 0024 | M12-UI-Grafical-Rework | M12 |
| 0025 | M13-Visual-Polish | M13 |
| 0026 | M14-Engine-Perf-Content | M14 |

## Test count progression

| Phase | Tests | Asserts |
|-------|-------|---------|
| M0 | 0 | 0 |
| M1-Closeout | 32 | 200 |
| M2-Closeout | 69 | 380 |
| M3-Foundation | 84 | 480 |
| M3-Closeout | 100 | 600 |
| M3-Hardening | 106 | 700 |
| M4-Foundation | 125 | 800 |
| M4-Closeout | 149 | 900 |
| M4-Hardening | 159 | 950 |
| M0-M3-Audit | 159 | 950 |
| M5-Foundation | 172 | 966 |
| M5-Real-UI-Assets | 184 | 1007 |
| M5-Closeout-Bucket-4 | 202 | 1045 |
| M5-Closeout-Bucket-1 | 209 | 1086 |
| M5-Closeout-Bucket-2 | 215 | 1104 |
| M5-Closeout-Bucket-3 | 222 | 1251 |
| M5-Closeout-Bucket-5 | 229 | 1496 |
| M5-Closeout-Bucket-6 | 236 | 1566 |
| M6-Release-Readiness | 251 | 1591 |
| M7-Content-and-Balance | 273 | 1652 |
| M8-iPadOS-and-Mobile | 291 | 1678 |
| M9-Co-op-Foundation | 333 | 1741 |
| M10-Co-op-Live-Mode | 367 | 1791 |
| M11-Art-Rework | 392 | 1867 |
| M12-UI-Grafical-Rework | 407 | 1888 |
| M13-Visual-Polish | 444 | 1942 |
| M14-Engine-Perf-Content | 492 | 2016 |

## References

- `AGENTS.md` — contributor guidance
- `docs/roadmap.md` — milestone status
- `docs/milestones.md` — milestone Definition-of-Done
- `docs/style-bible.md` — Gothic-Fantasy Dark palette
- `docs/accessibility.md` — M6 WCAG 2.1 AA standard
- `LICENSES/asset-manifest.md` — asset license manifest
- `KNOWN_ISSUES.md` — M6 known issues
- `RELEASE_NOTES.md` — M6 v0.2.0-m6 release notes
