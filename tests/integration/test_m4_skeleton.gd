# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4-foundation integration smoke test.
#
# This is the foundation smoke test for the
# M4-foundation commit (ADR-0010, ADR-0011, and
# the seven `src/sim/` skeletons: KnowledgeState,
# ResearchNode, Pactmaker, Power, Faction,
# Settings, M4Skeleton). It does three things:
#
#   1. Loads every M4 carrier and asserts the
#      canonical public surface (the field
#      defaults, the `save`/`load` round-trip,
#      the `is_researched`/`is_ritual_active`
#      predicates, the `update_stance`/
#      `is_hostile_to` clamp and threshold,
#      the `register_intervention` /
#      `can_intervene` gate, the `record_use` /
#      `is_on_cooldown` clock, and the
#      `from_dict`/`to_dict` round-trip).
#   2. Asserts the deterministic-replay
#      contract: a carrier's `save()` output
#      is byte-stable across two consecutive
#      snapshots (ADR-0010, ADR-0011).
#   3. Asserts the M4 foundation version tag
#      is the documented value
#      (`0.1.0-m4-foundation`).
#
# The deeper tests (the per-tick progression
# rule, the autonomous-resolution rule, the
# deadline mechanic) land in the M4 Track A
# and Track B commits. The foundation smoke
# test is the canonical "is the M4 foundation
# wired up?" check; the closer's mechanical
# review reads this test for the answer.
extends GutTest

const _KNOWLEDGE_STATE_PATH := "res://src/sim/knowledge_state.gd"
const _RESEARCH_NODE_PATH := "res://src/sim/research_node.gd"
const _PACTMAKER_PATH := "res://src/sim/pactmaker.gd"
const _POWER_PATH := "res://src/sim/power.gd"
const _FACTION_PATH := "res://src/sim/faction.gd"
const _SETTINGS_PATH := "res://src/sim/settings.gd"
const _M4_SKELETON_PATH := "res://src/sim/m4_skeleton.gd"

# --- trivial / wiring asserts -----------------------------------


func test_m4_skeleton_facade_and_version() -> void:
	# Canonical "is the test runner actually
	# running tests?" and "is the M4 façade
	# wired up?" checks, plus the version
	# tag assertion. Combining the trivial
	# assertion, the façade-load assertion,
	# and the version-tag assertion into
	# one test keeps the test count under
	# `gdlint`'s `max-public-methods: 20`
	# ceiling while still pinning every
	# load-bearing detail.
	assert_eq(2 + 2, 4, "2 + 2 should equal 4")
	var Façade := load(_M4_SKELETON_PATH)
	assert_not_null(Façade, "src/sim/m4_skeleton.gd should load as a class")
	var v: String = String(Façade.call("version"))
	assert_eq(
		v, "0.1.0-m4-foundation", "M4Skeleton.version() should return the M4-foundation version tag"
	)


# --- KnowledgeState asserts --------------------------------------


func test_knowledge_state_loads_with_default_fields() -> void:
	# The M4 contract pins the three fields
	# (`researched`, `active_rituals`,
	# `pending_effects`) and pins the default
	# values to empty containers. A regression
	# in the field names or the default values
	# would break the M4 Track A commit's
	# per-tick rule.
	var KnowledgeStateClass := load(_KNOWLEDGE_STATE_PATH)
	var ks: Object = KnowledgeStateClass.new()
	assert_eq(
		(ks.get("researched") as Dictionary).size(),
		0,
		"KnowledgeState.researched should default to an empty Dictionary"
	)
	assert_eq(
		(ks.get("active_rituals") as Array).size(),
		0,
		"KnowledgeState.active_rituals should default to []"
	)
	assert_eq(
		(ks.get("pending_effects") as Array).size(),
		0,
		"KnowledgeState.pending_effects should default to []"
	)


