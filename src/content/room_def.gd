# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Room definition resource.
#
# A `RoomDef` is the data-driven schema for a single room type (e.g. the
# Hearth). It is loaded by `ContentRegistry` from `res://data/rooms/*.tres`
# and is the contract between the content data and the runtime in
# `src/realm/hearth.gd` (Track A). Per ADR-0002, `src/content` is data
# only; this class holds no behaviour beyond what is needed for the
# `Resource` round-trip and the validation contract.
#
# The field set is the one pinned in ADR-0003 §"save body" plus the
# room-specific fields Track A needs. The fields are typed in the
# editor via `_init` and the `@export` annotations on the
# `class_name`d script so that an invalid `.tres` file fails fast at
# load time, not silently at runtime.
class_name RoomDef
extends Resource

## Stable id used for content lookup and for cross-references in
## saves. MUST be a `StringName` so it can be used as a `Dictionary`
## key without conversion.
@export var id: StringName = &""

## Localised display name. The `.tres` file stores the
## `StringName` lookup key; the runtime resolves it against the
## active locale via `tr(...)` so the English literal never
## appears in `.gd` source.
@export var display_name: StringName = &""

## Construction time in in-game days. Mirrored into the save
## body so a partially-built Hearth round-trips correctly.
@export var build_time_days: int = 0

## Labour cost in worker-days. The runtime converts this to
## inhabitant-hours via the `src/realm` labour model (lands
## with Track A).
@export var labour_cost: int = 0

## Materials cost as a `Dictionary[StringName, int]` mapping
## resource ids to required amounts. The `Dictionary` is the
## canonical form; `ResourceSaver` round-trips it.
@export var materials_cost: Dictionary = {}

## Maximum number of inhabitants the room can hold.
@export var capacity: int = 0

## Free-form tag list used by the simulation for "is this a
## starter room?", "is this a defensive room?", etc. Tags are
## versioned with the content set.
@export var tags: PackedStringArray = PackedStringArray()


## Validate the definition against the ADR-0003 contract.
## Returns an empty `PackedStringArray` on success, or a list of
## human-readable error messages. The validator is a single
## place to land schema rules so a `.tres` file with a bad
## `id` (empty StringName) or a negative `capacity` fails fast
## with a useful error message.
func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	if String(id).is_empty():
		errs.append("RoomDef.id is empty; expected a non-empty StringName")
	if String(display_name).is_empty():
		(
			errs
			. append(
				"RoomDef.display_name is empty; expected a StringName key into locales/source_strings.csv"
			)
		)
	if build_time_days < 0:
		errs.append("RoomDef.build_time_days is negative (%d); must be >= 0" % build_time_days)
	if labour_cost < 0:
		errs.append("RoomDef.labour_cost is negative (%d); must be >= 0" % labour_cost)
	if capacity < 0:
		errs.append("RoomDef.capacity is negative (%d); must be >= 0" % capacity)
	for k in materials_cost.keys():
		if not (k is StringName) and not (k is String):
			errs.append("RoomDef.materials_cost key %s is not a StringName/String" % str(k))
			break
		var v: Variant = materials_cost[k]
		if not (v is int) or int(v) < 0:
			errs.append("RoomDef.materials_cost[%s] is not a non-negative int" % str(k))
			break
	return errs
