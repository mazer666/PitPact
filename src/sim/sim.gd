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
# The M2-foundation commit shipped `Sim` as a SKELETON: the
# `tick` method was a no-op. The M2 Track B commit filled in
# the per-tick contract / crisis / task-progress rules and
# wired them into the `tick()` body. The M2 Track A commit
# (this file) adds the per-tick inhabitants / needs /
# event-memory / relationship rules and wires them into
# the same `tick()` body. The order of operations inside the
# tick is exactly the eight steps documented below; the
# inhabitant logic lives in steps 1-5 (RNG draw, needs
# decay, task progress, event-memory recording, relationship
# update), and the contract / crisis logic lives in steps
# 6-7. Step 8 is the post-condition that every event has a
# matching log row.
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

## M2 Track A + M3 cycle 2 (Track A) exploration
## version tag. Bumped from the M2 Track A tag
## to mark the exploration step landing in
## this commit. String rather than a numeric
## constant so the version can be derived from
## a single source of truth in a later
## milestone.
const _VERSION: String = "0.4.1-m2-track-a-explore"

## In-game time, in days. The sim's clock is advanced by
## `delta_days` at the end of every `tick()` call (step 6
## in ADR-0005). Read-only from the outside; the value is
## authoritative for the realm.
var time_days: float = 0.0

## The per-tick RNG state. `SplitMix64` is the project's
## only sanctioned source of randomness (see
## `src/core/rng.gd` and ADR-0005). Held as a private
## member so the public surface cannot leak a writable
## (rng now lives at the top, before event_log)

## The realm's append-only event log. The sim owns the
## log; subsystems (Contract, Task, Crisis) receive a
## borrowed reference via `bind_event_log`. The log is
## the source of truth for the UI's event-log panel
## (§13 of `docs/requirements.md`) and the save/load
## pipeline (ADR-0003).
var event_log: EventLog = EventLog.new()

## The realm's contract set. A `Dictionary[StringName,
## Contract]` keyed by contract id. The set is mutated
## when the player signs a new contract (M3+) or when a
## contract is breached; the per-tick rule reads from
## the set. The set is owned by the sim; the realm
## façade exposes it through a getter.
var contracts: Dictionary = {}

## The realm's task queue. A `Dictionary[StringName,
## Task]` keyed by task id. The set is mutated when the
## player queues a new task (M3+) or when a task is
## completed; the per-tick rule advances every open
## task's progress in step 3 of ADR-0005.
var tasks: Dictionary = {}

## The realm's crisis queue. A `Dictionary[StringName,
## Crisis]` keyed by crisis id. The set is mutated when
## the player schedules a new crisis (M3+) or when a
## crisis is resolved; the per-tick rule evaluates
## every crisis's `condition` between steps 5 and 6 of
## ADR-0005.
var crises: Dictionary = {}

## The realm's exploration map. The M3 cycle 2
## (Track A) commit lands this field as the
## registered-fog-of-war reference. `null` means
## "no exploration has been registered"; the
## per-tick rule (step 7a, M3) treats the
## `null` case as a no-op (the M2 contract is
## preserved). The realm façade binds the
## reference via `register_exploration`.
var exploration_map: RefCounted = null

## The realm's narrative-anchor set. M3 cycle 2
## (Track B) commit lands this field as the
## registered-anchor reference. `null` means
## "no anchors have been registered"; the
## per-tick rule (step 7b, M3) treats the
## `null` case as a no-op (the M2 contract is
## preserved). The realm façade binds the
## reference via `register_anchors`.
var narrative_anchors: Variant = null

## The realm's relationship graph. A
## `Dictionary[StringName, Relationship]` keyed by a
## canonical edge id. The canonical id is the
## lexicographically-sorted `(a, b)` pair joined by
## the U+0001 SEPARATOR character, so `(a, b)` and
## `(b, a)` resolve to the same entry. The M2 Track
## A commit owns the `add_relationship` and
## `find_or_create_edge` helpers below; the per-tick
## step 5 walks this graph and applies the cooperative
## / conflict nudges from the tick's events.
var relationships: Dictionary = {}

## The per-tick RNG state. `SplitMix64` is the project's
## only sanctioned source of randomness (see
## `src/core/rng.gd` and ADR-0005). Held as a private
## member so the public surface cannot leak a writable
## handle to a subsystem. The seed is supplied at
## construction; the deterministic-replay invariant
## depends on the seed being recorded into the save body
## (ADR-0003) and re-supplied at load time.
var _rng: SplitMix64 = SplitMix64.new(0)

