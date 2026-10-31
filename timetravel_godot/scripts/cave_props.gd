extends RefCounted
# cave_props.gd - things that only the cave hideout (cave.gd) uses: hide tents (bloodied in the raided camp), fire rings, camp tables,
# bedrolls, stake palisades, the wooden cage and the jail's small pens, the chief's seat, his hoard, his war table, the band's banner,
# a fire bowl, a spiked barricade, dropped gear, a spilled pot, a broken spear, what the raid and the jail left (arrows in the ground,
# a torn tunic, chain frames, a strap bench, a bowl of branding irons, a straw mat), the loot strewn over the boss room (coin bags,
# spilled coins, a strongbox, an ibex skull), the dead (staked captives, the figures slumped in the pens), and the daylight falling
# in at the mouth. Same rules as props.gd: absolute world coordinates, dark outline, three tones, light from the top-left, soft
# shadow to the bottom-right.
# Historical care (about 550-330 BCE): cages and pens are lashed wooden poles (not iron bars), the tents are hide and wool, the band's
# banner carries a plain painted mark, never a royal sign, and the executed are bound to upright stakes (as the Behistun
# inscription records), never crosses. The hoard's coins are gold darics (struck from about 515 BCE) and its bowls are phialai; the
# war table is lit by a clay oil lamp, not candles; the skull is an ibex's (the band's own mark), not a person's.
# Tone (design doc): the camp shows traces only (blood, gear); the jail's instruments are empty, and its dead are featureless dark
# figures slumped in the pens; the boss room's captives are distant, featureless silhouettes.

const Props = preload("res://scripts/props.gd")

const OL := Color("#3a2517")
const WD := Color("#8a5a32")
const WD_L := Color("#b07a46")
const WD_D := Color("#5e3a1e")
const ROPE := Color("#c8a868")
# hide tents (tan) and the band's red wool
const HIDE := [Color("#b89a6a"), Color("#d4b888"), Color("#8a6e48")]
const WOOL := [Color("#9a2e24"), Color("#c0473a"), Color("#6e1e18")]
# cave stone (matches terrain.gd's cave rim)
const STN := Color("#857463")
const STN_L := Color("#a8977f")
const STN_D := Color("#54483d")
const STN_OL := Color("#2e241d")
const IRON := Color("#4a4a52")
const IRON_L := Color("#6a6a74")
const IRON_D := Color("#2e2e34")
const GOLD := Color("#e8b838")
const GOLD_L := Color("#ffe48a")
const GOLD_D := Color("#a87820")
# blood on things (the ground's blood is painted by terrain.gd, same reds)
const BLOOD := Color("#6e1410")
const BLOOD_D := Color("#4a0e0a")
const SIL := Color("#141010")         # the dead, seen as featureless silhouettes

static func R(n, x: float, y: float, w: float, h: float, c) -> void:
	Props.R(n, x, y, w, h, c)

static func poly(n, pts: Array, c: Color) -> void:
	n.draw_colored_polygon(PackedVector2Array(pts), c)

# a 1 px line of rects from a to b (for thin marks drawn on things, like the routes on the war map)
static func _line(n, a: Vector2, b: Vector2, c: Color) -> void:
	var steps := maxi(1, int(a.distance_to(b)))
	for i in range(steps + 1):
		var p := a.lerp(b, float(i) / steps)
		R(n, floorf(p.x), floorf(p.y), 1, 1, c)

# a pole lying on the ground from a to b (an outline, then the wood)
static func _shaft(n, a: Vector2, b: Vector2, c: Color) -> void:
	var d := (b - a).normalized()
	var nr := Vector2(-d.y, d.x)
	poly(n, [a - nr * 1.5, b - nr * 1.5, b + nr * 1.5, a + nr * 1.5], OL)
	poly(n, [a - nr * 0.6, b - nr * 0.6, b + nr * 0.6, a + nr * 0.6], c)

# a flame (animated): h grows and shrinks; used by the lit fire ring and the fire bowl
static func _flame(n, x: float, y: float, w: float, h: float) -> void:
	R(n, x - w / 2.0 - 1, y - h - 1, w + 2, h + 2, OL)
	R(n, x - w / 2.0, y - h, w, h, Color("#e8742a"))
	R(n, x - w / 4.0, y - h * 0.55, w / 2.0, h * 0.55, Color("#ffd060"))
	R(n, x, y - h - 3, 1, 2, Color("#e8742a"))

# ------------------------------------------------------------------ tents
# a tent seen from the front at an angle: two roof slopes running back from the front ridge, the door flaps tied back.
# (x, y) = centre of its front foot, w = width. torn = the raided camp's tents (faded, slashed, one flap hanging loose, blood
# sprayed over the cloth and dark on the threshold); red = the band's red wool tent instead of tan hide.
static func tent(n, x: float, y: float, w: float, torn := false, red := false) -> void:
	var c: Array = (WOOL if red else HIDE).duplicate()
	if torn:
		c = [c[0].darkened(0.14), c[1].darkened(0.18), c[2].darkened(0.1)]
	var h := w * 0.6
	var dep := h * 0.42            # how far the ridge runs back (up the screen)
	var l := x - w / 2.0
	var r := x + w / 2.0
	Props.shadow(n, x + 5, y + 1, w * 0.58, 4)
	# outline of the whole shape, then the two roof slopes (left lit, right in shade), then the front triangle
	poly(n, [Vector2(l - 1, y + 1), Vector2(l - 1, y - dep), Vector2(x, y - h - dep - 2), Vector2(r + 1, y - dep), Vector2(r + 1, y + 1)], OL)
	poly(n, [Vector2(l, y), Vector2(l, y - dep), Vector2(x, y - h - dep), Vector2(x, y - h)], c[1])
	poly(n, [Vector2(r, y), Vector2(r, y - dep), Vector2(x, y - h - dep), Vector2(x, y - h)], c[2])
	poly(n, [Vector2(l, y), Vector2(x, y - h), Vector2(r, y)], c[0])
	poly(n, [Vector2(l + 2, y), Vector2(x, y - h + 2), Vector2(x, y)], c[1].lerp(c[0], 0.5))
	# the doorway with its flaps tied back
	var dw := w * 0.28
	poly(n, [Vector2(x - dw, y), Vector2(x, y - h * 0.62), Vector2(x + dw, y)], Color("#1e140e"))
	R(n, x - dw - 2, y - 6, 3, 6, c[2]); R(n, x + dw - 1, y - 6, 3, 6, c[2])
	R(n, x - dw - 1, y - 8, 2, 1, ROPE); R(n, x + dw, y - 8, 2, 1, ROPE)
	# ridge pole and guy ropes to pegs
	R(n, x - 1, y - h - 4, 2, 5, OL); R(n, x - 1, y - h - 4, 1, 4, WD_L)
	R(n, l - 4, y - 1, 2, 2, WD_D); R(n, r + 2, y - 1, 2, 2, WD_D)
	for i in range(4):
		R(n, l - 3 + i, y - 2 - i * 3, 1, 1, ROPE)
		R(n, r + 2 - i, y - 2 - i * 3, 1, 1, ROPE)
	# seams
	R(n, l + w * 0.25, y - h * 0.5, 1, h * 0.5 - 1, c[2])
	if torn:
		# slashes in the cloth and a flap hanging loose at an angle
		for s in [[0.22, 0.45], [0.7, 0.3], [0.62, 0.62]]:
			var sx: float = l + w * s[0]
			var sy: float = y - h * s[1]
			R(n, sx, sy, 1, 1, OL); R(n, sx + 1, sy + 1, 1, 2, OL); R(n, sx + 2, sy + 3, 1, 1, OL)
		poly(n, [Vector2(x + dw - 1, y - h * 0.5), Vector2(x + dw + 9, y - 2), Vector2(x + dw + 4, y)], c[2])
		# blood sprayed across the cloth (fractions of the width / height, all inside the tent's outline), runs down the flaps,
		# and the threshold dark where someone was pulled out
		for s in [[0.18, 0.3, 3, 2], [0.3, 0.5, 2, 2], [0.12, 0.5, 2, 1], [0.74, 0.42, 3, 2], [0.82, 0.2, 2, 1], [0.6, 0.72, 2, 2],
				[0.4, 0.25, 1, 1], [0.86, 0.5, 1, 2], [0.25, 0.15, 1, 2], [0.68, 0.12, 2, 1]]:
			R(n, l + w * s[0], y - h * s[1] - dep * 0.2, s[2], s[3], BLOOD if s[2] > 1 else BLOOD_D)
		R(n, x - dw - 2, y - 5, 2, 4, BLOOD_D); R(n, x + dw - 1, y - 7, 2, 6, BLOOD)
		poly(n, [Vector2(x - dw + 2, y + 1), Vector2(x - 1, y - 4), Vector2(x + dw - 1, y + 1)], BLOOD_D)

