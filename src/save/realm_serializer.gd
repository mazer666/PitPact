# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Realm serializer (save / load facade).
#
# This file is the single entry point gameplay code uses
# to read and write a save. Per ADR-0002, `src/save` is the
# persistence layer; per ADR-0003, the format is a content-
# agnostic JSON object with a SHA-256 integrity check and
# an explicit `engine_version` for migration support.
#
# The serializer is intentionally a thin layer over
# `SaveFormat` and `SaveMigrations`:
#
#   * `SaveFormat`  owns the wire format, the canonical
#                   JSON, the SHA-256, and the `verify_save`
#                   rejection gate.
#   * `SaveMigrations` owns the version chain.
#   * This file   owns the *realm* ↔ `body` translation.
#                  The realm façade (Track A) hands us a
#                  payload `Dictionary`; we hand one back
#                  on load. The translation is content-
#                  agnostic (the only Godot-specific bits
#                  are the RNG state, which is a
#                  `PackedByteArray`, and the room
#                  identifiers, which are `StringName`s).
#
# Why a façade at all?
#   * Game-domain code calls `RealmSerializer.save(...)`,
#     not `ResourceSaver.save(...)` and not
#     `JSON.stringify(...)`. The save format is hidden
#     behind a small surface so the next bump of
#     `format_version` does not ripple through the rest
#     of the tree.
#   * The load path runs the migration chain and verifies
#     the integrity check in one place.
class_name RealmSerializer
extends RefCounted

## The current engine version. The literal is the build
## identifier the running binary was compiled from; it is
## written into every save as `engine_version` so a save
## from a different build is detected and surfaced with a
## friendly message.
const ENGINE_VERSION: String = "0.1.0+m1-content-save"

## The current content-set version. Written into every
## save as `content_version`; the M1 cycle pins it at
## "1.0.0". A content-only patch (no behavioural change)
## bumps this without bumping `save_version`; a behavioural
## patch bumps `save_version` and adds a migration.
const CONTENT_VERSION: String = "1.0.0"


## Build a `save` `Dictionary` from a realm payload. The
## caller fills in `body` (the canonical realm state), the
## seed, and any extra metadata; this function:
##
##   1. stamps the format / save / engine / content
##      versions,
##   2. stamps `written_at` if the caller did not,
##   3. computes the SHA-256 over the canonical form,
##
## and returns the finalised `save` `Dictionary` ready to
## be serialised to disk by the caller.
static func build_save(
	realm_body: Dictionary, seed_hex: String, extra: Dictionary = {}
) -> Dictionary:
	var partial: Dictionary = extra.duplicate(true)
	partial["seed"] = seed_hex
	partial["body"] = realm_body
	return SaveFormat.finalise(partial, ENGINE_VERSION, CONTENT_VERSION)


## Serialise a `save` `Dictionary` to a JSON string. The
## result is the bytes-on-disk form; the writer (the realm
## factory, in Track A) is responsible for writing them
## to a file. Splitting "build the save" from "write the
## bytes" keeps this class testable in headless CI (the
## test asserts the JSON, not the file).
static func to_json(save: Dictionary) -> String:
	return JSON.stringify(save, "", 0)


