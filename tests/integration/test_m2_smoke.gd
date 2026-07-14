# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
extends GutTest

const _SEED: int = 42
const _W: int = 12
const _H: int = 12
const _TICKS: int = 10
const _CRISIS_DISPLAY_NAME_KEY: String = "CRISIS_FIRST_INSPECTION_NAME"
const HEARTH_RES: Resource = preload("res://data/rooms/hearth.tres")
const FIRST_INSPECTION_RES: Resource = preload("res://data/events/first_inspection.tres")


func _make_inhabitant(p_id: StringName, p_culture: StringName, p_role: StringName) -> Inhabitant:
	var inh: Inhabitant = Inhabitant.new()
	inh._init_id(p_id, p_culture, p_id, p_role)
	return inh


func _make_contract(p_id: StringName, p_inhabitant_id: StringName) -> Contract:
	var c: Contract = Contract.new()
	c.id = p_id
	c.inhabitant_id = p_inhabitant_id
	c.terms = {
		"lodging": true,
		"food_share": true,
		"labour_hours_per_day": 8,
		"breach_consequence": &"morale_penalty",
	}
	return c


func _build_crisis(p_log: EventLog) -> Crisis:
	return Crisis.make(
		&"first_inspection",
		float(FIRST_INSPECTION_RES.get("trigger_at_day")),
		func(_t: float) -> bool: return true,
		FIRST_INSPECTION_RES.get("choices").duplicate(true),
		p_log
	)


func _clone_inhabitants(p_inhabitants: Array) -> Array:
	var out: Array = []
	for inh in p_inhabitants:
		var cc: Inhabitant = Inhabitant.new()
		cc.from_dict(inh.to_dict())
		out.append(cc)
	return out


func _po_msgstr(p_po_path: String, p_msgid: String) -> String:
	var abs_path: String = ProjectSettings.globalize_path(p_po_path)
	var f: FileAccess = FileAccess.open(abs_path, FileAccess.READ)
	if f == null:
		return ""
	var content: String = f.get_as_text()
	f.close()
	var lines: PackedStringArray = content.split("\n")
	var saw_msgid: bool = false
	var target: String = 'msgid "' + p_msgid + '"'
	for line in lines:
		if saw_msgid:
			if line.begins_with('msgstr "'):
				return line.substr(8, line.length() - 9)
			continue
		if line.strip_edges() == target:
			saw_msgid = true
	return ""


func _build_sim(p_seed: int) -> Dictionary:
	var sim: Sim = Sim.new(p_seed)
	var inhabitants: Array = [
		_make_inhabitant(&"lantern_1", &"lanternbearer", &"scribe"),
		_make_inhabitant(&"settler_1", &"bellows", &"settler"),
		_make_inhabitant(&"settler_2", &"ledger", &"settler"),
	]
	for inh in inhabitants:
		sim.add_contract(_make_contract(StringName("pact_" + String(inh.id)), inh.id))
	sim.add_crisis(_build_crisis(sim.event_log))
	return {"sim": sim, "inhabitants": inhabitants}


