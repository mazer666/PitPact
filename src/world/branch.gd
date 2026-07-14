# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the branching-event node data carrier (M3-foundation skeleton).
#
# `BranchNode` is a per-node data carrier the M3 world
# generator (ADR-0007) emits and the realm's branching
# event tree (ADR-0008) reads. §11 of
# `docs/requirements.md` requires "branching events
# with short- and long-term consequences"; the tree
# shape is documented in ADR-0008. The `BranchNode`
# class is the runtime in-memory representation of a
# single node in the tree; the on-disk definition of
# a follow-up lives in
# `src/content/branch_node_def.gd` (a `BranchNodeDef`
# resource, planned for the M3 cycle 2 Track B commit).
#
# The skeleton declares the public surface that M3
# cycle 2 (Track B) will fill in. The fields are:
#
#   * `id` — stable identity (`StringName`).
#   * `parent` — the upstream event id (a
#     `StringName`); the M3 default is `&""` for
#     root nodes. The M3 cycle 2 (Track B) commit
#     pins the parent-edge canonicalisation
#     (the same canonical-edge rule the M2
#     `Relationship` graph uses, per ADR-0005).
#   * `trigger_at_day` — the in-game day the node
#     becomes available. A negative value
#     (`-1.0`) means "the node is parent-gated,
#     not time-gated"; the per-tick rule treats
#     a negative value as "available once the
#     parent's choice has been picked".
#   * `condition` — a `Callable` placeholder.
#     The M3 default is an empty (invalid)
#     `Callable`; the M3 cycle 2 (Track B) commit
#     populates the callable from the loaded
#     `BranchNodeDef` content. The signature is
#     `func(time_days: float) -> bool`; the
#     callable returns `true` when the node
#     should trigger *now*.
#   * `children` — an `Array` of `StringName`
#     (the downstream nodes' ids). The M3
#     default is an empty array; a non-terminal
#     node has at least one child, a terminal
#     node has zero children. The M3 cycle 2
#     (Track B) commit populates the children
#     from the loaded `BranchNodeDef`.
#   * `terminal_effect` — a `Dictionary` of
#     effect-tag / effect-value pairs. The
#     M3 default is an empty `Dictionary`; a
#     non-empty `Dictionary` means the node
#     is terminal (a leaf of the tree, with no
#     children). The rule "non-empty `Dictionary`
#     iff the node is terminal" is the structural
#     invariant ADR-0008 pins.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/sim`, `src/realm`, `src/save`, or
# `src/audit`. It imports from `src/core` and
# `src/content` only.
class_name BranchNode
extends RefCounted

## The node's stable identity. `StringName` for
## the same reasons as `Tile.id` and `Inhabitant.id`:
## it survives the dictionary round-trip and
## identity comparisons are O(1) hashed lookups.
## The id is assigned once at construction and
## never changes. The save/load pipeline
## (ADR-0003) round-trips this value under
## `body.world.branch_roots[*].id`.
var id: StringName = &""

## The upstream event id (a `StringName`). The
## M3 default is `&""` for root nodes. The M3
## cycle 2 (Track B) commit pins the parent-edge
## canonicalisation (the same canonical-edge rule
## the M2 `Relationship` graph uses, per
## ADR-0005). The save body stores this value
## under `body.world.branch_roots[*].parent`.
var parent: StringName = &""

## The in-game day the node becomes available.
## A `float`; the M3 default is `0.0` (the node
## is available from the start). A negative value
## (`-1.0`) means "the node is parent-gated, not
## time-gated"; the per-tick rule treats a
## negative value as "available once the parent's
## choice has been picked". The save body stores
## this value under
## `body.world.branch_roots[*].trigger_at_day`.
var trigger_at_day: float = 0.0

## The condition that triggers the node. The
## signature is `func(time_days: float) -> bool`;
## the callable returns `true` when the node
## should trigger *now*. The M3 default is an
## empty (invalid) `Callable`; the M3 cycle 2
## (Track B) commit populates the callable from
## the loaded `BranchNodeDef` content. The
## condition is a placeholder for M3+ material
## (the M3 foundation ships the field, the M3
## cycle 2 commit ships the per-node callables).
##
## The `time_days` argument is the realm's
## `time_days` at the *end* of the tick (post
## step 6 in ADR-0005), so the condition sees
## the same value the event log will eventually
## store. This is what makes the trigger
## reproducible.
var condition: Callable = Callable()

