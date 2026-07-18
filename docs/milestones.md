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
| M7: Content and balance | Additional content (2x), balance pass (45-day win / 6-inhabitant minimum), mod/content interface. |
| M8: iPadOS & mobile UI | Touch input, mobile UI reflow, iOS export preset. |
| Post-release | Balancing, additional content, mod/content interfaces, and later iPadOS preparation; co-op only after the single-player architecture is stable. |

## M5-Closeout sub-buckets (per ADR-0017)

| Bucket | Title | Status |
|---|---|---|
| 4 | Success/Failure/Restart | ✅ done (commit 4d206a0) |
| 1 | Six Cultures | ✅ done (commit 8763bfc) |
| 2 | Ten Rooms | ✅ done (commit e9dfadb) |
| 3 | Fifteen Events | ✅ done (commit 59ae945) |
| 5 | English/German i18n | ✅ done (commit 53e8dc7) |
| 6 | Audio | ✅ done (commit 7c2ca25) |

## M6-Release-Readiness sub-buckets (per ADR-0018)

| Bucket | Title | Status |
|---|---|---|
| 1 | Performance | ✅ done (1.11ms/tick, 45x headroom) |
| 2 | Reproducible Builds | ✅ done |
| 3 | Release Notes | ✅ done |
| 4 | Accessibility | ✅ done (WCAG 2.1 AA) |
| 5 | Licensing/IP Audit | ✅ done (audit PASS) |
| 6 | Known-Issues | ✅ done (3 documented issues) |

## M7-Content-and-Balance sub-buckets (per ADR-0019)

| Bucket | Title | Status |
|---|---|---|
| 1 | Content Expansion | ✅ done (6 portraits + 4 tiles + 15 events) |
| 2 | Balance Pass | ✅ done (45-day / 6-inhabitant minimum) |
| 3 | Mod/Content Interface | ✅ done (data/mods/ + tools/mod_template/) |

## M8-iPadOS-and-Mobile sub-buckets (per ADR-0020)

| Bucket | Title | Status |
|---|---|---|
| 1 | Touch Input | ✅ done (`_input()` + `InputMap` setup + 7 tests) |
| 2 | Mobile UI Reflow | ✅ done (touch-friendly min sizes + 6 tests) |
| 3 | iOS Export Preset | ✅ done (`tools/build/build_ios.sh` + `docs/ipados-deployment.md` + 5 tests) |

## Out of scope

- **Co-op** — M9+
- **Real-money shop** — explicitly out of scope (the
  project is open-source, offline-first, per
  `docs/requirements.md` §1)

## Recommended immediate M0 sequence

1. Add formal license files for GPL-3.0-or-later and CC BY-SA 4.0.
2. Create contribution, code of conduct, security, changelog, and roadmap documents.
3. Initialize the Godot 4 project.
4. Add the first local quality command in `tools/`.
5. Define ADR, style-bible, asset-manifest, localization, and data-schema templates.
