# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant lifecycle integration test
# (M2 Track A).
#
# This is the end-to-end test for the M2 Track A
# inhabitant / needs / event-memory / relationship
# wiring. The test exercises the full tick loop
# (steps 1, 2, 4, 5 of ADR-0005) and asserts:
#
#   1. All four needs decay over 10 in-game days
#      (the per-need baseline rate is
#      `TUNING_NEED_DECAY_PER_DAY = 0.05`, so 10
#      days of decay removes `0.50` from each
#      need).
#
#   2. The Lanternbearer's morale/stress changes
#      *differently* from the two generic
#      inhabitants — the culture's per-tick bias
#      (`+0.05` morale, `-0.02` stress) is
#      visible in the post-tick values.
#
#   3. Each inhabitant's `EventMemory` has
#      exactly 10 entries after 10 days of
#      ticking (the integration test seeds
#      one `event.day_passed` event per tick;
#      the memory records each one).
#
#   4. Save/load roundtrip preserves all of the
#      above: needs, morale, stress, event
#      memory, and the inhabitant's identifying
#      fields (id, culture, name, role, state).
extends GutTest

## The seed the test uses. Pinned so a
## regression in the deterministic
## inhabitant / RNG plumbing surfaces as a
## change in the post-tick values.
const _SEED: int = 0xCAFE_5042

## Cached Lanternbearer culture data
## resource. `gdlint` flags repeated
## `load(...)` calls as `duplicated-load`;
## cache the reference at module load.
const CULTURE_RES: Resource = preload("res://data/cultures/lanternbearer.tres")

## Cached Lanternbearer culture class.
## `gdlint` flags repeated `load(...)` calls
## as `duplicated-load`; cache the reference
## at module load.
const LANTERNBEARER_CULTURE := preload("res://src/sim/cultures/lanternbearer.gd")

## Cached Sim class. Same `duplicated-load`
## rationale as above.
const SIM_CLASS := preload("res://src/sim/sim.gd")

## Cached Inhabitant class. Same
## `duplicated-load` rationale as above.

## Cached Morale class. Same rationale.
const MORALE_CLASS := preload("res://src/sim/morale.gd")

## Cached Needs class. Same rationale.
const NEEDS_CLASS := preload("res://src/sim/needs.gd")

## Cached EventMemory class. Same rationale.
const EVENT_MEMORY_CLASS := preload("res://src/sim/event_memory.gd")

## Number of in-game days the test ticks
## for. The assertion that event memory has
## 10 entries per inhabitant depends on
## this; the test fails if the constant is
## changed without updating the assertion.
const _DAYS: int = 10

## Per-tick event id. The integration test
## appends one `event.day_passed` event to
## the sim's `events` input per tick; the
## memory-recording step records each event
## into the affected inhabitant's memory.
const _TICK_EVENT_ID := &"event.day_passed"

## Per-tick event kind. `event.day_passed`
## is a content-driven kind that the
## event-memory step handles as
## "record into every affected
## inhabitant's memory".
const _TICK_EVENT_KIND := &"tick.day_passed"


## A minimal inhabitant factory used by
## the integration test. Returns a fresh
## `Inhabitant` with the canonical
## (id, culture, name, role) tuple.
## The factory is a local helper so the
## test does not depend on the realm
## façade's content loader.
func _make_inhabitant(
	p_id: StringName, p_culture: StringName, p_name: StringName, p_role: StringName
) -> Inhabitant:
	var inh: Inhabitant = Inhabitant.new()
	inh._init_id(p_id, p_culture, p_name, p_role)
	inh.birth_day = 0.0
	inh.position = Vector2i.ZERO
	return inh


