# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 5:
# Lobby Server.
#
# The M15 closeout ships an
# in-memory lobby server. The
# server tracks registered
# lobbies (game sessions) +
# supports listing + filtering.
#
# The M15 closeout's tests
# verify the register /
# unregister / list / filter
# API. The production path
# (M15.1) replaces the in-memory
# registry with a cloud-backed
# service.
class_name LobbyServer
extends RefCounted

# The canonical M15 version.
# The M15 closeout pins the
# version per ADR-0027.
const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"

# `version()` returns the
# canonical M15 version
# string.
# Internal state.
var _lobbies: Dictionary = {}


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# lobby server.
static func make() -> LobbyServer:
	var ls: LobbyServer = LobbyServer.new()
	ls._lobbies = {}
	return ls


# `register_lobby()` registers
# a new lobby. Returns 0 on
# success, -1 if invalid.
func register_lobby(
	lobby_id: StringName, host: String, port: int, max_players: int, metadata: Dictionary = {}
) -> int:
	if lobby_id == &"" or port <= 0 or max_players <= 0:
		return -1
	_lobbies[lobby_id] = {
		"host": host,
		"port": port,
		"max_players": max_players,
		"current_players": 1,
		"metadata": metadata.duplicate(true),
		"registered_at": Time.get_unix_time_from_system()
	}
	return 0


# `unregister_lobby()` removes
# a lobby. Returns 0 on
# success, -1 if not found.
func unregister_lobby(lobby_id: StringName) -> int:
	if not _lobbies.has(lobby_id):
		return -1
	_lobbies.erase(lobby_id)
	return 0


# `list_lobbies()` returns a
# list of lobbies matching
# the filter. The filter is
# a Dictionary of metadata
# key-value pairs (all must
# match).
func list_lobbies(filter: Dictionary = {}) -> Array:
	var out: Array = []
	for id in _lobbies.keys():
		var lobby: Dictionary = _lobbies[id]
		if _matches_filter(lobby, filter):
			var entry: Dictionary = lobby.duplicate(true)
			entry["lobby_id"] = id
			out.append(entry)
	return out


# `lobby_count()` returns
# the total number of
# registered lobbies.
func lobby_count() -> int:
	return _lobbies.size()


# `get_lobby()` returns the
# lobby with the given ID.
# Returns an empty dict if
# not found.
func get_lobby(lobby_id: StringName) -> Dictionary:
	if not _lobbies.has(lobby_id):
		return {}
	var lobby: Dictionary = _lobbies[lobby_id]
	var entry: Dictionary = lobby.duplicate(true)
	entry["lobby_id"] = lobby_id
	return entry


# `update_player_count()`
# updates the current player
# count of a lobby.
func update_player_count(lobby_id: StringName, count: int) -> int:
	if not _lobbies.has(lobby_id):
		return -1
	_lobbies[lobby_id]["current_players"] = count
	return 0


# `_matches_filter()` returns
# whether a lobby matches the
# given filter.
func _matches_filter(lobby: Dictionary, filter: Dictionary) -> bool:
	var metadata: Dictionary = lobby.get("metadata", {})
	for key in filter.keys():
		if metadata.get(key, null) != filter[key]:
			return false
	return true
