extends RefCounted
# props.gd - drawing functions for everything that stands up in the world (trees, pillars, walls, houses, torches ...).
# All use absolute world coordinates (the prop node is "rebased", see drawn.gd). n is the node being drawn on.
# Look: dark brown outline, three tones per material, light from the top-left, soft shadow to the bottom-right.

const OL := Color("#3a2517")
const SH := Color(0.24, 0.13, 0.04, 0.26)

# sandstone (pillars, ruins)
const ST := Color("#cfae7c")
const ST_L := Color("#e8cf9c")
const ST_D := Color("#a58358")
const ST_DD := Color("#7a5b3b")
# adobe (town buildings)
const AD_TOP := Color("#e6c48c")
const AD_TOP_D := Color("#cba46c")
const AD_FACE := Color("#c9965a")
const AD_FACE_L := Color("#dba96c")
const AD_FACE_D := Color("#a87440")
const AD_FACE_DD := Color("#80542c")
const DOOR := Color("#2a1810")
# wood
const WD := Color("#8a5a32")
const WD_L := Color("#b07a46")
const WD_D := Color("#5e3a1e")
# town wall stone
const WL := Color("#c9a06a")
const WL_L := Color("#e2bf86")
const WL_D := Color("#a07a48")
const WL_DD := Color("#745230")
const RED := Color("#b8372b")
const RED_D := Color("#8a251d")
const GOLD := Color("#e8b838")

static func R(n, x: float, y: float, w: float, h: float, c) -> void:
	var col: Color = Color.html(c) if c is String else c
	n.draw_rect(Rect2(roundf(x), roundf(y), roundf(w), roundf(h)), col)

# outlined box with light top-left edges and dark bottom-right edges
static func ob(n, x: float, y: float, w: float, h: float, fill, hi, lo) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y, w, h, fill)
	R(n, x, y, w, 1, hi); R(n, x, y, 1, h, hi)
	R(n, x, y + h - 1, w, 1, lo); R(n, x + w - 1, y, 1, h, lo)

