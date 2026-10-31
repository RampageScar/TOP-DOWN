extends RefCounted
# sprites.gd - code-drawn characters. Everything draws through these functions,
# so PNG sprite sheets can replace them later without touching movement or combat.

const BASE := {
	"hair": "#5a3a22", "skin": "#e0b088", "skinD": "#c28f68",
	"jac": "#7a4a26", "jacD": "#5a3418", "pants": "#85858c", "pantsD": "#66666d",
	"boot": "#3f2816", "strap": "#b78443", "bag": "#9a6a35", "bagD": "#6e4720",
	"satchel": true, "robe": false, "hat": ""
}

# NPC looks (placeholders; no names here)
const PALETTES := {
	"keeper": {"jac": "#6a3b2a", "jacD": "#4a2519", "robe": true, "hair": "#2a2a2a", "hat": "#d8d0b8", "satchel": false},
	"scribe": {"jac": "#3d5a6a", "jacD": "#2a4050", "robe": true, "hair": "#222222", "skin": "#c99a70", "satchel": false},
	"guard": {"jac": "#8a2e2a", "jacD": "#611d1a", "pants": "#4a4a52", "hair": "#3a2a1a", "hat": "#8a8f99", "satchel": false},
	"villager": {"jac": "#8c7a3a", "jacD": "#665726", "robe": true, "hair": "#1f1a14", "satchel": false},
	"datis": {"jac": "#7a2a26", "jacD": "#561a18", "pants": "#4a4a52", "hair": "#a8a8a8", "hat": "#8a8f99", "satchel": false},
	"carrier": {"jac": "#4a7a8a", "jacD": "#325a68", "robe": true, "hair": "#2a2a2a", "hat": "#d8d0b8", "satchel": false},
	"potter": {"jac": "#b8744a", "jacD": "#8a5232", "robe": true, "hair": "#3a2a1a", "skin": "#c99a70", "satchel": false},
	"handler": {"jac": "#6a7a3a", "jacD": "#4a5726", "robe": true, "hair": "#222222", "hat": "#b04a3a", "satchel": false},
	"cook": {"jac": "#e0d8c0", "jacD": "#b8b098", "robe": true, "hair": "#3a2a1a", "hat": "#f0ead8", "satchel": false},
	"traveller": {"jac": "#5a4a7a", "jacD": "#3e3258", "robe": true, "hair": "#2a1f14", "hat": "#d8d0b8", "satchel": false},
	"bandit": {"jac": "#4a3a2c", "jacD": "#2e231a", "pants": "#8a6a45", "pantsD": "#6a4e30", "hair": "#1a1410", "hat": "#c0392b", "skin": "#c99a70", "satchel": false},
	"bandit2": {"jac": "#5a2c24", "jacD": "#3a1c16", "pants": "#6a5a48", "pantsD": "#4e4234", "hair": "#241810", "hat": "#c0392b", "skin": "#b88a62", "satchel": false},
	"bandit3": {"jac": "#3a3a30", "jacD": "#26261e", "pants": "#7a5a3a", "pantsD": "#5a422a", "hair": "#14100c", "hat": "#c0392b", "skin": "#d0a478", "satchel": false},
	"king": {"jac": "#5a2a7a", "jacD": "#3e1a58", "robe": true, "hair": "#1c1410", "hat": "#e8b838", "skin": "#d8aa80", "satchel": false},
	"royal": {"jac": "#7a1f1c", "jacD": "#521412", "pants": "#3a3a42", "hair": "#2a1a10", "hat": "#d9a838", "skin": "#c99a70", "satchel": false},
	"child": {"jac": "#c05a3a", "jacD": "#8a3e26", "pants": "#d8d0b8", "pantsD": "#b8b098", "hair": "#1f1a14", "satchel": false},
	# the great hall: a servant in Median dress (tunic, trousers, soft cap, as the servants on the Persepolis reliefs), a scholar in a long robe
	"servant": {"jac": "#9a7a4a", "jacD": "#74582f", "pants": "#5a4632", "pantsD": "#433424", "hair": "#2a1a10", "hat": "#e0d4b0", "skin": "#c99a70", "satchel": false},
	"scholar": {"jac": "#2e3a6a", "jacD": "#1f2850", "robe": true, "hair": "#9a9a98", "hat": "#ece6d6", "skin": "#d0a478", "satchel": false},
	# the cave: a captured royal rider in Persian riding dress (belted tunic, trousers, a soft felt hood), his bow taken from him
	"rider": {"jac": "#7a2e22", "jacD": "#521c16", "pants": "#6a5238", "pantsD": "#4e3c28", "hair": "#2a1a10", "hat": "#c9b48a", "skin": "#c99a70", "satchel": false},
	# the riders' captain, staked in the boss room: the same riding dress, torn and darkened, grey in his hair, his hood gone
	"captain": {"jac": "#5e2620", "jacD": "#3e1612", "pants": "#5a4632", "pantsD": "#3e3020", "hair": "#6a645c", "skin": "#b88a62", "satchel": false},
	# the band's chief (drawn 1.3x, with a fur and a sagaris by chief.gd): dark wool and a dark felt cap; his slingers in drab tunics
	"chief": {"jac": "#2e2622", "jacD": "#1c1614", "pants": "#4a3a2a", "pantsD": "#33281c", "hair": "#120c08", "hat": "#4a3a2c", "skin": "#b88a62", "satchel": false},
	"slinger": {"jac": "#6a5a3a", "jacD": "#4a3e26", "pants": "#5a4a38", "pantsD": "#423628", "hair": "#1a1410", "hat": "#8a3a2a", "skin": "#c99a70", "satchel": false},
}