## M3-Closeout (Track B): inhabitants array
## captured at the top of `tick()` so
## `_evaluate_crises` can pass it to
## `Crisis.apply_pending_effects`. The field
## is module-private (leading underscore) and
## is reset at the end of every `tick` call.
var _crisis_inhabitants: Array = []

## M3-Closeout (Track B): the inhabitants
## array as seen at the top of `tick()`. The
## field is the single source of truth for
## "who is in the realm this tick".
var _crisis_tick_inhabitants: Array = []


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
	_bind_subsystem_logs()


## Bind the sim's event log to every subsystem in
## `contracts`, `tasks`, and `crises` so they can
## append events. Called from `_init` and from the
## `add_contract` / `add_task` / `add_crisis`
## helpers below. The bind is one-way: the sim
## owns the log; subsystems borrow it.
func _bind_subsystem_logs() -> void:
	for c in contracts.values():
		if c is Contract:
			c.bind_event_log(event_log)
	for t in tasks.values():
		if t is Task:
			t.bind_event_log(event_log)
	for cr in crises.values():
		if cr is Crisis:
			cr.bind_event_log(event_log)


## Add a `Contract` to the realm's contract set and
## bind it to the sim's event log. The `Contract.id`
## is the dictionary key. Adding a contract with a
## duplicate id is a `push_error` no-op (the realm
## façade would have caught the duplicate before
## calling us, but the sim is defensive).
func add_contract(c: Contract) -> void:
	if c == null:
		push_error("Sim.add_contract: contract is null")
		return
	if contracts.has(c.id):
		push_error("Sim.add_contract: contract id %s is already in the set" % String(c.id))
		return
	c.bind_event_log(event_log)
	contracts[c.id] = c


## Add a `Task` to the realm's task queue and bind
## it to the sim's event log. The `Task.id` is the
## dictionary key. Duplicate ids are a `push_error`
## no-op.
func add_task(t: Task) -> void:
	if t == null:
		push_error("Sim.add_task: task is null")
		return
	if tasks.has(t.id):
		push_error("Sim.add_task: task id %s is already in the queue" % String(t.id))
		return
	t.bind_event_log(event_log)
	tasks[t.id] = t


## Add a `Crisis` to the realm's crisis queue and
## bind it to the sim's event log. The `Crisis.id`
## is the dictionary key. Duplicate ids are a
## `push_error` no-op.
func add_crisis(cr: Crisis) -> void:
	if cr == null:
		push_error("Sim.add_crisis: crisis is null")
		return
	if crises.has(cr.id):
		push_error("Sim.add_crisis: crisis id %s is already in the queue" % String(cr.id))
		return
	cr.bind_event_log(event_log)
	crises[cr.id] = cr


## Register the realm's exploration map. The
## `register_exploration` call binds the map to
## the sim; the per-tick rule (step 7a, M3)
## reads the map and advances the exploration.
## Passing `null` unregisters the map. The
## method does NOT validate the map (a
## registration of a `null` map is a
## legitimate unregister; a registration of a
## non-`ExplorationMap` value is a caller error
## that the per-tick rule surfaces as a no-op).
##
## The M2 contract is preserved: a `Sim` that
## has never had `register_exploration` called
## has `exploration_map == null`; the per-tick
## rule treats that as a no-op (the existing M2
## tests continue to pass).
func register_exploration(map) -> void:
	exploration_map = map


## M3 cycle 2 (Track B) anchor registry. Binds
## the realm's narrative-anchor set so the
## per-tick step 7b can fire the trigger
## rule. `null` is a no-op (the M2 contract is
## preserved: a sim that has never had this
## called behaves exactly as the M2 tests
## expect).
func register_anchors(anchors_v) -> void:
	narrative_anchors = anchors_v


