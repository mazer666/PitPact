# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Pactmaker-power data carrier (M4
# foundation).
#
# `Power` is the per-power data carrier for the
# Pactmaker's supernatural interventions
# (`docs/requirements.md` §5, §11). A power has
# a content-defined `effect: Callable` (the
# rule the sim invokes when the player uses the
# power), an intervention cost (the number of
# Pactmaker interventions the power consumes),
# and a cooldown (the number of in-game days
# the power is unavailable after a use).
#
# The M4 foundation commit ships the carrier as
# a SKELETON: the cooldown tracking
# (`is_on_cooldown`, `record_use`) is a full
# implementation; the `effect: Callable` field
# is reserved for the M4 Track A commit's
# per-tick rule.
#
# The carrier is a *content* carrier, not a
# *state* carrier. The state side of the
# cooldown lives on the power instance itself
# (`_last_used_at_day`); the per-tick rule
# reads the cooldown through
# `is_on_cooldown(time_days)`.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, or `src/save`.
# It imports from `src/core` only (the
# `Callable` type is built-in; no other
# dependency is required for the skeleton).
class_name Power
extends RefCounted

## The power's stable identity.
## `StringName` so it survives the
## dictionary round-trip and so
## identity comparisons are O(1)
## hashed lookups. The id is the
## dictionary key in the Pactmaker's
## `powers` array and the lookup key
## in the content catalogue.
var id: StringName = &""

## The power's display name, stored as
## a `StringName` that is a *locale key*
## (see `docs/localization.md` §"Naming").
## The M4 code does not resolve the key;
## the UI layer resolves it via `tr()` at
## draw time.
var name: StringName = &""

## The number of Pactmaker interventions
## the power consumes. The M4 default is
## `1`; the M4 Track A commit's content
## catalogue pins the per-power cost. A
## power whose `cost_interventions > 1`
## is a "big" power; the UI surfaces the
## cost in the power-use tooltip.
var cost_interventions: int = 1

## The power's effect, a `Callable` the
## sim invokes when the player uses the
## power. The M4 default is
## `Callable()` (no effect); the M4
## Track A commit's content catalogue
## fills the `Callable` from the
## per-power registration. The signature
## is
## `func(time_days: float, sim: Sim, inhabitants: Array) -> void`.
## The `Callable` is allowed in a content
## file because the *rule itself* lives
## in the sim (the `Callable` is a
## registered function, not an embedded
## GDScript function — see ADR-0011
## §"Module-boundary impact").
var effect: Callable = Callable()

## The cooldown, in in-game days. The
## M4 default is `0` (no cooldown); a
## positive value is the number of days
## the power is unavailable after a
## use. The M4 default per-power
## cooldown is content-tunable.
var cooldown_days: int = 0

## The in-game day the power was last
## used. `-1.0` until the first use.
## The field is private (leading
## underscore) and is only read through
## `is_on_cooldown(time_days)` and
## written through
## `record_use(time_days)`.
var _last_used_at_day: float = -1.0


## Default constructor. Starts with empty
## fields and a clean cooldown
## (`_last_used_at_day = -1.0`).
func _init() -> void:
	id = &""
	name = &""
	cost_interventions = 1
	effect = Callable()
	cooldown_days = 0
	_last_used_at_day = -1.0


## Whether the power is on cooldown at
## `time_days`. Returns `true` when the
## power has been used and
## `time_days - _last_used_at_day <
## cooldown_days`. A power that has
## never been used (`_last_used_at_day
## == -1.0`) returns `false`. A power
## whose `cooldown_days <= 0` returns
## `false` (the cooldown is disabled).
##
## The method is a pure function on the
## power's state and the clock; it does
## not mutate either. The UI's "is this
## power greyed out?" check calls this
## method; the per-tick rule's "can the
## player use this power?" check calls
## this method.
func is_on_cooldown(time_days: float) -> bool:
	if cooldown_days <= 0:
		return false
	if _last_used_at_day < 0.0:
		return false
	return (time_days - _last_used_at_day) < float(cooldown_days)


## Record a use of the power at
## `time_days`. Sets
## `_last_used_at_day = time_days`. The
## method is the canonical "the player
## just used this power" mutation path;
## the per-tick rule and the UI's
## power-use button call this method
## *after* invoking `effect` (or
## after the per-tick rule has
## resolved the use). A second call
## before the cooldown expires is
## allowed (the cooldown is reset, not
## stacked); the M4 default is "last
## use wins".
##
## A negative `time_days` is a
## `push_error` no-op (the M4 default
## is "strict clock": a negative
## clock value is a programming
## error, not a silent pass-through).
func record_use(time_days: float) -> void:
	if time_days < 0.0:
		push_error("Power.record_use: time_days must be non-negative (got %f)" % time_days)
		return
	_last_used_at_day = time_days
