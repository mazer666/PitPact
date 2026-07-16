# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — crisis data carrier (M2 Track B).
#
# `Crisis` is the per-crisis data carrier for the
# realm's crisis queue. A crisis is a timed,
# branching, player-influenced event that threatens
# the realm's existence if not resolved. §11 of
# `docs/requirements.md` requires two major crises
# in the first public release; the M2 Track B
# commit ships the first one (`FirstInspection`).
#
# A `Crisis` wraps a `Condition` (a `Callable` that
# returns `true` when the crisis should trigger) and
# a list of `Choice`s (plain `Dictionary` records
# the player picks from). The condition is invoked
# once per tick by the sim; when it returns `true`
# and `time_days >= trigger_at_day`, the crisis
# transitions to *triggered* state and the player
# can pick a choice.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name Crisis
extends RefCounted

## The M2 default timeout, in in-game days. The
## default is a `const` on the class so the M2
## skeleton has a documented timeout even before
## the per-crisis overrides land.
const DEFAULT_TIMEOUT_DAYS: float = 7.0

## M4-Closeout: the default deadline (in
## in-game days) for the
## `autonomous_resolution_days` field.
const DEFAULT_AUTONOMOUS_RESOLUTION_DAYS: float = 14.0

## The crisis's stable identity. `StringName` for
## the same reasons as `Inhabitant.id`. The id is
## what the event log (`crisis.triggered` and
## `crisis.resolved` events carry it) keys off.
var id: StringName = &""

## The in-game day the crisis is scheduled to
## trigger. The value is the realm's `time_days`
## at the tick the crisis was scheduled; the
## trigger happens at the *next* tick whose
## `time_days >= trigger_at_day`. The per-tick
## check evaluates `condition(time_days)` and
## the early-trigger return.
var trigger_at_day: float = 0.0

## The condition that triggers the crisis. The
## signature is `func(time_days: float) -> bool`.
## The condition returns `true` when the crisis
## should fire *now* (the per-tick rule combines
## the boolean with `time_days >=
## trigger_at_day`). The default value is a
## no-op `Callable` (always returns `false`);
## content-driven crises replace it with the
## real check.
##
## The `time_days` argument is the realm's
## `time_days` *at the end of the tick* (post
## step 6 in ADR-0005), so the condition sees
## the same value the event log will eventually
## store. This is what makes the trigger
## reproducible.
var condition: Callable = Callable()

## The crisis's player choices, as an `Array` of
## `Choice` dicts. The `Choice` shape is a plain
## `Dictionary` with the canonical keys
## `id` (StringName), `display_name` (StringName
## locale key), `consequence_summary` (StringName
## locale key for the event-log summary), and
## `effect` (a `Callable` the sim invokes when
## the player picks the choice; the M2 default
## is a no-op `Callable`).
var choices: Array = []

## Whether the crisis has been resolved. The
## `resolved` flag is set by the sim's per-tick
## crisis-resolution rule when the player picks
## a choice (or when the crisis expires). Once
## `resolved` is `true`, the crisis is removed
## from the active crisis queue.
var resolved: bool = false

## The in-game day the crisis was resolved on.
## `0.0` while `resolved` is `false`. The value
## is set by `resolve()` to the realm's
## `time_days` at the end of the resolution
## tick.
var resolved_at_day: float = 0.0

## Whether the crisis has been triggered. A
## crisis is *triggered* between the moment the
## condition fires and the moment the player
## picks a choice (or the crisis expires).
## Triggered-but-unresolved crises are
## rendered in the UI's "pending crises" panel
## (M5+).
var triggered: bool = false

## The id of the choice the player picked.
## `&""` until `resolve()` is called. The
## value is what the event log's
## `crisis.choice_made` event carries.
var chosen_id: StringName = &""

## M3-Closeout (Track B): pending terminal
## effect, applied by the sim at the end of the
## resolution tick. The dictionary mirrors the
## `BranchNode.terminal_effect` schema
## (ADR-0008). Supported keys:
##
##   * `"morale_delta"` (float, range `[-1, 1]`)
##     — the per-inhabitant morale nudge the
##     sim applies on `apply_pending_effect`.
##   * `"needs_food_delta"` (float, range
##     `[-1, 1]`) — per-inhabitant food-need
##     nudge (positive = "the realm is fed",
##     negative = "the realm goes hungry").
##   * `"follow_up_anchor_id"` (StringName) —
##     the id of a follow-up narrative anchor
##     the sim will mark as resolved at the
##     same time, so the UI can chain the two
##     stories.
##
## The dictionary is empty by default; the
## `resolve_branch` call populates it from the
## `BranchNode.terminal_effect` of the chosen
## terminal node.
var pending_effects: Dictionary = {}

