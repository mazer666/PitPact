# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M4 Track D difficulty helpers.
#
# `Difficulty` is a static-only helper
# class the sim's per-tick rule and the
# realm façade consult for difficulty-
# dependent multipliers. The M4 closeout
# defines three difficulties (`PEACEFUL`,
# `BALANCED`, `CRUEL`) and three
# multipliers (`get_research_rate`,
# `get_morale_delta_per_day`,
# `get_crisis_chance_per_day`).
#
# The multipliers are *content*; the
# carrier is a static helper (the M4
# design doc pins the per-difficulty
# values, the M5 content pass can
# extend with custom difficulties).
class_name Difficulty
extends RefCounted

## The three M4-default difficulties.
## The values are the canonical
## `Settings.difficulty` integers.
const PEACEFUL: int = 0
const BALANCED: int = 1
const CRUEL: int = 2


## The research rate per difficulty.
## PEACEFUL = `1.0` (default), BALANCED
## = `1.0` (default), CRUEL = `0.5`
## (slower research). The values are
## multipliers on the per-tick rule's
## `delta_days` argument.
static func get_research_rate(d: int) -> float:
	match d:
		PEACEFUL:
			return 1.0
		BALANCED:
			return 1.0
		CRUEL:
			return 0.5
		_:
			return 1.0


## The morale delta per day per
## difficulty. PEACEFUL = `+0.05` (slow
## morale recovery), BALANCED = `0.0`
## (no drift), CRUEL = `-0.1` (slow
## morale decay). The values are added
## to the realm's morale once per tick.
static func get_morale_delta_per_day(d: int) -> float:
	match d:
		PEACEFUL:
			return 0.05
		BALANCED:
			return 0.0
		CRUEL:
			return -0.1
		_:
			return 0.0


## The crisis chance per day per
## difficulty. PEACEFUL = `0.0` (no
## random crisis), BALANCED = `0.05`
## (1 in 20 chance per day), CRUEL =
## `0.1` (1 in 10 chance per day). The
## values are probabilities in `[0, 1]`.
static func get_crisis_chance_per_day(d: int) -> float:
	match d:
		PEACEFUL:
			return 0.0
		BALANCED:
			return 0.05
		CRUEL:
			return 0.1
		_:
			return 0.0
