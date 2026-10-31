extends RefCounted
# terrain.gd - paints the ground of the map into one big image: sand, dunes, dirt roads, packed town floor,
# rock cliffs, the river, the bridge deck, flights of steps, cave ground (floor, stone rim, rock faces from a floor mask) and the
# cave's blood (pools, spatter, drag marks).
# Everything here is baked once at start-up (no per-frame cost).
# Anything that stands up (trees, pillars, walls, torches...) is NOT here; those are y-sorted props (props.gd).

const SAND := "#dba94f"
const SAND_L := "#e9c36d"
const SAND_D := "#c4953f"
const SAND_DD := "#b58437"

# rock palette (cliffs and boulders)
const OUT := "#3a2517"
const TOP := "#b98a5e"
const TOP_L := "#d3a475"
const TOP_D := "#9a6e48"
const FACE := "#8a5c3c"
const FACE_D := "#6c432a"
const FACE_DD := "#4d2e1d"

var img: Image
var rng := RandomNumberGenerator.new()
var W := 0
var H := 0
var _blobs := {}

func _init(w: int, h: int) -> void:
	W = w
	H = h
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	rng.seed = 11

# ------------------------------------------------------------------ tiny helpers
static func K(h: String) -> Color:
	return Color.html(h)

func f(x: float, y: float, w: float, h: float, c) -> void:
	var col: Color = Color.html(c) if c is String else c
	img.fill_rect(Rect2i(int(x), int(y), int(w), int(h)), col)

func px(x: int, y: int, c) -> void:
	if x < 0 or y < 0 or x >= W or y >= H:
		return
	img.set_pixel(x, y, Color.html(c) if c is String else c)

# rectangle with the corners nibbled off (r = 2 or 3)
func rr(x: float, y: float, w: float, h: float, c, r := 2) -> void:
	var col: Color = Color.html(c) if c is String else c
	var xi := int(x); var yi := int(y); var wi := int(w); var hi := int(h)
	img.fill_rect(Rect2i(xi + r, yi, wi - 2 * r, hi), col)
	img.fill_rect(Rect2i(xi, yi + r, wi, hi - 2 * r), col)
	img.fill_rect(Rect2i(xi + 1, yi + 1, wi - 2, hi - 2), col)
	if r >= 3:
		img.fill_rect(Rect2i(xi + 2, yi + 1, wi - 4, hi - 2), col)

func disc(cx: float, cy: float, r: float, c) -> void:
	var col: Color = Color.html(c) if c is String else c
	var ri := int(r)
	for dy in range(-ri, ri + 1):
		var dx := int(sqrt(maxf(0.0, r * r - dy * dy)))
		img.fill_rect(Rect2i(int(cx) - dx, int(cy) + dy, dx * 2 + 1, 1), col)

# soft round patch of colour with ordered-dither banding (keeps the pixel look)
func _blob_img(r: int, col: Color, strength: float) -> Image:
	var key := "%d_%s_%.2f" % [r, col.to_html(), strength]
	if _blobs.has(key):
		return _blobs[key]
	var b := Image.create(r * 2, r * 2, false, Image.FORMAT_RGBA8)
	var bayer := [[0.0, 0.5, 0.125, 0.625], [0.75, 0.25, 0.875, 0.375], [0.1875, 0.6875, 0.0625, 0.5625], [0.9375, 0.4375, 0.8125, 0.3125]]
	for y in range(r * 2):
		for x in range(r * 2):
			var d := Vector2(x - r + 0.5, y - r + 0.5).length() / r
			if d >= 1.0:
				continue
			var v := (1.0 - d) * 3.2
			var lvl := floorf(v + bayer[y % 4][x % 4] - 0.4)
			if lvl >= 1.0:
				b.set_pixel(x, y, Color(col.r, col.g, col.b, strength * minf(lvl / 3.0, 1.0)))
	_blobs[key] = b
	return b

func patch(cx: float, cy: float, r: int, col: Color, strength := 0.5) -> void:
	var b := _blob_img(r, col, strength)
	img.blend_rect(b, Rect2i(0, 0, r * 2, r * 2), Vector2i(int(cx) - r, int(cy) - r))

func shade(x: float, y: float, w: float, h: float, col: Color) -> void:
	var s := Image.create(int(w), int(h), false, Image.FORMAT_RGBA8)
	s.fill(col)
	img.blend_rect(s, Rect2i(0, 0, int(w), int(h)), Vector2i(int(x), int(y)))