## Deserialise a JSON string into a `save` `Dictionary`,
## run the migration chain, and verify the integrity
## check. Returns `{ ok: true, save: … }` on success and
## `{ ok: false, reason: "…" }` on any failure. The
## caller is expected to translate the `reason` into a
## player-facing message.
##
## The function is content-agnostic: it does not know
## what a `Realm` is. The realm factory (Track A) takes
## the returned `save["body"]` and re-hydrates it.
static func from_json(json_text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "save is not a JSON object"}
	var save: Dictionary = parsed

	# 1. Required keys + version gate.
	for k in SaveFormat.REQUIRED_KEYS:
		if not save.has(k):
			return {"ok": false, "reason": "save is missing required key '%s'" % k}
	if int(save["format_version"]) != SaveFormat.FORMAT_VERSION:
		return {
			"ok": false,
			"reason":
			(
				"format_version %d is not understood (this engine expects %d)"
				% [int(save["format_version"]), SaveFormat.FORMAT_VERSION]
			),
		}

	# 1a. Coerce int values. JSON has a single number type,
	#     so `JSON.parse_string` returns every number as a
	#     `float`. The body schema uses `int` for counts,
	#     indices, and `Dictionary` sizes; a `deep_equal`
	#     roundtrip fails on `3` vs `3.0`. We walk the
	#     body and convert every whole-number `float`
	#     back to `int`. The coercer is conservative: it
	#     only converts values that are exactly
	#     representable as `int` (no fractional part
	#     within the float's precision).
	var read_save_version: int = int(save["save_version"])
	if read_save_version > SaveFormat.SAVE_VERSION:
		return {
			"ok": false,
			"reason":
			(
				"save_version %d is newer than this engine's %d"
				% [read_save_version, SaveFormat.SAVE_VERSION]
			),
		}

	# 2. Migration chain. The chain is a no-op for
	#    `save_version = 1` (the M1 default); a future
	#    `save_version = 2` adds `migrate_1_to_2` to
	#    `SaveMigrations` and the loader applies it here.
	#
	#    The body goes through `_coerce_int_values` first
	#    so the type structure matches the original body;
	#    a deep_equal roundtrip is then exact, which
	#    `tests/integration/test_save_roundtrip.gd`
	#    asserts.
	var body: Dictionary = _coerce_int_values(save["body"])
	var migrated: Dictionary = SaveMigrations.run(body, read_save_version, SaveFormat.SAVE_VERSION)
	migrated = _coerce_int_values(migrated)
	var rebuilt: Dictionary = save.duplicate(true)
	rebuilt["body"] = migrated
	rebuilt["save_version"] = SaveFormat.SAVE_VERSION

	# 3. Integrity check. A migrated save is, by
	#    definition, no longer byte-identical to the
	#    one that was written; we re-stamp the
	#    checksum here so a *subsequent* integrity
	#    check on the same loaded save passes.
	rebuilt["checksum"] = SaveFormat.compute_canonical_hash(rebuilt)

	return {"ok": true, "save": rebuilt}


## Convenience: write a `save` to a file. The path is a
## `user://` or `res://` path; the engine resolves it. A
## write failure (disk full, permission denied) returns
## `{ ok: false, reason: … }`; success returns
## `{ ok: true, path: … }`.
static func write_to_file(save: Dictionary, path: String) -> Dictionary:
	var json_text: String = to_json(save)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"reason":
			"could not open %s for writing: %s" % [path, error_string(FileAccess.get_open_error())],
		}
	file.store_string(json_text)
	file.close()
	return {"ok": true, "path": path}


## Convenience: read a `save` from a file and run the
## load pipeline (parse → migrate → verify). Returns the
## same shape as `from_json`, plus the path on success.
static func read_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "save file does not exist: %s" % path}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"reason":
			"could not open %s for reading: %s" % [path, error_string(FileAccess.get_open_error())],
		}
	var json_text: String = file.get_as_text()
	file.close()
	return from_json(json_text)


# --- helpers -------------------------------------------------------------


## Walk a `Dictionary` / `Array` tree and convert every
## whole-number `float` back to `int`. The coercer is the
## best-effort answer to JSON's single-number-type problem:
## `JSON.parse_string` returns every number as `float`, but
## the body's schema uses `int` for counts, indices, and
## `Dictionary` sizes. A `deep_equal` roundtrip is then
## exact.
##
## The conversion is conservative: a value is converted to
## `int` only when it is exactly representable as a 64-bit
## signed integer. `3.0` becomes `3`; `3.14` stays a
## `float`; `1e20` stays a `float` (the GDScript `int` is
## 64-bit signed, so values above ~9.2e18 are out of range
## anyway).
static func _coerce_int_values(value: Variant) -> Variant:
	var t: int = typeof(value)
	match t:
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for k in (value as Dictionary).keys():
				out[k] = _coerce_int_values((value as Dictionary)[k])
			return out
		TYPE_ARRAY:
			var arr: Array = value
			var new_arr: Array = []
			for item in arr:
				new_arr.append(_coerce_int_values(item))
			return new_arr
		TYPE_FLOAT:
			var f: float = value
			if f == floor(f) and f >= -9.223372036854776e18 and f <= 9.223372036854776e18:
				return int(f)
			return value
		_:
			return value
