# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Canonical JSON serialiser for the save format.
#
# Per ADR-0003, the save-format integrity check is the
# lowercase-hex SHA-256 of the canonical-JSON form of the save
# with `checksum` removed and with keys sorted lexicographically
# and no insignificant whitespace. The canonical form is the
# mechanical input to the SHA-256; the only place the format
# decision lives is here.
#
# Why a hand-rolled serialiser rather than `JSON.stringify`?
#   * GDScript 4.3's `JSON.stringify(dict, "", 0)` does not
#     sort keys. The canonical form requires sorted keys; a
#     non-sorted serialiser would produce a different checksum
#     on every run for the same logical save, which would make
#     the integrity check useless.
#   * We also want a stable, inspectable form so a player
#     opening the save in a text editor sees the same byte
#     sequence the integrity check sees.
#
# This file is intentionally small and obviously correct. The
# public entry point is `CanonicalJson.stringify(dict)`. The
# rest of the file is the recursive walker.
class_name CanonicalJson
extends RefCounted


## Render `value` as a canonical JSON string. The output:
##   * has no leading or trailing whitespace,
##   * has no insignificant whitespace inside,
##   * sorts object keys lexicographically (byte order, case
##     sensitive — Python `json.dumps(..., sort_keys=True)` is
##     the reference behaviour),
##   * emits arrays in the order they were given,
##   * uses `\uXXXX` escapes for control characters and
##     non-ASCII output, matching `JSON.stringify`'s default.
##
## Accepted input types: `Dictionary`, `Array`, `String`, `int`,
## `float`, `bool`, `PackedByteArray`, and `null` (the GDScript
## null literal). Other types (Object, Vector2, …) are
## converted via `String(value)`, which is lossy and will be
## flagged by the integration test.
##
## The function is pure: no I/O, no global state, deterministic
## output for deterministic input. This is the property the
## checksum depends on.
static func stringify(value: Variant) -> String:
	var sb := PackedStringArray()
	_write(sb, value)
	# PackedStringArray → String is O(n) and exact; the
	# alternative `String(sb)` builds a temporary Array first
	# and is slightly slower. The empty separator is critical:
	# any other separator would corrupt the output.
	var out: String = "".join(sb)
	return out


## Recursive worker. Appends canonical JSON fragments to `sb`.
## Kept module-private (leading underscore) so the public
## surface is exactly `stringify`.
static func _write(sb: PackedStringArray, value: Variant) -> void:
	# We dispatch on the runtime type. `typeof` is the cheap
	# GDScript way to do this; the alternative `value is …`
	# is correct but slower.
	var t: int = typeof(value)
	match t:
		TYPE_DICTIONARY:
			sb.append("{")
			# Build a sorted list of keys. Sorting as
			# `String` is fine because every JSON key is
			# text; the `String(...)` conversion is the
			# canonical comparator.
			var dict: Dictionary = value
			var keys: Array = dict.keys()
			keys.sort()
			var first: bool = true
			for k in keys:
				if not first:
					sb.append(",")
				first = false
				_write_string(sb, String(k))
				sb.append(":")
				_write(sb, dict[k])
			sb.append("}")
		TYPE_ARRAY:
			sb.append("[")
			var arr: Array = value
			for i in range(arr.size()):
				if i > 0:
					sb.append(",")
				_write(sb, arr[i])
			sb.append("]")
		TYPE_STRING:
			_write_string(sb, value)
		TYPE_STRING_NAME:
			# A `StringName` is not a JSON primitive. The
			# serialiser treats it the same as `String`
			# (the underlying text is the value), so a
			# save can contain `&"hearth"` references
			# without losing them on round-trip.
			_write_string(sb, String(value))
		TYPE_BOOL:
			sb.append("true" if value else "false")
		TYPE_INT, TYPE_FLOAT:
			# `String(num)` produces a faithful decimal
			# representation; `int` is decimal, `float`
			# uses the engine's default precision. This
			# is exactly the behaviour of Python
			# `json.dumps` for round-trippable numbers
			# and is what the save format needs.
			sb.append(str(value))
		TYPE_NIL:
			sb.append("null")
		TYPE_PACKED_BYTE_ARRAY:
			# A PackedByteArray is not a JSON primitive.
			# The save format stores the RNG state as a
			# hex-encoded string (e.g.
			# "0a1b2c3d4e5f60718"), which is what
			# `_bytes_to_hex` produces. We accept a
			# `PackedByteArray` here so the caller can
			# pass `rng.save_state()` directly without
			# having to wrap it in a hex call.
			_write_string(sb, _bytes_to_hex(value))
		_:
			# Fall back to `String(value)`. This is
			# lossy; the integration test asserts no
			# unknown types reach the canonical
			# serialiser, but the fallback is here so a
			# bad save fails the integrity check rather
			# than crashing the engine.
			_write_string(sb, str(value))


## Append a JSON-escaped string literal (with the surrounding
## double quotes) to `sb`. The escape table matches the JSON
## spec (RFC 8259 §7): quote, backslash, control characters
## `\b \f \n \r \t`, and any other code point below 0x20. The
## double quote and the backslash are escaped explicitly; all
## other control characters are escaped as `\u00XX`. Non-ASCII
## code points are emitted as-is (the JSON spec allows this;
## Python's `json.dumps(..., ensure_ascii=False)` does the
## same).
static func _write_string(sb: PackedStringArray, s: String) -> void:
	sb.append('"')
	for i in range(s.length()):
		var c: String = s.substr(i, 1)
		var code: int = s.unicode_at(i)
		match c:
			'"':
				sb.append('\\"')
			"\\":
				sb.append("\\\\")
			"\b":
				sb.append("\\b")
			"\f":
				sb.append("\\f")
			"\n":
				sb.append("\\n")
			"\r":
				sb.append("\\r")
			"\t":
				sb.append("\\t")
			_:
				if code < 0x20:
					# Control characters are
					# escaped as \u00XX so the
					# output is valid JSON.
					sb.append("\\u%04X" % code)
				else:
					sb.append(c)
	sb.append('"')


## Lowercase-hex encode a `PackedByteArray`. The output has
## no leading "0x" or separator; the save format treats the
## encoded value as an opaque hex string.
static func _bytes_to_hex(bytes: PackedByteArray) -> String:
	var out := PackedStringArray()
	for i in range(bytes.size()):
		out.append("%02x" % (bytes[i] & 0xFF))
	return "".join(out)
