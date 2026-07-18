# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Closeout Bucket 4 (Success/Failure/Restart)
# test net.
#
# This test net exercises the M5-Closeout
# Bucket 4 deliverable: the `M5GameState`
# carrier + the win/lose conditions +
# the restart loop. The net is the
# regression barrier for the
# "M5-Closeout §Bucket 4" entry in
# the milestone plan; the M5-Closeout
# ADR-0017 documents the design intent.
extends GutTest

const _PS_PATH: String = "res://src/ui/playable_shell.gd"
const _PSUI_PATH: String = "res://src/ui/playable_shell_ui.gd"
const _GS_PATH: String = "res://src/sim/m5_game_state.gd"
const _SHELL_PATH: String = "res://scenes/main/PlayableShell.tscn"


func test_m5_game_state_make_creates_default() -> void:
	# The factory produces a fresh
	# game state with the canonical
	# defaults. The test pins the
	# initial outcome (`playing`),
	# the initial day count (0),
	# and the initial room counts
	# (all 0).
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	assert_eq(gs.days_survived, 0, "days_survived starts at 0")
	assert_eq(gs.hearth_count, 0, "hearth_count starts at 0")
	assert_eq(gs.shrine_count, 0, "shrine_count starts at 0")
	assert_eq(gs.forge_count, 0, "forge_count starts at 0")
	assert_eq(gs.well_count, 0, "well_count starts at 0")
	assert_eq(gs.trap_count, 0, "trap_count starts at 0")
	assert_eq(gs.outcome, "playing", "outcome starts at 'playing'")
	assert_eq(gs.reason, "", "reason starts at ''")
	assert_eq(gs.inhabitant_count, 0, "inhabitant_count starts at 0")


func test_m5_game_state_version_is_pinned() -> void:
	# The version tag is the
	# canonical "give me the
	# carrier's version" entry
	# point. The M5-Closeout
	# version is `0.2.0-m5-closeout`.
	var GS: GDScript = load(_GS_PATH)
	assert_eq(GS.call("version"), "0.2.0-m5-closeout", "M5GameState version is '0.2.0-m5-closeout'")


func test_m5_game_state_tick_increments_days() -> void:
	# The `tick_day` method
	# increments `days_survived`
	# by 1. The test pins the
	# increment.
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	gs.days_survived = 5
	# `tick_day` needs a sim, but
	# the day count increments
	# before the recompute. Use
	# `null` for the sim (the
	# recompute is a no-op when
	# sim is null).
	gs.tick_day(null)
	assert_eq(gs.days_survived, 6, "tick_day increments days_survived by 1")


func test_m5_game_state_idempotent_tick() -> void:
	# Re-ticking the same day
	# should not double-increment
	# if the carrier uses a
	# monotonic counter. The
	# M5-Closeout uses a
	# monotonic counter, so a
	# second tick does increment
	# (the test pins the behavior
	# so a regression that changes
	# the semantics is caught).
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	gs.tick_day(null)
	gs.tick_day(null)
	assert_eq(gs.days_survived, 2, "two ticks = 2 days")


func test_m5_game_state_lose_no_inhabitants() -> void:
	# The lose condition fires
	# when the realm has 0
	# inhabitants. The test pins
	# the reason string.
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	# No inhabitants -> lose.
	gs.inhabitant_count = 0
	gs.evaluate(null)
	assert_eq(gs.outcome, "lose", "0 inhabitants = lose")
	assert_eq(gs.reason, "lose_no_inhabitants", "reason = 'lose_no_inhabitants'")


func test_m5_game_state_lose_no_hearth() -> void:
	# The lose condition fires
	# when the realm has 0
	# hearths. The test pins the
	# reason string.
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	# 1 inhabitant count + 0
	# hearths -> lose.
	gs.inhabitant_count = 1
	gs.days_survived = 5
	gs.evaluate(null)
	# With 1 inhabitant the
	# inhabitant check passes
	# (>= LOSE_MIN_INHABITANTS = 1),
	# but 0 hearths triggers
	# the hearth check.
	assert_eq(gs.outcome, "lose", "0 hearths = lose")
	assert_eq(gs.reason, "lose_no_hearth", "reason = 'lose_no_hearth'")


