# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the realm façade (Realm).
#
# `Realm` is the single object the UI sees. It composes
# `src/world/WorldState` (the spatial state) and the list
# of `Room`s (the promoted zones) into a player-visible
# "realm" view. It is the public entry point of
# `src/realm/`, per ADR-0002.
#
# The façade:
#   * owns the per-realm `WorldState`,
#   * owns the list of `Room`s,
#   * routes player commands (paint, promote) to the
#     right subsystem,
#   * exposes save/load hooks that delegate to
#     `src/save/RealmSerializer`,
#   * exposes a deterministic `tick(delta)` that drives
#     the room state machines.
#
# Per ADR-0002, this file does not import from `src/ui`.
# It imports from `src/core`, `src/world`, `src/sim`,
# `src/content`, `src/save`, and `src/audit`.
class_name Realm
extends RefCounted

## The realm's spatial state.
var world: RefCounted

## The list of rooms in the realm, in creation order.
var rooms: Array = []

## The seed the realm was created from.
var seed: int = 0

## Per-realm version counter.
var version: int = 0

## In-game clock, in days.
var time_days: float = 0.0


## Default constructor.
func _init() -> void:
	world = null
	rooms = []
	seed = 0
	version = 0
	time_days = 0.0


## Factory: build a new realm.
static func create(p_seed: int, p_w: int = 12, p_h: int = 12) -> RefCounted:
	var r: RefCounted = Realm.new()
	r.seed = p_seed
	r.world = WorldState.create(p_seed, p_w, p_h)
	return r


## Paint a rectangular zone.
func paint_zone(rect: Rect2i, purpose: int) -> Array:
	if world == null:
		return []
	var zones: Array = world.paint_zone(rect, purpose)
	version += 1
	return zones


## Find all zones of the given purpose.
func find_zones(purpose: int) -> Array:
	if world == null:
		return []
	return world.find_zones(purpose)


## Look up the zone purpose of a single tile.
func zone_at(x: int, y: int) -> int:
	if world == null:
		return 0
	return int(world.zone_at(x, y))


## Promote the zone at `rect` to a room.
func promote_zone(rect: Rect2i, purpose: int, definition: Resource) -> RefCounted:
	if world == null:
		return null
	if definition == null:
		push_error("Realm.promote_zone: definition is null")
		return null
	var zones: Array = world.find_zones(purpose)
	for z in zones:
		if z == null:
			continue
		var zb: Rect2i = z.bounds
		if _rects_overlap(rect, zb):
			var room: RefCounted = Room.promote(z, definition)
			if room != null:
				rooms.append(room)
				version += 1
			return room
	return null


## Tick the realm by `delta` in-game days.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	time_days += delta
	for room in rooms:
		if room == null:
			continue
		room.tick(delta)


## Save the realm.
func save() -> Dictionary:
	var RealmSerializerClass := load("res://src/save/realm_serializer.gd")
	var seed_str: String = "%016x" % abs(seed)
	var body: Dictionary = to_dict()
	if RealmSerializerClass != null and RealmSerializerClass.has_method("build_save"):
		return RealmSerializerClass.build_save(body, seed_str, {})
	return {}


## Rehydrate a `Realm` from a save body.
func from_dict(body: Dictionary) -> bool:
	if body == null:
		return false
	var realm_body: Dictionary = body.get("realm", body)
	seed = int(realm_body.get("seed", 0))
	if realm_body.has("world") and realm_body["world"] is Dictionary:
		world = WorldState.from_dict(realm_body["world"])
	if realm_body.has("rooms") and realm_body["rooms"] is Array:
		rooms.clear()
		for rd in realm_body["rooms"]:
			if not (rd is Dictionary):
				continue
			var room: RefCounted = Room.new()
			room.from_dict(rd)
			var did: String = String(rd.get("definition_id", ""))
			if did == "hearth":
				room.definition = load("res://data/rooms/hearth.tres")
			rooms.append(room)
	if realm_body.has("time_days"):
		time_days = float(realm_body["time_days"])
	version = 0
	return true


## Serialise the realm to a JSON-friendly dict.
func to_dict() -> Dictionary:
	var room_dicts: Array = []
	for r in rooms:
		if r == null:
			continue
		room_dicts.append(r.to_dict())
	return {
		"seed": seed,
		"version": version,
		"time_days": time_days,
		"world": world.to_dict() if world != null else {},
		"rooms": room_dicts,
	}


# --- helpers ----------------------------------------------------------


func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
	if a.size.x <= 0 or a.size.y <= 0:
		return false
	if b.size.x <= 0 or b.size.y <= 0:
		return false
	var a_x2: int = a.position.x + a.size.x
	var a_y2: int = a.position.y + a.size.y
	var b_x2: int = b.position.x + b.size.x
	var b_y2: int = b.position.y + b.size.y
	var separated: bool = a_x2 <= b.position.x or b_x2 <= a.position.x
	separated = separated or a_y2 <= b.position.y or b_y2 <= a.position.y
	return not separated


static func module_version() -> String:
	return "0.2.0-m1-spatial"
