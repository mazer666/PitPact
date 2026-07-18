# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Bucket 1: Co-op
# Protocol.
#
# The M9 closeout ships a
# deterministic, lockstep-based
# protocol for sim-state sync
# between 2+ players. The
# protocol is the canonical
# "what's the state?" entry
# point for co-op; the M9
# closeout's tests verify the
# determinism guarantee
# (identical seeds + inputs =
# identical hashes).
#
# The M9 closeout does NOT ship
# a real ENet adapter (per
# ADR-0021); the adapter is
# the M9.1 closeout's job.
class_name CoopProtocol
extends RefCounted

# FNV-1a 64-bit hash constants.
# The M9 closeout uses the
# canonical FNV-1a constants:
#   - prime = 0x100000001b3
#   - offset = 0xcbf29ce484222325
# See https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
const _FNV_PRIME: int = 1099511628211
const _FNV_OFFSET: int = -3750763034362895579


# `version()` returns the
# canonical M9 version string.
# The M9 closeout pins the
# version per ADR-0021.
static func version() -> String:
	return "0.5.0-m9-coop-foundation"


# `hash_state()` computes a
# deterministic FNV-1a hash of
# a sim state. The state is a
# nested Dictionary; the M9
# closeout hashes it in
# canonical order (sorted
# keys, no RNG, no wall-clock).
# Two identical states always
# produce the same hash.
static func hash_state(state: Dictionary) -> int:
	var h: int = _FNV_OFFSET
	h = _hashed_dict(h, state)
	return h


# `diff_states()` computes the
# operations needed to transform
# `old` into `new`. The M9
# closeout uses a simple
# add/remove/set operation
# model. The M9.1 closeout can
# add `move` for arrays.
static func diff_states(old: Dictionary, new: Dictionary) -> Array:
	var ops: Array = []
	# Find removed keys.
	for key in old.keys():
		if not new.has(key):
			ops.append({"op": "remove", "key": key})
	# Find added or changed keys.
	for key in new.keys():
		if not old.has(key):
			ops.append({"op": "add", "key": key, "value": new[key]})
		elif old[key] != new[key]:
			ops.append({"op": "set", "key": key, "value": new[key]})
	# Canonical order: sort by
	# key.
	ops.sort_custom(_compare_ops)
	return ops


# `apply_diff()` applies a list
# of operations to a state.
# The M9 closeout applies in
# the canonical order (sorted
# by key) to ensure
# determinism. The M9.1
# closeout can add operations
# like `move` for arrays.
static func apply_diff(state: Dictionary, ops: Array) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	for op_dict in ops:
		var op: String = op_dict["op"]
		var key: Variant = op_dict["key"]
		if op == "add" or op == "set":
			result[key] = op_dict["value"]
		elif op == "remove":
			result.erase(key)
	return result


# `_compare_ops()` is a sort
# comparator for ops. The M9
# closeout sorts by key (then
# by op) for canonical order.
static func _compare_ops(a: Dictionary, b: Dictionary) -> bool:
	if a["key"] < b["key"]:
		return true
	if a["key"] > b["key"]:
		return false
	return a["op"] < b["op"]


# `_hashed_dict()` recursively
# hashes a Dictionary in
# canonical (sorted-key) order.
# The M9 closeout handles
# Dictionary, Array, String,
# int, float, bool, Vector2,
# Vector2i. The M9.1 closeout
# can add Vector3, Color, etc.
static func _hashed_dict(h: int, d: Dictionary) -> int:
	var keys: Array = d.keys()
	keys.sort()
	for k in keys:
		# Hash the key.
		h = _hashed_value(h, k)
		# Hash the value.
		h = _hashed_value(h, d[k])
	return h


# `_hashed_value()` dispatches
# on the value type. The M9
# closeout handles the
# canonical sim types.
static func _hashed_value(h: int, v: Variant) -> int:
	if v is Dictionary:
		return _hashed_dict(h, v)
	if v is Array:
		return _hashed_array(h, v)
	if v is String:
		return _hashed_string(h, v)
	if v is int or v is float or v is bool:
		return _hashed_int(h, int(v))
	if v is Vector2:
		return _hashed_int(h, int(v.x) ^ int(v.y))
	if v is Vector2i:
		return _hashed_int(h, v.x ^ v.y)
	# Fallback: hash the type
	# name.
	return _hashed_string(h, str(typeof(v)))


# `_hashed_array()` recursively
# hashes an Array in order.
# The M9 closeout preserves
# order (arrays are ordered
# in sim).
static func _hashed_array(h: int, a: Array) -> int:
	h = _hashed_int(h, a.size())
	for item in a:
		h = _hashed_value(h, item)
	return h


# `_hashed_string()` hashes a
# String. The M9 closeout
# hashes each character.
static func _hashed_string(h: int, s: String) -> int:
	h = _hashed_int(h, s.length())
	for i in s.length():
		h = _hashed_int(h, s.unicode_at(i))
	return h


# `_hashed_int()` applies the
# FNV-1a hash step. The M9
# closeout uses
# `h = h XOR byte; h = h * prime`
# in 64-bit arithmetic.
static func _hashed_int(h_in: int, byte: int) -> int:
	# FNV-1a 64-bit in signed
	# 64-bit GDScript int. The
	# M9 closeout's protocol
	# uses signed wrap-around
	# arithmetic (Godot's int
	# is signed 64-bit). The
	# FNV-1a algorithm is
	# defined modulo 2^64.
	# (Constants: 2^63 = 9223372036854775808,
	# 2^64 = 18446744073709551616)
	var h: int = h_in ^ byte
	h = h * _FNV_PRIME
	# Wrap to signed 64-bit
	# (GDScript int is signed;
	# FNV-1a uses unsigned
	# 64-bit modulo).
	if h > 9223372036854775807:
		h -= 18446744073709551616
	elif h < -9223372036854775808:
		h += 18446744073709551616
	return h
