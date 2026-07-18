# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026 PitPact contributors
#
# PitPact — M5-Foundation procedural asset generator.
#
# This is the canonical "open-source asset
# pipeline" for PitPact. The generator
# procedurally draws every tile, UI icon,
# inhabitant portrait, and crisis icon the
# M5-Foundation UI needs.
#
# The generator is a Godot 4.7 headless
# script. Re-running it overwrites the PNGs
# (the generator is idempotent; the
# determinism contract is pinned via the
# `SEED` constant). The procedural approach
# is the canonical "no third-party IP" path
# (per docs/requirements.md §20).
#
# The generator is a *tool*, not a runtime
# asset. It runs once at the dev workstation
# to produce the PNGs; the runtime loads
# the PNGs via `Image.load_from_file()` or
# the editor's `.import` system.
#
# Per ADR-0002, this file does not import
# from `src/`. It is a standalone tool
# that lives under `tools/assets/`.
extends SceneTree

const SEED: int = 4242

const _TILE_W: int = 16
const _TILE_H: int = 16
const _UI_ICON_SIZE: int = 32
const _PORTRAIT_W: int = 16
const _PORTRAIT_H: int = 24
const _CRISIS_ICON_SIZE: int = 32

const _TILES_DIR: String = "res://assets/tiles/"
const _UI_DIR: String = "res://assets/ui/"
const _INHAB_DIR: String = "res://assets/inhabitants/"
const _CRISIS_DIR: String = "res://assets/crises/"

# Gothic-Fantasy palette (per docs/style-bible.md
# §2.2 — the M5-Foundation default). Each color
# is a 32-bit RGBA value.
const _PAL: Dictionary = {
	"ink":        Color(0.07, 0.06, 0.10, 1.0),
	"parchment":  Color(0.86, 0.79, 0.62, 1.0),
	"stone":      Color(0.45, 0.42, 0.40, 1.0),
	"stone_dk":   Color(0.30, 0.28, 0.27, 1.0),
	"moss":       Color(0.35, 0.50, 0.30, 1.0),
	"moss_dk":    Color(0.20, 0.35, 0.18, 1.0),
	"ember":      Color(0.95, 0.50, 0.20, 1.0),
	"ember_dk":   Color(0.75, 0.30, 0.10, 1.0),
	"rust":       Color(0.70, 0.30, 0.20, 1.0),
	"violet":     Color(0.45, 0.25, 0.55, 1.0),
	"violet_dk":  Color(0.30, 0.15, 0.40, 1.0),
	"gold":       Color(0.85, 0.70, 0.30, 1.0),
	"blood":      Color(0.70, 0.10, 0.10, 1.0),
	"fog":        Color(0.40, 0.40, 0.45, 0.55),
	"highland":   Color(0.55, 0.45, 0.30, 1.0),
	"highland_dk": Color(0.40, 0.32, 0.20, 1.0),
	"marsh":      Color(0.40, 0.45, 0.35, 1.0),
	"marsh_dk":   Color(0.25, 0.30, 0.20, 1.0),
	"bone":       Color(0.90, 0.85, 0.75, 1.0),
	"shadow":     Color(0.0, 0.0, 0.0, 0.35),
	"highlight":  Color(1.0, 1.0, 1.0, 0.10),
}


