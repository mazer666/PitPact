# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M2-foundation sim-skeleton smoke test.
#
# This is the trivial smoke test for the M2-foundation
# commit (ADR-0005 + the src/sim/ skeletons). It does
# two things:
#
#   1. Asserts that the new `Sim` class is loadable
#      from `res://src/sim/sim.gd`. A regression in the
#      file path or a syntax error in the file would
#      fail this test; a passing test confirms the
#      `class_name Sim` declaration resolved and the
#      GUT 9 harness can `load()` the script.
#
#   2. Asserts that an `Inhabitant` can be instantiated
#      with a deterministic id. The `id` is the
#      inhabitant's stable identity and is what every
#      other module (relationships, event memory,
#      contracts) keys off. A test on `id` is a test
#      on the determinism contract the M2 cycle 2
#      and cycle 3 commits build on.
#
# The deeper replay test (two `Sim` instances with the
# same seed and the same input events produce deep-
# equal state at every tick) lands in the M2 cycle 3
# commit as `tests/sim/test_sim_replay.gd`. The
# skeleton cannot exercise the replay test because
# the tick body is a no-op in the M2 foundation; the
# replay test is owned by the two tracks that fill
# the tick body in.
extends GutTest

const _SIM_PATH := "res://src/sim/sim.gd"
const _INHABITANT_PATH := "res://src/sim/inhabitant.gd"
const _NEEDS_PATH := "res://src/sim/needs.gd"
const _EVENT_MEMORY_PATH := "res://src/sim/event_memory.gd"
const _RELATIONSHIP_PATH := "res://src/sim/relationships.gd"
const _CONTRACT_PATH := "res://src/sim/contract.gd"
const _TASK_PATH := "res://src/sim/tasks.gd"
const _EVENT_LOG_PATH := "res://src/sim/event_log.gd"
const _CRISIS_PATH := "res://src/sim/crisis.gd"
const _CONSTANTS_PATH := "res://src/sim/constants.gd"


func test_trivial_assertion() -> void:
	# Canonical "is the test runner actually running tests?"
	# assertion. If this fails, the failure is upstream of
	# any real test logic.
	assert_eq(2 + 2, 4, "2 + 2 should equal 4")


func test_sim_class_loads() -> void:
	# The M2 contract pins the new public entry point as
	# `class_name Sim` (ADR-0005 and the foundation
	# commit). The class must load from `res://src/sim/sim.gd`
	# and the GUT 9 harness must be able to instantiate
	# it. A regression in the file path, a syntax error
	# in the file, or an unresolved class_name would
	# fail this test.
	var SimClass := load(_SIM_PATH)
	assert_not_null(SimClass, "src/sim/sim.gd should load as a class")


func test_sim_has_tick_method() -> void:
	# The M2 contract pins `tick(delta_days, inhabitants,
	# events) -> void` as the only mutating method on
	# `Sim`. The method must exist on the class; a
	# regression in the signature would fail this test
	# (the cycle 2 and cycle 3 tracks build against the
	# signature). We exercise the method through an
	# instance (rather than `has_method` on the script)
	# because GDScript's `has_method` on a `load()`-ed
	# `Script` does not consistently see instance methods
	# on 4.3 — the call-and-assert path is the stable
	# check.
	var SimClass := load(_SIM_PATH)
	assert_not_null(SimClass, "src/sim/sim.gd should load as a class")
	var sim: Object = SimClass.new(0)
	var before: float = float(sim.get("time_days"))
	sim.call("tick", 1.0, [], [])
	var after: float = float(sim.get("time_days"))
	assert_eq(
		after - before,
		1.0,
		"Sim.tick(delta_days, inhabitants, events) must advance time_days by delta_days (ADR-0005)"
	)


func test_sim_instantiates_with_deterministic_seed() -> void:
	# The deterministic-replay invariant (ADR-0005) is
	# anchored on the seed: two `Sim` instances
	# constructed with the same seed and ticked with
	# the same input events produce deep-equal state at
	# every tick. A test on the seed plumbing is a test
	# on the anchor.
	#
	# The M2 skeleton does not exercise the replay
	# (the tick body is a no-op); the M2 cycle 3
	# commit's `tests/sim/test_sim_replay.gd` is the
	# full check. This test is the skeleton-level
	# confirmation that the `Sim._init(seed)` path
	# works.
	var SimClass := load(_SIM_PATH)
	var seed: int = 0xC0FFEE
	var sim: Object = SimClass.new(seed)
	assert_not_null(sim, "Sim.new(seed) should produce a non-null instance")
	assert_eq(
		float(sim.get("time_days")), 0.0, "A freshly-constructed Sim should have time_days == 0.0"
	)


