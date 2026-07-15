# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
extends GutTest

## M3 cycle 2 (Track B) — branching-event
## integration tests. Wires the BranchNode
## tree into the Sim via a Crisis and
## `register_anchors` so the per-tick step 7b
## fires the trigger rule. Pins the
## M3-first-inspection -> accept_audit /
## counter_offer branching flow.


func _build_sim_with_anchors(p_anchors: Array) -> Sim:
	var sim: Sim = Sim.new(42)
	sim.register_anchors(p_anchors)
	return sim


func test_step_7b_triggers_anchor_at_day() -> void:
	var a: NarrativeAnchor = NarrativeAnchor.from_content(&"first_morning", 2.0, &"x", &"x")
	var sim: Sim = _build_sim_with_anchors([a])
	var empty: Array = []
	sim.tick(1.0, [], empty)
	assert_false(a.triggered, "day 1: anchor not yet triggered (trigger_at_day=2)")
	sim.tick(1.0, [], empty)
	assert_true(a.triggered, "day 2: anchor triggered")
	a.resolve()
	assert_true(a.resolved, "anchor resolved")


func test_step_7b_skips_location_gated_anchor() -> void:
	# Negative trigger_at_day means "location-gated,
	# not time-gated"; the per-tick rule must NOT
	# auto-trigger it.
	var a: NarrativeAnchor = NarrativeAnchor.from_content(&"stowaway", -1.0, &"x", &"x")
	var sim: Sim = _build_sim_with_anchors([a])
	var empty: Array = []
	for i in range(10):
		sim.tick(1.0, [], empty)
	assert_false(a.triggered, "location-gated anchor stays untriggered after 10 ticks")


func test_step_7b_no_anchors_is_noop() -> void:
	# M2 contract: a sim that has never had
	# `register_anchors` called behaves exactly as
	# the M2 tests expect.
	var sim: Sim = Sim.new(7)
	var empty: Array = []
	sim.tick(1.0, [], empty)
	assert_eq(sim.time_days, 1.0, "tick still advances time without anchors")


func test_branch_resolve_appends_event() -> void:
	# The branching-event flow: a Crisis carries the
	# branch root, the realm façade calls
	# `resolve_branch` with the player's pick, the
	# EventLog gets a `branch.resolved` entry.
	var log: EventLog = EventLog.new()
	var cr: Crisis = Crisis.make(
		&"first_inspection",
		0.0,
		func(_t: float) -> bool: return true,
		[{"id": &"receive_inspector", "effect": Callable()}],
		log
	)
	cr.trigger(0.0)
	cr.resolve_branch(0.0, &"accept_audit", &"first_inspection")
	var found: bool = false
	for entry in log.entries:
		if String(entry.get("kind", "")) == "branch.resolved":
			found = true
			assert_eq(String(entry.get("choice_id", "")), "accept_audit", "choice_id recorded")
			assert_eq(String(entry.get("branch_id", "")), "first_inspection", "branch_id recorded")
			break
	assert_true(found, "branch.resolved event appended to log")
	assert_true(cr.resolved, "crisis marked resolved")


func test_branch_tree_full_flow() -> void:
	# End-to-end: build the canonical M3 branch
	# tree, mark a Crisis resolved via
	# `resolve_branch` with one of the terminals,
	# assert the EventLog records the pick.
	var log: EventLog = EventLog.new()
	var root: BranchNode = BranchNode.make_root(
		&"first_inspection", [&"accept_audit", &"counter_offer"]
	)
	var accept: BranchNode = BranchNode.terminal(
		&"accept_audit", &"first_inspection", {"audit_outcome": &"compliant"}
	)
	assert_true(root.is_root(), "root is root")
	assert_true(accept.is_terminal(), "accept is terminal")

	var cr: Crisis = Crisis.make(
		root.id,
		0.0,
		func(_t: float) -> bool: return true,
		[{"id": &"receive_inspector", "effect": Callable()}],
		log
	)
	cr.trigger(0.0)
	cr.resolve_branch(0.0, accept.id, root.id)
	assert_true(cr.resolved, "crisis resolved via branch tree")
	assert_eq(String(cr.chosen_id), "accept_audit", "chosen_id == accept_audit")
