extends "res://scripts/level.gd"
# storeroom.gd - the storeroom map (a separate map from the town; you reach it through the storeroom door in the town).
# Shape (from the reference image): a wide top room (the giant rat's barn), a long corridor south, a side room on the east side of the
# corridor, a lower room, and an entrance passage with the exit door at the bottom.
# The barn (boss room) is 28 x 15 tiles = 448 x 240 px of floor, so it fits on one screen: the rice / seed pile is at the far north with the
# giant rat and its rats munching at it, four fenced hay pens (two each side, the southern two are where the summoned rats come from),
# two small cover piles, torches. The gate (corridor mouth) is at the bottom centre, far from the pile.
#
#   LAYOUT is in 16 px tiles. Everything you can walk on is a rectangle in FLOORS; walls are made automatically (two tiles thick)
#   around them; everything else is black void. Props, torches and enemies are data further down.
# Light: a dark ambient colour (CanvasModulate) plus warm point lights at the torches and a soft lantern that follows the hero.

const Props = preload("res://scripts/props.gd")

const T := 16
const COLS := 40
const ROWS := 58
const END_ROW := 56       # nothing is built from this row down (y 896, the bottom edge of the exit door): just black, so the door shows
                          # clear of the HUD's hint line at the bottom of the screen

# walkable rectangles in tiles: [x0, y0, x1, y1] (x1 / y1 not included)
const FLOORS := [
	[6, 3, 34, 18],      # the barn: boss room (448 x 240 px, fits one screen)
	[17, 18, 23, 36],    # long corridor
	[25, 22, 38, 33],    # side room (east)
	[23, 26, 25, 30],    # opening between the corridor and the side room
	[11, 36, 29, 49],    # lower room (first rats)
	[17, 49, 23, 56],    # entrance passage: dirt all the way down to the exit door
]

# torches: [x, y]  (foot of the torch; the light sits 30 px above)
const TORCHES := [
	[244, 66], [396, 66], [104, 150], [536, 150], [286, 420], [596, 506], [446, 690], [276, 866], [364, 866], [188, 722],
]

# props: [kind, x, y]  kind: barrel | crate | stack | sacks | hay   (y = foot, drawn against the wall behind it)
const PROPS := [
	# the barn: corners of the back wall, flanking the pile, and two small cover piles in the south half (off the gate's line)
	["barrel", 112, 76], ["barrel", 128, 76], ["crate", 150, 78], ["barrel", 528, 76], ["barrel", 512, 76], ["crate", 490, 78],
	["stack", 206, 74], ["stack", 434, 74], ["sacks", 176, 76], ["sacks", 464, 76],
	["sacks", 214, 222], ["crate", 238, 226], ["barrel", 202, 242], ["sacks", 426, 214], ["barrel", 402, 222], ["stack", 440, 240],
	# corridor
	["crate", 282, 340], ["barrel", 358, 372], ["sacks", 350, 470], ["crate", 282, 520], ["barrel", 284, 548],
	# side room
	["stack", 456, 370], ["barrel", 520, 370], ["barrel", 536, 370], ["sacks", 580, 374], ["crate", 594, 436], ["crate", 594, 458],
	["hay", 440, 520], ["barrel", 420, 520],
	# lower room
	["sacks", 202, 596], ["stack", 232, 596], ["sacks", 414, 596], ["stack", 446, 596],
	["crate", 188, 676], ["crate", 188, 698], ["barrel", 192, 748], ["barrel", 208, 750], ["crate", 450, 740], ["barrel", 452, 764],
]

