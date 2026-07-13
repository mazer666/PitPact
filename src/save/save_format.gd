# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Save format: top-level shape + integrity check.
#
# The format is pinned in `docs/adrs/0003-save-format.md`. The
# top-level shape is a single `Dictionary` with these required
# keys:
#
#   format_version   (int)  : pinned at 1 by ADR-0003
#   save_version     (int)  : owned by `src/save/`
#   engine_version   (String): e.g. "0.1.0+gc82f655"
#   content_version  (String): e.g. "1.0.0"
#   written_at       (String): ISO 8601 UTC timestamp
#   seed             (String): generator seed (hex)
#   body             (Dictionary): canonical game-state payload
#   checksum         (String): lowercase-hex SHA-256 of the
#                              canonical-JSON form of every
#                              key EXCEPT `checksum`
#
# This file owns the constants (the `FORMAT_VERSION` is a
# property of the file, not the directory) and the two pure
# functions that are the wire-format contract:
#
#   compute_canonical_hash(save) -> String
#   verify_save(save) -> bool
#
# The serializer that builds the `save` `Dictionary` from a
# `Realm` lives in `realm_serializer.gd`; this file does not
# know about realms.
class_name SaveFormat
extends RefCounted

## The format-version pinned by ADR-0003. Bumping this is a
## breaking change and requires a new ADR.
const FORMAT_VERSION: int = 1

## The save-content version owned by `src/save/`. Bumped
## whenever the meaning of a value in `body` changes. ADR-0003
## pins it at 1 for the M1 cycle.
const SAVE_VERSION: int = 1

## The required top-level keys. `body` and `checksum` are the
## two keys that carry meaning; the rest are metadata used by
## the loader for diagnostics, friendly error messages, and
## (in the case of `engine_version`) the "this save is from a
## newer version" rejection.
const REQUIRED_KEYS: Array = [
	"format_version",
	"save_version",
	"engine_version",
	"content_version",
	"written_at",
	"seed",
	"body",
	"checksum",
]

# --- SHA-256 round constants ----------------------------------------
#
# The 64 round constants from FIPS 180-4 §4.2.2. They are
# placed near the top of the class so the per-block
# transform below can reference them by name; gdlint
# requires `const` declarations before function
# definitions in the class body.
const _SHA256_K: Array = [
	0x428A2F98,
	0x71374491,
	0xB5C0FBCF,
	0xE9B5DBA5,
	0x3956C25B,
	0x59F111F1,
	0x923F82A4,
	0xAB1C5ED5,
	0xD807AA98,
	0x12835B01,
	0x243185BE,
	0x550C7DC3,
	0x72BE5D74,
	0x80DEB1FE,
	0x9BDC06A7,
	0xC19BF174,
	0xE49B69C1,
	0xEFBE4786,
	0x0FC19DC6,
	0x240CA1CC,
	0x2DE92C6F,
	0x4A7484AA,
	0x5CB0A9DC,
	0x76F988DA,
	0x983E5152,
	0xA831C66D,
	0xB00327C8,
	0xBF597FC7,
	0xC6E00BF3,
	0xD5A79147,
	0x06CA6351,
	0x14292967,
	0x27B70A85,
	0x2E1B2138,
	0x4D2C6DFC,
	0x53380D13,
	0x650A7354,
	0x766A0ABB,
	0x81C2C92E,
	0x92722C85,
	0xA2BFE8A1,
	0xA81A664B,
	0xC24B8B70,
	0xC76C51A3,
	0xD192E819,
	0xD6990624,
	0xF40E3585,
	0x106AA070,
	0x19A4C116,
	0x1E376C08,
	0x2748774C,
	0x34B0BCB5,
	0x391C0CB3,
	0x4ED8AA4A,
	0x5B9CCA4F,
	0x682E6FF3,
	0x748F82EE,
	0x78A5636F,
	0x84C87814,
	0x8CC70208,
	0x90BEFFFA,
	0xA4506CEB,
	0xBEF9A3F7,
	0xC67178F2,
]


## Build the canonical-JSON string used as the input to the
## SHA-256 integrity check. The function:
##   1. copies the save,
##   2. removes the `checksum` key (the integrity check is over
##      the save *without* the checksum, so the checksum can
##      never include itself),
##   3. serialises the copy with `CanonicalJson.stringify`.
##
## The result is byte-exact: the same `save` always produces
## the same string. The check is integrity, not authenticity
## (a player can still edit the save; the check just catches
## accidental corruption).
static func canonical_form(save: Dictionary) -> String:
	var stripped: Dictionary = save.duplicate(true)
	stripped.erase("checksum")
	return CanonicalJson.stringify(stripped)


