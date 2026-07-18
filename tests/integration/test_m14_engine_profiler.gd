# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 3 (Engine
# Profiler + Object Pool) test net.
extends GutTest

const _FP_PATH: String = "res://src/engine/engine_profiler.gd"
const _OP_PATH: String = "res://src/engine/object_pool.gd"


func test_m14_engine_profiler_version() -> void:
	var FP: GDScript = load(_FP_PATH)
	var v: String = FP.call("version")
	assert_eq(v, "0.10.0-m14-engine-perf-content", "version() returns the M14 closeout version")


func test_m14_engine_profiler_make() -> void:
	var FP: GDScript = load(_FP_PATH)
	var p: Variant = FP.call("make")
	assert_eq(p.frame_count(), 0, "0 frames initially")


func test_m14_engine_profiler_record_frame() -> void:
	var FP: GDScript = load(_FP_PATH)
	var p: Variant = FP.call("make")
	p.record_frame(16.0)
	p.record_frame(20.0)
	assert_eq(p.frame_count(), 2, "2 frames recorded")


func test_m14_engine_profiler_avg_frame_ms() -> void:
	var FP: GDScript = load(_FP_PATH)
	var p: Variant = FP.call("make")
	p.record_frame(10.0)
	p.record_frame(20.0)
	p.record_frame(30.0)
	assert_eq(p.avg_frame_ms(), 20.0, "avg = (10+20+30)/3 = 20.0")


func test_m14_engine_profiler_p99() -> void:
	var FP: GDScript = load(_FP_PATH)
	var p: Variant = FP.call("make")
	# 100 frames at 10ms each
	# — p99 should be ~10ms.
	for i in 100:
		p.record_frame(10.0)
	var p99: float = p.p99_frame_ms()
	assert_lte(p99, 10.0, "p99 <= 10ms")


func test_m14_engine_profiler_within_budget() -> void:
	# Frames under 16.67ms
	# (= 60 FPS) are within
	# budget.
	var FP: GDScript = load(_FP_PATH)
	var p: Variant = FP.call("make")
	for i in 10:
		p.record_frame(10.0)
	assert_true(p.is_within_budget(16.67), "avg 10ms is within 16.67ms budget")


func test_m14_engine_profiler_outside_budget() -> void:
	# Frames over 16.67ms
	# are outside budget.
	var FP: GDScript = load(_FP_PATH)
	var p: Variant = FP.call("make")
	for i in 10:
		p.record_frame(20.0)
	assert_false(p.is_within_budget(16.67), "avg 20ms is outside 16.67ms budget")


func test_m14_engine_profiler_reset() -> void:
	var FP: GDScript = load(_FP_PATH)
	var p: Variant = FP.call("make")
	p.record_frame(10.0)
	p.reset()
	assert_eq(p.frame_count(), 0, "0 frames after reset")


func test_m14_object_pool_version() -> void:
	var OP: GDScript = load(_OP_PATH)
	var v: String = OP.call("version")
	assert_eq(v, "0.10.0-m14-engine-perf-content", "version() returns the M14 closeout version")


func test_m14_object_pool_make() -> void:
	var OP: GDScript = load(_OP_PATH)
	var pool: Variant = OP.call("make", func() -> RefCounted: return RefCounted.new())
	assert_eq(pool.total_count(), 0, "0 objects initially")


func test_m14_object_pool_acquire_creates_new() -> void:
	# Acquiring from an empty
	# pool creates a new object
	# via the factory.
	var OP: GDScript = load(_OP_PATH)
	var factory: Callable = func() -> RefCounted: return RefCounted.new()
	var pool: Variant = OP.call("make", factory)
	var obj: Variant = pool.acquire()
	assert_ne(obj, null, "acquired object is not null")
	assert_eq(pool.in_use_count(), 1, "1 object in use")
	assert_eq(pool.total_count(), 1, "1 object total")


func test_m14_object_pool_acquire_uses_available() -> void:
	# Acquiring reuses an
	# available object (if
	# any).
	var OP: GDScript = load(_OP_PATH)
	var pool: Variant = OP.call("make", func() -> RefCounted: return RefCounted.new())
	var obj1: Variant = pool.acquire()
	pool.release(obj1)
	# Pool now has 1 available.
	var obj2: Variant = pool.acquire()
	assert_eq(obj1, obj2, "second acquire returns same object")
	assert_eq(pool.in_use_count(), 1, "1 object in use")
	assert_eq(pool.available_count(), 0, "0 objects available")


func test_m14_object_pool_release_returns_to_available() -> void:
	var OP: GDScript = load(_OP_PATH)
	var pool: Variant = OP.call("make", func() -> RefCounted: return RefCounted.new())
	var obj: Variant = pool.acquire()
	assert_eq(pool.in_use_count(), 1, "1 in use before release")
	pool.release(obj)
	assert_eq(pool.in_use_count(), 0, "0 in use after release")
	assert_eq(pool.available_count(), 1, "1 available after release")


func test_m14_object_pool_release_unknown_is_noop() -> void:
	# Releasing an object not
	# in use is a no-op.
	var OP: GDScript = load(_OP_PATH)
	var pool: Variant = OP.call("make", func() -> RefCounted: return RefCounted.new())
	pool.release({"x": 99})
	assert_eq(pool.available_count(), 0, "0 available (release of unknown)")


func test_m14_object_pool_default_size() -> void:
	var OP: GDScript = load(_OP_PATH)
	var s: int = OP.call("default_size")
	assert_eq(s, 16, "default size is 16")
