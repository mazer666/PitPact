# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Migration registry for the save format.
#
# Per ADR-0003, every load goes through a migration chain.
# The chain is a list of pure functions, each shaped
# `migrate_<from>_to_<to>(body: Dictionary) -> Dictionary`,
# registered in this file. The loader walks the chain from
# the read `save_version` to the version the running code
# understands (currently `1`).
#
# M1 ships ONE migration as a smoke-test: a no-op for
# version 1 → 1. The no-op exists so the registry is live
# and exercisable; a future PR that bumps `save_version`
# adds the real `migrate_1_to_2`, `migrate_2_to_3`, etc.
#
# Why pure functions in this file, not the loader?
#   * The migrations are testable from CI without a Godot
#     runtime (the loader is `realm_serializer.gd`).
#   * A future `migrations/` directory can hold the per-
#     version files; this file stays the registry and the
#     single source of truth for the chain.
class_name SaveMigrations
extends RefCounted


## A single migration step. `from_version` and `to_version`
## are integers; the function takes a `body` `Dictionary`
## and returns the migrated `body`. The function MUST be
## pure (no I/O, no global state); the loader relies on that
## for its deterministic-replay property.
class _Migration:
	var from_version: int
	var to_version: int
	var func_ref: Callable

	func _init(f: int, t: int, fn: Callable) -> void:
		from_version = f
		to_version = t
		func_ref = fn


# The live registry. Order is not significant (the loader
# walks the chain by matching `(read_version, target_version)`
# against the registered `(from, to)` pairs), but registering
# the no-op smoke-test first keeps the file easy to read.
static var _registry: Array = []


## Register a migration. Called from the bottom of this file
## (and from future per-version files) at module load time.
## Returns nothing; the side effect is the `_registry` list
## gaining one entry. A duplicate `(from, to)` registration
## is a hard `push_error`; the chain must be deterministic.
static func register(from_version: int, to_version: int, fn: Callable) -> void:
	for m in _registry:
		if m.from_version == from_version and m.to_version == to_version:
			push_error(
				(
					"SaveMigrations: duplicate registration of migrate_%d_to_%d"
					% [from_version, to_version]
				)
			)
			return
	_registry.append(_Migration.new(from_version, to_version, fn))


## Look up the migration step from `from_version` to
## `to_version`. Returns the callable, or `null` if the
## chain is incomplete. The loader uses the result to walk
## the chain; a `null` return is the signal to refuse the
## save with "no migration path".
static func find(from_version: int, to_version: int) -> Callable:
	for m in _registry:
		if m.from_version == from_version and m.to_version == to_version:
			return m.func_ref
	return Callable()


## Walk the chain from `from_version` to `to_version`. Each
## step calls the registered pure function; if any step
## fails (the callable returns a non-Dictionary, or the
## return is malformed), the chain aborts and the original
## `body` is returned with a `push_error`. The loader is
## expected to surface a player-facing error in that case.
##
## The chain is one step at a time; a "1 → 3" migration that
## needs to go through "2" is two separate registrations
## (`1 → 2` and `2 → 3`). This makes each step small,
## testable, and easy to bisect on.
static func run(body: Dictionary, from_version: int, to_version: int) -> Dictionary:
	if from_version == to_version:
		return body
	var current: Dictionary = body.duplicate(true)
	var v: int = from_version
	# Guard against an infinite loop: at most 32 steps
	# (far more than the M1 → M6 path will ever need; the
	# cap is a safety net for a buggy chain).
	for _i in range(32):
		if v == to_version:
			return current
		var step: Callable = find(v, to_version)
		if not step.is_valid():
			push_error("SaveMigrations: no path from version %d to %d" % [v, to_version])
			return body
		var out: Variant = step.call(current)
		if typeof(out) != TYPE_DICTIONARY:
			push_error(
				(
					"SaveMigrations: migrate_%d_to_%d returned %s, expected Dictionary"
					% [v, to_version, type_string(typeof(out))]
				)
			)
			return body
		current = out
		v += 1
	push_error("SaveMigrations: chain exceeded 32 steps without reaching %d" % to_version)
	return body


# --- the M1 registry ---
#
# M1 ships a single no-op for version 1 → 1. The function
# exists so the registry is exercisable; a future PR that
# bumps `save_version` replaces the constant below with the
# real chain (1 → 2, 2 → 3, …).


## The no-op migration for `save_version` 1 → 1. The
## function is intentionally trivial: it returns its
## argument. The reason it exists is that the registry
## must have at least one entry, and the integration test
## (`tests/integration/test_save_roundtrip.gd`) walks the
## chain on every load.
static func migrate_1_to_1(body: Dictionary) -> Dictionary:
	return body


# Bootstrap the registry at module load time. A future M2+
# commit adds the real chain here (e.g.
# `register(1, 2, _m1_migrate_1_to_2)`).
static func _static_init() -> void:
	# `register` is idempotent: re-registering the same
	# `(from, to)` is a `push_error`, but `_static_init`
	# runs once per class load, so a duplicate
	# registration means someone added two migration
	# files for the same version — the kind of mistake
	# that should fail loud.
	register(1, 1, Callable(SaveMigrations, "migrate_1_to_1"))
