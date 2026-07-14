# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M3-foundation world-skeleton smoke test.
#
# This is the trivial smoke test for the M3-foundation
# commit (ADR-0007 + ADR-0008 + the WorldGenerator
# façade + the four `src/world/` skeletons). It does
# three things:
#
#   1. Asserts that the new `WorldGenerator` class is
#      loadable from `res://src/world/generator.gd`.
#      A regression in the file path or a syntax error
#      in the file would fail this test; a passing test
#      confirms the `class_name WorldGenerator`
#      declaration resolved and the GUT 9 harness can
#      `load()` the script.
#
#   2. Asserts that one `Biome` can be instantiated
#      with a deterministic id. The `id` is the
#      biome's stable identity and is what every
#      other module (the generator, the renderer,
#      the save body) keys off. A test on `id` is a
#      test on the determinism contract the M3
#      cycle 2 (Track A) commit builds on.
#
#   3. Asserts that one `NarrativeAnchor` can be
#      instantiated. The anchor is the §8
#      "fixed narrative anchor" data carrier; the
#      skeleton-level check is that the class
#      loads and the public surface is reachable.
#
# The deeper generator-determinism test
# (`tests/world/test_generator_determinism.gd`)
# and the branching-event test
# (`tests/integration/test_branching_event.gd`)
# land in the M3 cycle 2 commits. The skeleton
# cannot exercise those tests because the
# `WorldGenerator.generate()` body is a no-op
# in the M3 foundation; the tests are owned by
# the two tracks that fill the body in.
extends GutTest

const _GENERATOR_PATH := "res://src/world/generator.gd"
const _BIOME_PATH := "res://src/world/biome.gd"
const _EXPLORATION_PATH := "res://src/world/exploration.gd"
const _NARRATIVE_ANCHOR_PATH := "res://src/world/narrative_anchor.gd"
const _BRANCH_PATH := "res://src/world/branch.gd"


func test_trivial_assertion() -> void:
	# Canonical "is the test runner actually running tests?"
	# assertion. If this fails, the failure is upstream of
	# any real test logic.
	assert_eq(2 + 2, 4, "2 + 2 should equal 4")


func test_world_generator_class_loads() -> void:
	# The M3-foundation contract pins the new public entry
	# point as `class_name WorldGenerator` (ADR-0007).
	# The class must load from
	# `res://src/world/generator.gd` and the GUT 9
	# harness must be able to instantiate it. A
	# regression in the file path, a syntax error in
	# the file, or an unresolved class_name would fail
	# this test.
	var GeneratorClass := load(_GENERATOR_PATH)
	assert_not_null(GeneratorClass, "src/world/generator.gd should load as a class")


func test_world_generator_has_generate_method() -> void:
	# The M3-foundation contract pins
	# `WorldGenerator.generate(seed, width, height,
	# constraints) -> WorldMap` as the single public
	# mutating method. The method must exist on the
	# class; a regression in the signature would fail
	# this test (the M3 cycle 2 Track A commit builds
	# against the signature). We exercise the method
	# through an instance (rather than `has_method` on
	# the script) because GDScript's `has_method` on a
	# `load()`-ed `Script` does not consistently see
	# instance methods on 4.3 — the call-and-assert
	# path is the stable check.
	var GeneratorClass := load(_GENERATOR_PATH)
	assert_not_null(GeneratorClass, "src/world/generator.gd should load as a class")
	var gen: Object = GeneratorClass.new()
	# The M3-foundation body is a no-op that returns
	# an empty `WorldMap`. The post-condition we can
	# assert at the skeleton level is "the call
	# returns without throwing and the returned value
	# is a `WorldMap` (an inner class of
	# `WorldGenerator`)". The M3 cycle 2 (Track A)
	# commit's determinism test asserts the deeper
	# post-conditions (deep-equal maps, structural
	# checks).
	var result: Object = gen.call("generate", 0, 0, 0, {})
	assert_not_null(result, "WorldGenerator.generate should return a non-null WorldMap")


func test_world_generator_has_world_map_inner_class() -> void:
	# The M3-foundation contract pins `WorldMap` as
	# an inner class of `WorldGenerator` (the
	# generator's return type). The class must be
	# reachable through the generator; a regression
	# in the inner-class declaration would fail this
	# test.
	var GeneratorClass := load(_GENERATOR_PATH)
	var world_map_class: Variant = GeneratorClass.get("WorldMap")
	assert_not_null(world_map_class, "WorldGenerator should expose a WorldMap inner class")


func test_world_generator_version_is_m3_skeleton() -> void:
	# The version tag is a string rather than a
	# numeric constant so the version can be derived
	# from a single source of truth in a later
	# milestone. The M3-foundation tag is
	# `0.1.0-m3-skeleton`; the M3 cycle 2 (Track A)
	# commit bumps it to `0.2.0-m3-track-a` to mark
	# the body landing.
	var GeneratorClass := load(_GENERATOR_PATH)
	var v: String = String(GeneratorClass.call("version"))
	assert_eq(
		v,
		"0.2.0-m3-track-a",
		"WorldGenerator.version() should return the M3 cycle 2 (Track A) version tag"
	)


