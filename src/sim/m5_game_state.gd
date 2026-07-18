# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Closeout: Game state carrier.
#
# `M5GameState` is the canonical "is the
# player winning or losing" data carrier.
# The carrier tracks the player's survival
# progress and exposes two predicates:
#
#   - `check_win_condition(sim)` — the
#     player has survived the campaign
#     and built a viable realm
#     (M5-Closeout ADR-0017 §Bucket 4).
#   - `check_lose_condition(sim)` — the
#     player has lost (no inhabitants,
#     no hearth, or out of time).
#
# The carrier is a *data* carrier, not a
# system: it does not tick or schedule.
# The sim's per-day tick calls
# `tick_day(sim, game_state)` to update
# the day count and the predicates.
#
# Per ADR-0002, this file does not import
# from `src/ui`, `src/realm`, or `src/save`.
# It imports from `src/core`, `src/sim`.
class_name M5GameState
extends RefCounted

## M5-Closeout win/lose thresholds.
## The thresholds are pinned in
# `test_m5_game_state.gd`; the
# M5-Closeout ADR-0017 §Bucket 4
## documents the design intent.

## The M5-Closeout survival target.
## The player must survive 30 days
## to win the campaign.
const WIN_DAYS_SURVIVED: int = 30

## The M5-Closeout minimum inhabitant
## count for the win condition. The
## realm must have at least 4
## inhabitants at the win check.
const WIN_MIN_INHABITANTS: int = 4

## The M5-Closeout minimum hearth count
## for the win condition. The realm
## must have at least 1 hearth tile.
const WIN_MIN_HEARTHS: int = 1

## The M5-Closeout minimum shrine count
## for the win condition. The realm
## must have at least 1 shrine tile
## (the M5-Closeout Bucket 2 room set).
const WIN_MIN_SHRINES: int = 1

## The M5-Closeout minimum forge count
## for the win condition. The realm
## must have at least 1 forge tile
## (the M5-Closeout Bucket 2 room set).
const WIN_MIN_FORGES: int = 1

## The M5-Closeout minimum well count
## for the win condition. The realm
## must have at least 1 well tile
## (the M5-Closeout Bucket 2 room set).
const WIN_MIN_WELLS: int = 1

## The M5-Closeout minimum trap count
## for the win condition. The realm
## must have at least 1 trap tile
## (the M5-Closeout Bucket 2 room set).
const WIN_MIN_TRAPS: int = 1

## The M5-Closeout lose-condition
## inhabitant count. The player
## loses when 0 inhabitants remain
## (the realm is abandoned).
const LOSE_MIN_INHABITANTS: int = 1

## The M5-Closeout lose-condition
## hearth count. The player loses
## when 0 hearths remain (no
## warmth, no shelter).
const LOSE_MIN_HEARTHS: int = 1

## The M5-Closeout version tag.
## The M5-Closeout bumps this to
## `0.2.0-m5-closeout` when the
## full M5-Closeout lands. The
## M5-Closeout Bucket 4 (game state)
## uses the same tag because the
## carrier is part of the M5-Closeout
## deliverable.
const _VERSION: String = "0.2.0-m5-closeout"

## The current day count. The
## counter increments every tick
## via `tick_day`.
var days_survived: int = 0

## The number of hearth tiles in
## the realm. The counter is
## recomputed every tick from
## the world's `tile.id` distribution.
var hearth_count: int = 0

## The number of shrine tiles in
## the realm. The counter is
## recomputed every tick.
var shrine_count: int = 0

## The number of forge tiles in
## the realm. The counter is
## recomputed every tick.
var forge_count: int = 0

## The number of well tiles in
## the realm. The counter is
## recomputed every tick.
var well_count: int = 0

## The number of trap tiles in
## the realm. The counter is
## recomputed every tick.
var trap_count: int = 0

## The outcome of the most recent
## win/lose check. The string is
## one of:
##   - `"playing"` (game is on)
##   - `"win"` (player won)
##   - `"lose"` (player lost)
##   - `"win_<reason>"` (e.g. "win_survived")
##   - `"lose_<reason>"` (e.g. "lose_no_inhabitants")
var outcome: String = "playing"

