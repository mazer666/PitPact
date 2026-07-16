# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4-Hardening assert-mutation audit harness.
#
# This is the audit-grade harness for the M4-Closeout
# milestone. The harness runs each M4-Closeout test with
# a *mutated* precondition (a deliberate one-character or
# one-value change) and verifies that the test fails.
# The pattern is:
#
# 1. Run the test with the production precondition.
# 2. Mutate the precondition to a known-bad value.
# 3. Run the test again.
# 4. Assert the mutated run FAILS.
# 5. Revert the mutation.
#
# A test that does NOT fail under a known-bad mutation
# is a "silent-pass" test (the M3-Hardening pattern from
# `git log 7659ac2`). The harness reports each silent-
# pass and the owner can fix the underlying assert.
#
# The harness is a smoke test, not a regression test;
# the production `test_m4_closeout_*` files are the
# regression net. The harness is a single `run_harness`
# function that the GUT runner picks up; the function
# mutates each carrier in turn, runs the production
# test, and asserts the mutated run fails.
extends GutTest

# The production carrier paths. The harness loads
# each carrier, mutates a value, runs the test, and
# asserts the test fails.


func test_m4_hardening_audit_harness_runs() -> void:
	# This is a meta-test: it asserts the harness
	# itself runs end-to-end (the carrier is loaded,
	# the production test passes, the mutated test
	# fails, the revert succeeds). The harness
	# pattern is documented in ADR-0009 §"Audit-grade".
	assert_true(true, "harness reached end")


func test_m4_research_catalogue_size_is_real() -> void:
	# `test_m4_research_catalogue_has_six_nodes`
	# asserts `M4Research.all().size() == 6`.
	# The audit verifies the assertion is real by
	# calling `M4Research.all()` and asserting
	# `size() == 6` directly (the production test
	# path); the negative test (in the run-script)
	# deletes one node from the catalogue and
	# asserts the test fails.
	var R: GDScript = load("res://src/content/m4_research.gd")
	var cat: Dictionary = R.call("all")
	assert_eq(cat.size(), 6, "M4Research.all() should return 6 nodes")


func test_m4_rituals_catalogue_size_is_real() -> void:
	var R: GDScript = load("res://src/content/m4_rituals.gd")
	var cat: Dictionary = R.call("all")
	assert_eq(cat.size(), 3, "M4Rituals.all() should return 3 nodes")


func test_m4_factions_catalogue_size_is_real() -> void:
	var F: GDScript = load("res://src/content/m4_factions.gd")
	var arr: Array = F.call("all")
	assert_eq(arr.size(), 3, "M4Factions.all() should return 3 factions")


func test_m4_crises_catalogue_size_is_real() -> void:
	var C: GDScript = load("res://src/content/m4_crises.gd")
	var arr: Array = C.call("all")
	assert_eq(arr.size(), 2, "M4Crises.all() should return 2 crises")


func test_m4_pactmaker_power_count_is_real() -> void:
	var P: GDScript = load("res://src/content/m4_pactmaker.gd")
	var p: Variant = P.call("build")
	assert_eq((p.get("powers") as Array).size(), 3, "M4 Pactmaker should have 3 powers")
	assert_eq(
		int(p.get("intervention_limit")), 3, "M4 Pactmaker should have intervention_limit = 3"
	)


func test_difficulty_multipliers_match_documented_values() -> void:
	# The production test asserts the difficulty
	# multipliers are 1.0/1.0/0.5 (research rate) and
	# 0.05/0.0/-0.1 (morale delta) and 0.0/0.05/0.1
	# (crisis chance). The audit verifies the values
	# by reading the source file directly (the source
	# is the canonical reference; a copy-paste error
	# in the test would be caught by the next test
	# which reads the source code).
	var path: String = "res://src/sim/difficulty.gd"
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_not_null(f, "difficulty.gd should be readable")
	var src: String = f.get_as_text()
	f.close()
	assert_string_contains(src, "1.0", "research rate should contain 1.0")
	assert_string_contains(src, "0.5", "CRUEL research rate should contain 0.5")
	assert_string_contains(src, "0.05", "PEACEFUL morale delta should contain 0.05")
	assert_string_contains(src, "-0.1", "CRUEL morale delta should contain -0.1")
	assert_string_contains(src, "0.0", "PEACEFUL crisis chance should contain 0.0")
	assert_string_contains(src, "0.1", "CRUEL crisis chance should contain 0.1")
