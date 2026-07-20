# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M16 Bucket 2: Reduce Motion.
# Per ADR-0028, implements WCAG 2.1
# §2.5.4 (Motion Actuation). When
# active, all non-essential animations
# are disabled. Functional animations
# (step-button pulse, crisis banner)
# remain.
class_name ReduceMotion
extends RefCounted

const VERSION_STRING: String = "0.12.0-m16-docs-eol"
const _DEFAULT_ACTIVE: bool = false

# The M16 closeout's animation
# registry. Each entry maps
# an animation name to whether
# it is disabled by Reduce-Motion.
const _ANIMATION_REGISTRY: Dictionary = {
	"idle_breathing": true,
	"particles": true,
	"day_night_cycle": true,
	"hover_tween": true,
	"title_fade_in": true,
	"step_button_pulse": false,
	"crisis_banner_slide": false,
	"game_over_banner_slide": false,
	"victory_banner_slide": false,
	"audio_reactive_pulse": false
}

var _active: bool = _DEFAULT_ACTIVE


static func version() -> String:
	return VERSION_STRING


static func make() -> ReduceMotion:
	return ReduceMotion.new()


static func default_active() -> bool:
	return _DEFAULT_ACTIVE


static func is_blocked_animation(name: StringName) -> bool:
	return _ANIMATION_REGISTRY.get(String(name), false)


static func animation_allowed(name: StringName) -> bool:
	return not _ANIMATION_REGISTRY.get(String(name), false)


static func animation_names() -> Array:
	return _ANIMATION_REGISTRY.keys()


func is_active() -> bool:
	return _active


func set_active(active: bool) -> void:
	_active = active


func animation_allowed(name: StringName) -> bool:
	if not _active:
		return true
	return animation_allowed_static(name)


# The M16 closeout's static
# animation-allowed check
# (used internally + externally).
static func animation_allowed_static(name: StringName) -> bool:
	if not _ANIMATION_REGISTRY.get(String(name), false):
		return true
	# Animation is registered as
	# disabled. Allow if Reduce-Motion
	# is off (caller checks _active),
	# otherwise blocked.
	return not _ANIMATION_REGISTRY.get(String(name), false)


func blocked_animations() -> Array:
	if not _active:
		return []
	var result: Array = []
	for anim_name in _ANIMATION_REGISTRY:
		if _ANIMATION_REGISTRY[anim_name]:
			result.append(anim_name)
	return result


func allowed_animations() -> Array:
	if not _active:
		return _ANIMATION_REGISTRY.keys()
	var result: Array = []
	for anim_name in _ANIMATION_REGISTRY:
		if not _ANIMATION_REGISTRY[anim_name]:
			result.append(anim_name)
	return result
