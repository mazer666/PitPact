# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant data carrier (M2 skeleton).
#
# `Inhabitant` is the per-inhabitant data carrier for the
# M2 simulation. The class is a SKELETON in this commit: the
# public surface (the typed fields and the `class_name`)
# lands here, and the per-inhabitant behaviour (need
# evaluation, contract fulfilment, task assignment) is filled
# in by the M2 Track A commit.
#
# Per ADR-0002, this file does not import from `src/ui`,
# `src/realm`, or `src/save`. It imports from `src/core`
# only; the eventual `Needs`, `Contract`, `Task`, and
# `EventMemory` instances are referenced as typed `Variant`
# members in the skeleton, and narrowed to typed members in
# the cycle 2 commit.
#
# The M2 skeleton holds inhabitant data as plain fields on
# a `RefCounted`. The save/load pipeline (ADR-0003)
# round-trips the fields through the canonical body; the
# M2 cycle 3 commit adds the `to_save_dict` and
# `from_save_dict` accessors the serializer will call.
class_name Inhabitant
extends RefCounted

## Lifecycle enum (M2 cycle 2). The values are the
## canonical integers from the M0 baseline; the names
## are what the cycle 2 commit uses. The `int` is the
## authoritative representation; the enum is the
## readable alias. `ABSENT` covers both voluntary
## departure and involuntary disappearance (kidnapping,
## exploration, …) — the difference is captured in
## the event log, not in the enum.
const STATE_ALIVE: int = 0
const STATE_ABSENT: int = 1
const STATE_DECEASED: int = 2

## The inhabitant's stable identity. `StringName` so it
## survives the dictionary round-trip and so identity
## comparisons are O(1) hashed lookups. The id is
## assigned once at construction and never changes for
## the lifetime of the inhabitant. The id is what the
## relationship graph, the event memory, and the
## contract set key off; a corrupted id is a save-load
## failure.
var id: StringName = &""

## The inhabitant's culture id (a `StringName` reference
## to a `CultureData` instance under `data/cultures/`).
## The M0 template reserves the cultures directory; the
## M5 commit populates the six culture files. The id
## here is the `StringName` key into the content
## registry; the registry is owned by `src/content/`
## (M2 cycle 2 dependency, not preloaded here).
var culture: StringName = &""

## The inhabitant's display name, stored as a
## `StringName` that is a *locale key* (see
## `docs/localization.md` §"Naming"). The M2 skeleton
## does not resolve the key; the UI layer resolves it
## via `tr()` at draw time. The name is a
## `StringName` so it survives the dictionary round-trip
## and so identity comparisons are O(1) hashed lookups.
var name: StringName = &""

## The inhabitant's role in the realm. Default is
## `"settler"` per the M2 contract; other values
## (`"foreman"`, `"scout"`, `"scribe"`, …) are added
## by the M2 Track A and Track B commits. The role is
## a `StringName` keyed against a `RoleData` table in
## `data/roles/` (planned for M2 cycle 2).
var role: StringName = &"settler"

## The inhabitant's tile coordinates, per ADR-0004.
## `Vector2i` because the spatial state is integer
## (`src/world/coordinates.gd`). The M2 skeleton
## treats this as the *authoritative* position; the
## pathing layer (M3+) animates between positions and
## the simulation only ever sees the `Vector2i`
## endpoints.
var position: Vector2i = Vector2i.ZERO

## The inhabitant's lifecycle state, as an `int` enum
## value. The enum values live in the M2 cycle 2 commit
## (the skeleton ships the `int` field with the canonical
## `0` = alive, `1` = absent, `2` = deceased values
## so the save format can round-trip the field even
## before the enum is named). A non-zero value marks
## the inhabitant as out of the active tick loop:
## absent inhabitants do not work, deceased
## inhabitants do not decay, and the realm façade's
## view model (M5) renders them with the
## `INHABITANT_STATE_ABSENT` / `_DECEASED` localised
## label.
var state: int = STATE_ALIVE


## Default constructor. Assigns a fresh
## `StringName("")` id, the canonical `"settler"`
## role, the origin position, and the `ALIVE` state.
## The M2 cycle 2 commit replaces this with a
## constructor that takes `(id, culture, name, role)`
## and asserts the arguments are non-empty.
func _init() -> void:
	id = &""
	culture = &""
	name = &""
	role = &"settler"
	position = Vector2i.ZERO
	state = STATE_ALIVE
