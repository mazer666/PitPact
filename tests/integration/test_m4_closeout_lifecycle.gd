# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4-Closeout lifecycle integration test.
#
# This file covers the per-tick lifecycle
# hooks: KnowledgeState.tick,
# Pactmaker.register_intervention,
# Pactmaker.apply_power, and
# Crisis.autonomous_resolve. The content
# catalogues and the per-tick step
# delegation live in
# `test_m4_closeout_content.gd`.
extends GutTest

const _KNOWLEDGE_PATH: String = "res://src/sim/knowledge_state.gd"
const _PACTMAKER_PATH: String = "res://src/sim/pactmaker.gd"
const _CRISIS_PATH: String = "res://src/sim/crisis.gd"
const _M4_RESEARCH_PATH: String = "res://src/content/m4_research.gd"
const _M4_RITUALS_PATH: String = "res://src/content/m4_rituals.gd"
const _M4_PACTMAKER_PATH: String = "res://src/content/m4_pactmaker.gd"

# --- KnowledgeState lifecycle ---------------------------------


func test_knowledge_state_tick_advances_research() -> void:
	var KS: GDScript = load(_KNOWLEDGE_PATH)
	var ks: Variant = KS.new()
	var Research: GDScript = load(_M4_RESEARCH_PATH)
	var cat: Dictionary = Research.call("all")
	var node: Variant = cat[&"binding_basics"]
	var sim: Dictionary = {
		"settings": null,
		"knowledge_state": ks,
		"pactmaker": null,
		"factions": null,
		"exploration_map": null,
		"anchor": Vector2i.ZERO,
		"crises": {},
	}
	assert_true(
		ks.call("register_research", node), "register_research should accept binding_basics"
	)
	ks.call("tick", 7.0, sim)
	assert_true(
		bool(ks.call("is_researched", &"binding_basics")),
		"binding_basics should be researched after 7 days"
	)


func test_knowledge_state_register_research_rejects_rituals() -> void:
	var KS: GDScript = load(_KNOWLEDGE_PATH)
	var ks: Variant = KS.new()
	var Rituals: GDScript = load(_M4_RITUALS_PATH)
	var cat: Dictionary = Rituals.call("all")
	var ritual: Variant = cat[&"survey_tile"]
	assert_false(
		bool(ks.call("register_research", ritual)), "register_research must reject a ritual node"
	)


func test_knowledge_state_register_research_enforces_prereqs() -> void:
	var KS: GDScript = load(_KNOWLEDGE_PATH)
	var ks: Variant = KS.new()
	var Research: GDScript = load(_M4_RESEARCH_PATH)
	var cat: Dictionary = Research.call("all")
	var deep: Variant = cat[&"deep_binding"]
	assert_false(
		bool(ks.call("register_research", deep)),
		"register_research must reject deep_binding without binding_rituals"
	)


func test_knowledge_state_register_ritual_consumes_days() -> void:
	var KS: GDScript = load(_KNOWLEDGE_PATH)
	var ks: Variant = KS.new()
	ks.set("researched", {&"survey_basics": 1})
	var Rituals: GDScript = load(_M4_RITUALS_PATH)
	var cat: Dictionary = Rituals.call("all")
	var ritual: Variant = cat[&"survey_tile"]
	ks.set("node_lookup", {&"survey_tile": ritual})
	var sim: Dictionary = {
		"settings": null,
		"knowledge_state": ks,
		"pactmaker": null,
		"factions": null,
		"exploration_map": null,
		"anchor": Vector2i.ZERO,
		"crises": {},
	}
	assert_true(ks.call("register_ritual", ritual), "register_ritual should accept survey_tile")
	ks.call("tick", 1.0, sim)
	var effects: Array = ks.call("consume_pending_effects")
	assert_eq(effects.size(), 1, "survey_tile should emit exactly one effect")
	assert_true(
		bool((effects[0] as Dictionary).get("reveal_tile", false)),
		"the effect should be a reveal_tile"
	)


# --- Pactmaker / Power ----------------------------------------


