# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — per-inhabitant event memory (M2 Track A).
#
# `EventMemory` is the per-inhabitant record of events
# the inhabitant has witnessed. The M2 Track A commit
# fills in the cap policy, the search helpers, and the
# per-entry halflife decay:
#
#   * The memory holds the last
#     `SimConstants.TUNING_EVENT_MEMORY_CAPACITY`
#     entries per inhabitant (default 32). New
#     `record(entry)` calls append; if the resulting
#     length would exceed the cap, the *oldest* entry
#     is evicted. The cap is per-inhabitant; the
#     `EventLog` is the realm-wide append-only log
#     and does not share the cap.
#
#   * Entries are kept sorted by `time_days`
#     ascending. The `record()` method inserts in
#     O(n) (linear scan to find the insertion
#     point); the `recall()` method returns a
#     *contiguous slice* of the sorted array.
#
#   * Each entry's `summary_weight` decays by half
#     per `TUNING_EVENT_MEMORY_HALFLIFE_DAYS`
#     (default 30 in-game days). A fresh entry has
#     `summary_weight = 1.0`; an entry one halflife
#     old has `summary_weight = 0.5`; an entry two
#     halflives old has `summary_weight = 0.25`;
#     and so on. The decay is computed in
#     `recall()` (lazily, against `current_day`),
#     not in `record()`. This is the contract
#     ADR-0005 step 4 documents: the memory
#     *records* events; the per-entry weight is a
#     *read-time* function of the current tick.
#
# The `EventEntry` shape is a plain `Dictionary` with
# the canonical keys listed in the §"EventEntry shape"
# section below. The Dictionary shape is what the
# `EventLog` (`src/sim/event_log.gd`) appends, what
# the event-memory step (step 4 in ADR-0005) records,
# and what the save/load pipeline (ADR-0003)
# round-trips. Pinning the Dictionary keys here pins
# the contract.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` and `src/sim/constants.gd` only.
class_name EventMemory
extends RefCounted

## The inhabitant's remembered events, in
## chronological order (oldest first, newest last).
## Each entry is a plain `Dictionary` with the
## canonical `EventEntry` shape:
##
##   * `id`:         `StringName` — the event's stable
##                   identity (a content-defined
##                   StringName, e.g. `"evt_first_fire"`,
##                   `"evt_contract_breach_42"`).
##   * `time_days`:  `float`     — the in-game day the
##                   event was recorded (`time_days +
##                   delta_days` at the end of the
##                   tick that produced it, per
##                   ADR-0005 step 6).
##   * `kind`:       `StringName` — a tag that says
##                   *what kind* of event this is
##                   (`"task.completed"`, `"needs.low"`,
##                   `"contract.breached"`,
##                   `"crisis.resolved"`, …). The set
##                   of kinds is content-driven; the
##                   M2 Track A and Track B commits
##                   add the kinds they emit.
##   * `summary`:    `StringName` — a *locale key* for
##                   a one-sentence English / German
##                   summary of the event, resolved
##                   via `tr()` at draw time. See
##                   `docs/localization.md` §"Naming"
##                   for the key shape (`EVENT_*`).
##   * `affected`:   `PackedStringArray` — the
##                   inhabitant ids affected by the
##                   event, in stable order
##                   (alphabetical by id, the
##                   determinism-friendly default).
##                   The inhabitant whose `EventMemory`
##                   this entry lives in is always
##                   present in this list.
##   * `summary_weight` (optional, computed
##                   lazily): `float` in `[0.0, 1.0]`
##                   representing the decayed
##                   *recall weight* of the event.
##                   Computed in `recall()` against
##                   the current `time_days`; not
##                   stored on the entry.
##
## The M2 Track A commit narrows the type to
## `Array[Dictionary]` and adds the per-cap eviction
## policy.
var entries: Array = []


## Default constructor. Starts with an empty
## `entries` array.
func _init() -> void:
	entries = []


