# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — Lanternbearer culture definition.
#
# The Lanternbearer is the first of the six original
# cultures M5 ships (and the only one M2 Track A
# fleshes out in depth). The class is a thin
# `RefCounted` that exposes the culture's identifying
# data and the small per-tick hooks the sim reads.
# The M2 Track A commit is a *content carrier*; the
# M5 cultures pass fleshes out the gameplay-side
# rules (e.g. how a Lanternbearer's scribe trait
# boosts research tasks). The Lanternbearer name is
# provisional (the final name lands at M5).
#
# §9.1 spec rules the Lanternbearer encodes:
#
#   * Body form: small, winged, dim light. A
#     Lanternbearer stands about half the height
#     of a human; they have vestigial wings that
#     support short, fluttering flight; they
#     carry a soft, bioluminescent "lantern"
#     that pulses with their mood. The body
#     form is *distinct* — not a tolkienesque
#     elf, not a pixie, not a glow-worm
#     fey. The lantern is the defining
#     silhouette; the wings are vestigial and
#     not for soaring. (M5 visual style pass
#     will pin the silhouette against the
#     `docs/style-bible.md` palette.)
#
#   * Movement: limited flight, prefers high
#     corridors. A Lanternbearer can fly short
#     distances (a few tiles in a single move)
#     but tires quickly; the realm's
#     high-ceiling corridors are where they
#     thrive. Low-ceiling rooms are
#     uncomfortable.
#
#   * Values: preservation of light,
#     story-keeping. A Lanternbearer takes
#     *personal* damage when a light source
#     in the realm is snuffed; they are the
#     realm's living archive, and they record
#     events others forget.
#
#   * Profession: scribe, loremaster. The
#     Lanternbearer's default role is
#     `"scribe"` (later content adds
#     `"loremaster"`); the role is what
#     the task queue prefers when assigning
#     research and lore tasks.
#
#   * Social expectations: quiet; speaks
#     only when needed. A Lanternbearer
#     rarely initiates conversation; when
#     they do, it is short and considered.
#     This is a *content* rule, not a
#     mechanical one — M5 ships the
#     dialogue tree.
#
#   * Conflict pattern: non-violent,
#     retreats, but remembers. A
#     Lanternbearer does not engage in
#     combat; when threatened, they
#     retreat to a high corridor. But
#     their `EventMemory` records the
#     conflict, and a future M5
#     "tell me about the rift" panel
#     surfaces the memory years later.
#
# §9 spec rule: cultures must not replicate
# recognisable existing fantasy designs. The
# Lanternbearer is *not* an elf (no immortality,
# no pointed ears, no forest affinity), *not*
# a pixie (no pranking, no trickster), *not* a
# glow-worm spirit (no insect anatomy), *not*
# a Lovecraftian "lantern" entity (no cosmic
# horror, no forbidden knowledge). The
# lantern is a *sympathetic* light that
# responds to the bearer's mood; the wings
# are vestigial; the lore-keeping is
# bureaucratic, not mystical.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, or `src/save`.
# It imports from `src/core` and
# `src/sim/constants.gd` only.
class_name LanternbearerCulture
extends RefCounted

## The culture's stable id, used as the
## `Inhabitant.culture` field value and as the
## `data/cultures/lanternbearer.tres` file's
## `id` key. The id is a `StringName` so it
## survives the dictionary round-trip and so
## identity comparisons are O(1) hashed
## lookups.
const CULTURE_ID: StringName = &"lanternbearer"

## The culture's localised display name, as
## a `StringName` that is a *locale key* (see
## `docs/localization.md` §"Naming"). The M2
## code does not resolve the key; the UI
## layer resolves it via `tr()` at draw time.
## The key is `CREATURE_LANTERNBEARER_NAME`
## in the project's `locales/source_strings.csv`
## (a future commit adds the row; the M2
## skeleton ships the key as the canonical
## reference).
const DISPLAY_NAME: StringName = &"CREATURE_LANTERNBEARER_NAME"

## The culture's body form, as a
## `StringName` locale key. Resolved by the
## UI layer's body-form renderer (M5+). The
## M2 Track A commit ships the key; the M5
## visual style pass adds the row to the
## `locales/source_strings.csv`.
const BODY_FORM: StringName = &"CREATURE_LANTERNBEARER_BODY_FORM"

## The culture's primary value, as a
## `StringName` locale key. A Lanternbearer
## is *defined* by the preservation of
## light; the value is what the M5
## inspector surfaces as the
## "primary allegiance" line.
const PRIMARY_VALUE: StringName = &"CREATURE_LANTERNBEARER_VALUE_PRESERVATION"

## The culture's secondary value, as a
## `StringName` locale key. A Lanternbearer
## is the realm's living archive; the value
## is what the M5 inspector surfaces as the
## "second allegiance" line.
const SECONDARY_VALUE: StringName = &"CREATURE_LANTERNBEARER_VALUE_STORYKEEPING"

## The Lanternbearer's default role, as a
## `StringName`. The realm façade's
## content loader reads this and stamps
## the role on a freshly-arrived
## Lanternbearer inhabitant.
const DEFAULT_ROLE: StringName = &"scribe"

## The Lanternbearer's preferred profession
## family, as a `StringName`. The task
## queue's auto-assigner (M2 cycle 2) reads
## this when scoring a task assignment.
## Scribes and loremasters are the M5
## family members; the M2 skeleton ships
## the family id.
const PROFESSION_FAMILY: StringName = &"lore"

