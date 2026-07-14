# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant needs data carrier (M2 Track A).
#
# `Needs` is the per-inhabitant need vector. Four need
# channels per the M2 contract and §9 of
# `docs/requirements.md`: `food`, `rest`, `safety`,
# `recognition`. All four are normalised in `[0.0, 1.0]`,
# where `0.0` is "starving / exhausted / terrified /
# invisible" and `1.0` is "satiated / rested / safe /
# acclaimed". A high value is *good*; the need decays
# downward and recovery moves it back up.
#
# The M2 Track A commit fills in the per-tick decay
# and recovery rules:
#
#   * `decay(delta_days, has_shelter)` — apply
#     `TUNING_NEED_DECAY_PER_DAY * delta_days` to each
#     need channel. If `has_shelter` is `true`, the
#     `safety` channel decays at *half* the baseline
#     rate (a sheltered inhabitant feels safe longer
#     than an exposed one).
#
#   * `satisfy(need, amount)` — apply a positive
#     delta to a single need channel. The delta is
#     `amount` (clamped to `[0.0, 1.0]`). The amount
#     is the per-tick recovery; the caller (the room
#     the inhabitant occupies) decides the per-tick
#     amount. A "kitchen room" might feed the
#     inhabitant by `+0.10` per tick; a "habitation
#     room" might rest them by `+0.15` per tick.
#
# Both methods are *idempotent* and *commutative*:
# decay-then-satisfy produces the same final value as
# satisfy-then-decay, modulo the order of intermediate
# clamps. The class does not assert a particular
# ordering; the caller does (typically, decay first,
# then satisfy — that is the order ADR-0005 step 2
# documents).
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` and `src/sim/constants.gd` only.
class_name Needs
extends RefCounted

## The `food` need, in `[0.0, 1.0]`. Decays downward
## at `TUNING_NEED_DECAY_PER_DAY` per in-game day;
## recovers when the inhabitant eats (in a kitchen
## room with food in inventory). The M2 Track A
## commit owns the per-tick calculation.
var food: float = 1.0

## The `rest` need, in `[0.0, 1.0]`. Decays downward
## at `TUNING_NEED_DECAY_PER_DAY` per in-game day;
## recovers when the inhabitant sleeps (in a
## habitation room). The M2 Track A commit owns
## the per-tick calculation.
var rest: float = 1.0

## The `safety` need, in `[0.0, 1.0]`. Decays
## downward when the inhabitant is in a room or
## biome with hazard flags; recovers in a safe
## room. Unlike `food` and `rest`, `safety` does
## NOT decay at a flat per-day rate; the M2 Track
## A commit encodes the per-room and per-biome
## modifiers. The decay rate from
## `TUNING_NEED_DECAY_PER_DAY` is the *baseline*
## that the modifiers scale. When `has_shelter`
## is `true` (the inhabitant is in a room tagged
## `safe` or `habitation`), the baseline is
## halved.
var safety: float = 1.0

## The `recognition` need, in `[0.0, 1.0]`. Decays
## downward slowly; recovers when the inhabitant
## performs a publicly-visible action (completes a
## task, fulfils a contract, wins a conflict). The
## M2 Track A commit owns the per-tick calculation.
var recognition: float = 1.0


## Default constructor. All four needs start at
## `1.0` (the M2 contract: an inhabitant arrives
## in the realm well-fed, well-rested, safe, and
## recognised).
func _init() -> void:
	food = 1.0
	rest = 1.0
	safety = 1.0
	recognition = 1.0


## Apply the per-tick decay to every need channel.
## `delta_days` is the in-game time the tick
## advances (positive). `has_shelter` is a boolean
## flag: when `true`, the `safety` channel decays
## at half the baseline rate (a sheltered
## inhabitant feels safe longer).
##
## The decay is `TUNING_NEED_DECAY_PER_DAY *
## delta_days` per channel. The values are clamped
## to `[0.0, 1.0]` after the subtraction; a need
## that has decayed to `0.0` stays at `0.0` (it
## does not "decay into negative territory" — the
## inhabitant is starving, exhausted, terrified, or
## invisible, not *more* starving).
##
## Pre-condition: `delta_days > 0.0`. The M2
## skeleton asserts this; the M2 Track A commit
## narrows the assertion to a typed error.
func decay(delta_days: float, has_shelter: bool) -> void:
	assert(delta_days > 0.0, "Needs.decay: delta_days must be positive (got %f)" % delta_days)
	var baseline: float = SimConstants.TUNING_NEED_DECAY_PER_DAY
	var safety_rate: float = baseline
	if has_shelter:
		# The shelter bonus halves the safety
		# decay rate. The M2 baseline
		# `TUNING_NEED_DECAY_PER_DAY` is
		# `0.05`; with shelter the safety
		# decay becomes `0.025` per in-game
		# day, so a fully-satisfied
		# inhabitant reaches "unsafe" after
		# forty days (twice the un-sheltered
		# baseline).
		safety_rate = baseline * 0.5
	food = clampf(food - baseline * delta_days, 0.0, 1.0)
	rest = clampf(rest - baseline * delta_days, 0.0, 1.0)
	safety = clampf(safety - safety_rate * delta_days, 0.0, 1.0)
	recognition = clampf(recognition - baseline * delta_days, 0.0, 1.0)