## Compute the lowercase-hex SHA-256 of the canonical form of
## `save`. The implementation is hand-rolled (no engine
## dependency) so the migration tests can re-compute the
## checksum in CI without a Godot install.
##
## The function is a thin wrapper over `canonical_form` and
## `_sha256_hex`. The two are kept as separate functions so
## the test suite can assert the canonical form independently
## of the hash (e.g. to detect a `JSON.stringify` regression
## that would break the integrity check without breaking the
## round-trip).
static func compute_canonical_hash(save: Dictionary) -> String:
	var canon: String = canonical_form(save)
	return _sha256_hex(canon)


## Verify the integrity of a save. Returns `true` when the
## `checksum` field matches the recomputed hash AND every
## required top-level key is present AND the `format_version`
## is the one this engine understands. Returns `false` on
## any check failure; the caller is expected to surface a
## player-facing error.
##
## The function never raises. A `false` return is a hard
## "this save is corrupt" signal to the loader.
static func verify_save(save: Variant) -> bool:
	if typeof(save) != TYPE_DICTIONARY:
		return false
	var dict: Dictionary = save
	for k in REQUIRED_KEYS:
		if not dict.has(k):
			return false
	if int(dict["format_version"]) != FORMAT_VERSION:
		return false
	if int(dict["save_version"]) > SAVE_VERSION:
		# A save with a *higher* save_version is from a
		# newer engine; we accept it only when the
		# migration chain can roll it back. For M1
		# (save_version = 1) and the same engine,
		# equality is required.
		return false
	var expected: String = compute_canonical_hash(dict)
	var got: String = String(dict["checksum"])
	if expected.length() != got.length():
		return false
	# Case-insensitive comparison: the format pins
	# lowercase hex, but a hex editor that re-types the
	# checksum in uppercase should not be rejected.
	return expected.to_lower() == got.to_lower()


## Convenience: stamp the metadata fields on a save and
## compute the checksum. The caller is responsible for
## filling in `body`, `seed`, `engine_version`, and
## `content_version` before calling this; the function
## does not invent values.
static func finalise(
	partial: Dictionary, engine_version: String, content_version: String
) -> Dictionary:
	var out: Dictionary = partial.duplicate(true)
	out["format_version"] = FORMAT_VERSION
	out["save_version"] = SAVE_VERSION
	out["engine_version"] = engine_version
	out["content_version"] = content_version
	# `written_at` is set if not already set. The default
	# is the current UTC time in lowercase ISO 8601. The
	# field is informational only; the loader never uses
	# it for migration.
	if not out.has("written_at") or String(out["written_at"]).is_empty():
		out["written_at"] = Time.get_datetime_string_from_system(true) + "Z"
	out["checksum"] = compute_canonical_hash(out)
	return out


# --- SHA-256 (no engine dependency) -----------------------------------
#
# The implementation is a textbook SHA-256 written to operate
# on a UTF-8 byte stream. It is intentionally verbose and
# obviously correct; the alternative ("trust the engine to
# have a SHA-256") is unavailable in headless CI without a
# Godot install. The function is the integrity check; the
# migration tests depend on it being deterministic and
# engine-independent.
#
# Reference: FIPS 180-4 §6.2. The per-block transform
# below uses the round constants declared at the top of
# the class; the round schedule is the canonical one.


