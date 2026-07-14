# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the world-generator façade (ADR-0007).
#
# `WorldGenerator` is the public entry point for the M3
# world-generator. It is a *pure function*:
#
#   WorldGenerator.generate(seed, width, height, constraints)
#       -> WorldMap
#
# The function is deterministic: two calls with the same
# `(seed, width, height, constraints)` produce deep-equal
# `WorldMap` values, on every platform, for every Godot
# version, for every integer version of GDScript. The
# contract is pinned by ADR-0007 (world-generator
# determinism).
#
# The function holds the per-generation RNG state in a
# private member; the state is exhausted at the end of
# the call. The generator does NOT expose
# `snapshot` / `restore` / `save_state` / `load_state` on
# the public surface. The save/load pipeline (ADR-0003)
# round-trips the generator by re-supplying the seed, not
# by storing the generator's residual state. This mirrors
# ADR-0005's RNG-ownership rule for the sim.
#
# The constraint set is a `Dictionary` with the canonical
# keys documented in ADR-0007:
#
#   * `hearth_position: Vector2i`    — the tile coordinate
#                                       the Hearth must be
#                                       placed on (or
#                                       `null` to let the
#                                       generator pick).
#   * `required_biome_ids: Array`    — the set of biome
#                                       ids the generator
#                                       must place at least
#                                       one tile of.
#   * `min_biome_count: int`         — the minimum number
#                                       of spatially
#                                       distinct biomes
#                                       the map must
#                                       contain.
#   * `hearth_burden_max: float`     — the maximum
#                                       `biome.burden` the
#                                       Hearth's tile is
#                                       allowed to have.
#   * `random: int`                  — an additional
#                                       per-generation
#                                       entropy offset.
#
# Every key is optional; a missing key falls back to the
# documented default. The generator must satisfy every
# constraint in the set; if a constraint is unsatisfiable
# (e.g. the requested Hearth position is unreachable from
# the requested map edge), the generator raises a
# `GeneratorConstraintError` and returns an empty
# `WorldMap`. The error path is part of the contract: a
# generator that silently relaxes a constraint has NOT
# honoured the contract.
#
# This M3-foundation commit ships the SIGNATURE ONLY. The
# `generate()` body is a no-op that returns an empty
# `WorldMap`. The M3 cycle 2 (Track A) commit fills in
# the body; the cycle 2 commit's `tests/world/
# test_generator_determinism.gd` is the mechanical check
# for the determinism invariant.
#
# Per ADR-0002, this file does not import from `src/ui`,
# `src/sim`, `src/realm`, `src/save`, or `src/audit`. It
# imports from `src/core` and `src/content` only.
class_name WorldGenerator
extends RefCounted

## M3-foundation version tag. The full generator lands in
## the M3 cycle 2 (Track A) commit; this string is bumped
## to mark the body landing. String rather than a numeric
## constant so the version can be derived from a single
## source of truth in a later milestone.
const _VERSION: String = "0.1.0-m3-skeleton"

## The per-generation RNG state. `SplitMix64` is the
## project's only sanctioned source of randomness (see
## `src/core/rng.gd` and ADR-0005). Held as a private
## member so the public surface cannot leak a writable
## handle to a caller. The state is constructed at the
## top of `generate()` from the seed and is exhausted
## before the call returns.
var _rng: SplitMix64 = SplitMix64.new(0)

## The width of the last-generated map, in tiles. `0`
## until `generate()` is called. The save/load pipeline
## (ADR-0003) does NOT read this field; the save body
## stores the seed and the dimensions explicitly.
var _last_width: int = 0

## The height of the last-generated map, in tiles. `0`
## until `generate()` is called.
var _last_height: int = 0

## The seed of the last generation. `0` until
## `generate()` is called. Stored for the convenience of
## callers that want to log the seed after a successful
## generation; the save/load pipeline does NOT read
## this field.
var _last_seed: int = 0


