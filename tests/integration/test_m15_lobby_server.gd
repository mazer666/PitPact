# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 5
# (Lobby Server + NAT
# Traversal) test net.
extends GutTest

const _LS_PATH: String = "res://src/net/lobby_server.gd"
const _NT_PATH: String = "res://src/net/nat_traversal.gd"


func test_m15_lobby_server_version() -> void:
	var LS: GDScript = load(_LS_PATH)
	var v: String = LS.call("version")
	assert_eq(v, "0.11.0-m15-final-polish-coop", "version() returns the M15 closeout version")


func test_m15_lobby_server_make() -> void:
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	assert_eq(ls.lobby_count(), 0, "0 lobbies initially")


func test_m15_lobby_server_register() -> void:
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	var err: int = ls.register_lobby(&"lobby1", "127.0.0.1", 7777, 4, {"region": "eu"})
	assert_eq(err, 0, "register returns 0")
	assert_eq(ls.lobby_count(), 1, "1 lobby after register")


func test_m15_lobby_server_register_invalid() -> void:
	# Registering with empty
	# ID or invalid port
	# returns -1.
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	var err1: int = ls.register_lobby(&"", "127.0.0.1", 7777, 4)
	assert_eq(err1, -1, "empty ID returns -1")
	var err2: int = ls.register_lobby(&"l1", "127.0.0.1", 0, 4)
	assert_eq(err2, -1, "port=0 returns -1")
	var err3: int = ls.register_lobby(&"l1", "127.0.0.1", 7777, 0)
	assert_eq(err3, -1, "max_players=0 returns -1")


func test_m15_lobby_server_unregister() -> void:
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	ls.register_lobby(&"lobby1", "127.0.0.1", 7777, 4)
	var err: int = ls.unregister_lobby(&"lobby1")
	assert_eq(err, 0, "unregister returns 0")
	assert_eq(ls.lobby_count(), 0, "0 lobbies after unregister")


func test_m15_lobby_server_unregister_unknown() -> void:
	# Unregistering a non-
	# existent lobby returns
	# -1.
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	var err: int = ls.unregister_lobby(&"unknown")
	assert_eq(err, -1, "unregister unknown returns -1")


func test_m15_lobby_server_list_empty() -> void:
	# `list_lobbies()` with
	# no lobbies returns an
	# empty array.
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	var list: Array = ls.list_lobbies({})
	assert_eq(list.size(), 0, "0 lobbies in list")


func test_m15_lobby_server_list_with_filter() -> void:
	# Filter lobbies by
	# metadata.
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	ls.register_lobby(&"l1", "127.0.0.1", 7777, 4, {"region": "eu"})
	ls.register_lobby(&"l2", "127.0.0.1", 7778, 4, {"region": "us"})
	ls.register_lobby(&"l3", "127.0.0.1", 7779, 4, {"region": "eu"})
	var eu_lobbies: Array = ls.list_lobbies({"region": "eu"})
	assert_eq(eu_lobbies.size(), 2, "2 eu lobbies")


func test_m15_lobby_server_get_lobby() -> void:
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	ls.register_lobby(&"l1", "127.0.0.1", 7777, 4, {"region": "eu"})
	var lobby: Dictionary = ls.get_lobby(&"l1")
	assert_eq(lobby.get("port", 0), 7777, "lobby port=7777")
	assert_eq(lobby.get("lobby_id", &""), &"l1", "lobby_id=l1")


func test_m15_lobby_server_get_lobby_unknown() -> void:
	# `get_lobby()` for an
	# unknown ID returns an
	# empty dict.
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	var lobby: Dictionary = ls.get_lobby(&"unknown")
	assert_eq(lobby.size(), 0, "unknown lobby returns empty dict")


func test_m15_lobby_server_update_player_count() -> void:
	var LS: GDScript = load(_LS_PATH)
	var ls: Variant = LS.call("make")
	ls.register_lobby(&"l1", "127.0.0.1", 7777, 4)
	var err: int = ls.update_player_count(&"l1", 3)
	assert_eq(err, 0, "update returns 0")
	var lobby: Dictionary = ls.get_lobby(&"l1")
	assert_eq(lobby.get("current_players", 0), 3, "current_players=3")


func test_m15_nat_traversal_version() -> void:
	var NT: GDScript = load(_NT_PATH)
	var v: String = NT.call("version")
	assert_eq(v, "0.11.0-m15-final-polish-coop", "version() returns the M15 closeout version")


func test_m15_nat_traversal_is_available() -> void:
	# `is_available()` returns
	# false (stub; M15.1 will
	# integrate real STUN/TURN).
	var NT: GDScript = load(_NT_PATH)
	var available: bool = NT.call("is_available")
	assert_false(available, "NAT-traversal is not available (stub)")


func test_m15_nat_traversal_connect() -> void:
	# `connect()` returns -1
	# (not available).
	var NT: GDScript = load(_NT_PATH)
	var err: int = NT.call("connect_via_nat", "127.0.0.1", 7777)
	assert_eq(err, -1, "connect returns -1 (stub)")