# ------------------------------------------------------------------ fire ring
# a ring of stones round a fire. lit = the band's camp fire (animated flames); cold = the raided camp's dead fire (ash, charred logs,
# a thin wisp of smoke). (x, y) = the front of the ring.
static func fire_ring(n, x: float, y: float, lit: bool) -> void:
	var t := Props.now()
	var cy := y - 5.0
	Props.blob(n, x, cy, 13, 6, Color("#241a14"))
	Props.blob(n, x, cy, 10, 4, Color("#5e5650") if not lit else Color("#3a2618"))
	# charred logs, crossed
	R(n, x - 8, cy - 2, 14, 3, OL); R(n, x - 7, cy - 2, 12, 2, Color("#2a1a12"))
	R(n, x - 3, cy - 4, 3, 8, OL); R(n, x - 2, cy - 4, 1, 7, Color("#3a2618"))
	var stones := []
	for i in range(10):
		var a := TAU * i / 10.0
		stones.append(Vector2(x + cos(a) * 14.0, cy + sin(a) * 7.0))
	for p in stones:                 # back half of the ring first
		if p.y < cy:
			_ring_stone(n, p)
	if lit:
		var fl := int(t * 9.0 + x) % 3
		_flame(n, x - 4, cy + 1, 5, 8 + fl * 2)
		_flame(n, x + 3, cy + 1, 6, 11 - fl)
		_flame(n, x, cy + 2, 4, 6 + (fl + 1) % 3 * 2)
		var k := fmod(t * 1.3 + x * 0.01, 1.0)       # a spark rising
		R(n, x - 2 + sin(t * 5.0) * 3.0, cy - 14 - k * 16.0, 1, 1, Color(1.0, 0.85, 0.4, 1.0 - k))
	else:
		R(n, x - 4, cy - 1, 2, 1, Color("#8a6a4a")); R(n, x + 3, cy, 2, 1, Color("#7a5a3a"))
		for i in range(3):           # a thin wisp of smoke
			var ph := fmod(t * 0.35 + i * 0.33, 1.0)
			R(n, x + sin(t * 1.4 + i * 2.0) * 3.0, cy - 4 - ph * 26.0, 2, 2, Color(0.6, 0.58, 0.55, 0.35 * (1.0 - ph)))
	for p in stones:
		if p.y >= cy:
			_ring_stone(n, p)

static func _ring_stone(n, p: Vector2) -> void:
	R(n, p.x - 3, p.y - 2, 7, 5, STN_OL)
	R(n, p.x - 2, p.y - 2, 5, 4, STN)
	R(n, p.x - 2, p.y - 2, 4, 1, STN_L)
	R(n, p.x - 2, p.y + 1, 5, 1, STN_D)

# ------------------------------------------------------------------ camp furniture
# a low plank table on two trestles. (x, y) = centre of the front foot, w = width. items: "food" (bowls, flat bread, a jug),
# "bow" (the caged rider's bow and his gorytos, the Persian bow case, taken from him), "irons" (the jailer's shackles, tongs and
# chain), "" (bare). bloody = a dark splash across the planks and a run down the front (the raided camp)
static func camp_table(n, x: float, y: float, w: float, items := "food", bloody := false) -> void:
	var l := x - w / 2.0
	Props.shadow(n, x + 3, y + 1, w * 0.55, 3)
	for lx in [l + 3, l + w - 6]:
		R(n, lx - 1, y - 9, 5, 10, OL); R(n, lx, y - 8, 3, 8, WD_D); R(n, lx, y - 8, 1, 8, WD)
	Props.ob(n, l, y - 15, w, 6, WD, WD_L, WD_D)
	R(n, l, y - 9, w, 2, WD_D)
	var px := l + 9.0
	while px < l + w - 4:
		R(n, px, y - 15, 1, 6, WD_D)
		px += 9.0
	if bloody:
		Props.blob(n, x - w * 0.12, y - 12, w * 0.2, 2, BLOOD_D)
		Props.blob(n, x - w * 0.16, y - 13, w * 0.1, 1, BLOOD)
		R(n, x - w * 0.22, y - 10, 1, 5, BLOOD_D); R(n, x - w * 0.04, y - 10, 1, 3, BLOOD)
		R(n, l + w - 9, y - 14, 3, 1, BLOOD); R(n, l + w - 6, y - 12, 1, 1, BLOOD_D)
	match items:
		"food":
			Props.blob(n, l + 8, y - 13, 4, 2, OL); Props.blob(n, l + 8, y - 13, 3, 1, Color("#b8744a"))
			Props.blob(n, x + 2, y - 13, 5, 2, Color("#c49a5c")); R(n, x - 1, y - 14, 3, 1, Color("#e0bc7a"))      # flat bread
			R(n, l + w - 10, y - 21, 6, 8, OL); R(n, l + w - 9, y - 20, 4, 6, Color("#b8744a")); R(n, l + w - 9, y - 20, 1, 6, Color("#d08a5a"))
		"bow":
			# a recurved bow lying across the table, its string slack, and the bow case beside it
			for i in range(9):
				var bx := l + 4 + i * 3.0
				var by := y - 13 - absf(sin(float(i) / 8.0 * PI)) * 3.0 + (1.0 if i == 0 or i == 8 else 0.0)
				R(n, bx, by, 3, 2, OL); R(n, bx, by, 3, 1, Color("#7a4a26"))
			R(n, l + 5, y - 12, 24, 1, Color("#e0d4b0"))
			R(n, l + w - 14, y - 16, 10, 5, OL); R(n, l + w - 13, y - 15, 8, 3, Color("#8a3a2a")); R(n, l + w - 13, y - 15, 8, 1, Color("#b05a40"))
			for i in range(3):
				R(n, l + w - 12 + i * 2, y - 18, 1, 3, Color("#e8dcc0"))      # arrow fletchings sticking out of the case
		"irons":
			for sx in [l + 4, l + 11]:                                      # a pair of shackles, joined
				R(n, sx - 1, y - 15, 7, 4, OL); R(n, sx, y - 14, 5, 2, IRON); R(n, sx + 1, y - 14, 3, 1, Color("#1e140e"))
			R(n, l + 9, y - 13, 3, 1, IRON_D)
			R(n, x - 3, y - 14, 12, 1, IRON_L); R(n, x - 3, y - 13, 12, 1, IRON_D); R(n, x + 8, y - 15, 3, 1, IRON_D)      # tongs
			for c in [[0, 0], [3, 0], [1, 2], [4, 2]]:                      # a coil of chain
				R(n, l + w - 11 + c[0], y - 15 + c[1], 3, 2, IRON_D); R(n, l + w - 11 + c[0], y - 15 + c[1], 1, 1, IRON_L)

