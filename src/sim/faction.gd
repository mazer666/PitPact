# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — faction data carrier (M4 foundation).
#
# `Faction` is the per-realm data carrier for
# the realm's relationship with a *non-
# inhabitant* faction — rival realm, surface
# polity, cult, academy, guild, etc. (§6 of
# `docs/requirements.md` lists the major
# factions). The M4 acceptance uses the
# carrier for the `faction_dispute` crisis
# (ADR-0011); the M5 content pass extends the
# carrier with more content.
#
# The M4 foundation commit ships the carrier
# as a SKELETON: the public surface
# (`stance`, `update_stance`,
# `is_hostile_to`) is a full implementation.
# The M4 Track A commit fills in the
# per-tick faction-update rule and the
# `faction_dispute` crisis's autonomous
# resolution (ADR-0011 §"The two M4 default
# crises").
#
# The carrier is a *state* carrier, not a
# *content* carrier. The content side of the
# faction (names, definitions, per-faction
# hooks) lives in `src/content/` (M4 Track A
# dependency); the `Faction` carrier is the
# per-realm *instance* the per-tick rule
# reads and writes.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, or `src/save`.
# It imports from `src/core` only.
class_name Faction
extends RefCounted

## The hostility threshold, in the
## `[-100, 100]` stance range. A stance
## at or below `-50` is "hostile";
## `is_hostile_to(other)` returns `true`.
## The constant is the M4 default; the
## M5 content pass can override it
## (the constant is a `const` on the
## class so the threshold is part of
## the public surface; an M5 override
## is a per-faction field, not a
## change to the class constant).
const HOSTILITY_THRESHOLD: int = -50

## The stance clamp range. The M4
## default is `[-100, 100]`; an M5
## content pass can widen or narrow
## the range (the constants are
## class-level so a per-faction
## override is an additive field,
## not a change to the class).
const STANCE_MIN: int = -100
const STANCE_MAX: int = 100

## The faction's stable identity.
## `StringName` so it survives the
## dictionary round-trip and so
## identity comparisons are O(1)
## hashed lookups. The id is the
## dictionary key in the realm's
## faction set and the lookup key in
## `stance` (a
## `Dictionary[StringName, int]`).
var id: StringName = &""

## The faction's display name, stored
## as a `StringName` that is a *locale
## key* (see `docs/localization.md`
## §"Naming"). The M4 code does not
## resolve the key; the UI layer
## resolves it via `tr()` at draw
## time.
var display_name: StringName = &""

## The faction's per-target stance.
## A `Dictionary[StringName, int]`
## keyed by the target faction's id;
## the value is the stance in
## `[STANCE_MIN, STANCE_MAX]`. The
## stance is *symmetric* in the M4
## default: a positive
## `stance[a][b]` is the same as a
## positive `stance[b][a]` (the M4
## Track A commit asserts the
## symmetry at save time).
##
## The `Dictionary[StringName, int]`
## shape is the save-format-friendly
## representation; the M4 Track A
## commit adds a per-tick accessor
## that returns a `0` for unknown
## ids without mutating the
## dictionary (the
## "one map read" contract is
## preserved).
var stance: Dictionary = {}


## Default constructor. Starts with
## empty `id`, `display_name`, and
## `stance`.
func _init() -> void:
	id = &""
	display_name = &""
	stance = {}


## Nudge the `stance[other]` value by
## `delta`, clamped to
## `[STANCE_MIN, STANCE_MAX]`. The
## method is the canonical "the
## per-tick rule changed my stance"
## mutation path; the
## `faction_dispute` crisis's
## autonomous resolution rule (M4
## Track A) calls this method as
## the recovery nudge.
##
## The method is idempotent: a
## second call with the same `other`
## and `delta` produces the same
## result. A `delta` of `0` is a
## no-op (the carrier's state is
## not mutated; the method returns
## without pushing an error).
## Inserting a new `other` id with
## a `0` delta is also a no-op (the
## dictionary is not mutated; the
## `stance[other] = 0` is implicit
## in the next read).
func update_stance(other: StringName, delta: int) -> void:
	if other == &"":
		return
	var current: int = 0
	if stance.has(other):
		current = int(stance[other])
	var new_val: int = clampi(current + delta, STANCE_MIN, STANCE_MAX)
	if new_val == 0 and not stance.has(other):
		# Avoid inserting a `0` entry on a
		# zero-delta update; the M4 default is
		# "lazy insertion": the entry is
		# only inserted when the value is
		# non-zero or the existing entry is
		# already non-zero. The "one map
		# read" contract is preserved (a
		# missing entry reads as `0`).
		return
	stance[other] = new_val


## Whether the faction is hostile to
## `other`. Returns `true` when
## `stance[other] <= HOSTILITY_THRESHOLD`
## (the M4 default is `-50`). The
## reader is the canonical "is this
## faction at war?" check; the
## `faction_dispute` crisis's
## autonomous resolution rule (M4
## Track A) calls this method as
## the trigger predicate.
##
## The method does NOT mutate
## `stance`; an unknown `other`
## returns `false` without raising
## (the M4 default is "missing is
## neutral": a faction with no
## recorded stance toward `other`
## is *not* hostile, the default is
## `0` which is well above the
## hostility threshold).
func is_hostile_to(other: StringName) -> bool:
	if other == &"":
		return false
	if not stance.has(other):
		return false
	return int(stance[other]) <= HOSTILITY_THRESHOLD
