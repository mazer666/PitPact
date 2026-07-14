# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant morale/stress value object.
#
# `Morale` is a small value object that holds the two
# affective scalars §9 of `docs/requirements.md` asks
# every inhabitant to carry:
#
#   * `morale` — a `float` in `[-1.0, 1.0]`. `+1.0` is
#     "elated", `0.0` is "neutral", `-1.0` is "despairing".
#   * `stress` — a `float` in `[0.0, 1.0]`. `0.0` is
#     "calm", `1.0` is "overwhelmed".
#
# The two are *related but not the same* — a thriving
# inhabitant can be calm (low stress, high morale); a
# thriving inhabitant who is being chased by a rival
# can be high-stress but still positive-morale; a
# starving inhabitant who has given up is low-morale
# and high-stress.
#
# §9.1 spec rules this class encodes:
#
#   R1. Morale is *derived* from needs, not stored
#       directly. The class recomputes morale from
#       the four needs (food, rest, safety,
#       recognition) on every `tick()` call, weighted
#       by the per-need weights in
#       `SimConstants.TUNING_MORALE_WEIGHT_*`. A
#       fully-satisfied inhabitant lands at
#       `morale = +1.0`; a fully-deprived inhabitant
#       lands at `morale = -1.0`.
#
#   R2. Stress is *derived* from morale, not from
#       needs directly. The class uses the rule
#       "low morale breeds stress": a negative-morale
#       inhabitant accumulates stress; a positive-
#       morale inhabitant loses stress. A neutral-
#       morale inhabitant's stress decays slowly
#       toward `0.0` at
#       `SimConstants.TUNING_STRESS_DECAY_PER_DAY`
#       per in-game day.
#
#   R3. Stress decays slowly even when morale is
#       neutral. The decay rate is
#       `TUNING_STRESS_DECAY_PER_DAY`; the M2
#       baseline of `0.02` means a fully-stressed
#       inhabitant reaches "calm" after fifty
#       in-game days of being well-fed and safe.
#
#   R4. The morale and stress values are *clamped*
#       to their natural ranges after every
#       adjustment. The clamp is the public
#       contract; callers that bypass `tick()`
#       (e.g. tests that set `morale` directly) are
#       responsible for their own clamping.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` and `src/sim/constants.gd` only.
class_name Morale
extends RefCounted

## The inhabitant's morale scalar, in `[-1.0, 1.0]`.
## `+1.0` is "elated", `0.0` is "neutral", `-1.0` is
## "despairing". The value is recomputed from the
## four needs on every `tick()` call (R1).
var morale: float = 0.0

## The inhabitant's stress scalar, in `[0.0, 1.0]`.
## `0.0` is "calm", `1.0` is "overwhelmed". The
## value is recomputed from `morale` on every
## `tick()` call (R2, R3).
var stress: float = 0.0


## Default constructor. Starts at neutral morale
## (`0.0`) and calm stress (`0.0`). The M2 contract
## pins this as the "freshly arrived" state — a
## new inhabitant's morale/stress reflect their
## starting conditions, not their journey.
func _init() -> void:
	morale = 0.0
	stress = 0.0


