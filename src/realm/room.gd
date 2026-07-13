# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Room (a promoted Zone) and the Room state
# machine (ADR-0004).
#
# A `Room` is a zone that has been *promoted*: the player
# named it, gave it a purpose, and the simulation is
# driving it through a lifecycle. Promotion is one-way: a
# demoted room is no longer a room.
#
# The lifecycle is a strict state machine (per ADR-0004
# and the M1 task spec):
#
#   PLANNED → CONSTRUCTING → ACTIVE → DECAYING → ABANDONED
#
# Transitions are state-machine driven (no string
# matching). The transitions live in
# `_try_transition()`. Each transition has a single
# documented trigger; the trigger is the only place a
# caller can move the state forward.
#
# Per ADR-0002, this file does not import from `src/ui` or
# `src/save`. It imports from `src/core`, `src/world`,
# `src/content`, and `src/audit`.
class_name Room
extends RefCounted

## Room states (ADR-0004 + the M1 task spec). The enum is
## `int` for stable JSON round-trip; the M1 save format
## encodes the integer and the deserialiser verifies it.
##
## The states, in order:
##
##   PLANNED       — the zone has been promoted; nothing
##                   has happened yet. The player has
##                   committed to the room.
##   CONSTRUCTING  — construction labour has started.
##                   The room is not yet operational; the
##                   `days_in_state` counter advances
##                   toward `build_time_days`.
##   ACTIVE        — the room is operational. Inhabitants
##                   can be assigned. Production /
##                   research / storage happens here.
##   DECAYING      — the room is operational but
##                   neglected. Resources are
##                   deteriorating; inhabitants may leave.
##   ABANDONED     — final state. The room is no longer
##                   functional. The zone can be
##                   demoted back to a plain zone.
enum RoomState {
	PLANNED = 0,
	CONSTRUCTING = 1,
	ACTIVE = 2,
	DECAYING = 3,
	ABANDONED = 4,
}

## The current state of the room. Read by the UI; mutated
## only via `_try_transition()`.
var state: int = RoomState.PLANNED

## The `RoomDef` resource that defines this room. The
## runtime reads `build_time_days`, `labour_cost`,
## `materials_cost`, and `capacity` from this resource
## (per the M1 task spec: "The runtime reads this; do not
## hard-code values in src/realm/hearth.gd").
var definition: Resource

## The tiles belonging to the room, in zone-order
## (ascending `(y, x)`, per ADR-0004). The room owns its
## tiles; a tile is in AT MOST one room at a time
## (overlapping rooms are not allowed; the painter tool
## refuses to paint a zone that intersects an existing
## room).
var tiles: Array = []  # Array[Vector2i]

## The bounding box of the room, recomputed on promotion
## and on tile-list edits. Used by the renderer and the
## save format.
var bounds: Rect2i = Rect2i(0, 0, 0, 0)

## The number of in-game days the room has been in the
## current state. Reset on every transition; the state
## machine's triggers are written in terms of this counter
## so the lifecycle is fully deterministic.
var days_in_state: float = 0.0

## The room's purpose. Mirrors the `ZonePurpose` of the
## zone the room was promoted from (per ADR-0004:
## "promotion does not change the spatial footprint's
## purpose").
var purpose: int = 0

## A monotonically increasing per-room version. Bumped on
## every observable change. The renderer's redraw decision
## and the save format's "has anything changed?" check
## both use this counter.
var version: int = 0


## Default constructor. Most callers should use
## `Room.promote(zone, definition)` instead; this
## constructor is kept for the save-loader path.
func _init(p_definition: Resource = null) -> void:
	definition = p_definition
	version = 0


## Factory: promote a zone to a room. The new room is in
## state `PLANNED`, has the given `definition`, and owns
## the zone's tiles. The zone's `purpose` is mirrored
## into the room's `purpose` field (per ADR-0004).
##
## `definition` MUST be a `RoomDef` (per the M1 task
## spec); the factory reads `build_time_days`,
## `labour_cost`, `materials_cost`, and `capacity` from
## it. A `null` definition is rejected with `push_error`
## and a `null` return.
static func promote(zone, definition: Resource) -> Room:
	if zone == null:
		push_error("Room.promote: zone is null")
		return null
	if definition == null:
		push_error("Room.promote: definition is null")
		return null
	var r: Room = Room.new(definition)
	r.tiles = zone.tiles.duplicate()
	r.purpose = zone.purpose
	# Compute the bounding box from the tile list.
	if r.tiles.size() > 0:
		var min_x: int = r.tiles[0].x
		var min_y: int = r.tiles[0].y
		var max_x: int = r.tiles[0].x
		var max_y: int = r.tiles[0].y
		for t in r.tiles:
			if t.x < min_x:
				min_x = t.x
			if t.y < min_y:
				min_y = t.y
			if t.x > max_x:
				max_x = t.x
			if t.y > max_y:
				max_y = t.y
		r.bounds = Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))
	r.state = RoomState.PLANNED
	r.days_in_state = 0.0
	r.version = 0
	return r