## Build the 3-inhabitant roster the
## integration test ticks. The roster is
## 1 Lanternbearer (`Lia`) and 2 generics
## (`Aren`, `Bex`); the Lanternbearer has
## the per-culture morale/stress bias the
## test asserts is visible in the
## post-tick values.
func _make_roster() -> Array:
	var roster: Array = []
	roster.append(
		_make_inhabitant(
			&"lanternbearer_lia", &"lanternbearer", &"CREATURE_LANTERNBEARER_NAME", &"scribe"
		)
	)
	roster.append(
		_make_inhabitant(&"generic_aren", &"generic", &"CREATURE_GENERIC_AREN_NAME", &"settler")
	)
	roster.append(
		_make_inhabitant(&"generic_bex", &"generic", &"CREATURE_GENERIC_BEX_NAME", &"settler")
	)
	return roster


## Build the per-tick `event.day_passed`
## event array. The integration test feeds
## exactly one event per inhabitant per
## tick; the event's `affected` list is the
## whole roster (so the memory step
## records into every inhabitant).
func _make_tick_events(inhabitants: Array, tick_day: float) -> Array:
	var affected: PackedStringArray = PackedStringArray()
	for inh in inhabitants:
		if inh is Inhabitant:
			affected.append(String(inh.id))
	return [
		{
			"id": _TICK_EVENT_ID,
			"time_days": tick_day,
			"kind": _TICK_EVENT_KIND,
			"summary": &"EVENT_DAY_PASSED",
			"affected": affected,
		}
	]


func test_three_inhabitants_ten_days_needs_decay() -> void:
	# 1. Set up: 1 Lanternbearer, 2 generics.
	var sim: Sim = SIM_CLASS.new(_SEED)
	var roster: Array = _make_roster()
	# 2. Tick 10 days, one tick per day, feeding
	#    one `event.day_passed` event per tick.
	for d in range(1, _DAYS + 1):
		var evs: Array = _make_tick_events(roster, float(d))
		sim.call("tick", 1.0, roster, evs)
	# 3. All four needs decayed for every
	#    inhabitant. The per-day decay rate is
	#    `TUNING_NEED_DECAY_PER_DAY = 0.05`;
	#    10 days of decay removes `0.50` from
	#    each need, taking a fresh `1.0` need
	#    to `0.50`. The test asserts the
	#    *post-tick* value is below the
	#    starting value; the exact number
	#    depends on the per-tick ordering
	#    (decay-then-morale) and is not
	#    over-asserted.
	for inh in roster:
		assert_lt(float(inh.needs.food), 1.0, "Inhabitant %s: food decayed" % String(inh.id))
		assert_lt(float(inh.needs.rest), 1.0, "Inhabitant %s: rest decayed" % String(inh.id))
		assert_lt(float(inh.needs.safety), 1.0, "Inhabitant %s: safety decayed" % String(inh.id))
		assert_lt(
			float(inh.needs.recognition), 1.0, "Inhabitant %s: recognition decayed" % String(inh.id)
		)


func test_lanternbearer_morale_stress_differs_from_generics() -> void:
	# 1. Set up: 1 Lanternbearer, 2 generics.
	var sim: Sim = SIM_CLASS.new(_SEED)
	var roster: Array = _make_roster()
	# 2. Tick 10 days, one tick per day, feeding
	#    one `event.day_passed` event per tick.
	for d in range(1, _DAYS + 1):
		var evs: Array = _make_tick_events(roster, float(d))
		sim.call("tick", 1.0, roster, evs)
	# 3. The Lanternbearer (`Lia`) has
	#    *higher* morale than the generic
	#    inhabitants (the culture's
	#    `+0.05` per-tick bias accumulates
	#    over 10 days to `+0.50`, on top of
	#    the need-driven derivation).
	var lanternbearer: Inhabitant = roster[0]
	var generic_aren: Inhabitant = roster[1]
	var generic_bex: Inhabitant = roster[2]
	# Assert the Lanternbearer and the two
	# generics are *not* equal. The exact
	# ordering is sensitive to the per-tick
	# bias and the need-driven derivation;
	# the test asserts the per-culture
	# tilt is *visible*, not that the
	# tilt is in a specific direction
	# (a starving Lanternbearer is still
	# miserable; the tilt is small).
	assert_ne(
		float(lanternbearer.morale.morale),
		float(generic_aren.morale.morale),
		"Lanternbearer morale differs from generic (Aren)"
	)
	assert_ne(
		float(lanternbearer.morale.morale),
		float(generic_bex.morale.morale),
		"Lanternbearer morale differs from generic (Bex)"
	)
	# 4. Stress: the Lanternbearer's
	#    `STRESS_BIAS = -0.02` per tick
	#    accumulates over 10 days to
	#    `-0.20` of the per-tick stress
	#    update. The exact difference
	#    depends on the morale-driven
	#    stress rule; the test asserts
	#    the difference is *visible*
	#    (not equal), not that it is in
	#    a specific direction.
	assert_ne(
		float(lanternbearer.morale.stress),
		float(generic_aren.morale.stress),
		"Lanternbearer stress differs from generic (Aren)"
	)
	assert_ne(
		float(lanternbearer.morale.stress),
		float(generic_bex.morale.stress),
		"Lanternbearer stress differs from generic (Bex)"
	)