## Derive morale from the four needs, derive stress
## from morale, decay stress slowly. The function
## is the per-tick affective update that step 2 of
## `Sim.tick()` (ADR-0005) drives.
##
## Parameters:
##   * `needs`         — a `Needs` instance whose
##                        four channels are read.
##   * `delta_days`    — the in-game days the tick
##                        advances (positive).
##
## Algorithm (R1, R2, R3):
##
##   1. Recompute `morale` as the weighted sum of
##      `(need - 0.5) * 2` for each of the four
##      needs. A need at `0.0` contributes `-weight`
##      to morale; a need at `1.0` contributes
##      `+weight`. A need at `0.5` contributes
##      `0.0`. The weights come from
##      `SimConstants.TUNING_MORALE_WEIGHT_*` and
##      sum to `1.0` by construction.
##
##   2. Update `stress`:
##      * If `morale < 0.0`: `stress +=
##        |morale| * delta_days * 0.5` (low
##        morale breeds stress; the `0.5` factor
##        means a fully-negative-morale
##        inhabitant gains `0.5` stress per
##        in-game day, reaching `1.0` after two
##        such days).
##      * If `morale >= 0.0`: `stress -=
##        delta_days * TUNING_STRESS_DECAY_PER_DAY
##        * (1.0 + morale)` (high morale soothes;
##        the `(1.0 + morale)` factor means a
##        fully-positive-morale inhabitant
##        recovers at twice the baseline rate).
##      * If `morale` is exactly `0.0`: `stress`
##        decays at the baseline rate (the
##        `(1.0 + morale)` term reduces to `1.0`).
##
##   3. Clamp both values to their natural ranges
##      (R4).
func tick(needs: Needs, delta_days: float) -> void:
	# Pre-condition: `needs` is non-null and
	# `delta_days` is positive. Asserted at the
	# top so a regression surfaces as a test
	# failure, not a silent NaN.
	assert(needs != null, "Morale.tick: needs is null")
	assert(delta_days > 0.0, "Morale.tick: delta_days must be positive (got %f)" % delta_days)

	# Step 1: derive morale from needs. The
	# weighted sum is the contract (R1).
	var w_food: float = SimConstants.TUNING_MORALE_WEIGHT_FOOD
	var w_rest: float = SimConstants.TUNING_MORALE_WEIGHT_REST
	var w_safety: float = SimConstants.TUNING_MORALE_WEIGHT_SAFETY
	var w_recog: float = SimConstants.TUNING_MORALE_WEIGHT_RECOGNITION
	var m: float = 0.0
	m += w_food * (needs.food - 0.5) * 2.0
	m += w_rest * (needs.rest - 0.5) * 2.0
	m += w_safety * (needs.safety - 0.5) * 2.0
	m += w_recog * (needs.recognition - 0.5) * 2.0
	# Clamp to `[-1.0, 1.0]` defensively. The
	# weights sum to `1.0` so the natural range
	# is `[-1.0, 1.0]`, but a misconfigured
	# content datum could overflow.
	morale = clampf(m, -SimConstants.TUNING_MORALE_CAP, SimConstants.TUNING_MORALE_CAP)

	# Step 2: derive stress from morale (R2, R3).
	var s: float = stress
	if morale < 0.0:
		# Low morale breeds stress. The
		# `0.5` factor is the M2 baseline
		# rate at which a fully-negative-
		# morale inhabitant accumulates
		# stress. A `0.1` negative morale
		# accumulates `0.05` stress per
		# day, reaching `1.0` after twenty
		# such days.
		s += absf(morale) * delta_days * 0.5
	else:
		# High morale (or neutral) soothes.
		# The `(1.0 + morale)` factor scales
		# the baseline decay rate up to
		# `2x` at peak morale; the baseline
		# rate is the `TUNING_STRESS_DECAY_PER_DAY`
		# constant. A neutral-morale
		# inhabitant decays at the
		# baseline rate.
		s -= delta_days * SimConstants.TUNING_STRESS_DECAY_PER_DAY * (1.0 + morale)
	stress = clampf(s, 0.0, SimConstants.TUNING_STRESS_CAP)


## Convenience: return a deep-copy `Dictionary`
## representation of the morale/stress pair, for
## save/load (ADR-0003) and for test asserts. The
## returned dictionary has the canonical keys
## `morale` and `stress`; round-tripping through
## `from_dict` is the test contract.
func to_dict() -> Dictionary:
	return {
		"morale": morale,
		"stress": stress,
	}


## Convenience: restore morale/stress from a
## `Dictionary` produced by `to_dict`. Unknown
## keys are ignored; missing keys leave the
## current value in place. Used by the M2
## save/load pipeline (Track C); the M2 cycle 3
## commit is the canonical caller.
func from_dict(d: Dictionary) -> void:
	if d == null:
		return
	if d.has("morale"):
		morale = float(d["morale"])
	if d.has("stress"):
		stress = float(d["stress"])