# ------------------------------------------------------------------ the whole ground
func sand() -> void:
	img.fill(K(SAND))
	# big soft light / dark swells so the desert is not flat
	for i in range(150):
		var cx := rng.randf() * W; var cy := rng.randf() * H
		var r := rng.randi_range(28, 80)
		patch(cx, cy, r, K(SAND_L) if rng.randf() < 0.55 else K(SAND_D), 0.30)
	# wind ripples on the dunes
	for i in range(330):
		var x := rng.randf() * W; var y := rng.randf() * H
		var w := 14.0 + rng.randf() * 46.0
		f(x, y, w, 1, SAND_D)
		f(x + 3, y + 1, w - 7, 1, SAND_DD if rng.randf() < 0.25 else SAND_D)
		f(x + 5, y - 1, w - 12, 1, SAND_L)
	# short curved ripple strokes
	for i in range(160):
		var x := rng.randf() * W; var y := rng.randf() * H
		f(x, y, 7, 1, SAND_D); f(x + 7, y + 1, 5, 1, SAND_D); f(x + 2, y - 1, 6, 1, SAND_L)

func scatter_details(avoid: Array) -> void:
	# pebbles, dry grass, bones - kept off the roads / town floor by the caller's mask test
	for i in range(1400):
		var x := rng.randf() * W; var y := rng.randf() * H
		if _near_avoid(x, y, avoid):
			continue
		var big := rng.randf() < 0.18
		if big:
			f(x, y, 3, 2, "#b0894a"); f(x, y, 3, 1, "#d8bd82"); f(x + 1, y + 2, 3, 1, SAND_DD)
		else:
			f(x, y, 1 + int(rng.randf() * 2), 1, "#b88a3e" if rng.randf() < 0.5 else "#f0cf86")
	for i in range(330):
		var x := rng.randf() * W; var y := rng.randf() * H
		if _near_avoid(x, y, avoid):
			continue
		# dry grass tuft
		f(x, y, 1, 4, "#9a7424"); f(x - 2, y + 1, 1, 3, "#9a7424"); f(x + 2, y + 1, 1, 3, "#b08a30"); f(x - 1, y + 2, 1, 2, "#7d5c1c")
	for i in range(120):
		var x := rng.randf() * W; var y := rng.randf() * H
		if _near_avoid(x, y, avoid):
			continue
		# green tuft
		f(x, y, 1, 4, "#5f8a3a"); f(x - 2, y + 1, 1, 3, "#5f8a3a"); f(x + 2, y + 1, 1, 3, "#7aa84a"); f(x - 1, y + 2, 1, 2, "#44692a")
	for i in range(55):
		var x := rng.randf() * W; var y := rng.randf() * H
		if _near_avoid(x, y, avoid):
			continue
		# small dry bush
		f(x, y + 1, 7, 3, "#8d6a2a"); f(x + 1, y, 5, 1, "#a58036"); f(x + 2, y + 4, 3, 1, "#6e5120"); f(x + 3, y - 1, 1, 1, "#c4a050")
	for i in range(12):
		var x := rng.randf() * W; var y := rng.randf() * H
		if _near_avoid(x, y, avoid):
			continue
		f(x, y, 6, 1, "#f1e8d0"); f(x + 2, y - 1, 1, 3, "#f1e8d0"); f(x + 5, y - 1, 2, 1, "#f1e8d0")   # old bone

func _near_avoid(x: float, y: float, avoid: Array) -> bool:
	for r in avoid:
		if r.has_point(Vector2(x, y)):
			return true
	return false

# ------------------------------------------------------------------ roads
static func spline(pts: Array, step := 3.0) -> Array:
	var out := []
	var n := pts.size()
	for i in range(n - 1):
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, n - 1)]
		var seg := int(p1.distance_to(p2) / step) + 1
		for k in range(seg):
			var t := float(k) / seg
			var t2 := t * t; var t3 := t2 * t
			var p := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			out.append(p)
	out.append(pts[n - 1])
	return out