## Generate a `WorldMap` from a seed and a constraint
## set. Pure function per ADR-0007. The M3-foundation
## commit ships the signature and the no-op body; the
## M3 cycle 2 (Track A) commit fills in the body.
##
## Pre-conditions:
##   * `seed` is any 64-bit signed integer. Two
##     structurally similar seeds (e.g. `0` and `1`) do
##     not start at correlated points in the sequence;
##     `SplitMix64` mixes the seed on construction
##     (see `src/core/rng.gd`).
##   * `width > 0` and `height > 0`. A non-positive
##     dimension is a caller error; the function
##     `push_error`s and returns an empty `WorldMap`.
##   * `constraints` is a `Dictionary` with the
##     canonical keys documented in ADR-0007. Unknown
##     keys are ignored; missing keys fall back to
##     the documented defaults.
##
## Post-conditions:
##   * The returned `WorldMap` is the canonical
##     data carrier the realm façade, the renderer,
##     and the inhabitants read.
##   * The per-generation RNG state is exhausted;
##     the generator's `_rng` is left in a
##     well-defined but unspecified state.
##   * Two calls with the same `(seed, width, height,
##     constraints)` produce deep-equal `WorldMap`
##     values. This is the determinism invariant
##     ADR-0007 pins.
##
## Errors:
##   * A non-positive `width` or `height` is a
##     `push_error`; the function returns an empty
##     `WorldMap`.
##   * An unsatisfiable constraint (e.g. the Hearth
##     position is unreachable from the map edge) is
##     a `GeneratorConstraintError`; the function
##     returns an empty `WorldMap`. The error path
##     is part of the contract: a generator that
##     silently relaxes a constraint has NOT honoured
##     the contract.
func generate(seed: int, width: int, height: int, constraints: Dictionary) -> WorldMap:
	# Pre-conditions. A non-positive dimension is a
	# caller error; we `push_error` and return an
	# empty `WorldMap` so the caller can detect the
	# failure (the empty map has `width == 0`).
	if width <= 0 or height <= 0:
		push_error(
			(
				"WorldGenerator.generate: width and height must be positive (got width=%d, height=%d)"
				% [width, height]
			)
		)
		return WorldMap.new()
	# A `null` constraints dictionary is a caller
	# error; we `push_error` and return an empty
	# `WorldMap` so the caller can detect the
	# failure. The foundation commit accepts an
	# empty `Dictionary` (the documented "no
	# constraints" form); the M3 cycle 2 Track A
	# commit validates the per-key contents.
	if constraints == null:
		push_error("WorldGenerator.generate: constraints dictionary is null")
		return WorldMap.new()
	# Foundation-commit no-op body. The M3 cycle 2
	# (Track A) commit replaces this stub with the
	# real generator: a `SplitMix64` constructed
	# from `seed`, the biome catalogue consulted
	# against `constraints.required_biome_ids`, the
	# Hearth placed per `constraints.hearth_position`
	# (or picked per the low-burden / edge-reachable
	# rule), the structural acceptance checks
	# (edge reachability, low burden, biome count)
	# asserted, and a populated `WorldMap` returned.
	#
	# The stub records the inputs in the private
	# members so a future caller can introspect
	# "what was the last generation's parameters"
	# without writing a wrapper.
	_last_width = width
	_last_height = height
	_last_seed = seed
	_rng = SplitMix64.new(seed)
	# Intentional no-op return: the M3-foundation
	# commit ships an empty `WorldMap` so the
	# signature compiles and the smoke test passes.
	# The M3 cycle 2 commit replaces this with the
	# real generator body.
	return WorldMap.new()


## The M3-foundation version tag. String rather than
## a numeric constant so the version can be derived
## from a single source of truth in a later milestone.
static func version() -> String:
	return _VERSION


# --- inner classes ---------------------------------------------------


