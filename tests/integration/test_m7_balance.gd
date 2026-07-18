# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M7 Bucket 2 (Balance Pass)
# test net.
extends GutTest

const _M7BC_PATH: String = "res://src/sim/m7_balance.gd"


func test_balance_config_version() -> void:
	# The M7 balance config has
	# the canonical version tag.
	var M7BC: GDScript = load(_M7BC_PATH)
	assert_eq(
		M7BC.call("version"),
		"0.3.0-m7-content-and-balance",
		"M7BalanceConfig version is '0.3.0-m7-content-and-balance'"
	)


func test_balance_config_m7_balanced_defaults() -> void:
	# The M7 balanced factory
	# produces the canonical M7
	# values.
	var M7BC: GDScript = load(_M7BC_PATH)
	var cfg: M7BalanceConfig = M7BC.call("m7_balanced")
	assert_eq(cfg.win_days_survived, 45, "win_days_survived = 45")
	assert_eq(cfg.win_min_inhabitants, 6, "win_min_inhabitants = 6")
	assert_eq(cfg.win_min_hearths, 1, "win_min_hearths = 1")
	assert_eq(cfg.win_min_shrines, 1, "win_min_shrines = 1")
	assert_eq(cfg.win_min_forges, 1, "win_min_forges = 1")
	assert_eq(cfg.win_min_wells, 1, "win_min_wells = 1")
	assert_eq(cfg.win_min_traps, 1, "win_min_traps = 1")
	assert_eq(cfg.lose_min_inhabitants, 2, "lose_min_inhabitants = 2")
	assert_eq(cfg.lose_min_hearths, 1, "lose_min_hearths = 1")


func test_balance_config_easy() -> void:
	# The easy factory produces
	# an easier-than-balanced
	# mode (20 days, 3 inhabitants).
	var M7BC: GDScript = load(_M7BC_PATH)
	var cfg: M7BalanceConfig = M7BC.call("easy")
	assert_eq(cfg.win_days_survived, 20, "easy win_days = 20")
	assert_eq(cfg.win_min_inhabitants, 3, "easy min_inhabitants = 3")
	assert_eq(cfg.lose_min_inhabitants, 1, "easy lose_inhabitants = 1")


func test_balance_config_hard() -> void:
	# The hard factory produces
	# a harder-than-balanced
	# mode (60 days, 8 inhabitants).
	var M7BC: GDScript = load(_M7BC_PATH)
	var cfg: M7BalanceConfig = M7BC.call("hard")
	assert_eq(cfg.win_days_survived, 60, "hard win_days = 60")
	assert_eq(cfg.win_min_inhabitants, 8, "hard min_inhabitants = 8")
	assert_eq(cfg.lose_min_inhabitants, 3, "hard lose_inhabitants = 3")


func test_balance_config_is_valid() -> void:
	# The M7 balanced config
	# passes the validity check.
	var M7BC: GDScript = load(_M7BC_PATH)
	var cfg: M7BalanceConfig = M7BC.call("m7_balanced")
	assert_true(cfg.is_valid(), "m7_balanced config is valid")
	var easy: M7BalanceConfig = M7BC.call("easy")
	assert_true(easy.is_valid(), "easy config is valid")
	var hard: M7BalanceConfig = M7BC.call("hard")
	assert_true(hard.is_valid(), "hard config is valid")


func test_balance_config_is_valid_rejects_zero_days() -> void:
	# A config with win_days = 0
	# is invalid (would mean
	# instant win).
	var M7BC: GDScript = load(_M7BC_PATH)
	var cfg: M7BalanceConfig = M7BC.call("m7_balanced")
	cfg.win_days_survived = 0
	assert_false(cfg.is_valid(), "win_days = 0 is invalid")


func test_balance_config_constants_pinned() -> void:
	# The M7 balance constants
	# are pinned in the M7 test
	# net (a regression that
	# changes the constants is
	# caught).
	var M7BC: GDScript = load(_M7BC_PATH)
	assert_eq(int(M7BC.M7_WIN_DAYS_SURVIVED), 45, "M7_WIN_DAYS_SURVIVED = 45")
	assert_eq(int(M7BC.M7_WIN_MIN_INHABITANTS), 6, "M7_WIN_MIN_INHABITANTS = 6")
	assert_eq(int(M7BC.M7_LOSE_MIN_INHABITANTS), 2, "M7_LOSE_MIN_INHABITANTS = 2")
