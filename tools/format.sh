#!/usr/bin/env bash
# format.sh — format GDScript under src/ and tests/ with gdformat.
#
# Idempotent: re-running it is a no-op once the tree is
# formatted. Exits 0 on a clean (or cleanable) tree, non-zero
# if gdformat itself fails.
#
# Why a wrapper rather than a bare `gdformat src/ tests/`?
#   - It pins the formatter version (gdformat 4.5.0 from
#     gdtoolkit) so contributors without a pinned install get
#     the same output.
#   - It limits scope: the formatting contract is over
#     `src/` and `tests/`, not over the vendored `tests/gut/`
#     tree (which is pinned third-party code) and not over
#     `scenes/`, `data/`, or `locales/`.
#   - It exits 0 if `gdformat --check` says the tree is
#     already formatted, which is what CI wants.
#
# Tools/run_quality.sh runs this script in --check mode by
# default; pass FORMAT_WRITE=1 to actually rewrite the tree
# (intended for local use, never for CI).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

MODE="${FORMAT_WRITE:-0}"  # 0 = check (default), 1 = write

# --- locate gdformat ---
if ! command -v gdformat >/dev/null 2>&1; then
  echo "format.sh: gdformat not on PATH" >&2
  echo "  install with: pip install --user gdtoolkit==4.5.0" >&2
  exit 2
fi

# --- scope: only first-party GDScript, never the vendored GUT tree ---
TARGETS=()
for d in src tests; do
  if [ -d "${d}" ]; then
    TARGETS+=("${d}")
  fi
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "format.sh: no targets (src/ and tests/ both missing); nothing to do"
  exit 0
fi

# gdformat takes positional paths and recurses by default.
# It has no --exclude flag. We list the first-party GDScript
# files explicitly via a find pipeline, excluding the
# vendored tests/gut/ tree. Using a generated list is slower
# than a positional directory, but it is the only way to keep
# the formatter away from the pinned third-party code.
mapfile -t GDFILES < <(find "${TARGETS[@]}" \
  -type f -name '*.gd' \
  -not -path 'tests/gut/*' \
  -not -path 'tests/gut' \
  | sort)

if [ "${#GDFILES[@]}" -eq 0 ]; then
  echo "format.sh: no .gd files to format; nothing to do"
  exit 0
fi

if [ "${MODE}" = "1" ]; then
  echo "format.sh: gdformat (write) over ${#GDFILES[@]} first-party files (excluding tests/gut)"
  gdformat "${GDFILES[@]}"
else
  echo "format.sh: gdformat --check over ${#GDFILES[@]} first-party files (excluding tests/gut)"
  if ! gdformat --check "${GDFILES[@]}"; then
    echo "format.sh: tree is not formatted; run with FORMAT_WRITE=1 to fix" >&2
    exit 1
  fi
fi

echo "format.sh: OK"