static func R(n, x, y, w, h, c: Color) -> void:
	n.draw_rect(Rect2(roundf(x), roundf(y), roundf(w), roundf(h)), c)

static func K(h: String) -> Color:
	return Color.html(h)

# Generic ~16x24 person. Feet at (x, y).
static func person(n, x: float, y: float, dir: String, frame: int, moving: bool, pal: Dictionary) -> void:
	if dir == "left":
		n.draw_set_transform(Vector2(x, 0), 0.0, Vector2(-1, 1))
		person(n, 0.0, y, "right", frame, moving, pal)
		n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var p: Dictionary = BASE.duplicate()
	p.merge(pal, true)
	var hair := K(p["hair"]); var skin := K(p["skin"]); var skin_d := K(p["skinD"])
	var jac := K(p["jac"]); var jac_d := K(p["jacD"])
	var pants := K(p["pants"]); var pants_d := K(p["pantsD"]); var boot := K(p["boot"])
	var strap := K(p["strap"]); var bag := K(p["bag"]); var bag_d := K(p["bagD"])
	var satchel: bool = p["satchel"]
	var robe: bool = p["robe"]
	var hat: String = p["hat"]

	x = roundf(x); y = roundf(y)
	var f := (frame % 4 + 4) % 4 if moving else 0
	var lift1 := 2 if f == 1 else 0
	var lift2 := 2 if f == 3 else 0
	var by := y - (1 if f % 2 == 1 else 0)
	var a1 := 1 if f == 1 else (-1 if f == 3 else 0)
	R(n, x - 6, y - 1, 12, 2, Color(0, 0, 0, 0.25))

	if dir == "down" or dir == "up":
		R(n, x - 4, y - 6, 3, 6 - lift1, pants); R(n, x - 4, y - 2 - lift1, 3, 2, boot)
		R(n, x + 1, y - 6, 3, 6 - lift2, pants); R(n, x + 1, y - 2 - lift2, 3, 2, boot)
		if robe:
			R(n, x - 5, by - 9, 10, 8, jac)
		R(n, x - 5, by - 16, 10, 10, jac); R(n, x - 5, by - 8, 10, 2, jac_d)
		R(n, x - 7, by - 15 + a1, 2, 8, jac); R(n, x - 7, by - 7 + a1, 2, 2, skin)
		R(n, x + 5, by - 15 - a1, 2, 8, jac); R(n, x + 5, by - 7 - a1, 2, 2, skin)
		if dir == "down":
			if satchel:
				for i in range(9):
					R(n, x - 4 + i, by - 16 + i, 1, 2, strap)
				R(n, x + 3, by - 10, 5, 5, bag); R(n, x + 3, by - 10, 5, 1, bag_d)
			R(n, x - 4, by - 24, 8, 8, skin)
			R(n, x - 4, by - 25, 8, 4, hair); R(n, x - 5, by - 24, 1, 4, hair); R(n, x + 4, by - 24, 1, 4, hair)
			R(n, x - 2, by - 27, 2, 2, hair); R(n, x + 1, by - 26, 3, 1, hair)
			R(n, x - 2, by - 19, 1, 2, Color("#222222")); R(n, x + 1, by - 19, 1, 2, Color("#222222"))
		else:
			if satchel:
				R(n, x - 3, by - 13, 6, 6, bag); R(n, x - 3, by - 13, 6, 1, bag_d)
				for i in range(9):
					R(n, x + 4 - i, by - 16 + i, 1, 2, strap)
			R(n, x - 4, by - 25, 8, 8, hair); R(n, x - 1, by - 17, 2, 1, skin)
			R(n, x - 2, by - 27, 2, 2, hair); R(n, x + 1, by - 26, 3, 1, hair)
		if hat != "":
			R(n, x - 5, by - 27, 10, 3, K(hat))
		return

	# side view, facing right
	var off: int = [0, 2, 0, -2][f]
	R(n, x - 2 - off, y - 6, 3, 4, pants_d); R(n, x - 2 - off, y - 2, 4, 2, boot)
	R(n, x - 1 + off, y - 6, 3, 4, pants); R(n, x - 1 + off, y - 2, 4, 2, boot)
	if robe:
		R(n, x - 4, by - 9, 8, 8, jac)
	if satchel:
		R(n, x - 6, by - 12, 4, 6, bag)
	R(n, x - 3, by - 16, 6, 10, jac); R(n, x - 3, by - 8, 6, 2, jac_d)
	if satchel:
		R(n, x - 6, by - 12, 4, 1, bag_d)
		for i in range(7):
			R(n, x - 3 + i, by - 16 + i, 1, 1, strap)
	var ax := x - 1 + roundf(off / 2.0)
	R(n, ax, by - 15, 2, 8, jac_d); R(n, ax, by - 7, 2, 2, skin)
	R(n, x - 3, by - 24, 7, 8, skin)
	R(n, x - 4, by - 25, 8, 4, hair); R(n, x - 4, by - 24, 3, 8, hair)
	R(n, x - 2, by - 27, 2, 2, hair); R(n, x + 1, by - 26, 3, 1, hair)
	R(n, x + 2, by - 20, 1, 2, Color("#222222")); R(n, x + 4, by - 19, 1, 1, skin_d)
	if hat != "":
		R(n, x - 4, by - 27, 9, 3, K(hat))

