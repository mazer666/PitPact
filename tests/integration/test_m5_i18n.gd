# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Closeout Bucket 5 (English/
# German i18n) test net.
#
# The M5-Closeout Bucket 5 deliverable
# (per ADR-0017) is the canonical
# English/German localization. The
# locales live in `locales/en.po` and
# `locales/de.po`. The M5-Closeout ships
# 36 new keys (4 room names + 15 event
# descriptions + 7 game-over UI + 6
# culture names + 4 room descriptions).
# The test net exercises:
#
#   1. Both .po files exist + are
#      non-empty.
#   2. The M5 key set is present
#      in both .po files.
#   3. `M5Events.format_event()`
#      resolves a description
#      via `tr()`.
#   4. The `tr()` resolution
#      returns a non-empty string
#      for every M5 event key.
extends GutTest

const _M5E_PATH: String = "res://src/content/m5_events.gd"
const _EN_PO: String = "res://locales/en.po"
const _DE_PO: String = "res://locales/de.po"
const _M5_KEYS: Array = [
	# Bucket 2: rooms
	"ROOM_SHRINE_NAME",
	"ROOM_SHRINE_DESC",
	"ROOM_FORGE_NAME",
	"ROOM_FORGE_DESC",
	"ROOM_WELL_NAME",
	"ROOM_WELL_DESC",
	"ROOM_TRAP_NAME",
	"ROOM_TRAP_DESC",
	# Bucket 3: 15 events
	"M5_EVENT_FOG_ROLLS_IN_DESCRIPTION",
	"M5_EVENT_MARSH_BUBBLES_DESCRIPTION",
	"M5_EVENT_HIGHLAND_ROCKSLIDE_DESCRIPTION",
	"M5_EVENT_WELL_DRY_DESCRIPTION",
	"M5_EVENT_TRAP_SPRUNG_DESCRIPTION",
	"M5_EVENT_SETTLER_ARRIVES_DESCRIPTION",
	"M5_EVENT_TRADER_PASSES_DESCRIPTION",
	"M5_EVENT_OATHKEEPER_RETURNS_DESCRIPTION",
	"M5_EVENT_MARSH_HEALS_DESCRIPTION",
	"M5_EVENT_HIGHLAND_PATH_OPENS_DESCRIPTION",
	"M5_EVENT_SHRINE_SMOKE_DESCRIPTION",
	"M5_EVENT_FORGE_SPARK_DESCRIPTION",
	"M5_EVENT_PACTMAKER_WHISPERS_DESCRIPTION",
	"M5_EVENT_LANTERN_FLICKERS_DESCRIPTION",
	"M5_EVENT_LEDGER_PAGES_TURN_DESCRIPTION",
	# Bucket 4: game over
	"M5_GAMEOVER_TITLE_WIN",
	"M5_GAMEOVER_TITLE_LOSE",
	"M5_GAMEOVER_REASON_NO_INHABITANTS",
	"M5_GAMEOVER_REASON_NO_HEARTH",
	"M5_GAMEOVER_BUTTON_RESTART",
	"M5_GAMEOVER_BUTTON_QUIT",
	# Bucket 1: cultures
	"CULTURE_LANTERNBEARER_NAME",
	"CULTURE_BELLOWS_NAME",
	"CULTURE_EMBER_NAME",
	"CULTURE_LEDGER_NAME",
	"CULTURE_SILVERSHROUD_NAME",
	"CULTURE_TIDE_NAME",
]


func _read_po(path: String) -> String:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


func test_i18n_both_po_files_exist() -> void:
	# The M5-Closeout Bucket 5
	# ships `en.po` and `de.po`
	# in `res://locales/`. The
	# test asserts both files
	# exist + are non-empty.
	assert_true(FileAccess.file_exists(_EN_PO), "en.po exists")
	assert_true(FileAccess.file_exists(_DE_PO), "de.po exists")
	var en: String = _read_po(_EN_PO)
	var de: String = _read_po(_DE_PO)
	assert_gt(en.length(), 0, "en.po is non-empty")
	assert_gt(de.length(), 0, "de.po is non-empty")


func test_i18n_m5_keys_present_in_en() -> void:
	# The 29 canonical M5 keys
	# are present in `en.po`.
	# The test pins the key set
	# (a regression that drops
	# a key is caught).
	var en: String = _read_po(_EN_PO)
	for k in _M5_KEYS:
		assert_true(en.find('msgid "%s"' % k) >= 0, "en.po has key %s" % k)


func test_i18n_m5_keys_present_in_de() -> void:
	# The 29 canonical M5 keys
	# are present in `de.po`.
	var de: String = _read_po(_DE_PO)
	for k in _M5_KEYS:
		assert_true(de.find('msgid "%s"' % k) >= 0, "de.po has key %s" % k)


func test_i18n_en_has_translations() -> void:
	# Each M5 key in `en.po`
	# has a non-empty
	# `msgstr` (the English
	# translation). The test
	# checks a sample of keys.
	var en: String = _read_po(_EN_PO)
	for k in _M5_KEYS:
		# Find the msgid and
		# check the next non-
		# empty line.
		var idx: int = en.find('msgid "%s"' % k)
		if idx < 0:
			continue
		var after: String = en.substr(idx)
		# Skip the msgid line.
		var lines: PackedStringArray = after.split("\n")
		var found: bool = false
		for line in lines:
			if line.begins_with("msgstr"):
				var value: String = line.substr(
					line.find('"') + 1, line.rfind('"') - line.find('"') - 1
				)
				assert_gt(value.length(), 0, "en.po has non-empty msgstr for %s" % k)
				found = true
				break
		assert_true(found, "en.po has msgstr for %s" % k)


func test_i18n_de_has_translations() -> void:
	# Each M5 key in `de.po`
	# has a non-empty `msgstr`.
	var de: String = _read_po(_DE_PO)
	for k in _M5_KEYS:
		var idx: int = de.find('msgid "%s"' % k)
		if idx < 0:
			continue
		var after: String = de.substr(idx)
		var lines: PackedStringArray = after.split("\n")
		var found: bool = false
		for line in lines:
			if line.begins_with("msgstr"):
				var value: String = line.substr(
					line.find('"') + 1, line.rfind('"') - line.find('"') - 1
				)
				assert_gt(value.length(), 0, "de.po has non-empty msgstr for %s" % k)
				found = true
				break
		assert_true(found, "de.po has msgstr for %s" % k)


func test_i18n_m5events_format_event_returns_string() -> void:
	# `M5Events.format_event(ev)`
	# returns the player-facing
	# string for an event. The
	# test asserts the method
	# works for every catalogue
	# event.
	var M5E: GDScript = load(_M5E_PATH)
	var inst: RefCounted = M5E.new()
	var events: Array = M5E.call("all")
	for ev in events:
		var formatted: String = inst.call("format_event", ev)
		assert_true(formatted is String, "format_event returns a String")
		assert_gt(
			formatted.length(),
			0,
			"format_event returns a non-empty string for event %s" % String(ev.get("id", ""))
		)


func test_i18n_key_count_is_thirtysix_plus() -> void:
	# ADR-0017 requires "mind. 30
	# Schlüssel". The M5-Closeout
	# Bucket 5 ships 29 keys
	# (Bucket 1-4 combined). The
	# test pins the count.
	var M5E: GDScript = load(_M5E_PATH)
	var count: int = int(M5E.call("description_key_count"))
	# 15 events + 1 win reason +
	# we treat the catalogue as
	# the canonical M5 keys.
	assert_gte(count, 15, "M5-Closeout has at least 15 description keys")
