# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
extends GutTest

## M3-Closeout (best-in-class audit): the canonical
## M3 anchor set and the FirstInspection branch tree.
## The test pins the public surface of
## `M3Campaign.list_anchors` /
## `M3Campaign.first_inspection_tree` and asserts
## the invariants the M3 closeout promises in
## CHANGELOG.md (four anchors, three-node branch
## tree, two terminals with `terminal_effect`
## dictionaries).


func test_list_anchors_has_four_entries() -> void:
	var anchors: Array = M3Campaign.list_anchors()
	assert_eq(anchors.size(), 4, "M3 closeout ships four anchors")


func test_list_anchors_contains_first_morning() -> void:
	var anchors: Array = M3Campaign.list_anchors()
	var found: bool = false
	for a in anchors:
		if a.id == &"first_morning":
			found = true
			assert_eq(a.trigger_at_day, 2.0, "first_morning triggers at day 2.0")
			break
	assert_true(found, "first_morning anchor in the canonical set")


func test_list_anchors_contains_stowaway_with_negative_trigger() -> void:
	# The M3 default for the stowaway anchor is
	# `trigger_at_day = -1.0` (location-gated, not
	# time-gated). The per-tick rule treats a
	# negative value as "always available once the
	# player reaches the anchor's tile".
	var anchors: Array = M3Campaign.list_anchors()
	var stowaway: NarrativeAnchor = null
	for a in anchors:
		if a.id == &"stowaway":
			stowaway = a
			break
	assert_ne(stowaway, null, "stowaway anchor in the canonical set")
	assert_lt(
		float(stowaway.trigger_at_day), 0.0, "stowaway is location-gated (trigger_at_day < 0.0)"
	)


func test_first_inspection_tree_shape() -> void:
	var tree: Array = M3Campaign.first_inspection_tree()
	assert_eq(tree.size(), 3, "FirstInspection tree has 3 nodes (root + 2 terminals)")
	var root: BranchNode = null
	var accept: BranchNode = null
	var counter: BranchNode = null
	for n in tree:
		if n.id == &"first_inspection":
			root = n
		elif n.id == &"accept_audit":
			accept = n
		elif n.id == &"counter_offer":
			counter = n
	assert_ne(root, null, "root in tree")
	assert_ne(accept, null, "accept terminal in tree")
	assert_ne(counter, null, "counter terminal in tree")
	assert_true(root.is_root(), "first_inspection is the root")
	assert_eq(String(root.parent), "", "root has no parent")
	assert_true(accept.is_terminal(), "accept is terminal")
	assert_true(counter.is_terminal(), "counter is terminal")


func test_first_inspection_terminal_effects() -> void:
	var tree: Array = M3Campaign.first_inspection_tree()
	for n in tree:
		if n.id == &"accept_audit":
			assert_eq(
				float(n.terminal_effect.get("morale_delta", 0.0)),
				-0.2,
				"accept_audit morale_delta == -0.2"
			)
			assert_eq(
				String(n.terminal_effect.get("follow_up_anchor_id", &"")),
				"inspector_returns",
				"accept_audit follow_up_anchor_id == inspector_returns"
			)
		elif n.id == &"counter_offer":
			assert_eq(
				float(n.terminal_effect.get("morale_delta", 0.0)),
				0.1,
				"counter_offer morale_delta == +0.1"
			)
			assert_eq(
				String(n.terminal_effect.get("follow_up_anchor_id", &"")),
				"first_pactmaker_visit",
				"counter_offer follow_up_anchor_id == first_pactmaker_visit"
			)


func test_first_inspection_root_id_constant() -> void:
	assert_eq(
		String(M3Campaign.FIRST_INSPECTION_ROOT_ID),
		"first_inspection",
		'FIRST_INSPECTION_ROOT_ID is &"first_inspection"'
	)
