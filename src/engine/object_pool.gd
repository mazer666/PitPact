# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M14 Bucket 3:
# Object Pool.
#
# The M14 closeout ships a
# simple object pool for
# reusing objects (particles,
# inhabitants, tiles). The
# pool is configured with a
# `factory` callable that
# creates new objects.
#
# The M14 closeout's tests
# verify the acquire/release
# cycle and the pool size.
class_name ObjectPool
extends RefCounted

# The canonical M14 version.
# The M14 closeout pins the
# version per ADR-0026.
const VERSION_STRING: String = "0.10.0-m14-engine-perf-content"

# The M14 closeout's default
# pool size (16 objects). The
# M14 closeout uses this
# as the initial capacity.
const _DEFAULT_SIZE: int = 16

# `version()` returns the
# canonical M14 version
# string.
# Internal state.
var _factory: Callable = Callable()
var _available: Array = []
var _in_use: Array = []


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# pool. The `factory` is a
# callable that returns a
# new object.
static func make(factory: Callable) -> ObjectPool:
	var p: ObjectPool = ObjectPool.new()
	p._factory = factory
	p._available = []
	p._in_use = []
	return p


# `acquire()` acquires an
# object from the pool. If
# no objects are available,
# a new one is created via
# the factory.
func acquire() -> Variant:
	if _available.is_empty():
		var obj: Variant = _factory.call()
		_in_use.append(obj)
		return obj
	var obj2: Variant = _available.pop_back()
	_in_use.append(obj2)
	return obj2


# `release()` returns an
# object to the pool. The
# M14 closeout's release is
# idempotent (releasing an
# object not in use is a
# no-op).
func release(obj: Variant) -> int:
	if not _in_use.has(obj):
		return _available.size()
	_in_use.erase(obj)
	_available.append(obj)
	return _available.size()


# `available_count()` returns
# the number of available
# objects in the pool.
func available_count() -> int:
	return _available.size()


# `in_use_count()` returns
# the number of objects
# currently in use.
func in_use_count() -> int:
	return _in_use.size()


# `total_count()` returns
# the total number of
# objects (available + in use).
func total_count() -> int:
	return _available.size() + _in_use.size()


# `default_size()` returns
# the default pool size.
static func default_size() -> int:
	return _DEFAULT_SIZE
