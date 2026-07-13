#!/usr/bin/env bash
# lint.sh — lint GDScript under src/ and tests/ with gdlint.
#
# The linter is the second-tier quality gate (after the
# formatter). It catches:
#   - unused variables / imports,
#   - shadowed identifiers,
#   - missing return types,
#   - unused parameters,
#   - unsafe `_init(...)` patterns,
#   - and the rest of the rules in gdtoolkit 4.5.0.
#
# Per the M1 foundation spec, the linter MUST fail on
# warnings (exit non-zero on any warning). gdlint exits
# non-zero on warnings by default, so we only need to be
# careful to propagate the exit code (no `|| true`).
#
# Scope: src/ and tests/ — explicitly NOT tests/gut/ (pinned
# third-party code, see licenses/THIRD-PARTY.md).
#
# Exit codes:
#   0   clean
#   1   one or more warnings/errors
#   2   gdlint not on PATH

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

# --- locate gdlint ---
if ! command -v gdlint >/dev/null 2>&1; then
  echo "lint.sh: gdlint not on PATH" >&2
  echo "  install with: pip install --user gdtoolkit==4.5.0" >&2
  exit 2
fi

# --- scope: only first-party GDScript, never the vendored GUT tree ---
mapfile -t LINTFILES < <(find src tests \
  -type f -name '*.gd' \
  -not -path 'tests/gut/*' \
  -not -path 'tests/gut' \
  | sort)

if [ "${#LINTFILES[@]}" -eq 0 ]; then
  echo "lint.sh: no .gd files to lint; nothing to do"
  exit 0
fi

echo "lint.sh: gdlint over ${#LINTFILES[@]} first-party files (excluding tests/gut)"

# gdlint prints "FILE:LINE:COL: CODE message" per finding and
# exits non-zero on any finding. We propagate the exit code
# so the local quality suite and CI see the failure.
gdlint "${LINTFILES[@]}"

echo "lint.sh: OK"
