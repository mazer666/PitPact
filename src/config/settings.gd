# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 2:
# Settings.
#
# The M15 closeout ships a
# `Settings` carrier. Settings
# are key-value pairs stored
# in memory + persisted to
# disk.
#
# The M15 closeout's tests
# verify the get / set / save /
# load API.
class_name GameSettings
extends RefCounted

# The canonical M15 version.
# The M15 closeout pins the
# version per ADR-0027.
const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"

# The canonical M15 settings
# file (user://settings.json).
# The M15 closeout uses Godot's
# `user://` (per-user data).
const _DEFAULT_PATH: String = "user://settings.json"

# The M15 closeout's default
# values for the 10 built-in
# settings keys.
const _DEFAULTS: Dictionary = {
	"audio.master_volume": 0.8,
	"audio.sfx_volume": 1.0,
	"audio.music_volume": 0.7,
	"display.resolution": Vector2i(1920, 1080),
	"display.fullscreen": false,
	"display.vsync": true,
	"language.locale": "en",
	"gameplay.difficulty": 1,  # 0=easy, 1=normal, 2=hard, 3=insane
	"gameplay.auto_save": true,
	"accessibility.color_blind_mode": 0
}

# `version()` returns the
# canonical M15 version
# string.
# Internal state.
var _values: Dictionary = {}


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# settings carrier with
# defaults.
static func make() -> GameSettings:
	var s: GameSettings = GameSettings.new()
	s._values = _DEFAULTS.duplicate(true)
	return s


# `set()` sets a value. The
# M15 closeout's set is
# type-flexible (any
# `Variant`).
func set_value(key: StringName, value: Variant) -> void:
	_values[key] = value


# `get()` returns a value.
# Returns the default if the
# key is not set.
func get_value(key: StringName) -> Variant:
	return _values.get(key, null)  # GDScript array.get, not Object.get


# `has()` returns whether
# the key is set.
func has(key: StringName) -> bool:
	return _values.has(key)


# `unset()` removes a key.
func unset(key: StringName) -> void:
	_values.erase(key)


# `keys()` returns the list
# of set keys.
func keys() -> Array:
	return _values.keys()


# `defaults()` returns the
# default values.
static func defaults() -> Dictionary:
	return _DEFAULTS.duplicate(true)


# `save()` writes the
# settings to disk (JSON
# format).
func save() -> int:
	var f: FileAccess = FileAccess.open(_DEFAULT_PATH, FileAccess.WRITE)
	if f == null:
		return -1
	f.store_string(JSON.stringify(_values))
	f.close()
	return 0


# `load_from_disk()` reads
# the settings from disk.
# Returns 0 on success, -1
# on miss.
func load_from_disk() -> int:
	if not FileAccess.file_exists(_DEFAULT_PATH):
		return -1
	var f: FileAccess = FileAccess.open(_DEFAULT_PATH, FileAccess.READ)
	if f == null:
		return -1
	var content: String = f.get_as_text()
	f.close()
	var json: JSON = JSON.new()
	var err: int = json.parse(content)
	if err != OK:
		return -1
	if not json.data is Dictionary:
		return -1
	_values = json.data
	return 0


# `reset_to_defaults()` resets
# all values to defaults.
func reset_to_defaults() -> void:
	_values = _DEFAULTS.duplicate(true)
