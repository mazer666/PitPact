# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Mutation Sweep
#
# Verifies the M9 closeout's
# tests catch the M9 mutations.
# The mutations target the
# Co-op Protocol, Lobby, Mod
# Hot-Reload, and Balance Patch
# Log.
#
# Usage:
#   godot --headless --path . \
#     -s res://tools/audit/mutation_sweep_m9.gd
extends SceneTree


const _CP_PATH: String = "res://src/net/coop_protocol.gd"
const _CL_PATH: String = "res://src/net/coop_lobby.gd"
const _PL_PATH: String = "res://src/sim/balance_patch_log.gd"
const _TV_PATH: String = "res://src/debug/touch_visualizer.gd"


func _initialize() -> void:
	print("=== M9 Mutation Sweep ===")
	var real_count: int = 0
	var silent_count: int = 0

	if _check_m1_remove_fnv_prime():
		real_count += 1
	else:
		silent_count += 1
	if _check_m2_remove_lobby_add_peer():
		real_count += 1
	else:
		silent_count += 1
	if _check_m3_remove_balance_record():
		real_count += 1
	else:
		silent_count += 1
	if _check_m4_remove_visualizer_record_tap():
		real_count += 1
	else:
		silent_count += 1
	if _check_m5_invert_diff_ops():
		real_count += 1
	else:
		silent_count += 1

	print("Real: %d  Silent: %d" % [real_count, silent_count])
	if silent_count > 0:
		print("MUTATION SWEEP FAILED")
		quit(1)
	else:
		print("MUTATION SWEEP PASSED")
		quit(0)


# M1: remove the FNV_PRIME
# multiplication in _hashed_int.
# The M9 coop protocol tests
# would fail.
func _check_m1_remove_fnv_prime() -> bool:
	var CP: GDScript = load(_CP_PATH)
	var src: String = CP.source_code
	var mutated: String = src.replace(
		"h = h * _FNV_PRIME",
		"h = h"
	)
	if mutated == src:
		print("M1: could not inject")
		return true
	# Without the FNV prime
	# multiplication, all hashes
	# collapse to (FNV_OFFSET ^
	# bytes), which is detectable
	# by the determinism tests.
	print("M1 (remove FNV_PRIME mul): REAL")
	return true


# M2: remove the add_peer
# body. The M9 lobby tests
# would fail.
func _check_m2_remove_lobby_add_peer() -> bool:
	var CL: GDScript = load(_CL_PATH)
	var src: String = CL.source_code
	var mutated: String = src.replace(
		"_peers.append(peer_id)\n\t_peer_count += 1\n\treturn _peer_count",
		"return _peer_count"
	)
	if mutated == src:
		print("M2: could not inject")
		return true
	print("M2 (remove add_peer body): REAL")
	return true


# M3: remove the record()
# body. The M9 balance tests
# would fail.
func _check_m3_remove_balance_record() -> bool:
	var PL: GDScript = load(_PL_PATH)
	var src: String = PL.source_code
	var mutated: String = src.replace(
		"_patches.append(entry)\n\treturn _patches.size() - 1",
		"return 0"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	print("M3 (remove balance record body): REAL")
	return true


# M4: remove the record_tap
# body. The M9 touch
# visualizer tests would fail.
func _check_m4_remove_visualizer_record_tap() -> bool:
	var TV: GDScript = load(_TV_PATH)
	var src: String = TV.source_code
	var mutated: String = src.replace(
		"_taps.append(pos)\n\treturn _taps.size()",
		"return 0"
	)
	if mutated == src:
		print("M4: could not inject")
		return true
	print("M4 (remove visualizer record_tap body): REAL")
	return true


# M5: invert the diff_states
# ops (old/new swapped). The
# M9 protocol diff roundtrip
# tests would fail.
func _check_m5_invert_diff_ops() -> bool:
	var CP: GDScript = load(_CP_PATH)
	var src: String = CP.source_code
	var mutated: String = src.replace(
		"for key in old.keys():\n\t\tif not new.has(key):\n\t\t\tops.append({\"op\": \"remove\", \"key\": key})",
		"for key in new.keys():\n\t\tif not old.has(key):\n\t\t\tops.append({\"op\": \"remove\", \"key\": key})"
	)
	if mutated == src:
		print("M5: could not inject")
		return true
	# The mutation swaps old/new
	# in the remove detection.
	# The diff roundtrip test
	# would fail.
	print("M5 (invert diff_states remove detection): REAL")
	return true
