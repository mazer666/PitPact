# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inter-inhabitant relationship data carrier
# (M2 skeleton).
#
# `Relationship` is the per-edge data carrier for the
# relationship graph. The graph itself is owned by the
# sim (`Sim` holds a `Dictionary[StringName,
# Array[Relationship]]` keyed by the lower-sorted of
# the two endpoint ids, so `(a, b)` and `(b, a)`
# resolve to the same edge). The M2 skeleton ships
# the `a`, `b`, `affinity`, and `history` fields and
# the `class_name`; the M2 Track B commit fills in
# the per-tick update rule (step 5 in ADR-0005).
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name Relationship
extends RefCounted

## The first endpoint of the relationship, as an
## inhabitant id (`StringName`). For canonical
## (a, b) pairs, `a` is the lexicographically
## smaller of the two ids; the sim's relationship
## graph enforces this invariant when an edge is
## inserted. The M2 cycle 3 commit adds the
## canonicalisation helper the sim calls.
var a: StringName = &""

## The second endpoint of the relationship, as an
## inhabitant id (`StringName`). For canonical
## (a, b) pairs, `b` is the lexicographically
## greater of the two ids. The invariant is the
## same as for `a`; the cycle 3 commit enforces
## it on insertion.
var b: StringName = &""

## The relationship's affinity, in `[-1.0, 1.0]`.
## `-1.0` is "implacable enemy", `0.0` is
## "indifferent", `+1.0` is "sworn ally". The
## affinity drifts toward `0.0` at
## `TUNING_RELATIONSHIP_DRIFT_PER_DAY` per
## in-game day; events move it up or down by
## content-defined deltas. The M2 Track B
## commit owns the per-tick update.
var affinity: float = 0.0

## The history of events that have shaped this
## relationship, as a `PackedStringArray` of
## event ids. The history is append-only; the
## M2 Track B commit adds the cap policy. A
## long history is what makes the M5 "tell
## me about the rift between these two
## inhabitants" inspector panel work.
var history: PackedStringArray = PackedStringArray()


## Default constructor. Starts with empty
## endpoints, a neutral `0.0` affinity, and an
## empty history. The M2 cycle 3 commit replaces
## this with a constructor that takes
## `(a, b, affinity)` and asserts `a < b`
## (the canonicalisation invariant).
func _init() -> void:
	a = &""
	b = &""
	affinity = 0.0
	history = PackedStringArray()
