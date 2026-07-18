# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M6 Bucket 6: Known-Issues
# test net.
extends GutTest

const _KNOWN_ISSUES_PATH: String = "res://KNOWN_ISSUES.md"
const _PERF_PATH: String = "res://tools/benchmarks/run_perf.gd"
const _BUILD_PATH: String = "res://tools/build/build_release.sh"
const _GEN_RELEASE_NOTES_PATH: String = "res://tools/build/generate_release_notes.sh"


func test_known_issues_file_exists() -> void:
	# The M6 Bucket 6 ships
	# `KNOWN_ISSUES.md` with at
	# least 3 documented issues.
	assert_true(FileAccess.file_exists(_KNOWN_ISSUES_PATH), "KNOWN_ISSUES.md exists")
	var content: String = FileAccess.get_file_as_string(_KNOWN_ISSUES_PATH)
	assert_gt(content.length(), 100, "KNOWN_ISSUES.md is non-trivial")


func test_known_issues_at_least_three_issues() -> void:
	# The M6 closeout documents
	# at least 3 issues. The test
	# pins the count by counting
	# "## Issue #" headers.
	var content: String = FileAccess.get_file_as_string(_KNOWN_ISSUES_PATH)
	var count: int = 0
	for line in content.split("\n"):
		if line.begins_with("## Issue #"):
			count += 1
	assert_gte(count, 3, "at least 3 known issues documented")


func test_perf_benchmark_script_exists() -> void:
	# The M6 Bucket 1 ships the
	# performance benchmark script.
	assert_true(FileAccess.file_exists(_PERF_PATH), "run_perf.gd exists")


func test_build_release_script_exists() -> void:
	# The M6 Bucket 2 ships the
	# reproducible build script.
	assert_true(FileAccess.file_exists(_BUILD_PATH), "build_release.sh exists")


func test_release_notes_generator_exists() -> void:
	# The M6 Bucket 3 ships the
	# release notes generator.
	assert_true(FileAccess.file_exists(_GEN_RELEASE_NOTES_PATH), "generate_release_notes.sh exists")