## M3 cycle 2 (Track A) exploration step. The
## method is a thin wrapper over
## `ExplorationStep.run(self, delta_days,
## inhabitants, exploration_map, true)`. The
## implementation lives in `src/sim/
## exploration_step.gd`; the wrapper is here
## so the per-tick hook in `tick`'s step 7a
## can call the same code path with
## `advance_time = false` (and so the
## `sim.gd` file stays under the 1000-line
## cap the lint check enforces).
func explore(delta_days: float, inhabitants: Array, exploration_map_v) -> void:
	if delta_days <= 0.0:
		push_error("Sim.explore: delta_days must be positive (got %f)" % delta_days)
		return
	ExplorationStep.run(self, delta_days, inhabitants, exploration_map_v, true)


## Internal exploration step. Called from
## `tick`'s step 7a with `advance_time = false`
## (the standard `time_days += delta_days` at
## the end of `tick` is the single source of
## truth for the clock). The wrapper is the
## thin layer that routes to
## `ExplorationStep.run`.
func _exploration_step(
	delta_days: float, inhabitants: Array, exploration_map_v, advance_time: bool
) -> void:
	ExplorationStep.run(self, delta_days, inhabitants, exploration_map_v, advance_time)


## Tick the simulation forward by `delta_days`. Pure
## function on `inhabitants` + `events` + the sim's
## private RNG state. The body fills in the six steps
## pinned by ADR-0005 in exactly this order:
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
##   6. Contract eval    — breach every active `Contract`
##                          whose terms are violated; append
##                          a `contract.breach` event.
##   7. Crisis eval      — trigger every untriggered
##                          crisis whose `condition` fires;
##                          resolve every triggered crisis
##                          whose choice has been picked.
##   8. Event-log append — the tick's events are already
##                          in the log (subsystems append
##                          as they fire); step 6 of ADR-0005
##                          is the post-condition that every
##                          event has a matching log row.
##
## After step 8, the sim's `time_days` is advanced by
## `delta_days` and the tick returns.
##
## Determinism contract (ADR-0005):
##   * `delta_days` is the only parameter that varies
##     across a sequence of ticks; the seed and the
##     `inhabitants` and `events` arrays are the same.
##   * Two `Sim` instances constructed with the same seed
##     and ticked with the same `delta_days` and the same
##     `inhabitants` / `events` arguments produce deep-equal
##     state at every tick.
##
## Pre-conditions:
##   * `delta_days > 0.0` — a tick of zero or negative
##     length is a programmer error.
##   * `inhabitants` is an `Array` of `Inhabitant`
##     instances (typed as `Array` for now).
##   * `events` is an `Array` of `EventEntry` dicts
##     (typed as `Array` for now).
##
## Post-conditions:
##   * `time_days` is advanced by `delta_days`.
##   * `inhabitants` and `events` are mutated *only* in
##     the ways the tick's eight steps specify.
func tick(delta_days: float, inhabitants: Array, events: Array) -> void:
	assert(delta_days > 0.0, "Sim.tick: delta_days must be positive (got %f)" % delta_days)
	assert(inhabitants != null, "Sim.tick: inhabitants array is null")
	assert(events != null, "Sim.tick: events array is null")

	# 1. RNG draw. The M2 Track A inhabitants side
	#    does not pull random values directly into
	#    `Sim.tick()`; the inhabitants read the
	#    per-tick RNG through the handle passed to
	#    `Inhabitant.tick()`. The sim owns the
	#    state, the inhabitants read it.

	# 2. Needs decay (Track A). Every inhabitant's
	#    `Needs` are decayed by
	#    `TUNING_NEED_DECAY_PER_DAY * delta_days`.
	#    The sim's step 2 walks the inhabitants
	#    array; absent and deceased inhabitants
	#    are no-ops (the per-inhabitant `tick()`
	#    short-circuits on `state != STATE_ALIVE`).
	_advance_inhabitants(delta_days, inhabitants, null, _rng)

	# 3. Task progress. Every open task advances its
	#    progress. Tasks with `progress >= 1.0` complete
	#    in the same tick (the completion appends a
	#    `task.completed` event to the log).
	_advance_tasks(delta_days)

	# 4. Event-memory recording. The tick's events
	#    (from the input `events` array plus any
	#    events the tasks / contracts / crises
	#    appended in this tick) are recorded into
	#    each affected inhabitant's `EventMemory`.
	_record_tick_events(time_days, inhabitants, events)

	# 5. Relationships update. Each pair of
	#    affected inhabitants linked by a
	#    cooperative or conflict event in the
	#    input `events` array (or in the events
	#    appended by the task/contract/crisis
	#    steps in this tick) has the
	#    corresponding `Relationship` edge
	#    nudged and the per-tick drift applied.
	_update_relationships(delta_days, events)

	# 6. Contract evaluation. Every active contract is
	#    checked against the realm's current state. A
	#    standard pact is breached when `food_share`
	#    is `false` (the realm has stopped feeding
	#    its inhabitants) or when `lodging` is
	#    `false`. The `breach()` call appends a
	#    `contract.breach` event to the log. The
	#    `delta_days` is forwarded so the helper
	#    records the *end-of-tick* clock in the
	#    `breach_at_day` and the event log.
	_evaluate_contracts(delta_days)

	# 7. Crisis evaluation. Every untriggered crisis
	#    whose `condition` fires (and whose
	#    `trigger_at_day` is in the past) is
	#    triggered. Triggered crises whose `choice`
	#    has been picked by the player (or whose
	#    deadline has passed) are resolved. The
	#    `trigger()` and `resolve()` calls append
	#    events to the log. The `delta_days`
	#    argument is forwarded so the helper can
	#    compare against the *end-of-tick* clock
	#    (`time_days + delta_days`), which is the
	#    value the event log's `time_days` field
	#    will record.
	_evaluate_crises(delta_days)

	# 7a. Exploration step (M3 cycle 2 Track A).
	#     The step is a no-op if the realm has no
	#     `ExplorationMap` registered (the M2
	#     contract is preserved: a sim that has
	#     never had `register_exploration` called
	#     continues to behave exactly as the M2
	#     tests expect). The step is also a no-op
	#     if the realm is fully revealed. The
	#     step passes `advance_time = false` so
	#     the standard `time_days += delta_days`
	#     at the end of `tick` is the single
	#     source of truth for the realm's clock;
	#     the per-call cost is logged as an
	#     event for the UI.
	if exploration_map != null:
		_exploration_step(delta_days, inhabitants, exploration_map, false)

	# 7b. Narrative-anchor step (M3 cycle 2
	#     Track B). The step walks the registered
	#     anchor set and calls `trigger()` on every
	#     anchor whose `trigger_at_day` is in the
	#     past. The M2 contract is preserved: a
	#     sim that has never had `register_anchors`
	#     called continues to behave exactly as the
	#     M2 tests expect (the `narrative_anchors
	#     == null` check short-circuits the loop).
	if narrative_anchors != null:
		_trigger_anchors(time_days + delta_days)

	# 8. Event-log append is implicit — every
	#    subsystem that mutates state appends its
	#    own event in the same call.

	# Advance the clock.
	time_days += delta_days
	return