func _init() -> void:
	seed(SEED)
	_ensure_dirs()
	# Tiles
	_save_png(_TILES_DIR + "floor_stone.png", _make_floor_stone())
	_save_png(_TILES_DIR + "floor_marsh.png", _make_floor_marsh())
	_save_png(_TILES_DIR + "floor_highland.png", _make_floor_highland())
	_save_png(_TILES_DIR + "wall_stone.png", _make_wall_stone())
	_save_png(_TILES_DIR + "hearth.png", _make_hearth())
	_save_png(_TILES_DIR + "fog.png", _make_fog())
	_save_png(_TILES_DIR + "shrine.png", _make_shrine())
	_save_png(_TILES_DIR + "forge.png", _make_forge())
	_save_png(_TILES_DIR + "well.png", _make_well())
	_save_png(_TILES_DIR + "trap.png", _make_trap())
	# M7 Bucket 1: 4 additional rooms
	# (altar, vault, garden, library).
	_save_png(_TILES_DIR + "altar.png", _make_altar())
	_save_png(_TILES_DIR + "vault.png", _make_vault())
	_save_png(_TILES_DIR + "garden.png", _make_garden())
	_save_png(_TILES_DIR + "library.png", _make_library())
	# UI icons
	_save_png(_UI_DIR + "step.png", _make_icon_step())
	_save_png(_UI_DIR + "auto_tick.png", _make_icon_auto_tick())
	_save_png(_UI_DIR + "save.png", _make_icon_save())
	_save_png(_UI_DIR + "load.png", _make_icon_load())
	_save_png(_UI_DIR + "settings.png", _make_icon_settings())
	_save_png(_UI_DIR + "pause.png", _make_icon_pause())
	_save_png(_UI_DIR + "play.png", _make_icon_play())
	_save_png(_UI_DIR + "power_seal_breach.png", _make_icon_seal())
	_save_png(_UI_DIR + "power_pause_crisis.png", _make_icon_pause_power())
	_save_png(_UI_DIR + "power_reveal_tile.png", _make_icon_reveal())
	# Inhabitant portraits
	_save_png(_INHAB_DIR + "lanternbearer_scribe.png", _make_portrait_lanternbearer_scribe())
	_save_png(_INHAB_DIR + "settler.png", _make_portrait_settler())
	_save_png(_INHAB_DIR + "bellows.png", _make_portrait_bellows())
	_save_png(_INHAB_DIR + "ember.png", _make_portrait_ember())
	_save_png(_INHAB_DIR + "ledger.png", _make_portrait_ledger())
	_save_png(_INHAB_DIR + "silvershroud.png", _make_portrait_silvershroud())
	_save_png(_INHAB_DIR + "tide.png", _make_portrait_tide())
	# M7 Bucket 1: 6 alternative role portraits
	# (2 per culture: lanternbearer_pilot,
	# bellows_smoker, ember_keeper, ledger_scholar,
	# silvershroud_guard, tide_warden).
	_save_png(_INHAB_DIR + "lanternbearer_pilot.png", _make_portrait_lanternbearer_pilot())
	_save_png(_INHAB_DIR + "bellows_smoker.png", _make_portrait_bellows_smoker())
	_save_png(_INHAB_DIR + "ember_keeper.png", _make_portrait_ember_keeper())
	_save_png(_INHAB_DIR + "ledger_scholar.png", _make_portrait_ledger_scholar())
	_save_png(_INHAB_DIR + "silvershroud_guard.png", _make_portrait_silvershroud_guard())
	_save_png(_INHAB_DIR + "tide_warden.png", _make_portrait_tide_warden())
	# Crisis icons
	_save_png(_CRISIS_DIR + "plague.png", _make_crisis_plague())
	_save_png(_CRISIS_DIR + "faction.png", _make_crisis_faction())
	# Tile atlas (4x4 grid of tiles)
	_save_png(_TILES_DIR + "atlas_4x4.png", _make_atlas_4x4())
	print("Assets generated: tiles=%d ui=%d inhabitants=%d crises=%d" % [
		_count_files(_TILES_DIR), _count_files(_UI_DIR),
		_count_files(_INHAB_DIR), _count_files(_CRISIS_DIR)
	])
	quit()


func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_TILES_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_UI_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_INHAB_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_CRISIS_DIR))


func _count_files(p_dir: String) -> int:
	var d: DirAccess = DirAccess.open(p_dir)
	if d == null:
		return 0
	var n: int = 0
	d.list_dir_begin()
	var name: String = d.get_next()
	while name != "":
		if not d.current_is_dir() and name.ends_with(".png"):
			n += 1
		name = d.get_next()
	d.list_dir_end()
	return n


func _save_png(p_path: String, p_image: Image) -> void:
	var abs_path: String = ProjectSettings.globalize_path(p_path)
	p_image.save_png(abs_path)


# --- Tile generators ---

func _make_floor_stone() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Cracks
	for i in range(3):
		var x: int = randi() % _TILE_W
		var y: int = randi() % _TILE_H
		img.set_pixel(x, y, _PAL.stone_dk)
		if x + 1 < _TILE_W:
			img.set_pixel(x + 1, y, _PAL.stone_dk)
	# Mossy corners (top-left)
	for dx in range(3):
		for dy in range(3):
			if randf() < 0.5:
				img.set_pixel(dx, dy, _PAL.moss)
	return img