static func rat(n, x: float, y: float, flip: int, anim: float, scale: float, eat := 0.0) -> void:
	n.draw_set_transform(Vector2(roundf(x), roundf(y)), 0.0, Vector2(scale * flip, scale))
	var body := K("#7a6652"); var belly := K("#a58d72"); var dark := K("#4d3f31"); var pink := K("#d9a0a0")
	var f := int(anim) % 2
	R(n, -8, 0, 16, 1, Color(0, 0, 0, 0.25))
	R(n, -12, -4, 5, 1, pink); R(n, -15, -6, 3, 1, pink); R(n, -17, -7, 2, 1, pink)
	var hy := 0                                 # eating: the head dips and bobs
	if eat > 0.0:
		hy = 1 + int(anim) % 2
	R(n, -8, -8, 13, 7, body); R(n, -7, -3, 11, 2, belly)
	R(n, 4, -7 + hy, 6, 5, body); R(n, 10, -5 + hy, 2, 2, body); R(n, 11, -5 + hy, 1, 1, K("#c97a7a"))
	R(n, 4, -9 + hy, 2, 2, pink); R(n, 7, -9 + hy, 2, 2, pink)
	R(n, 8, -6 + hy, 1, 1, K("#111111"))
	R(n, -6, -1, 2, 1 + f, dark); R(n, 2, -1, 2, 2 - f, dark)
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# the scorpion's tail, from where it leaves the body to the stinger (the last point), facing right: resting curled over its back,
# arched over its head (the sting's wind-up), and struck forward (the sting). sprites.gd scorpion blends between them.
const TAIL_REST := [Vector2(-9, -5), Vector2(-12, -7), Vector2(-13, -10), Vector2(-11, -13), Vector2(-8, -14), Vector2(-5, -13)]
const TAIL_UP := [Vector2(-9, -6), Vector2(-11, -10), Vector2(-10, -14), Vector2(-6, -17), Vector2(-2, -17), Vector2(1, -15)]
const TAIL_STRIKE := [Vector2(-9, -6), Vector2(-9, -10), Vector2(-6, -13), Vector2(-2, -13), Vector2(2, -12), Vector2(6, -10)]