## The downstream nodes' ids (an `Array` of
## `StringName`). The M3 default is an empty
## array. The structural invariant
## (ADR-0008) is: a node is *terminal* iff
## `children.is_empty()` AND
## `not terminal_effect.is_empty()`. A node
## with non-empty `children` is a non-terminal
## node and `terminal_effect` is empty. A
## node with empty `children` is a terminal
## node and `terminal_effect` is non-empty.
## A node with empty `children` AND empty
## `terminal_effect` is a content error and
## is rejected at load time. The save body
## stores this array under
## `body.world.branch_roots[*].children`.
var children: Array = []

## The terminal effect, as a `Dictionary` of
## effect-tag / effect-value pairs. The M3
## default is an empty `Dictionary`. The
## structural invariant (ADR-0008) is: a
## non-empty `Dictionary` means the node is
## terminal (a leaf of the tree); an empty
## `Dictionary` means the node is non-terminal
## (an interior node with at least one child).
## The save body stores this value under
## `body.world.branch_roots[*].terminal_effect`.
var terminal_effect: Dictionary = {}


## Default constructor. All fields default to
## their zero-equivalents; the generator's
## content-adapter step (M3 cycle 2, Track B)
## populates the values from the loaded
## `BranchNodeDef` content.
func _init() -> void:
	id = &""
	parent = &""
	trigger_at_day = 0.0
	condition = Callable()
	children = []
	terminal_effect = {}


## Whether this node is terminal (a leaf of the
## tree). The rule (ADR-0008) is: a node is
## terminal iff `children.is_empty()` AND
## `not terminal_effect.is_empty()`. A node
## with non-empty `children` is non-terminal;
## a node with empty `children` AND empty
## `terminal_effect` is a content error and
## `is_terminal()` returns `false` for it (the
## validator is the canonical place to assert
## the invariant; `is_terminal()` is a
## convenience for callers that want a
## predicate).
func is_terminal() -> bool:
	return children.is_empty() and not terminal_effect.is_empty()


## Whether this node is a root node (a node
## with no parent). The rule is: a root node
## has `parent == &""`. The M3 cycle 2
## (Track B) commit pins the root-set
## canonicalisation (the realm façade's
## branching-event tree is rooted at the
## set of nodes with empty `parent`).
func is_root() -> bool:
	return String(parent).is_empty()


## Equality by value. Two branch nodes are
## equal iff they have the same `id`, the
## same `parent`, the same `trigger_at_day`,
## the same `children` (same `StringName`s
## in the same order), and the same
## `terminal_effect` (same keys, same
## values). The `condition` is a `Callable`
## and is NOT compared (callables do not
## have a value-equality semantics; the
## determinism test compares the *content*
## of the callables through the
## `BranchNodeDef` round-trip, not through
## `equals()`).
func equals(other: BranchNode) -> bool:
	# Single-return accumulator pattern. The
	# function used to early-return on each
	# mismatch; the refactor is a `max-returns`
	# lint fix (gdtoolkit caps `equals`-style
	# functions at 6 returns). The accumulator
	# is updated on each mismatch and the
	# function returns the accumulator at the
	# end. The behaviour is unchanged: the
	# function returns `true` iff every
	# comparison passes.
	var matches: bool = true
	if other == null:
		matches = false
	elif id != other.id:
		matches = false
	elif parent != other.parent:
		matches = false
	elif not is_equal_approx(trigger_at_day, other.trigger_at_day):
		matches = false
	elif children.size() != other.children.size():
		matches = false
	else:
		# Per-child name match. A size mismatch
		# was caught above; we walk the arrays
		# in order.
		var i: int = 0
		while i < children.size() and matches:
			if StringName(children[i]) != StringName(other.children[i]):
				matches = false
			i += 1
		# Per-key effect match. The size
		# mismatch check follows the children
		# check; a non-match sets the
		# accumulator.
		if matches and terminal_effect.size() != other.terminal_effect.size():
			matches = false
		elif matches:
			for k in terminal_effect.keys():
				if not other.terminal_effect.has(k):
					matches = false
					break
				if str(terminal_effect[k]) != str(other.terminal_effect[k]):
					matches = false
					break
	return matches