static func ell(cx: float, cy: float, rx: float, ry: float, steps := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * i / steps
		pts.append(Vector2(roundf(cx + cos(a) * rx), roundf(cy + sin(a) * ry)))
	return pts

static func shadow(n, cx: float, cy: float, rx: float, ry: float) -> void:
	n.draw_colored_polygon(ell(cx, cy, rx, ry), SH)

static func blob(n, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	n.draw_colored_polygon(ell(cx, cy, rx, ry, 16), c)

static func now() -> float:
	return Time.get_ticks_msec() / 1000.0

# ------------------------------------------------------------------ rocks
static func rock(n, x: float, y: float, w: float, h: float) -> void:
	shadow(n, x + w / 2.0 + 3, y + h, w / 2.0 + 2, 3)
	R(n, x - 1, y + 1, w + 2, h, OL); R(n, x + 1, y - 1, w - 2, h + 2, OL)
	R(n, x, y + 2, w, h - 2, Color("#8a6444")); R(n, x + 1, y, w - 2, 4, Color("#c49a6c"))
	R(n, x + 1, y, w - 5, 1, Color("#dcb384")); R(n, x, y + 3, 2, h - 8, Color("#a8805a"))
	R(n, x, y + h - 4, w, 3, Color("#5e4129")); R(n, x + w - 3, y + 4, 2, h - 8, Color("#6e4d32"))
	R(n, x + 4, y + 6, 1, 3, Color("#4a3322")); R(n, x + w - 8, y + 5, 3, 1, Color("#d6b88c"))

# ------------------------------------------------------------------ plants
# bushy desert tree (olive / acacia style). kind 0 = green, 1 = olive-yellow
static func tree(n, x: float, y: float, s: float, kind: int, animated: bool) -> void:
	var t := now()
	var sw := roundf(sin(t * 1.3 + x * 0.05)) if animated else 0.0
	var d1 := Color("#2c5a2a") if kind == 0 else Color("#4a5a22")
	var d2 := Color("#43812f") if kind == 0 else Color("#6f8a2e")
	var d3 := Color("#76ad41") if kind == 0 else Color("#a2b445")
	var d4 := Color("#a8d65a") if kind == 0 else Color("#cbd266")
	shadow(n, x + 5, y + 1, 15.0 * s, 4.0 * s)
	# trunk
	R(n, x - 3, y - 15 * s, 7, 15 * s + 1, OL)
	R(n, x - 2, y - 15 * s, 5, 15 * s, Color("#6e4526")); R(n, x - 2, y - 15 * s, 2, 15 * s, Color("#92623a"))
	R(n, x - 5, y - 2, 11, 3, OL); R(n, x - 4, y - 2, 9, 2, Color("#6e4526"))
	R(n, x + 1, y - 22 * s, 3, 9 * s, OL); R(n, x + 1, y - 22 * s, 2, 9 * s, Color("#6e4526"))
	var cy := y - 24.0 * s
	# canopy: outline then 3 layers of clustered blobs
	var cl := [[-11, 3, 11, 8], [10, 4, 11, 8], [0, -3, 14, 10], [-12, -6, 9, 7], [11, -6, 9, 7], [-3, -12, 11, 8], [6, -11, 8, 6]]
	for c in cl:
		blob(n, x + c[0] * s + sw, cy + c[1] * s, c[2] * s + 1.5, c[3] * s + 1.5, OL)
	for c in cl:
		blob(n, x + c[0] * s + sw, cy + c[1] * s, c[2] * s, c[3] * s, d1)
	for c in cl:
		blob(n, x + c[0] * s + sw - 1, cy + c[1] * s - 2, c[2] * s * 0.82, c[3] * s * 0.72, d2)
	for c in cl:
		blob(n, x + c[0] * s + sw - 2, cy + c[1] * s - 3, c[2] * s * 0.5, c[3] * s * 0.4, d3)
	blob(n, x - 5 * s + sw, cy - 8 * s, 4.0 * s, 2.5 * s, d4)
	blob(n, x + 6 * s + sw, cy - 6 * s, 3.0 * s, 2.0 * s, d4)
	for i in range(7):
		R(n, x - 14 * s + i * 4.6 * s + sw, cy - 2 * s + (i % 3) * 4 * s, 2, 2, d1)
	if kind == 1:
		R(n, x - 6 * s + sw, cy + 4 * s, 2, 2, Color("#d9a63a")); R(n, x + 8 * s + sw, cy - 1 * s, 2, 2, Color("#d9a63a"))

# tall date palm with swaying fronds
static func palm(n, x: float, y: float, h: float, lean: float, animated: bool) -> void:
	var t := now()
	var sw := sin(t * 1.4 + x * 0.07) if animated else 0.0
	shadow(n, x + 6, y + 1, 12, 3)
	# curved trunk made of short rings
	var segs := int(h / 4.0)
	var px := x
	var py := y
	for i in range(segs):
		var u := float(i) / segs
		var bx := x + lean * u * u * 14.0
		R(n, bx - 3, y - i * 4 - 4, 7, 5, OL)
	for i in range(segs):
		var u := float(i) / segs
		var bx := x + lean * u * u * 14.0
		var w := 5 - int(u * 1.5)
		R(n, bx - 2, y - i * 4 - 4, w, 4, Color("#7a5230") if i % 2 == 0 else Color("#65411f"))
		R(n, bx - 2, y - i * 4 - 4, 1, 4, Color("#a07448"))
		px = bx
		py = y - i * 4 - 4
	# crown
	var cx := px + 1.0
	var cy := py
	R(n, cx - 3, cy - 2, 7, 5, OL); R(n, cx - 2, cy - 1, 5, 3, Color("#5a3a1c"))
	R(n, cx - 4, cy + 2, 2, 3, Color("#7a4a22")); R(n, cx + 2, cy + 2, 2, 3, Color("#7a4a22"))   # dates
	var fr := [[-1.0, -0.15], [-0.8, -0.55], [-0.35, -0.9], [0.1, -1.0], [0.55, -0.85], [0.9, -0.5], [1.0, -0.1], [-0.6, 0.1], [0.65, 0.12]]
	for i in range(fr.size()):
		var dv := Vector2(fr[i][0], fr[i][1])
		var wob := sw * (1.0 + (i % 3) * 0.4)
		var p0 := Vector2(cx, cy)
		var p1 := p0 + dv * 11.0 + Vector2(0, -3.0 + wob * 0.4)
		var p2 := p0 + dv * 21.0 + Vector2(wob * 0.8, 3.0 + absf(dv.x) * 4.0)
		var pts := PackedVector2Array([p0, p1, p2])
		n.draw_polyline(pts, OL, 4.0)
	for i in range(fr.size()):
		var dv := Vector2(fr[i][0], fr[i][1])
		var wob := sw * (1.0 + (i % 3) * 0.4)
		var p0 := Vector2(cx, cy)
		var p1 := p0 + dv * 11.0 + Vector2(0, -3.0 + wob * 0.4)
		var p2 := p0 + dv * 21.0 + Vector2(wob * 0.8, 3.0 + absf(dv.x) * 4.0)
		var pts := PackedVector2Array([p0, p1, p2])
		n.draw_polyline(pts, Color("#2e7a2e"), 2.0)
		n.draw_polyline(PackedVector2Array([p0 + Vector2(0, -1), p1 + Vector2(0, -1), p2 + Vector2(0, -1)]), Color("#7cc04a"), 1.0)

static func cactus(n, x: float, y: float, v: int) -> void:
	shadow(n, x + 4, y, 8, 2)
	var g := Color("#4f8a3a"); var gl := Color("#7cb85a"); var gd := Color("#2f5f2a")
	R(n, x - 4, y - 21, 9, 22, OL); R(n, x - 3, y - 20, 7, 20, g); R(n, x - 3, y - 20, 2, 20, gl); R(n, x + 2, y - 20, 2, 20, gd)
	R(n, x - 1, y - 20, 1, 20, gd)
	if v % 2 == 0:
		R(n, x - 11, y - 14, 8, 6, OL); R(n, x - 10, y - 13, 6, 4, g); R(n, x - 11, y - 20, 5, 12, OL); R(n, x - 10, y - 19, 3, 11, g); R(n, x - 10, y - 19, 1, 10, gl)
	if v % 3 != 0:
		R(n, x + 3, y - 10, 8, 6, OL); R(n, x + 4, y - 9, 6, 4, g); R(n, x + 8, y - 16, 5, 12, OL); R(n, x + 9, y - 15, 3, 11, g); R(n, x + 9, y - 15, 1, 10, gl)
	for i in range(5):
		R(n, x - 2, y - 17 + i * 4, 1, 1, Color("#e8f0c0"))
	R(n, x - 1, y - 23, 3, 2, Color("#e87aa8")); R(n, x, y - 24, 1, 1, Color("#ffd0e0"))

# spiky agave / yucca - the green plants in the sand
static func agave(n, x: float, y: float, s: float, v: int) -> void:
	shadow(n, x + 3, y, 7 * s, 2)
	var tones := [Color("#3f7a34"), Color("#5da048"), Color("#8cc860")]
	for k in range(3):
		var cnt := 8
		for i in range(cnt):
			var a := PI + PI * (i + 0.5) / cnt
			var ln := (8.0 - k * 2.0) * s
			var tip := Vector2(x + cos(a) * ln * 1.25, y - 2 + sin(a) * ln * 1.25)
			n.draw_line(Vector2(x, y - 1), tip, OL if k == 0 else tones[k], 3.0 if k == 0 else 2.0 - k * 0.5)
	for i in range(5):
		var a := PI + PI * (i + 0.5) / 5.0
		n.draw_line(Vector2(x, y - 2), Vector2(x + cos(a) * 5 * s, y - 2 + sin(a) * 5 * s), tones[2], 1.0)
	if v % 3 == 0:
		R(n, x, y - 18 * s, 2, 14 * s, OL); R(n, x, y - 18 * s, 1, 14 * s, Color("#b89a58")); R(n, x - 1, y - 20 * s, 4, 3, Color("#f0e0a0"))

static func dead_tree(n, x: float, y: float, v: int) -> void:
	shadow(n, x + 4, y, 10, 3)
	var c := Color("#5e4a36"); var cl := Color("#8a7256")
	var lines := [[[0, 0], [0, -14], [-3, -24]], [[0, -14], [6, -22], [9, -30]], [[0, -9], [-8, -16], [-13, -17]], [[-1, -19], [3, -27], [1, -33]], [[3, -17], [11, -20]]]
	if v % 2 == 1:
		lines = [[[0, 0], [1, -12], [-1, -22], [-6, -30]], [[1, -12], [8, -19], [12, -28]], [[-1, -18], [5, -26]], [[0, -7], [-9, -12]]]
	for l in lines:
		var pts := PackedVector2Array()
		for p in l:
			pts.append(Vector2(x + p[0], y + p[1]))
		n.draw_polyline(pts, OL, 5.0)
	for l in lines:
		var pts := PackedVector2Array()
		for p in l:
			pts.append(Vector2(x + p[0], y + p[1]))
		n.draw_polyline(pts, c, 3.0)
		var pts2 := PackedVector2Array()
		for p in l:
			pts2.append(Vector2(x + p[0] - 1, y + p[1]))
		n.draw_polyline(pts2, cl, 1.0)

# ------------------------------------------------------------------ ruins
# kind 0 = full pillar, 1 = broken (jagged top), 2 = short stump
static func pillar(n, x: float, y: float, h: float, kind: int, v := 0) -> void:
	shadow(n, x + 8, y + 1, 15, 4)
	# base slab
	R(n, x - 11, y - 7, 22, 9, OL); R(n, x - 10, y - 7, 20, 8, ST); R(n, x - 10, y - 7, 20, 2, ST_L); R(n, x - 10, y - 1, 20, 2, ST_DD)
	R(n, x - 10, y - 7, 2, 8, ST_L); R(n, x + 8, y - 6, 2, 7, ST_D)
	var top := y - h
	if kind == 2:
		top = y - 14.0 - (v % 3) * 3
	# shaft
	R(n, x - 9, top, 18, y - top - 6, OL)
	R(n, x - 8, top, 16, y - top - 7, ST)
	R(n, x - 8, top, 4, y - top - 7, ST_L)
	R(n, x + 3, top, 5, y - top - 7, ST_D)
	R(n, x + 6, top, 2, y - top - 7, ST_DD)
	var gy := top + 2
	while gy < y - 9:
		R(n, x - 2, gy, 1, 5, ST_D)
		R(n, x + 1, gy + 3, 1, 4, ST_DD)
		gy += 9
	# horizontal drum seams
	var sy := y - 20.0
	while sy > top + 3:
		R(n, x - 8, sy, 16, 1, ST_DD); R(n, x - 8, sy + 1, 5, 1, ST_L)
		sy -= 17.0
	if kind == 0:
		# capital
		R(n, x - 12, top - 8, 24, 9, OL); R(n, x - 11, top - 7, 22, 8, ST); R(n, x - 11, top - 7, 22, 2, ST_L)
		R(n, x - 11, top - 1, 22, 2, ST_DD); R(n, x + 8, top - 6, 3, 6, ST_D)
		R(n, x - 9, top + 1, 18, 2, ST_DD)
		R(n, x - 3, top - 4, 6, 2, ST_D)
	elif kind == 1:
		# jagged broken top
		R(n, x - 9, top - 2, 6, 3, OL); R(n, x - 8, top - 2, 4, 3, ST_L)
		R(n, x - 1, top - 5, 7, 6, OL); R(n, x, top - 4, 5, 5, ST); R(n, x, top - 4, 2, 5, ST_L)
		R(n, x + 5, top, 5, 2, OL)
		R(n, x + 1, top + 6, 1, 7, OL)
		R(n, x - 6, y - 3, 5, 3, ST_D); R(n, x + 9, y - 2, 6, 3, ST)            # fallen chips
	else:
		R(n, x - 9, top - 1, 18, 3, OL); R(n, x - 8, top - 1, 16, 2, ST_L)
		R(n, x - 9, top + 2, 4, 3, OL)
		R(n, x + 9, y - 3, 6, 3, ST); R(n, x - 15, y - 2, 5, 2, ST_D)

static func column_drum(n, x: float, y: float, is_long: bool) -> void:
	shadow(n, x + 4, y + 1, 18 if is_long else 10, 3)
	var w := 34 if is_long else 18
	R(n, x - w / 2.0 - 1, y - 12, w + 2, 14, OL)
	R(n, x - w / 2.0, y - 11, w, 12, ST); R(n, x - w / 2.0, y - 11, w, 3, ST_L); R(n, x - w / 2.0, y - 2, w, 3, ST_DD)
	R(n, x - w / 2.0 + 2, y - 6, 1, 4, ST_D)
	if is_long:
		R(n, x - 4, y - 11, 1, 12, ST_DD); R(n, x + 8, y - 11, 1, 12, ST_DD)
	R(n, x + w / 2.0 - 4, y - 10, 3, 10, ST_D)

# low ruined wall: stone blocks along the base, ragged top (each segment a different height). v seeds the pattern
static func ruin_wall(n, x: float, y: float, w: float, h: float, v: int) -> void:
	shadow(n, x + w / 2.0 + 2, y + h, w / 2.0 + 4, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = v * 977 + 13
	var bx := 0.0
	var row := 0
	while bx < w:
		var bw := minf(float(rng.randi_range(9, 16)), w - bx)
		var drop := float(rng.randi_range(0, int(h * 0.6))) if rng.randf() < 0.6 else 0.0
		var top := y + drop
		R(n, x + bx - 1, top - 1, bw + 2, h - drop + 1, OL)
		R(n, x + bx, top, bw, h - drop, ST)
		R(n, x + bx, top, bw, 2, ST_L)
		R(n, x + bx, top, 1, h - drop, ST_L)
		R(n, x + bx + bw - 2, top + 1, 2, h - drop - 1, ST_D)
		var yy := top + 7.0
		while yy < y + h - 2:
			R(n, x + bx, yy, bw, 1, ST_D)
			R(n, x + bx + 4 + (int(yy) % 5), yy + 1, 1, 6, ST_D)
			yy += 7.0
		bx += bw
		row += 1
	R(n, x, y + h - 3, w, 3, ST_DD)
	R(n, x + 2, y - 3, 6, 3, OL); R(n, x + 3, y - 2, 4, 2, ST_L)

static func rubble(n, x: float, y: float, s: int) -> void:
	shadow(n, x + 3, y + 1, 8 + s * 2, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 31 + y)
	for i in range(3 + s * 2):
		var ox := rng.randf_range(-6.0 - s * 2.0, 6.0 + s * 2.0)
		var oy := rng.randf_range(-3.0, 1.0)
		var w := rng.randf_range(4.0, 8.0 + s)
		var h := rng.randf_range(3.0, 6.0)
		R(n, x + ox - 1, y + oy - h - 1, w + 2, h + 2, OL)
		R(n, x + ox, y + oy - h, w, h, ST if i % 2 == 0 else ST_D)
		R(n, x + ox, y + oy - h, w, 1, ST_L)

# ------------------------------------------------------------------ torch
static func torch(n, x: float, y: float, animated := true) -> void:
	var t := now()
	R(n, x - 3, y + 1, 7, 2, SH)
	R(n, x - 2, y - 24, 5, 26, OL); R(n, x - 1, y - 24, 3, 25, WD); R(n, x - 1, y - 24, 1, 25, WD_L); R(n, x + 1, y - 23, 1, 24, WD_D)
	R(n, x - 4, y - 28, 9, 6, OL); R(n, x - 3, y - 27, 7, 4, Color("#4a4a52")); R(n, x - 3, y - 27, 7, 1, Color("#7a7a86"))
	var fl := (int(t * 9.0 + x) % 3) if animated else 1
	var h := 6 + fl * 2
	R(n, x - 3, y - 28 - h, 7, h + 1, OL)
	R(n, x - 2, y - 28 - h + 1, 5, h, Color("#e8742a"))
	R(n, x - 1, y - 28 - h / 2.0 - 1, 3, h / 2.0 + 1, Color("#ffd060"))
	R(n, x, y - 28 - h - 2, 1, 2, Color("#e8742a"))

static func banner(n, x: float, y: float, w: float, h: float) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y, w, h, RED); R(n, x, y, w, 2, Color("#d9503f")); R(n, x + w - 2, y, 2, h, RED_D); R(n, x, y + h - 3, w, 3, RED_D)
	# gold trident-ish emblem
	var cx := x + w / 2.0
	R(n, cx - 1, y + 6, 2, h - 14, GOLD); R(n, cx - 4, y + 6, 1, 6, GOLD); R(n, cx + 3, y + 6, 1, 6, GOLD); R(n, cx - 4, y + 11, 8, 1, GOLD)
	R(n, cx - 2, y + 4, 4, 2, GOLD)
	# pointed tail
	R(n, x + 1, y + h, w - 2, 2, RED_D); R(n, x + 3, y + h + 2, w - 6, 2, RED_D)
	R(n, x - 2, y - 3, w + 4, 2, OL); R(n, x - 1, y - 3, w + 2, 1, GOLD)

# ------------------------------------------------------------------ town walls and towers
# horizontal wall: crenellated cap on top, big stone face below. (x, y) top-left, h = total height
static func wall_h(n, x: float, y: float, w: float, h: float, v := 0) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y + 9, w, h - 9, WL)
	# crenels
	var cx := 0.0
	while cx < w:
		R(n, x + cx, y - 1, 12, 11, OL)
		R(n, x + cx + 1, y, 10, 9, WL_L)
		R(n, x + cx + 1, y, 10, 2, Color("#f0d6a2"))
		R(n, x + cx + 9, y + 2, 2, 7, WL_D)
		cx += 18.0
	R(n, x, y + 9, w, 2, WL_L); R(n, x, y + 11, w, 3, WL_D)
	# stone courses on the face
	var row := 0
	var yy := 14.0
	while yy < h - 4:
		var off := 0.0 if row % 2 == 0 else 9.0
		R(n, x, y + yy, w, 1, WL_D)
		var bx := off
		while bx < w:
			R(n, x + bx, y + yy + 1, 1, 7, WL_D)
			bx += 18.0
		yy += 8.0
		row += 1
	R(n, x, y + h - 5, w, 5, WL_D); R(n, x, y + h - 2, w, 2, WL_DD)
	# weathering
	var rng := RandomNumberGenerator.new()
	rng.seed = v + int(x)
	for i in range(int(w / 20.0)):
		var wx := x + rng.randf() * (w - 6)
		R(n, wx, y + 15 + rng.randf() * (h - 24), 4, 1, WL_DD)
		R(n, wx + 1, y + 12 + rng.randf() * (h - 24), 2, 2, WL_L)

# vertical wall seen from above: brick-patterned cap, darker side edge, small face at the south end
static func wall_v(n, x: float, y: float, w: float, h: float) -> void:
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y, w, h - 14, WL_L)
	R(n, x, y, 3, h - 14, Color("#f0d6a2")); R(n, x + w - 4, y, 4, h - 14, WL)
	R(n, x + w - 2, y, 2, h - 14, WL_D)
	var yy := 4.0
	var row := 0
	while yy < h - 16:
		R(n, x + 3, y + yy, w - 7, 1, WL_D)
		R(n, x + 3 + (row % 2) * 8 + 10, y + yy + 1, 1, 5, WL_D)
		yy += 7.0
		row += 1
	# battlement teeth along the outer edge
	var ty := 3.0
	while ty < h - 20:
		R(n, x + 1, y + ty, 3, 5, WL_DD)
		R(n, x + w - 4, y + ty, 3, 5, WL_DD)
		ty += 12.0
	# the south end face
	R(n, x, y + h - 14, w, 14, WL); R(n, x, y + h - 14, w, 2, WL_L)
	R(n, x, y + h - 3, w, 3, WL_DD)
	R(n, x + w / 2.0 - 1, y + h - 12, 1, 8, WL_D)

