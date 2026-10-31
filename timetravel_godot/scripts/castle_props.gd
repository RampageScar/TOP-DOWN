extends RefCounted
# castle_props.gd - things that only the castle maps use (courtyard now, great hall later): the royal banner with a Persian
# winged-disc emblem, the warrior statue, cypress trees, the wall fountain, the supply colonnade, the armoury stall and the raised
# portcullis. Same rules as props.gd:
# absolute world coordinates, dark outline, three tones, light from the top-left.

const Props = preload("res://scripts/props.gd")

const OL := Color("#3a2517")
const GOLD := Color("#e8b838")
const GOLD_L := Color("#f8dc7a")
const GOLD_D := Color("#a87c18")
const RED := Color("#b8372b")
const RED_D := Color("#8a251d")
const RED_L := Color("#d9503f")
# statue stone (cooler grey than the sandstone walls so it reads as a monument)
const SG := Color("#a8a59b")
const SG_L := Color("#d2cfc3")
const SG_D := Color("#77746b")
const SG_DD := Color("#53514a")

static func R(n, x: float, y: float, w: float, h: float, c) -> void:
	Props.R(n, x, y, w, h, c)

# ------------------------------------------------------------------ banner with a winged sun disc (Achaemenid style, no fleur-de-lis)
static func royal_banner(n, x: float, y: float, w: float, h: float) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y, w, h, RED); R(n, x, y, w, 2, RED_L); R(n, x + w - 2, y, 2, h, RED_D); R(n, x, y + h - 3, w, 3, RED_D)
	var cx := x + w / 2.0
	var cy := y + 11.0
	# the disc
	R(n, cx - 2, cy - 2, 5, 5, GOLD); R(n, cx - 1, cy - 3, 3, 7, GOLD); R(n, cx - 1, cy - 1, 3, 3, GOLD_L)
	# two wings, three feathers each
	for s in [-1.0, 1.0]:
		var wx: float = cx + (3.0 if s > 0.0 else -3.0 - 5.0)
		R(n, wx, cy - 2, 5, 1, GOLD)
		R(n, wx + (0.0 if s > 0.0 else 1.0), cy, 4, 1, GOLD)
		R(n, wx + (0.0 if s > 0.0 else 2.0), cy + 2, 3, 1, GOLD_D)
	# the tail below the disc
	R(n, cx - 1, cy + 4, 3, 3, GOLD_D); R(n, cx - 3, cy + 7, 2, 2, GOLD_D); R(n, cx + 2, cy + 7, 2, 2, GOLD_D)
	# gold hem and the pointed bottom
	R(n, x + 2, y + h - 6, w - 4, 1, GOLD)
	R(n, x + 1, y + h, w - 2, 2, RED_D); R(n, x + 3, y + h + 2, w - 6, 2, RED_D)
	R(n, x - 2, y - 3, w + 4, 2, OL); R(n, x - 1, y - 3, w + 2, 1, GOLD)

# ------------------------------------------------------------------ cypress (tall, narrow, dark green)
static func cypress(n, x: float, y: float, h: float) -> void:
	Props.shadow(n, x + 3, y + 1, 7, 3)
	R(n, x - 1, y - 5, 3, 5, Color("#4a2e1a"))
	var cy := y - 5.0 - h / 2.0
	n.draw_colored_polygon(Props.ell(x, cy, 8.0, h / 2.0 + 1.0, 16), Color("#1c3a1c"))
	n.draw_colored_polygon(Props.ell(x, cy, 7.0, h / 2.0, 16), Color("#2c5a2a"))
	n.draw_colored_polygon(Props.ell(x - 2.0, cy - 1.0, 3.5, h / 2.0 - 3.0, 12), Color("#3f7a38"))
	n.draw_colored_polygon(Props.ell(x + 3.0, cy + 2.0, 2.5, h / 2.0 - 5.0, 10), Color("#224a22"))

static func bush(n, x: float, y: float, s := 1.0, flowers := false) -> void:
	Props.shadow(n, x + 3, y + 1, 10.0 * s, 3)
	Props.blob(n, x, y - 4.0 * s, 10.0 * s, 6.0 * s, Color("#1c3a1c"))
	Props.blob(n, x, y - 5.0 * s, 9.0 * s, 5.0 * s, Color("#3a6e30"))
	Props.blob(n, x - 2.0 * s, y - 7.0 * s, 5.0 * s, 3.0 * s, Color("#58903f"))
	if flowers:
		# a few white and pink blossoms, placed from x so neighbouring bushes don't repeat the same pattern
		for i in range(6):
			var k := int(x) * 7 + i * 13
			var fx: float = x - 7.0 * s + float(k % 13) * s
			var fy: float = y - 9.0 * s + float((k / 3) % 6) * s
			R(n, fx, fy, 2, 2, Color("#f4ead0") if i % 3 != 0 else Color("#e8788a"))