## Reference to the sim's event log. The crisis
## only writes to the log in `trigger()` and
## `resolve()`; the reference is held weakly
## (the sim owns the log).

## M4-Closeout: the deadline (in in-game
## days) after which the sim auto-resolves
## a triggered-but-unresolved crisis with
## the first `default_choice` (or with
## `&""` when no choice has been picked).
## The M4 default is
## `DEFAULT_AUTONOMOUS_RESOLUTION_DAYS`
## (`14.0`); the M4 content catalogue
## overrides this per-crisis (e.g.
## `plague_outbreak` = 14.0,
## `faction_dispute` = 14.0). The field
## is the canonical ADR-0011 entry point.
var autonomous_resolution_days: float = DEFAULT_AUTONOMOUS_RESOLUTION_DAYS

## M4-Closeout: the day the crisis was
## triggered. The sim reads this to
## compute the autonomous-resolution
## deadline. The field is `0.0` until
## `trigger()` is called.

## M4-Closeout: the `&"paused"` /
## `&"resolved"` / `&"default"` flag the
## sim's per-tick rule reads when
## auto-resolving. The default is `&""`
## (no autonomous outcome yet).
var autonomous_outcome: StringName = &""

## M4-Closeout: per-crisis data the
## content catalogue sets. The M4
## closeout keys are `sealable: bool`
## (the `seal_breach` Pactmaker power
## targets these) and `pausable: bool`
## (the `pause_crisis` Pactmaker power
## targets these). The default is `{}`
## (no flags).
var data: Dictionary = {}

## Reference to the sim's event log. The crisis
## only writes to the log in `trigger()` and
## `resolve()`; the reference is held weakly
## (the sim owns the log).
var _event_log: EventLog = null
## M4-Closeout: the day the crisis was
## triggered. The sim reads this to
## compute the autonomous-resolution
## deadline. The field is `0.0` until
## `trigger()` is called.
var _triggered_at_day: float = 0.0
## Default constructor. Starts with empty
## fields, a no-op `condition`, an empty
## `choices` array, and `resolved = false`.


func _init() -> void:
	id = &""
	trigger_at_day = 0.0
	condition = Callable()
	choices = []
	resolved = false
	resolved_at_day = 0.0
	triggered = false
	chosen_id = &""
	_event_log = null
	pending_effects = {}


## Construct a crisis with the canonical
## `(id, trigger_at_day, condition, choices)`
## tuple. The `event_log` argument is optional;
## when supplied, `trigger()` and `resolve()`
## will append events to the log.
static func make(
	p_id: StringName,
	p_trigger_at_day: float,
	p_condition: Callable,
	p_choices: Array,
	p_event_log: EventLog = null
) -> Crisis:
	var cr: Crisis = Crisis.new()
	cr.id = p_id
	cr.trigger_at_day = p_trigger_at_day
	cr.condition = p_condition
	cr.choices = p_choices
	if p_event_log != null:
		cr._event_log = p_event_log
	return cr


## Bind the event log this crisis should write
## `crisis.triggered` and `crisis.resolved` events
## to. The sim calls this once after construction
## so crises do not have to know about the sim's
## internal log layout.
func bind_event_log(p_event_log: EventLog) -> void:
	_event_log = p_event_log


## Trigger the crisis at `time_days`. Sets
## `triggered = true` and appends a
## `crisis.triggered` event to the bound
## `EventLog` (if one is bound). Calling
## `trigger()` on an already-triggered crisis
## is a no-op. The `time_days` argument is the
## realm's `time_days` at the *end* of the
## trigger tick (post step 6 in ADR-0005), so
## the value is reproducible.
func trigger(time_days: float) -> void:
	if triggered:
		return
	triggered = true
	_triggered_at_day = time_days
	if _event_log == null:
		return
	var entry: Dictionary = {
		"id": StringName(String(id) + ".triggered"),
		"time_days": time_days,
		"kind": &"crisis.triggered",
		"summary": &"EVENT_CRISIS_TRIGGERED",
		"affected": PackedStringArray(),
		"crisis_id": id,
	}
	_event_log.append(entry)


