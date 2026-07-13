#!/bin/sh
# _ensure_gut_path.sh — make `res://addons/gut` resolvable.
#
# This is a small companion script to test_runner.gd. The
# vendored GUT 9 source lives at tests/gut/ (per the M1
# foundation spec), but GUT 9's own code hardcodes
# `res://addons/gut/...` paths throughout. Rather than patch
# 75+ vendored files, we expose the vendored copy at the
# conventional `res://addons/gut/` location via a symlink
# (POSIX) or directory copy (Windows).
#
# This script is invoked by test_runner.gd at test time and
# is idempotent. It does not modify any source under tests/gut/
# or src/. The only side effect is the addons/gut symlink (or
# copy), which is excluded by .gitignore.
#
# Usage:
#   sh tests/_smoke/_ensure_gut_path.sh
#
# Exit codes:
#   0   addons/gut is loadable now (idempotent)
#   1   the vendored tests/gut/ directory is missing
#   2   symlink/copy creation failed
#
# Note: this script is intentionally POSIX-`/bin/sh` so it
# runs under whatever shell Godot's OS.execute("sh", ...) hands
# us. We do NOT use `set -o pipefail` (not POSIX) or
# namerefs (bash-only); we use the minimal features below.

set -eu

# --- locate repo root from this script's path ---
# POSIX-portable: $0 may be a relative path under sh, so
# we resolve through `dirname` and `cd` to get an absolute
# path. We do NOT use ${BASH_SOURCE[0]} (bash-only).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

VENDORED="tests/gut"
TARGET="addons/gut"

if [ ! -d "${VENDORED}" ]; then
  echo "FATAL: vendored GUT not found at ${VENDORED}" >&2
  exit 1
fi

# Idempotent: if `res://addons/gut` (i.e. addons/gut) is
# already loadable, do nothing.
if [ -e "${TARGET}/gut.gd" ]; then
  exit 0
fi

# Make sure the parent directory exists.
mkdir -p addons

# Platform branch. We use uname rather than the OS env var
# because this script is invoked via sh from inside Godot
# (where OS.get_name() feeds the GDScript side).
case "$(uname -s)" in
  Linux|Darwin|BSD|*CYGWIN*|*MINGW*)
    # Symlink: cheap, instant, and `git status` ignores it
    # via the `addons/gut/` entry in .gitignore.
    ln -s "../${VENDORED}" "${TARGET}"
    echo "[ensure_gut_path] created symlink ${TARGET} -> ../${VENDORED}"
    ;;
  *)
    # Windows and unknown: copy the vendored tree. Slower
    # than a symlink, but GUT loads by file path and a copy
    # is the portable fallback.
    cp -R "${VENDORED}" "${TARGET}"
    echo "[ensure_gut_path] copied ${VENDORED} to ${TARGET}"
    ;;
esac

# Verify.
if [ ! -e "${TARGET}/gut.gd" ]; then
  echo "FATAL: ${TARGET}/gut.gd still missing after bootstrap" >&2
  exit 2
fi

exit 0
