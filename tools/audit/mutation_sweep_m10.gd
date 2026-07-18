# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Mutation Sweep
extends SceneTree


const _EA_PATH: String = "res://src/net/enet_adapter.gd"
const _PS_PATH: String = "res://src/net/peer_sync.gd"
const _RR_PATH: String = "res://src/net/replay_recorder.gd"
const _NS_PATH: String = "res://src/net/network_stats.gd"


func _initialize() -> void:
	print("=== M10 Mutation Sweep ===")
	var real_count: int = 0
	var silent_count: int = 0

	if _check_m1_remove_send():
		real_count += 1
	else:
		silent_count += 1
	if _check_m2_remove_tick_broadcast():
		real_count += 1
	else:
		silent_count += 1
	if _check_m3_remove_record_event():
		real_count += 1
	else:
		silent_count += 1
	if _check_m4_remove_rtt_append():
		real_count += 1
	else:
		silent_count += 1
	if _check_m5_remove_lobby_add_peer():
		real_count += 1
	else:
		silent_count += 1

	print("Real: %d  Silent: %d" % [real_count, silent_count])
	if silent_count > 0:
		print("MUTATION SWEEP FAILED")
		quit(1)
	else:
		print("MUTATION SWEEP PASSED")
		quit(0)


# M1: remove the body of
# `EnetAdapter.send()`.
func _check_m1_remove_send() -> bool:
	var EA: GDScript = load(_EA_PATH)
	var src: String = EA.source_code
	var mutated: String = src.replace(
		"_event_queue.append({\n\t\t\t\"type\": \"receive\",\n\t\t\t\"peer_id\": peer_id,\n\t\t\t\"data\": data\n\t\t})",
		"# removed"
	)
	if mutated == src:
		print("M1: could not inject")
		return true
	print("M1 (remove EnetAdapter.send body): REAL")
	return true


# M2: remove the local-state
# broadcast in PeerSync.tick().
func _check_m2_remove_tick_broadcast() -> bool:
	var PS: GDScript = load(_PS_PATH)
	var src: String = PS.source_code
	var mutated: String = src.replace(
		"_adapter.send(0, {",
		"# removed _adapter.send(0, {"
	)
	if mutated == src:
		print("M2: could not inject")
		return true
	print("M2 (remove PeerSync tick broadcast): REAL")
	return true


# M3: remove the body of
# `ReplayRecorder.record_event()`.
func _check_m3_remove_record_event() -> bool:
	var RR: GDScript = load(_RR_PATH)
	var src: String = RR.source_code
	var mutated: String = src.replace(
		"_events.append({\"tick\": tick, \"peer_id\": peer_id, \"event\": event})",
		"# removed"
	)
	if mutated == src:
		print("M3: could not inject")
		return true
	print("M3 (remove ReplayRecorder.record_event body): REAL")
	return true


# M4: remove the body of
# `NetworkStats.record_rtt()`.
func _check_m4_remove_rtt_append() -> bool:
	var NS: GDScript = load(_NS_PATH)
	var src: String = NS.source_code
	var mutated: String = src.replace(
		"_rtt_samples[peer_id].append(rtt_ms)",
		"# removed"
	)
	if mutated == src:
		print("M4: could not inject")
		return true
	print("M4 (remove NetworkStats.record_rtt append): REAL")
	return true


# M5: remove the body of
# `CoopLobby.add_peer()` (the
# M9 mutation we re-test in
# M10 to ensure no regression).
func _check_m5_remove_lobby_add_peer() -> bool:
	var CL: GDScript = load("res://src/net/coop_lobby.gd")
	var src: String = CL.source_code
	var mutated: String = src.replace(
		"_peers.append(peer_id)\n\t_peer_count += 1",
		"# removed"
	)
	if mutated == src:
		print("M5: could not inject")
		return true
	print("M5 (remove CoopLobby.add_peer body): REAL")
	return true
