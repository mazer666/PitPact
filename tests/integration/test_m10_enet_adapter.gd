# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Bucket 1 (ENet
# Adapter) test net.
extends GutTest

const _EA_PATH: String = "res://src/net/enet_adapter.gd"


func test_m10_enet_adapter_version() -> void:
	var EA: GDScript = load(_EA_PATH)
	var v: String = EA.call("version")
	assert_eq(v, "0.6.0-m10-coop-live", "version() returns the M10 closeout version")


func test_m10_enet_adapter_make_host() -> void:
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	assert_true(host.is_host(), "host adapter is_host=true")
	assert_false(host.is_adapter_active(), "host adapter not connected initially")


func test_m10_enet_adapter_make_client() -> void:
	var EA: GDScript = load(_EA_PATH)
	var client: Variant = EA.call("make_client", "127.0.0.1", 7777)
	assert_false(client.is_host(), "client adapter is_host=false")
	assert_false(client.is_adapter_active(), "client adapter not connected initially")


func test_m10_enet_adapter_host_accepts_connection() -> void:
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	var n: int = host.accept_connection(42)
	assert_eq(n, 1, "host has 1 peer after accept_connection")
	assert_true(host.is_adapter_active(), "host is connected after accept")
	assert_eq(host.peer_count(), 1, "peer_count=1")


func test_m10_enet_adapter_client_connects_to_host() -> void:
	var EA: GDScript = load(_EA_PATH)
	var client: Variant = EA.call("make_client", "127.0.0.1", 7777)
	var n: int = client.connect_to_host()
	assert_eq(n, 1, "client has 1 peer after connect_to_host")
	assert_true(client.is_adapter_active(), "client is connected after connect_to_host")


func test_m10_enet_adapter_send_returns_count() -> void:
	# The M10 closeout's `send()`
	# returns the number of bytes
	# sent (1 in headless mode).
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	host.accept_connection(42)
	var sent: int = host.send(42, {"type": "tick", "data": "hello"})
	assert_eq(sent, 1, "send returns 1 in headless mode")


func test_m10_enet_adapter_send_when_not_connected() -> void:
	# `send()` is a no-op when
	# the adapter is not
	# connected.
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	var sent: int = host.send(42, {"type": "tick"})
	assert_eq(sent, 0, "send returns 0 when not connected")


func test_m10_enet_adapter_poll_empty() -> void:
	# `poll()` returns an empty
	# array when no events are
	# pending.
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	host.accept_connection(42)
	var events: Array = host.poll()
	assert_eq(events.size(), 0, "no events initially")


func test_m10_enet_adapter_poll_after_send() -> void:
	# After `send()`, the local
	# adapter queues a `receive`
	# event that can be polled.
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	host.accept_connection(42)
	host.send(42, {"type": "tick", "data": "hello"})
	var events: Array = host.poll()
	assert_eq(events.size(), 1, "1 event after send")
	assert_eq(events[0]["type"], "receive", "event type is 'receive'")


func test_m10_enet_adapter_close() -> void:
	# `close()` disconnects the
	# adapter and clears the
	# event queue.
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	host.accept_connection(42)
	host.send(42, {"x": 1})
	host.close()
	assert_false(host.is_adapter_active(), "not connected after close")
	var events: Array = host.poll()
	assert_eq(events.size(), 0, "no events after close")


func test_m10_enet_adapter_host_multiple_peers() -> void:
	# The host can accept up to
	# `max_clients` peers.
	var EA: GDScript = load(_EA_PATH)
	var host: Variant = EA.call("make_host", 7777, 4)
	host.accept_connection(1)
	host.accept_connection(2)
	host.accept_connection(3)
	# Duplicate is a no-op.
	host.accept_connection(1)
	assert_eq(host.peer_count(), 3, "host has 3 unique peers")
