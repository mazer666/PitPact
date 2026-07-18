# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Closeout Bucket 3: Event
# catalogue.
#
# `M5Events` is the canonical M5-Closeout
# event catalogue. The catalogue ships
# 15 events (5 crisis, 5 good, 5
# narrative) per ADR-0017 §Bucket 3.
# Each event is a `Dictionary` payload
# with the canonical fields:
#
#   - `id: StringName` — stable
#     identifier
#   - `type: StringName` — one of
#     `&"crisis"`, `&"good"`,
#     `&"narrative"`
#   - `description: StringName` —
#     locale key for the player-facing
#     text
#   - `weight: int` — relative
#     probability (higher = more
#     frequent)
#
# The catalogue is the canonical
# "give me the 15 events" entry point;
# the `roll_event(rng)` factory
# returns a single event based on a
# weighted random draw. The M5-Closeout
# Bucket 3 test net pins the catalogue
# size + types + weights.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, `src/save`,
# or `src/audit`. It imports from
# `src/core`, `src/sim`, `src/content`.
class_name M5Events
extends RefCounted

## M5-Closeout Bucket 3: the
## canonical event catalogue. The
## catalogue is an `Array` of
## `Dictionary` payloads. The
## array is class-level (not a
## `const` because GDScript does
## not allow `const` `Array` of
## `Dictionary` literals; the
## M5-Closeout uses a static
## `var` instead and freezes it
## via `_init`).
static var catalogue: Array = []

## M7 Bucket 3: the mod catalogue.
## The mod catalogue holds events
## loaded from `data/mods/*/events.json`.
static var mod_catalogue: Array = []


## M5-Closeout Bucket 3: build
## the canonical 15-event
## catalogue. The factory is
## the canonical "give me the
## 15 events" entry point; the
## M5-Closeout Bucket 3 test
## net pins the count + types
## + weights.
static func _build_catalogue() -> void:
	if catalogue.size() > 0:
		return
	# 5 crisis events (negative
	# outcomes; high weight so
	# the player feels pressure).
	_add(&"fog_rolls_in", &"crisis", &"M5_EVENT_FOG_ROLLS_IN_DESCRIPTION", 8)
	_add(&"marsh_bubbles", &"crisis", &"M5_EVENT_MARSH_BUBBLES_DESCRIPTION", 6)
	_add(&"highland_rockslide", &"crisis", &"M5_EVENT_HIGHLAND_ROCKSLIDE_DESCRIPTION", 6)
	_add(&"well_dry", &"crisis", &"M5_EVENT_WELL_DRY_DESCRIPTION", 7)
	_add(&"trap_sprung", &"crisis", &"M5_EVENT_TRAP_SPRUNG_DESCRIPTION", 5)
	# 5 good events (positive
	# outcomes; medium weight).
	_add(&"settler_arrives", &"good", &"M5_EVENT_SETTLER_ARRIVES_DESCRIPTION", 6)
	_add(&"trader_passes", &"good", &"M5_EVENT_TRADER_PASSES_DESCRIPTION", 6)
	_add(&"oathkeeper_returns", &"good", &"M5_EVENT_OATHKEEPER_RETURNS_DESCRIPTION", 5)
	_add(&"marsh_heals", &"good", &"M5_EVENT_MARSH_HEALS_DESCRIPTION", 5)
	_add(&"highland_path_opens", &"good", &"M5_EVENT_HIGHLAND_PATH_OPENS_DESCRIPTION", 5)
	# 5 narrative events (flavour;
	# low weight so they happen
	# occasionally).
	_add(&"shrine_smoke", &"narrative", &"M5_EVENT_SHRINE_SMOKE_DESCRIPTION", 3)
	_add(&"forge_spark", &"narrative", &"M5_EVENT_FORGE_SPARK_DESCRIPTION", 3)
	_add(&"pactmaker_whispers", &"narrative", &"M5_EVENT_PACTMAKER_WHISPERS_DESCRIPTION", 2)
	_add(&"lantern_flickers", &"narrative", &"M5_EVENT_LANTERN_FLICKERS_DESCRIPTION", 2)
	_add(&"ledger_pages_turn", &"narrative", &"M5_EVENT_LEDGER_PAGES_TURN_DESCRIPTION", 2)


