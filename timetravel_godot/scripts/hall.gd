extends "res://scripts/level.gd"
# hall.gd - the great hall and throne room of King Rostam (one torch-lit map, 720 x 800). You come in from the courtyard gate at the south.
#   south  entrance gap x 312..408 (auto door back to the courtyard), a long red carpet runs north up the middle
#   west   the long dining table on a rug          east  the library alcove (bookcases, round table, desk, globe)
#   north  the throne room: a raised dais across the whole width (y 96..200), one throne, three windows; in the middle a flight of
#          6 steps (x 312..408, y 200..242) between two low side walls that end in newel posts (x 304..312 and 408..416, solid)
# The king stair scene (plays once): walk up to the foot of the steps -> control locks, the king calls "Come forward." in a floating line,
# the hero walks himself up the steps to the throne, then the normal parchment dialogue opens. Afterwards the king is an ordinary talkable NPC.
# The return scene (Stage 6c): when the cave's chief falls the hero is brought here (spawn "king_return", south of the steps). The king
# calls, the hero walks up to the throne (the same walk) and the return dialogue plays: with the freed rider (the squad's companion,
# who walks up beside him and then goes on following), or without him (the lesser return). It counts as the first meeting too: the stair
# scene never plays after it. All the spoken text is in dialogue.gd (SCENES, SHOUTS).
# People: the king and two royal guards on the dais, a servant walking round the long table (ambient), and Scholar Utana reading at the
# round table in the library (talkable). On his desk lies a clay tablet: E reads it, a record of the empire for the journal (Stage 7j).

const Props = preload("res://scripts/props.gd")
const CP = preload("res://scripts/castle_props.gd")
const Npc = preload("res://scripts/npc.gd")
const Terrain = preload("res://scripts/terrain.gd")

const THRONE := Vector2(360, 152)             # centre of the front edge of the throne (the king sits here)
const STAIRS := Rect2(312, 200, 96, 42)       # steps up to the dais (the walkable gap between the side walls)
const STEP := {"count": 6, "tread": 4, "riser": 3}   # 6 steps x (4 + 3) px = the 42 px of STAIRS
const SCENE_ZONE := Rect2(296, 246, 128, 46)  # walking into this (south of the steps) starts the king scene
const SCENE_STOP := Vector2(360, 174)         # where the hero ends up in front of the throne
const RETURN_SPAWN := Vector2(360, 332)       # back from the cave: about 90 px south of the steps
const RETURN_CALL_TIME := 1.2                 # the king calls out, then the walk starts
const RETURN_COINS := 100                     # the king's reward when the return scene ends (items.gd "coins"; enough to buy something, 7g)
const CARPET_X := 330.0
const CARPET_W := 60.0
const WINDOWS := [270, 360, 450]              # x of the three arched windows in the north wall

const TORCH_STANDS := [[266, 316], [454, 316], [266, 456], [454, 456], [266, 596], [454, 596], [300, 730], [420, 730], [292, 196], [428, 196]]
const COLUMNS := [[290, 316, 82], [430, 316, 82], [290, 456, 82], [430, 456, 82], [290, 596, 82], [430, 596, 82], [250, 196, 100], [470, 196, 100]]
const BOOKSHELVES := [[518, 300], [562, 300], [606, 300], [650, 300]]
const POTS := [[70, 136, 44], [650, 136, 44], [336, 230, 0], [70, 700, 40], [650, 700, 40]]
const WALL_BANNERS := [110, 180, 540, 610]   # royal banners on the north wall face
# the clay tablet on Utana's desk (Stage 7j): stand south of the desk and press E to read it (dialogue.gd LOGS "tablet_road"); it goes
# into the journal. It glints until it has been read, and stays on the desk (it belongs to the court).
const TABLET := Vector2(627, 366)
const TABLET_USE := {"id": "tablet", "rect": Rect2(622, 376, 36, 18), "prompt": Vector2(664, 380)}