# ------------------------------------------------------------------ wall fountain (against the north wall)
# (x, y) = centre of the basin's front edge. A niche of blue glazed brick (as on the palace walls at Susa) with a gold lion-head
# spout, water falling into a stone basin. Animated (stream and ripples), so place it with prop(..., true, interval).
static func wall_fountain(n, x: float, y: float) -> void:
	var t := Props.now()
	Props.shadow(n, x + 4, y + 1, 26, 4)
	# the niche: stone frame, arched top, blue brick inside
	R(n, x - 17, y - 54, 34, 40, OL); n.draw_colored_polygon(Props.ell(x, y - 54, 17.0, 10.0, 18), OL)
	R(n, x - 16, y - 53, 32, 38, SG); n.draw_colored_polygon(Props.ell(x, y - 54, 16.0, 9.0, 18), SG)
	R(n, x - 16, y - 53, 2, 38, SG_L); R(n, x + 14, y - 53, 2, 38, SG_D)
	R(n, x - 12, y - 52, 24, 36, Color("#2f5f9e")); n.draw_colored_polygon(Props.ell(x, y - 52, 12.0, 7.0, 16), Color("#2f5f9e"))
	var row := 0
	var by := y - 50.0
	while by < y - 17:
		R(n, x - 12, by, 24, 1, Color("#244a7c"))
		var bx := x - 12.0 + (row % 2) * 4.0
		while bx < x + 12:
			R(n, bx, by + 1, 1, 3, Color("#244a7c")); R(n, bx + 1, by + 1, 3, 1, Color("#4a86c8"))
			bx += 8.0
		by += 4.0
		row += 1
	# gold border band and the lion head (mane, face, open mouth)
	R(n, x - 12, y - 46, 24, 1, GOLD_D)
	Props.blob(n, x, y - 34, 7, 6, OL); Props.blob(n, x, y - 34, 6, 5, GOLD_D)
	Props.blob(n, x, y - 34, 4, 4, GOLD); R(n, x - 2, y - 36, 2, 2, GOLD_L)
	R(n, x - 2, y - 35, 1, 1, OL); R(n, x + 1, y - 35, 1, 1, OL)
	R(n, x - 1, y - 32, 3, 2, OL)
	# the stream: a light column with highlights running down
	R(n, x - 1, y - 30, 3, 14, Color("#5aa0c0")); R(n, x, y - 30, 1, 14, Color("#a8d8e8"))
	for i in range(3):
		var a := fmod(t * 1.6 + i / 3.0, 1.0)
		R(n, x - 1, y - 30 + a * 13.0, 3, 2, Color(1, 1, 1, 0.8))
	# the basin: rim, water with ripples, a front face with joints
	R(n, x - 23, y - 21, 46, 22, OL)
	R(n, x - 22, y - 20, 44, 5, SG_L); R(n, x - 22, y - 16, 44, 1, SG)
	R(n, x - 19, y - 15, 38, 7, Color("#2d6a8a")); R(n, x - 19, y - 15, 38, 1, Color("#245670"))
	for i in range(2):
		var a := fmod(t * 0.8 + i * 0.5, 1.0)
		var rw := 4.0 + a * 14.0
		R(n, x - rw, y - 12 + (i % 2), rw * 2.0, 1, Color(0.75, 0.9, 1.0, 0.7 * (1.0 - a)))
	R(n, x - 22, y - 8, 44, 8, SG); R(n, x - 22, y - 8, 44, 1, SG_L); R(n, x - 22, y - 2, 44, 2, SG_D)
	for jx in [-12, 2, 14]:
		R(n, x + jx, y - 7, 1, 5, SG_D)

# a plain stone bench. (x, y) = centre of the front edge
static func bench(n, x: float, y: float) -> void:
	Props.shadow(n, x + 4, y + 1, 15, 3)
	for lx in [-11, 7]:
		R(n, x + lx - 1, y - 7, 6, 8, OL); R(n, x + lx, y - 6, 4, 6, SG_D)
	R(n, x - 14, y - 12, 28, 6, OL); R(n, x - 13, y - 11, 26, 4, SG); R(n, x - 13, y - 11, 26, 1, SG_L); R(n, x - 13, y - 8, 26, 1, SG_D)

# ------------------------------------------------------------------ covered supply colonnade (lean-to against a wall)
# (x, y) = west end of the front edge (where the pillars stand); the roof runs back `depth` px to the wall; h = pillar height.
# Goods sit in the shade between the pillars; a lantern hangs from the middle of the front beam.
static func colonnade(n, x: float, y: float, w: float, depth: float, h: float) -> void:
	Props.shadow(n, x + w / 2.0 + 6, y + 1, w / 2.0 + 4, 4)
	n.draw_rect(Rect2(x, y - depth, w, depth), Color(0.1, 0.05, 0.02, 0.28))
	# goods, one group per bay, cycling through what a castle keeps in store
	var bay := w / 5.0
	for i in range(5):
		var gx := x + bay * (i + 0.5)
		match i % 5:
			0: Props.crate_stack(n, gx, y - 6)
			1: Props.sacks(n, gx, y - 6)
			2: Props.barrel(n, gx - 7, y - 6); Props.barrel(n, gx + 7, y - 5)
			3: Props.pots(n, gx, y - 6)
			4: Props.crate(n, gx - 6, y - 6); Props.sacks(n, gx + 6, y - 4)
	# stone pillars at the bay edges
	for i in range(6):
		var cx := x + bay * i
		R(n, cx - 5, y - 4, 10, 5, OL); R(n, cx - 4, y - 3, 8, 3, SG)
		R(n, cx - 4, y - h, 8, h - 3, OL); R(n, cx - 3, y - h, 6, h - 4, SG)
		R(n, cx - 3, y - h, 2, h - 4, SG_L); R(n, cx + 2, y - h, 1, h - 4, SG_D)
		R(n, cx - 5, y - h - 3, 10, 4, OL); R(n, cx - 4, y - h - 2, 8, 2, SG_L)
	# timber roof: front beam, then rafters running back to the wall
	var ry := y - h - 3.0
	R(n, x - 4, ry - 18, w + 8, 20, OL)
	R(n, x - 3, ry - 17, w + 6, 12, Props.WD_D)
	var rx := x - 3.0
	while rx < x + w + 3:
		R(n, rx, ry - 17, 3, 12, Props.WD); R(n, rx, ry - 17, 1, 12, Props.WD_L)
		rx += 7.0
	R(n, x - 3, ry - 5, w + 6, 6, Props.WD); R(n, x - 3, ry - 5, w + 6, 1, Props.WD_L); R(n, x - 3, ry, w + 6, 1, Props.WD_D)
	# a few vines over the beam
	for i in range(9):
		var vx := x + 8.0 + float((i * 37) % int(w - 16.0))
		Props.blob(n, vx, ry - 4, 5, 3, Color("#1c3a1c")); Props.blob(n, vx, ry - 5, 4, 2, Color("#3a6e30"))
		R(n, vx - 1, ry - 2, 1, 4 + (i % 3) * 2, Color("#3a6e30"))
		if i % 2 == 0:
			R(n, vx + 1, ry - 6, 1, 1, Color("#58903f"))
	# lantern on a short chain
	var lx := x + w / 2.0
	R(n, lx, ry + 1, 1, 5, OL)
	R(n, lx - 3, ry + 6, 7, 8, OL); R(n, lx - 2, ry + 7, 5, 6, GOLD_D); R(n, lx - 1, ry + 8, 3, 4, Color("#ffd060"))