# a stool for the jailer
static func stool(n, x: float, y: float) -> void:
	Props.shadow(n, x + 2, y + 1, 6, 2)
	R(n, x - 5, y - 8, 10, 4, OL); R(n, x - 4, y - 8, 8, 2, WD_L); R(n, x - 4, y - 6, 8, 1, WD_D)
	R(n, x - 4, y - 4, 2, 5, OL); R(n, x + 2, y - 4, 2, 5, OL)

# a blanket laid out on the ground with a rolled end (flat: sort it by its top edge). (x, y) = top-left, col = blanket colour
static func bedroll(n, x: float, y: float, col: Color) -> void:
	R(n, x - 1, y - 1, 26, 12, OL)
	R(n, x, y, 24, 10, col); R(n, x, y, 24, 1, col.lightened(0.25)); R(n, x, y + 8, 24, 2, col.darkened(0.25))
	for i in range(3):
		R(n, x + 6 + i * 6, y, 1, 10, col.darkened(0.18))
	R(n, x - 2, y - 1, 6, 12, OL); R(n, x - 1, y, 4, 10, col.lightened(0.12)); R(n, x - 1, y, 1, 10, col.lightened(0.3))

# a short fence of sharpened stakes on a rail. (x, y) = left end of its foot, w = length
static func palisade(n, x: float, y: float, w: float) -> void:
	Props.shadow(n, x + w / 2.0 + 3, y + 1, w / 2.0 + 2, 3)
	R(n, x - 1, y - 14, w + 2, 4, OL); R(n, x, y - 13, w, 2, WD_D)
	var sx := x + 1.0
	var i := 0
	while sx < x + w - 2:
		var h := 18.0 + float((i * 7) % 5)
		R(n, sx - 1, y - h, 5, h + 1, OL)
		R(n, sx, y - h + 2, 3, h - 2, WD); R(n, sx, y - h + 2, 1, h - 2, WD_L)
		R(n, sx + 1, y - h, 1, 2, WD_L)
		sx += 6.0
		i += 1
	R(n, x, y - 8, w, 2, ROPE.darkened(0.2)); R(n, x, y - 8, w, 1, ROPE)

# a spiked barricade (sharpened stakes crossed over a log), as dragged across a tunnel. (x, y) = left end of its foot, w = length
static func barricade(n, x: float, y: float, w: float) -> void:
	Props.shadow(n, x + w / 2.0 + 3, y + 1, w / 2.0 + 4, 3)
	var sx := x + 4.0
	while sx < x + w - 4:
		for s in [-1.0, 1.0]:
			var a := Vector2(sx - s * 7.0, y)
			var b := Vector2(sx + s * 7.0, y - 22.0)
			var nrm := Vector2(2, 0)
			poly(n, [a - nrm, b - nrm * 0.4, b + nrm * 0.4, a + nrm], OL)
			poly(n, [a - nrm * 0.5, b, a + nrm * 0.5], WD if s < 0.0 else WD_L)
			R(n, b.x - 1, b.y, 2, 2, Color("#d8c8a0"))
		sx += 14.0
	Props.ob(n, x, y - 9, w, 6, WD, WD_L, WD_D)
	var k := x + 7.0
	while k < x + w - 3:
		R(n, k, y - 9, 2, 6, ROPE)
		k += 14.0

# ------------------------------------------------------------------ the cage and the pens
# The band's cage: lashed wooden poles against the back wall, with a door in the middle of the front. The jail's small pens are the
# same thing, lower and with a narrow door.
# (x, y) = centre of its FRONT foot, w = width, d = depth (front to back). part "back" = back poles and the straw floor
# (drawn behind whoever is inside); part "front" = the side and front poles, the top frame and the door (drawn in front).
# open = 0 shut .. 1 swung wide (the door hangs on its left post and swings out toward you). door = door width, ch = height,
# gap = spacing of the poles across the front and back (the pens' are wider apart, so you can see what lies inside).
const CAGE_H := 34.0
const CAGE_DOOR := 20.0          # door width

static func _pole(n, x: float, foot: float, h: float) -> void:
	R(n, x - 1, foot - h - 1, 4, h + 2, OL)
	R(n, x, foot - h, 2, h, WD); R(n, x, foot - h, 1, h, WD_L)