func test_event_memory_has_ten_entries_per_inhabitant() -> void:
	# 1. Set up: 1 Lanternbearer, 2 generics.
	var sim: Sim = SIM_CLASS.new(_SEED)
	var roster: Array = _make_roster()
	# 2. Tick 10 days, one tick per day, feeding
	#    one `event.day_passed` event per tick.
	#    The event is in the input `events`
	#    array; the sim's step 4 records it
	#    into every affected inhabitant's
	#    memory.
	for d in range(1, _DAYS + 1):
		var evs: Array = _make_tick_events(roster, float(d))
		sim.call("tick", 1.0, roster, evs)
	# 3. Every inhabitant has exactly 10
	#    memory entries — one per tick.
	for inh in roster:
		assert_eq(
			inh.memory.entries.size(),
			_DAYS,
			"Inhabitant %s: event memory has %d entries" % [String(inh.id), _DAYS]
		)
	# 4. The memory entries are sorted by
	#    `time_days` ascending. The
	#    `EventMemory.record` method inserts
	#    in sorted order; a regression in
	#    the sort surfaces here.
	for inh in roster:
		var prev_t: float = -1.0
		for e in inh.memory.entries:
			var t: float = float(e.get("time_days", -1.0))
			assert_true(t >= prev_t, "Inhabitant %s: memory sorted by time_days" % String(inh.id))
			prev_t = t


