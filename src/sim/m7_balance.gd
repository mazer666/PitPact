# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M7 Bucket 2: Balance Config
# carrier.
#
# `M7BalanceConfig` is the canonical
# "balance knobs" carrier. The carrier
# holds the M7-balanced values for the
# win/lose parameters; the M5-Closeout
# carrier (`M5GameState`) uses the
# constants directly (the M5 closeout
# did not separate balance from
# mechanics). The M7 closeout
# introduces `M7BalanceConfig` so the
# M8 closeout can ship a "hard mode"
# without code changes — just a new
# `M7BalanceConfig.hard()` factory.
#
# The carrier is a *data* carrier; the
# `M5GameState.from_balance(cfg)` factory
# (in `M5GameState`) produces a
# `M5GameState` configured by the
# balance config.
#
# Per ADR-0002, this file does not
# import from `src/ui`, `src/realm`, or
# `src/save`. It imports from `src/core`,
# `src/sim`.
class_name M7BalanceConfig
extends RefCounted

## M7 Bucket 2: the M7-balanced
## win threshold. The M5-Closeout
## used 30 days; the M7 closeout
## raises it to 45 (the player
## must invest more time in the
## realm before winning).
const M7_WIN_DAYS_SURVIVED: int = 45

## M7 Bucket 2: the M7-balanced
## minimum inhabitant count for
## the win condition. The M5-
## Closeout used 4; the M7 closeout
## raises it to 6 (the player
## must attract all 6 cultures
## before winning).
const M7_WIN_MIN_INHABITANTS: int = 6

## M7 Bucket 2: the M7-balanced
## minimum hearth count for the
## win condition (the player
## must have at least 1 hearth).
const M7_WIN_MIN_HEARTHS: int = 1

## M7 Bucket 2: the M7-balanced
## minimum shrine count for the
## win condition (the player
## must have at least 1 shrine).
const M7_WIN_MIN_SHRINES: int = 1

## M7 Bucket 2: the M7-balanced
## minimum forge count for the
## win condition (the player
## must have at least 1 forge).
const M7_WIN_MIN_FORGES: int = 1

## M7 Bucket 2: the M7-balanced
## minimum well count for the
## win condition (the player
## must have at least 1 well).
const M7_WIN_MIN_WELLS: int = 1

## M7 Bucket 2: the M7-balanced
## minimum trap count for the
## win condition (the player
## must have at least 1 trap).
const M7_WIN_MIN_TRAPS: int = 1

## M7 Bucket 2: the M7-balanced
## minimum inhabitant count to
## avoid instant loss. The M5-
## Closeout used 1 (lose when 0);
## the M7 closeout uses 2 (lose
## when < 2).
const M7_LOSE_MIN_INHABITANTS: int = 2

## M7 Bucket 2: the M7-balanced
## minimum hearth count to avoid
## instant loss (lose when 0).
const M7_LOSE_MIN_HEARTHS: int = 1

## M7 Bucket 2: the version
## tag for the M7 balanced config.
const _VERSION: String = "0.3.0-m7-content-and-balance"

## M7 Bucket 2: the win days
## threshold.
var win_days_survived: int = 30

## M7 Bucket 2: the win minimum
## inhabitants.
var win_min_inhabitants: int = 4

## M7 Bucket 2: the win minimum
## hearths.
var win_min_hearths: int = 1

## M7 Bucket 2: the win minimum
## shrines.
var win_min_shrines: int = 1

## M7 Bucket 2: the win minimum
## forges.
var win_min_forges: int = 1

## M7 Bucket 2: the win minimum
## wells.
var win_min_wells: int = 1

## M7 Bucket 2: the win minimum
## traps.
var win_min_traps: int = 1

## M7 Bucket 2: the lose minimum
## inhabitants.
var lose_min_inhabitants: int = 1

## M7 Bucket 2: the lose minimum
## hearths.
var lose_min_hearths: int = 1