# ------------------------------------------------------------------ armoury stall: a red canopy over a spear rack and shields
# (x, y) = west end of the front edge, like Props.cook_camp
static func armoury(n, x: float, y: float, w: float) -> void:
	Props.shadow(n, x + w / 2.0 + 3, y + 1, w / 2.0 + 4, 4)
	Props.rack(n, x + w / 2.0 - 6, y - 4)
	wicker_shield(n, x + w - 14, y - 1)
	wicker_shield(n, x + 12, y)
	for px in [x + 2, x + w - 6]:
		R(n, px, y - 48, 4, 48, OL); R(n, px + 1, y - 48, 2, 48, Props.WD); R(n, px + 1, y - 48, 1, 48, Props.WD_L)
	R(n, x - 3, y - 60, w + 6, 22, OL)
	R(n, x - 2, y - 59, w + 4, 20, RED); R(n, x - 2, y - 59, w + 4, 3, RED_L); R(n, x - 2, y - 44, w + 4, 5, RED_D)
	R(n, x - 2, y - 52, w + 4, 2, GOLD_D); R(n, x - 2, y - 53, w + 4, 1, GOLD)
	var sx := x - 2.0
	var k := 0
	while sx < x + w + 2:
		R(n, sx, y - 39, 9, 4 + (k % 2) * 2, OL); R(n, sx + 1, y - 39, 7, 3 + (k % 2) * 2, RED); sx += 10.0; k += 1

# a Persian-style wicker shield (woven cane on a frame), leaning upright. (x, y) = its foot
static func wicker_shield(n, x: float, y: float) -> void:
	Props.blob(n, x, y - 9, 7, 10, OL)
	Props.blob(n, x, y - 9, 6, 9, Color("#b08a4a"))
	Props.blob(n, x - 1, y - 11, 3, 5, Color("#d0aa66"))
	for i in range(4):
		R(n, x - 5, y - 15 + i * 4, 10, 1, Color("#8a6a34"))
	R(n, x - 1, y - 18, 2, 18, Color("#6e4a24"))

# ------------------------------------------------------------------ the great warrior statue
# (x, y) = centre of the front edge of the base. The statue is the first prop drawn from a PNG instead of code:
# assets/props/statue.png (68 x 116, its own plinth, cypresses and flower beds), made from Sprites/Props/statue_src.webp
# with Code/prep_prop.py. If the PNG is missing, the older code-drawn statue on a three-step plinth is used instead.
const STATUE_PNG := "res://assets/props/statue.png"
# Held here on purpose: props are drawn once, and a texture only referenced by a local would be freed after that draw,
# leaving the recorded draw call to show a white box.
static var _statue_tex: Texture2D

static func statue(n, x: float, y: float) -> void:
	if _statue_tex == null and ResourceLoader.exists(STATUE_PNG):
		_statue_tex = load(STATUE_PNG)
	if _statue_tex:
		Props.shadow(n, x + 6, y + 1, 38, 6)
		n.draw_texture(_statue_tex, Vector2(roundf(x - _statue_tex.get_width() / 2.0), y - _statue_tex.get_height()))
		return
	_statue_drawn(n, x, y)