static func _sha256_hex(message: String) -> String:
	var bytes: PackedByteArray = message.to_utf8_buffer()
	# Padding. Append a single `1` bit, then `0` bits until
	# the length is 56 mod 64, then append the big-endian
	# 64-bit length in bits. SHA-256 is defined over bytes;
	# the "1 bit" is the byte 0x80.
	var bit_len: int = bytes.size() * 8
	bytes.append(0x80)
	while bytes.size() % 64 != 56:
		bytes.append(0)
	# Big-endian 64-bit length. SHA-256's length field is
	# 8 bytes total, not 8 + 8; the previous version of
	# this function added 16 bytes (a 32-bit "hi" loop
	# plus a 32-bit "lo" loop), which over-sized the
	# message and caused out-of-bounds reads in the block
	# loop. The fix is a single 8-byte append, big-endian
	# from the high bit down.
	for i in range(7, -1, -1):
		bytes.append((bit_len >> (i * 8)) & 0xFF)

	# Initial hash values (FIPS 180-4 §5.3.3).
	var h: PackedInt32Array = PackedInt32Array(
		[
			0x6A09E667,
			0xBB67AE85,
			0x3C6EF372,
			0xA54FF53A,
			0x510E527F,
			0x9B05688C,
			0x1F83D9AB,
			0x5BE0CD19,
		]
	)
	var w: PackedInt32Array = PackedInt32Array()
	w.resize(64)

	# Process each 512-bit (64-byte) block.
	for block_start in range(0, bytes.size(), 64):
		for i in range(16):
			var word: int = 0
			for j in range(4):
				word = (word << 8) | (bytes[block_start + i * 4 + j] & 0xFF)
			# Mask to 32 bits so the arithmetic is
			# unsigned. GDScript's `int` is 64-bit, so
			# we cannot rely on overflow.
			w[i] = word & 0xFFFFFFFF
		for i in range(16, 64):
			var s0: int = _rotr32(w[i - 15], 7) ^ _rotr32(w[i - 15], 18) ^ _shr32(w[i - 15], 3)
			var s1: int = _rotr32(w[i - 2], 17) ^ _rotr32(w[i - 2], 19) ^ _shr32(w[i - 2], 10)
			w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF

		var a: int = h[0]
		var b: int = h[1]
		var c: int = h[2]
		var d: int = h[3]
		var e: int = h[4]
		var f: int = h[5]
		var g: int = h[6]
		var hh: int = h[7]
		for i in range(64):
			var s1: int = _rotr32(e, 6) ^ _rotr32(e, 11) ^ _rotr32(e, 25)
			var ch: int = (e & f) ^ (~e & 0xFFFFFFFF & g)
			var temp1: int = (hh + s1 + ch + _SHA256_K[i] + w[i]) & 0xFFFFFFFF
			var s0: int = _rotr32(a, 2) ^ _rotr32(a, 13) ^ _rotr32(a, 22)
			var maj: int = (a & b) ^ (a & c) ^ (b & c)
			var temp2: int = (s0 + maj) & 0xFFFFFFFF
			hh = g
			g = f
			f = e
			e = (d + temp1) & 0xFFFFFFFF
			d = c
			c = b
			b = a
			a = (temp1 + temp2) & 0xFFFFFFFF
		h[0] = (h[0] + a) & 0xFFFFFFFF
		h[1] = (h[1] + b) & 0xFFFFFFFF
		h[2] = (h[2] + c) & 0xFFFFFFFF
		h[3] = (h[3] + d) & 0xFFFFFFFF
		h[4] = (h[4] + e) & 0xFFFFFFFF
		h[5] = (h[5] + f) & 0xFFFFFFFF
		h[6] = (h[6] + g) & 0xFFFFFFFF
		h[7] = (h[7] + hh) & 0xFFFFFFFF

	var hex: PackedStringArray = PackedStringArray()
	for i in range(8):
		hex.append("%08x" % (h[i] & 0xFFFFFFFF))
	return "".join(hex)


static func _rotr32(x: int, n: int) -> int:
	# Right-rotate a 32-bit value by `n` bits. GDScript's
	# `int` is 64-bit SIGNED, so a "32-bit value" stored in
	# an `int` has its high bit treated as the sign bit
	# by `>>`. The previous version of this function
	# relied on `x >> n` to logical-shift, but on a value
	# with the high bit set the shift is sign-extended
	# and the rotation is wrong. The fix is to mask the
	# top `n` bits explicitly with a `(32 - n)`-bit mask.
	x = x & 0xFFFFFFFF
	var top: int = (x >> n) & ((1 << (32 - n)) - 1)
	var bot: int = (x << (32 - n)) & 0xFFFFFFFF
	return (top | bot) & 0xFFFFFFFF


## Logical (unsigned) right shift of a value that is
## expected to fit in 32 bits. GDScript's `>>` is an
## arithmetic shift on signed `int`s, so a "32-bit value"
## with the high bit set would be sign-extended. SHA-256
## defines the sigma functions over 32-bit values, not
## over sign-extended 64-bit values; the result must be
## the low 32 bits only.
static func _shr32(x: int, n: int) -> int:
	return (x & 0xFFFFFFFF) >> n