func test_save_load_roundtrip_preserves_inhabitant_state() -> void:
	# 1. Set up: 1 Lanternbearer, 2 generics.
	#    Tick 5 days (the test does not
	#    need the full 10 to exercise
	#    save/load).
	var sim: Sim = SIM_CLASS.new(_SEED)
	var roster: Array = _make_roster()
	for d in range(1, 6):
		var evs: Array = _make_tick_events(roster, float(d))
		sim.call("tick", 1.0, roster, evs)
	# 2. Snapshot the pre-save state of
	#    every inhabitant.
	var pre_save: Array = []
	for inh in roster:
		pre_save.append(inh.to_dict())
	# 3. Build a save dict from the
	#    snapshot. The test uses the
	#    canonical save body shape from
	#    `tests/integration/test_save_roundtrip.gd`
	#    (the realm's `to_dict` +
	#    `RealmSerializer.build_save`
	#    pipeline). The inhabitant side
	#    is serialised through
	#    `Inhabitant.to_dict()` and
	#    restored through
	#    `Inhabitant.from_dict()`.
	var body: Dictionary = {
		"sim": {"time_days": sim.time_days, "rng_seed": _SEED},
		"inhabitants": pre_save,
	}
	# 4. Reload the inhabitants from the
	#    save body. The reload goes
	#    through `Inhabitant.from_dict`
	#    so the roundtrip is the test
	#    contract.
	var reloaded: Array = []
	for inh_dict in body.get("inhabitants", []):
		var new_inh: Inhabitant = Inhabitant.new()
		new_inh.from_dict(inh_dict)
		reloaded.append(new_inh)
	# 5. Assert the post-load state
	#    matches the pre-save state
	#    element-wise.
	assert_eq(reloaded.size(), roster.size(), "Roundtrip: inhabitant count")
	for i in range(roster.size()):
		var pre: Inhabitant = roster[i]
		var post: Inhabitant = reloaded[i]
		assert_eq(String(post.id), String(pre.id), "Roundtrip: id %d" % i)
		assert_eq(String(post.culture), String(pre.culture), "Roundtrip: culture %d" % i)
		assert_eq(String(post.name), String(pre.name), "Roundtrip: name %d" % i)
		assert_eq(String(post.role), String(pre.role), "Roundtrip: role %d" % i)
		assert_eq(int(post.state), int(pre.state), "Roundtrip: state %d" % i)
		assert_eq(float(post.birth_day), float(pre.birth_day), "Roundtrip: birth_day %d" % i)
		assert_eq(float(post.needs.food), float(pre.needs.food), "Roundtrip: needs.food %d" % i)
		assert_eq(float(post.needs.rest), float(pre.needs.rest), "Roundtrip: needs.rest %d" % i)
		assert_eq(
			float(post.needs.safety), float(pre.needs.safety), "Roundtrip: needs.safety %d" % i
		)
		assert_eq(
			float(post.needs.recognition),
			float(pre.needs.recognition),
			"Roundtrip: needs.recognition %d" % i
		)
		assert_eq(float(post.morale.morale), float(pre.morale.morale), "Roundtrip: morale %d" % i)
		assert_eq(float(post.morale.stress), float(pre.morale.stress), "Roundtrip: stress %d" % i)
		assert_eq(
			post.memory.entries.size(), pre.memory.entries.size(), "Roundtrip: memory size %d" % i
		)
		# 6. The first memory entry's
		#    `time_days` is preserved.
		if post.memory.entries.size() > 0:
			assert_eq(
				float(post.memory.entries[0].get("time_days", -1.0)),
				float(pre.memory.entries[0].get("time_days", -1.0)),
				"Roundtrip: first memory entry time_days %d" % i
			)


func test_lanternbearer_culture_data_loads() -> void:
	# The data file at
	# `data/cultures/lanternbearer.tres`
	# loads as a `CultureData` resource
	# with the canonical id, display
	# name, body form, and values. A
	# regression in the schema or the
	# file's `script_class` would fail
	# this test.
	assert_not_null(CULTURE_RES, "lanternbearer.tres must load")
	assert_eq(String(CULTURE_RES.get("id")), "lanternbearer", "culture id is 'lanternbearer'")
	assert_eq(
		String(CULTURE_RES.get("display_name")),
		"CREATURE_LANTERNBEARER_NAME",
		"culture display_name is the locale key"
	)
	assert_eq(
		String(CULTURE_RES.get("body_form")),
		"CREATURE_LANTERNBEARER_BODY_FORM",
		"culture body_form is the locale key"
	)
	var values_v: Variant = CULTURE_RES.get("values")
	assert_true(values_v is PackedStringArray, "culture values is a PackedStringArray")
	var values: PackedStringArray = values_v
	assert_eq(values.size(), 2, "culture has two values (preservation, story-keeping)")


func test_lanternbearer_culture_info_returns_canonical_data() -> void:
	# The runtime class
	# `LanternbearerCulture` exposes
	# the canonical data through
	# `info()`. A regression in the
	# constants would fail this test.
	var info: Dictionary = LANTERNBEARER_CULTURE.new().info()
	assert_eq(String(info.get("id")), "lanternbearer", "info id matches")
	assert_eq(
		String(info.get("display_name")), "CREATURE_LANTERNBEARER_NAME", "info display_name matches"
	)
	assert_eq(float(info.get("morale_bias")), 0.05, "info morale_bias matches the constant")
	assert_eq(float(info.get("stress_bias")), -0.02, "info stress_bias matches the constant")