static func tower(n, x: float, y: float, w: float, h: float, flag: bool) -> void:
	shadow(n, x + w / 2.0 + 5, y + h, w / 2.0 + 6, 4)
	R(n, x - 1, y - 1, w + 2, h + 2, OL)
	R(n, x, y + 14, w, h - 14, WL)
	# crenellated top platform
	R(n, x - 2, y - 3, w + 4, 18, OL)
	R(n, x - 1, y - 2, w + 2, 16, WL_L)
	var cx := 0.0
	while cx < w:
		R(n, x - 1 + cx, y - 5, 8, 6, OL); R(n, x + cx, y - 4, 6, 5, WL_L)
		cx += 12.0
	R(n, x - 1, y + 8, w + 2, 6, WL_D)
	R(n, x, y + 14, w, 2, WL_L)
	var yy := 18.0
	var row := 0
	while yy < h - 4:
		R(n, x, y + yy, w, 1, WL_D)
		var bx := (row % 2) * 7.0
		while bx < w:
			R(n, x + bx, y + yy + 1, 1, 7, WL_D)
			bx += 14.0
		yy += 8.0
		row += 1
	R(n, x, y + 14, 3, h - 14, WL_L); R(n, x + w - 4, y + 14, 4, h - 14, WL_D)
	R(n, x, y + h - 5, w, 5, WL_D); R(n, x, y + h - 2, w, 2, WL_DD)
	# slit window
	R(n, x + w / 2.0 - 2, y + 28, 4, 10, OL); R(n, x + w / 2.0 - 1, y + 29, 2, 8, DOOR)
	if flag:
		banner(n, x + w / 2.0 - 8, y + 42, 16, h - 56)

static func gate_pillar(n, x: float, y: float, w: float, h: float) -> void:
	tower(n, x, y, w, h, false)
	banner(n, x + w / 2.0 - 8, y + 24, 16, 42)
	# iron hinge bands
	R(n, x + (w - 3 if x < 400 else 0), y + h - 40, 3, 30, Color("#3a3a42"))

# east gate pillar: same tower and red banner as the south gate, only shorter so it never hides the walkway
static func east_gate_pillar(n, x: float, y: float, w: float, h: float) -> void:
	tower(n, x, y, w, h, false)
	banner(n, x + w / 2.0 - 8, y + 17, 16, h - 27)

# iron gate bars standing open beside the road (drawn at the inner face of each tower)
static func gate_bars(n, x: float, y: float, h: float) -> void:
	R(n, x - 1, y - 1, 5, h + 2, OL)
	R(n, x, y, 3, h, Color("#3e3e46")); R(n, x, y, 1, h, Color("#6a6a74"))
	for i in range(int(h / 8.0)):
		R(n, x - 2, y + 4 + i * 8, 7, 1, Color("#2a2a30"))