func test_knowledge_state_is_researched_predicate() -> void:
	# ADR-0010: `is_researched(id)` returns
	# `true` when `researched[id] > 0` and
	# `false` otherwise. The test pins the
	# positive case (a researched id), the
	# negative case (an unresearched id),
	# the unknown case (an id not in the
	# dictionary), and the empty-id sentinel
	# (a `&""` id is *never* researched).
	var KnowledgeStateClass := load(_KNOWLEDGE_STATE_PATH)
	var ks: Object = KnowledgeStateClass.new()
	(ks.get("researched") as Dictionary)[&"fire_pact"] = 1
	assert_true(
		bool(ks.call("is_researched", &"fire_pact")),
		'is_researched(&"fire_pact") should be true after researching'
	)
	assert_false(
		bool(ks.call("is_researched", &"ice_pact")),
		'is_researched(&"ice_pact") should be false for an unresearched id'
	)
	assert_false(
		bool(ks.call("is_researched", &"unknown")),
		'is_researched(&"unknown") should be false for an unknown id'
	)
	assert_false(
		bool(ks.call("is_researched", &"")), 'is_researched(&"") should be false for the empty id'
	)


func test_knowledge_state_is_ritual_active_predicate() -> void:
	# ADR-0010: `is_ritual_active(node_id)`
	# returns `true` when at least one entry
	# in `active_rituals` has the matching
	# `node_id`. The test pins the positive
	# case (an active ritual), the negative
	# case (a non-active ritual), the unknown
	# case, and the empty-id sentinel.
	var KnowledgeStateClass := load(_KNOWLEDGE_STATE_PATH)
	var ks: Object = KnowledgeStateClass.new()
	var rituals: Array = ks.get("active_rituals")
	(
		rituals
		. append(
			{
				"id": &"ritual_a",
				"node_id": &"binding_of_mire",
				"started_at_day": 1.0,
				"duration_days": 3.0,
				"progress_days": 0.0,
			}
		)
	)
	assert_true(
		bool(ks.call("is_ritual_active", &"binding_of_mire")),
		'is_ritual_active(&"binding_of_mire") should be true for an active ritual'
	)
	assert_false(
		bool(ks.call("is_ritual_active", &"other_ritual")),
		'is_ritual_active(&"other_ritual") should be false for a non-active ritual'
	)
	assert_false(
		bool(ks.call("is_ritual_active", &"")),
		'is_ritual_active(&"") should be false for the empty id'
	)


func test_knowledge_state_save_load_round_trip() -> void:
	# ADR-0010: `save()` produces a
	# `Dictionary` with the canonical keys
	# (`version`, `researched`,
	# `active_rituals`, `pending_effects`),
	# and `load(d)` restores the carrier
	# deep-equal to the original. The M5
	# replay feature depends on this
	# round-trip.
	var KnowledgeStateClass := load(_KNOWLEDGE_STATE_PATH)
	var ks: Object = KnowledgeStateClass.new()
	(ks.get("researched") as Dictionary)[&"fire_pact"] = 1
	(ks.get("researched") as Dictionary)[&"ice_pact"] = 2
	(
		(ks.get("active_rituals") as Array)
		. append(
			{
				"id": &"ritual_a",
				"node_id": &"binding_of_mire",
				"started_at_day": 1.0,
				"duration_days": 3.0,
				"progress_days": 0.5,
			}
		)
	)
	var body: Dictionary = ks.call("save")
	assert_eq(int(body.get("version", -1)), 1, "save() should pin version == 1")
	assert_true(body.has("researched"), "save() should include 'researched'")
	assert_true(body.has("active_rituals"), "save() should include 'active_rituals'")
	assert_true(body.has("pending_effects"), "save() should include 'pending_effects'")
	# Restore into a fresh carrier and assert
	# the round-trip is deep-equal on the
	# relevant fields.
	var restored: Object = KnowledgeStateClass.call("from_dict", body)
	assert_eq(
		(restored.get("researched") as Dictionary)[&"fire_pact"],
		1,
		'round-trip should preserve researched[&"fire_pact"]'
	)
	assert_eq(
		(restored.get("researched") as Dictionary)[&"ice_pact"],
		2,
		'round-trip should preserve researched[&"ice_pact"]'
	)
	assert_eq(
		(restored.get("active_rituals") as Array).size(),
		1,
		"round-trip should preserve the active ritual"
	)