static func cage(n, x: float, y: float, w: float, d: float, part: String, open := 0.0, door := CAGE_DOOR, ch := CAGE_H, gap := 7.0) -> void:
	var x0 := x - w / 2.0
	var x1 := x + w / 2.0
	var yb := y - d
	if part == "back":
		R(n, x0, yb, w, d, Color("#6a5528"))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(x * 7.0 + y)
		for i in range(int(w * d / 30.0)):
			R(n, x0 + rng.randf() * (w - 5), yb + rng.randf() * (d - 2), rng.randi_range(3, 5), 1, Color("#b08a3a") if rng.randf() < 0.6 else Color("#4e3c1a"))
		var px := x0
		while px <= x1 + 0.5:
			_pole(n, px, yb, ch)
			px += gap
		R(n, x0 - 1, yb - ch - 1, w + 4, 4, OL); R(n, x0, yb - ch, w + 2, 2, WD_L)
		R(n, x0, yb - ch * 0.45, w + 2, 2, WD_D)
		return
	# side walls: poles standing at a few depths down each side, joined by a top rail
	for side in [x0, x1]:
		var fy := yb + 7.0
		while fy < y:
			_pole(n, side, fy, ch)
			fy += 8.0
		R(n, side - 1, yb - ch - 1, 4, d + 2, OL); R(n, side, yb - ch, 2, d, WD_L)
	# the front, with the door in the middle
	var dl := x - door / 2.0
	var dr := x + door / 2.0
	var fx := x0
	while fx <= x1 + 0.5:
		if fx <= dl - 1.0 or fx >= dr + 1.0:
			_pole(n, fx, y, ch)
		fx += gap
	_pole(n, dl - 2.0, y, ch + 2.0)       # door posts
	_pole(n, dr + 1.0, y, ch + 2.0)
	R(n, x0 - 1, y - ch - 1, w + 4, 4, OL); R(n, x0, y - ch, w + 2, 2, WD_L)
	R(n, x0 - 1, y - 13, dl - x0 - 1, 3, OL); R(n, x0, y - 12, dl - x0 - 2, 1, WD_D)
	R(n, dr + 3, y - 13, x1 - dr - 1, 3, OL); R(n, dr + 3, y - 12, x1 - dr - 3, 1, WD_D)
	# the door: a pole every 6-7 px and two cross-bars; it swings out on its left post
	var sw := cos(open * PI * 0.5)
	var drop := sin(open * PI * 0.5) * 9.0
	var poles := maxi(1, int(roundf(door / 7.0)))
	for i in range(poles):
		var off := door / poles * (i + 0.5) * sw
		_pole(n, dl + off, y + drop * (off / door), ch - 4.0)
	for by in [y - ch + 6.0, y - 12.0]:
		R(n, dl, by + drop * 0.4, door * sw, 3, OL); R(n, dl + 1, by + 1 + drop * 0.4, door * sw - 2, 1, WD_L)
	if open < 0.05:
		R(n, dr - 2, y - 20, 3, 4, ROPE); R(n, dr - 1, y - 21, 1, 6, ROPE.darkened(0.3))   # the lashing that holds it shut
	# rope lashings where the rails cross the poles
	var lx := x0 + 3.0
	while lx < x1:
		R(n, lx, y - ch, 1, 2, ROPE)
		lx += 14.0

# what lies on a pen's straw floor, drawn between its back and its front, placed in the clear gaps between the front poles of a
# pen with PEN_GAP spacing. v >= 0: one of the dead, slumped against the back poles (a featureless dark figure; an even v sits in
# the left gap, an odd v in the right one); v < 0: an empty pen, a wooden bowl and an open cuff left in the straw.
# (x, y) = the pen's centre, a little behind its front foot
const PEN_GAP := 11.0
static func pen_inside(n, x: float, y: float, v := -1) -> void:
	if v < 0:
		Props.blob(n, x - 11, y - 2, 4, 2, OL); Props.blob(n, x - 11, y - 2, 3, 1, WD); R(n, x - 13, y - 3, 3, 1, WD_D)
		R(n, x + 9, y - 3, 6, 4, OL); R(n, x + 10, y - 2, 4, 2, IRON); R(n, x + 11, y - 2, 2, 1, Color("#1e140e"))
		return
	x += -10.0 if v % 2 == 0 else 11.0
	var s := 1.0 if v % 2 == 0 else -1.0
	Props.blob(n, x + 2, y, 8, 3, Color("#2a0e0c"))
	# knees drawn up toward us, the back against the poles, the head fallen onto one shoulder, an arm hanging
	poly(n, [Vector2(x - 6, y + 1), Vector2(x - 4, y - 6), Vector2(x + 1, y - 7), Vector2(x + 3, y - 2), Vector2(x + 6, y + 1)], SIL)
	poly(n, [Vector2(x - 5, y - 3), Vector2(x - 5 + s, y - 15), Vector2(x + 3 + s, y - 16), Vector2(x + 4, y - 4)], SIL)
	Props.blob(n, x + s * 3.0, y - 16, 3.5, 3.5, SIL)
	R(n, x + s * 4.0 - 1, y - 12, 2, 7, SIL)

# a scrap of leather with charcoal writing, dropped in a pen (Stage 7j, cave.gd NOTE: a rider's last note, read with E). Pale enough to
# catch the eye between the poles. (x, y) = its middle
static func leather_note(n, x: float, y: float) -> void:
	R(n, x - 4, y - 3, 9, 5, OL)
	R(n, x - 3, y - 2, 7, 3, Color("#d0aa78")); R(n, x - 3, y - 2, 7, 1, Color("#ecc898")); R(n, x + 3, y, 1, 1, Color("#a88458"))
	R(n, x - 2, y - 1, 3, 1, Color("#2a1a10")); R(n, x - 2, y, 2, 1, Color("#2a1a10")); R(n, x + 1, y, 1, 1, Color("#2a1a10"))

# ------------------------------------------------------------------ the chief's corner
# the chief's seat: crates under a dark hide and a red wool cushion, a plank backrest crowned with a pair of ibex horns.
# (x, y) = centre of the front foot
static func chief_seat(n, x: float, y: float) -> void:
	Props.shadow(n, x + 4, y + 1, 20, 4)
	Props.ob(n, x - 14, y - 44, 28, 30, WD, WD_L, WD_D)          # backrest
	R(n, x - 5, y - 44, 1, 30, WD_D); R(n, x + 4, y - 44, 1, 30, WD_D)
	for s in [-1.0, 1.0]:                                           # ibex horns curving back over the top
		for i in range(7):
			var hx: float = x + s * (3.0 + i * 1.6)
			var hy: float = y - 46 - i * 2.2 + (i * i) * 0.35
			R(n, hx - 1, hy - 1, 4, 4, OL); R(n, hx, hy, 2, 2, Color("#d8c8a0"))
	Props.ob(n, x - 18, y - 18, 36, 18, Color("#b08040"), Color("#d8a868"), Color("#6e4a24"))     # crate base
	R(n, x - 18, y - 10, 36, 1, Color("#6e4a24")); R(n, x - 1, y - 18, 2, 18, Color("#8a5e30"))
	# a dark hide over the seat, hanging down the front, with pale spots
	poly(n, [Vector2(x - 19, y - 19), Vector2(x + 19, y - 19), Vector2(x + 16, y - 6), Vector2(x + 6, y - 9), Vector2(x - 4, y - 5), Vector2(x - 17, y - 8)], OL)
	poly(n, [Vector2(x - 18, y - 18), Vector2(x + 18, y - 18), Vector2(x + 15, y - 7), Vector2(x + 6, y - 10), Vector2(x - 4, y - 6), Vector2(x - 16, y - 9)], Color("#5a3a22"))
	for p in [[-10, -15], [-2, -12], [7, -15], [12, -11], [-13, -11]]:
		R(n, x + p[0], y + p[1], 2, 1, Color("#a8865a"))
	R(n, x - 10, y - 24, 20, 6, OL); R(n, x - 9, y - 23, 18, 4, WOOL[0]); R(n, x - 9, y - 23, 18, 1, WOOL[1])        # cushion

