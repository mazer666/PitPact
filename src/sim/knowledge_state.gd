# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — knowledge-state carrier (M4 foundation).
#
# `KnowledgeState` is the per-realm carrier for
# research and ritual progression (ADR-0010). The
# carrier is a deterministic, save-format-versioned
# data structure that records *what the realm has
# researched*, *which rituals are currently in
# progress*, and *which effects the per-tick rule
# has produced this tick*. The realm façade holds
# one instance per realm; the per-tick rule
# (sim's step 7c, planned for M4 Track A) reads
# and writes the carrier.
#
# The M4 foundation commit ships the carrier as
# a SKELETON: the `save()` and `load()` methods
# are full implementations (the round-trip is the
# load-bearing contract), but the per-tick
# progression rule is a no-op until the M4 Track A
# commit lands. The save body slot the carrier
# occupies is `body.knowledge` (ADR-0003, M4
# reservation).
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` and `src/content` (the content
# adapter is a planned M4 Track A dependency; the
# skeleton declares it but does not preload it).
class_name KnowledgeState
extends RefCounted

## M4 foundation: the canonical save-body
## schema version. The M4 default is `1`;
## future migrations bump the value and add
## a step to `src/save/migrations.gd`. The
## version is the migration hook ADR-0003
## pins for every per-realm save body.
const _SAVE_VERSION: int = 1

## The per-node research completion counters.
## A `Dictionary[StringName, int]` keyed by
## the research node's `id`. A non-zero value
## means "the realm has researched this node"
## (`is_researched(id)` returns `true`). The
## M4 default is `0` (unresearched) or `1`
## (researched); an M5 content pass can use
## `> 1` for repeatable nodes (e.g. "increase
## the realm's food yield by 5%", stacked).
##
## The `Dictionary[StringName, int]` shape is
## the save-format-friendly representation;
## the M4 Track A commit adds a per-tick
## accessor that returns a `0` for unknown
## ids without mutating the dictionary (the
## ADR-0010 invariant "one map read" is
## preserved).
var researched: Dictionary = {}

## The list of *currently active* rituals.
## An active ritual is a `Dictionary` with
## the canonical keys `id: StringName`,
## `node_id: StringName` (the ritual's
## research-node id), `started_at_day: float`,
## `duration_days: float`, and
## `progress_days: float`. The carrier does
## not own the time math; the per-tick rule
## (M4 Track A) reads and writes the
## `progress_days` field. The M4 default is
## `[]` (no active rituals).
var active_rituals: Array = []

## The queue of effect payloads the per-tick
## rule has emitted but the realm façade has
## not yet consumed. An effect payload is a
## `Dictionary` with the canonical
## `ResearchNode.effect` keys
## (`pactmaker_power_id`, `decree_unlock`,
## `room_unlock`, `crisis_summon_id`).
## `consume_pending_effects()` returns the
## queue and resets it to `[]`. The M4
## default is `[]` (no pending effects).
var pending_effects: Array = []


## Default constructor. Starts with empty
## `researched`, `active_rituals`, and
## `pending_effects`.
func _init() -> void:
	researched = {}
	active_rituals = []
	pending_effects = []


## Whether the realm has researched the node
## with id `id`. Returns `true` when
## `researched[id] > 0`. The reader is the
## canonical way to ask "is this researched?";
## reaching into `researched` directly is
## allowed but not the public surface.
##
## The method does NOT mutate `researched`;
## an unknown id returns `false` without
## inserting a `0` entry. The
## "one map read" contract (ADR-0010) is
## preserved: the call is O(1) on a known
## id and O(1) (with no side effect) on an
## unknown id.
func is_researched(id: StringName) -> bool:
	if id == &"":
		return false
	if not researched.has(id):
		return false
	return int(researched[id]) > 0


## Whether a ritual with id `node_id` is
## currently in `active_rituals`. Returns
## `true` when at least one entry in
## `active_rituals` has `node_id == node_id`.
## The reader is the canonical way to ask
## "is this ritual active?"; reaching into
## `active_rituals` directly is allowed but
## not the public surface.
##
## The method does NOT mutate
## `active_rituals`; an unknown id returns
## `false` without raising. The
## "one scan" contract is preserved: the
## call is O(n) in the number of active
## rituals, which is small in the M4
## surface area (≤ a few concurrent
## rituals per realm).
func is_ritual_active(node_id: StringName) -> bool:
	if node_id == &"":
		return false
	for r in active_rituals:
		if r == null or not (r is Dictionary):
			continue
		if StringName(String(r.get("node_id", &""))) == node_id:
			return true
	return false


## Serialize the carrier to a `Dictionary`
## the save body stores at `body.knowledge`.
## The result has the canonical keys:
## `version: int` (the migration hook),
## `researched: Dictionary[StringName, int]`,
## `active_rituals: Array`, and
## `pending_effects: Array`. The
## `Dictionary` is a *deep* copy of the
## carrier's state; mutating the result
## after `save()` returns does NOT
## mutate the carrier.
##
## The method is the canonical "snapshot
## for save" path; the M5 replay feature
## uses the snapshot to rebuild a campaign
## from a saved event log. The M4
## foundation commit ships the method
## as a full implementation; the per-tick
## progression rule is a separate concern
## (M4 Track A).
func save() -> Dictionary:
	return {
		"version": _SAVE_VERSION,
		"researched": researched.duplicate(true),
		"active_rituals": active_rituals.duplicate(true),
		"pending_effects": pending_effects.duplicate(true),
	}


## Restore the carrier from a `Dictionary`
## the save body stored at `body.knowledge`.
## The `d` argument is the save body's
## `knowledge` slot; the method validates
## the canonical keys (`version`,
## `researched`, `active_rituals`,
## `pending_effects`) and refuses to
## restore from a mismatched version. The
## method returns `true` on a successful
## restore and `false` on a version
## mismatch (the caller is the migration
## registry, which falls back to the
## previous version's migration step).
##
## A `null` argument or a `Dictionary`
## missing the canonical keys is a
## `push_error` no-op that returns
## `false`. The M4 contract pins a
## *strict* shape: the migration
## registry owns the migration; the
## carrier does not silently relax
## the shape.
func load(d: Dictionary) -> bool:
	if not _validate_save_body(d):
		return false
	researched = (d["researched"] as Dictionary).duplicate(true)
	active_rituals = (d["active_rituals"] as Array).duplicate(true)
	pending_effects = (d["pending_effects"] as Array).duplicate(true)
	return true


## Internal save-body validator. Returns
## `true` on a valid save body, `false`
## otherwise (the `load(d)` method is the
## only caller; the helper is private).
## The validator pushes the same error
## message the M4 contract pins; the
## helper is the one place that knows
## the canonical shape.
func _validate_save_body(d: Dictionary) -> bool:
	var err: String = _save_body_error(d)
	if err == "":
		return true
	push_error("KnowledgeState.load: " + err)
	return false


## Internal save-body error-message
## builder. Returns the empty string on
## a valid save body, a non-empty
## human-readable error message
## otherwise. Splitting the validator
## into "build the error" and "push
## the error" keeps the public method
## (`load`) and the validator
## (`_validate_save_body`) under the
## `gdlint` `max-returns: 6` ceiling.
func _save_body_error(d: Dictionary) -> String:
	# Walk the canonical checks in order;
	# the first failing check produces the
	# error. A single-return body keeps
	# the helper under the
	# `gdlint` `max-returns: 6` ceiling.
	if d == null:
		return "save body is null"
	if not (d is Dictionary):
		return "save body is not a Dictionary"
	var v: int = int(d.get("version", -1))
	if v != _SAVE_VERSION:
		return "save body version mismatch (got %d, expected %d)" % [v, _SAVE_VERSION]
	# The three container-shape checks
	# are independent; the helper rolls
	# them into one loop and reports the
	# first failure. This keeps the
	# function under the
	# `gdlint` `max-returns: 6` ceiling.
	for spec in [
		["researched", TYPE_DICTIONARY],
		["active_rituals", TYPE_ARRAY],
		["pending_effects", TYPE_ARRAY],
	]:
		var key: String = spec[0]
		var want_type: int = spec[1]
		if not d.has(key) or typeof(d[key]) != want_type:
			return "save body missing or wrong-typed '%s'" % key
	return ""


## Static factory. The canonical way to
## construct a carrier from a save body.
## The factory delegates to `load(d)`
## and returns the new instance on
## success, or a *fresh* `KnowledgeState`
## (with empty fields) on a version
## mismatch — the migration registry's
## fallback path. The M4 default is
## "strict restore": a version mismatch
## is a hard error, not a silent
## degradation.
##
## The M4 foundation commit ships the
## factory as a full implementation;
## the migration registry is the M4
## Track A commit's responsibility.
static func from_dict(d: Dictionary) -> KnowledgeState:
	var ks: KnowledgeState = KnowledgeState.new()
	if d == null:
		return ks
	if ks.load(d):
		return ks
	# On failure, return a fresh carrier so
	# the caller can decide what to do
	# (the migration registry's job is to
	# walk the version chain; the carrier
	# is the leaf).
	return ks


## Drain the `pending_effects` queue. The
## method returns the queue and resets it
## to `[]`. The realm façade's "what
## happened this tick?" poll calls this
## once per tick (after the sim's `tick()`
## returns); the per-effect side effects
## (Pactmaker power unlock, decree
## unlock, room unlock, crisis-summon)
## are applied by the *consumer*, not by
## the carrier.
##
## The method is idempotent: a second
## call without an intervening
## `pending_effects.append(...)` returns
## `[]`. The M4 default is "drain on
## consume" — the queue is *not* a log;
## the realm façade's event log (M2
## contract) is the audit trail.
func consume_pending_effects() -> Array:
	var out: Array = pending_effects
	pending_effects = []
	return out