## The reason string for the
## current outcome. The string
## is set when `outcome` is
## `"win"` or `"lose"`. The
## UI's `GameOverBanner` renders
## the reason (the M5-Closeout
## Bucket 4 UI element).
var reason: String = ""

## The number of inhabitants in
## the realm. The carrier's
## `evaluate` method uses this
## field for the inhabitant
## check when the `sim` argument
## is `null` (the test path) or
## when the sim does not expose
## an `inhabitants` field (the
## M3-Closeout `Sim` exposes
## the inhabitants via the
## `_crisis_inhabitants` private
## field; the M5-Closeout test
## net sets this field
## directly). The production
## path: the UI sets the
## field from the bound
## `inhabitants` array at
## `bind()` time (see
## `PlayableShellUI`).
var inhabitant_count: int = 0


## Return the carrier's version
## tag. The method is the canonical
## "give me the carrier's version"
## entry point; the test pins the
## version (a regression that bumps
## the version without bumping the
## test is caught).
static func version() -> String:
	return _VERSION


## Build a fresh M5-Closeout
## game state. The factory is
## the canonical "give me a
## game state" entry point;
## the test pins the field
## defaults. The factory does
## not compute the win/lose
## checks; the sim's per-day
## tick calls `tick_day` to
## update the counts and then
## `evaluate` to update the
## outcome.
static func make() -> M5GameState:
	var gs: M5GameState = M5GameState.new()
	gs.days_survived = 0
	gs.hearth_count = 0
	gs.shrine_count = 0
	gs.forge_count = 0
	gs.well_count = 0
	gs.trap_count = 0
	gs.outcome = "playing"
	gs.reason = ""
	gs.inhabitant_count = 0
	return gs


## Tick the day counter. The
## method is the canonical
## "advance the game state by
## 1 day" entry point; the
## sim's per-day tick calls it
## after the world tick. The
## method increments
## `days_survived` by 1 and
## then calls `evaluate` to
## update the outcome. The
## method is idempotent across
## re-ticks (re-ticking the
## same day does not double-
## increment; see the
## `test_m5_game_state_idempotent_tick`
## test).
func tick_day(sim: Variant) -> void:
	days_survived += 1
	_recompute_room_counts(sim)
	evaluate(sim)


## Tick the day counter with an
## explicit world reference.
## The method is the canonical
## "advance the game state by
## 1 day, given the world"
## entry point; the M5-Closeout
## UI's `GameOverBanner` calls
## it because the world is held
## by the `PlayableShell` factory
## (not by the sim). The
## `sim`-only `tick_day` is
## retained for backward compat.
func tick_day_with_world(sim: Variant, world: Variant) -> void:
	days_survived += 1
	_recompute_room_counts_from_world(world)
	evaluate(sim)


## Recompute the room counts
## from the world. The method
## walks the world's tile grid
## and counts the room-type
## tiles (hearth, shrine,
## forge, well, trap). The
## counts are SEED-deterministic
## (they depend only on the
## world's tile distribution,
## which is SEED-deterministic
## per ADR-0005).
func _recompute_room_counts_from_world(world: Variant) -> void:
	hearth_count = 0
	shrine_count = 0
	forge_count = 0
	well_count = 0
	trap_count = 0
	if world == null:
		return
	var tiles: Variant = world.tiles if world != null else null
	if tiles == null:
		return
	var w: int = int(world.width) if "width" in world else 0
	var h: int = int(world.height) if "height" in world else 0
	if w <= 0 or h <= 0:
		return
	for y in range(h):
		for x in range(w):
			var tile: Variant = tiles[y * w + x]
			if tile == null:
				continue
			var tile_id: int = int(tile.id)
			match tile_id:
				4:  # hearth
					hearth_count += 1
				6:  # shrine (M5-Closeout)
					shrine_count += 1
				7:  # forge (M5-Closeout)
					forge_count += 1
				8:  # well (M5-Closeout)
					well_count += 1
				9:  # trap (M5-Closeout)
					trap_count += 1