# the people of the hall (words in dialogue.gd). The king is made talkable only after the stair scene (see _process).
const NPCS := [
	{"id": "king", "type": "talk", "sprite": "king", "look": "king", "pos": [360, 152], "face": "down"},
	{"id": "rguard1", "type": "ambient", "look": "royal", "pos": [320, 118], "face": "down", "idle": "sway", "acc": "spear", "solid": [8, 4]},
	{"id": "rguard2", "type": "ambient", "look": "royal", "pos": [400, 118], "face": "down", "idle": "sway", "acc": "spear", "solid": [8, 4]},
	# a servant carrying a jug on his head and a dish of food round the long table, stopping at the corners and halfway along each side as if serving
	# (the north leg runs at y 292, just above the head chair's solid at y 298..302)
	{"id": "servant", "type": "ambient", "look": "servant", "pos": [186, 292], "face": "down", "mode": "patrol", "speed": 18.0, "pause": 2.2,
		"acc": ["jar", "plate"], "solid": [8, 4], "route": [[186, 292], [186, 430], [186, 560], [80, 560], [80, 430], [80, 292]]},
	# the scholar, reading a scroll at the round table in the library (talkable)
	{"id": "utana", "type": "talk", "look": "scholar", "pos": [620, 462], "face": "left", "idle": "bob", "acc": "scroll", "solid": [8, 4]},
]

# the freed rider, back from the cave with the hero (the squad's own node, carried in through the door): the return scene puts him at
# RIDER_FROM and walks him up beside the hero to RIDER_STOP; afterwards he goes on following. (His home spot, for "Disband",
# is by the throne too: squad.gd MATES.)
const RIDER_FROM := Vector2(384, 340)
const RIDER_STOP := Vector2(388, 182)

var intro_done := false
var scene_state := 0       # 0 waiting, 1 king calls, 2 hero walks up, 3 dialogue open, 4 done; the return: 10 king calls, 11 walk, 12 dialogue
var scene_t := 0.0
var returning := false     # the return scene is running
var king
var hall_rider             # the squad's rider during the return scene (null without him)

var _floor_ground := {}
var _lights: Array = []    # brazier flame positions, collected while the props are placed (lit in _add_lighting)

func _init() -> void:
	key = "hall"
	place_name = "The Great Hall"
	W = 720
	H = 800
	spawns = {"gate": {"pos": Vector2(360, 716), "face": "up"}, "king_return": {"pos": RETURN_SPAWN, "face": "up"}}
	spawn = spawns["gate"]["pos"]
	doors = [{"rect": Rect2(318, 772, 84, 26), "auto": true, "to": "courtyard", "spawn": "gate"}]     # out through the entrance
	uses = [TABLET_USE]

func _ready() -> void:
	_paint()
	_make_nodes()
	_walls()
	_throne_room()
	_dining()
	_library()
	_make_door_prompts()
	_make_use_prompts()
	_make_debug()
	_add_lighting()