## Advance every open `Task`'s `progress`. A task
## whose `progress >= 1.0` is completed in the same
## tick. The M2 default is `has_inputs = true` for
## every tick; the M3+ content data overrides the
## per-task input requirement. The M2 cycle 3
## commit adds the per-task content lookup.
func _advance_tasks(delta_days: float) -> void:
	var post_tick_day: float = time_days + delta_days
	for t in tasks.values():
		if not (t is Task):
			continue
		if t.completed:
			continue
		t.tick(delta_days, true)
		if t.progress >= 1.0 and not t.completed:
			t.complete(post_tick_day)


## Evaluate every active `Contract`. The M2 default
## rule is:
##
##   * Breach when the realm's inhabitants are
##     missing the contract's `lodging` or
##     `food_share` terms. The M2 model is
##     "the realm as a whole has the flag on or
##     off"; a per-inhabitant rule lands with the
##     M3+ content pass.
##
## The rule reads the contract's `terms` directly;
## the per-tick evaluation does NOT mutate
## `terms`. The `breach()` call is idempotent: a
## second call on an already-breached contract is
## a no-op.
func _evaluate_contracts(delta_days: float) -> void:
	var post_tick_day: float = time_days + delta_days
	for c in contracts.values():
		if not (c is Contract):
			continue
		if c.breached:
			continue
		if not c.is_active(post_tick_day):
			continue
		# The realm's "has lodging" / "shares food"
		# flags are content-driven. The M2 default
		# reads them off the contract's `terms` —
		# the contract is the source of truth for
		# the realm's promise. A breach happens
		# when a `bool` term is `false`.
		var breached_any: bool = false
		for key in [&"lodging", &"food_share"]:
			var v: Variant = c.terms_for(key)
			if v == null:
				continue
			if v is bool and not bool(v):
				breached_any = true
				break
		if breached_any:
			c.breach(post_tick_day)