func _make_floor_marsh() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.marsh)
	for i in range(4):
		var x: int = randi() % _TILE_W
		var y: int = randi() % _TILE_H
		img.set_pixel(x, y, _PAL.marsh_dk)
	# Puddles
	for i in range(2):
		var px: int = 2 + randi() % (_TILE_W - 4)
		var py: int = 2 + randi() % (_TILE_H - 4)
		img.set_pixel(px, py, _PAL.stone_dk)
		img.set_pixel(px + 1, py, _PAL.stone_dk)
	return img


func _make_floor_highland() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.highland)
	for i in range(5):
		var x: int = randi() % _TILE_W
		var y: int = randi() % _TILE_H
		img.set_pixel(x, y, _PAL.highland_dk)
	return img


func _make_wall_stone() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone_dk)
	# Top row is brighter (light from above)
	for x in range(_TILE_W):
		img.set_pixel(x, 0, _PAL.stone)
	# Bottom shadow
	for x in range(_TILE_W):
		img.set_pixel(x, _TILE_H - 1, _PAL.ink)
	# Brick pattern
	for y in range(2, _TILE_H - 1, 4):
		for x in range(_TILE_W):
			if (y / 4) % 2 == 0:
				if x % 8 == 0:
					img.set_pixel(x, y, _PAL.ink)
			else:
				if (x + 4) % 8 == 0:
					img.set_pixel(x, y, _PAL.ink)
	return img


func _make_hearth() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Hearth stones (3x3 in middle)
	for dx in range(3, 13):
		for dy in range(3, 13):
			img.set_pixel(dx, dy, _PAL.stone_dk)
	# Ember glow (center)
	for dx in range(6, 10):
		for dy in range(6, 10):
			img.set_pixel(dx, dy, _PAL.ember)
	# Bright center
	img.set_pixel(7, 7, _PAL.gold)
	img.set_pixel(8, 7, _PAL.gold)
	img.set_pixel(7, 8, _PAL.gold)
	img.set_pixel(8, 8, _PAL.gold)
	# Top edge highlight
	for x in range(_TILE_W):
		img.set_pixel(x, 0, _PAL.ember_dk)
	return img


func _make_fog() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.fog)
	# Wisps
	for i in range(3):
		var x: int = randi() % _TILE_W
		var y: int = randi() % _TILE_H
		img.set_pixel(x, y, _PAL.parchment)
	return img


## M5-Closeout Bucket 2: shrine
## tile. The shrine is a ritual
## site; the win condition
## (M5-Closeout Bucket 4) requires
## at least 1 shrine. The shrine
## has a gold-trimmed base + a
## violet altar in the center.
func _make_shrine() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Base (parchment slab)
	for y in range(8, 14):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.parchment)
	# Altar (violet)
	for y in range(6, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.violet)
	# Gold trim
	for x in range(4, 12):
		img.set_pixel(x, 8, _PAL.gold)
		img.set_pixel(x, 13, _PAL.gold)
	img.set_pixel(4, 8, _PAL.gold)
	img.set_pixel(11, 8, _PAL.gold)
	img.set_pixel(4, 13, _PAL.gold)
	img.set_pixel(11, 13, _PAL.gold)
	return img


## M5-Closeout Bucket 2: forge
## tile. The forge is a crafting
## site; the bellows culture
## (M5-Closeout Bucket 1) gets
## a bonus here. The forge has
## a stone base + an ember-glow
## center.
func _make_forge() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Anvil (dark stone)
	for y in range(6, 10):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.stone_dk)
	# Ember glow (center)
	for y in range(10, 14):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.ember)
	img.set_pixel(7, 11, _PAL.gold)
	img.set_pixel(8, 11, _PAL.gold)
	img.set_pixel(7, 12, _PAL.gold)
	img.set_pixel(8, 12, _PAL.gold)
	return img