func test_pactmaker_register_intervention_debits_counter() -> void:
	var P: GDScript = load(_PACTMAKER_PATH)
	var p: Variant = P.new()
	p.set("intervention_limit", 3)
	p.set("intervention_count", 0)
	assert_true(bool(p.call("register_intervention")), "first intervention should succeed")
	assert_eq(int(p.get("intervention_count")), 1, "counter should be 1 after one intervention")
	assert_true(bool(p.call("register_intervention")), "second intervention should succeed")
	assert_true(bool(p.call("register_intervention")), "third intervention should succeed")
	assert_false(
		bool(p.call("register_intervention")), "fourth intervention must be rejected at the limit"
	)


func test_pactmaker_reset_yearly_count_returns_previous() -> void:
	var P: GDScript = load(_PACTMAKER_PATH)
	var p: Variant = P.new()
	p.set("intervention_limit", 3)
	p.set("intervention_count", 2)
	assert_eq(int(p.call("reset_yearly_count")), 2, "reset_yearly_count should return 2")
	assert_eq(int(p.get("intervention_count")), 0, "reset_yearly_count should zero the counter")


func test_pactmaker_apply_power_invokes_effect() -> void:
	var M4P: GDScript = load(_M4_PACTMAKER_PATH)
	var p: Variant = M4P.call("build")
	var Crisis: GDScript = load(_CRISIS_PATH)
	var cr: Variant = Crisis.call(
		"make",
		&"test_sealable",
		0.0,
		Callable(),
		[
			{
				"id": &"default",
				"label": &"DEFAULT",
				"summary": &"",
				"effect": Callable(),
				"is_default": true
			}
		]
	)
	cr.set("data", {"sealable": true})
	var sim: Dictionary = {
		"crises": {&"test_sealable": cr},
		"settings": null,
		"knowledge_state": null,
		"pactmaker": p,
		"factions": null,
		"exploration_map": null,
		"anchor": Vector2i.ZERO,
	}
	var ok: bool = bool(p.call("apply_power", &"seal_breach", sim, 5.0))
	assert_true(ok, "seal_breach should resolve a sealable crisis")
	assert_true(bool(cr.get("resolved")), "the crisis should be marked resolved")


func test_pactmaker_has_power_predicate() -> void:
	var M4P: GDScript = load(_M4_PACTMAKER_PATH)
	var p: Variant = M4P.call("build")
	assert_true(bool(p.call("has_power", &"seal_breach")), "should have seal_breach")
	assert_true(bool(p.call("has_power", &"pause_crisis")), "should have pause_crisis")
	assert_true(bool(p.call("has_power", &"reveal_tile")), "should have reveal_tile")
	assert_false(bool(p.call("has_power", &"unknown")), "should not have unknown")


# --- Crisis autonomous resolution -----------------------------


func test_crisis_autonomous_resolution_after_deadline() -> void:
	var Crisis: GDScript = load(_CRISIS_PATH)
	var cr: Variant = Crisis.call(
		"make",
		&"plague_test",
		0.0,
		Callable(),
		[
			{
				"id": &"quarantine",
				"label": &"Q",
				"summary": &"",
				"effect": Callable(),
				"is_default": true
			},
			{
				"id": &"burn",
				"label": &"B",
				"summary": &"",
				"effect": Callable(),
				"is_default": false
			}
		]
	)
	cr.set("autonomous_resolution_days", 14.0)
	cr.call("trigger", 0.0)
	assert_false(
		bool(cr.call("is_autonomous_deadline_reached", 13.9)),
		"13.9 days must not be enough to auto-resolve"
	)
	assert_true(
		bool(cr.call("is_autonomous_deadline_reached", 14.0)),
		"14.0 days must trigger the autonomous resolution"
	)
	var pick: StringName = cr.call("autonomous_resolve", 14.0)
	assert_eq(pick, &"quarantine", "autonomous resolve should pick the default choice")
	assert_true(bool(cr.get("resolved")), "the crisis should be marked resolved")


func test_crisis_paused_skips_autonomous_resolution() -> void:
	var Crisis: GDScript = load(_CRISIS_PATH)
	var cr: Variant = Crisis.call(
		"make",
		&"paused_test",
		0.0,
		Callable(),
		[{"id": &"q", "label": &"", "summary": &"", "effect": Callable(), "is_default": true}]
	)
	cr.set("autonomous_resolution_days", 14.0)
	cr.call("trigger", 0.0)
	cr.set("autonomous_outcome", &"paused")
	assert_false(
		bool(cr.call("is_autonomous_deadline_reached", 100.0)),
		"a paused crisis must not auto-resolve"
	)
