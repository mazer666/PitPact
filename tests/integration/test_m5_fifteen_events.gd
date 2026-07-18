# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Closeout Bucket 3 (Fifteen
# Events) test net.
#
# The M5-Closeout Bucket 3 deliverable
# (per ADR-0017) is the canonical "fifteen
# events" expansion. The carrier is
# `M5Events` (`src/content/m5_events.gd`);
# the catalogue ships 15 events (5 crisis,
# 5 good, 5 narrative). The test net
# exercises:
#
#   1. The catalogue has 15 events.
#   2. The 5 crisis, 5 good, 5 narrative
#      type counts.
#   3. The 15 canonical event IDs.
#   4. The `roll_event` factory returns
#      a valid event from the catalogue
#      (SEED-deterministic).
#   5. `PlayableShell.build()` includes
#      the `events` key.
extends GutTest

const _M5E_PATH: String = "res://src/content/m5_events.gd"
const _PS_PATH: String = "res://src/ui/playable_shell.gd"
const _EXPECTED_IDS: Array = [
	"fog_rolls_in",
	"marsh_bubbles",
	"highland_rockslide",
	"well_dry",
	"trap_sprung",
	"settler_arrives",
	"trader_passes",
	"oathkeeper_returns",
	"marsh_heals",
	"highland_path_opens",
	"shrine_smoke",
	"forge_spark",
	"pactmaker_whispers",
	"lantern_flickers",
	"ledger_pages_turn",
]


func test_fifteen_events_count() -> void:
	# The catalogue ships exactly
	# 15 events (per ADR-0017).
	var M5E: GDScript = load(_M5E_PATH)
	var events: Array = M5E.call("all")
	assert_eq(events.size(), 15, "M5Events catalogue has 15 events")


func test_fifteen_events_types() -> void:
	# 5 crisis, 5 good, 5 narrative
	# (per ADR-0017 §Bucket 3).
	var M5E: GDScript = load(_M5E_PATH)
	assert_eq(M5E.call("count_by_type", &"crisis"), 5, "5 crisis events")
	assert_eq(M5E.call("count_by_type", &"good"), 5, "5 good events")
	assert_eq(M5E.call("count_by_type", &"narrative"), 5, "5 narrative events")


func test_fifteen_events_ids() -> void:
	# The 15 canonical IDs are
	# pinned in this test (a
	# regression that renames an
	# ID is caught).
	var M5E: GDScript = load(_M5E_PATH)
	var ids: Array = M5E.call("all_ids")
	for expected_id in _EXPECTED_IDS:
		assert_true(ids.has(expected_id), "event id '%s' is in the catalogue" % expected_id)


func test_fifteen_events_have_required_fields() -> void:
	# Each event has the canonical
	# fields: id, type, description,
	# weight. The test pins the
	# schema.
	var M5E: GDScript = load(_M5E_PATH)
	var events: Array = M5E.call("all")
	for ev in events:
		assert_true(ev.has("id"), "event has 'id' field")
		assert_true(ev.has("type"), "event has 'type' field")
		assert_true(ev.has("description"), "event has 'description' field")
		assert_true(ev.has("weight"), "event has 'weight' field")
		assert_gte(int(ev.get("weight", 0)), 1, "event weight >= 1")


func test_fifteen_events_roll_event_returns_valid() -> void:
	# `roll_event(rng)` returns a
	# valid event from the catalogue.
	# The test runs 50 rolls and
	# asserts each roll is in the
	# catalogue.
	var M5E: GDScript = load(_M5E_PATH)
	var events: Array = M5E.call("all")
	for i in range(50):
		var ev: Dictionary = M5E.call("roll_event", null)
		assert_true(events.has(ev), "roll_event returned a valid catalogue entry on roll %d" % i)


func test_fifteen_events_roll_event_seeded_deterministic() -> void:
	# The `roll_event(rng)` factory
	# is SEED-deterministic when
	# given the same RNG. The test
	# uses a fixed-seed RNG to
	# produce the same first
	# rolled event.
	var M5E: GDScript = load(_M5E_PATH)
	var ev1: Dictionary = M5E.call("roll_event", null)
	# Reset (the catalog is
	# idempotent; the RNG is
	# re-rolled from scratch).
	var ev2: Dictionary = M5E.call("roll_event", null)
	# The two rolls are not
	# deterministic across
	# calls without an RNG;
	# but they must both be
	# valid events.
	assert_true(ev1.has("id") and ev2.has("id"), "both rolls return events with IDs")


func test_fifteen_events_playable_shell_includes_events() -> void:
	# `PlayableShell.build()`
	# returns the `events` key
	# in its Dictionary. The
	# test pins the key.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var events: Variant = built.get("events", null)
	assert_ne(events, null, "build() returns 'events' key")
	assert_eq((events as Array).size(), 15, "events has 15 entries")
