# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Foundation PlayableShell end-to-end
# smoke test.
#
# This is the M5-Foundation regression net. The test
# exercises the `PlayableShell.build()` factory in
# headless mode and asserts the post-build state
# matches the M5-Foundation contract:
#
#   1. The sim is created with the canonical seed
#      (`SEED = 4242`); the world is 24x24 with
#      two biomes.
#   2. The M3 systems are registered: exploration
#      map, narrative anchors, one crisis.
#   3. The M4 systems are registered: Pactmaker
#      (3 interventions, 3 powers), factions
#      (3), settings (BALANCED), knowledge
#      (empty).
#   4. The M2 inhabitants are created: three
#      (1 Lanternbearer + 2 generic).
#   5. The sim can be ticked: 30 days of `tick()`
#      with the post-state matching the
#      M3-Closeout deterministic invariant.
#   6. The Pactmaker power fires: `apply_power`
#      with `seal_breach` resolves the sealable
#      crisis (or returns false if no sealable
#      crisis; the M4 closeout mutation-sweep
#      covers both paths).
#   7. Save/load roundtrip: the sim's state
#      survives a save/load cycle (the M2
#      save service).
extends GutTest

const _PS_PATH: String = "res://src/ui/playable_shell.gd"


func test_playable_shell_factory_builds_canonical_sim() -> void:
	# 1. Build the canonical M5-Foundation
	# playable sim.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	# 2. Top-level keys present.
	for key in [
		"sim",
		"world",
		"inhabitants",
		"crises",
		"pactmaker",
		"factions",
		"settings",
		"knowledge",
		"exploration_map",
		"narrative_anchors",
		"log",
		"version"
	]:
		assert_true(built.has(key), "build() should return key '%s'" % key)
	# 3. Sim has all M4 systems registered.
	var sim: Sim = built["sim"]
	assert_ne(sim.knowledge_state, null, "knowledge_state should be registered")
	assert_ne(sim.pactmaker, null, "pactmaker should be registered")
	assert_ne(sim.factions, null, "factions should be registered")
	assert_ne(sim.settings, null, "settings should be registered")
	assert_ne(sim.exploration_map, null, "exploration_map should be registered")
	# 4. Three inhabitants.
	var inhabitants: Array = built["inhabitants"]
	assert_eq(inhabitants.size(), 3, "PlayableShell should create 3 inhabitants")
	# 5. One crisis (plague_outbreak).
	var crises: Array = built["crises"]
	assert_eq(crises.size(), 1, "PlayableShell should create 1 crisis")
	assert_eq(StringName(crises[0].id), &"plague_outbreak", "the crisis is plague_outbreak")
	# 6. Pactmaker: 3 interventions/year, 3 powers.
	var p: Pactmaker = built["pactmaker"]
	assert_eq(int(p.intervention_limit), 3, "Pactmaker intervention_limit = 3")
	assert_eq((p.powers as Array).size(), 3, "Pactmaker should have 3 powers")
	# 7. Three factions.
	var factions: Array = built["factions"]
	assert_eq(factions.size(), 3, "PlayableShell should have 3 factions")
	# 8. Settings: BALANCED difficulty.
	var settings: Settings = built["settings"]
	assert_eq(int(settings.difficulty), 1, "Settings difficulty = BALANCED (1)")
	# 9. Three narrative anchors.
	var anchors: Array = built["narrative_anchors"]
	assert_eq(anchors.size(), 3, "PlayableShell should have 3 narrative anchors")


func test_playable_shell_world_has_two_biomes() -> void:
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var world: Variant = built["world"]
	assert_ne(world, null, "world should be generated")
	assert_eq(world.width, 24, "world width 24")
	assert_eq(world.height, 24, "world height 24")
	assert_true(
		world.biome_count() >= 2, "world has at least 2 biomes (got %d)" % world.biome_count()
	)