## M5-Closeout Bucket 2: well
## tile. The well is a water
## source; the tide culture
## (M5-Closeout Bucket 1) gets
## a bonus here. The well has
## a stone rim + a blue (highland)
## water surface.
func _make_well() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Rim
	for y in range(5, 12):
		for x in range(3, 13):
			img.set_pixel(x, y, _PAL.stone_dk)
	# Water (highland blue)
	for y in range(7, 10):
		for x in range(5, 11):
			img.set_pixel(x, y, _PAL.highland)
	# Center post
	for y in range(2, 5):
		img.set_pixel(8, y, _PAL.bone)
	img.set_pixel(7, 2, _PAL.bone)
	img.set_pixel(9, 2, _PAL.bone)
	return img


## M5-Closeout Bucket 2: trap
## tile. The trap is a
## crisis-amplifier (the
## M5-Closeout Bucket 3 events
## can trigger a trap effect).
## The trap has a blood-red
## pressure plate + a stone
## base.
func _make_trap() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Pressure plate (blood)
	for y in range(8, 12):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.blood)
	# Teeth (bone spikes)
	for x in range(5, 11):
		img.set_pixel(x, 5, _PAL.bone)
		img.set_pixel(x, 6, _PAL.bone)
	# Inset shadow
	for x in range(5, 11):
		img.set_pixel(x, 13, _PAL.stone_dk)
	return img


## M7 Bucket 1: altar tile. The
## altar is a ritual site that
## boosts Pactmaker powers. The
## altar has a gold base + a
## violet central rune.
func _make_altar() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Base (gold)
	for y in range(10, 14):
		for x in range(3, 13):
			img.set_pixel(x, y, _PAL.gold)
	# Rune (violet)
	for y in range(5, 10):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.violet)
	# Top point (bone)
	img.set_pixel(8, 4, _PAL.bone)
	img.set_pixel(7, 5, _PAL.bone)
	img.set_pixel(9, 5, _PAL.bone)
	return img


## M7 Bucket 1: vault tile. The
## vault is a storage site for
## resources. The vault has a
## stone arch + an iron door.
func _make_vault() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Arch (parchment trim)
	for y in range(2, 8):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.parchment)
	# Door (dark stone)
	for y in range(8, 14):
		for x in range(5, 11):
			img.set_pixel(x, y, _PAL.stone_dk)
	# Door handle (gold)
	img.set_pixel(9, 11, _PAL.gold)
	return img


## M7 Bucket 1: garden tile. The
## garden is a food source. The
## garden has grass + sprouts.
func _make_garden() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.moss)
	# Soil patches (stone)
	for y in range(10, 13):
		for x in range(2, 14):
			if (x + y) % 3 == 0:
				img.set_pixel(x, y, _PAL.stone)
	# Sprouts (green)
	for x in range(3, 13):
		img.set_pixel(x, 5, _PAL.moss)
		img.set_pixel(x, 6, _PAL.moss)
	return img


## M7 Bucket 1: library tile. The
## library is a research-boost
## site. The library has stone
## walls + parchment books.
func _make_library() -> Image:
	var img: Image = Image.create(_TILE_W, _TILE_H, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.stone)
	# Bookshelf (parchment)
	for y in range(4, 12):
		for x in range(3, 13):
			img.set_pixel(x, y, _PAL.parchment)
	# Books (alternating colors)
	for x in range(4, 12):
		if x % 2 == 0:
			for y in range(6, 11):
				img.set_pixel(x, y, _PAL.blood)
		else:
			for y in range(6, 11):
				img.set_pixel(x, y, _PAL.ink)
	# Shelf trim
	for x in range(3, 13):
		img.set_pixel(x, 4, _PAL.gold)
		img.set_pixel(x, 12, _PAL.gold)
	return img


# --- UI icon generators ---

func _make_icon_step() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Right-pointing triangle
	for y in range(8, 24):
		var w: int = (y - 8) * 2 / 3 + 4
		for x in range(8, 8 + w):
			img.set_pixel(x, y, _PAL.parchment)
	return img


func _make_icon_auto_tick() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Circle (refresh symbol)
	for y in range(8, 24):
		for x in range(8, 24):
			var d: float = Vector2(x - 16, y - 16).length()
			if d > 6 and d < 9:
				img.set_pixel(x, y, _PAL.ember)
	# Center dot
	img.set_pixel(16, 16, _PAL.ember)
	return img


