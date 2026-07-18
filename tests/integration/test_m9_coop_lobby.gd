# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Bucket 2 (Co-op
# Lobby) test net.
extends GutTest

const _CL_PATH: String = "res://src/net/coop_lobby.gd"


func test_m9_coop_lobby_version() -> void:
	var CL: GDScript = load(_CL_PATH)
	var v: String = CL.call("version")
	assert_eq(v, "0.5.0-m9-coop-foundation", "version() returns the M9 closeout version")


func test_m9_coop_lobby_make_host() -> void:
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 1)
	assert_true(lobby.is_host(), "host lobby is_host=true")
	assert_eq(lobby.peer_count(), 1, "1 peer (host)")


func test_m9_coop_lobby_make_client() -> void:
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", false, 1)
	assert_false(lobby.is_host(), "client lobby is_host=false")


func test_m9_coop_lobby_add_peer() -> void:
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 1)
	lobby.add_peer(42)
	assert_eq(lobby.peer_count(), 2, "peer count after add_peer")


func test_m9_coop_lobby_add_peer_max() -> void:
	# The M9 closeout caps at
	# 4 peers (per ADR-0021).
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 1)
	lobby.add_peer(1)
	lobby.add_peer(2)
	lobby.add_peer(3)
	# 4 peers total (host + 3
	# clients). Adding a 5th
	# should be a no-op.
	lobby.add_peer(4)
	assert_eq(lobby.peer_count(), 4, "peer count caps at 4 (host + 3 clients)")


func test_m9_coop_lobby_remove_peer() -> void:
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 1)
	lobby.add_peer(42)
	lobby.remove_peer(42)
	assert_eq(lobby.peer_count(), 1, "peer count after remove_peer")


func test_m9_coop_lobby_remove_nonexistent_peer() -> void:
	# Removing a peer that's not
	# in the lobby is a no-op.
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 1)
	lobby.remove_peer(99)
	assert_eq(lobby.peer_count(), 1, "removing non-existent peer is a no-op")


func test_m9_coop_lobby_invalid_until_seed_set() -> void:
	# The M9 closeout requires
	# the seed to be set before
	# the lobby is valid.
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 2)
	assert_false(lobby.is_valid(), "lobby is not valid without seed")
	lobby.set_seed(4242)
	assert_true(lobby.is_valid(), "lobby is valid after seed is set")


func test_m9_coop_lobby_invalid_below_min_peers() -> void:
	# The M9 closeout requires
	# at least 2 peers.
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 1)
	lobby.set_seed(4242)
	assert_false(lobby.is_valid(), "lobby with 1 peer is invalid")


func test_m9_coop_lobby_peers_list() -> void:
	# `peers()` returns the list
	# of peer IDs.
	var CL: GDScript = load(_CL_PATH)
	var lobby: Variant = CL.call("make", true, 1)
	lobby.add_peer(42)
	lobby.add_peer(43)
	var peers: Array = lobby.peers()
	assert_eq(peers.size(), 2, "peers() returns 2 peers")
	assert_true(42 in peers, "peer 42 in list")
	assert_true(43 in peers, "peer 43 in list")
