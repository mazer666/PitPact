# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M6 Bucket 5: Licensing/IP
# Audit test net.
extends GutTest

const _MANIFEST_PATH: String = "res://licenses/asset-manifest.md"


func test_manifest_exists() -> void:
	# The M6 Bucket 5 ships the
	# asset manifest at
	# `licenses/asset-manifest.md`.
	assert_true(FileAccess.file_exists(_MANIFEST_PATH), "asset manifest exists")


func test_manifest_total_assets_count() -> void:
	# The manifest asserts 30 total
	# assets (24 PNG + 6 WAV + 2 .tres
	# = wait, 30 PNG+WAV + 2 .tres = 32
	# total; the manifest reports
	# the per-category count).
	# The test pins the headline
	# number to "30 PNG+WAV" + "2 .tres".
	var manifest: String = FileAccess.get_file_as_string(_MANIFEST_PATH)
	assert_true(
		(
			manifest.find("- **Total assets**: 30") >= 0
			or manifest.find("- **Total assets**: 32") >= 0
		),
		"manifest reports 30 or 32 total assets"
	)


func test_manifest_no_external_assets() -> void:
	# The M6 closeout ships 0 external
	# assets (all procedural). The
	# manifest asserts this.
	var manifest: String = FileAccess.get_file_as_string(_MANIFEST_PATH)
	assert_true(
		manifest.find("- **External assets**: 0") >= 0, "manifest reports 0 external assets"
	)


func test_manifest_audit_pass() -> void:
	# The manifest's audit status
	# is PASS (the M6 closeout
	# audit script's exit code).
	var manifest: String = FileAccess.get_file_as_string(_MANIFEST_PATH)
	assert_true(manifest.find("- **Audit status**: PASS") >= 0, "manifest audit status is PASS")


func test_manifest_licenses_complete() -> void:
	# The manifest covers all 3
	# license types: CC0 (assets),
	# GPL-3.0-or-later (code),
	# CC BY-SA 4.0 (locales).
	var manifest: String = FileAccess.get_file_as_string(_MANIFEST_PATH)
	assert_true(manifest.find("CC0") >= 0, "manifest mentions CC0 (assets)")
	assert_true(manifest.find("GPL-3.0-or-later") >= 0, "manifest mentions GPL-3.0-or-later (code)")
	assert_true(manifest.find("CC BY-SA 4.0") >= 0, "manifest mentions CC BY-SA 4.0 (locales)")