func _make_icon_save() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Floppy outline
	for y in range(6, 26):
		img.set_pixel(8, y, _PAL.parchment)
		img.set_pixel(23, y, _PAL.parchment)
	for x in range(8, 24):
		img.set_pixel(x, 6, _PAL.parchment)
		img.set_pixel(x, 25, _PAL.parchment)
	# Inner square
	for y in range(10, 18):
		for x in range(12, 20):
			img.set_pixel(x, y, _PAL.stone_dk)
	return img


func _make_icon_load() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Up-arrow
	for y in range(8, 24):
		var w: int = (24 - y) * 2 + 2
		var x_start: int = maxi(0, 16 - w / 2)
		var x_end: int = mini(_UI_ICON_SIZE, 16 + w / 2)
		for x in range(x_start, x_end):
			img.set_pixel(x, y, _PAL.parchment)
	return img


func _make_icon_settings() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Gear (8-tooth)
	for i in range(8):
		var angle: float = i * PI / 4.0
		var tx: int = int(16 + cos(angle) * 9)
		var ty: int = int(16 + sin(angle) * 9)
		img.set_pixel(tx, ty, _PAL.gold)
		img.set_pixel(tx + 1, ty, _PAL.gold)
		img.set_pixel(tx, ty + 1, _PAL.gold)
	# Hub
	for y in range(13, 19):
		for x in range(13, 19):
			img.set_pixel(x, y, _PAL.gold)
	return img


func _make_icon_pause() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Two vertical bars
	for y in range(8, 24):
		for x in range(11, 14):
			img.set_pixel(x, y, _PAL.parchment)
		for x in range(18, 21):
			img.set_pixel(x, y, _PAL.parchment)
	return img


func _make_icon_play() -> Image:
	return _make_icon_step()


func _make_icon_seal() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Hexagram (6-pointed seal)
	for i in range(6):
		var angle: float = i * PI / 3.0
		var tx: int = int(16 + cos(angle) * 8)
		var ty: int = int(16 + sin(angle) * 8)
		for r in range(3):
			img.set_pixel(int(16 + cos(angle) * r), int(16 + sin(angle) * r), _PAL.violet)
		img.set_pixel(tx, ty, _PAL.violet)
	# Center
	img.set_pixel(16, 16, _PAL.gold)
	return img


func _make_icon_pause_power() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Stop hand
	for y in range(8, 24):
		for x in range(13, 19):
			img.set_pixel(x, y, _PAL.blood)
	return img


func _make_icon_reveal() -> Image:
	var img: Image = Image.create(_UI_ICON_SIZE, _UI_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Eye
	for y in range(12, 20):
		for x in range(8, 24):
			var dx: float = abs(x - 16) / 8.0
			var dy: float = abs(y - 16) / 4.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, _PAL.ember)
	# Pupil
	img.set_pixel(16, 16, _PAL.ink)
	return img


# --- Portrait generators ---

func _make_portrait_lanternbearer_scribe() -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe (parchment with violet trim)
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.parchment)
	# Head (bone)
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.bone)
	# Lantern (held in hand)
	for y in range(14, 18):
		for x in range(11, 14):
			img.set_pixel(x, y, _PAL.gold)
	img.set_pixel(12, 16, _PAL.ember)
	# Trim
	for y in range(8, 12):
		img.set_pixel(4, y, _PAL.violet)
		img.set_pixel(11, y, _PAL.violet)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


func _make_portrait_settler() -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe (stone)
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.stone)
	# Head
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.bone)
	# Tool (axe)
	for y in range(10, 18):
		img.set_pixel(12, y, _PAL.stone_dk)
	img.set_pixel(12, 10, _PAL.stone_dk)
	img.set_pixel(13, 10, _PAL.stone_dk)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


## M5-Closeout Bucket 1: bellows
## culture portrait. The bellows-
## tender carries a leather
## bellows at their hip; the
## bellows are used to fan
## forge-fires. The portrait
## has a leather-bag shape on
## the right side.
func _make_portrait_bellows() -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe (moss)
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.moss)
	# Head
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.bone)
	# Bellows (leather bag)
	for y in range(12, 18):
		for x in range(11, 14):
			img.set_pixel(x, y, _PAL.stone_dk)
	img.set_pixel(11, 12, _PAL.stone)
	img.set_pixel(13, 12, _PAL.stone)
	# Nozzle (gold tip)
	img.set_pixel(14, 14, _PAL.gold)
	img.set_pixel(14, 15, _PAL.gold)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


