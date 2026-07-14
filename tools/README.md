# `tools/` — Local Quality and Build Scripts

> This directory holds the local commands a contributor runs on
> their own machine. The local quality suite is the authoritative
> gate; CI in `.github/workflows/ci.yml` is the safety net, not
> the source of truth. See [`docs/code-style.md`](../docs/code-style.md) §15
> for the canonical reference.

## The single local quality command

```sh
./tools/run_quality.sh
```

This is the one command you run before every push. It exits 0 on
a clean tree, non-zero on any failure. It runs, in order:

1. **M0 baseline file presence check** — the governance, license,
   ADR, and module-README files that the M0 Definition-of-Done
   requires.
2. **SPDX header scan** — every GDScript file in `src/` and
   `tests/` (excluding the vendored GUT at `tests/gut/`) starts
   with the GPL-3.0-or-later SPDX header.
3. **GitHub Actions YAML validation** — the workflow files
   parse.
4. **Formatter check (`gdformat --check`)** — the first-party
   tree is formatted. Set `FORMAT_WRITE=1` to write fixes.
5. **Lint check (`gdlint`)** — no warnings on first-party files.
6. **Module-dependency check** — the ADR-0002 rule
   (`src/<game-domain>/` MUST NOT import from `src/ui/`).
7. **GUT smoke tests** — the headless test runner picks up the
   tests in `tests/_smoke/`, `tests/unit/`, and
   `tests/integration/`.
8. **Benchmark dry-run** — `tools/run_benchmark.sh --check`
   lists the scenario manifests. The real benchmark execution
   lands in M6.

Skip the benchmark step with `PITPACT_SKIP_BENCH=1`. Make the
script verbose with `PITPACT_VERBOSE=1`.

## What lives in this directory

| Script | Purpose |
|--------|---------|
| `run_quality.sh` | The single local quality command. The contributor's primary loop. |
| `format.sh` | Wraps `gdformat` over first-party files. Idempotent; supports `FORMAT_WRITE=1` to fix. |
| `lint.sh` | Wraps `gdlint` over first-party files. Fails on warnings. |
| `check_module_dependencies.sh` | Static analysis of import statements. Enforces ADR-0002. |
| `validate_locale.sh` | Source-of-truth checks for the locale pipeline. See [`docs/localization.md`](../docs/localization.md). |
| `run_benchmark.sh` | Reproducible performance harness. M0 stub; full implementation lands in M6. |

## Conventions

- Every script is a plain `bash` script, executable, and starts
  with `#!/usr/bin/env bash`.
- Every script uses `set -euo pipefail`. A failure anywhere is a
  failure everywhere.
- Every script is idempotent. Re-running it on a clean tree is a
  no-op.
- Every script documents its CLI in a comment at the top of the
  file. `--help` prints the usage.
- No script mutates the working tree unless the user explicitly
  asked (e.g. `FORMAT_WRITE=1`). Read-only is the default.

## Adding a new tool

1. Place the script under `tools/` with the `*.sh` extension.
2. Make it executable (`chmod +x tools/<name>.sh`).
3. Wire it into `tools/run_quality.sh` as a numbered step.
4. Add the script's name to the table above.
5. If the tool depends on a system binary that is not in the
   standard PATH, document the dependency in
   [`CONTRIBUTING.md`](../CONTRIBUTING.md).

## See also

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — the contributor
  workflow.
- [`docs/code-style.md`](../docs/code-style.md) §15 — the local
  quality suite in the broader code style.
- [`AGENTS.md`](../AGENTS.md) — the rules for AI-assisted
  contributors, which inherit this directory's discipline.
