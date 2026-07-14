# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M2 simulation tuning constants.
#
# This file is the per-module equivalent of
# `src/core/constants.gd`: it holds the named numeric
# constants the M2 simulation reads in every tick. The
# constants are *not* the canonical place for content
# balance (that lives in `data/*.tres`); they are the
# defaults the M2 Track A and Track B commits start
# from, and the per-tick numbers every per-subsystem
# test depends on.
#
# Why a per-module `constants.gd` instead of
# `src/core/constants.gd`?
#   * The constants are M2-specific. The M0 baseline
#     of `src/core/constants.gd` holds engine-wide
#     numbers (the tile-pixel size, the save-format
#     version, etc.). Mixing M2 tuning in there would
#     turn the file into a junk drawer.
#   * The constants are *not* engine-wide. They are
#     read by the sim's six tick steps (ADR-0005) and
#     nowhere else; the UI layer does not know they
#     exist. The per-module file makes the scope
#     explicit.
#   * Track A and Track B are the only two commits
#     that will tune these numbers. A per-module file
#     keeps the diff between the two tracks small
#     (each track edits its own row, not the
#     global constants file).
#
# Per ADR-0002, this file does not import from
# `src/ui`, `src/realm`, or `src/save`. It imports
# from `src/core` only (and even that is a planned
# M2 cycle 2 dependency; the M2 skeleton does not
# actually preload anything).
class_name SimConstants
extends RefCounted

## The per-day decay rate of an inhabitant's needs,
## in `[0.0, 1.0]` per in-game day. Used in step 2
## of every `Sim.tick()` call (ADR-0005). The value
## is a baseline; the M2 Track A commit encodes the
## per-need modifiers (a `food` need decays at the
## baseline rate; a `safety` need decays faster in
## a hazardous biome, slower in a safe room). The
## `0.05` baseline means a fully-satisfied
## inhabitant reaches "hungry" after twenty
## in-game days, "starving" after forty. The Track
## A commit will tune this against playtest data.
const TUNING_NEED_DECAY_PER_DAY: float = 0.05

## The per-day recovery rate of an inhabitant's
## needs, in `[0.0, 1.0]` per in-game day. Used in
## step 2 of every `Sim.tick()` call. The value is
## a baseline; the M2 Track A commit encodes the
## per-need and per-room modifiers. The `0.10`
## baseline means a starving inhabitant reaches
## "satiated" after ten in-game days of eating
## (faster than the decay rate, so a working
## realm's inhabitants tend to be fed). The Track
## A commit will tune this against playtest data.
const TUNING_NEED_RECOVERY_PER_DAY: float = 0.10

## The per-day drift rate of a relationship's
## affinity toward `0.0` ("indifferent"), in
## `[-1.0, 1.0]` per in-game day. Used in step
## 5 of every `Sim.tick()` call (ADR-0005). The
## `0.01` baseline means a "+1.0" relationship
## reaches "indifferent" after a hundred days
## without any positive events. The M2 Track B
## commit will tune this against playtest data;
## the baseline is conservative so the M5
## "tell me about the rift" panel has time to
## read long history chains.
const TUNING_RELATIONSHIP_DRIFT_PER_DAY: float = 0.01

## The default crisis timeout, in in-game days.
## Used by the M2 Track B per-tick crisis
## evaluation rule. The `7.0` baseline means a
## crisis that is not resolved by the player in
## a week of in-game time expires and the realm
## takes the default outcome (the content-defined
## "you did not respond" consequence). The Track B
## commit will tune this against playtest data;
## the M3+ per-crisis overrides live in
## `data/crises/*.tres` and are not pinned here.
const TUNING_CRISIS_DEFAULT_DAYS: float = 7.0

## Default capacity of an inhabitant's
## `EventMemory.entries` array. The cap is
## content-tunable (per ADR-0005, the cap is
## the per-subsystem default; Track A and Track
## B may override it for specific inhabitants
## via a per-inhabitant field). The M2 Track A
## commit evicts the oldest entry when the cap
## is reached; the per-eviction policy is
## documented in `src/sim/event_memory.gd`.
const TUNING_EVENT_MEMORY_CAPACITY: int = 32