## Evaluate every `Crisis`. An untriggered crisis
## whose `condition(time_days)` returns `true` and
## whose `trigger_at_day` is in the past is
## triggered. A triggered crisis whose `chosen_id`
## is non-empty is resolved (the player has picked
## a choice in the UI; the sim applies the
## consequence in the same tick).
##
## The M2 default for the `FirstInspection` crisis
## is `condition = func(_t): return time_days >= 7.0`.
## The sim's own per-tick rule is "trigger when the
## realm's clock has reached the crisis's
## `trigger_at_day`"; the condition is consulted
## only for early-trigger overrides.
func _evaluate_crises(delta_days: float) -> void:
	# M3-Closeout (Track B): cache the
	# inhabitants for the duration of the
	# per-tick call. The cache is read by the
	# `apply_pending_effects` helper called
	# below; the cache is reset at the end of
	# `tick` to keep the `_evaluate_crises`
	# signature stable for any future caller
	# that does not pass inhabitants.
	_crisis_inhabitants = _crisis_tick_inhabitants
	_evaluate_crises_body(delta_days)
	_crisis_inhabitants = [] as Array


func _evaluate_crises_body(delta_days: float) -> void:
	var post_tick_day: float = time_days + delta_days
	for cr in crises.values():
		if not (cr is Crisis):
			continue
		if cr.resolved:
			continue
		if not cr.triggered:
			# Trigger when the *end-of-tick*
			# clock (`time_days + delta_days`)
			# has reached the crisis's
			# `trigger_at_day` AND the
			# crisis's `condition` (if any)
			# agrees. The end-of-tick clock
			# is the value the event log's
			# `time_days` field will
			# record, so the trigger and
			# the event's `time_days`
			# agree.
			if post_tick_day >= cr.trigger_at_day:
				if cr.condition.is_valid():
					if bool(cr.condition.call(post_tick_day)):
						cr.trigger(post_tick_day)
				else:
					cr.trigger(post_tick_day)
			continue
		# Triggered: resolve when the player has
		# picked a choice (`chosen_id` is set by
		# the realm façade / M5 UI binding). The
		# M2 default does NOT auto-resolve on
		# the trigger tick; the realm façade
		# applies the choice within a real
		# turn. The resolution records the
		# end-of-tick clock in the event log.
		if cr.chosen_id != &"":
			cr.resolve(post_tick_day, cr.chosen_id)
		# M3-Closeout (Track B): apply the
		# crisis's `pending_effects` to the
		# inhabitants. The call is the sim-facing
		# entry point that converts the
		# `BranchNode.terminal_effect` schema
		# (ADR-0008) into per-inhabitant state
		# nudges. The call is a no-op when the
		# crisis has no pending effects.
		if not cr.pending_effects.is_empty():
			cr.apply_pending_effects(post_tick_day, _crisis_inhabitants)


## M2 Track A: walk the inhabitants array and
## call `Inhabitant.tick(delta_days, world, rng)`
## on every ALIVE inhabitant. The inhabitants
## array is sorted by `id` ascending before the
## walk so the per-tick order is deterministic
## (the determinism-friendly default from
## ADR-0005's "what is *not* in the contract"
## section: the order *within* a step is pinned
## to alphabetical by id).
##
## The `world` and `rng` arguments are passed
## through to the inhabitant so M3+ can feed the
## room-membership / shelter query without
## changing the call site. The M2 default passes
## `null` for `world` (no room data yet) and the
## sim's own `_rng` for `rng` (per ADR-0005, the
## sim owns the RNG state; inhabitants read it).
func _advance_inhabitants(delta_days: float, inhabitants: Array, world, rng) -> void:
	# Pre-condition: inhabitants is non-null.
	# The tick body's `assert` already checks
	# this; the helper asserts again so a
	# direct call from a test surfaces the
	# failure at the helper, not the tick.
	if inhabitants == null:
		return
	# Sort by id ascending. The M2 contract
	# pins the order as a determinism-friendly
	# default; the sort is O(n log n) per
	# tick, which is acceptable for the M2
	# surface area (≤ a few hundred
	# inhabitants per realm).
	var sorted_inh: Array = inhabitants.duplicate()
	sorted_inh.sort_custom(func(x, y): return String(x.id) < String(y.id))
	for inh in sorted_inh:
		if not (inh is Inhabitant):
			continue
		inh.tick(delta_days, world, rng)
		# Step 2.5: apply the per-culture
		# morale/stress bias. The bias is
		# the per-culture *tilt*; it is
		# small enough that it never
		# dominates the need-driven
		# calculation.
		inh.apply_culture_bias(delta_days)