## The Lanternbearer's preferred room
## height, as a `StringName` enum
## (`"low"`, `"medium"`, `"high"`). The
## M3+ room system reads this when
## computing the room-comfort modifier.
## Lanternbearers prefer `"high"`.
const PREFERRED_ROOM_HEIGHT: StringName = &"high"

## The Lanternbearer's social-expectation
## verb, as a `StringName` locale key.
## The M5 dialogue tree uses this to
## generate the per-NPC greeting;
## the M2 skeleton ships the key.
const SOCIAL_EXPECTATION: StringName = &"CREATURE_LANTERNBEARER_SOCIAL_QUIET"

## The Lanternbearer's conflict-pattern
## verb, as a `StringName` locale key.
## The M5 conflict-resolution tree
## uses this; the M2 skeleton ships
## the key.
const CONFLICT_PATTERN: StringName = &"CREATURE_LANTERNBEARER_CONFLICT_RETREAT"

## The Lanternbearer's per-tick morale
## bias — a small `float` in `[-0.2, 0.2]`
## that the `Morale.tick` step applies
## *after* the weighted-sum derivation.
## The Lanternbearer has a positive bias
## (`+0.05`) because their profession
## (scribing) produces steady
## `recognition` recovery that other
## cultures do not get. The bias is
## small enough that a starving
## Lanternbearer is still miserable;
## it is the per-culture *tilt*, not a
## replacement for the underlying
## need-driven morale calculation.
const MORALE_BIAS: float = 0.05

## The Lanternbearer's per-tick stress
## bias — a small `float` in `[-0.2, 0.2]`
## that the `Morale.tick` step applies
## *after* the per-morale stress
## derivation. The Lanternbearer has a
## negative bias (`-0.02`) because their
## story-keeping profession provides
## *context* for hardship: a Lanternbearer
## who has seen worse is less stressed
## by the current crisis. The bias is
## small enough that a starving
## Lanternbearer is still stressed;
## it is the per-culture *tilt*, not a
## replacement for the underlying
## morale-driven stress calculation.
const STRESS_BIAS: float = -0.02

## The Lanternbearer's per-tick need
## modifier — a small bias toward the
## `recognition` need that the
## story-keeping profession produces.
## A Lanternbearer in a Hearth room
## recovers `recognition` at
## `TUNING_NEED_RECOVERY_PER_DAY *
## RECOGNITION_BIAS_MULT` per tick; the
## multiplier is the M2 Track A default
## (`1.2`, a 20% boost).
##
## The M3+ room system multiplies the
## baseline recovery by this factor
## when the inhabitant is a
## Lanternbearer. The M2 skeleton
## ships the constant; the M3 room
## system applies it.
const RECOGNITION_BIAS_MULT: float = 1.2

## The Lanternbearer's per-tick event-
## memory bias. The Lanternbearer's
## memory retains entries *longer* than
## the M2 default (a Lanternbearer is the
## realm's living archive, so they hold
## onto the past). The bias is a
## multiplier on the prune threshold
## (`4.0 * MEMORY_BIAS_MULT` halflives
## instead of `4.0`); the M2 default is
## `2.0` (a Lanternbearer keeps entries
## for 8 halflives = 240 days at the
## `TUNING_EVENT_MEMORY_HALFLIFE_DAYS =
## 30.0` default, twice the M2 cap).
const MEMORY_BIAS_MULT: float = 2.0


## The Lanternbearer's identifying data
## as a plain `Dictionary`. The M2 Track A
## content loader reads this when
## hydrating a `data/cultures/lanternbearer.tres`
## file into runtime form; the integration
## test reads it when asserting the
## content contract.
func info() -> Dictionary:
	return {
		"id": CULTURE_ID,
		"display_name": DISPLAY_NAME,
		"body_form": BODY_FORM,
		"primary_value": PRIMARY_VALUE,
		"secondary_value": SECONDARY_VALUE,
		"default_role": DEFAULT_ROLE,
		"profession_family": PROFESSION_FAMILY,
		"preferred_room_height": PREFERRED_ROOM_HEIGHT,
		"social_expectation": SOCIAL_EXPECTATION,
		"conflict_pattern": CONFLICT_PATTERN,
		"morale_bias": MORALE_BIAS,
		"stress_bias": STRESS_BIAS,
	}


## Static version of `apply_bias` for callers
## that do not have a `LanternbearerCulture`
## instance (notably the per-inhabitant
## `apply_culture_bias` helper that dispatches
## on the `Inhabitant.culture` field). The
## M2 Track A sim calls this from step 2.
## The `delta_days` argument is the in-game
## days the tick advances; the bias is scaled
## by `delta_days` so a multi-day tick applies
## the bias once per in-game day. The static
## method is the canonical call site; the
## instance method is kept for callers that
## have an instance.
static func apply_bias_static(morale: Morale, delta_days: float) -> void:
	if morale == null:
		return
	var step: float = float(delta_days)
	morale.morale = clampf(morale.morale + MORALE_BIAS * step, -1.0, 1.0)
	morale.stress = clampf(morale.stress + STRESS_BIAS * step, 0.0, 1.0)


## Apply the Lanternbearer's per-tick
## morale/stress bias. The function is the
## `Morale.tick` step's *content* hook
## (the sim's step 2 calls it after the
## need-driven calculation; see
## `sim.gd::tick` for the call site).
## The bias is small enough that it
## never dominates the underlying
## need-driven calculation; it is the
## per-culture *tilt*, not a replacement.
func apply_bias(morale: Morale, _delta_days: float) -> void:
	if morale == null:
		return
	morale.morale = clampf(morale.morale + MORALE_BIAS, -1.0, 1.0)
	morale.stress = clampf(morale.stress + STRESS_BIAS, 0.0, 1.0)
