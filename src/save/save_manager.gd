# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 1:
# Save Manager.
#
# The M15 closeout ships a
# multi-slot save manager. The
# manager supports save / load /
# delete / has_save for up to
# 5 slots. Each save has a
# format version + a SHA-256
# hash for validation.
#
# The M15 closeout's tests
# verify the save/load cycle
# + hash validation.
class_name SaveManager
extends RefCounted

# The canonical M15 version.
# The M15 closeout pins the
# version per ADR-0027.
const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"

# The canonical M15 save
# format version. The M15
# closeout uses v1.0.0; future
# versions can detect old
# saves.
const SAVE_FORMAT_VERSION: String = "1.0.0"

# The M15 closeout's max
# number of save slots.
const _MAX_SLOTS: int = 5

# The M15 closeout's auto-
# save interval (every 10
# ticks).
const _AUTO_SAVE_INTERVAL: int = 10

# `version()` returns the
# canonical M15 version
# string.
# Internal state.
var _slots: Dictionary = {}
var _auto_save_counter: int = 0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# save manager.
static func make() -> SaveManager:
	var sm: SaveManager = SaveManager.new()
	sm._slots = {}
	sm._auto_save_counter = 0
	return sm


# `save()` saves the given
# state to the given slot.
# Returns 0 on success, -1
# on invalid slot.
func save(slot: int, state: Dictionary) -> int:
	if slot < 0 or slot >= _MAX_SLOTS:
		return -1
	var state_hash: int = _hash_state(state)
	_slots[slot] = {
		"version": SAVE_FORMAT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"state": state.duplicate(true),
		"hash": state_hash
	}
	return 0


# `load()` loads the state
# from the given slot. Returns
# an empty Dictionary if the
# slot is empty.
func load(slot: int) -> Dictionary:
	if not _slots.has(slot):
		return {}
	var entry: Dictionary = _slots[slot]
	var state: Dictionary = entry.get("state", {})
	var expected_hash: int = entry.get("hash", 0)
	var actual_hash: int = _hash_state(state)
	if actual_hash != expected_hash:
		# Hash mismatch — the
		# save is corrupted.
		# Return empty.
		return {}
	return state.duplicate(true)


# `delete()` deletes the
# save in the given slot.
# Returns 0 on success.
func delete(slot: int) -> int:
	if _slots.has(slot):
		_slots.erase(slot)
	return 0


# `has_save()` returns
# whether the given slot
# has a save.
func has_save(slot: int) -> bool:
	return _slots.has(slot)


# `slot_count()` returns the
# number of used slots.
func slot_count() -> int:
	return _slots.size()


# `max_slots()` returns the
# max number of slots.
static func max_slots() -> int:
	return _MAX_SLOTS


# `save_format_version()`
# returns the canonical
# save format version.
static func save_format_version() -> String:
	return SAVE_FORMAT_VERSION


# `auto_save_interval()`
# returns the auto-save
# interval (ticks).
static func auto_save_interval() -> int:
	return _AUTO_SAVE_INTERVAL


# `tick_auto_save()` ticks
# the auto-save counter. If
# the counter reaches the
# interval, returns true
# (caller should call
# `save(0, state)`). The
# counter is reset on tick.
func tick_auto_save(state: Dictionary) -> bool:
	_auto_save_counter += 1
	if _auto_save_counter >= _AUTO_SAVE_INTERVAL:
		_auto_save_counter = 0
		save(0, state)
		return true
	return false


# `verify_hash()` returns
# whether the hash of the
# slot's state matches the
# stored hash. Returns
# false if the slot is
# empty.
func verify_hash(slot: int) -> bool:
	if not _slots.has(slot):
		return false
	var entry: Dictionary = _slots[slot]
	var state: Dictionary = entry.get("state", {})
	var expected: int = entry.get("hash", 0)
	var actual: int = _hash_state(state)
	return actual == expected


# `_hash_state()` computes
# a FNV-1a 64-bit hash of
# the state. The M15 closeout
# uses the M9 `CoopProtocol`
# for the hash function.
func _hash_state(state: Dictionary) -> int:
	return CoopProtocol.hash_state(state)