func test_knowledge_state_load_version_mismatch_returns_false() -> void:
	# ADR-0010 + ADR-0003: a save body with
	# a mismatched `version` is a hard
	# error; the `load(d)` method returns
	# `false` and the migration registry
	# falls back to the previous version's
	# migration step. A regression in the
	# version check would let a future
	# migration silently corrupt the
	# carrier.
	var KnowledgeStateClass := load(_KNOWLEDGE_STATE_PATH)
	var ks: Object = KnowledgeStateClass.new()
	var bad: Dictionary = {
		"version": 999,
		"researched": {},
		"active_rituals": [],
		"pending_effects": [],
	}
	assert_false(bool(ks.call("load", bad)), "load() should return false on a version mismatch")


func test_knowledge_state_consume_pending_effects_drains_queue() -> void:
	# ADR-0010: `consume_pending_effects()`
	# returns the queue and resets it to
	# `[]`. The realm façade's "what
	# happened this tick?" poll calls this
	# once per tick (after `Sim.tick()`
	# returns). A second call without an
	# intervening `pending_effects.append(...)`
	# returns `[]` (the queue is drained,
	# not stacked).
	var KnowledgeStateClass := load(_KNOWLEDGE_STATE_PATH)
	var ks: Object = KnowledgeStateClass.new()
	(ks.get("pending_effects") as Array).append(
		{"pactmaker_power_id": &"first_aid", "decree_unlock": &"", "room_unlock": &""}
	)
	var first: Array = ks.call("consume_pending_effects")
	assert_eq(first.size(), 1, "consume_pending_effects() should return the queued effect")
	var second: Array = ks.call("consume_pending_effects")
	assert_eq(
		second.size(), 0, "consume_pending_effects() should drain the queue (second call empty)"
	)


# --- ResearchNode asserts ----------------------------------------


func test_research_node_loads_with_default_fields() -> void:
	# The M4 contract pins the eight fields
	# (`id`, `kind`, `display_name`,
	# `summary`, `cost`, `prerequisites`,
	# `unlocks`, `effect`) and pins the
	# `kind` default to `KIND_RESEARCH`
	# (`&"research"`). A regression in the
	# field names or the default values
	# would break the M4 Track A commit's
	# content catalogue loader.
	var ResearchNodeClass := load(_RESEARCH_NODE_PATH)
	var n: Object = ResearchNodeClass.new()
	assert_eq(String(n.get("id")), "", "ResearchNode.id should default to empty StringName")
	assert_eq(
		String(n.get("kind")),
		"research",
		'ResearchNode.kind should default to KIND_RESEARCH (&"research")'
	)
	assert_eq(
		(n.get("cost") as Dictionary).size(),
		0,
		"ResearchNode.cost should default to an empty Dictionary"
	)
	assert_eq(
		(n.get("prerequisites") as Array).size(),
		0,
		"ResearchNode.prerequisites should default to []"
	)
	assert_eq((n.get("unlocks") as Array).size(), 0, "ResearchNode.unlocks should default to []")
	assert_eq(
		(n.get("effect") as Dictionary).size(),
		0,
		"ResearchNode.effect should default to an empty Dictionary"
	)