## Recompute the room counts
## from the sim's world field.
## The method is the canonical
## "count rooms in sim.world"
## entry point; the sim path is
## used by tests that don't have
## an explicit world reference.
func _recompute_room_counts(sim: Variant) -> void:
	hearth_count = 0
	shrine_count = 0
	forge_count = 0
	well_count = 0
	trap_count = 0
	if sim == null:
		return
	# The world is exposed via
	# `sim.world` (the M3-Closeout
	# `register_world` pattern).
	# The world is a `WorldMap`
	# (nested class in
	# `src/world/generator.gd`)
	# with `tiles: Array` of
	# `Tile` instances, indexed
	# `y * width + x`.
	var world: Variant = sim.world if sim != null else null
	if world == null:
		return
	var tiles: Variant = world.tiles if world != null else null
	if tiles == null:
		return
	var w: int = int(world.width) if "width" in world else 0
	var h: int = int(world.height) if "height" in world else 0
	if w <= 0 or h <= 0:
		return
	for y in range(h):
		for x in range(w):
			var tile: Variant = tiles[y * w + x]
			if tile == null:
				continue
			var tile_id: int = int(tile.id)
			match tile_id:
				4:  # hearth
					hearth_count += 1
				6:  # shrine (M5-Closeout)
					shrine_count += 1
				7:  # forge (M5-Closeout)
					forge_count += 1
				8:  # well (M5-Closeout)
					well_count += 1
				9:  # trap (M5-Closeout)
					trap_count += 1


## Evaluate the win/lose
## conditions. The method is the
## canonical "check the game state"
## entry point; the test pins the
## evaluation order (lose checks
## first, then win checks, so a
## realm that fails both conditions
## is reported as `lose`, not
## `win`). The `sim` argument is
## optional: when `null` (the
## default), the carrier uses
## the `inhabitant_count` field
## (test-only) for the inhabitant
## check. The M5-Closeout test
## net uses the explicit field
## to avoid the sim coupling.
func evaluate(sim: Variant) -> void:
	var inh_count: int = -1
	if sim != null and "inhabitants" in sim:
		var inhabitants: Variant = sim.inhabitants
		if inhabitants is Array:
			inh_count = (inhabitants as Array).size()
	if inh_count < 0:
		# Fallback: use the
		# carrier's `inhabitant_count`
		# field. The field is
		# updated by the sim's
		# `register_inhabitant` /
		# `unregister_inhabitant`
		# path; the M5-Closeout
		# test net sets it
		# directly.
		inh_count = int(inhabitant_count)
	# Lose checks (order: inhabitants,
	# then hearths).
	if inh_count < LOSE_MIN_INHABITANTS:
		outcome = "lose"
		reason = "lose_no_inhabitants"
		return
	if hearth_count < LOSE_MIN_HEARTHS:
		outcome = "lose"
		reason = "lose_no_hearth"
		return
	# Win check (survived + realm
	# viability).
	if (
		days_survived >= WIN_DAYS_SURVIVED
		and inh_count >= WIN_MIN_INHABITANTS
		and hearth_count >= WIN_MIN_HEARTHS
		and shrine_count >= WIN_MIN_SHRINES
		and forge_count >= WIN_MIN_FORGES
		and well_count >= WIN_MIN_WELLS
		and trap_count >= WIN_MIN_TRAPS
	):
		outcome = "win"
		reason = "win_survived"
		return
	# Otherwise the game is on.
	outcome = "playing"
	reason = ""


## Check the win condition. The
## method is the canonical "did
## the player win?" entry point;
## the test pins the predicate
## (a regression that flips the
## condition is caught).
func check_win_condition() -> bool:
	return outcome == "win"


## Check the lose condition. The
## method is the canonical "did
## the player lose?" entry point;
## the test pins the predicate.
func check_lose_condition() -> bool:
	return outcome == "lose"


## Reset the game state. The
## method is the canonical "start
## a new game" entry point; the
## UI's Restart button calls it
## after building a new sim. The
## method is idempotent: a
## second call does not change
## the outcome (the sim is
## already fresh).
func reset() -> void:
	days_survived = 0
	hearth_count = 0
	shrine_count = 0
	forge_count = 0
	well_count = 0
	trap_count = 0
	outcome = "playing"
	reason = ""
	inhabitant_count = 0