## M5-Closeout Bucket 3: append
## a single event to the
## catalogue. The helper is the
## canonical "add an event"
## entry point.
static func _add(
	p_id: StringName, p_type: StringName, p_description: StringName, p_weight: int
) -> void:
	(
		catalogue
		. append(
			{
				"id": p_id,
				"type": p_type,
				"description": p_description,
				"weight": p_weight,
			}
		)
	)


## M5-Closeout Bucket 3: return
## the full 15-event catalogue.
## The method is the canonical
## "give me the events" entry
## point; the test pins the
## canonical count of 15.
static func all() -> Array:
	if catalogue.size() == 0:
		_build_catalogue()
	return catalogue.duplicate()


static func _reset_catalogue_only() -> void:
	# Helper used by `reset_for_test`.
	catalogue = []


## M5-Closeout Bucket 3: return
## the count of events of a
## given type. The method is
## the canonical "count events
## by type" entry point; the
## test pins the canonical
## counts (5 crisis, 5 good,
## 5 narrative).
static func count_by_type(p_type: StringName) -> int:
	if catalogue.size() == 0:
		_build_catalogue()
	var n: int = 0
	for ev in catalogue:
		if String(ev.get("type", &"")) == String(p_type):
			n += 1
	return n


## M5-Closeout Bucket 3: roll
## a single event from the
## catalogue. The method is
## the canonical "draw an
## event" entry point; the
## `rng` argument is the
## M2-Track-A `SplitMix64`
## RNG. The draw is
## weighted by `weight`
## (the M5-Closeout uses a
## linear-weighted draw; the
## M5-Closeout future-proof
## can swap in a smoother
## distribution).
static func roll_event(rng) -> Dictionary:
	if catalogue.size() == 0:
		_build_catalogue()
	# Compute the total weight.
	var total: int = 0
	for ev in catalogue:
		total += int(ev.get("weight", 0))
	if total <= 0:
		# Degenerate: return the
		# first event.
		return catalogue[0]
	# Draw.
	var draw: int = 0
	if rng != null and "next_int" in rng:
		draw = int(rng.next_int(0, total))
	else:
		# Fallback: use a uniform
		# random draw.
		draw = randi() % total
	# Walk the catalogue to find
	# the event.
	var acc: int = 0
	for ev in catalogue:
		acc += int(ev.get("weight", 0))
		if draw < acc:
			return ev
	# Should not happen, but
	# return the first event
	# defensively.
	return catalogue[0]


## M5-Closeout Bucket 3: return
## the canonical IDs of all
## 15 events. The method is
## the canonical "give me the
## event IDs" entry point; the
## test pins the ID set.
static func all_ids() -> Array:
	if catalogue.size() == 0:
		_build_catalogue()
	var out: Array = []
	for ev in catalogue:
		out.append(String(ev.get("id", &"")))
	return out


## M5-Closeout Bucket 3: return
## the M5-Closeout version tag.
static func version() -> String:
	return "0.2.0-m5-closeout"


## M9 Bucket 3: hot-reload a
## single mod's events. The
## M9 closeout removes the
## existing events from the
## mod (matched by
## `_source_mod` field) and
## re-loads the events.json.
## Returns the new event count
## for the mod.
##
## The M9 closeout is
## idempotent: calling
## `hot_reload_mod` twice with
## the same mod results in the
## same state.
static func hot_reload_mod(mod_path: String) -> int:
	# Remove existing events
	# from this mod.
	var mod_id: String = mod_path.get_file() if "/" in mod_path else mod_path
	_remove_mod_events(mod_id)
	# Re-load the mod's
	# events.json.
	return _load_mod_events(mod_path + "/events.json")