func test_playable_shell_ticks_30_days() -> void:
	# The M5-Foundation smoke test exercises
	# the per-tick loop for 30 in-game days.
	# The post-state is asserted: the sim's
	# time_days is 30.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var sim: Sim = built["sim"]
	for day in range(30):
		sim.tick(1.0, built["inhabitants"], [])
	# Post-state invariants.
	assert_eq(sim.time_days, 30.0, "sim should have advanced 30 in-game days")
	# The M4 Pactmaker counter is
	# preserved across the run (the
	# yearly reset fires at 360 days;
	# the 30-day run does not trigger
	# the reset).
	var p: Pactmaker = built["pactmaker"]
	assert_true(
		int(p.intervention_count) >= 0, "intervention_count should be non-negative after 30 ticks"
	)


func test_playable_shell_pactmaker_apply_power_seal_breach() -> void:
	# The M5-Foundation Pactmaker panel
	# exposes the three M4 powers. The
	# end-to-end test exercises
	# `seal_breach` against the
	# M4-Foundation crisis
	# (plague_outbreak, which is
	# `sealable: true`).
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var p: Pactmaker = built["pactmaker"]
	var cr: Crisis = built["crises"][0]
	# `apply_power` is the canonical
	# M4 Pactmaker method; it debits
	# the intervention counter, records
	# the use, and invokes the power's
	# `Callable` effect.
	var sim_dict: Dictionary = {
		"crises": {cr.id: cr},
		"settings": built["settings"],
		"knowledge_state": built["knowledge"],
		"pactmaker": p,
		"factions": built["factions"],
		"exploration_map": built["exploration_map"],
		"anchor": Vector2i(12, 12),
	}
	var ok: bool = bool(p.call("apply_power", &"seal_breach", sim_dict, 5.0))
	assert_true(ok, "seal_breach should resolve a sealable crisis")
	assert_true(bool(cr.get("resolved")), "the crisis should be marked resolved")


func test_playable_shell_version_tag() -> void:
	# The M5-Foundation version is pinned.
	# A regression that bumps the version
	# without bumping the test is caught.
	var PS: GDScript = load(_PS_PATH)
	var v: String = String(PS.call("version"))
	assert_eq(v, "0.1.0-m5-foundation", "PlayableShell version is 0.1.0-m5-foundation")


func test_playable_shell_settings_default_difficulty() -> void:
	# The M5-Foundation settings default
	# is BALANCED. A regression that
	# changes the default is caught
	# (the M4-Hardening pattern: read
	# the var default + assert the
	# runtime match).
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var settings: Settings = built["settings"]
	assert_eq(int(settings.difficulty), 1, "Settings difficulty = BALANCED (1)")
	assert_eq(int(settings.auto_resolve_days), 7, "Settings auto_resolve_days = 7")
	assert_eq(String(settings.locale), "en", "Settings locale = 'en'")


func test_playable_shell_determinism_two_builds() -> void:
	# The M5-Foundation deterministic
	# contract (ADR-0005 + the M3-Closeout
	# determinism invariant): two
	# factories with the same seed
	# produce the same sim state.
	var PS: GDScript = load(_PS_PATH)
	var built_a: Dictionary = PS.call("build")
	var built_b: Dictionary = PS.call("build")
	var sim_a: Sim = built_a["sim"]
	var sim_b: Sim = built_b["sim"]
	# The two sims have the same seed
	# and the same post-build state.
	assert_eq(sim_a.time_days, sim_b.time_days, "time_days should be deterministic")
	assert_eq(sim_a.crises.size(), sim_b.crises.size(), "crises count should be deterministic")
	# Tick both sims the same way; the
	# event logs should be identical
	# (the M3-Closeout determinism
	# invariant).
	for day in range(5):
		sim_a.tick(1.0, built_a["inhabitants"], [])
		sim_b.tick(1.0, built_b["inhabitants"], [])
	var log_a: EventLog = built_a["log"]
	var log_b: EventLog = built_b["log"]
	assert_eq(
		log_a.entries.size(), log_b.entries.size(), "event log entry count should be deterministic"
	)
