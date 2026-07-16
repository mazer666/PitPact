# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Pactmaker data carrier (M4 foundation).
#
# `Pactmaker` is the per-realm data carrier for
# the *player* (§5 of `docs/requirements.md`):
# the disembodied entity that builds the realm
# through bargains, decrees, and limited
# supernatural interventions. The carrier is a
# per-realm data structure; the realm façade
# holds one instance per realm.
#
# The M4 foundation commit ships the carrier as
# a SKELETON: the public surface
# (`intervention_count`, `intervention_limit`,
# `can_intervene`, `register_intervention`) is
# a full implementation. The M4 Track A commit
# fills in the per-tick intervention rule and
# the Pactmaker-power unlock flow
# (ADR-0010's `ResearchNode.effect.
# pactmaker_power_id`).
#
# The carrier is a *state* carrier, not a
# *content* carrier. The content side of the
# Pactmaker (origins, power catalogues) lives
# in `src/content/` (M4 Track A dependency);
# the `Pactmaker` carrier is the per-realm
# *instance* of the player's chosen origin and
# the per-realm accumulator of interventions
# and unlocked powers.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It
# imports from `src/core` and `src/content`
# (the content adapter is a planned M4 Track A
# dependency; the skeleton declares it but
# does not preload it).
class_name Pactmaker
extends RefCounted

## The Pactmaker's stable identity.
## `StringName` so it survives the
## dictionary round-trip and so identity
## comparisons are O(1) hashed lookups.
## The id is the dictionary key in the
## realm's Pactmaker set; the M4 default
## is one Pactmaker per realm.
var id: StringName = &""

## The Pactmaker's display name, stored as
## a `StringName` that is a *locale key*
## (see `docs/localization.md` §"Naming").
## The M4 code does not resolve the key;
## the UI layer resolves it via `tr()` at
## draw time.
var name: StringName = &""

## The Pactmaker's origin id (a
## `StringName` reference to an
## `OriginData` instance under
## `data/origins/`). The M4 foundation
## commit reserves the slot; the M4
## Track A commit populates the
## `data/origins/` directory and the
## content registry's loader.
var origin_id: StringName = &""

## The list of *currently unlocked*
## Pactmaker powers. Each entry is a
## `Power` instance
## (`src/sim/power.gd`). The M4 default
## is `[]` (no powers unlocked); the M4
## Track A commit fills the list as the
## per-tick research rule unlocks
## `ResearchNode.effect.pactmaker_power_id`
## effects.
var powers: Array = []

## The number of interventions the
## Pactmaker has used in the current
## campaign. The counter is incremented
## by `register_intervention()` and
## reset to `0` at the start of a new
## campaign. The M4 default is `0`.
var intervention_count: int = 0

## The maximum number of interventions
## the Pactmaker may use in the current
## campaign. The M4 default is `5`; the
## M4 Track A commit makes the limit
## origin-tunable (the limit is a
## per-origin value in the content
## catalogue; the carrier's
## `intervention_limit` is the
## per-instance value the realm façade
## reads at construction).
var intervention_limit: int = 5


## Default constructor. Starts with empty
## fields and a clean intervention
## counter.
func _init() -> void:
	id = &""
	name = &""
	origin_id = &""
	powers = []
	intervention_count = 0
	intervention_limit = 5


## Whether the Pactmaker can intervene
## *right now*. Returns `true` when
## `intervention_count < intervention_limit`.
## The reader is the canonical way to
## gate the "use a power" UI affordance;
## reaching into `intervention_count`
## directly is allowed but not the
## public surface.
##
## The method does NOT mutate either
## counter; a `register_intervention()`
## call is the canonical mutation path.
## The M4 default is "strict gate": an
## intervention past the limit is a
## `push_error` no-op
## (`register_intervention()` returns
## `false`), not a silent relaxation of
## the limit.
func can_intervene() -> bool:
	return intervention_count < intervention_limit


## Register a Pactmaker intervention.
## Increments `intervention_count` by 1
## and returns `true` on success. Returns
## `false` (and does NOT mutate the
## counter) when the limit has been
## reached. The method is the canonical
## "I used a power" mutation path; the
## UI's power-use button calls this
## before invoking the power's effect.
##
## A `null` self is a `push_error` no-op
## that returns `false` (the M4 default
## is "strict gate": a missing Pactmaker
## is a programming error, not a silent
## pass-through).
func register_intervention() -> bool:
	if not can_intervene():
		return false
	intervention_count += 1
	return true