func road(pts: Array, width: float) -> void:
	var path := spline(pts, 3.0)
	# soft shoulder, edge, body, lit centre
	for p in path:
		disc(p.x, p.y + 1, width * 0.5 + 4.0 + rng.randf() * 1.5, K("#cf9f48"))
	for p in path:
		disc(p.x, p.y + 1, width * 0.5 + 1.5 + rng.randf() * 1.2, K("#c08f3e"))
	for p in path:
		disc(p.x, p.y, width * 0.5 - 0.5 + rng.randf() * 1.0, K("#e5c577"))
	for p in path:
		disc(p.x - 1, p.y - 1, width * 0.28, K("#edd28c"))
	# footprints and ruts
	var side := 1.0
	var acc := 0.0
	for i in range(1, path.size()):
		var a: Vector2 = path[i - 1]; var b: Vector2 = path[i]
		var d := (b - a)
		acc += d.length()
		if acc > 11.0:
			acc = 0.0
			var nrm := Vector2(-d.y, d.x).normalized()
			var q := b + nrm * side * (3.0 + rng.randf() * 3.0)
			f(q.x, q.y, 2, 1, "#b78a3a"); f(q.x, q.y + 1, 1, 1, "#d8b568")
			side = -side
		if rng.randf() < 0.04:
			var nrm2 := Vector2(-d.y, d.x).normalized()
			var q2 := b + nrm2 * (width * 0.5 + 3.0) * (1.0 if rng.randf() < 0.5 else -1.0)
			f(q2.x, q2.y, 2, 1, "#a77a30"); f(q2.x, q2.y - 1, 1, 1, "#e8d08c")

# ------------------------------------------------------------------ town floor, yard and ruins
func town_floor(r: Rect2) -> void:
	f(r.position.x, r.position.y, r.size.x, r.size.y, "#dbb464")
	for i in range(int(r.size.x * r.size.y / 380.0)):
		var x := r.position.x + 2 + rng.randf() * (r.size.x - 6)
		var y := r.position.y + 2 + rng.randf() * (r.size.y - 6)
		f(x, y, 3 + int(rng.randf() * 6), 2, "#c9a050" if rng.randf() < 0.55 else "#e6c577")
	for i in range(int(r.size.x * r.size.y / 900.0)):
		var x := r.position.x + 4 + rng.randf() * (r.size.x - 8)
		var y := r.position.y + 4 + rng.randf() * (r.size.y - 8)
		f(x, y, 1, 1, "#a98238")
		f(x + 1, y + 1, 2, 1, "#f0d590")

func flagstones(r: Rect2, omit := 0.35) -> void:
	var cell := 12
	var x0 := int(r.position.x); var y0 := int(r.position.y)
	for gy in range(int(r.size.y / cell)):
		for gx in range(int(r.size.x / cell)):
			if rng.randf() < omit:
				continue
			var x := x0 + gx * cell; var y := y0 + gy * cell
			var tone: String = ["#d9b974", "#d1b06b", "#dcc07e"][rng.randi() % 3]
			f(x, y, cell - 1, cell - 1, tone)
			f(x, y, cell - 1, 1, "#ead39b")
			f(x, y + cell - 2, cell - 1, 1, "#b8924a")
			if rng.randf() < 0.18:
				f(x + 3, y + 4, 4, 1, "#a98238")

func rug(x: float, y: float, w: float, h: float, a: String, b: String) -> void:
	f(x - 1, y - 1, w + 2, h + 2, "#3a2517")
	f(x, y, w, h, a)
	f(x + 2, y + 2, w - 4, h - 4, b)
	f(x + 4, y + 4, w - 8, h - 8, a)
	for i in range(int(w / 4)):
		f(x + 2 + i * 4, y + h / 2.0, 2, 1, "#e8d9a0")

# A flight of steps climbing north (step 0 is the top one), seen from the south. Each step is a tread with a lit front lip, then the riser
# below it: the face that looks at the camera, in shade, with a dark contact line at its foot where it meets the next tread.
# (x, y) = top-left, w = width. tones = [lip, tread, riser, foot]. fade darkens the upper steps (by `fade` at the top step), e.g. for
# stairs climbing into a dark tunnel.
func steps(x: float, y: float, w: float, count: int, tread: int, riser: int, tones: Array, fade := 0.0) -> void:
	for k in range(count):
		var dk := fade * float(count - 1 - k) / maxf(1.0, float(count - 1))
		var c: Array = []
		for t in tones:
			c.append((Color.html(t) if t is String else t).darkened(dk))
		var sy := y + k * (tread + riser)
		f(x, sy, w, tread, c[1])
		var jx := 6.0 + (k % 2) * 9.0         # joints between the stone blocks, staggered from step to step
		while jx < w - 3.0:
			f(x + jx, sy, 1, tread - 1, c[2])
			jx += 18.0
		f(x, sy + tread - 1, w, 1, c[0])
		f(x, sy + tread, w, riser, c[2])
		f(x, sy + tread + riser - 1, w, 1, c[3])