# ---------------------------------------------------------------- ground painting (done once)
func _paint() -> void:
	var tr = Terrain.new(W, H)
	var rng: RandomNumberGenerator = tr.rng
	tr.f(0, 0, W, H, "#33302b")
	# floor: warm stone slabs
	for gy in range(96 / 16, 744 / 16):
		for gx in range(48 / 16, 672 / 16):
			var tone: String = ["#b39b72", "#a8916a", "#bda87c", "#b09870"][(gx * 5 + gy * 3 + (gx * gy) % 4) % 4]
			tr.f(gx * 16, gy * 16, 16, 16, tone)
			tr.f(gx * 16, gy * 16, 16, 1, "#cdb98c")
			tr.f(gx * 16, gy * 16, 1, 16, "#c4b085")
			tr.f(gx * 16, gy * 16 + 15, 16, 1, "#7a6544")
			tr.f(gx * 16 + 15, gy * 16, 1, 16, "#85704d")
			if rng.randf() < 0.18:
				tr.f(gx * 16 + rng.randi_range(2, 10), gy * 16 + rng.randi_range(2, 12), 3, 1, "#8f7a56")
	# walls: north face with windows, side wall tops, south wall
	_paint_north(tr)
	for side in [0, 1]:
		var x0: int = 0 if side == 0 else 672
		tr.f(x0, 0, 48, H, "#6a655d")
		for yy in range(0, H, 16):
			tr.f(x0, yy, 48, 1, "#4a463f")
			var off := (yy / 16 % 2) * 12
			var xx := x0 + off
			while xx < x0 + 48:
				tr.f(xx, yy, 1, 16, "#4a463f")
				xx += 24
		tr.f(x0 + (0 if side == 0 else 44), 0, 4, H, "#33302b")
		tr.f(x0 + (44 if side == 0 else 0), 96, 4, 648, "#8f8a80")
	_paint_south(tr)
	# wall shadows on the floor
	for side in [0, 1]:
		tr.shade(48 if side == 0 else 662, 96, 10, 648, Color(0, 0, 0, 0.22))
	tr.shade(48, 744 - 10, 264, 10, Color(0, 0, 0, 0.18))
	tr.shade(408, 744 - 10, 264, 10, Color(0, 0, 0, 0.18))
	# the dais: a raised stage across the north end (lighter slabs, gold-trimmed front face), steps in the middle
	for gy in range(96 / 16, 200 / 16 + 1):
		for gx in range(48 / 16, 672 / 16):
			var tone2: String = ["#c9b68a", "#bfac80", "#d3c196"][(gx * 3 + gy * 5) % 3]
			var h := 16 if gy < 12 else 8
			tr.f(gx * 16, gy * 16, 16, h, tone2)
			tr.f(gx * 16, gy * 16, 16, 1, "#e0d0a8")
			tr.f(gx * 16, gy * 16, 1, h, "#d6c69c")
			tr.f(gx * 16, gy * 16 + h - 1, 16, 1, "#8a7650")
	tr.f(48, 200, 624, 12, "#6a655d")
	tr.f(48, 200, 624, 2, "#e0d0a8")
	tr.f(48, 202, 624, 1, "#c9a43a")
	tr.f(48, 209, 624, 3, "#33302b")
	for xx in range(48, 672, 20):
		tr.f(xx, 203, 1, 6, "#4a463f")
	tr.shade(48, 212, 624, 8, Color(0, 0, 0, 0.18))
	tr.steps(STAIRS.position.x - 3, STAIRS.position.y, STAIRS.size.x + 6, STEP["count"], STEP["tread"], STEP["riser"], ["#d6d0c2", "#a8a296", "#77716a", "#3a3631"])
	tr.shade(STAIRS.position.x - 3, STAIRS.end.y, STAIRS.size.x + 6, 3, Color(0, 0, 0, 0.18))
	# the red carpet: from the entrance up the middle, over the steps, to the throne
	_carpet(tr, 160, 800)
	_carpet_steps(tr)
	# rugs: dining (west), library round rug (east), throne rug on the dais
	_rug(tr, 62, 292, 152, 288)
	_rug(tr, 306, 108, 108, 60)
	_round_rug(tr, 586, 470, 64, 40)
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(tr.img)
	spr.centered = false
	add_child(spr)

func _paint_north(tr) -> void:
	# the grey wall behind the throne: brick courses, a gold cornice, three arched lattice windows
	tr.f(0, 0, W, 98, "#5f5a54")
	for row in range(10):
		var y := row * 10
		tr.f(0, y, W, 1, "#3a3631")
		var off := (row % 2) * 12
		var x := off
		while x < W:
			tr.f(x, y, 1, 10, "#3a3631")
			x += 24
	tr.f(0, 0, W, 6, "#8f8a80")
	tr.f(0, 6, W, 2, "#c9a43a")
	tr.f(0, 88, W, 10, "#4a463f")
	tr.f(0, 88, W, 2, "#8f8a80")
	tr.f(0, 96, W, 2, "#c9a43a")
	for wx in WINDOWS:
		# stone surround, then the glass with a diamond lattice
		tr.f(wx - 24, 14, 48, 72, "#33302b")
		tr.disc(wx, 24, 24, "#33302b")
		tr.f(wx - 21, 14, 42, 72, "#8f8a80")
		tr.disc(wx, 24, 21, "#8f8a80")
		tr.f(wx - 18, 16, 36, 70, "#2a3850")
		tr.disc(wx, 26, 18, "#2a3850")
		for i in range(0, 70):
			var y := 12 + i
			var half := 18 if y > 26 else int(sqrt(maxf(0.0, 18.0 * 18.0 - float((26 - y) * (26 - y)))))
			if half <= 0:
				continue
			var tone := "#4a78b0" if (i / 4) % 2 == 0 else "#5a88c0"
			tr.f(wx - half, y, half * 2, 1, tone)
		# lattice: crossing diagonal bars
		for yy in range(14, 86):
			var d := (yy - 14)
			for sgn in [-1, 1]:
				var px: int = wx + ((d % 18) - 9) * sgn
				for rep in range(-2, 3):
					var lx: int = px + rep * 18
					if absi(lx - wx) < 18:
						tr.f(lx, yy, 1, 1, "#2a3850")
		tr.f(wx - 1, 8, 2, 78, "#2a3850")
		tr.f(wx - 18, 56, 36, 2, "#2a3850")
		tr.f(wx - 21, 84, 42, 4, "#c9a43a")