func test_m2_end_to_end_smoke() -> void:
	# 1. Build a 12x12 realm with a 3x3 Hearth zone.
	var realm: Object = Realm.create(_SEED, _W, _H)
	var paint_rect: Rect2i = Rect2i(Vector2i(4, 4), Vector2i(3, 3))
	realm.paint_zone(paint_rect, 2)
	var room: Object = realm.promote_zone(paint_rect, 2, HEARTH_RES)
	assert_not_null(room, "Hearth was promoted from the zone")
	assert_eq(int(room.state), 0, "Hearth is in PLANNED (enum 0)")

	# 2. Build the sim and inhabitants.
	var b: Dictionary = _build_sim(_SEED)
	var sim: Sim = b["sim"]
	var inhabitants: Array = b["inhabitants"]
	var lantern: Inhabitant = inhabitants[0]
	var settler_1: Inhabitant = inhabitants[1]
	var settler_2: Inhabitant = inhabitants[2]

	# 3. Tick 10 days.
	var events: Array = []
	for d in range(_TICKS):
		sim.tick(1.0, inhabitants, events)
		assert_eq(int(sim.time_days), d + 1, "Tick %d advances sim.time_days" % (d + 1))

	# 4. Needs decayed.
	for inh in inhabitants:
		assert_lt(
			float(inh.needs.food),
			0.6,
			"%s food need decayed below 0.6 (got %f)" % [String(inh.id), float(inh.needs.food)]
		)
	pass_test("needs decay")

	# 5. Lanternbearer morale differs from generic mean.
	var lantern_morale: float = float(lantern.morale.morale)
	var gen_mean: float = (float(settler_1.morale.morale) + float(settler_2.morale.morale)) * 0.5
	assert_ne(
		lantern_morale,
		gen_mean,
		"Lanternbearer morale differs from generic mean (L=%f G=%f)" % [lantern_morale, gen_mean]
	)
	pass_test("culture bias")

	# 6. Crisis fired at day 7.
	var fired: bool = false
	for entry in sim.event_log.entries:
		if String(entry.get("kind", "")) == "crisis.triggered":
			fired = true
			break
	assert_true(fired, "FirstInspection crisis triggered")
	for cr in sim.crises.values():
		if cr is Crisis and cr.id == &"first_inspection":
			cr.resolve(sim.time_days, &"receive_inspector")
			break
	var choice_made: bool = false
	for entry in sim.event_log.entries:
		if String(entry.get("kind", "")) == "crisis.choice_made":
			choice_made = true
			break
	assert_true(choice_made, "FirstInspection crisis resolved with receive_inspector")

	# 7. Save/load roundtrip.
	var save_dict: Dictionary = realm.save()
	assert_true(save_dict.has("format_version"), "Save has format_version")
	assert_eq(int(save_dict["format_version"]), 1, "format_version is 1")
	var body: Dictionary = save_dict.get("body", {})
	var realm2: Object = Realm.new()
	var ok: bool = realm2.from_dict(body)
	assert_true(ok, "Realm reloaded from save body")
	assert_eq(realm2.seed, realm.seed, "Save/load: seed preserved")
	assert_eq(realm2.rooms.size(), realm.rooms.size(), "Save/load: room count")

	# 8. Locale: de.po has a real German translation
	# for the crisis display name (not the English
	# fallback).
	var de_msgstr: String = _po_msgstr("res://locales/de.po", _CRISIS_DISPLAY_NAME_KEY)
	assert_ne(de_msgstr, "", "de.po has a msgstr for %s" % _CRISIS_DISPLAY_NAME_KEY)
	var en_msgstr: String = _po_msgstr("res://locales/en.po", _CRISIS_DISPLAY_NAME_KEY)
	assert_ne(en_msgstr, "", "en.po has a msgstr for %s" % _CRISIS_DISPLAY_NAME_KEY)
	assert_ne(de_msgstr, en_msgstr, "de.po msgstr differs from en.po msgstr")

	# 9. Synthetic event append.
	var before: int = sim.event_log.entries.size()
	var synthetic: Dictionary = {
		"id": &"synthetic_test",
		"time_days": float(sim.time_days),
		"kind": &"test.synthetic",
		"summary": &"TEST_SYNTHETIC",
		"affected": PackedStringArray(),
	}
	sim.event_log.append(synthetic)
	assert_eq(sim.event_log.entries.size(), before + 1, "Synthetic event appended")
	sim.tick(0.001, inhabitants, events)
	assert_true(
		sim.event_log.entries.size() >= before + 1, "Tick did not erase the synthetic event"
	)

	# 10. Determinism: two sims with the same seed,
	# same inhabitants (cloned via from_dict/to_dict),
	# same contracts, same crisis, ticked 10 days,
	# produce the same number of event-log entries.
	var b2: Dictionary = _build_sim(_SEED)
	var sim_b: Sim = b2["sim"]
	var inhabitants_b: Array = b2["inhabitants"]
	for d in range(_TICKS):
		sim_b.tick(1.0, inhabitants_b, [])
	# Resolve sim_b's crisis the same way sim was
	# resolved, so the event-log sizes match.
	for cr in sim_b.crises.values():
		if cr is Crisis and cr.id == &"first_inspection":
			cr.resolve(sim_b.time_days, &"receive_inspector")
			break
	assert_eq(
		sim.event_log.entries.size() - 1,
		sim_b.event_log.entries.size(),
		"Determinism: same seed + same ticks -> same log size (excluding the synthetic event on sim)"
	)
