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
## `[-1.0, 1.0]` per in-game day. Used in step 5
## of every `Sim.tick()` call (ADR-0005). The
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