## M2 Track A: record the tick's events into
## each affected inhabitant's `EventMemory`.
## The `events` array is the union of (a) the
## input events the caller passed to `tick()`,
## and (b) any events the task / contract /
## crisis steps appended to the sim's
## `EventLog` in this tick. The function reads
## the log's tail (entries whose `time_days`
## is `>=` the tick's start) to find the
## just-appended events.
##
## Each event's `affected` list (a
## `PackedStringArray` of inhabitant ids) is
## walked; the event is recorded into each
## affected inhabitant's memory. The
## `EventMemory.record` call sorts by
## `time_days` and applies the per-cap
## eviction; the helper does not need to
## pre-sort.
func _record_tick_events(tick_start_days: float, inhabitants: Array, events: Array) -> void:
	if inhabitants == null or events == null:
		return
	# Build a `Dictionary` index of inhabitant
	# id -> inhabitant, so the per-event
	# affected-walk is O(1) per lookup. The
	# M2 surface area is small enough that the
	# O(n) build per tick is fine.
	var by_id: Dictionary = {}
	for inh in inhabitants:
		if not (inh is Inhabitant):
			continue
		by_id[String(inh.id)] = inh
	# Walk the events array. The events that
	# were *just* appended in this tick are
	# those with `time_days >= tick_start_days`;
	# the helper records them into the
	# affected inhabitants' memories.
	for ev in events:
		if ev == null or not (ev is Dictionary):
			continue
		var t: float = float(ev.get("time_days", 0.0))
		if t < tick_start_days:
			continue
		var affected: Variant = ev.get("affected", PackedStringArray())
		if not (affected is PackedStringArray):
			continue
		for aid in affected:
			var inh: Variant = by_id.get(String(aid), null)
			if inh == null or not (inh is Inhabitant):
				continue
			# Record into the inhabitant's
			# memory. The `record` call
			# returns `false` if the entry
			# is malformed; the helper
			# silently skips the failure
			# (the M2 contract pins a
			# best-effort recording: a
			# malformed event does not
			# abort the tick).
			(inh as Inhabitant).memory.record(ev)


## M2 Track A: apply the per-tick relationship
## updates. For each event in the `events`
## array, find the pairs of affected
## inhabitants and call `Relationship.register`
## on the corresponding edge. After the
## per-event pass, every edge in the
## `relationships` graph has the per-tick
## `drift(delta_days)` applied.
##
## The helper is intentionally permissive: an
## event with fewer than two affected
## inhabitants is a no-op; an event whose
## affected pair has no edge yet is a no-op
## (the helper does *not* auto-create edges
## from event data; the realm façade's
## add_relationship method is the canonical
## edge-insertion path).
func _update_relationships(delta_days: float, events: Array) -> void:
	if events == null:
		return
	# Per-event pass: nudge the affinity of
	# each affected pair. The pair is the
	# Cartesian product of the affected
	# list; a two-element affected list
	# produces one pair; a three-element
	# list produces three pairs; a
	# one-element list produces zero pairs.
	for ev in events:
		if ev == null or not (ev is Dictionary):
			continue
		var t: float = float(ev.get("time_days", 0.0))
		if t < time_days:
			# Only events whose time_days is
			# at-or-after the current
			# `time_days` are "this tick's"
			# events. The helper is
			# defensive: the tick body's
			# step 5 happens *after* the
			# per-tick event appends, so
			# the events array can contain
			# earlier-tick entries that
			# the caller pre-loaded.
			continue
		var affected_v: Variant = ev.get("affected", PackedStringArray())
		if not (affected_v is PackedStringArray):
			continue
		var affected: PackedStringArray = affected_v
		if affected.size() < 2:
			continue
		var ev_id: StringName = StringName(String(ev.get("id", &"")))
		var ev_kind: StringName = StringName(String(ev.get("kind", &"")))
		for i in range(affected.size()):
			for j in range(i + 1, affected.size()):
				var a: StringName = StringName(affected[i])
				var b: StringName = StringName(affected[j])
				var edge_id: StringName = _canonical_edge_id(a, b)
				if not relationships.has(edge_id):
					# No edge yet: skip. The
					# realm façade's
					# add_relationship is
					# the canonical
					# edge-insertion path;
					# the per-tick helper
					# does not auto-create.
					continue
				var rel: Variant = relationships[edge_id]
				if rel is Relationship:
					(rel as Relationship).register(ev_id, ev_kind, 0.0)
	# Per-tick drift pass: every edge in
	# the graph drifts toward `0.0` at
	# `TUNING_RELATIONSHIP_DRIFT_PER_DAY *
	# delta_days`. The drift is symmetric;
	# a positive affinity drifts down, a
	# negative drifts up. The pass is
	# O(|edges|).
	for rel in relationships.values():
		if rel is Relationship:
			(rel as Relationship).drift(delta_days)