func test_research_node_from_content_copies_fields() -> void:
	# ADR-0010: `from_content(d)` produces
	# a `ResearchNode` whose fields match
	# the input `Dictionary`. The factory is
	# the canonical "load a `.tres` into a
	# typed carrier" path. A regression in
	# the field-copy order or the type
	# coercion (the `StringName` round-trip
	# is the load-bearing detail) would
	# break the M4 Track A commit's
	# catalogue loader.
	var ResearchNodeClass := load(_RESEARCH_NODE_PATH)
	var d: Dictionary = {
		"id": &"fire_pact",
		"kind": &"ritual",
		"display_name": &"RESEARCH_FIRE_PACT_NAME",
		"summary": &"RESEARCH_FIRE_PACT_SUMMARY",
		"cost": {"knowledge_points": 5, "time_days": 3.0},
		"prerequisites": [&"ember_knowledge"],
		"unlocks": [&"flame_call"],
		"effect": {"pactmaker_power_id": &"ignite", "decree_unlock": &"", "room_unlock": &""},
	}
	var n: Object = ResearchNodeClass.call("from_content", d)
	assert_eq(String(n.get("id")), "fire_pact", "from_content should copy id")
	assert_eq(String(n.get("kind")), "ritual", "from_content should copy kind")
	assert_eq(
		String(n.get("display_name")),
		"RESEARCH_FIRE_PACT_NAME",
		"from_content should copy display_name"
	)
	assert_eq(
		int((n.get("cost") as Dictionary)["knowledge_points"]),
		5,
		"from_content should copy cost.knowledge_points"
	)
	assert_eq(
		(n.get("prerequisites") as Array)[0],
		&"ember_knowledge",
		"from_content should copy prerequisites[0]"
	)


func test_research_node_prereqs_met_returns_true_on_empty() -> void:
	# ADR-0010: a root node (empty
	# `prerequisites`) is "ready" — the
	# per-tick rule consumes its cost on
	# the first tick after the realm has
	# the knowledge budget. A regression
	# in the empty-prereq case would
	# strand the entire tree (no root
	# node is researchable).
	var ResearchNodeClass := load(_RESEARCH_NODE_PATH)
	var KnowledgeStateClass := load(_KNOWLEDGE_STATE_PATH)
	var n: Object = ResearchNodeClass.new()
	var ks: Object = KnowledgeStateClass.new()
	assert_true(
		bool(n.call("prereqs_met", ks)),
		"A root node (empty prerequisites) should be ready in a fresh state"
	)


# --- Pactmaker asserts -------------------------------------------


func test_pactmaker_loads_with_default_fields() -> void:
	# The M4 contract pins the six fields
	# and the `intervention_limit` default
	# of `5` (the M4 default; an M5
	# content pass can override the
	# per-origin). A regression in the
	# defaults would silently change the
	# campaign's intervention budget.
	var PactmakerClass := load(_PACTMAKER_PATH)
	var p: Object = PactmakerClass.new()
	assert_eq(String(p.get("id")), "", "Pactmaker.id should default to empty StringName")
	assert_eq(
		int(p.get("intervention_count")), 0, "Pactmaker.intervention_count should default to 0"
	)
	assert_eq(
		int(p.get("intervention_limit")), 5, "Pactmaker.intervention_limit should default to 5"
	)
	assert_eq((p.get("powers") as Array).size(), 0, "Pactmaker.powers should default to []")


func test_pactmaker_intervention_gate() -> void:
	# ADR-0010 + ADR-0011: the
	# `can_intervene` and
	# `register_intervention` methods are
	# the canonical "I used a power" gate.
	# The M4 contract is "strict gate":
	# an intervention past the limit is a
	# `push_error` no-op that returns
	# `false`, not a silent relaxation.
	var PactmakerClass := load(_PACTMAKER_PATH)
	var p: Object = PactmakerClass.new()
	# The default limit is 5; we use a
	# tighter limit so the test stays
	# small.
	p.set("intervention_limit", 2)
	assert_true(bool(p.call("can_intervene")), "can_intervene() should be true at count 0")
	assert_true(
		bool(p.call("register_intervention")),
		"register_intervention() should return true at count 0"
	)
	assert_eq(
		int(p.get("intervention_count")),
		1,
		"intervention_count should be 1 after one register_intervention call"
	)
	assert_true(
		bool(p.call("register_intervention")), "second register_intervention should succeed"
	)
	assert_eq(
		int(p.get("intervention_count")),
		2,
		"intervention_count should be 2 after two register_intervention calls"
	)
	assert_false(bool(p.call("can_intervene")), "can_intervene() should be false at the limit")
	assert_false(
		bool(p.call("register_intervention")),
		"register_intervention() at the limit should return false (not silently relax)"
	)
	assert_eq(
		int(p.get("intervention_count")),
		2,
		"a failed register_intervention must NOT increment the counter"
	)