# About 100 px tall including the spear; base 62 px wide.
static func _statue_drawn(n, x: float, y: float) -> void:
	Props.shadow(n, x + 8, y + 1, 40, 7)
	# plinth: three steps, then the pedestal with a gold band
	_step(n, x - 31, y - 12, 62, 12)
	_step(n, x - 23, y - 22, 46, 10)
	_step(n, x - 14, y - 38, 28, 16)
	R(n, x - 12, y - 32, 24, 3, GOLD_D); R(n, x - 12, y - 33, 24, 1, GOLD)
	R(n, x - 2, y - 30, 4, 4, GOLD)       # rosette on the front
	var by := y - 38.0                    # figure stands on this line
	# boots and legs
	R(n, x - 7, by - 4, 6, 4, SG_DD); R(n, x + 1, by - 4, 6, 4, SG_DD)
	R(n, x - 6, by - 15, 5, 12, SG); R(n, x + 1, by - 15, 5, 12, SG_D)
	R(n, x - 6, by - 15, 1, 12, SG_L)
	# scale-armour skirt and torso
	R(n, x - 8, by - 24, 16, 10, OL); R(n, x - 7, by - 23, 14, 8, SG)
	for i in range(3):
		R(n, x - 7, by - 22 + i * 3, 14, 1, SG_D)
		for j in range(4):
			R(n, x - 6 + j * 4 + (i % 2) * 2, by - 21 + i * 3, 1, 2, SG_D)
	R(n, x - 9, by - 38, 18, 15, OL); R(n, x - 8, by - 37, 16, 13, SG)
	R(n, x - 8, by - 37, 5, 13, SG_L); R(n, x + 4, by - 37, 4, 13, SG_D)
	for i in range(4):
		R(n, x - 8, by - 35 + i * 3, 16, 1, SG_D)
	R(n, x - 9, by - 27, 18, 2, GOLD_D)     # belt
	# shield on the left arm (round, with a boss)
	n.draw_colored_polygon(Props.ell(x - 14, by - 27, 7.0, 8.0, 14), OL)
	n.draw_colored_polygon(Props.ell(x - 14, by - 27, 6.0, 7.0, 14), SG_D)
	n.draw_colored_polygon(Props.ell(x - 15, by - 28, 3.0, 4.0, 10), SG)
	R(n, x - 15, by - 29, 2, 2, GOLD)
	# raised right arm and the spear
	R(n, x + 8, by - 36, 4, 12, SG); R(n, x + 8, by - 36, 1, 12, SG_L)
	R(n, x + 10, by - 78, 2, 52, OL); R(n, x + 10, by - 78, 1, 52, Color("#8a5a32")); R(n, x + 11, by - 78, 1, 52, Color("#5e3a1e"))
	n.draw_colored_polygon(PackedVector2Array([Vector2(x + 7, by - 78), Vector2(x + 11, by - 92), Vector2(x + 15, by - 78)]), OL)
	n.draw_colored_polygon(PackedVector2Array([Vector2(x + 8.5, by - 79), Vector2(x + 11, by - 89), Vector2(x + 13.5, by - 79)]), SG_L)
	R(n, x + 7, by - 36, 6, 3, SG_D)
	# neck, face and the conical helmet
	R(n, x - 3, by - 42, 6, 5, SG_D)
	R(n, x - 4, by - 51, 8, 10, OL); R(n, x - 3, by - 50, 6, 8, SG); R(n, x - 3, by - 50, 2, 8, SG_L)
	R(n, x - 2, by - 47, 1, 1, SG_DD); R(n, x + 1, by - 47, 1, 1, SG_DD)
	n.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, by - 49), Vector2(x, by - 64), Vector2(x + 6, by - 49)]), OL)
	n.draw_colored_polygon(PackedVector2Array([Vector2(x - 5, by - 50), Vector2(x, by - 62), Vector2(x + 5, by - 50)]), SG)
	n.draw_colored_polygon(PackedVector2Array([Vector2(x - 5, by - 50), Vector2(x, by - 62), Vector2(x - 1, by - 50)]), SG_L)
	R(n, x - 6, by - 50, 12, 2, GOLD_D)

static func _step(n, x: float, y: float, w: float, h: float) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y, w, h, SG)
	R(n, x, y, w, 2, SG_L)
	R(n, x, y + h - 3, w, 3, SG_D)
	R(n, x + w - 3, y, 3, h, SG_D)
	R(n, x, y, 2, h, SG_L)
	var bx := 10.0
	while bx < w - 4:
		R(n, x + bx, y + 2, 1, h - 5, SG_D)
		bx += 14.0

# ------------------------------------------------------------------ raised portcullis hanging in the gate arch (x0..x1 = opening, y = top of the arch)
static func portcullis(n, x0: float, x1: float, y: float) -> void:
	var w := x1 - x0
	# arch stones over the opening
	R(n, x0 - 3, y - 2, w + 6, 16, OL)
	R(n, x0 - 2, y - 1, w + 4, 14, Color("#b99562"))
	R(n, x0 - 2, y - 1, w + 4, 2, Color("#e2bf86")); R(n, x0 - 2, y + 11, w + 4, 2, Color("#745230"))
	var sx := x0 - 2.0
	while sx < x1 + 2:
		R(n, sx, y + 1, 1, 10, Color("#745230"))
		sx += 9.0
	# iron bars that stop short of the floor (the gate is open)
	R(n, x0 + 1, y + 13, w - 2, 3, Color("#3e3e46")); R(n, x0 + 1, y + 13, w - 2, 1, Color("#6a6a74"))
	var bx := x0 + 3.0
	while bx < x1 - 2:
		R(n, bx, y + 14, 3, 10, Color("#3e3e46")); R(n, bx, y + 14, 1, 10, Color("#6a6a74"))
		R(n, bx, y + 24, 3, 2, Color("#2a2a30"))
		bx += 8.0

# ================================================================== great hall / throne room pieces (Stage 5b)
# interior stone is cooler and greyer than the sandstone of the outside walls
const IW := Color("#6a655d")
const IW_L := Color("#8f8a80")
const IW_LL := Color("#b3ada0")
const IW_D := Color("#4a463f")
const IW_DD := Color("#33302b")
const WOOD := Color("#7a4a26")
const WOOD_L := Color("#a06a3a")
const WOOD_D := Color("#4e2e16")
const CLOTH := Color("#a8262a")
const CLOTH_D := Color("#7a1a1e")

# a grey interior wall running east-west: lit cap on top, brick face below (x, y = top-left, h = total height)
static func inner_wall_h(n, x: float, y: float, w: float, h: float) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y, w, 10, IW_L); R(n, x, y, w, 2, IW_LL); R(n, x, y + 8, w, 2, IW_D)
	R(n, x, y + 10, w, h - 10, IW)
	var yy := 12.0
	var row := 0
	while yy < h - 3:
		R(n, x, y + yy, w, 1, IW_D)
		var bx := (row % 2) * 8.0
		while bx < w:
			R(n, x + bx, y + yy + 1, 1, 7, IW_D)
			bx += 16.0
		yy += 8.0
		row += 1
	R(n, x, y + h - 3, w, 3, IW_DD)

