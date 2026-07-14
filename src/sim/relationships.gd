# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inter-inhabitant relationship data carrier
# (M2 Track A).
#
# `Relationship` is the per-edge data carrier for the
# relationship graph. The graph itself is owned by the
# sim (`Sim` holds a `Dictionary[StringName,
# Array[Relationship]]` keyed by the lower-sorted of
# the two endpoint ids, so `(a, b)` and `(b, a)`
# resolve to the same edge).
#
# The M2 Track A commit fills in `register(a, b,
# event_id)`:
#
#   * `register(a, b, event_id)` — records the
#     `event_id` on the relationship history and
#     nudges the affinity by the
#     `TUNING_RELATIONSHIP_POSITIVE_NUDGE` or
#     `TUNING_RELATIONSHIP_NEGATIVE_NUDGE`
#     constant, depending on the event kind
#     (cooperative kinds nudge up, conflict
#     kinds nudge down). The affinity is bounded
#     in `[-1.0, 1.0]`.
#
# The M2 Track A commit also adds the per-tick
# drift helper `drift(delta_days)` that the sim
# calls in step 5 of ADR-0005: every tick, the
# affinity moves toward `0.0` at
# `TUNING_RELATIONSHIP_DRIFT_PER_DAY *
# delta_days`. The drift is symmetric (a
# positive affinity drifts down, a negative
# affinity drifts up).
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` and `src/sim/constants.gd` only.
class_name Relationship
extends RefCounted

## The first endpoint of the relationship, as an
## inhabitant id (`StringName`). For canonical
## (a, b) pairs, `a` is the lexicographically
## smaller of the two ids; the sim's relationship
## graph enforces this invariant when an edge is
## inserted.
var a: StringName = &""

## The second endpoint of the relationship, as an
## inhabitant id (`StringName`). For canonical
## (a, b) pairs, `b` is the lexicographically
## greater of the two ids. The invariant is the
## same as for `a`.
var b: StringName = &""

## The relationship's affinity, in `[-1.0, 1.0]`.
## `-1.0` is "implacable enemy", `0.0` is
## "indifferent", `+1.0` is "sworn ally". The
## affinity drifts toward `0.0` at
## `TUNING_RELATIONSHIP_DRIFT_PER_DAY` per
## in-game day; events move it up or down by
## content-defined deltas.
var affinity: float = 0.0

## The history of events that have shaped this
## relationship, as a `PackedStringArray` of
## event ids. The history is append-only; the
## M2 Track A commit adds the cap policy (32
## entries, the same cap as `EventMemory`).
## A long history is what makes the M5
## "tell me about the rift between these two
## inhabitants" inspector panel work.
var history: PackedStringArray = PackedStringArray()


## Default constructor. Starts with empty
## endpoints, a neutral `0.0` affinity, and an
## empty history.
func _init() -> void:
	a = &""
	b = &""
	affinity = 0.0
	history = PackedStringArray()


## Construct a `Relationship` between two
## inhabitant ids. The constructor canonicalises
## the pair so `a < b` (lexicographic) is the
## invariant the sim relies on. The id
## comparison uses GDScript's default
## `StringName` ordering, which is byte-wise
## and stable.
func _init_canonical(p_a: StringName, p_b: StringName) -> void:
	if String(p_a) <= String(p_b):
		a = p_a
		b = p_b
	else:
		a = p_b
		b = p_a
	affinity = 0.0
	history = PackedStringArray()


## Record an event on the relationship's history
## and nudge the affinity. The function is the
## per-tick step-5 helper ADR-0005 documents.
##
## Parameters:
##   * `event_id` — the `StringName` id of the
##     event being recorded. Added to the
##     `history` array.
##   * `event_kind` — the `StringName` kind of
##     the event. The function looks at the
##     kind to decide whether the nudge is
##     positive (a cooperative kind) or
##     negative (a conflict kind).
##   * `delta_override` — optional `float` to
##     override the default nudge magnitude
##     (used by content-driven relationship
##     rules). `0.0` means "use the default
##     constant".
##
## Cooperative kinds (positive nudge):
##   * `&"task.completed"`
##   * `&"contract.fulfilled"`
##   * `&"room.built"`
##   * `&"recognition.awarded"`
##   * `&"cooperative"` (generic catch-all for
##     content-defined cooperative events)
##
## Conflict kinds (negative nudge):
##   * `&"conflict"`
##   * `&"contract.breached"`
##   * `&"crisis.unresolved"`
##   * `&"needs.deprivation"` (severe,
##     relationship-damaging deprivation)
##
## Unknown kinds are no-ops: the function
## records the event_id in the history (so
## the M5 inspector still shows the event)
## but does not move the affinity. This is
## the safe default for content kinds that
## land in future milestones.
##
## The affinity is clamped to `[-1.0, 1.0]`
## after the nudge.
##
## Returns the new affinity after the nudge
## (a `float` in `[-1.0, 1.0]`).
func register(event_id: StringName, event_kind: StringName, delta_override: float = 0.0) -> float:
	# Append to history. The history is
	# append-only; the M2 contract pins
	# that property (it is what the M5
	# "tell me about the rift" panel
	# depends on). The history is capped
	# at the per-inhabitant cap; the
	# eviction policy is "drop the
	# oldest first", the same policy as
	# `EventMemory`.
	if String(event_id) != "":
		history.append(event_id)
		var cap: int = SimConstants.TUNING_EVENT_MEMORY_CAPACITY
		while history.size() > cap and history.size() > 0:
			# `PackedStringArray` does not
			# expose `pop_front`; the M2
			# workaround is a slice from
			# index 1 onward. The history
			# is small (≤ 32 entries), so
			# the O(n) slice is fine.
			var trimmed: PackedStringArray = PackedStringArray()
			for i in range(1, history.size()):
				trimmed.append(history[i])
			history = trimmed
	# Decide the nudge magnitude. The
	# default is the per-constant; the
	# content override (when provided)
	# replaces it. The function does
	# not consult the sim's RNG: the
	# nudge is deterministic, per the
	# M2 contract. (The M5+ "random
	# social drift" feature is content,
	# not M2.)
	var nudge: float = 0.0
	if delta_override != 0.0:
		nudge = delta_override
	elif _is_cooperative_kind(event_kind):
		nudge = SimConstants.TUNING_RELATIONSHIP_POSITIVE_NUDGE
	elif _is_conflict_kind(event_kind):
		nudge = SimConstants.TUNING_RELATIONSHIP_NEGATIVE_NUDGE
	# Apply the nudge, clamped to the
	# natural affinity range. A nudge
	# past the cap is a no-op (the cap
	# is the natural limit; the function
	# does not "overshoot" the affinity).
	if nudge != 0.0:
		var new_affinity: float = affinity + nudge
		affinity = clampf(new_affinity, -1.0, 1.0)
	return affinity


## Apply the per-tick drift toward `0.0`. The
## drift is `TUNING_RELATIONSHIP_DRIFT_PER_DAY *
## delta_days` toward zero, regardless of the
## sign of the current affinity. A positive
## affinity drifts down; a negative affinity
## drifts up; a zero affinity stays at zero.
##
## The function is symmetric: an absolute-
## value move toward zero. The implementation
## is a sign-preserving move toward `0.0`,
## which is algebraically equivalent to
## `affinity -= sign(affinity) *
## TUNING_RELATIONSHIP_DRIFT_PER_DAY *
## delta_days`.
func drift(delta_days: float) -> void:
	assert(
		delta_days > 0.0, "Relationship.drift: delta_days must be positive (got %f)" % delta_days
	)
	var step: float = SimConstants.TUNING_RELATIONSHIP_DRIFT_PER_DAY * delta_days
	if affinity > 0.0:
		affinity = maxf(0.0, affinity - step)
	elif affinity < 0.0:
		affinity = minf(0.0, affinity + step)
	# A zero affinity stays at zero; the
	# `else` branch is implicit.


