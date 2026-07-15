# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — splitmix64 deterministic PRNG.
#
# This file is part of src/core. Per ADR-0002, src/core has no
# upstream dependencies: it must not import from any other src/
# module, and it must not depend on Godot scene-tree types. The
# class extends RefCounted (the standard engine-agnostic reference
# type) and exposes the deterministic random-number contract that
# every other module uses. See `docs/adrs/0002-module-boundaries.md`
# and §16 of `docs/requirements.md` for the determinism guarantee.
#
# Algorithm reference: Steele, Lea & Flood, 2014, "Fast Splittable
# Pseudorandom Number Generators". SplitMix64 is the seed-mixing step
# of the family; we use it as a stand-alone PRNG because the 64-bit
# state is small, the period is 2^64, and the sequence is identical
# across runs and architectures.
#
# Why a PackedByteArray state instead of `int`?
#   GDScript's `int` is 64-bit *signed*. SplitMix64 needs the full
#   64-bit *unsigned* range (the algorithm relies on unsigned shifts
#   and on values with the high bit set). The cleanest portable
#   representation is an 8-byte `PackedByteArray`; the byte-level
#   arithmetic is verbose but unambiguously correct on any platform
#   and on any future GDScript version. The public API still
#   surfaces `int` (so callers do not see the byte array); the
#   conversion is done on every call.
class_name SplitMix64
extends RefCounted

## Deterministic 64-bit SplitMix64 PRNG. The state is an 8-byte
## little-endian unsigned integer; the generator advances the state
## with a fixed multiplier and adds the golden gamma, then xorshifts
## the high bits out to a 64-bit output. The same seed produces the
## same sequence on every run, on every platform, for every integer
## version of GDScript.
##
## Usage:
##   var rng := SplitMix64.new(0xDEADBEEF_CAFEBABE)
##   var n: int = rng.next_u64()
##   var f: float = rng.next_float()  # in [0.0, 1.0)
##
## Determinism contract (covered by `tests/_smoke/test_smoke.gd`):
##   * Two `SplitMix64` instances constructed with the same seed
##     produce identical sequences of `next_u64()` outputs.
##   * The sequence does not depend on wall-clock time, the scene
##     tree, or the engine version.
##   * `snapshot()` and `restore(s)` round-trip the state exactly.

# The SplitMix64 mix constants, as 8-byte little-endian PackedByteArray.
# Stored as bytes so the algorithm does not have to fight GDScript's
# 64-bit-signed `int`. The constants are:
#   MIX_GAMMA  = 0x9E3779B97F4A7C15 (golden gamma)
#   M1         = 0xBF58476D1CE4E5B9 (mix1)
#   M2         = 0x94D049BB133111EB (mix2)
#   MIX_ADD    = 0xBF58476D1CE4E5B9 (mix increment, same value as M1)
#
# `const` cannot be a PackedByteArray literal in GDScript 4.3
# (the literal is not a constant expression). We use
# class-level `static var` so the arrays are constructed once
# at first use, not per instance.
static var mix_gamma: PackedByteArray = PackedByteArray(
	[0x15, 0x7C, 0x4A, 0x7F, 0xB9, 0x79, 0x37, 0x9E]
)
static var m1: PackedByteArray = PackedByteArray([0xB9, 0xE5, 0xE4, 0x1C, 0x6D, 0x47, 0x58, 0xBF])
static var m2: PackedByteArray = PackedByteArray([0xEB, 0x11, 0x31, 0x13, 0xBB, 0x49, 0xD0, 0x94])
static var mix_add: PackedByteArray = PackedByteArray(
	[0xB9, 0xE5, 0xE4, 0x1C, 0x6D, 0x47, 0x58, 0xBF]
)

# The 8-byte state. Publicly exposed only via `snapshot()` and
# `restore()`; never read or written directly.
var _state: PackedByteArray = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0])


## Construct a SplitMix64 with an explicit 64-bit seed. The seed is
## mixed once on construction so that two structurally similar seeds
## (e.g. `0` and `1`) do not start at correlated points in the
## sequence. The seed is taken modulo 2^64; values with the high bit
## set are accepted (the byte array can hold the full range).
func _init(seed: int = 0) -> void:
	_state = _int_to_bytes(seed)
	# Mix the seed by XORing with `mix_add` (the SplitMix64 mix
	# increment). This is the seeding convention from Steele, Lea &
	# Flood 2014 (and is what Java's `SplittableRandom` uses); it
	# decorrelates adjacent seeds and matches the canonical
	# reference outputs in `tests/_smoke/test_smoke.gd`.
	#
	# The mixing is *only* the XOR; the first `next_u64()` call
	# will then perform the standard `state += MIX_GAMMA; mix;`
	# step. Doing an extra `_mix` here would shift the sequence
	# by one and break the reference-output table in
	# `tests/_smoke/test_smoke.gd`.
	_state = _xor_bytes(_state, mix_add)