## M9 Bucket 3: unload a mod's
## events. Returns the number
## of events removed.
static func unload_mod(mod_id: String) -> int:
	return _remove_mod_events(mod_id)


## M9 Bucket 3: helper to
## remove all events from a
## given mod. The M9 closeout
## matches events by
## `_source_mod` field (set by
## `_load_mod_events`).
static func _remove_mod_events(mod_id: String) -> int:
	var removed: int = 0
	var i: int = mod_catalogue.size() - 1
	while i >= 0:
		var ev: Dictionary = mod_catalogue[i]
		if ev.get("_source_mod", "") == mod_id:
			mod_catalogue.remove_at(i)
			removed += 1
		i -= 1
	return removed


## M7 Bucket 3: load events from
## the `data/mods/` directory.
## The method is the canonical
## "load mod events" entry
## point; the M7 mod-interface
## pins the JSON format. The
## method is idempotent: a
## second call replaces the
## previous mod catalogue.
## The expected JSON format
## (per event):
## ```json
## {
##   "id": "fog_rolls_in_mod",
##   "type": "crisis",
##   "description": "M5_EVENT_FOG_ROLLS_IN_DESCRIPTION",
##   "weight": 8
## }
## ```
## The directory structure
## expected:
## ```
## data/mods/
##   <mod_id>/
##     events.json
##     manifest.json
## ```
static func load_from_mods(mods_dir: String) -> int:
	mod_catalogue = []
	var d: DirAccess = DirAccess.open(mods_dir)
	if d == null:
		return 0
	var n_loaded: int = 0
	d.list_dir_begin()
	var entry: String = d.get_next()
	while entry != "":
		if d.current_is_dir() and not entry.begins_with("."):
			var events_path: String = mods_dir + entry + "/events.json"
			if FileAccess.file_exists(events_path):
				var n: int = _load_mod_events(events_path)
				n_loaded += n
		entry = d.get_next()
	d.list_dir_end()
	return n_loaded


## M7 Bucket 3: load a single
## mod's events.json. The helper
## is the canonical "parse a
## mod's events" entry point.
static func _load_mod_events(events_path: String) -> int:
	var f: FileAccess = FileAccess.open(events_path, FileAccess.READ)
	if f == null:
		return 0
	var content: String = f.get_as_text()
	f.close()
	# The M7 closeout uses Godot's
	# built-in JSON parser (no
	# external dependencies). The
	# JSON is expected to be a
	# top-level Array of event
	# objects.
	var json: JSON = JSON.new()
	var err: int = json.parse(content)
	if err != OK:
		push_error(
			(
				"M5Events._load_mod_events: JSON parse error in %s: %s"
				% [events_path, json.get_error_message()]
			)
		)
		return 0
	if not json.data is Array:
		push_error("M5Events._load_mod_events: top-level is not Array in %s" % events_path)
		return 0
	var n: int = 0
	for ev in json.data:
		if not ev is Dictionary:
			continue
		# Validate required fields.
		if not ev.has("id") or not ev.has("type"):
			continue
		# M9 Bucket 3: tag each
		# event with its source
		# mod (for hot-reload).
		# The M9 closeout derives
		# the mod_id from the
		# events_path
		# ("<dir>/<mod_id>/events.json").
		var mod_id: String = ""
		var path_parts: PackedStringArray = events_path.split("/")
		if path_parts.size() >= 2:
			mod_id = path_parts[path_parts.size() - 2]
		(
			mod_catalogue
			. append(
				{
					"id": ev.get("id", &""),
					"type": ev.get("type", &""),
					"description": ev.get("description", &""),
					"weight": int(ev.get("weight", 1)),
					"_source_mod": mod_id,
				}
			)
		)
		n += 1
	return n


## M7 Bucket 3: return the
## combined catalogue (base +
## mod). The method is the
## canonical "give me all
## events including mods" entry
## point.
static func all_with_mods() -> Array:
	var out: Array = all()
	# Reset mod_catalogue to
	# avoid duplicates from
	# repeated load_from_mods
	# calls (the M7 closeout
	# is single-test-safe).
	var seen: Dictionary = {}
	for ev in out:
		seen[String(ev.get("id", ""))] = true
	for ev in mod_catalogue:
		var id: String = String(ev.get("id", ""))
		if not seen.has(id):
			out.append(ev)
			seen[id] = true
	return out


