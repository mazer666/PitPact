# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 1
# (Save Manager) test net.
extends GutTest

const _SM_PATH: String = "res://src/save/save_manager.gd"


func test_m15_save_manager_version() -> void:
	var SM: GDScript = load(_SM_PATH)
	var v: String = SM.call("version")
	assert_eq(v, "0.11.0-m15-final-polish-coop", "version() returns the M15 closeout version")


func test_m15_save_manager_make() -> void:
	var SM: GDScript = load(_SM_PATH)
	var sm: Variant = SM.call("make")
	assert_eq(sm.slot_count(), 0, "0 slots initially")


func test_m15_save_manager_save_load_roundtrip() -> void:
	# Save state to slot 0,
	# load, verify.
	var SM: GDScript = load(_SM_PATH)
	var sm: Variant = SM.call("make")
	var state: Dictionary = {"day": 5, "hearth_count": 3, "inhabitants": ["a", "b"]}
	var err: int = sm.save(0, state)
	assert_eq(err, 0, "save returns 0")
	var loaded: Dictionary = sm.load(0)
	assert_eq(loaded.get("day", 0), 5, "loaded day=5")
	assert_eq(loaded.get("hearth_count", 0), 3, "loaded hearth_count=3")


func test_m15_save_manager_invalid_slot() -> void:
	# Saving to an invalid slot
	# returns -1.
	var SM: GDScript = load(_SM_PATH)
	var sm: Variant = SM.call("make")
	var err: int = sm.save(99, {"x": 1})
	assert_eq(err, -1, "invalid slot returns -1")


func test_m15_save_manager_load_empty_slot() -> void:
	# Loading an empty slot
	# returns an empty dict.
	var SM: GDScript = load(_SM_PATH)
	var sm: Variant = SM.call("make")
	var loaded: Dictionary = sm.load(0)
	assert_eq(loaded.size(), 0, "empty slot returns empty dict")


func test_m15_save_manager_delete() -> void:
	# Delete clears the slot.
	var SM: GDScript = load(_SM_PATH)
	var sm: Variant = SM.call("make")
	sm.save(0, {"x": 1})
	assert_true(sm.has_save(0), "has save after save()")
	sm.delete(0)
	assert_false(sm.has_save(0), "no save after delete()")


func test_m15_save_manager_has_save() -> void:
	var SM: GDScript = load(_SM_PATH)
	var sm: Variant = SM.call("make")
	assert_false(sm.has_save(0), "no save initially")
	sm.save(0, {"x": 1})
	assert_true(sm.has_save(0), "has save after save()")


func test_m15_save_manager_max_slots() -> void:
	# Max slots is 5.
	var SM: GDScript = load(_SM_PATH)
	var n: int = SM.call("max_slots")
	assert_eq(n, 5, "max slots=5")


func test_m15_save_manager_format_version() -> void:
	# The save format version
	# is "1.0.0".
	var SM: GDScript = load(_SM_PATH)
	var v: String = SM.call("save_format_version")
	assert_eq(v, "1.0.0", "format version is 1.0.0")


func test_m15_save_manager_verify_hash() -> void:
	# The hash is verified on
	# load. A valid save has
	# matching hash.
	var SM: GDScript = load(_SM_PATH)
	var sm: Variant = SM.call("make")
	sm.save(0, {"day": 5})
	assert_true(sm.verify_hash(0), "hash is valid after save")


func test_m15_save_manager_multiple_slots() -> void:
	# Save to multiple slots.
	var SM: GDScript = load(_SM_PATH)
	var sm: GDScript = SM
	var inst: Variant = sm.call("make")
	inst.save(0, {"day": 1})
	inst.save(1, {"day": 5})
	inst.save(2, {"day": 10})
	assert_eq(inst.slot_count(), 3, "3 slots used")
	var loaded2: Dictionary = inst.load(2)
	assert_eq(loaded2.get("day", 0), 10, "slot 2 = day 10")


func test_m15_save_manager_auto_save_interval() -> void:
	# Auto-save interval is 10
	# ticks.
	var SM: GDScript = load(_SM_PATH)
	var n: int = SM.call("auto_save_interval")
	assert_eq(n, 10, "auto-save interval=10 ticks")


func test_m15_save_manager_tick_auto_save() -> void:
	# `tick_auto_save()` returns
	# true every 10 ticks.
	var SM: GDScript = load(_SM_PATH)
	var inst: Variant = SM.call("make")
	var triggered: bool = false
	for i in 9:
		triggered = inst.tick_auto_save({"day": i})
	assert_false(triggered, "no auto-save in first 9 ticks")
	triggered = inst.tick_auto_save({"day": 9})
	assert_true(triggered, "auto-save triggers on tick 10")
	assert_true(inst.has_save(0), "auto-save wrote to slot 0")
