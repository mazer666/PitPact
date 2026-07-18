# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Bucket 2: Co-op
# Lobby.
#
# The M9 closeout ships a
# headless, in-memory coop lobby.
# The lobby tracks peers (2-4
# per ADR-0021), the host's
# identity, and the sim seed.
#
# The M9 closeout does NOT ship
# a real ENet adapter (per
# ADR-0021 §Out of scope); the
# adapter is the M9.1 closeout's
# job. The M9 closeout's tests
# verify the in-memory state
# machine.
class_name CoopLobby
extends RefCounted

# The canonical M9 lobby
# constants. The M9 closeout
# supports 2-4 players per
# ADR-0021.
const _MIN_PEERS: int = 2
const _MAX_PEERS: int = 4

# Internal state. The M9
# closeout keeps it private
# (the M9.1 closeout can add
# persistence).
var _is_host: bool = false
var _peer_count: int = 0
var _seed: int = 0
var _peers: Array = []


# `version()` returns the
# canonical M9 version string.
# The M9 closeout pins the
# version per ADR-0021.
static func version() -> String:
	return "0.5.0-m9-coop-foundation"


# `make()` creates a fresh
# lobby. The M9 closeout
# supports host-only (the M9.1
# closeout adds join-by-code).
static func make(host: bool, peer_count: int) -> CoopLobby:
	var lobby: CoopLobby = CoopLobby.new()
	lobby._is_host = host
	lobby._peer_count = peer_count
	lobby._seed = 0
	lobby._peers = []
	return lobby


# `add_peer()` adds a peer to
# the lobby. Returns the new
# peer count. The M9 closeout
# rejects peers above
# `_MAX_PEERS`.
func add_peer(peer_id: int) -> int:
	if _peer_count >= _MAX_PEERS:
		return _peer_count
	_peers.append(peer_id)
	_peer_count += 1
	return _peer_count


# `remove_peer()` removes a
# peer. Returns the new peer
# count. The M9 closeout
# requires at least
# `_MIN_PEERS` for the lobby
# to remain valid.
func remove_peer(peer_id: int) -> int:
	var idx: int = _peers.find(peer_id)
	if idx < 0:
		return _peer_count
	_peers.remove_at(idx)
	_peer_count -= 1
	return _peer_count


# `peer_count()` returns the
# current number of peers
# (including host).
func peer_count() -> int:
	return _peer_count


# `is_host()` returns whether
# this lobby is the host.
func is_host() -> bool:
	return _is_host


# `set_seed()` sets the sim
# seed. The M9 closeout
# requires the seed to be set
# before the lobby can start.
func set_seed(seed: int) -> int:
	_seed = seed
	return _seed


# `get_seed()` returns the
# current sim seed.
func get_seed() -> int:
	return _seed


# `is_valid()` returns whether
# the lobby is in a valid
# state (peer count in range,
# seed set).
func is_valid() -> bool:
	if _peer_count < _MIN_PEERS:
		return false
	if _peer_count > _MAX_PEERS:
		return false
	if _seed == 0:
		return false
	return true


# `peers()` returns the list
# of peer IDs (read-only).
func peers() -> Array:
	return _peers.duplicate()
