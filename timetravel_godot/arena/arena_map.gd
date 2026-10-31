extends "res://scripts/level.gd"
# arena_map.gd - the combat test arena's one map (Stage 8a): a plain walled square of packed ground with flagstones in the middle,
# four stone columns (tall: they block sight, stop arrows and stones, and daze the chief's charge, so steering, line of sight and the
# charge can all be tried) and the training dummy in the north-west corner (it takes no damage, so the readouts show a weapon's own DPS on
# it). No people, doors or pickups; enemy_plan() is empty, because every enemy comes from the arena panel's spawner.
#
# Layout (world pixels, map = 640 x 480):
#   walls   north y 0..40 (the face), south y 452..480, west x 0..24, east x 616..640     floor x 24..616, y 40..452
#   columns PILLARS, the dummy DUMMY_AT, the hero's start SPAWN

const Props = preload("res://scripts/props.gd")
const CP = preload("res://scripts/castle_props.gd")
const Terrain = preload("res://scripts/terrain.gd")

const FLOOR := Rect2(24, 40, 592, 412)
const MIDDLE := Rect2(176, 136, 288, 216)       # flagstones under the middle of the square
# [x, y, w, h] solid wall pieces drawn with Props.wall_h / wall_v
const WALLS_H := [[0, 0, 640, 40], [0, 452, 640, 28]]
const WALLS_V := [[0, 40, 24, 412], [616, 40, 24, 412]]
const PILLARS := [Vector2(200, 160), Vector2(440, 160), Vector2(200, 340), Vector2(440, 340)]   # centre of each column's base
const PILLAR_H := 44.0
const DUMMY_AT := Vector2(72, 92)                # the dummy's foot
const SPAWN := Vector2(320, 400)

func _init() -> void:
	key = "arena"
	place_name = "Arena"
	W = 640
	H = 480
	spawn = SPAWN
	spawns = {"start": {"pos": SPAWN, "face": "up"}}

func _ready() -> void:
	_paint()
	_make_nodes()
	for w in WALLS_H:
		solid(w[0], w[1], w[2], w[3])
		var ww: Array = w
		prop(w[1] + w[3], func(n): Props.wall_h(n, ww[0], ww[1], ww[2], ww[3]))
	for w in WALLS_V:
		solid(w[0], w[1], w[2], w[3])
		var ww: Array = w
		prop(w[1] + w[3], func(n): Props.wall_v(n, ww[0], ww[1], ww[2], ww[3]))
	for p in PILLARS:
		var pp: Vector2 = p
		solid(pp.x - 10, pp.y - 9, 20, 10)
		prop(pp.y, func(n): CP.column(n, pp.x, pp.y, PILLAR_H))
	solid(DUMMY_AT.x - 6, DUMMY_AT.y - 6, 12, 6)
	var dummy := {"pos": DUMMY_AT, "t": 99.0, "dir": 1.0, "lean": 0.0}
	hittables.append(dummy)
	prop(DUMMY_AT.y, func(n): Props.dummy(n, dummy["pos"].x, dummy["pos"].y, dummy["lean"]), true)
	_make_debug()

# the ground, painted once
func _paint() -> void:
	var tr := Terrain.new(W, H)
	tr.f(0, 0, W, H, "#7b6a52")
	tr.town_floor(FLOOR)
	tr.flagstones(MIDDLE, 0.1)
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(tr.img)
	spr.centered = false
	add_child(spr)
