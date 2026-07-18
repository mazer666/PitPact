# PitPact Roadmap

> Status: **live**, best-in-class. The roadmap reflects the
> repository as of the M4-Closeout commit on `main`. The
> next update lands with the M5 closeout. Every closeout
> is held to the best-in-class bar defined in
> [`AGENTS.md`](../AGENTS.md): architecture-grade,
> test-grade, documentation-grade, local-quality-grade,
> content-grade, audit-grade.
>
> See also: [`docs/milestones.md`](milestones.md) for the milestone
> Definition-of-Done, [`docs/requirements.md`](requirements.md) for
> the product requirements this roadmap is derived from, and
> [`CHANGELOG.md`](../CHANGELOG.md) for the live log of merged
> changes.

## Current state

The M0 Foundation milestone is **complete** on `main`. The four
M0-Closeout commits landed:

1. Repository governance (LICENSE, CODE_OF_CONDUCT, CONTRIBUTING,
   .gitignore).
2. Godot 4 project skeleton (project.godot, icon.svg, .gdignore
   markers).
3. CI workflow, issue/PR templates, and the local quality command
   (tools/run_quality.sh).
4. Style bible, IP/license checklist, security policy, changelog,
   and ADR-0001.

The M1 architectural foundation (ADRs 0002/3/4, src/ module stubs,
GUT 9.2.1 setup, expanded run_quality.sh) and the first vertical
slice (Track A spatial, Track B camera+UI, Track C content+save+locale)
are **also on main** as of this writing, but they are part of the
M1 work, not the M0-Closeout. They will be reported in the M1
closeout commit and the corresponding changelog entry.

## M0 → M6 at a glance

The milestone plan in [`docs/milestones.md`](milestones.md) defines
six milestones. Each milestone has a Definition-of-Done that must
hold before the next one opens. The milestones, in order:

