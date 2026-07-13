#!/usr/bin/env bash
# check_module_dependencies.sh — mechanically enforce the
# data-flow rule from ADR-0002.
#
# The rule (load-bearing, see docs/adrs/0002-module-boundaries.md):
#
#   Deterministic game-domain modules — src/core, src/world,
#   src/sim, src/realm, src/content, src/save — MUST NOT
#   import from src/ui. UI imports game-domain modules; never
#   the other way.
#
# This script greps every first-party .gd under src/<m>/ for
# literal references to the other modules' directories and
# asserts that the only allowed edges are present.
#
# Why a grep, not an AST pass?
#   - The rule is "no path to src/ui from game-domain
#     modules". A grep for `res://src/ui/` catches the
#     realistic violation mode (someone typing
#     `preload("res://src/ui/...")` or
#     `load("res://src/ui/...")`).
#   - GDScript's static type references resolve at parse
#     time; a class_name declared in src/ui/ (e.g.
#     `RealmUiController`) would be visible in any module
#     and is therefore also a violation. We also grep for
#     those class_name references.
#   - A grep is fast (sub-second on this tree) and has no
#     Godot dependency, so it can run in CI without a Godot
#     install.
#
# The dependency graph this script enforces is the one in
# ADR-0002:
#
#   src/core        → (nothing)
#   src/content     → src/core
#   src/audit       → src/core
#   src/save        → src/core
#   src/world       → src/core, src/content
#   src/sim         → src/core, src/world, src/content, src/audit
#   src/realm       → src/core, src/world, src/sim, src/content, src/save, src/audit
#   src/ui          → src/realm, src/content, src/audit
#
# To add a new module or a new allowed edge, edit the
# `ALLOWED_DEPS` map below AND update ADR-0002. The two
# stay in sync by review.
#
# Exit codes:
#   0   no violations
#   1   one or more violations
#   2   src/ is missing entirely (the tree is broken)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

if [ ! -d src ]; then
  echo "check_module_dependencies.sh: src/ missing; nothing to check" >&2
  exit 2
fi

# The dependency graph. The right-hand side is the
# *upstream* set: a module is allowed to import from its
# own directory, from any of these, and from nowhere else.
# `src/ui` is the special case: game-domain modules MUST
# NOT import from it (the load-bearing rule); the empty
# upstream set is enforced separately below.
declare -A ALLOWED_DEPS=(
  [core]=""
  [content]="core"
  [audit]="core"
  [save]="core"
  [world]="core content"
  [sim]="core world content audit"
  [realm]="core world sim content save audit"
  [ui]="realm content audit"
)

# The forbidden class_name set: any class declared in
# src/ui/ (e.g. `class_name RealmUiController`) MUST NOT be
# referenced from a game-domain module. We collect this
# dynamically so adding a new class in src/ui/ does not
# require editing this script.
UI_CLASSNAMES=()
while IFS= read -r line; do
  # strip leading whitespace
  cn="${line##+( )}"
  UI_CLASSNAMES+=("$cn")
done < <(grep -rh --include='*.gd' -E '^[[:space:]]*class_name[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' src/ui/ 2>/dev/null \
  | sed -E 's/^[[:space:]]*class_name[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/')

if [ "${#UI_CLASSNAMES[@]}" -gt 0 ]; then
  echo "check_module_dependencies.sh: tracking ${#UI_CLASSNAMES[@]} ui class_name(s): ${UI_CLASSNAMES[*]}"
fi

violations=0