# a grey interior wall running north-south seen from above: just the lit top, with a darker south face
static func inner_wall_v(n, x: float, y: float, w: float, h: float) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y, w, h - 12, IW_L); R(n, x, y, 2, h - 12, IW_LL); R(n, x + w - 2, y, 2, h - 12, IW_D)
	var yy := 5.0
	while yy < h - 14:
		R(n, x + 2, y + yy, w - 4, 1, IW_D)
		yy += 8.0
	R(n, x, y + h - 12, w, 12, IW); R(n, x, y + h - 12, w, 2, IW_LL); R(n, x, y + h - 3, w, 3, IW_DD)

# a stone column with a gold collar. (x, y) = centre of the base on the floor, h = total height
static func column(n, x: float, y: float, h: float) -> void:
	Props.shadow(n, x + 5, y, 13, 4)
	R(n, x - 10, y - 9, 20, 10, OL); R(n, x - 9, y - 8, 18, 8, IW_L); R(n, x - 9, y - 8, 18, 2, IW_LL); R(n, x - 9, y - 2, 18, 2, IW_D)
	R(n, x - 7, y - h + 6, 14, h - 14, OL)
	R(n, x - 6, y - h + 6, 12, h - 14, IW_L)
	R(n, x - 6, y - h + 6, 3, h - 14, IW_LL); R(n, x + 3, y - h + 6, 3, h - 14, IW_D)
	R(n, x - 1, y - h + 6, 1, h - 14, IW_D); R(n, x + 1, y - h + 6, 1, h - 14, IW)
	R(n, x - 7, y - h + 8, 14, 2, GOLD_D); R(n, x - 7, y - 14, 14, 2, GOLD_D)
	R(n, x - 11, y - h - 1, 22, 9, OL); R(n, x - 10, y - h, 20, 7, IW_L); R(n, x - 10, y - h, 20, 2, IW_LL); R(n, x - 10, y - h + 5, 20, 2, IW_D)
	R(n, x - 10, y - h + 2, 20, 1, GOLD)

# a standing gold brazier with a flame (animated)
static func brazier(n, x: float, y: float) -> void:
	var t := Props.now()
	Props.shadow(n, x + 3, y + 1, 8, 3)
	for lx in [-5, 4]:
		R(n, x + lx - 1, y - 14, 3, 14, OL); R(n, x + lx, y - 14, 1, 14, GOLD_D)
	R(n, x - 2, y - 14, 5, 14, OL); R(n, x - 1, y - 14, 3, 14, GOLD_D); R(n, x - 1, y - 14, 1, 14, GOLD)
	R(n, x - 8, y - 22, 17, 9, OL); R(n, x - 7, y - 21, 15, 7, GOLD); R(n, x - 7, y - 21, 15, 2, GOLD_L); R(n, x - 7, y - 16, 15, 2, GOLD_D)
	var fl := int(t * 9.0 + x) % 3
	var h := 7 + fl * 2
	R(n, x - 4, y - 22 - h, 9, h + 1, OL)
	R(n, x - 3, y - 22 - h + 1, 7, h, Color("#e8742a"))
	R(n, x - 2, y - 22 - h / 2.0, 5, h / 2.0, Color("#ffd060"))
	R(n, x, y - 24 - h, 1, 2, Color("#e8742a"))

# cypress in a gold-banded pot
static func potted_cypress(n, x: float, y: float, h: float) -> void:
	Props.shadow(n, x + 3, y + 1, 9, 3)
	R(n, x - 6, y - 9, 13, 10, OL); R(n, x - 5, y - 8, 11, 8, Color("#a8623a")); R(n, x - 5, y - 8, 3, 8, Color("#c8825a")); R(n, x - 5, y - 6, 11, 1, GOLD_D)
	n.draw_colored_polygon(Props.ell(x, y - 9 - h / 2.0, 7.0, h / 2.0 + 1.0, 16), Color("#1c3a1c"))
	n.draw_colored_polygon(Props.ell(x, y - 9 - h / 2.0, 6.0, h / 2.0, 16), Color("#2c5a2a"))
	n.draw_colored_polygon(Props.ell(x - 2.0, y - 10 - h / 2.0, 3.0, h / 2.0 - 3.0, 12), Color("#3f7a38"))

# the one throne: a stone-and-gold seat with a tall red back carrying the winged disc. (x, y) = centre of the front edge
static func throne(n, x: float, y: float) -> void:
	Props.shadow(n, x + 6, y + 1, 30, 5)
	# tall back (drawn first). Kept low enough that the person-sized king still reads in front of it.
	R(n, x - 20, y - 62, 40, 42, OL)
	R(n, x - 19, y - 61, 38, 40, GOLD_D); R(n, x - 19, y - 61, 38, 2, GOLD_L)
	R(n, x - 16, y - 58, 32, 36, CLOTH_D); R(n, x - 15, y - 57, 30, 34, CLOTH); R(n, x - 15, y - 57, 30, 2, RED_L)
	R(n, x - 22, y - 66, 6, 6, OL); R(n, x - 21, y - 65, 4, 4, GOLD)          # finials
	R(n, x + 16, y - 66, 6, 6, OL); R(n, x + 17, y - 65, 4, 4, GOLD)
	# winged disc high on the back, just above the king's tiara (its tail is hidden behind his head)
	R(n, x - 3, y - 57, 7, 7, GOLD); R(n, x - 2, y - 58, 5, 9, GOLD); R(n, x - 1, y - 55, 3, 3, GOLD_L)
	for s in [-1.0, 1.0]:
		var wx: float = x + (4.0 if s > 0.0 else -13.0)
		R(n, wx, y - 56, 9, 1, GOLD); R(n, wx + (0.0 if s > 0.0 else 1.0), y - 54, 8, 1, GOLD); R(n, wx + (1.0 if s > 0.0 else 3.0), y - 52, 6, 1, GOLD_D)
	R(n, x - 1, y - 49, 3, 4, GOLD_D); R(n, x - 4, y - 46, 3, 2, GOLD_D); R(n, x + 2, y - 46, 3, 2, GOLD_D)
	# arms and the seat block
	R(n, x - 23, y - 34, 8, 30, OL); R(n, x - 22, y - 33, 6, 28, GOLD_D); R(n, x - 22, y - 33, 6, 3, GOLD_L)
	R(n, x + 15, y - 34, 8, 30, OL); R(n, x + 16, y - 33, 6, 28, GOLD_D); R(n, x + 16, y - 33, 6, 3, GOLD_L)
	R(n, x - 16, y - 22, 32, 18, OL); R(n, x - 15, y - 21, 30, 16, IW_L); R(n, x - 15, y - 21, 30, 3, CLOTH); R(n, x - 15, y - 18, 30, 1, GOLD)
	R(n, x - 15, y - 5, 30, 1, IW_D)
	R(n, x - 3, y - 14, 6, 6, GOLD); R(n, x - 2, y - 13, 4, 4, GOLD_L)      # rosette on the seat front
	# stepped base
	R(n, x - 28, y - 7, 56, 8, OL); R(n, x - 27, y - 6, 54, 6, IW_L); R(n, x - 27, y - 6, 54, 2, IW_LL); R(n, x - 27, y - 1, 54, 2, IW_D)
	R(n, x - 24, y - 12, 4, 5, GOLD_D); R(n, x + 20, y - 12, 4, 5, GOLD_D)    # feet

