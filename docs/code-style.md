# PitPact Code Style Guide (GDScript)

> Status: **M0 baseline**, enforceable from the first commit. The
> rules below are short, opinionated, and chosen to keep the
> codebase readable for new contributors and AI-assisted agents
> alike. They are enforced by `tools/format.sh` (gdformat),
> `tools/lint.sh` (gdlint), and `tools/check_module_dependencies.sh`
> in the local quality suite; see
> [`docs/roadmap.md`](roadmap.md) for the suite.
>
> When a rule feels wrong, open an issue. Don't silently break it.
>
> **Best-in-class bar.** Every commit on `main` must clear the
> best-in-class bar defined in [`AGENTS.md`](../AGENTS.md). The
> bar is the union of (a) the architectural rules here and in
> the ADRs, (b) the test rules in the integration tests, and
> (c) the documentation rules in
> [`docs/roadmap.md`](roadmap.md) /
> [`CHANGELOG.md`](../CHANGELOG.md) /
> the module READMEs. A commit that passes `format.sh` /
> `lint.sh` / `check_module_dependencies.sh` but breaks any
> ADR, drops a test, or drifts a doc is *not* best in class
> and the commit is reverted.

## Why this file is short

This guide is a baseline, not a textbook. Detailed GDScript
documentation lives in the Godot manual. The rules here are the
project-specific calls. The companion documents that go deeper:

- [`docs/style-bible.md`](style-bible.md) — tone, palette,
  silhouette, sound motifs, and forbidden reference points.
- [`docs/data-schema.md`](data-schema.md) — how content data is
  shaped and versioned.
- [`docs/localization.md`](localization.md) — how user-visible
  strings are externalized.
- [`docs/requirements.md`](requirements.md) — the why behind the
  product; informs every naming and comment decision.

## 1. Static typing where useful

- Annotate every function signature and every member variable in
  new code. `gdformat` and `gdlint` are configured to flag untyped
  declarations as warnings.
- The exception is `var` declarations whose right-hand side is
  itself a typed literal and where adding the type adds no
  information. Prefer the explicit type anyway; the cost is one
  word and the gain is one fewer mental hop.
- For collections, prefer typed arrays and dictionaries
  (`Array[int]`, `Dictionary[StringName, Variant]`) over
  untyped `Array` and `Dictionary`. The Godot 4.7+ syntax
  `Array[Type]` is the standard.

## 2. Small, focused files

- One class per file. The file name is the class name in
  `snake_case`; the `class_name` declaration in the file is the
  same name in `PascalCase`.
- A file that crosses ~250 lines of executable code is a signal
  to split. The split should follow the module boundaries in
  [`docs/repository-structure.md`](repository-structure.md).
- Tests follow the same rule: one focused test file per
  behaviour, named after the behaviour.

## 3. Module headers

- Every file starts with the SPDX header:
  ```
  # SPDX-License-Identifier: GPL-3.0-or-later
  # Copyright (c) 2026 PitPact contributors
  #
  # PitPact — <one-line purpose of this file>.
  ```
  `tools/check_module_dependencies.sh` and the
  `rg -L "SPDX-License-Identifier: GPL-3.0-or-later" src/ tests/`
  check in the local quality suite flag files that miss this.
- Below the SPDX header, a short doc comment explains the file's
  purpose, its public surface, and any non-obvious invariants or
  contracts. See the existing `src/core/rng.gd` and
  `src/world/zone.gd` for the style.

## 4. Docstrings

- Public functions and classes get a docstring. The docstring is
  one short paragraph that says **what the function returns or
  changes**, not what every parameter is.
- For non-obvious behaviour, the docstring says **why**, not
  **how**. Code says how.
- Private functions (prefixed `_`) get a docstring only when their
  behaviour is non-obvious from the name.

## 5. Comments explain why

- Comments explain intent, invariants, constraints, and
  trade-offs. They do not narrate the obvious.
- Bad:
  ```gdscript
  # increment i
  i += 1
  ```
- Good:
  ```gdscript
  # Skip the leading sentinel; it does not participate in the
  # mass-balance equation and the renderer uses its absence as
  # "no row above".
  for i in range(1, rows):
      ...
  ```
- TODOs use the format `# TODO(your-name): <what, why>`. TODOs
  without a name or a reason are deleted at review.

## 6. No magic numbers

- Numeric literals in gameplay or simulation code live in
  `src/core/constants.gd` (or the module-local equivalent) as
  named constants. The only literals that are allowed inline are:
  0, 1, -1, 2 (in `range(2, ...)`-style idioms), and the
  literal that names a tile-coord origin.
- Strings that act as keys (`"fire"`, `"food"`, ...) live in the
  content data under `data/` and are referenced by `StringName`,
  not as raw literals in code. This is enforced by
  `tools/check_module_dependencies.sh` indirectly: source code
  must read from the data definitions, not duplicate the strings.

## 7. Central configuration

- Engine settings that affect gameplay, rendering, or audio
  belong in `project.godot` (the project settings), or in a
  dedicated `autoload` if they need to be read at runtime.