## M5-Closeout Bucket 1: ember
## culture portrait. The fire-
## keeper carries a glowing
## ember; the ember is the
## defining silhouette.
func _make_portrait_ember() -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe (blood-red)
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.blood)
	# Head
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.bone)
	# Ember (glowing orange)
	for y in range(10, 16):
		for x in range(11, 14):
			img.set_pixel(x, y, _PAL.ember)
	img.set_pixel(12, 12, _PAL.gold)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


## M5-Closeout Bucket 1: ledger
## culture portrait. The ledger
## scribe carries a book at
## their side; the book is the
## defining feature.
func _make_portrait_ledger() -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe (parchment with gold trim)
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.parchment)
	# Head
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.bone)
	# Book (gold-edged)
	for y in range(12, 18):
		for x in range(11, 14):
			img.set_pixel(x, y, _PAL.gold)
	img.set_pixel(11, 12, _PAL.ink)
	img.set_pixel(13, 12, _PAL.ink)
	img.set_pixel(11, 17, _PAL.ink)
	img.set_pixel(13, 17, _PAL.ink)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


## M5-Closeout Bucket 1: silvershroud
## culture portrait. The oath-
## keeper carries a silver
## chain; the chain is the
## defining feature.
func _make_portrait_silvershroud() -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe (fog)
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.fog)
	# Head
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.bone)
	# Chain (silver thread)
	for y in range(10, 18):
		img.set_pixel(12, y, _PAL.bone)
	img.set_pixel(11, 12, _PAL.bone)
	img.set_pixel(13, 12, _PAL.bone)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


## M5-Closeout Bucket 1: tide
## culture portrait. The tide-
## reader carries a kelp
## strand; the kelp is the
## defining feature.
func _make_portrait_tide() -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe (marsh)
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, _PAL.marsh)
	# Head
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, _PAL.bone)
	# Kelp (green strand)
	for y in range(10, 18):
		img.set_pixel(12, y, _PAL.moss)
	img.set_pixel(11, 14, _PAL.moss)
	img.set_pixel(13, 14, _PAL.moss)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


## M7 Bucket 1: 6 alternative
## role portraits. The factory
## is the canonical "M7 portrait"
## entry point; the variations
## are based on the canonical
## 6 culture portraits but with
## different secondary color
## (the M7 closeout's "tier-2
## role" indicator).
func _make_portrait_lanternbearer_pilot() -> Image:
	return _make_portrait_variant(_PAL.parchment, _PAL.violet, _PAL.gold, 12, 8, _PAL.ember)


func _make_portrait_bellows_smoker() -> Image:
	return _make_portrait_variant(_PAL.moss, _PAL.stone, _PAL.ember, 13, 6, _PAL.gold)


func _make_portrait_ember_keeper() -> Image:
	return _make_portrait_variant(_PAL.blood, _PAL.bone, _PAL.gold, 11, 10, _PAL.ember)


func _make_portrait_ledger_scholar() -> Image:
	return _make_portrait_variant(_PAL.parchment, _PAL.gold, _PAL.ink, 12, 8, _PAL.ink)


func _make_portrait_silvershroud_guard() -> Image:
	return _make_portrait_variant(_PAL.fog, _PAL.bone, _PAL.ink, 11, 9, _PAL.bone)


func _make_portrait_tide_warden() -> Image:
	return _make_portrait_variant(_PAL.marsh, _PAL.bone, _PAL.moss, 12, 9, _PAL.moss)


