extends GutTest


func test_version() -> void:
	assert_eq(PerformanceOverlay.version(), "0.12.0-m16-docs-eol", "version")


func test_make() -> void:
	var po: PerformanceOverlay = PerformanceOverlay.make()
	assert_not_null(po, "make returns instance")
	assert_eq(po.is_visible(), false, "default hidden")


func test_set_visible() -> void:
	var po: PerformanceOverlay = PerformanceOverlay.make()
	po.set_visible(true)
	assert_eq(po.is_visible(), true, "visible")
	po.set_visible(false)
	assert_eq(po.is_visible(), false, "hidden")


func test_toggle() -> void:
	var po: PerformanceOverlay = PerformanceOverlay.make()
	var result: bool = po.toggle()
	assert_eq(result, true, "toggled on")
	assert_eq(po.is_visible(), true, "now visible")
	result = po.toggle()
	assert_eq(result, false, "toggled off")
	assert_eq(po.is_visible(), false, "now hidden")


func test_update_metrics() -> void:
	var po: PerformanceOverlay = PerformanceOverlay.make()
	po.update_metrics(60, 16.67, 150, 256.0)
	assert_eq(po.fps(), 60, "fps")
	assert_eq(po.frame_ms(), 16.67, "frame_ms")
	assert_eq(po.draw_calls(), 150, "draw_calls")
	assert_eq(po.memory_mb(), 256.0, "memory_mb")


func test_metrics_dict() -> void:
	var po: PerformanceOverlay = PerformanceOverlay.make()
	po.update_metrics(60, 16.67, 150, 256.0)
	var m: Dictionary = po.metrics()
	assert_eq(m.get("fps"), 60, "dict fps")
	assert_eq(m.get("frame_ms"), 16.67, "dict frame_ms")


func test_default_metrics() -> void:
	var po: PerformanceOverlay = PerformanceOverlay.make()
	assert_eq(po.fps(), 0, "default fps 0")
	assert_eq(po.frame_ms(), 0.0, "default frame_ms 0")
	assert_eq(po.draw_calls(), 0, "default draw_calls 0")
	assert_eq(po.memory_mb(), 0.0, "default memory_mb 0")


func test_is_fps_target_met() -> void:
	var po: PerformanceOverlay = PerformanceOverlay.make()
	po.update_metrics(60, 16.67, 150, 256.0)
	assert_eq(po.is_fps_target_met(60), true, "meets 60")
	assert_eq(po.is_fps_target_met(120), false, "misses 120")
	po.update_metrics(120, 8.33, 150, 256.0)
	assert_eq(po.is_fps_target_met(120), true, "meets 120")