## M7 Bucket 2: the canonical
## "M7 balanced" factory. The
## method is the canonical
## "give me the M7 balance"
## entry point; the M7 test net
## pins the canonical values.
static func m7_balanced() -> M7BalanceConfig:
	var cfg: M7BalanceConfig = M7BalanceConfig.new()
	cfg.win_days_survived = M7_WIN_DAYS_SURVIVED
	cfg.win_min_inhabitants = M7_WIN_MIN_INHABITANTS
	cfg.win_min_hearths = M7_WIN_MIN_HEARTHS
	cfg.win_min_shrines = M7_WIN_MIN_SHRINES
	cfg.win_min_forges = M7_WIN_MIN_FORGES
	cfg.win_min_wells = M7_WIN_MIN_WELLS
	cfg.win_min_traps = M7_WIN_MIN_TRAPS
	cfg.lose_min_inhabitants = M7_LOSE_MIN_INHABITANTS
	cfg.lose_min_hearths = M7_LOSE_MIN_HEARTHS
	return cfg


## M7 Bucket 2: the canonical
## "easy" factory. The M7 closeout
## ships an easier-than-balanced
## mode for new players.
static func easy() -> M7BalanceConfig:
	var cfg: M7BalanceConfig = M7BalanceConfig.new()
	cfg.win_days_survived = 20
	cfg.win_min_inhabitants = 3
	cfg.win_min_hearths = 1
	cfg.win_min_shrines = 1
	cfg.win_min_forges = 1
	cfg.win_min_wells = 1
	cfg.win_min_traps = 1
	cfg.lose_min_inhabitants = 1
	cfg.lose_min_hearths = 1
	return cfg


## M7 Bucket 2: the canonical
## "hard" factory. The M7 closeout
## ships a harder-than-balanced
## mode for experienced players.
static func hard() -> M7BalanceConfig:
	var cfg: M7BalanceConfig = M7BalanceConfig.new()
	cfg.win_days_survived = 60
	cfg.win_min_inhabitants = 8
	cfg.win_min_hearths = 1
	cfg.win_min_shrines = 1
	cfg.win_min_forges = 1
	cfg.win_min_wells = 1
	cfg.win_min_traps = 1
	cfg.lose_min_inhabitants = 3
	cfg.lose_min_hearths = 1
	return cfg


## M7 Bucket 2: return the
## version tag. The method is
## the canonical "give me the
## version" entry point; the
## M7 test net pins the
## version.
## M7 Bucket 2: the version
## tag for the M7 balanced config.
static func version() -> String:
	return _VERSION


## M7 Bucket 2: assert the carrier's
## fields are within valid ranges.
## The method is the canonical
## "is the config valid" entry
## point; the M7 test net pins
## the validation.
func is_valid() -> bool:
	return (
		win_days_survived > 0
		and win_min_inhabitants > 0
		and win_min_hearths >= 0
		and win_min_shrines >= 0
		and win_min_forges >= 0
		and win_min_wells >= 0
		and win_min_traps >= 0
		and lose_min_inhabitants > 0
		and lose_min_hearths >= 0
	)


## M9 Bucket 4: apply a balance
## patch. The method is the
## canonical "modify a config
## live" entry point; the M9
## closeout supports numeric
## patches (int/float) and
## string patches. The M9
## closeout returns a new
## `M7BalanceConfig` (the
## original is unchanged).
func apply_patch(patch: Dictionary) -> M7BalanceConfig:
	var result: M7BalanceConfig = M7BalanceConfig.new()
	result.win_days_survived = win_days_survived
	result.win_min_inhabitants = win_min_inhabitants
	result.win_min_hearths = win_min_hearths
	result.win_min_shrines = win_min_shrines
	result.win_min_forges = win_min_forges
	result.win_min_wells = win_min_wells
	result.win_min_traps = win_min_traps
	result.lose_min_inhabitants = lose_min_inhabitants
	result.lose_min_hearths = lose_min_hearths
	for key in patch.keys():
		if key in result:
			var v: Variant = patch[key]
			if v is int or v is float:
				result[key] = result[key] + v
			else:
				result[key] = v
	return result