# ------------------------------------------------------------------ buildings
# flat-roofed adobe house. (x, y) top-left of the drawing; roof_h = visible roof band; h = total height
static func adobe(n, x: float, y: float, w: float, h: float, roof_h: float, door_x: float, door_w: float, wins: Array, parapet := true, roof_tone := 0, clutter := true) -> void:
	shadow(n, x + w / 2.0 + 6, y + h, w / 2.0 + 8, 4)
	R(n, x - 2, y - 2, w + 4, h + 3, OL)
	# roof (seen from above)
	var rt := AD_TOP if roof_tone == 0 else Color("#dcb27c")
	R(n, x - 1, y - 1, w + 2, roof_h + 1, rt)
	R(n, x - 1, y - 1, w + 2, 2, Color("#f4dcaa"))
	R(n, x - 1, y + roof_h - 3, w + 2, 3, AD_TOP_D)
	if parapet:
		R(n, x + 3, y + 3, w - 6, 1, AD_TOP_D)
		R(n, x + 3, y + 3, 1, roof_h - 8, AD_TOP_D); R(n, x + w - 4, y + 3, 1, roof_h - 8, AD_TOP_D)
	# roof clutter (house() and storehouse() draw their own)
	if clutter:
		R(n, x + w - 22, y + 8, 7, 6, OL); R(n, x + w - 21, y + 9, 5, 4, Color("#b8744a"))
		R(n, x + 9, y + 8, 12, 2, WD_D)
	# face
	R(n, x - 1, y + roof_h, w + 2, h - roof_h, AD_FACE)
	R(n, x - 1, y + roof_h, w + 2, 3, AD_FACE_D)
	R(n, x - 1, y + roof_h, 3, h - roof_h, AD_FACE_L)
	R(n, x + w - 3, y + roof_h, 4, h - roof_h, AD_FACE_D)
	R(n, x - 1, y + h - 5, w + 2, 5, AD_FACE_D); R(n, x - 1, y + h - 2, w + 2, 2, AD_FACE_DD)
	# plaster patches (bricks showing through)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 7 + y)
	for i in range(int(w / 14.0)):
		var px := x + 4 + rng.randf() * (w - 14)
		var py := y + roof_h + 5 + rng.randf() * (h - roof_h - 14)
		R(n, px, py, 5, 3, AD_FACE_D); R(n, px + 1, py, 2, 1, AD_FACE_DD)
	# door with wooden frame
	if door_w > 0.0:
		var dx := x + door_x
		var dh := h - roof_h - 5.0
		R(n, dx - 3, y + h - dh - 3, door_w + 6, dh + 3, OL)
		R(n, dx - 2, y + h - dh - 2, door_w + 4, dh + 2, WD)
		R(n, dx, y + h - dh, door_w, dh, DOOR)
		R(n, dx, y + h - dh, door_w, 3, Color("#150c08"))
		R(n, dx - 2, y + h - dh - 2, door_w + 4, 2, WD_L)
		R(n, dx - 4, y + h - 3, door_w + 8, 3, ST_D)   # step
	for wx in wins:
		R(n, x + wx - 1, y + roof_h + 5, 8, 11, OL); R(n, x + wx, y + roof_h + 6, 6, 9, DOOR)
		R(n, x + wx - 2, y + roof_h + 4, 10, 2, AD_FACE_D)

# A lived-in mud-brick house: the adobe body plus a curtained doorway and a set of details, so no two houses look alike.
# deco: any of "ladder" (to the roof, left of the door), "awning" (reed mat over the door), "jar" (water jar by the door),
# "cloth" (washing drying on the roof), "pots" (plants on the roof terrace), "stair" (mud-brick stair up the left side), "window".
static func house(n, x: float, y: float, w: float, h: float, roof_h: float, door_x: float, door_w: float, curtain: Color, deco: Array, roof_tone := 0) -> void:
	adobe(n, x, y, w, h, roof_h, 0.0, 0.0, [], true, roof_tone, false)
	var dx := x + door_x
	var dh := h - roof_h - 8.0
	var dy := y + h - dh
	# doorway: wooden lintel, a cloth curtain with folds, a stone step
	R(n, dx - 2, dy - 2, door_w + 4, dh + 2, OL)
	R(n, dx - 1, dy - 1, door_w + 2, dh + 1, DOOR)
	R(n, dx, dy + 2, door_w, dh - 2, curtain); R(n, dx, dy + 2, door_w, 1, curtain.lightened(0.25))
	for fx in range(3, int(door_w), 4):
		R(n, dx + fx, dy + 3, 1, dh - 4, curtain.darkened(0.25))
	R(n, dx - 4, dy - 4, door_w + 8, 3, OL); R(n, dx - 3, dy - 3, door_w + 6, 1, WD_L)
	R(n, dx - 4, y + h - 3, door_w + 8, 3, ST_D)
	if "window" in deco:
		var wx := x + w - 22.0
		R(n, wx - 1, y + roof_h + 6, 9, 9, OL); R(n, wx, y + roof_h + 7, 7, 7, DOOR); R(n, wx + 3, y + roof_h + 7, 1, 7, WD); R(n, wx, y + roof_h + 10, 7, 1, WD)
	if "awning" in deco:
		var ax := dx - 7.0
		var ay := dy - 8.0
		R(n, ax - 1, ay - 1, door_w + 16, 7, OL)
		for i in range(int((door_w + 14) / 3.0)):
			R(n, ax + i * 3, ay, 2, 5, Color("#c8a860") if i % 2 == 0 else Color("#b08e48"))
		R(n, ax, ay, door_w + 14, 1, Color("#e0c47a"))
		for px in [ax + 1, ax + door_w + 11]:
			R(n, px, ay + 5, 2, y + h - ay - 5, OL); R(n, px, ay + 5, 1, y + h - ay - 5, WD)
	if "jar" in deco:
		var jx := dx + door_w + 8.0
		R(n, jx - 4, y + h - 11, 9, 11, OL); R(n, jx - 3, y + h - 10, 7, 9, Color("#b8744a")); R(n, jx - 3, y + h - 10, 2, 9, Color("#d8946a"))
		R(n, jx - 2, y + h - 13, 5, 3, OL); R(n, jx - 1, y + h - 12, 3, 1, Color("#8a4a2e"))
	if "ladder" in deco:
		var lx := dx - 18.0
		for rx in [lx, lx + 7]:
			R(n, rx, y + roof_h - 8, 2, h - roof_h + 8, OL); R(n, rx, y + roof_h - 8, 1, h - roof_h + 8, WD_L)
		var ry := y + roof_h - 5.0
		while ry < y + h - 2:
			R(n, lx + 1, ry, 7, 2, WD)
			ry += 5.0
	if "stair" in deco:
		for i in range(5):
			var sh := (i + 1) * (h - roof_h) / 5.0
			R(n, x + 2 + i * 6, y + h - sh, 7, sh, AD_FACE_D); R(n, x + 2 + i * 6, y + h - sh, 7, 2, AD_TOP)
		R(n, x + 1, y + roof_h, 1, h - roof_h, OL)
	if "cloth" in deco:
		R(n, x + 8, y + 10, w - 16, 1, OL)
		var cols := [Color("#d8d0b8"), Color("#3d78b8"), Color("#b8372b"), Color("#e0b038")]
		for i in range(4):
			var cx := x + 12 + i * (w - 28) / 3.0
			R(n, cx - 1, y + 10, 8, 10, OL); R(n, cx, y + 11, 6, 8, cols[i]); R(n, cx, y + 11, 6, 1, cols[i].lightened(0.3))
	if "pots" in deco:
		for i in range(3):
			var px := x + 10 + i * 14.0
			R(n, px - 1, y + 14, 9, 8, OL); R(n, px, y + 15, 7, 6, Color("#b8744a"))
			blob(n, px + 3, y + 12, 6, 5, Color("#1c3a1c")); blob(n, px + 3, y + 11, 5, 4, Color("#3a6e30")); blob(n, px + 2, y + 10, 2, 2, Color("#58903f"))
		R(n, x + w - 24, y + 8, 14, 12, OL); R(n, x + w - 23, y + 9, 12, 10, Color("#c8a860"))     # a reed screen
		for i in range(4):
			R(n, x + w - 22 + i * 3, y + 9, 1, 10, Color("#a08040"))

