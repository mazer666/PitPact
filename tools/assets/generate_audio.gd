# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Closeout Bucket 6: Procedural
# Audio Generator.
#
# This script generates 5 SFX + 1 Ambient
# track as `.wav` files (per ADR-0017
# §Bucket 6). The generator uses
# `AudioStreamGenerator` + raw PCM data
# (Godot 4.7's `AudioStreamWAV` with
# `format = FORMAT_16_BITS`).
#
# Per ADR-0005, the generator is
# SEED-pinned (the random samples
# use the same SEED as the visual
# asset generator). The generator
# is idempotent: a re-run produces
# byte-identical .wav files.
#
# Per ADR-0002, this file does not
# import from `src/ui`, `src/realm`,
# `src/save`, or `src/audit`. It is
# a `tools/assets/*` script.
extends SceneTree


## M5-Closeout Bucket 6: the
## canonical SEED. Pinned so the
# generator is idempotent.
const SEED: int = 4242

## M5-Closeout Bucket 6: the
## sample rate (Hz). 22050 is
## the M2 track default; the
## M5-Closeout uses the same
## for consistency.
const SAMPLE_RATE: int = 22050

## M5-Closeout Bucket 6: the
## audio output directory.
const AUDIO_DIR: String = "res://assets/audio/"

## M5-Closeout Bucket 6: the
## ambient track length (in
## seconds). The ambient track
## is a 10-second loop.
const AMBIENT_SECONDS: float = 10.0


func _init() -> void:
	# SEED-pinned determinism.
	seed(SEED)
	# Make sure the output
	# directory exists.
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(AUDIO_DIR)
	)
	# Generate the 5 SFX + 1
	# ambient track.
	_save_wav(AUDIO_DIR + "step.wav", _make_sfx_step())
	_save_wav(AUDIO_DIR + "power_seal.wav", _make_sfx_power_seal())
	_save_wav(AUDIO_DIR + "power_pause.wav", _make_sfx_power_pause())
	_save_wav(AUDIO_DIR + "crisis_horn.wav", _make_sfx_crisis_horn())
	_save_wav(AUDIO_DIR + "game_over.wav", _make_sfx_game_over())
	_save_wav(AUDIO_DIR + "ambient_loop.wav", _make_ambient_loop())
	print("Audio generated: 5 SFX + 1 ambient (in %s)" % AUDIO_DIR)
	quit(0)


## M5-Closeout Bucket 6: the
## "step" SFX. A short downward
## chirp (200ms) suggesting
## footsteps. The waveform is
## a sine + exponential decay.
func _make_sfx_step() -> PackedByteArray:
	var n_samples: int = int(0.2 * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n_samples * 2)
	for i in range(n_samples):
		# Decay envelope: 1.0 -> 0.0
		var t: float = float(i) / float(n_samples)
		var envelope: float = (1.0 - t) * (1.0 - t)
		# Frequency sweep: 600Hz -> 300Hz
		var freq: float = 600.0 - 300.0 * t
		var sample: float = sin(2.0 * PI * freq * t) * envelope * 0.4
		var s16: int = int(sample * 32767.0)
		# Little-endian 16-bit signed PCM
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data