## M7 Bucket 1: helper that
## builds a portrait variant
## from the canonical 16x24
## template. The factory is
## the canonical "M7 portrait
## variant" entry point; the
## per-variant parameters are
## `robe_color`, `head_color`,
## `accent_color`, `accent_x`,
## `accent_y`, `accent_secondary`.
func _make_portrait_variant(robe_color: Color, head_color: Color, accent_color: Color, accent_x: int, accent_y: int, accent_secondary: Color) -> Image:
	var img: Image = Image.create(_PORTRAIT_W, _PORTRAIT_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Robe
	for y in range(8, 24):
		for x in range(4, 12):
			img.set_pixel(x, y, robe_color)
	# Head
	for y in range(2, 8):
		for x in range(6, 10):
			img.set_pixel(x, y, head_color)
	# Accent (held item)
	img.set_pixel(accent_x, accent_y, accent_color)
	img.set_pixel(accent_x + 1, accent_y, accent_color)
	img.set_pixel(accent_x, accent_y + 1, accent_secondary)
	img.set_pixel(accent_x + 1, accent_y + 1, accent_secondary)
	# Eyes
	img.set_pixel(7, 4, _PAL.ink)
	img.set_pixel(9, 4, _PAL.ink)
	return img


# --- Crisis icon generators ---

func _make_crisis_plague() -> Image:
	var img: Image = Image.create(_CRISIS_ICON_SIZE, _CRISIS_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Skull
	for y in range(8, 22):
		for x in range(10, 22):
			var dx: float = (x - 16) / 6.0
			var dy: float = (y - 14) / 7.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, _PAL.bone)
	# Eye sockets
	img.set_pixel(13, 13, _PAL.ink)
	img.set_pixel(19, 13, _PAL.ink)
	# Teeth
	for x in range(13, 20):
		img.set_pixel(x, 19, _PAL.ink)
	# Blood drip
	for y in range(22, 28):
		img.set_pixel(16, y, _PAL.blood)
	return img


func _make_crisis_faction() -> Image:
	var img: Image = Image.create(_CRISIS_ICON_SIZE, _CRISIS_ICON_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Two crossed swords
	for i in range(-10, 11):
		var x1: int = 16 + i
		var y1: int = 8 + i
		var x2: int = 16 + i
		var y2: int = 24 - i
		if x1 >= 0 and x1 < 32 and y1 >= 0 and y1 < 32:
			img.set_pixel(x1, y1, _PAL.bone)
		if x2 >= 0 and x2 < 32 and y2 >= 0 and y2 < 32:
			img.set_pixel(x2, y2, _PAL.bone)
	# Pommels
	for y in range(6, 10):
		for x in range(14, 18):
			img.set_pixel(x, y, _PAL.gold)
			img.set_pixel(36 - x, 36 - y, _PAL.gold)
	return img


# --- Atlas ---

func _make_atlas_4x4() -> Image:
	# M7 Bucket 1: atlas is now
	# 4x4 (16 cells) — 6 M5-Foundation
	# + 4 M5-Closeout + 4 M7 Bucket 1
	# cells. The atlas file name
	# `atlas_4x4.png` is now *accurate*
	# (4 rows x 4 cols).
	var img: Image = Image.create(_TILE_W * 4, _TILE_H * 4, false, Image.FORMAT_RGBA8)
	img.fill(_PAL.ink)
	var tile_a: Image = _make_floor_stone()
	var tile_b: Image = _make_floor_marsh()
	var tile_c: Image = _make_floor_highland()
	var tile_d: Image = _make_wall_stone()
	# Row 0: floor variants
	_blit(img, tile_a, 0, 0)
	_blit(img, tile_b, 1, 0)
	_blit(img, tile_c, 2, 0)
	_blit(img, tile_d, 3, 0)
	# Row 1: hearth + fog + filler
	_blit(img, _make_hearth(), 0, 1)
	_blit(img, _make_fog(), 1, 1)
	_blit(img, tile_a, 2, 1)
	_blit(img, tile_d, 3, 1)
	# Row 2 (M5-Closeout): shrine, forge, well, trap
	_blit(img, _make_shrine(), 0, 2)
	_blit(img, _make_forge(), 1, 2)
	_blit(img, _make_well(), 2, 2)
	_blit(img, _make_trap(), 3, 2)
	# Row 3 (M7 Bucket 1): altar, vault, garden, library
	_blit(img, _make_altar(), 0, 3)
	_blit(img, _make_vault(), 1, 3)
	_blit(img, _make_garden(), 2, 3)
	_blit(img, _make_library(), 3, 3)
	return img


func _blit(p_dst: Image, p_src: Image, p_col: int, p_row: int) -> void:
	for y in range(_TILE_H):
		for x in range(_TILE_W):
			var c: Color = p_src.get_pixel(x, y)
			p_dst.set_pixel(p_col * _TILE_W + x, p_row * _TILE_H + y, c)