# We iterate modules in a fixed order (matching the graph in
# ADR-0002) so the violation report is stable.
for module in core content audit save world sim realm ui; do
  mod_dir="src/${module}"
  [ -d "${mod_dir}" ] || continue

  # Find every first-party .gd in this module.
  mapfile -t mod_files < <(find "${mod_dir}" -maxdepth 1 -type f -name '*.gd' | sort)
  if [ "${#mod_files[@]}" -eq 0 ]; then
    continue
  fi

  # Build the allowed-upstream set as a regex alternation.
  allowed="${ALLOWED_DEPS[${module}]}"
  if [ -z "${allowed}" ]; then
    # Module with no upstream — only `res://src/<self>/` and
    # built-ins are allowed.
    allowed_re="(^|/)src/${module}/"
  else
    parts=""
    for a in ${allowed}; do
      parts="${parts:+$parts|}(^|/)src/${a}/"
    done
    # Self is always allowed.
    allowed_re="(^|/)src/${module}/|${parts}"
  fi

  for f in "${mod_files[@]}"; do
    # 1. Find every `res://src/<other>/` reference.
    while IFS= read -r match; do
      [ -z "${match}" ] && continue
      # Extract the module name from the match.
      # `res://src/<module>/...`
      target=$(echo "${match}" | sed -E 's@res://src/([A-Za-z0-9_]+)/.*@\1@')
      if [ -z "${target}" ]; then
        continue
      fi
      if [ "${target}" = "${module}" ]; then
        continue  # self-imports are fine
      fi
      # The allowed set is the bare module names (e.g.
      # `core content` for `world`). Compare the bare
      # target name against the allowed set, not against
      # a regex that expects `src/<module>/` path
      # fragments — the previous form missed bare-name
      # matches and produced false positives for legal
      # imports like `load("res://src/core/rng.gd")` from
      # a module that is allowed to depend on `core`.
      for a in ${allowed} ${module}; do
        if [ "${target}" = "${a}" ]; then
          continue 2
        fi
      done
      echo "VIOLATION ${f}: imports from src/${target}/ (not allowed from src/${module}/)" >&2
      violations=$((violations + 1))
    done < <(grep -oE 'res://src/[A-Za-z0-9_]+(/[^"'"'"' ]*)?' "${f}" 2>/dev/null || true)

    # 2. Find every reference to a src/ui/ class_name.
    #    A bare class_name token in code resolves through
    #    Godot's global class table; referencing a UI
    #    class_name from a game-domain module is a
    #    violation of the load-bearing rule.
    #
    #    Same-module references (UI -> UI) are always
    #    fine; the rule is one-directional. Skip the
    #    class_name check entirely for files inside
    #    `src/ui/`.
    if [ "${module}" = "ui" ]; then
      continue
    fi
    for cn in "${UI_CLASSNAMES[@]}"; do
      if grep -qE "\b${cn}\b" "${f}" 2>/dev/null; then
        # The `class_name` line itself is the declaration;
        # ignore it. We are looking for *uses*, which can
        # be `var x: ClassName`, `x as ClassName`,
        # `ClassName.new(...)`, or `: ClassName`.
        if grep -E "^[[:space:]]*class_name[[:space:]]+${cn}\b" "${f}" >/dev/null 2>&1; then
          continue
        fi
        # Filter out the docstring-comment line that just
        # names the class for documentation purposes.
        if grep -E "^[[:space:]]*##.*\b${cn}\b" "${f}" >/dev/null 2>&1; then
          # Could be a docstring. Look for a real
          # *use* — a `:` after a name, a `as`,
          # `ClassName.new`, or a `var x: ClassName`.
          if ! grep -E "(:[[:space:]]+${cn}\b|as[[:space:]]+${cn}\b|${cn}\.new|new[[:space:]]+${cn}\b)" "${f}" >/dev/null 2>&1; then
            continue
          fi
        fi
        echo "VIOLATION ${f}: references UI class_name ${cn} (load-bearing rule: game-domain must not depend on src/ui/)" >&2
        violations=$((violations + 1))
      fi
    done
  done
done

if [ "${violations}" -gt 0 ]; then
  echo "check_module_dependencies.sh: ${violations} violation(s) — see docs/adrs/0002-module-boundaries.md" >&2
  exit 1
fi

echo "check_module_dependencies.sh: OK (no module-dependency violations)"