## The generator's output data carrier. A `WorldMap`
## is a pure data object: the realm façade, the
## renderer, and the inhabitants read it; nobody
## mutates it after the generator returns it.
##
## The M3-foundation commit ships the field set as
## declared public surface; the M3 cycle 2 (Track A)
## commit populates the fields and the M3 cycle 2
## (Track B) commit adds the narrative-anchor and
## branch-node fields. The public surface is the
## only thing the two tracks are allowed to add to.
##
## Per ADR-0002, this inner class does not import
## from any other `src/<module>/`; the realm façade
## binds a `WorldState` and a `Sim` to a `WorldMap`
## at materialisation time, and the inner class is
## the data carrier between the two.
class WorldMap:
	extends RefCounted

	## The seed the map was generated from. The
	## save/load pipeline (ADR-0003) round-trips
	## this value under `body.world.seed`. A
	## regenerate from the same seed produces the
	## same map (the determinism invariant
	## ADR-0007 pins).
	var seed: int = 0

	## The width of the map, in tiles. The M3
	## default is a positive integer. The save
	## body stores this value under
	## `body.world.w`.
	var width: int = 0

	## The height of the map, in tiles. The M3
	## default is a positive integer. The save
	## body stores this value under
	## `body.world.h`.
	var height: int = 0

	## The Hearth's tile coordinate. The M3
	## default is the generator's pick; the M3
	## cycle 2 (Track A) commit pins the pick
	## rule (low-burden, edge-reachable). The
	## save body stores this value under
	## `body.world.hearth_position`.
	var hearth_position: Vector2i = Vector2i(-1, -1)

	## The per-tile grid. The M3-foundation
	## commit ships an empty array; the M3
	## cycle 2 (Track A) commit populates it
	## with one entry per tile, indexed as
	## `tiles[y * width + x]`. The grid is
	## the source of truth for the renderer's
	## biome and tile-id lookups.
	var tiles: Array = []

	## The biome catalogue as a `Dictionary` of
	## biome id (StringName) -> `Biome` (the
	## skeleton class in `biome.gd`). The M3
	## cycle 2 (Track A) commit populates this
	## from `ContentRegistry`; the foundation
	## commit ships an empty dictionary.
	var biomes: Dictionary = {}

	## The fog-of-war state. The M3-foundation
	## commit ships a `null` reference; the M3
	## cycle 2 (Track A) commit replaces it
	## with a real `ExplorationMap` instance.
	## The save body stores this value under
	## `body.world.exploration`.
	var exploration: RefCounted = null

	## The narrative anchors. An `Array` of
	## `NarrativeAnchor` (the skeleton class in
	## `narrative_anchor.gd`). The M3-foundation
	## commit ships an empty array; the M3
	## cycle 2 (Track B) commit populates it.
	## The save body stores this value under
	## `body.world.narrative_anchors`.
	var narrative_anchors: Array = []

	## The branching-event root nodes. An
	## `Array` of `BranchNode` (the skeleton
	## class in `branch.gd`). The M3-foundation
	## commit ships an empty array; the M3
	## cycle 2 (Track B) commit populates it.
	## The save body stores this value under
	## `body.world.branch_roots`.
	var branch_roots: Array = []

	## Default constructor. All fields are zero /
	## empty; the populated values are the
	## generator's responsibility.
	func _init() -> void:
		seed = 0
		width = 0
		height = 0
		hearth_position = Vector2i(-1, -1)
		tiles = []
		biomes = {}
		exploration = null
		narrative_anchors = []
		branch_roots = []


## Raised by `generate()` when a constraint is
## unsatisfiable. The M3-foundation commit declares
## the class so callers can `instanceof`-check the
## failure mode; the M3 cycle 2 (Track A) commit
## raises the error from the constraint-validation
## step. The class is an inner class for the same
## reason `WorldMap` is: the generator owns the
## failure mode and the realm façade handles it.
class GeneratorConstraintError:
	extends RefCounted

	## A human-readable description of the
	## unsatisfied constraint. The realm façade
	## surfaces the message in the player's
	## error toast; the smoke test asserts the
	## message is non-empty.
	var message: String = ""

	## Default constructor. Takes the message
	## as the only argument.
	func _init(p_message: String = "") -> void:
		message = p_message