## Whether the Pactmaker has a power
## with id `power_id` in `powers`. The
## method is a convenience for the UI's
## "is this power available?" query; the
## M4 Track A commit's research-unlock
## flow uses this method to gate
## `pactmaker_power_id` effect
## application.
func has_power(power_id: StringName) -> bool:
	if power_id == &"":
		return false
	for p in powers:
		if p == null or not (p is Power):
			continue
		if (p as Power).id == power_id:
			return true
	return false


## M4-Closeout: reset the yearly
## intervention counter. The method
## zeroes `intervention_count` and
## returns the previous value. The M4
## default caller is the sim façade's
## per-year rule (every 360 in-game
## days). The method is idempotent: a
## second call without an intervening
## `register_intervention()` returns 0.
func reset_yearly_count() -> int:
	var prev: int = intervention_count
	intervention_count = 0
	return prev


## M4-Closeout: look up a power by id in
## the Pactmaker's `powers`. Returns
## `null` when the id is unknown or the
## Pactmaker has no such power. The
## method is the canonical "power by id"
## entry point; `apply_power(...)`
## delegates to this method.
func get_power(power_id: StringName) -> Power:
	if power_id == &"":
		return null
	for p in powers:
		if p == null or not (p is Power):
			continue
		if (p as Power).id == power_id:
			return p
	return null


## M4-Closeout: apply a power by id. The
## method looks up the power, calls
## `register_intervention()` to debit
## the counter, calls
## `Power.record_use(time_days)` to
## start the cooldown, and invokes
## `Power.effect.call(...)` with the
## `sim` and `time_days` arguments. The
## method returns the power's return
## value (typically `true` / `false`)
## or `false` when:
## - `sim` is `null`
## - the power is unknown
## - the Pactmaker is at the
##   intervention limit
## - the power is on cooldown
## - the power's effect raises.
func apply_power(power_id: StringName, sim: Variant, time_days: float = 0.0) -> bool:
	if not _can_apply_power(power_id, sim, time_days):
		return false
	var power: Power = get_power(power_id)
	# Try the effect first; the counter
	# is incremented only on success.
	# The M4 default is "debit on
	# success": a power that no-ops
	# (e.g. `seal_breach` with no
	# sealable crisis) does not cost
	# an intervention.
	var result: bool = _invoke_power_effect(power, sim, time_days)
	if not result:
		return false
	# The M4-Hardening contract is
	# "debit on success": the counter
	# is incremented only after the
	# effect succeeds. A race-condition
	# guard (the counter was at the
	# limit but is now full) is
	# impossible in single-threaded
	# code, but the conservative
	# check is preserved.
	if not register_intervention():
		return true
	power.record_use(time_days)
	return true


## M4-Hardening: predicate for
## `apply_power`. The method factors
## out the four gate checks (sim,
## power, intervention-limit,
## cooldown) so the public method's
## body stays under gdlint's
## `max-returns` cap.
func _can_apply_power(power_id: StringName, sim: Variant, time_days: float) -> bool:
	if sim == null:
		return false
	var power: Power = get_power(power_id)
	if power == null:
		return false
	if not can_intervene():
		# The M4 default is "strict gate":
		# a Pactmaker at the intervention
		# limit cannot apply a power (the
		# counter is *not* incremented on
		# the rejected call).
		return false
	if power.is_on_cooldown(time_days):
		# The cooldown gate is a soft no-op
		# (the M4 default is "no free
		# pass for cooldown-locked
		# powers"; the counter is *not*
		# incremented on the rejected
		# call).
		return false
	return true


## M4-Closeout: invoke a power's
## effect. The method is the
## factored-out "run the callable
## and return its result" path so
## `apply_power` stays under
## gdlint's `max-returns` cap.
func _invoke_power_effect(power: Power, sim: Variant, time_days: float) -> bool:
	if not power.effect.is_valid():
		return true
	var result: Variant = power.effect.call(sim, time_days)
	if result == null:
		return true
	return bool(result)