# ------------------------------------------------------------------ rock cliffs / boulders
# generic rounded rectangle (radius r) - the building block of the boulders
func rrr(x: float, y: float, w: float, h: float, c, r: int) -> void:
	var col: Color = Color.html(c) if c is String else c
	var xi := int(x); var yi := int(y); var wi := int(w); var hi := int(h)
	r = mini(r, mini(wi, hi) / 2)
	for dy in range(hi):
		var e := dy if dy < r else (hi - 1 - dy if dy >= hi - r else r)
		var inset := 0
		if e < r:
			var d := r - e - 0.5
			inset = r - int(roundf(sqrt(maxf(0.0, r * r - d * d))))
		img.fill_rect(Rect2i(xi + inset, yi + dy, wi - inset * 2, 1), col)

# Fills `r` with a heap of big rounded boulders (lit top-left, darker sides, dark outline).
func cliff(r: Rect2, flat_top := false) -> void:
	var x0 := r.position.x; var y0 := r.position.y
	var x1 := r.end.x; var y1 := r.end.y
	var cy := y0 - 6.0
	var last := false
	var guard := 0
	while not last and guard < 60:
		guard += 1
		var th := rng.randi_range(20, 32)
		var fh := rng.randi_range(14, 24)
		if cy + th + fh >= y1 - 3:
			cy = y1 - th - fh
			last = true
		var x := x0 - rng.randf() * 26.0
		while x < x1:
			var bw := float(rng.randi_range(46, 100))
			var bx := maxf(x, x0)
			var bex := minf(x + bw, x1)
			if bex - bx >= 20.0:
				var jit := rng.randf_range(-3.0, 6.0)
				var yy := cy + jit
				if yy < y0 - 1.0:
					yy = y0 - 1.0
				if last:
					yy = minf(yy, y1 - th - fh)
				_block(bx, yy, bex - bx, th + rng.randi_range(-3, 3), fh, rng.randf())
			x += bw - rng.randf_range(4.0, 14.0)
		cy += int((th + fh) * 0.46)
	# soft ground shadow to the south-east so it sits on the sand
	shade(x0 + 4, y1 - 1, (x1 - x0) - 2, 8, Color(0.25, 0.14, 0.05, 0.30))
	shade(x0 + 6, y1 + 7, (x1 - x0) - 6, 5, Color(0.25, 0.14, 0.05, 0.15))

func _block(x: float, y: float, w: float, th: float, fh: float, tone: float) -> void:
	var lift := (tone - 0.5) * 0.16
	var top := K(TOP).lightened(maxf(lift, 0.0)).darkened(maxf(-lift, 0.0))
	var topl := K(TOP_L).lightened(maxf(lift, 0.0)).darkened(maxf(-lift, 0.0) * 0.5)
	var face := K(FACE).lightened(maxf(lift, 0.0) * 0.6).darkened(maxf(-lift, 0.0) * 0.6)
	var rad := mini(8, int(th * 0.4))
	var total := th + fh
	# outline
	rrr(x - 1, y - 1, w + 2, total + 2, OUT, rad + 1)
	# vertical face
	rrr(x, y + th * 0.4, w, total - th * 0.4, face, rad)
	rrr(x + 1, y + total - 8, w - 2, 8, FACE_D, 4)
	rrr(x + 3, y + total - 4, w - 6, 4, FACE_DD, 3)
	var sx := x + 4 + rng.randf() * 6
	while sx < x + w - 5:
		var sl := rng.randi_range(5, int(fh) + 4)
		f(sx, y + th - 2, 1, sl, FACE_D)
		f(sx + 1, y + th, 1, maxi(sl - 4, 2), "#9d6c47")
		sx += rng.randi_range(6, 14)
	# lit top with a bevel: dark lip, body, bright upper-left plateau
	rrr(x, y, w, th, TOP_D, rad)
	rrr(x, y, w, th - 3, top, rad)
	rrr(x + 3, y + 2, w * 0.6, th * 0.42, topl, maxi(rad - 3, 2))
	f(x + rad, y + 1, w * 0.3, 1, "#e8c08c")
	# texture: speckles and a couple of cracks
	for i in range(int(w * th / 90.0) + 1):
		var sxp := x + 5 + rng.randf() * (w - 11); var syp := y + 5 + rng.randf() * (th - 11)
		f(sxp, syp, 2, 1, TOP_D); f(sxp + 1, syp - 1, 1, 1, TOP_L)
	for i in range(int(w / 40.0) + (1 if rng.randf() < 0.5 else 0)):
		var cx := x + 8 + rng.randf() * (w - 18); var cyy := y + 4 + rng.randf() * 4
		f(cx, cyy, 1, 3, OUT); f(cx + 1, cyy + 3, 1, 4, OUT); f(cx, cyy + 7, 1, 3, OUT)

