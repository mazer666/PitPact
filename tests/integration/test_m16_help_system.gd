extends GutTest


func test_version() -> void:
	assert_eq(HelpSystem.version(), "0.12.0-m16-docs-eol", "version")


func test_make() -> void:
	var hs: HelpSystem = HelpSystem.make()
	assert_not_null(hs, "make returns instance")
	assert_gt(hs.topic_count(), 0, "default topics installed")


func test_default_topics() -> void:
	var hs: HelpSystem = HelpSystem.make()
	assert_eq(hs.has_topic(&"getting_started"), true, "welcome")
	assert_eq(hs.has_topic(&"inhabitants"), true, "inhabitants")
	assert_eq(hs.has_topic(&"crises"), true, "crises")
	assert_eq(hs.has_topic(&"co_op"), true, "co-op")
	assert_eq(hs.has_topic(&"settings"), true, "settings")


func test_get_topic() -> void:
	var hs: HelpSystem = HelpSystem.make()
	var t: HelpTopic = hs.get_topic(&"getting_started")
	assert_not_null(t, "found")
	assert_eq(t.title, "Getting Started", "title")
	assert_gt(t.body.length(), 0, "body not empty")


func test_get_unknown_topic() -> void:
	var hs: HelpSystem = HelpSystem.make()
	var t: HelpTopic = hs.get_topic(&"unknown")
	assert_null(t, "unknown returns null")


func test_topics_for_context() -> void:
	var hs: HelpSystem = HelpSystem.make()
	var gameplay: Array = hs.topics_for_context(&"gameplay")
	assert_eq(gameplay.size(), 3, "3 gameplay topics")
	var coop: Array = hs.topics_for_context(&"co_op")
	assert_eq(coop.size(), 1, "1 co-op topic")
	var settings: Array = hs.topics_for_context(&"settings")
	assert_eq(settings.size(), 1, "1 settings topic")


func test_add_topic() -> void:
	var hs: HelpSystem = HelpSystem.make()
	var before: int = hs.topic_count()
	hs.add_topic(
		HelpTopic.make(&"custom", "Custom", "Custom body", PackedStringArray(), &"gameplay")
	)
	assert_eq(hs.topic_count(), before + 1, "topic added")


func test_add_topic_invalid() -> void:
	var hs: HelpSystem = HelpSystem.make()
	# Empty id should fail.
	var result: int = hs.add_topic(HelpTopic.make(&"", "X", "Y", PackedStringArray(), &"general"))
	assert_eq(result, -1, "empty id rejected")


func test_remove_topic() -> void:
	var hs: HelpSystem = HelpSystem.make()
	hs.add_topic(HelpTopic.make(&"removable", "X", "Y", PackedStringArray(), &"gameplay"))
	var result: int = hs.remove_topic(&"removable")
	assert_eq(result, 0, "remove ok")
	assert_eq(hs.has_topic(&"removable"), false, "no longer has")


func test_remove_unknown() -> void:
	var hs: HelpSystem = HelpSystem.make()
	var result: int = hs.remove_topic(&"unknown")
	assert_eq(result, -1, "unknown")


func test_related_topics() -> void:
	var hs: HelpSystem = HelpSystem.make()
	var t: HelpTopic = hs.get_topic(&"getting_started")
	assert_gt(t.related_count(), 0, "has related")
	assert_eq(t.has_related(), true, "has_related true")


func test_contexts() -> void:
	assert_eq(HelpSystem.context_gameplay(), &"gameplay", "gp ctx")
	assert_eq(HelpSystem.context_coop(), &"co_op", "coop ctx")
	assert_eq(HelpSystem.context_settings(), &"settings", "set ctx")
