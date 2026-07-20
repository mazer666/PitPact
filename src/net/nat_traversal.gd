# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M15 Bucket 5:
# NAT Traversal Stub.
#
# The M15 closeout ships a
# NAT-traversal stub. The
# stub returns `false` for
# `is_available()` because
# real NAT-traversal requires
# STUN/TURN infrastructure
# (out of scope per ADR-0027;
# the M15.1 closeout will
# integrate it).
#
# The M15 closeout's tests
# verify the stub's API.
class_name NatTraversal
extends RefCounted

# The canonical M15 version.
# The M15 closeout pins the
# version per ADR-0027.
const VERSION_STRING: String = "0.11.0-m15-final-polish-coop"


# `version()` returns the
# canonical M15 version
# string.
static func version() -> String:
	return VERSION_STRING


# `is_available()` returns
# whether NAT-traversal is
# available. The M15 closeout
# returns false (stub; the
# M15.1 closeout will integrate
# real STUN/TURN).
static func is_available() -> bool:
	return false


# `connect()` is a stub for
# the real connection. The
# M15 closeout returns -1
# (not available).
static func connect_via_nat(_host: String, _port: int) -> int:
	return -1


# `relay_via_turn()` is a
# stub for TURN-relay. The
# M15 closeout returns -1.
static func relay_via_turn(_peer_id: int) -> int:
	return -1

# Internal state (none — the
# M15 closeout's stub is
# stateless).