## Advance the room by `delta` in-game days. The
## state machine is fully deterministic: the same
## `delta` sequence produces the same state sequence.
## The M1 transition rules are:
##
##   PLANNED + (1 tick of construction labour) → CONSTRUCTING
##   CONSTRUCTING + (build_time_days reached)    → ACTIVE
##   ACTIVE + (no inhabitants for N days)        → DECAYING
##   DECAYING + (decay_days reached)             → ABANDONED
##
## The first transition is taken on the FIRST tick
## (the room does not sit in PLANNED for a full day;
## the M1 task spec says "tick 1 day → Hearth
## transitions PLANNED → CONSTRUCTING → ACTIVE").
## Construction completes in `build_time_days` ticks.
##
## `inhabitants`: optional list of inhabitants currently
## assigned to the room. The DECAYING trigger is
## "no inhabitants for `decay_threshold_days`" — M1
## uses a default of `build_time_days * 2` for the
## threshold so the demo state machine completes in
## a few ticks.
func tick(delta: float, inhabitants: Array = []) -> void:
	if delta <= 0.0:
		return
	days_in_state += delta
	_try_transition(inhabitants)


# --- state-machine internals ------------------------------------------


## Single state-machine dispatcher. Each branch is
## deterministic and side-effect-free except for writing
## `state` and resetting `days_in_state`. The triggers
## are documented in `tick()`.
func _try_transition(inhabitants: Array) -> void:
	match state:
		RoomState.PLANNED:
			# The M1 spec: one tick takes the room
			# from PLANNED to CONSTRUCTING. We use
			# a zero-day threshold so the transition
			# fires on the first tick.
			_set_state(RoomState.CONSTRUCTING)
		RoomState.CONSTRUCTING:
			var build_days: int = _build_time_days()
			if days_in_state >= float(build_days):
				_set_state(RoomState.ACTIVE)
		RoomState.ACTIVE:
			# DECAYING trigger: no inhabitants for
			# `decay_threshold_days`. M1 uses a
			# default threshold derived from the
			# definition's `build_time_days`; a
			# proper inhabitant-absence clock lives
			# in M2.
			var threshold: int = max(1, _build_time_days() * 2)
			if inhabitants.size() == 0 and days_in_state >= float(threshold):
				_set_state(RoomState.DECAYING)
		RoomState.DECAYING:
			# ABANDONED trigger: the same threshold
			# as DECAYING's, so the room is
			# abandoned after another threshold
			# period of decay.
			var threshold: int = max(1, _build_time_days() * 2)
			if days_in_state >= float(threshold):
				_set_state(RoomState.ABANDONED)
		RoomState.ABANDONED:
			# Terminal state. No transition.
			pass


## Internal: set the state and reset the per-state day
## counter. Bumps `version` so the renderer redraws.
func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	days_in_state = 0.0
	version += 1


## Internal: read `build_time_days` from the definition.
## Returns a safe default of 1 if the definition is
## missing or the field is not set, so the M1 demo
## still ticks.
func _build_time_days() -> int:
	if definition == null:
		return 1
	if not ("build_time_days" in definition):
		return 1
	return int(definition.get("build_time_days"))


## External: read `capacity` from the definition. Returns
## 0 if the definition is missing. The UI uses this to
## size the inhabitant list.
func capacity() -> int:
	if definition == null:
		return 0
	if not ("capacity" in definition):
		return 0
	return int(definition.get("capacity"))


## External: read `display_name` (a StringName
## localisation key) from the definition. Returns an
## empty StringName if the definition is missing. The UI
## resolves the key via `tr(...)`.
func display_name_key() -> StringName:
	if definition == null:
		return &""
	if not ("display_name" in definition):
		return &""
	return StringName(String(definition.get("display_name")))


## External: read `id` from the definition. Returns an
## empty StringName if the definition is missing. The
## save format uses the id as the room's stable
## identifier across versions.
func definition_id() -> StringName:
	if definition == null:
		return &""
	if not ("id" in definition):
		return &""
	return StringName(String(definition.get("id")))


## Serialise the room to a JSON-friendly dict. The
## definition is stored by its `id` (a `StringName`); the
## loader reads the id and re-resolves it against the
## content registry.
func to_dict() -> Dictionary:
	return {
		"state": state,
		"days_in_state": days_in_state,
		"purpose": purpose,
		"version": version,
		"definition_id": String(definition_id()),
		"tiles": tiles.duplicate(),
		"bounds":
		{"x": bounds.position.x, "y": bounds.position.y, "w": bounds.size.x, "h": bounds.size.y},
	}


## Deserialise a dict produced by `to_dict()`. The
## `definition_id` is stored; the caller is responsible
## for resolving the id back to a `RoomDef` (via
## `ContentRegistry`) and re-assigning it to `definition`.
## The state machine's state and counter are restored
## exactly.
func from_dict(d: Dictionary) -> bool:
	if d.has("state"):
		state = int(d["state"])
	if d.has("days_in_state"):
		days_in_state = float(d["days_in_state"])
	if d.has("purpose"):
		purpose = int(d["purpose"])
	if d.has("version"):
		version = int(d["version"])
	if d.has("tiles") and d["tiles"] is Array:
		tiles = (d["tiles"] as Array).duplicate()
	if d.has("bounds") and d["bounds"] is Dictionary:
		var b: Dictionary = d["bounds"]
		bounds = Rect2i(
			Vector2i(int(b.get("x", 0)), int(b.get("y", 0))),
			Vector2i(int(b.get("w", 0)), int(b.get("h", 0)))
		)
	return true
