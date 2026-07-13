# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Locale validation integration test.
#
# This test wires the GUT suite to the shell-side
# `tools/validate_locale.sh` script. The script is the
# gate; the GUT wrapper is a smoke-test that the script
# runs cleanly and that the artefacts it produces
# (en.po, de.po) are non-empty.
#
# Why a shell-out from GUT?
#   * The validator does its work in pure Python (and
#     optionally in `msgfmt`); the GDScript side is the
#     wrong place to do it.
#   * Running the validator from CI and from `godot
#     --headless` is one command, not two.
#
# The test only runs on platforms where `sh` is
# available. On Windows, the test is skipped (the local
# quality suite catches the locale problem via the
# GDScript-side content registry; see
# `tests/integration/test_locale_validation.gd` and
# `tools/validate_locale.sh`).
extends GutTest

const _SCRIPT_PATH := "res://tools/validate_locale.sh"
const _EN_PO_PATH := "res://locales/en.po"
const _DE_PO_PATH := "res://locales/de.po"


func test_validate_locale_script_exits_zero() -> void:
	# `OS.execute` is the headless-safe way to run a
	# shell command from GDScript. The script is
	# idempotent; re-running it is a no-op.
	var abs_script: String = ProjectSettings.globalize_path(_SCRIPT_PATH)
	assert_true(FileAccess.file_exists(abs_script), "validate_locale.sh must exist on disk")
	var output: Array = []
	var rc: int = OS.execute("sh", [abs_script], output, true, false)
	var combined: String = ""
	for line in output:
		combined += String(line) + "\n"
	assert_eq(rc, 0, "validate_locale.sh should exit 0; got rc=%d, output:\n%s" % [rc, combined])


func test_generated_en_po_is_non_empty() -> void:
	# The validator asserts the file is non-empty as part
	# of its own checks; this test duplicates the
	# assertion at the GUT layer so a missing
	# `locales/en.po` fails the integration suite, not
	# just the shell gate.
	var abs_en: String = ProjectSettings.globalize_path(_EN_PO_PATH)
	assert_true(FileAccess.file_exists(abs_en), "locales/en.po must exist on disk")
	var file: FileAccess = FileAccess.open(abs_en, FileAccess.READ)
	assert_not_null(file, "locales/en.po must be readable")
	var size: int = file.get_length()
	file.close()
	assert_gt(size, 0, "locales/en.po must be non-empty")


func test_generated_de_po_is_non_empty() -> void:
	# The German translation is machine-draft quality at
	# this stage (M5 closes the loop on real
	# translations), but the file MUST be a valid PO
	# file with at least the header block. A zero-byte
	# `de.po` is a clear regression.
	var abs_de: String = ProjectSettings.globalize_path(_DE_PO_PATH)
	assert_true(FileAccess.file_exists(abs_de), "locales/de.po must exist on disk")
	var file: FileAccess = FileAccess.open(abs_de, FileAccess.READ)
	assert_not_null(file, "locales/de.po must be readable")
	var size: int = file.get_length()
	file.close()
	assert_gt(size, 0, "locales/de.po must be non-empty")
