# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
extends GutTest

## M3 cycle 2 (Track B) — branch-node factory
## tests. Pins the structural invariant
## (ADR-0008): a terminal node has empty
## `children` AND non-empty `terminal_effect`; a
## non-terminal (fork) node has at least one
## child AND empty `terminal_effect`.


func test_make_root() -> void:
	var b: BranchNode = BranchNode.make_root(
		&"first_inspection", [&"accept_audit", &"counter_offer"]
	)
	assert_eq(String(b.id), "first_inspection", "id set")
	assert_eq(String(b.parent), "", "root has no parent")
	assert_true(b.is_root(), "is_root() == true")
	assert_false(b.is_terminal(), "root is not terminal")
	assert_eq(b.children.size(), 2, "root has 2 children")


func test_terminal_factory() -> void:
	var b: BranchNode = BranchNode.terminal(
		&"accept_audit", &"first_inspection", {"morale_delta": -0.2, "log": "audit accepted"}
	)
	assert_eq(String(b.id), "accept_audit", "id set")
	assert_eq(String(b.parent), "first_inspection", "parent set")
	assert_true(b.is_terminal(), "is_terminal() == true")
	assert_eq(b.children.size(), 0, "terminal has no children")
	assert_eq(b.terminal_effect.size(), 2, "terminal has 2 effect keys")


func test_fork_factory() -> void:
	var b: BranchNode = BranchNode.fork(
		&"first_inspection", &"", [&"accept_audit", &"counter_offer"]
	)
	assert_true(b.is_root(), "fork with no parent is a root")
	assert_false(b.is_terminal(), "fork is not terminal")
	assert_eq(b.children.size(), 2, "fork has 2 children")
	assert_eq(b.terminal_effect.size(), 0, "fork has empty terminal_effect")


func test_first_inspection_branch_tree() -> void:
	# Build the canonical M3 First-Inspection branch
	# tree (root + 2 terminals). This is the same
	# shape the M3 narrative content ships.
	var root: BranchNode = BranchNode.make_root(
		&"first_inspection", [&"accept_audit", &"counter_offer"]
	)
	var accept: BranchNode = BranchNode.terminal(
		&"accept_audit", &"first_inspection", {"morale_delta": -0.2, "audit_outcome": &"compliant"}
	)
	var counter: BranchNode = BranchNode.terminal(
		&"counter_offer", &"first_inspection", {"morale_delta": 0.1, "audit_outcome": &"contested"}
	)
	var tree: Dictionary = {
		root.id: root,
		accept.id: accept,
		counter.id: counter,
	}
	assert_eq(tree.size(), 3, "tree has 3 nodes")
	assert_true(tree[&"first_inspection"].is_root(), "root is_root")
	assert_true(tree[&"accept_audit"].is_terminal(), "accept is terminal")
	assert_true(tree[&"counter_offer"].is_terminal(), "counter is terminal")


func test_branch_equals() -> void:
	var a: BranchNode = BranchNode.fork(&"x", &"", [&"c1", &"c2"])
	var b: BranchNode = BranchNode.fork(&"x", &"", [&"c1", &"c2"])
	assert_true(a.equals(b), "two equal forks are equal")
	var c: BranchNode = BranchNode.fork(&"x", &"", [&"c1", &"c3"])
	assert_false(a.equals(c), "different children differ")
