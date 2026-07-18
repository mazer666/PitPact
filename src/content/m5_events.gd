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
