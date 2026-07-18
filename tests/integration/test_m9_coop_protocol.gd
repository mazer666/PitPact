# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Bucket 1 (Co-op
# Protocol) test net.
extends GutTest

const _CP_PATH: String = "res://src/net/coop_protocol.gd"


func test_m9_coop_protocol_version() -> void:
	# The M9 closeout's `version()`
	# returns the canonical M9
	# version string per ADR-0021.
	var CP: GDScript = load(_CP_PATH)
	var v: String = CP.call("version")
	assert_eq(v, "0.5.0-m9-coop-foundation", "version() returns the M9 closeout version")


func test_m9_coop_protocol_hash_state_deterministic() -> void:
	# The M9 closeout's `hash_state()`
	# is deterministic: two calls
	# with the same state produce
	# the same hash.
	var CP: GDScript = load(_CP_PATH)
	var state: Dictionary = {"day": 1, "hearth_count": 2, "inhabitants": ["a", "b"]}
	var h1: int = CP.call("hash_state", state)
	var h2: int = CP.call("hash_state", state)
	assert_eq(h1, h2, "hash_state is deterministic (same state -> same hash)")


func test_m9_coop_protocol_hash_state_different_for_different_states() -> void:
	# Two different states produce
	# different hashes.
	var CP: GDScript = load(_CP_PATH)
	var state_a: Dictionary = {"day": 1, "hearth_count": 2}
	var state_b: Dictionary = {"day": 2, "hearth_count": 2}
	var h_a: int = CP.call("hash_state", state_a)
	var h_b: int = CP.call("hash_state", state_b)
	assert_ne(h_a, h_b, "different states produce different hashes")


func test_m9_coop_protocol_hash_key_order_does_not_matter() -> void:
	# The hash is order-
	# independent (sorts keys
	# canonically).
	var CP: GDScript = load(_CP_PATH)
	var state_a: Dictionary = {"a": 1, "b": 2, "c": 3}
	var state_b: Dictionary = {"c": 3, "a": 1, "b": 2}
	var h_a: int = CP.call("hash_state", state_a)
	var h_b: int = CP.call("hash_state", state_b)
	assert_eq(h_a, h_b, "key order does not affect hash (sorted internally)")


func test_m9_coop_protocol_diff_states_no_change() -> void:
	# `diff_states()` returns an
	# empty array for identical
	# states.
	var CP: GDScript = load(_CP_PATH)
	var state: Dictionary = {"a": 1, "b": 2}
	var ops: Array = CP.call("diff_states", state, state)
	assert_eq(ops.size(), 0, "diff_states of identical states returns empty ops")


func test_m9_coop_protocol_diff_states_add() -> void:
	# `diff_states()` detects
	# added keys.
	var CP: GDScript = load(_CP_PATH)
	var old: Dictionary = {"a": 1}
	var new: Dictionary = {"a": 1, "b": 2}
	var ops: Array = CP.call("diff_states", old, new)
	assert_eq(ops.size(), 1, "diff_states detects one added key")
	assert_eq(ops[0]["op"], "add", "op is 'add'")
	assert_eq(ops[0]["key"], "b", "key is 'b'")


func test_m9_coop_protocol_diff_states_remove() -> void:
	# `diff_states()` detects
	# removed keys.
	var CP: GDScript = load(_CP_PATH)
	var old: Dictionary = {"a": 1, "b": 2}
	var new: Dictionary = {"a": 1}
	var ops: Array = CP.call("diff_states", old, new)
	assert_eq(ops.size(), 1, "diff_states detects one removed key")
	assert_eq(ops[0]["op"], "remove", "op is 'remove'")


func test_m9_coop_protocol_diff_states_set() -> void:
	# `diff_states()` detects
	# changed values.
	var CP: GDScript = load(_CP_PATH)
	var old: Dictionary = {"a": 1}
	var new: Dictionary = {"a": 2}
	var ops: Array = CP.call("diff_states", old, new)
	assert_eq(ops.size(), 1, "diff_states detects one changed key")
	assert_eq(ops[0]["op"], "set", "op is 'set'")


func test_m9_coop_protocol_apply_diff_roundtrip() -> void:
	# `apply_diff()` correctly
	# applies a list of operations
	# to produce a target state.
	var CP: GDScript = load(_CP_PATH)
	var old: Dictionary = {"a": 1, "b": 2}
	var new: Dictionary = {"a": 1, "b": 3, "c": 4}
	var ops: Array = CP.call("diff_states", old, new)
	var result: Dictionary = CP.call("apply_diff", old, ops)
	assert_eq(result, new, "apply_diff(old, ops) == new")


func test_m9_coop_protocol_diff_apply_idempotent() -> void:
	# Applying the same diff twice
	# is a no-op (the second
	# application sees no change).
	var CP: GDScript = load(_CP_PATH)
	var old: Dictionary = {"a": 1}
	var new: Dictionary = {"a": 2, "b": 3}
	var ops: Array = CP.call("diff_states", old, new)
	var after_first: Dictionary = CP.call("apply_diff", old, ops)
	var after_second: Dictionary = CP.call("apply_diff", after_first, ops)
	assert_eq(after_first, after_second, "applying diff twice is a no-op")


func test_m9_coop_protocol_determinism_100_ticks() -> void:
	# The M9 closeout's protocol
	# is deterministic for 100
	# ticks: two identical runs
	# produce the same final
	# hash.
	var CP: GDScript = load(_CP_PATH)
	# Simulate 100 ticks: each
	# tick increments `day`.
	var state: Dictionary = {"day": 0, "hearth_count": 1}
	for i in 100:
		state["day"] = i + 1
	var h_run_a: int = CP.call("hash_state", state)
	# Run a second time.
	var state2: Dictionary = {"day": 0, "hearth_count": 1}
	for i in 100:
		state2["day"] = i + 1
	var h_run_b: int = CP.call("hash_state", state2)
	assert_eq(h_run_a, h_run_b, "100-tick runs produce identical hashes")
