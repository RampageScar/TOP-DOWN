extends "res://scripts/level.gd"
# courtyard.gd - the castle courtyard (a separate map). You arrive from the town over the bridge (west) and walk into the walled yard:
# a great warrior statue in a raised round planter in the middle, ringed by a paved road that both roads run into; a wall fountain in
# the north-west, a covered supply colonnade in the north-east, an armoury stall and supplies along the east wall, and the open gate
# (portcullis raised) in the north wall.
# The open gate leads into the great hall: walking into the tunnel (the auto door in `doors`) fades into hall.gd.
#
# Layout (all numbers are world pixels, map = 960 x 640):
#   bridge  x 0..230, deck y 290..326          gatehouse between two towers  x 222..270, y 282..336
#   walls   north y 56..108 (gate gap x 510..570, 7 steps y 66..115 climbing into the tunnel), south y 560..612, east x 896..920, west x 246..270
#   floor   x 270..896, y 108..560             statue front edge (540, 324); planter x 490..590, y 278..344; ring road x 462..618, y 258..358
#                                              (the ring is centred on y 308, the middle of the bridge road, so that road runs into its side)
#   fountain x 358..402, y 80..134             colonnade x 640..880, y 108..150     armoury x 806..866, y 286..300

const Props = preload("res://scripts/props.gd")
const CP = preload("res://scripts/castle_props.gd")
const Npc = preload("res://scripts/npc.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Atmosphere = preload("res://scripts/atmosphere.gd")

const FLOOR := Rect2(270, 108, 626, 452)
const STATUE := Vector2(540, 324)           # centre of the base's front edge (the statue PNG is drawn upward from here)
const DECK_Y := 290.0
const DECK_H := 36.0
const GATE := Rect2(510, 36, 60, 72)         # the opening in the north wall (tunnel behind it)
const TUNNEL_END := Rect2(510, 30, 60, 40)   # the dark end of the tunnel (solid, so nobody stands inside the wall if a door ever fails)
# the steps climbing into the tunnel (fade = how much darker the top step is than the bottom one)
const GATE_STEPS := {"top": 66, "count": 7, "tread": 4, "riser": 3, "fade": 0.55}

# [x, y, w, h] solid wall pieces drawn with Props.wall_h / wall_v
const WALLS_H := [[278, 56, 192, 52], [610, 56, 270, 52], [278, 560, 602, 52]]
const WALLS_V := [[246, 114, 24, 72], [246, 422, 24, 114], [896, 114, 24, 422]]
# towers [x, y, w, h]: four corners and the two that flank the bridge
const TOWERS := [[222, 30, 56, 84], [880, 30, 56, 84], [222, 536, 56, 84], [880, 536, 56, 84], [222, 186, 48, 96], [222, 326, 48, 96]]
const GATE_PILLARS := [[470, 24, 40, 84], [570, 24, 40, 84]]
# banners hung on the wall faces: [x, wall_y, wall_h]
const WALL_BANNERS := [[324, 56, 52], [404, 56, 52], [652, 56, 52], [742, 56, 52], [824, 56, 52], [352, 560, 52], [452, 560, 52], [640, 560, 52], [742, 560, 52]]
const TORCHES := [[488, 128], [592, 128], [292, 268], [292, 366], [380, 558], [700, 558]]

# the plaza round the statue: a raised round planter (stone kerb, grass, flowers) inside a paved ring road.
# PLANTER = [centre x, centre y, rx, ry, kerb face height]; RING = outer [rx, ry] of the ring road around the same centre.
const PLANTER := [540, 308, 50, 30, 6]
const RING := [78, 50]
# the two roads that run into the ring: down from the gate, and in from the bridge (they start under the tunnel / gatehouse paint)
const ROADS := [Rect2(510, 104, 60, 190), Rect2(266, 290, 244, 36)]
# plants inside the planter [kind, x, foot_y, (height for a cypress)]. The statue PNG already has two cypresses, so only flowering bushes.
const PLANTER_PLANTS := [["bush", 502, 326], ["bush", 520, 334], ["bush", 560, 334], ["bush", 578, 326]]

# cypress trees [x, foot_y, height]
const CYPRESS := [
	[330, 126, 36], [430, 126, 36],
	[320, 552, 34], [410, 552, 34], [520, 552, 34], [610, 552, 34], [700, 552, 34],
]
const BUSHES := [[300, 126], [360, 552], [470, 552], [565, 552], [660, 552], [755, 552]]
# the wall fountain in the north-west (centre of the basin's front edge), a stone bench near it
const FOUNTAIN := Vector2(380, 134)
const BENCH := Vector2(416, 160)
# the supply colonnade against the north wall, east of the gate: [x, front_y, w, depth, pillar height]
const COLONNADE := [640, 150, 240, 42, 36]
# the armoury stall on the east side: [x, front_y, w]
const ARMOURY := [806, 300, 60]
# supplies [kind, x, y]  kind: barrel | crate | stack | sacks | pots | cart
const SUPPLIES := [
	["stack", 860, 200], ["barrel", 880, 228], ["barrel", 866, 234], ["crate", 884, 262],
	["sacks", 872, 352], ["pots", 878, 384], ["crate", 884, 420], ["barrel", 768, 410], ["barrel", 782, 414],
	["stack", 860, 452], ["cart", 744, 492], ["sacks", 846, 492], ["pots", 452, 140],
]
# the two red standards on poles where the gate road meets the ring
const STANDARDS := [[498, 254], [582, 254]]

# the guards. Two walk laps; one stands at the bridge end. (chatter lines: dialogue.gd, ids cguard1..3)
const NPCS := [
	{"id": "cguard1", "type": "ambient", "look": "guard", "pos": [608, 308], "face": "down", "mode": "patrol", "speed": 22.0, "pause": 1.6, "solid": [8, 4],
		"route": [[608, 308], [590, 346], [540, 356], [490, 346], [472, 308], [492, 275], [540, 262], [588, 275]]},     # round the ring road
	{"id": "cguard2", "type": "ambient", "look": "guard", "pos": [330, 470], "face": "right", "mode": "patrol", "speed": 20.0, "pause": 2.2, "solid": [8, 4],
		"route": [[330, 470], [700, 470], [700, 522], [330, 522]]},
	{"id": "cguard3", "type": "ambient", "look": "guard", "pos": [298, 352], "face": "left", "idle": "sway", "solid": [8, 4]},
]

var _tr
var _lights: Array = []
var _water_marks: Array = []
var atmosphere

func _init() -> void:
	key = "courtyard"
	place_name = "The King's Courtyard"
	W = 960
	H = 640
	spawns = {
		"bridge": {"pos": Vector2(28, 310), "face": "right"},       # arriving from the town: the west end of the bridge
		"gate": {"pos": Vector2(540, 128), "face": "down"},         # coming out of the great hall: just below the open gate
	}
	spawn = spawns["bridge"]["pos"]
	doors = [
		{"rect": Rect2(0, 292, 14, 32), "auto": true, "to": "town", "spawn": "castle"},     # walking west off the bridge: back to the town
		{"rect": Rect2(512, 70, 56, 26), "auto": true, "to": "hall", "spawn": "gate"},      # the open gate: into the great hall
	]

func _ready() -> void:
	_paint()
	_make_nodes()
	_bridge_solids()
	_walls_and_towers()
	_gate()
	_statue()
	_plants()
	_fountain()
	_colonnade()
	_armoury()
	_camp()
	_torches()
	_make_door_prompts()
	_make_debug()
	_water_sparkle()
	atmosphere = Atmosphere.new()
	add_child(atmosphere)
	atmosphere.setup(self, _lights, [], 0.0, 0.0, float(W))

# ---------------------------------------------------------------- ground painting (done once)
func _ell(cx: float, cy: float, rx: float, ry: float, col) -> void:
	for dy in range(-int(ry), int(ry) + 1):
		var dx := int(rx * sqrt(maxf(0.0, 1.0 - float(dy * dy) / (ry * ry))))
		_tr.f(cx - dx, cy + dy, dx * 2 + 1, 1, col)

func _slabs(r: Rect2) -> void:
	var x0 := int(r.position.x)
	var y0 := int(r.position.y)
	for gy in range(int(r.size.y / 12.0)):
		for gx in range(int(r.size.x / 12.0)):
			var x := x0 + gx * 12
			var y := y0 + gy * 12
			var tone: String = ["#cdb98f", "#c2ad82", "#d4c298"][(gx * 7 + gy * 3 + (gx * gy)) % 3]
			_tr.f(x, y, 12, 12, tone)
			_tr.f(x, y, 12, 1, "#e6d6b0")
			_tr.f(x, y, 1, 12, "#dac9a2")
			_tr.f(x, y + 11, 12, 1, "#9a8760")
			_tr.f(x + 11, y, 1, 12, "#a89468")
			if (gx * 5 + gy * 11) % 9 == 0:
				_tr.f(x + 3, y + 5, 4, 1, "#9a8760")

func _grass(r: Rect2) -> void:
	_tr.f(r.position.x, r.position.y, r.size.x, r.size.y, "#5d8a3a")
	for i in range(int(r.size.x * r.size.y / 14.0)):
		var x: float = r.position.x + _tr.rng.randf() * (r.size.x - 3)
		var y: float = r.position.y + _tr.rng.randf() * (r.size.y - 2)
		var c: String = ["#4a7a30", "#7aa84a", "#8fbf5a", "#3f6a2a"][_tr.rng.randi() % 4]
		_tr.f(x, y, 2, 1, c)
	for i in range(int(r.size.x * r.size.y / 260.0)):
		var x: float = r.position.x + 2 + _tr.rng.randf() * (r.size.x - 5)
		var y: float = r.position.y + 2 + _tr.rng.randf() * (r.size.y - 5)
		_tr.f(x, y, 2, 2, ["#e8788a", "#f4ead0", "#e8c040", "#b070c8"][_tr.rng.randi() % 4])
	_tr.f(r.position.x, r.position.y, r.size.x, 1, "#3f6a2a")
	_tr.f(r.position.x, r.end.y - 1, r.size.x, 1, "#3f6a2a")

func _paint() -> void:
	_tr = Terrain.new(W, H)
	var rng: RandomNumberGenerator = _tr.rng
	# water everywhere, with streaks
	_tr.f(0, 0, W, H, "#4388af")
	for i in range(1100):
		var x := rng.randf() * W
		var y := rng.randf() * H
		var w := 6.0 + rng.randf() * 18.0
		_tr.f(x, y, w, 1, "#3d7fa6")
		_tr.f(x + 2, y - 1, w - 5, 1, "#5da3c6" if rng.randf() < 0.6 else "#78b9d0")
	for r in [[60, 120], [150, 480], [110, 570], [40, 230], [170, 40], [60, 410]]:
		_tr._boulder_in_water(r[0], r[1])
	# the island: dark rock under everything, then the keep wall along the north edge (above the north wall)
	_tr.f(214, 0, 730, H, "#7b6a52")
	_paint_keep()
	# courtyard floor, worn patches, pavements
	_tr.town_floor(FLOOR)
	for p in [[540, 310, 120, 0.55], [380, 230, 70, 0.4], [700, 240, 70, 0.4], [420, 470, 80, 0.4], [690, 450, 80, 0.4]]:
		_tr.patch(p[0], p[1], p[2], Color("#c9a050"), p[3])
	_grass(Rect2(270, 108, 200, 22))
	_grass(Rect2(610, 108, 30, 22))
	_grass(Rect2(270, 534, 626, 26))
	_pave_plaza()                           # both roads and the ring road, as one shape
	_slabs(Rect2(222, 282, 56, 54))         # between the two bridge towers
	_slabs(Rect2(344, 108, 72, 48))         # apron in front of the fountain
	_slabs(Rect2(636, 108, 252, 48))        # floor under the colonnade
	_paint_planter()
	_paint_gate_tunnel()
	# the bridge
	_tr.bridge_deck(0, 230, DECK_Y, DECK_H)
	# rocks around the island
	for c in [[206, 0, 30, 120], [206, 96, 40, 100], [206, 408, 40, 160], [200, 556, 760, 84], [920, 0, 40, 640]]:
		_tr.cliff(Rect2(c[0], c[1], c[2], c[3]))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(_tr.img)
	spr.centered = false
	add_child(spr)

func _paint_keep() -> void:
	# the front of the keep behind the north wall: brick courses with tall arched windows
	_tr.f(222, 0, 722, 60, "#a08058")
	for row in range(6):
		var y := row * 10
		_tr.f(222, y, 722, 1, "#7a5e3c")
		var off := (row % 2) * 10
		var x := 222 + off
		while x < 944:
			_tr.f(x, y, 1, 10, "#7a5e3c")
			x += 20
	_tr.f(222, 0, 722, 4, "#c0a070")
	for wx in [300, 372, 440, 640, 708, 780, 852]:
		_tr.f(wx - 6, 12, 12, 30, "#3a2a1c")
		_tr.disc(wx, 12, 6, "#3a2a1c")
		_tr.f(wx - 4, 14, 8, 26, "#1c1410")
		_tr.disc(wx, 13, 4, "#1c1410")
		_tr.f(wx - 1, 14, 2, 26, "#e8b838")      # a warm light inside
	_tr.f(222, 48, 722, 8, "#6a5030")

const FILLET := 6.0     # radius of the rounded joins where a road edge meets the ring

# the ring's outline: top edge at column x, and left edge at row y
func _ring_top(x: float) -> float:
	var u := (x - PLANTER[0]) / float(RING[0])
	return PLANTER[1] - RING[1] * sqrt(maxf(0.0, 1.0 - u * u))

func _ring_left(y: float) -> float:
	var v := (y - PLANTER[1]) / float(RING[1])
	return PLANTER[0] - RING[0] * sqrt(maxf(0.0, 1.0 - v * v))

func _in_plaza(x: int, y: int) -> bool:
	var dx := (x - PLANTER[0]) / float(RING[0])
	var dy := (y - PLANTER[1]) / float(RING[1])
	if dx * dx + dy * dy <= 1.0:
		return true
	for r in ROADS:
		if r.has_point(Vector2(x, y)):
			return true
	return _in_fillet(float(x), float(y))

# The corner between a straight road edge and the ring is filled with paving, except for a circle of radius FILLET tucked into it,
# so each join is a small rounded curve instead of a sharp notch. Corners: both sides of the gate road (top of the ring) and both
# sides of the bridge road (left of the ring).
func _in_fillet(x: float, y: float) -> bool:
	var r := FILLET
	var gate: Rect2 = ROADS[0]
	var bridge: Rect2 = ROADS[1]
	# gate road: edges at x = gate.x (corner to the west) and x = gate.end.x (corner to the east)
	for side in [[gate.position.x, -1.0], [gate.end.x, 1.0]]:
		var ex: float = side[0]; var s: float = side[1]
		var c := Vector2(ex + s * r, _ring_top(ex + s * r) - r)
		if (x - ex) * s >= 0.0 and (x - ex) * s <= r and y >= c.y and y < _ring_top(x) and Vector2(x, y).distance_to(c) > r:
			return true
	# bridge road: edges at y = bridge.y (corner above) and y = bridge.end.y (corner below)
	for side in [[bridge.position.y, -1.0], [bridge.end.y, 1.0]]:
		var ey: float = side[0]; var s: float = side[1]
		var c := Vector2(_ring_left(ey + s * r) - r, ey + s * r)
		if (y - ey) * s >= 0.0 and (y - ey) * s <= r and x >= c.x and x < _ring_left(y) and Vector2(x, y).distance_to(c) > r:
			return true
	return false

func _pave_plaza() -> void:
	# The roads and the ring road share one slab grid (origin chosen so the gate road's slabs line up with its edges), so they join
	# without seams. A mask is built first, then every pixel is painted from its slab cell; a darker line runs where the paving
	# meets sand. The planter is painted over the middle afterwards.
	var b := Rect2i(262, 100, 360, 290)
	var mask := PackedByteArray()
	mask.resize(b.size.x * b.size.y)
	for y in range(b.size.y):
		for x in range(b.size.x):
			mask[y * b.size.x + x] = 1 if _in_plaza(b.position.x + x, b.position.y + y) else 0
	var tones := [Color("#cdb98f"), Color("#c2ad82"), Color("#d4c298")]
	for y in range(b.size.y):
		for x in range(b.size.x):
			if mask[y * b.size.x + x] == 0:
				continue
			var wx := b.position.x + x
			var wy := b.position.y + y
			var edge := x == 0 or y == 0 or x == b.size.x - 1 or y == b.size.y - 1
			if not edge:
				edge = mask[y * b.size.x + x - 1] == 0 or mask[y * b.size.x + x + 1] == 0 or mask[(y - 1) * b.size.x + x] == 0 or mask[(y + 1) * b.size.x + x] == 0
			if edge:
				_tr.px(wx, wy, "#8a7650")
				continue
			# same look as _slabs(): 12 px slabs, light top/left joints, dark bottom/right joints, an odd crack
			var gx := (wx - 6) / 12
			var gy := (wy - 2) / 12
			var lx := (wx - 6) % 12
			var ly := (wy - 2) % 12
			var c: Color = tones[(gx * 7 + gy * 3 + (gx * gy)) % 3]
			if ly == 0:
				c = Color("#e6d6b0")
			elif lx == 0:
				c = Color("#dac9a2")
			elif ly == 11:
				c = Color("#9a8760")
			elif lx == 11:
				c = Color("#a89468")
			elif ly == 5 and lx >= 3 and lx < 7 and (gx * 5 + gy * 11) % 9 == 0:
				c = Color("#9a8760")
			_tr.px(wx, wy, c)

func _paint_planter() -> void:
	# a raised round bed: a soft shadow on the road, the kerb's front face (statue grey, with joints), the lit kerb top,
	# then grass with flower specks inside.
	var cx: float = PLANTER[0]; var cy: float = PLANTER[1]; var rx: float = PLANTER[2]; var ry: float = PLANTER[3]; var fh: float = PLANTER[4]
	for dy in range(-int(ry), int(ry) + 1):
		var dx := int((rx + 3) * sqrt(maxf(0.0, 1.0 - float(dy * dy) / (ry * ry))))
		_tr.shade(cx + 5 - dx, cy + fh + 3 + dy, dx * 2 + 1, 1, Color(0.24, 0.13, 0.04, 0.22))
	_ell(cx, cy + fh, rx + 1, ry + 1, CP.OL)
	_ell(cx, cy + fh, rx, ry, CP.SG_D)
	var jx := -int(rx) + 6
	while jx < int(rx):
		var yb := cy + ry * sqrt(maxf(0.0, 1.0 - float(jx * jx) / (rx * rx)))
		_tr.f(cx + jx, yb + 1, 1, fh - 1, CP.SG_DD)
		jx += 10
	_ell(cx, cy, rx + 1, ry + 1, CP.OL)
	_ell(cx, cy, rx, ry, CP.SG_L)
	_ell(cx, cy, rx - 3, ry - 2, CP.SG)
	_ell(cx, cy, rx - 4, ry - 3, "#3f6a2a")
	_ell(cx, cy, rx - 5, ry - 4, "#5d8a3a")
	for i in range(180):
		var a: float = _tr.rng.randf() * TAU
		var r: float = sqrt(_tr.rng.randf())
		_tr.f(cx + cos(a) * r * (rx - 8), cy + sin(a) * r * (ry - 7), 2, 1, ["#4a7a30", "#7aa84a", "#8fbf5a"][_tr.rng.randi() % 3])
	for i in range(30):
		var a: float = _tr.rng.randf() * TAU
		var r: float = sqrt(_tr.rng.randf())
		_tr.f(cx + cos(a) * r * (rx - 9), cy + sin(a) * r * (ry - 8), 2, 2, ["#e8788a", "#f4ead0", "#e8c040", "#b070c8"][_tr.rng.randi() % 4])

func _paint_gate_tunnel() -> void:
	# the passage under the keep: dark, with stairs climbing into it and a warm hint of light at the far end
	_tr.f(GATE.position.x, GATE.position.y, GATE.size.x, GATE.size.y, "#14100c")
	_tr.f(GATE.position.x + 10, GATE.position.y + 4, GATE.size.x - 20, 22, "#2c1c10")
	_tr.f(GATE.position.x + 18, GATE.position.y + 8, GATE.size.x - 36, 12, "#4a3018")
	# the steps start just under the raised portcullis bars and get darker toward the top, so they climb into the shadow.
	# The bottom step stands out of the wall face onto the road like a front step; the gate pillars are the side walls.
	var s: Dictionary = GATE_STEPS
	var foot: float = s["top"] + s["count"] * (s["tread"] + s["riser"])
	_tr.steps(GATE.position.x, s["top"], GATE.size.x, s["count"], s["tread"], s["riser"], ["#c9bb9c", "#8a7e6a", "#62584a", "#2e2a23"], s["fade"])
	_tr.shade(GATE.position.x - 2, foot, GATE.size.x + 4, 3, Color(0, 0, 0, 0.22))
	_tr.shade(GATE.position.x, 36, 3, 72, Color(0, 0, 0, 0.4))
	_tr.shade(GATE.end.x - 3, 36, 3, 72, Color(0, 0, 0, 0.4))

# ---------------------------------------------------------------- collision + props
func _bridge_solids() -> void:
	solid(0, DECK_Y - 4, 222, 10)                  # north rail
	solid(0, DECK_Y + DECK_H - 4, 222, 12)         # south rail
	prop(DECK_Y + 6, func(n): Props.bridge_rail(n, 0, 222, DECK_Y + 4, true))
	prop(DECK_Y + DECK_H + 6, func(n): Props.bridge_rail(n, 0, 222, DECK_Y + DECK_H + 2, false))
	# between the two towers the walkway is stone: nothing to add (the towers are solid)

func _wall_h(x: float, y: float, w: float, h: float, v := 0) -> void:
	solid(x, y, w, h)
	prop(y + h, func(n): Props.wall_h(n, x, y, w, h, v))

func _wall_v(x: float, y: float, w: float, h: float) -> void:
	solid(x, y, w, h)
	prop(y + h, func(n): Props.wall_v(n, x, y, w, h))

func _walls_and_towers() -> void:
	var v := 0
	for w in WALLS_H:
		_wall_h(w[0], w[1], w[2], w[3], v)
		v += 1
	for w in WALLS_V:
		_wall_v(w[0], w[1], w[2], w[3])
	for t in TOWERS:
		var x: float = t[0]; var y: float = t[1]; var w: float = t[2]; var h: float = t[3]
		solid(x, y + 10, w, h - 10)
		prop(y + h, func(n):
			Props.tower(n, x, y, w, h, false)
			CP.royal_banner(n, x + w / 2.0 - 8, y + 34, 16, h - 52))
	for b in WALL_BANNERS:
		var bx: float = b[0]; var by: float = b[1] + 12.0; var wh: float = b[2]
		prop(b[1] + wh + 1.0, func(n): CP.royal_banner(n, bx, by, 14, wh - 30))

func _gate() -> void:
	for p in GATE_PILLARS:
		var x: float = p[0]; var y: float = p[1]; var w: float = p[2]; var h: float = p[3]
		solid(x, y + 10, w, h - 10)
		prop(y + h, func(n):
			Props.tower(n, x, y, w, h, false)
			CP.royal_banner(n, x + w / 2.0 - 8, y + 26, 16, 36))
	# the raised portcullis hangs in the arch; the hero walks under it (sorted behind the hero once he is inside)
	prop(66, func(n): CP.portcullis(n, GATE.position.x, GATE.end.x, 40.0))
	solid(TUNNEL_END.position.x, TUNNEL_END.position.y, TUNNEL_END.size.x, TUNNEL_END.size.y)

func _statue() -> void:
	# the raised planter (which holds the statue's own base) is solid: horizontal bands that cover the kerb top and its front face.
	# Each band is as wide as the planter at the band's row nearest the middle, so no visible kerb is left walkable.
	var cx: float = PLANTER[0]; var cy: float = PLANTER[1]; var rx: float = PLANTER[2]; var ry: float = PLANTER[3]; var fh: float = PLANTER[4]
	var y0 := cy - ry
	while y0 < cy + ry + fh:
		var y1 := minf(y0 + 6.0, cy + ry + fh)
		var d := 0.0                                   # distance from the band to the rows y cy..cy+fh (where the planter is widest)
		if y1 <= cy:
			d = cy - y1
		elif y0 >= cy + fh:
			d = y0 - (cy + fh)
		var hw := rx * sqrt(maxf(0.0, 1.0 - (d * d) / (ry * ry)))
		solid(cx - hw, y0, hw * 2.0, y1 - y0)
		y0 = y1
	prop(STATUE.y, func(n): CP.statue(n, STATUE.x, STATUE.y))
	for p in PLANTER_PLANTS:
		var x: float = p[1]; var y: float = p[2]
		if p[0] == "cypress":
			var h: float = p[3]
			prop(y, func(n): CP.cypress(n, x, y, h))
		else:
			prop(y, func(n): CP.bush(n, x, y, 0.8, true))
	for s in STANDARDS:
		var x: float = s[0]; var y: float = s[1]
		solid(x - 2, y - 3, 4, 4)
		prop(y, func(n):
			Props.shadow(n, x + 2, y + 1, 5, 2)
			Props.R(n, x - 1, y - 46, 3, 47, Props.OL); Props.R(n, x, y - 45, 1, 45, Props.WD_L); Props.R(n, x + 1, y - 45, 1, 45, Props.WD_D)
			Props.R(n, x - 2, y - 49, 5, 4, Props.GOLD)
			CP.royal_banner(n, x - 7, y - 44, 14, 24))

func _plants() -> void:
	for c in CYPRESS:
		var x: float = c[0]; var y: float = c[1]; var h: float = c[2]
		solid(x - 3, y - 3, 6, 4)
		prop(y, func(n): CP.cypress(n, x, y, h))
	for b in BUSHES:
		var x: float = b[0]; var y: float = b[1]
		solid(x - 6, y - 4, 12, 5)
		prop(y, func(n): CP.bush(n, x, y))
	# a few trees on the far bank (decor only: the bridge rails keep you on the deck)
	for t in [[16, 70, 1.0, 0], [34, 156, 0.8, 1], [20, 540, 1.0, 1], [38, 604, 0.9, 0], [96, 20, 0.9, 1]]:
		var x: float = t[0]; var y: float = t[1]; var s: float = t[2]; var k: int = t[3]
		prop(y, func(n): Props.tree(n, x, y, s, k, true), true, 0.12)

func _fountain() -> void:
	solid(FOUNTAIN.x - 22, FOUNTAIN.y - 21, 44, 21)
	prop(FOUNTAIN.y, func(n): CP.wall_fountain(n, FOUNTAIN.x, FOUNTAIN.y), true, 0.08)
	solid(BENCH.x - 14, BENCH.y - 8, 28, 8)
	prop(BENCH.y, func(n): CP.bench(n, BENCH.x, BENCH.y))

func _colonnade() -> void:
	var x: float = COLONNADE[0]; var y: float = COLONNADE[1]; var w: float = COLONNADE[2]; var d: float = COLONNADE[3]; var h: float = COLONNADE[4]
	solid(x, y - d, w, d)
	prop(y, func(n): CP.colonnade(n, x, y, w, d, h))
	_lights.append([x + w / 2.0, y - h + 10.0, 36.0, 0])     # the lantern

func _armoury() -> void:
	var x: float = ARMOURY[0]; var y: float = ARMOURY[1]; var w: float = ARMOURY[2]
	solid(x + 2, y - 14, w - 4, 14)
	prop(y, func(n): CP.armoury(n, x, y, w))

func _camp() -> void:
	for s in SUPPLIES:
		var x: float = s[1]; var y: float = s[2]
		match s[0]:
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
			"pots":
				solid(x - 9, y - 6, 20, 7)
				prop(y, func(n): Props.pots(n, x, y))
			"cart":
				solid(x - 18, y - 8, 36, 9)
				prop(y, func(n): Props.cart(n, x, y))

func _torches() -> void:
	for t in TORCHES:
		var x: float = t[0]
		var y: float = t[1]
		solid(x - 3, y - 3, 6, 4)
		prop(y, func(n): Props.torch(n, x, y), true, 0.11)
		_lights.append([x, y - 30.0, 50.0, 0])

func _water_sparkle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in range(120):
		var x := rng.randf_range(2.0, 205.0)
		var y := rng.randf_range(2.0, float(H) - 2.0)
		if y > DECK_Y - 8.0 and y < DECK_Y + DECK_H + 14.0:
			continue
		_water_marks.append([x, y, rng.randi_range(5, 14), rng.randf_range(0.6, 1.6), rng.randf() * TAU])
	var node := Drawn.new()
	node.animated = true
	node.interval = 0.09
	node.draw_fn = func(n):
		var t := Time.get_ticks_msec() / 1000.0
		for m in _water_marks:
			var a: float = 0.25 + 0.35 * (0.5 + 0.5 * sin(t * m[3] * 1.7 + m[4]))
			var x: float = roundf(m[0] + sin(t * m[3] + m[4]) * 4.0)
			n.draw_rect(Rect2(x, roundf(m[1]), m[2], 1), Color(0.92, 0.98, 1.0, a))
			n.draw_rect(Rect2(x + 2, roundf(m[1]) + 1, m[2] * 0.5, 1), Color(0.75, 0.9, 1.0, a * 0.6))
	add_child(node)
	move_child(node, 1)       # just above the ground image

# ---------------------------------------------------------------- people
func start_npcs() -> void:
	for d in NPCS:
		var n = Npc.new()
		ysort.add_child(n)
		npcs.append(n)
		n.setup(d, self)
