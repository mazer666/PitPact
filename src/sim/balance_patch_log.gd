# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M9 Bucket 4: Balance
# Patch Log.
#
# The M9 closeout ships a
# headless balance-patch log
# for A/B testing balance
# changes without sim restart.
# The log records patches
# with tick numbers and allows
# reverting to a previous
# state.
#
# The M9 closeout does NOT
# ship telemetry (out of
# scope per ADR-0021).
class_name BalancePatchLog
extends RefCounted

# Internal state.
var _patches: Array = []


# The canonical M9 version.
# The M9 closeout pins the
# version per ADR-0021.
static func version() -> String:
	return "0.5.0-m9-coop-foundation"


# `make()` creates a fresh
# patch log.
static func make() -> BalancePatchLog:
	var log: BalancePatchLog = BalancePatchLog.new()
	log._patches = []
	return log


# `record()` records a patch
# at the given tick. Returns
# the patch index. The M9
# closeout stores the patch
# verbatim (the patch is a
# Dictionary).
func record(patch: Dictionary, tick: int) -> int:
	var entry: Dictionary = {"tick": tick, "patch": patch, "index": _patches.size()}
	_patches.append(entry)
	return _patches.size() - 1


# `history()` returns the list
# of recorded patches in
# chronological order.
func history() -> Array:
	return _patches.duplicate()


# `count()` returns the number
# of recorded patches.
func count() -> int:
	return _patches.size()


# `revert_to()` returns a
# `M7BalanceConfig`-compatible
# patch that reverts all
# changes from `tick` onwards.
# The M9 closeout produces a
# "rollback" patch by
# inverting the patches (the
# caller is responsible for
# applying the rollback to a
# config).
func revert_to(tick: int) -> Dictionary:
	var rollback: Dictionary = {}
	for entry in _patches:
		if entry["tick"] >= tick:
			# Invert the patch
			# (the M9 closeout's
			# naive inversion:
			# subtract instead of
			# add). The M9.1
			# closeout can add
			# proper inversion.
			var p: Dictionary = entry["patch"]
			for key in p.keys():
				var v: Variant = p[key]
				if v is int or v is float:
					rollback[key] = -v
	return rollback


# `clear()` removes all
# recorded patches. The M9
# closeout's test helper.
func clear() -> void:
	_patches.clear()
