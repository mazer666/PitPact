# tests

Automated checks for the PitPact project. Tests are organised
by concern and run by a single local command
([`./tools/run_quality.sh`](../tools/run_quality.sh)).

## Layout

| Directory | Purpose |
|-----------|---------|
| `_smoke/`     | Bootstrapping tests and the GUT 9 headless entry point. Always run first. |
| `unit/`       | Pure unit tests for individual classes (no Godot scene tree required). |
| `integration/`| Multi-module integration tests; the realm façade over a stub world. |
| `save/`       | Save/load round-trip and migration tests (see ADR-0003). |
| `generator/`  | Procedural-generation validity tests (see §7 of the requirements spec). |
| `locale/`     | Localization completeness and placeholder checks (see §15). |
| `gut/`        | Vendored GUT 9.2.1 source (pinned, see [`licenses/THIRD-PARTY.md`](../licenses/THIRD-PARTY.md)). Do not modify. |

## Running the suite

The full suite is one command:

```sh
./tools/run_quality.sh
```

That script invokes the formatter, the linter, the module-
dependency check, and the GUT 9 test runner in order. See
[`../tools/README.md`](../tools/README.md) for the individual
commands and exit-code semantics.

To run only the GUT tests:

```sh
godot --headless --path . --script res://tests/_smoke/test_runner.gd
```

The first run creates a symlink at `addons/gut` that points
at the vendored `tests/gut/`. That symlink is git-ignored and
is created idempotently on every run; delete it with
`rm addons/gut` to force a re-bootstrap.

To run only one test file, pass the script's path to GUT's
`-gtest` option (after the bootstrap):

```sh
godot --headless --path . \
  --script res://tests/_smoke/test_runner.gd \
  -ggtest=res://tests/_smoke/test_smoke.gd
```

## Writing a new test

1. Pick the right subdirectory. Pure unit tests for a class
   in `src/<module>/` go in `tests/unit/`. Tests that span
   modules (e.g. a save → load round-trip) go in
   `tests/integration/` or the relevant cross-cutting
   directory.
2. Name the file `test_<thing>.gd`. GUT 9's default
   prefix/suffix match.
3. Extend `GutTest` (`extends GutTest` at the top of the
   file). The `GutTest` base class is exposed by
   `tests/gut/test.gd`, which is reachable as
   `res://addons/gut/test.gd` after the symlink bootstrap.
4. Use `assert_*` and `assert_eq` / `assert_ne` from GUT's
   standard library. Avoid `print`-based "tests".
5. Add an SPDX header (`SPDX-License-Identifier: GPL-3.0-or-later`).
6. If the test depends on a new `src/<module>/` file, make
   sure the new file follows the dependency rules in
   [`docs/adrs/0002-module-boundaries.md`](../adrs/0002-module-boundaries.md).
   `tools/check_module_dependencies.sh` enforces them.

## See also

- [`docs/adrs/0002-module-boundaries.md`](../docs/adrs/0002-module-boundaries.md) — the
  per-module contract that the tests verify.
- [`docs/requirements.md`](../docs/requirements.md) §16, §18 — testing
  and local quality gates.
- [`licenses/THIRD-PARTY.md`](../licenses/THIRD-PARTY.md) — GUT 9
  provenance and modifications.
