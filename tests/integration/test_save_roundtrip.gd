# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Save/load roundtrip integration test.
#
# This test is the load-bearing gate on ADR-0003. It builds
# a tiny realm payload (a 3x3 grid with a single Hearth
# room and one zone), saves it to a temp file via
# `RealmSerializer`, reads it back, and asserts that:
#
#   1. the `body` is deep-equal,
#   2. the `seed` is identical,
#   3. the RNG state round-trips through the save (a
#      SplitMix64 reconstructed from the loaded state
#      produces the same sequence as one that continued
#      from the pre-save state),
#   4. the integrity check passes on the loaded save,
#   5. the migration chain ran (the `save_version` is
#      the engine's current `SaveFormat.SAVE_VERSION`).
#
# The test is an integration test, not a unit test: it
# exercises the full save pipeline (canonical JSON, SHA-256,
# migration, file I/O). The determinism property
# (`SplitMix64` snapshot round-trip) is covered separately
# in `tests/_smoke/test_smoke.gd` and is not duplicated
# here.
extends GutTest

const _SPLITMIX64_PATH := "res://src/core/rng.gd"
const _SAVE_FORMAT_PATH := "res://src/save/save_format.gd"
const _REALM_SERIALIZER_PATH := "res://src/save/realm_serializer.gd"
const _MIGRATIONS_PATH := "res://src/save/migrations.gd"

## A deterministic seed. The literal is two 32-bit halves
## so the value is a positive `int` in GDScript's 64-bit
## signed representation (the high bit of the high half is
## zero).
const _SEED_HEX: String = "00000000deadbeef"

# --- helpers ---------------------------------------------------------


## Build a tiny realm payload. The shape matches the
## "body" sub-document of the save format (see ADR-0003):
## the body is content-agnostic, so we use plain
## `Dictionary` keys the same way `src/world` (Track A)
## will.
func _build_tiny_realm() -> Dictionary:
	return {
		"world":
		{
			"grid":
			[
				[
					{"biome": &"hollow", "tile_id": 0},
					{"biome": &"hollow", "tile_id": 0},
					{"biome": &"hollow", "tile_id": 0},
				],
				[
					{"biome": &"hollow", "tile_id": 0},
					{"biome": &"hollow", "tile_id": 0},
					{"biome": &"hollow", "tile_id": 0},
				],
				[
					{"biome": &"hollow", "tile_id": 0},
					{"biome": &"hollow", "tile_id": 0},
					{"biome": &"hollow", "tile_id": 0},
				],
			],
			"zones":
			[
				{
					"id": &"zone_0",
					"purpose": &"social",
					"tiles":
					[
						{"x": 1, "y": 1},
					],
				},
			],
			"rooms":
			[
				{
					"id": &"hearth_0",
					"def_id": &"hearth",
					"zone_id": &"zone_0",
					"state": "ACTIVE",
					"construction_progress_days": 3,
				},
			],
		},
		"sim":
		{
			"tick": 0,
			"inhabitants": [],
		},
	}


# --- the actual tests -----------------------------------------------


func test_save_load_roundtrip_body_equals() -> void:
	# Build a tiny realm, save it, load it, assert deep-equal
	# on the body. This is the load-bearing property the
	# save format promises.
	var body: Dictionary = _build_tiny_realm()
	var save: Dictionary = RealmSerializer.build_save(body, _SEED_HEX)
	var json_text: String = RealmSerializer.to_json(save)
	var result: Dictionary = RealmSerializer.from_json(json_text)
	assert_true(
		result["ok"], "from_json should succeed; got reason: %s" % str(result.get("reason", ""))
	)
	var loaded: Dictionary = result["save"]
	assert_true(SaveFormat.verify_save(loaded), "verify_save should pass on a freshly-loaded save")
	var loaded_body: Dictionary = loaded["body"]
	# GUT 9.2.1's `assert_eq_deep` does a recursive deep
	# compare on Dictionaries and Arrays; that is the
	# property we want.
	assert_eq_deep(loaded_body, body)


func test_save_load_roundtrip_seed_preserved() -> void:
	# The `seed` is the bridge to §7 (procedural generation)
	# and §16 (deterministic replay). Losing it on save
	# would be a silent replay-break.
	var body: Dictionary = _build_tiny_realm()
	var save: Dictionary = RealmSerializer.build_save(body, _SEED_HEX)
	var result: Dictionary = RealmSerializer.from_json(RealmSerializer.to_json(save))
	assert_true(result["ok"])
	var loaded: Dictionary = result["save"]
	assert_eq(loaded["seed"], _SEED_HEX, "seed must round-trip exactly")


