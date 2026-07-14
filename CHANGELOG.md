# Changelog

> Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
> adapted for a pre-release project. Each release entry lists
> player-facing, developer-facing, and documentation changes.
>
> Until the first public release (M6), this file is the live log of
> merged changes. After M6, a "Release notes" file is generated from
> the entries below and the GitHub Release.

## [Unreleased] — M2 Simulation core in progress

M0 Foundation is **complete**. M1 Playable realm core is
**complete** and the documented local quality command
(`./tools/run_quality.sh`) is green end-to-end, including
**32/32 GUT tests passing in ~0.27s on Godot 4.3 headless**.
See the M1-Closeout entry below for the closeout details.

The next milestone is M2 (Simulation core: inhabitant needs,
contracts, tasks, relationships, memory, event log, resources).
M2-Closeout entries will be added when M2 lands.

### Added (M1-Closeout)

- M1 vertical slice is on `main`. The three parallel tracks
  (Track A spatial, Track B camera+UI, Track C
  content+save+locale) and the architectural foundation
  (ADRs 0002/0003/0004, src/ module stubs, GUT 9.2.1 setup,
  SplitMix64 RNG, expanded run_quality.sh) are merged.
- M1-Closeout local quality: 32/32 GUT tests passing in
  ~0.27s on Godot 4.3 headless, plus format, lint, and
  module-dependency checks all green. The M1 acceptance
  criteria from `docs/milestones.md` — camera/UI shell,
  tile map, zoning, one room lifecycle, local saving,
  diagnostics — are met on the integrated whole.

### Changed (M1-Closeout)

- `tools/run_quality.sh` now prefers GUT 9's own `gut_cmdln.gd`
  CLI over the custom SceneTree runner at
  `tests/_smoke/test_runner.gd`. The custom runner had a
  known issue where GUT's internal `_test_the_scripts` calls
  `get_tree()` on a Node before that Node is attached to the
  SceneTree, which crashes under `--script` mode but works
  fine under the GUT CLI. The custom runner is preserved as
  a fallback and as documentation of intent but is no
  longer the default.
- 11 pre-existing lint issues in M1 source files fixed
  (mechanical: `duplicated-load` caches, `class_name`
  PascalCase for one test variable, `class-definitions-order`
  in `zone_painter.gd`, two `max-returns` refactors in
  `realm.gd` and `tile.gd`).

### Local quality status (M1-Closeout)

- `tools/run_quality.sh` runs end-to-end and is fully green.
  Format check, license-header scan, workflow YAML validation,
  module-dependency check, GUT headless tests, benchmark
  dry-run, and locale validation all pass.
- **GUT test results (headless, Godot 4.3.0 + GUT 9.2.1):**
  7 scripts, 32 tests, 299 asserts, 0 failures, ~0.27s.

## [Unreleased] — M0 Foundation in progress (superseded)

### Added (M0-Closeout, documentation pass)

- [`docs/roadmap.md`](docs/roadmap.md) — live roadmap that
  reflects the M0-Closeout state, the M1 in-progress state, and
  the M2-M6 plan. Replaces the 17-line placeholder.
- [`docs/code-style.md`](docs/code-style.md) — beginner-friendly,
  enforceable GDScript style guide. Covers static typing, file
  size, module headers, docstrings, comment style, the
  no-magic-numbers rule, central configuration, data-driven
  content, localization, error handling, test expectations,
  naming, and the local quality gate. Backed by
  `tools/format.sh`, `tools/lint.sh`, and
  `tools/check_module_dependencies.sh`.
- [`docs/data-schema.md`](docs/data-schema.md) — M0 template for
  content data schemas. Defines the file layout, the `.tres`
  and `.json` conventions, the versioning rules, and the
  RoomData / ResourceCategoryData / BiomeData / OriginData
  schemas. CultureData is reserved for the M5 pass.
- [`docs/localization.md`](docs/localization.md) — M0 template
  for the localization pipeline. Defines `source_strings.csv`
  as the source of truth, naming conventions, placeholder
  rules, pluralization, the concatenation prohibition, and the
  deprecation workflow for removed keys.