# cave mouth cut into a cliff face (drawn after the cliff). c = bottom centre of the opening.
func cave(c: Vector2, w: float, h: float) -> void:
	var x := c.x - w / 2.0; var y := c.y - h
	rr(x - 7, y - 7, w + 14, h + 9, OUT, 3)
	rr(x - 5, y - 5, w + 10, h + 7, "#7d5236", 3)
	f(x - 5, y - 5, w + 10, 3, "#a8794f")
	# dark arch
	for i in range(int(h)):
		var t := float(i) / h
		var hw := w / 2.0 * (sqrt(1.0 - pow(1.0 - minf(t * 1.25, 1.0), 2.0)) if t < 0.8 else 1.0)
		f(c.x - hw, y + i, hw * 2.0, 1, "#1d1410" if t < 0.55 else "#120c08")
	f(x + 2, y + h - 4, w - 4, 4, "#2b1d14")
	for i in range(6):   # rock teeth over the opening
		f(x + 3 + i * (w - 10) / 5.0, y + 1, 4, 3 + (i % 2) * 2, "#6c432a")
	# lit floor at the mouth
	patch(c.x, c.y + 2, 26, K("#2b1d14"), 0.35)

# ------------------------------------------------------------------ river + bridge
# shore: left bank polyline (x as a function of y), water runs east to the edge of the map.
func river(shore: Array, y0: float, y1: float) -> void:
	for yi in range(int(y0), int(y1)):
		var sx := shore_x(shore, yi)
		if sx >= W:
			continue
		# sandy wet bank on the dry side
		f(sx - 7, yi, 3, 1, "#c9993f"); f(sx - 4, yi, 2, 1, "#b98a35"); f(sx - 2, yi, 2, 1, "#a37a2e")
		var wid := W - sx
		f(sx, yi, wid, 1, "#4f93b8")
		f(sx, yi, 2, 1, "#e3f1ec")
		f(sx + 2, yi, 3, 1, "#a7d6dc")
		f(sx + 5, yi, 7, 1, "#78b9d0")
		f(sx + 12, yi, 14, 1, "#5da3c6")
		if wid > 60:
			f(sx + 40, yi, wid - 40, 1, "#4388af")
	# darker current in the middle + lighter shallows by noise
	for i in range(90):
		var yy := y0 + rng.randf() * (y1 - y0)
		var xx := shore_x(shore, int(yy)) + 14.0 + rng.randf() * 70.0
		if xx > W - 8:
			continue
		var w := 6.0 + rng.randf() * 18.0
		f(xx, yy, w, 1, "#3d7fa6")
		f(xx + 2, yy - 1, w - 5, 1, "#6db0cf")
	# a few rocks in the water
	for r in [[1100, 580], [1150, 700], [1095, 505]]:
		_boulder_in_water(r[0], r[1])

func _boulder_in_water(x: float, y: float) -> void:
	f(x - 7, y - 4, 16, 9, "#e3f1ec")
	rr(x - 6, y - 5, 13, 9, OUT, 2)
	rr(x - 5, y - 5, 11, 7, "#8a6a4c", 2)
	f(x - 4, y - 5, 8, 2, "#b08a64")

static func shore_x(shore: Array, y: int) -> float:
	for i in range(shore.size() - 1):
		var a: Vector2 = shore[i]; var b: Vector2 = shore[i + 1]
		if y >= a.y and y <= b.y:
			var t := (y - a.y) / maxf(b.y - a.y, 0.001)
			return lerpf(a.x, b.x, t)
	return 99999.0