# Enemy groups. "wake" = a group sleeps until the hero comes within `radius` of `center`.
#  entrance: 3 small rats, awake from the start (right inside the first room)
#  side:     2 rats in the side room + 1 in the corridor, wake when you enter the corridor
#  boss:     the giant rat + 2 small rats, wake when you get near the top room
const WAKE := {
	"side": {"center": Vector2(320, 500), "radius": 110.0},
	"boss": {"center": Vector2(320, 176), "radius": 62.0, "aggro": true},   # the middle of the barn: the whole group charges at once
}
# the rice / seed pile (a solid block at the far north of the barn) and the open sacks below it that the rats eat from
const PILE := Rect2(276, 72, 96, 46)
const OPEN_SACKS := [Vector2(284, 130), Vector2(356, 130)]
const ENEMIES := [
	{"kind": "rat", "pos": Vector2(250, 664), "group": ""},
	{"kind": "rat", "pos": Vector2(388, 654), "group": ""},
	{"kind": "rat", "pos": Vector2(322, 706), "group": ""},
	{"kind": "rat", "pos": Vector2(480, 436), "group": "side"},
	{"kind": "rat", "pos": Vector2(548, 482), "group": "side"},
	{"kind": "rat", "pos": Vector2(322, 400), "group": "side"},
	# the barn: the giant and 3 rats, all eating at the pile until you reach the middle of the room
	{"kind": "giant", "pos": Vector2(320, 144), "group": "boss", "munch": Vector2(320, 118)},
	{"kind": "rat", "pos": Vector2(262, 144), "group": "boss", "munch": Vector2(284, 130)},
	{"kind": "rat", "pos": Vector2(378, 144), "group": "boss", "munch": Vector2(356, 130)},
	{"kind": "rat", "pos": Vector2(320, 166), "group": "boss", "munch": Vector2(320, 118)},
]

# things to take (level.gd pickups, Stage 7g): [id, item, n, foot]
const PICKUPS := [
	["sacks_bread", "bread", 2, Vector2(226, 614)],          # among the sacks of the lower room
	["gate_potion", "small_potion", 1, Vector2(300, 300)],   # at the barn's gate, before the giant
	# Datis's broken sword (his side quest, Stage 7l): the blade where the side room's rats nest, the hilt by the giant's pile
	["sword_blade", "sword_blade", 1, Vector2(570, 500)],
	["sword_hilt", "sword_hilt", 1, Vector2(392, 112)],
]

# the four hay pens (tiles x0, y0, x1, y1). Fence rails are solid; the hay is just floor.
const PENS := [[6, 6, 10, 12], [6, 12, 10, 18], [30, 6, 34, 12], [30, 12, 34, 18]]
# where the giant's summoned rats come out: inside the two SOUTHERN pens (left and right)
const SUMMON_LEFT := [Vector2(108, 208), Vector2(132, 212), Vector2(108, 236), Vector2(132, 240), Vector2(108, 264), Vector2(132, 268), Vector2(146, 226), Vector2(146, 256)]

var _floor := {}          # tile key -> true
var _wall := {}           # tile key -> true
var _lantern

func _init() -> void:
	key = "storeroom"
	place_name = "The Storeroom"
	rats_flee = false                          # storeroom rats fight to the death
	pickup_plan = PICKUPS
	W = COLS * T
	H = ROWS * T
	spawns = {"entry": {"pos": Vector2(320, 826), "face": "up"}}
	spawn = spawns["entry"]["pos"]
	# the exit door (south end of the passage): stand in front of it and press E -> back out into the town
	doors = [{"rect": Rect2(272, 846, 96, 46), "prompt": Vector2(320, 856), "to": "town", "spawn": "storeroom_door"}]
	for k in WAKE.keys():
		groups[k] = {"center": WAKE[k]["center"], "radius": WAKE[k]["radius"], "active": false, "aggro": WAKE[k].get("aggro", false)}

func _ready() -> void:
	for f in FLOORS:
		for x in range(f[0], f[2]):
			for y in range(f[1], f[3]):
				_floor[_k(x, y)] = true
	for x in range(COLS):
		for y in range(END_ROW):
			if _floor.has(_k(x, y)):
				continue
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if _floor.has(_k(x + dx, y + dy)):
						_wall[_k(x, y)] = true
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(_paint())
	spr.centered = false
	add_child(spr)
	_make_nodes()
	_wall_solids()
	_add_props()
	_add_barn()
	_add_torches()
	_make_pickups()
	_make_door_prompts()
	_exit_door()
	_make_debug()
	_add_lighting()

func _k(x: int, y: int) -> int:
	return x * 4096 + y

func _in_pen(x: int, y: int) -> bool:
	for p in PENS:
		if x >= p[0] and x < p[2] and y >= p[1] and y < p[3]:
			return true
	return false

func _is_floor(x: int, y: int) -> bool:
	return _floor.has(_k(x, y))