## Resolve the crisis at `time_days` by
## picking the choice with id `pick_id`.
## Invokes the choice's `effect` Callable (if
## any), sets `resolved = true`,
## `resolved_at_day = time_days`,
## `chosen_id = pick_id`, and appends a
## `crisis.choice_made` event to the bound
## `EventLog` (if one is bound). The
## `affected` list of the event is the union
## of any ids the effect's return value
## names; the M2 default effects return an
## empty list (the sim fills the list from
## the realm's inhabitants, not from the
## effect).
func resolve(time_days: float, pick_id: StringName) -> void:
	if resolved:
		return
	resolved = true
	resolved_at_day = time_days
	chosen_id = pick_id
	# Find the choice, invoke its effect.
	var choice_effect: Callable = Callable()
	for c in choices:
		if not (c is Dictionary):
			continue
		if StringName(String(c.get("id", &""))) == pick_id:
			var eff: Variant = c.get("effect", Callable())
			if eff is Callable:
				choice_effect = eff
			break
	if choice_effect.is_valid():
		choice_effect.call(time_days, self)
	if _event_log == null:
		return
	var entry: Dictionary = {
		"id": StringName(String(id) + "." + String(pick_id)),
		"time_days": time_days,
		"kind": &"crisis.choice_made",
		"summary": &"EVENT_CRISIS_CHOICE_MADE",
		"affected": PackedStringArray(),
		"crisis_id": id,
		"choice_id": pick_id,
	}
	_event_log.append(entry)


## M3 cycle 2 (Track B) branching-event
## resolution. The method records the player's
## pick on the crisis and (optionally) appends
## a `branch.resolved` event to the log. The
## `pick_id` is the StringName of the chosen
## `BranchNode` (or, for the M2-style choices,
## the StringName of the chosen `choice.id`;
## the resolver accepts both). The `branch_id`
## is the StringName of the originating branch
## root (or `&""` for M2-style choices that
## have no branch tree). The `terminal_effect`
## argument is a `Dictionary` of effect-tag /
## effect-value pairs (per ADR-0008); the
## resolver copies the dictionary into
## `pending_effects` so the sim can apply it at
## the end of the resolution tick.
func resolve_branch(
	time_days: float,
	pick_id: StringName,
	branch_id: StringName = &"",
	terminal_effect: Dictionary = {}
) -> void:
	if resolved:
		return
	resolved = true
	resolved_at_day = time_days
	chosen_id = pick_id
	pending_effects = terminal_effect.duplicate(true)
	if _event_log == null:
		return
	var entry: Dictionary = {
		"id": StringName(String(id) + ".branch." + String(pick_id)),
		"time_days": time_days,
		"kind": &"branch.resolved",
		"summary": &"EVENT_BRANCH_RESOLVED",
		"affected": PackedStringArray(),
		"crisis_id": id,
		"choice_id": pick_id,
		"branch_id": branch_id,
		"terminal_effect": pending_effects,
	}
	_event_log.append(entry)