# the band's banner: dark red wool on a crossbar pole, ragged at the bottom, with a pale painted ibex-horn mark
# (a plain mark of their own: no royal winged disc, no sun wheel). (x, y) = foot of the pole
static func band_banner(n, x: float, y: float, w: float, h: float) -> void:
	var t := Props.now()
	var top := y - h - 14.0
	Props.shadow(n, x + 3, y + 1, 5, 2)
	R(n, x - 2, top - 1, 4, h + 16, OL); R(n, x - 1, top, 2, h + 14, WD); R(n, x - 1, top, 1, h + 14, WD_L)
	R(n, x - w / 2.0 - 2, top + 1, w + 4, 4, OL); R(n, x - w / 2.0 - 1, top + 2, w + 2, 2, WD_L)
	var cl := x - w / 2.0
	var ch := h * 0.72
	var sway := roundf(sin(t * 1.1 + x) * 0.8)
	R(n, cl - 1, top + 4, w + 2, ch + 2, OL)
	R(n, cl, top + 5, w, ch, WOOL[0]); R(n, cl, top + 5, 2, ch, WOOL[1]); R(n, cl + w - 3, top + 5, 3, ch, WOOL[2])
	var bx := cl
	var k := 0
	while bx < cl + w:          # ragged bottom edge
		R(n, bx + sway, top + 5 + ch, 3, 2 + (k % 2) * 3, WOOL[0] if k % 3 != 2 else WOOL[2])
		bx += 3.0
		k += 1
	# the mark: two horns curving out from a short bar
	var mx := x
	var my := top + 5 + ch * 0.45
	R(n, mx - 4, my + 4, 9, 2, Color("#d8b878"))
	for s in [-1.0, 1.0]:
		for i in range(6):
			R(n, mx + s * (2.0 + i * 1.3) - (1.0 if s < 0.0 else 0.0), my + 3 - i * 2.0 + (i * i) * 0.25, 2, 2, Color("#d8b878"))

# a rough iron fire bowl on three legs (the band's, not the king's gold brazier). Animated flame.
static func fire_bowl(n, x: float, y: float) -> void:
	var t := Props.now()
	Props.shadow(n, x + 3, y + 1, 8, 3)
	for lx in [-6, -1, 4]:
		R(n, x + lx - 1, y - 12, 3, 13, OL); R(n, x + lx, y - 12, 1, 12, IRON_L)
	R(n, x - 9, y - 19, 19, 8, OL); R(n, x - 8, y - 18, 17, 6, IRON); R(n, x - 8, y - 18, 17, 1, IRON_L); R(n, x - 8, y - 14, 17, 2, IRON_D)
	var fl := int(t * 9.0 + x) % 3
	_flame(n, x, y - 18, 8, 8 + fl * 2)

# a wooden chest bound with iron. (x, y) = centre of the front foot, w = width. open = the lid thrown back and gold showing inside
static func chest(n, x: float, y: float, open := false, w := 18.0) -> void:
	var l := x - w / 2.0
	Props.shadow(n, x + 3, y + 1, w * 0.6, 3)
	if open:
		Props.ob(n, l, y - 24, w, 8, WD_D, WD, OL)                                   # the lid, thrown back
		R(n, l + 3, y - 24, 2, 8, IRON_D); R(n, l + w - 5, y - 24, 2, 8, IRON_D)
		Props.ob(n, l, y - 16, w, 5, Color("#6a4224"), WD, WD_D)                     # the open top, heaped with coin
		Props.blob(n, x, y - 14, w / 2.0 - 2, 2, GOLD_D); Props.blob(n, x - 1, y - 15, w / 2.0 - 4, 2, GOLD)
		R(n, x - 3, y - 16, 2, 1, GOLD_L)
	else:
		Props.ob(n, l - 1, y - 17, w + 2, 6, WD, WD_L, WD_D)                          # the lid
		R(n, l + 3, y - 17, 2, 6, IRON_D); R(n, l + w - 5, y - 17, 2, 6, IRON_D)
	Props.ob(n, l, y - 11, w, 11, WD, WD_L, WD_D)                                     # the body
	for bx in [l + 3, l + w - 5]:
		R(n, bx, y - 11, 2, 11, IRON_D); R(n, bx, y - 11, 1, 11, IRON_L)
	if not open:
		R(n, x - 2, y - 12, 4, 4, IRON_D); R(n, x - 1, y - 11, 2, 2, GOLD_D)            # the hasp

# the chief's hoard, heaped against the wall behind his seat: a mound of gold darics, chests (one open), gold bowls (phialai)
# lying on the heap, coins spilled in front, and a glint that wanders over it (animated). (x, y) = centre of the front foot, w = width
static func hoard(n, x: float, y: float, w: float) -> void:
	var t := Props.now()
	var hw := w / 2.0
	Props.shadow(n, x + 5, y + 1, hw + 2, 4)
	chest(n, x - hw * 0.45, y - 14, false, 20.0)                                       # a chest at the back of the heap
	# the mound: a low heap across the whole width and two higher piles either side of the middle (where his seat stands in
	# front), each an outline, dark gold, gold, then a lit crest toward the top-left
	for m in [[0.0, 1.0, 9.0], [-0.52, 0.48, 15.0], [0.52, 0.48, 13.0]]:
		var mx: float = x + hw * m[0]
		var mr: float = hw * m[1]
		var mh: float = m[2]
		Props.blob(n, mx, y - 7, mr + 1, mh + 1, OL)
		Props.blob(n, mx, y - 7, mr, mh, GOLD_D)
		Props.blob(n, mx - 2, y - 9, mr * 0.75, mh * 0.75, GOLD)
		Props.blob(n, mx - mr * 0.25, y - 7 - mh * 0.6, mr * 0.35, 2, GOLD_L)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 3.0 + y)
	for i in range(int(w * 1.2)):                                                      # single coins catching the light
		var cx := x + rng.randf_range(-hw + 4, hw - 4)
		var top := y - 7 - 12.0 * sqrt(maxf(0.0, 1.0 - pow((cx - x) / hw, 2.0)))
		R(n, cx, rng.randf_range(top + 1, y - 1), 2, 1, GOLD_L if rng.randf() < 0.35 else (GOLD_D if rng.randf() < 0.5 else GOLD))
	for b in [[-0.55, -18], [0.5, -15], [0.8, -6]]:                                     # gold bowls lying on the heap
		var bx: float = x + hw * b[0]
		var by: float = y + b[1]
		Props.blob(n, bx, by, 5, 2, OL); Props.blob(n, bx, by, 4, 1.5, GOLD); R(n, bx - 1, by - 1, 2, 1, GOLD_L)
	chest(n, x + hw * 0.62, y + 2, true, 18.0)                                          # an open chest at the front
	chest(n, x - hw * 0.78, y + 3, false, 16.0)
	for i in range(14):                                                                 # coins spilled on the ground
		R(n, x + rng.randf_range(-hw, hw), y + rng.randf_range(-1, 4), 2, 1, GOLD if rng.randf() < 0.6 else GOLD_D)
	var g := int(t * 2.0) % 6                                                          # a glint wandering over the heap
	var gx: float = x + [-0.5, 0.1, 0.4, -0.2, 0.6, -0.7][g] * hw
	var gy: float = y - [12, 14, 9, 8, 6, 5][g]
	R(n, gx, gy - 1, 1, 3, Color(1, 1, 0.9)); R(n, gx - 1, gy, 3, 1, Color(1, 1, 0.9))