## M2 Track A: compute the canonical edge id
## for a pair of inhabitant ids. The canonical
## id is the lexicographically-sorted pair
## joined by the U+0001 SEPARATOR character.
## The separator is a non-printable control
## character that cannot appear in a
## `StringName` id, so the join is unambiguous
## (`"a" + U+0001 + "b"` is distinct from
## `"a_b"` or any pair the realm's id
## generator could produce).
##
## Used by `_update_relationships` to look up
## the per-pair edge in the `relationships`
## graph. The function is also exposed (with
## the `_` prefix) so the realm façade's
## `add_relationship` method can use the
## same canonicalisation; the contract is
## the same on both sides.
func _canonical_edge_id(a: StringName, b: StringName) -> StringName:
	var sa: String = String(a)
	var sb: String = String(b)
	var sep: String = char(1)
	if sa <= sb:
		return StringName(sa + sep + sb)
	return StringName(sb + sep + sa)


## M2 Track A: add a `Relationship` edge to
## the graph. The pair is canonicalised so
## `(a, b)` and `(b, a)` resolve to the same
## edge. Adding a duplicate edge is a
## `push_error` no-op (the realm façade would
## have caught the duplicate before calling).
func add_relationship(rel: Relationship) -> void:
	if rel == null:
		push_error("Sim.add_relationship: relationship is null")
		return
	var edge_id: StringName = _canonical_edge_id(rel.a, rel.b)
	# Re-canonicalise the (a, b) pair on the
	# edge so the stored relationship
	# matches the key. The `Relationship`
	# class does not enforce the canonical
	# ordering on construction; the sim is
	# the authority.
	if String(rel.a) > String(rel.b):
		var tmp_a: StringName = rel.a
		var tmp_b: StringName = rel.b
		rel.a = tmp_b
		rel.b = tmp_a
	if relationships.has(edge_id):
		push_error("Sim.add_relationship: edge %s is already in the graph" % String(edge_id))
		return
	relationships[edge_id] = rel


## Return the M2 Track A version tag. The
## value is a string rather than a numeric
## constant so the version can be derived
## from a single source of truth in a later
## milestone. The Track A commit increments
## from the M2-Track-B tag to mark the
## inhabitant wiring landing in this branch.
static func version() -> String:
	return _VERSION


## M3 cycle 2 (Track B) anchor trigger helper.
## Walks the registered anchor set and calls
## `trigger()` on every anchor whose
## `trigger_at_day` is at or before the
## end-of-tick clock. Anchors with
## `trigger_at_day < 0.0` (location-gated) are
## NOT auto-triggered here; the realm façade
## triggers them when the player reaches the
## anchor's tile. The `post_tick_day` argument
## is the *end-of-tick* clock (`time_days +
## delta_days`), the same value the event log's
## `time_days` field will eventually store, so
## the trigger and the log agree.
func _trigger_anchors(post_tick_day: float) -> void:
	if narrative_anchors == null:
		return
	var anchors_v: Array = []
	var raw: Variant = narrative_anchors
	if raw is Array:
		anchors_v = raw
	elif raw is Dictionary:
		anchors_v = (raw as Dictionary).values()
	for a in anchors_v:
		if not (a is NarrativeAnchor):
			continue
		if a.triggered:
			continue
		if a.trigger_at_day < 0.0:
			continue
		if post_tick_day >= a.trigger_at_day:
			a.trigger()
