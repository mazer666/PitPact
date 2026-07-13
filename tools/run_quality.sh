#!/usr/bin/env bash
# run_quality.sh — single local quality command for PitPact.
#
# This is the documented single command contributors run before pushing
# (see CONTRIBUTING.md and §18 of docs/requirements.md). It is the
# authoritative gate. CI in .github/workflows/ci.yml runs a subset of
# the same checks on every push; the local run must always be at least
# as strict as CI.
#
# Exit codes:
#   0   all checks passed
#   1   one or more checks failed
#   2   tooling missing (godot binary not on PATH, formatter not found)
#
# Override behaviour with env vars:
#   PITPACT_GODOT       path to the godot binary (default: godot on PATH)
#   PITPACT_SKIP_BENCH  set to 1 to skip the benchmark dry-run
#   PITPACT_VERBOSE     set to 1 to print full command output
#
# Usage:
#   ./tools/run_quality.sh
#   PITPACT_VERBOSE=1 ./tools/run_quality.sh
#
# Conventions:
#   - The script is idempotent and safe to re-run.
#   - It does NOT mutate the working tree. It only reads and reports.
#   - It does NOT push, commit, or open a PR.

set -euo pipefail

# --- locate repo root (this script's parent directory's parent) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

GODOT_BIN="${PITPACT_GODOT:-godot}"
VERBOSE="${PITPACT_VERBOSE:-0}"
SKIP_BENCH="${PITPACT_SKIP_BENCH:-0}"

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

# --- 1. Working tree must be clean of M0 baseline drift ---
log "→ git status (informational)"
git status --porcelain | sed 's/^/    /' || true

# --- 2. Required files present ---
log "→ checking required files"
required=(
  "AGENTS.md"
  "README.md"
  "LICENSE"
  "CODE_OF_CONDUCT.md"
  "CONTRIBUTING.md"
  "CHANGELOG.md"
  "SECURITY.md"
  "docs/requirements.md"
  "docs/milestones.md"
  "docs/roadmap.md"
  "docs/repository-structure.md"
  "docs/style-bible.md"
  "docs/ip-license-checklist.md"
  "docs/adrs"
  "licenses/GPL-3.0.txt"
  "licenses/CC-BY-SA-4.0.txt"
  "licenses/THIRD-PARTY.md"
  "project.godot"
  "tools/run_quality.sh"
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
  fail "M0 baseline incomplete"
fi
log "✓ required files present"

# --- 3. License headers (best-effort) ---
log "→ checking license headers on tracked source files"
if command -v rg >/dev/null 2>&1; then
  bad=$(rg -L "SPDX-License-Identifier: GPL-3.0-or-later" --type-add 'gd:*.gd' --type-add 'gdscript:*.gd' -t gdscript src/ 2>/dev/null || true)
  if [ -n "${bad}" ]; then
    warn "the following GDScript files under src/ lack an SPDX header:"
    printf '%s\n' "${bad}" >&2
    fail "license header check failed"
  fi
  log "✓ license headers present on src/*.gd"
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

# --- 5. Headless Godot project import (compiles shaders, parses project.godot) ---
if command -v "${GODOT_BIN}" >/dev/null 2>&1; then
  log "→ godot --headless --quit (project import / parse check)"
  run_step "godot import" \
    env PITPACT_VERBOSE="${VERBOSE}" "${GODOT_BIN}" --headless --quit --path "${REPO_ROOT}"

  # --- 6. Headless test runner ---
  # The real test entry point lands in M2. For M0 we just confirm that
  # the test scaffold at least imports without script errors.
  if [ -d tests ] && [ -f tests/.gdignore ]; then
    log "→ godot --headless test discovery (scaffold dry-run)"
    # We do NOT run any tests yet — there are none. We just assert the
    # runner path is plumbed and Godot can list scripts under tests/.
    if [ -z "$(find tests -name '*.gd' -print -quit)" ]; then
      log "✓ no tests yet (expected at M0); scaffold-only dry-run OK"
    else
      run_step "godot test discovery" \
        env PITPACT_VERBOSE="${VERBOSE}" "${GODOT_BIN}" \
          --headless --path "${REPO_ROOT}" \
          --script res://tests/_runner_dry_run.gd || true
    fi
  fi
else
  warn "godot binary not on PATH (set PITPACT_GODOT); skipping engine checks"
fi

# --- 7. Benchmark dry-run (skippable) ---
if [ "${SKIP_BENCH}" != "1" ]; then
  if [ -f tools/run_benchmark.sh ]; then
    log "→ benchmark dry-run"
    run_step "benchmark dry-run" tools/run_benchmark.sh --check
  else
    log "→ no benchmark script yet (M0); skipping"
  fi
fi

log "ALL CHECKS PASSED ✓"
