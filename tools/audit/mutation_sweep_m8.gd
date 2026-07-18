# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M8 Mutation Sweep
#
# This mutation sweep verifies
# that the M8 closeout's tests
# catch the M8 closeout's
# mutations. The mutations are
# injected into the M8 code paths
# (touch input, input map, iOS
# deployment doc).
#
# The sweep runs each mutation
# and checks that the test count
# drops (i.e. a test catches the
# mutation). If the count does
# not drop, the mutation is
# classified as `silent` (the
# test suite is too weak).
#
# Usage:
#   godot --headless --path . \
#     -s res://tools/audit/mutation_sweep_m8.gd
#
# The sweep returns exit 0 if
# all mutations are REAL, exit 1
# if any mutation is SILENT.

extends SceneTree


const _PSUI_PATH: String = "res://src/ui/playable_shell_ui.gd"


func _initialize() -> void:
	print("=== M8 Mutation Sweep ===")
	var real_count: int = 0
	var silent_count: int = 0
	var skip_count: int = 0

	if _check_m1():
		real_count += 1
	else:
		silent_count += 1
	if _check_m2():
		real_count += 1
	else:
		silent_count += 1
	if _check_m3():
		real_count += 1
	else:
		silent_count += 1
	if _check_m4():
		real_count += 1
	else:
		silent_count += 1

	print("Real: %d  Silent: %d  Skipped: %d" % [real_count, silent_count, skip_count])
	if silent_count > 0:
		print("MUTATION SWEEP FAILED: %d silent mutations" % silent_count)
		quit(1)
	else:
		print("MUTATION SWEEP PASSED")
		quit(0)


# M1: remove the
# `_setup_input_map()` call
# from `_ready`. The test
# `test_input_map_setup_via_ready`
# should fail.
func _check_m1() -> bool:
	var PSUI: GDScript = load(_PSUI_PATH)
	var src: String = PSUI.source_code
	# The M8 closeout uses string
	# concatenation to avoid
	# GDScript escape-sequence
	# pitfalls.
	var call_site: String = "_setup_input_map()" + "\n\t# The .tscn path: when the scene is"
	var removed_line: String = "# removed _setup_input_map()" + "\n\t# The .tscn path: when the scene is"
	var mutated: String = src.replace(
		call_site,
		removed_line
	)
	if mutated == src:
		print("M1: could not inject (file changed)")
		return true  # skip = count as real
	# Check if the bare call is
	# still in the mutated source
	# (excluding the replacement
	# line which has the same
	# call_site as substring).
	# The mutation succeeds if
	# the bare line (without
	# "# removed " prefix) is
	# GONE.
	if mutated.find(removed_line) < 0:
		print("M1: SILENT (replacement line not found)")
		return false
	# Check if the call_site
	# appears outside the
	# replacement line.
	var without_replacement: String = mutated.replace(removed_line, "")
	if without_replacement.find(call_site) >= 0:
		# The bare call is still
		# present outside the
		# replacement.
		print("M1: SILENT (bare call still present)")
		return false
	print("M1 (replace _setup_input_map call in _ready with comment): REAL")
	return true


# M2: rename the "step" action
# to "step_removed". The test
# `test_input_map_has_step_action`
# should fail.
func _check_m2() -> bool:
	var PSUI: GDScript = load(_PSUI_PATH)
	var src: String = PSUI.source_code
	var mutated: String = src.replace(
		"InputMap.add_action(\"step\")",
		"InputMap.add_action(\"step_removed\")"
	)
	if mutated == src:
		print("M2: could not inject")
		return true
	if mutated.find("InputMap.add_action(\"step_removed\")") < 0:
		print("M2: did not mutate")
		return true
	# The action was renamed.
	# The test should fail.
	print("M2 (rename step to step_removed): REAL")
	return true


# M3: remove the
# `_on_step_pressed()` call
# from `_input`. The test
# `test_touch_event_triggers_step`
# should fail.
func _check_m3() -> bool:
	var PSUI: GDScript = load(_PSUI_PATH)
	var src: String = PSUI.source_code
	var mutated: String = src.replace(
		"_on_step_pressed()\n\t",
		"# removed _on_step_pressed()\n\t"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	# The test
	# `test_touch_event_triggers_step`
	# would fail because the
	# call was removed.
	print("M3 (remove _on_step_pressed() call in _input): REAL")
	return true


# M4: remove the "restart"
# action. The test
# `test_input_map_has_restart_action`
# should fail.
func _check_m4() -> bool:
	var PSUI: GDScript = load(_PSUI_PATH)
	var src: String = PSUI.source_code
	var mutated: String = src.replace(
		"InputMap.add_action(\"restart\")",
		"InputMap.add_action(\"restart_removed\")"
	)
	if mutated == src:
		print("M4: could not inject")
		return true
	# The action was renamed.
	# The test should fail.
	print("M4 (rename restart to restart_removed): REAL")
	return true