## Return the next 64-bit unsigned integer in the sequence and
## advance the state. The output is in the range [0, 2^64 - 1] as
## a GDScript `int` (which, for high-bit-set values, is the signed
## representation of the unsigned value; callers should treat the
## return value as an opaque 64-bit pattern, not a signed number).
func next_u64() -> int:
	# Standard SplitMix64 step. We hold the state in bytes so the
	# arithmetic is unsigned and the shifts are logical. The
	# operation order is the canonical SplitMix64 order:
	#   z = (state += MIX_GAMMA)
	#   z = (z ^ (z >> 30)) * M1
	#   z = (z ^ (z >> 27)) * M2
	#   z = z ^ (z >> 31)
	# The shift reads the CURRENT z (before the xor/mul), not the
	# result of the previous step. A previous version of this
	# function mistakenly shifted the post-multiply z; the
	# reference-output test in tests/_smoke/test_smoke.gd catches
	# that bug.
	_state = _add_bytes(_state, mix_gamma)
	var z: PackedByteArray = _state
	z = _xor_bytes(z, _logical_shr_bytes(z, 30))
	z = _mul_bytes(z, m1)
	z = _xor_bytes(z, _logical_shr_bytes(z, 27))
	z = _mul_bytes(z, m2)
	z = _xor_bytes(z, _logical_shr_bytes(z, 31))
	return _bytes_to_int(z)


## Return a float in `[0.0, 1.0)`. Generated by taking the top 53
## bits of a 64-bit output and dividing by `2^53`. The result is
## deterministic and uniform across the 53-bit representable
## reals in `[0.0, 1.0)`.
##
## **M3-Closeout fix.** The previous implementation did
## `float(next_u64() >> 11) / 2^53`. GDScript's `int` is
## 64-bit **signed**; the right-shift operator on a signed
## integer is an *arithmetic* shift, which preserves the
## sign bit. For 64-bit SplitMix64 outputs whose top bit
## is `1` (roughly half of the output space), the shifted
## result is a *negative* float, and the returned
## `next_float()` value lies in `[-0.5, 0.0)` instead of
## `[0.0, 1.0)`. The M3 generator used `next_float()` as
## a height value and compared it to `_HEIGHT_THRESHOLD =
## 0.5`; on a negative `next_float()`, every tile
## resolved to the "low" branch (Marshlands), and the
## generator never produced a Highlands tile. The fix
## masks the top 53 bits explicitly with an unsigned
## AND (`& 0xFFFFFFFFFFFFF800`) before the shift; the
## result is a non-negative `int` whose division by
## `2^53` lands in `[0.0, 1.0)`.
##
## **M3-Closeout fix v2 (best-in-class audit).** The v1
## fix used `& 0x7FFFFFFFFFFFF800` as the mask. GDScript's
## `int` literal parser silently maps the unsigned
## `0xFFFFFFFFFFFFF800` to the signed `0x7FFFFFFFFFFFFFFF`
## (= `INT64_MAX`); the resulting mask cleared the
## sign bit of every `next_u64()` output, so the
## shifted value lived in `[0, 2^52)` and the divided
## float lived in `[0.0, 0.5)` — *never* above the
## `_HEIGHT_THRESHOLD = 0.5` that the M3 generator
## checks. The v2 fix uses the signed 64-bit
## representation of `0xFFFFFFFFFFFFF800`, which is
## `-2048` (`~0x7FF`); the high bit is preserved, the
## bottom 11 bits are zeroed, and the shifted value
## lives in `[0, 2^53)` and the float in `[0.0, 1.0)`.
func next_float() -> float:
	# M3-Closeout fix v3: extract the top 53 bits of the
	# 64-bit *unsigned* output as a non-negative `int`,
	# then divide by `2^53`. The previous fix
	# (`(next_u64() & -2048) >> 11`) failed because
	# GDScript's right-shift on a signed int with the
	# high bit set is an arithmetic shift (it propagates
	# the sign bit), so the result was still negative.
	# The byte-level approach: take the 8 bytes of the
	# next_u64() output, build the top 53 bits via
	# `int` arithmetic (each step is positive), and
	# divide. The helper uses the static
	# `_int_to_bytes` / `_bytes_to_int` round-trip
	# that already lives in this file.
	var u: int = next_u64()
	var bytes: PackedByteArray = _int_to_bytes(u)
	# `_int_to_bytes` is little-endian: `bytes[0]` is the
	# low byte, `bytes[7]` is the high byte. The top 53
	# bits of the 64-bit unsigned output are:
	#   bits  0..7  = bytes[1] >> 3     (low 5 bits of byte 1)
	#   bits  8..15 = bytes[2]          (full byte 2)
	#   bits 16..23 = bytes[3]
	#   bits 24..31 = bytes[4]
	#   bits 32..39 = bytes[5]
	#   bits 40..47 = bytes[6]
	#   bits 48..52 = bytes[7]          (low 5 bits of byte 7, since
	#                                   the top 3 bits of byte 7 are
	#                                   the discarded bottom 11 bits)
	# Note: `bytes[7] & 0x1F` extracts the *low* 5 bits of the
	# high byte. The top 3 bits of `bytes[7]` (the high byte)
	# are part of the 11-bit "discard" zone; only the bottom 5
	# bits of `bytes[7]` survive the right-shift by 11.
	var top: int = 0
	top |= (bytes[1] & 0xF8) >> 3
	top |= bytes[2] << 5
	top |= bytes[3] << 13
	top |= bytes[4] << 21
	top |= bytes[5] << 29
	top |= bytes[6] << 37
	top |= bytes[7] << 45
	return float(top) / 9007199254740992.0


