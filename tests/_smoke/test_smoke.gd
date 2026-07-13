# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — first passing GUT smoke test.
#
# This test exists to prove the GUT 9 harness is wired up
# correctly. It does two things:
#
#   1. The trivial `assert_eq(2 + 2, 4)` is the canonical
#      "is the test runner actually running tests?" check.
#   2. A real assertion on `SplitMix64` from `src/core/rng.gd`
#      proves that the vendored GUT 9 addon can resolve
#      `res://src/core/rng.gd` and that the determinism
#      contract of `SplitMix64` (same seed → same sequence)
#      holds.
#
# If this test ever stops running, the most likely cause is a
# missing `addons/gut` symlink; the symlink is created on
# demand by `tests/_smoke/test_runner.gd` (and by the local
# quality suite). See docs/adrs/0002-module-boundaries.md
# and licenses/THIRD-PARTY.md for the GUT provenance.
extends GutTest

const _SPLITMIX64_PATH := "res://src/core/rng.gd"
# Reference outputs for the first 5 calls of
# `next_u64()` on a SplitMix64 seeded with
# `0xDEADBEEF_CAFEBABE`. Computed against the canonical
# SplitMix64 reference implementation (Steele, Lea & Flood
# 2014); the GDScript implementation must reproduce them
# exactly. If these change, the determinism contract is
# broken.
const _REFERENCE_OUTPUTS: Array = [
	"5A89A098603245B5",
	"4507B9A87C0F3430",
	"E0D5F6261C37465B",
	"FBD6DA83AE9B952C",
	"1A59DC1D46450EED"
]


func test_trivial_assertion() -> void:
	# Canonical "is the test runner actually running tests?"
	# assertion. If this fails, the failure is upstream of
	# any real test logic.
	assert_eq(2 + 2, 4, "2 + 2 should equal 4")


func test_splitmix64_loads() -> void:
	# The smoke test is also a load test for the src/core
	# module: if this fails, the dependency wiring (see
	# tools/check_module_dependencies.sh) is broken.
	var SplitMix64Class := load(_SPLITMIX64_PATH)
	assert_not_null(SplitMix64Class, "src/core/rng.gd should load as a class")


func test_splitmix64_matches_reference_output() -> void:
	# Reference-output test: a hard-coded list of expected
	# outputs for a fixed seed. The list is the
	# canonical SplitMix64 output, and a divergence is a
	# regression in the algorithm.
	#
	# Note on seed construction: GDScript's `int` is 64-bit
	# SIGNED, so the literal `0xDEADBEEF_CAFEBABE` overflows
	# and is silently truncated to 0x7FFFFFFFFFFFFFFF. We
	# build the 64-bit seed from two 32-bit halves; the
	# result is a negative `int` (because the high bit of
	# 0xDEADBEEF is set), which `_int_to_bytes` accepts.
	var SplitMix64Class := load(_SPLITMIX64_PATH)
	var seed: int = (0xDEADBEEF << 32) | 0xCAFEBABE
	var rng: Object = SplitMix64Class.new(seed)
	for i in range(_REFERENCE_OUTPUTS.size()):
		var got: String = _u64_to_hex(rng.next_u64())
		assert_eq(got, _REFERENCE_OUTPUTS[i], "SplitMix64 output #%d diverged" % i)


func test_splitmix64_determinism() -> void:
	# Determinism contract: two SplitMix64 instances
	# constructed with the same seed MUST produce the same
	# sequence of next_u64() outputs. This is the
	# load-bearing property that ADR-0002's "game-domain
	# modules are deterministic" rule depends on.
	var SplitMix64Class := load(_SPLITMIX64_PATH)
	var seed: int = (0xDEADBEEF << 32) | 0xCAFEBABE
	var rng_a: Object = SplitMix64Class.new(seed)
	var rng_b: Object = SplitMix64Class.new(seed)

	# Assert 32 consecutive outputs are equal. 32 is small
	# enough to keep the test fast and large enough to
	# catch any state-management regression.
	for i in range(32):
		var ua: int = rng_a.next_u64()
		var ub: int = rng_b.next_u64()
		assert_eq(ua, ub, "SplitMix64 outputs diverged at step %d" % i)


func test_splitmix64_different_seeds_diverge() -> void:
	# The complement to the determinism test: two different
	# seeds must produce different sequences. A bug here
	# would mean the seed is being silently ignored.
	var SplitMix64Class := load(_SPLITMIX64_PATH)
	var rng_a: Object = SplitMix64Class.new(0x0000000000000001)
	var rng_b: Object = SplitMix64Class.new(0x0000000000000002)

	# A single output is enough; if the seeds are
	# honoured, the very first output differs.
	assert_ne(
		rng_a.next_u64(), rng_b.next_u64(), "Different seeds should produce different first outputs"
	)


func test_splitmix64_snapshot_round_trips() -> void:
	# The snapshot API is what the save format stores in
	# `body.world.rng_state` (see ADR-0003). A bug here
	# would corrupt every save.
	var SplitMix64Class := load(_SPLITMIX64_PATH)
	var seed: int = (0x12345678 << 32) | 0x9ABCDEF0
	var rng: Object = SplitMix64Class.new(seed)

	# Discard the first 7 outputs so the state is non-trivial.
	for _i in range(7):
		rng.next_u64()

	var snap: PackedByteArray = rng.snapshot()
	var expected: int = rng.next_u64()

	# Reset and replay: the post-snapshot state should
	# produce the same next value.
	var restored: Object = SplitMix64Class.new(0x0000000000000000)
	restored.restore(snap)
	assert_eq(
		restored.next_u64(), expected, "Snapshot round-trip should reproduce the same next value"
	)


# --- helpers ---------------------------------------------------------


# Format a GDScript int that represents an unsigned 64-bit value
# as a 16-character uppercase hex string. GDScript's `int` is
# 64-bit signed, so values with the high bit set are negative.
# We extract the bytes directly (GDScript's `%X` format does not
# handle signed-int-as-unsigned correctly) and convert each byte
# to two hex digits.
static func _u64_to_hex(v: int) -> String:
	var s: String = ""
	for i in range(15, -1, -1):
		# Extract the i-th hex digit (4 bits) from the int.
		# GDScript's `>>` on a negative int is an arithmetic
		# shift (sign-extending); we mask with 0xF to take
		# only the low 4 bits of the shifted value, which
		# gives the unsigned 4-bit pattern for any v.
		var nibble: int = (v >> (i * 4)) & 0xF
		s += "%X" % nibble
	return s


static func _pad16(s: String) -> String:
	while s.length() < 16:
		s = "0" + s
	return s
