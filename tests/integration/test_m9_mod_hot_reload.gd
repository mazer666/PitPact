# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Bucket 3 (Mod
# Hot-Reload) test net.
extends GutTest

const _M5E_PATH: String = "res://src/content/m5_events.gd"
const _MOD_DIR: String = "res://data/mods/example_mod/"
const _MOD_PATH: String = "res://data/mods/example_mod"
const _TMP_MOD_DIR: String = "res://data/mods/test_mod_hot_reload/"


func _cleanup_tmp_mod() -> void:
	# Best-effort cleanup of
	# the temp test mod. The
	# M9 closeout's tests use
	# a separate dir under
	# `data/mods/` to avoid
	# polluting the canonical
	# example mod.
	var dir: DirAccess = DirAccess.open(_TMP_MOD_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir():
			dir.remove(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(_TMP_MOD_DIR)


func _write_tmp_mod(events: Array) -> void:
	_cleanup_tmp_mod()
	DirAccess.make_dir_recursive_absolute(_TMP_MOD_DIR)
	var f: FileAccess = FileAccess.open(_TMP_MOD_DIR + "events.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(events))
	f.close()


func test_m9_hot_reload_mod_replaces_existing_events() -> void:
	# The M9 closeout's
	# `hot_reload_mod()`
	# replaces existing events
	# from the same mod.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.reset_for_test()
	M5E.load_from_mods("res://data/mods/")
	var initial_count: int = M5E.mod_event_count()
	# Now hot-reload the same
	# mod. The event count
	# should be the same (the
	# mod's events.json hasn't
	# changed).
	var after_reload: int = M5E.call("hot_reload_mod", "res://data/mods/example_mod")
	assert_eq(
		after_reload, initial_count, "hot_reload_mod returns same count when events.json unchanged"
	)


func test_m9_hot_reload_mod_reflects_new_events() -> void:
	# Adding an event to the
	# mod's events.json and
	# hot-reloading reflects the
	# new event count.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.reset_for_test()
	M5E.load_from_mods("res://data/mods/")
	var initial_count: int = M5E.mod_event_count()
	# Write a new events.json
	# with 1 event.
	_write_tmp_mod(
		[
			{
				"id": "test_hot_reload_ev",
				"type": "crisis",
				"description": "M5_TEST_HOT_RELOAD_DESC",
				"weight": 5
			}
		]
	)
	var new_count: int = M5E.call("hot_reload_mod", _TMP_MOD_DIR.rstrip("/"))
	assert_eq(new_count, 1, "hot_reload_mod returns 1 for a mod with 1 event")
	_cleanup_tmp_mod()


func test_m9_unload_mod_removes_events() -> void:
	# `unload_mod()` removes all
	# events from the mod.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.reset_for_test()
	M5E.load_from_mods("res://data/mods/")
	# Unload the example_mod.
	var removed: int = M5E.call("unload_mod", "example_mod")
	assert_gt(removed, 0, "unload_mod removes >0 events from the example_mod")
	assert_eq(M5E.mod_event_count(), 0, "mod_event_count is 0 after unload")


func test_m9_unload_nonexistent_mod_is_noop() -> void:
	# Unloading a mod that
	# isn't loaded is a no-op.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.reset_for_test()
	M5E.load_from_mods("res://data/mods/")
	var initial_count: int = M5E.mod_event_count()
	var removed: int = M5E.call("unload_mod", "nonexistent_mod")
	assert_eq(removed, 0, "unloading a non-existent mod returns 0")
	assert_eq(
		M5E.mod_event_count(),
		initial_count,
		"unloading a non-existent mod does not change mod_event_count"
	)


func test_m9_hot_reload_is_idempotent() -> void:
	# Calling `hot_reload_mod()`
	# twice with the same mod
	# produces the same state.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.reset_for_test()
	M5E.load_from_mods("res://data/mods/")
	var first_count: int = M5E.mod_event_count()
	M5E.call("hot_reload_mod", "res://data/mods/example_mod")
	var second_count: int = M5E.mod_event_count()
	assert_eq(first_count, second_count, "hot_reload_mod is idempotent")


func test_m9_hot_reload_mod_source_mod_tag() -> void:
	# Each event from a mod is
	# tagged with `_source_mod`
	# so hot-reload can find it.
	var M5E: GDScript = load(_M5E_PATH)
	M5E.reset_for_test()
	M5E.load_from_mods("res://data/mods/")
	# Find an event from the
	# example_mod and check
	# its `_source_mod` field.
	var all: Array = M5E.all_with_mods()
	var found: bool = false
	for ev in all:
		if ev.get("_source_mod", "") == "example_mod":
			found = true
			break
	assert_true(found, "at least one event has _source_mod='example_mod'")