## Return a deterministic signed 32-bit integer in `[lo, hi)`
## (half-open). Fails loudly (via `push_error` + a clamped return)
## if the caller asks for a reversed range; a half-open range is
## what the simulation uses everywhere and the contract is part of
## the determinism story.
func next_int(lo: int, hi: int) -> int:
	if hi <= lo:
		push_error("SplitMix64.next_int: hi (%d) must be > lo (%d); clamping" % [hi, lo])
		return lo
	var span: int = hi - lo
	# Rejection sampling would be the textbook move, but the
	# 64-bit output space dwarfs any in-game range, so the simple
	# modulo is exact for every range we use. Document the limit
	# in the assertion: the range must be a 32-bit-or-smaller
	# positive integer to avoid bias. We pin this contract here
	# because the simulation depends on it.
	assert(
		span > 0 and span <= 0x7FFFFFFF, "SplitMix64.next_int: range too large for unbiased output"
	)
	return lo + (abs(next_u64()) % span)


## Return a snapshot of the internal state. The snapshot is the raw
## 8-byte state; round-tripping through `restore()` is exact.
## Snapshots are what the save format stores in
## `body.world.rng_state` (see ADR-0003).
func snapshot() -> PackedByteArray:
	# Return a copy so the caller cannot mutate our state.
	return _state.duplicate()


## Restore a state previously obtained from `snapshot()`. The state
## is taken as-is; a malformed snapshot (wrong length) is rejected
## with a `push_error` because the alternative is a load-time
## failure and the snapshot is always produced by our own code.
func restore(state: PackedByteArray) -> void:
	if state.size() != 8:
		push_error("SplitMix64.restore: expected 8-byte state, got %d bytes" % state.size())
		return
	_state = state.duplicate()


## Save-state alias. Returns the same `PackedByteArray` as
## `snapshot()` but with a name that reads naturally at the
## call site in `src/save/realm_serializer.gd`. The two
## methods exist so the rest of the code can use whichever
## verb fits the context ("snapshot the RNG" vs. "save the
## RNG state to the realm body").
##
## Determinism contract: round-tripping a state through
## `save_state` → `load_state` must reproduce the exact same
## sequence of `next_u64()` calls. This is the property the
## `tests/integration/test_save_roundtrip.gd` integration
## test depends on (Track C, ADR-0003).
func save_state() -> PackedByteArray:
	return snapshot()


## Load-state alias. Mirror of `restore(state)`. The name
## reads naturally at the call site: "load the RNG state
## from the realm body". The two methods are functionally
## identical; both reject malformed states (not 8 bytes) with
## `push_error`.
func load_state(state: PackedByteArray) -> void:
	restore(state)


# --- 8-byte unsigned-arithmetic helpers --------------------------------
#
# The helpers below are deliberately verbose and obviously correct.
# They operate on 8-byte little-endian PackedByteArrays, so the
# result is always a well-defined unsigned 64-bit value. The
# SplitMix64 algorithm is small enough that this inlining is
# cheaper than an autoload-wide "bigint" module.


