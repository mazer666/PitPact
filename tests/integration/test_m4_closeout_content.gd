# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4-Closeout content + sim integration test.
#
# This file covers the M4 content
# catalogues (research, ritual,
# faction, crisis, Pactmaker), the
# difficulty multipliers, the settings
# round-trip, the Sim registration
# surface, the end-to-end Sim per-tick
# step delegation, and the locale key
# coverage. The lifecycle hooks live
# in `test_m4_closeout_lifecycle.gd`.
extends GutTest

const _SIM_PATH: String = "res://src/sim/sim.gd"
const _FACTION_PATH: String = "res://src/sim/faction.gd"
const _SETTINGS_PATH: String = "res://src/sim/settings.gd"
const _CRISIS_PATH: String = "res://src/sim/crisis.gd"
const _DIFFICULTY_PATH: String = "res://src/sim/difficulty.gd"
const _KNOWLEDGE_PATH: String = "res://src/sim/knowledge_state.gd"
const _M4_SKELETON_PATH: String = "res://src/sim/m4_skeleton.gd"
const _M4_RESEARCH_PATH: String = "res://src/content/m4_research.gd"
const _M4_RITUALS_PATH: String = "res://src/content/m4_rituals.gd"
const _M4_FACTIONS_PATH: String = "res://src/content/m4_factions.gd"
const _M4_CRISES_PATH: String = "res://src/content/m4_crises.gd"
const _M4_PACTMAKER_PATH: String = "res://src/content/m4_pactmaker.gd"

# --- Faction stance drift -------------------------------------


func test_faction_update_stance_clamps_to_range() -> void:
	var F: GDScript = load(_FACTION_PATH)
	var f: Variant = F.new()
	f.set("stance", {"realm": 0})
	f.call("update_stance", &"realm", 50)
	assert_true(int(f.get("stance").get("realm", 0)) >= 50, "stance should accept +50")
	f.call("update_stance", &"realm", -200)
	assert_true(int(f.get("stance").get("realm", 0)) >= -100, "stance should clamp at -100")
	assert_true(int(f.get("stance").get("realm", 0)) <= 100, "stance should clamp at 100")


func test_faction_is_hostile_to_predicate() -> void:
	var F: GDScript = load(_FACTION_PATH)
	var f: Variant = F.new()
	assert_false(bool(f.call("is_hostile_to", &"realm")), "neutral stance should not be hostile")
	f.call("update_stance", &"realm", -60)
	assert_true(bool(f.call("is_hostile_to", &"realm")), "-60 should be hostile")


# --- Difficulty multipliers -----------------------------------


func test_difficulty_multipliers_have_documented_values() -> void:
	var D: GDScript = load(_DIFFICULTY_PATH)
	assert_eq(float(D.call("get_research_rate", 0)), 1.0, "PEACEFUL research rate should be 1.0")
	assert_eq(float(D.call("get_research_rate", 1)), 1.0, "BALANCED research rate should be 1.0")
	assert_eq(float(D.call("get_research_rate", 2)), 0.5, "CRUEL research rate should be 0.5")
	assert_eq(
		float(D.call("get_morale_delta_per_day", 0)), 0.05, "PEACEFUL morale delta should be 0.05"
	)
	assert_eq(
		float(D.call("get_morale_delta_per_day", 1)), 0.0, "BALANCED morale delta should be 0.0"
	)
	assert_eq(
		float(D.call("get_morale_delta_per_day", 2)), -0.1, "CRUEL morale delta should be -0.1"
	)
	assert_eq(
		float(D.call("get_crisis_chance_per_day", 0)), 0.0, "PEACEFUL crisis chance should be 0.0"
	)
	assert_eq(
		float(D.call("get_crisis_chance_per_day", 1)), 0.05, "BALANCED crisis chance should be 0.05"
	)
	assert_eq(
		float(D.call("get_crisis_chance_per_day", 2)), 0.1, "CRUEL crisis chance should be 0.1"
	)


# --- Settings round-trip ---------------------------------------


func test_settings_round_trip() -> void:
	var S: GDScript = load(_SETTINGS_PATH)
	var s: Variant = S.new()
	s.set("difficulty", 2)
	s.set("auto_resolve_days", 14)
	s.set("locale", "de")
	var d: Dictionary = s.call("to_dict")
	var s2: Variant = S.call("from_dict", d)
	assert_eq(int(s2.get("difficulty")), 2, "difficulty should round-trip")
	assert_eq(int(s2.get("auto_resolve_days")), 14, "auto_resolve_days should round-trip")
	assert_eq(String(s2.get("locale")), "de", "locale should round-trip")


# --- M4 content catalogues ------------------------------------


func test_m4_research_catalogue_has_six_nodes() -> void:
	var R: GDScript = load(_M4_RESEARCH_PATH)
	var cat: Dictionary = R.call("all")
	assert_eq(cat.size(), 6, "M4 research catalogue should have 6 nodes")


func test_m4_rituals_catalogue_has_three_nodes() -> void:
	var R: GDScript = load(_M4_RITUALS_PATH)
	var cat: Dictionary = R.call("all")
	assert_eq(cat.size(), 3, "M4 rituals catalogue should have 3 nodes")


func test_m4_factions_catalogue_has_three_factions() -> void:
	var F: GDScript = load(_M4_FACTIONS_PATH)
	var arr: Array = F.call("all")
	assert_eq(arr.size(), 3, "M4 factions catalogue should have 3 factions")


func test_m4_crises_catalogue_has_two_crises() -> void:
	var C: GDScript = load(_M4_CRISES_PATH)
	var arr: Array = C.call("all")
	assert_eq(arr.size(), 2, "M4 crises catalogue should have 2 crises")