func test_sim_tick_advances_time_days() -> void:
	# The M2 contract pins the post-condition of `tick`
	# as "time_days is advanced by delta_days". The M2
	# skeleton honours that post-condition (the body of
	# `tick` is just `time_days += delta_days`). A
	# regression in the post-condition would break every
	# save and every replay test downstream.
	var SimClass := load(_SIM_PATH)
	var sim: Object = SimClass.new(0)
	sim.call("tick", 1.0, [], [])
	assert_eq(
		float(sim.get("time_days")), 1.0, "A single 1.0-day tick should advance time_days to 1.0"
	)
	sim.call("tick", 2.5, [], [])
	assert_eq(
		float(sim.get("time_days")),
		3.5,
		"A second 2.5-day tick on top of the first should bring time_days to 3.5"
	)


func test_sim_version_is_m2_skeleton() -> void:
	# The version tag is a string rather than a numeric
	# constant so the version can be derived from a
	# single source of truth in a later milestone. The
	# M2-foundation tag is `0.1.0-m2-skeleton`; the
	# cycle 2 commit bumps it to `0.2.0-m2-track-a`,
	# and the cycle 3 commit to `0.3.0-m2-track-b`.
	# The M2 Track A inhabitants commit (this branch)
	# bumps it again to `0.4.0-m2-track-a` to mark
	# the inhabitant-side wiring landing on top of
	# the Track B contract / crisis wiring.
	var SimClass := load(_SIM_PATH)
	var v: String = String(SimClass.call("version"))
	assert_eq(v, "0.4.0-m2-track-a", "Sim.version() should return the M2-Track-A version tag")


func test_inhabitant_loads_and_has_deterministic_id() -> void:
	# The inhabitant's `id` is its stable identity. The
	# M2 contract pins the field as a `StringName`
	# defaulting to `&""`. The skeleton-level check is
	# that the class loads, that the `id` field
	# exists, and that the value is deterministic (a
	# fresh `Inhabitant` always has `&""`).
	var InhabitantClass := load(_INHABITANT_PATH)
	assert_not_null(InhabitantClass, "src/sim/inhabitant.gd should load as a class")
	var inhabitant: Object = InhabitantClass.new()
	assert_not_null(inhabitant, "Inhabitant.new() should produce a non-null instance")
	# `StringName("")` and the empty StringName
	# compare equal; we round-trip through String to
	# avoid a GDScript type-comparison pitfall on
	# some 4.x patch versions.
	var got_id: String = String(inhabitant.get("id"))
	assert_eq(got_id, "", "A freshly-constructed Inhabitant should have an empty StringName id")


func test_inhabitant_state_default_is_alive() -> void:
	# The M2 contract pins the inhabitant's lifecycle
	# state as an `int` enum (`0` = ALIVE, `1` = ABSENT,
	# `2` = DECEASED). The default for a fresh
	# inhabitant is `ALIVE`; absent / deceased are
	# state transitions the sim drives, not the
	# construction default.
	var InhabitantClass := load(_INHABITANT_PATH)
	var inhabitant: Object = InhabitantClass.new()
	assert_eq(
		int(inhabitant.get("state")),
		0,
		"A freshly-constructed Inhabitant should have state == 0 (ALIVE)"
	)


func test_inhabitant_role_default_is_settler() -> void:
	# The M2 contract pins the inhabitant's default
	# role as `"settler"`. Other roles (`"foreman"`,
	# `"scout"`, `"scribe"`, …) are added by the
	# M2 Track A commit.
	var InhabitantClass := load(_INHABITANT_PATH)
	var inhabitant: Object = InhabitantClass.new()
	assert_eq(
		String(inhabitant.get("role")),
		"settler",
		'A freshly-constructed Inhabitant should have role == "settler"'
	)


func test_needs_default_to_one() -> void:
	# The M2 contract pins the four `Needs` channels
	# (`food`, `rest`, `safety`, `recognition`) in
	# `[0.0, 1.0]` and defaults to `1.0` (the
	# M2 contract: an inhabitant arrives in the
	# realm well-fed, well-rested, safe, and
	# recognised).
	var NeedsClass := load(_NEEDS_PATH)
	var needs: Object = NeedsClass.new()
	assert_eq(float(needs.get("food")), 1.0, "Needs.food should default to 1.0")
	assert_eq(float(needs.get("rest")), 1.0, "Needs.rest should default to 1.0")
	assert_eq(float(needs.get("safety")), 1.0, "Needs.safety should default to 1.0")
	assert_eq(float(needs.get("recognition")), 1.0, "Needs.recognition should default to 1.0")


func test_event_memory_appends_entries() -> void:
	# The M2 contract pins `EventMemory.entries` as
	# an `Array` and pins the canonical `EventEntry`
	# `Dictionary` shape. The skeleton-level check
	# is that the class loads, that `entries` is
	# empty by default, and that an `append`-style
	# workflow (here, a direct `.append` call on
	# the public `entries` field) is the
	# supported way to add entries. The M2 cycle 2
	# commit replaces the direct `.append` with a
	# typed `record_event` method.
	var EventMemoryClass := load(_EVENT_MEMORY_PATH)
	var mem: Object = EventMemoryClass.new()
	var entries: Array = mem.get("entries")
	assert_eq(entries.size(), 0, "EventMemory.entries should default to []")
	(
		entries
		. append(
			{
				"id": &"evt_test",
				"time_days": 1.0,
				"kind": &"test.event",
				"summary": &"EVENT_TEST_SUMMARY",
				"affected": PackedStringArray(),
			}
		)
	)
	assert_eq(entries.size(), 1, "EventMemory.entries should accept a canonical EventEntry")