func test_m5_game_state_win_requires_all_rooms() -> void:
	# The win condition requires
	# days_survived >= 30 AND
	# at least 1 hearth + 1 shrine
	# + 1 forge + 1 well + 1 trap.
	# The test pins the
	# multi-constraint.
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	gs.days_survived = 30
	gs.inhabitant_count = 4
	gs.hearth_count = 1
	gs.shrine_count = 0  # missing
	gs.forge_count = 1
	gs.well_count = 1
	gs.trap_count = 1
	gs.evaluate(null)
	# Missing shrine -> still
	# playing (the win check
	# requires all 5 rooms).
	assert_eq(gs.outcome, "playing", "missing shrine = still playing")
	# Add shrine.
	gs.shrine_count = 1
	gs.evaluate(null)
	assert_eq(gs.outcome, "win", "all rooms + days = win")
	assert_eq(gs.reason, "win_survived", "reason = 'win_survived'")


func test_m5_game_state_win_requires_30_days() -> void:
	# The win condition requires
	# days_survived >= 30. A
	# regression that lowers the
	# threshold to 0 lets the
	# player win immediately; the
	# test pins the threshold by
	# asserting that 29 days is
	# not enough.
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	gs.days_survived = 29
	gs.inhabitant_count = 4
	gs.hearth_count = 1
	gs.shrine_count = 1
	gs.forge_count = 1
	gs.well_count = 1
	gs.trap_count = 1
	gs.evaluate(null)
	assert_eq(gs.outcome, "playing", "29 days + all rooms = still playing (need 30)")
	gs.days_survived = 30
	gs.evaluate(null)
	assert_eq(gs.outcome, "win", "30 days + all rooms = win")


func test_m5_game_state_reset() -> void:
	# The `reset` method clears
	# all fields. The test pins
	# the reset semantics.
	var GS: GDScript = load(_GS_PATH)
	var gs: M5GameState = GS.make()
	gs.days_survived = 30
	gs.outcome = "win"
	gs.reason = "win_survived"
	gs.reset()
	assert_eq(gs.days_survived, 0, "reset clears days_survived")
	assert_eq(gs.outcome, "playing", "reset clears outcome")
	assert_eq(gs.reason, "", "reset clears reason")


func test_playable_shell_includes_game_state() -> void:
	# The M5-Closeout factory
	# returns a `game_state`
	# key. The test pins the
	# key + the carrier type.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	assert_ne(built.get("game_state", null), null, "build() returns game_state key")
	var gs: M5GameState = built["game_state"]
	assert_true(gs is M5GameState, "game_state is a M5GameState")


func test_playable_shell_includes_world() -> void:
	# The M5-Closeout factory
	# returns a `world` key.
	# The test pins the key.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	assert_ne(built.get("world", null), null, "build() returns world key")


func test_playable_shell_includes_seed() -> void:
	# The M5-Closeout factory
	# returns a `seed` key.
	# The test pins the key +
	# the value (the canonical
	# SEED = 4242).
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	assert_eq(built.get("seed", -1), 4242, "build() returns seed=4242")


func test_playable_shell_build_with_seed_overrides() -> void:
	# The M5-Closeout
	# `build_with_seed` factory
	# builds a fresh sim with
	# the override seed. The
	# test pins the override
	# behavior.
	var PS: GDScript = load(_PS_PATH)
	var fresh: Dictionary = PS.call("build_with_seed", 9999)
	assert_eq(fresh.get("seed", -1), 9999, "build_with_seed(9999) returns seed=9999")
	# The default factory
	# should still return the
	# canonical SEED after the
	# override.
	var default: Dictionary = PS.call("build")
	assert_eq(default.get("seed", -1), 4242, "default build() returns seed=4242 after override")


