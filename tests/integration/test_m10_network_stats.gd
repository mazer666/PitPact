# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Side-Quest G
# (Network Stats) test net.
extends GutTest

const _NS_PATH: String = "res://src/net/network_stats.gd"


func test_m10_network_stats_version() -> void:
	var NS: GDScript = load(_NS_PATH)
	var v: String = NS.call("version")
	assert_eq(v, "0.6.0-m10-coop-live", "version() returns the M10 closeout version")


func test_m10_network_stats_record_rtt() -> void:
	var NS: GDScript = load(_NS_PATH)
	var s: Variant = NS.call("make")
	s.record_rtt(42, 10)
	s.record_rtt(42, 20)
	s.record_rtt(42, 30)
	assert_eq(s.rtt_sample_count(42), 3, "3 RTT samples recorded for peer 42")
	assert_eq(s.average_rtt(42), 20, "average RTT is (10+20+30)/3 = 20")


func test_m10_network_stats_average_unknown_peer() -> void:
	# `average_rtt()` returns 0
	# for unknown peers.
	var NS: GDScript = load(_NS_PATH)
	var s: Variant = NS.call("make")
	assert_eq(s.average_rtt(999), 0, "average_rtt for unknown peer is 0")


func test_m10_network_stats_packet_loss() -> void:
	var NS: GDScript = load(_NS_PATH)
	var s: Variant = NS.call("make")
	s.record_packet_loss(42, 5, 100)
	# 5/100 = 0.05
	var rate: float = s.packet_loss_rate(42)
	assert_almost_eq(rate, 0.05, 0.001, "packet loss rate is 5/100 = 0.05")


func test_m10_network_stats_packet_loss_unknown_peer() -> void:
	# `packet_loss_rate()`
	# returns 0.0 for unknown
	# peers.
	var NS: GDScript = load(_NS_PATH)
	var s: Variant = NS.call("make")
	assert_eq(s.packet_loss_rate(999), 0.0, "packet_loss_rate for unknown peer is 0.0")


func test_m10_network_stats_packet_loss_no_sent() -> void:
	# `packet_loss_rate()`
	# returns 0.0 when sent=0
	# (avoid division by zero).
	var NS: GDScript = load(_NS_PATH)
	var s: Variant = NS.call("make")
	s.record_packet_loss(42, 0, 0)
	assert_eq(s.packet_loss_rate(42), 0.0, "packet_loss_rate with sent=0 is 0.0")


func test_m10_network_stats_per_peer_isolation() -> void:
	# RTT samples are tracked
	# per-peer.
	var NS: GDScript = load(_NS_PATH)
	var s: Variant = NS.call("make")
	s.record_rtt(1, 10)
	s.record_rtt(2, 50)
	assert_eq(s.average_rtt(1), 10, "peer 1 avg RTT is 10")
	assert_eq(s.average_rtt(2), 50, "peer 2 avg RTT is 50")