func test_biome_class_loads() -> void:
	# The M3-foundation contract pins `class_name
	# Biome` in `src/world/biome.gd`. The class must
	# load and the GUT 9 harness must be able to
	# instantiate it. A regression in the file path,
	# a syntax error, or an unresolved class_name
	# would fail this test.
	var BiomeClass := load(_BIOME_PATH)
	assert_not_null(BiomeClass, "src/world/biome.gd should load as a class")


func test_biome_instantiates_with_deterministic_id() -> void:
	# The M3 contract pins the biome's `id` as a
	# `StringName` defaulting to `&""`. The
	# skeleton-level check is that the class loads,
	# that the `id` field exists, and that the
	# `Biome.make` factory produces a biome with the
	# `id` the caller asked for (a deterministic
	# round-trip: same id in, same id out).
	var BiomeClass := load(_BIOME_PATH)
	var b: Object = BiomeClass.call("make", &"hollow", &"BIOME_HOLLOW_NAME", 0.1, 1.0)
	assert_not_null(b, "Biome.make should produce a non-null instance")
	var got_id: String = String(b.get("id"))
	assert_eq(got_id, "hollow", "Biome.make should set the id to the requested StringName")


func test_biome_defaults_are_skeleton_baseline() -> void:
	# The M3 contract pins the four `Biome` fields
	# (`id`, `display_name`, `burden`,
	# `movement_modifier`) and the default values.
	# A fresh `Biome` has `id = &""`, `display_name
	# = &""`, `burden = 0.0`, and `movement_modifier
	# = 1.0`. The defaults are the values the
	# generator's content-adapter step overrides
	# (M3 cycle 2, Track A).
	var BiomeClass := load(_BIOME_PATH)
	var b: Object = BiomeClass.new()
	assert_eq(
		String(b.get("id")), "", "A freshly-constructed Biome should have an empty StringName id"
	)
	assert_eq(
		String(b.get("display_name")),
		"",
		"A freshly-constructed Biome should have an empty StringName display_name"
	)
	assert_eq(float(b.get("burden")), 0.0, "A freshly-constructed Biome should have burden == 0.0")
	assert_eq(
		float(b.get("movement_modifier")),
		1.0,
		"A freshly-constructed Biome should have movement_modifier == 1.0"
	)


func test_exploration_map_class_loads() -> void:
	# The M3-foundation contract pins `class_name
	# ExplorationMap` in `src/world/exploration.gd`.
	# The class must load and the GUT 9 harness
	# must be able to instantiate it.
	var ExplorationClass := load(_EXPLORATION_PATH)
	assert_not_null(ExplorationClass, "src/world/exploration.gd should load as a class")


func test_exploration_map_instantiates_with_dimensions() -> void:
	# The M3 contract pins the `ExplorationMap`
	# constructor as `_init(p_w, p_h)`. The
	# skeleton-level check is that the constructor
	# accepts dimensions, builds a flat `revealed`
	# array of the right length, and defaults
	# `home_position` to `Vector2i(-1, -1)`.
	var ExplorationClass := load(_EXPLORATION_PATH)
	var m: Object = ExplorationClass.new(8, 6)
	assert_eq(int(m.get("w")), 8, "ExplorationMap(8, 6) should set w == 8")
	assert_eq(int(m.get("h")), 6, "ExplorationMap(8, 6) should set h == 6")
	var revealed: Array = m.get("revealed")
	assert_eq(
		revealed.size(),
		48,
		"ExplorationMap(8, 6).revealed should be 8*6 == 48 entries (flat 2D bool array)"
	)
	for v in revealed:
		assert_false(
			bool(v), "A freshly-constructed ExplorationMap should have all tiles unrevealed"
		)
	assert_eq(
		m.get("home_position"),
		Vector2i(-1, -1),
		"A freshly-constructed ExplorationMap should have home_position == Vector2i(-1, -1)"
	)


func test_narrative_anchor_class_loads() -> void:
	# The M3-foundation contract pins `class_name
	# NarrativeAnchor` in
	# `src/world/narrative_anchor.gd`. The class
	# must load and the GUT 9 harness must be able
	# to instantiate it.
	var AnchorClass := load(_NARRATIVE_ANCHOR_PATH)
	assert_not_null(AnchorClass, "src/world/narrative_anchor.gd should load as a class")