# the chief's war table: a heavy plank table with a painted hide map on it (the roads his band watches, marked in red), an
# akinakes lying across one end, rolled scrolls and a small clay oil lamp (its flame is animated). (x, y) = centre of the front foot
static func war_table(n, x: float, y: float, w: float) -> void:
	var t := Props.now()
	var l := x - w / 2.0
	Props.shadow(n, x + 4, y + 1, w * 0.55, 4)
	for lx in [l + 3, l + w - 7]:
		R(n, lx - 1, y - 11, 5, 12, OL); R(n, lx, y - 10, 3, 10, WD_D); R(n, lx, y - 10, 1, 10, WD)
	Props.ob(n, l, y - 28, w, 17, WD, WD_L, WD_D)                                     # the top, seen from above
	R(n, l, y - 12, w, 2, WD_D); R(n, l, y - 12, w, 1, OL)
	var px := l + 11.0
	while px < l + w - 4:
		R(n, px, y - 28, 1, 16, WD_D)
		px += 11.0
	# the map: pale hide with ragged corners, red roads joining dark marks (camps, wells), a black blot where the band sits
	var mx := l + w * 0.24
	var mw := w * 0.48
	R(n, mx - 1, y - 27, mw + 2, 13, OL); R(n, mx, y - 26, mw, 11, Color("#d8c08a")); R(n, mx, y - 26, mw, 1, Color("#ecd8a8"))
	R(n, mx, y - 26, 2, 1, OL); R(n, mx + mw - 2, y - 17, 2, 2, OL)
	var road := [Vector2(mx + 2, y - 18), Vector2(mx + mw * 0.3, y - 22), Vector2(mx + mw * 0.55, y - 19), Vector2(mx + mw * 0.8, y - 24), Vector2(mx + mw - 3, y - 21)]
	for i in range(road.size() - 1):
		_line(n, road[i], road[i + 1], Color("#a8372b"))
	_line(n, road[2], Vector2(mx + mw * 0.5, y - 16), Color("#a8372b"))
	for p in road:
		R(n, p.x - 1, p.y - 1, 2, 2, Color("#3a2517"))
	R(n, mx + mw * 0.8 - 2, y - 25, 4, 3, Color("#1e140e"))
	# the akinakes: a short straight blade with a cross-guard, lying across the right end
	R(n, l + w - 19, y - 21, 13, 1, Color("#d0d4da")); R(n, l + w - 19, y - 20, 13, 1, Color("#8a8e96"))
	R(n, l + w - 20, y - 23, 1, 5, GOLD_D); R(n, l + w - 24, y - 21, 4, 2, WD_D); R(n, l + w - 25, y - 22, 2, 3, GOLD_D)
	# rolled scrolls and the oil lamp on the left
	for s in [[3, -16], [5, -13]]:
		R(n, l + s[0] - 1, y + s[1] - 1, 10, 3, OL); R(n, l + s[0], y + s[1], 8, 1, Color("#e8dcc0"))
	Props.blob(n, l + 7, y - 22, 4, 2, OL); Props.blob(n, l + 7, y - 22, 3, 1.5, Color("#b8744a")); R(n, l + 10, y - 23, 2, 1, Color("#8a5434"))
	var fl := int(t * 9.0 + x) % 2
	R(n, l + 11, y - 26 - fl, 1, 2 + fl, Color("#ffd060")); R(n, l + 11, y - 24, 1, 1, Color("#e8742a"))

# ------------------------------------------------------------------ the loot strewn over the boss room
# a leather bag of coin, tied at the neck, a few coins spilled beside it. (x, y) = foot
static func coin_bag(n, x: float, y: float) -> void:
	Props.shadow(n, x + 2, y + 1, 5, 2)
	Props.blob(n, x, y - 4, 5, 4, OL)
	Props.blob(n, x, y - 4, 4, 3, Color("#8a6238"))
	Props.blob(n, x - 1, y - 5, 2, 1, Color("#b08458"))
	R(n, x - 2, y - 10, 4, 3, OL); R(n, x - 1, y - 10, 2, 1, GOLD_L)                  # gold showing at the neck
	R(n, x - 2, y - 8, 4, 1, ROPE)
	for c in [[4, -1, GOLD], [6, 0, GOLD_D], [3, 1, GOLD_L], [8, -2, GOLD], [-6, 0, GOLD], [5, 2, GOLD_D]]:     # coins spilled beside it
		R(n, x + c[0], y + c[1], 2, 1, c[2])

# a handful of coins spilled flat on the ground (sort it by its top edge). (x, y) = the middle
static func coins(n, x: float, y: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 5.0 + y)
	for i in range(12):
		var cx := x + rng.randf_range(-8, 8)
		var cy := y + rng.randf_range(-3, 3)
		R(n, cx, cy + 1, 2, 1, GOLD_D); R(n, cx, cy, 2, 1, GOLD if rng.randf() < 0.7 else GOLD_L)

# a heavy iron-bound chest standing open on two crates (tall: it hides you, stops a stone and dazes a charging chief).
# (x, y) = centre of the front foot
static func strongbox(n, x: float, y: float) -> void:
	Props.crate(n, x - 7, y)
	Props.crate(n, x + 7, y)
	chest(n, x, y - 14, true, 24.0)

# an ibex skull lying on the ground, the band's own mark: a long face, dark eye holes, two long ridged horns sweeping back.
# (x, y) = the muzzle's foot
static func ibex_skull(n, x: float, y: float) -> void:
	var bone := Color("#d8c8a0")
	var bone_d := Color("#a8987a")
	Props.shadow(n, x + 3, y + 1, 7, 2)
	for s in [-1.0, 1.0]:
		for i in range(7):
			var hx: float = x + s * (2.0 + i * 1.2) - (1.0 if s < 0.0 else 0.0)
			var hy: float = y - 9 - i * 2.0 + (i * i) * 0.18
			R(n, hx - 1, hy - 1, 4, 4, OL); R(n, hx, hy, 2, 2, bone if i % 2 == 0 else bone_d)
	poly(n, [Vector2(x - 5, y - 11), Vector2(x + 5, y - 11), Vector2(x + 3, y - 2), Vector2(x + 1, y), Vector2(x - 1, y), Vector2(x - 3, y - 2)], OL)
	poly(n, [Vector2(x - 4, y - 10), Vector2(x + 4, y - 10), Vector2(x + 2, y - 2), Vector2(x, y - 1), Vector2(x - 2, y - 2)], bone)
	R(n, x - 3, y - 9, 1, 6, bone.lightened(0.2))
	R(n, x - 3, y - 8, 2, 2, Color("#2a1c12")); R(n, x + 1, y - 8, 2, 2, Color("#2a1c12"))
	R(n, x + 1, y - 5, 1, 3, bone_d)

