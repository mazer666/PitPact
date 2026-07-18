# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M7 Bucket 3 (Mod/Content
# Interface) test net.
extends GutTest

const _M5E_PATH: String = "res://src/content/m5_events.gd"
const _MODS_DIR: String = "res://data/mods/"
const _MOD_TEMPLATE_DIR: String = "res://tools/mod_template/"


func test_mods_example_mod_manifest_exists() -> void:
	# The M7 closeout ships a
	# canonical example mod
	# in `data/mods/example_mod/`.
	var path: String = _MODS_DIR + "example_mod/manifest.json"
	assert_true(FileAccess.file_exists(path), "example_mod/manifest.json exists")


func test_mods_example_mod_events_exists() -> void:
	# The example mod's events.json
	# is canonical JSON with 2
	# event entries.
	var path: String = _MODS_DIR + "example_mod/events.json"
	assert_true(FileAccess.file_exists(path), "example_mod/events.json exists")
	var content: String = FileAccess.get_file_as_string(path)
	assert_true(content.find("example_mod_storm") >= 0, "events.json has example_mod_storm")
	assert_true(content.find("example_mod_visitor") >= 0, "events.json has example_mod_visitor")


func test_mods_template_manifest_exists() -> void:
	# The M7 mod-template ships
	# a manifest template.
	var path: String = _MOD_TEMPLATE_DIR + "manifest.json"
	assert_true(FileAccess.file_exists(path), "mod_template/manifest.json exists")
	var content: String = FileAccess.get_file_as_string(path)
	assert_true(content.find('"id":') >= 0, "manifest template has 'id' field")
	assert_true(content.find('"version":') >= 0, "manifest template has 'version' field")


func test_mods_template_events_exists() -> void:
	# The M7 mod-template ships
	# a sample events.json.
	var path: String = _MOD_TEMPLATE_DIR + "events.json"
	assert_true(FileAccess.file_exists(path), "mod_template/events.json exists")


func test_mods_load_from_mods_returns_two_events() -> void:
	# `M5Events.load_from_mods(dir)`
	# loads the example mod's 2
	# events into the mod catalogue.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.call("reset_for_test")
	var n: int = M5E.call("load_from_mods", _MODS_DIR)
	assert_eq(n, 2, "load_from_mods returned 2 events")


func test_mods_mod_catalogue_has_two_events() -> void:
	# After loading, the mod
	# catalogue has 2 events.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.call("reset_for_test")
	M5E.call("load_from_mods", _MODS_DIR)
	var count: int = M5E.call("mod_event_count")
	assert_eq(count, 2, "mod_event_count = 2")


func test_mods_all_with_mods_returns_17() -> void:
	# `all_with_mods()` returns
	# 15 base + 2 mod = 17 events.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.call("reset_for_test")
	M5E.call("load_from_mods", _MODS_DIR)
	var combined: Array = M5E.call("all_with_mods")
	assert_eq(combined.size(), 17, "all_with_mods = 17 (15 base + 2 mod, pre-M7 expand)")


func test_mods_mod_ids_in_combined() -> void:
	# The combined catalogue
	# includes the mod event IDs.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.call("reset_for_test")
	M5E.call("load_from_mods", _MODS_DIR)
	var combined: Array = M5E.call("all_with_mods")
	var ids: Array = []
	for ev in combined:
		ids.append(String(ev.get("id", "")))
	assert_true(ids.has("example_mod_storm"), "combined has example_mod_storm")
	assert_true(ids.has("example_mod_visitor"), "combined has example_mod_visitor")
	assert_true(ids.has("fog_rolls_in"), "combined still has base fog_rolls_in")
