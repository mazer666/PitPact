#!/usr/bin/env bash
# run_benchmark.sh — reproducible performance scenarios for PitPact.
#
# The real benchmark harness lands in M6 (performance target milestone).
# This stub exists so that tools/run_quality.sh can find a deterministic
# entry point from M0 onward, and so contributors have a single
# "reproduce the published numbers" command to point at in release notes.
#
# Today it supports two modes:
#   --check      dry-run: list scenarios, check preconditions, exit 0/1
#   --list       print the scenario names
#
# Future modes (M6+):
#   --scenario NAME --seed N  run a single scenario with a fixed seed
#   --report PATH              write JSON/CSV results to PATH
#
# Conventions:
#   - All scenarios are deterministic; seeds are required.
#   - Results are written to benchmarks/results/ (gitignored).
#   - Re-running a scenario with the same seed must produce numbers
#     within the documented tolerance band (or the scenario is broken).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

GODOT_BIN="${PITPACT_GODOT:-godot}"
RESULTS_DIR="${REPO_ROOT}/benchmarks/results"

log()  { printf '\033[1;35m[run_benchmark]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[run_benchmark]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [--check | --list | --scenario NAME --seed N --report PATH]

  --check               dry-run: validate scenario manifests, exit 0/1
  --list                print scenario names
  --scenario NAME       run a single named scenario (M6+)
  --seed N              seed for the scenario (M6+)
  --report PATH         write results to PATH (M6+)
EOF
}

mode="${1:-}"

case "${mode}" in
  --check)
    log "benchmark dry-run"
    if [ ! -d "${REPO_ROOT}/benchmarks/scenarios" ]; then
      log "no scenarios yet (expected at M0); dry-run OK"
      exit 0
    fi
    log "✓ dry-run OK"
    exit 0
    ;;
  --list)
    if [ ! -d "${REPO_ROOT}/benchmarks/scenarios" ]; then
      log "(no scenarios defined yet)"
      exit 0
    fi
    for f in "${REPO_ROOT}"/benchmarks/scenarios/*.json; do
      [ -e "${f}" ] || continue
      basename "${f}" .json
    done
    exit 0
    ;;
  --scenario)
    fail "--scenario is not implemented yet; it lands in M6"
    ;;
  -h|--help|"")
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