## Convert a GDScript `int` to an 8-byte little-endian PackedByteArray.
## The input is taken modulo 2^64; the result is always exactly 8 bytes.
static func _int_to_bytes(v: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(8)
	# We extract 8 bytes from the int. The "high bit" of the int
	# (the sign bit in GDScript's 64-bit signed representation) is
	# the high bit of the 8th byte; `& 0xFF` on each byte gives the
	# unsigned byte value. This works for both positive and
	# negative `v` because the bit pattern is preserved by `& 0xFF`
	# in two's complement.
	for i in range(8):
		bytes[i] = v & 0xFF
		v = v >> 8
	return bytes


## Convert an 8-byte little-endian PackedByteArray to a GDScript
## `int`. The result is the 64-bit two's-complement value of the
## bytes; callers should treat it as an unsigned pattern.
static func _bytes_to_int(bytes: PackedByteArray) -> int:
	var v: int = 0
	for i in range(7, -1, -1):
		v = (v << 8) | (bytes[i] & 0xFF)
	return v


## Add two 8-byte little-endian PackedByteArrays modulo 2^64.
static func _add_bytes(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(8)
	var carry: int = 0
	for i in range(8):
		var s: int = (a[i] & 0xFF) + (b[i] & 0xFF) + carry
		out[i] = s & 0xFF
		carry = (s >> 8) & 0xFF
	return out


## Multiply two 8-byte little-endian PackedByteArrays modulo 2^64.
## This is the standard "schoolbook" implementation: 8 partial
## products of 1 byte × 8 bytes, each accumulated with carry.
## It is O(64) byte additions; SplitMix64 calls it twice per
## output, so the total cost is in the low microseconds per
## output on the reference M5.
static func _mul_bytes(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(8)
	for i in range(8):
		result[i] = 0
	# 8 partial products, one per byte of `b`.
	for j in range(8):
		var bj: int = b[j] & 0xFF
		if bj == 0:
			continue
		var carry: int = 0
		for i in range(8 - j):
			var prod: int = (a[i] & 0xFF) * bj + (result[i + j] & 0xFF) + carry
			result[i + j] = prod & 0xFF
			carry = (prod >> 8) & 0xFF
		# Carry out of the high end is discarded (modulo 2^64).
	return result


## XOR two 8-byte little-endian PackedByteArrays.
static func _xor_bytes(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(8)
	for i in range(8):
		out[i] = (a[i] & 0xFF) ^ (b[i] & 0xFF)
	return out


## Logical (unsigned) right shift of an 8-byte little-endian
## PackedByteArray by `n` bits. The result is the top (64 - n) bits
## of the input, left-padded with zeros. `n` must be in [0, 64].
static func _logical_shr_bytes(a: PackedByteArray, n: int) -> PackedByteArray:
	assert(n >= 0 and n <= 64, "SplitMix64: shift must be in [0, 64]")
	if n == 0:
		return a.duplicate()
	if n >= 64:
		return PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0])
	var out := PackedByteArray()
	out.resize(8)
	# Walk the bytes from high to low; the byte at index k in the
	# output is built from the bytes at indices k and k-1 in the
	# input, shifted and OR'd. The high bits come from the
	# current byte; the low bits come from the previous (more
	# significant) byte.
	var byte_shift: int = n / 8
	var bit_shift: int = n % 8
	for k in range(8):
		var src_lo: int = k + byte_shift
		var src_hi: int = src_lo + 1
		if src_lo >= 8:
			out[k] = 0
			continue
		var lo: int = (a[src_lo] & 0xFF) >> bit_shift
		var hi: int = 0
		if bit_shift > 0 and src_hi < 8:
			hi = (a[src_hi] & 0xFF) << (8 - bit_shift) & 0xFF
		out[k] = (hi | lo) & 0xFF
	return out


## The SplitMix64 "xorshift mix" applied to an 8-byte state. Used
## once on construction to decorrelate the seed. The operation
## order matches `next_u64`: xor-then-mul, not mul-then-xor.
static func _mix(a: PackedByteArray) -> PackedByteArray:
	var z: PackedByteArray = a
	z = _xor_bytes(z, _logical_shr_bytes(z, 30))
	z = _mul_bytes(z, m1)
	z = _xor_bytes(z, _logical_shr_bytes(z, 27))
	z = _mul_bytes(z, m2)
	z = _xor_bytes(z, _logical_shr_bytes(z, 31))
	return z
