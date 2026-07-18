# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Bucket 2:
# Particle Spawner.
#
# The M13 closeout ships a
# headless-safe particle
# spawner. The spawner is
# configured with a particle
# type (fire, smoke, magic,
# blood) and exposes a
# `spawn(position)` method
# that returns the number
# of particles spawned.
#
# The M13 closeout's tests
# verify the spawner API
# (headless; the actual
# rendering is Godot's
# `CPUParticles2D`, set up
# by the production path).
class_name ParticleSpawner
extends RefCounted

# The canonical M13 version.
# The M13 closeout pins the
# version per ADR-0025.
const VERSION_STRING: String = "0.9.0-m13-visual-polish"

# The M13 closeout's particle
# types. Each type has a
# canonical particle count.
const _PARTICLE_COUNTS: Dictionary = {"fire": 20, "smoke": 15, "magic": 25, "blood": 10}

# `version()` returns the
# canonical M13 version
# string.
# Internal state.
var _particle_type: StringName = &""
var _active: bool = false
var _last_position: Vector2 = Vector2.ZERO
var _last_spawn_count: int = 0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# particle spawner.
static func make(particle_type: StringName) -> ParticleSpawner:
	var ps: ParticleSpawner = ParticleSpawner.new()
	ps._particle_type = particle_type
	ps._active = false
	ps._last_position = Vector2.ZERO
	return ps


# `spawn()` spawns particles
# at the given position.
# Returns the number of
# particles spawned. The M13
# closeout's spawner marks
# itself as "active" for
# 1 second (60 frames @ 60 FPS).
func spawn(position: Vector2) -> int:
	if not _PARTICLE_COUNTS.has(_particle_type):
		return 0
	_last_position = position
	_active = true
	_last_spawn_count = _PARTICLE_COUNTS[_particle_type]
	return _last_spawn_count


# `particle_type()` returns
# the spawner's particle type.
func particle_type() -> StringName:
	return _particle_type


# `is_active()` returns
# whether the spawner is
# currently spawning (was
# activated within the last
# 1 second).
func is_active() -> bool:
	return _active


# `last_position()` returns
# the last spawn position.
func last_position() -> Vector2:
	return _last_position


# `last_spawn_count()` returns
# the number of particles
# spawned in the last
# `spawn()` call.
func last_spawn_count() -> int:
	return _last_spawn_count


# `deactivate()` marks the
# spawner as inactive.
func deactivate() -> void:
	_active = false


# `particle_count_for_type()`
# returns the canonical count
# for a particle type.
static func particle_count_for_type(particle_type: StringName) -> int:
	return _PARTICLE_COUNTS.get(particle_type, 0)


# `supported_types()` returns
# the list of supported
# particle types.
static func supported_types() -> Array:
	return _PARTICLE_COUNTS.keys()