func bridge_deck(x0: float, x1: float, y: float, h: float) -> void:
	# long shadow on the water
	shade(x0 + 6, y + h - 2, x1 - x0, 7, Color(0.05, 0.15, 0.25, 0.35))
	f(x0, y - 1, x1 - x0, h + 2, OUT)
	var x := x0
	var i := 0
	while x < x1:
		var tone: String = ["#9a6a3a", "#8a5c30", "#a5733f"][i % 3]
		f(x, y, 6, h, tone)
		f(x, y, 6, 1, "#c08a52")
		f(x, y + h - 2, 6, 2, "#5e3a1c")
		f(x + 5, y, 1, h, "#4a2e18")
		if (i * 7) % 5 == 0:
			f(x + 2, y + 6 + (i % 3) * 4, 1, 1, "#4a2e18")
		x += 6
		i += 1
	f(x0, y, x1 - x0, 2, "#c9975c")
	f(x0, y + h - 3, x1 - x0, 3, "#4a2e18")

# ------------------------------------------------------------------ caves
# Warm dirt and warm grey-brown stone: Era 1 keeps to sand and ochre, so the cave rock is not the cold blue-grey of the reference picture.
const CV_VOID := "#120c0a"
const CV_DIRT := ["#7a5636", "#83603c", "#6e4d30"]
const CV_DIRT_L := "#9a7048"
const CV_STONE := ["#857463", "#76675a", "#8f7d69"]
const CV_STONE_L := "#a8977f"
const CV_STONE_D := "#54483d"
const CV_STONE_OL := "#2e241d"
const CV_FACE := ["#5e4636", "#6a4f3c", "#523c2f"]
const CV_FACE_L := "#7e604a"
const CV_FACE_DD := "#2b1f19"