- [`tools/README.md`](tools/README.md) — replaces the 3-line
  placeholder with the contributor-facing responsibilities of
  the local quality command, the per-script purpose, and the
  conventions for adding new tools.
- [`assets/README.md`](assets/README.md) — replaces the
  3-line placeholder with the contributor-facing layout,
  inventory rules, and the forbidden-pattern list.
- [`licenses/README.md`](licenses/README.md) — replaces the
  3-line placeholder with the contributor-facing split-license
  summary, third-party inventory rules, and the pre-release
  review workflow.

### Changed (M0-Closeout)

- `assets/README.md` no longer references a not-yet-existing
  `assets/MANIFEST.md`. Until the asset count justifies the
  split, the authoritative inventory is
  `licenses/THIRD-PARTY.md`.
- `src/save/save.gd` and `tests/integration/test_hearth_lifecycle.gd`
  reformatted with `gdformat`. Mechanical, no semantic change.

### Local quality status

- `tools/run_quality.sh` runs end-to-end on the M0-Closeout
  state. Format check, license-header scan, workflow YAML
  validation, and M0 baseline file presence are all green.
- The lint step reports 11 pre-existing issues in M1 source
  files. These are M1-Closeout concerns and are resolved by
  the M1-Closeout entry above.

### Notes

- M0-Closeout is documentation-only plus the two mechanical
  reformat lines. No game mechanics, no scenes, no
  `project.godot`, and no existing requirements were
  modified.

## [Unreleased] — M0 Foundation in progress

### Added

- `LICENSE` (split-license: GPL-3.0-or-later for code, CC BY-SA 4.0
  for art/audio/writing/data) and the corresponding full license
  texts under `licenses/`.
- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1, adapted for the
  satire-vs-harm boundary in §6.2).
- `CONTRIBUTING.md` (workflow, PR rules, AI-assist disclosure,
  review expectations).
- `SECURITY.md` (private disclosure channel, threat model,
  hardening commitments).
- `.gitignore` (Godot 4, Python, IDEs, OS, secrets, build artifacts).
- Godot 4.3 project skeleton: `project.godot`, `icon.svg`, and
  `.gdignore` markers in directories Godot should not scan.
- Single local quality command `tools/run_quality.sh` and the
  `tools/run_benchmark.sh` stub.
- GitHub Actions confirmation suite at
  `.github/workflows/ci.yml`.
- Issue templates for bugs, feature ideas, balance feedback,
  translation, performance, and security/privacy concerns.
- Pull request template at `.github/PULL_REQUEST_TEMPLATE.md`.
- `docs/style-bible.md` (M0 framing; full content lands with M1
  art / M3 audio passes).
- `docs/ip-license-checklist.md` (per §20.3 pre-release review).
- `docs/adrs/0001-record-architecture-decisions.md` (MADR-based
  ADR template).
- `CREDITS.md` (contributor recognition skeleton).
- `archive/README.md` policy.

### Changed

- Removed now-redundant root `.gitkeep` and the
  `licenses/.gitkeep` placeholder now that those directories
  contain real content. Other directory `.gitkeep` files are kept
  in directories that will grow content in M1+ (data, assets,
  locales, scenes, src).

### Fixed

- _None._

### Security

- No security fixes in M0. The first private-vulnerability report
  is expected post-M0; see `SECURITY.md`.

### Notes

- The full Requirements Specification lives in `docs/requirements.md`.
- The milestone plan and the M0 Definition-of-Done live in
  `docs/milestones.md`.
- License posture is split: code is GPL-3.0-or-later; original
  art, audio, writing, and data are CC BY-SA 4.0. Third-party
  material is recorded in `licenses/THIRD-PARTY.md`.

## Earlier

_Repository bootstrapped. The "Initialize repository" commit
established the empty repository; the "Add initial project
documentation structure" PR (codex #1) added the directory
scaffolding, `AGENTS.md`, `README.md`, and the `docs/` skeleton
including the mirrored requirements spec._