# --- Sim registration surface ---------------------------------


func test_sim_register_knowledge_and_pactmaker() -> void:
	var Sim: GDScript = load(_SIM_PATH)
	var sim: Variant = Sim.new()
	var KS: GDScript = load(_KNOWLEDGE_PATH)
	var ks: Variant = KS.new()
	sim.call("register_knowledge", ks)
	assert_eq(sim.get("knowledge_state"), ks, "register_knowledge should bind the state")
	var M4P: GDScript = load(_M4_PACTMAKER_PATH)
	var p: Variant = M4P.call("build")
	sim.call("register_pactmaker", p)
	assert_eq(sim.get("pactmaker"), p, "register_pactmaker should bind the Pactmaker")
	var F: GDScript = load(_M4_FACTIONS_PATH)
	var factions: Array = F.call("all")
	sim.call("register_factions", factions)
	assert_eq(sim.get("factions"), factions, "register_factions should bind the list")


func test_m4_pactmaker_has_three_powers() -> void:
	var P: GDScript = load(_M4_PACTMAKER_PATH)
	var p: Variant = P.call("build")
	assert_eq((p.get("powers") as Array).size(), 3, "M4 Pactmaker should have 3 powers")
	assert_eq(
		int(p.get("intervention_limit")), 3, "M4 Pactmaker should have intervention_limit = 3"
	)


# --- Sim end-to-end smoke --------------------------------------


func test_sim_step_7c_advances_research() -> void:
	var Sim: GDScript = load(_SIM_PATH)
	var sim: Variant = Sim.new()
	var KS: GDScript = load(_KNOWLEDGE_PATH)
	var ks: Variant = KS.new()
	var Research: GDScript = load(_M4_RESEARCH_PATH)
	var cat: Dictionary = Research.call("all")
	var node: Variant = cat[&"binding_basics"]
	ks.call("register_research", node)
	sim.call("register_knowledge", ks)
	var S: GDScript = load(_SETTINGS_PATH)
	var s: Variant = S.new()
	sim.call("register_settings", s)
	sim.call("tick", 7.0, [], [])
	assert_true(
		bool(ks.call("is_researched", &"binding_basics")),
		"Sim.step 7c should advance binding_basics to researched in 7 days"
	)


func test_sim_step_7d_advances_faction_stance() -> void:
	var Sim: GDScript = load(_SIM_PATH)
	var sim: Variant = Sim.new()
	var F: GDScript = load(_FACTION_PATH)
	var f1: Variant = F.new()
	f1.set("stance", {"realm": -0.5})
	var f2: Variant = F.new()
	f2.set("stance", {"realm": 0.5})
	sim.call("register_factions", [f1, f2])
	sim.call("tick", 1.0, [], [])
	var s1: float = float((f1.get("stance") as Dictionary).get("realm", 0.0))
	var s2: float = float((f2.get("stance") as Dictionary).get("realm", 0.0))
	assert_lt(s1, -0.5, "hostile stance should drift further hostile (s1 < -0.5)")
	assert_gt(s2, 0.5, "friendly stance should drift further friendly (s2 > 0.5)")


func test_sim_step_7e_resolves_autonomous_crisis() -> void:
	var Sim: GDScript = load(_SIM_PATH)
	var sim: Variant = Sim.new()
	var Crisis: GDScript = load(_CRISIS_PATH)
	var cr: Variant = Crisis.call(
		"make",
		&"auto_test",
		0.0,
		Callable(),
		[
			{
				"id": &"default_choice",
				"label": &"",
				"summary": &"",
				"effect": Callable(),
				"is_default": true
			}
		]
	)
	cr.set("autonomous_resolution_days", 14.0)
	sim.call("add_crisis", cr)
	sim.call("tick", 0.1, [], [])
	sim.call("tick", 14.0, [], [])
	assert_true(bool(cr.get("resolved")), "crisis should be auto-resolved at day 14")
	assert_eq(
		StringName(cr.get("chosen_id")),
		&"default_choice",
		"the autonomous resolve should pick default_choice"
	)
	assert_eq(
		StringName(cr.get("autonomous_outcome")),
		&"default",
		'autonomous_outcome should be &"default"'
	)


# --- Locale coverage -------------------------------------------


func test_locale_keys_present() -> void:
	var en_path: String = "res://locales/en.po"
	var de_path: String = "res://locales/de.po"
	var en_file: FileAccess = FileAccess.open(en_path, FileAccess.READ)
	var de_file: FileAccess = FileAccess.open(de_path, FileAccess.READ)
	assert_not_null(en_file, "en.po should be readable")
	assert_not_null(de_file, "de.po should be readable")
	var en_text: String = en_file.get_as_text()
	var de_text: String = de_file.get_as_text()
	en_file.close()
	de_file.close()
	for key in [
		"SETTINGS_DIFFICULTY_LABEL",
		"PACTMAKER_NAME",
		"POWER_SEAL_BREACH_NAME",
		"FACTION_LANTERN_CLAN_NAME",
		"M4_RESEARCH_BINDING_BASICS_NAME",
		"M4_RITUAL_BIND_INHABITANT_NAME",
		"M4_CRISIS_PLAGUE_QUARANTINE",
		"EVENT_CRISIS_AUTONOMOUS_RESOLVED",
	]:
		assert_string_contains(en_text, 'msgid "%s"' % key, "en.po should contain %s" % key)
		assert_string_contains(de_text, 'msgid "%s"' % key, "de.po should contain %s" % key)