# ------------------------------------------------------------------ what the raid left behind (no bodies: see the design doc's tone rule)
# a royal rider's wicker shield lying flat, a broken spear and two arrows. (x, y) = the shield's centre
static func dropped_gear(n, x: float, y: float) -> void:
	# spear in two pieces, bronze head
	R(n, x - 22, y + 3, 16, 3, OL); R(n, x - 21, y + 4, 14, 1, WD_L)
	R(n, x + 6, y - 6, 20, 3, OL); R(n, x + 7, y - 5, 18, 1, WD_L)
	R(n, x + 25, y - 7, 6, 5, OL); R(n, x + 26, y - 6, 4, 3, Color("#c89a48")); R(n, x + 26, y - 6, 4, 1, Color("#e8c070"))
	# the shield, flat on the ground
	Props.blob(n, x, y, 11, 7, OL)
	Props.blob(n, x, y, 10, 6, Color("#b08a4a"))
	Props.blob(n, x - 2, y - 1, 5, 3, Color("#d0aa66"))
	for i in range(3):
		R(n, x - 8, y - 3 + i * 3, 16, 1, Color("#8a6a34"))
	# arrows
	for a in [[-14, -8], [10, 8]]:
		R(n, x + a[0], y + a[1], 12, 1, Color("#e0d4b0")); R(n, x + a[0], y + a[1] - 1, 3, 3, Color("#a8372b"))

# a clay pot knocked on its side, its grain spilled
static func spilled_pot(n, x: float, y: float) -> void:
	Props.blob(n, x + 9, y - 1, 9, 3, Color("#8a6a2c")); Props.blob(n, x + 8, y - 2, 6, 2, Color("#d4a94c"))
	Props.blob(n, x, y - 5, 8, 6, OL)
	Props.blob(n, x, y - 5, 7, 5, Color("#b8744a"))
	Props.blob(n, x - 2, y - 7, 3, 2, Color("#d08a5a"))
	Props.blob(n, x + 6, y - 5, 2, 4, Color("#2a1810"))

# three spent arrows standing in the ground where they fell short or went through (the raid). (x, y) = where the middle one stands
static func arrows_stuck(n, x: float, y: float) -> void:
	for a in [[-6, 1, -2], [0, 0, 1], [5, 2, 3]]:
		var ax: float = x + a[0]
		var ay: float = y + a[1]
		var lean: float = a[2]
		for i in range(10):                       # the shaft, leaning a little
			R(n, ax + lean * i / 10.0, ay - i, 1, 1, Color("#e0d4b0") if i < 8 else OL)
		R(n, ax + lean * 0.8 - 1, ay - 11, 3, 3, Color("#a8372b"))     # fletching
		R(n, ax - 1, ay, 3, 1, Color("#3a1a10"))

# a spear snapped in two, the pieces lying crossed on the ground, its bronze leaf head on one of them (flat: sort it by its
# top edge). (x, y) = where they cross
static func broken_spear(n, x: float, y: float) -> void:
	_shaft(n, Vector2(x - 14, y - 6), Vector2(x + 9, y + 3), WD_L)
	_shaft(n, Vector2(x - 8, y + 5), Vector2(x + 12, y - 5), WD)
	R(n, x + 9, y + 2, 2, 2, Color("#d8c8a0")); R(n, x - 9, y + 4, 2, 2, Color("#d8c8a0"))          # the splintered ends
	poly(n, [Vector2(x + 11, y - 7), Vector2(x + 20, y - 10), Vector2(x + 13, y - 3)], OL)
	poly(n, [Vector2(x + 12, y - 6), Vector2(x + 18, y - 9), Vector2(x + 13, y - 4)], Color("#c89a48"))

# a strip of a rider's red tunic snagged on a broken stake, dark with old blood. (x, y) = the stake's foot
static func torn_cloth(n, x: float, y: float) -> void:
	Props.shadow(n, x + 3, y + 1, 5, 2)
	R(n, x - 2, y - 15, 4, 16, OL); R(n, x - 1, y - 14, 2, 14, WD); R(n, x - 1, y - 14, 1, 14, WD_L)
	R(n, x - 1, y - 17, 1, 3, OL); R(n, x, y - 16, 1, 2, WD_L)                        # the splintered top
	poly(n, [Vector2(x + 1, y - 12), Vector2(x + 9, y - 10), Vector2(x + 7, y - 4), Vector2(x + 10, y - 1), Vector2(x + 2, y - 5)], OL)
	poly(n, [Vector2(x + 2, y - 11), Vector2(x + 8, y - 9), Vector2(x + 6, y - 4), Vector2(x + 8, y - 2), Vector2(x + 2, y - 6)], Color("#7a2e22"))
	R(n, x + 3, y - 10, 3, 1, Color("#a84a38"))
	R(n, x + 4, y - 7, 2, 2, Color("#3a1210")); R(n, x + 6, y - 4, 1, 2, Color("#3a1210"))     # the dark of old blood

# ------------------------------------------------------------------ the jail's instruments (wood, leather, rope and iron of the period; empty)
# a frame of two posts and a beam with chains hanging from it, each ending in an open cuff; the ground dark beneath.
# (x, y) = centre of the foot
static func chain_frame(n, x: float, y: float) -> void:
	Props.shadow(n, x + 4, y + 1, 15, 3)
	Props.blob(n, x, y - 1, 8, 2, Color("#3a1210"))
	for px in [x - 13, x + 10]:
		R(n, px - 1, y - 38, 5, 39, OL); R(n, px, y - 37, 3, 37, WD_D); R(n, px, y - 37, 1, 37, WD)
	Props.ob(n, x - 16, y - 41, 32, 5, WD, WD_L, WD_D)                  # the beam
	R(n, x - 13, y - 35, 3, 1, ROPE); R(n, x + 10, y - 35, 3, 1, ROPE)   # lashed to the posts
	for c in [[-5, 21], [3, 15]]:
		var cx: float = x + c[0]
		var drop: int = c[1]
		for i in range(int(drop / 3.0)):
			R(n, cx, y - 36 + i * 3, 2, 3, IRON_D); R(n, cx, y - 36 + i * 3, 1, 1, IRON_L)
		var cy: float = y - 36 + drop
		R(n, cx - 2, cy, 6, 4, OL); R(n, cx - 1, cy + 1, 4, 2, IRON); R(n, cx, cy + 1, 2, 1, Color("#1e140e"))

# a heavy plank bench with leather straps buckled across it, old blood soaked into the wood. (x, y) = centre of the front foot
static func strap_bench(n, x: float, y: float) -> void:
	var w := 40.0
	var l := x - w / 2.0
	Props.shadow(n, x + 4, y + 1, 22, 4)
	for lx in [l + 2, l + w - 6]:
		R(n, lx - 1, y - 9, 5, 10, OL); R(n, lx, y - 8, 3, 8, WD_D); R(n, lx, y - 8, 1, 8, WD)
	Props.ob(n, l, y - 22, w, 12, WD, WD_L, WD_D)                       # the top, the planks running along it
	R(n, l + 1, y - 18, w - 2, 1, WD_D); R(n, l + 1, y - 14, w - 2, 1, WD_D)
	R(n, l, y - 11, w, 3, WD_D); R(n, l, y - 11, w, 1, OL)              # the front edge
	Props.blob(n, x - 3, y - 16, 8, 3, BLOOD_D)
	Props.blob(n, x - 5, y - 17, 4, 1, BLOOD)
	R(n, x - 6, y - 11, 1, 4, BLOOD_D); R(n, x + 2, y - 11, 1, 3, BLOOD)
	for sx in [l + 7, l + 19, l + 31]:                                   # the straps, hanging over the front
		R(n, sx - 1, y - 23, 5, 16, OL); R(n, sx, y - 22, 3, 14, Color("#5a3a1e")); R(n, sx, y - 22, 1, 14, Color("#7a5230"))
		R(n, sx, y - 17, 3, 2, IRON_L)
	R(n, l + w - 4, y - 21, 3, 3, IRON_D)                                # a ring bolt at the head end