# ---------------------------------------------------------------- ground painting (done once)
func _paint() -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for x in range(COLS):
		for y in range(ROWS):
			var r := Rect2i(x * T, y * T, T, T)
			if _is_floor(x, y):
				_paint_floor(img, rng, x, y, r)
			elif _wall.has(_k(x, y)):
				_paint_wall(img, rng, x, y, r)
	return img

func _paint_floor(img: Image, rng: RandomNumberGenerator, x: int, y: int, r: Rect2i) -> void:
	var tone := rng.randi_range(0, 2)
	var base: Color = [Color("#5a3d25"), Color("#533720"), Color("#614329")][tone]
	var hay := _in_pen(x, y)
	if hay:
		base = [Color("#7a5e2c"), Color("#705528"), Color("#846830")][tone]
	img.fill_rect(r, base)
	if hay:      # straw strokes
		for i in range(10):
			var sc := Color("#b08a3a") if rng.randf() < 0.55 else Color("#5a4420")
			img.fill_rect(Rect2i(r.position.x + rng.randi_range(0, 11), r.position.y + rng.randi_range(0, 14), rng.randi_range(3, 5), 1), sc)
	for i in range(0 if hay else 9):    # dirt speckles
		var c := Color("#3f2a18") if rng.randf() < 0.5 else Color("#74522f")
		img.fill_rect(Rect2i(r.position.x + rng.randi_range(0, 13), r.position.y + rng.randi_range(0, 14), rng.randi_range(1, 3), 1), c)
	if rng.randf() < 0.32:    # pebble
		var px := r.position.x + rng.randi_range(1, 12)
		var py := r.position.y + rng.randi_range(1, 12)
		img.fill_rect(Rect2i(px, py, 3, 2), Color("#8a7358"))
		img.fill_rect(Rect2i(px, py + 2, 3, 1), Color("#3a2a1a"))
	if rng.randf() < 0.14 and not hay:    # spilled grain
		var gx := r.position.x + rng.randi_range(1, 12)
		var gy := r.position.y + rng.randi_range(1, 12)
		for j in range(4):
			img.fill_rect(Rect2i(gx + rng.randi_range(-2, 3), gy + rng.randi_range(-2, 3), 1, 1), Color("#d4a94c"))
	# the wall above throws a shadow onto the floor, the wall at the side darkens the edge
	if not _is_floor(x, y - 1):
		img.fill_rect(Rect2i(r.position.x, r.position.y, T, 5), Color(0, 0, 0, 0.35))
		img.fill_rect(Rect2i(r.position.x, r.position.y + 5, T, 3), Color(0, 0, 0, 0.16))
	if not _is_floor(x - 1, y):
		img.fill_rect(Rect2i(r.position.x, r.position.y, 3, T), Color(0, 0, 0, 0.22))
	if not _is_floor(x + 1, y):
		img.fill_rect(Rect2i(r.position.x + 13, r.position.y, 3, T), Color(0, 0, 0, 0.22))
	# worn path down the middle of the corridor and the entrance passage, right up to the exit door (dirt all the way, no stone)
	if x >= 18 and x <= 21 and y >= 15 and y < END_ROW and rng.randf() < 0.5:
		img.fill_rect(Rect2i(r.position.x + rng.randi_range(0, 12), r.position.y + rng.randi_range(0, 12), 3, 1), Color("#7c5a36"))

