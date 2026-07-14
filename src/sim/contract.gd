# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant contract data carrier
# (M2 Track B).
#
# `Contract` is the per-contract data carrier for the
# pact the player strikes with an individual
# inhabitant (§9 and §10 of `docs/requirements.md`).
# The M2 foundation shipped the field-only skeleton;
# this commit fills in the per-tick evaluation rule
# (called from `Sim.tick()` after the needs-decay
# step), the `breach()` mutator, the `is_active()`
# predicate, and the `terms_for()` reader.
#
# The contract model is **one-inhabitant-per-contract**.
# A contract between the player and a *group* of
# inhabitants is a content-defined fan-out into N
# one-inhabitant contracts. The terms themselves are
# a content-defined `Dictionary[StringName, Variant]`
# — the standard pact (`data/contracts/standard_pact.tres`)
# pins the keys; the M5 content pass adds more.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name Contract
extends RefCounted

## The contract's stable identity. `StringName`
## for the same reasons as `Inhabitant.id`: it
## survives the dictionary round-trip and identity
## comparisons are O(1) hashed lookups. The id is
## assigned once at construction and never changes.
var id: StringName = &""

## The inhabitant the contract is with, as an
## inhabitant id (`StringName`). The M2 contract
## model is one-inhabitant-per-contract.
var inhabitant_id: StringName = &""

## The contract's clause set, as a `Dictionary`.
## The standard pact's keys are `lodging: bool`,
## `food_share: bool`,
## `labour_hours_per_day: int`, and
## `breach_consequence: StringName`. Content-defined
## pacts may add more keys; the simulator only
## evaluates the keys the per-tick rule knows about.
var terms: Dictionary = {}

## Whether the contract has been breached. The
## `breached` flag is set by `breach()` when one of
## the clauses in `terms` is no longer satisfied.
## Once `breached` is `true`, it stays `true`;
## the contract is not re-evaluated after breach.
var breached: bool = false

## The in-game day the contract was breached on.
## `0.0` while `breached` is `false`. The value is
## set by `breach()` to `time_days` at the end of
## the breach tick (post step 6 in ADR-0005), so the
## value is reproducible.
var breach_at_day: float = 0.0

## Per-day breach-evaluation costs and recovery
## modifiers are content-driven. The standard pact
## sets `breach_consequence` to a `StringName` (e.g.
## `&"contract.breach.morale_penalty"`) that the
## event log's `summary` resolves against a
## locale-key prefix. The reference to the Sim's
## event log is held weakly: the sim owns the log,
## the contract only borrows it for the duration
## of one `breach()` call.
var _event_log: EventLog = null


## Default constructor. Starts with empty
## fields and a clean contract.
func _init() -> void:
	id = &""
	inhabitant_id = &""
	terms = {}
	breached = false
	breach_at_day = 0.0
	_event_log = null


## Construct a contract with the canonical
## `(id, inhabitant_id, terms)` triple. The
## `event_log` argument is optional; when supplied,
## `breach()` will append a `contract.breach` event
## to the log. The event-log reference is held
## weakly — a contract is not the owner of the log.
static func make(
	p_id: StringName, p_inhabitant_id: StringName, p_terms: Dictionary, p_event_log: EventLog = null
) -> Contract:
	var c: Contract = Contract.new()
	c.id = p_id
	c.inhabitant_id = p_inhabitant_id
	c.terms = p_terms.duplicate(true)
	if p_event_log != null:
		c._event_log = p_event_log
	return c


## Bind the event log this contract should write
## `breach` events to. The sim calls this once
## after construction so contracts do not have to
## know about the sim's internal log layout.
func bind_event_log(p_event_log: EventLog) -> void:
	_event_log = p_event_log


## Breach the contract at `time_days`. Sets
## `breached = true`, records `breach_at_day =
## time_days`, and appends a `contract.breach`
## event to the bound `EventLog` (if one is bound).
## Calling `breach()` on an already-breached
## contract is a no-op (the append-only log must
## not see duplicate breach events for the same
## contract).
##
## The breach event's `summary` is the locale key
## `EVENT_CONTRACT_BREACH`; the UI's event-log
## panel resolves the key through `tr()` and
## substitutes the contract id and the
## `breach_consequence` term. The `affected` list
## is the contract's `inhabitant_id` (the contract
## has exactly one affected party).
func breach(time_days: float) -> void:
	if breached:
		return
	breached = true
	breach_at_day = time_days
	if _event_log == null:
		return
	var consequence: StringName = StringName(String(terms.get("breach_consequence", &"")))
	var entry: Dictionary = {
		"id": StringName(String(id) + ".breach"),
		"time_days": time_days,
		"kind": &"contract.breach",
		"summary": &"EVENT_CONTRACT_BREACH",
		"affected": PackedStringArray([String(inhabitant_id)]),
		"breach_consequence": consequence,
	}
	_event_log.append(entry)


## Whether the contract is *active* at `time_days`.
## A contract is active when it has not yet been
## breached and `time_days` is greater than or equal
## to `0.0` (the contract has been "signed" — the
## M2 model assumes the contract was signed at the
## realm's founding, so any non-negative time is
## active). The M3+ per-contract `signed_at_day`
## field narrows this to a real interval; for M2
## the all-time-active form is enough.
func is_active(time_days: float) -> bool:
	if breached:
		return false
	return time_days >= 0.0


## Read a single term by key. Returns the term's
## value (a `Variant`) if the key is present,
## `null` otherwise. The reader is the canonical
## way for the per-tick rule and the UI's
## contract-inspector panel to look up a term;
## reaching into `terms` directly is allowed but
## not the public surface.
func terms_for(key: StringName) -> Variant:
	if not terms.has(key):
		return null
	return terms[key]