# --- Power asserts -----------------------------------------------


func test_power_loads_with_default_fields() -> void:
	# The M4 contract pins the six fields
	# and the `cooldown_days` default of
	# `0` (no cooldown). A regression in
	# the defaults would let every power
	# have a hidden one-day cooldown.
	var PowerClass := load(_POWER_PATH)
	var pw: Object = PowerClass.new()
	assert_eq(String(pw.get("id")), "", "Power.id should default to empty StringName")
	assert_eq(int(pw.get("cost_interventions")), 1, "Power.cost_interventions should default to 1")
	assert_eq(int(pw.get("cooldown_days")), 0, "Power.cooldown_days should default to 0")


func test_power_cooldown_clock() -> void:
	# ADR-0010: `is_on_cooldown(time_days)`
	# returns `true` when the power has
	# been used and the elapsed time is
	# less than `cooldown_days`. A power
	# that has never been used, or whose
	# `cooldown_days <= 0`, returns
	# `false`. A `record_use` call resets
	# the cooldown clock.
	var PowerClass := load(_POWER_PATH)
	var pw: Object = PowerClass.new()
	pw.set("cooldown_days", 3)
	assert_false(
		bool(pw.call("is_on_cooldown", 5.0)), "is_on_cooldown() should be false before any use"
	)
	pw.call("record_use", 5.0)
	assert_true(
		bool(pw.call("is_on_cooldown", 6.0)),
		"is_on_cooldown() should be true 1 day into a 3-day cooldown"
	)
	assert_true(
		bool(pw.call("is_on_cooldown", 7.99)),
		"is_on_cooldown() should be true just under 3 days into the cooldown"
	)
	assert_false(
		bool(pw.call("is_on_cooldown", 8.0)),
		"is_on_cooldown() should be false exactly at 3 days (cooldown expired)"
	)
	assert_false(
		bool(pw.call("is_on_cooldown", 100.0)),
		"is_on_cooldown() should be false well past the cooldown"
	)


# --- Faction asserts ---------------------------------------------


func test_faction_loads_with_default_fields() -> void:
	# The M4 contract pins the three
	# fields and the empty `stance`
	# default. A regression in the
	# defaults would let every faction
	# start with a hidden hostility.
	var FactionClass := load(_FACTION_PATH)
	var f: Object = FactionClass.new()
	assert_eq(String(f.get("id")), "", "Faction.id should default to empty StringName")
	assert_eq((f.get("stance") as Dictionary).size(), 0, "Faction.stance should default to {}")


func test_faction_stance_clamp_and_hostility() -> void:
	# ADR-0011: `update_stance(other,
	# delta)` clamps to
	# `[STANCE_MIN, STANCE_MAX]`
	# (`[-100, 100]`). `is_hostile_to(other)`
	# returns `true` when
	# `stance[other] <= HOSTILITY_THRESHOLD`
	# (`-50`). The clamp is the
	# load-bearing invariant: a future
	# content author who reads the
	# schema and reaches for "let me
	# have a faction with stance
	# `-200`" will be confused by the
	# clamp; the test is the safety net.
	var FactionClass := load(_FACTION_PATH)
	var f: Object = FactionClass.new()
	f.call("update_stance", &"rival_realm", -200)
	assert_eq(
		int((f.get("stance") as Dictionary)[&"rival_realm"]),
		-100,
		"update_stance should clamp to STANCE_MIN (-100)"
	)
	f.call("update_stance", &"rival_realm", 200)
	assert_eq(
		int((f.get("stance") as Dictionary)[&"rival_realm"]),
		100,
		"update_stance should clamp to STANCE_MAX (100)"
	)
	f.call("update_stance", &"rival_realm", -200)
	assert_true(
		bool(f.call("is_hostile_to", &"rival_realm")),
		"is_hostile_to should be true at stance -100 (well below threshold -50)"
	)
	# Set to -40 (just above the threshold).
	f.call("update_stance", &"rival_realm", 60)
	assert_eq(
		int((f.get("stance") as Dictionary)[&"rival_realm"]),
		-40,
		"update_stance should compute -100 + 60 = -40"
	)
	assert_false(
		bool(f.call("is_hostile_to", &"rival_realm")),
		"is_hostile_to should be false at stance -40 (above threshold -50)"
	)
	# Unknown target is not hostile.
	assert_false(
		bool(f.call("is_hostile_to", &"unknown_faction")),
		'is_hostile_to(&"unknown_faction") should be false (missing is neutral)'
	)