func _paint_wall(img: Image, rng: RandomNumberGenerator, x: int, y: int, r: Rect2i) -> void:
	if _is_floor(x, y + 1):
		# front face of a north wall: brick rows
		img.fill_rect(r, Color("#4d4036"))
		for row in range(2):
			var by := r.position.y + row * 8
			img.fill_rect(Rect2i(r.position.x, by + 7, T, 1), Color("#2a211b"))
			var off := (x + row) % 2 * 8
			img.fill_rect(Rect2i(r.position.x + off, by, 1, 7), Color("#2a211b"))
			img.fill_rect(Rect2i(r.position.x + (off + 8) % 16, by, 1, 7), Color("#2a211b"))
			img.fill_rect(Rect2i(r.position.x, by, T, 1), Color("#625446"))
		for i in range(3):
			img.fill_rect(Rect2i(r.position.x + rng.randi_range(0, 13), r.position.y + rng.randi_range(0, 14), 2, 1), Color("#3a2f27"))
		img.fill_rect(Rect2i(r.position.x, r.position.y + 14, T, 2), Color(0, 0, 0, 0.3))
	else:
		# top of a wall: grey flagstones with a light top-left edge
		var tone := 0 if (x + y) % 2 == 0 else 1
		img.fill_rect(r, [Color("#6a655d"), Color("#625d55")][tone])
		img.fill_rect(Rect2i(r.position.x, r.position.y, T, 1), Color("#8b857a"))
		img.fill_rect(Rect2i(r.position.x, r.position.y, 1, T), Color("#7d776c"))
		img.fill_rect(Rect2i(r.position.x, r.position.y + 15, T, 1), Color("#3d3931"))
		img.fill_rect(Rect2i(r.position.x + 15, r.position.y, 1, T), Color("#3d3931"))
		for i in range(2):
			img.fill_rect(Rect2i(r.position.x + rng.randi_range(2, 12), r.position.y + rng.randi_range(2, 12), 2, 1), Color("#57524a"))

# ---------------------------------------------------------------- collision: wall tiles, merged along each row
func _wall_solids() -> void:
	for y in range(ROWS):
		var x := 0
		while x < COLS:
			if _wall.has(_k(x, y)):
				var x0 := x
				while x < COLS and _wall.has(_k(x, y)):
					x += 1
				solid(x0 * T, y * T, (x - x0) * T, T)
			else:
				x += 1

# ---------------------------------------------------------------- props (barrels, crates ...) and torches
func _add_props() -> void:
	for p in PROPS:
		var kind: String = p[0]
		var x: float = p[1]
		var y: float = p[2]
		match kind:
			"barrel":
				solid(x - 6, y - 5, 12, 6)
				prop(y, func(n): Props.barrel(n, x, y))
			"crate":
				solid(x - 7, y - 6, 14, 7)
				prop(y, func(n): Props.crate(n, x, y))
			"stack":
				solid(x - 16, y - 6, 32, 7)
				prop(y, func(n): Props.crate_stack(n, x, y))
			"sacks":
				solid(x - 12, y - 6, 24, 7)
				prop(y, func(n): Props.sacks(n, x, y))
			"hay":
				solid(x - 10, y - 6, 20, 7)
				prop(y, func(n): Props.hay(n, x, y))

# ---------------------------------------------------------------- the barn: pile, open sacks, pen fences
# a rail is low: it stops feet, but a rat sees over it (so the alarm and the rats' eyes reach across the pens and the side room)
func _fence(x: float, y: float, w: float, h: float) -> void:
	solid(x, y, w, h, true)
	prop(y + h, func(n):
		Props.ob(n, x, y, w, h, Props.WD, Props.WD_L, Props.WD_D)
		if w > h:       # posts every 24 px on a horizontal rail
			var px := x
			while px <= x + w - 3:
				Props.R(n, px, y - 3, 3, h + 4, Props.WD_D)
				px += 24.0
		else:
			var py := y
			while py <= y + h - 3:
				Props.R(n, x - 1, py, h + 2, 3, Props.WD_D)
				py += 24.0)

func _open_sack(n, x: float, y: float) -> void:
	Props.shadow(n, x + 3, y + 1, 12, 3)
	# grain spilled in front, an open burlap sack behind it
	Props.blob(n, x + 2, y - 1, 11, 4, Color("#8a6a2c"))
	Props.blob(n, x + 1, y - 2, 9, 3, Color("#d4a94c"))
	Props.R(n, x - 7, y - 13, 15, 14, Props.OL)
	Props.R(n, x - 6, y - 12, 13, 12, Color("#cdb482"))
	Props.R(n, x - 6, y - 12, 4, 12, Color("#e0cb9a"))
	Props.R(n, x + 3, y - 12, 4, 12, Color("#a89060"))
	Props.R(n, x - 6, y - 14, 13, 3, Color("#8a6a2c"))
	Props.R(n, x - 4, y - 15, 9, 2, Color("#d4a94c"))
	Props.R(n, x - 3, y - 4, 7, 1, Color("#a89060"))

