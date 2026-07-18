# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Side-Quest J
# (Audio-Reactive Visual) test
# net.
extends GutTest

const _ARV_PATH: String = "res://src/ui/audio_reactive_visual.gd"


func test_m13_audio_reactive_visual_version() -> void:
	var ARV: GDScript = load(_ARV_PATH)
	var v: String = ARV.call("version")
	assert_eq(v, "0.9.0-m13-visual-polish", "version() returns the M13 closeout version")


func test_m13_audio_reactive_visual_make() -> void:
	var ARV: GDScript = load(_ARV_PATH)
	var arv: Variant = ARV.call("make")
	assert_eq(arv.step_pulse(), 0.0, "step_pulse=0 initially")
	assert_eq(arv.crisis_flash(), 0.0, "crisis_flash=0 initially")
	assert_eq(arv.power_glow(), 0.0, "power_glow=0 initially")


func test_m13_audio_reactive_visual_on_step() -> void:
	var ARV: GDScript = load(_ARV_PATH)
	var arv: Variant = ARV.call("make")
	arv.on_step()
	assert_eq(arv.step_pulse(), 1.0, "step_pulse=1.0 after on_step")


func test_m13_audio_reactive_visual_on_crisis() -> void:
	var ARV: GDScript = load(_ARV_PATH)
	var arv: Variant = ARV.call("make")
	arv.on_crisis()
	assert_eq(arv.crisis_flash(), 1.0, "crisis_flash=1.0 after on_crisis")


func test_m13_audio_reactive_visual_on_power() -> void:
	var ARV: GDScript = load(_ARV_PATH)
	var arv: Variant = ARV.call("make")
	arv.on_power()
	assert_eq(arv.power_glow(), 1.0, "power_glow=1.0 after on_power")


func test_m13_audio_reactive_visual_tick_decays() -> void:
	# `tick()` decays the
	# pulses linearly.
	var ARV: GDScript = load(_ARV_PATH)
	var arv: Variant = ARV.call("make")
	arv.on_step()
	# Half the pulse duration
	# → 0.5 remaining.
	arv.tick(0.15)
	assert_eq(arv.step_pulse(), 0.5, "step_pulse=0.5 after half duration")


func test_m13_audio_reactive_visual_tick_clamps_to_zero() -> void:
	# `tick()` clamps to 0
	# (not negative).
	var ARV: GDScript = load(_ARV_PATH)
	var arv: Variant = ARV.call("make")
	arv.on_step()
	# More than the pulse
	# duration.
	arv.tick(1.0)
	assert_eq(arv.step_pulse(), 0.0, "step_pulse=0 after full duration")


func test_m13_audio_reactive_visual_pulse_duration() -> void:
	# Pulse duration is 0.3s
	# (= 18 frames @ 60 FPS).
	var ARV: GDScript = load(_ARV_PATH)
	var d: float = ARV.call("pulse_duration")
	assert_eq(d, 0.3, "pulse duration is 0.3s")


func test_m13_audio_reactive_visual_independent_events() -> void:
	# The 3 events are
	# independent (triggering
	# one does not affect the
	# others).
	var ARV: GDScript = load(_ARV_PATH)
	var arv: Variant = ARV.call("make")
	arv.on_step()
	assert_eq(arv.step_pulse(), 1.0, "step triggered")
	assert_eq(arv.crisis_flash(), 0.0, "crisis not triggered")
	assert_eq(arv.power_glow(), 0.0, "power not triggered")
