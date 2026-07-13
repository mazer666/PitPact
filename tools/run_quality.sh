#!/usr/bin/env bash
# run_quality.sh — single local quality command for PitPact.
#
# This is the documented single command contributors run before pushing
# (see CONTRIBUTING.md and §18 of docs/requirements.md). It is the
# authoritative gate. CI in .github/workflows/ci.yml runs a subset of
# the same checks on every push; the local run must always be at least
# as strict as CI.
#
# Pipeline (in order; first failure aborts the rest):
#   1. M0 baseline file set (file presence).
#   2. License header check on first-party GDScript (best-effort).
#   3. GitHub Actions workflow YAML syntax.
#   4. tools/format.sh --check (gdformat).
#   5. tools/lint.sh (gdlint, fails on warnings).
#   6. tools/check_module_dependencies.sh (ADR-0002 data-flow rule).
#   7. GUT 9 headless test runner (tests/_smoke/test_runner.gd).
#   8. tools/run_benchmark.sh --check (skippable).
#
# Exit codes:
#   0   all checks passed
#   1   one or more checks failed
#   2   tooling missing (godot binary not on PATH, formatter not found)
#
# Override behaviour with env vars:
#   PITPACT_GODOT       path to the godot binary (default: godot on PATH)
#   PITPACT_SKIP_BENCH  set to 1 to skip the benchmark dry-run
#   PITPACT_SKIP_TESTS  set to 1 to skip the GUT test run
#   PITPACT_VERBOSE     set to 1 to print full command output
#
# Usage:
#   ./tools/run_quality.sh
#   PITPACT_VERBOSE=1 ./tools/run_quality.sh
#   PITPACT_SKIP_TESTS=1 ./tools/run_quality.sh   # for editors without a Godot install
#
# Conventions:
#   - The script is idempotent and safe to re-run.
#   - It does NOT mutate the working tree (with the
#     intentional exception of creating the addons/gut
#     symlink/copy required by the GUT test runner; the
#     symlink is git-ignored).
#   - It does NOT push, commit, or open a PR.

set -euo pipefail

# --- locate repo root (this script's parent directory's parent) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

GODOT_BIN="${PITPACT_GODOT:-godot}"
VERBOSE="${PITPACT_VERBOSE:-0}"
SKIP_BENCH="${PITPACT_SKIP_BENCH:-0}"
SKIP_TESTS="${PITPACT_SKIP_TESTS:-0}"

# --- helpers ---
log()  { printf '\033[1;36m[run_quality]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[run_quality]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m[run_quality]\033[0m %s\n' "$*" >&2; exit 1; }

run_step() {
  local name="$1"; shift
  log "→ ${name}"
  if [ "${VERBOSE}" = "1" ]; then
    if ! "$@"; then
      fail "${name} FAILED"
    fi
  else
    local out
    if ! out="$("$@" 2>&1)"; then
      printf '%s\n' "${out}" >&2
      fail "${name} FAILED"
    fi
  fi
  log "✓ ${name}"
}

# --- preflight ---
command -v git >/dev/null 2>&1 || fail "git not on PATH"
[ -f project.godot ] || fail "project.godot missing; run from repo root"

# --- 1. Working tree status (informational) ---
log "→ git status (informational)"
git status --porcelain | sed 's/^/    /' || true

# --- 2. Required files present ---
log "→ checking required files"
required=(
  AGENTS.md
  README.md
  LICENSE
  CODE_OF_CONDUCT.md
  CONTRIBUTING.md
  CHANGELOG.md
  SECURITY.md
  docs/requirements.md
  docs/milestones.md
  docs/roadmap.md
  docs/repository-structure.md
  docs/style-bible.md
  docs/ip-license-checklist.md
  docs/adrs
  docs/adrs/0001-record-architecture-decisions.md
  docs/adrs/0002-module-boundaries.md
  docs/adrs/0003-save-format.md
  docs/adrs/0004-spatial-model.md
  licenses/GPL-3.0.txt
  licenses/CC-BY-SA-4.0.txt
  licenses/THIRD-PARTY.md
  project.godot
  tools/run_quality.sh
  tools/format.sh
  tools/lint.sh
  tools/check_module_dependencies.sh
  src/core/README.md
  src/world/README.md
  src/sim/README.md
  src/realm/README.md
  src/content/README.md
  src/save/README.md
  src/ui/README.md
  src/audit/README.md
  src/core/rng.gd
  tests/_smoke/test_runner.gd
  tests/_smoke/test_smoke.gd
  tests/gut
)
missing=()
for f in "${required[@]}"; do
  if [ ! -e "${f}" ]; then
    missing+=("${f}")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  printf 'Missing required paths:\n' >&2
  for f in "${missing[@]}"; do printf '  - %s\n' "${f}" >&2; done
  fail "M1 foundation baseline incomplete"
fi
log "✓ required files present"

