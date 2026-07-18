# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M10 Bucket 3:
# Replay Recorder.
#
# The M10 closeout ships a
# replay recorder for coop
# sessions. The recorder
# stores events in memory
# and can save/load to a
# JSON-lines file (one event
# per line, human-readable).
#
# The M10 closeout's tests
# verify the in-memory state
# and the save/load roundtrip.
# The production path can
# stream events to disk as
# they occur (M10.1 closeout's
# job).
class_name ReplayRecorder
extends RefCounted

# The canonical M10 version.
# The M10 closeout pins the
# version per ADR-0022.
const VERSION_STRING: String = "0.6.0-m10-coop-live"

# The JSON-lines format
# (one event per line). The
# M10 closeout uses Godot's
# built-in JSON printer for
# each event.
const _FILE_HEADER: String = "PITPACT_REPLAY_V1\n"

# Internal state.
var _path: String = ""
var _events: Array = []


# `version()` returns the
# canonical M10 version
# string.
static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# recorder. The `path` is
# the file to write to when
# `save()` is called.
static func make(path: String) -> ReplayRecorder:
	var r: ReplayRecorder = ReplayRecorder.new()
	r._path = path
	r._events = []
	return r


# `record_event()` records an
# event at the given tick
# from the given peer.
# Returns the event index.
func record_event(tick: int, peer_id: int, event: Dictionary) -> int:
	_events.append({"tick": tick, "peer_id": peer_id, "event": event})
	return _events.size() - 1


# `events()` returns the list
# of recorded events.
func events() -> Array:
	return _events.duplicate(true)


# `event_count()` returns the
# number of recorded events.
func event_count() -> int:
	return _events.size()


# `save()` writes the events
# to the file at the given
# path. Returns the number
# of events written. The M10
# closeout uses JSON-lines
# format.
func save() -> int:
	var f: FileAccess = FileAccess.open(_path, FileAccess.WRITE)
	if f == null:
		return 0
	f.store_string(_FILE_HEADER)
	for ev in _events:
		f.store_line(JSON.stringify(ev))
	f.close()
	return _events.size()


# `load_from_file()` loads
# events from a file. The
# M10 closeout returns a new
# `ReplayRecorder` instance.
# Returns null if the file
# cannot be opened or the
# header is missing.
static func load_from_file(path: String) -> ReplayRecorder:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	# Read the header.
	var header: String = f.get_line()
	if header != _FILE_HEADER.rstrip("\n"):
		f.close()
		return null
	var r: ReplayRecorder = ReplayRecorder.new()
	r._path = path
	r._events = []
	while not f.eof_reached():
		var line: String = f.get_line()
		if line == "":
			continue
		var json: JSON = JSON.new()
		var err: int = json.parse(line)
		if err != OK:
			continue
		if json.data is Dictionary:
			r._events.append(json.data)
	f.close()
	return r


# `clear()` removes all
# recorded events.
func clear() -> void:
	_events.clear()