## The halflife of an inhabitant's event-memory
## summary weight, in in-game days. Entries
## older than one halflife have their summary
## weight divided by two; entries older than
## two halflives have their weight divided by
## four; and so on. The `30.0` baseline means
## a thirty-day-old event has half the recall
## weight of a fresh one, and a sixty-day-old
## event has a quarter. The M2 Track A commit
## owns the per-entry decay calculation; the
## M5 "tell me about the rift" panel reads the
## decayed weight to decide which events are
## worth surfacing.
const TUNING_EVENT_MEMORY_HALFLIFE_DAYS: float = 30.0

## The default affinity nudge when two
## inhabitants are linked by a cooperative
## event (e.g. a `task.completed` event with
## both endpoints as `affected`). Used by
## `Relationship.register` in step 5 of
## ADR-0005. The `0.05` baseline is small
## enough that a single cooperative event
## does not swing a relationship from
## neutral to ally in one tick, but a steady
## stream of cooperation nudges a relationship
## toward "+1.0" in a few tens of days.
const TUNING_RELATIONSHIP_POSITIVE_NUDGE: float = 0.05

## The default affinity nudge when two
## inhabitants are linked by a conflict event
## (e.g. a `conflict` event with both endpoints
## as `affected`). Used by
## `Relationship.register` in step 5 of
## ADR-0005. The `-0.10` baseline is slightly
## larger than the positive nudge so a single
## conflict moves the relationship more than a
## single cooperation; this matches the
## §9.4 spec rule that conflicts leave a
## longer scar than a cooperation leaves a
## favour.
const TUNING_RELATIONSHIP_NEGATIVE_NUDGE: float = -0.10

## The per-day stress decay rate. Stress
## bleeds away slowly when the inhabitant's
## needs are met and morale is high. The
## `0.02` baseline means a fully-stressed
## inhabitant reaches "calm" after fifty
## in-game days of being well-fed and safe.
## The M2 Track A commit owns the per-tick
## decay calculation; the M5 inspector panel
## surfaces the resulting stress value.
const TUNING_STRESS_DECAY_PER_DAY: float = 0.02

## The cap on an inhabitant's morale absolute
## value after a per-tick adjustment. The
## cap is `1.0` (the natural range), but
## future content may pin a softer cap so a
## freshly-arrived inhabitant is not at
## "peak morale" on day one. M2 ships the
## hard `1.0` cap.
const TUNING_MORALE_CAP: float = 1.0

## The cap on an inhabitant's stress absolute
## value. Same shape as `TUNING_MORALE_CAP`:
## the M2 default is `1.0` (the natural range);
## future content may pin a softer cap.
const TUNING_STRESS_CAP: float = 1.0

## The weight of `food` in the morale
## calculation. A need at `1.0` (satiated)
## contributes this much to the positive
## morale pole; a need at `0.0` (starving)
## contributes this much to the negative.
## Sum of the four need weights should
## equal `1.0` so a fully-satisfied inhabitant
## lands at `+1.0` morale and a fully-deprived
## inhabitant lands at `-1.0`. The Track A
## commit owns the per-tick calculation; the
## M5 inspector surfaces the resulting value.
const TUNING_MORALE_WEIGHT_FOOD: float = 0.30

## The weight of `rest` in the morale
## calculation. See `TUNING_MORALE_WEIGHT_FOOD`
## for the contract.
const TUNING_MORALE_WEIGHT_REST: float = 0.30

## The weight of `safety` in the morale
## calculation. See `TUNING_MORALE_WEIGHT_FOOD`
## for the contract.
const TUNING_MORALE_WEIGHT_SAFETY: float = 0.25

## The weight of `recognition` in the morale
## calculation. See `TUNING_MORALE_WEIGHT_FOOD`
## for the contract.
const TUNING_MORALE_WEIGHT_RECOGNITION: float = 0.15
