extends GutTest


func test_version() -> void:
	assert_eq(ReduceMotion.version(), "0.12.0-m16-docs-eol", "version")


func test_default_active() -> void:
	assert_eq(ReduceMotion.default_active(), false, "default off")


func test_make() -> void:
	var rm: ReduceMotion = ReduceMotion.make()
	assert_not_null(rm, "make returns instance")
	assert_eq(rm.is_active(), false, "default is_active false")


func test_set_active() -> void:
	var rm: ReduceMotion = ReduceMotion.make()
	rm.set_active(true)
	assert_eq(rm.is_active(), true, "set true")
	rm.set_active(false)
	assert_eq(rm.is_active(), false, "set false")


func test_animation_allowed_default() -> void:
	# Without Reduce-Motion, all animations allowed.
	var rm: ReduceMotion = ReduceMotion.make()
	assert_eq(rm.animation_allowed(&"idle_breathing"), true, "default allows idle")
	assert_eq(rm.animation_allowed(&"particles"), true, "default allows particles")
	assert_eq(rm.animation_allowed(&"hover_tween"), true, "default allows hover")


func test_animation_blocked_when_active() -> void:
	# With Reduce-Motion, decorative animations blocked.
	var rm: ReduceMotion = ReduceMotion.make()
	rm.set_active(true)
	assert_eq(rm.animation_allowed(&"idle_breathing"), false, "block idle")
	assert_eq(rm.animation_allowed(&"particles"), false, "block particles")
	assert_eq(rm.animation_allowed(&"day_night_cycle"), false, "block day-night")
	assert_eq(rm.animation_allowed(&"hover_tween"), false, "block hover")
	assert_eq(rm.animation_allowed(&"title_fade_in"), false, "block title-fade")


func test_functional_animations_allowed() -> void:
	# Functional animations stay on even with Reduce-Motion.
	var rm: ReduceMotion = ReduceMotion.make()
	rm.set_active(true)
	assert_eq(rm.animation_allowed(&"step_button_pulse"), true, "step-button allowed")
	assert_eq(rm.animation_allowed(&"crisis_banner_slide"), true, "crisis allowed")
	assert_eq(rm.animation_allowed(&"game_over_banner_slide"), true, "game-over allowed")
	assert_eq(rm.animation_allowed(&"victory_banner_slide"), true, "victory allowed")
	assert_eq(rm.animation_allowed(&"audio_reactive_pulse"), true, "audio-reactive allowed")


func test_animation_allowed_static() -> void:
	# Static check (always returns "allowed" by registry,
	# regardless of _active — caller must check _active).
	assert_eq(ReduceMotion.animation_allowed_static(&"idle_breathing"), false, "static block")
	assert_eq(ReduceMotion.animation_allowed_static(&"step_button_pulse"), true, "static allow")


func test_is_blocked_animation() -> void:
	assert_eq(ReduceMotion.is_blocked_animation(&"idle_breathing"), true, "blocked")
	assert_eq(ReduceMotion.is_blocked_animation(&"step_button_pulse"), false, "not blocked")


func test_animation_names() -> void:
	var names: Array = ReduceMotion.animation_names()
	assert_eq(names.size(), 10, "10 registered")


func test_blocked_animations_when_active() -> void:
	var rm: ReduceMotion = ReduceMotion.make()
	rm.set_active(true)
	var blocked: Array = rm.blocked_animations()
	assert_eq(blocked.size(), 5, "5 blocked (idle, particles, day, hover, title)")


func test_blocked_animations_when_inactive() -> void:
	var rm: ReduceMotion = ReduceMotion.make()
	var blocked: Array = rm.blocked_animations()
	assert_eq(blocked.size(), 0, "0 blocked when inactive")


func test_allowed_animations_when_active() -> void:
	var rm: ReduceMotion = ReduceMotion.make()
	rm.set_active(true)
	var allowed: Array = rm.allowed_animations()
	assert_eq(allowed.size(), 5, "5 allowed (step, crisis, game-over, victory, audio)")


func test_allowed_animations_when_inactive() -> void:
	var rm: ReduceMotion = ReduceMotion.make()
	var allowed: Array = rm.allowed_animations()
	assert_eq(allowed.size(), 10, "10 allowed when inactive")
