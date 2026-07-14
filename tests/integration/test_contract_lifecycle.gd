# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Contract lifecycle integration test (Track B).
#
# The M2 Track B task spec asks for a contract-
# lifecycle integration test:
#
#   * create a standard pact with an inhabitant,
#   * tick for 30 days,
#   * assert the contract was breached when
#     `food_share` was set to `false`,
#   * assert a `breach` event was logged.
#
# The test exercises the M2 Track B contract
# pipeline end-to-end: the data-driven
# `data/contracts/standard_pact.tres` is loaded,
# the `Contract` instance is built from its
# `terms`, the `Sim` evaluates the contract on
# every tick, and the resulting `breach` event
# lands in the sim's `EventLog`.
extends GutTest

## The contract's data-driven resource. `gdlint`
## flags repeated `load(...)` calls as
## `duplicated-load`; cache the reference at
## module load.
const STANDARD_PACT: Resource = preload("res://data/contracts/standard_pact.tres")

## The seed the test uses. Pinned so a regression
## in the deterministic sim surfaces as a change
## in the resulting event log.
const _SEED: int = 0xC0FFEE_5_0BA


func test_standard_pact_loads_with_required_terms() -> void:
	# The standard pact's `terms` is the contract
	# the per-tick rule reads. A regression in the
	# `data/contracts/standard_pact.tres` file
	# (e.g. a missing required key) would fail
	# every contract-evaluation test downstream;
	# the smoke test catches the regression here.
	assert_not_null(STANDARD_PACT, "data/contracts/standard_pact.tres should load")
	assert_eq(String(STANDARD_PACT.get("id")), "standard_pact", "id is 'standard_pact'")
	var terms: Dictionary = STANDARD_PACT.get("terms")
	assert_true(terms.has(&"lodging"), "terms has 'lodging'")
	assert_true(terms.has(&"food_share"), "terms has 'food_share'")
	assert_true(terms.has(&"labour_hours_per_day"), "terms has 'labour_hours_per_day'")
	assert_true(terms.has(&"breach_consequence"), "terms has 'breach_consequence'")


func test_contract_made_factory_returns_instance_with_terms() -> void:
	# The `Contract.make` factory is the public
	# surface for constructing a contract. The
	# factory deep-copies `terms` so a caller-
	# side mutation of the original dictionary
	# does not leak into the contract's state.
	var c: Object = Contract.make(
		&"test_contract", &"inhabitant_1", {&"food_share": true, &"lodging": true}
	)
	assert_not_null(c, "Contract.make returns a non-null instance")
	assert_eq(String(c.id), "test_contract", "id is preserved")
	assert_eq(String(c.inhabitant_id), "inhabitant_1", "inhabitant_id is preserved")
	assert_false(c.breached, "fresh contract is not breached")
	assert_true(c.is_active(0.0), "contract is active at time_days = 0.0")
	assert_eq(bool(c.terms_for(&"food_share")), true, "terms_for('food_share') returns true")
	assert_null(c.terms_for(&"missing_key"), "terms_for(missing) returns null")


func test_contract_breaches_when_food_share_false_after_30_days() -> void:
	# Build a sim, attach a standard pact whose
	# `food_share` is `false` from the start, tick
	# 30 days, and assert the contract was breached
	# exactly once and that a `contract.breach`
	# event was logged.
	var sim: Object = Sim.new(_SEED)
	# Build the contract's `terms` from the data
	# resource; we override `food_share` to `false`
	# to provoke the breach.
	var terms: Dictionary = STANDARD_PACT.get("terms").duplicate(true)
	terms[&"food_share"] = false
	var c: Object = Contract.make(&"test_pact_breach", &"inhabitant_alice", terms, sim.event_log)
	sim.add_contract(c)
	# Tick 30 days. The per-tick rule reads the
	# contract's `terms` on every tick; the
	# `food_share` term is `false` from day 0, so
	# the first tick is enough to detect the breach.
	# We tick 30 days so the test exercises the
	# `is_active` rule across the full window.
	for _i in range(30):
		sim.tick(1.0, [], [])
	# The contract's `breached` flag is `true`; the
	# `breach_at_day` is the realm's `time_days` at
	# the breach tick (≤ 1.0 in this test; the first
	# tick detects the breach).
	assert_true(c.breached, "Contract was breached")
	assert_gt(c.breach_at_day, 0.0, "breach_at_day is positive")
	# The event log has at least one `contract.breach`
	# entry that involves `inhabitant_alice`. The
	# `breach` event is the only kind the contract
	# emits, so the log's `entries_involving` is the
	# canonical check.
	var breach_entries: Array = sim.event_log.entries_involving(&"inhabitant_alice")
	assert_gt(breach_entries.size(), 0, "event log has at least one breach entry for alice")
	var found_breach: bool = false
	for e in breach_entries:
		if e.get("kind", &"") == &"contract.breach":
			found_breach = true
			break
	assert_true(found_breach, "event log has a 'contract.breach' entry")
	# Calling `breach()` again is a no-op (the
	# append-only log must not see duplicate events).
	var size_before: int = sim.event_log.entries.size()
	c.breach(99.0)
	var size_after: int = sim.event_log.entries.size()
	assert_eq(size_after, size_before, "double breach() is a no-op (append-only log invariant)")


func test_contract_does_not_breach_when_food_share_true() -> void:
	# Same setup as the breach test, but the
	# `food_share` term is `true`. The contract
	# must remain unbreached after 30 days.
	var sim: Object = Sim.new(_SEED)
	var terms: Dictionary = STANDARD_PACT.get("terms").duplicate(true)
	terms[&"food_share"] = true
	terms[&"lodging"] = true
	var c: Object = Contract.make(&"test_pact_kept", &"inhabitant_bob", terms, sim.event_log)
	sim.add_contract(c)
	for _i in range(30):
		sim.tick(1.0, [], [])
	assert_false(c.breached, "Contract with food_share=true is not breached after 30 days")
	# The log has no `contract.breach` entries
	# involving `inhabitant_bob`.
	var bob_entries: Array = sim.event_log.entries_involving(&"inhabitant_bob")
	for e in bob_entries:
		assert_ne(e.get("kind", &""), &"contract.breach", "no breach event for inhabitant_bob")


func test_contract_inactive_when_already_breached() -> void:
	# A breached contract is not active. The
	# `is_active` predicate is the per-tick
	# rule's "should I evaluate this contract?"
	# check.
	var sim: Object = Sim.new(_SEED)
	var terms: Dictionary = STANDARD_PACT.get("terms").duplicate(true)
	terms[&"food_share"] = false
	var c: Object = Contract.make(&"test_pact_inactive", &"inhabitant_carol", terms, sim.event_log)
	sim.add_contract(c)
	sim.tick(1.0, [], [])
	assert_true(c.breached, "Contract was breached on the first tick")
	# Now the contract is breached; `is_active`
	# returns `false` regardless of `time_days`.
	assert_false(c.is_active(100.0), "Breached contract is not active")
	assert_false(c.is_active(0.0), "Breached contract is not active at day 0 either")