## M3-Closeout (Track B): apply the
## `pending_effects` dictionary to the
## `inhabitants` array. The method is the
## sim-facing entry point that converts the
## `BranchNode.terminal_effect` schema into
## per-inhabitant state nudges. The method is
## idempotent: a second call on the same crisis
## is a no-op (the `pending_effects` dictionary
## is consumed and cleared).
##
## The supported keys (per the field's
## docstring above) are applied in this order:
##   1. `morale_delta` (float) — the method
##      stores the delta on each inhabitant's
##      `morale` scalar directly. The M3 default
##      is "transient delta" — the value decays
##      back to the natural value on the next
##      `tick()` call (the per-tick morale rule
##      recomputes from needs). The M3-Closeout
##      pins the delta's *sign* in the event log
##      for the UI to display; the value is
##      available for the same tick only.
##   2. `needs_food_delta` (float) — a direct
##      nudge on each inhabitant's
##      `needs.food`. This delta is *persistent*
##      (food does not auto-recover).
##   3. `follow_up_anchor_id` (StringName) — a
##      follow-up anchor id the method appends
##      to the event log as
##      `narrative.anchor_followup` so the UI
##      can chain the two stories.
##
## The method is a no-op when `pending_effects`
## is empty or when `inhabitants` is empty. The
## method does NOT write to the event log
## itself; the sim calls it after `_evaluate_crises`
## so the per-effect event lands in the same
## tick as the resolution.
func apply_pending_effects(time_days: float, inhabitants: Array) -> void:
	if pending_effects.is_empty():
		return
	if inhabitants == null or inhabitants.is_empty():
		return
	var morale_delta: float = float(pending_effects.get("morale_delta", 0.0))
	var needs_food_delta: float = float(pending_effects.get("needs_food_delta", 0.0))
	var follow_up_anchor_id: StringName = StringName(
		String(pending_effects.get("follow_up_anchor_id", &""))
	)
	for inh in inhabitants:
		if not (inh is Inhabitant):
			continue
		if morale_delta != 0.0:
			inh.morale.morale = clampf(inh.morale.morale + morale_delta, -1.0, 1.0)
		if needs_food_delta != 0.0:
			inh.needs.food = clampf(inh.needs.food + needs_food_delta, 0.0, 1.0)
	if _event_log != null and (morale_delta != 0.0 or needs_food_delta != 0.0):
		var entry: Dictionary = {
			"id": StringName(String(id) + ".effects"),
			"time_days": time_days,
			"kind": &"crisis.effects_applied",
			"summary": &"EVENT_CRISIS_EFFECTS_APPLIED",
			"affected": PackedStringArray(),
			"crisis_id": id,
			"morale_delta": morale_delta,
			"needs_food_delta": needs_food_delta,
		}
		_event_log.append(entry)
	if _event_log != null and String(follow_up_anchor_id) != "":
		var fentry: Dictionary = {
			"id": StringName(String(id) + ".followup"),
			"time_days": time_days,
			"kind": &"narrative.anchor_followup",
			"summary": &"EVENT_NARRATIVE_ANCHOR_FOLLOWUP",
			"affected": PackedStringArray(),
			"crisis_id": id,
			"anchor_id": follow_up_anchor_id,
		}
		_event_log.append(fentry)
	pending_effects = {}


## M4-Closeout: whether the crisis is past
## its autonomous-resolution deadline. The
## method returns `true` when the crisis is
## triggered-but-unresolved and the current
## time minus `_triggered_at_day` is at or
## above `autonomous_resolution_days`. A
## crisis with `autonomous_outcome ==
## &"paused"` is exempt (the player
## explicitly paused it; the M4 default
## is "no auto-resolve while paused").
##
## The M4 closeout default is "strict
## gate": a `null` self is a `push_error`
## no-op that returns `false`.
func is_autonomous_deadline_reached(time_days: float) -> bool:
	if not triggered:
		return false
	if resolved:
		return false
	if autonomous_outcome == &"paused":
		return false
	return (time_days - _triggered_at_day) >= autonomous_resolution_days


## M4-Closeout: auto-resolve the crisis.
## The method sets `resolved = true`,
## `resolved_at_day = time_days`,
## `autonomous_outcome = &"default"`,
## and picks the choice with
## `is_default = true` (or `&""` when no
## choice has the flag). The method is
## the canonical "the player did not
## pick in time" mutation path; the
## sim's per-tick rule calls this when
## `is_autonomous_deadline_reached(...)`
## is `true`.
##
## The method appends a
## `crisis.autonomous_resolved` event
## to the bound `EventLog` (if one is
## bound). The M4 default is "strict
## gate": a `null` self is a `push_error`
## no-op that returns `&""`.
func autonomous_resolve(time_days: float) -> StringName:
	if resolved:
		return chosen_id
	if not triggered:
		return &""
	autonomous_outcome = &"default"
	# Pick the first default choice, or
	# `&""` when no choice is flagged.
	var pick: StringName = &""
	for c in choices:
		if c == null or not (c is Dictionary):
			continue
		if bool((c as Dictionary).get("is_default", false)):
			pick = StringName(String((c as Dictionary).get("id", &"")))
			break
	resolved = true
	resolved_at_day = time_days
	chosen_id = pick
	if _event_log != null:
		(
			_event_log
			. append(
				{
					"id": StringName(String(id) + ".autonomous_resolved"),
					"time_days": time_days,
					"kind": &"crisis.autonomous_resolved",
					"summary": &"EVENT_CRISIS_AUTONOMOUS_RESOLVED",
					"affected": PackedStringArray(),
					"crisis_id": id,
					"chosen_id": pick,
				}
			)
		)
	return pick