func test_narrative_anchor_instantiates_with_deterministic_fields() -> void:
	# The M3 contract pins the six `NarrativeAnchor`
	# fields (`id`, `trigger_at_day`, `display_name`,
	# `summary`, `triggered`, `resolved`) and the
	# default values. The skeleton-level check is
	# that the `NarrativeAnchor.make` factory
	# produces an anchor with the values the caller
	# asked for (a deterministic round-trip: same
	# fields in, same fields out).
	var AnchorClass := load(_NARRATIVE_ANCHOR_PATH)
	var a: Object = AnchorClass.call(
		"make", &"anchor_first_step", 3.0, &"ANCHOR_FIRST_STEP", &"ANCHOR_FIRST_STEP_SUMMARY"
	)
	assert_not_null(a, "NarrativeAnchor.make should produce a non-null instance")
	assert_eq(
		String(a.get("id")),
		"anchor_first_step",
		"NarrativeAnchor.make should set the id to the requested StringName"
	)
	assert_eq(
		float(a.get("trigger_at_day")),
		3.0,
		"NarrativeAnchor.make should set trigger_at_day to the requested float"
	)
	assert_eq(
		String(a.get("display_name")),
		"ANCHOR_FIRST_STEP",
		"NarrativeAnchor.make should set display_name to the requested StringName"
	)
	assert_eq(
		String(a.get("summary")),
		"ANCHOR_FIRST_STEP_SUMMARY",
		"NarrativeAnchor.make should set summary to the requested StringName"
	)
	assert_false(
		bool(a.get("triggered")), "A freshly-made NarrativeAnchor should have triggered == false"
	)
	assert_false(
		bool(a.get("resolved")), "A freshly-made NarrativeAnchor should have resolved == false"
	)


func test_narrative_anchor_trigger_and_resolve_lifecycle() -> void:
	# The M3 contract pins the `triggered` and
	# `resolved` flags as the anchor's lifecycle
	# state. The skeleton-level check exercises
	# both transitions: `trigger()` sets
	# `triggered = true`; `resolve()` sets
	# `resolved = true` and (if not already set)
	# `triggered = true`. A regression in the
	# lifecycle would fail this test.
	var AnchorClass := load(_NARRATIVE_ANCHOR_PATH)
	var a: Object = AnchorClass.new()
	assert_false(bool(a.get("triggered")), "A fresh anchor should have triggered == false")
	a.call("trigger")
	assert_true(bool(a.get("triggered")), "After trigger(), triggered should be true")
	a.call("resolve")
	assert_true(bool(a.get("resolved")), "After resolve(), resolved should be true")
	assert_true(bool(a.get("triggered")), "After resolve(), triggered should still be true")
	# Calling trigger / resolve twice is a no-op
	# (the M3 contract pins the idempotence).
	a.call("trigger")
	a.call("resolve")
	assert_true(bool(a.get("resolved")), "A second resolve() should be a no-op")


func test_branch_node_class_loads() -> void:
	# The M3-foundation contract pins `class_name
	# BranchNode` in `src/world/branch.gd`. The
	# class must load and the GUT 9 harness must
	# be able to instantiate it.
	var BranchClass := load(_BRANCH_PATH)
	assert_not_null(BranchClass, "src/world/branch.gd should load as a class")


func test_branch_node_defaults_are_skeleton_baseline() -> void:
	# The M3 contract pins the six `BranchNode`
	# fields (`id`, `parent`, `trigger_at_day`,
	# `condition`, `children`, `terminal_effect`)
	# and the default values. A fresh `BranchNode`
	# has `id = &""`, `parent = &""`,
	# `trigger_at_day = 0.0`, an invalid
	# `Callable()`, an empty `children` array, and
	# an empty `terminal_effect` dictionary. The
	# defaults are the values the generator's
	# content-adapter step overrides (M3 cycle 2,
	# Track B).
	var BranchClass := load(_BRANCH_PATH)
	var n: Object = BranchClass.new()
	assert_eq(
		String(n.get("id")),
		"",
		"A freshly-constructed BranchNode should have an empty StringName id"
	)
	assert_eq(
		String(n.get("parent")),
		"",
		"A freshly-constructed BranchNode should have an empty StringName parent (root node)"
	)
	assert_eq(
		float(n.get("trigger_at_day")),
		0.0,
		"A freshly-constructed BranchNode should have trigger_at_day == 0.0"
	)
	var cond: Variant = n.get("condition")
	assert_false(
		(cond as Callable).is_valid() if cond is Callable else true,
		"A freshly-constructed BranchNode should have an invalid Callable condition (placeholder)"
	)
	var children: Array = n.get("children")
	assert_eq(
		children.size(), 0, "A freshly-constructed BranchNode should have an empty children array"
	)
	var te: Dictionary = n.get("terminal_effect")
	assert_eq(
		te.size(),
		0,
		"A freshly-constructed BranchNode should have an empty terminal_effect dictionary"
	)
	# A fresh BranchNode is a root node (empty
	# parent) but is NOT a terminal node (the
	# structural invariant from ADR-0008: a node
	# is terminal iff `children.is_empty()` AND
	# `not terminal_effect.is_empty()`).
	assert_true(bool(n.call("is_root")), "A fresh BranchNode should be a root node (empty parent)")
	assert_false(
		bool(n.call("is_terminal")),
		"A fresh BranchNode should NOT be terminal (empty children AND empty terminal_effect)"
	)
