# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M3 World-and-Campaign canonical content.
#
# This file is the canonical M3 closeout content
# for the four fixed narrative anchors and the
# FirstInspection branch tree (ADR-0008). The
# content is "fixed" in the M3 sense: the same
# seed produces the same anchor set and the same
# branch tree; the data is not procedurally
# generated text. The content lives in code (not
# in `.tres` files) because `NarrativeAnchor`
# and `BranchNode` are `RefCounted` carriers, not
# `Resource`-derived; serialising them in `.tres`
# would require either a `Resource` adapter or
# a save/load helper, both of which are out of
# scope for M3. The M5+ content pass moves this
# data to `.tres` (the data schema in
# `docs/data-schema.md` is the canonical target).
#
# The M3-Closeout public surface:
#   * `M3Campaign.list_anchors() -> Array[NarrativeAnchor]`
#   * `M3Campaign.first_inspection_tree() -> Array[BranchNode]`
#   * `M3Campaign.first_inspection_root_id() -> StringName`
#
# Per ADR-0002, this file does not import from
# `src/world`, `src/sim`, `src/realm`, `src/save`,
# `src/ui`, or `src/audit`. It imports from
# `src/core` and `src/content` only.
class_name M3Campaign
extends RefCounted

## The id of the FirstInspection branch root.
## The constant is the canonical name the M3
## closeout uses for the FirstInspection
## crisis; the realm façade's content adapter
## reads this id when wiring the crisis to the
## branch tree.
const FIRST_INSPECTION_ROOT_ID: StringName = &"first_inspection"


## The canonical M3 anchor set. The four anchors
## cover the §8 "fixed narrative anchors"
## requirement: a "first morning" hook, a
## "stowaway" discovery, a "first pactmaker
## visit", and an "inspector returns" hook. The
## `trigger_at_day` values are the M3 default
## (the test suite and the M3-Closeout smoke
## use the same values; the realm façade can
## override at construction time).
static func list_anchors() -> Array:
	return [
		NarrativeAnchor.from_content(
			&"first_morning", 2.0, &"ANCHOR_FIRST_MORNING_NAME", &"ANCHOR_FIRST_MORNING_SUMMARY"
		),
		NarrativeAnchor.from_content(
			&"stowaway", -1.0, &"ANCHOR_STOWAWAY_NAME", &"ANCHOR_STOWAWAY_SUMMARY"
		),
		NarrativeAnchor.from_content(
			&"first_pactmaker_visit",
			7.0,
			&"ANCHOR_FIRST_PACTMAKER_NAME",
			&"ANCHOR_FIRST_PACTMAKER_SUMMARY"
		),
		NarrativeAnchor.from_content(
			&"inspector_returns",
			21.0,
			&"ANCHOR_INSPECTOR_RETURNS_NAME",
			&"ANCHOR_INSPECTOR_RETURNS_SUMMARY"
		),
	]


## The canonical M3 FirstInspection branch tree
## (ADR-0008 §"branching event schema"). The
## tree is a root with two terminal children:
##   * `accept_audit` — the realm accepts the
##     inspector's audit. The `terminal_effect`
##     is a `morale_delta = -0.2` and a
##     `follow_up_anchor_id = "inspector_returns"`.
##   * `counter_offer` — the realm counters with
##     a different arrangement. The
##     `terminal_effect` is a `morale_delta =
##     +0.1` and a `follow_up_anchor_id =
##     "first_pactmaker_visit"`.
##
## The tree is the canonical M3 closeout
## branching event; the M4 cycle replaces it
## with the autonomous-conflict trees (per
## `docs/milestones.md`).
static func first_inspection_tree() -> Array:
	var root: BranchNode = BranchNode.make_root(
		&"first_inspection", [&"accept_audit", &"counter_offer"]
	)
	var accept: BranchNode = (
		BranchNode
		. terminal(
			&"accept_audit",
			&"first_inspection",
			{
				"morale_delta": -0.2,
				"needs_food_delta": 0.0,
				"follow_up_anchor_id": &"inspector_returns",
			}
		)
	)
	var counter: BranchNode = (
		BranchNode
		. terminal(
			&"counter_offer",
			&"first_inspection",
			{
				"morale_delta": 0.1,
				"needs_food_delta": 0.05,
				"follow_up_anchor_id": &"first_pactmaker_visit",
			}
		)
	)
	return [root, accept, counter]