# a pallet of loose straw on the ground (flat: sort it by its top edge). (x, y) = top-left
static func straw_mat(n, x: float, y: float) -> void:
	R(n, x - 1, y - 1, 26, 12, OL)
	R(n, x, y, 24, 10, Color("#9a7a34"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x * 13.0 + y)
	for i in range(24):
		R(n, x + rng.randf() * 20.0, y + rng.randf() * 9.0, rng.randi_range(3, 5), 1, Color("#d8b860") if rng.randf() < 0.55 else Color("#6a4e1e"))
	R(n, x, y + 9, 24, 1, Color("#6a4e1e"))

# a low iron bowl of coals with two irons resting in them, their tips glowing. (x, y) = foot
static func brand_bowl(n, x: float, y: float) -> void:
	var t := Props.now()
	Props.shadow(n, x + 3, y + 1, 9, 3)
	for lx in [-6, 4]:
		R(n, x + lx - 1, y - 7, 3, 8, OL); R(n, x + lx, y - 7, 1, 7, IRON_L)
	R(n, x - 10, y - 13, 21, 7, OL); R(n, x - 9, y - 12, 19, 5, IRON); R(n, x - 9, y - 12, 19, 1, IRON_L); R(n, x - 9, y - 9, 19, 2, IRON_D)
	var glow := 0.75 + 0.25 * sin(t * 3.0 + x)
	R(n, x - 7, y - 13, 15, 2, Color(0.9, 0.35 * glow + 0.1, 0.1, 1.0))                                # the coals
	R(n, x - 4, y - 14, 3, 1, Color(1.0, 0.75, 0.3, glow))
	for ir in [[-3, -1], [3, 1]]:                                 # the irons: handles out to the side, tips in the coals
		var hx: float = x + ir[0] * 4.0
		R(n, hx - 1, y - 22, 2, 10, IRON_D); R(n, hx - 1, y - 22, 1, 10, IRON_L)
		R(n, hx - 2, y - 24, 4, 3, WD_D)
	var k := fmod(t * 0.9 + x * 0.01, 1.0)                       # a thread of heat rising
	R(n, x + sin(t * 2.0) * 2.0, y - 15 - k * 12.0, 1, 1, Color(1.0, 0.6, 0.3, 0.7 * (1.0 - k)))

# ------------------------------------------------------------------ the boss room's stakes
# A tall upright stake with a captive bound to it, seen from far off in the gloom: a near-black, featureless silhouette (no face,
# no wounds; the design doc lets the boss room show this much, never more). v = variant (lean of the head and body). (x, y) = foot
static func stake_captive(n, x: float, y: float, v := 0) -> void:
	var sil := Color("#141010")
	var lean: float = [0.0, 1.0, -1.0][v % 3]
	Props.shadow(n, x + 4, y + 1, 6, 3)
	Props.blob(n, x + 2, y - 1, 9, 3, Color("#2a0e0c"))
	R(n, x - 2, y - 58, 5, 59, OL); R(n, x - 1, y - 57, 3, 57, WD_D); R(n, x - 1, y - 57, 1, 57, WD)      # the stake
	R(n, x - 1, y - 61, 3, 3, OL)                                                                          # its sharpened top
	# the body hanging from the lashings, feet off the ground, head bowed to one side
	var by := y - 14.0
	poly(n, [Vector2(x - 5, by - 28), Vector2(x + 5, by - 28), Vector2(x + 4 + lean, by - 6), Vector2(x + 2 + lean, by), Vector2(x - 2 + lean, by), Vector2(x - 4 + lean, by - 6)], sil)
	poly(n, [Vector2(x - 5, by - 28), Vector2(x - 8, by - 38), Vector2(x - 6, by - 39), Vector2(x - 3, by - 28)], sil)   # arms bound up behind
	poly(n, [Vector2(x + 5, by - 28), Vector2(x + 8, by - 38), Vector2(x + 6, by - 39), Vector2(x + 3, by - 28)], sil)
	Props.blob(n, x + lean * 2.0 + 1.0, by - 31, 4, 4, sil)                                                 # the bowed head
	for ry in [by - 26, by - 12, y - 52]:                                                                    # the ropes, pale in the dark
		R(n, x - 4, ry, 9, 1, ROPE.darkened(0.45))
	R(n, x - 1, by + 2, 1, 6, Color("#2a0e0c")); R(n, x + 2, by + 4, 1, 5, Color("#2a0e0c"))                # dark runs down the stake

# a bare stake with cut ropes (where the captain was bound, once he is cut down). (x, y) = foot
static func bare_stake(n, x: float, y: float, cut := false) -> void:
	Props.shadow(n, x + 4, y + 1, 5, 2)
	Props.blob(n, x + 2, y - 1, 8, 3, Color("#2a0e0c"))
	R(n, x - 2, y - 58, 5, 59, OL); R(n, x - 1, y - 57, 3, 57, WD_D); R(n, x - 1, y - 57, 1, 57, WD)
	R(n, x - 1, y - 61, 3, 3, OL)
	if cut:
		R(n, x - 3, y - 40, 7, 2, OL); R(n, x - 2, y - 40, 5, 1, ROPE)
		R(n, x + 3, y - 39, 1, 7, ROPE.darkened(0.3)); R(n, x - 3, y - 39, 1, 5, ROPE.darkened(0.3))

# the ropes across a living captive bound to his stake (drawn in front of him until he is cut down). (x, y) = the stake's foot
static func captive_ropes(n, x: float, y: float) -> void:
	for ry in [y - 30, y - 22, y - 9]:
		R(n, x - 7, ry - 1, 15, 3, OL); R(n, x - 6, ry, 13, 1, ROPE)

# ------------------------------------------------------------------ the mouth
# daylight falling in at the cave mouth: soft warm shafts and drifting dust. The node drawing it uses an additive, unshaded
# material (cave.gd sets it), so it brightens the dark instead of being darkened by it. (x, y) = the middle of the opening, w = width
static func daylight(n, x: float, y: float, w: float, h: float) -> void:
	var t := Props.now()
	for i in range(4):
		var sx := x - w * 0.4 + i * w * 0.27
		var a := 0.05 + 0.02 * sin(t * 0.7 + i * 1.9)
		poly(n, [Vector2(sx - 10, y), Vector2(sx + 12, y), Vector2(sx + 6 - i * 3, y - h), Vector2(sx - 4 - i * 3, y - h)], Color(1.0, 0.92, 0.72, a))
	for i in range(14):
		var ph := fmod(t * 0.08 + i * 0.071, 1.0)
		var dx := x - w * 0.45 + fmod(i * 37.0, w * 0.9) + sin(t * 0.6 + i) * 4.0
		R(n, dx, y - ph * h, 1, 1, Color(1.0, 0.95, 0.8, 0.5 * sin(ph * PI)))
