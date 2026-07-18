# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Bucket 2: Peer
# Sync.
#
# The M10 closeout ships a
# real-time peer-sync carrier
# that uses the M9
# `CoopProtocol` to hash states
# and broadcast them to peers.
#
# The M10 closeout's `tick()`
# broadcasts the local state's
# hash and receives remote
# states. The carrier tracks
# per-peer desync events for
# post-mortem debugging.
#
# The M10 closeout's tests
# use the M9 lockstep protocol
# (FNV-1a 64-bit hash) and the
# M10 ENet adapter for
# loopback. The production
# path uses real ENet
# (M10.1 closeout's job).
class_name PeerSync
extends RefCounted

# The canonical M10 version.
# The M10 closeout pins the
# version per ADR-0022.
const VERSION_STRING: String = "0.6.0-m10-coop-live"

# `version()` returns the
# canonical M10 version
# string.
# Internal state.
var _adapter: EnetAdapter = null
var _tick_rate_ms: int = 0
var _local_state: Dictionary = {}
var _remote_states: Dictionary = {}
var _desync_count: int = 0
var _last_tick: int = -1


static func version() -> String:
	return VERSION_STRING


# `make()` creates a peer-sync
# instance. The `adapter` is
# the M10 ENet adapter; the
# `tick_rate_ms` is the
# broadcast interval.
static func make(adapter: EnetAdapter, tick_rate_ms: int) -> PeerSync:
	var ps: PeerSync = PeerSync.new()
	ps._adapter = adapter
	ps._tick_rate_ms = tick_rate_ms
	ps._local_state = {}
	ps._remote_states = {}
	ps._desync_count = 0
	ps._last_tick = -1
	return ps


# `tick()` broadcasts the
# local state's hash and
# returns the list of
# (peer_id, state_hash) tuples
# received from peers. The
# M10 closeout's tick uses
# `CoopProtocol.hash_state()`
# for the hash.
func tick(local_state: Dictionary) -> Array:
	_local_state = local_state
	var local_hash: int = CoopProtocol.hash_state(local_state)
	# Broadcast the local hash
	# to all peers.
	if _adapter != null and _adapter.is_adapter_active():
		_adapter.send(0, {"type": "state_hash", "hash": local_hash, "tick": _last_tick + 1})
	# Drain incoming events.
	var events: Array = _adapter.poll() if _adapter != null else []
	var received: Array = []
	for ev in events:
		if ev.get("type", "") == "receive":
			var data: Dictionary = ev.get("data", {})
			if data.get("type", "") == "state_hash":
				# Skip the local
				# broadcast (peer_id
				# 0 is the local
				# adapter's
				# broadcast target).
				var peer_id: int = ev.get("peer_id", 0)
				if peer_id == 0:
					continue
				var remote_hash: int = data.get("hash", 0)
				_remote_states[peer_id] = remote_hash
				# Check for desync.
				if remote_hash != local_hash:
					_desync_count += 1
				received.append({"peer_id": peer_id, "hash": remote_hash})
	_last_tick += 1
	return received


# `peers_in_sync()` returns
# true if all known peers
# have the same state hash
# as the local state.
func peers_in_sync() -> bool:
	if _remote_states.is_empty():
		return true
	var local_hash: int = CoopProtocol.hash_state(_local_state)
	for peer_id in _remote_states.keys():
		if _remote_states[peer_id] != local_hash:
			return false
	return true


# `desync_count()` returns
# the total number of desync
# events detected.
func desync_count() -> int:
	return _desync_count


# `last_remote_state()` returns
# the last seen hash for the
# given peer. Returns -1 if
# the peer is unknown.
func last_remote_state(peer_id: int) -> int:
	if not _remote_states.has(peer_id):
		return -1
	return _remote_states[peer_id]


# `local_state()` returns the
# last local state.
func local_state() -> Dictionary:
	return _local_state.duplicate(true)


# `peer_count()` returns the
# number of known remote
# peers.
func peer_count() -> int:
	return _remote_states.size()