## Apply a positive recovery delta to a single
## need channel. The `need` argument is a
## `StringName` naming the channel (`&"food"`,
## `&"rest"`, `&"safety"`, `&"recognition"`).
## The `amount` is the per-tick recovery (a
## non-negative `float`; values larger than what
## the channel needs are clamped to `1.0`).
##
## The function is a no-op for unknown need
## names: a typo (`&"safty"`) silently does
## nothing. This is intentional — the M2 contract
## pins the four canonical names, and a content
## typo should not crash the simulation.
##
## The amount is the per-tick increment. A caller
## in a kitchen room might call
## `needs.satisfy(&"food", 0.10)` to feed the
## inhabitant at `+0.10` per tick (a fully
## starving inhabitant reaches "satiated" in
## ten in-game days at this rate).
func satisfy(need: StringName, amount: float) -> void:
	assert(amount >= 0.0, "Needs.satisfy: amount must be non-negative (got %f)" % amount)
	var delta: float = amount
	match need:
		&"food":
			food = clampf(food + delta, 0.0, 1.0)
		&"rest":
			rest = clampf(rest + delta, 0.0, 1.0)
		&"safety":
			safety = clampf(safety + delta, 0.0, 1.0)
		&"recognition":
			recognition = clampf(recognition + delta, 0.0, 1.0)
		_:
			# Unknown need name: no-op. The
			# M2 contract pins the four
			# canonical names; an unknown
			# name is a content typo that
			# the caller should fix in
			# review.
			pass


## Convenience: return a deep-copy `Dictionary`
## representation of the four need channels, for
## save/load (ADR-0003) and for test asserts. The
## returned dictionary has the canonical keys
## `food`, `rest`, `safety`, `recognition`; the
## values are `float`s in `[0.0, 1.0]`. Round-
## tripping through `from_dict` is the test
## contract.
func to_dict() -> Dictionary:
	return {
		"food": food,
		"rest": rest,
		"safety": safety,
		"recognition": recognition,
	}


## Convenience: restore the four need channels
## from a `Dictionary` produced by `to_dict`.
## Unknown keys are ignored; missing keys leave
## the current value in place. Used by the M2
## save/load pipeline (Track C); the M2 cycle 3
## commit is the canonical caller.
func from_dict(d: Dictionary) -> void:
	if d == null:
		return
	if d.has("food"):
		food = float(d["food"])
	if d.has("rest"):
		rest = float(d["rest"])
	if d.has("safety"):
		safety = float(d["safety"])
	if d.has("recognition"):
		recognition = float(d["recognition"])