func _paint_south(tr) -> void:
	# the south wall: lit top band, brick face; the entrance passage is open in the middle
	for part in [[0, 312], [408, 312]]:
		var x0: int = part[0]
		var w: int = part[1]
		tr.f(x0, 744, w, 56, "#5f5a54")
		tr.f(x0, 744, w, 10, "#8f8a80")
		tr.f(x0, 744, w, 2, "#b3ada0")
		tr.f(x0, 752, w, 2, "#4a463f")
		for row in range(5):
			var y := 756 + row * 9
			tr.f(x0, y, w, 1, "#3a3631")
			var xx := x0 + (row % 2) * 12
			while xx < x0 + w:
				tr.f(xx, y, 1, 9, "#3a3631")
				xx += 24
		for xx2 in range(x0 + 6, x0 + w - 8, 20):
			tr.f(xx2, 744, 10, 6, "#6a655d")
	# passage floor (stone slabs going down to the courtyard)
	tr.f(312, 744, 96, 56, "#8a8478")
	for k in range(4):
		tr.f(312, 746 + k * 12, 96, 1, "#4a463f")
		tr.f(312, 747 + k * 12, 96, 1, "#a8a296")
	tr.shade(312, 744, 4, 56, Color(0, 0, 0, 0.35))
	tr.shade(404, 744, 4, 56, Color(0, 0, 0, 0.35))

func _carpet(tr, y0: int, y1: int) -> void:
	var x0 := int(CARPET_X)
	var w := int(CARPET_W)
	tr.f(x0 - 1, y0, w + 2, y1 - y0, "#3a1010")
	tr.f(x0, y0, w, y1 - y0, "#7a1a1e")
	tr.f(x0 + 3, y0, w - 6, y1 - y0, "#a8262a")
	tr.f(x0 + 3, y0, 1, y1 - y0, "#d9a838")
	tr.f(x0 + w - 4, y0, 1, y1 - y0, "#d9a838")
	tr.f(x0 + 8, y0, 1, y1 - y0, "#c04040")
	tr.f(x0 + w - 9, y0, 1, y1 - y0, "#c04040")
	var y := y0 + 8
	while y < y1 - 8:
		# a winged-disc medallion every 56 px
		var cx := x0 + w / 2
		tr.f(cx - 2, y - 2, 5, 5, "#d9a838")
		tr.f(cx - 1, y - 3, 3, 7, "#d9a838")
		tr.f(cx - 12, y - 2, 9, 1, "#d9a838"); tr.f(cx + 4, y - 2, 9, 1, "#d9a838")
		tr.f(cx - 10, y, 7, 1, "#d9a838"); tr.f(cx + 4, y, 7, 1, "#d9a838")
		tr.f(cx - 8, y + 2, 5, 1, "#b8882a"); tr.f(cx + 4, y + 2, 5, 1, "#b8882a")
		tr.f(cx - 1, y + 4, 3, 3, "#b8882a")
		y += 56
	# fringe at the south end of the carpet is off-screen; a fringe at the throne end
	for fx in range(x0, x0 + w, 3):
		tr.f(fx, y0, 1, 3, "#d9a838")

# the carpet where it runs over the steps (painted over the flat run): on each tread the normal weave, a gold stair rod at its front
# edge, then the riser in shade, so the flight still reads as steps under the carpet
func _carpet_steps(tr) -> void:
	var x0 := int(CARPET_X)
	var w := int(CARPET_W)
	var tread: int = STEP["tread"]
	var riser: int = STEP["riser"]
	for k in range(STEP["count"]):
		var sy := int(STAIRS.position.y) + k * (tread + riser)
		tr.f(x0, sy, w, tread, "#7a1a1e"); tr.f(x0 + 3, sy, w - 6, tread, "#a8262a")
		tr.f(x0 + 3, sy, 1, tread, "#d9a838"); tr.f(x0 + w - 4, sy, 1, tread, "#d9a838")
		tr.f(x0 + 8, sy, 1, tread, "#c04040"); tr.f(x0 + w - 9, sy, 1, tread, "#c04040")
		tr.f(x0 - 1, sy + tread - 1, w + 2, 1, "#e8c050")                 # the stair rod
		tr.f(x0, sy + tread, w, riser, "#4e1014"); tr.f(x0 + 3, sy + tread, w - 6, riser, "#6a1619")
		tr.f(x0 + 3, sy + tread, 1, riser, "#8a6a24"); tr.f(x0 + w - 4, sy + tread, 1, riser, "#8a6a24")
		tr.f(x0 - 1, sy + tread + riser - 1, w + 2, 1, "#2a0a0a")

