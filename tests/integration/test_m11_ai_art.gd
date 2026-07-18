# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M11 Bucket 1
# (AI-Art Generation) test net.
extends GutTest

const _MANIFEST: String = "res://tools/assets/ai_asset_manifest.json"


func test_m11_ai_manifest_exists() -> void:
	assert_true(FileAccess.file_exists(_MANIFEST), "AI asset manifest exists")


func test_m11_ai_manifest_has_schema_version() -> void:
	var content: String = FileAccess.get_file_as_string(_MANIFEST)
	assert_true(content.find("schema_version") >= 0, "manifest has schema_version")
	assert_true(content.find("style") >= 0, "manifest has style")


func test_m11_ai_manifest_has_required_assets() -> void:
	# The M11 closeout requires
	# 6 inhabitants, 6 tiles,
	# 4 ui_icons, 2 crises.
	var content: String = FileAccess.get_file_as_string(_MANIFEST)
	var required: Array = [
		"lanternbearer",
		"bellows",
		"ember",
		"ledger",
		"silvershroud",
		"tide",
		"hearth",
		"shrine",
		"forge",
		"well",
		"trap",
		"altar",
		"step",
		"auto_tick",
		"restart",
		"power",
		"faction",
		"plague"
	]
	for id in required:
		assert_true(content.find('"' + id + '"') >= 0, "manifest has asset '%s'" % id)


func test_m11_ai_assets_exist_on_disk() -> void:
	# All 18 AI-generated
	# assets exist on disk.
	var paths: Array = [
		"res://assets/ai/inhabitants/lanternbearer.png",
		"res://assets/ai/inhabitants/bellows.png",
		"res://assets/ai/inhabitants/ember.png",
		"res://assets/ai/inhabitants/ledger.png",
		"res://assets/ai/inhabitants/silvershroud.png",
		"res://assets/ai/inhabitants/tide.png",
		"res://assets/ai/tiles/hearth.png",
		"res://assets/ai/tiles/shrine.png",
		"res://assets/ai/tiles/forge.png",
		"res://assets/ai/tiles/well.png",
		"res://assets/ai/tiles/trap.png",
		"res://assets/ai/tiles/altar.png",
		"res://assets/ai/ui/step.png",
		"res://assets/ai/ui/auto_tick.png",
		"res://assets/ai/ui/restart.png",
		"res://assets/ai/ui/power.png",
		"res://assets/ai/crises/faction.png",
		"res://assets/ai/crises/plague.png"
	]
	for p in paths:
		assert_true(FileAccess.file_exists(p), "asset exists: %s" % p)


func test_m11_ai_manifest_license_is_cc0() -> void:
	# All AI-generated assets
	# are CC0 per ADR-0018
	# (no copyright on AI art).
	var content: String = FileAccess.get_file_as_string(_MANIFEST)
	assert_true(content.find("CC0") >= 0, "manifest declares CC0 license")
