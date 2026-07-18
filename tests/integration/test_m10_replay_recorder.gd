# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Bucket 3 (Replay
# Recorder) test net.
extends GutTest

const _RR_PATH: String = "res://src/net/replay_recorder.gd"
const _TMP_PATH: String = "user://test_m10_replay.replay"


func _cleanup_tmp_file() -> void:
	if FileAccess.file_exists(_TMP_PATH):
		DirAccess.remove_absolute(_TMP_PATH)


func test_m10_replay_recorder_version() -> void:
	var RR: GDScript = load(_RR_PATH)
	var v: String = RR.call("version")
	assert_eq(v, "0.6.0-m10-coop-live", "version() returns the M10 closeout version")


func test_m10_replay_recorder_make() -> void:
	var RR: GDScript = load(_RR_PATH)
	var r: Variant = RR.call("make", _TMP_PATH)
	assert_eq(r.event_count(), 0, "no events initially")


func test_m10_replay_recorder_record_event() -> void:
	var RR: GDScript = load(_RR_PATH)
	var r: Variant = RR.call("make", _TMP_PATH)
	var idx: int = r.record_event(1, 42, {"type": "tick", "data": "hello"})
	assert_eq(idx, 0, "first event index=0")
	assert_eq(r.event_count(), 1, "1 event recorded")


func test_m10_replay_recorder_events() -> void:
	var RR: GDScript = load(_RR_PATH)
	var r: Variant = RR.call("make", _TMP_PATH)
	r.record_event(1, 42, {"type": "tick"})
	r.record_event(2, 42, {"type": "tick"})
	var events: Array = r.events()
	assert_eq(events.size(), 2, "2 events recorded")
	assert_eq(events[0]["tick"], 1, "first event tick=1")
	assert_eq(events[1]["tick"], 2, "second event tick=2")


func test_m10_replay_recorder_save_and_load() -> void:
	# Save events to a file,
	# load them back, verify
	# the roundtrip.
	_cleanup_tmp_file()
	var RR: GDScript = load(_RR_PATH)
	var r: Variant = RR.call("make", _TMP_PATH)
	r.record_event(1, 42, {"type": "tick", "data": "hello"})
	r.record_event(2, 43, {"type": "tick", "data": "world"})
	var n: int = r.save()
	assert_eq(n, 2, "save() returns 2 events")
	var r2: Variant = RR.call("load_from_file", _TMP_PATH)
	assert_ne(r2, null, "load returns a recorder")
	if r2 != null:
		assert_eq(r2.event_count(), 2, "loaded recorder has 2 events")
	_cleanup_tmp_file()


func test_m10_replay_recorder_load_nonexistent() -> void:
	# Loading a nonexistent
	# file returns null.
	var RR: GDScript = load(_RR_PATH)
	var r: Variant = RR.call("load_from_file", "user://nonexistent.replay")
	assert_eq(r, null, "load nonexistent file returns null")


func test_m10_replay_recorder_clear() -> void:
	var RR: GDScript = load(_RR_PATH)
	var r: Variant = RR.call("make", _TMP_PATH)
	r.record_event(1, 42, {"type": "tick"})
	r.clear()
	assert_eq(r.event_count(), 0, "clear() removes all events")
