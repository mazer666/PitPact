extends GutTest


func test_version() -> void:
	assert_eq(PauseIndicator.version(), "0.12.0-m16-docs-eol", "version")


func test_make() -> void:
	var pi: PauseIndicator = PauseIndicator.make()
	assert_not_null(pi, "make returns instance")
	assert_eq(pi.is_paused(), false, "default not paused")


func test_reasons() -> void:
	assert_eq(PauseIndicator.reason_window_unfocused(), "window_unfocused", "win")
	assert_eq(PauseIndicator.reason_manual_pause(), "manual_pause", "manual")
	assert_eq(PauseIndicator.reason_auto_pause(), "auto_pause", "auto")


func test_set_focused() -> void:
	var pi: PauseIndicator = PauseIndicator.make()
	pi.set_focused(false)
	assert_eq(pi.is_paused(), true, "paused when unfocused")
	assert_eq(pi.pause_reason(), "window_unfocused", "reason unfocused")
	pi.set_focused(true)
	assert_eq(pi.is_paused(), false, "resumed")


func test_set_manual_pause() -> void:
	var pi: PauseIndicator = PauseIndicator.make()
	pi.set_manual_pause(true)
	assert_eq(pi.is_paused(), true, "paused when manual")
	assert_eq(pi.pause_reason(), "manual_pause", "reason manual")
	pi.set_manual_pause(false)
	assert_eq(pi.is_paused(), false, "resumed manual")


func test_manual_takes_precedence() -> void:
	var pi: PauseIndicator = PauseIndicator.make()
	pi.set_focused(false)
	pi.set_manual_pause(true)
	assert_eq(pi.pause_reason(), "manual_pause", "manual wins")
	pi.set_manual_pause(false)
	assert_eq(pi.pause_reason(), "window_unfocused", "unfocused next")


func test_resume() -> void:
	var pi: PauseIndicator = PauseIndicator.make()
	pi.set_focused(false)
	pi.set_manual_pause(true)
	pi.resume()
	assert_eq(pi.is_paused(), false, "resume clears all")
	assert_eq(pi.is_focused(), true, "focused")
	assert_eq(pi.is_manually_paused(), false, "not manual")


func test_should_show_overlay() -> void:
	var pi: PauseIndicator = PauseIndicator.make()
	assert_eq(pi.should_show_overlay(), false, "no overlay when not paused")
	pi.set_focused(false)
	assert_eq(pi.should_show_overlay(), true, "overlay when unfocused")
	pi.set_focused(true)
	pi.set_manual_pause(true)
	assert_eq(pi.should_show_overlay(), true, "overlay when manual")
