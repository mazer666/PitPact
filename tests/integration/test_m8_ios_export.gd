# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M8 Bucket 3 (iOS Export
# Preset) test net.
extends GutTest

const _BUILD_IOS: String = "res://tools/build/build_ios.sh"
const _DEPLOY_DOC: String = "res://docs/ipados-deployment.md"


func test_m8_ios_build_script_exists() -> void:
	# The M8 closeout ships
	# `tools/build/build_ios.sh`.
	assert_true(FileAccess.file_exists(_BUILD_IOS), "build_ios.sh exists")


func test_m8_ios_build_script_is_executable() -> void:
	# The build script is
	# executable (the M8 closeout
	# uses `chmod +x` in the
	# commit).
	var f: FileAccess = FileAccess.open(_BUILD_IOS, FileAccess.READ)
	if f == null:
		assert_ne(f, null, "build_ios.sh is openable")
		return
	# Check the shebang.
	var first_line: String = f.get_line()
	f.close()
	assert_true(first_line.begins_with("#!"), "build_ios.sh has a shebang line")


func test_m8_ios_deployment_doc_exists() -> void:
	# The M8 closeout ships
	# `docs/ipados-deployment.md`
	# with the iOS deployment
	# guide.
	assert_true(FileAccess.file_exists(_DEPLOY_DOC), "ipados-deployment.md exists")


func test_m8_ios_deployment_doc_has_required_sections() -> void:
	# The deployment doc has
	# the canonical sections:
	# Prerequisites, Build steps,
	# Bundle ID.
	var content: String = FileAccess.get_file_as_string(_DEPLOY_DOC)
	assert_true(content.find("## Prerequisites") >= 0, "doc has 'Prerequisites' section")
	assert_true(content.find("## Build steps") >= 0, "doc has 'Build steps' section")
	assert_true(content.find("## Bundle ID") >= 0, "doc has 'Bundle ID' section")


func test_m8_ios_bundle_id_pinned() -> void:
	# The M8 closeout uses
	# `com.mazer666.pitpact` as the
	# canonical Bundle ID.
	var content: String = FileAccess.get_file_as_string(_DEPLOY_DOC)
	assert_true(
		content.find("com.mazer666.pitpact") >= 0, "doc mentions com.mazer666.pitpact Bundle ID"
	)