# The storehouse: a plain block with big double plank doors bound in iron (under a lintel beam), no windows. door_cx = the doors' centre.
static func storehouse(n, x: float, y: float, w: float, h: float, roof_h: float, door_cx: float) -> void:
	adobe(n, x, y, w, h, roof_h, 0.0, 0.0, [], true, 1, false)
	var dw := 32.0
	var dh := h - roof_h - 6.0
	var dx := door_cx - dw / 2.0
	var dy := y + h - dh
	R(n, dx - 2, dy - 2, dw + 4, dh + 2, OL)
	for leaf in range(2):
		var lx := dx + leaf * dw / 2.0
		R(n, lx, dy, dw / 2.0, dh, WD); R(n, lx, dy, 2, dh, WD_L)
		for pl in range(1, 4):
			R(n, lx + pl * 4, dy, 1, dh, WD_D)
		for sy in [dy + 4.0, dy + dh - 7.0]:                       # iron straps
			R(n, lx + 1, sy, dw / 2.0 - 2, 2, Color("#3a3a42")); R(n, lx + 1, sy, dw / 2.0 - 2, 1, Color("#6a6a74"))
	R(n, door_cx - 1, dy, 2, dh, OL)
	for hx in [door_cx - 5.0, door_cx + 3.0]:                        # ring handles
		n.draw_arc(Vector2(hx + 1, dy + dh / 2.0 + 1), 2.0, 0.0, TAU, 10, Color("#2a2a30"), 1.2)
	R(n, dx - 5, dy - 6, dw + 10, 5, OL); R(n, dx - 4, dy - 5, dw + 8, 3, WD); R(n, dx - 4, dy - 5, dw + 8, 1, WD_L)   # lintel beam
	R(n, dx - 4, y + h - 3, dw + 8, 3, ST_D)

# the stable (barn): an open-fronted timber barn. footprint x..x+w, y..y+h; the back wall stands on the line y + 20.
# Split in two so animals / people standing inside are drawn between the back (floor, plank wall, hay loft, braced rails) and the front
# (corner posts, roof beam, brace, lantern and rope).
const HAY := Color("#e8c758")
const HAY_L := Color("#f6e08a")
const HAY_D := Color("#b08e30")

static func _bale(n, bx: float, by: float, bw: float, bh: float) -> void:
	R(n, bx - 1, by - 1, bw + 2, bh + 2, OL); R(n, bx, by, bw, bh, HAY); R(n, bx, by, bw, 3, HAY_L); R(n, bx, by + bh - 2, bw, 2, HAY_D)
	R(n, bx + int(bw / 3.0), by, 1, bh, HAY_D); R(n, bx + int(bw * 2.0 / 3.0), by, 1, bh, HAY_D)

static func stable_back(n, x: float, y: float, w: float, h: float) -> void:
	shadow(n, x + w / 2.0 + 5, y + h, w / 2.0 + 8, 4)
	var base := y + 20.0
	# straw floor
	R(n, x + 4, base, w - 8, h - 22, Color("#d8b658"))
	for i in range(int(w / 6.0)):
		R(n, x + 6 + i * 6, base + 4 + (i * 7) % (int(h) - 32), 4, 1, HAY_D)
		R(n, x + 9 + i * 6, base + 10 + (i * 11) % (int(h) - 38), 3, 1, HAY_L)
	# back wall: dark planks
	R(n, x, base - 40, w, 42, OL)
	R(n, x + 1, base - 39, w - 2, 40, WD_D)
	var sx := x + 6.0
	while sx < x + w - 2:
		R(n, sx, base - 39, 1, 40, Color("#4a2c16")); R(n, sx + 1, base - 39, 1, 40, WD)
		sx += 9.0
	# hay loft: a shelf on posts with three bales and a loose pile on the right
	R(n, x + 1, base - 22, w - 2, 4, OL); R(n, x + 2, base - 21, w - 4, 2, WD_L)
	for i in range(3):
		_bale(n, x + 10 + i * 28, base - 35, 22, 13)
	blob(n, x + w - 30, base - 27, 18, 9, OL); blob(n, x + w - 30, base - 28, 17, 8, HAY); blob(n, x + w - 34, base - 31, 9, 4, HAY_L)
	# lower wall: X-braced rail panels between posts
	var pw := (w - 4) / 4.0
	for i in range(4):
		var px := x + 2 + i * pw
		R(n, px, base - 16, pw, 2, WD_L); R(n, px, base - 3, pw, 2, WD)
		n.draw_line(Vector2(px + 2, base - 14), Vector2(px + pw - 2, base - 3), WD, 2.0)
		n.draw_line(Vector2(px + pw - 2, base - 14), Vector2(px + 2, base - 3), WD, 2.0)
		R(n, px - 1, base - 18, 3, 18, OL); R(n, px, base - 17, 1, 16, WD_L)
	R(n, x + 1, base - 1, w - 2, 2, Color(0, 0, 0, 0.25))

static func stable_front(n, x: float, y: float, w: float, h: float) -> void:
	# two thick corner posts holding a heavy roof beam
	for px in [x + 1, x + w - 8]:
		R(n, px - 1, y - 22, 9, h + 24, OL); R(n, px, y - 21, 7, h + 22, WD); R(n, px, y - 21, 2, h + 22, WD_L); R(n, px + 5, y - 21, 2, h + 22, WD_D)
	R(n, x - 4, y - 30, w + 8, 10, OL)
	R(n, x - 3, y - 29, w + 6, 8, WD); R(n, x - 3, y - 29, w + 6, 2, WD_L); R(n, x - 3, y - 23, w + 6, 2, WD_D)
	for i in range(int(w / 12.0) + 1):                      # rafter ends along the beam
		R(n, x - 2 + i * 12, y - 33, 4, 4, OL); R(n, x - 1 + i * 12, y - 32, 2, 2, WD_L)
	# diagonal brace in the top-right corner
	n.draw_line(Vector2(x + w - 8, y + 2), Vector2(x + w - 30, y - 21), OL, 5.0)
	n.draw_line(Vector2(x + w - 8, y + 2), Vector2(x + w - 30, y - 21), WD, 3.0)
	# a coil of rope and a lantern hanging on the left post
	n.draw_arc(Vector2(x + 4, y + 26), 5.0, 0.0, TAU, 14, OL, 3.0)
	n.draw_arc(Vector2(x + 4, y + 26), 5.0, 0.0, TAU, 14, Color("#b8945a"), 1.5)
	R(n, x + 11, y + 22, 1, 4, OL)
	R(n, x + 9, y + 26, 6, 9, OL); R(n, x + 10, y + 27, 4, 7, Color("#3a3a42")); R(n, x + 11, y + 28, 2, 4, Color("#ffd060"))

# market stall with a striped cloth roof. goods: 0 pots, 1 fruit, 2 cloth rolls
static func stall_striped(n, x: float, y: float, w: float, goods: int, c1 := "#b8372b", c2 := "#f0e6cc") -> void:
	shadow(n, x + w / 2.0 + 4, y + 1, w / 2.0 + 6, 4)
	# table
	ob(n, x + 6, y - 14, w - 12, 12, WD, WD_L, WD_D)
	R(n, x + 6, y - 14, w - 12, 3, Color("#d8b070"))
	if goods == 0:
		for i in range(int((w - 20) / 12.0)):
			var jx := x + 12 + i * 12
			R(n, jx - 1, y - 24, 9, 11, OL); R(n, jx, y - 23, 7, 9, Color("#b8744a") if i % 2 == 0 else Color("#8a4a2e")); R(n, jx, y - 23, 2, 9, Color("#d8946a"))
			R(n, jx + 1, y - 26, 5, 3, Color("#8a4a2e"))
	elif goods == 1:
		for i in range(int((w - 20) / 9.0)):
			R(n, x + 12 + i * 9, y - 20, 6, 6, OL); R(n, x + 13 + i * 9, y - 19, 4, 4, ["#d94a2a", "#e8a82a", "#7aa83a"][i % 3])
	else:
		for i in range(int((w - 16) / 10.0)):
			R(n, x + 10 + i * 10 - 1, y - 24, 9, 11, OL); R(n, x + 10 + i * 10, y - 23, 7, 9, ["#3a6aa0", "#a03a4a", "#d8b038"][i % 3])
	# posts
	var a := y                 # the awning is drawn relative to this line
	R(n, x + 1, a - 40, 4, 40, OL); R(n, x + 2, a - 40, 2, 40, WD); R(n, x + w - 5, a - 40, 4, 40, OL); R(n, x + w - 4, a - 40, 2, 40, WD)
	# striped awning
	R(n, x - 3, a - 48, w + 6, 14, OL)
	var i := 0
	var sx := x - 2.0
	while sx < x + w + 2:
		var sw := minf(8.0, x + w + 2 - sx)
		R(n, sx, a - 47, sw, 12, Color(c1) if i % 2 == 0 else Color(c2))
		R(n, sx, a - 47, sw, 2, Color("#d9503f") if i % 2 == 0 else Color("#fffbe8"))
		sx += 8.0
		i += 1
	R(n, x - 2, a - 36, w + 4, 2, Color(0, 0, 0, 0.22))
	# scalloped hem
	i = 0
	sx = x - 2.0
	while sx < x + w:
		R(n, sx, a - 35, 7, 2, OL); R(n, sx + 1, a - 35, 5, 1, Color(c1) if i % 2 == 0 else Color(c2))
		sx += 8.0
		i += 1

