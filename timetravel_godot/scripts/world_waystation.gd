extends "res://scripts/level.gd"
# world_waystation.gd - the map: one scrolling portrait exterior (1200 x 1340).
#   south: you start on the dirt road -> bandits on the road -> the walled Waystation Town (gate in the south wall)
#   north-west: Ancient Ruins     north-east: Cave Hideout (cliff, torches, winding road; walk into the mouth -> the cave map)
#   east: river with a wooden bridge (walk off its east end -> the castle courtyard)
# After the return to the king, the stranger's trail lies in the ruins: boot prints, a dropped brass box, a torn page (Stage 7b), and a
# second page by the scorpions' den in the west of the ruins (Stage 7j; the den and its three scorpions are there from the start).
# Place names (Waystation Road / Town / The Ancient Ruins) are PLACES below.
# The ground is painted once (terrain.gd); everything that stands up is a y-sorted prop (props.gd).
# The storeroom (storeroom.gd), the cave (cave.gd) and the courtyard (courtyard.gd) are their own maps; the doors are in `doors` below.

const Props = preload("res://scripts/props.gd")
const Npc = preload("res://scripts/npc.gd")
const NpcData = preload("res://scripts/npc_data.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Atmosphere = preload("res://scripts/atmosphere.gd")

var bridge_exit := Rect2(1176, 604, 24, 32)     # the far end of the bridge: walking into it leads to the castle courtyard
var cave_mouth := Rect2(1006, 130, 48, 10)      # the foot of the cave mouth in the north-east cliff: walking into it leads into the cave
var nests: Array[Vector2] = []                  # rat nests (east side)
var bandit_spots: Array = []                    # [home, patrol axis, half length]
var _road_cells := {} # 8px cells that are on or next to a road
var _lights: Array = []
var _tr
var atmosphere

# ---------------------------------------------------------------- layout data
const ROADS := [
	# [width, points...]
	{"w": 40.0, "pts": [[598, 1345], [600, 1240], [606, 1130], [596, 1030], [562, 935], [506, 868], [458, 800], [434, 728], [432, 640], [432, 600]]},
	{"w": 32.0, "pts": [[506, 866], [584, 806], [690, 764], [800, 748], [900, 722], [985, 676], [1030, 612], [1040, 548], [1010, 492], [950, 456], [900, 434]]},
	{"w": 28.0, "pts": [[900, 434], [958, 396], [1012, 342], [1034, 272], [1030, 206], [1030, 150]]},
	{"w": 24.0, "pts": [[900, 434], [850, 440], [800, 444]]},
	{"w": 26.0, "pts": [[1030, 612], [1050, 618], [1075, 618]]},
]
const SHORE := [Vector2(1078, 455), Vector2(1062, 500), Vector2(1070, 560), Vector2(1068, 640), Vector2(1092, 700), Vector2(1145, 745), Vector2(1200, 766)]
const WATER_Y0 := 455.0
const WATER_Y1 := 766.0

# rock cliffs painted into the ground (also solid). Rect2(x, y, w, h)
const CLIFFS := [
	[610, 0, 590, 58], [760, 0, 440, 132], [1086, 0, 114, 262], [275, 0, 95, 22], [575, 0, 100, 16],
	[0, 358, 30, 60], [1080, 330, 120, 126], [845, 526, 90, 76], [0, 656, 50, 96], [625, 768, 82, 46],
	[930, 748, 76, 48], [1060, 746, 140, 58],    # the gap between these two (x 1006..1060) is wide enough for a rat to find [0, 786, 60, 108], [1090, 884, 110, 70], [1040, 944, 160, 400],
	[960, 1062, 240, 278], [880, 1214, 100, 60], [800, 1272, 170, 68],
	[0, 992, 170, 348], [0, 1130, 400, 210], [120, 1092, 130, 60],
]

# [x, base_y, height, kind(0 full, 1 broken, 2 stump)]
const PILLARS := [
	[132, 152, 94, 0], [192, 170, 72, 1], [358, 152, 74, 0], [500, 102, 66, 0], [521, 114, 30, 2], [282, 124, 30, 2],
	[66, 268, 74, 0], [338, 268, 66, 0], [627, 210, 104, 0], [780, 268, 100, 0], [303, 254, 24, 2], [505, 202, 26, 2],
	[160, 152, 24, 2], [325, 154, 22, 2], [440, 220, 40, 1],
	# south-east ruins
	[990, 934, 120, 0], [1050, 940, 86, 0], [792, 990, 92, 0], [822, 994, 28, 2], [922, 982, 26, 2], [880, 905, 44, 1],
	# bottom-left ruin
	[123, 886, 76, 0], [186, 862, 32, 1], [60, 860, 26, 2],
]
# [x, y, w, h, seed]
const RUIN_WALLS := [
	[92, 154, 60, 18, 1], [232, 150, 40, 16, 2], [545, 190, 62, 26, 3], [256, 240, 48, 20, 4], [560, 150, 50, 16, 5],
	[400, 100, 44, 16, 6], [220, 300, 38, 16, 7],
	[940, 860, 60, 20, 8], [896, 996, 62, 22, 9], [1010, 1000, 40, 16, 10],
	[204, 884, 64, 22, 11], [60, 904, 46, 18, 12],
	[408, 944, 62, 22, 13], [218, 1034, 60, 24, 14],
]
const DRUMS := [[230, 206, 0], [432, 160, 1], [585, 282, 0], [1022, 990, 1], [850, 940, 0], [470, 1010, 0], [286, 985, 1]]
const RUBBLE := [[78, 188, 1], [210, 190, 0], [300, 160, 1], [545, 244, 0], [605, 120, 1], [388, 236, 0], [180, 275, 0], [700, 100, 0],
	[960, 880, 1], [1040, 1004, 0], [830, 1010, 1], [150, 905, 0], [440, 970, 1], [250, 1070, 0]]

# [x, base_y, scale, kind]
const TREES := [
	[50, 64, 1.0, 0], [415, 44, 0.95, 0], [600, 90, 0.9, 1], [42, 154, 0.85, 0], [862, 306, 0.95, 0], [832, 304, 0.8, 1],
	[322, 804, 1.25, 0], [750, 866, 1.0, 0], [150, 1190, 1.15, 0], [848, 1128, 1.1, 0], [60, 750, 0.9, 1], [385, 1100, 0.95, 1],
	[705, 1186, 1.0, 1], [820, 640, 0.9, 0], [970, 1006, 0.85, 1], [698, 606, 0.8, 0], [110, 1000, 0.9, 1], [690, 1010, 0.9, 0],
	[170, 790, 0.85, 1], [900, 1290, 0.9, 0], [330, 1240, 0.9, 1],
]
# [x, base_y, height, lean]
const PALMS := [
	[40, 314, 56, 0.6], [30, 458, 58, 0.5], [40, 544, 52, 0.6], [705, 198, 60, 0.4], [1018, 438, 60, -0.5], [1142, 508, 62, -0.4],
	[1124, 316, 56, -0.4], [864, 366, 64, 0.2], [806, 586, 56, 0.4], [890, 848, 56, 0.3], [700, 938, 60, 0.5], [990, 1178, 56, -0.4],
	[410, 182, 56, -0.4], [905, 300, 52, 0.3], [810, 1190, 54, -0.3], [630, 1090, 52, 0.4],
]
const CACTI := [[232, 748, 0], [733, 734, 1], [1060, 346, 2], [830, 820, 3], [782, 1054, 4], [231, 1114, 5], [640, 1230, 6], [440, 1180, 7], [90, 570, 8], [980, 760, 9]]
const DEAD_TREES := [[395, 886, 0], [135, 1014, 1], [700, 1100, 0], [990, 560, 1]]
const TORCHES := [[97, 74], [720, 232], [984, 154], [1076, 150], [985, 288], [958, 456], [988, 602], [606, 824], [336, 726], [528, 726]]
# Training yard: everything in the yard is placed from its original spot plus this shift (east, north).
const YARD_SHIFT := Vector2(-10, -12)       # (its south-west corner tucks behind the gate pillar, which is fine: both are solid)
# Road signs: position of the post's foot, and the lines shown when you press E. [direction, destination, arrow]
const SIGNS := [
	{"pos": [557, 850], "lines": [["NORTH", "TOWN", "up"], ["EAST", "CASTLE", "right"]]},
	{"pos": [874, 404], "lines": [["NORTH", "CAVE", "up"], ["EAST", "CASTLE", "right"]]},
]
const NEST_SPOTS := [[930, 255], [965, 358], [985, 524], [882, 632], [1052, 692]]

# rest spots (level.gd rests: E rests and autosaves, only while no enemy is after you): the well in the plaza, the town's only one
const RESTS := [
	{"rect": Rect2(405, 466, 40, 18), "prompt": Vector2(446, 462), "name": "the well"},
]
# things to take (level.gd pickups, Stage 7g): [id, item, n, foot]. Only out in the wild: nothing at the stalls (people's goods).
const PICKUPS := [
	["ruins_potion", "small_potion", 1, Vector2(210, 188)],      # among the broken pillars of the ruins
	["ruins_coins", "coins", 15, Vector2(486, 120)],             # by the north pillar
]
# place names (hud.gd shows them top-right): the map's own name, and its named parts [name, Rect2, quest note]
const PLACE_NAME := "Waystation Road"
const PLACES := [
	["Waystation Town", Rect2(68, 300, 726, 380), ""],
	["The Ancient Ruins", Rect2(0, 40, 800, 245), ""],
]

# The stranger's trail (Stage 7b). It is there once the king has heard about the stranger (quest flag return_done):
#   PRINTS     boot prints from the road by the east gate, up past the town's east wall and west into the ruins (a walkable path);
#              walking along them (PRINTS_SEEN) puts them in the journal
#   CLUE_BOX   the brass box he dropped where they stop        CLUE_PAGE   a torn page from his notebook, under a stone nearby
# E takes the box and the page (use spots). With both, the ruins are searched (quest.gd "ruins_searched").
const PRINTS := [[838, 430], [858, 414], [858, 394], [874, 374], [870, 354], [850, 342], [830, 322], [814, 302], [814, 282], [802, 262],
	[782, 256], [762, 252], [742, 255], [722, 251], [702, 254], [682, 250], [662, 253], [642, 249], [622, 252]]
const PRINTS_SEEN := Rect2(600, 236, 230, 36)
const CLUE_BOX := Vector2(604, 254)
const CLUE_PAGE := Vector2(540, 246)
const BOX_USE := {"id": "ruins_box", "rect": Rect2(590, 244, 28, 22), "prompt": Vector2(616, 242)}
const PAGE_USE := {"id": "ruins_page", "rect": Rect2(526, 236, 28, 22), "prompt": Vector2(552, 234)}
# The scorpions' den (Stage 7j, a type A wildlife den): a burrow under a toppled slab in the west of the ruins (DEN = the slab's front
# foot; low, so it is no cover), its three scorpions (enemy_plan, after the bandits so an older save's rows keep their meaning) and,
# once the trail is there, a second torn page lying beside it (CLUE_PAGE_2). The page is optional: the search is done without it.
const DEN := Vector2(128, 226)
const DEN_SCORPIONS := [[114, 240], [144, 238], [128, 208]]
const CLUE_PAGE_2 := Vector2(92, 238)
const PAGE2_USE := {"id": "ruins_page_2", "rect": Rect2(78, 228, 28, 22), "prompt": Vector2(104, 226)}

func _init() -> void:
	key = "town"
	place_name = PLACE_NAME
	places = PLACES
	uses = [BOX_USE, PAGE_USE, PAGE2_USE]
	rests = RESTS
	pickup_plan = PICKUPS
	W = 1200
	H = 1340
	spawn = Vector2(598, 1226)                    # bottom centre, on the road
	spawns = {
		"storeroom_door": {"pos": Vector2(443, 392), "face": "down"},     # just outside the storeroom door
		"castle": {"pos": Vector2(1156, 620), "face": "left"},            # coming back over the bridge from the castle
		"cave": {"pos": Vector2(1030, 166), "face": "down"},              # coming out of the cave (below the door rect, so no ping-pong)
	}
	# the storeroom door (south face of the building at 385,300): stand in front of it and press E
	doors = [
		{"rect": Rect2(424, 377, 40, 26), "prompt": Vector2(443, 380), "to": "storeroom", "spawn": "entry"},
		{"rect": bridge_exit, "auto": true, "to": "courtyard", "spawn": "bridge"},   # the east end of the bridge
		{"rect": cave_mouth, "auto": true, "to": "cave", "spawn": "entry"},          # the cave mouth at the end of the north-east road
	]

func _ready() -> void:
	_tr = Terrain.new(W, H)
	_tr.sand()
	_tr.scatter_details([])
	_paint_roads()
	_tr.town_floor(Rect2(112, 330, 640, 296))
	_paint_town_details()
	_tr.river(SHORE, WATER_Y0, WATER_Y1)
	_tr.bridge_deck(1046, W, 600, 36)
	for c in CLIFFS:
		_tr.cliff(Rect2(c[0], c[1], c[2], c[3]))
	_tr.cave(Vector2(1030, 134), 66, 72)
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(_tr.img)
	spr.centered = false
	add_child(spr)

	_make_nodes()
	_cliff_solids()
	_water_solids()
	_town()
	_ruins()
	_ruins_clue()
	_landmarks()
	_plants()
	_scatter()
	_scorpion_den()                # after the scatter, so the random rocks and agaves stay where they were before the den
	_nests_and_bandits()
	_torches()
	_make_pickups()
	_make_door_prompts()
	_make_use_prompts()
	_make_rest_prompts()
	_make_debug()

	atmosphere = Atmosphere.new()
	add_child(atmosphere)
	atmosphere.setup(self, _lights, SHORE, WATER_Y0, WATER_Y1, float(W))

func _on_road(p: Vector2) -> bool:
	return _road_cells.has(int(p.x / 8.0) * 4096 + int(p.y / 8.0))

func _in_water(p: Vector2) -> bool:
	return p.y > WATER_Y0 - 14.0 and p.y < WATER_Y1 + 14.0 and p.x > Terrain.shore_x(SHORE, int(clampf(p.y, WATER_Y0, WATER_Y1))) - 16.0

# ---------------------------------------------------------------- ground painting
func _paint_roads() -> void:
	for r in ROADS:
		var pts := []
		for p in r["pts"]:
			pts.append(Vector2(p[0], p[1]))
		_tr.road(pts, r["w"])
		var dense := Terrain.spline(pts, 6.0)
		var rad: float = r["w"] * 0.5 + 16.0
		for q in dense:
			for ox in range(-int(rad / 8.0), int(rad / 8.0) + 1):
				for oy in range(-int(rad / 8.0), int(rad / 8.0) + 1):
					if Vector2(ox * 8, oy * 8).length() <= rad:
						_road_cells[(int(q.x / 8.0) + ox) * 4096 + int(q.y / 8.0) + oy] = true

func _paint_town_details() -> void:
	# training yard sand
	_tr.f(519 + YARD_SHIFT.x, 534 + YARD_SHIFT.y, 118, 78, "#e8c97a")
	for i in range(40):
		_tr.f(522 + YARD_SHIFT.x + _tr.rng.randf() * 112, 536 + YARD_SHIFT.y + _tr.rng.randf() * 72, 3, 1, "#c99f4f")
	# rug in front of the red-and-white stall (between the training yard and the east wall)
	_tr.rug(650, 558, 86, 12, "#a8372b", "#e0b038")
	# flagstones in the plaza around the well and by the gate
	_tr.flagstones(Rect2(396, 432, 60, 60), 0.3)
	_tr.flagstones(Rect2(408, 560, 48, 36), 0.45)
	# ruin floors
	for r in [Rect2(110, 90, 60, 36), Rect2(300, 90, 48, 24), Rect2(480, 130, 72, 48), Rect2(160, 200, 60, 36), Rect2(560, 220, 48, 36),
			Rect2(900, 940, 72, 48), Rect2(780, 920, 60, 36), Rect2(60, 820, 48, 36), Rect2(1000, 840, 48, 36)]:
		_tr.flagstones(r, 0.4)
	# cast shadows of the town walls on the ground (inside to the south / outside to the south and east)
	var sh := Color(0.25, 0.14, 0.05, 0.26)
	_tr.shade(114, 335, 640, 9, sh)
	_tr.shade(112, 344, 11, 246, sh)
	_tr.shade(116, 672, 212, 9, sh); _tr.shade(516, 672, 222, 9, sh)
	_tr.shade(792, 344, 10, 38, sh)
	_tr.shade(792, 490, 10, 100, sh)
	_tr.shade(328, 692, 190, 8, sh)
	# dark soft patches where trees and big pillars will stand and by the road
	for i in range(60):
		var p := Vector2(_tr.rng.randf() * W, _tr.rng.randf() * H)
		_tr.patch(p.x, p.y, 20 + int(_tr.rng.randf() * 18), Color(0.55, 0.38, 0.12), 0.16)

# ---------------------------------------------------------------- solids for the painted terrain
func _cliff_solids() -> void:
	for c in CLIFFS:
		solid(c[0] + 1, c[1] + 1, c[2] - 2, c[3] - 3)
	# the cave mouth's arch is drawn in the ground image and stays solid cliff; the auto door `cave_mouth` at its foot leads inside

func _water_solids() -> void:
	var y := int(WATER_Y0)
	while y < int(WATER_Y1):
		# keep the bridge walkway open (the rails below are solid themselves)
		if y + 6 <= 594 or y >= 644:
			var sx := Terrain.shore_x(SHORE, y + 3)
			if sx < W:
				solid(sx + 4.0, y, W - sx, 6)
		y += 6
	# bridge rails (north and south edge of the deck) - you walk along the planks between them
	solid(1056, 596, W - 1056, 10)
	solid(1056, 632, W - 1056, 12)
	prop(606, func(n): Props.bridge_rail(n, 1056, W, 604, true))
	prop(642, func(n): Props.bridge_rail(n, 1056, W, 638, false))

# ---------------------------------------------------------------- the walled town
func _wall_h(x: float, y: float, w: float, h: float, v := 0) -> void:
	solid(x, y, w, h)
	prop(y + h, func(n): Props.wall_h(n, x, y, w, h, v))

func _wall_v(x: float, y: float, w: float, h: float) -> void:
	solid(x, y, w, h)
	prop(y + h, func(n): Props.wall_v(n, x, y, w, h))

func _tower(x: float, y: float, w: float, h: float, flag: bool) -> void:
	solid(x, y + 10, w, h - 10)
	prop(y + h, func(n): Props.tower(n, x, y, w, h, flag))

func _house(x: float, y: float, w: float, h: float, roof_h: float, door_x: float, door_w: float, curtain: Color, deco: Array, roof_tone := 0) -> void:
	solid(x, y + 6, w, h - 6)
	prop(y + h, func(n): Props.house(n, x, y, w, h, roof_h, door_x, door_w, curtain, deco, roof_tone))

func _town() -> void:
	# --- walls and towers
	_wall_h(114, 285, 624, 50, 1)
	_wall_v(68, 342, 44, 248)
	# East wall split around the new side gate, connecting the plaza to the outer road.
	_wall_v(752, 344, 42, 38)
	_wall_v(752, 490, 42, 100)
	_wall_h(116, 625, 212, 47, 2)
	_wall_h(516, 625, 222, 47, 3)
	_tower(60, 258, 56, 86, true)
	_tower(736, 258, 58, 86, true)
	_tower(60, 588, 56, 84, false)
	_tower(736, 588, 58, 84, false)
	# East-side gate: matching banner pillars, with a clear walk-through opening.
	solid(752, 380, 42, 32)
	prop(412, func(n): Props.east_gate_pillar(n, 752, 364, 42, 48))
	solid(752, 458, 42, 32)
	prop(490, func(n): Props.east_gate_pillar(n, 752, 442, 42, 48))
	# the gate: two big banner towers, iron gate leaves folded back
	solid(328, 585, 48, 107)
	prop(692, func(n): Props.gate_pillar(n, 328, 575, 48, 117))
	solid(468, 585, 48, 107)
	prop(692, func(n): Props.gate_pillar(n, 468, 575, 48, 117))
	prop(676, func(n): Props.gate_bars(n, 377, 640, 48))
	prop(676, func(n): Props.gate_bars(n, 464, 640, 48))
	prop(673, func(n): Props.banner(n, 190, 633, 16, 34))
	prop(673, func(n): Props.banner(n, 640, 633, 16, 34))
	# --- buildings along the walls. Every house has its own details (Props.house deco) so no two look alike.
	# a family house with the storeroom built onto its east side (the storeroom's double doors work: E, centred on x 443)
	_house(300, 300, 115, 76, 40, 44, 16, Color("#a03a4a"), ["ladder", "awning", "jar", "window"])
	solid(415, 318, 86, 58)
	prop(376, func(n): Props.storehouse(n, 415, 312, 86, 64, 30, 443))
	_house(116, 448, 100, 74, 38, 64, 16, Color("#3d6a9a"), ["cloth", "window"], 1)
	# two houses along the north wall, east of the storeroom
	_house(545, 300, 85, 76, 34, 30, 16, Color("#5a7a3a"), ["pots", "jar"])
	_house(640, 304, 85, 72, 34, 50, 16, Color("#b8744a"), ["stair", "cloth"], 1)
	# stable (open front, hay at the back)
	solid(122, 318, 146, 22)
	solid(122, 318, 7, 78)
	solid(261, 318, 7, 78)
	prop(344, func(n): Props.stable_back(n, 122, 322, 146, 74))
	prop(396, func(n): Props.stable_front(n, 122, 322, 146, 74))
	# the red-and-white pottery stall between the training yard and the east wall; its roof top (y 510) is level with the yard's north rail.
	# Nidu minds it, standing just to its west (npc_data.gd), and sells supplies from it (shop.gd, Stage 7h).
	solid(654, 546, 80, 12)
	prop(558, func(n): Props.stall_striped(n, 652, 558, 82, 0))
	# cook camp: a long red canopy over the cauldron (fire at x 262) and, at its west end, the sleeping traveller (npc_data.gd)
	solid(250, 594, 24, 8)
	solid(142, 590, 5, 12)
	solid(216, 590, 5, 12)
	solid(304, 590, 5, 12)
	prop(602, func(n): Props.cook_camp(n, 140, 602, 170, 262, [216.0]), true, 0.1)
	_lights.append([262.0, 580.0, 64.0, 1])
	# well in the plaza
	solid(404, 454, 42, 14)
	prop(468, func(n): Props.well(n, 425, 462))
	# training yard (YARD_SHIFT moves the whole yard). The rail rects are the collision; the
	# drawing is chunky posts with a raised rail (north and south), long beams on the sides, an opening on the west side, a dummy in
	# the middle that wobbles when hit (it is in `hittables`) and a weapon rack in the north-east corner.
	var ys := YARD_SHIFT
	for f in [[515, 530, 127, 4], [515, 612, 127, 4], [638, 530, 4, 86], [515, 530, 4, 36], [515, 590, 4, 26]]:
		solid(f[0] + ys.x, f[1] + ys.y, f[2], f[3])
	var lx: float = 517.0 + ys.x          # west and east fence lines (post centres)
	var rx: float = 640.0 + ys.x
	var ty: float = 534.0 + ys.y          # ground lines of the north and south fences
	var by: float = 616.0 + ys.y
	var gap0: float = 566.0 + ys.y        # the opening in the west fence runs from gap0 to gap1
	var gap1: float = 594.0 + ys.y
	prop(ty, func(n): Props.fence_h(n, lx, rx, ty, 20.0))
	prop(by, func(n): Props.fence_h(n, lx, rx, by, 20.0))
	prop(by - 0.5, func(n): Props.fence_v(n, rx, ty, by))      # just before the south fence, so its corner post covers the beam's end
	prop(gap0 - 0.5, func(n): Props.fence_v(n, lx, ty, gap0))
	prop(gap0, func(n): Props.fence_post(n, lx, gap0))
	prop(by - 0.5, func(n): Props.fence_v(n, lx, gap1, by))
	prop(gap1, func(n): Props.fence_post(n, lx, gap1))
	solid(564 + ys.x, 576 + ys.y, 12, 6)
	var dummy := {"pos": Vector2(570, 582) + ys, "t": 99.0, "dir": 1.0, "lean": 0.0}
	hittables.append(dummy)
	prop(dummy["pos"].y, func(n): Props.dummy(n, dummy["pos"].x, dummy["pos"].y, dummy["lean"]), true)
	solid(608 + ys.x, 552 + ys.y, 24, 6)
	prop(558 + ys.y, func(n): Props.weapon_rack(n, 620 + ys.x, 558 + ys.y))
	# watch post outside the east wall (north of the gate road), its base level with the north gate pillar's (y 412).
	# The south one was removed: a guard stands there instead.
	solid(812, 358, 36, 54)
	prop(412, func(n): Props.watch_post(n, 812, 354, 36, 58))
	# everyday clutter
	solid(272, 362, 24, 12)                    # barrels between the stable and the house
	prop(374, func(n): Props.barrel(n, 278, 368))
	prop(374, func(n): Props.barrel(n, 292, 372))
	solid(512, 368, 16, 12)                    # crate and sacks by the storeroom
	prop(380, func(n): Props.crate(n, 520, 378))
	solid(470, 378, 24, 8)
	prop(386, func(n): Props.sacks(n, 482, 386))
	solid(250, 496, 24, 12)
	prop(508, func(n): Props.wheel_pots(n, 262, 506))
	solid(278, 502, 18, 10)
	prop(510, func(n): Props.pots(n, 288, 510))
	solid(232, 416, 28, 10)
	prop(426, func(n): Props.hay(n, 246, 424))
	solid(334, 598, 24, 8)
	prop(606, func(n): Props.sacks(n, 346, 606))

# ---------------------------------------------------------------- ruins (north-west and south-east) and other landmarks
func _ruins() -> void:
	for p in PILLARS:
		var x: float = p[0]; var y: float = p[1]; var h: float = p[2]; var k: int = p[3]
		solid(x - 9, y - 8, 18, 9)
		prop(y, func(n): Props.pillar(n, x, y, h, k, int(x)))
	for w in RUIN_WALLS:
		var x: float = w[0]; var y: float = w[1]; var ww: float = w[2]; var hh: float = w[3]; var sd: int = w[4]
		solid(x, y + 4, ww, hh - 4)
		prop(y + hh, func(n): Props.ruin_wall(n, x, y, ww, hh, sd))
	for d in DRUMS:
		var x: float = d[0]; var y: float = d[1]; var lg: bool = d[2] == 1
		solid(x - (16.0 if lg else 8.0), y - 8, 32.0 if lg else 16.0, 8, true)       # a fallen drum is low: enemies see over it
		prop(y, func(n): Props.column_drum(n, x, y, lg))
	for r in RUBBLE:
		var x: float = r[0]; var y: float = r[1]; var s: int = r[2]
		prop(y, func(n): Props.rubble(n, x, y, s))

# the scorpions' den (Stage 7j): the slab over the burrow (low: enemies and the hero see over it)
func _scorpion_den() -> void:
	solid(DEN.x - 13, DEN.y - 6, 26, 6, true)
	prop(DEN.y, func(n): Props.scorpion_den(n, DEN.x, DEN.y))

# ---------------------------------------------------------------- the stranger's trail in the ruins (Stage 7b)
func _ruins_clue() -> void:
	prop(0.0, _draw_prints, true, 0.5)          # flat on the ground: sorted first, under everything that stands
	prop(CLUE_BOX.y, _draw_box, true, 0.1)
	prop(CLUE_PAGE.y, _draw_page, true, 0.5)
	prop(CLUE_PAGE_2.y, _draw_page_2, true, 0.5)

func _clue_ready() -> bool:
	return dialogue != null and dialogue.quest.flags.get("return_done", false)

func _flag(f: String) -> bool:
	return dialogue != null and dialogue.quest.flags.get(f, false)

func _draw_prints(n) -> void:
	if not _clue_ready():
		return
	for i in range(PRINTS.size()):
		var p := Vector2(PRINTS[i][0], PRINTS[i][1])
		var nxt := Vector2(PRINTS[mini(i + 1, PRINTS.size() - 1)][0], PRINTS[mini(i + 1, PRINTS.size() - 1)][1])
		var prv := Vector2(PRINTS[maxi(i - 1, 0)][0], PRINTS[maxi(i - 1, 0)][1])
		Props.boot_print(n, p.x, p.y, (nxt - prv).angle(), i % 2 == 0)

func _draw_box(n) -> void:
	if _clue_ready() and not _flag("found_object"):
		Props.brass_box(n, CLUE_BOX.x, CLUE_BOX.y, fmod(Props.now(), 2.0) < 0.2)

func _draw_page(n) -> void:
	if _clue_ready() and not _flag("found_log"):
		Props.torn_page(n, CLUE_PAGE.x, CLUE_PAGE.y)

func _draw_page_2(n) -> void:
	if _clue_ready() and not _flag("found_log_2"):
		Props.torn_page(n, CLUE_PAGE_2.x, CLUE_PAGE_2.y)

func usable(id: String) -> bool:
	match id:
		"ruins_box":
			return _clue_ready() and not _flag("found_object")
		"ruins_page":
			return _clue_ready() and not _flag("found_log")
		"ruins_page_2":
			return _clue_ready() and not _flag("found_log_2")
	return false

# E at the box: it goes into the inventory. E at a page: it opens in the log reader. All are written in the journal. The box and the
# first page finish the search; the second page (by the den) is extra.
func use_spot(id: String) -> void:
	if not usable(id):
		return
	var q = dialogue.quest
	match id:
		"ruins_box":
			dialogue.inv.add("brass_box")
			q.note("found_object")
			q.add_journal("brass_box")
			combat.spark(CLUE_BOX + Vector2(0, -5), Vector2.UP, 6, Color("#ecc66a"))
		"ruins_page":
			q.note("found_log")
			q.add_journal("page_1")
			dialogue.menu.read_log("page_1")
		"ruins_page_2":
			q.note("found_log_2")
			q.add_journal("page_2")
			dialogue.menu.read_log("page_2")
	if _flag("found_object") and _flag("found_log"):
		q.note("ruins_searched")

# walking along the prints (once they are there) notes them in the journal
func _process(_dt: float) -> void:
	if player != null and not talking and _clue_ready() and not _flag("saw_prints") and PRINTS_SEEN.has_point(player.position):
		dialogue.quest.note("saw_prints")
		dialogue.quest.add_journal("boot_prints")

func _landmarks() -> void:
	solid(252, 856, 36, 14)
	prop(870, func(n): Props.crate_stack(n, 270, 870))
	solid(996, 970, 14, 8)
	prop(978, func(n): Props.barrel(n, 1003, 976))
	# cart + bones along the road
	solid(380, 1150, 40, 10)
	prop(1160, func(n): Props.cart(n, 400, 1160))
	for b in [[560, 1190], [200, 960], [770, 700], [1000, 860]]:
		var x: float = b[0]; var y: float = b[1]
		prop(y, func(n): Props.bones(n, x, y))
	# Road signs: the post, plus a boxed E prompt at its bottom right while the hero is close.
	for sg in SIGNS:
		var x: float = sg["pos"][0]; var y: float = sg["pos"][1]
		solid(x - 4, y - 4, 6, 4)
		prop(y, func(n): Props.signpost(n, x, y))
		var tag := prop(y + 1, func(n): _draw_sign_prompt(n, x, y), true, 0.1)
		tag.z_index = 60     # always on top of the hero and props

func _draw_sign_prompt(n, x: float, y: float) -> void:
	if player == null or talking or player.position.distance_to(Vector2(x, y)) >= 34.0:
		return
	var font := ThemeDB.fallback_font
	var px := x + 8.0
	var py := y - 2.0
	Sprites.R(n, px - 1, py - 1, 13, 13, Color("#3a2614"))
	Sprites.R(n, px, py, 11, 11, Color("#f4ead0"))
	n.draw_string(font, Vector2(px + 2, py + 9), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#3a2614"))

func _plants() -> void:
	for t in TREES:
		var x: float = t[0]; var y: float = t[1]; var s: float = t[2]; var k: int = t[3]
		solid(x - 5, y - 4, 10, 5)
		prop(y, func(n): Props.tree(n, x, y, s, k, true), true, 0.14)
	for p in PALMS:
		var x: float = p[0]; var y: float = p[1]; var h: float = p[2]; var l: float = p[3]
		solid(x - 4, y - 4, 9, 5)
		prop(y, func(n): Props.palm(n, x, y, h, l, true), true, 0.14)
	for c in CACTI:
		var x: float = c[0]; var y: float = c[1]; var v: int = c[2]
		solid(x - 4, y - 4, 9, 5, true)          # thin: no cover from enemy sight
		prop(y, func(n): Props.cactus(n, x, y, v))
	for d in DEAD_TREES:
		var x: float = d[0]; var y: float = d[1]; var v: int = d[2]
		solid(x - 3, y - 3, 7, 4, true)          # bare and thin: no cover
		prop(y, func(n): Props.dead_tree(n, x, y, v))

# agaves, boulders and small bushes sprinkled over the free sand
func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var placed := 0
	var tries := 0
	while placed < 70 and tries < 4000:
		tries += 1
		var p := Vector2(rng.randf_range(24.0, W - 24.0), rng.randf_range(60.0, H - 12.0))
		if not _free_spot(p, 16.0):
			continue
		var x := p.x; var y := p.y
		var s := rng.randf_range(0.85, 1.25)
		var v := rng.randi() % 6
		solid(x - 4, y - 3, 8, 3, true)          # scatter is low: enemies see over the agaves (and the small rocks below)
		prop(y, func(n): Props.agave(n, x, y, s, v))
		placed += 1
	placed = 0
	tries = 0
	while placed < 46 and tries < 4000:
		tries += 1
		var p := Vector2(rng.randf_range(24.0, W - 40.0), rng.randf_range(60.0, H - 20.0))
		var w := float(rng.randi_range(14, 28)); var h := float(rng.randi_range(10, 18))
		if not _free_spot(p, 20.0):
			continue
		var x := p.x - w / 2.0; var y := p.y - h
		solid(x, y + 3, w, h - 3, true)
		prop(p.y, func(n): Props.rock(n, x, y, w, h))
		placed += 1

func _free_spot(p: Vector2, margin: float) -> bool:
	if _on_road(p) or _in_water(p):
		return false
	if p.x > 40 and p.x < 810 and p.y > 240 and p.y < 705:
		return false
	if p.distance_to(spawn) < 40.0 or p.distance_to(Vector2(1030, 150)) < 50.0:
		return false
	return not _rect_blocked(Rect2(p.x - margin, p.y - margin, margin * 2.0, margin * 1.6))

func _nests_and_bandits() -> void:
	for nn in NEST_SPOTS:
		var x: float = nn[0]; var y: float = nn[1]
		nests.append(Vector2(x, y))
		solid(x - 10, y - 6, 20, 7, true)        # a low pile: the rats see over their own nest
		prop(y, func(n): Props.nest(n, x, y))
	bandit_spots = [
		[Vector2(343, 925), Vector2(1, 0), 32.0],
		[Vector2(285, 972), Vector2(0.2, 1).normalized(), 26.0],
		[Vector2(443, 1014), Vector2(1, -0.2).normalized(), 30.0],
	]

func _torches() -> void:
	for t in TORCHES:
		var x: float = t[0]; var y: float = t[1]
		solid(x - 3, y - 3, 6, 4)
		prop(y, func(n): Props.torch(n, x, y), true, 0.11)
		_lights.append([x, y - 30.0, 50.0, 0])
	_lights.append([1030.0, 112.0, 70.0, 2])

# ---------------------------------------------------------------- people (data in npc_data.gd, words in dialogue.gd)
func start_npcs() -> void:   # called by main.gd once the dialogue data exists
	for d in NpcData.LIST:
		var n = Npc.new()
		ysort.add_child(n)
		npcs.append(n)
		n.setup(d, self)

# the sign the hero is standing at ({} if none) - see SIGNS
func near_sign() -> Dictionary:
	if player == null:
		return {}
	for sg in SIGNS:
		if player.position.distance_to(Vector2(sg["pos"][0], sg["pos"][1])) <= 30.0:
			return sg
	return {}

func npc_by_id(id: String):
	for n in npcs:
		if n.id == id:
			return n
	return null

func chatter_for(id: String) -> Array:
	return dialogue.chatter_for(id) if dialogue != null else []

func mark_for(id: String) -> String:
	return dialogue.mark_for(id) if dialogue != null else ""

# enemies of the town map: rats at the nests (how many: combat.NEST_RATS), the three bandits on the road, and the scorpions at their
# den in the ruins (Stage 7j). New rows go at the end: a save notes the dead by their row (level.gd dead_plan).
func enemy_plan(c) -> Array:
	var out := []
	for i in c.NEST_RATS.keys():
		var n: int = c.NEST_RATS[i]
		for j in range(n):
			out.append({"kind": "rat", "pos": nests[i] + Vector2((j - (n - 1) / 2.0) * 20.0, 16.0)})
	for b in bandit_spots:
		out.append({"kind": "bandit", "pos": b[0], "axis": b[1], "span": b[2]})
	for s in DEN_SCORPIONS:
		out.append({"kind": "scorpion", "pos": Vector2(s[0], s[1])})
	return out