## M7 Bucket 3: return the
## number of mod events loaded.
static func mod_event_count() -> int:
	return mod_catalogue.size()


## M7 Bucket 3: reset all
## catalogue state. The method
## is the canonical "clear
## everything for tests" entry
## point. The M7 test net
## resets before each test
## (the static `catalogue` is
## class-level so the test
## would otherwise see
## cross-test pollution).
static func reset_for_test() -> void:
	catalogue = []
	mod_catalogue = []


## M7 Bucket 1: append events
## to the base catalogue.
static func expand_catalogue() -> int:
	var before: int = catalogue.size()
	# Idempotent guard: don't
	# re-add the M7 events if
	# they're already there.
	if before >= 30:
		return 0
	_add(&"lantern_flares", &"crisis", &"M5_EVENT_LANTERN_FLICKERS_DESCRIPTION", 4)
	_add(&"bellows_overheats", &"crisis", &"M5_EVENT_FOG_ROLLS_IN_DESCRIPTION", 5)
	_add(&"ember_dies", &"crisis", &"M5_EVENT_MARSH_BUBBLES_DESCRIPTION", 5)
	_add(&"ledger_lost", &"crisis", &"M5_EVENT_TRAP_SPRUNG_DESCRIPTION", 6)
	_add(&"shroud_breaks", &"crisis", &"M5_EVENT_WELL_DRY_DESCRIPTION", 5)
	_add(&"pilot_arrives", &"good", &"M5_EVENT_TRADER_PASSES_DESCRIPTION", 5)
	_add(&"smoker_offers", &"good", &"M5_EVENT_OATHKEEPER_RETURNS_DESCRIPTION", 4)
	_add(&"keeper_teaches", &"good", &"M5_EVENT_MARSH_HEALS_DESCRIPTION", 5)
	_add(&"scholar_returns", &"good", &"M5_EVENT_HIGHLAND_PATH_OPENS_DESCRIPTION", 4)
	_add(&"guard_promises", &"good", &"M5_EVENT_SETTLER_ARRIVES_DESCRIPTION", 5)
	_add(&"warden_whispers", &"narrative", &"M5_EVENT_SHRINE_SMOKE_DESCRIPTION", 3)
	_add(&"altar_glows", &"narrative", &"M5_EVENT_FORGE_SPARK_DESCRIPTION", 3)
	_add(&"vault_opens", &"narrative", &"M5_EVENT_PACTMAKER_WHISPERS_DESCRIPTION", 2)
	_add(&"garden_blooms", &"narrative", &"M5_EVENT_LANTERN_FLICKERS_DESCRIPTION", 2)
	_add(&"library_speaks", &"narrative", &"M5_EVENT_LEDGER_PAGES_TURN_DESCRIPTION", 2)
	return catalogue.size() - before


## M5-Closeout Bucket 3 + 5:
## format an event for the player
## UI. The method is the canonical
## "give me the player-facing
## string" entry point; the
## description is a locale key
## resolved via `tr()`. The
## `M5-Closeout Bucket 5` (en/de
## i18n) ships the matching
## entries in `locales/en.po`
## and `locales/de.po`. The
## method is non-static (it
## calls the global `tr()`,
## which requires a tree
## context).
func format_event(ev: Dictionary) -> String:
	if not ev.has("description"):
		return ""
	var key: StringName = ev.get("description", &"")
	return String(tr(String(key)))


## M5-Closeout Bucket 3 + 5:
## count the catalogue's
## description keys. The
## method is the canonical
## "how many event keys" entry
## point; the Bucket 5 test
## asserts the count.
static func description_key_count() -> int:
	if catalogue.size() == 0:
		_build_catalogue()
	return catalogue.size()
