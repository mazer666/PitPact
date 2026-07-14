# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the simulation façade (Sim).
#
# `Sim` is the per-realm simulation façade declared by ADR-0002
# and pinned by ADR-0005 (sim-tick determinism). It is the
# *one* owner of the per-tick RNG state; every other module
# (inhabitants, contracts, crisis, …) receives a read-only
# handle for the duration of a tick.
#
# The M2-foundation commit ships `Sim` as a SKELETON: the
# `tick` method is a no-op. The next two parallel tracks
# (Track A: inhabitants / needs / tasks / event memory;
# Track B: contracts / relationships / crises) fill in the
# six steps pinned by ADR-0005. The public surface — the
# `tick(delta_days, inhabitants, events)` signature, the
# `version()` accessor, the `time_days` property — is fixed
# by this commit and is what the two tracks build against.
#
# Per ADR-0002, this file does not import from `src/ui`,
# `src/realm`, or `src/save`. It imports from `src/core` and
# `src/content` (the content adapter is a planned M2 cycle 2
# dependency; the skeleton declares it but does not preload
# it).
#
# Per ADR-0005, the sim owns the per-tick RNG state. The
# public surface of `Sim` does NOT expose `snapshot` /
# `restore` / `save_state` / `load_state`. Those methods
# live on the `SplitMix64` instance the sim holds; the
# save/load pipeline (ADR-0003) round-trips the RNG state
# by reaching into the sim through a friend accessor on the
# realm façade (planned for the M2 cycle 3 commit).
class_name Sim
extends RefCounted

## M2 version tag. Bumped by the cycle 2 (Track A) and
## cycle 3 (Track B) commits when they fill in the tick
## body. The value is a string rather than a numeric
## constant so the version can be derived from a single
## source of truth in a later milestone.
const _VERSION: String = "0.1.0-m2-skeleton"

## In-game time, in days. The sim's clock is advanced by
## `delta_days` at the end of every `tick()` call (step 6
## in ADR-0005). Read-only from the outside; the value is
## authoritative for the realm.
var time_days: float = 0.0

## The per-tick RNG state. `SplitMix64` is the project's
## only sanctioned source of randomness (see
## `src/core/rng.gd` and ADR-0005). Held as a private
## member so the public surface cannot leak a writable
## handle to a subsystem. The seed is supplied at
## construction; the deterministic-replay invariant
## depends on the seed being recorded into the save body
## (ADR-0003) and re-supplied at load time.
var _rng: SplitMix64 = SplitMix64.new(0)


## Construct a `Sim` with an explicit 64-bit seed. The
## seed is mixed once by `SplitMix64._init`; two
## structurally similar seeds (e.g. `0` and `1`) do not
## start at correlated points in the sequence. The seed
## is also stored as a public member so the save/load
## pipeline (ADR-0003) can record it under
## `body.sim.seed` and re-supply it at load time.
func _init(seed: int = 0) -> void:
	time_days = 0.0
	_rng = SplitMix64.new(seed)


## Tick the simulation forward by `delta_days`. Pure
## function on `inhabitants` + `events` + the sim's
## private RNG state. The body is a NO-OP in the M2
## skeleton; the cycle 2 (Track A) and cycle 3 (Track B)
## commits fill in the six steps pinned by ADR-0005 in
## exactly this order:
##
##   1. RNG draw         — pull a per-tick batch from `_rng`.
##   2. Needs decay      — decay every inhabitant's `Needs`.
##   3. Task progress    — advance every open `Task`'s
##                          `progress`; emit `task.completed`.
##   4. Event-memory     — record the tick's events into
##      recording           each affected inhabitant's
##                          `EventMemory`.
##   5. Relationships    — update every `Relationship` edge
##      update              based on the events from step 4.
##   6. Event-log append — append the tick's events to the
##                          append-only `EventLog`.
##
## After step 6, the sim's `time_days` is advanced by
## `delta_days` and the tick returns.
##
## Determinism contract (ADR-0005):
##   * `delta_days` is the only parameter that varies
##     across a sequence of ticks; the seed and the
##     `inhabitants` and `events` arrays are the same.
##   * Two `Sim` instances constructed with the same seed
##     and ticked with the same `delta_days` and the same
##     `inhabitants` / `events` arguments produce deep-equal
##     state at every tick. The replay test
##     `tests/sim/test_sim_replay.gd` (M2 cycle 3) is the
##     mechanical check for this contract.
##
## Pre-conditions (asserted at the top of the M2
## skeleton; the cycle 2 commit turns them into typed
## errors):
##   * `delta_days > 0.0` — a tick of zero or negative
##     length is a programmer error.
##   * `inhabitants` is an `Array` of `Inhabitant`
##     instances (typed as `Array` for now; the cycle 2
##     commit narrows it to `Array[Inhabitant]`).
##   * `events` is an `Array` of `EventEntry` dicts
##     (typed as `Array` for now; the cycle 2 commit
##     narrows it to `Array[Dictionary]`).
##
## Post-conditions:
##   * `time_days` is advanced by `delta_days`.
##   * `inhabitants` and `events` are mutated *only* in
##     the ways the tick's six steps specify (needs decay,
##     task progress, memory recording, relationship
##     update, event-log append). The sim never replaces
##     the arrays wholesale; the realm façade's view
##     model (M5) observes the same arrays in place.
func tick(delta_days: float, inhabitants: Array, events: Array) -> void:
	# M2 SKELETON: the tick body is intentionally empty.
	# The cycle 2 (Track A) and cycle 3 (Track B) commits
	# fill in the six ADR-0005 steps in the order
	# documented above. Advancing `time_days` and asserting
	# the pre-conditions is the only behaviour this
	# skeleton ships; the rest is owned by the two
	# follow-up tracks.
	assert(delta_days > 0.0, "Sim.tick: delta_days must be positive (got %f)" % delta_days)
	assert(inhabitants != null, "Sim.tick: inhabitants array is null")
	assert(events != null, "Sim.tick: events array is null")
	time_days += delta_days
	return


## Return the M2-skeleton version tag. The value is a
## string rather than a numeric constant so the version
## can be derived from a single source of truth in a
## later milestone. The cycle 2 commit will bump this
## to "0.2.0-m2-track-a"; the cycle 3 commit will bump
## it to "0.3.0-m2-track-b".
static func version() -> String:
	return _VERSION
