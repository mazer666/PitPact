# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — inhabitant needs data carrier (M2 skeleton).
#
# `Needs` is the per-inhabitant need vector. Four need
# channels per the M2 contract and §9 of
# `docs/requirements.md`: `food`, `rest`, `safety`,
# `recognition`. All four are normalised in `[0.0, 1.0]`,
# where `0.0` is "starving / exhausted / terrified /
# invisible" and `1.0` is "satiated / rested / safe /
# acclaimed". A high value is *good*; the need decays
# downward and recovery moves it back up.
#
# The M2 SKELETON ships the four fields and the
# `class_name`; the M2 Track A commit fills in the
# per-tick decay and recovery rules. The decay rate and
# the recovery rate are pinned in
# `src/sim/constants.gd` (`TUNING_NEED_DECAY_PER_DAY`
# and `TUNING_NEED_RECOVERY_PER_DAY`) so Track B's
# contract and crisis code can read the same numbers.
#
# Per ADR-0002, this file does not import from `src/ui`,
# `src/realm`, or `src/save`. It imports from `src/core`
# only.
class_name Needs
extends RefCounted

## The `food` need, in `[0.0, 1.0]`. Decays downward
## at `TUNING_NEED_DECAY_PER_DAY` per in-game day;
## recovers when the inhabitant eats (in a kitchen
## room with food in inventory). The M2 Track A commit
## owns the per-tick decay and the per-tick recovery
## calculation.
var food: float = 1.0

## The `rest` need, in `[0.0, 1.0]`. Decays downward
## at `TUNING_NEED_DECAY_PER_DAY` per in-game day;
## recovers when the inhabitant sleeps (in a
## habitation room). The M2 Track A commit owns the
## per-tick calculation.
var rest: float = 1.0

## The `safety` need, in `[0.0, 1.0]`. Decays
## downward when the inhabitant is in a room or
## biome with hazard flags; recovers in a safe room.
## Unlike `food` and `rest`, `safety` does NOT decay
## at a flat per-day rate; the M2 Track A commit
## encodes the per-room and per-biome modifiers. The
## decay rate from `TUNING_NEED_DECAY_PER_DAY` is the
## *baseline* that the modifiers scale.
var safety: float = 1.0

## The `recognition` need, in `[0.0, 1.0]`. Decays
## downward slowly; recovers when the inhabitant
## performs a publicly-visible action (completes a
## task, fulfils a contract, wins a conflict). The
## M2 Track A commit owns the per-tick calculation.
var recognition: float = 1.0


## Default constructor. All four needs start at `1.0`
## (the M2 contract: an inhabitant arrives in the
## realm well-fed, well-rested, safe, and recognised).
## The M2 cycle 2 commit replaces this with a
## constructor that takes the four values explicitly
## and asserts each is in `[0.0, 1.0]`.
func _init() -> void:
	food = 1.0
	rest = 1.0
	safety = 1.0
	recognition = 1.0