# --- 3. License headers (best-effort) ---
log "→ checking license headers on tracked source files"
if command -v rg >/dev/null 2>&1; then
  # Use --files-without-match (the modern flag). The legacy
  # `-L` alias has surprising output behaviour in some
  # ripgrep versions, so we use the canonical flag here.
  bad=$(rg --files-without-match \
    -g '*.gd' \
    "SPDX-License-Identifier: GPL-3.0-or-later" \
    src/ tests/_smoke 2>/dev/null || true)
  if [ -n "${bad}" ]; then
    warn "the following GDScript files lack an SPDX header:"
    printf '%s\n' "${bad}" >&2
    fail "license header check failed"
  fi
  log "✓ license headers present on first-party GDScript"
else
  warn "rg (ripgrep) not on PATH — skipping license-header scan"
fi

# --- 4. GitHub workflow YAML syntax (best-effort) ---
if command -v python3 >/dev/null 2>&1; then
  log "→ validating GitHub Actions workflows"
  python3 -c "
import sys, pathlib, yaml
errs = 0
for p in pathlib.Path('.github/workflows').glob('*.yml'):
    try:
        with p.open() as fh:
            yaml.safe_load(fh)
    except Exception as e:
        print(f'  {p}: {e}', file=sys.stderr)
        errs += 1
sys.exit(errs)
" || fail "workflow YAML validation failed"
  log "✓ workflows valid"
else
  warn "python3 not on PATH — skipping workflow YAML validation"
fi

# --- 5. Formatter (gdformat) ---
if [ -x tools/format.sh ]; then
  run_step "format check (gdformat)" tools/format.sh
else
  warn "tools/format.sh missing or not executable; skipping"
fi

# --- 6. Linter (gdlint) ---
if [ -x tools/lint.sh ]; then
  run_step "lint check (gdlint)" tools/lint.sh
else
  warn "tools/lint.sh missing or not executable; skipping"
fi

# --- 7. Module-dependency check (ADR-0002) ---
if [ -x tools/check_module_dependencies.sh ]; then
  run_step "module-dependency check" tools/check_module_dependencies.sh
else
  warn "tools/check_module_dependencies.sh missing or not executable; skipping"
fi

# --- 8. Godot project parse + GUT 9 headless tests ---
if command -v "${GODOT_BIN}" >/dev/null 2>&1; then
  # 8a. Bootstrap the GUT loadable path. The vendored GUT 9
  #     source lives at tests/gut/ (per the M1 foundation
  #     spec), but GUT's own code hardcodes
  #     `res://addons/gut/...` paths. We expose the
  #     vendored copy via a symlink (POSIX) or copy
  #     (Windows) so the GUT 9.2.1 vendored source is
  #     unmodified. The shim is idempotent and is ignored
  #     by .gitignore.
  if [ -f tests/_smoke/_ensure_gut_path.sh ]; then
    run_step "gutm path bootstrap" sh tests/_smoke/_ensure_gut_path.sh
  else
    warn "tests/_smoke/_ensure_gut_path.sh missing; assuming addons/gut is present"
  fi

  # 8b. Run `godot --import` so the global class registry
  #     picks up every class_name, including those under
  #     addons/gut/. We must do this AFTER the symlink is
  #     in place, otherwise GUT's classes are not
  #     registered and GUT 9 fails to parse.
  log "→ godot --headless --import (project import / class cache)"
  run_step "godot import" \
    env PITPACT_VERBOSE="${VERBOSE}" "${GODOT_BIN}" --headless --import --path "${REPO_ROOT}"

  # 8c. The headless test run.
  if [ "${SKIP_TESTS}" = "1" ]; then
    warn "PITPACT_SKIP_TESTS=1; skipping GUT 9 test run"
  elif [ -f tests/_smoke/test_runner.gd ]; then
    log "→ godot --headless GUT 9 test run (tests/_smoke/test_runner.gd)"
    run_step "gut headless tests" \
      env PITPACT_VERBOSE="${VERBOSE}" "${GODOT_BIN}" \
        --headless --path "${REPO_ROOT}" \
        --script res://tests/_smoke/test_runner.gd
  else
    warn "tests/_smoke/test_runner.gd missing; skipping GUT 9 test run"
  fi
else
  warn "godot binary not on PATH (set PITPACT_GODOT); skipping engine checks"
  if [ "${SKIP_TESTS}" != "1" ]; then
    warn "to run the GUT test suite later: PITPACT_SKIP_TESTS=0 + godot on PATH"
  fi
fi

# --- 9. Benchmark dry-run (skippable) ---
if [ "${SKIP_BENCH}" != "1" ]; then
  if [ -f tools/run_benchmark.sh ]; then
    log "→ benchmark dry-run"
    run_step "benchmark dry-run" tools/run_benchmark.sh --check
  else
    log "→ no benchmark script yet (M0); skipping"
  fi
fi

# --- 10. Locale validation (M1 Track C, §15 + §18) ---
if [ -x tools/validate_locale.sh ]; then
  run_step "locale validation" tools/validate_locale.sh
else
  warn "tools/validate_locale.sh missing or not executable; skipping"
fi

log "ALL CHECKS PASSED ✓"
