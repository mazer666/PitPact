# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — task data carrier (M2 Track B).
#
# `Task` is the per-task data carrier for the realm's
# task queue. A task is a unit of work assigned to an
# inhabitant: build a room, deliver a resource, scout
# a region, research a topic. Tasks are issued by the
# player (through the realm façade) and by the
# simulation itself (e.g. auto-repair after a
# crisis). The M2 foundation shipped the field-only
# skeleton; this commit fills in the per-tick
# progress rule (step 3 in ADR-0005), the
# `assign()` mutator, the `tick()` method, and the
# `complete()` mutator.
#
# Tasks are in-world objects; the assignment is by
# inhabitant id, not by zone. The M3+ zone model
# adds a `zone: Vector2i` for spatial pinning; for
# M2 the inhabitant-id assignment is the only
# required coordinate.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name Task
extends RefCounted

## Per-tick progress rate when the assigned
## inhabitant has all required inputs on hand
## (a `has_inputs` of `true` in `tick()`). The
## baseline is a content-defined constant; the
## M2 default is 0.1 (`progress += 0.1 *
## delta_days` when `has_inputs` is true). The
## M3+ content data overrides the rate per task
## type; the M2 skeleton ships the default.
const PROGRESS_PER_DAY_WITH_INPUTS: float = 0.10

## Per-tick progress rate when the assigned
## inhabitant is missing one or more required
## inputs. The M2 default is 0.04
## (significantly slower — the inhabitant
## either waits, improvises, or stops). The
## "no inputs" rate is content-tunable but
## always strictly less than the
## "with inputs" rate; the M2 ratio is
## roughly 0.4.
const PROGRESS_PER_DAY_WITHOUT_INPUTS: float = 0.04

## The task's stable identity. `StringName` for
## the same reasons as `Inhabitant.id`. The id is
## what the event log (`task.completed` events
## carry it) and the relationship history key
## off.
var id: StringName = &""

## The inhabitant the task is assigned to, as an
## inhabitant id (`StringName`). A `&""` value
## means "unassigned"; the realm façade's auto-
## assigner (M3+) fills this in. Tasks assigned to
## an absent or deceased inhabitant are no-ops in
## step 3 of ADR-0005.
var assigned_to: StringName = &""

## The task's progress, in `[0.0, 1.0]`. `0.0`
## is "not started", `1.0` is "complete". A
## task whose `progress` reaches `1.0` is
## considered complete and emits a
## `task.completed` event into the event log
## (ADR-0005 step 6) in the same tick.
var progress: float = 0.0

## The in-game day the task was started. The
## value is the realm's `time_days` at the tick
## the task was issued; a task issued by the
## player outside a tick records the realm's
## current `time_days`. The field is what the
## UI's "task age" badge reads.
var started_at_day: float = 0.0

## Whether the task has been completed. Set by
## `complete()`; the per-tick rule never advances
## a completed task. The M2 model does NOT
## re-queue a completed task; the realm façade
## creates a new `Task` instance for the next
## iteration.
var completed: bool = false

## Reference to the sim's event log. The task
## only writes to the log in `complete()`; the
## reference is held weakly (the sim owns the
## log).
var _event_log: EventLog = null


## Default constructor. Starts with empty
## fields and `0.0` progress.
func _init() -> void:
	id = &""
	assigned_to = &""
	progress = 0.0
	started_at_day = 0.0
	completed = false
	_event_log = null


## Construct a task with the canonical
## `(id, assigned_to, started_at_day)` triple.
## The `event_log` argument is optional; when
## supplied, `complete()` will append a
## `task.completed` event to the log.
static func make(
	p_id: StringName,
	p_assigned_to: StringName,
	p_started_at_day: float,
	p_event_log: EventLog = null
) -> Task:
	var t: Task = Task.new()
	t.id = p_id
	t.assigned_to = p_assigned_to
	t.started_at_day = p_started_at_day
	if p_event_log != null:
		t._event_log = p_event_log
	return t


## Bind the event log this task should write
## `task.completed` events to. The sim calls
## this once after construction so tasks do
## not have to know about the sim's internal
## log layout.
func bind_event_log(p_event_log: EventLog) -> void:
	_event_log = p_event_log


## Assign (or re-assign) the task to
## `inhabitant_id`. Setting `assigned_to` to
## `&""` unassigns the task; the per-tick rule
## treats an unassigned task as paused (no
## progress). Re-assignment is allowed; the
## task does not reset `progress` (the new
## assignee inherits the prior work).
func assign(inhabitant_id: StringName) -> void:
	assigned_to = inhabitant_id


## Advance the task's progress by `delta_days`
## in-game days. Progress is faster when
## `has_inputs` is `true`. The progress delta
## is a content-defined function of the task
## type, the assigned inhabitant's
## `Needs`, and the available tools; the M2
## default is the two-`const` rates above.
## A completed task (`completed == true`) is
## a no-op; the per-tick rule never advances
## a finished task.
##
## When the task's `progress` reaches `1.0`
## the task is *not* completed here — the
## caller is expected to call `complete()` in
## the same tick (the sim's `tick()` body
## does this in step 6). The split is what
## the M2 contract pins: `tick()` advances
## progress; `complete()` is the side-effect-
## bearing mutator.
func tick(delta_days: float, has_inputs: bool) -> void:
	if completed:
		return
	if assigned_to == &"":
		return
	var rate: float = PROGRESS_PER_DAY_WITH_INPUTS
	if not has_inputs:
		rate = PROGRESS_PER_DAY_WITHOUT_INPUTS
	progress = min(1.0, progress + rate * delta_days)


## Mark the task as complete at `time_days`.
## Sets `completed = true`, clamps
## `progress` to `1.0`, and appends a
## `task.completed` event to the bound
## `EventLog` (if one is bound). Calling
## `complete()` on an already-completed task
## is a no-op (the append-only log must not
## see duplicate `task.completed` events).
## The `time_days` argument is the realm's
## `time_days` at the *end* of the
## completion tick (post step 6 in
## ADR-0005), so the value is reproducible.
func complete(time_days: float) -> void:
	if completed:
		return
	completed = true
	progress = 1.0
	if _event_log == null:
		return
	var affected: PackedStringArray = PackedStringArray()
	if assigned_to != &"":
		affected.append(String(assigned_to))
	var entry: Dictionary = {
		"id": StringName(String(id) + ".completed"),
		"time_days": time_days,
		"kind": &"task.completed",
		"summary": &"EVENT_TASK_COMPLETED",
		"affected": affected,
	}
	_event_log.append(entry)
