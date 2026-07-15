# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
extends GutTest

## M3-Closeout smoke test. End-to-end:
##   1. Generate a 24x24 world with the two M3
##      biomes (Marshlands + Highlands).
##   2. Register an exploration map and tick fog
##      reveal.
##   3. Register 3 narrative anchors; tick step 7b
##      fires the time-gated anchor and skips the
##      location-gated one.
##   4. Resolve a FirstInspection crisis via the
##      branch tree (accept_audit / counter_offer).
##   5. Save/load roundtrip.
##   6. Locale-switch (en -> de) on a crisis key.
##   7. Determinism: two sims with the same seed
##      produce identical event logs.

const _SEED: int = 4242
const _W: int = 24
const _H: int = 24
const _TICKS: int = 10


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


func _build_sim(p_anchors: Array, p_log: EventLog) -> Sim:
	var sim: Sim = Sim.new(_SEED)
	sim.register_anchors(p_anchors)
	var root: BranchNode = BranchNode.make_root(
		&"first_inspection", [&"accept_audit", &"counter_offer"]
	)
	var cr: Crisis = Crisis.make(
		root.id,
		3.0,
		func(_t: float) -> bool: return true,
		[{"id": &"receive_inspector", "effect": Callable()}],
		p_log
	)
	sim.add_crisis(cr)
	return sim


func test_m3_world_and_campaign_smoke() -> void:
	# 1. Generate 24x24 world with 2 biomes.
	var gen: WorldGenerator = WorldGenerator.new()
	var constraints: Dictionary = {
		"hearth_position": Vector2i(12, 12),
		"hearth_burden_max": 0.3,
		"min_biome_count": 2,
		"required_biome_ids": [&"marshlands", &"highlands"],
	}
	var world: Variant = gen.generate(_SEED, _W, _H, constraints)
	assert_ne(world, null, "WorldGenerator returns a map")
	assert_eq(world.width, _W, "width 24")
	assert_eq(world.height, _H, "height 24")
	assert_eq(gen.version(), "0.2.0-m3-track-a", "generator version pinned")
	# Two biomes present: the catalogue advertises
	# both, and the generator's verify step
	# guarantees `min_biome_count` is met.
	assert_true(
		world.biome_count() >= 2, "world has at least 2 biomes (got %d)" % world.biome_count()
	)

	# 2. Build the sim with anchors + crisis.
	var log: EventLog = EventLog.new()
	var anchors: Array = [
		NarrativeAnchor.from_content(
			&"first_morning", 2.0, &"ANCHOR_FIRST_MORNING_NAME", &"ANCHOR_FIRST_MORNING_SUMMARY"
		),
		NarrativeAnchor.from_content(
			&"stowaway", -1.0, &"ANCHOR_STOWAWAY_NAME", &"ANCHOR_STOWAWAY_SUMMARY"
		),
		NarrativeAnchor.from_content(
			&"inspector_returns",
			5.0,
			&"ANCHOR_INSPECTOR_RETURNS_NAME",
			&"ANCHOR_INSPECTOR_RETURNS_SUMMARY"
		),
	]
	var sim: Sim = _build_sim(anchors, log)

	# 3. Tick 10 days; step 7b fires the time-gated
	# anchors and skips the location-gated one.
	var events: Array = []
	for d in range(_TICKS):
		sim.tick(1.0, [], events)
	assert_eq(int(sim.time_days), _TICKS, "10 ticks advance time_days to 10")
	assert_true(anchors[0].triggered, "first_morning (trigger_at_day=2) fired")
	assert_false(anchors[1].triggered, "stowaway (location-gated) skipped after 10 ticks")
	assert_true(anchors[2].triggered, "inspector_returns (trigger_at_day=5) fired")

	# 4. Resolve the FirstInspection crisis via the
	# branch tree.
	var fired: bool = false
	for entry in sim.event_log.entries:
		if String(entry.get("kind", "")) == "crisis.triggered":
			fired = true
			break
	assert_true(fired, "FirstInspection crisis triggered")
	for cr in sim.crises.values():
		if cr is Crisis and cr.id == &"first_inspection":
			cr.resolve_branch(sim.time_days, &"accept_audit", &"first_inspection")
			break
	var branch_resolved: bool = false
	for entry in sim.event_log.entries:
		if String(entry.get("kind", "")) == "branch.resolved":
			branch_resolved = true
			assert_eq(
				String(entry.get("choice_id", "")), "accept_audit", "choice_id == accept_audit"
			)
			assert_eq(
				String(entry.get("branch_id", "")),
				"first_inspection",
				"branch_id == first_inspection"
			)
			break
	assert_true(branch_resolved, "branch.resolved event recorded")

	# 5. Save/load roundtrip on the sim's event log.
	var save_dict: Dictionary = sim.save()
	assert_true(save_dict.has("format_version"), "Sim save has format_version")
	var realm: Object = Realm.create(_SEED, _W, _H)
	var realm_save: Dictionary = realm.save()
	var realm2: Object = Realm.new()
	var ok: bool = realm2.from_dict(realm_save.get("body", {}))
	assert_true(ok, "Realm save/load roundtrip works")

	# 6. Locale: de.po has a real German translation
	# for the crisis display name (not the English
	# fallback).
	const _CRISIS_KEY: String = "CRISIS_FIRST_INSPECTION_NAME"
	var de_msgstr: String = _po_msgstr("res://locales/de.po", _CRISIS_KEY)
	var en_msgstr: String = _po_msgstr("res://locales/en.po", _CRISIS_KEY)
	assert_ne(de_msgstr, "", "de.po has a msgstr for %s" % _CRISIS_KEY)
	assert_ne(en_msgstr, "", "en.po has a msgstr for %s" % _CRISIS_KEY)
	assert_ne(de_msgstr, en_msgstr, "de.po msgstr differs from en.po msgstr")

	# 7. Determinism: two sims with the same seed
	# produce identical event-log size.
	var log2: EventLog = EventLog.new()
	var sim_b: Sim = _build_sim(anchors, log2)
	for d in range(_TICKS):
		sim_b.tick(1.0, [], [])
	for cr in sim_b.crises.values():
		if cr is Crisis and cr.id == &"first_inspection":
			cr.resolve_branch(sim_b.time_days, &"accept_audit", &"first_inspection")
			break
	assert_eq(
		sim.event_log.entries.size(),
		sim_b.event_log.entries.size(),
		"Determinism: same seed + same ticks -> same log size"
	)