func test_playable_shell_world_has_hearth_tile() -> void:
	# The M5-Closeout
	# `WorldGenerator` sets
	# `tile.id = 4` (hearth) on
	# the hearth tile. The test
	# pins the tile id.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var world: Variant = built["world"]
	var tiles: Array = world.tiles
	var w: int = int(world.width)
	var h: int = int(world.height)
	# Walk the grid and find at
	# least one tile with id=4.
	var found: bool = false
	for y in range(h):
		for x in range(w):
			var tile: Variant = tiles[y * w + x]
			if tile != null and int(tile.id) == 4:
				found = true
				break
		if found:
			break
	assert_true(found, "world has at least one hearth tile (id=4)")


func test_playable_shell_game_state_counts_hearth() -> void:
	# The M5-Closeout
	# `M5GameState` counts the
	# hearth tiles in the world.
	# The test pins the count
	# (the canonical M5-Foundation
	# world has 1 hearth at the
	# realm anchor).
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var gs: M5GameState = built["game_state"]
	# Tick once to recompute
	# the room counts.
	gs.tick_day_with_world(built["sim"], built["world"])
	assert_gte(gs.hearth_count, 1, "hearth_count >= 1 after tick_day_with_world")


func test_playable_shell_ui_shows_game_over_banner() -> void:
	# The M5-Closeout UI's
	# `GameOverBanner` is
	# visible when the game
	# state is `win` or `lose`.
	# The test pins the banner
	# visibility.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	add_child_autofree(shell)
	shell.bind(built)
	# Force the game-over state
	# directly on the carrier.
	shell.game_state.outcome = "win"
	shell.game_state.reason = "win_survived"
	shell.call("_show_game_over")
	# The banner should now be
	# visible.
	var banner: Node = shell.get_node("GameOverBanner")
	assert_true(banner.visible, "GameOverBanner is visible after _show_game_over()")


func test_playable_shell_ui_hides_game_over_banner_on_restart() -> void:
	# The M5-Closeout UI's
	# `_on_restart_pressed`
	# hides the banner and
	# rebuilds the sim. The
	# test pins the restart
	# behavior.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	add_child_autofree(shell)
	shell.bind(built)
	# Force the game-over state.
	shell.game_state.outcome = "lose"
	shell.game_state.reason = "lose_no_inhabitants"
	shell.call("_show_game_over")
	var banner: Node = shell.get_node("GameOverBanner")
	assert_true(banner.visible, "GameOverBanner is visible before restart")
	# Trigger the restart.
	shell._on_restart_pressed()
	# The banner should be
	# hidden after the restart.
	assert_false(banner.visible, "GameOverBanner is hidden after restart")
	# The sim should be a fresh
	# instance (the M5-Closeout
	# restart loop).
	assert_ne(shell.sim, built["sim"], "restart produces a fresh sim")
	# The seed should be bumped
	# (the M5-Closeout restart
	# loop's invariants).
	assert_eq(shell._current_seed, 4243, "_current_seed is bumped to 4243 (was 4242)")


func test_playable_shell_ui_step_ticks_game_state() -> void:
	# The M5-Closeout UI's
	# `_on_step_pressed` must
	# tick the game state carrier
	# (the M5-Closeout §Bucket 4
	# win/lose path). The test
	# pins the day count after
	# one step.
	var PS: GDScript = load(_PS_PATH)
	var built: Dictionary = PS.call("build")
	var ps_scene: PackedScene = load(_SHELL_PATH)
	var shell: Node = ps_scene.instantiate()
	add_child_autofree(shell)
	shell.bind(built)
	# Reset days to 0 (the
	# carrier starts at 0).
	shell.game_state.days_survived = 0
	# Step once.
	shell.call("_on_step_pressed")
	# The day count should be
	# 1 (the carrier ticked
	# once). A regression that
	# skips the tick leaves
	# the count at 0.
	assert_eq(shell.game_state.days_survived, 1, "game_state.days_survived = 1 after 1 step")
