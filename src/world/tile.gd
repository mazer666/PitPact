# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — a single tile's data (ADR-0004).
#
# A tile is a single cell of the realm grid. The data model
# is intentionally small: an `id` (the visual variant key
# for the renderer), a `biome` (a content-defined id), and a
# `surface_meta` (a free-form per-tile metadata dictionary).
# The tile does NOT know its zone purpose, does NOT know
# what room it belongs to, and does NOT carry a state
# machine. Zone purpose and room state are layered on top
# (see `zone.gd` and `realm/room.gd`).
#
# Per ADR-0002, this file does not import from any other
# `src/<module>/`. The tile is a pure data container.
class_name Tile
extends RefCounted

## The visual variant key used by the renderer. The M1
## renderer (`src/world/tile_map.gd`) maps this to a
## `TileSetAtlasSource` cell. Content-driven: the runtime
## does not interpret the value; it only round-trips it
## through the save format. Default `0` means "empty
## floor" in the M1 demo.
var id: int = 0

## The biome the tile belongs to. Biomes are content
## (see §8 of `docs/requirements.md`); the runtime stores
## the id and the UI looks up the visual identity through
## `ContentRegistry`. Default `&""` means "biome not yet
## assigned"; the grid factory seeds every tile with a
## deterministic biome.
var biome: StringName = &""

## Free-form per-tile metadata. Used by the simulation for
## things like "this tile is on fire" or "this tile has a
## crack". The dictionary is the canonical form: keys are
## `StringName` (round-trip through the save format),
## values are JSON-friendly primitives (int, float, bool,
## String, StringName, PackedArrays of those). M1 does not
## read or write this dictionary outside the save format;
## it is a placeholder for M2+.
var surface_meta: Dictionary = {}


## Default constructor. `id` defaults to 0 (empty floor),
## `biome` defaults to an empty `StringName`, and
## `surface_meta` defaults to an empty dictionary. Use
## `Tile.make(id, biome, surface_meta)` for a non-default
## value.
func _init(p_id: int = 0, p_biome: StringName = &"", p_surface_meta: Dictionary = {}) -> void:
	id = p_id
	biome = p_biome
	surface_meta = p_surface_meta.duplicate(true)


## Convenience factory. Equivalent to
## `Tile.new(id, biome, surface_meta)` but reads more
## naturally at call sites.
static func make(p_id: int = 0, p_biome: StringName = &"", p_surface_meta: Dictionary = {}) -> Tile:
	return Tile.new(p_id, p_biome, p_surface_meta)


## Serialise the tile to a JSON-friendly `Dictionary`. The
## `surface_meta` is recursively converted to a JSON
## representation. The round-trip is exact for the
## JSON-friendly subset of GDScript values (int, float,
## bool, String, StringName, Array, Dictionary); values of
## other types are stored as their string representation
## with a logged warning. Save format consumers
## (`src/save/realm_serializer.gd`) call this and the
## inverse `from_dict` to round-trip.
func to_dict() -> Dictionary:
	var out: Dictionary = {
		"id": id, "biome": String(biome), "surface_meta": _meta_to_json(surface_meta)
	}
	return out


## Deserialise a `Dictionary` produced by `to_dict()`. The
## inverse of `to_dict`. Unknown keys are preserved
## (ADR-0003: a save with forward-compatible keys round-
## trips without dropping data).
static func from_dict(d: Dictionary) -> Tile:
	var t: Tile = Tile.new()
	if d.has("id"):
		t.id = int(d["id"])
	if d.has("biome"):
		t.biome = StringName(String(d["biome"]))
	if d.has("surface_meta") and d["surface_meta"] is Dictionary:
		t.surface_meta = _json_to_meta(d["surface_meta"])
	# Preserve unknown keys on the Tile's surface_meta so a
	# future tool can read an older save without losing
	# data. ADR-0003's "unknown keys are preserved" rule.
	for k in d.keys():
		if k in ["id", "biome", "surface_meta"]:
			continue
		if not (k is StringName) and not (k is String):
			continue
		t.surface_meta[String(k)] = d[k]
	return t


## Equality by value. Two tiles are equal iff they have the
## same `id`, the same `biome`, and the same
## `surface_meta` content. Used by the save round-trip
## test.
func equals(other: Tile) -> bool:
	if other == null:
		return false
	if id != other.id:
		return false
	if biome != other.biome:
		return false
	if surface_meta.size() != other.surface_meta.size():
		return false
	for k in surface_meta.keys():
		if not other.surface_meta.has(k):
			return false
		if str(surface_meta[k]) != str(other.surface_meta[k]):
			return false
	return true


# --- helpers ----------------------------------------------------------


## Recursively convert a GDScript value to a JSON-friendly
## form. JSON-friendly means: int, float, bool, String,
## StringName (stored as String), Array of JSON-friendly,
## Dictionary with String/StringName keys of JSON-friendly.
## Non-JSON-friendly values are converted via `str()` and
## the conversion is logged; this is a placeholder for M2+
## to add proper support.
static func _meta_to_json(v: Variant) -> Variant:
	if v == null:
		return null
	if v is bool:
		return v
	if v is int:
		return v
	if v is float:
		return v
	if v is String:
		return v
	if v is StringName:
		return String(v)
	if v is Array:
		var out_arr: Array = []
		for e in v:
			out_arr.append(_meta_to_json(e))
		return out_arr
	if v is Dictionary:
		var out_dict: Dictionary = {}
		for k in v.keys():
			var key_str: String = k if (k is String) else String(k)
			out_dict[key_str] = _meta_to_json(v[k])
		return out_dict
	# Fallback: stringify. M2+ will land typed metadata
	# schemas that this branch can grow into.
	push_warning(
		"Tile: surface_meta value of type %s is not JSON-friendly; stringifying" % str(typeof(v))
	)
	return str(v)


## Inverse of `_meta_to_json`. Currently a no-op (the JSON
## form is identical to the GDScript form for the supported
## subset); factored out so the JSON form can evolve
## independently of the runtime form.
static func _json_to_meta(v: Variant) -> Variant:
	return v