## M5-Closeout Bucket 6: the
## "power_seal" SFX. A 500ms
## bright bell-ringing sound.
func _make_sfx_power_seal() -> PackedByteArray:
	var n_samples: int = int(0.5 * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n_samples * 2)
	for i in range(n_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = exp(-3.0 * t)
		# Three harmonics
		var sample: float = (
			sin(2.0 * PI * 800.0 * t)
			+ 0.5 * sin(2.0 * PI * 1200.0 * t)
			+ 0.3 * sin(2.0 * PI * 1600.0 * t)
		) * envelope * 0.3
		var s16: int = int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data


## M5-Closeout Bucket 6: the
## "power_pause" SFX. A 400ms
## descending tone.
func _make_sfx_power_pause() -> PackedByteArray:
	var n_samples: int = int(0.4 * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n_samples * 2)
	for i in range(n_samples):
		var t: float = float(i) / float(n_samples)
		var envelope: float = 1.0 - t
		# Frequency: 500Hz -> 200Hz
		var freq: float = 500.0 - 300.0 * t
		var sample: float = sin(2.0 * PI * freq * t) * envelope * 0.35
		var s16: int = int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data


## M5-Closeout Bucket 6: the
## "crisis_horn" SFX. A 700ms
## low-frequency alarm.
func _make_sfx_crisis_horn() -> PackedByteArray:
	var n_samples: int = int(0.7 * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n_samples * 2)
	for i in range(n_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = 0.7 + 0.3 * sin(2.0 * PI * 8.0 * t)
		# Three low frequencies
		var sample: float = (
			sin(2.0 * PI * 110.0 * t)
			+ 0.7 * sin(2.0 * PI * 165.0 * t)
			+ 0.5 * sin(2.0 * PI * 220.0 * t)
		) * envelope * 0.3
		var s16: int = int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data


## M5-Closeout Bucket 6: the
## "game_over" SFX. A 1-second
## descending major-third
## interval (sad).
func _make_sfx_game_over() -> PackedByteArray:
	var n_samples: int = int(1.0 * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n_samples * 2)
	for i in range(n_samples):
		var t: float = float(i) / float(n_samples)
		var envelope: float = (1.0 - t) * exp(-2.0 * t)
		# Two notes: A4 (440Hz) for
		# first half, F4 (349Hz) for
		# second half (descending
		# major third).
		var freq: float = 440.0 if t < 0.5 else 349.0
		var local_t: float = t if t < 0.5 else (t - 0.5)
		var sample: float = sin(2.0 * PI * freq * local_t) * envelope * 0.4
		var s16: int = int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data


## M5-Closeout Bucket 6: the
## ambient loop. 10 seconds
## of slow, low-frequency
## drone + filtered noise.
## The track is designed to
## loop seamlessly.
func _make_ambient_loop() -> PackedByteArray:
	var n_samples: int = int(AMBIENT_SECONDS * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n_samples * 2)
	for i in range(n_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		# Two slowly-detuned
		# oscillators for a
		# beating effect.
		var sample: float = (
			0.4 * sin(2.0 * PI * 55.0 * t)
			+ 0.3 * sin(2.0 * PI * 55.5 * t)
			+ 0.2 * sin(2.0 * PI * 110.0 * t)
		)
		# Add a hint of filtered
		# noise (random values
		# attenuated by sine).
		var noise: float = randf() * 2.0 - 1.0
		sample += 0.05 * noise * sin(2.0 * PI * 0.5 * t)
		# Clamp + scale.
		sample = clamp(sample, -1.0, 1.0) * 0.4
		var s16: int = int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data


## M5-Closeout Bucket 6: write
## PCM data as a 16-bit mono
## WAV file. The header is
## RIFF/WAVE/PCM (the canonical
## uncompressed WAV format).
func _save_wav(path: String, pcm: PackedByteArray) -> void:
	var n_channels: int = 1
	var bits_per_sample: int = 16
	var byte_rate: int = SAMPLE_RATE * n_channels * bits_per_sample / 8
	var block_align: int = n_channels * bits_per_sample / 8
	var data_size: int = pcm.size()
	var file_size: int = 36 + data_size
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Could not open %s for writing" % path)
		return
	# RIFF header
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(file_size)
	f.store_buffer("WAVE".to_ascii_buffer())
	# fmt chunk
	f.store_buffer("fmt ".to_ascii_buffer())
	f.store_32(16)  # fmt chunk size
	f.store_16(1)  # PCM format
	f.store_16(n_channels)
	f.store_32(SAMPLE_RATE)
	f.store_32(byte_rate)
	f.store_16(block_align)
	f.store_16(bits_per_sample)
	# data chunk
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(data_size)
	f.store_buffer(pcm)
	f.close()