func test_event_log_append_and_range_query() -> void:
	# The M2 contract pins `EventLog` as append-only
	# with two methods: `append(entry)` and
	# `entries_in_range(from_day, to_day)`. The
	# skeleton-level check exercises both.
	var EventLogClass := load(_EVENT_LOG_PATH)
	var log: Object = EventLogClass.new()
	log.call(
		"append",
		{
			"id": &"evt_a",
			"time_days": 1.0,
			"kind": &"k",
			"summary": &"s",
			"affected": PackedStringArray()
		}
	)
	log.call(
		"append",
		{
			"id": &"evt_b",
			"time_days": 2.0,
			"kind": &"k",
			"summary": &"s",
			"affected": PackedStringArray()
		}
	)
	log.call(
		"append",
		{
			"id": &"evt_c",
			"time_days": 3.0,
			"kind": &"k",
			"summary": &"s",
			"affected": PackedStringArray()
		}
	)
	var r1: Array = log.call("entries_in_range", 0.0, 2.0)
	# Half-open interval: [0.0, 2.0) matches evt_a
	# (1.0) but not evt_b (2.0).
	assert_eq(r1.size(), 1, "entries_in_range(0.0, 2.0) should match exactly one entry")
	var r2: Array = log.call("entries_in_range", 1.0, 4.0)
	# [1.0, 4.0) matches evt_a, evt_b, evt_c.
	assert_eq(r2.size(), 3, "entries_in_range(1.0, 4.0) should match all three entries")


func test_relationship_default_neutral() -> void:
	# The M2 contract pins `Relationship.affinity` in
	# `[-1.0, 1.0]` and defaults to `0.0` (indifferent).
	# A fresh relationship is "indifferent"; events
	# move it up or down from there.
	var RelationshipClass := load(_RELATIONSHIP_PATH)
	var rel: Object = RelationshipClass.new()
	assert_eq(float(rel.get("affinity")), 0.0, "Relationship.affinity should default to 0.0")


func test_contract_default_unbreached() -> void:
	# The M2 contract pins `Contract.breached` as
	# `false` and `breach_at_day` as `0.0` for a
	# fresh contract. Breach is set by the M2
	# Track B per-tick evaluation rule.
	var ContractClass := load(_CONTRACT_PATH)
	var c: Object = ContractClass.new()
	assert_false(bool(c.get("breached")), "Contract.breached should default to false")
	assert_eq(float(c.get("breach_at_day")), 0.0, "Contract.breach_at_day should default to 0.0")


func test_task_default_zero_progress() -> void:
	# The M2 contract pins `Task.progress` in
	# `[0.0, 1.0]` and defaults to `0.0` (not
	# started). The Track A per-tick progress
	# rule moves the value up; `1.0` is
	# "complete" and triggers a `task.completed`
	# event.
	var TaskClass := load(_TASK_PATH)
	var t: Object = TaskClass.new()
	assert_eq(float(t.get("progress")), 0.0, "Task.progress should default to 0.0")


func test_crisis_default_unresolved() -> void:
	# The M2 contract pins `Crisis.resolved` as
	# `false` for a fresh crisis. Resolution is
	# set by the M2 Track B per-tick evaluation
	# rule.
	var CrisisClass := load(_CRISIS_PATH)
	var cr: Object = CrisisClass.new()
	assert_false(bool(cr.get("resolved")), "Crisis.resolved should default to false")


func test_constants_have_documented_values() -> void:
	# The M2 contract pins the four `SimConstants`
	# tuning values. The cycle 2 and cycle 3
	# commits tune them; the skeleton ships the
	# conservative defaults. A test on the
	# literals is a test on the public contract
	# the two tracks build against.
	var SimConstantsClass := load(_CONSTANTS_PATH)
	assert_eq(
		float(SimConstantsClass.get("TUNING_NEED_DECAY_PER_DAY")),
		0.05,
		"TUNING_NEED_DECAY_PER_DAY should be 0.05"
	)
	assert_eq(
		float(SimConstantsClass.get("TUNING_NEED_RECOVERY_PER_DAY")),
		0.10,
		"TUNING_NEED_RECOVERY_PER_DAY should be 0.10"
	)
	assert_eq(
		float(SimConstantsClass.get("TUNING_RELATIONSHIP_DRIFT_PER_DAY")),
		0.01,
		"TUNING_RELATIONSHIP_DRIFT_PER_DAY should be 0.01"
	)
	assert_eq(
		float(SimConstantsClass.get("TUNING_CRISIS_DEFAULT_DAYS")),
		7.0,
		"TUNING_CRISIS_DEFAULT_DAYS should be 7.0"
	)