# red cloth canopy over a cooking cauldron. fire_x = where the fire and cauldron are (default: the middle); mid_poles = extra poles
# holding up a long canopy
static func cook_camp(n, x: float, y: float, w: float, fire_x := -1.0, mid_poles := []) -> void:
	var t := now()
	shadow(n, x + w / 2.0 + 3, y + 1, w / 2.0 + 4, 4)
	for px in [x + 2.0, x + w - 6.0] + mid_poles:
		R(n, px, y - 48, 4, 48, OL); R(n, px + 1, y - 48, 2, 48, WD)
	# canopy
	R(n, x - 3, y - 60, w + 6, 22, OL)
	R(n, x - 2, y - 59, w + 4, 20, RED); R(n, x - 2, y - 59, w + 4, 3, Color("#d9503f")); R(n, x - 2, y - 44, w + 4, 5, RED_D)
	for i in range(int(w / 14.0) + 1):
		R(n, x + 4 + i * 14, y - 56, 1, 12, RED_D)
	var sx := x - 2.0
	var k := 0
	while sx < x + w + 2:
		R(n, sx, y - 39, 9, 4 + (k % 2) * 2, OL); R(n, sx + 1, y - 39, 7, 3 + (k % 2) * 2, RED); sx += 10.0; k += 1
	# fire pit + cauldron
	var c := fire_x if fire_x >= 0.0 else x + w / 2.0
	var fl := int(t * 9.0) % 3
	R(n, c - 11, y - 6, 22, 7, OL)
	for i in range(6):
		R(n, c - 10 + i * 3.5, y - 5, 4, 5, Color("#7a756c") if i % 2 == 0 else Color("#5e5a52"))
	R(n, c - 6, y - 8, 12, 3, Color("#4a2e1a"))
	var fh := 6 + fl * 2
	R(n, c - 4, y - 8 - fh, 8, fh, Color("#e8742a")); R(n, c - 2, y - 8 - fh / 2.0, 4, fh / 2.0, Color("#ffd060"))
	# iron pot hanging from a bar
	R(n, c - 15, y - 36, 30, 3, OL); R(n, c - 14, y - 36, 28, 2, Color("#3a3a42"))
	R(n, c - 1, y - 34, 2, 6, OL)
	blob(n, c, y - 22, 11, 9, OL); blob(n, c, y - 22, 10, 8, Color("#2e2e34")); blob(n, c - 2, y - 24, 6, 4, Color("#55555e"))
	R(n, c - 9, y - 29, 18, 3, Color("#16161a"))
	R(n, c - 7, y - 28, 14, 1, Color("#8a5a2a"))   # stew
	# steam
	for i in range(3):
		var a := fmod(t * 0.7 + i * 0.33, 1.0)
		R(n, c - 3 + i * 4 + sin(t * 2.0 + i) * 2.0, y - 34 - a * 12.0, 2, 2, Color(1, 1, 1, 0.45 * (1.0 - a)))

static func well(n, x: float, y: float) -> void:
	shadow(n, x + 5, y + 6, 24, 5)
	# stone ring
	blob(n, x, y, 21, 13, OL)
	blob(n, x, y, 20, 12, Color("#a89878"))
	blob(n, x, y - 2, 20, 10, Color("#c8b890"))
	blob(n, x, y - 3, 14, 7, OL)
	blob(n, x, y - 3, 13, 6, Color("#2d6a8a"))
	blob(n, x - 2, y - 4, 7, 3, Color("#5aa0c0"))
	R(n, x - 8, y - 3, 5, 1, Color("#a8d8e8"))
	for i in range(7):
		var a := PI * (0.1 + 0.8 * i / 6.0)
		R(n, x + cos(a) * 18 - 2, y + 2 + sin(a) * 8 - 2, 5, 4, Color("#9a8a6a") if i % 2 == 0 else Color("#b8a888"))
		R(n, x + cos(a) * 18 - 2, y + 2 + sin(a) * 8 - 2, 5, 1, Color("#dccaa0"))
	# frame
	R(n, x - 17, y - 36, 5, 40, OL); R(n, x - 16, y - 35, 3, 38, WD); R(n, x - 16, y - 35, 1, 38, WD_L)
	R(n, x + 12, y - 36, 5, 40, OL); R(n, x + 13, y - 35, 3, 38, WD); R(n, x + 13, y - 35, 1, 38, WD_L)
	R(n, x - 19, y - 41, 38, 7, OL); R(n, x - 18, y - 40, 36, 5, WD); R(n, x - 18, y - 40, 36, 1, WD_L); R(n, x - 18, y - 36, 36, 1, WD_D)
	# roof cap
	R(n, x - 21, y - 46, 42, 6, OL); R(n, x - 20, y - 45, 40, 4, Color("#a05a3a")); R(n, x - 20, y - 45, 40, 1, Color("#c87a52"))
	# rope + bucket
	R(n, x - 1, y - 34, 2, 14, Color("#d8c08a")); R(n, x - 4, y - 21, 9, 7, OL); R(n, x - 3, y - 20, 7, 5, Color("#7a5530")); R(n, x - 3, y - 20, 7, 1, Color("#b08040"))
	# stray bucket on the rim
	R(n, x + 14, y + 2, 7, 6, OL); R(n, x + 15, y + 3, 5, 4, Color("#7a5530"))

static func barrel(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 8, 3)
	R(n, x - 6, y - 14, 12, 15, OL); R(n, x - 5, y - 13, 10, 13, Color("#8a5a32")); R(n, x - 5, y - 13, 3, 13, Color("#b07a46")); R(n, x + 2, y - 13, 3, 13, Color("#5e3a1e"))
	R(n, x - 6, y - 12, 12, 2, Color("#3e3e46")); R(n, x - 6, y - 5, 12, 2, Color("#3e3e46"))
	R(n, x - 5, y - 15, 10, 3, OL); R(n, x - 4, y - 15, 8, 2, Color("#c49058"))

static func crate(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 9, 3)
	ob(n, x - 7, y - 14, 14, 15, Color("#b08040"), Color("#d8a868"), Color("#6e4a24"))
	R(n, x - 7, y - 8, 14, 1, Color("#6e4a24")); R(n, x - 1, y - 14, 2, 15, Color("#8a5e30"))
	R(n, x - 6, y - 13, 3, 1, Color("#e8c88a"))

static func crate_stack(n, x: float, y: float) -> void:
	crate(n, x - 9, y)
	crate(n, x + 8, y)
	crate(n, x, y - 14)

static func sacks(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 12, 3)
	for k in range(2):
		var ox := x - 8 + k * 11
		R(n, ox - 1, y - 11, 11, 12, OL); R(n, ox, y - 10, 9, 10, Color("#d8c08a")); R(n, ox, y - 10, 3, 10, Color("#ecd8a8")); R(n, ox + 6, y - 10, 3, 10, Color("#b09860"))
		R(n, ox + 2, y - 12, 5, 2, Color("#a08850"))

static func hay(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 11, 3)
	R(n, x - 10, y - 12, 20, 13, OL); R(n, x - 9, y - 11, 18, 11, Color("#e8c758")); R(n, x - 9, y - 11, 18, 3, Color("#f6e08a"))
	R(n, x - 9, y - 2, 18, 2, Color("#b08e30")); R(n, x - 4, y - 11, 1, 11, Color("#a88a30")); R(n, x + 4, y - 11, 1, 11, Color("#a88a30"))
	R(n, x - 7, y - 14, 3, 3, Color("#e8c758")); R(n, x + 3, y - 13, 4, 2, Color("#f6e08a"))

static func pots(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 12, 3)
	R(n, x - 8, y - 12, 10, 13, OL); R(n, x - 7, y - 11, 8, 11, Color("#b8744a")); R(n, x - 7, y - 11, 3, 11, Color("#d8946a")); R(n, x - 6, y - 14, 6, 3, OL); R(n, x - 5, y - 14, 4, 2, Color("#b8744a"))
	R(n, x + 2, y - 9, 9, 10, OL); R(n, x + 3, y - 8, 7, 8, Color("#c8825a")); R(n, x + 3, y - 8, 2, 8, Color("#e0a47a")); R(n, x + 4, y - 11, 5, 3, OL); R(n, x + 5, y - 11, 3, 2, Color("#c8825a"))
	R(n, x - 7, y - 6, 8, 1, Color("#7a4a2e"))

static func wheel_pots(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 12, 3)
	R(n, x - 9, y - 8, 18, 9, OL); R(n, x - 8, y - 7, 16, 7, Color("#7a5530")); R(n, x - 6, y - 9, 12, 3, Color("#9a6b3a"))
	R(n, x - 2, y - 16, 4, 7, Color("#b8744a")); R(n, x - 5, y - 21, 10, 6, OL); R(n, x - 4, y - 20, 8, 4, Color("#c8825a"))

# ------------------------------------------------------------------ training yard: fence, dummy, weapon rack; signs
const FENCE_H := 9.0          # how high the rail sits on the fence posts
const CLOTH := Color("#e8dcc0")
const CLOTH_L := Color("#f6eedc")
const CLOTH_D := Color("#bfae8c")

# one chunky fence post standing on (x, y): 6 px wide, 14 tall, with a lit cap
static func fence_post(n, x: float, y: float) -> void:
	R(n, x - 4, y - 15, 8, 16, OL)
	R(n, x - 3, y - 14, 6, 14, WD); R(n, x - 3, y - 14, 2, 14, WD_L); R(n, x + 2, y - 14, 1, 14, WD_D)
	R(n, x - 3, y - 14, 6, 2, Color("#c8925a")); R(n, x - 3, y - 12, 6, 1, WD_D)
	R(n, x - 3, y - 1, 6, 1, WD_D)