## Append an event to the memory. The `entry`
## argument is a `Dictionary` with the canonical
## `EventEntry` shape; the function does not
## validate the shape (the M2 contract pins the
## shape at the `EventLog` boundary; the memory
## accepts whatever the log appends).
##
## The insertion is in sorted order by
## `time_days` ascending. The function finds the
## insertion point in O(n) (linear scan) and
## inserts in O(n) (the array shift). The
## resulting `entries` array is sorted by
## `time_days` ascending.
##
## If the resulting `entries` length would
## exceed the per-inhabitant cap
## (`SimConstants.TUNING_EVENT_MEMORY_CAPACITY`,
## default 32), the *oldest* entry is evicted
## before the insertion. The eviction policy
## is "drop the oldest first"; the M2 contract
## does not pin a more sophisticated policy
## (e.g. weighted eviction) because the cap is
## generous (32 entries = 32 days of daily
## events, well over a month of memory).
##
## Returns `true` on success, `false` on
## validation failure (a `null` entry, a
## `Dictionary` with no `time_days` key). The
## caller can use the return value to decide
## whether to log a warning.
func record(entry: Dictionary) -> bool:
	if entry == null:
		return false
	if not entry.has("time_days"):
		# An event without a `time_days` is
		# un-sortable. Reject rather than
		# silently mis-sort. The M2 contract
		# pins `time_days` as a canonical
		# key on every `EventEntry`.
		return false
	var t: float = float(entry.get("time_days", 0.0))
	# Evict the oldest entry if we are at
	# the cap. The cap is the global M2
	# default; per-inhabitant overrides
	# (planned for content) would be
	# encoded as a constructor argument.
	var cap: int = SimConstants.TUNING_EVENT_MEMORY_CAPACITY
	while entries.size() >= cap and entries.size() > 0:
		entries.pop_front()
	# Find the insertion point. The array
	# is sorted by `time_days` ascending;
	# a binary search would be O(log n),
	# but a linear scan is O(n) and the
	# cap is small (32). Linear scan keeps
	# the dependency-free implementation.
	var insert_at: int = entries.size()
	for i in range(entries.size()):
		var e_t: float = float(entries[i].get("time_days", 0.0))
		if t < e_t:
			insert_at = i
			break
	entries.insert(insert_at, entry)
	return true


## Return the entries whose `kind` matches the
## given `StringName`. The result is a new
## `Array`; the memory itself is not mutated.
## The returned array is a *filtered view* in
## the same sorted order as `entries` (by
## `time_days` ascending).
##
## If `current_day` is provided, each entry's
## `summary_weight` is computed and stamped
## onto a *copy* of the entry (the original
## `entries` array is not mutated). The weight
## decays by half per
## `TUNING_EVENT_MEMORY_HALFLIFE_DAYS`; a
## fresh entry has weight `1.0` and a very
## old entry has weight near `0.0`.
##
## If `current_day` is `null` or omitted, the
## returned entries are the raw stored
## dictionaries (no `summary_weight`
## stamping). This is the cheap path the M2
## event log uses when it does not care
## about decay.
func recall(kind: StringName, current_day: float = INF) -> Array:
	var out: Array = []
	for e in entries:
		if e == null or not (e is Dictionary):
			continue
		if e.get("kind", &"") == kind:
			if current_day == INF or current_day == null:
				out.append(e)
			else:
				# Compute the per-entry
				# summary weight. The
				# weight is a read-time
				# function of the
				# `time_days` delta from
				# `current_day`; the
				# halflife is the M2
				# default.
				var t: float = float(e.get("time_days", 0.0))
				var age: float = maxf(0.0, current_day - t)
				var halflife: float = SimConstants.TUNING_EVENT_MEMORY_HALFLIFE_DAYS
				if halflife <= 0.0:
					# A misconfigured halflife
					# (zero or negative) is a
					# developer error; clamp
					# to a safe default.
					halflife = 1.0
				var weight: float = pow(0.5, age / halflife)
				var copy_e: Dictionary = e.duplicate()
				copy_e["summary_weight"] = weight
				out.append(copy_e)
	return out


## Prune entries older than
## `TUNING_EVENT_MEMORY_HALFLIFE_DAYS * 4` (i.e.,
## entries whose summary weight is below `1/16`).
## Called from `Inhabitant.tick()` at the end of
## every tick to bound the per-inhabitant memory
## footprint. The 4x halflife threshold is the M2
## baseline; a content override can pin a stricter
## cap.
func prune(current_day: float) -> void:
	var threshold: float = SimConstants.TUNING_EVENT_MEMORY_HALFLIFE_DAYS * 4.0
	var keep: Array = []
	for e in entries:
		if e == null or not (e is Dictionary):
			continue
		var t: float = float(e.get("time_days", 0.0))
		if current_day - t <= threshold:
			keep.append(e)
	entries = keep


## Convenience: return a deep-copy `Dictionary`
## representation of the memory, for save/load
## (ADR-0003) and for test asserts. The returned
## dictionary has the canonical key `entries`;
## round-tripping through `from_dict` is the
## test contract.
func to_dict() -> Dictionary:
	return {
		"entries": entries.duplicate(true),
	}


## Convenience: restore the memory from a
## `Dictionary` produced by `to_dict`. Unknown
## keys are ignored; missing keys leave the
## current value in place. Used by the M2
## save/load pipeline (Track C); the M2 cycle 3
## commit is the canonical caller.
func from_dict(d: Dictionary) -> void:
	if d == null:
		return
	if d.has("entries") and d["entries"] is Array:
		entries = (d["entries"] as Array).duplicate(true)
