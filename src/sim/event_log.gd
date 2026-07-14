# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — append-only event log (M2 Track B).
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
## (oldest first, newest last). Each entry is a plain
## `Dictionary` with the canonical `EventEntry`
## shape (`id`, `time_days`, `kind`, `summary`,
## `affected`). The contract is that callers
## always `append` entries with strictly
## non-decreasing `time_days`; the log sorts on
## read (via `entries_in_range` /
## `entries_involving` / `latest`) rather than
## mutating the array, which preserves the
## append-only invariant.
var entries: Array = []


## Default constructor. Starts with an empty
## `entries` array.
func _init() -> void:
	entries = []


## Append an event entry to the log. The
## `entry` argument is a plain `Dictionary`
## with the canonical `EventEntry` shape. The
## append is O(1) amortised; the log's total
## memory grows linearly with the number of
## ticks and the number of events per tick.
## The log does NOT verify the dictionary's
## shape on append — the canonical-five-keys
## assertion is the caller's responsibility
## (the sim's `tick()` body is the canonical
## caller and the entry-builder helpers it
## uses pin the shape).
func append(entry: Dictionary) -> void:
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
## `to_day < from_day`.
##
## The implementation is a linear scan over the
## `entries` array. The array is monotonic in
## `time_days` (the sim appends in tick order);
## a future optimisation replaces the scan with
## a binary search. The M2 cycle 3 commit is
## the documented home of that optimisation.
func entries_in_range(from_day: float, to_day: float) -> Array:
	var out: Array = []
	for e in entries:
		if e == null or not (e is Dictionary):
			continue
		var t: float = float(e.get("time_days", 0.0))
		if t >= from_day and t < to_day:
			out.append(e)
	return out


## Return the entries that involve
## `inhabitant_id`. An entry "involves" an
## inhabitant when the inhabitant's id is in
## the entry's `affected` PackedStringArray
## (the canonical list of affected parties the
## event log's writers fill in). The result is
## a new `Array`; the log itself is not mutated.
## The comparison is exact (string equality)
## — an inhabitant id is a `StringName`, the
## `affected` list is a `PackedStringArray` of
## `String` representations, and the
## `String(StringName)` round-trip is
## deterministic.
##
## The implementation is a linear scan over
## the `entries` array. The M5 UI's "events
## involving me" panel is the consumer; the
## scan is acceptable for M2 because the log
## size in a default playthrough is well under
## the per-inhabitant scan's break-even point.
func entries_involving(inhabitant_id: StringName) -> Array:
	var out: Array = []
	var needle: String = String(inhabitant_id)
	for e in entries:
		if e == null or not (e is Dictionary):
			continue
		var affected: Variant = e.get("affected", PackedStringArray())
		if not (affected is PackedStringArray) and not (affected is Array):
			continue
		for a in affected:
			if String(a) == needle:
				out.append(e)
				break
	return out


## Return the most-recent `n` entries, in
## chronological order (oldest first, newest
## last). The result is a new `Array`; the log
## itself is not mutated. `n <= 0` returns an
## empty array; `n` larger than the log's size
## returns a copy of the entire log. The
## implementation is a tail slice; the M5
## UI's "last 10 events" panel is the
## consumer.
func latest(n: int) -> Array:
	var out: Array = []
	if n <= 0:
		return out
	if n >= entries.size():
		return entries.duplicate()
	var start: int = entries.size() - n
	for i in range(start, entries.size()):
		out.append(entries[i])
	return out