# the seated king, drawn in the same local frame as throne() (feet at 0,0). t = time for a slow breathing bob.
# Person-sized (8 px head, 14 px wide body with the arms, like sprites.gd person()): about 48 px from the floor to the top of the
# tiara. He looks taller than the guards only because the seat raises him, not because he is drawn bigger.
static func king_seated(n, x: float, y: float, t: float) -> void:
	var b := 1.0 if fmod(t, 3.6) > 3.1 else 0.0
	var robe := Color("#5a2a7a"); var robe_d := Color("#3e1a58"); var robe_l := Color("#7a44a0")
	var skin := Color("#d8aa80"); var skin_d := Color("#b88a62")
	var beard := Color("#1c1410")
	# robe skirt hanging over the seat front, boots resting on the throne base
	R(n, x - 6, y - 21, 12, 15, OL); R(n, x - 5, y - 20, 10, 13, robe); R(n, x - 5, y - 20, 3, 13, robe_l); R(n, x + 3, y - 20, 2, 13, robe_d)
	R(n, x - 5, y - 10, 10, 2, GOLD_D)                                                   # gold hem
	R(n, x - 6, y - 7, 5, 4, OL); R(n, x + 1, y - 7, 5, 4, OL)
	R(n, x - 5, y - 6, 3, 2, Color("#2a1810")); R(n, x + 2, y - 6, 3, 2, Color("#2a1810"))
	# body with the arms at the sides, hands on the knees
	R(n, x - 8, y - 33 + b, 16, 13, OL)
	R(n, x - 7, y - 32 + b, 14, 11, robe); R(n, x - 7, y - 32 + b, 4, 11, robe_l); R(n, x + 4, y - 32 + b, 3, 11, robe_d)
	R(n, x - 5, y - 32 + b, 1, 10, robe_d); R(n, x + 4, y - 32 + b, 1, 10, Color("#2e1244"))     # where the arms meet the body
	R(n, x - 7, y - 31 + b, 14, 2, GOLD_D)                                               # collar (the beard covers its middle)
	R(n, x - 4, y - 25 + b, 8, 1, GOLD)                                                  # sash
	R(n, x - 7, y - 22 + b, 3, 2, skin); R(n, x + 4, y - 22 + b, 3, 2, skin_d)          # hands
	# head, long squared beard over the chest, the fluted tiara
	R(n, x - 5, y - 41 + b, 10, 10, OL); R(n, x - 4, y - 40 + b, 8, 8, skin); R(n, x - 4, y - 40 + b, 2, 8, Color("#e8c098"))
	R(n, x - 3, y - 38 + b, 1, 2, Color("#222222")); R(n, x + 1, y - 38 + b, 1, 2, Color("#222222"))
	R(n, x - 1, y - 36 + b, 2, 1, skin_d)
	R(n, x - 5, y - 35 + b, 10, 8, OL); R(n, x - 4, y - 35 + b, 8, 7, beard); R(n, x - 4, y - 35 + b, 8, 1, Color("#3a2a1c"))
	R(n, x - 3, y - 32 + b, 1, 4, Color("#2c2018")); R(n, x + 1, y - 32 + b, 1, 4, Color("#2c2018"))   # beard curls
	R(n, x - 5, y - 49 + b, 10, 10, OL)
	R(n, x - 4, y - 48 + b, 8, 8, GOLD); R(n, x - 4, y - 48 + b, 2, 8, GOLD_L); R(n, x + 2, y - 48 + b, 2, 8, GOLD_D)
	R(n, x - 1, y - 48 + b, 1, 6, GOLD_D)                                                # fluting
	R(n, x - 4, y - 45 + b, 8, 1, GOLD_D); R(n, x - 4, y - 42 + b, 8, 2, CLOTH)          # band and the red fillet
	for cx in [-4, -1, 2]:                                                               # crenellated top
		R(n, x + cx, y - 50 + b, 2, 1, OL); R(n, x + cx, y - 49 + b, 2, 1, GOLD_L)