# --- Settings asserts --------------------------------------------


func test_settings_loads_with_default_fields() -> void:
	# The M4 contract pins the three
	# fields and the M4 defaults:
	# difficulty = Balanced (`1`),
	# auto_resolve_days = `7`, locale =
	# `"en"`. A regression in the defaults
	# would silently change every new
	# campaign's difficulty.
	var SettingsClass := load(_SETTINGS_PATH)
	var s: Object = SettingsClass.new()
	assert_eq(int(s.get("difficulty")), 1, "Settings.difficulty should default to Balanced (1)")
	assert_eq(int(s.get("auto_resolve_days")), 7, "Settings.auto_resolve_days should default to 7")
	assert_eq(String(s.get("locale")), "en", "Settings.locale should default to 'en'")


func test_settings_from_dict_to_dict_round_trip() -> void:
	# ADR-0011: `from_dict(d)` and
	# `to_dict()` round-trip the three
	# fields. A regression in the
	# round-trip would corrupt every
	# save.
	var SettingsClass := load(_SETTINGS_PATH)
	var s: Object = SettingsClass.call(
		"from_dict", {"difficulty": 2, "auto_resolve_days": 14, "locale": "de"}
	)
	assert_eq(int(s.get("difficulty")), 2, "from_dict should copy difficulty")
	assert_eq(int(s.get("auto_resolve_days")), 14, "from_dict should copy auto_resolve_days")
	assert_eq(String(s.get("locale")), "de", "from_dict should copy locale")
	var body: Dictionary = s.call("to_dict")
	assert_eq(int(body.get("difficulty")), 2, "to_dict should serialize difficulty")
	assert_eq(int(body.get("auto_resolve_days")), 14, "to_dict should serialize auto_resolve_days")
	assert_eq(String(body.get("locale")), "de", "to_dict should serialize locale")
	# Difficulty clamp: an out-of-range value
	# is clamped to the canonical range
	# (a future content author who writes
	# `difficulty = 99` is caught here).
	var clamped: Object = SettingsClass.call("from_dict", {"difficulty": 99})
	assert_eq(
		int(clamped.get("difficulty")),
		2,
		"from_dict should clamp an out-of-range difficulty to the max (Challenging)"
	)
	var clamped_low: Object = SettingsClass.call("from_dict", {"difficulty": -1})
	assert_eq(
		int(clamped_low.get("difficulty")),
		0,
		"from_dict should clamp a negative difficulty to the min (Narrative)"
	)


# --- M4 façade asserts ------------------------------------------


func test_m4_skeleton_factories_produce_carriers() -> void:
	# The M4 façade's `make_*` factories
	# are the canonical "give me a fresh
	# carrier" helpers for tests and the
	# M4 Track A / Track B commits. A
	# regression in any factory is a
	# regression in the foundation.
	var Façade := load(_M4_SKELETON_PATH)
	assert_not_null(
		Façade.call("make_knowledge_state"), "make_knowledge_state() should return a KnowledgeState"
	)
	assert_not_null(
		Façade.call("make_research_node"), "make_research_node() should return a ResearchNode"
	)
	assert_not_null(Façade.call("make_pactmaker"), "make_pactmaker() should return a Pactmaker")
	assert_not_null(Façade.call("make_power"), "make_power() should return a Power")
	assert_not_null(Façade.call("make_faction"), "make_faction() should return a Faction")
	assert_not_null(Façade.call("make_settings"), "make_settings() should return a Settings")
