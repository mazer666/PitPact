# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — append-only event log (M2 skeleton).
#
# `EventLog` is the realm's append-only event log.
# Every event the sim emits in step 6 of a tick
# (ADR-0005) lands here, in the order it was
# emitted. The event log is the source of truth for
# the UI's event-log panel (§13 of
# `docs/requirements.md`) and for the save/load
# pipeline (ADR-0003 — `body.sim.event_log` is the
# canonical place the save body stores the log).
#
# The log is **append-only**. There is no
# `remove` method, no `clear` method, no
# `truncate` method. The only mutating method is
# `append(entry)`. A row that turns out to be a
# mistake is corrected by appending a *new* row
# (e.g. `"event.corrects"` with a reference to
# the corrected row's id), not by mutating the
# existing row. This is the property the M5
# "replay a campaign" feature depends on.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only.
class_name EventLog
extends RefCounted

## The log's entries, in chronological order
## (oldest first, newest last). Each entry is a
## plain `Dictionary` with the canonical
## `EventEntry` shape pinned by `EventMemory`
## (`id`, `time_days`, `kind`, `summary`,
## `affected`). The `Array[Dictionary]` type
## is the M2 contract; the M2 cycle 2 commit
## narrows the field's type to that exactly.
var entries: Array = []


## Default constructor. Starts with an empty
## `entries` array. The M2 cycle 2 commit
## replaces this with a constructor that takes
## a seed capacity hint.
func _init() -> void:
	entries = []


## Append an event entry to the log. The
## `entry` argument is a plain `Dictionary`
## with the canonical `EventEntry` shape. The
## append is O(1) amortised; the log's total
## memory grows linearly with the number of
## ticks and the number of events per tick.
## The M2 cycle 2 commit asserts the
## dictionary's keys are the canonical five
## (`id`, `time_days`, `kind`, `summary`,
## `affected`); the M2 skeleton accepts any
## `Dictionary` so the save/load pipeline can
## round-trip the log before the assertion
## lands.
func append(entry: Dictionary) -> void:
	# M2 SKELETON: the M2 cycle 2 commit adds the
	# shape assertion and the per-inhabitant
	# memory recording hook (step 4 in ADR-0005).
	if entry == null:
		push_error("EventLog.append: entry is null")
		return
	entries.append(entry)
	return


## Return the entries whose `time_days` falls in
## the half-open interval `[from_day, to_day)`.
## The result is a new `Array`; the log itself
## is not mutated. The half-open interval is
## what the UI's "events of day N" panel uses
## (a day-N event belongs to day N, not to day
## N+1). The comparison is a `float` compare;
## the caller is responsible for not asking for
## `to_day < from_day` (the M2 cycle 2 commit
## adds the assertion).
##
## The M2 SKELETON ships a linear scan; the M2
## cycle 2 commit replaces it with a binary
## search against the (already-sorted) `entries`
## array. The O(log n) form is what the M5
## "events in the last 30 days" panel wants.
func entries_in_range(from_day: float, to_day: float) -> Array:
	var out: Array = []
	for e in entries:
		if e == null or not (e is Dictionary):
			continue
		var t: float = float(e.get("time_days", 0.0))
		if t >= from_day and t < to_day:
			out.append(e)
	return out