# a low side wall beside a flight of steps (terrain.gd steps()): its stone cap steps down with the flight, and it ends in a newel post
# with a gold ball. (x, y0) = top-left of the 8 px wide footprint, y1 = its south end on the floor, steps = how many steps it runs beside.
static func stair_cheek(n, x: float, y0: float, y1: float, steps: int) -> void:
	Props.shadow(n, x + 6, y1 + 1, 8, 3)
	R(n, x - 1, y0, 10, y1 - y0, OL)
	var seg := floorf((y1 - y0) / steps)
	for k in range(steps):
		var by := y0 + k * seg
		R(n, x, by, 8, seg - 1, IW_L); R(n, x, by, 8, 2, IW_LL); R(n, x, by, 1, seg - 1, IW_LL); R(n, x + 6, by, 2, seg - 1, IW_D)
		R(n, x, by + seg - 1, 8, 1, IW_DD)          # the drop to the next, lower piece of the cap
	# newel post: cap, front face with a gold band, a gold ball on top
	var px := x - 1.0
	R(n, px - 1, y1 - 15, 12, 16, OL)
	R(n, px, y1 - 14, 10, 4, IW_LL); R(n, px, y1 - 11, 10, 1, IW_L)
	R(n, px, y1 - 10, 10, 10, IW); R(n, px, y1 - 10, 2, 10, IW_L); R(n, px + 8, y1 - 10, 2, 10, IW_D)
	R(n, px + 1, y1 - 7, 8, 1, GOLD_D); R(n, px, y1 - 2, 10, 2, IW_DD)
	n.draw_colored_polygon(Props.ell(x + 4, y1 - 18, 4.0, 4.0, 12), OL)
	n.draw_colored_polygon(Props.ell(x + 4, y1 - 18, 3.0, 3.0, 12), GOLD)
	R(n, x + 2, y1 - 20, 2, 2, GOLD_L)

# bookcase against a wall (front view). (x, y) = centre of the base, 40 wide, 56 tall
static func bookshelf(n, x: float, y: float) -> void:
	Props.shadow(n, x + 3, y + 1, 21, 3)
	R(n, x - 21, y - 58, 42, 59, OL)
	R(n, x - 20, y - 57, 40, 57, WOOD_D)
	R(n, x - 20, y - 57, 40, 3, WOOD_L); R(n, x - 20, y - 59, 40, 2, GOLD_D)
	var cols := [Color("#8a2e2a"), Color("#2a4a6a"), Color("#3a6a3a"), Color("#c9a227"), Color("#6a3a6a"), Color("#e0d0a8"), Color("#a8623a")]
	var seed_i := int(x) * 7
	for row in range(4):
		var ry := y - 53 + row * 13
		R(n, x - 19, ry + 11, 38, 2, WOOD)
		var bx := x - 18.0
		var k := 0
		while bx < x + 17:
			var bw := 2.0 + float((seed_i + k * 5 + row * 3) % 3)
			var bh := 8.0 + float((seed_i + k * 3 + row) % 3)
			if row == 3 and k % 4 == 2:       # a rolled scroll instead of a book
				R(n, bx, ry + 8, 5, 3, Color("#e8dcc0")); R(n, bx, ry + 8, 1, 3, Color("#b8a880"))
				bx += 5.0
			else:
				R(n, bx, ry + 11 - bh, bw, bh, cols[(seed_i + k * 2 + row) % cols.size()])
				R(n, bx, ry + 11 - bh, 1, bh, Color(1, 1, 1, 0.18))
				bx += bw + 0.0
			k += 1
	R(n, x - 20, y - 2, 40, 2, WOOD_D)

# a plain wooden chair. facing: "left" / "right" (the way the sitter looks) or "down"
static func chair(n, x: float, y: float, facing: String) -> void:
	Props.shadow(n, x + 2, y + 1, 6, 2)
	R(n, x - 5, y - 9, 10, 10, OL); R(n, x - 4, y - 8, 8, 8, WOOD); R(n, x - 4, y - 8, 8, 2, WOOD_L)
	R(n, x - 3, y - 6, 6, 5, CLOTH); R(n, x - 3, y - 6, 6, 1, RED_L)
	if facing == "right":
		R(n, x - 6, y - 15, 3, 14, OL); R(n, x - 5, y - 14, 2, 12, WOOD_D)
	elif facing == "left":
		R(n, x + 4, y - 15, 3, 14, OL); R(n, x + 4, y - 14, 2, 12, WOOD_D)
	else:
		R(n, x - 5, y - 15, 10, 3, OL); R(n, x - 4, y - 14, 8, 2, WOOD_D)

# a candelabra of three flames standing on a table
static func candelabra(n, x: float, y: float) -> void:
	var t := Props.now()
	R(n, x - 2, y - 2, 5, 2, GOLD_D); R(n, x, y - 9, 1, 8, GOLD)
	R(n, x - 4, y - 9, 9, 1, GOLD); R(n, x - 4, y - 11, 1, 3, GOLD); R(n, x + 4, y - 11, 1, 3, GOLD)
	for fx in [-4, 0, 4]:
		var fl := int(t * 8.0 + x + fx) % 3
		R(n, x + fx, y - 14 - (fl if fx == 0 else 0), 1, 3, Color("#ffd060"))
		R(n, x + fx, y - 15 - (fl if fx == 0 else 0), 1, 1, Color("#e8742a"))

# the long dining table, seen from above: dark wood, a red runner, plates, goblets and candelabras. (x, y) = top-left
static func long_table(n, x: float, y: float, w: float, h: float) -> void:
	Props.shadow(n, x + w / 2.0 + 4, y + h + 2, w / 2.0 + 6, 5)
	R(n, x - 1, y - 1, w + 2, h + 8, OL)
	R(n, x, y, w, h, WOOD); R(n, x, y, w, 2, WOOD_L); R(n, x, y, 2, h, WOOD_L)
	R(n, x, y + h, w, 6, WOOD_D); R(n, x, y + h + 4, w, 2, OL)          # front edge
	R(n, x + w / 2.0 - 7, y + 3, 14, h - 6, CLOTH_D); R(n, x + w / 2.0 - 6, y + 3, 12, h - 6, CLOTH)
	R(n, x + w / 2.0 - 6, y + 3, 1, h - 6, GOLD); R(n, x + w / 2.0 + 5, y + 3, 1, h - 6, GOLD)
	var py := y + 14.0
	while py < y + h - 12.0:
		for side in [-1, 1]:
			var px: float = x + w / 2.0 + side * 15.0 - 3.0
			R(n, px, py, 7, 7, Color("#e8e0c8")); R(n, px + 1, py + 1, 5, 5, Color("#cfc6a8"))
			R(n, px + (-3 if side < 0 else 8), py + 1, 2, 4, GOLD)
		py += 28.0