# A cave is painted from a floor mask: one byte per `cell` x `cell` px square, 1 = floor (walkable), 0 = rock.
#  - floor cells get dirt in soft patches, darker along the walls;
#  - the rock right above a floor edge becomes a rock face `face_cells` high (the walls stand up toward the top of the screen);
#  - the rock beside the floor and on top of those faces gets a rim of rounded stones; deeper rock fades into the dark void.
# Returns the face mask (1 = face cell).
func cave_ground(mask: PackedByteArray, gw: int, gh: int, cell: int, face_cells := 6) -> PackedByteArray:
	var n := gw * gh
	var face := PackedByteArray()
	face.resize(n)
	for gx in range(gw):
		for gy in range(1, gh):
			if mask[gy * gw + gx] == 1 and mask[(gy - 1) * gw + gx] == 0:
				for k in range(1, face_cells + 1):
					var yy := gy - k
					if yy < 0 or mask[yy * gw + gx] == 1:
						break
					face[yy * gw + gx] = 1
	# distance in cells from the floor or a face, over the rock (8 neighbours), up to 6
	var dist := PackedByteArray()
	dist.resize(n)
	dist.fill(255)
	var queue := PackedInt32Array()
	for i in range(n):
		if mask[i] == 1 or face[i] == 1:
			dist[i] = 0
			queue.append(i)
	var head := 0
	while head < queue.size():
		var i: int = queue[head]
		head += 1
		var d: int = dist[i]
		if d >= 6:
			continue
		var gx := i % gw
		var gy := i / gw
		for oy in [-1, 0, 1]:
			for ox in [-1, 0, 1]:
				var nx: int = gx + ox
				var ny: int = gy + oy
				if nx < 0 or ny < 0 or nx >= gw or ny >= gh:
					continue
				var j := ny * gw + nx
				if dist[j] == 255:
					dist[j] = d + 1
					queue.append(j)
	img.fill(K(CV_VOID))
	var noise := FastNoiseLite.new()
	noise.seed = 23
	noise.frequency = 0.035
	# deep rock: a faint warm texture that fades into the void
	for i in range(n):
		var d: int = dist[i]
		if d >= 3 and d <= 6:
			var c := K("#3a2e25").lerp(K(CV_VOID), (d - 3) / 3.0)
			f((i % gw) * cell, (i / gw) * cell, cell, cell, c)
	# the floor: soft patches of three dirt tones, darker where a wall stands beside or above it
	for i in range(n):
		if mask[i] != 1:
			continue
		var gx := i % gw
		var gy := i / gw
		var v := noise.get_noise_2d(gx * 3.0, gy * 3.0)
		var c := K(CV_DIRT[0] if v < -0.15 else (CV_DIRT[1] if v < 0.2 else CV_DIRT[2]))
		if gy >= 1 and face[(gy - 1) * gw + gx] == 1:
			c = c.darkened(0.38)
		elif gy >= 2 and face[(gy - 2) * gw + gx] == 1:
			c = c.darkened(0.2)
		elif (gx >= 1 and mask[i - 1] == 0) or (gx < gw - 1 and mask[i + 1] == 0):
			c = c.darkened(0.15)
		f(gx * cell, gy * cell, cell, cell, c)
	for i in range(n / 3):      # speckles, pebbles and small cracks
		var gx := rng.randi_range(0, gw - 1)
		var gy := rng.randi_range(0, gh - 1)
		if mask[gy * gw + gx] != 1:
			continue
		var x := gx * cell + rng.randi_range(0, cell - 1)
		var y := gy * cell + rng.randi_range(0, cell - 1)
		var r := rng.randf()
		if r < 0.6:
			f(x, y, rng.randi_range(1, 3), 1, "#4e3622" if rng.randf() < 0.5 else "#9a7652")
		elif r < 0.85:
			f(x, y, 3, 2, "#8a7358"); f(x, y, 3, 1, "#a8916f"); f(x, y + 2, 3, 1, "#3a2a1a")
		else:
			f(x, y, 1, 2, "#4a3220"); f(x + 1, y + 2, 1, 2, "#4a3220"); f(x + 1, y + 4, 2, 1, "#4a3220")
	# rock faces: vertical ribs that run on across neighbouring columns, a lit lip on top, a dark foot where they meet the floor
	for gx in range(gw):
		for gy in range(1, gh):
			if not (mask[gy * gw + gx] == 1 and face[(gy - 1) * gw + gx] == 1):
				continue
			var top := gy - 1
			while top > 0 and face[(top - 1) * gw + gx] == 1:
				top -= 1
			var y0 := top * cell
			var y1 := gy * cell
			for px_x in range(gx * cell, gx * cell + cell):
				var rib := noise.get_noise_2d(px_x * 1.6, 7.0)
				var tone: String = CV_FACE[0] if rib < -0.1 else (CV_FACE[1] if rib < 0.25 else CV_FACE[2])
				f(px_x, y0, 1, y1 - y0, tone)
				if rib > 0.25 and noise.get_noise_2d((px_x - 1) * 1.6, 7.0) <= 0.25:
					f(px_x, y0 + 2, 1, y1 - y0 - 4, CV_FACE_L)
			f(gx * cell, y0, cell, 1, CV_FACE_L)
			f(gx * cell, y1 - 3, cell, 1, CV_FACE[2])
			f(gx * cell, y1 - 2, cell, 2, CV_FACE_DD)
			if rng.randf() < 0.18:      # a crack across the face
				f(gx * cell + rng.randi_range(0, cell - 2), y0 + rng.randi_range(4, maxi(5, y1 - y0 - 6)), 2, 1, CV_FACE_DD)
	# the rim: rounded stones on a dark bed beside the floor and on top of the faces (staggered 8 px grid with jitter)
	for i in range(n):
		if dist[i] >= 1 and dist[i] <= 2 and face[i] == 0:
			f((i % gw) * cell, (i / gw) * cell, cell, cell, "#3a2e25")
	for gy in range(0, gh, 2):
		for gx in range((gy / 2) % 2, gw, 2):
			var i := gy * gw + gx
			if dist[i] < 1 or dist[i] > 2 or face[i] == 1:
				continue
			var sw := rng.randi_range(7, 10)
			var sh := rng.randi_range(6, 8)
			var sx := gx * cell + rng.randi_range(-2, 2) - 1
			var sy := gy * cell + rng.randi_range(-2, 2) - 1
			rr(sx - 1, sy - 1, sw + 2, sh + 2, CV_STONE_OL, 2)
			rr(sx, sy, sw, sh, CV_STONE[rng.randi() % 3], 2)
			f(sx + 2, sy + 1, sw - 4, 1, CV_STONE_L)
			f(sx + 1, sy + 2, 1, sh - 4, CV_STONE_L)
			f(sx + 2, sy + sh - 2, sw - 3, 1, CV_STONE_D)
	return face

# a worn track along a cave tunnel: soft lighter dirt and a few scuffs
func cave_path(pts: Array, width: float) -> void:
	var path := spline(pts, 8.0)
	for p in path:
		patch(p.x, p.y, int(width * 0.32), K(CV_DIRT_L), 0.32)
	for p in path:
		if rng.randf() < 0.5:
			f(p.x + rng.randf_range(-width * 0.25, width * 0.25), p.y + rng.randf_range(-4.0, 4.0), 3, 1, "#5e4228")

# ------------------------------------------------------------------ blood (traces, not bodies: see the design doc's tone rule)
# A red that still reads under a dark cave's CanvasModulate and glows near a fire: a dark edge, the body, a wet shine.
const BLOOD_D := "#4e0c0a"
const BLOOD := "#7c1410"
const BLOOD_L := "#a8261c"

