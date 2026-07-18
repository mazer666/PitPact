# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M13 Side-Quest J:
# Audio-Reactive Visual.
#
# The M13 closeout ships a
# carrier for audio-reactive
# visual feedback. The carrier
# tracks 3 events (step, crisis,
# power) and triggers visual
# effects (pulse, flash, glow).
#
# The M13 closeout's tests
# verify the event handling
# and the decay timing.
class_name AudioReactiveVisual
extends RefCounted

# The canonical M13 version.
# The M13 closeout pins the
# version per ADR-0025.
const VERSION_STRING: String = "0.9.0-m13-visual-polish"

# The M13 closeout's pulse
# duration (0.3s = 18 frames @
# 60 FPS). The pulse decays
# linearly over this period.
const _PULSE_DURATION: float = 0.3

# `version()` returns the
# canonical M13 version
# string.
# Internal state.
var _step_pulse: float = 0.0
var _crisis_flash: float = 0.0
var _power_glow: float = 0.0


static func version() -> String:
	return VERSION_STRING


# `make()` creates a fresh
# audio-reactive visual.
static func make() -> AudioReactiveVisual:
	var arv: AudioReactiveVisual = AudioReactiveVisual.new()
	arv._step_pulse = 0.0
	arv._crisis_flash = 0.0
	arv._power_glow = 0.0
	return arv


# `on_step()` triggers a step
# pulse. The pulse decays
# over `_PULSE_DURATION`
# seconds.
func on_step() -> void:
	_step_pulse = 1.0


# `on_crisis()` triggers a
# crisis flash. The flash
# decays over `_PULSE_DURATION`
# seconds.
func on_crisis() -> void:
	_crisis_flash = 1.0


# `on_power()` triggers a
# power glow. The glow decays
# over `_PULSE_DURATION`
# seconds.
func on_power() -> void:
	_power_glow = 1.0


# `tick()` advances the
# visuals by `delta` seconds.
func tick(delta: float) -> void:
	_step_pulse = max(0.0, _step_pulse - delta / _PULSE_DURATION)
	_crisis_flash = max(0.0, _crisis_flash - delta / _PULSE_DURATION)
	_power_glow = max(0.0, _power_glow - delta / _PULSE_DURATION)


# `step_pulse()` returns the
# current step pulse value
# (0.0-1.0).
func step_pulse() -> float:
	return _step_pulse


# `crisis_flash()` returns
# the current crisis flash
# value (0.0-1.0).
func crisis_flash() -> float:
	return _crisis_flash


# `power_glow()` returns the
# current power glow value
# (0.0-1.0).
func power_glow() -> float:
	return _power_glow


# `pulse_duration()` returns
# the pulse duration.
static func pulse_duration() -> float:
	return _PULSE_DURATION
