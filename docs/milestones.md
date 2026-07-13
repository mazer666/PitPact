# Milestones

| Milestone | Definition of done |
|---|---|
| M0: Foundation | Repository governance, licenses, `AGENTS.md`, style rules, Godot project, local quality command, CI-minimum, documentation skeleton. |
| M1: Playable realm core | Camera/UI shell, tile map, zoning, one room lifecycle, local saving, diagnostics. |
| M2: Simulation core | Inhabitant needs, contracts, tasks, relationships/memory foundation, resources, event log, tests. |
| M3: World and campaign | Constrained generator, two biomes, exploration, fixed narrative anchors, branching events. |
| M4: Knowledge and crisis | Research/ritual progression, Pactmaker powers, autonomous conflict, two crises, difficulty/settings. |
| M5: Vertical campaign completion | Six cultures, ten rooms, fifteen events, complete success/failure/restart loop, English/German, audio pass. |
| M6: Public release readiness | Performance target, accessibility review, licensing/IP audit, reproducible builds, release notes, known-issues list. |
| Post-release | Balancing, additional content, mod/content interfaces, and later iPadOS preparation; co-op only after the single-player architecture is stable. |

## Recommended immediate M0 sequence

1. Add formal license files for GPL-3.0-or-later and CC BY-SA 4.0.
2. Create contribution, code of conduct, security, changelog, and roadmap documents.
3. Initialize the Godot 4 project.
4. Add the first local quality command in `tools/`.
5. Define ADR, style-bible, asset-manifest, localization, and data-schema templates.