- Tuning constants for the simulation live in
  `src/core/constants.gd`, with one entry per concern. Sub-modules
  read them from there; they do not redefine them.
- Save-format constants (format version, magic bytes) live in
  `src/save/save_format.gd`. They are referenced from the
  migration registry, never from the simulation code.

## 8. Data-driven content

- Anything that names a creature, room, resource, biome, origin,
  contract, or event is a content datum. It lives under `data/`
  as a `.tres` (Godot Resource) or a `.json` (engine-agnostic
  data). Code that needs the value loads the resource; it does
  not embed a string.
- The schema for each content type is documented in
  [`docs/data-schema.md`](data-schema.md). Adding a new field
  to a content type requires updating the schema, the data
  file(s), and the migration registry in `src/save/migrations.gd`
  if the field is saved.

## 9. Localization

- Every user-visible string is externalized. The string lives
  in `locales/source_strings.csv` (English source) and in
  `locales/en.po` / `locales/de.po` (or whichever languages the
  project ships). Code references the string by key
  (`tr("UI_MENU_START")`).
- No hard-coded English in `.gd` or `.tscn` files. The check
  `tools/validate_locale.sh` enforces this on the data side; on
  the code side, code review and `gdlint` catch strings passed
  directly to `Label.text` etc.
- The full set of localization rules lives in
  [`docs/localization.md`](localization.md).

## 10. Error handling

- Use Godot's typed return convention: functions that can fail
  return a `Result`-like structure, never throw. The project
  defines a small set of result types in `src/core/result.gd`
  (planned for M1, enforced from M2).
- `assert` is for invariants the developer can prove. It is not
  for runtime input validation. Runtime checks return a typed
  error.
- The simulation never crashes the game on a recoverable
  condition. Inhabitants, contracts, and rooms fail gracefully
  and surface the failure in the event log.

## 11. Test expectations

- Every module under `src/` ships with at least one test in
  `tests/unit/` (per-class) or `tests/integration/`
  (cross-module). The local quality suite runs GUT against both
  directories.
- Test names describe the behaviour, not the implementation:
  `test_hearth_lifecycle_paint_then_tick_to_active` is good;
  `test_hearth_state_transitions` is not (it does not say what
  is being tested).
- Tests assert the post-condition with a specific, meaningful
  value, not just `assert_not_null(result)`. The fix-on-fail
  signal is the assertion message, not the test name.
- Tests for determinism use a fixed seed and assert
  `deep_equal` against a recorded reference. The SplitMix64
  RNG (see `src/core/rng.gd`) is the project's only sanctioned
  source of randomness.

## 12. Naming

- Modules: `snake_case` directory names; classes in
  `PascalCase`.
- Files: `snake_case.gd`, matching the class they contain.
- Public functions: `verb_noun` (`tick`, `paint_zone`,
  `serialize_realm`).
- Private functions and members: leading underscore
  (`_compute_hash`, `_state`).
- Constants: `SCREAMING_SNAKE_CASE`.
- Resource IDs (content): `StringName` in `snake_case`
  (`"stone"`, `"hearth"`, `"hollow"`).
- Locale keys: `SCREAMING_SNAKE_CASE` with a section prefix
  (`UI_MENU_START`, `CREATURE_LANTERNBEARER_NAME`).

## 13. Imports and module boundaries

- `src/<game-domain>/` modules do not import from `src/ui/`. The
  rule is enforced by `tools/check_module_dependencies.sh` and
  recorded in [`docs/adrs/0002-module-boundaries.md`](adrs/0002-module-boundaries.md).
- `src/ui/` is allowed to import from any game-domain module.
- Cross-module references in code go through the receiving
  module's public surface, not by reaching into its private
  members. `private` (single underscore) means private.

## 14. Versioning

- The save format is versioned (see [`docs/adrs/0003-save-format.md`](adrs/0003-save-format.md)).
  Every change to `src/save/save_format.gd` or
  `src/save/realm_serializer.gd` adds a migration entry in
  `src/save/migrations.gd` and a corresponding test in
  `tests/integration/test_save_roundtrip.gd`.
- The locale key schema is versioned in
  [`docs/localization.md`](localization.md). Removing a key
  requires a deprecation period; renaming a key requires
  leaving a redirect in the loader.

## 15. Local quality gates

Before every push, run:

```sh
./tools/run_quality.sh
```

It must exit 0. It runs, in order:

1. M0 baseline file presence check.
2. SPDX header scan on `src/*.gd` and `tests/*.gd`.
3. GitHub Actions YAML validation.
4. `gdformat --check` over `src/` and `tests/`.
5. `gdlint` over `src/` and `tests/`.
6. `check_module_dependencies.sh` (the ADR-0002 rule).
7. GUT smoke tests via Godot 4 headless.
8. Benchmark dry-run (skippable with `PITPACT_SKIP_BENCH=1`).

A PR is mergeable when the local quality suite passes, the
documentation is updated in the same PR, and the
[`CONTRIBUTING.md`](../CONTRIBUTING.md) checklist is complete.