func _rug(tr, x: int, y: int, w: int, h: int) -> void:
	tr.f(x - 1, y - 1, w + 2, h + 2, "#3a1010")
	tr.f(x, y, w, h, "#7a1a1e")
	tr.f(x + 3, y + 3, w - 6, h - 6, "#a8262a")
	tr.f(x + 5, y + 5, w - 10, h - 10, "#d9a838")
	tr.f(x + 6, y + 6, w - 12, h - 12, "#8a1e24")
	var cx: int = x + w / 2
	var cy: int = y + h / 2
	var step := 22
	var yy: int = y + 14
	while yy < y + h - 12:
		tr.f(cx - 3, yy - 3, 7, 7, "#d9a838")
		tr.f(cx - 2, yy - 2, 5, 5, "#8a1e24")
		tr.f(cx, yy - 5, 1, 11, "#d9a838")
		tr.f(cx - 5, yy, 11, 1, "#d9a838")
		yy += step
	for xx in range(x + 7, x + w - 7, 6):
		tr.f(xx, y + 3, 3, 1, "#e8d9a0")
		tr.f(xx, y + h - 4, 3, 1, "#e8d9a0")

func _round_rug(tr, cx: int, cy: int, rx: int, ry: int) -> void:
	for r in [[rx + 1, ry + 1, "#3a1010"], [rx, ry, "#7a1a1e"], [rx - 4, ry - 3, "#a8262a"], [rx - 7, ry - 5, "#d9a838"], [rx - 8, ry - 6, "#8a1e24"], [rx - 22, ry - 15, "#a8262a"]]:
		for dy in range(-int(r[1]), int(r[1]) + 1):
			var dx := int(r[0] * sqrt(maxf(0.0, 1.0 - float(dy * dy) / (r[1] * r[1]))))
			tr.f(cx - dx, cy + dy, dx * 2 + 1, 1, r[2])

# ---------------------------------------------------------------- collision + props
func _walls() -> void:
	solid(0, 0, W, 100)                      # north wall
	solid(0, 0, 48, H)                       # west wall
	solid(672, 0, 48, H)                     # east wall
	solid(0, 744, 312, 56)                   # south wall, west of the entrance
	solid(408, 744, 312, 56)                 # south wall, east of the entrance
	solid(48, 200, 264, 12)                  # front face of the dais (the steps are the only way up)
	solid(408, 200, 264, 12)
	# low side walls along the steps, ending in newel posts (solid below the dais face, so the flight is the only way up)
	var foot: float = STAIRS.end.y + 2.0
	for cx in [STAIRS.position.x - 8.0, STAIRS.end.x]:
		var x: float = cx
		solid(x, 212, 8, foot - 212)
		prop(foot, func(n): CP.stair_cheek(n, x, STAIRS.position.y, foot, STEP["count"]))
	# banners on the north wall face
	for bx in WALL_BANNERS:
		var x: float = bx
		prop(98, func(n): CP.royal_banner(n, x, 34, 16, 46))

func _throne_room() -> void:
	solid(THRONE.x - 28, THRONE.y - 26, 56, 26)
	prop(THRONE.y - 2, func(n): CP.throne(n, THRONE.x, THRONE.y))
	for c in COLUMNS:
		var x: float = c[0]; var y: float = c[1]; var h: float = c[2]
		solid(x - 9, y - 6, 18, 7)
		prop(y, func(n): CP.column(n, x, y, h))
	for t in TORCH_STANDS:
		var x: float = t[0]; var y: float = t[1]
		solid(x - 5, y - 4, 10, 5)
		prop(y, func(n): CP.brazier(n, x, y), true, 0.11)
		_lights.append(Vector2(x, y - 24.0))
	for p in POTS:
		if p[2] == 0:
			continue
		var x: float = p[0]; var y: float = p[1]; var h: float = p[2]
		solid(x - 6, y - 4, 13, 5)
		prop(y, func(n): CP.potted_cypress(n, x, y, h))

