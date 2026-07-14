# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — the narrative-anchor data carrier (M3-foundation skeleton).
#
# `NarrativeAnchor` is a per-anchor data carrier the M3
# world generator (ADR-0007) emits and the realm
# inspector reads. §8 of `docs/requirements.md` requires
# "fixed narrative anchors" — short story hooks the
# player can discover as they explore the realm. The
# anchors are *fixed* in the sense that the same seed
# produces the same anchor set in the same positions;
# they are *not* procedurally generated text. The
# anchor's `display_name` and `summary` are locale
# keys; the resolved text lives in
# `locales/source_strings.csv`.
#
# The skeleton declares the public surface that M3
# cycle 2 (Track B) will fill in. The fields are:
#
#   * `id` — stable identity (`StringName`).
#   * `trigger_at_day` — the in-game day the anchor
#     becomes available. A negative value (`-1.0`)
#     means "the anchor is location-gated, not
#     time-gated"; the per-tick rule treats a negative
#     value as "always available once the player
#     reaches the anchor's tile".
#   * `display_name` — locale key, resolved via `tr()`
#     at draw time.
#   * `summary` — locale key for the one-sentence
#     story hook the UI shows in the realm
#     inspector. The M3 default is a one-sentence
#     hook; M5 content can ship longer hooks.
#   * `triggered` — `true` once the anchor has been
#     "seen" (the player has reached its tile or
#     its `trigger_at_day` has passed). The renderer
#     uses this to dim the anchor's icon in the
#     realm inspector.
#   * `resolved` — `true` once the anchor has been
#     "resolved" (the player has dismissed the
#     hook or taken a follow-up action). The
#     per-tick rule sets `resolved`; the UI's
#     realm-inspector panel reads it.
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/sim`, `src/realm`, `src/save`, or
# `src/audit`. It imports from `src/core` and
# `src/content` only.
class_name NarrativeAnchor
extends RefCounted

## The anchor's stable identity. `StringName` for
## the same reasons as `Tile.id` and `Inhabitant.id`:
## it survives the dictionary round-trip and identity
## comparisons are O(1) hashed lookups. The id is
## assigned once at construction and never changes.
## The save/load pipeline (ADR-0003) round-trips
## this value under
## `body.world.narrative_anchors[*].id`.
var id: StringName = &""

## The in-game day the anchor becomes available.
## A `float`; the M3 default is `0.0` (the anchor
## is available from the start). A negative value
## (`-1.0`) means "the anchor is location-gated,
## not time-gated"; the per-tick rule treats a
## negative value as "always available once the
## player reaches the anchor's tile". The save
## body stores this value under
## `body.world.narrative_anchors[*].trigger_at_day`.
var trigger_at_day: float = 0.0

## Localised display name. The runtime stores the
## `StringName` *locale key* (per §15 of
## `docs/requirements.md`); the UI resolves it via
## `tr()` at draw time. The M3 default is an empty
## `StringName`; the generator's content-adapter
## step (M3 cycle 2, Track B) populates the value
## from the loaded content.
var display_name: StringName = &""

## Localised summary. The runtime stores the
## `StringName` *locale key* (per §15 of
## `docs/requirements.md`); the UI resolves it via
## `tr()` at draw time. The M3 default is a
## one-sentence hook; M5 content can ship longer
## hooks. The save body stores this value under
## `body.world.narrative_anchors[*].summary`.
var summary: StringName = &""

## Whether the anchor has been "seen" (the player
## has reached its tile or its `trigger_at_day`
## has passed). The M3 default is `false`; the
## per-tick rule (M3 cycle 2, Track B) sets this
## to `true` when the trigger condition fires.
## The renderer uses this to dim the anchor's
## icon in the realm inspector.
var triggered: bool = false

## Whether the anchor has been "resolved" (the
## player has dismissed the hook or taken a
## follow-up action). The M3 default is `false`;
## the per-tick rule sets this to `true` when
## the resolution condition fires. The UI's
## realm-inspector panel reads it.
var resolved: bool = false


## Default constructor. All fields default to
## their zero-equivalents; the generator's
## content-adapter step (M3 cycle 2, Track B)
## populates the values from the loaded content.
func _init() -> void:
	id = &""
	trigger_at_day = 0.0
	display_name = &""
	summary = &""
	triggered = false
	resolved = false


## Convenience factory. Equivalent to
## `NarrativeAnchor.new()` followed by field
## assignments, but reads more naturally at call
## sites. The generator's content-adapter step
## uses this factory.
static func make(
	p_id: StringName = &"",
	p_trigger_at_day: float = 0.0,
	p_display_name: StringName = &"",
	p_summary: StringName = &""
) -> NarrativeAnchor:
	var a: NarrativeAnchor = NarrativeAnchor.new()
	a.id = p_id
	a.trigger_at_day = p_trigger_at_day
	a.display_name = p_display_name
	a.summary = p_summary
	return a


## Mark the anchor as triggered. Sets
## `triggered = true`. The M3 cycle 2 (Track B)
## commit calls this from the per-tick rule
## when the trigger condition fires. Calling
## `trigger()` on an already-triggered anchor
## is a no-op.
func trigger() -> void:
	if triggered:
		return
	triggered = true


## Mark the anchor as resolved. Sets
## `resolved = true` and, if the anchor has not
## yet been triggered, also sets `triggered =
## true` (a resolved anchor is always a
## triggered anchor). The M3 cycle 2 (Track B)
## commit calls this from the per-tick rule
## when the resolution condition fires. Calling
## `resolve()` on an already-resolved anchor is
## a no-op.
func resolve() -> void:
	if resolved:
		return
	resolved = true
	triggered = true


## Equality by value. Two anchors are equal iff
## they have the same `id`, the same
## `trigger_at_day`, the same `display_name`, the
## same `summary`, the same `triggered`, and the
## same `resolved`. Used by the M3 cycle 2
## (Track B) determinism test to assert the
## generator's anchor set is deep-equal across
## two runs of the same seed.
func equals(other: NarrativeAnchor) -> bool:
	# Single-return accumulator pattern. The
	# function used to early-return on each
	# mismatch; the refactor is a `max-returns`
	# lint fix (gdtoolkit caps `equals`-style
	# functions at 6 returns). The accumulator
	# is updated on each mismatch and the
	# function returns the accumulator at the
	# end. The behaviour is unchanged: the
	# function returns `true` iff every
	# comparison passes.
	var matches: bool = true
	if other == null:
		matches = false
	elif id != other.id:
		matches = false
	elif not is_equal_approx(trigger_at_day, other.trigger_at_day):
		matches = false
	elif display_name != other.display_name:
		matches = false
	elif summary != other.summary:
		matches = false
	elif triggered != other.triggered:
		matches = false
	elif resolved != other.resolved:
		matches = false
	return matches