# A desert scorpion seen from the side (Stage 7j), about 26 x 17: the jointed back, one claw held forward, legs stepping in two sets,
# the tail curled up over its back. tail = 0 at rest, 1 arched over its head, 2 struck forward. Feet at (x, y), facing right (flip -1).
static func scorpion(n, x: float, y: float, flip: int, anim: float, tail: float) -> void:
	n.draw_set_transform(Vector2(roundf(x), roundf(y)), 0.0, Vector2(flip, 1))
	var ol := K("#2e1c0c"); var body := K("#9a6a2a"); var lit := K("#c89048"); var dark := K("#5e3e18")
	var f := int(anim) % 2
	R(n, -10, 0, 22, 1, Color(0, 0, 0, 0.25))
	for i in range(4):                                                       # legs, two sets stepping in turn
		var up := (i + f) % 2
		R(n, -6 + i * 3, -2 + up, 1, 2 - up, ol); R(n, -5 + i * 3, -1, 1, 1, dark)
	R(n, -9, -7, 15, 6, ol)                                                  # the back: segments, lit from above
	R(n, -8, -6, 13, 4, body); R(n, -8, -6, 13, 1, lit)
	for sx in [-5, -2, 1]:
		R(n, sx, -5, 1, 3, dark)
	R(n, 5, -6, 5, 5, ol); R(n, 5, -5, 4, 3, body); R(n, 5, -5, 4, 1, lit)  # the head and an eye
	R(n, 8, -5, 1, 1, K("#111111"))
	R(n, 9, -4, 3, 2, ol); R(n, 9, -4, 2, 1, body)                           # the claw: arm, pincer, its two fingers
	R(n, 11, -6, 4, 4, ol); R(n, 12, -5, 2, 2, lit)
	R(n, 15, -6, 2, 1, ol); R(n, 15, -3, 2, 1, ol)
	var a: Array = TAIL_REST if tail <= 1.0 else TAIL_UP
	var b: Array = TAIL_UP if tail <= 1.0 else TAIL_STRIKE
	var k := clampf(tail if tail <= 1.0 else tail - 1.0, 0.0, 1.0)
	for i in range(a.size()):
		var p: Vector2 = (a[i] as Vector2).lerp(b[i], k).round()
		if i < a.size() - 1:                                                 # a segment
			R(n, p.x - 2, p.y - 2, 4, 4, ol); R(n, p.x - 1, p.y - 1, 3, 3, body); R(n, p.x - 1, p.y - 1, 3, 1, lit)
		else:                                                                # the stinger, its tip pointing down and forward
			R(n, p.x - 1, p.y - 1, 3, 3, ol); R(n, p.x, p.y, 2, 2, dark); R(n, p.x + 2, p.y + 2, 1, 1, ol)
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func heart(n, x: float, y: float, c: Color) -> void:
	var rows := [".xx.xx.", "xxxxxxx", "xxxxxxx", ".xxxxx.", "..xxx..", "...x..."]
	for j in range(rows.size()):
		for i in range(7):
			if rows[j][i] == "x":
				R(n, x + i, y + j, 1, 1, c)

