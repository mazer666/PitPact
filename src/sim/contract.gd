# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant contract data carrier
# (M2 skeleton).
#
# `Contract` is the per-contract data carrier for the
# pact the player strikes with an individual
# inhabitant (§9 and §10 of `docs/requirements.md`).
# The M2 skeleton ships the `id`, `inhabitant_id`,
# `terms`, `breached`, and `breach_at_day` fields and
# the `class_name`; the M2 Track B commit fills in
# the per-tick evaluation rule (called from step 5
# in ADR-0005, after the relationships update).
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
## model is one-inhabitant-per-contract; a contract
## between the player and a *group* of inhabitants
## is a content-defined fan-out into N
## one-inhabitant contracts.
var inhabitant_id: StringName = &""

## The contract's clause set, as a `Dictionary`.
## The Dictionary's shape is content-defined
## (the M2 Track B commit pins the keys; the M5
## release populates the data). The skeleton ships
## an empty `Dictionary` so the save/load pipeline
## can round-trip the field before the keys are
## pinned. The M2 cycle 3 commit narrows the type
## to `Dictionary[StringName, Variant]`.
var terms: Dictionary = {}

## Whether the contract has been breached. The
## `breached` flag is set by the M2 Track B
## per-tick evaluation rule when one of the
## clauses in `terms` is no longer satisfied.
## Once `breached` is `true`, it stays `true`;
## the contract is not re-evaluated after breach.
var breached: bool = false

## The in-game day the contract was breached on.
## `0.0` while `breached` is `false`. The value is
## set by the M2 Track B per-tick evaluation rule
## at the same tick the `breached` flag is raised.
## The value is the realm's `time_days` *at the
## end* of the breach tick (post step 6 in
## ADR-0005), so the value is reproducible.
var breach_at_day: float = 0.0


## Default constructor. Starts with empty
## fields and a clean contract. The M2 cycle 3
## commit replaces this with a constructor that
## takes `(id, inhabitant_id, terms)`.
func _init() -> void:
	id = &""
	inhabitant_id = &""
	terms = {}
	breached = false
	breach_at_day = 0.0
