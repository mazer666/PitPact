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

## Reference to the sim's event log. The crisis
## only writes to the log in `trigger()` and
## `resolve()`; the reference is held weakly
## (the sim owns the log).
var _event_log: EventLog = null


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
