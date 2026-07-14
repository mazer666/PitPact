# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — crisis data carrier (M2 skeleton).
#
# `Crisis` is the per-crisis data carrier for the
# realm's crisis queue. A crisis is a timed,
# branching, player-influenced event that threatens
# the realm's existence if not resolved. §11 of
# `docs/requirements.md` requires two major crises
# in the first public release; the M2 cycle 3 commit
# ships the two.
#
# The M2 skeleton ships the public surface and the
# `class_name`; the M2 Track B commit fills in the
# per-tick evaluation rule (called from step 5 in
# ADR-0005, after the relationships update). The
# `condition: Callable` is a placeholder in the M2
# skeleton — the M2 cycle 3 commit narrows its
# signature and pins the M3+ evaluation
# documentation.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name Crisis
extends RefCounted

## The M2 default timeout, in in-game days. The
## M2 cycle 3 commit replaces the literal with
## `TUNING_CRISIS_DEFAULT_DAYS` from
## `src/sim/constants.gd`; the constant is the
## one this commit ships. The default is a
## `const` on the class so the M2 skeleton has
## a documented timeout even before the
## `constants.gd` cycle-2 commit is merged.
const DEFAULT_TIMEOUT_DAYS: float = 7.0

## The crisis's stable identity. `StringName` for
## the same reasons as `Inhabitant.id`. The id is
## what the event log (`crisis.triggered` and
## `crisis.resolved` events carry it) keys off.
var id: StringName = &""

## The in-game day the crisis is scheduled to
## trigger. The value is the realm's `time_days`
## at the tick the crisis was scheduled; the
## trigger happens at the *next* tick whose
## `time_days >= trigger_at_day`. The M2 Track B
## commit owns the per-tick check.
var trigger_at_day: float = 0.0

## The condition that triggers the crisis. The
## M2 skeleton stores this as an untyped
## `Callable`; the M2 cycle 3 commit narrows the
## field's type and pins the signature
## `func(state: Dictionary) -> bool`. The
## `state: Dictionary` is the sim's per-tick
## state at the time of the check; the
## `Callable` returns `true` when the crisis
## should trigger early, `false` to wait for
## `trigger_at_day`. The default value is a
## no-op `Callable` (always returns `false`);
## the M2 cycle 3 commit replaces it with a
## content-driven condition.
var condition: Callable = Callable()

## The crisis's player choices, as an `Array` of
## `Choice` dicts. The `Choice` shape is a plain
## `Dictionary` with the canonical keys
## `id` (StringName), `label` (StringName
## locale key), and `effect` (Callable —
## M3+ material, narrowed by the M2 cycle 3
## commit). The M2 skeleton ships an empty
## `Array`; the M2 cycle 3 commit populates it
## from the content registry.
var choices: Array = []

## Whether the crisis has been resolved. The
## `resolved` flag is set by the M2 Track B
## per-tick evaluation rule when the player
## picks a choice (or when the crisis expires).
## Once `resolved` is `true`, the crisis is
## removed from the active crisis queue.
var resolved: bool = false


## Default constructor. Starts with empty
## fields, a no-op `condition`, an empty
## `choices` array, and `resolved = false`. The
## M2 cycle 3 commit replaces this with a
## constructor that takes `(id, trigger_at_day,
## choices)`.
func _init() -> void:
	id = &""
	trigger_at_day = 0.0
	condition = Callable()
	choices = []
	resolved = false