func _add_barn() -> void:
	# the pile: one solid block (so nobody can squeeze in between its parts) drawn from sacks, crates and barrels
	solid(PILE.position.x, PILE.position.y, PILE.size.x, PILE.size.y)
	for p in [["barrel", 282, 96], ["barrel", 366, 94], ["stack", 308, 94], ["stack", 340, 94], ["crate", 324, 78],
			["sacks", 296, 114], ["sacks", 326, 116], ["sacks", 356, 114]]:
		var x: float = p[1]
		var y: float = p[2]
		match p[0]:
			"barrel": prop(y, func(n): Props.barrel(n, x, y))
			"stack": prop(y, func(n): Props.crate_stack(n, x, y))
			"crate": prop(y, func(n): Props.crate(n, x, y))
			"sacks": prop(y, func(n): Props.sacks(n, x, y))
	for sp in OPEN_SACKS:
		var q: Vector2 = sp
		prop(q.y, func(n): _open_sack(n, q.x, q.y))
	# pen fences (left pens x 96..160, right pens mirrored). Each pen has a 32 px gap in its inner rail.
	for side in [0, 1]:
		var f := func(x: float, w: float) -> float:
			return x if side == 0 else float(W) - x - w
		_fence(f.call(96.0, 66.0), 94.0, 66.0, 5.0)              # top rail of the north pen
		_fence(f.call(96.0, 66.0), 190.0, 66.0, 5.0)             # divider between the pens
		_fence(f.call(158.0, 5.0), 96.0, 5.0, 32.0)              # inner rail, north pen (gap y 128..160)
		_fence(f.call(158.0, 5.0), 160.0, 5.0, 32.0)
		_fence(f.call(158.0, 5.0), 195.0, 5.0, 29.0)             # inner rail, south pen (gap y 224..256)
		_fence(f.call(158.0, 5.0), 256.0, 5.0, 32.0)

# the left spawn points are the SUMMON_LEFT list; the right ones are mirrored
func summon_points() -> Dictionary:
	var right := []
	for p in SUMMON_LEFT:
		right.append(Vector2(float(W) - p.x, p.y))
	return {"left": SUMMON_LEFT.duplicate(), "right": right}

func _add_torches() -> void:
	for t in TORCHES:
		var x: float = t[0]
		var y: float = t[1]
		solid(x - 3, y - 3, 6, 4)
		prop(y, func(n): Props.torch(n, x, y), true, 0.11)

# the wooden exit door at the south end of the passage (the dirt runs right up to it; a sill stops you walking past it)
func _exit_door() -> void:
	solid(266, 890, 108, 6)
	prop(893, func(n):
		var x := 272.0
		Props.R(n, x - 6, 874, 108, 22, Props.OL)
		Props.R(n, x - 4, 876, 104, 18, Props.WD_D)
		Props.R(n, x, 878, 44, 16, Props.WD)
		Props.R(n, x + 52, 878, 44, 16, Props.WD)
		for i in range(5):
			Props.R(n, x + 8 + i * 9, 878, 1, 16, Props.WD_D)
			Props.R(n, x + 60 + i * 9, 878, 1, 16, Props.WD_D)
		Props.R(n, x, 884, 96, 2, Color("#3e3e46"))
		Props.R(n, x + 44, 878, 8, 16, Props.OL)
		Props.R(n, x + 40, 886, 3, 3, Props.GOLD); Props.R(n, x + 53, 886, 3, 3, Props.GOLD))

# ---------------------------------------------------------------- light (helpers in level.gd)
func _add_lighting() -> void:
	var cm := CanvasModulate.new()
	cm.color = Color(0.30, 0.27, 0.36)     # the dark of the storeroom
	add_child(cm)
	for t in TORCHES:
		point_light(Vector2(t[0], t[1] - 30.0), 96.0, Color(1.0, 0.62, 0.26), 1.15, true)
	_lantern = point_light(Vector2.ZERO, 70.0, Color(1.0, 0.86, 0.62), 0.55)    # the hero's own small light

func _process(_dt: float) -> void:
	flicker_lights(0.12)
	if player != null and _lantern != null:
		_lantern.position = player.position + Vector2(0, -10)

# ---------------------------------------------------------------- enemies (see ENEMIES / WAKE at the top)
func enemy_plan(_c) -> Array:
	return ENEMIES.duplicate(true)