# a pool of blood on the ground: wider than tall (it lies flat), a dark rim, a wet red middle with a shine toward the light,
# splashes round it and droplets flung further out. r = radius of the pool
func stain(cx: float, cy: float, r: int) -> void:
	var rb := maxi(2, int(r * 0.75))
	for ox in [-0.45, 0.0, 0.45]:
		patch(cx + ox * r, cy, rb + 1, K(BLOOD_D), 0.85)
	for ox in [-0.35, 0.1, 0.4]:
		patch(cx + ox * r - 1, cy - 1, maxi(2, rb - 1), K(BLOOD), 0.9)
	for i in range(4):
		var a := rng.randf() * TAU
		var d := r * rng.randf_range(0.8, 1.4)
		patch(cx + cos(a) * d, cy + sin(a) * d * 0.6, maxi(2, int(r * rng.randf_range(0.25, 0.45))), K(BLOOD if rng.randf() < 0.6 else BLOOD_D), 0.8)
	if r >= 4:
		f(cx - r * 0.45, cy - r * 0.3, maxi(1, int(r / 3.0)), 1, BLOOD_L)
		f(cx + r * 0.1, cy - r * 0.2, 1, 1, BLOOD_L)
	spatter(cx, cy, r * 2.2, 4 + r)

# blood flung round a point: n drops over a flattened ellipse of radius r, most of them 1 px, a few bigger
func spatter(cx: float, cy: float, r: float, n: int) -> void:
	for i in range(n):
		var a := rng.randf() * TAU
		var d := r * sqrt(rng.randf())
		var x := cx + cos(a) * d
		var y := cy + sin(a) * d * 0.6
		var k := rng.randf()
		if k < 0.7:
			f(x, y, 1, 1, BLOOD if k < 0.45 else BLOOD_D)
		elif k < 0.92:
			f(x, y, 2, 1, BLOOD); f(x, y + 1, 2, 1, BLOOD_D)
		else:
			f(x - 1, y, 3, 2, BLOOD); f(x - 1, y, 1, 1, BLOOD_L); f(x, y + 2, 2, 1, BLOOD_D)

# blood dragged along the ground (someone pulled along it): streaks running with the path, widest and darkest where it starts,
# thinning and breaking up toward the end, with a few clots. pts = the path (a smooth curve through them), w = width at the start
func drag(pts: Array, w: float) -> void:
	var path := spline(pts, 1.0)
	var n := path.size()
	if n < 2:
		return
	var cols := [K(BLOOD_D), K(BLOOD), K(BLOOD_L)]
	var lanes := []        # the streaks across the width: offset (-0.5 .. 0.5), colour, and how far along it gives out
	for i in range(maxi(3, int(w / 1.5))):
		var o := rng.randf_range(-0.5, 0.5)
		lanes.append({"o": o, "c": cols[1] if rng.randf() < 0.55 else cols[0], "end": rng.randf_range(0.55, 1.0) - absf(o) * 0.3})
	lanes.append({"o": rng.randf_range(-0.15, 0.15), "c": cols[2], "end": 0.45})      # a wet line near the middle
	patch(path[0].x, path[0].y, maxi(2, int(w * 0.6)), cols[0], 0.85)                   # where it starts
	for i in range(n):
		var k := float(i) / (n - 1)
		var p: Vector2 = path[i]
		var dir: Vector2 = (path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		var ww := w * lerpf(1.0, 0.35, k)
		if k < 0.85 and i % 2 == 0:
			# the smear itself: a dark band, a redder middle, both thinning out along the way (strength in steps, so the blobs cache)
			var st := snappedf(lerpf(0.85, 0.3, k), 0.1)
			patch(p.x, p.y, maxi(2, int(ww * 0.45)), cols[0], st)
			patch(p.x, p.y, maxi(1, int(ww * 0.25)), cols[1], st)
		for ln in lanes:
			if k > ln["end"] or (k > ln["end"] - 0.15 and rng.randf() < 0.5):
				continue
			var q: Vector2 = p + nrm * ln["o"] * ww
			px(int(q.x), int(q.y), ln["c"])
		if rng.randf() < 0.025:
			var q2: Vector2 = p + nrm * rng.randf_range(-0.4, 0.4) * ww
			f(q2.x, q2.y, 2, 2, cols[0]); px(int(q2.x), int(q2.y), cols[1])