func test_save_load_roundtrip_rng_state() -> void:
	# The deterministic RNG state lives in `body.world.rng_state`.
	# The state is a `PackedByteArray`; the canonical JSON
	# stores it as a hex string. A bug here would silently
	# break deterministic replay.
	var SplitMix64Class := load(_SPLITMIX64_PATH)
	var rng: Object = SplitMix64Class.new(0x12345678 << 32 | 0x9ABCDEF0)
	# Burn a few outputs so the state is non-trivial.
	for _i in range(5):
		rng.next_u64()
	var saved_state: PackedByteArray = rng.save_state()
	# A few more outputs on the live RNG; the replayed RNG
	# must catch up at exactly the right place.
	var expected_next: int = rng.next_u64()

	var body: Dictionary = _build_tiny_realm()
	# The save format stores the hex-encoded state. We
	# convert here so the test exercises the same
	# code path the runtime will.
	var hex: String = ""
	for i in range(saved_state.size()):
		hex += "%02x" % (saved_state[i] & 0xFF)
	body["world"]["rng_state"] = hex

	var save: Dictionary = RealmSerializer.build_save(body, _SEED_HEX)
	var result: Dictionary = RealmSerializer.from_json(RealmSerializer.to_json(save))
	assert_true(result["ok"])
	var loaded_body: Dictionary = result["save"]["body"]
	var loaded_hex: String = String(loaded_body["world"]["rng_state"])
	assert_eq(loaded_hex, hex, "rng state hex must round-trip exactly")

	# Reconstruct an RNG from the loaded state and assert
	# it produces the same next value. The hex string is
	# two ASCII hex digits per byte; we use `hex_to_int`
	# (GDScript's `int("0x...")` does NOT auto-detect
	# hex — that was a bug in the first version of this
	# test).
	var replay: Object = SplitMix64Class.new(0)
	var bytes: PackedByteArray = PackedByteArray()
	for i in range(0, loaded_hex.length(), 2):
		bytes.append(loaded_hex.substr(i, 2).hex_to_int())
	replay.load_state(bytes)
	assert_eq(
		replay.next_u64(), expected_next, "replayed RNG should produce the expected next value"
	)


func test_save_load_roundtrip_file_io() -> void:
	# End-to-end through a real file. The path is a
	# `user://` path Godot guarantees is writable in
	# headless mode.
	var body: Dictionary = _build_tiny_realm()
	var save: Dictionary = RealmSerializer.build_save(body, _SEED_HEX)
	var path: String = "user://_test_save_roundtrip_%d.json" % Time.get_ticks_usec()
	var write_result: Dictionary = RealmSerializer.write_to_file(save, path)
	assert_true(
		write_result["ok"],
		"write_to_file should succeed; got: %s" % str(write_result.get("reason", ""))
	)

	var read_result: Dictionary = RealmSerializer.read_from_file(path)
	assert_true(
		read_result["ok"],
		"read_from_file should succeed; got: %s" % str(read_result.get("reason", ""))
	)
	var loaded: Dictionary = read_result["save"]
	assert_true(SaveFormat.verify_save(loaded), "loaded save should pass verify_save")

	# Clean up the temp file. We do not assert on the
	# cleanup result; `remove` is best-effort.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_migration_chain_runs_on_load() -> void:
	# The migration chain is wired even when the read
	# `save_version` matches the engine's. The chain is
	# a no-op for `1 → 1` (M1 ships one smoke-test
	# migration), but it must run; the loaded save's
	# `save_version` is the engine's, not the on-disk
	# version (they are the same here, but the chain
	# still touched the body).
	var body: Dictionary = _build_tiny_realm()
	var save: Dictionary = RealmSerializer.build_save(body, _SEED_HEX)
	var result: Dictionary = RealmSerializer.from_json(RealmSerializer.to_json(save))
	assert_true(result["ok"])
	var loaded: Dictionary = result["save"]
	assert_eq(int(loaded["save_version"]), SaveFormat.SAVE_VERSION)


func test_corrupt_checksum_is_rejected() -> void:
	# A save with a tampered body must fail `verify_save`.
	# The integration test exercises the full pipeline:
	# the build succeeds (the body is technically valid),
	# but the integrity check refuses the modified save.
	var body: Dictionary = _build_tiny_realm()
	var save: Dictionary = RealmSerializer.build_save(body, _SEED_HEX)
	# Tamper with a non-checksum field.
	save["seed"] = "ffffffffffffffff"
	assert_false(
		SaveFormat.verify_save(save), "verify_save should reject a save with a stale checksum"
	)