| # | Milestone | Status (this roadmap) |
|---|-----------|------------------------|
| M0 | Foundation | **Done** — see [`CHANGELOG.md`](../CHANGELOG.md). |
| M1 | Playable realm core | **Done** — foundation and first vertical slice merged; 32/32 GUT tests passing on Godot 4.7+ headless; the local quality command is green end-to-end. |
| M2 | Simulation core | **Done** — see the M2-Closeout entry in [`CHANGELOG.md`](../CHANGELOG.md); 69/69 GUT tests passing in ~0.42s on Godot 4.7+ headless. |
| M3 | World and campaign | **Done** — see the M3-Closeout entry in [`CHANGELOG.md`](../CHANGELOG.md); 106/106 GUT tests in ~0.63s / 727 Asserts on Godot 4.7+ headless (GUT 9.4.0); constrained 24x24 generator + Marshlands/Highlands + ExplorationMap (fog-of-war) + 4 fixed narrative anchors + 3-node branching-event tree (FirstInspection → accept_audit / counter_offer with `terminal_effect` schema). |
| M4 | Knowledge and crisis | **Done + hardened + audited** — see the M4-Closeout, M4-Hardening, and M0-M3-Audit entries in [`CHANGELOG.md`](../CHANGELOG.md); 172/172 GUT tests in ~0.85s / 966 Asserts on Godot 4.7+ headless (GUT 9.4.0). M4-Hardening: 22/22 mutations REAL (two silent-pass bug fixes: Settings `_init()`, Pactmaker debit-on-success). M0-M3-Audit: 16/16 mutations REAL (M0-M3 carriers are clean). M5-Foundation: PlayableShell factory + PlayableShellUI code-driven controller + 13 new end-to-end tests; 7/7 mutations REAL. |
| M4 | Knowledge and crisis | Research/ritual progression, Pactmaker powers, autonomous conflict, two crises, difficulty/settings. |
| M5 | Vertical campaign completion | Six cultures, ten rooms, fifteen events, complete success/failure/restart loop, English/German, audio pass. **Phase 2.5 (echte UI + prozedurale Assets) abgeschlossen** — 21 prozedurale PNGs (Tiles/UI/Inhabitants/Crises) + TileSet-Resource + UI-Theme + echte `PlayableShell.tscn` + 12 neue Tests; 6/6 PlayableShell-Scene-Mutationen REAL. 184/184 GUT tests, 1007 Asserts. **M5-Closeout Bucket 4 (Success/Failure/Restart) abgeschlossen** — `M5GameState` carrier + Win/Lose conditions + `GameOverBanner` + `_on_restart_pressed()` SEED-bump loop + 18 neue Tests; 9/9 M5-Closeout-Bucket-4-Mutationen REAL. 202/202 GUT tests, 1045 Asserts. **M5-Closeout Bucket 1 (Six Cultures) abgeschlossen** — 6 inhabitants (lanternbearer, bellows, ember, ledger, silvershroud, tide) + 5 neue Portrait-PNGs + `_portrait_path_for_culture()` mapping + 7 neue Tests. 209/209 GUT tests, 1086 Asserts. **M5-Closeout Bucket 2 (Ten Rooms) abgeschlossen** — 4 neue Tile-PNGs (shrine, forge, well, trap) + TileSet-Resource 4x3 (12 Cells) + `WorldGenerator._place_room_tile()` + 6 neue Tests. 215/215 GUT tests, 1104 Asserts. **M5-Closeout Bucket 3 (Fifteen Events) abgeschlossen** — `M5Events` carrier mit 15 Events (5 crisis, 5 good, 5 narrative) + `roll_event(rng)` weighted draw + 7 neue Tests. 222/222 GUT tests, 1251 Asserts. **M5-Closeout Bucket 5 (en/de i18n) abgeschlossen** — 36 neue Locale-Keys in `locales/en.po` + `locales/de.po` (4 rooms + 15 events + 7 game-over + 6 cultures + 4 room-descs) + `M5Events.format_event()` + 7 neue Tests. 229/229 GUT tests, 1496 Asserts. **M5-Closeout Bucket 6 (Audio) abgeschlossen** — 5 SFX + 1 Ambient-Track prozedural generiert (16-bit PCM @ 22050 Hz) + `PlayableShell.tscn` StepSfx AudioStreamPlayer + 7 neue Tests. 236/236 GUT tests, 1566 Asserts. **M5-Closeout komplett abgeschlossen — alle 6 Buckets (4, 1, 2, 3, 5, 6) geliefert.** **M6-Public-Release-Readiness abgeschlossen** — Performance-Benchmark (1.11ms/tick, 45x headroom), Reproducible-Builds Script + GitHub Action, Release-Notes + Generator, Accessibility-Statement + WCAG-AA-Compliance, Licensing/IP-Audit (30 PNGs + 6 WAVs, alle CC0/GPL), Known-Issues-Liste (3 dokumentierte Issues), 15 neue Tests. 251/251 GUT tests, 1591 Asserts. **M7-Content-and-Balance abgeschlossen** — Content-Expansion (6 alternative Portraits + 4 neue Tiles + 15 neue Events = 25 neue Assets), Balance-Pass (`M7BalanceConfig` mit easy/balanced/hard factories, 45-day win / 6-inhab minimum), Mod-Interface (`M5Events.load_from_mods()` + `tools/mod_template/` + `data/mods/example_mod/`), 22 neue Tests. 273/273 GUT tests, 1652 Asserts. ADR-0019 dokumentiert die 3 M7-Buckets. |
| M6 | Public release readiness | Performance target, accessibility review, licensing/IP audit, reproducible builds, release notes, known-issues list. |
| M8 | iPadOS & mobile UI | Touch Input (`_input()` handler + `InputMap` setup), Mobile UI Reflow (touch-friendly Button min sizes, anchor tests), iOS Export Preset (`tools/build/build_ios.sh` + `docs/ipados-deployment.md`). 18 neue Tests, 4/4 M8-Mutationen REAL. 291/291 GUT tests, 1678 Asserts. ADR-0020 dokumentiert die 3 M8-Buckets. |
| M9 | Co-op Foundation | Co-op Protocol (FNV-1a 64-bit hash, diff/apply roundtrip), Lobby (peer 2-4), Mod Hot-Reload (`M5Events.hot_reload_mod` + `unload_mod`), Balance Iteration (`M7BalanceConfig.apply_patch` + `BalancePatchLog`), Touch Visualizer (side-quest F). 42 neue Tests, 5/5 M9-Mutationen REAL. 333/333 GUT tests, 1741 Asserts. ADR-0021 dokumentiert die 4 M9-Buckets + Side-Quest F. |
| M10 | Co-op Live Mode | ENet Adapter (headless loopback), Peer Sync (lockstep state hashes), Replay Recorder (JSON-lines format), Network Stats (RTT + packet loss, side-quest G). 34 neue Tests, 5/5 M10-Mutationen REAL. 367/367 GUT tests, 1791 Asserts. ADR-0022 dokumentiert die 3 M10-Buckets + Side-Quest G. |
| M11 | Art Rework | AI-Art (18 assets, CC0 via mavis image_synthesize), Procedural Upgrade (Perlin-noise + hue-shifts), Shader Pipeline (post_process.gdshader mit Bloom/Vignette/Color-Grade), TimeOfDay (4 phases), Perf Budget (60 FPS auf 4-year-old laptop). 25 neue Tests, 5/5 M11-Mutationen REAL. 392/392 GUT tests, 1867 Asserts. ADR-0023 dokumentiert die 3 M11-Buckets + Side-Quest H. |
| M12 | UI Grafical Rework | AI-driven .tscn scenes (PlayableShell, CrisisBanner, GameOverBanner, VictoryBanner, TitleScreen) — alle mit AI-generierten Gothic-Watercolor-Texturen. Theme v2 mit 4 Button-States (normal/hover/pressed/disabled) + animated transitions (60 FPS, 9 frames per tween). Title-Screen fade-in 1.5s. 15 neue Tests, 5/5 M12-Mutationen REAL. 407/407 GUT tests, 1888 Asserts. ADR-0024 dokumentiert die 3 M12-Buckets + Side-Quest I. |

