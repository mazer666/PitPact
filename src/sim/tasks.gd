# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — task data carrier (M2 skeleton).
#
# `Task` is the per-task data carrier for the realm's
# task queue. A task is a unit of work assigned to an
# inhabitant: build a room, deliver a resource, scout
# a region, research a topic. Tasks are issued by the
# player (through the realm façade) and by the
# simulation itself (e.g. auto-repair after a
# crisis). The M2 skeleton ships the public surface;
# the M2 Track A commit fills in the per-tick
# progress rule (step 3 in ADR-0005).
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name Task
extends RefCounted

## The task's stable identity. `StringName` for
## the same reasons as `Inhabitant.id`. The id
## is what the event log (`task.completed` events
## carry it) and the relationship history key
## off.
var id: StringName = &""

## The inhabitant the task is assigned to, as an
## inhabitant id (`StringName`). A `&""` value
## means "unassigned"; the realm façade's auto-
## assigner (M2 cycle 2) fills this in. Tasks
## assigned to an absent or deceased inhabitant
## are no-ops in step 3 of ADR-0005.
var assigned_to: StringName = &""

## The task's progress, in `[0.0, 1.0]`. `0.0`
## is "not started", `1.0` is "complete". A
## task whose `progress` reaches `1.0` is
## considered complete and emits a
## `task.completed` event into the event log
## (ADR-0005 step 6) in the same tick. The M2
## Track A commit owns the per-tick progress
## calculation; the per-tick delta is a
## content-defined function of the inhabitant's
## `Needs`, the room's purpose, and the
## available tools.
var progress: float = 0.0

## The in-game day the task was started. The
## value is the realm's `time_days` at the tick
## the task was issued; a task issued by the
## player outside a tick records the realm's
## current `time_days`. The field is what the
## UI's "task age" badge reads.
var started_at_day: float = 0.0


## Default constructor. Starts with empty
## fields and `0.0` progress. The M2 cycle 2
## commit replaces this with a constructor that
## takes `(id, assigned_to, started_at_day)`.
func _init() -> void:
	id = &""
	assigned_to = &""
	progress = 0.0
	started_at_day = 0.0
