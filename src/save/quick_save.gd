# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M16 Bucket 3: Quick-Save.
# Per ADR-0028, F5 saves the
# current state, F9 loads it.
# Sentinel slot: 99 (out of
# normal 0-4 range).
class_name QuickSave
extends RefCounted

const VERSION_STRING: String = "0.12.0-m16-docs-eol"
const _SENTINEL_SLOT: int = 99

var _state: Dictionary = {}
var _timestamp: int = 0
var _has_save: bool = false


static func version() -> String:
	return VERSION_STRING


static func sentinel_slot() -> int:
	return _SENTINEL_SLOT


static func make() -> QuickSave:
	return QuickSave.new()


func save_state(state: Dictionary) -> int:
	if state == null:
		return -1
	_state = state.duplicate(true)
	_timestamp = Time.get_unix_time_from_system()
	_has_save = true
	return 0


func load_state() -> Dictionary:
	if not _has_save:
		return {}
	return _state.duplicate(true)


func has_quick_save() -> bool:
	return _has_save


func timestamp() -> int:
	return _timestamp


func delete() -> int:
	_state = {}
	_timestamp = 0
	_has_save = false
	return 0


func save_count() -> int:
	# The M16 closeout's Quick-Save
	# stores one slot (sentinel 99).
	# The M16 closeout does not
	# version-bump per save.
	return 1 if _has_save else 0