Post-release work (balancing, additional content, mod/content
interfaces, eventual co-op) is out of scope for
M0-M11 and tracked separately.

## What "done" means for M1

The M1 Definition-of-Done is in [`docs/milestones.md`](milestones.md).
At a glance, M1 needs:

- Camera/UI shell, isometric tile map, zoning, one room lifecycle,
  local saving, diagnostics.

M1 is **done** on `main`. The three parallel vertical slices
(spatial, camera+UI, content+save+locale) and the architectural
foundation (ADRs 0002/0003/0004, src/ module stubs, GUT 9.2.1
setup, SplitMix64 RNG, expanded run_quality.sh) are merged. The
local quality command `./tools/run_quality.sh` runs end-to-end
and is fully green: 7 scripts, 32 tests, 299 asserts, 0 failures,
~0.27s. See the M1-Closeout entry in `CHANGELOG.md` for the
detailed status.

## What the M0-Closeout delivers

The M0-Closeout is the smallest, sharpest slice of work that
makes the repository internally consistent and contributor-ready.
Specifically, the M0-Closeout commits:

- Put formal licenses (GPL-3.0-or-later for code, CC BY-SA 4.0 for
  assets) on every file that needs them.
- Documented the contributor and community expectations
  (`CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`).
- Stood up the local quality command
  (`tools/run_quality.sh`) and the GitHub Actions confirmation
  suite, so that "is this build green?" has a single, documented
  answer.
- Wrote the style bible, IP/license checklist, and the first ADR
  (the ADR practice itself), so that future decisions have a
  template.
- Wrote this roadmap and updated the changelog so that a new
  contributor can answer "where is the project right now?" from
  the repo alone.

## What the M0-Closeout does not deliver

M0-Closeout is **not** a release. It is the launch pad for M1.
Specifically, the M0-Closeout does not include:

- Working gameplay. M1 and later milestones add gameplay.
- Performance benchmarks. M6 adds them.
- A polished style bible. The M0 style bible is a framing document;
  the full palette, silhouette rules, and sound motifs land with
  the M1 art pass and the M3 audio pass.
- Translations. English is the only complete source language at M0.
  German is the first additional language and is added at M5.

These are not gaps; they are the explicit scope of the milestone
plan.

## How this roadmap evolves

- M0 is done. M1 is done. M2 is done. The M3-Closeout commit
  will add a new section here that reflects the M3 state.
- Each milestone closeout adds a section below; the older sections
  stay as historical record.
- Architectural changes to the milestone plan itself (e.g. adding
  a milestone, splitting one) require an ADR in
  [`docs/adrs/`](adrs/README.md).

## See also

- [`docs/milestones.md`](milestones.md) — the milestone plan and
  Definitions-of-Done.
- [`docs/requirements.md`](requirements.md) — the product
  requirements this roadmap is derived from.
- [`docs/repository-structure.md`](repository-structure.md) — the
  directory map.
- [`CHANGELOG.md`](../CHANGELOG.md) — the live log of merged
  changes.