# a fence along x0..x1 on the ground line y: a soft shadow, the rail raised FENCE_H px, then the posts in front of it every
# `step` px (the last one always at x1)
static func fence_h(n, x0: float, x1: float, y: float, step: float) -> void:
	n.draw_rect(Rect2(x0, y - 1, x1 - x0, 3), SH)
	var ry := y - FENCE_H - 2.0
	R(n, x0, ry - 1, x1 - x0, 6, OL)
	R(n, x0, ry, x1 - x0, 4, WD); R(n, x0, ry, x1 - x0, 1, WD_L); R(n, x0, ry + 3, x1 - x0, 1, WD_D)
	var px := x0
	while px < x1 - step * 0.5:
		fence_post(n, px, y)
		px += step
	fence_post(n, x1, y)

# a side fence seen from above: one long beam from y0 to y1 at x, raised like the rail of fence_h (its posts come from fence_h / fence_post)
static func fence_v(n, x: float, y0: float, y1: float) -> void:
	n.draw_rect(Rect2(x + 2, y0, 3, y1 - y0), SH)
	R(n, x - 3, y0 - FENCE_H - 3, 6, y1 - y0 + 2, OL)
	R(n, x - 2, y0 - FENCE_H - 2, 4, y1 - y0, WD); R(n, x - 2, y0 - FENCE_H - 2, 1, y1 - y0, WD_L); R(n, x + 1, y0 - FENCE_H - 2, 1, y1 - y0, WD_D)

# The training dummy: a cloth-wrapped log for a head, a crossbar for arms with rags hanging off it, a cloth torso with a painted target,
# on a post. (x, y) = foot. lean tips it over from the foot when it is hit: a skew (each row moves sideways by lean px per px of
# height) rather than a rotation, so the pixel rows stay straight. The shadow stays put. Like every prop it is drawn on a rebased node
# that sits at the foot's y, so the foot is (x, y - n.position.y) in the node's own space.
static func dummy(n, x: float, y: float, lean := 0.0) -> void:
	shadow(n, x + 3, y + 1, 10, 3)
	n.draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(-lean, 1), Vector2(x, y - n.position.y)))
	_dummy_body(n)
	n.draw_set_transform(Vector2(0.0, -n.position.y), 0.0, Vector2.ONE)

static func _dummy_body(n) -> void:
	# the post, then the crossbar (the torso cloth hangs over its middle)
	R(n, -3, -16, 6, 17, OL); R(n, -2, -15, 4, 15, WD); R(n, -2, -15, 1, 15, WD_L); R(n, 1, -15, 1, 15, WD_D)
	R(n, -15, -26, 30, 6, OL); R(n, -14, -25, 28, 4, WD); R(n, -14, -25, 28, 1, WD_L); R(n, -14, -22, 28, 1, WD_D)
	R(n, -16, -25, 1, 4, OL); R(n, 15, -25, 1, 4, OL)
	# rags tied near both ends of the crossbar
	for sx in [-11.0, 8.0]:
		R(n, sx - 1, -25, 5, 9, OL); R(n, sx, -24, 3, 7, CLOTH); R(n, sx, -24, 1, 7, CLOTH_L); R(n, sx + 2, -24, 1, 6, CLOTH_D)
		R(n, sx + 1, -17, 1, 1, OL)
	# torso: cream cloth with a torn hem and a red ring-and-dot target
	R(n, -8, -28, 16, 16, OL); R(n, -7, -27, 14, 14, CLOTH); R(n, -7, -27, 3, 14, CLOTH_L); R(n, 4, -27, 3, 14, CLOTH_D)
	R(n, -7, -14, 2, 1, OL); R(n, -2, -14, 3, 1, OL); R(n, 4, -14, 2, 1, OL)              # torn hem
	R(n, -7, -27, 14, 2, CLOTH_D)                                                          # where it is tied round the neck
	n.draw_colored_polygon(ell(0, -20, 4.0, 4.0, 14), RED)
	n.draw_colored_polygon(ell(0, -20, 2.5, 2.5, 12), CLOTH)
	R(n, -1, -21, 2, 2, RED)
	# head: a log wrapped in cloth bands, lighter end grain on top
	R(n, -6, -37, 12, 11, OL); R(n, -5, -36, 10, 9, WD); R(n, -5, -36, 2, 9, WD_L); R(n, 3, -36, 2, 9, WD_D)
	for by in [-34.0, -30.0]:
		R(n, -5, by, 10, 2, CLOTH); R(n, -5, by, 3, 1, CLOTH_L); R(n, 3, by + 1, 2, 1, CLOTH_D)
	n.draw_colored_polygon(ell(0, -37, 5.0, 2.0, 12), OL)
	n.draw_colored_polygon(ell(0, -37, 4.0, 1.0, 12), Color("#c8945a"))
	R(n, -1, -37, 2, 1, WD_D)

# A weapon rack: two short straight swords (an akinakes is the Persian short sword) and three spears. (x, y) = centre of the base front.
static func weapon_rack(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 15, 3)
	# frame: two uprights, two bars, a base plank
	for ux in [x - 14.0, x + 11.0]:
		R(n, ux - 1, y - 23, 5, 22, OL); R(n, ux, y - 22, 3, 20, WD); R(n, ux, y - 22, 1, 20, WD_L)
	R(n, x - 15, y - 21, 30, 4, OL); R(n, x - 14, y - 20, 28, 2, WD); R(n, x - 14, y - 20, 28, 1, WD_L)
	R(n, x - 15, y - 12, 30, 4, OL); R(n, x - 14, y - 11, 28, 2, WD_D)
	R(n, x - 16, y - 5, 32, 6, OL); R(n, x - 15, y - 4, 30, 4, WD); R(n, x - 15, y - 4, 30, 1, WD_L); R(n, x - 15, y - 1, 30, 1, WD_D)
	# two swords, hilts up, resting against the top bar
	for sx in [x - 9.0, x - 4.0]:
		R(n, sx - 1, y - 18, 4, 14, OL); R(n, sx, y - 17, 2, 12, Color("#d0d4da")); R(n, sx, y - 17, 1, 12, Color("#f0f2f4"))
		R(n, sx - 2, y - 19, 6, 2, OL); R(n, sx - 1, y - 19, 4, 1, Color("#8a6a3a"))       # guard
		R(n, sx - 1, y - 24, 4, 6, OL); R(n, sx, y - 23, 2, 4, Color("#4a2e1a"))            # grip
		R(n, sx, y - 25, 2, 2, Color("#b8a070"))                                            # pommel
	# three spears, leaf-shaped tips staggered in height
	var tops := [34.0, 40.0, 37.0]
	for i in range(3):
		var px: float = x + 2.0 + i * 4.0
		var top: float = y - tops[i]
		R(n, px - 1, top + 6, 3, y - 2 - top - 6, OL); R(n, px, top + 6, 1, y - 3 - top - 6, Color("#7a5232"))
		n.draw_colored_polygon(PackedVector2Array([Vector2(px + 0.5, top - 1), Vector2(px + 3.5, top + 4), Vector2(px + 0.5, top + 8), Vector2(px - 2.5, top + 4)]), OL)
		n.draw_colored_polygon(PackedVector2Array([Vector2(px + 0.5, top + 0.5), Vector2(px + 2.5, top + 4), Vector2(px + 0.5, top + 7), Vector2(px - 1.5, top + 4)]), Color("#d0d4da"))
		R(n, px, top + 2, 1, 4, Color("#f0f2f4"))

static func rack(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 12, 3)
	R(n, x - 12, y - 28, 4, 29, OL); R(n, x - 11, y - 27, 2, 27, WD); R(n, x + 9, y - 28, 4, 29, OL); R(n, x + 10, y - 27, 2, 27, WD)
	R(n, x - 12, y - 28, 25, 4, OL); R(n, x - 11, y - 27, 23, 2, WD_L)
	R(n, x - 12, y - 14, 25, 4, OL); R(n, x - 11, y - 13, 23, 2, WD)
	for i in range(6):
		R(n, x - 9 + i * 4, y - 26, 2, 25, Color("#6a4a2a"))
		R(n, x - 10 + i * 4, y - 32 - (i % 2) * 2, 4, 7, OL); R(n, x - 9 + i * 4, y - 31 - (i % 2) * 2, 2, 5, Color("#d0d4da"))

