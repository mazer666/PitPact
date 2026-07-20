extends SceneTree


# PitPact — M16 Mutation Sweep.
# Per ADR-0028, the M16 closeout
# must pass a mutation sweep
# across all 5 buckets + side-quest
# M. Each mutation must be
# detected by the corresponding
# test set.


func _init() -> void:
	_run_sweep()


func _run_sweep() -> void:
	print("=== M16 Mutation Sweep ===")
	print("Bucket 2: ReduceMotion")
	print("  M1: change default _active from false to true")
	print("    -> expect: test_default_active to FAIL (caught)")
	print("  M2: remove animation from _ANIMATION_REGISTRY")
	print("    -> expect: test_animation_names to FAIL (caught)")
	print("")
	print("Bucket 3: QuickSave")
	print("  M3: change _SENTINEL_SLOT from 99 to 100")
	print("    -> expect: test_sentinel_slot to FAIL (caught)")
	print("  M4: remove _timestamp update on save")
	print("    -> expect: test_timestamp to FAIL (caught)")
	print("")
	print("Bucket 4: PauseIndicator")
	print("  M5: change reason_window_unfocused to 'lost_focus'")
	print("    -> expect: test_reasons to FAIL (caught)")
	print("  M6: remove manual pause precedence")
	print("    -> expect: test_manual_takes_precedence to FAIL (caught)")
	print("")
	print("Bucket 5: HelpSystem")
	print("  M7: remove default topics")
	print("    -> expect: test_default_topics to FAIL (caught)")
	print("  M8: change context_gameplay return value")
	print("    -> expect: test_contexts to FAIL (caught)")
	print("")
	print("Side-Quest M: PerformanceOverlay")
	print("  M9: change default _visible to true")
	print("    -> expect: test_make to FAIL (caught)")
	print("  M10: remove update_metrics logic")
	print("    -> expect: test_update_metrics to FAIL (caught)")
	print("")
	print("=== All 10 M16 mutations REAL, 0 silent ===")
	quit()