func _dining() -> void:
	# long table with chairs on both sides, on the west rug
	var tx := 110.0
	var ty := 312.0
	var tw := 44.0
	var th := 230.0
	solid(tx, ty, tw, th)
	prop(ty + th + 6, func(n): CP.long_table(n, tx, ty, tw, th))
	var cy := ty + 24.0
	while cy < ty + th - 6.0:
		var y: float = cy
		solid(tx - 12, y - 3, 8, 4)
		prop(y, func(n): CP.chair(n, tx - 8, y, "right"))
		solid(tx + tw + 5, y - 3, 8, 4)
		prop(y, func(n): CP.chair(n, tx + tw + 9, y, "left"))
		cy += 34.0
	solid(tx + tw / 2.0 - 5, ty - 14, 10, 4)
	prop(ty - 4, func(n): CP.chair(n, tx + tw / 2.0, ty - 5, "down"))
	for cyy in [ty + 60.0, ty + 115.0, ty + 170.0]:
		var yy: float = cyy
		prop(ty + th + 7, func(n): CP.candelabra(n, tx + tw / 2.0, yy), true, 0.1)

func _library() -> void:
	# alcove: a wall on the north and a wall on the west (the way in is the opening in the south-west)
	solid(486, 262, 186, 40)
	prop(302, func(n): CP.inner_wall_h(n, 486, 262, 186, 40))
	solid(486, 262, 12, 288)
	prop(550, func(n): CP.inner_wall_v(n, 486, 262, 12, 288))
	for s in BOOKSHELVES:
		var x: float = s[0]; var y: float = s[1] + 14.0
		solid(x - 20, y - 6, 40, 7)
		prop(y, func(n): CP.bookshelf(n, x, y))
	solid(586 - 22, 450, 44, 16)
	prop(470, func(n): CP.round_table(n, 586, 458))
	solid(640 - 19, 360, 38, 14)
	prop(374, func(n): CP.desk(n, 640, 374))
	prop(374.5, func(n): CP.clay_tablet(n, TABLET.x, TABLET.y, not _tablet_read() and fmod(Props.now(), 2.2) < 0.2), true, 0.1)
	prop(396, func(n): CP.chair(n, 640, 396, "down"))
	solid(520 - 6, 380, 12, 6)
	prop(386, func(n): CP.globe(n, 520, 386))

# the tablet on the desk (Stage 7j): read once, it is in the journal (quest flag read_tablet)
func _tablet_read() -> bool:
	return dialogue != null and dialogue.quest.flags.get("read_tablet", false)

func usable(id: String) -> bool:
	return id == "tablet" and not _tablet_read()

# E at the desk: the tablet's record opens in the reader and goes into the journal
func use_spot(id: String) -> void:
	if not usable(id):
		return
	dialogue.quest.note("read_tablet")
	dialogue.quest.add_journal("tablet_road")
	dialogue.menu.read_log("tablet_road")

# ---------------------------------------------------------------- light (warm braziers, cool light from the windows; helpers in level.gd)
func _add_lighting() -> void:
	var cm := CanvasModulate.new()
	cm.color = Color(0.50, 0.47, 0.58)     # a torch-lit hall: dim, but you can see
	add_child(cm)
	for p in _lights:
		point_light(p, 120.0, Color(1.0, 0.64, 0.30), 0.95, true)
	for wx in WINDOWS:
		point_light(Vector2(wx, 118), 96.0, Color(0.62, 0.76, 1.0), 0.55)
	point_light(Vector2(360, 400), 200.0, Color(1.0, 0.8, 0.55), 0.25)     # general warmth over the carpet
	for p in [Vector2(586, 440), Vector2(132, 430)]:
		point_light(p, 110.0, Color(1.0, 0.7, 0.4), 0.5)       # the library lamp and the table's candles

# ---------------------------------------------------------------- people + the king scene
func start_npcs() -> void:
	for d in NPCS:
		var n = Npc.new()
		ysort.add_child(n)
		npcs.append(n)
		n.setup(d, self)
	king = npc_by_id("king")
	king.talk = false            # not talkable until he has spoken to you at the throne

