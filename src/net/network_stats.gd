# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Side-Quest G:
# Network Stats.
#
# The M10 closeout ships a
# network-stats carrier for
# tracking RTT (round-trip
# time) and packet loss per
# peer. The M10 closeout's
# tests verify the in-memory
# state; the production path
# wires the stats into the
# M10 ENet adapter.
class_name NetworkStats
extends RefCounted

# The canonical M10 version.
# The M10 closeout pins the
# version per ADR-0022.
const VERSION_STRING: String = "0.6.0-m10-coop-live"

# `version()` returns the
# canonical M10 version
# string.
# Internal state.
var _rtt_samples: Dictionary = {}
var _packet_loss: Dictionary = {}


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# stats carrier.
static func make() -> NetworkStats:
	var s: NetworkStats = NetworkStats.new()
	s._rtt_samples = {}
	s._packet_loss = {}
	return s


# `record_rtt()` records an
# RTT sample (in ms) for the
# given peer. The M10
# closeout keeps all samples
# (no rolling window) for
# deterministic tests.
func record_rtt(peer_id: int, rtt_ms: int) -> void:
	if not _rtt_samples.has(peer_id):
		_rtt_samples[peer_id] = []
	_rtt_samples[peer_id].append(rtt_ms)


# `average_rtt()` returns the
# average RTT for the given
# peer. Returns 0 if no
# samples have been recorded.
func average_rtt(peer_id: int) -> int:
	if not _rtt_samples.has(peer_id):
		return 0
	var samples: Array = _rtt_samples[peer_id]
	if samples.is_empty():
		return 0
	var total: int = 0
	for s in samples:
		total += s
	return total / samples.size()


# `rtt_sample_count()` returns
# the number of RTT samples
# recorded for the given peer.
func rtt_sample_count(peer_id: int) -> int:
	if not _rtt_samples.has(peer_id):
		return 0
	return _rtt_samples[peer_id].size()


# `record_packet_loss()`
# records the packet loss
# stats (lost, sent) for the
# given peer. The M10 closeout
# stores the cumulative
# (lost, sent) counts; the
# rate is computed on demand.
func record_packet_loss(peer_id: int, lost: int, sent: int) -> void:
	_packet_loss[peer_id] = {"lost": lost, "sent": sent}


# `packet_loss_rate()` returns
# the packet loss rate
# (0.0-1.0) for the given
# peer. Returns 0.0 if no
# stats have been recorded.
func packet_loss_rate(peer_id: int) -> float:
	if not _packet_loss.has(peer_id):
		return 0.0
	var s: Dictionary = _packet_loss[peer_id]
	var sent: int = s.get("sent", 0)
	if sent == 0:
		return 0.0
	var lost: int = s.get("lost", 0)
	return float(lost) / float(sent)
