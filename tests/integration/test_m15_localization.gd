# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Side-Quest L
# (Localization Manager) test
# net.
extends GutTest

const _LM_PATH: String = "res://src/i18n/localization_manager.gd"


func test_m15_localization_version() -> void:
	var LM: GDScript = load(_LM_PATH)
	var v: String = LM.call("version")
	assert_eq(v, "0.11.0-m15-final-polish-coop", "version() returns the M15 closeout version")


func test_m15_localization_default_locale() -> void:
	# The default locale is "en".
	var LM: GDScript = load(_LM_PATH)
	var d: String = LM.call("default_locale")
	assert_eq(d, "en", "default locale='en'")


func test_m15_localization_supported_locales() -> void:
	# 3 supported locales:
	# en, de, ja.
	var LM: GDScript = load(_LM_PATH)
	var list: Array = LM.call("supported_locales")
	assert_eq(list.size(), 3, "3 supported locales")
	assert_true(&"en" in list, "en supported")
	assert_true(&"de" in list, "de supported")
	assert_true(&"ja" in list, "ja supported")


func test_m15_localization_set_get_locale() -> void:
	var LM: GDScript = load(_LM_PATH)
	var lm: Variant = LM.call("make")
	var err: int = lm.set_locale("de")
	assert_eq(err, 0, "set_locale('de') returns 0")
	assert_eq(lm.get_locale(), "de", "get_locale()='de'")


func test_m15_localization_set_locale_invalid() -> void:
	# Setting an unsupported
	# locale returns -1.
	var LM: GDScript = load(_LM_PATH)
	var lm: Variant = LM.call("make")
	var err: int = lm.set_locale("fr")
	assert_eq(err, -1, "set_locale('fr') returns -1")


func test_m15_localization_is_supported() -> void:
	# `is_supported()` checks
	# if a locale is in the
	# supported list.
	var LM: GDScript = load(_LM_PATH)
	assert_true(LM.call("is_supported", "en"), "en is supported")
	assert_true(LM.call("is_supported", "de"), "de is supported")
	assert_true(LM.call("is_supported", "ja"), "ja is supported")
	assert_false(LM.call("is_supported", "fr"), "fr is not supported")


func test_m15_localization_translate_english() -> void:
	# `translate()` returns the
	# translation for the given
	# key in the current locale.
	var LM: GDScript = load(_LM_PATH)
	var lm: Variant = LM.call("make")
	assert_eq(lm.translate(&"MENU_START"), "Start", "English: MENU_START='Start'")


func test_m15_localization_translate_german() -> void:
	# German translations.
	var LM: GDScript = load(_LM_PATH)
	var lm: Variant = LM.call("make")
	lm.set_locale("de")
	assert_eq(lm.translate(&"MENU_QUIT"), "Beenden", "German: MENU_QUIT='Beenden'")
	assert_eq(lm.translate(&"GAME_DAY"), "Tag", "German: GAME_DAY='Tag'")


func test_m15_localization_translate_japanese() -> void:
	# Japanese translations.
	var LM: GDScript = load(_LM_PATH)
	var lm: Variant = LM.call("make")
	lm.set_locale("ja")
	assert_eq(lm.translate(&"MENU_START"), "スタート", "Japanese: MENU_START='スタート'")
	assert_eq(lm.translate(&"GAME_OVER"), "ゲームオーバー", "Japanese: GAME_OVER='ゲームオーバー'")


func test_m15_localization_translate_unknown_key() -> void:
	# Unknown key returns the
	# key as-is.
	var LM: GDScript = load(_LM_PATH)
	var lm: Variant = LM.call("make")
	assert_eq(lm.translate(&"UNKNOWN_KEY"), "UNKNOWN_KEY", "unknown key returns key as-is")
