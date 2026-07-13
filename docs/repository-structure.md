# Repository Structure

This document records the initial M0 repository layout. The tree may evolve, but changes that affect module boundaries or contributor workflow require an ADR in `docs/adrs/`.

```text
/
  AGENTS.md                 # Rules for human and AI contributors
  README.md                 # Project entry point
  docs/                     # Architecture, plans, ADRs, guides, style bible
  src/                      # GDScript source by module
  scenes/                   # Godot scenes, with minimal embedded logic
  data/                     # Versioned game-content definitions
  locales/                  # Translation files
  assets/                   # Original/licensed assets and manifests
  tests/                    # Unit, integration, generator, and migration tests
  tools/                    # Local build, test, lint, and validation scripts
  benchmarks/               # Reproducible performance scenarios/results
  licenses/                 # Third-party and asset provenance records
  archive/                  # Superseded public plans/spec snapshots where useful
```

## Directory responsibilities

- `docs/`: requirements, architecture notes, milestone plans, ADRs, style guidance, IP/license checklists, and contributor documentation.
- `src/`: deterministic game-domain logic and GDScript modules.
- `scenes/`: Godot scene files with minimal embedded logic.
- `data/`: versioned data definitions for content such as cultures, rooms, events, resources, biomes, research, and contracts.
- `locales/`: source and translated localization files.
- `assets/`: art, audio, fonts, placeholder manifests, and asset provenance references.
- `tests/`: automated checks for rules, simulation, generation, localization, saves, migrations, and regressions.
- `tools/`: local developer commands for formatting, linting, validation, tests, exports, and release checks.
- `benchmarks/`: reproducible performance scenarios and recorded benchmark results.
- `licenses/`: license texts, third-party notices, and attribution records.
- `archive/`: intentionally retained superseded public documents.
