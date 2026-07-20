# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Side-Quest L:
# Localization Manager.
class_name LocalizationManager
extends RefCounted

const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"
const _SUPPORTED: Array = ["en", "de", "ja"]
const _DEFAULT: String = "en"

var _locale: String = _DEFAULT


static func version() -> String:
	return VERSION_STRING


static func make() -> LocalizationManager:
	var lm: LocalizationManager = LocalizationManager.new()
	lm._locale = _DEFAULT
	return lm


static func supported_locales() -> Array:
	return _SUPPORTED.duplicate()


static func default_locale() -> String:
	return _DEFAULT


static func is_supported(locale: String) -> bool:
	return _SUPPORTED.has(locale)


# The M15 closeout's in-memory
# translations for the 3
# locales. The M15 closeout
# uses simple `get()` lookups;
# the M15.1 closeout can
# integrate the existing
# `locales/*.po` files.
static func _translations_for(locale: String) -> Dictionary:
	if locale == "de":
		return {
			"MENU_START": "Start",
			"MENU_QUIT": "Beenden",
			"MENU_SETTINGS": "Einstellungen",
			"GAME_DAY": "Tag",
			"GAME_WIN": "Sieg",
			"GAME_OVER": "Spiel Vorbei"
		}
	if locale == "ja":
		return {
			"MENU_START": "スタート",
			"MENU_QUIT": "終了",
			"MENU_SETTINGS": "設定",
			"GAME_DAY": "日目",
			"GAME_WIN": "勝利",
			"GAME_OVER": "ゲームオーバー"
		}
	# English (default).
	return {
		"MENU_START": "Start",
		"MENU_QUIT": "Quit",
		"MENU_SETTINGS": "Settings",
		"GAME_DAY": "Day",
		"GAME_WIN": "Victory",
		"GAME_OVER": "Game Over"
	}


func set_locale(locale: String) -> int:
	if not _SUPPORTED.has(locale):
		return -1
	_locale = locale
	return 0


func get_locale() -> String:
	return _locale


func translate(key: StringName) -> String:
	var translations: Dictionary = _translations_for(_locale)
	return translations.get(String(key), String(key))