static func signpost(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 9, 3)
	R(n, x - 2, y - 30, 5, 31, OL); R(n, x - 1, y - 29, 3, 29, WD); R(n, x - 1, y - 29, 1, 29, WD_L)
	R(n, x - 15, y - 32, 27, 9, OL); R(n, x - 14, y - 31, 25, 7, Color("#a87646")); R(n, x - 14, y - 31, 25, 1, Color("#d09c64"))
	R(n, x + 11, y - 30, 4, 5, OL); R(n, x + 11, y - 29, 3, 3, Color("#a87646"))
	R(n, x - 11, y - 28, 14, 1, DOOR); R(n, x - 11, y - 26, 9, 1, DOOR)
	R(n, x - 12, y - 22, 20, 7, OL); R(n, x - 11, y - 21, 18, 5, Color("#8a5a32")); R(n, x - 11, y - 21, 18, 1, Color("#b07a46"))
	R(n, x - 8, y - 19, 11, 1, DOOR)

# rat burrow in the sand
static func nest(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 3, 16, 4)
	blob(n, x, y - 1, 13, 7, OL)
	blob(n, x, y - 1, 12, 6, Color("#b88e4c"))
	blob(n, x - 1, y - 3, 10, 4, Color("#cba264"))
	blob(n, x, y - 1, 6, 3, OL)
	blob(n, x, y - 1, 5, 2, Color("#1c1008"))
	R(n, x + 9, y - 2, 4, 1, Color("#e8dcc0")); R(n, x - 12, y, 3, 1, Color("#e8dcc0"))
	R(n, x - 9, y - 6, 3, 2, Color("#9a7430")); R(n, x + 5, y - 7, 4, 2, Color("#9a7430"))

# ------------------------------------------------------------------ small landmarks
static func cart(n, x: float, y: float) -> void:
	shadow(n, x + 4, y + 2, 22, 4)
	R(n, x - 18, y - 14, 36, 14, OL); R(n, x - 17, y - 13, 34, 11, Color("#8a5a32")); R(n, x - 17, y - 13, 34, 3, Color("#b07a46"))
	R(n, x - 17, y - 5, 34, 1, Color("#5e3a1e")); R(n, x - 8, y - 13, 1, 11, Color("#5e3a1e")); R(n, x + 4, y - 13, 1, 11, Color("#5e3a1e"))
	R(n, x - 24, y - 18, 7, 5, OL); R(n, x - 23, y - 17, 6, 3, WD)
	blob(n, x - 8, y - 2, 8, 8, OL); blob(n, x - 8, y - 2, 6, 6, Color("#4a2e1a")); blob(n, x - 8, y - 2, 2, 2, Color("#a88a60"))
	R(n, x + 12, y - 5, 10, 6, OL); R(n, x + 13, y - 4, 8, 4, Color("#5a3f24"))
	R(n, x - 4, y - 18, 10, 6, Color("#e0bc50")); R(n, x - 4, y - 18, 10, 2, Color("#f6e08a"))

static func bones(n, x: float, y: float) -> void:
	R(n, x - 6, y - 2, 12, 2, OL); R(n, x - 5, y - 1, 10, 1, Color("#f1e8d0"))
	R(n, x - 4, y - 5, 3, 3, Color("#f1e8d0")); R(n, x + 1, y - 4, 4, 2, Color("#e0d4b0"))

# the walkway rails of the bridge. top = true for the far (north) rail.
static func bridge_rail(n, x0: float, x1: float, y: float, top: bool) -> void:
	var yy := y
	R(n, x0, yy - 14, x1 - x0, 5, OL); R(n, x0, yy - 13, x1 - x0, 3, WD); R(n, x0, yy - 13, x1 - x0, 1, WD_L)
	R(n, x0, yy - 6, x1 - x0, 3, OL); R(n, x0, yy - 6, x1 - x0, 2, WD_D)
	var x := x0 + 2.0
	while x < x1:
		R(n, x - 2, yy - 18, 6, 22, OL); R(n, x - 1, yy - 17, 4, 20, WD); R(n, x - 1, yy - 17, 1, 20, WD_L)
		R(n, x - 2, yy - 19, 6, 2, WD_L)
		x += 26.0

static func watch_post(n, x: float, y: float, w: float, h: float) -> void:
	adobe(n, x, y, w, h, int(h * 0.45), w / 2.0 - 5.0, 10.0, [], true)

# ------------------------------------------------------------------ the stranger's trail in the ruins (Stage 7b)
# one boot print pressed into the sand: a sole and a heel along `ang` (the way he walked), with ridges across the sole - the
# tread is what makes it read as foreign next to sandals. left = the left foot (prints alternate either side of the line).
static func boot_print(n, x: float, y: float, ang: float, left: bool) -> void:
	var d := Vector2.from_angle(ang)
	var across := d.orthogonal()
	var base := Vector2(x, y) + across * (1.6 if left else -1.6)
	var dent := Color(0.42, 0.27, 0.12, 0.42)
	var sole := PackedVector2Array()
	var heel := PackedVector2Array()
	for i in range(10):
		var a := TAU * i / 10.0
		sole.append(base + d * (1.6 + sin(a) * 3.2) + across * cos(a) * 2.0)
		heel.append(base + d * (-3.4 + sin(a) * 1.4) + across * cos(a) * 1.7)
	n.draw_colored_polygon(sole, dent)
	n.draw_colored_polygon(heel, dent)
	for k in [0.0, 1.6, 3.2]:
		var p: Vector2 = base + d * k
		n.draw_line(p - across * 1.6, p + across * 1.6, Color(0.3, 0.18, 0.08, 0.45), 1.0)

# the scorpions' den in the ruins (Stage 7j, world_waystation.gd DEN): a fallen slab tipped onto a stone, a dark burrow under its raised
# front edge, and pale shed skins in the sand. Low: it is no cover. (x, y) = the middle of its front foot
static func scorpion_den(n, x: float, y: float) -> void:
	shadow(n, x + 3, y + 1, 16, 4)
	blob(n, x - 1, y - 2, 9, 4, OL)                                                              # the burrow under the slab
	blob(n, x - 1, y - 2, 8, 3, Color("#1c1008"))
	R(n, x - 13, y - 11, 26, 7, OL)                                                              # the slab, lit on top
	R(n, x - 12, y - 10, 24, 5, ST); R(n, x - 12, y - 10, 24, 1, ST_L); R(n, x - 12, y - 6, 24, 1, ST_D)
	R(n, x - 4, y - 10, 1, 3, ST_DD); R(n, x + 5, y - 8, 3, 1, ST_DD)                            # cracks
	R(n, x + 7, y - 5, 7, 5, OL); R(n, x + 8, y - 4, 5, 3, ST_D); R(n, x + 8, y - 4, 5, 1, ST)   # the stone it rests on
	R(n, x - 14, y - 4, 5, 4, OL); R(n, x - 13, y - 3, 3, 2, ST_D)                               # a small stone
	for c in [[-10, 2], [12, 1], [3, 3]]:                                                        # shed skins
		R(n, x + c[0], y + c[1], 3, 1, Color("#e8d8b0")); R(n, x + c[0] + 3, y + c[1] - 1, 1, 1, Color("#e8d8b0"))

# the stranger's dropped brass box (a compass, though nobody here has the word): a round brass case with a ring, a glass face and a
# red needle pointing north. glint = the short flash that makes it catch the eye among the rubble.
static func brass_box(n, x: float, y: float, glint: bool) -> void:
	shadow(n, x + 2, y, 6, 2)
	R(n, x - 1, y - 11, 3, 2, OL); R(n, x, y - 10, 1, 1, Color("#ecc66a"))                      # the ring
	blob(n, x, y - 5, 5, 4, OL)
	blob(n, x, y - 5, 4, 3, Color("#c8963a"))
	R(n, x - 3, y - 8, 3, 1, Color("#ecc66a"))                                                   # lit top-left rim
	R(n, x + 1, y - 3, 3, 1, Color("#8a6420"))                                                   # shaded bottom-right rim
	blob(n, x, y - 5, 2.6, 1.8, Color("#cfe2e0"))                                                # the glass face
	R(n, x, y - 7, 1, 2, Color("#c0392b")); R(n, x, y - 5, 1, 1, Color("#3a3a3a"))               # the needle, pointing north
	if glint:
		var c := Color(1, 1, 0.9, 0.95)
		R(n, x - 3, y - 12, 1, 5, c); R(n, x - 5, y - 10, 5, 1, c)

# a torn page from the stranger's notebook, weighed down by a stone: ruled lines, a ragged edge, his writing
static func torn_page(n, x: float, y: float) -> void:
	shadow(n, x + 2, y, 8, 2)
	R(n, x - 7, y - 7, 13, 8, OL)
	R(n, x - 6, y - 6, 11, 6, Color("#efe9da")); R(n, x - 6, y - 6, 11, 1, Color("#fbf8ef"))
	for k in range(3):
		R(n, x - 5, y - 5 + k * 2, 8 - k * 2, 1, Color("#8f9bb3"))                               # ruled lines, written on
	R(n, x + 5, y - 6, 1, 1, OL); R(n, x + 4, y - 4, 1, 1, OL); R(n, x + 5, y - 2, 1, 1, OL)      # the torn edge
	blob(n, x + 4, y - 2, 4, 3, OL)                                                              # the stone on its corner
	blob(n, x + 4, y - 2, 3, 2, ST_D)
	R(n, x + 2, y - 4, 3, 1, ST_L)