# a round table with scrolls, a book and a candle. (x, y) = centre
static func round_table(n, x: float, y: float) -> void:
	Props.shadow(n, x + 4, y + 8, 28, 8)
	n.draw_colored_polygon(Props.ell(x, y + 6, 27.0, 14.0, 20), OL)
	n.draw_colored_polygon(Props.ell(x, y + 6, 26.0, 13.0, 20), WOOD_D)
	n.draw_colored_polygon(Props.ell(x, y, 26.0, 13.0, 20), OL)
	n.draw_colored_polygon(Props.ell(x, y, 25.0, 12.0, 20), WOOD)
	n.draw_colored_polygon(Props.ell(x - 2, y - 1, 18.0, 8.0, 18), WOOD_L)
	R(n, x - 15, y - 5, 12, 8, Color("#e8dcc0")); R(n, x - 15, y - 5, 12, 1, Color("#fff4d8")); R(n, x - 13, y - 2, 8, 1, Color("#8a7a5a")); R(n, x - 13, y, 6, 1, Color("#8a7a5a"))
	R(n, x + 2, y - 4, 11, 7, OL); R(n, x + 3, y - 3, 9, 5, Color("#2a4a6a")); R(n, x + 3, y - 3, 9, 1, Color("#4a6a8a")); R(n, x + 3, y + 1, 9, 1, GOLD)
	R(n, x + 14, y - 8, 3, 6, Color("#f0e8d0")); R(n, x + 15, y - 11 - (int(Props.now() * 8.0) % 2), 1, 3, Color("#ffd060"))
	R(n, x - 20, y + 1, 8, 2, Color("#e8dcc0")); R(n, x - 20, y + 1, 1, 2, Color("#b8a880"))

# a writing desk with a parchment, an inkwell and a quill. (x, y) = centre of the front edge, 38 wide
static func desk(n, x: float, y: float) -> void:
	Props.shadow(n, x + 3, y + 1, 21, 4)
	R(n, x - 19, y - 16, 38, 17, OL)
	R(n, x - 18, y - 15, 36, 8, WOOD_L); R(n, x - 18, y - 15, 36, 1, Color("#c8905a"))
	R(n, x - 18, y - 7, 36, 7, WOOD); R(n, x - 18, y - 7, 36, 1, WOOD_D)
	R(n, x - 16, y - 5, 14, 4, WOOD_D); R(n, x + 2, y - 5, 14, 4, WOOD_D)
	R(n, x - 12, y - 14, 14, 7, Color("#e8dcc0")); R(n, x - 10, y - 12, 9, 1, Color("#8a7a5a")); R(n, x - 10, y - 10, 7, 1, Color("#8a7a5a"))
	R(n, x + 6, y - 13, 4, 5, Color("#222222")); R(n, x + 7, y - 13, 2, 1, Color("#5a5a6a"))
	R(n, x + 9, y - 21, 1, 9, Color("#f0e8d0")); R(n, x + 10, y - 21, 1, 4, Color("#c8b890"))

# a clay tablet lying on Utana's desk (Stage 7j, hall.gd TABLET): sun-dried clay with rows of wedge marks pressed into it.
# glint = the short flash that marks it as something to read. (x, y) = the middle of its bottom edge
static func clay_tablet(n, x: float, y: float, glint: bool) -> void:
	R(n, x - 5, y - 7, 10, 7, OL)
	R(n, x - 4, y - 6, 8, 5, Color("#b8855a")); R(n, x - 4, y - 6, 8, 1, Color("#d8a878")); R(n, x - 4, y - 2, 8, 1, Color("#8a5a38"))
	for row in range(2):                                         # the writing: two rows of small wedges
		for k in range(3):
			R(n, x - 3 + k * 2 + row, y - 5 + row * 2, 1, 1, Color("#5a3a20"))
	if glint:
		var c := Color(1, 1, 0.9, 0.95)
		R(n, x - 4, y - 11, 1, 5, c); R(n, x - 6, y - 9, 5, 1, c)

# a standing globe on a wooden stand. (x, y) = foot
static func globe(n, x: float, y: float) -> void:
	Props.shadow(n, x + 3, y + 1, 9, 3)
	R(n, x - 6, y - 4, 13, 5, OL); R(n, x - 5, y - 3, 11, 3, WOOD)
	R(n, x - 1, y - 14, 3, 11, OL); R(n, x, y - 13, 1, 10, WOOD_L)
	n.draw_colored_polygon(Props.ell(x, y - 21, 10.0, 10.0, 18), OL)
	n.draw_colored_polygon(Props.ell(x, y - 21, 9.0, 9.0, 18), Color("#3a6a9a"))
	n.draw_colored_polygon(Props.ell(x - 2, y - 22, 5.0, 4.0, 10), Color("#7a9a4a"))
	n.draw_colored_polygon(Props.ell(x + 3, y - 19, 3.0, 3.0, 8), Color("#c8a85a"))
	R(n, x - 6, y - 25, 3, 2, Color(1, 1, 1, 0.35))
	R(n, x - 11, y - 21, 22, 1, GOLD_D)
