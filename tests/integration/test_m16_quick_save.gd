extends GutTest


func test_version() -> void:
	assert_eq(QuickSave.version(), "0.12.0-m16-docs-eol", "version")


func test_sentinel_slot() -> void:
	assert_eq(QuickSave.sentinel_slot(), 99, "sentinel slot 99")


func test_make() -> void:
	var qs: QuickSave = QuickSave.make()
	assert_not_null(qs, "make returns instance")
	assert_eq(qs.has_quick_save(), false, "default no save")


func test_save() -> void:
	var qs: QuickSave = QuickSave.make()
	var state: Dictionary = {"day": 5, "hearth": "burning"}
	var result: int = qs.save_state(state)
	assert_eq(result, 0, "save returns 0")
	assert_eq(qs.has_quick_save(), true, "has save")


func test_save_overwrites() -> void:
	var qs: QuickSave = QuickSave.make()
	qs.save_state({"day": 5})
	qs.save_state({"day": 10})
	var loaded: Dictionary = qs.load_state()
	assert_eq(loaded.get("day"), 10, "latest state saved")


func test_load_no_save() -> void:
	var qs: QuickSave = QuickSave.make()
	var loaded: Dictionary = qs.load_state()
	assert_eq(loaded.size(), 0, "empty when no save")


func test_timestamp() -> void:
	var qs: QuickSave = QuickSave.make()
	qs.save_state({"day": 1})
	assert_gt(qs.timestamp(), 0, "timestamp set")


func test_delete() -> void:
	var qs: QuickSave = QuickSave.make()
	qs.save_state({"day": 1})
	qs.delete()
	assert_eq(qs.has_quick_save(), false, "deleted")
	assert_eq(qs.timestamp(), 0, "timestamp reset")


func test_save_count() -> void:
	var qs: QuickSave = QuickSave.make()
	assert_eq(qs.save_count(), 0, "0 saves")
	qs.save_state({"day": 1})
	assert_eq(qs.save_count(), 1, "1 save")
	qs.delete()
	assert_eq(qs.save_count(), 0, "0 saves after delete")