## Return the affinity of this relationship.
## Convenience accessor for the sim's step-5
## code; equivalent to reading `affinity`
## directly. Named `get_affinity()` so the
## sim can call it through a uniform edge
## interface (a `Relationship` and a
## `Crisis`-style edge both expose
## `get_affinity()` and `get_a()`).
func get_affinity() -> float:
	return affinity


## Return the first endpoint. See `get_affinity`
## for the rationale.
func get_a() -> StringName:
	return a


## Return the second endpoint. See `get_affinity`
## for the rationale.
func get_b() -> StringName:
	return b


## Convenience: return a deep-copy `Dictionary`
## representation of the relationship, for
## save/load (ADR-0003) and for test asserts.
## The returned dictionary has the canonical
## keys `a`, `b`, `affinity`, `history`;
## round-tripping through `from_dict` is the
## test contract.
func to_dict() -> Dictionary:
	return {
		"a": a,
		"b": b,
		"affinity": affinity,
		"history": PackedStringArray(history),
	}


## Convenience: restore the relationship from a
## `Dictionary` produced by `to_dict`. Unknown
## keys are ignored; missing keys leave the
## current value in place. Used by the M2
## save/load pipeline (Track C); the M2 cycle 3
## commit is the canonical caller.
func from_dict(d: Dictionary) -> void:
	if d == null:
		return
	if d.has("a"):
		a = StringName(d["a"])
	if d.has("b"):
		b = StringName(d["b"])
	if d.has("affinity"):
		affinity = float(d["affinity"])
	if d.has("history") and d["history"] is PackedStringArray:
		history = PackedStringArray(d["history"])


# --- private helpers ----------------------------------------------------


## Decide whether an event kind is cooperative
## (positive nudge) or not. The list is the
## M2 Track A baseline; future Track B and M3+
## commits add content kinds. Unknown kinds
## return `false` (the default).
func _is_cooperative_kind(kind: StringName) -> bool:
	return (
		kind == &"task.completed"
		or kind == &"contract.fulfilled"
		or kind == &"room.built"
		or kind == &"recognition.awarded"
		or kind == &"cooperative"
	)


## Decide whether an event kind is conflict
## (negative nudge) or not. The list is the
## M2 Track A baseline; future Track B and M3+
## commits add content kinds. Unknown kinds
## return `false` (the default).
func _is_conflict_kind(kind: StringName) -> bool:
	return (
		kind == &"conflict"
		or kind == &"contract.breached"
		or kind == &"crisis.unresolved"
		or kind == &"needs.deprivation"
	)
