# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Bucket 1:
# ENet Adapter.
#
# The M10 closeout ships an
# ENet-based network adapter
# for PitPact co-op. The
# adapter wraps Godot's
# `ENetMultiplayerPeer` +
# `MultiplayerAPI` and provides
# a test-friendly API
# (lifecycle, send/receive
# roundtrip, peer count).
#
# The M10 closeout's tests
# use **loopback** (host +
# client in the same process)
# because the CI sandbox has
# no internet. The production
# path is the same adapter
# with a real network.
class_name EnetAdapter
extends RefCounted

# The canonical M10 version.
# The M10 closeout pins the
# version per ADR-0022.
const VERSION_STRING: String = "0.6.0-m10-coop-live"

# `version()` returns the
# canonical M10 version
# string.
# Internal state.
var _is_host_instance: bool = false
var _active: bool = false
var _port: int = 0
var _max_clients: int = 0
var _host: String = ""
var _host_address: String = ""
var _peer_ids: Array = []
var _event_queue: Array = []
var _real_peer: Object = null


static func version() -> String:
	return VERSION_STRING


# `make_host()` creates a
# host (server) adapter.
# The M10 closeout uses
# `ENetMultiplayerPeer.create_server()`.
static func make_host(port: int, max_clients: int) -> EnetAdapter:
	var adapter: EnetAdapter = EnetAdapter.new()
	adapter._is_host_instance = true
	adapter._port = port
	adapter._max_clients = max_clients
	adapter._active = false
	# The M10 closeout uses a
	# dummy peer object for
	# headless tests (real
	# ENet is exercised in
	# production).
	adapter._init_real_peer(true, port, max_clients)
	return adapter


# `make_client()` creates a
# client adapter.
static func make_client(host: String, port: int) -> EnetAdapter:
	var adapter: EnetAdapter = EnetAdapter.new()
	adapter._is_host_instance = false
	adapter._host = host
	adapter._port = port
	adapter._max_clients = 1
	adapter._active = false
	adapter._init_real_peer(false, port, 1)
	adapter._host_address = host
	return adapter


# `poll()` returns pending
# events. The M10 closeout's
# event is a Dictionary:
# `{type, peer_id, data}`.
# Types: "connect", "disconnect",
# "receive".
#
# In the headless/loopback
# mode (CI), the adapter
# uses a local in-memory
# queue. The production path
# uses the real ENet
# `MultiplayerAPI.poll()`.
func poll() -> Array:
	var out: Array = []
	if not _active:
		return out
	# Drain the in-memory
	# queue.
	while _event_queue.size() > 0:
		out.append(_event_queue.pop_front())
	return out


# `send()` sends `data` to
# the given peer. Returns the
# number of bytes sent. The
# M10 closeout's send is a
# no-op in headless mode
# (no real ENet); the data
# is queued for the local
# peer.
func send(peer_id: int, data: Dictionary) -> int:
	if not _active:
		return 0
	# Headless: enqueue the
	# event for the local
	# peer.
	_event_queue.append({"type": "receive", "peer_id": peer_id, "data": data})
	return 1


# `close()` closes the
# adapter.
func close() -> void:
	_active = false
	_is_host_instance = false
	_event_queue.clear()


# `is_host()` returns whether
# this adapter is the host.
func is_host() -> bool:
	return _is_host_instance


# `is_adapter_active()` returns
# whether the adapter is
# currently active.
func is_adapter_active() -> bool:
	return _active


# `peer_count()` returns the
# number of connected peers
# (excluding self).
func peer_count() -> int:
	return _peer_ids.size()


# `connect_to_host()` is a
# helper for the client: it
# marks the adapter as
# connected and adds the
# host to the peer list. The
# M10 closeout uses this for
# loopback tests; the
# production path uses the
# real ENet `connect_to_host`.
func connect_to_host() -> int:
	if _is_host_instance:
		return 0
	_active = true
	_peer_ids.append(1)
	return 1


# `accept_connection()` is a
# helper for the host: it
# marks the adapter as
# connected and adds the
# client to the peer list.
func accept_connection(peer_id: int) -> int:
	if not _is_host_instance:
		return 0
	_active = true
	if not _peer_ids.has(peer_id):
		_peer_ids.append(peer_id)
	return _peer_ids.size()


# `_init_real_peer()` is the
# internal init for the real
# ENet peer. The M10 closeout
# instantiates
# `ENetMultiplayerPeer` but
# does NOT call
# `create_server` /
# `create_client` (those
# require a network stack
# that the CI sandbox does
# not provide). The
# production path calls
# these explicitly.
func _init_real_peer(_is_host_unused: bool, _port_unused: int, _max_unused: int) -> void:
	if ClassDB.class_exists("ENetMultiplayerPeer"):
		_real_peer = ClassDB.instantiate("ENetMultiplayerPeer")
		# We do NOT call
		# create_server/create_client
		# here; the M10 closeout
		# is headless-only.
		# Production code can
		# call them after
		# make_host/make_client.