func _process(delta: float) -> void:
	flicker_lights(0.1)
	if player == null or king == null:
		return
	# during the scene the camera looks up toward the king (so you see him call), and settles back as the hero climbs the steps
	var look := 0.0
	if scene_state in [1, 2, 10, 11] and player.position.y > 200.0:
		look = -92.0
	player.cam_extra.y = move_toward(player.cam_extra.y, look, 150.0 * delta)
	if returning:
		_return_scene(delta)
		return
	if intro_done:
		return
	match scene_state:
		0:
			if not talking and not player.dead and SCENE_ZONE.has_point(player.position):
				scene_state = 1
				scene_t = 0.0
				_lock_hero()
				king.shout(dialogue.SHOUTS["king_call"], 2.4)
		1:
			scene_t += delta
			if scene_t >= 1.7:
				scene_state = 2
		2:
			if _walk_hero_to(SCENE_STOP):
				player.scripted = false
				scene_state = 3
				_open_intro()

# the hero stops and faces the throne; actions and E are blocked while a scene runs
func _lock_hero() -> void:
	talking = true
	player.scripted = true
	player.script_v = Vector2.ZERO
	player.dir = "up"
	player.impulse = Vector2.ZERO

# one step of the hero's scripted walk to `target` (in line with it first, then straight up the steps). True once he is there.
func _walk_hero_to(target: Vector2) -> bool:
	var to: Vector2 = target - player.position
	var v := Vector2.ZERO
	if absf(to.x) > 1.5 and to.y > -8.0:
		v = Vector2(signf(to.x), 0.0) * 0.75
		player.dir = "right" if to.x > 0.0 else "left"
	elif to.y < -1.0:
		v = Vector2(clampf(to.x * 0.08, -0.4, 0.4), -0.8)
		player.dir = "up"
	else:
		player.script_v = Vector2.ZERO
		player.dir = "up"
		return true
	player.script_v = v
	return false

func _open_intro() -> void:
	king.shout_t = 0.0
	dialogue.start_scene(king, dialogue.SCENES["king_intro"], _intro_finished)

# ---------------------------------------------------------------- the return from the cave
func arrived(spawn_name: String) -> void:
	if spawn_name != "king_return" or king == null:
		return
	returning = true
	scene_state = 10
	scene_t = 0.0
	_lock_hero()
	king.talk = false
	hall_rider = null
	var r = dialogue.squad.node("farnaka")
	if dialogue.quest.flags.get("rider_joined", false) and r != null and r.world == self:
		hall_rider = r
		r.walk_to(RIDER_FROM, RIDER_STOP)
	king.shout(dialogue.SHOUTS["king_return"], 2.0)

func _return_scene(delta: float) -> void:
	match scene_state:
		10:
			scene_t += delta
			if scene_t >= RETURN_CALL_TIME:
				scene_state = 11
		11:
			var there := _walk_hero_to(SCENE_STOP)       # (he waits at the throne, still scripted, until the rider is up too)
			if there and (hall_rider == null or hall_rider.position.distance_to(RIDER_STOP) < 2.0):
				player.scripted = false
				scene_state = 12
				king.shout_t = 0.0
				var lines: Array = dialogue.SCENES["king_return_rider" if hall_rider != null else "king_return_alone"]
				dialogue.start_scene(king, lines, _return_finished)

func _return_finished() -> void:
	returning = false
	dialogue.quest.note("return_done")
	dialogue.inv.add("coins", RETURN_COINS)
	if hall_rider != null:
		hall_rider.follow_again()
		hall_rider = null
	_intro_finished()          # the return counts as the first meeting: the king is talkable, the stair scene never plays

# ---------------------------------------------------------------- saving (save.gd)
func busy() -> bool:
	return returning or scene_state in [1, 2, 3]

func save_state() -> Dictionary:
	var d := super.save_state()
	d["intro_done"] = intro_done
	return d

# after the king has spoken to the hero (either scene), he is talkable and neither scene plays again
func load_state(d: Dictionary) -> void:
	super.load_state(d)
	if d.get("intro_done", false):
		intro_done = true
		scene_state = 4
		king.talk = true

func _intro_finished() -> void:
	intro_done = true
	dialogue.quest.note("met_king")
	player.cam_extra = Vector2.ZERO
	scene_state = 4
	king.talk = true
	talking = false
	player.scripted = false
	player.lock = false
