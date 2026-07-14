# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — per-inhabitant event memory (M2 skeleton).
#
# `EventMemory` is the per-inhabitant record of events
# the inhabitant has witnessed. The M2 skeleton ships
# the `entries: Array` field and the `class_name`;
# the M2 Track A commit fills in the cap policy (how
# many entries to keep) and the search helpers
# (per-day, per-kind, per-actor).
#
# The `EventEntry` shape is a plain `Dictionary` with
# the canonical keys listed below. The Dictionary
# shape is what the M2 contract pins because it is
# the shape the event log (`src/sim/event_log.gd`)
# appends, the shape the event-memory step (step 4 in
# ADR-0005) records, and the shape the save/load
# pipeline (ADR-0003) round-trips. Pinning the
# Dictionary keys here pins the contract.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports from
# `src/core` only.
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
##
## The M2 Track A commit narrows the type to
## `Array[Dictionary]` and adds the per-cap eviction
## policy (the M0 baseline is "keep the last 64
## entries per inhabitant"; the cap is content-tunable
## in `src/sim/constants.gd`).
var entries: Array = []


## Default constructor. Starts with an empty
## `entries` array. The M2 cycle 2 commit replaces
## this with a constructor that takes a seed
## capacity hint (e.g. `64`).
func _init() -> void:
	entries = []