# ---- Stage 2 additions: camel, lizard, sleeping traveller ----
static func camel(n, x: float, y: float, flip: int, anim: float) -> void:
	n.draw_set_transform(Vector2(roundf(x), roundf(y)), 0.0, Vector2(flip, 1))
	var t := K("#c9965a"); var d := K("#a3763c"); var l := K("#e0b97a"); var dk := K("#4a3320")
	var f := int(anim) % 2
	R(n, -15, 0, 30, 2, Color(0, 0, 0, 0.25))
	R(n, -7, -10, 3, 10, d); R(n, 5, -10, 3, 10, d)           # far legs
	R(n, -12, -10, 3, 10, t); R(n, 9, -10, 3, 10, t)          # near legs
	R(n, -12, -2, 3, 2, dk); R(n, 9, -2, 3, 2, dk); R(n, -7, -2, 3, 2, dk); R(n, 5, -2, 3, 2, dk)
	R(n, -14, -20, 28, 11, t); R(n, -14, -11, 28, 2, d)
	R(n, -6, -26, 9, 6, t); R(n, -6, -26, 9, 1, l)
	R(n, -5, -20, 10, 8, K("#b04a3a")); R(n, -5, -16, 10, 2, K("#e8dcc0"))
	R(n, 10, -30, 5, 12, t); R(n, 12, -34, 9, 5, t); R(n, 19, -32 + f, 3, 4, l)
	R(n, 15, -33, 1, 1, dk); R(n, 13, -36, 2, 2, d)
	R(n, -16, -19, 2, 8, d); R(n, -17 + f, -12, 2, 3, dk)
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func lizard(n, x: float, y: float, flip: int, anim: float) -> void:
	n.draw_set_transform(Vector2(roundf(x), roundf(y)), 0.0, Vector2(flip, 1))
	var g := K("#6a8a3a"); var gd := K("#4a6a28")
	var f := int(anim) % 2
	R(n, -3, 0, 7, 1, Color(0, 0, 0, 0.2))
	R(n, -3, -2, 6, 2, g); R(n, 3, -3, 3, 3, g); R(n, 5, -2, 1, 1, K("#111111"))
	R(n, -8, -1, 5, 1, gd); R(n, -10 + f, -2, 2, 1, gd)
	R(n, -2, 0, 1, 1 + f, gd); R(n, 1, 0, 1, 2 - f, gd)
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func sleeper(n, x: float, y: float, pal: Dictionary) -> void:
	x = roundf(x); y = roundf(y)
	var p: Dictionary = BASE.duplicate()
	p.merge(pal, true)
	n.draw_colored_polygon(_ellipse(Vector2(x, y - 1), 26.0, 8.0), Color(0, 0, 0, 0.12))
	R(n, x - 13, y - 4, 26, 6, K("#8a3b2a")); R(n, x - 13, y - 4, 26, 1, K("#a8503a"))
	R(n, x - 14, y - 7, 6, 3, K(p["boot"])); R(n, x - 9, y - 8, 12, 5, K(p["pants"]))
	R(n, x + 2, y - 10, 11, 6, K(p["jac"])); R(n, x + 2, y - 10, 11, 1, K(p["jacD"]))
	R(n, x + 12, y - 11, 6, 6, K(p["skin"])); R(n, x + 12, y - 12, 6, 3, K(p["hair"]))
	R(n, x + 11, y - 13, 8, 3, K(p["hat"]) if p["hat"] != "" else K(p["hair"]))
	R(n, x - 2, y - 3, 8, 3, K(p["bag"]))

static func _ellipse(c: Vector2, w: float, h: float, steps := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * i / steps
		pts.append(Vector2(c.x + cos(a) * w / 2.0, c.y + sin(a) * h / 2.0))
	return pts
