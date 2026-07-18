# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Bucket 2 (Particle
# Spawner) test net.
extends GutTest

const _PS_PATH: String = "res://src/effects/particle_spawner.gd"


func test_m13_particle_spawner_version() -> void:
	var PS: GDScript = load(_PS_PATH)
	var v: String = PS.call("version")
	assert_eq(v, "0.9.0-m13-visual-polish", "version() returns the M13 closeout version")


func test_m13_particle_spawner_make() -> void:
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"fire")
	assert_eq(spawner.particle_type(), &"fire", "spawner type=fire")
	assert_false(spawner.is_active(), "spawner not active initially")


func test_m13_particle_spawner_spawn_fire() -> void:
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"fire")
	var n: int = spawner.spawn(Vector2(100, 100))
	assert_eq(n, 20, "fire spawns 20 particles")
	assert_true(spawner.is_active(), "spawner is active after spawn")


func test_m13_particle_spawner_spawn_smoke() -> void:
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"smoke")
	var n: int = spawner.spawn(Vector2(200, 200))
	assert_eq(n, 15, "smoke spawns 15 particles")


func test_m13_particle_spawner_spawn_magic() -> void:
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"magic")
	var n: int = spawner.spawn(Vector2(300, 300))
	assert_eq(n, 25, "magic spawns 25 particles")


func test_m13_particle_spawner_spawn_blood() -> void:
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"blood")
	var n: int = spawner.spawn(Vector2(400, 400))
	assert_eq(n, 10, "blood spawns 10 particles")


func test_m13_particle_spawner_unknown_type() -> void:
	# Spawning an unknown type
	# returns 0.
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"unknown")
	var n: int = spawner.spawn(Vector2.ZERO)
	assert_eq(n, 0, "unknown type spawns 0 particles")


func test_m13_particle_spawner_last_position() -> void:
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"fire")
	spawner.spawn(Vector2(123, 456))
	assert_eq(spawner.last_position(), Vector2(123, 456), "last_position matches spawn position")


func test_m13_particle_spawner_deactivate() -> void:
	var PS: GDScript = load(_PS_PATH)
	var spawner: Variant = PS.call("make", &"fire")
	spawner.spawn(Vector2.ZERO)
	assert_true(spawner.is_active(), "active after spawn")
	spawner.deactivate()
	assert_false(spawner.is_active(), "inactive after deactivate")


func test_m13_particle_spawner_supported_types() -> void:
	var PS: GDScript = load(_PS_PATH)
	var types: Array = PS.call("supported_types")
	assert_true(&"fire" in types, "fire is supported")
	assert_true(&"smoke" in types, "smoke is supported")
	assert_true(&"magic" in types, "magic is supported")
	assert_true(&"blood" in types, "blood is supported")


func test_m13_particle_spawner_count_for_type() -> void:
	var PS: GDScript = load(_PS_PATH)
	assert_eq(PS.call("particle_count_for_type", &"fire"), 20, "fire count=20")
	assert_eq(PS.call("particle_count_for_type", &"magic"), 25, "magic count=25")
